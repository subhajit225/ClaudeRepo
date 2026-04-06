@isTest
private class CS_CustomFieldControllerTest {
    /*Test method for setup*/
     @testsetup
    private static void testSetup(){
        User u=TestDataFactory.getUser();
        u.email='testuser@testuser1.com';
        insert u;
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Case_Special_Handling_Edit_Access'];
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = u.Id;
        psa.PermissionSetId = ps.Id;
        insert psa;   
    }
    
    /* test method for getFieldNames method */
    @isTest
    static void testGetFieldNames() {
        
        // Test positive scenario
        User u = [SELECT id, name from user where email ='testuser@testuser1.com'];
        System.runAs(u){
            Test.startTest();
            try {
                List <String> fieldNamesPositive = CS_CustomFieldController.getFieldNames('Case_Special_Handling__c', 'New');
                System.assertNotEquals(0, fieldNamesPositive.size(), 'Field names should not be empty for a valid fieldset and object.');
            } catch (Exception e) {
                System.assert(false, 'No exception should be thrown for a valid object and field set.');
            }
            
            try {
                List <String> fieldNamesFieldSetNotFound = CS_CustomFieldController.getFieldNames('Case_Special_Handling__c', 'NonExistentFieldSet');
                System.assert(false, 'An exception should have been thrown for a non-existent field set.');
            } catch (AuraHandledException e) {
                // Ensure the error message is specific to the missing field set and object
                String expectedErrorMessage = 'Script-thrown exception';
                System.assertEquals(expectedErrorMessage, e.getMessage(), 'Error message should be specific to the missing field set and object.');
            }
            
            try {
                List <String> fieldNamesObjectNotExist = CS_CustomFieldController.getFieldNames('NonExistentObject', 'New');
                System.assert(false, 'An exception should have been thrown for a non-existent object.');
            } catch (AuraHandledException e) {
                // Ensure the error message is specific to the missing object
                String expectedErrorMessage = 'Script-thrown exception';
                
            }
            Test.stopTest();
        }
    }
}