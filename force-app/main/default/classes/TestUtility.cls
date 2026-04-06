public with sharing class TestUtility {
    public Account createAccount() {
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.name='TestAccount01';
        insert act; 
        return act;
    }

    public Contact createContact(Id accountId) {
        Contact ct = new Contact(AccountId = accountId, Email='test.user@rurbrik.com', 
            FirstName='test', LastName='TestContact01', Phone = '8971371780');
        insert ct;
        return ct;
    }

    public Opportunity createOpportunity(Id accountId, Id contactId) {
        Opportunity op = new Opportunity(AccountId=accountId, CloseDate=Date.today(), 
        Deal_Registration_Type__c='Rubrik Initiated Deal', LeadSource='Channel Marketing', 
        Polaris_Portal_Contact__c =contactId, Initial_Contacts_Name__c=contactId, Name='TestContact01', 
        StageName='1 Discovery', Opportunity_Sub_Type__c = 'Regular', Opportunity_Type__c = 'New Customer',
        Installation_Assigned_To__c = 'FE Install', Partner_Level_Of_Involvement__c = '1.Rubrik initiated, Partner was fulfillment only',
        Lost_To_Won_Against__c = 'Actifio');
        insert op;
        return op;
    }

    public SBQQ__Quote__c createQuote(Id accountId, Id opportunityId, Id contactId, String accountName){
        Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'Standalone',
            'ProductCode' => 'Standalone-PROD',
            'IsActive' => true,
            'SBQQ__AssetConversion__c' => 'One per unit'
        };

        Map<String, Object> prdMap1 = new Map<String, Object> {
            'Name' => 'Subscription', 
            'ProductCode' => 'Subscription-PROD',
            'IsActive' => true, 
            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
            'SBQQ__SubscriptionTerm__c' => 12, 
            'SBQQ__SubscriptionType__c' => 'Renewable',
            'Product_Type__c' => '3rd Party Hardware'
        };
        Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
        prdList.add(prdHW);
        prdList.add(prdSubs);
        insert prdList;
        
        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        // Create a custom price book
        Pricebook2 customPB = new Pricebook2(Name='CPQ PriceBook', isActive=true);
        insert customPB;
        
       Id pricebookId = Test.getStandardPricebookId();
        
        
        PricebookEntry pbeHWstd = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHWstd.Product2Id = prdHW.Id;
        pbeHWstd.UnitPrice = 1500;
        pbeHWstd.Pricebook2id = pricebookId;
        pBList.add(pbeHWstd);

        PricebookEntry pbeSubsstd = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubsstd.Product2Id = prdSubs.Id;
        pbeSubsstd.UnitPrice = 1500;
        //pbeSubs.UseStandardPrice = true;
        pbeSubsstd.Pricebook2id = pricebookId;
        pBList.add(pbeSubsstd);
        
        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        pbeHw.UnitPrice = 1000;
        pbeHW.Pricebook2id = system.label.CPQPricebookID;
        pBList.add(pbeHW);

        PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubs.Product2Id = prdSubs.Id;
        pbeSubs.UnitPrice = 1500;
        //pbeSubs.UseStandardPrice = true;
        pbeSubs.Pricebook2id = system.label.CPQPricebookID;
        
        pBList.add(pbeSubs);
        insert pBList;
        
        System.debug('test class check netprice of line '+pBList[0].UseStandardPrice);
        System.debug('test class check netprice of line '+pbeSubs.Pricebook2id);

        Opportunity opp = new Opportunity(Id = opportunityId);
        opp.Pricebook2id = system.label.CPQPricebookID;
        update opp;

       
        
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = accountId;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__SubscriptionTerm__c = 36;
        /*qt.SBQQ__PriceBook__c = customPB.id;
        qt.SBQQ__PricebookId__c = customPB.id;*/
        
        insert qt; 

        
        
        
        //the JSON formatted String representing the quote model to add a product to
        String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', qt.id);
        String currencyCode = 'USD';
        System.debug('test class check line '+prdHW.id);
        System.debug('test class check line '+pbeHW.id);
        //the JSON formatted String representing the product to be added to the quote
        String productModel = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdSubs.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
        String productModel2 = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdHW.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
    
        List<ProductModel> productModels = new List<ProductModel>();
        productModels.add((ProductModel) JSON.deserialize(productModel, ProductModel.class));
        productModels.add((ProductModel) JSON.deserialize(productModel2, ProductModel.class));
        ProductAdder adder = new ProductAdder();
        QuoteModel quoteWithProducts = adder.add((QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class), productModels, 0);
        quoteWithProducts.lineItems[0].record.SBQQ__Quantity__c = 10;
        quoteWithProducts.lineItems[1].record.SBQQ__Quantity__c = 20;
    
        //the JSON formatted String representing the quote with the product added to it
        //String updatedQuoteModel = SBQQ.ServiceRouter.load('SBQQ.QuoteAPI.QuoteProductAdder', null, '{"quote" : ' + quoteModel + ', "products" : [' + productModel + '], "ignoreCalculate" : true}');
    
        //the JSON formatted String represeting the saved quote
        String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
        

        QuoteCalculator calculator = new QuoteCalculator();
        calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
    
        qt.ApprovalStatus__c = 'Approved';
        update qt;

        return qt;
    }
}