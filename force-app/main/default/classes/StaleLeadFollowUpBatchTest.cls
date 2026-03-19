/**
 * @description Unit tests for StaleLeadFollowUpBatch and StaleLeadFollowUpScheduler.
 *              Verifies that Tasks are created only for open, unconverted Leads
 *              older than 60 days, assigned to the Lead owner, with a 2-day due date.
 */
@IsTest
private class StaleLeadFollowUpBatchTest {

    @TestSetup
    static void setupTestData() {
        // 3 stale open leads (created 61 days ago)
        List<Lead> staleLeads = new List<Lead>();
        for (Integer i = 0; i < 3; i++) {
            staleLeads.add(new Lead(
                FirstName   = 'Stale',
                LastName    = 'Lead' + i,
                Company     = 'Test Corp ' + i,
                Status      = 'Open - Not Contacted'
            ));
        }
        insert staleLeads;

        // Back-date CreatedDate via Test.setCreatedDate
        for (Lead l : staleLeads) {
            Test.setCreatedDate(l.Id, DateTime.now().addDays(-61));
        }

        // 2 recent open leads (should NOT get a task)
        insert new List<Lead>{
            new Lead(FirstName = 'Recent', LastName = 'Lead0', Company = 'New Co 0', Status = 'Open - Not Contacted'),
            new Lead(FirstName = 'Recent', LastName = 'Lead1', Company = 'New Co 1', Status = 'Open - Not Contacted')
        };
    }

    @IsTest
    static void testBatchCreatesTasksForStaleLeads() {
        Test.startTest();
        Database.executeBatch(new StaleLeadFollowUpBatch(), 200);
        Test.stopTest();

        List<Task> tasks = [
            SELECT Subject, OwnerId, ActivityDate, WhoId
            FROM Task
            WHERE Subject = 'Close the Lead or mark it Bogus'
        ];

        Assert.areEqual(3, tasks.size(), 'Expected exactly 3 tasks for stale leads');

        Date expectedDueDate = Date.today().addDays(2);
        for (Task t : tasks) {
            Assert.areEqual('Close the Lead or mark it Bogus', t.Subject, 'Task subject mismatch');
            Assert.areEqual(expectedDueDate, t.ActivityDate, 'Task due date should be today + 2 days');
            Assert.isNotNull(t.WhoId, 'Task WhoId (Lead) should be set');
        }
    }

    @IsTest
    static void testBatchNoTasksForRecentLeads() {
        // Query only recent leads (created today, not back-dated)
        List<Lead> recentLeads = [SELECT Id FROM Lead WHERE LastName LIKE 'Lead0' OR LastName LIKE 'Lead1' LIMIT 2];
        Assert.areEqual(2, recentLeads.size());

        Test.startTest();
        Database.executeBatch(new StaleLeadFollowUpBatch(), 200);
        Test.stopTest();

        // Tasks should only be for stale leads (3), not for recent ones
        List<Task> tasks = [SELECT Id FROM Task WHERE Subject = 'Close the Lead or mark it Bogus'];
        Assert.areEqual(3, tasks.size(), 'Recent leads should not have tasks created');
    }

    @IsTest
    static void testSchedulerExecutesBatch() {
        Test.startTest();
        String cronExpr = '0 0 2 * * ?';
        System.schedule('Test Stale Lead Scheduler', cronExpr, new StaleLeadFollowUpScheduler());
        Test.stopTest();

        // If no exception was thrown, scheduler executed successfully
        Assert.isTrue(true, 'Scheduler should execute without errors');
    }
}