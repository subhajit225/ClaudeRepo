@isTest
public class SandboxRefreshEMaskInWorkFlowAlertTest {
    static testMethod void sandboxPostRefreshBatchTest(){
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new SandboxRefreshEMaskWorkFlowAlertMock());
        SandboxRefreshEmailMaskInWorkFlowAlerts emailMaskInWorkFlowAlerts = new SandboxRefreshEmailMaskInWorkFlowAlerts();
        Database.executeBatch(emailMaskInWorkFlowAlerts, 5);
        
        Sandbox_Refresh_Config__c sandboxRefreshConfig = new Sandbox_Refresh_Config__c(Name = 'Test', Description__c = 'Test Batch Execution', Status__c = 'Not Started', 
                                                                                       Execution_Order__c = 1, ObjectLabel__c = 'Email service', Type__c = 'Email Mask',
                                                                                       NoOfRecords__c = 0, LastFailedRecordCount__c = 0, ErrorDetails__c = '');
        Insert sandboxRefreshConfig;
        Database.executeBatch(new SandboxRefreshEmailMaskInWorkFlowAlerts(sandboxRefreshConfig.Id), 5);
        test.stopTest();
    }
}