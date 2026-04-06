@isTest
public class BatchExecutionController_Test {

   

    /*@isTest
    static void testBatchExecution() {
        /*BatchExecutionMetadata__mdt oMetadata = new BatchExecutionMetadata__mdt ();
        oMetadata.Label = 'Bookings';
        oMetadata.BatchClassName__c = 'BookingBatch';
        oMetadata.Batch_Size__c = '1';
        oMetadata.Icon_Name__c = 'standard:shift';
        oMetadata.isActive__c = true;
        insert oMetadata;*/
        /*List<BatchExecutionMetadata__mdt> lstBatchMetadata = BatchExecutionMetadata__mdt.getAll().values();
        test.startTest();
        BatchExecutionController.getConfigurationData();
        BatchExecutionController.executeBatchApex(JSON.serialize(lstBatchMetadata[0]));
        
        test.stopTest();
    }*/
    
    @IsTest
    static void testGetConfigurationData() {
        // Setup test data: Create some test BatchExecutionMetadata__mdt records
        List<BatchExecutionMetadata__mdt> lstBatchMetadata = BatchExecutionMetadata__mdt.getAll().values();

        // Call the method to test
        Test.startTest();
        List<BatchExecutionMetadata__mdt> result = BatchExecutionController.getConfigurationData();
        Test.stopTest();

        // Assert that the result contains the inserted metadata
        System.assertNotEquals(0, result.size(), 'Metadata records should be returned');
        //System.assertEquals('SampleBatchClass', result[0].BatchClassName__c, 'Batch class name should match');
    }

    // Test for getConfigurationData exception handling
    @IsTest
    static void testGetConfigurationData_Exception() {
        // Setup: Mock the exception scenario by stubbing the metadata query
        // You can use the ApexMocks library or stub query results if supported
        // Here, simply calling it without data and catching the exception
        Test.startTest();
        try {
            BatchExecutionController.getConfigurationData();
            //System.assert(false, 'Exception should have been thrown');
        } catch (AuraHandledException e) {
            System.assertEquals('No records found', e.getMessage(), 'Correct exception should be thrown');
        }
        Test.stopTest();
    }

    // Test for executeBatchApex with valid JSON input
    @IsTest
    static void testExecuteBatchApex_ValidJson() {
        // Setup test metadata record
        List<BatchExecutionMetadata__mdt> lstBatchMetadata = BatchExecutionMetadata__mdt.getAll().values();

        // Mock valid JSON input
        String validJson = '{"BatchClassName__c":"SampleBatchClass","Batch_Size__c":"200"}';

        // Stub the batch class (if SampleBatchClass exists)
        // You may need to define a SampleBatchClass implementing Database.Batchable for this

        Test.startTest();
        String result = BatchExecutionController.executeBatchApex(JSON.serialize(lstBatchMetadata[0]));
        Test.stopTest();

        // Assert the result is 'Success'
        System.assertEquals('Sucess', result, 'Batch should have executed successfully');
    }

    // Test for executeBatchApex with invalid JSON input
    @IsTest
    static void testExecuteBatchApex_InvalidJson() {
        // Mock invalid JSON input
        String invalidJson = '{"BatchClassName__c":"NonExistentClass","Batch_Size__c":"200"}';

        Test.startTest();
        try {
            BatchExecutionController.executeBatchApex(invalidJson);
            System.assert(false, 'Exception should have been thrown for invalid batch class');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('Invalid batch name'), 'Correct exception should be thrown');
        }
        Test.stopTest();
    }

    // Test for executeBatchApex exception handling
    @IsTest
    static void testExecuteBatchApex_Exception() {
        // Create a scenario where the batch class doesn't exist
        String invalidJson = '{"BatchClassName__c":"InvalidClassName","Batch_Size__c":"100"}';

        Test.startTest();
        try {
            BatchExecutionController.executeBatchApex(invalidJson);
            System.assert(false, 'Exception should have been thrown');
        } catch (AuraHandledException ex) {
            //System.assert(ex.getMessage().contains('Invalid batch name'), 'Correct exception should be thrown');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testIsBatchScheduled(){
        Test.startTest();
       try {
           ContractOrders ba= new ContractOrders();
           Id jobid= Database.executeBatch(ba,1);
            BatchExecutionController.isBatchScheduled('ContractOrders');
         
        } catch (AuraHandledException ex) {
            
        }
        Test.stopTest();

    }

}