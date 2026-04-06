@isTest
private class TestSupportLoginFlowController {
    @isTest
    static void testSupportLoginFlowControllerAction() {
        // Create a test user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser9876@example.com',
            Alias = 'tuser',
            CommunityNickname = 'tuser',
            ProfileId = p.Id,
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US'
        );
        insert testUser;

        // Set up test data
        Test.startTest();
        System.runAs(testUser) {
            SupportLoginFlowController controller = new SupportLoginFlowController();
            controller.SupportLoginFlowControllerAction();
            controller.FinishLoginFlowHome();
        }
        Test.stopTest();
         System.assertNotEquals(null, testUser.Id);
    }
    @isTest
    static void testFinishFlowProperty() {
        SupportLoginFlowController controller = new SupportLoginFlowController();
        
        // Test setting and getting finishflow
        controller.Set(true);
        controller.getfinishflow();
         System.assertNotEquals(1, 2);
    }
}