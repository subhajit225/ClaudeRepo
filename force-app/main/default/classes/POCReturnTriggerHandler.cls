public class POCReturnTriggerHandler extends TriggerManager.GenericTriggerHandler{                                                
    
    public List<POC_Return__c> newList = (List<POC_Return__c>)Trigger.new;
    public List<POC_Return__c> oldList = (List<POC_Return__c>)Trigger.old;
    public Map<Id, POC_Return__c> newMap = (Map<Id, POC_Return__c>)Trigger.newMap;
    public Map<Id, POC_Return__c> oldMap = (Map<Id, POC_Return__c>)Trigger.oldMap;
    
    public override void onBeforeUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap){
        POCReturnTriggerHelper helper = new POCReturnTriggerHelper();
        helper.checkSelfApprovalBeforeApproval(newMap.values(), oldMap );
        helper.checkLocationBeforeApproval(newMap.values(), oldMap );
        helper.mapReturnToPOCOrder( newList );
    }
    public override void onAfterUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap){
        POCReturnTriggerHelper helper = new POCReturnTriggerHelper();
        helper.updateStatusOnPOCRequest(newMap.values(), oldMap );
        helper.returnAssets(newMap.values(), oldMap );
    }
    public override void onBeforeInsert(List<sObject> lstTriggerNew){
        POCReturnTriggerHelper helper = new POCReturnTriggerHelper();
        helper.mapReturnToPOCOrder( newList );
    }
}