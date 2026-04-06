@isTest
public class LeadActivityUpdateBatch_Test {

    static testMethod void testMethod_1() {
       
        Task t1 = new Task();
        //t.WhoId = ld.id;
        t1.Subject = 'Test Meeting';
        insert t1;
        
        ShGl_TestFactoryHelper.WorkflowTriggerBypass();
        Lead ld = TestDataFactory.insertLead();
        insert ld;
        
        List<Task> tskList = new List<Task>();
        for(Integer i = 0; i < 1; i++){
            Task t = new Task();
            t.WhoId = ld.id;
            t.Subject = 'Test Meeting';
            tskList.add(t);
        }
        insert tskList;
        
        t1.WhoId = ld.Id;
        update t1;
        
        Test.startTest();

        LeadActivityUpdateBatch obj = new LeadActivityUpdateBatch();
        Database.executeBatch(obj);
        
         matchStatusForOldLeadsBatch sh1 = new matchStatusForOldLeadsBatch();

		String sch = '0 0 23 * * ?'; 
        system.schedule('matchStatusForOldLeadsBatch', sch, sh1);
        
        Test.stopTest();
        
    }
    
}