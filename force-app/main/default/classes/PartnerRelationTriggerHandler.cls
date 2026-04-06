/**
 * @description TriggerHandler for Partner Relation Object
 */
public without sharing class PartnerRelationTriggerHandler extends TriggerManager.GenericTriggerHandler{
    PartnerRelationTriggerHelper eleHelper;

    private List<Partner_Relation__c> newList = (List<Partner_Relation__c>)Trigger.new;
    private List<Partner_Relation__c> oldList = (List<Partner_Relation__c>)Trigger.old;
    private Map<Id, Partner_Relation__c> newMap = (Map<Id, Partner_Relation__c>)Trigger.newMap;
    private Map<Id, Partner_Relation__c> oldMap = (Map<Id, Partner_Relation__c>)Trigger.oldMap;

    /**
     * @description Constructor for PartnerRelationTriggerHandler
     */
    public PartnerRelationTriggerHandler() {
        eleHelper = new PartnerRelationTriggerHelper();
    }

    public override void onBeforeInsert(List<sObject> newRecords){
        system.debug(LoggingLevel.DEBUG, 'onBeforeInsert'+newRecords);
        PartnerRelationTriggerHelper.checkDuplicates(null,newList);
        //PRIT26-107
        //PartnerRelationTriggerHelper.updatePartnerRelationFields(null, newList);
    }
    
    public override void onBeforeUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap){
        system.debug(LoggingLevel.DEBUG, 'onBeforeUpdate'+newRecordsMap);
        PartnerRelationTriggerHelper.checkDuplicates(oldMap, newList);
        //PRIT26-107
        //PartnerRelationTriggerHelper.updatePartnerRelationFields(oldMap, newList);  //SAL26-73     
    }
    
    public override void onBeforeDelete(Map<ID, sObject> oldRecordsMap) {
        system.debug(LoggingLevel.DEBUG, 'onBeforeDelete'+oldRecordsMap);
    }

    public override void onAfterInsert(Map<ID, sObject> newRecordsMap){
        PartnerRelationTriggerHelper.opportunitySDPFieldsGSIMapping(null, newList);
        PartnerRelationTriggerHelper.opportunitySharingToPartnerAccount(null, newList);
    }
    
    public override void onAfterUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap){
        PartnerRelationTriggerHelper.opportunitySDPFieldsGSIMapping(oldMap,newList);
        PartnerRelationTriggerHelper.opportunitySharingToPartnerAccount(oldMap, newList); //SAL26-73
        PartnerRelationTriggerHelper.updateChildSplitPartnerReation(oldMap, newList); //SAL26-72 
    }
    
    public override void onAfterDelete(Map<ID, sObject> oldRecordsMap) {
        system.debug(LoggingLevel.DEBUG, 'onAfterDelete'+oldRecordsMap);
    }
    
    public override void onAfterUnDelete(List<sObject> newRecords) {
        system.debug(LoggingLevel.DEBUG, 'onAfterUnDelete'+newRecords);        
    }
}