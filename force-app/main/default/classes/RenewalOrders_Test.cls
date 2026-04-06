@isTest
public with sharing class RenewalOrders_Test {
    @isTest
    public static void test(){
        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Name = 'System Administrator', Disable_Opportunity_Validation_Rules__c = TRUE, Disable_Order_Old_Trigger__c = true, Disable_Account_Triggers__c = true);
    	insert disableLogic;
        FlowControll.opportunityTriggerHandler = false;
        //Generate the Account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.name='XYZ, Inc.';
        insert act;

        
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => act.Id
        };
        Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt;

        Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'Standalone',
            'ProductCode' => 'Standalone-Product',
            'IsActive' => true
        };

        Map<String, Object> prdMap1 = new Map<String, Object> {
            'Name' => 'Subscription', 
            'ProductCode' => 'Subscription-Product',
            'IsActive' => true, 
            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
            'SBQQ__SubscriptionTerm__c' => 12, 
            'SBQQ__SubscriptionType__c' => 'Renewable',
            'SBQQ__SubscriptionBase__c' => 'Base',
            'SBQQSC__EntitlementConversion__c' => 'One per unit',
            'SBQQ__AssetAmendmentBehavior__c' => 'Default'
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
        pbeHWstd.UnitPrice = 500;
        pbeHWstd.Pricebook2id = pricebookId;
        pBList.add(pbeHWstd);

        PricebookEntry pbeSubsstd = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubsstd.Product2Id = prdSubs.Id;
        pbeSubsstd.UnitPrice = 700;
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

        //Generate the Opportunity
        Opportunity opp = TestDataFactory.getOpportunity(act, cnt);
        opp.Pricebook2id = system.label.CPQPricebookID;
        opp.RecordTypeId = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
        insert opp;

       
        
        SBQQ__Quote__c qt = TestDataFactory.getQuotes(new Set<Id>{opp.Id}, 1)[0];
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__SubscriptionTerm__c = 36;
        /*qt.SBQQ__PriceBook__c = customPB.id;
        qt.SBQQ__PricebookId__c = customPB.id;*/
        
        insert qt; 

        
        FlowControll.opportunityTriggerHandler = true;
        
        //the JSON formatted String representing the quote model to add a product to
        String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', qt.id);
        String currencyCode = 'USD';

        List<Asset> assets = new list<Asset> {
                        new Asset(Name = 'SN1', SerialNumber = 'SN1', Serial_Number__c = 'SN1', Product2Id = prdHW.Id, Accountid = act.Id),
                        new Asset(Name = 'SN2', SerialNumber = 'SN2', Serial_Number__c = 'SN2', Product2Id = prdHW.Id, Accountid = act.Id)
        };

        insert assets;

        //the JSON formatted String representing the product to be added to the quote
        String productModel = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdSubs.id, '{"pricebookId" : "' + system.label.CPQPricebookID + '", "currencyCode" : "' + currencyCode + '"}');
        //String productModel2 = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdHW.id, '{"pricebookId" : "' + system.label.CPQPricebookID + '", "currencyCode" : "' + currencyCode + '"}');
    
        List<ProductModel> productModels = new List<ProductModel>();
        productModels.add((ProductModel) JSON.deserialize(productModel, ProductModel.class));
        //productModels.add((ProductModel) JSON.deserialize(productModel2, ProductModel.class));
        ProductAdder adder = new ProductAdder();
        QuoteModel quoteWithProducts = adder.add((QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class), productModels, 0);
        quoteWithProducts.lineItems[0].record.SBQQ__Quantity__c = 2;
        //quoteWithProducts.lineItems[1].record.SBQQ__Quantity__c = 2;

        quoteWithProducts.lineItems[0].record.SBQQ__SubscribedAssetIds__c = assets[0].Id + ',' + assets[1].Id;
    
        //the JSON formatted String representing the quote with the product added to it
        //String updatedQuoteModel = SBQQ.ServiceRouter.load('SBQQ.QuoteAPI.QuoteProductAdder', null, '{"quote" : ' + quoteModel + ', "products" : [' + productModel + '], "ignoreCalculate" : true}');
    
        //the JSON formatted String represeting the saved quote
        String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
        

        QuoteCalculator calculator = new QuoteCalculator();
        calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
    
        qt.ApprovalStatus__c = 'Approved';
        update qt;

        Opportunity oppObj = [Select SBQQ__PrimaryQuote__r.SBQQ__NetAmount__c, amount from Opportunity where ID = :opp.Id];

        FlowControll.opportunityTriggerHandler = false;
        Test.startTest();
        update new Opportunity(Id=opp.Id, StageName='6 PO With Channel', SBQQ__Ordered__c = true, 
         Lost_To_Won_Against__c='Actifio', Installation_Assigned_To__c ='Partner Install',
         amount = oppObj.SBQQ__PrimaryQuote__r.SBQQ__NetAmount__c,
         Partner_Level_Of_Involvement__c ='1.Rubrik initiated, Partner was fulfillment only', Opportunity_Sub_Type__c = 'Regular', Primary_Competitor__c = 'Actifio');

         Order ord = [Select Id from Order];
         update new Order(Id=ord.Id, Order_Sub_Type__c = 'Renewal', Status = 'Activated', Order_Status__c = 'Shipped');
         List<OrderItem> ordI = [Select Id,UnitPrice, PriceBookEntry.Pricebook2id from OrderItem];
         for(OrderItem oi: ordI){
            oi.SBQQ__Activated__c = true;
            oi.SBQQ__Contracted__c = true;
         }

         update ordI;
        
         List<ServiceContract> contract = [Select Id from ServiceContract];
         System.assertEquals(1, contract.size());

        List<Entitlement> ent = [Select Id from Entitlement where Type = 'Phone Support'];
        System.assertEquals(4, ent.size());

         System.debug(Limits.getQueries());
         Test.stopTest();
         System.debug(Limits.getQueries());
    }
}