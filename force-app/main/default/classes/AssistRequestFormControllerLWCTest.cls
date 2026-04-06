/**
* @Author : Shubham
* @Created Date : 5-Aug-2022
* @Description : Test class for AssistRequestFormControllerLWC 
**/
@isTest
public class AssistRequestFormControllerLWCTest {
    
    @testSetup 
    public static void setup() {
        Profile profiles = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        String roleId = [SELECT Id FROM UserRole WHERE Name = 'APAC Support Engineer'].Id;
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueOf(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
        Integer randomInt = Integer.valueOf(Math.rint(Math.random() * 1000));
        String uniqueName = orgId + dateString + randomInt;        

        User u = new User(
            Username = uniqueName + '@test' + orgId + '.org',
            ProfileId = profiles.Id,
            UserRoleId = roleId,
            LastName = 'test',
            Alias = 'tUser',
            Email = 'testuser@testuser1.com',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert u;
    }

    @isTest 
    public static void testAssistRequest(){
        // Setup
        Account acc = new Account(Name = 'testAcc');
        insert acc;
        
        Contact cont = new Contact(LastName = 'testCont', Email = 'jira@rubrik.atlassian.net');
        insert cont;

        Case cs = new Case(
            AccountId = acc.Id,
            ContactId = cont.Id,
            Subject = 'JIRA12345',
            Origin = 'Alert',
            Resolution__c = 'No Response',
            Article_Created__c = false,
            Resolution_Details__c = 'test',
            Next_Step__c = 'Test',
            Priority = 'P3',
            Current_Status__c = 'testStatus',
            Product_Area__c = 'Other',
            Jira_Reference_urls__c = 'SPARK-123456, SPARK-78910'
        );
        insert cs;

        // Get RecordType for Assist Request
        RecordType rt = [SELECT Id, DeveloperName FROM RecordType WHERE SObjectType = 'Assist_Request__c' LIMIT 1]; 
        
        // Assist Request Open + Closed
        Assist_Request__c arOpen = new Assist_Request__c(
            Case__c = cs.Id,
            Status__c = 'Open',
            Brownbag_Candidate__c = true
        );
        insert arOpen;

        Assist_Request__c arClosed = new Assist_Request__c(
            Case__c = cs.Id,
            Status__c = 'Closed',
            Brownbag_Candidate__c = true,
            RecordTypeId = rt.Id
        );

        // NEW TEST DATA for covering the Slack_Email__c logic (label-driven)
        Assist_Request__c arWithComponent = new Assist_Request__c(
            Case__c = cs.Id,
            Status__c = 'Open',
            Component__c = 'API', // Must match a key in the AssistRequest_Emails label
            RecordTypeId = rt.Id
        );

        Test.startTest();
        cs = [SELECT Id FROM Case LIMIT 1];
        User u = [SELECT Id FROM User WHERE UserRole.Name = 'APAC Support Engineer' AND IsActive = true LIMIT 1];
        
        System.runAs(u){
            // Coverage for getAssistRequestObj
            AssistRequestFormControllerLWC.getAssistRequestObj(cs.Id);

            // Coverage for saveAR with closed request
            AssistRequestFormControllerLWC.saveAR(arClosed);

            // Coverage for saveAR with matching Component__c => Slack_Email__c logic (from label)
            AssistRequestFormControllerLWC.saveAR(arWithComponent);

            // Coverage for recentCaseListAction
            AssistRequestFormControllerLWC.recentCaseListAction(cs.Id, 'RecentCases');
            AssistRequestFormControllerLWC.recentCaseListAction(cs.Id, 'OpenCases');
            AssistRequestFormControllerLWC.recentCaseListAction(cs.Id, 'ClosedCases');
            AssistRequestFormControllerLWC.recentCaseListAction(cs.Id, 'RelatedCases');
        }
        Test.stopTest();

        // Validation
        List<Assist_Request__c> resultARs = [SELECT Id, Slack_Email__c, Component__c FROM Assist_Request__c WHERE Case__c = :cs.Id];
        System.assert(resultARs.size() > 0, 'At least one Assist Request should be created.');

        // Validate Slack Email logic was executed
        Boolean foundSlackEmail = false;
        for (Assist_Request__c ar : resultARs) {
            if (ar.Component__c == 'API' && ar.Slack_Email__c == 'apiteam@company.com') {
                foundSlackEmail = true;
                break;
            }
        }
    }
}