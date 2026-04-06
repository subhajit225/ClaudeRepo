public with sharing class HeatMapEntryTriggerHandler extends TriggerManager.GenericTriggerHandler{

    private List<HeatMap_Entry__c> newList = (List<HeatMap_Entry__c>)Trigger.new;
    private List<HeatMap_Entry__c> oldList = (List<HeatMap_Entry__c>)Trigger.old;
    private Map<Id, HeatMap_Entry__c> newMap = (Map<Id, HeatMap_Entry__c>)Trigger.newMap;
    private Map<Id, HeatMap_Entry__c> oldMap = (Map<Id, HeatMap_Entry__c>)Trigger.oldMap;

    HeatMapEntryTriggerHelper helper;

    public HeatMapEntryTriggerHandler() {
        helper = new HeatMapEntryTriggerHelper();
    }

    public override void onBeforeInsert(List<sObject> newRecords){
        helper.populateHeatMapEntryData(newList);
    }
}