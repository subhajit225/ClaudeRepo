trigger EventTrigger on Event (after insert, after update, after delete, 
                                before insert, before update, before delete) {
    if(UserInfo.getUserId() == Label.DisableTriggerUser) return;

    if(!ShGl_DisableBusinessLogic__c.getInstance().Disable_Event_Triggers__c ) {
        TriggerManager.invokeHandler(new EventTriggerHandler());
    }
}