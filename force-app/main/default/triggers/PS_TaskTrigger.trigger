trigger PS_TaskTrigger on PS_Task__c (before insert, before update,after insert,after update,after delete) {
    
    if(UserInfo.getUserId() == Label.DisableTriggerUser) return;

    // Control trigger execution
    if(!ShGl_DisableBusinessLogic__c.getInstance().Disable_PS_Task_Triggers__c) {
        system.debug('Trigger execution');
        TriggerManager.invokeHandler(new PS_TaskTriggerHandler()); 
    }
}