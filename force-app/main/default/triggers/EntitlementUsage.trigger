trigger EntitlementUsage on Entitlement_Use__c (after insert, after update, after delete, after undelete) {
    new EntitlementUsageTriggerHandler().run();
}