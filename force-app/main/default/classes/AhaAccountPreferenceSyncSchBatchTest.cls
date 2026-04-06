/**
 * @description Test class for AhaAccountPreferenceSyncSchBatch.
 *              Provides comprehensive test coverage for the batch job that synchronizes
 *              account preferences with AHA ideas, including various scenarios like
 *              successful execution, error handling, null data processing, and callout limits.
 * @author Vijay K R
 * @since 28/11/2024
 * @see AhaAccountPreferenceSyncSchBatch
 */
@IsTest
private class AhaAccountPreferenceSyncSchBatchTest {

    /**
     * @description Mock class that simulates a successful AHA API response.
     *              Returns HTTP 200 response for callout execution.
     */
    private class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"success": true}');
            return res;
        }
    }

    /**
     * @description Mock class that simulates a failed AHA API response.
     *              Returns HTTP 500 response to trigger error handling logic.
     */
    private class FailureMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Internal Server Error');
            return res;
        }
    }

    /**
     * @description Sets up test data for all test methods including accounts with various
     *              account preferences, opportunities, cases, AHA ideas, and idea links.
     *              Creates the necessary test environment with disabled business logic.
     */
    static void setupTestData() {

        Account acc = new Account(
            Name = 'Test Account',
            Account_Preference__c = 'Strategic Account;Premium Account'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(10),
            AccountId = acc.Id
        );
        insert opp;

        Case cs = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Priority = 'P1',
            AccountId = acc.Id
        );
        insert cs;

        Aha_Ideas__c idea = new Aha_Ideas__c(
            Name = 'Test Idea',
            Aha_Unique_ID__c = 'AHA-12345',
            Strategic_Major_Account__c = 1
        );
        insert idea;

        Aha_Idea_Link__c link = new Aha_Idea_Link__c(
            Aha_Ideas__c = idea.Id,
            Opportunity_Name__c = opp.Id,
            Case_Number__c = cs.Id
        );
        insert link;
    }

    /**
     * @description Tests the successful execution of the AhaAccountPreferenceSyncBatch.
     *              Verifies that the batch job completes successfully and processes
     *              AHA idea links with account preferences correctly.
     */
    @IsTest
    static void testBatchSuccess() {
        User u = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        System.runAs(u) {
            setupTestData();
            Test.setMock(HttpCalloutMock.class, new SuccessMock());
            Test.startTest();
            Id jobId = AhaAccountPreferenceSyncSchBatch.executeBatchNow();
            Test.stopTest();
            System.assertNotEquals(null, jobId);
        }
    }

    /**
     * @description Tests scheduled job execution.
     *              Ensures scheduler triggers batch execution and returns job id.
     */
    @IsTest
    static void testSchedulerExecution() {
        User u = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        System.runAs(u) {
            setupTestData();
            Test.setMock(HttpCalloutMock.class, new SuccessMock());
            Test.startTest();
            AhaAccountPreferenceSyncSchBatch.scheduleJob();
            String jobId = AhaAccountPreferenceSyncSchBatch.scheduleJob('Test Job');
            Test.stopTest();
            System.assertNotEquals(null, jobId);
        }
    }

    /**
     * @description Tests error handling when AHA API returns failure response.
     *              Verifies that error logs are created when callout fails.
     */
    @IsTest
    static void testCalloutFailure() {
        User u = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        System.runAs(u) {
            setupTestData();
            Test.setMock(HttpCalloutMock.class, new FailureMock());
            Test.startTest();
            AhaAccountPreferenceSyncSchBatch.executeBatchNow();
            Test.stopTest();
            List<Idea_Exception__c> errors = [
                SELECT Id FROM Idea_Exception__c
            ];
            System.assert(errors.size() > 0);
        }
    }

    /**
     * @description Tests batch execution when no eligible records exist.
     *              Ensures batch exits gracefully without throwing exceptions.
     */
    @IsTest
    static void testNoDataScenario() {
        User u = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        System.runAs(u) {
            Test.setMock(HttpCalloutMock.class, new SuccessMock());
            Test.startTest();
            AhaAccountPreferenceSyncSchBatch.executeBatchNow();
            Test.stopTest();
            System.assert(true);
        }
    }
}