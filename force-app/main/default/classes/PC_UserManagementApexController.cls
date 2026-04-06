public without sharing class PC_UserManagementApexController {
    public static boolean adminAccess = false;
	
    @AuraEnabled
    public static string createNewUser(Contact conObj,Boolean createPortalUser){
        String result;
		Database.SaveResult saveResult;
        List<Id> conIds = new List<Id>();
		Set<Id> contactIdOfUsers = new Set<Id>();
        
        User currentUser = [SELECT Id,ContactId,Contact.AccountId
                            FROM User
                            WHERE Id =: UserInfo.getUserId() AND ContactId != null LIMIT 1];
		
        
		List<User> usersWithContact = [SELECT Id,ContactId,Profile.Name,IsActive,Contact.No_Longer_Employed_Here__c FROM User WHERE 
                                       AccountId =:currentUser.Contact.AccountId and Email =: conObj.Email ORDER BY Contact.Createddate DESC];
		
		if(!usersWithContact.isEmpty()){
			for(User u : usersWithContact){
				contactIdOfUsers.add(u.ContactId);
                if(u.Profile.Name == 'Rubrik Partner Community User' || u.Profile.Name == 'Rubrik Partner Community Manager'){
					if(u.Contact.No_Longer_Employed_Here__c){
						result = 'User is no longer employed at the company.';
						return result;
					}else if(createPortalUser && u.isActive){
						result = 'User already has portal access.';
						return result;
					}else if(createPortalUser && !u.isActive){
						result ='User already exists. Please activate the user.';
						return result;
					}
				}
            }
        }
		
		List<Contact> contWithReqEmail = [SELECT Id,Email,AccountId,No_Longer_Employed_Here__c,Create_Portal_User__c FROM Contact 
										  WHERE Email =: conObj.Email AND AccountId =:currentUser.Contact.AccountId AND Id NOT IN :contactIdOfUsers ORDER BY CreatedDate DESC LIMIT 1];
		
		Database.DMLOptions dmlOption = new Database.DMLOptions(); 
		dmlOption.DuplicateRuleHeader.allowSave = true;
		
		if(!contWithReqEmail.isEmpty()){
			Contact c = contWithReqEmail[0];
			c.Create_Portal_User__c = createPortalUser;
			saveResult = Database.update(c, dmlOption);
		}else{
			conObj.AccountId = currentUser.Contact.AccountId;
			conObj.Create_Portal_User__c = createPortalUser;
			saveResult = Database.insert(conObj, dmlOption);
		}
		
		if(saveResult.isSuccess()){
			result = 'success';
		}else{
			String errResult = '';
			for(Database.Error err : saveResult.getErrors()) {
				errResult = errResult + err.getMessage() + '. \n';
			}
			result = errResult;
		}
		
        return result;
	}
					
        /* Commented as a part of PRIT25-674. Redesigned the method
        for(Contact con : [SELECT Id,FirstName,LastName,Job_Function__c,Email,AccountId,No_Longer_Employed_Here__c FROM Contact WHERE Email =: conObj.Email 
                        AND AccountId =:currentUser.Contact.AccountId AND (CommunityUser__c = null OR User_Profile__c IN ('Rubrik Partner Community User','Rubrik Partner Community Manager')) ORDER BY createddate ASC])
        {
            conObj.AccountId = currentUser.Contact.AccountId;
            conObj.No_Longer_Employed_Here__c = con.No_Longer_Employed_Here__c;
            conMap.put(con.Id, conObj);
            conIds.add(con.Id);
        }
        
        if(conMap.size() > 0){
            for(User userRec : [SELECT Id,ContactId,IsActive FROM User WHERE ContactId IN :conIds AND
                                Profile.Name IN ('Rubrik Partner Community User','Rubrik Partner Community Manager')])
            {
                userMap.put(userRec.Id,userRec);
                if(conMap.get(userRec.ContactId).No_Longer_Employed_Here__c){
                    result = 'User is no longer employed at the company.';
                    return result;
                }else if(createPortalUser && userRec.isActive){
                    result = 'User already has portal access.';
                    return result;
                }else if(!userRec.isActive && createPortalUser){
                    result ='User already exists. Please activate the user.';
                    return result;
                }
            }
            if(userMap.size() == 0 && !createPortalUser){
                result = 'This email address is already associated to a user.';
                return result;
            }else if(userMap.size() == 0 && createPortalUser){
                Contact c = conMap.get(conIds[0]);
                c.Create_Portal_User__c = true;
                c.Id = conIds[0];
                Database.update(c, true);
            }
        }else{
            conObj.AccountId = currentUser.Contact.AccountId;
            if(createPortalUser){
                conObj.Create_Portal_User__c = true;
            }
            Database.insert(conObj, true);
            //self portal user creation will happen auto after con creation.
        }
        return result;
		*/
    
    @AuraEnabled
    public static String deactivateUser(String conId, Boolean reason){
        //List<String> conIdList = new List<String>();
        try{
            Contact conRec = [SELECT Id,No_Longer_Employed_Here__c
                              FROM Contact
                              WHERE Id =: conId LIMIT 1];
            if(reason){
                conRec.No_Longer_Employed_Here__c = true;
                Database.update(conRec,true);
            }
            return 'success';
        }catch(exception e){
            return 'failure';
        }
        //update user to deactivate
        //conIdList.add(conId);
        //updateUser(conId);
        
    }
    
    @AuraEnabled
    public static String updateContact(Contact con, boolean admAccess, boolean fieldValuesChanged){
        adminAccess = admAccess;
        String result = 'success';
        try{
            if(fieldValuesChanged){
                update con;
            }
            if(adminAccess){
                List<Partner_Registration_Request__c> prRecs = [SELECT Id
                                                                FROM Partner_Registration_Request__c
                                                                WHERE Email__c =: con.Email AND Partner_Registration_Status__c = 'Submitted'];
                if(prRecs.size()>0){
                    prRecs[0].Admin_Access__c = true;
                    update prRecs[0];
                }else{
                    Contact existingCon = [SELECT Id,Account.Name,Account.BillingStreet,Account.BillingCity,Account.BillingCountry,Account.BillingPostalCode,Account.BillingState
                                           FROM Contact
                                           WHERE ID=:con.Id];
                    
                    Partner_Registration_Request__c prRequest = new Partner_Registration_Request__c();
                    prRequest.First_Name__c = con.FirstName;
                    prRequest.Last_Name__c = con.LastName;
                    prRequest.Job_Title__c = con.Title;
                    prRequest.Email__c = con.Email;
                    prRequest.Phone_Number__c = con.Phone;
                    prRequest.Admin_Access__c = true;
                    if(existingCon != null){
                        prRequest.Company_Name__c = existingCon.Account.Name;
                        prRequest.Address__c = existingCon.Account.BillingStreet;
                        prRequest.City__c = existingCon.Account.BillingCity;
                        prRequest.Country_Picklist__c = existingCon.Account.BillingCountry;
                        //prRequest.State_Picklist__c = existingCon.Account.BillingState;
                        prRequest.Postal_Code__c = existingCon.Account.BillingPostalCode;
                    }
                    PC_PartnerRequestingFormController.savePartnerRecord(prRequest);
                }
            }
        }catch(Exception e){
            system.debug(e);
            result = 'failed';
        }
        return result;
    }
    
    @AuraEnabled
    public static String updateUser(String contactId){
        try{
            List<User> contactuserlist = new  List<User>();
            contactuserlist = [SELECT Id,name,isActive
                               FROM User
                               WHERE contactid=:ContactId];
            for(User u : contactuserlist){
                u.isActive = false;
            }
            if(!contactuserlist.isEmpty()){
                system.debug('contactuserlist->'+contactuserlist);
                update contactuserlist;
            }
            return 'success';
        }catch(exception e){
            return 'failure';
        }
    }
    
    @AuraEnabled
    public static String userActivation(String conId){
        try {
            List<User> userList = [SELECT Id,ContactId,IsActive
                                   FROM User
                                   WHERE ContactId =: conId LIMIT 1];
            
            if(userList.isEmpty()){
                Contact con = new Contact(Id = conId);
                con.Create_Portal_User__c = true;
                update con;
            }else{
                List<String> conIdList = new List<String>();
                conIdList.add(conId);
                updateUserActive(conIdList);
            }
            return 'success';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @future
    public static void updateUserActive(List<String> ContactIds){
        List<User> contactuserlist = new  List<User>();
        contactuserlist = [SELECT Id,name,isActive
                           FROM User
                           WHERE contactid=:ContactIds];
        for(User u : contactuserlist){
            u.isActive = true;
        }
        if(!contactuserlist.isEmpty()){
            update contactuserlist;
        }
    }
    
    @AuraEnabled
    public static String getContactList(Integer pageSize, Integer pageNumber, String searchText){
        User currentUser = [SELECT Id,ContactId,Contact.AccountId
                            FROM User
                            WHERE Id =: UserInfo.getUserId() AND ContactId != null LIMIT 1];
        
        String jsonDT = '';
        String partnerAccId = currentUser.Contact.AccountId;
        String currentConId = currentUser.ContactId;
        
        //Offset for SOQL
        Integer offset = (pageNumber - 1) * pageSize;
        
        String queryCount = 'SELECT Id,Name FROM Contact WHERE AccountId =: partnerAccId AND No_Longer_Employed_Here__c = false AND Id <> :currentConId AND User_Profile__c IN (\'Rubrik Partner Community User\',\'Rubrik Partner Community Manager\',\'\')';
        
        if(!String.isBlank(searchText) && !searchText.contains('@')){
            String stringToSearch = '%' + searchText + '%';
            queryCount = queryCount + ' AND Name LIKE :stringToSearch';
        }else if(!String.isBlank(searchText) && searchText.contains('@')){
            String emailToSearch = '%' + searchText + '%';
            queryCount = queryCount + 'AND Email LIKE : emailToSearch';
        }
        
        //Total Records
        Integer totalRecords = Database.query(queryCount).size();
        Integer recordEnd = pageSize * pageNumber;
        
        contactDTWrapper objDT =  new contactDTWrapper();
        objDT.pageSize = pageSize;
        objDT.pageNumber = pageNumber;
        objDT.recordStart = offset + 1;
        objDT.recordEnd = totalRecords >= recordEnd ? recordEnd : totalRecords;
        objDT.totalRecords = totalRecords;
        
        String queryAll = 'SELECT ID,Name,Email,FirstName,LastName,Phone,AccountId,CommunityUser__r.isActive,isPartnerContact__c,MobilePhone,Title,User_Profile__c,CommunityUserProfile__c,CreatedDate,Primary_Role__c FROM Contact WHERE AccountId =: partnerAccId AND No_Longer_Employed_Here__c = false AND Id <> :currentConId AND User_Profile__c IN (\'Rubrik Partner Community User\',\'Rubrik Partner Community Manager\',\'\')';
        
        if(!String.isBlank(searchText) && !searchText.contains('@')){
            String stringToSearch = '%' + searchText + '%';
            queryAll = queryAll + ' AND Name LIKE :stringToSearch';
        }else if(!String.isBlank(searchText) && searchText.contains('@')){
            String emailToSearch = '%' + searchText + '%';
            queryAll = queryAll + 'AND Email LIKE : emailToSearch';
        }
        queryAll = queryAll + ' ORDER BY CreatedDate DESC LIMIT :pageSize OFFSET :offset';
        objDT.contactRecList = Database.query(queryAll);
        jsonDT = JSON.serialize(objDT);
        return jsonDT;
    }
    
    public class contactDTWrapper {
        public Integer pageSize {get;set;}
        public Integer pageNumber {get;set;}
        public Integer totalRecords {get;set;}
        public Integer recordStart {get;set;}
        public Integer recordEnd {get;set;}
        public List<Contact> contactRecList {get;set;}
    }
}