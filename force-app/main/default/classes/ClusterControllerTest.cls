@isTest(seeAllData=false)
public class ClusterControllerTest {
    public static testMethod void testClusterControllerTest() {
        Account acc = new Account(name='testAcc', OwnerId = UserInfo.getUserId());
        insert acc;

        Cluster__c clusterRecord = new Cluster__c();
        clusterRecord.Name = 'Test Cluster1';
        clusterRecord.uuid__c = 'Test Cluster1';
        clusterRecord.account__c = acc.Id;
        clusterRecord.Tentative_Date_for_100_Capacity__c = System.today() + 20;
        clusterRecord.Capacity_Snapshot__c = 100;
        clusterRecord.Capacity_System__c = 100;
        clusterRecord.Capacity_Total__c = 200;
        insert clusterRecord;

        Test.startTest();

        ApexPages.StandardController sc = new ApexPages.StandardController(clusterRecord);
        ClusterController controllerObject = new ClusterController(sc);

        PageReference pageRef = Page.ClusterChart;
        Test.setCurrentPage(pageRef);

        System.assert(controllerObject.payLoad != null);

        Test.stopTest();
    }
}