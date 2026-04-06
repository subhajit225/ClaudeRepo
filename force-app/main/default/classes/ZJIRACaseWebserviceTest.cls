@isTest(SeeAllData=false)
public class ZJIRACaseWebserviceTest {
    
    @testSetup
    static void testSetUp() {
        insert new TriggerControl__c(Name='ZissueCaseJiraReferenceHyper'); 
        insert new TriggerControl__c(Name='zIssueCDM');
        ZJIRACaseWebservice.byPassCallout = true;
        
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
        
        List<Case> cases = [SELECT CaseNumber FROM Case LIMIT 1];
        
        zsfjira__ZIssue__c jiraIssue = new zsfjira__ZIssue__c();
        jiraIssue.zsfjira__IssueId__c = 1002;
        jiraIssue.zsfjira__IssueKey__c = 'CDM-10';
        jiraIssue.zsfjira__Status__c = 'Open';
        jiraIssue.SalesforceTicket__c = cases[0].CaseNumber;
        jiraIssue.zsfjira__IssueType__c = 'Customer Bug';
        insert jiraIssue;
        
        zsfjira__ZIssue_Case__c caseIssue = new zsfjira__ZIssue_Case__c();
        caseIssue.zsfjira__ZIssueId__c = jiraIssue.Id;
        caseIssue.zsfjira__CaseId__c = testCase.Id;
        insert caseIssue;
    }
    
    @istest
    static void testCallouts() {
        ZJIRACaseWebservice.byPassCallout = true;
        List<Case> cases = [SELECT CaseNumber FROM Case LIMIT 1];
        cases[0].OwnerId = userInfo.getUserId();
        update cases;

        Map<String, Case> caseDetails = new Map<String, Case>();
        caseDetails.put(cases[0].CaseNumber, cases[0]);
        
        test.startTest();
        ZJIRACaseWebservice.sendCaseOwnerUpdatesToJira(JSON.serialize(caseDetails));
        test.stopTest();
    }
    
    @istest
    static void testBatchClass() {
        String query = 'SELECT Id, zsfjira__CaseId__c, zsfjira__CaseId__r.CaseNumber,  zsfjira__ZIssueId__r.zsfjira__IssueKey__c, zsfjira__ZIssueId__r.SalesforceTicket__c, CreatedDate';  
                query += ' FROM zsfjira__ZIssue_Case__c '; 
                query += ' WHERE zsfjira__ZIssueId__r.zsfjira__IssueType__c = \''+'Customer Bug'+'\' Order by CreatedDate ASC'; 
        // String query = 'SELECT SalesforceTicket__c, zsfjira__IssueKey__c, zsfjira__Status__c FROM zsfjira__ZIssue__c';
        test.startTest();
        SFJIRACaseOwnerUpdateBatch newBatch = new SFJIRACaseOwnerUpdateBatch(query);
        Database.executeBatch(newBatch);
        test.stopTest();
    }
    
}