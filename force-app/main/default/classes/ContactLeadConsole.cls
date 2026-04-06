/**
 * @description ContactLeadConsole class provides methods for retrieving and managing Contact and Lead records within a console environment.
 * It includes functionalities to fetch records based on user profiles, assign follow-up tasks, update record statuses, and manage ownership.
 */
public class ContactLeadConsole {
    /**
     * @description Retrieves the name of the currently logged-in user's profile.
     * @return The name of the user's profile.
     */
    @AuraEnabled
    public static string getProfileName () {
        Id profileId=userinfo.getProfileId(); 
        String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
        return profileName;
    }
    
    /**
     * @description Retrieves a list of Contact records based on various display and filtering criteria.
     * This method supports displaying contacts based on MQL status, all contacts, or a manager's view,
     * and can filter by account status and fit score.
     * @param displayRecordBy Specifies how records should be displayed (e.g., 'MQL', 'All', 'Manager View').
     * @param fitScoremap A map of string to decimal for fit scores (currently unused in the provided code logic).
     * @param filterLowScoredRecordsFromView A boolean indicating whether to filter out low-scored records (currently unused in the provided code logic).
     * @param accountStatus Filters contacts by their associated account's routing status. Use 'None' to not filter by account status.
     * @return A response_Wrapper object containing Contact records, picklist options, opportunity list, SDR users, profile name,
     * and other relevant data for the console.
     */
    @AuraEnabled
    public static response_Wrapper getAccountContacts (String displayRecordBy, map<String,Decimal> fitScoremap,Boolean filterLowScoredRecordsFromView, String accountStatus) {  
        Id profileId=userinfo.getProfileId(); 
        String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
        
        list<string> contactIdToQuery = new list<string>();
        // Added Login to display manager view for Manager if role contain SDR Manager  for MKT22-74.. //
        // Added Login to display manager view for Manager if role contain SDR Manager  for MKT22-74.. //
        User  userRecord=[Select Id,Name,UserroleId,Userrole.Name from user where Id=:UserInfo.getUserId()];
        
        set<String> MQLCampaignType = new set<String>{'Call Out Day','Intent Data','Meeting Maker Outbound','Lead Share Program'};
        Id loginUserId = UserInfo.getUserId();
        List<Contact> contacts = new List<Contact>();

        Set<Id> setOfAccountIds = getAcccountIdsForPLSUser();
		
        String baseQuery = 'SELECT Id, Title, Account_Routing_Status__c, Priority_Date__c,LastActivityDate,MQL_Campaign_Type__c, OwnerId, Owner.Name, AccountId, Account.Name,Account.Owner.Name, Account.Account_Status__c, '+
            +'Account.Type, Name, Contact_Follow_Up_Status__c, Contact_Fit_Score__c, Follow_up_Requested_Date__c, Last_MQL_Date__c, '+
            +'Last_Follow_Up_Activity_Date__c, Contact_Status__c, Account.Account_Tier__c,Account_Tier__c, '+
            +'(SELECT Id, Status, CampaignId, Campaign.Name, Campaign.GTM_Play__c, Campaign.Campaign_Theme__c, Campaign.Type, Campaign.createdDate,FCRM__FCR_Response_Date__c, campaign.Always_On__c,campaign.IsActive from CampaignMembers ORDER BY campaign.createdDate Desc NULLS FIRST),'+
            +'(SELECT Id, CreatedDate, LastModifiedDate, WhoId, Who.Name, Subject, ActivityDate, Owner.Name FROM Events WHERE isChild = false ORDER BY LastModifiedDate Desc NULLS FIRST),'+
            +'(SELECT Id, CreatedDate, LastModifiedDate, Who.Name, Subject, ActivityDate, Owner.Name FROM Tasks ORDER BY LastModifiedDate Desc NULLS FIRST) '+
            +'FROM Contact '+
            +'WHERE AccountId != null '
            +'AND Contact_Status__C != \'Nurture\' '+
            +'And MQL_Campaign_Type__c NOT IN :MQLCampaignType '+
            +'AND (Campaign_Sourced_By__c = \'Marketing\' OR Campaign_Sourced_By__c = null) ';
        
        if(accountStatus != 'None'){
            baseQuery += 'AND Account_Routing_Status__c =: accountStatus ';
        }
        
        if(displayRecordBy == 'MQL'){
            baseQuery += 'AND (OwnerId =: loginUserId OR Account.OwnerId =: loginUserId';
            if(setOfAccountIds.size() > 0){
                baseQuery += ' OR AccountId IN: setOfAccountIds';
            }
            baseQuery += ') AND MQL__c = TRUE '+
                +'AND Partner_MQL__c = FALSE ';
        }
        else if(displayRecordBy == 'All') {
            baseQuery += 'AND (OwnerId =: loginUserId OR Account.OwnerId =: loginUserId';
            if(setOfAccountIds.size() > 0){
                baseQuery += ' OR AccountId IN: setOfAccountIds';
            }
            baseQuery +=  ')';
        } 
        else if(displayRecordBy == 'Manager View') {
            baseQuery += 'AND (OwnerManagerID__c =: loginUserId';
            if(setOfAccountIds.size() > 0){
                baseQuery += ' OR AccountId IN: setOfAccountIds';
            }
            baseQuery  += ') AND MQL__c = TRUE '+
                +'AND Partner_MQL__c = FALSE ';
        }
        
        
        baseQuery += 'ORDER BY Priority_Date__c  DESC NULLS LAST LIMIT 5000 '; 
        
        contacts = Database.query(baseQuery);
		
        List<Id> accIds= new List<Id>();
        Map<Id, List<Id>> mapAccIdWithContacts = new Map<Id, List<Id>>();
        for(Contact conRec : contacts){ 
            accIds.add(conRec.AccountId);
            if(!mapAccIdWithContacts.containsKey(conRec.AccountId))
                mapAccIdWithContacts.put(conRec.AccountId, new List<Id>());
            
            mapAccIdWithContacts.get(conRec.AccountId).add(conRec.Id);
        }
        
        Map<String,List<picklistOptions>> picklistNameValueList = new Map<String,List<picklistOptions>>();
        
        picklistNameValueList.put('Campaign',getPicklistValues('Campaign','GTM_Play__c', false));
        
        List<Opportunity> oppForContactList = new List<Opportunity>();     
        oppForContactList = [select id, Initial_Contacts_Name__c from Opportunity where Initial_Contacts_Name__c IN: contacts AND StageName !='7 Closed Won' AND StageName !='7 Closed Lost' AND StageName !='7 Closed Admin'];
        response_Wrapper territoryData = getTerritoryUsersForAccount(accIds, mapAccIdWithContacts);
        response_Wrapper response = new response_Wrapper();
        response.contactRecords = contacts;
        response.pickListOptns = picklistNameValueList;
        response.oppList = oppForContactList;
        response.sdrUsers = territoryData.sdrUsers;
        response.profileName = profileName;
        response.recordIdsWithPendingTaskForCurrentUser = contactIdToQuery;
        response.contactWithTerritoryUsers = territoryData.contactWithTerritoryUsers;
          // Added Login to display manager view for Manager if role contain SDR Manager  for MKT22-74 ...//
        if(userRecord != null && userRecord.UserroleId !=null)
            response.isManager=userRecord.Userrole.Name.contains('SDR Manager');


        return response;
    }
    
    /**
     * @description Retrieves territory users associated with a list of Account IDs and a map of Account IDs to Contact IDs.
     * This method identifies SDRs (Sales Development Representatives) within the active territories linked to the provided accounts.
     * @param accIds A list of Account IDs for which to retrieve territory users.
     * @param mapAccIdWithContacts A map where keys are Account IDs and values are lists of Contact IDs associated with those accounts.
     * @return A response_Wrapper object containing a list of SDR users and a map of Contact IDs to a set of associated territory user IDs.
     */
    public static response_Wrapper getTerritoryUsersForAccount (List<Id> accIds, Map<Id, List<Id>> mapAccIdWithContacts) {
    	 List<ObjectTerritory2Association> objTerritoryList= new List<ObjectTerritory2Association>();
        
        objTerritoryList= [SELECT AssociationCause,Id,IsDeleted,LastModifiedById,LastModifiedDate,ObjectId,SobjectType,SystemModstamp,Territory2Id, Territory2.Name 
            FROM ObjectTerritory2Association WHERE ObjectId IN: accIds AND Territory2.Territory2Model.State = 'Active'];
        Set<Id> territoryIdSet = new Set<Id>();
        Map<Id, List<Id>> objIdwithTerritory = new Map<Id, List<Id>>();
        Map<Id, List<Id>> territoryIdWithUserId = new Map<Id, List<Id>>();
        Map<Id, set<Id>> mapContactIdWithTerritoryUsers = new Map<Id, set<Id>>();
        for(ObjectTerritory2Association obj: objTerritoryList){
            territoryIdSet.add(obj.Territory2Id);
            for(id conId : mapAccIdWithContacts.get(obj.ObjectId)){
                if(!objIdwithTerritory.containsKey(conId))
                    objIdwithTerritory.put(conId, new List<Id>());
                
                objIdwithTerritory.get(conId).add(obj.Territory2Id);
            }

        }
        List<UserTerritory2Association> userTerritoryList = [SELECT Id,IsActive,Territory2Id,UserId, user.name 
                                                         FROM UserTerritory2Association WHERE RoleInTerritory2 = 'SDR' AND Territory2Id IN: territoryIdSet ];
        for(UserTerritory2Association userTerritory: userTerritoryList){
            if(userTerritory.UserId != null)
                if(!territoryIdWithUserId.containsKey(userTerritory.Territory2Id))
                    territoryIdWithUserId.put(userTerritory.Territory2Id, new List<Id>());
                
                territoryIdWithUserId.get(userTerritory.Territory2Id).add(userTerritory.UserId);
        }
        for(id contactId: objIdwithTerritory.keySet()){
            for(id territoryId: objIdwithTerritory.get(contactId)){
                if(!mapContactIdWithTerritoryUsers.containsKey(contactId))
                    mapContactIdWithTerritoryUsers.put(contactId, new set<Id>());
                if(territoryIdWithUserId.get(territoryId) != null)
                	mapContactIdWithTerritoryUsers.get(contactId).addAll(territoryIdWithUserId.get(territoryId));
            }
        }
        response_Wrapper response = new response_Wrapper();
     
        response.sdrUsers = userTerritoryList;
        response.contactWithTerritoryUsers = mapContactIdWithTerritoryUsers;
        return response;
    }

    /**
     * @description Retrieves a list of Lead records and associated campaign data based on various display and filtering criteria.
     * This method supports displaying leads based on MQL status, all leads, or a manager's view,
     * and can filter by account status. It also populates picklist options for campaigns and determines if the current user is a manager.
     * @param userId The ID of the user whose leads are to be retrieved. If empty, the current user's ID is used.
     * @param displayRecordBy Specifies how records should be displayed (e.g., 'MQL', 'All', 'Manager View').
     * @param fitScoremap A map of string to decimal for fit scores (currently unused in the provided code logic).
     * @param filterLowScoredRecordsFromView A boolean indicating whether to filter out low-scored records (currently unused in the provided code logic).
     * @param accountStatus Filters leads by their associated account's routing status. Use 'None' to not filter by account status.
     * @return A response_Wrapper object containing Lead records, picklist options, SDR users, profile name,
     * and other relevant data for the console.
     */
    @AuraEnabled
    public static response_Wrapper getLeadAccountCampaigns (string userId,String displayRecordBy,map<String,Decimal> fitScoremap, Boolean filterLowScoredRecordsFromView, String accountStatus) { 
                Id profileId=userinfo.getProfileId();
        String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
          // Added Login to display manager view for Manager if role contain SDR Manager  for MKT22-74 //
        User  userRecord=[Select Id,Name,UserroleId,Userrole.Name from user where Id=:UserInfo.getUserId()];

        list<string> statusSDRList = new list<string>{ 'Open' , 'Open - Reengaged' , 'Working', 'Meeting Set' , 'Meeting Attended', 'Prospecting', 'Contacted/Future Follow Up' };
        list<string> statusAEList = new list<string>{   };    
        list<string> statusToInclude =  new list<string>();
        ShGl_DisableFunctionalityLogic__c disabledFunctionality = ShGl_DisableFunctionalityLogic__c.getInstance();
		 
              if(profileName == 'Rubrik Inside Sales' || profileName=='Rubrik Renewal Specialist' || profileName == 'Rubrik Field Sales User' || profileName == 'Alliance partner'){
            statusToInclude = statusSDRList;
                
            }/*else if(profileName == 'Rubrik Field Sales User'){
                statusToInclude = statusSDRList;
            }*/      

        Set<Id> setOfAccountIds = getAcccountIdsForPLSUser();
        List<Lead> leads = new List<Lead>();
        string usrId = UserInfo.getUserId();
        if(!string.IsEmpty(userId))
            usrId = userId;
        set<String> MQLCampaignType = new set<String>{'Call Out Day','Intent Data','Meeting Maker Outbound','Lead Share Program'};
          // Added Parameter for MKT22-66 and 68 JIRA for new Display Logic//
        String loginUserId = UserInfo.getUserId();
        
        String baseQuery = 'SELECT Id, Title, Account_Routing_Status__c, Priority_Date__c, LastActivityDate,MQL_Campaign_Type__c, Name, Status, Company, Owner.name, L2A_Account__c, L2A_Account__r.Account_Status__c, Last_MQL_Date__c, '+
            +'L2A_Confidence_Code__c, Lead_FIT_Score1__c, L2A_Account__r.Name, L2A_Account__r.owner.Name, L2AAccountTier__c, Account_Status__c,'+
            +'(SELECT Id, Status, CreatedDate, CampaignId, Campaign.Name, Campaign.GTM_Play__c, Campaign.Campaign_Theme__c, Campaign.Type, Campaign.createdDate, Campaign.Always_On__c, Campaign.IsActive FROM CampaignMembers ORDER BY Campaign.CreatedDate DESC NULLS FIRST),'+
            +'(SELECT Id, Createddate, LastModifiedDate, Who.Name, Subject, ActivityDate, Owner.Name FROM Events WHERE isChild = FALSE ORDER BY LastModifiedDate DESC NULLS FIRST),'+
            +'(SELECT Id, CreatedDate, LastModifiedDate, Who.Name, Subject, ActivityDate, Owner.Name from Tasks ORDER BY LastModifiedDate DESC NULLS FIRST) '+
            +'FROM Lead '+
            +'WHERE Status IN: statusToInclude '+
            +'AND IsConverted = FALSE '+
            +'AND (Campaign_Sourced_By__c = \'Marketing\' OR Campaign_Sourced_By__c = null) '+
            +'And MQL_Campaign_Type__c NOT IN :MQLCampaignType ';
         
        if(accountStatus != 'None' ){
            baseQuery += 'AND Account_Routing_Status__c =: accountStatus ';
        }
        
        //MKT25-309

        if(displayRecordBy == 'MQL'){
            baseQuery += 'AND (OwnerId =: usrId OR (L2A_Account__r.OwnerId =: usrId AND L2A_Confidence_Code__c >=3)';
            if(setOfAccountIds.size() > 0){
                baseQuery += ' OR L2A_Account__c IN: setOfAccountIds';
            }
            baseQuery +=  ') AND MQL__c = True '
                +'AND Partner_MQL__c = False ';
        }
        else if(displayRecordBy == 'All'){
            baseQuery += 'AND (OwnerId =: usrId OR (L2A_Account__r.OwnerId =: usrId AND L2A_Confidence_Code__c >=3) ';
            if(setOfAccountIds.size() > 0){
                baseQuery += ' OR L2A_Account__c IN: setOfAccountIds';
            }
            baseQuery +=  ')';
        }
        else if(displayRecordBy == 'Manager View'){
            baseQuery += 'AND (L2A_Confidence_Code__c >=3 AND OwnerManagerID__c =:usrId';
            if(setOfAccountIds.size() > 0){
            	baseQuery += ' OR L2A_Account__c IN: setOfAccountIds';
            }
            baseQuery += ') AND MQL__c = True '
                +'AND Partner_MQL__c = False ';
        }
       
         baseQuery += 'ORDER BY Priority_Date__c  DESC NULLS LAST,Last_MQL_Date__c DESC NULLS LAST LIMIT 5000 ';
        
        leads = Database.query(baseQuery);
        
        Map<String,List<picklistOptions>> picklistNameValueList = new Map<String,List<picklistOptions>>();
        
        picklistNameValueList.put('Campaign',getPicklistValues('Campaign','GTM_Play__c', false));
        
        List<Opportunity> oppForContactList = new List<Opportunity>();   
        List<UserTerritory2Association> territoryForLoggedInUser = [SELECT Id,IsActive,Territory2Id,UserId, user.name 
                                                         FROM UserTerritory2Association WHERE RoleInTerritory2 = 'Account Executive' AND UserId =: UserInfo.getUserId() ];
        List<string> territoryId = new List<string>();
        for(UserTerritory2Association ut: territoryForLoggedInUser){
            territoryId.add(ut.Territory2Id);
        }
        List<UserTerritory2Association> territoryForSDRUser = [SELECT Id,IsActive,Territory2Id,UserId, user.name 
                                                         FROM UserTerritory2Association WHERE RoleInTerritory2 = 'SDR' AND Territory2Id IN: territoryId ];
        territoryForSDRUser.addAll(territoryForLoggedInUser);
        response_Wrapper response = new response_Wrapper();
        response.leadRecords = leads;
        response.pickListOptns = picklistNameValueList;
        response.profileName = profileName;
        response.sdrUsers = territoryForSDRUser; 
   
        // Added Login to display manager view for Manager if role contain SDR Manager  for MKT22-74 //
        if(userRecord != null && userRecord.UserroleId !=null)
            response.isManager=userRecord.Userrole.Name.contains('SDR Manager');
        Boolean hasPermissionEnableImportSalesloftButton = FeatureManagement.checkPermission('Enable_Import_to_Salesloft_Button');
        if(disabledFunctionality.EnableImporttoSalesloftButton__c || hasPermissionEnableImportSalesloftButton){
            response.EnableImporttoSalesloftButton=true;
        }



        //response.oppList = oppForContactList;
        return response;
    }
    
    /**
     * @description Assigns a follow-up task to a specified user for a list of contacts and updates the contact's follow-up status.
     * It also sends an email notification.
     * @param contactIds A comma-separated string of Contact IDs to assign the task to.
     * @param comment The description/comment for the follow-up task.
     * @param usrId The ID of the user to whom the follow-up task will be assigned.
     * @return A response_Wrapper indicating success or failure, and the updated contact records.
     */
    @AuraEnabled
    public static response_Wrapper assignFollowUpTask (String contactIds, String comment, string usrId) { 
        response_Wrapper response = new response_Wrapper();
        
        try{
            User sdrUser =  [select id, IsActive from user where id=: usrId];
            if(!sdrUser.IsActive){
                response.isSuccess = false;
                response.errorMessage ='Selected User is inactive';
                return response;
            }
        
            List<Task> followUpTasks = new List<Task>();
            List<Contact> relatedContacts = new List<Contact>();
            
            List<String> contactIdsList = contactIds.split(',');
            
            for(String recId : contactIdsList){ 
                contact ContactRec = new Contact(id= recId, Follow_up_Requested_Date__c = Date.today(), Contact_Follow_Up_Status__c = 'Follow up Required', OwnerId = usrId);
                relatedContacts.add(ContactRec);
                Task tsk = new Task();
                tsk.Subject = 'Follow up Request';
                tsk.WhoId = recId;
                tsk.ActivityDate = Date.today();
                //This is the default...
                tsk.OwnerId = usrId;
                tsk.Status = 'Not Started';
                tsk.Type = 'General Followup';
                tsk.Priority = 'Normal';
                tsk.Description = comment;
                followUpTasks.add(tsk);
            }
            if(!followUpTasks.isEmpty() && !relatedContacts.isEmpty()){
                insert followUpTasks;
                
                sendMailOnTask(followUpTasks, 'AE_Manually_Assigns_to_SDR',false);
                ShGl_DisableFunctionalityLogic__c cs = ShGl_DisableFunctionalityLogic__c.getInstance(userinfo.getProfileId());
                boolean isCustomSettingUpdated = false; 
                if(cs != null && !cs.Allow_Contact_Transfer__c){
                    isCustomSettingUpdated = true;
                    cs.Allow_Contact_Transfer__c = true;
                    update cs;
                }
                update relatedContacts;
                if(cs != null && isCustomSettingUpdated){
                    cs.Allow_Contact_Transfer__c = false;
                    update cs;
                }
            }
            List<Contact> contacts = new List<Contact>();
            contacts = [select id,Title,LastActivityDate, Owner.name,AccountId, Account.name,Account.Account_Status__c, Account.Type, Name, 
                        Contact_Follow_Up_Status__c,Follow_up_Requested_Date__c, Last_Follow_Up_Activity_Date__c,
                        (select id, status, campaignid,campaign.Name,campaign.GTM_Play__c, campaign.Campaign_Theme__c, campaign.Type,campaign.createdDate from CampaignMembers ORDER BY campaign.createdDate Desc NULLS FIRST),
                        (select id, createddate,LastModifiedDate from events ORDER BY LastModifiedDate Desc NULLS FIRST), (select id, createdDate, LastModifiedDate from tasks ORDER BY LastModifiedDate Desc NULLS FIRST) from contact 
                        WHERE Id IN: contactIdsList ];
            //response_Wrapper response = getAccountContacts();
            response.contactRecords =  contacts;
        } catch(DmlException e) {
            response.isSuccess = false;
            response.errorMessage = e.getMessage();
        }
        return response;
    }
    
    /**
     * @description Updates the status of one or more Lead records, optionally including a rejection reason or an account to convert to.
     * @param leadIds A comma-separated string of Lead IDs to update.
     * @param status The new status to set for the leads.
     * @param rejectReason The reason for rejecting the lead (optional).
     * @param AccounttoConvert The ID of the account to convert the lead to (optional).
     * @return A response_Wrapper indicating success or failure of the update operation.
     */
    @AuraEnabled 
    public static response_Wrapper updateLeadStatus (String leadIds, string status,String rejectReason,String AccounttoConvert) {
        response_Wrapper response = new response_Wrapper();
        try{
            List<String> leadIdsList = leadIds.split(',');
            List<lead> relatedleads = new List<lead>();
            for(String recId : leadIdsList){ 
                lead leadRec = new lead();
                leadRec.id = recId;
                leadRec.status = status;
                if(rejectReason !=null)
                leadRec.Lead_Rejection_Reason__c=rejectReason;
                if(AccounttoConvert !=null)
                leadRec.AccountToConvert__c=AccounttoConvert;
                relatedleads.add(leadRec);
            }
            update relatedleads;
        } catch(DmlException e) {
            response.isSuccess = false;
            response.errorMessage = e.getMessage();
        }
        return response;
    }
    
    /**
     * @description Updates the owner of one or more Lead records. If no owner ID is provided and userType is 'Queue',
     * it attempts to assign the lead to the 'Inbound' queue.
     * @param leadIds A comma-separated string of Lead IDs to update.
     * @param userType Specifies the type of owner ('User' or 'Queue').
     * @param ownerId The ID of the new owner (User or Queue). If null and userType is 'Queue', defaults to 'Inbound' queue.
     * @return A response_Wrapper indicating success or failure of the owner update operation.
     */
    @AuraEnabled 
    public static response_Wrapper updateLeadOwnerAction(String leadIds, string userType,String ownerId ) {
        response_Wrapper response = new response_Wrapper();
        try{
            if(leadIds !=''){

                List<String> leadIdsList = leadIds.split(',');
                List<lead> updateownerleads = new List<lead>();
                String setOwnerId ='';

            
            
                if(ownerId == null && 'Queue' == userType) {
                    List<Group> defaultQueue = [Select id,Name from group where type ='Queue' and Name ='Inbound' Limit 1];
                    if(defaultQueue.size()>0)
                    	setOwnerId=defaultQueue[0].Id;
                    
                } else {
                    setOwnerId=ownerId;
                }
                for(String recId : leadIdsList){ 
                    lead leadRec = new lead(); 
                    leadRec.id = recId;

                    leadRec.ownerid = setOwnerId;
                    updateownerleads.add(leadRec);
                }
                update updateownerleads;
         		
        	}   

        }

        catch(DmlException e) {
            response.isSuccess = false;
            response.errorMessage = e.getMessage();
        }
        return response;
    }

    /**
     * @description Updates the status of one or more Contact records, optionally including a rejection reason.
     * @param contactIds A comma-separated string of Contact IDs to update.
     * @param status The new status to set for the contacts.
     * @param contactrejectreason The reason for rejecting the contact (optional).
     * @return A response_Wrapper indicating success or failure of the update operation.
     */
    @AuraEnabled 
    public static response_Wrapper updateContactStatus (String contactIds, string status,string contactrejectreason) {
        response_Wrapper response = new response_Wrapper();
        try{
            List<String> contactIdsList = contactIds.split(',');
            List<contact> relatedContacts = new List<contact>();
            for(String recId : contactIdsList){ 
                contact contactRec = new contact();
                contactRec.id = recId;
                contactRec.Contact_Status__c = status;
                /*if(status =='Nurture')
               		contactRec.ContactRejectReason__c='Sales Future Follow-up';*/ 
                contactRec.ContactRejectReason__c = contactrejectreason;
                relatedContacts.add(contactRec);
            }
            update relatedContacts;
        } catch(DmlException e) {
            response.isSuccess = false;
            response.errorMessage = e.getMessage();
        }
        return response;
    }
    
    /**
     * @description Retrieves picklist values for a specified field on a given object.
     * @param object_name The API name of the object.
     * @param field_name The API name of the field.
     * @param addNoneValue A boolean indicating whether to include a '--None--' option at the beginning of the list.
     * @return A list of picklistOptions, where each option contains a label and a value.
     */
    public static List<picklistOptions> getPicklistValues(String object_name, String field_name, Boolean addNoneValue) {
        List<picklistOptions> values = new List<picklistOptions>();
        
        if(addNoneValue){
            values.add( new picklistOptions('--None--' , ''));
        }
        
        String[] types = new String[]{object_name};
            Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);
        for(Schema.DescribeSobjectResult res : results) {
            for (Schema.PicklistEntry entry : res.fields.getMap().get(field_name).getDescribe().getPicklistValues()) {
                if (entry.isActive()) {
                    values.add( new picklistOptions(entry.getLabel() , entry.getValue()));
                }
            }
        }
        
        return values;
    }
    
    /**
     * @description A wrapper class to encapsulate various data returned by the Apex methods for Lightning components.
     */
    public class response_Wrapper {
        @auraEnabled public List<Contact> contactRecords{get;set;}
        @auraEnabled public List<Lead> leadRecords{get;set;}
        @auraEnabled public Map<String,List<picklistOptions>> pickListOptns{get;set;}
        @auraEnabled public List<Opportunity> oppList{get;set;}
        @auraEnabled public List<UserTerritory2Association> sdrUsers{get;set;}
        @auraEnabled public List<id> recordIdsWithPendingTaskForCurrentUser{get;set;}
        @auraEnabled public String profileName{get;set;}
        @auraEnabled public Map<Id, set<Id>> contactWithTerritoryUsers {get;set;}
        @auraEnabled public boolean isSuccess{get;set;}
        @auraEnabled public string errorMessage  {get;set;}
        @auraEnabled public boolean isManager {get;set;}
        @auraEnabled public boolean EnableImporttoSalesloftButton {get;set;}
        
        public response_Wrapper(){
            this.isSuccess = true;
            this.errorMessage = '';
            this.isManager = false;
            this.EnableImporttoSalesloftButton=false;
            this.contactRecords = new List<Contact>();
            this.leadRecords = new List<lead>();
            this.pickListOptns = new Map<String,List<picklistOptions>>();
            this.oppList = new List<Opportunity>();
            this.sdrUsers = new List<UserTerritory2Association>(); 
            this.recordIdsWithPendingTaskForCurrentUser = new List<id>();
            this.contactWithTerritoryUsers = new Map<Id, set<Id>>();
        }
        
    }
    
    /**
     * @description Sends an email notification related to a task, using a specified email template.
     * Optionally includes the contact owner in CC if 'sendcc' is true and the task owner is different from the contact owner.
     * @param taskList A list of Task records for which to send email notifications.
     * @param templateName The Developer Name of the Email Template to be used.
     * @param sendcc A boolean indicating whether to CC the contact owner on the email.
     */
    public static void sendMailOnTask(List<Task> taskList, string templateName, boolean sendcc){
        Map<string, String> taskWithContact = new Map<string, String>();
        Map<string, String> taskWithOwner = new Map<string, String>();
        for(Task taskRecord : taskList){
            taskWithContact.put(taskRecord.id, taskRecord.WhoId);
            taskWithOwner.put(taskRecord.id, taskRecord.ownerId);
        }
        Map<id,Contact> idContactMap = new Map<id,Contact>();
        if(sendcc)
            idContactMap = new Map<ID, Contact>([select id, ownerid from contact where id IN: taskWithContact.values()]);
       
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        EmailTemplate et=[Select id from EmailTemplate where developername=: templateName];
        for(Task taskRecord : taskList){
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                if(sendcc && idContactMap.get(taskRecord.WhoId)!=null && taskRecord.ownerId != idContactMap.get(taskRecord.WhoId).ownerid  ){
                    List<Id> ccTo = new List<Id>();
                    ccTo.add(idContactMap.get(taskRecord.WhoId).ownerid);
                    mail.setCcAddresses(ccTo);
                }
                mail.setTargetObjectId(taskRecord.OwnerId);
                mail.setTemplateId(et.id);
                mail.setwhatId(taskRecord.WhoId);
                mail.setSaveAsActivity(false);
                
                mail.setSenderDisplayName('Rubrik Support');
                mail.setSaveAsActivity(false); 
                mails.add(mail);
 
        }
        if(!Test.isRunningTest() && !mails.isEmpty()){
        	Messaging.sendEmail(mails);
        }
    }
    
    /**
     * @description Reassigns an existing 'Follow up Request' task for a given Contact to an SDR (Sales Development Representative)
     * associated with the Contact's account territory. Also updates the Contact's owner and sends an email notification.
     * This method is designed to be invoked from a Flow or Process Builder.
     * @param ContactId A list containing the ID of the Contact for whom the task needs to be reassigned.
     */
    @InvocableMethod
    public static void reAssignTask(List<Id> ContactId){
       Contact conRecord =  new Contact( );
       conRecord = [Select id, AccountId,ownerId,Account.Account_Status__c, Account.Name, Account.RecordType.Name, Contact_Follow_Up_Status__c from Contact where id =:ContactId[0] Limit 1];
       if(conRecord.Account.Account_Status__c != 'Existing Customer' || conRecord.Contact_Follow_Up_Status__c =='Follow up completed' ) return;
       List<ObjectTerritory2Association> objTerritoryList= new List<ObjectTerritory2Association>();
        
        objTerritoryList= [SELECT AssociationCause,Id,IsDeleted,LastModifiedById,LastModifiedDate,ObjectId,SobjectType,SystemModstamp,Territory2Id, Territory2.Name 
            FROM ObjectTerritory2Association WHERE ObjectId=:conRecord.AccountId AND Territory2.Territory2Model.State = 'Active'];        
       
        List<UserTerritory2Association> userTerritoryList = [SELECT Id,IsActive,LastModifiedById,LastModifiedDate,RoleInTerritory2,SystemModstamp,Territory2Id,UserId 
                                                         FROM UserTerritory2Association WHERE RoleInTerritory2 = 'SDR' AND Territory2Id =: objTerritoryList[0].Territory2Id ];
        if(!userTerritoryList.isEmpty()){
            List<Task> taskList = [select Id,OwnerId,whoId,whatId,Subject,ActivityDate,Priority,Status From Task 
                                   where WhoId=: conRecord.Id AND Subject = 'Follow up Request' AND OwnerId =: conRecord.ownerId AND Status = 'Not Started'];
            for(task taskRec : taskList){
                string AEId = taskRec.OwnerId;
                taskRec.Task_Assigned_from_AE__c = AEId;
                taskRec.OwnerId = userTerritoryList[0].UserId;
                conRecord.OwnerId = userTerritoryList[0].UserId;
            }
            if(!taskList.isEmpty()){
                update taskList;
                sendMailOnTask(taskList, 'AE_assigns_a_follow_up_to_an_SDR', true);
                
                ShGl_DisableFunctionalityLogic__c cs = ShGl_DisableFunctionalityLogic__c.getInstance(userinfo.getProfileId());
                boolean isCustomSettingUpdated = false; 
                if(cs != null && !cs.Allow_contact_Transfer__c){
                    isCustomSettingUpdated = true;
                    cs.Allow_contact_Transfer__c = true;
                    update cs;
                }
                update conRecord;
                if(cs != null && isCustomSettingUpdated){
                    cs.Allow_contact_Transfer__c = false;
                    update cs;
                }
            }
                                  
        }
       
    }
    
    /**
     * @description Retrieves a set of Account IDs for the currently logged-in PLS (Partner Led Sales) user.
     * This identifies accounts where the user has either a 'SaaS AE' or 'NAS AE' role in an active territory model.
     * @return A set of Account IDs associated with the PLS user.
     */
    public static Set<Id> getAcccountIdsForPLSUser(){
        //Query the user territory and check if they have a role of PLS user in the active territory model
        Id loggedInUserId = UserInfo.getUserId();
        Set<Id> setOfTerritoryIds = new Set<Id>();        
        for(UserTerritory2Association ut : [SELECT Id, Territory2Id, UserId FROM UserTerritory2Association WHERE (RoleInTerritory2 ='SaaS AE' OR RoleInTerritory2 ='NAS AE') AND UserId =: loggedInUserId AND Territory2.Territory2Model.State = 'Active']){
            setOfTerritoryIds.add(ut.Territory2Id);
        }
         
        //if(user is PLS AE
        //prepare a set by query accounts where the user is in the ETM 
         
        Set<Id> setOfAccountIds = new Set<Id>();
        if(!setOfTerritoryIds.isEmpty()){
            for(ObjectTerritory2Association ota : [SELECT Id, ObjectId, SobjectType FROM ObjectTerritory2Association WHERE Territory2Id IN: setOfTerritoryIds]){
                if(ota.SobjectType == 'Account'){
                   setOfAccountIds.add(ota.ObjectId); 
                }
            }
        }
        return setOfAccountIds;
    }
    
    /**
     * @description A class to represent a single picklist option, containing a label and a value.
     */
    public class picklistOptions{
        @auraEnabled public String label;
        @auraEnabled public String value;
        
        /**
         * @description Constructor for the picklistOptions class.
         * @param label The display label for the picklist option.
         * @param value The API value for the picklist option.
         */
        public picklistOptions(String label, String value ){
            this.label = label;
            this.value = value;
        }
    }     
}