trigger OpportunityDebriefTrigger on Opportunity_Debrief__c (before insert,after insert, after update, after delete, after unDelete) {
    new OpportunityDebriefTriggerHandler().run();
}