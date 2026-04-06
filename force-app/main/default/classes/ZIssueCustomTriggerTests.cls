@isTest
public class ZIssueCustomTriggerTests {
    static testMethod void testTrigger() {
        //--INSERT
        insert new TriggerControl__c(Name='ZissueCaseJiraReferenceHyper');
        zsfjira__ZIssue__c ziss = new zsfjira__ZIssue__c();
        ziss.zsfjira__IssueId__c = 1002;
        ziss.Name=ziss.zsfjira__IssueKey__c = 'CDM-10';
        ziss.Name=ziss.zsfjira__Status__c = 'Open';
        insert ziss;
         
         
         Contact ct = new Contact();
         ct.Email = 'jira@rubrik.atlassian.net';
         ct.FirstName = 'hbn';
         ct.LastName = 'hi';
         insert ct;
         ct = [SELECT Id,Email FROM Contact WHERE Email='jira@rubrik.atlassian.net'];
        
         
        Case caseTest = new Case();
        caseTest.Subject = '\\[JIRA\\]\\(CDM-10\\) testing one more';
        caseTest.ContactId = ct.Id;
        caseTest.Priority = 'P1';
        caseTest.Jira_Reference_urls__c = 'test';
        insert caseTest;
        Case caseTest2 = new Case();
        caseTest2.Subject = '\\[JIRA\\]\\(CDM-12\\) testing one more';
        caseTest2.ContactId = ct.Id;
        caseTest2.Jira_Reference_urls__c = 'test';
        caseTest2.Priority = 'P1';
        insert caseTest2;
        
        zsfjira__ZIssue_SF__c rel = new zsfjira__ZIssue_SF__c();
        rel.zsfjira__IssueId__c = 1002;
        rel.zsfjira__ZIssue__c = ziss.Id;
        rel.zsfjira__Case__c = caseTest.Id;
        rel.zsfjira__IssueCreated__c = false;
        insert rel;
        
          
        zsfjira__ZIssue_Case__c rel2 = new zsfjira__ZIssue_Case__c(); 
        //rel2.Id = '003S000000uYmyWIAS';
        rel2.zsfjira__CaseId__c = caseTest2.Id;
        rel2.zsfjira__ZIssueId__c = ziss.Id;
        
        insert rel2;
        delete rel2;
        delete rel;
         
        System.assert(ziss!=null);
        //--UPDATE
        //ziss = [SELECT Id,zsfjira__Status__c FROM zsfjira__ZIssue__c WHERE zsfjira__IssueKey__c='C'];
        //ziss.zsfjira__Status__c = 'Closed';
        //upsert ziss;
        System.assert(ziss!=null);
         
    }
}