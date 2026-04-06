/**
* @Author       :   Saakshi Gupta
* @CreatedDate  :   08-08-2022
* @Jira Ticket  :   CS21-1100 - Forums 2.0 Rewards Redemption/Swag Store
* @Description  :   Trigger on Support Forums Order object.
* @TestClass    :   ForumsOrderTriggerHandlerTest
*/
trigger ForumsOrderTrigger on CS_Order__c (before insert, before update, after insert, after update) {
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            ForumsOrderTriggerHandler.setStatusChangeDates(Trigger.new, null);
        }
        else if(Trigger.isUpdate){
            ForumsOrderTriggerHandler.setStatusChangeDates(Trigger.new, Trigger.oldMap);
        }
    }
    else if(Trigger.isAfter){
        if(Trigger.isInsert){
            ForumsOrderTriggerHandler.updateCoinsOnUser(Trigger.new);
        }
        else if(Trigger.isUpdate){
            ForumsOrderTriggerHandler.createTaskForInvoice(Trigger.new, Trigger.oldMap);
        }
    }
}