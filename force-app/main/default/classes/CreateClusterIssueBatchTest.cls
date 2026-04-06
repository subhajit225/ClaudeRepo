@isTest(seeAllData=false)
public class CreateClusterIssueBatchTest {
    public static testMethod void testCreateClusterIssueBatch() {
        Account acc = new Account(name='testAcc', Type='Customer');
        insert acc;

        List<Cluster__c> clusterList = new List<Cluster__c>();
        Cluster__c clusterRecord = new Cluster__c();
        clusterRecord.Name = 'Test Cluster1';
        clusterRecord.uuid__c = 'Test Cluster1';
        clusterRecord.account__c = acc.Id;
        clusterRecord.Tentative_Date_for_100_Capacity__c = System.today() + 3;
        clusterList.add(clusterRecord);

        clusterRecord = new Cluster__c();
        clusterRecord.Name = 'Test Cluster2';
        clusterRecord.uuid__c = 'Test Cluster2';
        clusterRecord.account__c = acc.Id;
        clusterRecord.Tentative_Date_for_100_Capacity__c = System.today() + 20;
        clusterList.add(clusterRecord);

        clusterRecord = new Cluster__c();
        clusterRecord.Name = 'Test Cluster3';
        clusterRecord.uuid__c = 'Test Cluster3';
        clusterRecord.account__c = acc.Id;
        clusterRecord.Tentative_Date_for_100_Capacity__c = System.today() + 100;
        clusterList.add(clusterRecord);

        clusterRecord = new Cluster__c();
        clusterRecord.Name = 'Test Cluster4';
        clusterRecord.uuid__c = 'Test Cluster4';
        clusterRecord.account__c = acc.Id;
        clusterRecord.Tentative_Date_for_100_Capacity__c = System.today() + 200;
        clusterList.add(clusterRecord);

        insert clusterList;

        Test.startTest();

        Database.executeBatch(new CreateClusterIssueBatch(), 200);

        Test.stopTest();

        List<Cluster_Issue__c> clusterIssueList = [SELECT Id FROM Cluster_Issue__c];
        System.assert(clusterIssueList.size() == 3);
    }
}