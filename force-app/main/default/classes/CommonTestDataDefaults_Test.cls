@IsTest
private class CommonTestDataDefaults_Test {
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
        
    }

    @IsTest
    static void testGetDefaultsAndMerge() {
        
         // Fetch test user created in TestSetup
        User u = [SELECT Id FROM User WHERE Username = 'testuser01@test.com.new' LIMIT 1];

        System.runAs(u) {
        // Get existing defaults for Account
        Map<String, Object> defaults = CommonTestDataDefaults.getDefaults('Account');
        System.assertEquals('Technology', defaults.get('Industry'));

        // Merge new defaults
        CommonTestDataDefaults.mergeDefaults('Account', new Map<String, Object>{
            'Industry' => 'Finance',
            'Type' => 'Customer'
        });

        // Re-fetch and verify
        Map<String, Object> updated = CommonTestDataDefaults.getDefaults('Account');
        System.assertEquals('Finance', updated.get('Industry'));
        System.assertEquals('Customer', updated.get('Type'));

        // Verify non-existent object returns empty map
        Map<String, Object> missing = CommonTestDataDefaults.getDefaults('NonExistingObject');
            System.assertEquals(true, missing.isEmpty());
        }
    }
}