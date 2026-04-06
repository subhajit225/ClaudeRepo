@IsTest
private class UpdatePrimaryQuotesBatchTest {

    @TestSetup
    static void setupData() {
    
    List<Product2> listProduct = new List<Product2>();
        Product2 productOne = new Product2(
            Name = 'RBK-MSP-AIR',
            ProductCode = 'RBK-MSP-AIR',
            Category__c = 'Software',
            SBQQ__AssetConversion__c = 'None',
            SBQQSC__EntitlementConversion__c = 'One per unit',
            SBQQ__SubscriptionPricing__c = 'Fixed Price',
            SBQQ__SubscriptionTerm__c = 12,
            SBQQ__SubscriptionBase__c = 'List',
            SBQQ__SubscriptionType__c = 'Renewable',
            IsActive = true,
            Asset_Priority__c = 1,
            New_CPQ_Product__c = true
        );
        listProduct.add(productOne);
        Product2 productTwo = new Product2 (
            Name = 'RH-6408SE-02',
            ProductCode = 'RH-6408SE-02',
            Category__c = 'Hardware',
            SBQQ__AssetConversion__c = 'None',
            SBQQSC__EntitlementConversion__c = 'One per unit',
            SBQQ__SubscriptionPricing__c = 'Fixed Price',
            SBQQ__SubscriptionTerm__c = 12,
            SBQQ__SubscriptionBase__c = 'List',
            SBQQ__SubscriptionType__c = 'Renewable',
            IsActive = true,
            Asset_Priority__c = 1,
            New_CPQ_Product__c = true
        );
        listProduct.add(productTwo);
        insert listProduct;
        
        List<Pricebook2> listPricebook = TestDataFactory.getPricebook('PriceBook', 1);
        listPricebook[0].Name = 'CPQ Pricebook';
        insert listPricebook;
        
        List<PriceBookEntry> listPricebookentry = TestDataFactory.getPriceBookEntry(
            new List<Id>{listProduct[0].Id, listProduct[1].Id},
            new List<Id>{Test.getStandardPricebookId(), listPricebook[0].Id}
        );
        insert listPricebookentry;
        
        Opportunity objOpportunity = TestDataFactory.getOpportunity();
        insert objOpportunity;
       
    }
        
        
    @IsTest
    static void testUpdatePrimaryQuotesBatch() {
        
        List<Opportunity> opportunityList1 = [SELECT Id, Name FROM Opportunity];
        List<Pricebook2> listPricebook1 = [SELECT Id, Name FROM Pricebook2];
        List<Product2> listProduct1 = [SELECT Id, Name FROM Product2];
        List<PriceBookEntry> listPricebookentry1 = [SELECT Id, Name FROM PriceBookEntry];
        
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        SBQQ.TriggerControl.disable();
        
        List<SBQQ__Quote__c> listQuote = TestDataFactory.getQuotes(new Set<Id>{opportunityList1[0].Id}, 1);
        listQuote[0].SBQQ__Primary__c = True;
        listQuote[0].SBQQ__PriceBook__c = listPricebook1[0].Id;
        listQuote[0].SBQQ__PricebookId__c = listPricebook1[0].Id;
        insert listQuote;
                
        List<SBQQ__QuoteLine__c> listQuoteLine = TestDataFactory.getQuoteLines (
        new Map<Id, List<Id>> {
            listQuote[0].Id => new List<Id>{listProduct1[0].Id}
            }
        );
        //listQuoteLine[0].SBQQ__PricebookEntryId__c = listPricebookentry1[0].Id;
        listQuoteLine[0].SBQQ__NetPrice__c = 0;
        insert listQuoteLine;
        
        
         List<SBQQ__Quote__c> listQuote1 = TestDataFactory.getQuotes(new Set<Id>{opportunityList1[0].Id}, 1);
        listQuote1[0].SBQQ__Primary__c = True;
        listQuote1[0].SBQQ__PriceBook__c = listPricebook1 [0].Id;
        listQuote1[0].SBQQ__PricebookId__c = listPricebook1 [0].Id;
        insert listQuote1;
                
        List<SBQQ__QuoteLine__c> listQuoteLine1 = TestDataFactory.getQuoteLines (
        new Map<Id, List<Id>> {
            listQuote1[0].Id => new List<Id>{listProduct1[0].Id}
            }
        );
        //listQuoteLine1[0].SBQQ__PricebookEntryId__c = listPricebookentry1[0].Id;
        listQuoteLine1[0].SBQQ__NetPrice__c = 0;
        insert listQuoteLine1;
        
        TriggerControls.disableQuoteTrigger = false;
        TriggerControls.disableQuoteLineTrigger = false;
        SBQQ.TriggerControl.enable();
        

        Test.startTest();
        UpdatePrimaryQuotesBatch batch = new UpdatePrimaryQuotesBatch();
        Database.executeBatch(batch,10);
        Test.stopTest();

        List<Sbqq__quote__c> updatedQuotes = [SELECT Id, SBQQ__Opportunity2__c , SBQQ__Primary__c FROM Sbqq__quote__c];
        System.assertEquals(true,updatedQuotes.size()>0);

    }
    
        
    @IsTest
    static void testUpdateQuotesBatch() {
          
        List<Opportunity> opportunityList1 = [SELECT Id, Name FROM Opportunity];
        List<Pricebook2> listPricebook1 = [SELECT Id, Name FROM Pricebook2];
        List<Product2> listProduct1 = [SELECT Id, Name FROM Product2];
        List<PriceBookEntry> listPricebookentry1 = [SELECT Id, Name FROM PriceBookEntry];
        
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        SBQQ.TriggerControl.disable();
        
        List<SBQQ__Quote__c> listQuote = TestDataFactory.getQuotes(new Set<Id>{opportunityList1[0].Id}, 1);
        listQuote[0].SBQQ__PriceBook__c = listPricebook1[0].Id;
        listQuote[0].SBQQ__PricebookId__c = listPricebook1[0].Id;
        insert listQuote;
        
        List<SBQQ__QuoteLine__c> listQuoteLine = TestDataFactory.getQuoteLines (
        new Map<Id, List<Id>> {
            listQuote[0].Id => new List<Id>{listProduct1[0].Id}
            }
        );
        listQuoteLine[0].SBQQ__NetPrice__c = 100;
        insert listQuoteLine;
        
        
         List<SBQQ__Quote__c> listQuote1 = TestDataFactory.getQuotes(new Set<Id>{opportunityList1[0].Id}, 1);
        listQuote1[0].SBQQ__PriceBook__c = listPricebook1 [0].Id;
        listQuote1[0].SBQQ__PricebookId__c = listPricebook1 [0].Id;
        insert listQuote1;
        
        List<SBQQ__QuoteLine__c> listQuoteLine1 = TestDataFactory.getQuoteLines (
        new Map<Id, List<Id>> {
            listQuote1[0].Id => new List<Id>{listProduct1[0].Id}
            }
        );
        listQuoteLine1[0].SBQQ__NetPrice__c = 100;
        insert listQuoteLine1;
        
        TriggerControls.disableQuoteTrigger = false;
        TriggerControls.disableQuoteLineTrigger = false;
        SBQQ.TriggerControl.enable();
        

        Test.startTest();
        UpdatePrimaryQuotesBatchScheduler sh1 = new UpdatePrimaryQuotesBatchScheduler();
        
        String sch = '0 0 23 * * ?'; 
        system.schedule('Test Territory Check', sch, sh1); 
        Test.stopTest();

        List<Sbqq__quote__c> updatedQuotes = [SELECT Id, SBQQ__Opportunity2__c , SBQQ__Primary__c FROM Sbqq__quote__c];
        System.assertEquals(true,updatedQuotes.size()>0);

    }
        
    
        
    @IsTest
    static void testUpdatePrimaryQuotesOppBatch() {
          
        List<Opportunity> opportunityList1 = [SELECT Id, Name FROM Opportunity];
        List<Pricebook2> listPricebook1 = [SELECT Id, Name FROM Pricebook2];
        List<Product2> listProduct1 = [SELECT Id, Name FROM Product2];
        List<PriceBookEntry> listPricebookentry1 = [SELECT Id, Name FROM PriceBookEntry];
        
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        SBQQ.TriggerControl.disable();
        
        List<SBQQ__Quote__c> listQuote = TestDataFactory.getQuotes(new Set<Id>{opportunityList1[0].Id}, 1);
        listQuote[0].SBQQ__PriceBook__c = listPricebook1[0].Id;
        listQuote[0].SBQQ__PricebookId__c = listPricebook1[0].Id;
        insert listQuote;
        
        List<SBQQ__QuoteLine__c> listQuoteLine = TestDataFactory.getQuoteLines (
        new Map<Id, List<Id>> {
            listQuote[0].Id => new List<Id>{listProduct1[0].Id}
            }
        );
        listQuoteLine[0].SBQQ__NetPrice__c = 100;
        insert listQuoteLine;
        
        
         List<SBQQ__Quote__c> listQuote1 = TestDataFactory.getQuotes(new Set<Id>{opportunityList1[0].Id}, 1);
        listQuote1[0].SBQQ__PriceBook__c = listPricebook1 [0].Id;
        listQuote1[0].SBQQ__PricebookId__c = listPricebook1 [0].Id;
        insert listQuote1;
        
        List<SBQQ__QuoteLine__c> listQuoteLine1 = TestDataFactory.getQuoteLines (
        new Map<Id, List<Id>> {
            listQuote1[0].Id => new List<Id>{listProduct1[0].Id}
            }
        );
        listQuoteLine1[0].SBQQ__NetPrice__c = 100;
        insert listQuoteLine1;
        
        TriggerControls.disableQuoteTrigger = false;
        TriggerControls.disableQuoteLineTrigger = false;
        SBQQ.TriggerControl.enable();
        

        Test.startTest();
        Set<Id> oppId = new Set<Id>{opportunityList1[0].Id};
        UpdatePrimaryQuotesBatch batch = new UpdatePrimaryQuotesBatch(oppId);
        Database.executeBatch(batch,10);
        Test.stopTest();

        List<Sbqq__quote__c> updatedQuotes = [SELECT Id, SBQQ__Opportunity2__c , SBQQ__Primary__c FROM Sbqq__quote__c];
        System.assertEquals(true,updatedQuotes.size()>0);

    }
    
     @IsTest
    static void testUpdatePrimaryQuotesOppQueryBatch() {
          
        List<Opportunity> opportunityList1 = [SELECT Id, Name FROM Opportunity];
        List<Pricebook2> listPricebook1 = [SELECT Id, Name FROM Pricebook2];
        List<Product2> listProduct1 = [SELECT Id, Name FROM Product2];
        List<PriceBookEntry> listPricebookentry1 = [SELECT Id, Name FROM PriceBookEntry];
        
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        SBQQ.TriggerControl.disable();
        
        List<SBQQ__Quote__c> listQuote = TestDataFactory.getQuotes(new Set<Id>{opportunityList1[0].Id}, 1);
        listQuote[0].SBQQ__PriceBook__c = listPricebook1[0].Id;
        listQuote[0].SBQQ__PricebookId__c = listPricebook1[0].Id;
        insert listQuote;
        
        List<SBQQ__QuoteLine__c> listQuoteLine = TestDataFactory.getQuoteLines (
        new Map<Id, List<Id>> {
            listQuote[0].Id => new List<Id>{listProduct1[0].Id}
            }
        );
        listQuoteLine[0].SBQQ__NetPrice__c = 100;
        insert listQuoteLine;
        
        
         List<SBQQ__Quote__c> listQuote1 = TestDataFactory.getQuotes(new Set<Id>{opportunityList1[0].Id}, 1);
        listQuote1[0].SBQQ__PriceBook__c = listPricebook1 [0].Id;
        listQuote1[0].SBQQ__PricebookId__c = listPricebook1 [0].Id;
        insert listQuote1;
        
        List<SBQQ__QuoteLine__c> listQuoteLine1 = TestDataFactory.getQuoteLines (
        new Map<Id, List<Id>> {
            listQuote1[0].Id => new List<Id>{listProduct1[0].Id}
            }
        );
        listQuoteLine1[0].SBQQ__NetPrice__c = 100;
        insert listQuoteLine1;
        
        TriggerControls.disableQuoteTrigger = false;
        TriggerControls.disableQuoteLineTrigger = false;
        SBQQ.TriggerControl.enable();
        

        Test.startTest();
        Set<Id> oppId = new Set<Id>{opportunityList1[0].Id};
        String str = '';
        UpdatePrimaryQuotesBatch batch = new UpdatePrimaryQuotesBatch(str);
        Database.executeBatch(batch,10);
        Test.stopTest();

        List<Sbqq__quote__c> updatedQuotes = [SELECT Id, SBQQ__Opportunity2__c , SBQQ__Primary__c FROM Sbqq__quote__c];
        System.assertEquals(true,updatedQuotes.size()>0);

    }
    
     @IsTest
    static void testUpdatePrimaryQuotesOppNonZeroBatch() {
          
        List<Opportunity> opportunityList1 = [SELECT Id, Name FROM Opportunity];
        List<Pricebook2> listPricebook1 = [SELECT Id, Name FROM Pricebook2];
        List<Product2> listProduct1 = [SELECT Id, Name FROM Product2];
        List<PriceBookEntry> listPricebookentry1 = [SELECT Id, Name FROM PriceBookEntry];
        
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        SBQQ.TriggerControl.disable();
        
        List<SBQQ__Quote__c> listQuote = TestDataFactory.getQuotes(new Set<Id>{opportunityList1[0].Id}, 1);
        listQuote[0].SBQQ__PriceBook__c = listPricebook1[0].Id;
        listQuote[0].SBQQ__PricebookId__c = listPricebook1[0].Id;
        listQuote[0].SBQQ__Primary__c = true;
        insert listQuote;
        
        List<SBQQ__QuoteLine__c> listQuoteLine = TestDataFactory.getQuoteLines (
        new Map<Id, List<Id>> {
            listQuote[0].Id => new List<Id>{listProduct1[0].Id}
            }
        );
        listQuoteLine[0].SBQQ__NetPrice__c = 100;
        insert listQuoteLine;
        
        
         List<SBQQ__Quote__c> listQuote1 = TestDataFactory.getQuotes(new Set<Id>{opportunityList1[0].Id}, 1);
        listQuote1[0].SBQQ__PriceBook__c = listPricebook1 [0].Id;
        listQuote1[0].SBQQ__PricebookId__c = listPricebook1 [0].Id;
        listQuote1[0].SBQQ__Primary__c = true;
        insert listQuote1;
        
        List<SBQQ__QuoteLine__c> listQuoteLine1 = TestDataFactory.getQuoteLines (
        new Map<Id, List<Id>> {
            listQuote1[0].Id => new List<Id>{listProduct1[0].Id}
            }
        );
        listQuoteLine1[0].SBQQ__NetPrice__c = 100;
        insert listQuoteLine1;
        
        TriggerControls.disableQuoteTrigger = false;
        TriggerControls.disableQuoteLineTrigger = false;
        SBQQ.TriggerControl.enable();
        

        Test.startTest();
        UpdatePrimaryQuotesBatch batch = new UpdatePrimaryQuotesBatch();
        Database.executeBatch(batch,10);
        Test.stopTest();

        List<Sbqq__quote__c> updatedQuotes = [SELECT Id, SBQQ__Opportunity2__c , SBQQ__Primary__c FROM Sbqq__quote__c];
        System.assertEquals(true,updatedQuotes.size()>0);

    }
}