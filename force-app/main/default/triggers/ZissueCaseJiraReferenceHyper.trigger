trigger ZissueCaseJiraReferenceHyper on zsfjira__ZIssue_Case__c (after insert, after update, after delete) {
    //call trigger handler class
    ZSFJIRAZIssueCaseTriggerHandler.run(Trigger.new, Trigger.old, Trigger.oldMap, Trigger.operationType);
}