/**
 * @Description Trigger for Approval Snapshot object
 */
trigger ApprovalSnapshotTrigger on sbaa__ApprovalSnapshot__c (after insert) {
    new ApprovalSnapshotTriggerHandler().run();
}