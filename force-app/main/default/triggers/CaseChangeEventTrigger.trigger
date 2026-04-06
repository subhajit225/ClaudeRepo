trigger CaseChangeEventTrigger on Case_Change_Event__e (after insert) {
    CaseChangeEventTriggerHandler.afterInsert(Trigger.new);
}