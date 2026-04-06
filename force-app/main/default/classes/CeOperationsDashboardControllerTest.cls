/**
 * Author       :   Abhishek Mahajan
 * CreatedDate  :   26th October 2023
 * Description  :   Test class for CeOperationsDashboardController
 */
@isTest
public class CeOperationsDashboardControllerTest {
    /*
    * @description Account preference to for testing
    */    
    private static final string ACCOUNT_PREFERENCE = 'CSM Account';
    @testSetup
    static void setup() {
    	Account[] accounts = new List<Account>{
            new Account(Name = 'Test Account', Account_preference__c = ACCOUNT_PREFERENCE),
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

        zsfjira__ZIssue__c jira1 = new zsfjira__ZIssue__c(Name = 'Jira1', zsfjira__Summary__c = 'Summary1', zsfjira__Status__c = 'Closed', zsfjira__IssueId__c =232232, zsfjira__IssueKey__c='zsfjira__IssueKey1');
        zsfjira__ZIssue__c jira2 = new zsfjira__ZIssue__c(Name = 'Jira2', zsfjira__Summary__c = 'Summary2', zsfjira__Status__c = 'Open', zsfjira__IssueId__c =233232, zsfjira__IssueKey__c='zsfjira__IssueKey2');
        insert new List<zsfjira__ZIssue__c>{jira1, jira2};
            
        zsfjira__ZIssue_Case__c jiraCaseLink = new zsfjira__ZIssue_Case__c(zsfjira__CaseId__c = testCase.Id, zsfjira__ZIssueId__c = jira1.Id);
        insert jiraCaseLink;
        Profile p = [SELECT Id FROM Profile WHERE Name='Rubrik Customer Support Manager'];
        User u = new User(
                FirstName = 'User',
                LastName = 'Test',
                Username = 'cem@test.com',
                Email = 'cem@test.com',
                Alias = 'U',
                ProfileId = p.Id,
                TimeZoneSidKey = 'GMT',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US'
            );
        insert u;
        updateCEM(accounts[0].Id, u.Id);
    }
    /*
    * @description utility to assign CEM role to a user
    */   
    @future
    public static void updateCEM(Id accountId, Id cemId){
        update new Account(Id = accountId, Account_SAM__c=cemId);
    }
    /*
    * @description Test CeOperationDashboardController methods
    */
    @isTest
    public static void testgetAccounts(){
        Account[] account = [SELECT Id,Account_preference__c,Account_SAM__c FROM Account WHERE Name='Test Account' LIMIT 1];
        User cem = [SELECT Id FROM User WHERE username='cem@test.com' LIMIT 1];
        String[] fields = new List<String>{'Name'};
        String[] preferences = new List<String>{ACCOUNT_PREFERENCE};
        String[] names = new List<String>{account[0].Id};
        String[] cems = new List<String>{cem.Id};
        List<Object> accounts = CeOperationsDashboardController.getAccounts(fields, preferences, names, cems);
        List<Object> accountsOptions = CeOperationsDashboardController.getAccountOptions('name-change',null, preferences, cems, null, 0);
        List<Object> CEMOptions = CeOperationsDashboardController.getCEMOptions('cem-change',null, preferences, names, null, 0);
        List<Object> AccountPreferencePicklistValues = CeOperationsDashboardController.getPicklistValues('Account', 'Account_Preference__c');
        Map<String, Object> metricsMap = new Map<String, Object>();
        String[] metrics = new List<String>{'open_cases', 'closed_cases', /*'tcv_12_priority','avg_ttr_12_priority',*/ 'tcv_12', 'jiras', 'rfes', 'avg_ttr_12',  'open_p1'};
        for(String metric : metrics){
            metricsMap.put(metric, CeOperationsDashboardController.getMetrics(preferences, names, cems, metric, false));
        }
        CeOperationsDashboardController.getGroupMetrics(preferences, names, cems, 'tcv_12_priority', 'Priority', 'P1');
        System.assertEquals(1, accounts.size(), 'Expected one Account');
        System.assertEquals(1, accountsOptions.size(), 'Expected one Account Option');
        System.assertEquals(1, CEMOptions.size(), 'Expected one CEM Option');
        System.assert(!AccountPreferencePicklistValues.isempty(), 'Expected one Account Preference Value');
        System.assertNotEquals(0, metricsMap.size(), 'Expected non-empty metrics map');
    }

}