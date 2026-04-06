trigger AARObjectTrigger on After_Action_Review__c (before insert, after insert, after update) {
    if(flowcontroll.AARTrigger){
        if(Trigger.isBefore && Trigger.isInsert) {
            AARObjectTriggerHandler.checkForExistingAARs(Trigger.New);
        }
    
        if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate) && AARObjectTriggerHandler.isOppsUpdated == false) {
            AARObjectTriggerHandler.syncAAROpportunity(Trigger.New,Trigger.isInsert);
        }
    }
}