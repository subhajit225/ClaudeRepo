/********************************************************************************************************
* Name              : ProductsController_Test 
* Purpose           : ProductsController_Test is Used for Testing ProductsController Class
*********************************************************************************************************/
@IsTest
public class ProductsController_Test{
    public static testMethod void testProductsControllerMethods(){
        ProductsController.isTest=true;
        ProductsController pr = new ProductsController();
        
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

        List<Product2> products = new List<Product2> {
            //apliance
            new Product2(Name = 'RBK-R348-01',
                ProductCode = 'RBK-R348-01',
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
        insert products;
        
        List<Asset> assets = new list<Asset> {
            new Asset(Name = 'SN1', SW_Version__c = '0.1', SerialNumber = 'SN1', Serial_Number__c = 'SN1', Product2Id = products[0].Id, Accountid = acct.Id)
        };
        insert assets;
        
        List<Cluster__c> clusters = new List<Cluster__c> {
            new Cluster__c(UUID__c = 'Test1', Name = 'Test1'),
            new Cluster__c(UUID__c = 'Test2', Name = 'Test2',Account__c=acct.id)
        };
        insert clusters;
        
        Node__c node=new Node__c(
            Cluster__c = clusters.get(0).Id,
            Asset__c = assets.get(0).Id,
            Serial_Number__c = 'SNN-1-1',
            software_version__c = '1.0.1',
            Model__c = 'Edge',
            Name = 'SNN-1-1'
        );
        insert node;
        
        Test.startTest();
        pr.getClusters();
        pr.getDarkNodes();
        pr.getEdgeNodes();
        pr.getClout();
        pr.getClon();
        pr.getClCL();
        Test.stopTest();
    }
    
    public static testMethod void testGetedgeSize(){
        ProductsController pr = new ProductsController();
        
        Test.startTest();
        pr.getEdgeNodes();
        pr.getedgeSize();
        ProductsController.isTest=true;
        Test.stopTest();
    }
    
}