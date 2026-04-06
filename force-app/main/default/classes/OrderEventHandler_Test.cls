@isTest(SeeAllData=false)
public with sharing class OrderEventHandler_Test {  

    @TestSetup
    static void makeData(){
				
        ShGl_DisableBusinessLogic__c cdf1 = new ShGl_DisableBusinessLogic__c(
                                                                            Disable_Opportunity_Validation_Rules__c = True);
		insert cdf1;
        
        ShGl_TestFactoryHelper.insertTriggerControls();
        FlowControll.opportunityTriggerHandler = false;
        //Generate the Account
        //
        Id RecordTypeIdval =  Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.name='Promark Technology, Inc.';
        act.RecordTypeId = RecordTypeIdval;
        
        Account acctUnassigned = new Account(
            Name = 'Unassigned',
            Phone = '123-456-7890',
            AccountNumber = 'Test',
            BillingStreet = '123 street',
            BillingCity = 'Santa Clara',
            BillingState = 'California',
            BillingPostalCode = '95050',
            BillingCountry = 'United States'
         
        );
        insert new list<account>{acctUnassigned,act};

        //Create custom setting record for promark EDI Process
        SkipManualOrder__c cusset = new SkipManualOrder__c();
        cusset.Account_Id__c =act.id;
        cusset.Enabled__c = true;
        cusset.name='Promark Technology, Inc.';
        insert cusset;

        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => act.Id
        };
        Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt;

        Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'Standalone',
            'IsActive' => true,
            'SBQQ__AssetConversion__c' => 'One per unit'
        };

        Map<String, Object> prdMap1 = new Map<String, Object> {
            'Name' => 'Subscription',
            'IsActive' => true,
            'SBQQ__SubscriptionPricing__c' => 'Fixed Price',
            'SBQQ__SubscriptionTerm__c' => 12,
            'SBQQ__SubscriptionType__c' => 'Renewable'
        };
        Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        prdHW.Gorefresh_Mark_SW_End_Date__c = true;
        Product2 prdHW1 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);

        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
        prdList.add(prdHW);
        prdList.add(prdHW1);
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

        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => act.Id

        };
        Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
         opp.Distributor_Lookup__c =act.id;
        opp.Partner_Lookup__c=act.id;
        opp.StageName = '1 Discovery';
        System.debug('test pb '+opp.Pricebook2id);
        opp.Pricebook2id = system.label.CPQPricebookID;
        insert opp;

        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
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

        /*List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1 );
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2);
        qliList.add( qli1 );

         qliList.add( qli2 );
        insert qliList;*/

        SBQQ__Quote__c qtq =[select id,name,SBQQ__NetAmount__c,SBQQ__PricebookId__c from SBQQ__Quote__c where id=:qt.id ];

        System.debug('test class check netprice of line '+qt.id);
        List<SBQQ__QuoteLine__c> qliList =[select id,SBQQ__NetPrice__c,SBQQ__NetTotal__c,SBQQ__Product__r.productcode,SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c, SBQQ__Product__c   from SBQQ__QuoteLine__c where  SBQQ__Quote__c =:qt.id];
        List<Asset> assets = new list<Asset> {
            new Asset(Name = 'SN1', PurchaseDate = System.today(), Support_Start_Date__c = System.today(), SerialNumber = 'SN1', Serial_Number__c = 'SN1', Product2Id = prdHW.Id, Accountid = act.Id),
            new Asset(Name = 'SN2', PurchaseDate = System.today(), Support_Start_Date__c = System.today(), SerialNumber = 'SN2', Serial_Number__c = 'SN2', Product2Id = prdHW.Id, Accountid = acctUnassigned.Id)
            };
        insert assets;
        list<Entitlement> entitlements = new list<Entitlement> {
          new Entitlement(Name = 'ENT-1', Type = 'Phone Support', AccountId = act.Id, StartDate = Date.valueof(System.now().addDays(-2)), EndDate = Date.valueof(System.now().addYears(2)), AssetId = assets[0].Id, Product__c = prdHW.Id),
          new Entitlement(Name = 'ENT-2', Type = 'Phone Support', AccountId = act.Id, StartDate = Date.valueof(System.now().addDays(-2)), EndDate = Date.valueof(System.now().addYears(2)), AssetId = assets[0].Id, Product__c = prdHW1.Id),
          new Entitlement(Name = 'ENT-2', Type = 'Phone Support', AccountId = act.Id, StartDate = Date.valueof(System.now().addDays(-2)), EndDate = Date.valueof(System.now()), AssetId = assets[0].Id, Product__c = prdHW1.Id)
         } ;
         insert entitlements ;
        Test.startTest();
        opp.StageName = '5 Negotiate & Close';
        opp.SBQQ__Ordered__c = true;
        opp.Is_Order_Split__c = true;
        opp.Lost_To_Won_Against__c = 'Actifio';
        opp.Opportunity_Sub_Type__c='Regular';
        opp.Partner_Level_Of_Involvement__c='1.Rubrik initiated, Partner was fulfillment only';
        opp.Installation_Assigned_To__c='FE Install';
        opp.Opportunity_Type__c = 'New Customer';
        opp.Opportunity_Sub_Type__c = 'Regular';
        opp.Primary_Competitor__c = 'Actifio';
        opp.Cloud_Partner_Impact__c='Partner gets a well-qualified meeting with key decision-makers';
        opp.Cloud_Partner_Led_Activity__c='Yes';
        opp.Cloud_Type__c='Amazon EC2';
        opp.Initial_Contacts_Name__c=cnt.id;
        opp.Accept_Conditions__c = true;
        opp.SOW_Attached_to_Opportunity__c = TRUE;
        opp.SOW_Required__c = TRUE;
        update opp;
        Test.stopTest();
    }
    public static testMethod void testOrderShipment() {
       Test.startTest();
        Order ord = [Select Id,opportunityId,(select id,Product2.name from orderItems where Product2.name='Standalone') from Order LIMIT 1];
        Asset oldasst = [select id,serial_number__c from asset where name ='SN1' limit 1];
        List<Entitlement> entList = [select id from Entitlement];
        List<OrderItem> OIList = new List<orderItem>();
        OIList = ord.orderItems ;
        oldasst.Order_Service_Item__c = ord.orderItems[0].id;
        update oldasst;
        entList[0].Order_Service_Item__c =entList[1].Order_Service_Item__c=entList[2].Order_Service_Item__c= OIList[0].id;
        update entList;
        for(orderItem OI : OIList){
          OI.Upgraded_From__c = oldasst.serial_number__c;
          OI.SerialNumber__c = 'SN2';
        }
        update OIList;
        PSProjectHelperClass.createtaskrecurssion = false;
        ord.Actual_Order_Ship_Date__c = system.today().adddays(5);
        ord.Order_Status__c = 'Shipped';
        update ord;
        Test.stopTest();
    }
}