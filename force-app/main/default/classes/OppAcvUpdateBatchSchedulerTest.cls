@isTest
public with sharing class OppAcvUpdateBatchSchedulerTest {
    @isTest
    static void OppAcvUpdateBatchScheduler(){
        Test.startTest();        
        Datetime dt = Datetime.now().addMinutes(1);
        String jobID = System.Schedule('MetricsFieldCalculation', dt.format('s m H d M \'?\' yyyy'), new OppAcvUpdateBatchScheduler());		
        System.assert(jobID != null);
        Test.stopTest();
    }
}