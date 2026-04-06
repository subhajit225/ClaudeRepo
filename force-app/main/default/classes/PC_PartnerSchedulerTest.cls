@isTest
public class PC_PartnerSchedulerTest {
    @IsTest
    static void testPartnerScheduler(){
        String CRON_EXP = '0 0 0 * * ? *';
        Test.startTest();
        System.schedule('testdailyScheduler', CRON_EXP, new PC_PartnerDailyScheduler());
        System.schedule('testWeeklyScheduler', CRON_EXP, new PC_PartnerWeeklyScheduler());
        System.schedule('testMonthlyScheduler', CRON_EXP, new PC_PartnerMonthlyScheduler());
        Test.stopTest();
    }
}