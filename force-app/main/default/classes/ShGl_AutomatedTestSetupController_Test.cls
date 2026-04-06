// Test class for Code Coverage
@isTest
public class ShGl_AutomatedTestSetupController_Test {
    @isTest static void test_method_one() {
        // Implement test code
        ShGl_AutomatedTestSetupController obj = new ShGl_AutomatedTestSetupController ();
        
        obj.scheduleJobs();
        obj.createTestRun();
        obj.run();
        obj.email();
    }
}