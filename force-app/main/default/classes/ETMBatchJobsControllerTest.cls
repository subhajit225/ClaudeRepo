@isTest
public class ETMBatchJobsControllerTest {
    /*public ETMStage_Monitoring__c ETMStageMonitor = new ETMStage_Monitoring__c();
    @testSetup 
    static void setup() {
        ETMStageMonitor = new ETMStage_Monitoring__c(Status__c='New',name='Test Stage');
        insert ETMStageMonitor;
    }*/

    static testmethod void runETMBatchTest1() {
        /*
        ShGl_DisableBusinessLogic__c disableBusinessLogicCS = ShGl_DisableBusinessLogic__c.getInstance();
        disableBusinessLogicCS.Disable_ETMStageMonitoring_Triggers__c = true;
        upsert disableBusinessLogicCS;
        */
        ETMStage_Monitoring__c ETMStageMonitor = new ETMStage_Monitoring__c(Status__c='New',name='Test Stage');
        insert ETMStageMonitor;
        ApexPages.StandardController sc = new ApexPages.StandardController(ETMStageMonitor);
        ETMBatchJobsController etmBJC = new ETMBatchJobsController(sc);

        PageReference pageRef = Page.ETMBatchJobsRun;
        pageRef.getParameters().put('id', String.valueOf(ETMStageMonitor.Id));
        Test.setCurrentPage(pageRef);
        Test.startTest();
        PageReference etmPR = etmBJC.runETMBatch();
        Test.stopTest();
    }

    static testmethod void runETMBatchTest2() {
        ETMStage_Monitoring__c ETMStageMonitor = new ETMStage_Monitoring__c(Status__c='Init',name='Test Stage');
        insert ETMStageMonitor;
        ApexPages.StandardController sc = new ApexPages.StandardController(ETMStageMonitor);
        ETMBatchJobsController etmBJC = new ETMBatchJobsController(sc);

        PageReference pageRef = Page.ETMBatchJobsRun;
        pageRef.getParameters().put('id', String.valueOf(ETMStageMonitor.Id));
        Test.setCurrentPage(pageRef);
        Test.startTest();
        PageReference etmPR1 = etmBJC.runETMBatch();
        PageReference etmPR2 = etmBJC.redirectToETMStageMonitorRecord();
        Test.stopTest();
    }

    static testmethod void runETMBatchTest3() {
        
        ShGl_DisableBusinessLogic__c disableBusinessLogicCS = ShGl_DisableBusinessLogic__c.getInstance();
        disableBusinessLogicCS.Disable_ETMStageMonitoring_Triggers__c = true;
        upsert disableBusinessLogicCS;
        
        ETMStage_Monitoring__c ETMStageMonitor = new ETMStage_Monitoring__c(Status__c='New',name='Test Stage');
        insert ETMStageMonitor;
        Test.startTest();
        ETMCreateTerritoryModelBatch etmBatch = new ETMCreateTerritoryModelBatch();
        etmBatch.etmStageMonitoringId = ETMStageMonitor.Id;
        Database.executeBatch(etmBatch,1);
        ApexPages.StandardController sc = new ApexPages.StandardController(ETMStageMonitor);
        ETMBatchJobsController etmBJC = new ETMBatchJobsController(sc);
        PageReference pageRef = Page.ETMBatchJobsRun;
        pageRef.getParameters().put('id', String.valueOf(ETMStageMonitor.Id));
        Test.setCurrentPage(pageRef);
        PageReference etmPR = etmBJC.runETMBatch();
        Test.stopTest();
    }
     static testmethod void runETMBatchTest4() {
        ETMStage_Monitoring__c ETMStageMonitor = new ETMStage_Monitoring__c(Status__c='New',name='Test Stage');
        insert ETMStageMonitor;
        Test.startTest(); 
        ETMBatchJobsLWCController.runETMBatch(ETMStageMonitor.Id);
        Test.stopTest();
    }

    static testmethod void runETMBatchTest5() {
        ETMStage_Monitoring__c ETMStageMonitor = new ETMStage_Monitoring__c(Status__c='Init',name='Test Stage');
        insert ETMStageMonitor;
        Test.startTest();
        ETMBatchJobsLWCController.runETMBatch(ETMStageMonitor.Id);
        Test.stopTest();
    }

    static testmethod void runETMBatchTest6() {
        
        ShGl_DisableBusinessLogic__c disableBusinessLogicCS = ShGl_DisableBusinessLogic__c.getInstance();
        disableBusinessLogicCS.Disable_ETMStageMonitoring_Triggers__c = true;
        upsert disableBusinessLogicCS;
        
        ETMStage_Monitoring__c ETMStageMonitor = new ETMStage_Monitoring__c(Status__c='New',name='Test Stage');
        insert ETMStageMonitor;
        Test.startTest();
        ETMCreateTerritoryModelBatch etmBatch = new ETMCreateTerritoryModelBatch();
        etmBatch.etmStageMonitoringId = ETMStageMonitor.Id;
        Database.executeBatch(etmBatch,1);
        ETMBatchJobsLWCController.runETMBatch(ETMStageMonitor.Id);
        Test.stopTest();
    }
}