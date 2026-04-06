@istest
public with sharing class AssetEntitlementEndDateControllerTest {
    public AssetEntitlementEndDateControllerTest() {}

    @isTest
    public static void getReportTest(){
        
        AssetEntitlementEndDateController ctrlInst = new AssetEntitlementEndDateController();
        System.assertEquals(false, ctrlInst.notificationPanel);
        Test.startTest();
        ctrlInst.getReport();
        Test.stopTest();
        List<AsyncApexJob> lstAsyncBatchJob = [SELECT ApexClassId,
                                                      Id,
                                                      JobType,
                                                      MethodName,
                                                      Status         
                                               FROM AsyncApexJob
                                               WHERE JobType = 'BatchApex'];
        System.assertEquals(true, ctrlInst.notificationPanel);
        System.assertEquals(1, lstAsyncBatchJob.size());
    }
}