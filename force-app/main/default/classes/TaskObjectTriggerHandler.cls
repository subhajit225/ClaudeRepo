public with sharing class TaskObjectTriggerHandler extends TriggerManager.GenericTriggerHandler {
    
    public override void onBeforeInsert(List<sObject> newRecordList) {
        List<Task> newList = (List<Task>) newRecordList;
        TaskObjectTriggerHelper.resetFieldsValue(newList, null);
        TaskObjectTriggerHelper.updateBundleFeaturesForPolarisTasks(newList);
        TaskObjectTriggerHelper.populateTerritoryAndSegment(newList, null);
        TaskObjectTriggerHelper.setInOutActivityType(newList);
    }
    
    public override void onAfterInsert(Map<ID, sObject> newRecordsMap) {
        Map<ID, Task> newMap = (Map<ID, Task>) newRecordsMap;
        TaskObjectTriggerHelper.updateLeadAndContacts(newMap,true);
          //Mkt23-419 Comment//
        TaskObjectTriggerHelper.updateLeadContactDataAfterInsert(Trigger.new);
    }
    public override void onBeforeUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap){
        Map<ID, Task> oldMap = (Map<ID, Task>) oldRecordsMap;
        Map<ID, Task> newMap = (Map<ID, Task>) newRecordsMap;
        TaskObjectTriggerHelper.resetFieldsValue(newMap.values(), oldMap);
        TaskObjectTriggerHelper.populateTerritoryAndSegment(newMap.values(), oldMap);
    }
        
    public override void onAfterUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap) {
        Map<ID, Task> oldMap = (Map<ID, Task>) oldRecordsMap;
        List<Task> newList = (List<Task>) newRecordsMap.values();
        Map<ID, Order> orderMapToUpdate = new Map<ID, Order>();
         TaskObjectTriggerHelper.updateLeadContactDataUpdate(newList,oldMap);
        if(!orderMaptoUpdate.isEmpty()){
            update orderMaptoUpdate.values();
        }        
       // TaskObjectTriggerHelper.updateLeadAndDealRegistration(newList, oldMap); // Commented as part of PRIT24-27
    }
    public override void onAfterDelete(Map<ID, sObject> oldRecordsMap) {
        Map<ID, Task> oldMap = (Map<ID, Task>) oldRecordsMap;
        TaskObjectTriggerHelper.updateLeadAndContacts(oldMap,false);
    }
    
}