public class PS_TaskTriggerHandler extends TriggerManager.GenericTriggerHandler{
    PS_TaskTriggerHelper helper;
    
	public List<PS_Task__c> newList = (List<PS_Task__c>)Trigger.new;
    public List<PS_Task__c> oldList = (List<PS_Task__c>)Trigger.old;
    public Map<Id, PS_Task__c> newMap = (Map<Id, PS_Task__c>)Trigger.newMap;
    public Map<Id, PS_Task__c> oldMap = (Map<Id, PS_Task__c>)Trigger.oldMap;
	
	public PS_TaskTriggerHandler() {
        helper = new PS_TaskTriggerHelper();
    }
	
    public override void onBeforeInsert(List<sObject> newRecords) {
        helper.BeforeInsertHelper(newList);
    }
    public override void onBeforeUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap) {
        helper.BeforeUpdateHelper(newList, oldMap);
    }
    public override void onAfterInsert(Map<ID, sObject> newRecordsMap) {
        helper.updateHas_PSTaskInsert(newList);
    }
    public override void onAfterUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap) { 
        helper.updateHas_PSTaskUpdate(newList, oldMap);
    }
	public override void onAfterDelete(Map<ID, sObject> oldRecordsMap) {
		helper.updateHas_PSTaskDelete(oldMap);
	}
}