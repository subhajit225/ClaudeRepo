public class OpportunityDebriefTriggerHandler extends TriggerHandler{
    public override void beforeInsert() {
        OpportunityDebriefTriggerHelper.updateOwner(Trigger.new);
    }
    public override void afterInsert() {
        OpportunityDebriefTriggerHelper.sendEmail(Trigger.new);
        RollupSummaryUtility.rollupIssueTrackerOnOppty(Trigger.new, null);
    }
    public override void afterUpdate() {
        RollupSummaryUtility.rollupIssueTrackerOnOppty(Trigger.new, (Map<Id, Opportunity_Debrief__c>)Trigger.oldMap);
    }
    public override void afterDelete() {
        System.debug('@@afterDelete');
        RollupSummaryUtility.rollupIssueTrackerOnOppty(Trigger.old, null);
    }
    public override void afterUnDelete() {
        RollupSummaryUtility.rollupIssueTrackerOnOppty(Trigger.new, null);
    }
}