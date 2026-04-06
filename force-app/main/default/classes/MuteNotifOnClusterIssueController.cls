public with sharing class MuteNotifOnClusterIssueController {
    private Cluster_Issue__c issueRecord = new Cluster_Issue__c();

    public MuteNotifOnClusterIssueController(ApexPages.StandardController controller) {
        issueRecord = (Cluster_Issue__c)controller.getRecord();
    }

    public PageReference muteNotifications() {
        issueRecord.Mute_Notifications__c = true;

        try {
            update issueRecord;
        }
        catch(DmlException e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, e.getDmlMessage(0)));
            return null;
        }
        return new PageReference('/'+issueRecord.Id);
    }
}