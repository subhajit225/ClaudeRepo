//Test Generic Batch Scheduler for all Batch Jobs
@isTest
class BatchScheduler_Test {
    
    static testmethod void testBatchScheduule() {
        
        Test.startTest();
        
        LeadActivityUpdateBatch la = new LeadActivityUpdateBatch();
        
        // Instantiate the scheduler
        BatchScheduler scheduler = new BatchScheduler();
        
        // Assign the batch class to the variable within the scheduler
        scheduler.batchClass = la;
        
        // Run every day at 1pm
        String sch = '0 0 0 3 9 ? 2022';
        
        String jobId = System.schedule('BatchSchedulerTest - Everyday at 1pm', sch, scheduler);
        
        
        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                          FROM CronTrigger WHERE id = :jobId];
        
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);
        
        // Verify the next time the job will run
        System.assertEquals('2022-09-03 00:00:00', String.valueOf(ct.NextFireTime));
        
        Test.stopTest();
    }
}