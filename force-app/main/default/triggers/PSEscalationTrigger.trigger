trigger PSEscalationTrigger on DR_PS_Escalation__c (before update, after update ) {
    if(flowControll.PSEscalationTrigger){
        TriggerManager.invokeHandler(new PSEscalationTriggerHandler());
    }
}