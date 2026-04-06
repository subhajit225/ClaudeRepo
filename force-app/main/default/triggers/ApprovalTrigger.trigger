trigger ApprovalTrigger on sbaa__Approval__c (
        before insert, after insert,
        before update, after update,
        before delete, after delete,
        after undelete
) {
    if(!TriggerControl__c.getInstance('Approval').DisableTrigger__c) {
        new ApprovalTriggerHandler().run();
    }
}