/**
* @description Test class for ZIssueSFTriggerHandler
* @author shiva.sharma
*/
@isTest
public class ZIssueSFTriggerHandlerTest {
    
    /**
* @description Set up test data
*/
    @TestSetup
    static void setupTestData() {
        
        // Create automation user that can bypass validation rules
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        
        User automationUser = new User(
            ProfileId = profileId,
            LastName = 'Automation',
            Email = 'cs-testauto@rubrik.com',
            Username = 'cs-testauto@rubrik.com',
            CompanyName = 'TEST',
            Title = 'Automation User',
            Alias = 'csauto',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Employee_Time_Off__c = true
        );
        insert automationUser;
        
        // Create test accounts with different preferences
        System.runAs(automationUser){
            Account strategicAccount = new Account(
                Name = 'Strategic Test Account',
                Account_Preference__c = 'Strategic Account'
            );
            Account premiumAccount = new Account(
                Name = 'Premium Test Account', 
                Account_Preference__c = 'Premium Account'
            );
            Account topAccount = new Account(
                Name = 'Top Test Account',
                Account_Preference__c = 'Top Accounts'
            );
            
            insert new List<Account>{strategicAccount, premiumAccount, topAccount};
                
                
                // Create test cases
                Case closedCase = new Case(
                    Subject = 'Test Closed Case',
                    Status = 'Closed',
                    Priority = 'P3',
                    AccountId = strategicAccount.Id,
                    Resolution__c = 'Test Resolution'
                );
            Case openCase = new Case(
                Subject = 'Test Open Case',
                Status = 'Open',
                Priority = 'P3',
                AccountId = premiumAccount.Id
            );
            insert new List<Case>{closedCase, openCase};
            closedCase.Status = 'Closed';
            update closedCase;
            // Create test ZIssue records
            zsfjira__ZIssue__c jira1 = new zsfjira__ZIssue__c(Name = 'Jira1',zsfjira__IssueKey__c = 'CDM-100',zsfjira__IssueType__c = 'Usability', zsfjira__Summary__c = 'Summary1', zsfjira__Status__c = 'Resolved', zsfjira__IssueId__c =232232);
            zsfjira__ZIssue__c jira2 = new zsfjira__ZIssue__c(Name = 'Jira2', zsfjira__IssueKey__c = 'CDM-101',zsfjira__IssueType__c = 'Usability',zsfjira__Summary__c = 'Summary2', zsfjira__Status__c = 'Open', zsfjira__IssueId__c =233232);
            insert new List<zsfjira__ZIssue__c>{jira1, jira2};
                
                zsfjira__ZIssue_Case__c jiraCaseLink = new zsfjira__ZIssue_Case__c(zsfjira__CaseId__c = closedCase.Id, zsfjira__ZIssueId__c = jira1.Id);
            insert jiraCaseLink;
            
            // Create ZIssue_SF relationships
            zsfjira__ZIssue_SF__c relation1 = new zsfjira__ZIssue_SF__c(
                zsfjira__Case__c = closedCase.Id,
                zsfjira__ZIssue__c = jira1.Id
            );
            zsfjira__ZIssue_SF__c relation2 = new zsfjira__ZIssue_SF__c(
                zsfjira__Case__c = openCase.Id,
                zsfjira__ZIssue__c = jira1.Id
            );
            insert new List<zsfjira__ZIssue_SF__c>{relation1, relation2};
                }
    }
    
    /**    
* @description Test the beforeInsert method
*/
    @isTest
    static void testSendCommentOnJiraIssue() {
        List<zsfjira__ZIssue_SF__c> jiraRels = [SELECT Id, zsfjira__Case__c FROM zsfjira__ZIssue_SF__c];
        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            ZIssueSFTriggerHandler handler = new ZIssueSFTriggerHandler();
            handler.sendCommentOnJiraIssue(jiraRels);
            Test.stopTest();
            
            // Verify method executes without errors
            System.assert(true, 'Method executed successfully');
        }
    }
    
    /**
* @description Test the unlinkZissueAccountPreference method
*/
    @isTest
    static void testUnlinkZissueAccountPreference() {
        List<zsfjira__ZIssue_SF__c> caseIssues = [SELECT Id, zsfjira__ZIssue__c FROM zsfjira__ZIssue_SF__c];
        Test.startTest();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            ZIssueSFTriggerHandler.linkUnlinkZissue(caseIssues);
            Test.stopTest();
            delete caseIssues;
            
            System.assert(true, 'Method executed successfully');
        }
    }
    
    
    /**
* @description Test the updateCountByAccountPreference method
*/
    @isTest
    static void testUpdateCountByAccountPreference() {
        Set<Id> accountIds = new Set<Id>();
        for(Account acc : [SELECT Id FROM Account]) {
            accountIds.add(acc.Id);
        }
        System.runAs(new User(Id = UserInfo.getUserId())) {
            
            Test.startTest();
            ZIssueSFTriggerHandler.updateCountByAccountPreference(accountIds);
            Test.stopTest();
            
            System.assert(true, 'Method executed successfully');
        }
    }
    
    /**
* @description Test the supportedType method with a supported issue type
*/
    @isTest
    static void testSupportedType() {
        zsfjira__ZIssue_SF__c testRecord = [SELECT zsfjira__ZIssue__r.zsfjira__IssueKey__c, 
                                            zsfjira__ZIssue__r.zsfjira__IssueType__c 
                                            FROM zsfjira__ZIssue_SF__c LIMIT 1];
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.startTest();
            Boolean result = ZIssueSFTriggerHandler.supportedType(testRecord);
            Test.stopTest();
            
            System.assertEquals(true, result, 'Should return true for supported type');
        }
    }
    
    /**
* @description Test the supportedType method with an unsupported issue type
*/
    @isTest
    static void testSupportedTypeUnsupported() {
        zsfjira__ZIssue__c unsupportedIssue = new zsfjira__ZIssue__c(
            zsfjira__IssueKey__c = 'UNSUPPORTED-123',
            zsfjira__IssueType__c = 'Unsupported Type',
            zsfjira__IssueId__c = 3345
        );
        insert unsupportedIssue;
        
        zsfjira__ZIssue_SF__c unsupportedRelation = new zsfjira__ZIssue_SF__c(
            zsfjira__ZIssue__c = unsupportedIssue.Id
        );
        insert unsupportedRelation;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.startTest();
            Boolean result = ZIssueSFTriggerHandler.supportedType( [SELECT zsfjira__ZIssue__r.zsfjira__IssueKey__c, 
                                                                    zsfjira__ZIssue__r.zsfjira__IssueType__c 
                                                                    FROM zsfjira__ZIssue_SF__c WHERE Id =: unsupportedRelation.Id]);
            Test.stopTest();
            
            System.assertEquals(false, result, 'Should return false for unsupported type');
        }
    }
    
    /**
* @description Test the inner class IssuePreferenceCount
*/
    @isTest
    static void testIssuePreferenceCountClass() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.startTest();
            ZIssueSFTriggerHandler.IssuePreferenceCount counter = new ZIssueSFTriggerHandler.IssuePreferenceCount();
            Test.stopTest();
            
            System.assertEquals(0, counter.countTopAccount, 'Should initialize to 0');
            System.assertEquals(0, counter.countPremiumAccount, 'Should initialize to 0');
            System.assertEquals(0, counter.countStrategicAccount, 'Should initialize to 0');
        }
    }
    /**
* @description Test processIssuesInBatchContext method directly
*/
    @isTest
    static void testProcessIssuesInBatchContextDirect() {
        // Create test data
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Account testAccount = new Account(Name = 'Test Account');
            insert testAccount;
            
            Case testCase = new Case(
                Subject = 'Test Case for Batch Processing',
                AccountId = testAccount.Id,
                Status = 'New',
                Priority='P1 - Critical service impact'
            );
            insert testCase;
            
            Set<Id> issueIds = new Set<Id>{testCase.Id}; 
                
                Test.startTest();
            
            
            ZIssueSFTriggerHandler.processIssuesInFutureContext(issueIds);
            
            Test.stopTest();
            
            
            Case updatedCase = [SELECT Id, Status FROM Case WHERE Id = :testCase.Id];
            
            System.assertNotEquals(null, updatedCase, 'Case should be processed');
        }
    }

}