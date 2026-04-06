public without sharing class PC_PartnerRequestingFormController {
    private static boolean isduplicateContactBool;
    //PRIT24-435 - start
    @AuraEnabled
    public static String savePartnerRecord(Partner_Registration_Request__c record)
    {
        Map<String, List<PatchManager__c>> patchMap = new Map<String, List<PatchManager__c>>();        
        Set<Id> contactIds = new Set<Id>();
        for(User u: [SELECT Id, Email, AccountId, Account.RecordType.Name, ContactId, Profile.Name, UserType FROM User 
                     WHERE Account.RecordType.Name='Partner/Distributor' AND Contact.Email =: record.Email__c])
        {
            contactIds.add(u.ContactId);
            if(u.UserType == 'PowerPartner'){
                record.Related_Partner_Contact__c = u.ContactId;
                if(String.isBlank(record.Partner_Account_Lookup__c)){
                    record.Partner_Account_Lookup__c = u.AccountId;
                }
            }
        }
        for(Contact c : [SELECT Id, Email, AccountId, Account.RecordType.Name FROM Contact 
                         WHERE Account.RecordType.Name='Partner/Distributor' AND
                         Email =: record.Email__c AND Id NOT IN: contactIds LIMIT 1])
        {
            record.Related_Partner_Contact__c = c.Id;
            if(String.isBlank(record.Partner_Account_Lookup__c)){
                record.Partner_Account_Lookup__c = c.AccountId;
            }
        }
        
        String emailDomain = record.Email__c.split('@')[1];
        
        if(record.Company_Name__c != null && String.isBlank(record.Partner_Account_Lookup__c)){
            for(Account a : [SELECT Id, Name FROM Account WHERE Website =: emailDomain
                             AND BillingCountry =: record.Country_Picklist__c AND 
                             Name =: record.Company_Name__c AND RecordType.Name='Partner/Distributor' LIMIT 1])//prit24-918
            {
                record.Partner_Account_Lookup__c = a.Id;
            }
        }
        
        //PRIT24-436 Auto-approval 
        if(record.Partner_Account_Lookup__c != null && !record.Admin_Access__c){
            String endsWithEmailDomain = '%'+ emailDomain;
            List<Contact> partnerContacts = [SELECT Id, Account.OwnerId FROM Contact WHERE AccountId =: record.Partner_Account_Lookup__c AND Email like :endsWithEmailDomain 
                                             AND Account.RecordType.Name = 'Partner/Distributor'AND Account.Contract_Status__C ='Signed-Active'
                                             AND Account.BillingCountry =: record.Country_Picklist__c AND Account.Type IN ('Reseller', 'Distributor', 'MSP-Reseller', 'MSP')];
            if(!partnerContacts.isEmpty()){
                record.Auto_Approval__c = true;
                record.Partner_Registration_Status__c = 'Approved';
                record.OwnerId = partnerContacts[0].Account.OwnerId;
            }
        }
        
        if(!record.Auto_Approval__c){
            PatchManagerSettings__c patchManagerCustomSetting = PatchManagerSettings__c.getOrgDefaults();
            if(PatchManager.ROUTE_ON_INSERT_PARTNER || Test.isRunningtest()){                        
                patchMap = PatchManager.getPatchMap(new List<Partner_Registration_Request__c> {record}, PatchManager.PARTNER_ACCESS);
                PatchManager__c pmRec = PatchManager.assignPartnerAccessRequest(patchMap, record);
                record.Patch_Key__c = pmRec != null ? pmRec.Id : null;
                //PRIT25-796 Override owner with CDM in patch key
                record.OwnerId = !Test.isRunningTest() && pmRec.CDM__c != null && pmRec.CDM__r.isActive? pmRec.CDM__c:Label.POB_Exception_UserId;
																						  
            }
            record.Partner_Registration_Status__c ='Submitted';
        }
        
        if(!duplicateContactCheck(record)){
            if(record.ownerId==null){
                record.OwnerId = label.POB_Exception_UserId;
            }
                Database.SaveResult saveResult = database.insert(record,false);
                if (!saveResult.isSuccess()) {
                    System.debug(system.logginglevel.DEBUG, 'Exception :: '+saveResult.getErrors()[0].getMessage());
                    return saveResult.getErrors()[0].getMessage();
                }
        }else{
            return 'Duplicate';
        }
        
        if(String.isBlank(record.Partner_Account_Lookup__c)){
            return 'AccountNotexist';
        }else{
            return 'Accountexist';
        }
    }//PRIT24-435 - end
    
    public static boolean duplicateContactCheck(Partner_Registration_Request__c record){
        isduplicateContactBool=false;
        /** Email already present in request **/
        if(!String.isBlank(record.email__c)){
            List<Partner_Registration_Request__c> PRRecord = [SELECT Id, Name, Email__c, Partner_registration_Status__c FROM Partner_Registration_Request__c WHERE Email__c =: record.email__c AND Partner_Registration_Status__c ='Submitted'];
            if(!PRRecord.isEmpty()){
                isduplicateContactBool = true;
            }
            /** checking in partner user **/
			//PRIT25-804 - Bypass below check if the admin access is selected from Portal User tab of Partner Community
            else if(!isduplicateContactBool && !PC_UserManagementApexController.adminAccess){
                List<User> userRecord = [SELECT Id, Name, Profile.Name, Contact.Email from user WHERE (Profile.Name = 'Rubrik Partner Community User' OR Profile.Name = 'Rubrik Partner Community Manager') AND contact.Email =: record.email__c AND isActive = TRUE AND Portal_Admin_Access__c = FALSE];
                if(!userRecord.isEmpty()){
                    isduplicateContactBool = true;
                }
            }
        }
        
        return isduplicateContactBool;
    }
}