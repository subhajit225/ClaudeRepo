/*
* @Author       :   Saakshi Gupta
* @CreatedDate  :   14-01-2022
* @Class        :   CS_InsightMatchesController.cls
*/
@isTest(seeAllData=false)
public class CS_InsightMatchesControllerTest {

    @testSetup static void setup() {
        List<Account> accountList = new List<Account>();

        Account acc = new Account();
        acc.name = 'Test Account 1';
        acc.Insight_Matches__c = '[{"organizations": [], "severity": "Info", "insight_id": "AX0vGix-EDdRT2pu6NiL", "match_level": "account_id", "insight_title": "Test Insight match title", "insight_key": "INS00437", "tooltip": "Test Insight match tooltip", "proactive": true, "customer_facing": false}]';
        acc.Insight_Matches_Updated__c = System.now();
        insert acc;

        Cluster__c cluster = new Cluster__c();
        cluster.name = 'Test Cluster 1';
        cluster.uuid__c = 'Test Cluster 1';
        cluster.account__c = acc.Id;
        cluster.Insight_Matches__c = '[{"organizations": [], "severity": "Info", "insight_id": "AX0vGix-EDdRT2pu6NiL", "match_level": "cluster_uuid", "insight_title": "Test Insight match title", "insight_key": "INS00437", "tooltip": "Test Insight match tooltip", "proactive": true, "customer_facing": false}]';
        cluster.Insight_Matches_Updated__c = System.now();
        insert cluster;

        Case cs = new case();
        cs.Accountid = acc.id;
        cs.Subject = 'Test Case';
        cs.JIRA_References_URL__c = 'SPARK-123456, SPARK-78910';
        cs.Jira_Reference_urls__c = 'SPARK-123456, SPARK-78910';
        cs.Origin = 'Portal';
        cs.close_survey_triggered__c = false; 
        cs.Article_Created__c = false;
        cs.Resolution_Details__c = 'test';
        cs.Next_Step__c = 'Test';
        cs.Current_Status__c = 'testStatus';
        cs.Priority = 'P1';
        cs.Alert_Key__c = 'Alert case 1 key';
        cs.Cluster__c = cluster.Id;
        insert cs;
    }

    public static testmethod void testGetAccountInsightMatchesWrapper(){
        Account acc = [SELECT Id FROM Account];

        CS_InsightMatchesController.InsightMatchesWrapper resultWrapper = new CS_InsightMatchesController.InsightMatchesWrapper();

        Test.startTest();
            resultWrapper = CS_InsightMatchesController.getInsightMatchesWrapper(acc.Id, 'Account');
            CS_InsightMatchesController.InsightMatch insightMatchObject = new CS_InsightMatchesController.InsightMatch();
        Test.stopTest();

        System.assertNotEquals(null, resultWrapper.accountfocusUpdatedDate);
        System.assertEquals(null, resultWrapper.clusterfocusUpdatedDate);
        System.assertEquals(1, resultWrapper.insightMatchesList.size());
    }

    public static testmethod void testGetClusterInsightMatchesWrapper(){
        Cluster__c cluster = [SELECT Id FROM Cluster__c];

        CS_InsightMatchesController.InsightMatchesWrapper resultWrapper = new CS_InsightMatchesController.InsightMatchesWrapper();

        Test.startTest();
            resultWrapper = CS_InsightMatchesController.getInsightMatchesWrapper(cluster.Id, 'Cluster__c');
        Test.stopTest();

        System.assertEquals(null, resultWrapper.accountfocusUpdatedDate);
        System.assertNotEquals(null, resultWrapper.clusterfocusUpdatedDate);
        System.assertEquals(1, resultWrapper.insightMatchesList.size());
    }

    public static testmethod void testGetCaseInsightMatchesWrapper(){
        Case caseRecord = [SELECT Id FROM Case];

        CS_InsightMatchesController.InsightMatchesWrapper resultWrapper = new CS_InsightMatchesController.InsightMatchesWrapper();

        Test.startTest();
            resultWrapper = CS_InsightMatchesController.getInsightMatchesWrapper(caseRecord.Id, 'Case');
        Test.stopTest();

        System.assertNotEquals(null, resultWrapper.accountfocusUpdatedDate);
        System.assertNotEquals(null, resultWrapper.clusterfocusUpdatedDate);
        System.assertEquals(2, resultWrapper.insightMatchesList.size());
    }

    @IsTest 
    static void testgetAccountClusters(){
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account 1' Limit 1];
        Case objCase = [SELECT Id, Cluster__c FROM Case WHERE AccountId =: acc.Id];
        objCase.Cluster__c = null;
        update objCase;

        CS_InsightMatchesController.InsightMatchesWrapper resultWrapper = new CS_InsightMatchesController.InsightMatchesWrapper();

        Test.startTest();
            resultWrapper = CS_InsightMatchesController.getInsightMatchesWrapper(objCase.Id, 'Case');
            CS_InsightMatchesController.InsightMatch insightMatchObject = new CS_InsightMatchesController.InsightMatch();
        Test.stopTest();

        System.assertNotEquals(0, resultWrapper.accountClustersCount);
    }
}