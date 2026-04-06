/**
 * @description
 * Created as part of SAL26-323.
 * This is the trigger class of Account_Stage__c object.
 */ 
trigger AccountStageTrigger on Account_Stage__c (after update) {
    TriggerManager.invokeHandler(new AccountStageTriggerHandler());
}