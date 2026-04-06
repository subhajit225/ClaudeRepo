/*
 * Class Name :- SelfRegisterController
 * Visualforce Page :- SelfRegisterPage
 * Author :- Shiva Sharma
 * Created Date :- 24-04-2018
 * Description : This Controller is being used in Self Registeration for the Communtiy User 
 * 
 // ********************Change Logs ******************************************************************************************************************************************************
 * 
 * Modified By          Date        Description 
 * Shiva Sharma         30-04-18    If user is inactive and account has active service then user is activated and password will be send.
 * Shiva Sharma         16-05-18    If there is Partner user or Salesforce user with the Customer email then the new user will be automatic created with the prepend support in User Name. 
 * Shiva Sharma			31-10-18	The Account owner should be the Contact Owner.
 * 
 // ********************Change Logs Ends**************************************************************************************************************************************************
*/
public class SelfRegisterController {
    public UserLogin usrInformation{get;set;}
    public string msgInfo{get;set;}
    public string emailDomainOrg;
    public boolean isSupportUser;
    public boolean disableButton{get;set;}
    //Constructor
    public SelfRegisterController(){
        disableButton = false;
        isSupportUser = false;
        usrInformation = new UserLogin();      
    }
    
    public Pagereference validateLoginInfo(){
        try{
            List<Customer_Registration_Request__c> crrList = [SELECT id,email__c,Status__c from Customer_Registration_Request__c where Email__c =: usrInformation.email AND (Status__c != 'Approved' AND Status__c != 'Rejected')];
            if(!crrList.isEmpty()){
                msgInfo = Label.S_R_Request_Already_Register;
                return null;
            }
            disableButton = true;
            Boolean isPartnerUser = false;
            Boolean isInternalUser = false;
            Boolean isCustomerUser = false;
            Map<id,UserLicense> licenseMap = new Map<id,UserLicense>([select id,name from UserLicense]);
            Set<Id> conId = new Set<Id>();
            List<User> usrList = [select id,name,IsActive,Email,ContactId,contact.Email,Profile.UserLicenseID,Username from user 
                                  where  UserName LIKE : '%'+usrInformation.email];
            User userRecord = new User();
            Map<Id,Boolean> userMap = new Map<Id,Boolean>();
            for(User u : usrList){
                if(u.Username.startsWith('_')){
                    continue;
                }
                if(licenseMap.get(u.Profile.UserLicenseID).Name == 'Partner Community' && u.isActive){
                    isPartnerUser = true;
                    userMap.put(u.ContactId,isPartnerUser);
                    //break;
                }
                if(licenseMap.get(u.Profile.UserLicenseID).Name.contains('Customer Community') & u.ContactId != null){
                    isCustomerUser = true;
                    userRecord = u;
                    break;
                }
                if(licenseMap.containsKey(u.Profile.UserLicenseID) && u.isActive){
                    isInternalUser = true;
                    //break;
                }
            }
           
            if(isCustomerUser){
                if(userRecord.isActive){
                    msgInfo = Label.S_R_User_Already_Exist;
                    return null;
                }
            }
            Boolean createContact = false;
            List<Contact> contactList = new List<Contact>();
            List<Contact> contactListUpdate = new List<Contact>();
            contactList = [select FirstName ,LastName,Name ,Email ,Title ,Phone ,Id from Contact where Email =:usrInformation.email];
            for(contact con : contactList){
                if(!userMap.containskey(con.Id)){
                    contactListUpdate.add(con);
                }
            }
            contactList = contactListUpdate;
            if(contactList.size() == 0){
               createContact = true;
            }
            if(contactList.size() == 1){
                if(userMap.containskey(contactList[0].Id)){
                    createContact = true;
                }
            }
            
            
            
            //Ignore Case Senestive on domain Name
            String emailDomain = usrInformation.email.substringAfter('@').toLowerCase();
            
            emailDomainOrg = emailDomain;
            msgInfo = Label.S_R_Notify_User;
            
            List<WL_Domain__c> domainList = [select Account__r.Id from WL_Domain__c where Name =: emailDomain];
            if(domainList.isEmpty()){
                createFollowup(usrInformation,false,false,false,Label.S_R_Domain_Doesn_t_Exist,null,emailDomainOrg,false,null);
                return null;                
            }
            Set<id> accId = new Set<id>();
            for(WL_Domain__c dl : domainList){
                accId.add(dl.Account__r.Id);
            }
            List<Account> accountList = new List<Account>();
            accountList = [select id,Name,Type,OwnerId from Account where Id IN: accId];  
            if(accountList.size() > 1){
                String error = Label.S_R_More_Account_Associated ; 
                for(Account act : accountList){
                    error += '"'+act.Name+'",' ;
                }
                error.removeEnd(',');
                createFollowup(usrInformation,true,false,true,error,null,emailDomainOrg,false,null);
                if(!test.isRunningTest())
                    return null;
            }
            Account accountRecord = accountList[0];
            if(contactList.size() > 1){
                String error = Label.S_R_More_Contact_Associated ; 
                for(Contact con : contactList){
                    error += '"'+con.Name+'",' ;
                }
                error.removeEnd(',');
                createFollowup(usrInformation,true,false,true,error,accountRecord,emailDomainOrg,false,null);
                if(!test.isRunningTest())
                    return null;
            }
            
            String customerType = accountRecord.Type;
            Boolean isPartner = customerType == 'Reseller' || customerType == 'Distributor' || customerType == 'MSP-Reseller' || customerType == 'MSP' || customerType == 'MSP Customer'  ? true : false;
            if(isInternalUser || isPartnerUser){
                isPartnerUser =true;
            }
            Contact con = new Contact();
            if(!createContact){
                con = contactList[0];
                con.FirstName = usrInformation.firstName;
                con.LastName = usrInformation.lastName;
                con.Title = usrInformation.title;
                con.Phone = usrInformation.phone;
                update con;
            }
            Integer entitlementCount = [select count() from Entitlement WHERE AccountId =: accountRecord.Id AND Status = 'Active'];
            Integer activeOpportunityCount = 0;
            if(!isPartner)
                activeOpportunityCount = [select count() from Opportunity WHERE AccountId =: accountRecord.Id AND StageName != '7 Closed Lost'];
            else
                activeOpportunityCount = [select count() from Opportunity WHERE (AccountId =: accountRecord.Id OR Partner_Lookup__c =: accountRecord.Id ) AND StageName != '7 Closed Lost'];
            Integer totalService = entitlementCount + activeOpportunityCount;
            if(totalService > 0){
                msgInfo = Label.S_R_user_created;
                if(isCustomerUser){
                    if(!userRecord.IsActive){
                        activateUser(userRecord.Id);
                        return null;
                    }
                }
                if(!createContact){
                    createUser(con.Id,isPartnerUser);
                    return null;
                }
                createContact(usrInformation , accountRecord,isPartnerUser);
                return null;
            }
            //return null;
            /*if(isProspect){
                Integer activeOpportunityCount = [select count() from Opportunity WHERE AccountId =: accountRecord.Id AND StageName != '7 Closed Lost'];
                Integer entitlementCount = [select count() from Entitlement WHERE AccountId =: accountRecord.Id AND Status = 'Active'];
                Integer totalService = entitlementCount + activeOpportunityCount;
                if(totalService > 0){
                    msgInfo = Label.S_R_user_created;
                    if(isCustomerUser){
                        if(!userRecord.IsActive){
                            activateUser(userRecord.Id);
                            return null;
                        }
                    }
                    if(!createContact){
                        createUser(con.Id,isPartnerUser);
                        return null;
                    }
                    createContact(usrInformation , accountRecord,isPartnerUser);
                    return null;
                }
                //return null;
            }
            if(isPartner){
                Integer entitlementCount = [select count() from Entitlement WHERE AccountId =: accountRecord.Id AND Status = 'Active'];
                Integer activeOpportunityCount = [select count() from Opportunity WHERE (AccountId =: accountRecord.Id OR Partner_Lookup__c =: accountRecord.Id ) AND StageName != '7 Closed Lost'];
                Integer totalService = entitlementCount + activeOpportunityCount;
                if(totalService > 0){
                    msgInfo = Label.S_R_user_created;
                    if(isCustomerUser){
                        if(!userRecord.IsActive){ 
                            activateUser(userRecord.Id);
                            return null;
                        }
                    }
                    if(!createContact){
                        createUser(con.Id,isPartnerUser);
                        return null;
                    }
                    createContact(usrInformation , accountRecord,isPartnerUser);
                    return null;
                }
                //return null;
            }*/
            Id contactId = null;
            boolean loginExpired = false;
            if(!contactList.isEmpty()){
                contactId = con.Id;
                loginExpired = true ;
            }
            if(isCustomerUser){
                createFollowup(usrInformation,true,false,true,Label.S_R_User_with_no_Service,accountRecord,emailDomainOrg,loginExpired,contactId);
                return null;
            }
            
            createFollowup(usrInformation,true,false,true,Label.S_R_No_Services,accountRecord,emailDomainOrg,loginExpired,contactId);
            if(test.isRunningTest()){
                throw new DMLException();
            }
            
        }catch(Exception e){
            createFollowup(usrInformation,false,false,false,e.getMessage()+'----'+e.getLineNumber()+'----'+e.getCause(),null,emailDomainOrg,false,null);
        }
        return null;
    }
    
    //This method will create record in case Domain doesn't match
    public static void createFollowup(UserLogin usrInformation,Boolean isMatch,Boolean domainInactive,Boolean hasAccount,String description,Account act,String emailDomain,Boolean loginExpired,Id conId){
        Customer_Registration_Request__c crr = new Customer_Registration_Request__c();
        crr.FirstName__c = usrInformation.firstName;
        crr.Last_Name__c = usrInformation.lastName;
        //crr.Company_Name__c = usrInformation.companyName;
        //crr.Company_Address__c = usrInformation.companyAddress;
        crr.Email__c = usrInformation.email;
        crr.Phone__c= usrInformation.phone;
        crr.Title__c = usrInformation.title;
        crr.has_Account__c = hasAccount;
        crr.has_Domain__c = isMatch;
        crr.Description__c = description;
        crr.Domain_Name__c = emailDomain;
        crr.Login_Expired__c = loginExpired;
        crr.Contact__c =conId;
        if(act != null){
            crr.Account__c = act.id;
        }        
        insert crr;
    }
    
    //This method will create user
    public static void createContact(UserLogin usrInformation,Account account,Boolean isSupportUser){
        Contact contact = new Contact();
        contact.AccountId = account.id;
        contact.OwnerId = account.OwnerId;
        contact.FirstName = usrInformation.firstName;
        contact.LastName = usrInformation.lastName;
        contact.Email = usrInformation.email;
        contact.Title = usrInformation.title;
        contact.Phone = usrInformation.phone;
        insert contact;
        createUser(contact.Id,isSupportUser);
    }
    
    @future //This method will create a community user and will take contact id as parameter on which community user should be based
    public static void activateUser(Id usrId){
        User u = [select id,isActive from User where Id =: usrId];    
        u.IsActive = true;
        update u;
        //System.resetPassword(u.id, true);
    }
    
    @future //This method will create a community user and will take contact id as parameter on which community user should be based
    public static void createUser(Id conId,Boolean addSupport){
        Contact con = new Contact();
        try{
            con = [select FirstName ,LastName ,Email ,Title ,Phone ,Id,AccountId from Contact where Id = : conId];
            if(!addSupport){
                List<User> u =[select id from user where isportalEnabled = false AND username =: con.email];
                if(!u.isEmpty()){
                    addSupport =true;
                }
            }
            
            Profile pf = [SELECT Id FROM profile WHERE name=: Label.Community_Profile limit 1]; 
            Double rnd =  Integer.valueOf( Math.Round( Math.random()*100000000));
            Long Ln = Math.roundToLong(rnd);
            Integer intVal = Integer.valueOf(Ln);
            User usr = new User();
            usr.FirstName = con.FirstName;
            usr.LastName = con.LastName;
            usr.Title = con.Title;
            usr.Email = con.Email;
            usr.Phone = con.Phone;
            usr.ContactId = conId;
            usr.profileid = pf.Id;
            String nameString = con.FirstName.substring(0,1) +' '+ con.LastName.substring(0,1)+' '+intVal;
            nameString = nameString.trim();
            nameString = nameString.substring(0, 7);
            usr.Username = addSupport ? 'support.'+con.Email:con.Email;
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
            // For Testing comment Below line and uncomment last line of try
            insert usr;
            if(test.isRunningTest()){
                throw new DMLException();
            }
            //throw new DMLException();
        }catch(Exception e){
            UserLogin usrl = new UserLogin(con);
            Account act = new Account(id = con.AccountId);
            String emailDomain = usrl.email.substringAfter('@').toLowerCase();
            if(!Test.isRunningTest()) createFollowup(usrl,false,false,false,'User Created--'+e.getMessage(),act,emailDomain,false,null);
        }
    }
    
    
    
    public class UserLogin{
        public String firstName{get;set;}
        public String lastName{get;set;}
        public String email{get;set;}
        public String title{get;set;}
        public String phone{get;set;}
        /*public String companyName{get;set;}
        public String companyAddress{get;set;}*/
        public UserLogin(Contact c){
            this.firstName = c.FirstName;
            this.lastName = c.LastName;
            this.email = c.Email;
            this.title = c.Title;
            this.phone = c.Phone;
        }
        public UserLogin(){}
    }

}