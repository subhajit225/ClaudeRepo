@isTest 
public class PONotificationScheduler_Test {
   
    @isTest
    static void testMethod_1() {
    Test.StartTest();
   // PONotificationScheduler.testCoverage();
PONotificationScheduler sh1 = new PONotificationScheduler();
String sch = '0 0 23 * * ?'; 
system.schedule('Test PONotificationScheduler Check', sch, sh1); 
    Test.stopTest(); 
}
    
    
	
}