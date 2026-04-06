@isTest
public class CS_CaseSpecialHandlingControllerTest {

    static Account testAccount;

    @TestSetup
    static void testSetup() {
        UserRole vUserRole = new UserRole(DeveloperName = 'RubrikDeveloper1', Name = 'My Role');
        insert vUserRole;
        
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'last',
            Email = 'testuser@testuser1.com',
            Username = 'testrbkstlnw' +'@rubrik.com.sandbox',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'stlnw',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            UserRoleId = vUserRole.Id,
            Start_Date__c=System.Today().adddays(-30)
            
        );
        
        insert u;
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Case_Special_Handling_Edit_Access'];
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = u.Id;
        psa.PermissionSetId = ps.Id;
        insert psa;   
        System.runAs(u) {
        // Create a dummy Account record
        testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        }
    }

    /* test method for getRecords method*/
    @isTest
    static void testGetRecords() {
        User u = [SELECT id, name from user where email ='testuser@testuser1.com'];
        System.runAs(u){
        Id accId = [SELECT Id FROM Account LIMIT 1].id;
        // Create a Case record associated with the Account
        Case testCase = new Case(AccountId = accId, Priority = 'P4', RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Support_Case').getRecordTypeId());
        insert testCase;
            
        Case testCase1 = new Case(AccountId = accId, Priority = 'P4', RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Customer_Success').getRecordTypeId());
        insert testCase1;

        Case_Special_Handling__c testSpecialHandling = new Case_Special_Handling__c(
            Account_Id__c = accId,
            Icon__c = 'Dark Site',
            Category__c = 'Support contract exceptions',
            Message__c = 'SomeMessage',
            Is_Archived__c = false
        );
        insert testSpecialHandling;
        Case_Special_Handling__c testSpecialHandling1 = new Case_Special_Handling__c(
            Account_Id__c = accId,
            Icon__c = 'Dark Site',
            Category__c = 'Support contract exceptions',
            Message__c = 'SomeMessage',
            Is_Archived__c = false,
            Show_Banner__c = true
        );
        insert testSpecialHandling1;
            
		String querLimit = '5';
        String filter = 'Show_Banner__c = true';
        // Test the getRecords method with valid Case Id
        Test.startTest();
        List <Case_Special_Handling__c> result = CS_CaseSpecialHandlingController.getRecords(testCase.Id,querLimit,filter);
        List <Case_Special_Handling__c> result1 = CS_CaseSpecialHandlingController.getRecords(testCase1.Id,querLimit,filter);
        
        // Assertions for the valid Case Id scenario
        System.assertEquals(1, result.size());
        System.assertEquals('Dark Site', result[0].Icon__c);
        System.assertEquals('Support contract exceptions', result[0].Category__c);
        System.assertEquals('SomeMessage', result[0].Message__c);

        // Test the getRecords method with invalid Case Id
        try {
            result = CS_CaseSpecialHandlingController.getRecords(null,null,null);
            // Ensure that no result is returned if an exception is thrown
            System.assertEquals(0, result.size(), 'No records should be returned if an exception is thrown.');
        } catch (CS_CaseSpecialHandlingController.CS_CaseSpecialHandlingControllerException e) {
            // Verify that the custom exception is thrown with the expected message
            System.assertEquals('Script-thrown exception', e.getMessage(), 'Correct exception message should be thrown.');
        }
        Test.stopTest();
        }
    }

    @isTest
    static void testUpdateDateField() {
        User u = [SELECT id, name from user where email ='testuser@testuser1.com'];
        System.runAs(u){
        // Create a Case_Special_Handling record associated with the Account
        Case_Special_Handling__c testSpecialHandling = new Case_Special_Handling__c(
            Account_Id__c = [SELECT Id FROM Account LIMIT 1].id,
            Icon__c = 'Dark Site',
            Category__c = 'Support contract exceptions',
            Message__c = 'SomeMessage',
            Is_Archived__c = false
        );
        insert testSpecialHandling;

        // Test the updateDateField method with valid record Id
        Test.startTest();
        String result = CS_CaseSpecialHandlingController.updateDateField(testSpecialHandling.Id);

        // Assertions for the valid record Id scenario
        System.assertEquals('Success: Manual Review Requested Successfully.', result);

        // Test the updateDateField method with invalid record Id
        result = CS_CaseSpecialHandlingController.updateDateField('invalidId');

        // Assertions for the invalid record Id scenario
        System.assertEquals('Error: Invalid id: invalidId', result);
        Test.stopTest();
        }
    }
     @IsTest
    static void testCheckObjectAccess() {
        User u = [SELECT id, name from user where email ='testuser@testuser1.com'];
        System.runAs(u){
        Test.startTest();
        Boolean hasAccessToAccount = CS_CaseSpecialHandlingController.checkObjectAccess('Case_Special_Handling__c');
        Test.stopTest();
        System.assertEquals(true, hasAccessToAccount, 'Expected to have access to Account object');
        }
    }
    
    @IsTest
    static void testCheckObjectAccessWithNull() {
        User u = [SELECT id, name from user where email ='testuser@testuser1.com'];
        System.runAs(u){
        // Test with null value
        Test.startTest();
        Boolean hasAccessToNull = CS_CaseSpecialHandlingController.checkObjectAccess(null);
        Test.stopTest();
        System.assertEquals(false, hasAccessToNull, 'Expected to not have access when objectName is null');
        }
    }
}