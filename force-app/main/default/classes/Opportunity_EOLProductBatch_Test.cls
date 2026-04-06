@isTest
private class Opportunity_EOLProductBatch_Test {
	
	@testSetup
    static void testSetup() {
        Date closeDt = System.Today()+130;
        TriggerControl__c setting = new TriggerControl__c();
        setting.Name = 'Opportunity';
        setting.DisableTrigger__c = False;
        insert setting;

        id rId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account act =new Account(BillingCountryCode = 'US', Is_Refreshed__c = False, Name = 'Test', Sync_to_NetSuite__c = false, RecordTypeId = rId, Website='www.test3.com', OwnerId = userinfo.getUserId(),type='Customer');
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

        Product2 pd = new Product2(Name='RBK-R334-01',ProductCode='RBK-R334-01',Family='r300',isActive=true);
        pd.IsActive = true;
        insert pd;

        //PriceBook2 pb2Standard = [select Id from Pricebook2 where isStandard=true];
        //Id standardPriceBookId = pb2Standard.Id;        
        PriceBook2 CPQPriceBook = new Pricebook2(Name='CPQ PriceBook');
        insert CPQPriceBook;
        //PriceBook2 CPQPriceBook = [select Id from Pricebook2 where Name='CPQ PriceBook'];
        Id CPQPriceBookId = CPQPriceBook.Id;

        PricebookEntry pbe = new PricebookEntry(Pricebook2Id=standardPriceBookId, Product2Id=pd.Id, UnitPrice=99, isActive=true);
        insert pbe;

        Product2 p2ex = [SELECT Name FROM Product2 WHERE Id = :pd.Id];
        System.assertEquals(pd.Name,p2ex.Name);
        

        //Create your product
        Product2 prod = new Product2(
            Name='RBK-SVC-PREM-R344',ProductCode='RBK-SVC-PREM-R344',Family='RBK-R300',
            isActive = true
        );
        insert prod;

        //Create your product
        Product2 prod2 = new Product2(
            Name='RBK-SVC-PREM-R3410',ProductCode='RBK-SVC-PREM-R3410',Family='RBK-R300',
            isActive = true
        );
        insert prod2;

        //Create your product
        Product2 prod3 = new Product2(
            Name='RBK-SVC-PREM-R3445',ProductCode='RBK-SVC-PREM-R3445',Family='RBK-R300',
            isActive = true
        );
        insert prod3;

        Opportunity oppRec =[select id ,Pricebook2Id from Opportunity where Id=:oppr.Id];

        //Create your pricebook entry
        PricebookEntry pbEntry = new PricebookEntry(
            Pricebook2Id = oppRec.Pricebook2Id,
            Product2Id = prod.Id,
            UnitPrice = 100.00,
            UseStandardPrice = false,
            IsActive = true
        );
        insert pbEntry;
        //Create your pricebook entry
        PricebookEntry pbEntry3 = new PricebookEntry(
            Pricebook2Id = oppRec.Pricebook2Id,
            Product2Id = prod3.Id,
            UnitPrice = 100.00,
            UseStandardPrice = false,
            IsActive = true
        );
        insert pbEntry3;
        //Create your pricebook entry
        PricebookEntry pbEntry2 = new PricebookEntry(
            Pricebook2Id = oppRec.Pricebook2Id,
            Product2Id = prod2.Id,
            UnitPrice = 1000.00,
            UseStandardPrice = false,
            IsActive = true
        );
        insert pbEntry2;

        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = oppRec.Id,
            Quantity = 5,
            PricebookEntryId = pbEntry3.Id,
            TotalPrice = 5 * pbEntry.UnitPrice
        );
        insert oli;

        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OpportunityLineItem oli2 = new OpportunityLineItem(
            OpportunityId = oppRec.Id,
            Quantity = 5,
            PricebookEntryId = pbEntry3.Id,
            TotalPrice = 5 * pbEntry.UnitPrice
        );
        insert oli2;
	}
	
	@isTest static void testMethod_ExecuteBatch() {
		// Implement test code
		Test.startTest();
            Opportunity_EOLProductBatch obj = new Opportunity_EOLProductBatch();
            DataBase.executeBatch(obj); 
            Opportunity_EOLProductBatchSchedular sch1 = new Opportunity_EOLProductBatchSchedular();
            String sch = '0  00 1 3 * ?';
            system.schedule('Test', sch, sch1);
        Test.stopTest();
	}
	
}