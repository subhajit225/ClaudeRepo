trigger ClusterIssueTrigger on Cluster_Issue__c (before update) {
    if(ClusterIssueTriggerHandler.isFirstRun) {
        ClusterIssueTriggerHandler.updatePriorNotificationOnUnmute(Trigger.new, Trigger.oldMap);
    }
    ClusterIssueTriggerHandler.isFirstRun = false;
}