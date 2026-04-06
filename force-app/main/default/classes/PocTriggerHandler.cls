public class PocTriggerHandler extends TriggerManager.GenericTriggerHandler{
    public override void onBeforeInsert(List<sObject> newRecords) {}    
    public override void onAfterInsert(Map<ID, sObject> newRecordsMap) {
        POCRequestTriggerHelper.updateMostRecentPOCOnOppty((List<POC__c>)Trigger.new);
        POCRequestTriggerHelper.syncPOCLines((Map<Id,POC__c>)Trigger.newMap);
        POCRequestTriggerHelper.addVirtualLabPOCProduct((List<POC__c>)Trigger.new);
    }
    public override void onBeforeUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap) {
        Map<ID, POC__c> oldPocMap = (Map<ID, POC__c>) oldRecordsMap;
        Map<ID, POC__c> newPocMap = (Map<ID, POC__c>) newRecordsMap;
        POCRequestTriggerHelper.onBeforeUpdate(newPocMap, oldPocMap);
    }   
    public override void onAfterUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap) {
        Map<ID, POC__c> oldPocMap = (Map<ID, POC__c>) oldRecordsMap;
        Map<ID, POC__c> newPocMap = (Map<ID, POC__c>) newRecordsMap;
		POCRequestTriggerHelper.updateOrderAndAssetEndDates(newPocMap , oldPocMap);
		POCRequestTriggerHelper.createOrderDetails(newPocMap.values() , oldPocMap);
        POCRequestTriggerHelper.updateOpptyPOCProducts((List<POC__c>)Trigger.new, oldPocMap);
	POCRequestTriggerHelper.updatePOCPhaseonOpportuntiy((List<POC__c>)Trigger.new, oldPocMap);
    }
    public override void onBeforeDelete(Map<ID, sObject> oldRecordsMap) {}    
    public override void onAfterDelete(Map<ID, sObject> oldRecordsMap) {}
}