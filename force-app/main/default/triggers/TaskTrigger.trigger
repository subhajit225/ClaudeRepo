trigger TaskTrigger on Task (before insert, before update, before delete, after insert, after update, after delete) {

    ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance();
    if(disabled.Disable_Task_Triggers__c || !flowControll.TaskTrigger){
        return;
    }
    TriggerManager.invokeHandler(new TaskObjectTriggerHandler());
    //new TaskTriggerHandler().run();
}