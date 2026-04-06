@isTest
public class JiraCSVUploadControllerTest {
    @testSetup static void dataSetup() {
        //Creating Account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.Account_Preference__c = 'Advisory Account; Critical Account; CSM Account';
        act.Heads_Up_to_Support_Team__c = 'Hello';
        act.Strategic_Account__c =  true;
        insert act;

        //Creating Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => act.Id
                };
                    Contact con = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert con;

        ////Creating Case
        List<Case>  caseList= New List<Case>();
        Map<String, Object> caseMap = new Map<String, Object> {
            'Subject' => 'testing one more',
                'ContactId' => con.Id,
                'Jira_Reference_urls__c' => 'test',
                'Last_Case_Status__c' => 'Customer requested close',
                'Priority' => 'P2',
                'close_survey_triggered__c' => false,
                'Resolution__c' => 'Hardware problem',
                'Special_Handling_Instructions__c' => act.Heads_Up_to_Support_Team__c,
                'AccountId' => act.Id

                };
                    Case caseTest = (Case) ShGl_TestFactory.createSObject(new Case(), caseMap);
        caseList.add(caseTest);

        Map<String, Object> caseMap1 = new Map<String, Object> {
            'Subject' => 'testing Case 2',
                'ContactId' => con.Id,
                'Jira_Reference_urls__c' => 'test',
                'Last_Case_Status__c' => 'Customer requested close',
                'Priority' => 'P2',
                'close_survey_triggered__c' => false,
                'Resolution__c' => 'Hardware problem',
                'Special_Handling_Instructions__c' => act.Heads_Up_to_Support_Team__c,
                'AccountId' => act.Id
                };

                    Case caseTest1 = (Case) ShGl_TestFactory.createSObject(new Case(), caseMap1);
        caseList.add(caseTest1);

        Map<String, Object> caseMap2 = new Map<String, Object> {
            'Subject' => 'testing Case 3',
                'ContactId' => con.Id,
                'Jira_Reference_urls__c' => 'test',
                'Last_Case_Status__c' => 'Customer requested close',
                'Priority' => 'P2',
                'close_survey_triggered__c' => false,
                'Resolution__c' => 'Hardware problem',
                'Special_Handling_Instructions__c' => act.Heads_Up_to_Support_Team__c,
                'AccountId' => act.Id
                };

                    Case caseTest2 = (Case) ShGl_TestFactory.createSObject(new Case(), caseMap2);
        caseList.add(caseTest2);

        insert caseList;

        //Creating Aha Idea
        List<Aha_Ideas__c> ahaIdeaList = New List<Aha_Ideas__c>();
        Aha_Ideas__c ai1 = new Aha_Ideas__c();
        ai1.name = 'Idea Parent Test Record';
        ai1.Aha_Idea_Number__c = '7252627131616179867';
        ai1.Aha_Unique_ID__c = 'GRZWRKSPCE-I-16';
        ai1.Idea_Description__c = 'Account 1 idea 2 (Case)';
        ai1.Status__c = 'New';
        ai1.Aha_Idea_Origin__c = String.valueof(caseList[0].Id);
        ahaIdeaList.Add(ai1);

        Aha_Ideas__c ai = new Aha_Ideas__c();
        ai.name = 'Idea Parent Test Record';
        ai.Aha_Idea_Number__c = '7252627131616171212';
        ai.Aha_Unique_ID__c = 'GRZWRKSPCE-I-7';
        ai.Idea_Description__c = 'Account 1 idea 2 (Case)';
        ai.Status__c = 'New';
        ai.Duplicate_of__c = ai1.Id;
        ai.Escalation__c = 'No';
        ahaIdeaList.add(ai);

        Aha_Ideas__c ai2 = new Aha_Ideas__c();
        ai2.name = 'Idea Parent Test Record GRZWRKSPCE-I-54';
        ai2.Aha_Idea_Number__c = '7262607553085020750';
        ai2.Aha_Unique_ID__c = 'GRZWRKSPCE-I-54';
        ai2.Idea_Description__c = 'Account 1 GRZWRKSPCE-I-54';
        ai2.Status__c = 'New';
        ahaIdeaList.add(ai2);

        Aha_Ideas__c ai5 = new Aha_Ideas__c();
        ai5.name = 'Idea Parent Test Record GRZWRKSPCE-I-5';
        ai5.Aha_Idea_Number__c = '7249702860024198077';
        ai5.Aha_Unique_ID__c = 'GRZWRKSPCE-I-5';
        ai5.Idea_Description__c = 'Account 1 GRZWRKSPCE-I-5';
        ai5.Status__c = 'New';
        ahaIdeaList.add(ai5);

        INSERT ahaIdeaList;

        Aha_Idea_Link__c idealink = new Aha_Idea_Link__c();
        idealink.Aha_Ideas__c  = ai.Id;
        idealink.Case_Number__c = caseTest1.Id;
        INSERT idealink;

        Aha_Idea_Link__c idealink2 = new Aha_Idea_Link__c();
        idealink2.Aha_Ideas__c  = ai.Id;
        idealink2.Case_Number__c = caseTest2.Id;
        INSERT idealink2;

        List<zsfjira__ZIssue__c> zIssueInsertList = new List<zsfjira__ZIssue__c>();

        zsfjira__ZIssue__c zissueOne = new zsfjira__ZIssue__c();
        zissueOne.zsfjira__Summary__c = 'Test ZissueRecord One';
        zissueOne.zsfjira__IssueKey__c = 'GRZ-1257';
        zissueOne.zsfjira__IssueId__c = 1257;
        zissueOne.Name = 'GRZ-1257';
        zIssueInsertList.add(zissueOne);

        zsfjira__ZIssue__c zissueTwo = new zsfjira__ZIssue__c();
        zissueTwo.zsfjira__Summary__c = 'Test ZissueRecord Two';
        zissueTwo.zsfjira__IssueKey__c = 'GRZ-1258';
        zissueTwo.zsfjira__IssueId__c = 1258;
        zissueTwo.Name = 'GRZ-1258';

        zIssueInsertList.add(zissueTwo);

        zsfjira__ZIssue__c zissueThree = new zsfjira__ZIssue__c();
        zissueThree.zsfjira__Summary__c = 'Test ZissueRecord Three';
        zissueThree.zsfjira__IssueKey__c = 'GRZ-1259';
        zissueThree.zsfjira__IssueId__c = 1259;
        zissueThree.Name = 'GRZ-1259';
        zIssueInsertList.add(zissueThree);

        INSERT zIssueInsertList;
    } //End of Test set up method

    @isTest
    static void testProcessCsvData() {
        Aha_Ideas__c idea1 = [SELECT Id,Aha_Unique_ID__c FROM Aha_Ideas__c WHERE Aha_Unique_ID__c = 'GRZWRKSPCE-I-7' LIMIT 1];

        List<zsfjira__ZIssue__c> zIssueUpdateList = new List<zsfjira__ZIssue__c>();

        zsfjira__ZIssue__c zissueWithNoAhaId = [Select id,zsfjira__IssueKey__c,name from zsfjira__ZIssue__c where name = 'GRZ-1257' LIMIT 1];

        zsfjira__ZIssue__c zissueWithAhaIdInSfdc = [Select id,zsfjira__IssueKey__c,name from zsfjira__ZIssue__c where name = 'GRZ-1258' LIMIT 1];
        zissueWithAhaIdInSfdc.Aha_Unique_Id__c = 'GRZWRKSPCE-I-7';
        zIssueUpdateList.add(zissueWithAhaIdInSfdc);

        zsfjira__ZIssue__c zissueWithAhaIdNotInSfdc = [Select id,zsfjira__IssueKey__c,name from zsfjira__ZIssue__c where name = 'GRZ-1259' LIMIT 1];
        zissueWithAhaIdNotInSfdc.Aha_Unique_Id__c = 'GRZWRKSPCE-I-80';
        zIssueUpdateList.add(zissueWithAhaIdNotInSfdc);

        UPDATE zIssueUpdateList;

        idea1.zIsssue_Number__c = 'GRZ-1258';
        UPDATE idea1;

        Case cs1 = [SELECT Id,CaseNumber FROM Case WHERE Subject = 'testing one more' LIMIT 1];
        Case cs2 = [SELECT Id,CaseNumber FROM Case WHERE Subject = 'testing Case 2' LIMIT 1];
        Case cs3 = [SELECT Id,CaseNumber FROM Case WHERE Subject = 'testing Case 3' LIMIT 1];

        List<zsfjira__ZIssue_Case__c> insertZissueCaseList = new List<zsfjira__ZIssue_Case__c>();

        zsfjira__ZIssue_Case__c zissueandCase = new zsfjira__ZIssue_Case__c();
        zissueandCase.zsfjira__CaseId__c = cs1.Id;
        zissueandCase.zsfjira__ZIssueId__c = zissueWithAhaIdInSfdc.Id;
        insertZissueCaseList.add(zissueandCase);

        zsfjira__ZIssue_Case__c zissueandCase1 = new zsfjira__ZIssue_Case__c();
        zissueandCase1.zsfjira__CaseId__c = cs1.Id;
        zissueandCase1.zsfjira__ZIssueId__c = zissueWithNoAhaId.Id;
        insertZissueCaseList.add(zissueandCase1);

        zsfjira__ZIssue_Case__c zissueandCase2 = new zsfjira__ZIssue_Case__c();
        zissueandCase2.zsfjira__CaseId__c = cs1.Id;
        zissueandCase2.zsfjira__ZIssueId__c = zissueWithAhaIdNotInSfdc.Id;
        insertZissueCaseList.add(zissueandCase2);

        INSERT insertZissueCaseList;

        // Create test data
        List<String> csvLines = new List<String>{
            zissueWithNoAhaId.Name+','+cs1.CaseNumber,
                zissueWithAhaIdInSfdc.Name+','+cs2.CaseNumber,
                zissueWithAhaIdNotInSfdc.Name+','+cs3.CaseNumber,
                'GRZ-1260,'+cs2.CaseNumber,
                zissueWithNoAhaId.Name+','+cs2.CaseNumber,
                zissueWithAhaIdInSfdc.Name+','+cs1.CaseNumber
                };

                    Test.starttest();
        Test.setMock(HttpCalloutMock.class, new HTTPMockTestFactory());
        JiraCSVUploadController.processCsvData(csvLines);
        Test.stopTest();

        List<Aha_Ideas__c> ideainsertinbatch = [SELECT Id,Aha_Unique_ID__c FROM Aha_Ideas__c WHERE Aha_Unique_ID__c= 'GRZWRKSPCE-I-7' ];
        system.debug('ideainsertinbatch zissuewithAhaIdeaIdTest -->' + ideainsertinbatch);
        System.assert(ideainsertinbatch.Size()> 0);
    }

    @isTest
    static void zissuewithAhaIdeaIdTest() {
        Aha_Ideas__c idea1 = [SELECT Id,Aha_Unique_ID__c FROM Aha_Ideas__c WHERE Aha_Unique_ID__c = 'GRZWRKSPCE-I-7' LIMIT 1];

        List<zsfjira__ZIssue__c> zIssueUpdateList = new List<zsfjira__ZIssue__c>();


        zsfjira__ZIssue__c zissueWithAhaIdInSfdc = [Select id,zsfjira__IssueKey__c,name from zsfjira__ZIssue__c where name = 'GRZ-1258' LIMIT 1];
        zissueWithAhaIdInSfdc.Aha_Unique_Id__c = 'GRZWRKSPCE-I-7';
        zIssueUpdateList.add(zissueWithAhaIdInSfdc);

        zsfjira__ZIssue__c zissueWithAhaIdNotInSfdc = [Select id,zsfjira__IssueKey__c,name from zsfjira__ZIssue__c where name = 'GRZ-1259' LIMIT 1];
        zissueWithAhaIdNotInSfdc.Aha_Unique_Id__c = 'GRZWRKSPCE-I-80';
        zIssueUpdateList.add(zissueWithAhaIdNotInSfdc);

        UPDATE zIssueUpdateList;

        idea1.zIsssue_Number__c = 'GRZ-1258';
        UPDATE idea1;

        Case cs1 = [SELECT Id,CaseNumber FROM Case WHERE Subject = 'testing one more' LIMIT 1];
        Case cs2 = [SELECT Id,CaseNumber FROM Case WHERE Subject = 'testing Case 2' LIMIT 1];
        Case cs3 = [SELECT Id,CaseNumber FROM Case WHERE Subject = 'testing Case 3' LIMIT 1];

        zsfjira__ZIssue_Case__c zissueandCase = new zsfjira__ZIssue_Case__c();
        zissueandCase.zsfjira__CaseId__c = cs1.Id;
        zissueandCase.zsfjira__ZIssueId__c = zissueWithAhaIdInSfdc.Id;
        INSERT zissueandCase;

        zsfjira__ZIssue_Case__c zissueandCase1 = new zsfjira__ZIssue_Case__c();
        zissueandCase1.zsfjira__CaseId__c = cs2.Id;
        zissueandCase1.zsfjira__ZIssueId__c = zissueWithAhaIdInSfdc.Id;
        INSERT zissueandCase1;

        // Create test data
        List<String> csvLines = new List<String>{
            zissueWithAhaIdInSfdc.Name+','+cs2.CaseNumber,
                zissueWithAhaIdNotInSfdc.Name+','+cs3.CaseNumber,
                'GRZ-1260,'+cs2.CaseNumber,
                zissueWithAhaIdInSfdc.Name+','+cs1.CaseNumber
                };

                    Test.starttest();
        Test.setMock(HttpCalloutMock.class, new HTTPMockTestFactory());
        JiraCSVUploadController.processCsvData(csvLines);
        Test.stopTest();

        List<Aha_Ideas__c> ideainsertinbatch = [SELECT Id,Aha_Unique_ID__c FROM Aha_Ideas__c WHERE Aha_Unique_ID__c = 'GRZWRKSPCE-I-16' LIMIT 1];
        system.debug('ideainsertinbatch zissuewithAhaIdeaIdTest -->' + ideainsertinbatch);
        System.assert(ideainsertinbatch.Size()> 0);
    }

    @isTest
    static void BatchToUpdateZissueRecordWithAhaIdTest() {
        Aha_Ideas__c idea1 = [SELECT Id,Aha_Unique_ID__c,zIsssue_Number__c FROM Aha_Ideas__c WHERE Aha_Unique_ID__c = 'GRZWRKSPCE-I-5' LIMIT 1];

        zsfjira__ZIssue__c zissueWithAhaIdInSfdc = [Select id,zsfjira__IssueKey__c,name from zsfjira__ZIssue__c where name = 'GRZ-1258' LIMIT 1];

        Test.starttest();
        Test.setMock(HttpCalloutMock.class, new HTTPMockTestFactory());
        BatchToUpdateZissueRecordWithAhaId batch = new BatchToUpdateZissueRecordWithAhaId();
        Id batchJobId = Database.executeBatch(batch);
        Test.stopTest();

        List<Aha_Ideas__c> ideainsertinbatch = [SELECT Id,Aha_Unique_ID__c,zIsssue_Number__c FROM Aha_Ideas__c WHERE Aha_Unique_ID__c = 'GRZWRKSPCE-I-5'];
        system.debug('ideainsertinbatch-->' + ideainsertinbatch);
        System.assert(ideainsertinbatch[0].zIsssue_Number__c == zissueWithAhaIdInSfdc.Name);

    }
}