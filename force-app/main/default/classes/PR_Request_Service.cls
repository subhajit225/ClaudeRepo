public class PR_Request_Service {
    public static void convertPRtoContact(List<Partner_Registration_Request__c> convertPRList){
        try{
            //string contactAccountName =''; // PRIT24-861 
            List<string> ContactIds = new List<string>();
            if(!convertPRList.isEmpty()){
                system.debug('convertPRList---'+convertPRList+'---size--'+convertPRList.size());
                //List<String> companyNameList = new List<String>(); // PRIT24-861 
               // List<String> contactEmailList = new List<String>(); // PRIT24-861 
                Set<String> isExistingContactList = new Set<String>();
                //List<string> temp = new List<string>(); // PRIT24-861 
                Set<Id> PR_RequestIds= new Set<Id>(); // PRIT24-861 
                Set<Id> partnerAccountIds= new Set<Id>(); // PRIT24-861 
                Map<string,Id> accountMap = new Map<string,Id>();
                Map<Id, Partner_Registration_Request__c> prMap = new Map<Id, Partner_Registration_Request__c>();

                for(Partner_Registration_Request__c prRecord : convertPRList){
                    /* PRIT24-861 
                    if(!String.isBlank(prRecord.Company_Name__c ) )
                        companyNameList.add(prRecord.Company_Name__c);
                    if(prRecord.Email__c.contains('@')){
                    	temp = prRecord.Email__c.split('@');
                        temp[1] = '%'+temp[1];
                        contactEmailList.add(temp[1]);
                    }  PRIT24-861  */
                    PR_RequestIds.add(prRecord.id); // PRIT24-861 
                    isExistingContactList.add(prRecord.Email__c); 
                }
               // system.debug('contactEmailList--'+contactEmailList+'---size--'+contactEmailList.size());
                List<Partner_Registration_Request__c> partnerReqList= [SELECT id,First_Name__c,Last_Name__c,Email__c,Job_Title__c,Phone_Number__c,
                                                                       Address__c,City__c,Country__c,State__c,Postal_Code__c,
                                                                       Partner_Account_Lookup__c, Partner_Account_Lookup__r.Name,Admin_Access__c 
                                                                       FROM Partner_Registration_Request__c WHERE id= :PR_RequestIds];
                
                for(Partner_Registration_Request__c prRequest: partnerReqList)
                {
                    partnerAccountIds.add(prRequest.Partner_Account_Lookup__c); // PRIT24-861 
                    accountMap.put(prRequest.Partner_Account_Lookup__r.Name.toLowerCase(), prRequest.Partner_Account_Lookup__c); // PRIT24-861 
                    prMap.put(prRequest.Partner_Account_Lookup__c,prRequest);
                }
                
                List<String> userContactIds= new List<String>(); // PRIT24-861 
                Map<string,Id> contactMap = new Map<string,Id>();
                Map<String,User> contactUserMap = new Map<String,User>();
                List<Contact> conListToUpdate = new List<Contact>();
                // PRIT24-861 : START
                for(User user: [SELECT id,ContactId,Contact.Email,AccountId,Account.Name FROM User WHERE Contact.AccountId= :partnerAccountIds AND Email= :isExistingContactList AND UserType='PowerPartner']){
                    userContactIds.add(user.ContactId);
                    partnerAccountIds.remove(user.AccountId);
                    //contactUserMap.put(user.Contact.Email, user);
                    if(prMap.get(user.AccountId).Admin_Access__c)
                    {
                        Contact updateCon = new Contact();
						updateCon.Id = user.ContactId;
						updateCon.Primary_Role__c = 'Admin';
                        updateCon.User_Profile__c = 'Rubrik Partner Community Manager';
                        conListToUpdate.add(updateCon);
                    }
                }

                if(userContactIds.size() > 0){
                    update conListToUpdate;
                    PR_Request_Service.updateUser(userContactIds);
                }

                if(partnerAccountIds.size() > 0){
                    for(Contact con: [SELECT id,Name,Email,AccountId,Account.Name FROM Contact WHERE AccountId= :partnerAccountIds AND Email= :isExistingContactList AND Account.RecordType.DeveloperName = 'Partner_Distributor' order by createddate asc]){
                        contactMap.put(con.Email, con.id);
                        partnerAccountIds.remove(con.AccountId);
                    }
                }
                // PRIT24-861 : END
                
                /* PRIT24-861 
                for(Contact conRecord : [select id,Name,Email,AccountId,Account.Name from Contact where Email like: contactEmailList AND Account.RecordType.DeveloperName = 'Partner_Distributor' order by createddate asc]){
                    if(!isExistingContactList.isEmpty() && isExistingContactList.contains(conRecord.Email)){
                    	contactMap.put(conRecord.Email, conRecord.Id);
                    }
                    system.debug('in Contact loop '+conRecord);
                    if(conRecord.AccountId != null){
                        accountMap.put(conRecord.Account.Name.toLowerCase(), conRecord.AccountId);
                        contactAccountName =conRecord.Account.Name;
                    }
                } PRIT24-861  */
                if(contactMap.size() > 0 ){  // PRIT24-861 : Added IF Block
                    for(User u : [SELECT Id,Contact.Email FROM User WHERE ContactId IN :contactMap.values()]){
                        contactUserMap.put(u.Contact.Email,u);
                    }
                }
                
               /* if(contactMap.isEmpty()){
                    system.debug('in Account loop');
                    for(Account accRecord : [select id,Name from Account where Name IN : companyNameList]){
                        accountMap.put(accRecord.Name.toLowerCase(), accRecord.Id);
                        contactAccountName =accRecord.Name;
                    }
                }*/
                //system.debug('contactAccountName'+contactAccountName);
                system.debug('co MAp'+contactMap);
                system.debug('accountMap '+accountMap);
                List<Account> newAccounts = new List<Account>();
                Map<String, StateCodeName__C> mapStatusStateCodeCustomSetting = StateCodeName__C.getAll();
                Map<String, CountryWithCode__c> mapStatusCounrtyCodeCustomSetting = CountryWithCode__c.getAll();

                system.debug('accountMap---'+accountMap+'----size---'+accountMap.size());
                system.debug('ContactMap---'+ContactMap+'----size---'+ContactMap.size());
                List<Contact> newContactsList = new List<contact>();
                List<Contact> updateContactsList = new List<contact>();
                if(partnerAccountIds.size() > 0){
                    for(Partner_Registration_Request__c prRequestNew : partnerReqList){
                        if(!accountMap.isEmpty() && prRequestNew.Partner_Account_Lookup__c != null && (accountMap.containsKey(prRequestNew.Partner_Account_Lookup__r.Name.toLowerCase()) && partnerAccountIds.contains(prRequestNew.Partner_Account_Lookup__c)) ){  // PRIT24-861 
                            system.debug('new contact creation loop'+contactMap);
                            Contact conRecord = new Contact(LastName = prRequestNew.Last_Name__c,
                                                            FirstName = prRequestNew.First_Name__c,
                                                            AccountId = accountMap.get(prRequestNew.Partner_Account_Lookup__r.Name.toLowerCase()),
                                                            Email = prRequestNew.Email__c,
                                                            Title = prRequestNew.Job_Title__c,
                                                            Phone = prRequestNew.Phone_Number__c,
                                                            MailingStreet = prRequestNew.Address__c,
                                                            MailingCity = prRequestNew.City__c,
                                                            MailingCountry = prRequestNew.Country__c,
                                                            MailingPostalCode = prRequestNew.Postal_Code__c,
                                                            create_Portal_User__c=true,
                                                            LeadSource = 'Channel Marketing'
                                                           );
                            string uniqueCode='';
                            
                            
                            if(mapStatusCounrtyCodeCustomSetting.containsKey(prRequestNew.Country__c) && prRequestNew.State__c != null){
                                uniqueCode = mapStatusCounrtyCodeCustomSetting.get(prRequestNew.Country__c).code__C+'-'+prRequestNew.State__c;
                                System.debug('unique Code'+uniquecode);
                                conRecord.MailingState = mapStatusStateCodeCustomSetting.get(uniqueCode).State_Name__c;
                            }
                            else
                                conRecord.MailingState = null;
                            newContactsList.add(conRecord);
                        }
                        else if (!contactMap.isEmpty() ){
                            contact updateCon = new Contact();
                            updateCon.id = contactMap.get(prRequestNew.Email__c);
                                if(prRequestNew.Admin_Access__c){
                                    updateCon.Primary_Role__c = 'Admin';
                                }  
                                if(!contactUserMap.containskey(prRequestNew.Email__c)){
                                    updateCon.create_Portal_User__c=true;
                                }
                                updateContactsList.add(updateCon);
                            
                        }
                    }

                }
                
                if(!newContactsList.isEmpty()){
                    insert newContactsList;
                    system.debug('new insert creation loop'+contactMap);
                }
                
                if(!updateContactsList.isEmpty()){
                    update updateContactsList;
                    system.debug('new update creation loop'+contactMap);
                    for(Contact c :updateContactsList ){
                        if(!c.create_Portal_User__c){
                        	ContactIds.add(c.Id);
                        }
                    }
                    if(!ContactIds.isEmpty()){
                    	PR_Request_Service.updateUser(ContactIds);
                    }
                }
                // PRIT24-861 : START
                if(!PR_RequestIds.isEmpty()){
                    List<Partner_Registration_Request__c> updatePR_RequestList= new List<Partner_Registration_Request__c>();
                    for(Partner_Registration_Request__c PR_Request: [SELECT id,Is_Converted__c FROM Partner_Registration_Request__c WHERE id= :PR_RequestIds]){
                        PR_Request.Is_Converted__c= true;
                        updatePR_RequestList.add(PR_Request);
                    }
                    if(updatePR_RequestList.size() > 0){
                        update updatePR_RequestList;
                    }
                }
                // PRIT24-861 : END  
            }
        }catch(Exception ex){
            System.debug('Exception==Method: convertPRtoContact==Class==PR_Request_Service'+ex);
            System.debug('Exception on Line >> ' + ex.getLineNumber() + ' >> StackTree >> '+ ex.getStackTraceString());
        }
    }
    @future
    public static void updateUser(List<String> ContactIds){
        List<User> contactuserlist = new  List<User>(); 
        contactuserlist = [select id,name,isActive,ContactId,ProfileId from User where contactid=:ContactIds];  
		
		Map<Id,Contact> conMap = new Map<Id,Contact> ([SELECT Id, Primary_Role__c FROM Contact WHERE Id in : ContactIds]);
		
		Id managerProfileId = [SELECT Id FROM Profile WHERE Name = 'Rubrik Partner Community Manager'][0].Id;
		
        for(User u : contactuserlist){
            u.isActive = true;
			if(conMap != null && conMap.containsKey(u.ContactId) && conMap.get(u.ContactId).Primary_Role__c == 'Admin'){
				u.ProfileId = managerProfileId;
			}
        }
        if(!contactuserlist.isEmpty()){
            flowControll.UserTriggerHandler = false;
            update contactuserlist;
            flowControll.UserTriggerHandler = true;
        } 
    }
}