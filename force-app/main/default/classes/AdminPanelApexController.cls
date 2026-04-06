/** 
 * @Author          : 
 * @CreatedDate     : 4/26/2019 
 * @Description     : 
 * @TestClass       : AdminPanelApexController_Test
 * -------------------------- @History -------------------------------------
 * Story Number       Modified By              Date           Description
 * CS21-1613          Vijay Kumar K R         25 Apr, 2023   Update Source Name of Admin Panel Emails
 * CS21-1839          Raveesh Layal           16 Oct, 2023   Updates for contacts visibility in support portal.
 * -------------------------------------------------------------------------
 */
public without sharing class AdminPanelApexController {

    public static Map<String,List<UserLogin>> changedUserMap = new Map<String,List<UserLogin>>();
    // CS21-1613: Fetching donotreply OWD
    public static final Id DO_NOT_REPLY_OWD_ID = [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = 'donotreply@rubrik.com' Limit 1].Id;

    @AuraEnabled
    public static AccountWrapper accountInfo(){
        Boolean isAuthorize;
        Boolean setFirstAuthorize;
        List<User> usrList = new List<User>();
        List<UserLogin> existingUsers = new List<UserLogin>();
        List<UserLogin> originalUsers = new List<UserLogin>();
        //Map<id,UserLicense> licenseMap = new Map<id,UserLicense>([select id,name from UserLicense WHERE NAME LIKE '%Customer Community%']);
        User usr = [SELECT id,contact.AccountId,isAuthorizedUser__c FROM User WHERE Id =: Userinfo.getUserId()];
        Id accountID = usr.contact.AccountId;
        Map<Id, UserLicense> licenseMap = new Map<Id, UserLicense>();
        if(!usr.isAuthorizedUser__c){
            licenseMap = new Map<id,UserLicense>([SELECT Id, Name FROM UserLicense WHERE NAME LIKE '%Customer Community%']);
            isAuthorize = false;
            usrList = [SELECT id,username,firstName,lastName,email,title,phone,isAuthorizedUser__c,isActive,contactId, Profile.UserLicenseID,contact.Created_By_Customer__c FROM User WHERE Contact.AccountId =: accountID  AND Profile.UserLicenseID IN: licenseMap.keyset() AND isAuthorizedUser__c = true];
        }else{
            licenseMap = new Map<id,UserLicense>([SELECT Id, Name FROM UserLicense WHERE NAME LIKE '%Customer Community%' OR NAME LIKE '%Partner Community%']);
            isAuthorize = true;
            usrList = [SELECT id,username,firstName,lastName,email,title,phone,isAuthorizedUser__c,isActive,contactId, Profile.UserLicenseId,contact.Created_By_Customer__c FROM User WHERE Contact.AccountId =: accountID AND Profile.UserLicenseID IN: licenseMap.keyset()];
        }
        Set<Id> conIds = new Set<Id>();
        List<String> emailList = new List<String>();
        for(User u : usrList){
            if(!(u.IsActive && (licenseMap.get(u.Profile.UserLicenseId).Name).contains('Partner Community') && u.contact.Created_By_Customer__c))
            {
                conIds.add(u.contactId);  
            }
          
            if(u.IsActive && (licenseMap.get(u.Profile.UserLicenseId).Name).contains('Customer Community')) {
                emailList.add(u.Email);
            existingUsers.add(new UserLogin(u));
            originalUsers.add(new UserLogin(u));
        }
        }

        Integer licenceRecord = existingUsers.size();
        Account act = [SELECT Id, Name, Type, Total_Number_of_Opportunities__c FROM Account WHERE Id =: accountId];
        List<Contact> contactList = [SELECT Id, firstName, LastName, Email, Title, Phone FROM Contact WHERE AccountId =: accountId AND Id NOT IN: conIds and Created_By_Customer__c=true];
        /*<Additions By: Anmol Baweja 03 Mar, 2020>*/
        /*<Reason>
            To restrict any community user to make a new user with ignored email domain as per CS-582
        </Reason>*/
        List<String> ignoredDomains = new List<String>();
        for(Ignored_Domain__mdt ignoredD : [SELECT Id, Language, isIgnored__c, Label, MasterLabel FROM Ignored_Domain__mdt WHERE isIgnored__c = true]){
            ignoredDomains.add(ignoredD.Label.toLowerCase());
        }
        return new AccountWrapper(act, licenceRecord, existingUsers, originalUsers, contactList, isAuthorize, usr, emailList, ignoredDomains);
        /*</Additions By: Anmol Baweja>*/
    }

    /////Create Contact

    @AuraEnabled
    public static string createContact(list<UserLogin> forInsert, boolean isCreateuser) {
        User usr = [SELECT id,contact.AccountId,isAuthorizedUser__c from user where id =: Userinfo.getUserId()];
        String msgInfo = '';
        try{
            msgInfo =userMethod(forInsert,usr.contact.AccountId,isCreateuser);

        }catch(Exception e){
            msgInfo = 'Please try after some time';
        }
        return msgInfo;
    }

    //Create the Contact
    @AuraEnabled
    public static Contact contact {
        get {
            if (contact == null)
                contact = new Contact(AccountId = Util.CurrentUser.Contact.AccountId);
            return contact;
        }
        set;
    }

    public static void createUser(list<Contact>contactList ) {
        list<User>usrList =new  list<User>();
        try{
            Profile pf = [SELECT Id FROM profile WHERE name=: Label.Community_Profile limit 1];
            List<User> usrUpdate = new List<User>();
            for(Contact con : contactList){
                Double rnd =  Integer.valueOf( Math.Round( Math.random()*100000000));
                Long Ln = Math.roundToLong(rnd);
                Integer intVal = Integer.valueOf(Ln);
                User usr = new User();
                usr.FirstName = con.FirstName;
                usr.LastName = con.LastName;
                usr.Title = con.Title;
                usr.Email = con.Email;
                usr.Phone = con.Phone;
                usr.ContactId = con.Id;
                usr.profileid = pf.Id;
                String nameString = con.FirstName.substring(0,1) +' '+ con.LastName.substring(0,1)+' '+intVal;
                nameString = nameString.trim();
                nameString = nameString.substring(0, 7);
                usr.Username = con.Email;
                String nickName =  con.FirstName +'.'+ con.LastName+'-'+System.now().formatGMT('MMddyy-HHmm');
                if(nickName.length() > 40){
                    nickName = con.FirstName.substring(0,1) +'.'+ con.LastName.substring(0,1)+'-'+System.now().formatGMT('MMddyy-HHmm');
                }
                usr.CommunityNickname = nickName;
                usr.Alias =  nameString;
                usr.TimeZoneSidKey = 'America/Phoenix';
                usr.LocaleSidKey = 'en_US';
                usr.EmailEncodingKey = 'ISO-8859-1';
                usr.LanguageLocaleKey = 'en_US';
                usr.ProvisionType__c = 'Admin Panel'; //added ProvisionType__c for CS21-51 - Veera
                String activeValue =  'checked';
                usrList.add(usr);
            }

            if(!usrList.isEmpty()){
                checkRecursive.AllowSupportPortalUserCreation=true; 
                insert usrList;

                List<UserLogin> usrLogin = new List<UserLogin>();
                for(User u : usrList){
                    usrLogin.add(new UserLogin(u));
                }
                changedUserMap.put('Create', usrLogin);
                sendEmailMethod('Create');
            }
            if(test.isRunningTest())
                throw new DMLException();
        }catch(Exception e){
            Customer_Registration_Request__c crr = new Customer_Registration_Request__c();
            User currentUser = [SELECT id,Contact.AccountId,contactId from user where id =: Userinfo.getUserId()];
            crr.FirstName__c = 'Admin Panel Error';
            crr.Exception__c = e.getLineNumber()+'-----'+e.getMessage();
            crr.Account__c = currentUser.Contact.AccountId;
            crr.Contact__c = currentUser.ContactId;
            crr.Description__c = JSON.serialize(usrList);
            if(!test.isRunningTest())
                insert crr;
    }
    }

    // Update User
    @AuraEnabled
    public static string UserUpdate(List<UserLogin> forUpdate2, List<UserLogin> orgUser ) {
        User usr = [SELECT id,contact.AccountId,isAuthorizedUser__c from user where id =: Userinfo.getUserId()];
        list<User> toupdate= new list<User>();
        list<UserLogin> toinform= new list<UserLogin>();
        list<Contact> updateContactList= new list<Contact>();
        Integer i = 0 ;
        for(UserLogin ul : forUpdate2){
            if(AdminPanelApexController.compareObject(ul,orgUser[i])){
                toinform.add(ul);
            }
            i++;
        }
        String retVal = 'Please update User you want to update';
        try {
            if(toinform.size() > 0){
                retVal = userMethod(toinform,usr.contact.AccountId,true);
            }

        } catch (exception ex) {
            retVal = ex.getMessage();
        }
        return retVal;
    }

    public Static boolean compareObject(UserLogin org , UserLogin upd){
        boolean isUpdate = false;
        String[] fieldsList = new List<String>{'firstName','lastName','email','title','phone','adminUser','isActive'};
            for(String field : fieldsList){
                if(org.get(field) != upd.get(field)){
                    isUpdate = true;
                    break;
                }
            }
        return isUpdate;
    }

    @AuraEnabled
    public static String contactToUser(string Id) {
        Contact con = [select FirstName,AccountId ,LastName ,Email ,Title ,Phone ,Id from Contact WHERE Id =: Id limit 1];
        UserLogin ut = new UserLogin(con);
        List<UserLogin> ul = new List<UserLogin>();
        ul.add(ut);
        String msgInfo = userMethod(ul,con.AccountId,true);
        return msgInfo == '' ? label.S_R_Request_to_add_user: msgInfo;
    }

    public static String userMethod(List<UserLogin> UserList,ID accountId, Boolean createUserCheck){
        try{
            String msgInfo = '';
            List<String> emailList = new List<String>();
            Map<String,Id> emailContactMap = new Map<String,Id>();
            Map<String,Id> emailuserMap = new Map<String,Id>();
            List<Contact> conList = new List<Contact>();
            List<String> allEmails = new List<String>();
            List<User> updateUserList = new List<User>();
            List<Contact> updateContactList = new List<Contact>();
            for(UserLogin u : UserList){
                if(u.userID == null){
                  // emailList.add('%'+u.email);
                    allEmails.add(u.email);
                }else{
                    User usr = new User();
                    usr.Id = u.userID;
                    usr.FirstName = u.firstName;
                    usr.LastName = u.lastName;
                    usr.Email = u.email;
                    usr.Title = u.title;
                    usr.Phone = u.phone;
                    usr.IsActive = u.isActive;
                    usr.isAuthorizedUser__c = u.adminUser;
                    updateUserList.add(usr);
                    Contact con = new Contact(id=u.ContactId);
                    con.FirstName = u.firstName;
                    con.LastName = u.lastName;
                    con.Email = u.email;
                    con.Title = u.title;
                    con.Phone = u.phone;
                    updateContactList.add(con);
                }
            }
            if(!updateUserList.isEmpty()){
                checkRecursive.AllowSupportPortalUserCreation=true; 
                update updateUserList;
                //update updateContactList;
                ContactUpdate(JSON.serialize(updateContactList));
                changedUserMap.put('Update', new List<UserLogin>());
                changedUserMap.get('Update').addALL(UserList);
                sendEmailMethod('Update');
                return msgInfo;
            }

            Set<ID> conIds = new Set<Id>();
            Map<String,id> usernameEmailMap = new Map<String,id>();
            Map<id,UserLicense> licenseMap = new Map<id,UserLicense>([select id,name from UserLicense]);
          
            List<User>  usrList = [select id,name,IsActive,Email,AccountId,ContactId,contact.Email,Profile.UserLicenseID,Username,IsPortalEnabled,contact.Created_By_Customer__c from user  WHERE email in:allEmails or contact.email in :allEmails order by isactive desc];
          
            Map<String,Boolean> userMap = new Map<String,Boolean>();
            Map<String,Boolean> communityUserMap = new Map<String,Boolean>();
            
            list<String> sameAccCustomerlist=new list<String>();
            list<String> sameAccPartnerlist=new list<String>();
            list<String> sameAccInactiveUserList= new list<String>();
            list<String> diffAccUserlist=new list<String>();
            
            
            List<String> portalUserContact = new List<String>();
            List<String> customerUserContact = new List<String>();
            list<string> inactivePortalUsers=new  list<String>();
            map<String,String> contactToPartner=new map<String,String>();
             map<String,String> partnerToContact=new map<String,String>();
           
            list<string> partnerUsers=new list<string>();
            for(User u: usrList){
                if(u.AccountId==Util.CurrentUser.Contact.AccountId){
                    if(u.IsActive && (licenseMap.get(u.Profile.UserLicenseId).Name).contains('Customer Community') && u.IsPortalEnabled){
                        sameAccCustomerlist.add(u.email);
                    }else if(u.IsActive && (licenseMap.get(u.Profile.UserLicenseId).Name).contains('Partner Community') && u.IsPortalEnabled){
                        sameAccPartnerlist.add(u.email);
                    }else if(!u.IsActive){
                        sameAccInactiveUserlist.add(u.email);
                    }
                }else if(u.AccountId!=Util.CurrentUser.Contact.AccountId && u.AccountId!=null){
                    diffAccUserList.add(u.email);
                }else if(!u.Isactive){
                    inactivePortalUsers.add(u.email);
                }
                
            }
            
            for(User u: usrList){
                //CS21-1839
               //Display an error message when a customer attempts to add an inactive user.
                     
                          if(sameAccCustomerlist.contains(u.email)){
                              
                              if(u.contact.email!=u.email && allEmails.contains(u.contact.email) )
                              {
                                  return u.contact.email+'This user already exist with "'+u.email+'" email.';
                              }
                                return u.email+label.Manage_Colleague_Same_Acc_Error; 
                            }
                        else if(sameAccPartnerlist.contains(u.email) && !sameAccCustomerlist.contains(u.email))
                             {
                                 partnerToContact.put(u.email,u.contact.email);
                                 if(allemails.contains(u.contact.email))
                                 {
                                     partnerUsers.add(u.contact.email);
                                 }
                                 else{
                                     partnerUsers.add(u.email);
                                 }
                                
                                 contactToPartner.put(u.contact.email,u.email);
                                
                             }
                          else if(sameAccInactiveUserlist.contains(u.email) && !sameAccPartnerlist.contains(u.email) && !sameAccCustomerlist.contains(u.email) )
                               { 
                                  if(u.contact.email!=u.email && allemails.contains(u.contact.email) )
                                   {
                                      return u.contact.email+label.User_is_Inactive_Error;
                                    }
                                      return u.email+label.User_is_Inactive_Error;
                               }  
                           else if(diffAccUserList.contains(u.email)&& !sameAccInactiveUserlist.contains(u.email) && !sameAccPartnerlist.contains(u.email) && !sameAccCustomerlist.contains(u.email) ){
                                
                                if(u.contact.email!=u.email && allemails.contains(u.contact.email) )
                              {
                                  return u.contact.email+label.Different_Account_Error;
                              }
                                return u.email+label.Different_Account_Error;
                               }
                               else if(inactivePortalUsers.contains(u.email) && !diffAccUserList.contains(u.email)&& !sameAccInactiveUserlist.contains(u.email) && !sameAccPartnerlist.contains(u.email) && !sameAccCustomerlist.contains(u.email) ){
                                return u.email+label.User_is_Inactive_Error;
                           
                               }
                         
                      
                if(u.contactid!=null)
                {

                if(u.Username.startsWith('_')){
                    continue;
                }
                if(licenseMap.get(u.Profile.UserLicenseID).Name == 'Partner Community' && u.contact.Email != null){
                    if(u.AccountId != accountID){
                        portalUserContact.add(u.contact.Email.toLowerCase());
                    }

                    userMap.put(u.contact.Email.toLowerCase(),true);
                    conIds.add(u.ContactId);
                }
                if(licenseMap.get(u.Profile.UserLicenseID).Name.contains('Customer Community') && u.IsActive){
                    if(u.AccountId != accountID){
                        customerUserContact.add(u.contact.Email.toLowerCase());
                    }
                    communityUserMap.put(u.contact.Email.toLowerCase(),true);
                    usernameEmailMap.put(u.contact.Email.toLowerCase(),u.id);
                }
                     
                }
                    
                }
            

            Map<String,String> alreadyAccountMap = new Map <String,String>();
            list<String> sameAccountEmails=new list<String>();
            list<String> differentAccountEmails=new list<String>();
            Map<String,Contact> contactMap = new Map <String,Contact>();
            list<String> internalContact=new list<String>();
            list<String> alreadyContactList=new list<String>();
            for(Contact con : [Select id,FirstName,LastName,Title,Phone,Email,AccountId,Created_By_Customer__c,User_Profile__c from Contact where Email IN: allEmails or email in: partnerToContact.values() order by User_Profile__c desc]){
                if(con.AccountId  == accountId)
                {
                    if(String.isBlank(con.User_Profile__c)){

                        if(contactMap.containskey(con.email.toLowerCase()))
                        {
                            contactMap.remove(con.email.toLowerCase());
                        }
                        if(partnerToContact.containskey(con.email))
                        {
                            alreadyContactList.add(partnerToContact.get(con.email));
                        }else if(contactToPartner.containskey(con.email))
                        {
                            alreadyContactList.add(contactToPartner.get(con.email));
                        }
                        internalContact.add(con.email);
                        contactMap.put(con.Email.toLowerCase(), con); 
                    }
                    else if( partnerUsers!=null && partnerUsers.size()>0 && !alreadyContactList.contains(con.email) && !internalContact.contains(con.email))
                    {
                        if( partnerUsers.contains(con.email)){
                            contactMap.put(con.Email.toLowerCase(), con);  
                         }else {
                             contactMap.put(contactToPartner.get(con.Email).toLowerCase(), con);  
                               }
                    }
                       
                     
                     sameAccountEmails.Add(con.Email);
                }  
                else{
                    alreadyAccountMap.put(con.Email.toLowerCase(), con.AccountId +'#ref'+con.Id);
                    differentAccountEmails.add(con.Email);
                }
            }
            Set<Id> contactId = new Set<Id>();
            List<Contact> contactList = new List<Contact>();
            List<Contact> contactUpdateList = new List<Contact>();
            List<String> ignoredDomainsList = new List<String>();
            for(UserLogin ul : UserList){ 
                if(alreadyAccountMap.containsKey(ul.email.toLowerCase()) && !(sameAccountEmails.contains(ul.email) && differentAccountEmails.contains(ul.Email)) ){
                         //CS21-1839 removed the Customer_Registration_Request__c insertion.
                          String alreadyExistEmail=ul.email+system.label.Different_Account_Error;
                          // return ul.email; 
                          return alreadyExistEmail;
                   
                }else{
                   
                    Contact con = new Contact();
                    if(!customerUserContact.contains(ul.email.toLowerCase()) && communityUserMap.containsKey(ul.email.toLowerCase())){
                    }else if((!portalUserContact.contains(ul.email.toLowerCase()) && contactMap.containsKey(ul.email.toLowerCase())   && !partnerUsers.contains(ul.email)) || 
                             (partnerUsers.contains(ul.email) && !createUserCheck && !internalContact.contains(ul.email)) || 
                             (internalContact.contains(ul.email))){
                                 
                        con = contactMap.get(ul.email.toLowerCase());
                          
                        if(con.Created_By_Customer__c!=true || (con.Created_By_Customer__c==true && createUserCheck==true )){
                        con.FirstName = ul.firstName;
                        con.LastName = ul.lastName;
                        con.Email = ul.email;
                        con.Title = ul.title;
                        con.Phone = ul.phone;
                        con.Created_By_Customer__c=true;
                        contactUpdateList.add(con);
                        contactId.add(con.id); 
                           
                       }
                       else{
                         return ul.email+system.label.Contact_already_exists_Error;
                      }
                                         
                    }else{
                        con.AccountId = accountId;
                        con.FirstName = ul.firstName;
                        con.LastName = ul.lastName;
                        con.Email = ul.email;
                        con.Title = ul.title;
                        con.Phone = ul.phone;
                        if(createUserCheck){
                           con.User_Profile__c='Rubrik Customer Community Super Login User';  
                        }
                        con.Created_By_Customer__c=true;
                        contactList.add(con);
                    }
                }
            }

            if(!contactList.isEmpty())
            {
                insert contactList;}
            if(!contactUpdateList.isEmpty())
                update contactUpdateList;
            for(Contact con : contactList){
                contactId.add(con.id);
            }
            if(!contactId.isEmpty() && createUserCheck){
                msgInfo = label.S_R_User_Created_shortly;
                createUserFuture(contactId,accountId);
            }
            else{
                msgInfo = label.S_R_Contact_created_without_user;
            }
            return msgInfo;
        }
        catch(DMLException ex){
            return ex.getDmlMessage(0);
        }
        catch(Exception e){
            return 'exception : '+e.getMessage() ;
        }
    }

    @future //This method will create a community user and will take contact id as parameter on which community user should be based
    public static void ContactUpdate(String contactrecord){
        update (List<Contact>)JSON.deserialize(contactrecord, List<Contact>.class);
    }

    @future //This method will create a community user and will take contact id as parameter on which community user should be based
    public static void createUserFuture(Set<id> contactIdList,Id accountId){
        List<User> usrList = new List<User>();
        List<UserLogin> usrLogin = new List<UserLogin>();
        try{
            List<Contact> conList = [select FirstName ,LastName ,Email ,Title ,Phone ,Id from Contact where Id = : contactIdList];
            List<String> emailList = new List<String>();
            List<String> allemailList = new List<String>();
            for(Contact con : conList){
                emailList.add('%'+con.Email);
            }
            Map<id,UserLicense> licenseMap = new Map<id,UserLicense>([select id,name from UserLicense]);
            Profile pf = [SELECT Id FROM profile WHERE name=: Label.Community_Profile limit 1];
            Map<String,User> userMap = new Map<String,User>();
            for(User u : [select id,name,IsActive,ContactId,contact.Email,Profile.UserLicenseID from user where email IN: emailList ]){
                if(licenseMap.get(u.Profile.UserLicenseID).Name.contains('Customer Community') && u.contact.Email != null){
                    userMap.put(u.contact.Email.toLowerCase(), u);
                }
            }
            Map<String,Boolean> mapAddSupport = new Map<String,Boolean>();
            for(User u :[select id,email from user where username =: emailList]){
                mapAddSupport.put(u.Email.toLowerCase(),true);
            }

            List<User> usrUpdate = new List<User>();
            for(Contact con : conList){
                Double rnd =  Integer.valueOf( Math.Round( Math.random()*100000000));
                Long Ln = Math.roundToLong(rnd);
                Integer intVal = Integer.valueOf(Ln);
                User usr = new User();
                usr.FirstName = con.FirstName;
                usr.LastName = con.LastName;
                usr.Title = con.Title;
                usr.Email = con.Email;
                usr.Phone = con.Phone;
                usr.ContactId = con.Id;
                usr.profileid = pf.Id;
                String nameString = con.FirstName.substring(0,1) +' '+ con.LastName.substring(0,1)+' '+intVal;
                nameString = nameString.trim();
                nameString = nameString.substring(0, 7);
                usr.Username = mapAddSupport.containsKey(con.Email.toLowerCase()) ? 'support.'+con.Email:con.Email;
                String nickName =  con.FirstName +'.'+ con.LastName+'-'+System.now().formatGMT('MMddyy-HHmm');
                if(nickName.length() > 40){
                    nickName = con.FirstName.substring(0,1) +'.'+ con.LastName.substring(0,1)+'-'+System.now().formatGMT('MMddyy-HHmm');
                }
                usr.CommunityNickname = nickName;
                usr.Alias =  nameString;
                usr.TimeZoneSidKey = 'America/Phoenix';
                usr.LocaleSidKey = 'en_US';
                usr.EmailEncodingKey = 'ISO-8859-1';
                usr.LanguageLocaleKey = 'en_US';
                usr.ProvisionType__c = 'Admin Panel'; //added ProvisionType__c for CS21-51 - Veera
                String activeValue =  'checked';
                usrList.add(usr);
            }
            if(!usrList.isEmpty()){
                checkRecursive.AllowSupportPortalUserCreation=true; 
                insert usrList;
                // Send Email to Admin

                for(User u : usrList){
                    usrLogin.add(new UserLogin(u));
                }
                changedUserMap.put('Create', new List<UserLogin>());
                changedUserMap.get('Create').addALL(usrLogin);
                sendEmailMethod('Create');
            }
            if(test.isRunningTest())
                throw new DMLException();
        }catch(Exception e){
            Customer_Registration_Request__c crr = new Customer_Registration_Request__c();
            User currentUser = [SELECT id,Contact.AccountId,contactId from user where id =: Userinfo.getUserId()];
            crr.FirstName__c = 'Admin Panel Error';
            crr.Exception__c = e.getLineNumber()+'-----'+e.getMessage();
            crr.Account__c = currentUser.Contact.AccountId;
            crr.Contact__c = currentUser.ContactId;
            crr.Description__c = JSON.serialize(usrList);
            if(!test.isRunningTest())   insert crr;
        }
    }

    //Send Email
    public static void sendEmailMethod(String methodName){
        try{
            String templateName = methodName == 'Update' ? Label.Community_Update_Template : Label.Community_Creation_Template;
            ID templateId = [SELECT id from EmailTemplate where Name =: templateName LIMIT 1].ID;
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTargetObjectID(Userinfo.getUserId());
            mail.setTemplateID(templateId);
            mail.setSaveAsActivity(false);
            // CS21-1613: from address updated as "donotreply@rubrik.com"
            mail.setOrgWideEmailAddressId(DO_NOT_REPLY_OWD_ID);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }catch(exception e){
            System.assert(false,e.getMessage());
        }
    }

    @AuraEnabled
    public static void requestAccess(list<UserLogin>reqAccess){
        string msgInfo= '';
        try{
            ID templateId = [SELECT id from EmailTemplate where Name = 'Request Authorize Access' LIMIT 1].ID;
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            List<String> toAddresses = new List<String>();
            for(Userlogin u : reqAccess){
                if(u.adminUser)
                    toAddresses.add(u.userID);
            }
            mail.setToAddresses(toAddresses);
            mail.setTargetObjectID(Userinfo.getUserId());
            mail.setTreatTargetObjectAsRecipient(false);
            mail.setTemplateID(templateId);
            mail.setSaveAsActivity(false);
            // CS21-1613: from address updated as "donotreply@rubrik.com"
            mail.setOrgWideEmailAddressId(DO_NOT_REPLY_OWD_ID);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            msgInfo = label.Community_Authorized_Request_Label;
        }catch(Exception e){
            msgInfo = 'Please try after some time' + e.getMessage();
        }
    }

    @AuraEnabled
    public static User user {
        get {
            if (user == null)
                user = new user();
            return User;
        }
        set;
    }

    public class AccountWrapper{
        @AuraEnabled public String accountId{get;set;}
        @AuraEnabled public String accName{get;set;}
        @AuraEnabled public Integer licenceUsed{get;set;}
        @AuraEnabled public String accType{get;set;}
        @AuraEnabled public Integer totalOpenOpportunities{get;set;}
        @AuraEnabled public Boolean isAuthorize{get;set;}
        @AuraEnabled public List<Contact> contactList{get;set;}
        @AuraEnabled public List<UserLogin> existingUsers{get;set;}
        @AuraEnabled public List<UserLogin> originalUsers{get;set;}
        @AuraEnabled public List<UserLogin> newContact{get;set;}
        @AuraEnabled public UserLogin simpleContact{get;set;}
        @AuraEnabled public User CurrentUsers{get;set;}
        @AuraEnabled public List<String> existingEmails{get;set;}
        @AuraEnabled public List<String> ignoredDomainList{get;set;}
        public AccountWrapper(Account act , Integer licenceRecord , List<UserLogin> existingUsers,  List<UserLogin> originalUsers  , List<Contact> contactList,Boolean isAuthorize, User CrntUsers ,List<String> existingEmails,List<String> ignoredDomainList){
            this.accountId = act.Id;
            this.accName = act.Name;
            this.licenceUsed =  licenceRecord;
            this.accType = act.Type;
            this.totalOpenOpportunities = (integer)act.Total_Number_of_Opportunities__c;
            this.contactList = contactList;
            this.existingUsers = existingUsers;
            this.originalUsers = originalUsers;
            this.isAuthorize = isAuthorize;
            this.CurrentUsers= CrntUsers;
            this.simpleContact = new UserLogin();
            this.newContact = new List<UserLogin>();
            this.newContact.add(new UserLogin());
            this.existingEmails = existingEmails;
            this.ignoredDomainList = ignoredDomainList;
        }
    }

    public class UserLogin{
        @AuraEnabled public String firstName{get;set;}
        @AuraEnabled public String lastName{get;set;}
        @AuraEnabled public String email{get;set;}
        @AuraEnabled public String title{get;set;}
        @AuraEnabled public String phone{get;set;}
        @AuraEnabled public String userID{get;set;}
        @AuraEnabled public String contactId{get;set;}
        @AuraEnabled public boolean adminUser{get;set;}
        @AuraEnabled public boolean isActive{get;set;}
        @AuraEnabled public boolean hasError{get;set;}
        @AuraEnabled public boolean supportPortalLogin{get;set;}
        @AuraEnabled public String errorMessage{get;set;}
        public UserLogin(User u){
            this.firstName = u.firstName;
            this.lastName = u.lastName;
            this.email = u.email;
            this.title = u.title;
            this.phone = u.phone;
            this.userID = u.Id;
            this.adminUser = u.isAuthorizedUser__c;
            this.isActive = u.isActive;
            this.contactId = u.contactId;
            this.hasError = false;
        }
        public UserLogin(UserLogin u){
            this.firstName = u.firstName;
            this.lastName = u.lastName;
            this.email = u.email;
            this.title = u.title;
            this.phone = u.phone;
            this.userID = u.userID;
            this.adminUser = u.adminUser;
            this.isActive = u.isActive;
            this.errorMessage = '';
        }
        public UserLogin(Contact con){
            this.firstName = con.firstName;
            this.lastName = con.lastName;
            this.email = con.email;
            this.title = con.title;
            this.phone = con.phone;
            this.errorMessage = '';
        }
        public Object get(String fName){
            if(fName == 'firstName'){
                String returnString = this.firstName == '' || this.firstName == null ? null : this.firstName;
                return returnString;
            }else if(fName == 'lastName'){
                String returnString = this.lastName == '' || this.lastName == null ? null : this.lastName;
                return returnString;
            }else if(fName == 'email'){
                String returnString = this.email == '' || this.email == null ? null : this.email;
                return returnString;
            }else if(fName == 'title'){
                String returnString = this.title == '' || this.title == null ? null : this.title;
                return returnString;
            }else if(fName == 'phone'){
                String returnString = this.phone == '' || this.phone == null ? null : this.phone;
                return returnString;
            }else if(fName == 'isActive'){
                return this.isActive;
            }else if(fName == 'adminUser'){
                return this.adminUser;
            }
            return this;
        }
        public UserLogin(){
            this.supportPortalLogin = true;
            this.firstName = '';
            this.lastName = '';
            this.email = '';
            this.title = '';
            this.phone = '';
            this.errorMessage = '';
        }
    }
}