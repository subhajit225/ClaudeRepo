/** 
* @Author      : Raveesh Layal
* @CreatedDate : 11th July 2023
* @Description : Add Jira Watchers upon new Assist Request or if a owner is changed.
* @TstClass    : AssistRequestTriggerTest
* @Jira        : CS21-1713
* -------------------------- @History --------------------------------------------------------------------------------------------
* Story Number       Modified By              Date           Description
*                     
* --------------------------------------------------------------------------------------------------------------------------------
*/ 
trigger AssistRequestTrigger on Assist_Request__c (after insert,after update) {
    
    if((trigger.isinsert || trigger.isupdate) && trigger.isafter && !System.isBatch() && !System.isFuture())
    {
        UpdateAssistRqOwnerToJira.updateWatchers(json.serialize(Trigger.NEW),json.serialize(trigger.oldMap),Trigger.IsInsert);
        
    }
    
    
}