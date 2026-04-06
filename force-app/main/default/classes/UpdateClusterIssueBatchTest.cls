@isTest(seeAllData=false)
public class UpdateClusterIssueBatchTest {
    public static testMethod void testUpdateClusterIssueBatch() {
        List<User> userList = new List<User>();

        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'Sales Operations'].Id;
        User userRecord = new User(
            ProfileId = profileId,
            LastName = 'last',
            Email = 'testuser@test.com',
            Username = System.now().millisecond() + 'testuser@test.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Employee_Time_Off__c = true);
        insert userRecord;

        Account acc = new Account(name='testAcc', OwnerId = userRecord.Id);
        insert acc;

        List<Cluster__c> clusterList = new List<Cluster__c>();
        Cluster__c clusterRecord = new Cluster__c();
        clusterRecord.Name = 'Test Cluster1';
        clusterRecord.uuid__c = 'Test Cluster1';
        clusterRecord.account__c = acc.Id;
        clusterRecord.Tentative_Date_for_100_Capacity__c = System.today() + 20;
        clusterList.add(clusterRecord);

        clusterRecord = new Cluster__c();
        clusterRecord.Name = 'Test Cluster2';
        clusterRecord.uuid__c = 'Test Cluster2';
        clusterRecord.account__c = acc.Id;
        clusterRecord.Tentative_Date_for_100_Capacity__c = System.today() + 100;
        clusterList.add(clusterRecord);

        insert clusterList;

        List<Cluster_Issue__c> clusterIssueList = new List<Cluster_Issue__c>();
        Cluster_Issue__c clusterIssueRecord = new Cluster_Issue__c();
        clusterIssueRecord.Cluster__c = clusterList[0].Id;
        clusterIssueRecord.Account__c = acc.Id;
        clusterIssueRecord.Account_Owner__c = acc.OwnerId;
        clusterIssueRecord.Priority__c = 'P2';
        clusterIssueRecord.Status__c = 'Open';
        clusterIssueRecord.Owner__c = acc.OwnerId;
        clusterIssueList.add(clusterIssueRecord);

        clusterIssueRecord = new Cluster_Issue__c();
        clusterIssueRecord.Cluster__c = clusterList[1].Id;
        clusterIssueRecord.Account__c = acc.Id;
        clusterIssueRecord.Account_Owner__c = acc.OwnerId;
        clusterIssueRecord.Priority__c = 'P3';
        clusterIssueRecord.Status__c = 'Open';
        clusterIssueRecord.Owner__c = acc.OwnerId;
        clusterIssueList.add(clusterIssueRecord);

        insert clusterIssueList;

        User currentUser = [SELECT Id FROM User WHERE Id =: UserInfo.getUserId()];

        System.runAs(userRecord) {
            acc.OwnerId = currentUser.Id;
            acc.Rubrik_Sales_Engineer__c = currentUser.Id;
            update acc;
        }

        clusterList[0].Tentative_Date_for_100_Capacity__c = System.today() + 10;
        clusterList[1].Tentative_Date_for_100_Capacity__c = System.today() + 80;
        update clusterList;

        Test.startTest();

        Database.executeBatch(new UpdateClusterIssueOnCapacityChangeBatch(), 200);

        Test.stopTest();

        Cluster_Issue__c clusterIssue = [SELECT Id, Owner__c FROM Cluster_Issue__c LIMIT 1];
        System.assert(clusterIssue.Owner__c == currentUser.Id);
    }
}