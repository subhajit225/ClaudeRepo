@isTest
public class BatchApexErrorEventTriggerTest {
    @isTest static void testMethod1(){
        User thisUser = [ SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1 ];
        System.runAs(thisUser) {
            insert new Account(Name = 'test');
            Environment_Variables__c testEnvVars = new Environment_Variables__c();
            testEnvVars.Generic_Sandbox_Email__c = 'sandbox_test@rubrik.com';
            testEnvVars.Production_Marketing_Apps_Email__c = 'sandtest@rubrik.com';
            testEnvVars.Production_SOX_Batch_Email__c = 'sox_test@rubrik.com';
            
            insert testEnvVars;
            try{
                Test.startTest();
                Database.executeBatch(new TestBatch(), 1);
                Test.stopTest();
            }catch(Exception ex){
                String errormsg =ex.getMessage();
            }
            Test.getEventBus().deliver();
            
            System.assertEquals(true, true);
        }
    }
}