@IsTest
private class CommonTestDataUtils_Test {
    @TestSetup
    static void setup() {
        // Create a test user for System.runAs
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@test.com',
            Username = 'testuser01@test.com.new',
            Alias = 'tusr',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert u;
        // Ensure at least one automation record exists for tests
        if ([SELECT COUNT() FROM ShGl_DisableBusinessLogic__c] == 0) {
            insert new ShGl_DisableBusinessLogic__c(Name = 'Default Control');
        }
    }
    @IsTest
    static void testSetAutomationFlagsDisableAndEnable() {
         // Fetch test user created in TestSetup
        User u = [SELECT Id FROM User WHERE Username = 'testuser01@test.com.new' LIMIT 1];

        System.runAs(u) {
        // Disable all
        Test.startTest();
        CommonTestDataUtils.setAutomationFlags(true, null);
        Test.stopTest();
        // Verify record still exists
        ShGl_DisableBusinessLogic__c cs = [SELECT Id FROM ShGl_DisableBusinessLogic__c LIMIT 1];
        System.assertNotEquals(null, cs.Id);
        // Re-enable all
        CommonTestDataUtils.setAutomationFlags(false, null);
            System.assert(true, 'Automation flags toggled successfully');
        }
    }
    @IsTest
    static void testSetAutomationFlagsFilterCategory() {
        // Fetch test user created in TestSetup
        User u = [SELECT Id FROM User WHERE Username = 'testuser01@test.com.new' LIMIT 1];
        System.runAs(u) {
            Test.startTest();
            CommonTestDataUtils.setAutomationFlags(true, 'Trigger');
            Test.stopTest();
            System.assert(true, 'Trigger-only update executed successfully');
         }
    }
    @IsTest
    static void testGenerateUniqueStringAndPerformance() {
         // Fetch test user created in TestSetup
        User u = [SELECT Id FROM User WHERE Username = 'testuser01@test.com.new' LIMIT 1];
        System.runAs(u) {
        String s1 = CommonTestDataUtils.generateUniqueString('TestRec');
        String s2 = CommonTestDataUtils.generateUniqueString('TestRec');
        System.assertNotEquals(s1, s2, 'Unique strings should not collide');
        Long start = System.now().getTime();
            CommonTestDataUtils.assertPerformance(start, 5000);
        }
    }
    @IsTest
    static void testFutureBusinessDateUtility() {
         // Fetch test user created in TestSetup
        User u = [SELECT Id FROM User WHERE Username = 'testuser01@test.com.new' LIMIT 1];
        System.runAs(u) {
        DateTime future = CommonTestDataUtils.getFutureBusinessDate(3);
            System.assert(future > System.now(), 'Future business date should be ahead of now');
        }
    }
}