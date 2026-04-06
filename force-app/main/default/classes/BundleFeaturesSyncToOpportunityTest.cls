/**
* @description Test Class for  BundleFeaturesSyncToOpportunity
*
* @CreatedDate 07th March 2022
* @Created By Veera Gandi
* 
*/
@isTest(SeeAllData=false)
public class BundleFeaturesSyncToOpportunityTest {
    
    @testSetup
    static void testSetUp() {
        
        List<Account> accounts = new List<Account>();
        
        for (integer i=0 ; i< 20; i++) {
            Account account = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            account.Name = 'Test Account' + i;
            accounts.add(account);
        }
        
        Account account = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Distributor').getRecordTypeId();
        account.Partner_Agreement_Status__c = 'Approved ';
        account.Name = 'PartnerResellerAccount';
        accounts.add(account);
        insert accounts;
        
        TriggerControl__c control= new TriggerControl__c();
        control.Name='Opportunity';
        control.DisableTrigger__c=true;
        insert control;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        Opportunity opportunity = TestDataFactory.getOpportunity(accounts[0]);
        opportunity.closeDate = Date.today() + 5;
        opportunity.StageName = '4 Business Justification';
        opportunity.Pricebook2Id = pricebookId;
        
        insert opportunity;
        
        Product2 newProduct = new Product2(
            Name = 'RBK-R348-01',
            ProductCode = 'RBK-R348-01',
            Category__c = 'Platform',
            Family = 'R300',
            Support_Type__c = 'PREM',
            Appliance_Model__c = 'R348',
            Appliance_Model_HW__c = 'R348',
            Create_Asset_Entitlement__c = true,
            Asset_Priority__c = 0,
            IsActive = true,
            IsBundleFeaturesUpdated__c = true,
            Bundle_Features__c = 'Sonar'
        );
        
        insert newProduct;
        
        PricebookEntry newEntry = new PricebookEntry(
            Pricebook2Id = opportunity.pricebook2Id,
            Product2Id = newProduct.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        
        insert newEntry;
        
        OpportunityLineItem newOpportunityLineItem = new OpportunityLineItem(
            OpportunityId = opportunity.Id,
            Quantity = 5,
            Product2Id = newProduct.Id,
            PricebookEntryId = newEntry.Id,
            TotalPrice = 5 * newEntry.UnitPrice
        );
        
        insert newOpportunityLineItem;
    }
    
    @istest
    static void testBundleFeaturesSyncFromProductToOpportunity() {
        test.startTest();
        BundleFeaturesSyncToOpportunity syncBundleFeatures = new BundleFeaturesSyncToOpportunity();
        Database.executeBatch(syncBundleFeatures, 10);
        test.stopTest();
        
        List<Opportunity> opportunities = [SELECT Id, BundleFeatures__c FROM Opportunity LIMIT 1];
        System.assertEquals('Sonar', opportunities[0].BundleFeatures__c);        
    }
    
    @istest
    static void testBundleFeaturesSyncToOpportunity() {
        test.startTest();
        BundleFeaturesSyncToOpportunity syncBundleFeatures = new BundleFeaturesSyncToOpportunity(false);
        Database.executeBatch(syncBundleFeatures, 10);
        test.stopTest();
        
        List<Opportunity> opportunities = [SELECT Id, BundleFeatures__c FROM Opportunity LIMIT 1];
        System.assertEquals('Sonar', opportunities[0].BundleFeatures__c);        
    }
    
}