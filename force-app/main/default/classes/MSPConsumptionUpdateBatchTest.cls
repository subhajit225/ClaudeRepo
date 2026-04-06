@isTest
private class MSPConsumptionUpdateBatchTest {

    @testSetup
    static void testSetup() {
        
       

        Account acct = new Account(
            Name = 'Test Account',
            Phone = '123-456-7890',
            AccountNumber = 'Test',
            BillingStreet = '123 street',
            BillingCity = 'Santa Clara',
            BillingState = 'California',
            BillingPostalCode = '95050',
            BillingCountry = 'United States'
        );
        insert acct;
        
        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => acct.Id,
                //'Initial_Contacts_Name__c' => cnt1.Id,
                'Primary_Competitor__c' => 'Other',
                'Other_Primary_Competitor__c' => 'Other',
                'Other_Competitor_Field__c' => 'Other',
                'Lost_To_Won_Against__c' => 'Other',
                'Polaris_Region__c' => 'US'
                };
        
         List<Opportunity> opptyList = (List<Opportunity>) ShGl_TestFactory.createSObjectList(new Opportunity(), 1, oppMap);
        //insert opptyList;

        List<Product2> prodlist = new List<Product2> {
            //startup product
            new Product2(Name = 'X-0001-01',
                ProductCode = 'X-0001-01',
                Category__c = 'Platform',
                Family = 'RBK-R300',
                Support_Type__c = 'PREM',
                Appliance_Model__c = 'R348',
                Appliance_Model_HW__c = 'R348',
                Create_Asset_Entitlement__c = true,
                Asset_Priority__c = 0,
                Product_Subtype__c = 'Start Up',
                IsActive = true
            ),
            //non-startup product
            new Product2(Name = 'X-0001-01',
                ProductCode = 'X-0001-01',
                Category__c = 'Platform',
                Family = 'RBK-R300',
                Support_Type__c = 'PREM',
                Appliance_Model__c = 'R348',
                Appliance_Model_HW__c = 'R348',
                Create_Asset_Entitlement__c = true,
                Asset_Priority__c = 0,
                IsActive = true
            )
        };
        insert prodlist;
       
        Id pricebookId = Test.getStandardPricebookId();
      
        
        List<Asset> assets = new list<Asset> {
            new Asset(Name = 'SN123', SerialNumber = 'SN123', Serial_Number__c = 'SN123', Accountid = acct.Id,Product2id = prodlist[0].id),
            new Asset(Name = 'SN234', SerialNumber = 'SN234', Serial_Number__c = 'SN234',  Accountid = acct.Id,Product2id = prodlist[0].id),
            new Asset(Name = 'SN356', SerialNumber = 'SN356', Serial_Number__c = 'SN356',  Accountid = acct.Id,Product2id = prodlist[1].id)
        };
        insert assets;
        
        
         List<Cluster__c> clusters = new List<Cluster__c> {
            new Cluster__c(UUID__c = 'Test1', Name = 'Test1', Location__c = 'Alamo'),
            new Cluster__c(UUID__c = 'Test2', Name = 'Test2', Location__c = 'Albany'),
            new Cluster__c(UUID__c = 'Test3', Name = 'Test3', Location__c = 'Alhambra')
        };
        insert clusters;
        
         List<Node__c> Nodes = new List<Node__c> {
            new Node__c(Name = 'RVMHM2', Serial_Number__c = 'RVMHM2',cluster__c = clusters[0].id,asset__c=assets[0].id),
            new Node__c(Name = 'RVMHM22', Serial_Number__c = 'RVMHM22',cluster__c = clusters[1].id,asset__c=assets[1].id),
            new Node__c(Name = 'RVMHM23', Serial_Number__c = 'RVMHM23',cluster__c = clusters[2].id,asset__c=assets[2].id)
         };
 
        insert Nodes;
}

 public static testMethod void MSPConsumptionUpdateBatchTest() {
     Test.startTest();
     database.executeBatch(new MSPConsumptionUpdateBatch());
     Test.stopTest();
     System.assertEquals(2, [select count() from Cluster__c where MSP_Consumption__c = true ],'MSP Consumption field did not get updated to true.');
     MSPConsumptionUpdateBatch.Schedulingmethod();
 }

}