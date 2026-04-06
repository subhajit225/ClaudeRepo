@isTest
private class LeadAttemptFieldUpdateBatchtest {
    
    static testmethod void test() {
        ShGl_TestFactoryHelper.WorkflowTriggerBypass();
        List<Lead> ldlst = CustomTestDataFactory.createLead(1);
        List<Task> tasklst = CustomTestDataFactory.createTasklead(3,ldlst);
        system.debug('@@@tasklst'+tasklst);
        system.debug('@@@ldlst'+ldlst);
        
        Test.startTest();
        LeadAttemptFieldUpdateBatch ldatmpt = new LeadAttemptFieldUpdateBatch();
        Database.executeBatch(ldatmpt);
        Test.stopTest();
    }
}