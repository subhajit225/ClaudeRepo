public without sharing class ServiceContractAmend_LtngController {
    
    @AuraEnabled
    public static boolean checkAmendmentPermission(){
        boolean checkPer = false;
        system.debug('======IN checkAmendmentPermission======');
        checkPer = FeatureManagement.checkPermission('Service_Contract_Amend_Permission');
        return checkPer;
    }
    @AuraEnabled
    public static boolean checkOrderTypeMethod(Id recordId){
        boolean checktype = true;
        if (recordId != null) {
            ServiceContract srvc =  [SELECT Id, SBQQSC__Order__r.Order_Sub_Type__c FROM ServiceContract  WHERE Id = :recordId LIMIT 1];
            if (srvc.SBQQSC__Order__r.Order_Sub_Type__c == 'GC Offer' || srvc.SBQQSC__Order__r.Order_Sub_Type__c == 'GC Renewal') {
                checktype = false;
            }
        }
        return checktype;
    }
}