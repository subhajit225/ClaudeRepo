/**
 * @description
 * Added as part of SAL26-323.
 * This Apex class is the handler class of Account_Stage__c object.
 */ 
public without sharing class AccountStageTriggerHandler extends TriggerManager.GenericTriggerHandler {
    /** 
     * @description
     * @param oldRecordsMap
     * @param newRecordsMap
     * SAL26-323 Method to perform any after update operation
     */
    public override void onAfterUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap){
        List<Account_Stage__c> newAccountStage =(List<Account_Stage__c>)newRecordsMap.values();
        Map<Id,Account_Stage__c> oldAccountStage =(Map<Id,Account_Stage__c>)oldRecordsMap;
        AccountStageTriggerHelper.updateAccountStageStatus(oldAccountStage, newAccountStage);
    }
}