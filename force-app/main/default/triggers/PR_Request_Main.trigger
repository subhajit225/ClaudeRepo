trigger PR_Request_Main on Partner_Registration_Request__c (before update, after update, after insert) {
    Map<String,WorkflowTriggerBypass__c> bypassSettings = WorkflowTriggerBypass__c.getAll();
    if(bypassSettings.containsKey('PRRequestMainTrigger') && !bypassSettings.get('PRRequestMainTrigger').ByPassTrigger__c){
        final String errorMsg = 'You are approving a contact to an account that is a customer account, please update the Company Name to a Partner Account';
        if(trigger.isAfter && trigger.isUpdate){
            List<Partner_Registration_Request__c> PartRegList = new List<Partner_Registration_Request__c>();
            Map<Id,List<Id>> prLookupPrRequestIdsMap = new Map<Id,List<Id>>();
            Set<Id> customerAccPrRequestIds = new Set<Id>();
            List<Partner_Registration_Request__c> showErrorRecords = new List<Partner_Registration_Request__c>();
            for(Partner_Registration_Request__c PR_Request : Trigger.New){
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
            for(Partner_Registration_Request__c PR_Request : Trigger.New){
                Partner_Registration_Request__c oldPR = Trigger.oldMap.get(PR_Request.Id);
                //if(PR_Request.is_Converted__c == false &&
                if(oldPR.Partner_Registration_Status__c != PR_Request.Partner_Registration_Status__c 
                    && PR_Request.Partner_Registration_Status__c == 'Approved'){
                        if(customerAccPrRequestIds.contains(PR_Request.Id)){
                            PR_Request.addError(errorMsg);
                        }else{
                            PartRegList.add(PR_Request);
                        }
                    }
            }
            if(!PartRegList.isEmpty()) {
                PR_Request_Service.convertPRtoContact(PartRegList);
            }
        }
    
        if(trigger.isAfter && trigger.isInsert){
            List<Partner_Registration_Request__c> PartRegList = new List<Partner_Registration_Request__c>();
            for(Partner_Registration_Request__c PR_Request : Trigger.New){
                if(PR_Request.Auto_Approval__c && PR_Request.Partner_Registration_Status__c == 'Approved'){
                    PartRegList.add(PR_Request);
                }
            }
            if(!PartRegList.isEmpty()) {
                PR_Request_Service.convertPRtoContact(PartRegList);
            }
        }
    
        // PRIT24-861 : START
        if(Trigger.isBefore && Trigger.isUpdate){
            for(Partner_Registration_Request__c newRequest : Trigger.New){
                Partner_Registration_Request__c oldRequest = Trigger.oldMap.get(newRequest.Id);
                if(oldRequest.Partner_Registration_Status__c != newRequest.Partner_Registration_Status__c && newRequest.Partner_Registration_Status__c == 'Approved' && newRequest.Partner_Account_Lookup__c == null){
                    newRequest.addError('You are not allowed to approve if Partner Account Lookup is blank');
                }
            }
        }
        // PRIT24-861 : END
    }
}