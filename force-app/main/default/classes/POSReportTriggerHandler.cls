public without sharing class POSReportTriggerHandler extends TriggerManager.GenericTriggerHandler {
    
    public override void onBeforeInsert(List<sObject> newRecords) {    
        //SAL25-65
        List<POS_Report__c> newPOSRecords = (List<POS_Report__c>)newRecords;
        POSReportTriggerHelper.populatePOSReportFields(newPOSRecords, null);
    }
    
    public override void onBeforeUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap){
        //SAL25-65
        Map<ID, POS_Report__c> oldPOSMap = (Map<ID, POS_Report__c>) oldRecordsMap;
        List<POS_Report__c> newPOSRecords = (List<POS_Report__c>) newRecordsMap.values();
        POSReportTriggerHelper.populatePOSReportFields(newPOSRecords, oldPOSMap);
    }
    public override void onAfterInsert(Map<ID, sObject> newRecordsMap){
        POSReportTriggerHelper.populatePOSReportFieldsAfterInsertUpdate((List<POS_Report__c>)newRecordsMap.values(), null);//SAL26-79
    }    
    public override void onAfterUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap){
        POSReportTriggerHelper.populatePOSReportFieldsAfterInsertUpdate((List<POS_Report__c>) newRecordsMap.values(), (Map<ID, POS_Report__c>) oldRecordsMap);//SAL26-79
    }
    public override void onBeforeDelete(Map<ID, sObject> oldRecordsMap){
        
    }
}