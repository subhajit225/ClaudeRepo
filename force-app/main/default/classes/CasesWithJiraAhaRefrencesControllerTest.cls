/**
 * @author       :  Abhishek Mahajan
 * @createdDate  :   26th September 2023
 * @description  :   Test class for CasesWithJiraAhaRefrencesController
 */
@isTest
public class CasesWithJiraAhaRefrencesControllerTest {

    /**
    * @description Test setup method to create necessary test data including Account, Opportunity, Case,
    * Aha Ideas, Jira Issues, Playbook, Sub Tasks, Checklists, and a test User.
    */
    @testSetup
    static void setup() {
        Account[] accounts = new List<Account>{
            new Account(Name = 'Test Account'),
            new Account(Name = 'NA')
        };
        insert accounts;

        Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity', AccountId = accounts[0].Id, StageName = 'Closed Won', CloseDate = Date.today());
        insert testOpportunity;

        Case testCase = new Case(Subject = 'Test Case', AccountId = accounts[0].Id, Priority='P1');
        insert testCase;

        List<Aha_Ideas__c> ahaIdeas = new  List<Aha_Ideas__c>{
            new Aha_Ideas__c(Name = 'Idea1', Aha_Idea_Number__c = 'Aha123', Status__c = 'New'),
            new Aha_Ideas__c(Name = 'Idea2', Aha_Idea_Number__c = 'Aha456', Status__c = 'Closed: Won\'t Fix')
        };
        insert ahaIdeas;
            
        insert new List<Aha_Idea_Link__c>{
            new Aha_Idea_Link__c(Aha_Ideas__c = ahaIdeas[0].Id, Opportunity_Name__c = testOpportunity.Id),
            new Aha_Idea_Link__c(Aha_Ideas__c = ahaIdeas[1].Id, Case_Number__c = testCase.Id)
        };

        zsfjira__ZIssue__c jira1 = new zsfjira__ZIssue__c(Name = 'Jira1',zsfjira__IssueKey__c = 'CDM-100', zsfjira__Summary__c = 'Summary1', zsfjira__Status__c = 'Resolved', zsfjira__IssueId__c =232232);
        zsfjira__ZIssue__c jira2 = new zsfjira__ZIssue__c(Name = 'Jira2', zsfjira__IssueKey__c = 'CDM-101',zsfjira__Summary__c = 'Summary2', zsfjira__Status__c = 'Open', zsfjira__IssueId__c =233232);
        insert new List<zsfjira__ZIssue__c>{jira1, jira2};
            
        zsfjira__ZIssue_Case__c jiraCaseLink = new zsfjira__ZIssue_Case__c(zsfjira__CaseId__c = testCase.Id, zsfjira__ZIssueId__c = jira1.Id);
        insert jiraCaseLink;
        
        Playbook__c testPlaybook = new Playbook__c(Account__c = accounts[0].Id);
        insert testPlaybook;
        
        Sub_Task__c testSubTask = new Sub_Task__c(Name = 'Sub-Task 1', Playbook__c = testPlaybook.Id);
        insert testSubTask;

        Checklist__c checklist1 = new Checklist__c(
            Name = 'Checklist 1',
            Completed__c = false,
            Due_Date__c = Date.today(),
            Description__c = 'Description 1',
            Sub_Task__c = testSubTask.Id
        );
        Checklist__c checklist2 = new Checklist__c(
            Name = 'Checklist 2',
            Completed__c = true,
            Due_Date__c = Date.today().addDays(1),
            Description__c = 'Description 2',
            Sub_Task__c = testSubTask.Id
        );
        insert new List<Checklist__c> { checklist1, checklist2 };
            
        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'System Administrator'].Id;
        User u = new User(
            ProfileId = profileId,
            LastName = 'last',
            Email = 'csit-testuser@rubrik.com',
            Username = System.now().millisecond() + 'csit-testuser@rubrik.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Employee_Time_Off__c = true);
        insert u;
    }

    /**
    * @description Tests the getJiraRecords method with a valid Account ID and flag set to true,
    * expecting positive results including verifying the Jira record name.
    */
    @isTest
    static void testGetJiraRecordsPositive() {
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){
            Account[] accounts = [SELECT Id FROM Account WHERE Name='Test Account' LIMIT 1];
            List<zsfjira__ZIssue__c> result = CasesWithJiraAhaRefrencesController.getJiraRecords(accounts[0].Id, true);
            System.assertEquals(1, result.size());
            System.assertEquals('Jira1', result[0].Name);
        }
    }

    /**
    * @description Tests the getJiraRecords method with an Account ID that has no related Jira records
    * and flag set to false, expecting an empty result list.
    */
    @isTest
    static void testGetJiraRecordsNegative() {
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){
            Account[] accounts = [SELECT Id FROM Account WHERE Name='NA' LIMIT 1];
            List<zsfjira__ZIssue__c> result = CasesWithJiraAhaRefrencesController.getJiraRecords(accounts[0].Id, false);
            System.assertEquals(0, result.size());
        }
    }
    
    /**
    * @description Tests the getAhaRecords method with a valid Account ID and flag both true and false,
    * verifying returned Aha ideas including name checks for specific statuses.
    */
    @isTest
    static void testGetAhaRecordsPositive() {
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){
            Account[] accounts = [SELECT Id FROM Account WHERE Name='Test Account' LIMIT 1];
            List<Aha_Ideas__c> ahaIdeas = CasesWithJiraAhaRefrencesController.getAhaRecords(accounts[0].Id, true);
            List<Aha_Ideas__c> ahaIdea2 = CasesWithJiraAhaRefrencesController.getAhaRecords(accounts[0].Id, false);
            System.assertEquals(1, ahaIdeas.size());
            System.assertEquals('Idea2', ahaIdeas[0].Name);
        }
    }

    /**
    * @description Tests the getAhaRecords method with an Account ID having no Aha ideas,
    * expecting an empty list response.
    */
    @isTest
    static void testGetAhaRecordsNegative() {
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){
            Account[] accounts = [SELECT Id FROM Account WHERE Name='NA' LIMIT 1];
            List<Aha_Ideas__c> ahaIdeas = CasesWithJiraAhaRefrencesController.getAhaRecords(accounts[0].Id, false);
            System.assertEquals(0, ahaIdeas.size());
        }
    }
    
    /**
    * @description Tests the getChecklistRecords method with a valid Account ID,
    * verifying that only incomplete checklists for the related subtasks are returned
    * and their fields match expected values.
    */
    @isTest
    static void testGetChecklistRecordsPositive() {
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){
            Account[] accounts = [SELECT Id FROM Account WHERE Name='Test Account' LIMIT 1];
            List<Checklist__c> result = CasesWithJiraAhaRefrencesController.getChecklistRecords(accounts[0].Id);
            System.assertEquals(1, result.size());
            System.assertEquals('Checklist 1', result[0].Name);
            System.assertEquals(false, result[0].Completed__c);
            //System.assertEquals(Date.today(), result[0].Due_Date__c);
            System.assertEquals('Description 1', result[0].Description__c);
        }
    }

    /**
    * @description Tests the getChecklistRecords method with an Account ID that has no checklists,
    * expecting an empty list as a result.
    */
    @isTest
    static void testGetChecklistRecordsNegative() {
        User user1=[Select ProfileId,LastName from User WHERE Email='csit-testuser@rubrik.com'];
        System.runAs(user1){
            Account[] accounts = [SELECT Id FROM Account WHERE Name='NA' LIMIT 1];
            List<Checklist__c> result = CasesWithJiraAhaRefrencesController.getChecklistRecords(accounts[0].Id);
            System.assertEquals(0, result.size());
        }
    }
}