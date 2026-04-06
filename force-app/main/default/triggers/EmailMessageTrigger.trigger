trigger EmailMessageTrigger on EmailMessage (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    //calling trigger handler
    EmailMessageHandler.handleTrigger(trigger.new, trigger.old, trigger.newMap, trigger.oldMap, trigger.OperationType);
}