@isTest
public with sharing class OpportunityComPortfolioSchedulerTest {
    @TestSetUp 
    static void initialDataSetup() {
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        ShGl_DisableBusinessLogic__c disableBLCS = ShGl_DisableBusinessLogic__c.getInstance();
        disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
        disableFuncCS.Disable_OpportunityValidationRules__c = true;
        
        disableBLCS.Disable_Opportunity_Validation_Rules__c= true;
        upsert disableFuncCS;
        upsert disableBLCS;
        Product2 newProd = new Product2(Name = 'test product', family = 'test family', ProductCode = 'OPTY-SPLIT');
        insert newProd;
        
        Pricebook2 pricebook = new Pricebook2(Name = 'Test Price Book', isActive = true);
        insert priceBook;
        
        Id standardPBId = test.getStandardPricebookId();
        
        PriceBookEntry pbEntry = new PriceBookEntry(
            UnitPrice = 400,
            PriceBook2Id = standardPBId,
            Product2Id = newProd.Id,
            IsActive = true,
            UseStandardPrice=false);
        insert pbEntry ;
        
        Opportunity opp = TestDataFactory.getOpportunity();
        opp.Pricebook2Id=standardPBId;
        insert opp;
        
        OpportunityLineItem oppLine = new OpportunityLineItem(pricebookentryid=pbEntry.Id,TotalPrice=2000, Quantity = 2,OpportunityID = opp.Id);
        insert oppLine;
    }

    @isTest static void testOpportunityComPortfolioScheduler() {
        
        Opportunity oppObject = [Select ID, Commission_Portfolio_Type__c, StageName, Opportunity_Type__c, Opportunity_Sub_Type__c, Order_Sub_Type__c , SBQQ__PrimaryQuote__c,
        (Select ID, Product2.Name, Product2.Item_Type__c, Product2.Product_Type__c, Product2.Product_Subtype__c, Product2.License_Type__c, SBQQ__QuoteLine__r.Licensing_Model__c from OpportunityLineItems) from Opportunity LIMIT 1];
        oppObject.Order_Sub_Type__c  = 'MSP Overage';
        oppObject.StageName = '7 Closed Won';
        oppObject.Opportunity_Sub_Type__c = 'Renewal';
        update oppObject;
        oppObject.Time_of_Last_Stage_Change__c = System.now()-1;
        update oppObject;
        Test.startTest();
        Datetime dt = Datetime.now().addMinutes(1);
        String jobID = System.Schedule('OpportunityComPortfolioSetup', dt.format('s m H d M \'?\' yyyy'), new OpportunityComPortfolioScheduler());		
        Test.stopTest();

        //Opportunity oppObj = [Select Commission_Portfolio_Type__c FROM Opportunity where ID = :oppObject.id];
        //System.assertEquals('MSP Actual',oppObj.Commission_Portfolio_Type__c);            

        OpportunityLineItem oli = oppObject.OpportunityLineItems[0];
        oli.Product2.Product_Subtype__c = 'GO';
        oli.Product2.Product_Type__c = 'Accessories';
        oli.Product2.Name = '-HYB-';
        oli.SBQQ__QuoteLine__r = new SBQQ__QuoteLine__c(Licensing_Model__c = 'Perpetual');

        oppObject.Opportunity_Sub_Type__c = 'Renewal';
        boolean  rank1 = OpportunityCommissionPortfolioBatch.isCommissionPortfolioTypeChanged(oppObject, new Set<ID>{});
        System.assertEquals('Renewal', oppObject.Commission_Portfolio_Type__c);

        oppObject.Opportunity_Sub_Type__c = 'Renewal1';
        oppObject.Order_Sub_Type__c  = 'MSP Consumption';
        boolean  rank2 = OpportunityCommissionPortfolioBatch.isCommissionPortfolioTypeChanged(oppObject, new Set<ID>{});
        System.assertEquals('MSP Consumption', oppObject.Commission_Portfolio_Type__c);

        oppObject.Order_Sub_Type__c  = 'MSP Overage';
        oppObject.Opportunity_Sub_Type__c  = 'MSP Overage';
        boolean  rank3 = OpportunityCommissionPortfolioBatch.isCommissionPortfolioTypeChanged(oppObject, new Set<ID>{});
        System.assertEquals('MSP Actual', oppObject.Commission_Portfolio_Type__c);

        oppObject.Opportunity_Sub_Type__c  ='MSP Consumption';
        oppObject.Order_Sub_Type__c  = 'MSP';
        boolean  rank4 = OpportunityCommissionPortfolioBatch.isCommissionPortfolioTypeChanged(oppObject, new Set<ID>{});
        System.assertEquals('Rubrik Go', oppObject.Commission_Portfolio_Type__c);

        oli.Product2.Product_Subtype__c = 'Complete';
        boolean  rank5 = OpportunityCommissionPortfolioBatch.isCommissionPortfolioTypeChanged(oppObject, new Set<ID>{});
        System.assertEquals('Rubrik Complete', oppObject.Commission_Portfolio_Type__c);

        oli.Product2.Product_Subtype__c = '';        
        boolean  rank6 = OpportunityCommissionPortfolioBatch.isCommissionPortfolioTypeChanged(oppObject, new Set<ID>{});
        System.assertEquals('LOD', oppObject.Commission_Portfolio_Type__c);

        oli.SBQQ__QuoteLine__r.Licensing_Model__c = '';        
        boolean  rank7 = OpportunityCommissionPortfolioBatch.isCommissionPortfolioTypeChanged(oppObject, new Set<ID>{});
        System.assertEquals('HW/PIT', oppObject.Commission_Portfolio_Type__c);

        oli.Product2.Product_Type__c = 'test';
        boolean  rank8 = OpportunityCommissionPortfolioBatch.isCommissionPortfolioTypeChanged(oppObject, new Set<ID>{});
        System.assertEquals('HYB Bundle', oppObject.Commission_Portfolio_Type__c);

        oli.Product2.Name = '-SUB-PRO-';
        boolean  rank9 = OpportunityCommissionPortfolioBatch.isCommissionPortfolioTypeChanged(oppObject, new Set<ID>{});
        System.assertEquals('Pro Bundle', oppObject.Commission_Portfolio_Type__c);

        oli.Product2.Name = '-SCALE-';
        boolean  rank10 = OpportunityCommissionPortfolioBatch.isCommissionPortfolioTypeChanged(oppObject, new Set<ID>{});
        System.assertEquals('Scale Order', oppObject.Commission_Portfolio_Type__c);

        oli.Product2.Name = 'test';
        oli.Product2.Item_Type__c = 'Non-inventory Item';
        boolean  rank11 = OpportunityCommissionPortfolioBatch.isCommissionPortfolioTypeChanged(oppObject, new Set<ID>{});
        System.assertEquals('SaaS/Support Only', oppObject.Commission_Portfolio_Type__c);

        oli.Product2.Item_Type__c = 'test';
        boolean  rank12 = OpportunityCommissionPortfolioBatch.isCommissionPortfolioTypeChanged(oppObject, new Set<ID>{});
        System.assertEquals('Other', oppObject.Commission_Portfolio_Type__c);

        System.assertEquals(true, rank1, 'Rank 1 condition is mismatch.');
        System.assertEquals(true, rank2, 'Rank 2 condition is mismatch.');
        System.assertEquals(true, rank3, 'Rank 3 condition is mismatch.');
        System.assertEquals(true, rank4, 'Rank 4 condition is mismatch.');
        System.assertEquals(true, rank5, 'Rank 5 condition is mismatch.');
        System.assertEquals(true, rank6, 'Rank 6 condition is mismatch.');
        System.assertEquals(true, rank7, 'Rank 7 condition is mismatch.');
        System.assertEquals(true, rank8, 'Rank 8 condition is mismatch.');
        System.assertEquals(true, rank9, 'Rank 9 condition is mismatch.');
        System.assertEquals(true, rank10, 'Rank 10 condition is mismatch.');
        System.assertEquals(true, rank11, 'Rank 11 condition is mismatch.');
        System.assertEquals(true, rank12, 'Rank 12 condition is mismatch.');

    }
}