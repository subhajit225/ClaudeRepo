trigger MIPElementTrigger on MIP_Element__c (before insert, before update, before delete, after insert, after update, after delete) {
    if(flowControll.MIPElementTrigger){
        TriggerManager.invokeHandler(new MIPElementTriggerHandler());
    }
}