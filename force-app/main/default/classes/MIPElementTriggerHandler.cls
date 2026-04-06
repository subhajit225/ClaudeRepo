public without sharing class MIPElementTriggerHandler extends TriggerManager.GenericTriggerHandler{
    MIPElementTriggerHelper eleHelper;

    private List<MIP_ELement__c> newList = (List<MIP_ELement__c>)Trigger.new;
    private List<MIP_ELement__c> oldList = (List<MIP_ELement__c>)Trigger.old;
    private Map<Id, MIP_ELement__c> newMap = (Map<Id, MIP_ELement__c>)Trigger.newMap;
    private Map<Id, MIP_ELement__c> oldMap = (Map<Id, MIP_ELement__c>)Trigger.oldMap;

    public MIPElementTriggerHandler() {
        eleHelper = new MIPElementTriggerHelper();
    }

    public override void onBeforeInsert(List<sObject> newRecords){
    }

    public override void onAfterInsert(Map<ID, sObject> newRecordsMap){
        eleHelper.populateBookingsTotals(newMap);
    }

    public override void onBeforeUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap){
    }

    public override void onAfterUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap){
        eleHelper.calculateBookingsTotals(newList,oldMap);
    }
}