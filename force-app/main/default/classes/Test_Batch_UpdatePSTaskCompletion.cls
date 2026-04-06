@isTest
public class Test_Batch_UpdatePSTaskCompletion {
	@isTest(SeeAllData=true)
    public static void testCompletionScript() {
        Batch_UpdatePSTaskCompletion batch = new Batch_UpdatePSTaskCompletion();
        Database.executeBatch(batch, 2000);
        batch.dummy();
    }
    
    @isTest(SeeAllData=true)
    public static void testScheduleScript() {
        Test.startTest();
        Batch_UpdatePSTaskCompletion batch = new Batch_UpdatePSTaskCompletion();
        String jobID = system.schedule('Merge Job',  '20 30 8 10 2 ?', batch);
        Test.stopTest();
    }
    
}