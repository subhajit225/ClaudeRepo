@isTest
public with sharing class salesOpsDailyBatchClasses_Test {
    @isTest
    static void salesOpsDailyBatchClasses(){
        Test.startTest();        
        Datetime dt = Datetime.now().addMinutes(1);
        String jobID = System.Schedule('BatchClassTest', dt.format('s m H d M \'?\' yyyy'), new salesOpsDailyBatchClasses());		
        System.assert(jobID != null);
        Test.stopTest();
    }

}