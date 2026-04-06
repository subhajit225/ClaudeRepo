@isTest(seeAllData=false)
public class MuteNotifOnClusterIssueTest {
    public static testMethod void testMuteNotifOnClusterIssueTest() {
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

        Test.startTest();

        ApexPages.StandardController sc = new ApexPages.StandardController(clusterIssueRecord);
        MuteNotifOnClusterIssueController controllerObject = new MuteNotifOnClusterIssueController(sc);

        PageReference pageRef = Page.MuteNotificationsOnClusterIssue;
        Test.setCurrentPage(pageRef);

        PageReference recordRef = controllerObject.muteNotifications();
        System.assert(recordRef != null);

        clusterIssueRecord.Status__c = 'Opened';

        ApexPages.StandardController sc2 = new ApexPages.StandardController(clusterIssueRecord);
        MuteNotifOnClusterIssueController controllerObject2 = new MuteNotifOnClusterIssueController(sc2);

        PageReference pageRef2 = Page.MuteNotificationsOnClusterIssue;
        Test.setCurrentPage(pageRef2);

        PageReference recordRef2 = controllerObject2.muteNotifications();
        System.assert(recordRef2 == null);

        Test.stopTest();
    }
}