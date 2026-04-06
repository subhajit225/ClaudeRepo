public without sharing class ClusterIssueTriggerHandler {
    public static Boolean isFirstRun = true;

    public static void updatePriorNotificationOnUnmute(List<Cluster_Issue__c> newClusterIssueList,
                                                        Map<Id, Cluster_Issue__c> oldClusterIssueMap) {
        Cluster_Issue__c oldRecord = new Cluster_Issue__c();

        for(Cluster_Issue__c eachIssue : newClusterIssueList) {
            oldRecord = oldClusterIssueMap.get(eachIssue.Id);

            if(eachIssue.Mute_Notifications__c && !oldRecord.Mute_Notifications__c && eachIssue.Next_Notification_Date_Time__c != null) {
                eachIssue.Prior_Next_Notification_Date_Time__c = eachIssue.Next_Notification_Date_Time__c;
            }
        }
    }
}