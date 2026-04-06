@isTest(SeeAllData=false)
public class ZSFJIRAZIssueCaseTriggerServiceTest {
    
    @testSetup
    static void testSetUp() {
        insert new TriggerControl__c(Name='ZissueCaseJiraReferenceHyper');        
        
        zsfjira__ZIssue__c jiraIssue = new zsfjira__ZIssue__c();
        jiraIssue.zsfjira__IssueId__c = 1002;
        jiraIssue.zsfjira__IssueKey__c = 'CDM-10';
        jiraIssue.zsfjira__Status__c = 'Open';
        jiraIssue.zsfjira__IssueType__c='Improvement';
        insert jiraIssue;
        
        Contact contact = new Contact();
        contact.Email = 'test@example.com';
        contact.FirstName = 'test';
        contact.LastName = 'example';
        insert contact;
        
         
        Case testCase = new Case();
        testCase.Subject = 'Test case to validate jira references';
        testCase.ContactId = contact.Id;
        testCase.Priority = 'P1';
        testCase.Jira_Reference_urls__c = 'test urls';
        insert testCase;
         
        Assist_Request__c ar= new Assist_Request__c(Case__c=testCase.ID,Status__c = 'Open',Brownbag_Candidate__c=true);
        insert ar;
        zsfjira__ZIssue_Case__c caseIssue = new zsfjira__ZIssue_Case__c();
        caseIssue.zsfjira__ZIssueId__c = jiraIssue.Id;
        caseIssue.zsfjira__CaseId__c = testCase.Id;
        insert caseIssue;
    }
    
    @istest
    static void insertReferenceTest() {

        String jiraUrl = ZSFJIRAZIssueCaseTriggerService.JIRA_PROD_URL;
        if(ZSFJIRAZIssueCaseTriggerService.IS_SANDBOX){
            jiraUrl = System.Label.JIRA_Sandbox_Base_URL;
        }

        List<Case> cases = [SELECT Id, Jira_Reference_urls__c FROM Case LIMIT 1];
        System.assertEquals('<a href="'+jiraUrl+'CDM-10" target="_blank">CDM-10</a>', cases[0].Jira_Reference_urls__c);
        
        test.startTest();
        zsfjira__ZIssue__c jiraIssue = new zsfjira__ZIssue__c();
        jiraIssue.zsfjira__IssueId__c = 1003;
        jiraIssue.zsfjira__IssueKey__c = 'CDM-11';
        jiraIssue.zsfjira__Status__c = 'Open';
        insert jiraIssue;
        
        zsfjira__ZIssue_Case__c caseIssue = new zsfjira__ZIssue_Case__c();
        caseIssue.zsfjira__ZIssueId__c = jiraIssue.Id;
        caseIssue.zsfjira__CaseId__c = cases[0].Id;
        insert caseIssue;        
        
        test.stopTest();
        
        String expectedReference = '<a href="'+jiraUrl+'CDM-10" target="_blank">CDM-10</a>';
        expectedReference += ',<a href="'+jiraUrl+'CDM-11" target="_blank">CDM-11</a>';
        cases = [SELECT Id, Jira_Reference_urls__c FROM Case LIMIT 1];
        System.assertEquals(expectedReference, cases[0].Jira_Reference_urls__c);
    }
    
    @istest
    static void deleteReferenceTest() {
        String jiraUrl = ZSFJIRAZIssueCaseTriggerService.JIRA_PROD_URL;
        if(ZSFJIRAZIssueCaseTriggerService.IS_SANDBOX){
            jiraUrl = System.Label.JIRA_Sandbox_Base_URL;
        }

        List<Case> cases = [SELECT Id, Jira_Reference_urls__c FROM Case LIMIT 1];
        
        test.startTest();
        zsfjira__ZIssue__c jiraIssue = new zsfjira__ZIssue__c();
        jiraIssue.zsfjira__IssueId__c = 1003;
        jiraIssue.zsfjira__IssueKey__c = 'CDM-11';
        jiraIssue.zsfjira__Status__c = 'Open';
        jiraIssue.zsfjira__IssueType__c='Improvement';
        insert jiraIssue;
        
        zsfjira__ZIssue_Case__c caseIssue = new zsfjira__ZIssue_Case__c();
        caseIssue.zsfjira__ZIssueId__c = jiraIssue.Id;
        caseIssue.zsfjira__CaseId__c = cases[0].Id;
        insert caseIssue;        
        
        Delete [SELECT Id FROM zsfjira__ZIssue_Case__c WHERE zsfjira__ZIssueId__c = :jiraIssue.Id];
        
        cases = [SELECT Id, Jira_Reference_urls__c FROM Case LIMIT 1];        
        String expectedReference = '<a href="'+jiraUrl+'CDM-10" target="_blank">CDM-10</a>';
        System.assertEquals(expectedReference, cases[0].Jira_Reference_urls__c);
        
        Delete [SELECT Id FROM zsfjira__ZIssue_Case__c LIMIT 1];
        
        cases = [SELECT Id, Jira_Reference_urls__c FROM Case LIMIT 1];
        System.assertEquals(null, cases[0].Jira_Reference_urls__c);
        test.stopTest();
    }

}