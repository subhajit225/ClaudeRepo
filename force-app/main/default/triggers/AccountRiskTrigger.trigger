/*
* @Author       :   Sushant Arora
* @CreatedDate  :   10-06-2025
* @Jira Ticket  :   
* @Description  :   Trigger to create and update risk profile on basis of Account
* @Handler      :   AccountRiskTriggerHandler.cls
* @TestClass    :   AccountRiskTriggerHandlerTest.cls
* -------------------------- @History --------------------------------------------------------------------------------------------
* --------------------------------------------------------------------------------------------------------------------------------
*/
trigger AccountRiskTrigger on Account_Risk__c (before insert, before update, after update, after insert, after delete) {
    	    
       new AccountRiskTriggerHandler().handleOperation(
        Trigger.operationType,
        Trigger.new,
        Trigger.old,
        Trigger.newMap,
        Trigger.oldMap
    );

}