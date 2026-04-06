/**
* @description : Helper class for Partner_Registration_Request__c object.
* Validation of request is processed.
*/

public without sharing class PC_PartnerRegistrationRequestHelper {
	final String customerAccountError = 'You are approving a contact to an account that is a customer account, please update the Company Name to a Partner Account';
    final String partnerAccBlankError = 'You are not allowed to approve if Partner Account Lookup is blank';
    
    /**
    * @description : Validate mandatory Partner Account Lookup population on Approval
    * @return : void
    */
    public void checkPartnerAccount(List<Partner_Registration_Request__c> newRequestList, Map<Id,Partner_Registration_Request__c> oldRequestMap){
        for(Partner_Registration_Request__c newRequest : newRequestList){
            Partner_Registration_Request__c oldRequest = oldRequestMap.get(newRequest.Id);
            if(oldRequest.Partner_Registration_Status__c != newRequest.Partner_Registration_Status__c && newRequest.Partner_Registration_Status__c == 'Approved' && newRequest.Partner_Account_Lookup__c == null){
                newRequest.addError(partnerAccBlankError);
            }
        }
    }
    
    /**
     * @description : Updates Partner Registration Requests with related Contact and Account information based on matching Contact Email
     * @return : void
     */
    public void updateRelatedContactsByEmail(List<Partner_Registration_Request__c> newRequests, Map<Id, Partner_Registration_Request__c> oldRequestMap) {
        // Collect emails of PRR records whose status changed to Approved
        Map<Id, String> approvedRequestEmailMap = new Map<Id, String>();
        for (Partner_Registration_Request__c newRequest : newRequests) {
            if (oldRequestMap.get(newRequest.Id).Partner_Registration_Status__c != newRequest.Partner_Registration_Status__c && 
                newRequest.Partner_Registration_Status__c == 'Approved' && newRequest.Related_Partner_Contact__c == null) {
                approvedRequestEmailMap.put(newRequest.Id, newRequest.Email__c);
            }
        }
       
        // Query Contacts matching those emails under Partner/Distributor Accounts
        Map<String, Contact> contactByEmailMap = new Map<String, Contact>();
        Set<Id> contactIds = new Set<Id>();
        for(User u: [SELECT Id, Email, AccountId, Account.RecordType.Name, ContactId,Contact.Email, UserType, 
                     Contact.AccountId, Contact.Account.RecordType.Name, Profile.Name FROM User 
                     WHERE Account.RecordType.Name='Partner/Distributor' AND Contact.Email IN :approvedRequestEmailMap.values()])
        {
            contactIds.add(u.ContactId);
            if(u.UserType == 'PowerPartner'){
                contactByEmailMap.put(u.Contact.Email, u.Contact);
            }
        }
        
        for (Contact contactRecord : [ SELECT Id, Email, AccountId, Account.RecordType.Name FROM Contact WHERE 
                                      Account.RecordType.Name = 'Partner/Distributor' AND Email IN :approvedRequestEmailMap.values() 
                                     AND Id NOT IN: contactIds])
        {
            contactByEmailMap.put(contactRecord.Email, contactRecord); 
        }
        
        // Update PRR records with related Contact & Account info
        for (Partner_Registration_Request__c request : newRequests) {
            if (approvedRequestEmailMap.containsKey(request.Id) && contactByEmailMap.containsKey(request.Email__c)) {
                request.Related_Partner_Contact__c = contactByEmailMap.get(request.Email__c).Id;
                request.Partner_Account_Lookup__c = contactByEmailMap.get(request.Email__c)?.AccountId;
            }
        }
    }
    
    
    /**
    * @description : Validate Partner Account Lookup for Partner Accounts only and then send for further processing
    * @return : void
    */
    public void checkAccountType(List<Partner_Registration_Request__c> newRequestList, Map<Id,Partner_Registration_Request__c> oldRequestMap){
        List<Partner_Registration_Request__c> PartRegList = new List<Partner_Registration_Request__c>();
        Set<Id> customerAccPrRequestIds = new Set<Id>();
        Map<Id,List<Id>> prLookupPrRequestIdsMap = new Map<Id,List<Id>>();
        for(Partner_Registration_Request__c PR_Request : newRequestList){
            if(!prLookupPrRequestIdsMap.containsKey(PR_Request.Partner_Account_Lookup__c)){
                prLookupPrRequestIdsMap.put(PR_Request.Partner_Account_Lookup__c,new List<Id>{PR_Request.Id});
            }else{
                prLookupPrRequestIdsMap.get(PR_Request.Partner_Account_Lookup__c).add(PR_Request.Id);
            }
        }
        for(Account a: [SELECT Id,Name,RecordType.DeveloperName FROM Account WHERE Id IN: prLookupPrRequestIdsMap.keySet()]){
            if(a.RecordType.DeveloperName == 'Customer_Prospect'){
                customerAccPrRequestIds.addAll(prLookupPrRequestIdsMap.get(a.Id));
            }
        }
        for(Partner_Registration_Request__c PR_Request : newRequestList){
            Partner_Registration_Request__c oldPR = oldRequestMap.get(PR_Request.Id);
           if(oldPR.Partner_Registration_Status__c != PR_Request.Partner_Registration_Status__c 
                && PR_Request.Partner_Registration_Status__c == 'Approved'){
                    if(customerAccPrRequestIds.contains(PR_Request.Id)){
                        PR_Request.addError(customerAccountError);
                    }else if(!PR_Request.is_Converted__c){
                        PartRegList.add(PR_Request);
                    }
                }
        }
        if(!PartRegList.isEmpty()) {
            PC_PartnerRegistrationRequestService prReqService = new PC_PartnerRegistrationRequestService();
            prReqService.processPR(PartRegList);
        }

    }
    
    /**
    * @description :Send for further processing on auto approval
    * @return : void
    */
    public void processAutoApprovedRequests(List<Partner_Registration_Request__c> newRequestList){
        List<Partner_Registration_Request__c> PartRegList = new List<Partner_Registration_Request__c>();
        for(Partner_Registration_Request__c PR_Request : newRequestList){
            if(PR_Request.Auto_Approval__c && PR_Request.Partner_Registration_Status__c == 'Approved'){
                PartRegList.add(PR_Request);
            }
        }
        if(!PartRegList.isEmpty()) {
            PC_PartnerRegistrationRequestService prReqService = new PC_PartnerRegistrationRequestService();
            prReqService.processPR(PartRegList);
        } 
    }
}