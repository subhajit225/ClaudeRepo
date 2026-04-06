/**
* @Author      : Rubrik
* @CreatedDate : Aug 02, 2019 
* @Handler     : UserTriggerHandler
* @TstClass    : UserTriggerHandler_Test
* @Description : 
* -------------------------- @History ---------------------------------------------------------------------
* Story Number       Modified By              Date           Description
*                    Grazitti Akash -                        Admin Panel Access Functionality
* CS21-1478          Vijay Kumar K R          June 23, 2022  CIAM: SF Portal Users to Okta Integration
* CS21-2031          Raveesh Layal            Dec 4, 2023    Inactivated / Disabled Support Portal contacts should not have a “User Profile” listed
* PRIT26-556         Akhilesh Dhindsa         05 Jan,2026    Updated createUserHistory,removeInactiveUserFromAccountTeams methods.
* ---------------------------------------------------------------------------------------------------------
*/
public without sharing class UserTriggerHandler{
    public static Boolean userContactRecurrsion = false; // Added for fix SF-4109
    private static Set<Id> cspLiteProfileIds; //added for CS21-692
    private static Id rubrikCustomerCommunityProfileNoCasesId; //added for CS21-692
    private static Boolean profileDetailsAlreadyCached = false; //added for CS21-692
    
    /*public static void setchannelMapping(List<User> createduserList){
        try{
            set<string> actIds = new set<string>();
            set<string> parentactIds = new set<string>();
            Integer count = 0;
            Map<string,integer> accountchildscountMap = new Map<string,integer>();
            List<User> userList = [select id,name,contactId,Contact.Primary_Role__c,accountId,profileId from User where Id IN: createduserList AND (Profile.Name='Rubrik Partner Community Manager' OR Profile.Name = 'Rubrik Partner Community User')];
            for(User u : userList){
                parentactIds.add(u.accountId);
            }

            List<User> childUsersList = [select id,name,accountId from User where accountId IN : parentactIds];
            for(User u : childUsersList){
                if(!accountchildscountMap.isEmpty() && accountchildscountMap.containskey(u.accountId)){
                    count = accountchildscountMap.get(u.accountId);
                    count++;
                    accountchildscountMap.put(u.accountId,count);
                }else{
                    accountchildscountMap.put(u.accountId,1);
                }
            }

            for(User u : userList){
                if(u.accountId != null && u.Contact.Primary_Role__c == 'Admin' && !accountchildscountMap.isEmpty() && accountchildscountMap.containskey(u.accountId) && accountchildscountMap.get(u.accountId) == 1){
                    actIds.add(u.accountId);
                }
            }
            system.debug('@@ actIds '+actIds);
            if(!actIds.isEmpty()){
                PO_Request_Service.accountChannelprogMapping(actIds);
            }

        }catch(Exception e){
            system.debug('Exception occurred '+e.getMessage()+' at line '+e.getLineNumber());
        }
    }*/
    //Addes by Akash for disabling feed standard emails
    //Start
    public static void disableFeedStandardEmail(Map<Id,User> newUserMap){
        Set<Id> userIds = new Set<Id>();
        Set<Id> profilIds = new Set<Id>();
        for(User u : newUserMap.values()){
            userIds.add(u.Id);
        }
        Set<Id> communityUserIds = new Set<Id>();
        for(User u : [SELECT Id,Profile.Name FROM User WHERE Id IN : userIds]){
            if(u.Profile.Name.contains('Community')){
                communityUserIds.add(u.Id);
            }
        }
        List<NetworkMember> nmList = new List<NetworkMember>();
        if(communityUserIds != null){
            for(NetworkMember member:[Select id,PreferencesDisableAllFeedsEmail ,MemberId from  NetworkMember where    MemberId in: communityUserIds and NetworkId=:System.Label.networkScope]){
                member.PreferencesDisableAllFeedsEmail = true;
                nmList.add(member);
            }
        }
        if(!nmList.isEmpty())
            Update nmList;
    }
    //END
    public static void removeInactiveUserFromTerritory(List<User> usersList, Map<Id,User> usersOldMap){
        Set<Id> inactivatedUsers = new Set<Id>();
        Set<Id> activatedUsers = new Set<Id>();
        for(User u: usersList){
            User oldUser = usersOldMap.get(u.Id);
            
            if((u.isActive != oldUser.isActive) || (u.IsPortalEnabled != oldUser.IsPortalEnabled)){
                if(!u.isActive || !u.IsPortalEnabled){
                    inactivatedUsers.add(u.Id);

                    //CS21-745 : Enable automated time-off case routing for inactive or deactivated Support users
                    u.Automated_time_off_case_routing__c = 'Enable';
                    
                     //CS21-2605 : Disable the Admin Panel User field
                    if(u.isAuthorizedUser__c){
                        u.isAuthorizedUser__c=false;
                    }
                }
                else{
                    activatedUsers.add(u.Id);
                }
            }
        }
        if(inactivatedUsers.size()>0)
            delete [select id from UserTerritory2Association where UserId IN: inactivatedUsers and Territory2.Territory2Model.State='Active'];
        if(activatedUsers.size()>0)
            Update [select id from UserTerritory2Association where UserId IN: activatedUsers and Territory2.Territory2Model.State='Active'];
    }

    //Additions By: Shiva Sharma CS21-63
    public static void setNoAccessProfile(List<User> usersList){
        Set<Id> contactIds = new Set<Id>();
        //CS21-692 FIX - using ProfileIds instead of UserType as UserType will be null in before insert
        Set<Id> communityProfileIds = getCSPLitePortalProfileIds(); //added for CS21-692
        Id noCaseProfileId = getCommunityProfileNoCasesId();

        for (User eachUser : usersList) {
            if(communityProfileIds.contains(eachUser.ProfileId)
               && eachUser.ContactId != null)
                contactIds.add(eachUser.ContactId);
        }

        if (!contactIds.isEmpty()) {
            Map<Id, Contact> conMap = new Map<id,Contact>([SELECT Id, AccountId, Account.L3_Support_Only__c,
                                                           Account.Technical_support_provided_by_Partner__c
                                                           FROM Contact
                                                           WHERE Id IN: contactIds
                                                           AND AccountId != null]);

            if(!conMap.isEmpty()){
                for(User usr : usersList){
                    if(usr.ContactId != null && conMap.containsKey(usr.ContactId)
                       && (conMap.get(usr.ContactId).Account.L3_Support_Only__c || conMap.get(usr.ContactId).Account.Technical_support_provided_by_Partner__c != null)){
                           usr.ProfileId = noCaseProfileId;
                       }
                }
            }
        }
    }

    public static void removeInactiveUserFromAccountTeams(List<User> usersList, Map<Id,User> usersOldMap){
        Set<Id> inactivatedUsers = new Set<Id>();
        Set<String> excludedUserTypes = new Set<String>{'PowerPartner', 'CSPLitePortal'};

        for(User u: usersList){
            User oldUser = usersOldMap.get(u.Id);
            if(!u.isActive && oldUser.isActive && !excludedUserTypes.contains(u.UserType)){
                inactivatedUsers.add(u.Id);
            }
        }
        if(inactivatedUsers.size()>0){
          //removeInactiveUserFromAccountTeams(inactivatedUsers);
          RemoveInactiveUserController ric = new RemoveInactiveUserController(inactivatedUsers);
          ID jobID = System.enqueueJob(ric);
          RemoveInactiveUserLicense riul = new RemoveInactiveUserLicense(inactivatedUsers);
          ID jobID2 = System.enqueueJob(riul); //SAL23-839
        }
    }

    @future
    public static void removeInactiveUserFromAccountTeams(Set<Id> inactivatedUsers){
        List<AccountTeamMember> members = [Select Id from AccountTeamMember where UserId in :inactivatedUsers];
        if(members.size()>0){
            delete members;
        }
    }

    public static void setAuthorizeUser(List<User> createduserList){
        try{
            set<Id> contactIds = new set<Id>();
            map<Id,Id> mapContactToAccount = new map<Id,Id>();
            map<Id,List<Contact>> mapAccountToContacts = new map<Id,List<Contact>>();
            Map<id,UserLicense> licenseMap = new Map<id,UserLicense>([select id,name from UserLicense WHERE NAME LIKE '%Customer Community%']);
            for(User each : createduserList){
                if(each.contactId!=null && !each.isAuthorizedUser__c ){
                    contactIds.add(each.contactId);
                }
            }
            if(contactIds !=null && !contactIds .isEmpty()){
                for(Contact con : [select id,AccountId from contact WHERE ID IN : contactIds ]){
                    mapContactToAccount.put(con.id,con.Accountid);
                    if(mapAccountToContacts.containsKey(con.accountId))
                        mapAccountToContacts.get(con.AccountId).add(con);
                    else
                        mapAccountToContacts.put(con.AccountId,new List<Contact>{con});
                }
            }
            map<Id,Account> mapOfIdToAccount = new map<Id,Account>([select id,(select id from users WHERE Profile.UserLicenseID IN: licenseMap.keyset()) from account where Id IN : mapAccountToContacts.Keyset()]);

            for(User each : createduserList){
                if(each.contactid!=null && mapContactToAccount !=null && !mapContactToAccount.isEmpty() && mapContactToAccount.containsKey(each.ContactId)){
                    if(mapOfIdToAccount!=null && !mapOfIdToAccount.isEmpty() && mapOfIdToAccount.containsKey(mapContactToAccount.get(each.contactId))){
                        if(mapOfIdToAccount.get(mapContactToAccount.get(each.contactId)).users == null || mapOfIdToAccount.get(mapContactToAccount.get(each.contactId)).users.isEmpty()){
                            each.isAuthorizedUser__c = true;
                        }
                    }
                }
            }
        }catch(Exception e){
            System.debug(e);
        }
    }
    public static void updateContact(List<User> createduserList,map<Id,User>UserOldMap){
        try{

            List<Contact> lstToUpdate = new List<Contact>();
            set<Id> profileIds = new set<Id>();
            map<Id,User> ContactIdToUser = new map<Id,User>();
            map<Id,Profile> profileMap = new map<Id,Profile>();
            for(User each : createduserList){
                if(each.contactId!=null){
                    ContactIdToUser.put(each.contactId,each);
                    profileIds.add(each.ProfileId);
                }

            }
            if(profileIds!=null && !profileIds.isEmpty()){
                for(Profile each : [select id,Name from Profile where ID IN : profileIds]){
                    profileMap.put(each.Id,each);
                }
            }

			for(Contact con : [SELECT id,User_Profile__c,Time_Zone__c FROM contact where ID IN: ContactIdToUser.keyset()]){
                if(ContactIdToUser!=null && !ContactIdToUser .isEmpty() && ContactIdToUser.containskey(con.Id)){
                    if(UserOldMap!=null && !UserOldMap.isEmpty()){
                        User newUser = ContactIdToUser.get(con.Id);
                        User oldUser = UserOldMap.get(ContactIdToUser.get(con.Id).Id);
                        Boolean isConUpdate = false;
                        con.Time_Zone__c = ContactIdToUser.get(con.Id).TimeZoneSidKey;
                        if(!profileMap.isEmpty() && profileMap!=null && profileMap.containsKey(newUser.profileId)){
                            if(newUser.isActive && !oldUser.isActive){
                                con.User_Profile__c = profileMap.get(ContactIdToUser.get(con.Id).profileId).Name;
                                con.CommunityUser__c = ContactIdToUser.get(con.Id).Id; // added for CS21-788 - Veera
                                isConUpdate = true;
                            }
                            if(newUser.profileId!=oldUser.profileId){
                                con.User_Profile__c = profileMap.get(ContactIdToUser.get(con.Id).profileId).Name;
                                con.CommunityUser__c = ContactIdToUser.get(con.Id).Id; // added for CS21-788 - Veera
                                isConUpdate = true;
                            }
                             //CS21-2031 STARTS
                            if(!newUser.isActive && oldUser.isActive){
                                con.User_Profile__c =null;
                                isConUpdate = true;
                            }
                            //CS21-2031 ENDS
                            //
                            //CS21-1403 STARTS: Added by Ashish to update Phone on Support Portal User
                            if(newUser.phone!=oldUser.phone){
                                con.Phone = newUser.phone;
                                isConUpdate = true;
                            } 
                            //CS21-1403 ENDS
                            
                            if(isConUpdate && !lstToUpdate.contains(con)){
                                lstToUpdate.add(con);
                            }
                        }
                    }else{
                        if(!profileMap.isEmpty() && profileMap!=null && profileMap.containsKey(ContactIdToUser.get(con.Id).profileId)){
                            con.User_Profile__c = profileMap.get(ContactIdToUser.get(con.Id).profileId).Name;
                            con.CommunityUser__c = ContactIdToUser.get(con.Id).Id; // added for CS21-788 - Veera
                            lstToUpdate.add(con);
                        }
                        con.Time_Zone__c = ContactIdToUser.get(con.Id).TimeZoneSidKey;
                    }
                }
            }

            if(lstToUpdate!=null && !lstToUpdate .isEmpty()){
                //userContactRecurrsion = true;  // Added for fix SF-4109
                //update lstToUpdate;            // Added for fix SF-4109
                if(!System.isFuture())
                    updateContactFuture(JSON.serialize(lstToUpdate)); // Added for fix and reverted SF-4109.
                else
                    update lstToUpdate;
            }

        }catch(exception e){
            system.debug('#####'+e);
        }
    }
    @future
    public static void updateContactFuture(String contact){
        userContactRecurrsion = true;// Added for fix SF-4109
        update (List<Contact>)JSON.deserialize(contact,List<Contact>.class);
    }

   /* public static void setDefaultUserRole(List<User> createdUserList){

        ID roleId = [select id, name  from UserRole where Name ='Unassigned'].id;
        System.debug('Role Id -- '+roleId);
        for(User each : createdUserList){
            System.debug('User Role Id --'+each.UserRoleId);
                if(each.ContactId == null && each.UserRoleId == null){
                    each.UserRoleId = roleId;
            System.debug('User New Role Id --'+each.UserRoleId);
                }
        }
    } */

    //<Additions By: Anmol Baweja 27Feb, 2020 CS-582 start>
    //<Reason>
    //To restrict any community user creation which contains email domains like gmail.com,icloud.com, yahoo.com etc. as per CS-582
    //</Reason>
    //Refactored code - 13th Jan 2022 - Veera
    public static void UsersWithIgnoredDomains(List<User> newUsers, Map<Id, User> oldMap){
        Set<Id> contactIds = new Set<Id>();
        List<Id> supportCommunityProfileIds = System.Label.Community_Profiles_For_Portal.split(';');
        List<String> ignoredDomains = new List<String>();
        Map<Id,Contact> contactDetails = new Map<Id,Contact>();
        Map<Id,Profile> communityProfileIds = new Map<Id,Profile>([SELECT Id, Name FROM Profile WHERE Id IN: supportCommunityProfileIds]);

        for(User eachUser : newUsers) {
            if(eachUser.isActive == true && eachUser.ContactId != null) {
                contactIds.add(eachUser.ContactId);
            }
        }

        //CS21-199
        if (!contactIds.isEmpty()) {
            for (Contact eachContact :[SELECT Id, AccountId, Account.Name FROM Contact WHERE Id IN: ContactIds]) {
                contactDetails.put(eachContact.Id, eachContact);
            }
        }

        for(Ignored_Domain__mdt eachDomain : [SELECT Id, Language, isIgnored__c, Label, MasterLabel FROM Ignored_Domain__mdt
                                              WHERE isIgnored__c = true]) {
                                                  ignoredDomains.add(eachDomain.Label.toLowerCase());
                                              }

        for(User eachUser : newUsers){
            if(eachUser.IsActive == true && eachUser.ContactId != null) {
                if (contactDetails.containsKey(eachUser.ContactId)) {
                    eachUser.CompanyName = contactDetails.get(eachUser.ContactId).Account.Name;  //CS21-199
                }

                if(string.isNotBlank(eachUser.Email) && communityProfileIds.containsKey(eachUser.ProfileId)){
                    String currentEmailDomain = eachUser.Email.substringAfter('@').toLowerCase();
                    //Email is a required field on user
                    String oldEmailDomain = oldMap != null ? oldMap.get(eachUser.Id).Email.substringAfter('@').toLowerCase() : '';
                    Boolean isOldEmailNonCorporate = string.isNotBlank(oldEmailDomain) ? ignoredDomains.contains(oldEmailDomain) : false;
                    Boolean isCurrentEmailNonCorporate = ignoredDomains.contains(currentEmailDomain);

                    if (!isOldEmailNonCorporate && isCurrentEmailNonCorporate) {
                        eachUser.addError(System.Label.S_R_Ignored_Domain);
                    }
                }
            }
            //Added by Ashish Thakur on April 22, 2022 for Ticket CS21-1088
            else if(eachUser.IsActive && eachUser.UserType == 'standard'){
                eachUser.CompanyName = 'Rubrik';
            }
        }
    }

    //</Additions By: Anmol Baweja CS-582 end>

    //Freeze users when termination date is added
    //Update : CS21-195 : Deactivate and disable portal access for community users, exclude freezing for community users
    public static void freezeTerminatedUsers(List<User> updatedUsers, Map<Id, User> oldMap){
        Set<Id> usersTerminated = new Set<Id>();
        Set<Id> usersToFreeze = new Set<Id>();
        List<User> usersToDisableCommunityAccessList = new List<User>();
        //Using static variable to decide if the validation rule on user trigger should fire or not
        checkRecursive.AllowSupportPortalUserCreation = true;
        for(User u: updatedUsers){
            User oldUser = oldMap.get(u.Id);
            if(u.Termination_Date__c != null &&
               oldUser.Termination_Date__c == null){
                usersTerminated.add(u.Id);
            }
        }

        List<User> usersTerminatedList = [Select Id, Profile.Name from User where Id IN :usersTerminated];

        for(User terminatedUser : usersTerminatedList){
            if(terminatedUser.Profile.Name.contains('Community')){
                terminatedUser.IsActive = false;
                terminatedUser.IsPortalEnabled = false;
                usersToDisableCommunityAccessList.add(terminatedUser);
            } else{
                usersToFreeze.add(terminatedUser.Id);

            }
        }

        List<UserLogin> logins = new List<UserLogin>();
        for(UserLogin ul: [Select Id from UserLogin where UserId in :usersToFreeze]){
            logins.add(new UserLogin(Id = ul.Id, IsFrozen = true));
        }
        if(logins.size()>0){
            update logins;
        }

        if(usersToDisableCommunityAccessList.size()>0){
            update usersToDisableCommunityAccessList;
        }

    }

    public static void createSalesEnablementRecords(Map<ID, User> newUserMap, Map<ID, User> oldUserMap){
        List<Sales_Enablement__c> salesEnablementList = new  List<Sales_Enablement__c>();
        Profile rubrikFieldSalesUserProfile = [SELECT Id FROM profile WHERE name= 'Rubrik Field Sales User' limit 1];
        Set<ID> salesEnablementUserSet = new Set<ID>();
        if(oldUserMap != null){
            List<Sales_Enablement__c> savedSalesEnablementList = [Select User__c from Sales_Enablement__c WHERE User__c in :newUserMap.keySet()];
            for(Sales_Enablement__c se: savedSalesEnablementList){
                salesEnablementUserSet.add(se.User__c);
            }
        }
        for(User u: newUserMap.values()){
            if(u.ProfileId == rubrikFieldSalesUserProfile.id){
                if(oldUserMap == null || (  u.ProfileId != oldUserMap.get(u.id).ProfileId) && (!salesEnablementUserSet.contains(u.id)) ){
                    salesEnablementList.add(new Sales_Enablement__c(User__c = u.id, OwnerId=u.id, Name = (String.isBlank(u.FirstName) ? ''  : u.FirstName) + ' ' + u.LastName));
                }
            }
        }
        if(!salesEnablementList.isEmpty()){
            //insert salesEnablementList;
            createSalesEnablementRecordsInFuture(JSON.serialize(salesEnablementList));
        }
    }
    @future
    public static void createSalesEnablementRecordsInFuture(String usersDetails){
        List<Sales_Enablement__c> salesEnablementList = (List<Sales_Enablement__c>)JSON.deserialize(usersDetails, List<Sales_Enablement__c>.class);
        if(!salesEnablementList.isEmpty()){
            insert salesEnablementList;
        }
    }

    /**
     * Author       :   Saakshi Gupta
     * CreatedDate  :   4th June 2021
     * Description  :   CS21-493 : The method checks if RASP flag while User creation is true or false.
     *                  If true, RASP Resources value is added to the Releases field
    */
    public static void updateReleases(List<User> userList){
        for(User eachUser : userList){
            if(!String.isBlank(eachUser.ContactId) && eachUser.RASP__c && (String.isBlank(eachUser.Releases__c) || !eachUser.Releases__c.containsIgnoreCase('RASP Resources'))){
                eachUser.Releases__c = String.isBlank(eachUser.Releases__c) ? 'RASP Resources' : eachUser.Releases__c + ';RASP Resources';
            }
        }
    }

    /**
    * @description method to get all profile ids of type CSPLitePortal - CS21-692 - Veera
    * @return  set of Profile Ids
    */
    public static set<Id> getCSPLitePortalProfileIds() {
        if (!profileDetailsAlreadyCached) {
            getProfiledetails();
        }

        return cspLiteProfileIds;
    }

    /**
    * @description method to get "Rubrik Customer Community Login User (No Cases)" profile Id - CS21-692 - Veera
    * @return  Profile Ids
    */
    public static Id getCommunityProfileNoCasesId() {
        if (!profileDetailsAlreadyCached) {
            getProfiledetails();
        }

        return rubrikCustomerCommunityProfileNoCasesId;
    }

    /**
    * @description method to fetch profile details - CS21-692 - Veera
    * @return  void
    */
    public static void getProfiledetails() {
        cspLiteProfileIds = new Set<Id>();

        for (Profile eachProfile : [SELECT Id, Name FROM Profile
                                    WHERE UserType = 'CSPLitePortal'])
        {
            cspLiteProfileIds.add(eachProfile.Id);

            if (eachProfile.Name == 'Rubrik Customer Community Login User (No Cases)') {
                rubrikCustomerCommunityProfileNoCasesId = eachProfile.Id;
            }

        }

        profileDetailsAlreadyCached = true;
    }

    //start CS21-733
    public static void deleteAllSubscriptions(Map<Id,User> newUserMap,Map<Id,User> oldUserMap){
        List<Id> userIds = new List<Id>();
        for( User u : newUserMap.values()){
            if(u.IsActive == false && u.IsActive != oldUserMap.get(u.Id).IsActive){
                userIds.add(u.Id);
            }
        }

        if(!userIds.isEmpty()){
            if(System.isBatch() || System.isFuture()){
                deleteSubs(userIds);
            }
            else{
                deleteSubsInFuture(userIds);
            }
        }
    }

    @future
    private static void deleteSubsInFuture(List<Id> userIds){
        deleteSubs(userIds);
    }

    private static void deleteSubs(List<Id> userIds){
        DELETE [SELECT Id FROM Customer_Subscription__c WHERE Type__c='FeedItem' AND User__c IN : userIds];
        DELETE [SELECT Id FROM EntitySubscription WHERE SubscriberId IN : userIds];
    }
    //end CS21-733

    /**
    * @description method to assign badge to new community user - CS21-712
    */
    public static void assignWelcomeBadge(List<User> newList) {

        Set<Id> communityProfileIds = getCSPLitePortalProfileIds();
        Set<Id> userIds = new Set<Id>();

        for (User eachUser : newList) {
            if(communityProfileIds.contains(eachUser.ProfileId)) {
                userIds.add(eachUser.Id);
            }
        }

        if (!userIds.isEmpty()) {
            if (System.isBatch()
                || system.isFuture()
                || system.isQueueable()
                || system.isScheduled()) {
                assignWelcomeBadgeToSupportCommunityUsers(userIds);
            } else {
                asyncAssignWelcomeBadgeToSupportCommunityUsers(userIds);
            }
        }
    }

    /**
    * @description welcome badge assignment(future) - CS21-712
    */
    @future
    private static void asyncAssignWelcomeBadgeToSupportCommunityUsers(Set<Id> userIds) {
        assignWelcomeBadgeToSupportCommunityUsers(userIds);
    }

    /**
    * @description welcome badge assignment - CS21-712
    */
    private static void assignWelcomeBadgeToSupportCommunityUsers(Set<Id> userIds) {
        Id networkId = Label.NetworkId; //move to label
        Id badgeDefintionId = Label.BadgeDefinitionId;
        Id workThanksId = Label.WorkThanksId;
        List<WorkBadge> badges = new List<WorkBadge>();

        for (NetworkMember member : [SELECT Id, MemberId FROM NetworkMember
                                     WHERE NetworkId = :networkID
                                     AND Member.IsActive = true
                                     AND Member.Profile.UserType = 'CSPLitePortal'
                                     AND MemberId IN :userIds])
        {
            WorkBadge badge = new WorkBadge(
                DefinitionId = badgeDefintionId,
                NetworkID = networkId,
                RecipientId = member.MemberId,
                SourceId = workThanksId
            );

            badges.add(badge);
        }

        List<Database.SaveResult> results = Database.insert(badges, false);

        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                System.debug(LoggingLevel.ERROR, 'Result :: ' + result.getErrors());
            }
        }
    }

    /*
     * @description CS21-627 : Restrict the Sales User from creating Support portal Community user manually through button on contact detail page
     * @param newUserList
     * @param oldUserMap
     * @param userUpdate
     * @param userInsert
    */
    public static void showErrorOnSupportPortalUserCreation(List<User> newUserList, Map<ID, User> oldUserMap, boolean userUpdate, boolean userInsert){
        List<Group> groupDetail = [SELECT Id FROM Group WHERE DeveloperName = 'Disable_Support_Portal_User_Creation'];
        List<Profile> guestProfile=[SELECT id,Name from Profile WHERE Name='Rubrik Support Profile'];
        if(groupDetail!=NULL && groupDetail.size()>0){
            List<GroupMember> groupMemberList = [SELECT UserOrGroupId FROM GroupMember WHERE GroupId =: groupDetail[0].Id AND UserOrGroupId =: UserInfo.getUserId()];
            //Allow for System Admins,Public group, Add user Type Criteria CSPLite , Use this to Community_Profiles_For_Portal, add the usertype check of standard(it should be internal user)
            for(User eachUser : newUserList){
                if(userInsert){
                    String nickName =  eachUser.FirstName +'-'+System.now().formatGMT('MMddyy-HHmm');
                    if(nickName.length() > 40){
                        nickName = (eachUser.FirstName != null) ? eachUser.FirstName.substring(0,1) +'-'+System.now().formatGMT('MMddyy-HHmm'): System.now().formatGMT('MMddyy-HHmm');
                    }
                    if(!test.isRunningTest()){
                        eachUser.CommunityNickname = nickName;
                    }
                }
                if(eachUser.profileID != NULL && Label.Community_Profiles_For_Portal.contains(string.valueof(eachUser.profileID).Substring(0,15))){
                    if(!checkRecursive.AllowSupportPortalUserCreation){
                        if(userInsert && userInfo.getProfileId() != guestProfile[0].id  && userInfo.getProfileId() != Label.AdminProfileID && eachUser.contactID != NULL && groupMemberList.isEmpty()){
                            eachUser.addError(Label.Warning_Message_for_Support_Portal_user_Creation);
                        }
                        else if(userUpdate && userInfo.getProfileId() != guestProfile[0].id  && userInfo.getProfileId() != Label.AdminProfileID && eachUser.contactID != NULL && eachUser.UserType == 'CspLitePortal' && !eachUser.IsPortalEnabled && oldUserMap.get(eachUser.id).IsPortalEnabled && groupMemberList.isEmpty()) {
                            eachUser.addError(Label.Warning_Message_for_Support_Portal_user_Creation);
                        }
                    }
                }
            }
        }
    }
    //SAL23-374
    public static void setPOCApprover(List<User> newUserList, Map<Id,User> oldUserMap){
        Set<Id> roleMap = new Set<Id>();
        Set<Id> mgrIdSet = new Set<Id>();
        Set<Id> roleIdSet = new Set<Id>();
        List<User> uList = new List<User>();
        Map<Id,Id> mgrMap = new Map<Id,Id>();
        List<User> managerList = new List<User>();
        for(user u : newUserList){
            if(oldUserMap == null || (oldUserMap != null && (oldUserMap.get(u.Id).ManagerId != u.ManagerId) || (oldUserMap.get(u.Id).UserRoleId != u.UserRoleId)))
                uList.add(u);
                mgrIdSet.add(u.ManagerId);
        }
        if(!mgrIdSet.isEmpty()){
            for(User mgrUser : [select Id,isActive,ManagerId,Manager.isActive from User where Id IN: mgrIdSet]){
                if(mgrUser.isActive){
                    mgrMap.put(mgrUser.Id,mgrUser.Id);
                }else if(mgrUser.ManagerId != null && mgrUser.Manager.isActive){
                    mgrMap.put(mgrUser.Id,mgrUser.ManagerId);
                }
            }
        }

        if(!uList.isEmpty()){
            for(UserRole role : [select Id,Name from UserRole where Name like '%Sales Engineer%']){
                roleIdSet.add(role.Id);
            }
        }
        if(!roleIdSet.isEmpty()){
            for(user u : uList){
                if(roleIdSet.contains(u.UserRoleId) && u.ManagerId != null && !mgrMap.isEmpty() && mgrMap.containskey(u.ManagerId)){
                    u.POC_Approver__c = mgrMap.get(u.ManagerId);
                }else{
                    u.POC_Approver__c = null;
                }
            }
        }
    }

    //SAL23-374
    public static void removalofPOCApprover(List<User> newUserList, Map<Id,User> oldUserMap){
        Map<Id,UserTerritory2Association> allSEAEUTAMap = new Map<Id,UserTerritory2Association>();
        List<UserTerritory2Association> finalUTAList = new List<UserTerritory2Association>();
        Map<Id,Id> userPrevPOCIdMap = new Map<Id,Id>();

        for(user u : newUserList){
            if(oldUserMap != null && u.POC_Approver__c == null && oldUserMap.get(u.Id).POC_Approver__c != u.POC_Approver__c)
                userPrevPOCIdMap.put(u.Id,oldUserMap.get(u.Id).POC_Approver__c);
        }

        if(!userPrevPOCIdMap.isEmpty()){
            for(UserTerritory2Association uta : [select Id, UserId,IsActive,Territory2Id,RoleInTerritory2,Territory2.ParentTerritory2Id,Territory2.ParentTerritory2.ParentTerritory2Id ,Territory2.Territory2Type.DeveloperName,Territory2.Territory2Model.State from UserTerritory2Association where Territory2.Territory2Model.State = 'Active' and RoleInTerritory2 IN ('Account Executive','Sales Engineer') AND UserId IN:userPrevPOCIdMap.keySet()]){
                finalUTAList.add(uta);
            }
        }
        if(!finalUTAList.isEmpty()){
            UserTerritory2AssociationTriggerHelper.setPOCApprover(finalUTAList,userPrevPOCIdMap);
        }
    }

    /*
     * Author       :   Saakshi Gupta
     * CreatedDate  :   25th August 2022
     * Description  :   CS21-1189 : Insert User History records on change of Coins field value on User
         */
    public static void createUserHistory(List<User> newUserList, Map<Id,User> oldUserMap){
        List<User> usersWithCoinChanges = new List<User>();
        for (User userObj:newUserList)
        {
            User oldUser = oldUserMap.get(userObj.Id);
            if(userObj.Coins__c !=oldUser.Coins__c)
            {
                usersWithCoinChanges.add(userObj);
            }
        }
        if(!usersWithCoinChanges.isEmpty())
        {
            CS_FieldHistoryTracking.trackFieldsHistory(usersWithCoinChanges, oldUserMap);
        }

      /*  List<User_History__c> userHistoryList = new List<User_History__c>();
        for(User eachUser : newUserList){
            if(eachUser.Coins__c != oldUserMap.get(eachUser.Id).Coins__c){
                userHistoryList.add(new User_History__c(
                    Parent_Id__c = eachUser.Id,
                    Modified_By__c = UserInfo.getUserId(),
                    Modified_Date_Time__c = System.now(),
                    Old_Value__c = String.valueOf(oldUserMap.get(eachUser.Id).Coins__c),
                    New_Value__c = String.valueOf(eachUser.Coins__c),
                    Field__c = 'Coins'));
            }
        }

        if(!userHistoryList.isEmpty()){
            List<User_Coins_Update_Reason_Mapping__mdt> coinReasonMapping = [SELECT Increase_in_coins__c, Reason__c
                                                                            FROM User_Coins_Update_Reason_Mapping__mdt
                                                                            WHERE Active__c = true];

            Map<Integer, String> coinIncreaseToReasonMap = new Map<Integer, String>();
            for(User_Coins_Update_Reason_Mapping__mdt eachMapping : coinReasonMapping){
                coinIncreaseToReasonMap.put(Integer.valueOf(eachMapping.Increase_in_coins__c), eachMapping.Reason__c);
            }

            for(User_History__c eachUserHistory : userHistoryList){
                Integer coinDifference = Integer.valueOf(eachUserHistory.New_Value__c) - Integer.valueOf(eachUserHistory.Old_Value__c);
                //Set the reason based on the increase on coins to identify the action performed by the customer on support portal
                if(coinIncreaseToReasonMap.containsKey(coinDifference) && UserInfo.getName().equalsIgnoreCase('Automated Process')){
                    eachUserHistory.Reason__c = coinIncreaseToReasonMap.get(coinDifference);
                }
                else{
                    eachUserHistory.Reason__c = 'Manual';
                }
            }

            Database.insert(userHistoryList, false);
        }
*/
    }

   /**
    * @Author           :   gaurav rawat (partner) / vijay.kr (customer)
    * @CreatedDate      :   June 23, 2022
    * @Description      :   Okta Actions on User Creation, Updation, activation, de-activation
    * @Params           :   List<User> userRecordList, Boolean isInsert
    * @Return           :   void
    */
    public static void oktaUserCreation(List<User> userRecordList, Boolean isInsert){

        Set<String> userEmailSet = new Set<String>();
        for(User userInst : userRecordList){
            if(userInst.UserType == 'PowerPartner'){
                userEmailSet.add(userInst.Email);
            } 
        }
        
        Map<String, List<User>> existingPartnerUserByEmailMap = new Map<String, List<User>>(); 
        for(User userObj : [SELECT Id, UserType, Email 
                            FROM User 
                            WHERE Email IN : userEmailSet
                            AND UserType = 'PowerPartner']){
            if(!existingPartnerUserByEmailMap.containsKey(userObj.Email)){
                existingPartnerUserByEmailMap.put(userObj.Email, new List<User>());
            }
            existingPartnerUserByEmailMap.get(userObj.Email).add(userObj);

        }

        Set<Id> userIdSet = new Set<Id>();
        for(User userInst : userRecordList){
            if(userInst.UserType == 'PowerPartner'){
                if(!existingPartnerUserByEmailMap.isEmpty() 
                    && existingPartnerUserByEmailMap.containsKey(userInst.Email)
                    && existingPartnerUserByEmailMap.get(userInst.Email).size() > 1 
                    && isInsert){
                        userInst.addError('You can not create duplicate user with same Email, it is already exist!');
                        continue;
                }
            }
            // Okta User Creation only for Customer and Partner Portal Users
            if(userInst.ContactId != null
                && (userInst.UserType == 'CspLitePortal'
                    || userInst.UserType == 'PowerPartner')
                && (isChanged('FirstName', userInst)
                    || isChanged('LastName', userInst)
                    || isChanged('ProfileId', userInst)
                    || isChanged('isActive', userInst)
                    || isChanged('UserName', userInst)
                    || isChanged('Email', userInst))){
                        userIdSet.add(userInst.Id);
                }
        }
        if(!userIdSet.isEmpty()){
            ID jobID = System.enqueueJob(new OktaUserUtility(userIdSet,Trigger.oldMap));
        }
    }

    /**
    * @Author           :   vijay.kr@rubrik.com
    * @CreatedDate      :   June 23, 2022
    * @Description      :   To check value is changed bwtween old and new record
    * @Params           :   String fieldname, String newRecord
    * @Return           :   Boolean
    */
    public static Boolean isChanged(String fieldName, sObject newRecord){
        sObject oldRecord = Trigger.oldMap != null ? Trigger.oldMap.get((Id)newRecord.get('id')) : null;

        if(oldRecord == null){
            return true;
        }
        if(newRecord == null) {
            return null;
        }
        return oldRecord.get(fieldName.toLowerCase()) != newRecord.get(fieldName.toLowerCase());
    }
    
 //SAL23-597
  /*public static void assignPermissionSetgroup(List<User> newUserList, Map<Id,User> oldUserMap){
        Map<String,List<String>> permSetGrpMap = new Map<String,List<String>>();
        Map<String,List<String>> licenseMap = new Map<String,List<String>>();
        Map<String,List<String>> pubGrpMap = new Map<String,List<String>>();
		Map<Id,string> removePrevConfigsMap = new Map<Id,string>();
        Map<String,List<String>> userPermIdMap = new Map<String,List<String>>();
        Map<String,List<String>> userLicenseIdMap = new Map<String,List<String>>();
        Map<String,List<String>> pubGrpIdMap = new Map<String,List<String>>();
        Map<String,List<String>> oldBUUserIdMap = new Map<String,List<String>>();
        Map<Id,Set<Id>> existingUserLicenseMap = new Map<Id,Set<Id>>();
        List<string> tempList = new List<String>();
        Map<Id,Set<Id>> existingPermAsgnMap = new Map<Id,Set<Id>>();
        Map<Id,Set<Id>> existingPubGrpMap = new Map<Id,Set<Id>>();
        List<PermissionSetAssignment> permAsgnList = new List<PermissionSetAssignment>();
      	List<PermissionSetLicenseAssign> licenseAsgnList = new List<PermissionSetLicenseAssign>();
        List<GroupMember> pubGrpList = new List<GroupMember>();
        List<PermissionSetAssignment> removePermAsgnList = new List<PermissionSetAssignment>();
        List<GroupMember> removePubGrpList = new List<GroupMember>();

        for(Assign_PermSetGroup_BU__mdt psg : [select Id,MasterLabel,Business_Group_Name__c,Ids__c,Type__c from Assign_PermSetGroup_BU__mdt]){
            tempList = new List<String>();
            if(!string.isBlank(psg.Ids__c) && psg.Type__c == 'Permissionset Group'){
                if(psg.Ids__c.contains(';')){
                    tempList = psg.Ids__c.split(';');
                }else{
                	tempList.add(psg.Ids__c);
                }
                if(!tempList.isEmpty())
                	permSetGrpMap.put(psg.Business_Group_Name__c,tempList);
            }
            if(!string.isBlank(psg.Ids__c) && psg.Type__c == 'License'){
                if(psg.Ids__c.contains(';')){
                    tempList = psg.Ids__c.split(';');
                }else{
                	tempList.add(psg.Ids__c);
                }
                if(!tempList.isEmpty())
                	licenseMap.put(psg.Business_Group_Name__c,tempList);
            }
            if(!string.isBlank(psg.Ids__c) && psg.Type__c == 'Public Group'){ //SAL24-647
                if(psg.Ids__c.contains(';')){
                    tempList = psg.Ids__c.split(';');
                }else{
                	tempList.add(psg.Ids__c);
                }
                if(!tempList.isEmpty())
                	pubGrpMap.put(psg.Business_Group_Name__c,tempList);
            }
        }
        for(user u : newUserList){
            if(u.isActive == true && string.isBlank(u.Business_Group__c) && oldUserMap != null && oldUserMap.get(u.Id).Business_Group__c != u.Business_Group__c){
            	removePrevConfigsMap.put(u.Id,oldUserMap.get(u.Id).Business_Group__c);
            }
            if(u.isActive == true && !string.isBlank(u.Business_Group__c) && (oldUserMap == null || (oldUserMap != null && oldUserMap.get(u.Id).Business_Group__c != u.Business_Group__c))){
                if(oldUserMap != null)
                	removePrevConfigsMap.put(u.Id,oldUserMap.get(u.Id).Business_Group__c);
                if(!permSetGrpMap.isEmpty() && permSetGrpMap.containskey(u.Business_Group__c))
            		userPermIdMap.put(u.Id,permSetGrpMap.get(u.Business_Group__c));
                if(!licenseMap.isEmpty() && licenseMap.containskey(u.Business_Group__c))
                	userLicenseIdMap.put(u.Id,licenseMap.get(u.Business_Group__c));
                if(!pubGrpMap.isEmpty() && pubGrpMap.containskey(u.Business_Group__c))
                	pubGrpIdMap.put(u.Id,pubGrpMap.get(u.Business_Group__c));
            }
        }
        if(!removePrevConfigsMap.isEmpty()){
            if(!permSetGrpMap.isEmpty()){
                for(PermissionSetAssignment asgnrec : [select Id,AssigneeId,Assignee.Business_Group__c,PermissionSetGroupId from PermissionSetAssignment where AssigneeId IN: removePrevConfigsMap.keySet()]){
                    if(existingPermAsgnMap.isEmpty() || !existingPermAsgnMap.containskey(asgnrec.AssigneeId))
                        existingPermAsgnMap.put(asgnrec.AssigneeId, new Set<Id>());
                    existingPermAsgnMap.get(asgnrec.AssigneeId).add(asgnrec.PermissionSetGroupId);
                    if(removePrevConfigsMap.containskey(asgnrec.AssigneeId) && permSetGrpMap.containskey(removePrevConfigsMap.get(asgnrec.AssigneeId))){
                        for(String psgId : permSetGrpMap.get(removePrevConfigsMap.get(asgnrec.AssigneeId))){
                            if(Id.valueOf(psgId) == asgnrec.PermissionSetGroupId)
                                removePermAsgnList.add(asgnrec);
                        }
                    }
                }
            }
            if(!pubGrpMap.isEmpty()){ //SAL24-647
                for(GroupMember pubgrprec : [select Id,GroupId,UserOrGroupId from GroupMember where UserOrGroupId IN: removePrevConfigsMap.keySet()]){
                    if(existingPubGrpMap.isEmpty() || !existingPubGrpMap.containskey(pubgrprec.UserOrGroupId))
                        existingPubGrpMap.put(pubgrprec.UserOrGroupId, new Set<Id>());
                    existingPubGrpMap.get(pubgrprec.UserOrGroupId).add(pubgrprec.GroupId);
                   if(removePrevConfigsMap.containskey(pubgrprec.UserOrGroupId) && pubGrpMap.containskey(removePrevConfigsMap.get(pubgrprec.UserOrGroupId))){
                       for(String pgrpId : pubGrpMap.get(removePrevConfigsMap.get(pubgrprec.UserOrGroupId))){
                           if(Id.valueOf(pgrpId) == pubgrprec.GroupId)
                               removePubGrpList.add(pubgrprec);
                       }
                    }
                }
            }
        }
        if(!userPermIdMap.isEmpty()){
            for(Id uId : userPermIdMap.keySet()){
                for(String permsetgrpId : userPermIdMap.get(uId)){
                    Id grpIdVal = Id.valueOf(permsetgrpId);
                    if(existingPermAsgnMap.isEmpty() || existingPermAsgnMap.containskey(uId) && !existingPermAsgnMap.get(uId).contains(grpIdVal)){
                        PermissionSetAssignment assignment = new PermissionSetAssignment();
                        assignment.PermissionSetGroupId = grpIdVal;
                        assignment.AssigneeId = uId;
                        permAsgnList.add(assignment);
                    }
                }
            }
        }
        if(!userLicenseIdMap.isEmpty()){
            for(PermissionSetLicenseAssign lasgnRec : [SELECT Id,AssigneeId, PermissionSetLicenseId,PermissionSetLicense.DeveloperName,PermissionSetLicense.MasterLabel from PermissionSetLicenseAssign where AssigneeId IN: userLicenseIdMap.keySet()]){
                if(existingUserLicenseMap.isEmpty() || !existingUserLicenseMap.containskey(lasgnRec.AssigneeId))
                    existingUserLicenseMap.put(lasgnRec.AssigneeId, new Set<Id>());
                existingUserLicenseMap.get(lasgnRec.AssigneeId).add(lasgnRec.PermissionSetLicenseId);
            }

            for(Id uId : userLicenseIdMap.keySet()){
                for(String licenseId : userLicenseIdMap.get(uId)){
                    Id licenseIdIdVal = Id.valueOf(licenseId);
                    if(existingUserLicenseMap.isEmpty() || (existingUserLicenseMap.containskey(uId) && !existingUserLicenseMap.get(uId).contains(licenseIdIdVal))){
                        PermissionSetLicenseAssign assignment = new PermissionSetLicenseAssign();
                        assignment.PermissionSetLicenseId = licenseIdIdVal;
                        assignment.AssigneeId = uId;
                        licenseAsgnList.add(assignment);
                    }
                }
            }
        }
       if(!pubGrpIdMap.isEmpty()){ //SAL24-647
            for(Id uId : pubGrpIdMap.keySet()){
                for(String pubGrpId : pubGrpIdMap.get(uId)){
                    Id grpIdVal = Id.valueOf(pubGrpId);
                    if(existingPubGrpMap.isEmpty() || existingPubGrpMap.containskey(uId) && !existingPubGrpMap.get(uId).contains(grpIdVal)){
                        GroupMember grpMem = new GroupMember();
                        grpMem.GroupId = grpIdVal;
                        grpMem.UserOrGroupId = uId;
                        pubGrpList.add(grpMem);
                    }
                }
            }
        }
      	if(!removePermAsgnList.isEmpty()){
            delete removePermAsgnList;
        }
        if(!removePubGrpList.isEmpty()){ //SAL24-647
            delete removePubGrpList;
        }
      	if(!licenseAsgnList.isEmpty()){
            upsert licenseAsgnList;
        }
        if(!permAsgnList.isEmpty()){
            upsert permAsgnList;
        }
        if(!pubGrpList.isEmpty()){  //SAL24-647
            upsert pubGrpList;
        }
    }*/

    /**
     * @author      : sidhant.jain@rubrik.com
     * @createdDate : May 15, 2023
     * @Description : To check if user deactivated is FMM send email alert
     * @params      : Map<Id, User> newMap, Map<Id, User> oldMap
     * @return      : void
     */
    public static void sendInactiveFMMEmail(Map<Id, User> newMap, Map<Id, User> oldMap){
        List<String> fmmIds = new List<String>();
        List<User> usersDeactivated = new List<User>();
        List<Messaging.SingleEmailMessage> messageList = new List<Messaging.SingleEmailMessage>();
        EmailTemplate emailTemplate = new EmailTemplate();
        
        for(PartnerFundRequest_CDM_FMM__mdt rec : PartnerFundRequest_CDM_FMM__mdt.getAll().values())
        {
                fmmIds.add(rec.FMM_Id__c);
        }
        
        for(User u : newMap.values()){
            String userId = String.valueOf(u.Id).substring(0, 15);
            if(u.IsPortalEnabled == false && u.IsActive == false && oldMap.get(u.Id).isActive == true
              && fmmIds.size() > 0 && (fmmIds.contains(u.Id) || fmmIds.contains(userId))){
                usersDeactivated.add(u);
            }
        }
        if(usersDeactivated.size() > 0){
            emailTemplate = [SELECT Id, BrandTemplateId, Subject, Body, Description, HtmlValue, DeveloperName  FROM EmailTemplate 
                                       WHERE DeveloperName='FMM_Inactive_Email' LIMIT 1];
            
            for(User u : usersDeactivated){
                String htmlBody = emailTemplate.Body;
                List<String> emailIdsList = Label.FMMInactiveEmails.split(';') ;
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.setTemplateID(emailTemplate.Id);
                message.setOrgWideEmailAddressId(Label.NoReplyAddressID);
                message.setTargetObjectId(u.Id);
                if(htmlBody.contains('{!User.Name}')){
                    htmlBody = htmlBody.replace('{!User.Name}', u.FirstName+' '+u.LastName);
                }
                message.setHtmlBody(htmlBody);
                message.setSubject('ALERT - FMM Inactive ' + u.FirstName+' '+u.LastName);
                message.setSaveAsActivity(false);
                message.setToAddresses(emailIdsList);
                messageList.add(message);
                
            }
        }
        if(messageList.size() > 0){
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messageList);
        }        
    }
    
     /**
    * @Author           :   Saakshi Gupta
    * @CreatedDate      :   May 23, 2023
    * @Description      :   Prepend the username with 'support.' if a support portal user is created with Rubrik email address
    * @Params           :   List<User> userRecordList
    */
    public static void setSupportPortalUsername(List<User> userRecordList){
        Set<Id> communityProfileIds = getCSPLitePortalProfileIds();
        Set<Id> userIdSet = new Set<Id>();
        for(User userInst : userRecordList){
            // Prepend the username with 'support.' if a support portal user is created with Rubrik email address
            if(communityProfileIds.contains(userInst.ProfileId) && userInst.Email.endsWithIgnoreCase('@rubrik.com') && !String.isBlank(userInst.Username) && !userInst.Username.startsWithIgnoreCase('support.')){
                userInst.Username = String.isBlank(userInst.Username) ? 'support.' + userInst.Email : 'support.' + userInst.Username;
            }
        }
    }
	
	/**
    * @Author           :   Shubham Bangad
    * @CreatedDate      :   October 26, 2023
    * @Description      :   Create PR request for Admin Access
    * @Params           :   Map<Id, User> newMap, Map<Id, User> oldMap
    */
    public static void createAdminAccessReq(Map<Id, User> newMap, Map<Id, User> oldMap){
        List<Id> userIds = new List<Id>();
        for( Id usrId : newMap.keySet()){
			if(newMap.get(usrId).UserType == 'PowerPartner' && newMap.get(usrId).Portal_Admin_Access__c && oldMap.get(usrId).Portal_Admin_Access__c != newMap.get(usrId).Portal_Admin_Access__c){
            	userIds.add(usrId);
            }
        }
        if(!userIds.isEmpty()){
        	createAdminAccessReqFuture(userIds);
        }
	}
    
    @future
    public static void createAdminAccessReqFuture(List<Id> userIds){
        Map<Id,User> userMap = new Map<Id,User>([SELECT Id, ContactId, Contact.Email, Contact.FirstName, Contact.LastName, Contact.Title, Contact.Phone FROM User WHERE Id IN : userIds]);
		for( Id usrId : userMap.keySet()){
            User usrRecord = userMap.get(usrId);
            Contact con = new Contact();
            con.Id = usrRecord.ContactId;
            con.Email = usrRecord.Contact.Email;
            con.FirstName = usrRecord.Contact.FirstName;
            con.LastName = usrRecord.Contact.LastName;
            con.Title = usrRecord.Contact.Title;
            con.Phone = usrRecord.Contact.Phone;
            PC_UserManagementApexController.updateContact(con, TRUE, FALSE);
        }
    }
	
    /**
    * @Author           :   Shubham Bangad
    * @CreatedDate      :   July 11, 2025
    * @Description      :   Update Portal Registration Request record with Related partner account and contact and mark as converted
    * @Params           :   Map<Id, User> newMap, Map<Id, User> oldMap
    */
	public static void updatePartnerRegRequest(Map<Id,User> newUserMap, Map<Id,User> oldUserMap){
        Set<String> emailSet = new Set<String>();
        Map<String,User> emailUserMap = new Map<String,User>();
        List<Partner_Registration_Request__c> partnerRegRequestList = new List<Partner_Registration_Request__c>();
        for(Id userId : newUserMap.keySet()){
            if(newUserMap.get(userId).UserType == 'PowerPartner' && 
               (newUserMap.get(userId).Profile_Name__c == 'Rubrik Partner Community Manager' || newUserMap.get(userId).Profile_Name__c == 'Rubrik Partner Community User')){
                emailUserMap.put(newUserMap.get(userId).Email,newUserMap.get(userId));
            }
        }
        
        if(!emailUserMap.isEmpty()){
        	partnerRegRequestList = [SELECT id, Email__c,is_Converted__c,Related_Partner_Contact__c,Partner_Account_Lookup__c FROM Partner_Registration_Request__c 
                                     WHERE Email__c=:emailUserMap.keySet() AND Partner_Registration_Status__c = 'Approved' AND  is_Converted__c = FALSE ORDER BY createddate DESC];
        }
        
        for(Partner_Registration_Request__c pr: partnerRegRequestList){
            if(!emailSet.contains(pr.Email__c.toLowerCase())){
                emailSet.add(pr.Email__c.toLowerCase());
                pr.is_Converted__c=true;
                pr.Related_Partner_Contact__c = emailUserMap.containsKey(pr.Email__c)?emailUserMap.get(pr.Email__c).ContactId:null;
                pr.Partner_Account_Lookup__c = emailUserMap.containsKey(pr.Email__c)?emailUserMap.get(pr.Email__c).AccountId:null;
            }
        }
        if(!partnerRegRequestList.isEmpty()){
            if(System.isFuture()){
            	update partnerRegRequestList;
            }else{
                updatePartnerRegRequestFuture(JSON.serialize(partnerRegRequestList));
            }
        }
    }
    
    @future
    public static void updatePartnerRegRequestFuture(String PRRequest){
        update (List<Partner_Registration_Request__c>)JSON.deserialize(PRRequest,List<Partner_Registration_Request__c>.class);
    }
}