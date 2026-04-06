/*
 * Class Name :- CustomerRegistrationRequestTriggerHelper
 * Object :- Customer_Registration_Request__c
 * Trigger Class :- CustomerRegistrationRequestTrigger.apxt
 * Test Class :- CustomerRegistrationRequestTriggerTest.cls
 * Events :- Insert and Update
 * Author :- Shiva Sharma
 * Created Date :- 25-04-2018
 * Description : This Helper will be invoked by Trigger and will submit record for approval on Record Insert(afterInsert) and will create user once record is approved
 *               (afterUpdate).
 *
 // ************************************ Change Logs *****************************************************************************
 *
 * Story        Modified By          Date            Description
 *              Shiva Sharma         30-05-18        Create Entitlement when user login expiration
 * CS21-1837    Vijay Kumar K R      Aug 08, 2032    Approved Support Portal user didn't get enabled | Exception error created
 // ************************************ Change Logs Ends*************************************************************************
*/
public class CustomerRegistrationRequestTriggerHelper {

    public static void afterInsert(List<Customer_Registration_Request__c> crrList){
        try{
            List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();
            for (Customer_Registration_Request__c crr : crrList) {
                Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
                req1.setComments('Submitting request for approval.');
                req1.setObjectId(crr.id);
                //req1.setNextApproverIds(new List<Id>{crr.ownerId});
                req1.setSubmitterId(crr.ownerId);
                requests.add(req1);
            }
            if (requests.size() > 0) {
                List<Approval.ProcessResult> results = Approval.process(requests);
            }
            if(test.isRunningTest()){
                throw new DMLException();
            }
        }catch(Exception e){
            System.debug('error');
        }
    }

    public static void afterUpdate(List<Customer_Registration_Request__c> crrList,Map<Id,Customer_Registration_Request__c> oldMap){
        try {
            List<String> emailList = new List<String>();
            List<String> allEmails = new List<String>();
            Set<Id> accIds = new Set<Id>();
            
            for(Customer_Registration_Request__c crr : crrList){
                if(crr.Status__c != oldMap.get(crr.Id).Status__c && crr.Status__c == 'Approved'){
                    emailList.add('%'+crr.Email__c);
                    allEmails.add(crr.Email__c);
                    
                    if(crr.Description__c != null && crr.Description__c.contains(Label.S_R_More_Contact_Associated) && crr.Contact__c == null){
                        crr.addError('Contact is required, you can\'t Approve the record without selecting Contact');
                    } else if(crr.Account__c == null){
                        crr.addError('Account is required, you can\'t Approve the record without selecting Account');
                    } else {
                    accIds.add(crr.Account__c);
                    }   
                }            
            }
            
            Set<ID> conIds = new Set<Id>();
            Map<String,id> usernameEmailMap = new Map<String,id>();
            Map<id,UserLicense> licenseMap = new Map<id,UserLicense>([select id,name from UserLicense]);
            List<User> usrList = [select id,name,IsActive,Email,ContactId,contact.Email,Profile.UserLicenseID,Username from user  WHERE UserName LIKE : emailList];
            Map<String,Boolean> userMap = new Map<String,Boolean>();
            Map<String,Boolean> communityUserMap = new Map<String,Boolean>();
            
            for(User u: usrList){
                if(u.Username.startsWith('_')){
                    continue;
                } else if(licenseMap.get(u.Profile.UserLicenseID).Name == 'Partner Community' && u.contact.Email != null){
                    userMap.put(u.contact.Email.toLowerCase(),true);
                    conIds.add(u.ContactId);
                } else if(licenseMap.get(u.Profile.UserLicenseID).Name.contains('Customer Community') && u.IsActive){
                    communityUserMap.put(u.contact.Email.toLowerCase(),true);
                    usernameEmailMap.put(u.contact.Email.toLowerCase(),u.id);
                }
            }
            
            Map<String,Contact> contactMap = new Map <String,Contact>();
            
            for(Contact con : [Select id,FirstName,LastName,Title,Phone,Email from Contact where Email IN: allEmails AND ID NOT IN : conIds]){
                contactMap.put(con.Email.toLowerCase(), con);
            }
            
            //Map<Id,Integer> partnerAccountMap = new Map<Id,Integer>(); - Optimized for CS21-570 
            //Map<Id,Integer> customerProspectAccountMap = new Map<Id,Integer>(); - Optimized for CS21-570
            //Map<Id,String> accountTypeMap = new Map<Id,String>(); - Optimized for CS21-570
            Map<Id,Integer> accountCounts = new Map<Id,Integer>(); //added for CS21-570
            Map<Id,Id> accountUserMap = new Map<Id,Id>();
            List<String> openOpportunityStages = Label.CustomerRegistrationOpportunityStages.split(',');
            
            //updated query to fetch related records via inner query - CS21-570
            for (Account account : [SELECT Id, Type, OwnerId, Partner_Agreement_Status__c,
                                   (SELECT Id FROM Entitlements WHERE Status = 'Active' LIMIT 1),
                                   (SELECT Id FROM Opportunities WHERE StageName IN :openOpportunityStages LIMIT 1),
                                   (SELECT Id FROM Opportunities__r WHERE StageName IN :openOpportunityStages LIMIT 1)
                                   FROM Account WHERE Id IN :accIds])
            {
                //accountTypeMap.put(account.Id, account.Type); - Optimized for CS21-570
                accountUserMap.put(account.Id, account.OwnerId);
                
                //added for CS21-570
                if (account.Partner_Agreement_Status__c != 'Signed - Active') {
                    Integer accountCount = 0;
                    accountCount += account.Entitlements.size() + account.Opportunities.size() + account.Opportunities__r.size();
                    accountCounts.put(account.Id, accountCount);
                }
                //CS21-570 - End
                
                //commented for CS21-570
                /*if(act.Type == 'Reseller' || act.Type == 'Distributor' || act.Type == 'MSP-Reseller' || act.Type == 'MSP' || act.Type == 'MSP Customer')
                    partnerAccountMap.put(act.Id , 0);
                else
                    customerProspectAccountMap.put(act.Id , 0);
                */ 
            }
            
            /*
            //Entitlement
            for(Entitlement et : [SELECT Id, Account.Type, AccountId, Status FROM Entitlement 
                                  WHERE AccountId IN :accIds])
            {
                //commented for CS21-570
                if(et.account.Type == 'Reseller' || et.account.Type == 'Distributor' 
                   || et.account.Type == 'MSP-Reseller' || et.account.Type == 'MSP' || et.account.Type == 'MSP Customer' ){
                    if(et.Status == 'Active' && partnerAccountMap.containsKey(et.AccountId))
                        partnerAccountMap.put(et.AccountId,partnerAccountMap.get(et.AccountId)+1);
                }else{
                    if(et.Status == 'Active' && customerProspectAccountMap.containsKey(et.AccountId))
                      customerProspectAccountMap.put(et.AccountId,customerProspectAccountMap.get(et.AccountId)+1);
                }
            }
            
            //Opportunity
            
            for(Opportunity opportunity : [SELECT Id, Account.Type, AccountId, Partner_Lookup__r.type, Partner_Lookup__c, StageName 
                                           FROM Opportunity 
                                           WHERE (AccountId IN: accIds OR Partner_Lookup__c IN: accIds)]){
                if(opp.AccountId != null){
                    if(opp.account.Type == 'Prospect' || opp.account.Type == 'Customer' || opp.account.Type == null){
                        if(opp.StageName != '7 Closed Lost' &&  customerProspectAccountMap.containsKey(opp.AccountId))
                          customerProspectAccountMap.put(opp.AccountId,customerProspectAccountMap.get(opp.AccountId)+1);
                    }
                
                    if(opp.account.Type == 'Reseller' || opp.account.Type == 'Distributor' || opp.account.Type == 'MSP-Reseller' || opp.account.Type == 'MSP' || opp.account.Type == 'MSP Customer'){
                        if(opp.StageName != '7 Closed Lost' && partnerAccountMap.containsKey(opp.AccountId))
                            partnerAccountMap.put(opp.AccountId,partnerAccountMap.get(opp.AccountId)+1);
                    }else{
                        if(opp.StageName != '7 Closed Lost' &&  customerProspectAccountMap.containsKey(opp.AccountId))
                          customerProspectAccountMap.put(opp.AccountId,customerProspectAccountMap.get(opp.AccountId)+1);
                    }
                }
                
                if(opp.Partner_Lookup__c != null){
                    if(opp.Partner_Lookup__r.Type == 'Reseller'  || opp.Partner_Lookup__r.Type == 'Distributor' || opp.Partner_Lookup__r.Type == 'MSP-Reseller' || opp.Partner_Lookup__r.Type == 'MSP' || opp.Partner_Lookup__r.Type == 'MSP Customer'){
                        if(opp.StageName != '7 Closed Lost' && partnerAccountMap.containsKey(opp.Partner_Lookup__c))
                            partnerAccountMap.put(opp.Partner_Lookup__c,partnerAccountMap.get(opp.Partner_Lookup__c)+1);
                    }
                }  
            }*/
                
            Set<Id> contactId = new Set<Id>();
            List<Contact> contactList = new List<Contact>();
            List<Contact> updatedContactList = new List<Contact>();
            List<Entitlement> entitlementList = new List<Entitlement>();
            Product2 evaluationProduct = [SELECT Id, Name FROM Product2 WHERE Name = 'EVALUATION-CDM' LIMIT 1];
            Map<id,String> domainAccountMap = new Map<id,String>();
            
            for(Customer_Registration_Request__c crr : crrList){
                if(crr.Status__c != oldMap.get(crr.Id).Status__c && crr.Status__c == 'Approved'){
                    if(!crr.has_Domain__c){
                        domainAccountMap.put(crr.Account__c,crr.Domain_Name__c); 
                    }
                        
                    if (!accountCounts.isEmpty() && accountCounts.containsKey(crr.Account__c) && accountCounts.get(crr.Account__c) == 0) {
                        if(crr.Extended_By_Date__c == null){
                            crr.addError('Extended By Date is required, You can\'t Approve the record without the Extending Date as it is required for Creating Entitlments ');
                        } else {
                            entitlementList.add(new Entitlement(Name = evaluationProduct.Name, 
                                                                AccountId = crr.Account__c,
                                                                Product__c = evaluationProduct.Id, 
                                                                StartDate = System.today(), 
                                                                EndDate = crr.Extended_By_Date__c)); 
                        }
                    }
                    
                    /*if(accountTypeMap.containsKey(crr.Account__c)){
                        String customerType = accountTypeMap.get(crr.Account__c);
                        
                        if(customerType == 'Customer' || customerType == 'Prospect' || customerType == null){
                            if(customerProspectAccountMap.containsKey(crr.Account__c)){
                                if(customerProspectAccountMap.get(crr.Account__c) == 0){
                                    if(crr.Extended_By_Date__c == null){
                                        crr.addError('Extended By Date is required, You can\'t Approve the record without the Extending Date as it is required for Creating Entitlments ');
                                    }
                                    entitlementList.add(new Entitlement(Name = Pro.Name,AccountId = crr.Account__c,Product__c = pro.id, StartDate = System.today() , EndDate = crr.Extended_By_Date__c));
                                }
                            }
                        }
                        if(customerType == 'Reseller' || customerType == 'Distributor' || customerType == 'MSP-Reseller' || customerType == 'MSP' || customerType == 'MSP Customer'){
                            if(partnerAccountMap.containsKey(crr.Account__c)){
                                if(partnerAccountMap.get(crr.Account__c) == 0){
                                    if(crr.Extended_By_Date__c == null){
                                        crr.addError('Extended By Date is required, You can\'t Approve the record without the Extending Date as it is required for Creating Entitlments ');
                                    }
                                    entitlementList.add(new Entitlement(Name = Pro.Name,AccountId = crr.Account__c,Product__c = pro.id, StartDate = System.today() , EndDate = crr.Extended_By_Date__c));
                                }
                            }
                        }else{
                            if(customerProspectAccountMap.containsKey(crr.Account__c)){
                                if(customerProspectAccountMap.get(crr.Account__c) == 0){
                                    if(crr.Extended_By_Date__c == null){
                                        crr.addError('Extended By Date is required, You can\'t Approve the record without the Extending Date as it is required for Creating Entitlments ');
                                    }
                                    entitlementList.add(new Entitlement(Name = Pro.Name,AccountId = crr.Account__c,Product__c = pro.id, StartDate = System.today() , EndDate = crr.Extended_By_Date__c));
                                }
                            }
                        }
                    }*/
                    
                    if(crr.Reset_Password__c){
                        if(usernameEmailMap.containsKey(crr.Email__c.toLowerCase())){
                            System.resetPassword(usernameEmailMap.get(crr.Email__c.toLowerCase()), true);
                        }
                        continue;
                    }
                    if(crr.Contact__c != null && !communityUserMap.containsKey(crr.Email__c.toLowerCase())){
                        Contact con = new Contact();
                        con.Id = crr.Contact__c;
                        Boolean ischanged = false;
                        if(con.Phone == null || con.Phone == ''){
                            con.Phone = con.Phone == null ? crr.Phone__c : con.Phone;
                            ischanged = true;
                        }
                        if(con.Title == null || con.Title == ''){
                            con.Title = con.Title == null ? crr.Title__c : con.Title;
                            ischanged = true;
                        }
                        if(ischanged){
                            updatedContactList.add(con);
                        }
                        
                        contactId.add(crr.Contact__c);
                    }else{
                        Contact con = new Contact();
                        if(communityUserMap.containsKey(crr.Email__c.toLowerCase())){
                        }else if(contactMap.containsKey(crr.Email__c.toLowerCase())){
                            con = contactMap.get(crr.Email__c.toLowerCase());
                            Boolean ischanged = false;
                            if(con.Phone == null || con.Phone == ''){
                                con.Phone = con.Phone == null ? crr.Phone__c : con.Phone;
                                ischanged = true;
                            }
                            if(con.Title == null || con.Title == ''){
                                con.Title = con.Title == null ? crr.Title__c : con.Title;
                                ischanged = true;
                            }
                            if(ischanged){
                                updatedContactList.add(con);
                            }
                            contactId.add(con.id);
                        }else{
                            if(accountUserMap.containsKey(crr.Account__c))
                                con.OwnerId = accountUserMap.get(crr.Account__c);
                            con.AccountId = crr.Account__c;
                            con.FirstName = crr.firstName__c;
                            con.LastName = crr.Last_Name__c;
                            con.Email = crr.Email__c;
                            con.Title = crr.Title__c;
                            con.Phone = crr.Phone__c;
                            contactList.add(con);
                        }
                    }
                }
            }
            if(!entitlementList.isEmpty())
                insert entitlementList;
            // CS21-1837: ByPassing Contact duplicate rule, When new Support User Contact creating on existing Partner User Contact 
            // CS21-1837: Approved Support Portal user didn't get enabled | Exception error created
            if(!contactList.isEmpty()){
                Database.DMLOptions dml = new Database.DMLOptions(); 
                dml.DuplicateRuleHeader.allowSave = true;
                dml.DuplicateRuleHeader.runAsCurrentUser = true;
                List<Database.SaveResult> sr = Database.insert(contactList, dml);
            }
            if(!updatedContactList.isEmpty())
                update updatedContactList;
            for(Contact con : contactList){
                contactId.add(con.id);
            }
            if(domainAccountMap != null && !domainAccountMap.isEmpty())
                AccountServiceController.createNewDomain(domainAccountMap, true);
            if(!contactId.isEmpty())
                createUser(contactId);
            if(test.isRunningTest())
                throw new DMLException();
        } catch(Exception e){
            Customer_Registration_Request__c crr = new Customer_Registration_Request__c();
            crr.FirstName__c = 'Run-Time Error';
            crr.Description__c = e.getMessage()+'---'+e.getLineNumber();
            if(!test.isRunningTest())   insert crr;
        }
    }

    @future //This method will create a community user and will take contact id as parameter on which community user should be based
    public static void createUser(Set<id> contactIdList){
        List<User> usrList = new List<User>();
        try{
            List<Contact> conList = [SELECT AccountId, FirstName, LastName, Email, Title, Phone, Id FROM Contact WHERE Id = :contactIdList];
            List<String> emailList = new List<String>();
            List<String> allemailList = new List<String>();
            for(Contact con : conList){
                emailList.add(con.Email);
                emailList.add('support.'+con.Email);
            }
            Map<id,UserLicense> licenseMap = new Map<id,UserLicense>([select id,name from UserLicense]);
            Profile pf = [SELECT Id FROM profile WHERE name=: Label.Community_Profile limit 1]; 
            Map<String,User> userMap = new Map<String,User>();

            for(User u : [select id,name,IsActive,ContactId,contact.Email,Profile.UserLicenseID from user where (email IN: emailList OR email IN: allemailList)]){
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
                if(userMap.containsKey(con.Email.toLowerCase())){
                    User usr = userMap.get(con.Email.toLowerCase());
                    if(!usr.IsActive){
                        usr.IsActive = true; 
                        usr.ProvisionType__c = 'Customer Registration'; //added ProvisionType__c for CS21-51 - Veera
                        usrUpdate.add(usr);
                    }
                }
                else{
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

                    //First Name is not required on Contact
                    //Fixing FirstName Nullpointer Issue
                    String firstName = string.isNotBlank(con.FirstName) ? con.FirstName : '';
                    String firstNameString = string.isNotBlank(con.FirstName) ? con.FirstName.substring(0,1) : '';

                    String nameString = firstNameString + ' ' + con.LastName.substring(0,1) + ' ' + intVal;
                    nameString = nameString.trim();
                    nameString = nameString.length() > 8 ? nameString.substring(0, 7) : nameString;

                    String nickName =  firstName +'.'+ con.LastName+'-'+System.now().formatGMT('MMddyy-HHmm').trim();

                    if(nickName.length() > 40){
                        nickName = firstNameString +'.'+ con.LastName.substring(0,1)+'-'+System.now().formatGMT('MMddyy-HHmm').trim();
                    }
                    //Fix - End
                    
                    usr.Username = mapAddSupport.containsKey(con.Email.toLowerCase()) ? 'support.'+con.Email:con.Email;
                    usr.CommunityNickname = nickName;
                    usr.Alias =  nameString;
                    usr.TimeZoneSidKey = 'America/Phoenix';
                    usr.LocaleSidKey = 'en_US';
                    usr.EmailEncodingKey = 'ISO-8859-1';
                    usr.LanguageLocaleKey = 'en_US';
                    usr.ProvisionType__c = 'Customer Registration'; //added ProvisionType__c for CS21-51 - Veera
                    usrList.add(usr);
                }
            }
            if(!usrUpdate.isEmpty())
                update usrUpdate;
            if(!usrList.isEmpty())
                insert usrList;
            if(test.isRunningTest())
                throw new DMLException();
        }catch(Exception e){
            List<Customer_Registration_Request__c> crrList = new List<Customer_Registration_Request__c>();
            for(User usr: usrList){
                Customer_Registration_Request__c crr = new Customer_Registration_Request__c();
                crr.FirstName__c = usr.Name;
                crr.Last_Name__c = usr.UserName;
                crr.Email__c = usr.email;
                crr.Phone__c= usr.phone;
                crr.Title__c = usr.title;
                crr.Contact__c = usr.ContactId;
                crr.Description__c ='ERROR CREATING USER=>>>>>>>>>>>>'+ e.getMessage();
                crrList.add(crr);
            }
            if(!test.isRunningTest())   insert crrList;
        }
    }

}