@isTest
public with sharing class NightlyScheduledJobTest {
    @IsTest
    static void testScheduler(){
        
        Test.startTest();
        NightlyScheduledJob sch1 = new NightlyScheduledJob();
        String sch = '0 0 * * * ?';
        system.schedule('Test NightlyScheduledJob', sch, sch1);
        Test.stopTest();
        
    }
}