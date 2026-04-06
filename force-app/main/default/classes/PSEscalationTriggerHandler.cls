public without sharing class PSEscalationTriggerHandler extends TriggerManager.GenericTriggerHandler{
    PSEscalationTriggerHelper helper;

    private Map<Id, DR_PS_Escalation__c> newMap;
    private Map<Id, DR_PS_Escalation__c> oldMap;

    public PSEscalationTriggerHandler() {
        helper = new PSEscalationTriggerHelper();
        newMap = (Map<Id, DR_PS_Escalation__c>) Trigger.newMap;
        oldMap = (Map<Id, DR_PS_Escalation__c>) Trigger.oldMap;
    }

    public override void onBeforeUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap) {
        helper.populateRejectionReason(oldMap, newMap);
        helper.onApprovalActions(oldMap, newMap);
    }
    
    public override void onAfterUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap){
        helper.processRecords(oldMap,newMap);
        helper.afterApprovalActions(oldMap,newMap);
    }
}