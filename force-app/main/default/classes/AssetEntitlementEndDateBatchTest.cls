@isTest
public with sharing class AssetEntitlementEndDateBatchTest {
    public AssetEntitlementEndDateBatchTest() {}

    @testSetup static void createTestData() {
        
        TriggerControl__c custsetting = new TriggerControl__c();
        custsetting.Name = 'Entitlement';
        custsetting.DisableTrigger__c = true;
        insert custsetting;

        Account acct = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        acct.Name = 'Test Account';
        insert acct;

        List<Product2> prodlist = new List<Product2>();
        Map<String, Object>  prodMap = new Map<String, Object> {
            'Name' => 'X-0001-01',
                'ProductCode' => 'ProductXYZ',
                'isActive' => true,
                'Family' => 'POLARIS',
                'Product_Type__c' => 'Appliance'
                };
        Product2 pd = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap);  
        prodlist.add(pd);
        insert prodlist;

        List<Asset> assetsList = new List<Asset> {
            new Asset(Name = 'SN123', SerialNumber = 'SN123', Serial_Number__c = 'SN123', Accountid = acct.Id,Product2id = prodlist[0].id, Premium_Support_End_Date__c = Date.today(), Status='Purchased'),
            new Asset(Name = 'SN234', SerialNumber = 'SN234', Serial_Number__c = 'SN234', Accountid = acct.Id,Product2id = prodlist[0].id, Premium_Support_End_Date__c = (Date.today().addDays(1)), Status='Purchased'),
            new Asset(Name = 'SN356', SerialNumber = 'SN356', Serial_Number__c = 'SN356', Accountid = acct.Id,Product2id = prodlist[0].id, Status='Purchased')
        };
        insert assetsList;

        List<Entitlement> lstEntitlmnts = new List<Entitlement>();

        //Asset assetsList[0] and entitlement dosent have mismatched end date
        lstEntitlmnts.add(new Entitlement(Name='test1',AccountId=acct.Id,AssetId=assetsList[0].Id,StartDate=Date.today(),EndDate=Date.today()));

        //Asset assetsList[1] has many entitlements with mismatched end date.. Latest end date entitlement should be used for matching with asset
        for(Integer itr=2;itr<202;itr++){
            lstEntitlmnts.add(new Entitlement(Name='test'+itr,AccountId=acct.Id,AssetId=assetsList[1].Id,StartDate=Date.today(),EndDate=(Date.today().addDays(itr))));
        }

        //Asset assetsList[2] with no end date still considered a mismatche with entitlement
        lstEntitlmnts.add(new Entitlement(Name='test205',AccountId=acct.Id,AssetId=assetsList[2].Id,StartDate=Date.today(),EndDate=Date.today()));

        insert lstEntitlmnts;
    }

    /*Following test will cover the scenario where the mismatched 
     *Asset-Entitlments exist
    */
    @isTest
    public static void getReportPositiveScenario(){
        
        Test.startTest();
        Database.executeBatch(new AssetEntitlementEndDateBatch(), 2000);
        Test.stopTest();
        List<AsyncApexJob> lstAsyncBatchJob = [SELECT ApexClassId,
                                                      Id,
                                                      JobType,
                                                      MethodName,
                                                      Status         
                                               FROM AsyncApexJob
                                               WHERE JobType = 'BatchApex'];
        System.assertEquals(1, lstAsyncBatchJob.size());

    }

    /*Following test will cover the scenario where the mismatched 
     *Asset-Entitlments --DOES NOT-- exist
    */
    @isTest
    public static void getReportNegativeScenario(){
        
        delete[SELECT Id FROM Entitlement];
        
        Test.startTest();
        Database.executeBatch(new AssetEntitlementEndDateBatch(), 2000);
        Test.stopTest();
        List<AsyncApexJob> lstAsyncBatchJob = [SELECT ApexClassId,
                                                      Id,
                                                      JobType,
                                                      MethodName,
                                                      Status         
                                               FROM AsyncApexJob
                                               WHERE JobType = 'BatchApex'];
        System.assertEquals(1, lstAsyncBatchJob.size());

    }
}