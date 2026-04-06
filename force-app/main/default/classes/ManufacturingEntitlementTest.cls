@isTest
public with sharing class ManufacturingEntitlementTest {
    
    @IsTest
    static void testManufacturingEntitlement(){
        ShGl_TestFactoryHelper.insertTriggerControls();
        FlowControll.opportunityTriggerHandler = false;
        //Generate the Account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.name='Promark Technology, Inc.';
        insert act;

        
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => act.Id
        };
        Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt;

        Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'Standalone',
            'ProductCode' => 'Standalone-Prod',
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
            'Product_Type__c' => '3rd Party Hardware',
            'Family' => 'HPE'
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

        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => act.Id,
            'RecordTypeId' => Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId()
        };
        Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        System.debug('test pb '+opp.Pricebook2id);
        opp.Pricebook2id = system.label.CPQPricebookID;
        insert opp;

       
        
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__SubscriptionTerm__c = 36;
        
        insert qt; 
        FlowControll.opportunityTriggerHandler = true;
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

        Test.startTest();
        update new Opportunity(Id=opp.Id, StageName='6 PO With Channel', SBQQ__Ordered__c = true, 
         Lost_To_Won_Against__c='Actifio', Installation_Assigned_To__c ='Partner Install',
         Partner_Level_Of_Involvement__c ='1.Rubrik initiated, Partner was fulfillment only', Opportunity_Type__c = 'New Customer', Opportunity_Sub_Type__c = 'Regular', Primary_Competitor__c = 'Actifio');

         Order ord = [Select Id from Order];
        System.assertNotEquals(null, ord);

        ord.Billto_EndUser_Screen_Status__c = 'Approved';
        ord.ShipToContactScreenStatus__c = 'Approved';
        ord.Shipto_EndUser_Screen_Status__c = 'Approved';
        ord.ShipToScreenStatus__c = 'Approved';
        ord.NetSuite_Order__c = '12345';
        update ord;

        Order ord1 = [Select Id, Order_Status__c from Order];
        System.assertEquals('Order Accepted', ord1.Order_Status__c);
        for(OrderItem ol: [Select Id, PricebookEntry.Product2.Product_Type__c, PricebookEntry.Product2.Family from OrderItem ]){
            System.debug(ol.PricebookEntry.Product2.Product_Type__c);
            System.debug(ol.PricebookEntry.Product2.Family);
        }
        
        Entitlement e = [Select Id from Entitlement where Type = 'Manufacturing Entitlement'];
        System.assertNotEquals(null, e);

        List<OrderItem> olines = [Select Id from OrderItem];
        for(OrderItem oi : olines){
            oi.Support_Start_Date__c = Date.today();
            oi.Support_End_Date__c = Date.today().addYears(1);
        }

        update olines;

        ord.Order_Status__c = 'Shipped';
        update ord;

        String sch = '0 0 23 * * ?';
        system.schedule('Test check', sch, new ManufacturingEntitlementsDateUpdate());

        Test.stopTest();
        
    }
}