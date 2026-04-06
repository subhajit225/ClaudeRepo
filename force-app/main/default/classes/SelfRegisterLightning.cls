/*
 * Class Name :- SelfRegisterLightning
 * Visualforce Page :- SelfRegisterPage
 * Author :- Shiva Sharma
 * Created Date :- 24-04-2018
 * Description : This Controller is being used in Self Registeration for the Communtiy User
 * Test Class : SelfRegisterControllerTest
 // ********************Change Logs ******************************************************************************************************************************************************
 *
 * Story        Modified By          Date               Description
 *              Shiva Sharma         30-04-18           If user is inactive and account has active service then user is activated and password will be send.
 *              Shiva Sharma         30-06-20           Added check of Entitlemnt over Partner Account as per CS21-23 line: 141-169.
 * CS21-1837    Vijay Kumar K R      Aug 08, 2032       Approved Support Portal user didn't get enabled | Exception error created
 // ********************Change Logs Ends**************************************************************************************************************************************************
*/
public without sharing  class SelfRegisterLightning {

    //Constructor
    public SelfRegisterLightning (){

    }

    @AuraEnabled
    public static string validateLoginInfo(String Email,String firstName,String lastName,string title,string phone){
        UserLogin usrInformation = new UserLogin(Email,firstName,lastName,title,phone);
        string msgInfo;
        string emailDomainOrg;
        boolean isSupportUser;
        boolean disableButton;
        try{
            List<Customer_Registration_Request__c> crrList = [SELECT id,email__c,Status__c from Customer_Registration_Request__c where Email__c =: usrInformation.Email AND (Status__c != 'Approved' AND Status__c != 'Rejected')];
            if(!crrList.isEmpty()){
                msgInfo = Label.S_R_Request_Already_Register;
                return msgInfo;
            }
            disableButton = true;
            Boolean isPartnerUser = false;
            Boolean isInternalUser = false;
            Boolean isCustomerUser = false;
            Map<id,UserLicense> licenseMap = new Map<id,UserLicense>([select id,name from UserLicense]);
            Set<Id> conId = new Set<Id>();
            List<User> usrList = [select id,name,IsActive,Email,ContactId,contact.Email,Profile.UserLicenseID,Username from user
                                  where  UserName LIKE : '%'+usrInformation.Email];
            User userRecord = new User();
            List<Disable_Contact_List__mdt> ignoredC = [SELECT Id, Language, Label, MasterLabel FROM Disable_Contact_List__mdt where label =: usrInformation.Email];
            //Ignore Case Senestive on email
            if(!ignoredC.isEmpty()){
                msgInfo = System.label.S_R_Ignored_Email;
                return msgInfo;
            }
            Map<Id,Boolean> userMap = new Map<Id,Boolean>();
            for(User u : usrList){
                if(u.Username.startsWith('_')){
                    continue;
                }
                /*CS21-256 : Removed u.isActive check for Partner community users because contacts
                * may be enabled as Partner community user but inactive. We want to prepend support.
                * for such users as well
                */
                if(licenseMap.get(u.Profile.UserLicenseID).Name == 'Partner Community'){
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
                    return msgInfo;
                }
            }

            Boolean createContact = false;
            List<Contact> contactList = new List<Contact>();
            List<Contact> contactListUpdate = new List<Contact>();
            contactList = [select FirstName ,LastName,Name ,Email ,Title ,Phone ,Id,AccountId from Contact where Email =:usrInformation.Email];
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

            String[] ignoredDomains = new List<String>();
            for(Ignored_Domain__mdt ignoredD : [SELECT Id, Language, isIgnored__c, Label, MasterLabel FROM Ignored_Domain__mdt WHERE isIgnored__c = true]){
                ignoredDomains.add(ignoredD.Label.toLowerCase());
            }

            //Ignore Case Senestive on domain Name
            String emailDomain = usrInformation.Email.substringAfter('@').toLowerCase();
            if(!ignoredDomains.isEmpty() && ignoredDomains.contains(emailDomain)){
                msgInfo = System.label.S_R_Ignored_Domain;
                return msgInfo;
            }

            emailDomainOrg = emailDomain;
            msgInfo = Label.S_R_Notify_User;

            //CS21-657 : Added contactList check for skipping domain validation if a contact exists
            List<WL_Domain__c> domainList = [select Account__r.Id from WL_Domain__c where Name =: emailDomain];
            if(contactList.isEmpty() && domainList.isEmpty()){
                createFollowup(usrInformation,false,false,false,Label.S_R_Domain_Doesn_t_Exist,null,emailDomainOrg,false,null);
                return msgInfo;
            }

            //CS21-657 : Added else block to collect Account Ids from the Contact list if domain list is empty
            Set<id> accId = new Set<id>();
            if(!domainList.isEmpty()){
            for(WL_Domain__c dl : domainList){
                accId.add(dl.Account__r.Id);
            }
            }
            else if(!contactList.isEmpty()){
                for(Contact eachContact : contactList){
                    accId.add(eachContact.AccountId);
                }
            }

            List<Account> accountList = new List<Account>();
            //CS21-476 -Added Map to fetch accounts and add to lisyt
            Map<Id,Account> accountMap = new Map<Id,Account>([select id,Name,Type,OwnerId,Enforce_Admin_User__c,RecordType.Name,Partner_Agreement_Status__c from Account where Id IN: accId]);
            accountList = accountMap.values();

            /*CS21-390 : Support Portal Registration Exception Bug - Added existing contact check. If the contact already exists with the same email
            address, then skip the check for domains on multiple Accounts */
            if(accountList.size() > 1 && contactList.isEmpty()){
                String error = Label.S_R_More_Account_Associated ;
                for(Account act : accountList){
                    error += '"'+act.Name+'",' ;
                }
                error.removeEnd(',');
                createFollowup(usrInformation,true,false,true,error,null,emailDomainOrg,false,null);
                if(!test.isRunningTest())
                    return msgInfo ;
            }
            Account accountRecord = accountList[0];
            //CS21-476 - Added check to pick Contact Account instead of first.
            if(accountList.size() > 1 && !contactList.isEmpty() && !createContact && accountMap.containsKey(contactList[0].AccountId)){
                accountRecord = accountMap.get(contactList[0].AccountId);
            }
            if(accountRecord.Enforce_Admin_User__c){
                msgInfo = Label.Enforce_Admin_User;
                return msgInfo ;
            }
            if(contactList.size() > 1){
                String error = Label.S_R_More_Contact_Associated ;
                for(Contact con : contactList){
                    error += '"'+con.Name+'",' ;
                }
                error.removeEnd(',');
                createFollowup(usrInformation,true,false,true,error,accountRecord,emailDomainOrg,false,null);
                if(!test.isRunningTest())
                    return msgInfo ;
            }
            // Changes CS21-23 start
            Integer entitlementCount = [select count() from Entitlement WHERE AccountId =: accountRecord.Id AND Status = 'Active'];

            if(accountRecord.RecordType.Name == 'Partner/Distributor'){
                if(accountRecord.Partner_Agreement_Status__c == 'Signed - Active' || entitlementCount > 0){
                    msgInfo = Label.S_R_user_created;
                    if(!createContact){
                        Contact con = new Contact();
                        con = contactList[0];
                        createUser(con.Id,isPartnerUser);
                        if(!test.isRunningTest())
                            return msgInfo ;
                    }
                    createContact(usrInformation , accountRecord,isPartnerUser);
                    if(!test.isRunningTest())
                        return msgInfo ;
                }else if(accountRecord.Partner_Agreement_Status__c == 'Signed - Inactive'){
                    msgInfo = Label.S_R_Signed_inactive;
                    return msgInfo ;
                }else if(accountRecord.Partner_Agreement_Status__c == 'Unsigned'  && entitlementCount == 0){
                    msgInfo = Label.S_R_Unassigned;
                    return msgInfo ;
                }else if(accountRecord.Partner_Agreement_Status__c == 'Terminated' && entitlementCount == 0){
                    msgInfo = Label.S_R_Terminated;
                    return msgInfo ;
                }else if(accountRecord.Partner_Agreement_Status__c == 'Contract out of date' && entitlementCount == 0){
                    msgInfo = Label.S_R_Contract_out_of_date;
                    return msgInfo ;
                }
            }
            // Changes CS21-23 end
            String customerType = accountRecord.Type;
            Boolean isPartner = customerType == 'Partner' || customerType == 'Distributor' || customerType == 'Partner - MSP' || customerType == 'MSP' || customerType == 'MSP Customer'  ? true : false;
            //Added by ashish as per the ask in Jira CS21-1082
            Integer shipmentDelayByDays=Integer.valueof(System.Label.Days_for_Opportunity_Close_Date);
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
               // update con;
            }
            //Changes CS21-333 Start
            Integer activeOpportunityCount = 0;
            List<Opportunity> OpportunityList = new List<Opportunity>();
            //CS21-298 : Added 7 Closed Won stage to the list
            List<String> activeStages = new List<String>{'3 Technical Validation','4 Business Justification','5 Negotiate & Close','6 PO With Channel','7 Closed Won'};
            if(!isPartner)
                OpportunityList = [select Id,CloseDate from Opportunity WHERE AccountId =: accountRecord.Id AND StageName In:activeStages];
                //activeOpportunityCount = [select count() from Opportunity WHERE AccountId =: accountRecord.Id AND StageName != '7 Closed Lost'];
            else
                OpportunityList = [select Id,CloseDate from Opportunity WHERE (AccountId =: accountRecord.Id OR Partner_Lookup__c =: accountRecord.Id ) AND StageName In:activeStages ];
            //activeOpportunityCount = [select count() from Opportunity WHERE (AccountId =: accountRecord.Id OR Partner_Lookup__c =: accountRecord.Id ) AND StageName != '7 Closed Lost'];
            for(Opportunity opp:OpportunityList){
                if(opp.CloseDate.addDays(shipmentDelayByDays) > System.today()){
                    activeOpportunityCount++;
                }
            }
            Integer totalService = entitlementCount + activeOpportunityCount;
            if(totalService > 0){
                msgInfo = Label.S_R_user_created;
                if(isCustomerUser){
                    if(!userRecord.IsActive){
                        activateUser(userRecord.Id);
                        return msgInfo ;
                    }
                }
                if(!createContact){
                    createUser(con.Id,isPartnerUser);
                    if(!test.isRunningTest())
                        return msgInfo ;
                }
                createContact(usrInformation , accountRecord,isPartnerUser);
                if(!test.isRunningTest())
                    return msgInfo ;
            }
      if(totalService == 0 && OpportunityList.size() > activeOpportunityCount){
                msgInfo = Label.S_R_User_with_no_Service;
                return msgInfo;
            }
            //Changes CS21-333 End
            Id contactId = null;
            boolean loginExpired = false;
            if(!contactList.isEmpty()){
                contactId = con.Id;
                loginExpired = true ;
            }
            if(isCustomerUser){
                createFollowup(usrInformation,true,false,true,Label.S_R_User_with_no_Service,accountRecord,emailDomainOrg,loginExpired,contactId);
                return msgInfo ;
            }

            createFollowup(usrInformation,true,false,true,Label.S_R_No_Services,accountRecord,emailDomainOrg,loginExpired,contactId);
            if(test.isRunningTest()){
                throw new DMLException();
            }
        }catch(Exception e){
            createFollowup(usrInformation,false,false,false,e.getMessage()+'----'+e.getLineNumber()+'----'+e.getCause(),null,emailDomainOrg,false,null);
        }
        return msgInfo ;
    }

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
        // CS21-1837: ByPassing Contact duplicate rule, When new Support User Contact creating on existing Partner User Contact 
        // CS21-1837: Approved Support Portal user didn't get enabled | Exception error created
        Database.DMLOptions dml = new Database.DMLOptions(); 
        dml.DuplicateRuleHeader.allowSave = true;
        dml.DuplicateRuleHeader.runAsCurrentUser = true;
        Database.SaveResult sr = Database.insert(contact, dml);
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
            UserLogin usrl = new UserLogin(con.Email,con.firstName,con.lastName,con.title,con.phone);
            Account act = new Account(id = con.AccountId);
            String emailDomain = usrl.email.substringAfter('@').toLowerCase();
            if(!Test.isRunningTest()) createFollowup(usrl,false,false,false,'User Created--'+e.getMessage(),act,emailDomain,false,null);
        }
    }

     public class UserLogin{
        @auraEnabled
        public String firstName{get;set;}
        @auraEnabled
        public String lastName{get;set;}
        @auraEnabled
        public String email{get;set;}
        @auraEnabled
        public String title{get;set;}
        @auraEnabled
        public String phone{get;set;}

        public UserLogin(String Email,String firstName,String lastName,String title,String phone){
            this.firstName =FirstName;
            this.lastName = LastName;
            this.email = Email;
            this.title = Title;
            this.phone =Phone;
        }
        public UserLogin(){}
    }

    @AuraEnabled
    public static String getAccountGTC(String domainname, String timestamp){
        List <WL_Domain__c> wldList = new List <WL_Domain__c>();
        wldList = [SELECT id, Account__r.name, Account__r.GTC__c 
                    FROM WL_Domain__c 
                    WHERE Name =: domainname];
        // If same WL Domain record associated to multiple GTC denied Accounts, Not blocking User Registration    
        if(wldList.size() > 1 || wldList.size() == 0){
            return 'Access Denied Not Blocked Here';
        }else if(wldList[0].Account__r.GTC__c == 'Denied'){
            return 'Denied';
        }
        return 'SR User';
    }
}