@isTest()
public class updateProductTypeOLIBatchTest {
	@testSetup static void setup() {
        ShGl_DisableBusinessLogic__c sb = new ShGl_DisableBusinessLogic__c(TriggerMaxLoopCount__c=8,Disable_Opportunity_Triggers__c = false,SetupOwnerId=UserInfo.getOrganizationId());                     
        insert sb;
        ShGl_DisableFunctionalityLogic__c sf = new ShGl_DisableFunctionalityLogic__c(Disable_Opportunity_Old_Trigger__c = true,SetupOwnerId=UserInfo.getOrganizationId());                     
        insert sf;
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account act =new Account(BillingCountryCode = 'US', Is_Refreshed__c = False, Name = 'Test', Sync_to_NetSuite__c = false, RecordTypeId = devRecordTypeId, Website='www.test3.com', OwnerId = userinfo.getUserId(),type='Customer');
        flowcontroll.accountTrigger = false;
        insert act;
        Id standardPriceBookId = Test.getStandardPricebookId();
        opportunity oppr = new opportunity(Name='testing DIEtestsalesforce 4/6/2015' , Opportunity_Sub_Type__c = 'Regular', Distributor_Lookup__c = act.Id, Alliance_Source_Type_HW__c = 'Rubrik Initiated Alliance Deal',
                                           Mosaic_Customer_Environment__c='AWS', CloseDate = Date.Today().addDays(10), Lead_Email_Hidden__c='', AccountId = act.Id, StageName = '1 Discovery',
                                           Rubrik_Sales_Engineer__c = UserInfo.getUserId(), Alliance_Partner_Name__c='Amazon', Alliance_Source_Type__c='Alliance Initiated Deal', Installation_Assigned_To__c ='FE Install',
                                           Economic_Buyer__c = 'Test', Metric__c = 'Test', Decision_Process__c = 'Test', Decision_Criteria__c = 'Test',
                                           Alliance_Source_Type_SW__c ='Rubrik Initiated Alliance Deal', Identified_Pain__c = 'Test', Champion__c = 'Test', ForecastCategoryName = 'Best Case',pricebook2Id=standardPriceBookId);
        
        flowcontroll.opportunityTriggerHandler = false;
        insert oppr;  

    }
    static testMethod void testMethod1() {  
        testDataFactoryClass.createCustomSettings();
        Account acct = [SELECT Id FROM Account WHERE Name = 'Test'  LIMIT 1];        
        
        Opportunity oppr = [SELECT Id,Opportunity_Sub_Type__c, pricebook2Id FROM Opportunity WHERE AccountId =: acct.Id LIMIT 1];
        List<Product2> lstProds = new List<Product2>{
            new Product2(
                Name='RBK-SVC-PREM-R344',ProductCode='RBK-SVC-PREM-R344',Family='ASE', Appliance_Model_HW__c = 'RBK-R6408F',
                isActive = true,Product_Level__c = 'Support',Product_Type__c='Consulting'
            ),
                new Product2(
                    Name='RBK-SVC-PREM-R344',ProductCode='RBK-SVC-PREM-R344', Appliance_Model_HW__c = 'RBK-R640F',
                    isActive = true ,Product_Level__c = 'Support',Product_Type__c='Consulting', Bundle_Features__c = 'Cloud Native Protection', Family ='POLARIS'
                ),
                new Product2(
                    Name='RBK-SVC-PREM-R344',ProductCode='RBK-SVC-PREM-R344',Product_Type__c='Consulting', Appliance_Model_HW__c = 'RBK-R640F',
                    isActive = true , Bundle_Features__c = 'Cloud Native Protection', Family ='RCDM',
                    MSP_Std_Actual__c=null,Product_Level__c = 'Support'
                )
                };
                    
        insert lstProds;
        List<PricebookEntry> lstPbEntry =new List<PricebookEntry>{
            new PricebookEntry(
                Pricebook2Id = oppr.pricebook2Id,
                Product2Id = lstProds[0].Id,
                UnitPrice = 100.00,
                UseStandardPrice = false,
                IsActive = true
            ),
                new PricebookEntry(
                    Pricebook2Id = oppr.pricebook2Id,
                    Product2Id = lstProds[1].Id,
                    UnitPrice = 100.00,
                    UseStandardPrice = false,
                    IsActive = true
                ),
                new PricebookEntry(
                    Pricebook2Id = oppr.pricebook2Id,
                    Product2Id = lstProds[2].Id,
                    UnitPrice = 100.00,
                    UseStandardPrice = false,
                    IsActive = true
                )
                };
                    
        insert lstPbEntry;  
        
        List<OpportunityLineItem> lstOlis = new List<OpportunityLineItem>{
            new OpportunityLineItem(
                OpportunityId = oppr.Id,
                Quantity = 5,
                PricebookEntryId = lstPbEntry[0].Id,
                TotalPrice = 5 *  lstPbEntry[0].UnitPrice
            ),
                new OpportunityLineItem(
                    OpportunityId = oppr.Id,
                    Quantity = 5,
                    PricebookEntryId = lstPbEntry[1].Id,
                    TotalPrice = 5 *  lstPbEntry[1].UnitPrice
                )
                };
                    
       
       
        insert lstOlis;    
        Test.startTest();
        product2history ph = new product2history(Product2Id = lstProds[0].Id, Field = 'Product_Type__c'); 
        insert ph; 
        updateProductTypeOLIBatch bat = new updateProductTypeOLIBatch();
		Database.executeBatch(bat,100);
        OpportunityLineItemTriggersHelper.createOli(lstOlis[1]);
        delete lstOlis[1];
        Test.stopTest();
    }
    static testMethod void testMethod2() {  
        Test.startTest();
        flowControll.disableAllTriggers();
        Test.stopTest();
    }
}