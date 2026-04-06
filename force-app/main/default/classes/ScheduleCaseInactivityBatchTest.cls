@isTest
public class ScheduleCaseInactivityBatchTest {

    static testmethod void schedulerTest() {
        String CRON_EXP = '0 0 0 15 3 ? *';

        Test.startTest();

            String jobId = System.schedule('ScheduleCaseInactivityBatchTest',  CRON_EXP, new ScheduleCaseInactivityBatch());
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
            System.assertEquals(CRON_EXP, ct.CronExpression);
     
       Test.stopTest();
        
    }
      
}