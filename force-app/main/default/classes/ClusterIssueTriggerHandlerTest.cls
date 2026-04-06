@isTest(seeAllData=false)
public class ClusterIssueTriggerHandlerTest {
    @testSetup 
    public static void testDataSetup() {
        Account acc = new Account(name='testAcc', OwnerId = UserInfo.getUserId());
        insert acc;

        Cluster__c clusterRecord = new Cluster__c();
        clusterRecord.Name = 'Test Cluster1';
        clusterRecord.uuid__c = 'Test Cluster1';
        clusterRecord.account__c = acc.Id;
        clusterRecord.Tentative_Date_for_100_Capacity__c = System.today() + 20;
        insert clusterRecord;

        Cluster_Issue__c clusterIssueRecord = new Cluster_Issue__c();
        clusterIssueRecord.Cluster__c = clusterRecord.Id;
        clusterIssueRecord.Account__c = acc.Id;
        clusterIssueRecord.Account_Owner__c = acc.OwnerId;
        clusterIssueRecord.Priority__c = 'P2';
        clusterIssueRecord.Status__c = 'Open';
        clusterIssueRecord.Owner__c = acc.OwnerId;
        insert clusterIssueRecord;
    }
    public static testMethod void testUpdatePriorNotificationOnUnmute() {
        Cluster_Issue__c oldClusterIssueRecord = [SELECT Id, Mute_Notifications__c, Next_Notification_Date_Time__c FROM Cluster_Issue__c];
        oldClusterIssueRecord.Mute_Notifications__c = true;

        Test.startTest();

        update oldClusterIssueRecord;

        Test.stopTest();

        Cluster_Issue__c newClusterIssueRecord = [SELECT Id, Prior_Next_Notification_Date_Time__c FROM Cluster_Issue__c];
        System.assert(oldClusterIssueRecord.Next_Notification_Date_Time__c == newClusterIssueRecord.Prior_Next_Notification_Date_Time__c);
    }
}