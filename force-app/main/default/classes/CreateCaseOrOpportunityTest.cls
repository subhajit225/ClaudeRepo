@isTest(seeAllData=false)
public class CreateCaseOrOpportunityTest {
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

    public static testMethod void testCreateCase() {
        Cluster_Issue__c clusterIssueRecord = [SELECT Id FROM Cluster_Issue__c];

        Test.startTest();

        PageReference pageRef = Page.CreateCaseOrOpportunityPage;
        pageRef.getParameters().put('id', clusterIssueRecord.Id);
        pageRef.getParameters().put('object', 'Case');
        Test.setCurrentPage(pageRef);

        ApexPages.StandardController sc = new ApexPages.StandardController(clusterIssueRecord);
        CreateCaseOrOpportunityController controllerObject = new CreateCaseOrOpportunityController(sc);

        controllerObject.createCaseOrOpportunity();

        Cluster_Issue__c newClusterIssueRecord = [SELECT Id, Case__c FROM Cluster_Issue__c];
        System.assert(newClusterIssueRecord.Case__c != null);

        controllerObject.redirectToCreatedRecord();

        Test.stopTest();
    }

    public static testMethod void testCreateOpportunity() {
        Cluster_Issue__c clusterIssueRecord = [SELECT Id FROM Cluster_Issue__c];

        Test.startTest();

        PageReference pageRef = Page.CreateCaseOrOpportunityPage;
        pageRef.getParameters().put('id', clusterIssueRecord.Id);
        pageRef.getParameters().put('object', 'Opportunity');
        Test.setCurrentPage(pageRef);

        ApexPages.StandardController sc = new ApexPages.StandardController(clusterIssueRecord);
        CreateCaseOrOpportunityController controllerObject = new CreateCaseOrOpportunityController(sc);

        controllerObject.createCaseOrOpportunity();

        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
        upsert disableFuncCS;

        controllerObject.createCaseOrOpportunity();

        Cluster_Issue__c newClusterIssueRecord = [SELECT Id, Opportunity__c FROM Cluster_Issue__c];
        System.assert(newClusterIssueRecord.Opportunity__c != null);

        Test.stopTest();
    }
}