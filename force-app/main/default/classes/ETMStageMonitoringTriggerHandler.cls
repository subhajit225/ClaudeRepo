public with sharing class ETMStageMonitoringTriggerHandler extends TriggerManager.GenericTriggerHandler{
    public override void onBeforeInsert(List<sObject> newRecords) {
        updateStageName(newRecords);
    }
    public override void onBeforeUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap) {
        updateStageName(newRecordsMap.values());
    }
    public void updateStageName(List<sObject> newRecords){
        List<ETMStage_Monitoring__c> etmStageList = (List<ETMStage_Monitoring__c>) newRecords;
        List<Territory2Model> territoryModel = [Select Id, Name from Territory2Model where State = 'Active' limit 1];
        for(ETMStage_Monitoring__c esm :etmStageList){
            if(esm.Status__c == 'New'){
                if(!territoryModel.isEmpty()) esm.Name = territoryModel[0].Name;
                else esm.addError('There is no active Territory Model found. Please contact System Admin.');
            }
        }
    }
}