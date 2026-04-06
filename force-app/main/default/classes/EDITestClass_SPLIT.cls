/**************************************************************************************************
 * @description       : Stage PO Trigger logic
 * @author            : Chaitra
 * @last modified on  : 03-12-2025
 * @last modified by  : Siva Kumar
 * Covers following Apex Classes
 * SplitOrderSchedular
 * SplitOrder
 * POStageHandler
 * POItemStageHelperClass
 * POItemStageHandler
 ******************************************************************************/
@isTest 
public class EDITestClass_SPLIT {
    
    @testSetup 
    static void insertData() {
        String uniqueUserName = 'TestUser' + DateTime.now().getTime() + '@rbk.com';
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        
        User usr1 = new user( 
            alias = 'std',
            email = 'testuser@testclass.com',
            emailencodingkey = 'UTF-8',
            firstname = 'test',
            lastname = 'user',
            languagelocalekey = 'en_US',
            localesidkey = 'en_US',
            profileid = p.Id,
            timezonesidkey = 'America/Los_Angeles',
            username = uniqueUserName
        );
        insert usr1;
    }

    /**
    * @author Siva Kumar
    * @date 12-03-2025
    * @description test method to cover PO Stage trigger logic 
    */
    public static testMethod void testAmendmentOrder(){
        System.runAs(new User(Id=UserInfo.getUSerId()))  {
       SBQQ.TriggerControl.disable();
       ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_QuoteLine_Validation_Rules__c =  true, Disable_SBQQ_Quote_Validation_Rules__c = true,Disable_Opportunity_Validation_Rules__c = true,Disable_Opportunity_Triggers__c =true,Disable_SBQQ_Quote_Triggers__c = true,Disable_Order_Old_Trigger__c = true, Disable_Account_Triggers__c = true);
       insert disableLogic;
       
       Id partner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            Account customer = new Account(Name = 'Customer',recordtypeId = partner,Phone = '123-456-7890',AccountNumber = 'Test',BillingStreet = '123 street',BillingCity = 'Santa Clara',BillingState = 'California',BillingPostalCode = '95050',BillingCountry = 'United States',ShippingStreet = '123 street',ShippingCity = 'Santa Clara',ShippingState = 'California',ShippingPostalCode = '95050',ShippingCountry = 'United States');
            insert customer;
            Assert.areEqual('Customer', customer.Name);

         Opportunity opp = new Opportunity(
            AccountId = customer.Id,
            Name = 'Test',
              Opportunity_Sub_Type__c = 'GC Offer',
            CloseDate = System.today().addMonths(12),
            StageName = 'Test',
            Pricebook2Id = Test.getStandardPricebookId(),
            Distributor_Lookup__c = customer.Id,
            Partner_Lookup__c = customer.id,
            Alliance_Partner_Name__c='Amazon',
            Alliance_Source_Type__c='Alliance Initiated Deal');
        insert opp;
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__StartDate__c = System.today(),
            SBQQ__SubscriptionTerm__c = 12,
            SBQQ__Primary__c = true,
            SBQQ__Type__c = 'Amendment',
            OpportunitySubType__c = 'GC Offer',
            Is_RWD_Polaris_Quote__c = true,
            SBQQ__PriceBook__c = Test.getStandardPricebookId());
        insert quote;
        
        List<Product2> sampleProducts = new List<Product2>{
                // 0
                 new Product2(Name='RS-TB-FUE-RSV-PE',ProductCode ='RS-TB-FUE-RSV-PE',
                                 Support_Type__c='Premium',License_Type__c='Consumption',
                                 Product_Type__c='Edition Upgrade',Product_Subtype__c='Scale MSP',
                                 License_Category__c = 'SaaS',
                                 SBQQ__SubscriptionPricing__c='Fixed Price',SBQQ__SubscriptionType__c='Renewable',
                                 SBQQSC__EntitlementConversion__c='One per quote line',SBQQ__AssetAmendmentBehavior__c='Default'),
                     
                     
                       new Product2(Name='RS-TB-EE-RSV-PE',ProductCode ='RS-TB-EE-RSV-PE',
                                                                      Support_Type__c='Premium',License_Category__c = 'SaaS',Product_Level__c='Hybrid Software',License_Type__c='Consumption',
                                                                      Product_Type__c='Enterprise Edition',Product_Subtype__c='Scale MSP',
                                                                      Product_Payment_Option__c='Monthly',Approval_Category__c='Scale Utility RSV',
                                                                      SBQQ__SubscriptionPricing__c='Fixed Price',SBQQ__SubscriptionType__c='Renewable',
                                 SBQQSC__EntitlementConversion__c='One per quote line',SBQQ__AssetAmendmentBehavior__c='Default')
                 
                   
       		
        };
        insert sampleProducts;
		
         Id pricebookId = Test.getStandardPricebookId();
        List<PricebookEntry>entries = new List<PricebookEntry>();

        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = pricebookId, Product2Id = sampleProducts[0].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = pricebookId, Product2Id = sampleProducts[1].Id, IsActive = true, UnitPrice = 100));
        
        insert entries; 
        Pricebook2 customPB = new Pricebook2(Name='CPQ PriceBook', isActive=true);
        insert customPB;

        List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
        //Date stDate = Date.newInstance(Date.Today().Year(), Date.Today().Month(), 20);
        //Date endDate = stDate.addMonths(1).addDays(-1);
        Date stDate = System.Today();
        Date endDate = System.Today().addYears(1);
        
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id,  SBQQ__Product__c = sampleProducts[0].Id, SBQQ__PricebookEntryId__c = entries[0].Id, SBQQ__Quantity__c = 800,  SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__StartDate__c = stDate, SBQQ__EndDate__c = endDate, SBQQ__DefaultSubscriptionTerm__c = 1, SBQQ__ListPrice__c = 10, SBQQ__NetPrice__c = 10,SBQQ__SubscriptionTerm__c = 10));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id,  SBQQ__Product__c = sampleProducts[1].Id, SBQQ__PricebookEntryId__c = entries[1].Id, SBQQ__Quantity__c = 800,  SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__StartDate__c = stDate, SBQQ__EndDate__c = endDate, SBQQ__DefaultSubscriptionTerm__c = 1, SBQQ__ListPrice__c = 10, SBQQ__NetPrice__c = 10,Product_Subtype__c = 'Scale MSP',License_Category__c = 'SaaS',SBQQ__SubscriptionTerm__c = 10));
        
        
        insert lines;

        
        quote.ApprovalStatus__c = 'Approved';
        update quote;
        
        opp.StageName ='6 PO With Channel';
        opp.SBQQ__PrimaryQuote__c = quote.id;
        opp.Pricebook2Id = Test.getStandardPricebookId();
        opp.Polaris_Region__c = 'US';
        //opp.SBQQ__Ordered__c = true;
        //update opp;
        
        opp.SBQQ__Ordered__c = true;
          SBQQ__Quote__c qtq =[select id,name,SBQQ__NetAmount__c,SBQQ__PricebookId__c,(select id,SBQQ__NetPrice__c,SBQQ__NetTotal__c,SBQQ__Product__r.productcode,SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c, SBQQ__Product__c,SBQQ__PricebookEntryId__c from SBQQ__LineItems__r) from SBQQ__Quote__c where id=:quote.id ];
        
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c>(qtq.SBQQ__LineItems__r);
        Map<String, Object>  OrderMap = new Map<String, Object> {
            'Type' => 'Revenue',
            'AccountId' => customer.Id,
            'OpportunityId' => opp.Id,
            'Sync_to_NetSuite__c' => true,
            //'EffectiveDate' => system.today(),
            'EffectiveDate' => system.today(),
            'Status' => 'Pending',
            'Sell_to_Partner__c'=>customer.Id,
            'Bill_To_Name__c'=>customer.Id,
            'SBQQ__Quote__c'=>quote.id  
            };
            
        Order ord = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
    	ord.Type = 'Revenue';
       ord.Order_Status__c = 'Pending';
       ord.Order_Split_Type__c = 'GC Offer Amendment';
        ord.Order_Sub_Type__c = 'GC Offer';
        test.startTest();
        insert Ord;

        List<OrderItem> lstOrdrItems = new List<OrderItem>(); 
      
        for(integer i=0;i<qliList.size();i++){
            lstOrdrItems.add(new OrderItem( Product2Id = qliList[i].SBQQ__Product__c,SBQQ__QuotedQuantity__c = qliList[i].SBQQ__Quantity__c, OrderId = Ord.Id, Quantity = qliList[i].SBQQ__Quantity__c, PricebookEntryId = qliList[i].SBQQ__PricebookEntryId__c, unitprice =qliList[i].SBQQ__NetPrice__c,Sales_Price__c = qliList[i].SBQQ__NetPrice__c,SBQQ__QuoteLine__c=qliList[i].id, SBQQ__SubscriptionTerm__c =qliList[i].SBQQ__SubscriptionTerm__c));
        }
        insert lstOrdrItems;
        
        Integer count = 0;
       
       SplitOrder scbat = new SplitOrder();
       string jobID =Database.executeBatch(scbat);
       Test.stopTest();
        }
    }	
	/**
    * @author Siva Kumar
    * @date 12-03-2025
    * @description test method to cover PO Stage trigger logic 
    */
    static testMethod void testMethod1() {
        FlowControll.AccountTrigger = false;
        FlowControll.opportunityTriggerHandler = false;
        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_QuoteLine_Validation_Rules__c =  true, Disable_Product2_Validation_Rules__c = true, Disable_SBQQ_Quote_Triggers__c = true,Disable_SBQQ_Quote_Validation_Rules__c = true);
        insert disableLogic;
        ShGl_TestFactoryHelper.insertTriggerControls();
        System.runAs(new User(Id=UserInfo.getUserId())) {
        //Generate the Account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.name='Promark Technology, Inc.';
        act.Type ='Distributor';
        act.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        act.Contract_Status__c = 'Pending';
        insert act;
            Assert.areEqual('Promark Technology, Inc.', act.Name);

            act.Id = getPromarkAccount().Sfdc_Id__c;
        update act;
        
        //Create custom setting record for promark EDI Process.
        SkipManualOrder__c cusset = new SkipManualOrder__c();
        cusset.Account_Id__c =act.id;
        cusset.Enabled__c = true;
        cusset.name='Promark Technology, Inc.';
        insert cusset;
        
        createCustomSetPOValidationError();
        
        
        
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => act.Id
                };
                    Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt;
        
        Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'Standalone',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit',
                    'ProductCode' => 'RBK-REF-HW-CREDIT'
                };
                    
                    Map<String, Object> prdMap1 = new Map<String, Object> {
                        'Name' => 'Subscription', 
                            'IsActive' => true, 
                            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                            'SBQQ__SubscriptionTerm__c' => 12, 
                            'SBQQ__SubscriptionType__c' => 'Renewable',
                            'ProductCode' => 'test xyz'
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
                'RecordTypeId' => Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId()
                };
                    Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        opp.Distributor_Lookup__c =act.id;
        opp.Pricebook2id = system.label.CPQPricebookID;
        insert opp;
        
        
        
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__SubscriptionTerm__c = 36;
        qt.SBQQ__PaymentTerms__c = 'Net 45';
        
        insert qt; 
        
        
        FlowControll.AccountTrigger = true;
        FlowControll.opportunityTriggerHandler = true;
        
        
        //the JSON formatted String representing the quote model to add a product to
        String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', qt.id);
        String currencyCode = 'USD';
        //the JSON formatted String representing the product to be added to the quote
        String productModel = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdSubs.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
        String productModel2 = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdHW.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
            
            Asset assestIns = new Asset();
            assestIns.Name = '09092019APMSP1250';
            assestIns.SerialNumber = '09092019APMSP1250';
            assestIns.serial_number__c= '09092019APMSP1250';
            assestIns.AccountId = act.Id;
            assestIns.Product2Id = prdList[0].Id;
            insert assestIns;
        
        List<ProductModel> productModels = new List<ProductModel>();
        productModels.add((ProductModel) JSON.deserialize(productModel, ProductModel.class));
            productModels.add((ProductModel) JSON.deserialize(productModel2, ProductModel.class));
        productModels.add((ProductModel) JSON.deserialize(productModel2, ProductModel.class));
        ProductAdder adder = new ProductAdder();
        QuoteModel quoteWithProducts = adder.add((QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class), productModels, 0);
        quoteWithProducts.lineItems[0].record.SBQQ__Quantity__c = 10;
        quoteWithProducts.lineItems[1].record.SBQQ__Quantity__c = 20;
            quoteWithProducts.lineItems[2].record.SBQQ__Quantity__c = 30;
        
        //the JSON formatted String representing the quote with the product added to it
        //String updatedQuoteModel = SBQQ.ServiceRouter.load('SBQQ.QuoteAPI.QuoteProductAdder', null, '{"quote" : ' + quoteModel + ', "products" : [' + productModel + '], "ignoreCalculate" : true}');
        
        //the JSON formatted String represeting the saved quote
        String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
        
            List<SBQQ__QuoteLine__c> qlinesList =[select Id from SBQQ__QuoteLine__c where  SBQQ__Quote__c =:qt.id];
            qlinesList[1].SBQQ__RequiredBy__c = qlinesList[0].Id;
            qlinesList[1].Special_Program__c = 'Refresh';
            qlinesList[1].SBQQ__UpgradedAsset__c = assestIns.Id;
            qlinesList[2].SBQQ__RequiredBy__c = qlinesList[1].Id;
            qlinesList[2].Special_Program__c = 'Refresh';
            qlinesList[2].SBQQ__UpgradedAsset__c = assestIns.Id;
            update qlinesList;
        QuoteCalculator calculator = new QuoteCalculator();
        calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
        
        qt.ApprovalStatus__c = 'Approved';
        update qt;
        
        
        SBQQ__Quote__c qtq =[select id,name,SBQQ__NetAmount__c,SBQQ__PricebookId__c from SBQQ__Quote__c where id=:qt.id ];
        
        List<SBQQ__QuoteLine__c> qliList =[select id,SBQQ__NetPrice__c,SBQQ__NetTotal__c,SBQQ__Product__r.productcode,SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c, SBQQ__Product__c   from SBQQ__QuoteLine__c where  SBQQ__Quote__c =:qt.id];
        
        update new Product2(Id = qliList[0].SBQQ__Product__c, ProductCode = 'RBK-CONSULT', Name = 'RBK-CONSULT');
        
        Test.startTest();
        
        List<PO_Stage__c> poStageList = new List<PO_Stage__c>();
            PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.','test123',system.today().addDays(10),2,'test@test.com.invalid','test partner',system.today(),1,'test12345',qtq.name,qliList[0].SBQQ__NetTotal__c);
        pos.Bill_To_Name__c=act.Id;
        pos.Payment_schedule_type__c = 'test';
        poStageList.add(pos);
        
            PO_Stage__c pos1 = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.','test1234',system.today().addDays(10),2,'test@test.com.invalid','test partner',system.today(),2,'test12345',qtq.name,qliList[1].SBQQ__NetTotal__c);
        pos1.Bill_To_Name__c=act.Id;
        pos1.Payment_schedule_type__c = 'test';
        poStageList.add(pos1);
        
        insert poStageList;
        
        List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>();
        
        for(integer i=0;i<qliList.size();i++){
            
            string ediLinenum = 0+''+i;
            PO_Item_Stage__c poi;
            if(i==0)
                poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos.id,qliList[i].SBQQ__SubscriptionTerm__c,qliList[i].SBQQ__NetPrice__c);
            else
                poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos1.id,qliList[i].SBQQ__SubscriptionTerm__c,qliList[i].SBQQ__NetPrice__c);
            
            poItem.add(poi);
        }
        //PO_Item_Stage__c poi = ShGl_TestFactoryHelper.createPOItem('1234','01',prdHW.productcode,10,pos.id,null,(qtq.SBQQ__NetAmount__c/10));
        
        insert poItem;
        
        List<PO_Stage_Address__c> poAs = new List<PO_Stage_Address__c>();
            PO_Stage_Address__c spa = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com.invalid',pos.id,'292005','test','test2');
        poAs.add(spa);
            PO_Stage_Address__c spa1 = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com.invalid',pos1.id,'292005','test','test2');
        poAs.add(spa1);
        insert poAs;
        
        
        
        List<PO_Stage__c> upStageList = new  List<PO_Stage__c>();
        pos.PO_Validation_Status__c='Staged';
        
        upStageList.add(pos);
        pos1.PO_Validation_Status__c='Staged';
        
        POStageHelper.allStagePOmap.clear(); 
        POStageHelper.quoteMap.clear(); 
         upStageList.add(pos1);
        update upStageList;
        
        
        poStageList = [select id,PO_Validation_Status__c from PO_Stage__c where id=: pos.id];
        Test.stopTest();
    } 
    } 
    /**
    * @author Siva Kumar
    * @date 12-03-2025
    * @description test method to cover Initiate Internal validation Coverage 
    */
    static testMethod void testMethod2() {

        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_QuoteLine_Validation_Rules__c =  true, Disable_SBQQ_Quote_Triggers__c = true,Disable_SBQQ_Quote_Validation_Rules__c = true);
        insert disableLogic;
        
        FlowControll.AccountTrigger = false;
        FlowControll.opportunityTriggerHandler = false;
        
        ShGl_TestFactoryHelper.insertTriggerControls();
        
        //Generate the Account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.name='Promark Technology, Inc.';
        act.Type ='Distributor';
        act.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        act.Contract_Status__c = 'Pending';
        insert act;

        act.Id = getPromarkAccount().Sfdc_Id__c;
        update act;
        
        //Create custom setting record for promark EDI Process
        SkipManualOrder__c cusset = new SkipManualOrder__c();
        cusset.Account_Id__c =act.id;
        cusset.Enabled__c = true;
        cusset.name='Promark Technology, Inc.';
        insert cusset;
        
        createCustomSetPOValidationError();
        
        
        
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => act.Id
                };
                    Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt;
        
        Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'Standalone',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit',
                'ProductCode' => 'test xyz1'
                };
                    
                    Map<String, Object> prdMap1 = new Map<String, Object> {
                        'Name' => 'Subscription', 
                            'IsActive' => true, 
                            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                            'SBQQ__SubscriptionTerm__c' => 12, 
                            'SBQQ__SubscriptionType__c' => 'Renewable',
                            'ProductCode' => 'test xyz'
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
                'RecordTypeId' => Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId()
                };
                    Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        opp.Distributor_Lookup__c =act.id;
        opp.Pricebook2id = system.label.CPQPricebookID;
        insert opp;
        
        
        
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__SubscriptionTerm__c = 36;
        qt.SBQQ__PaymentTerms__c = 'Net 45';
        
        insert qt; 
        
        FlowControll.AccountTrigger = true;
        FlowControll.opportunityTriggerHandler = true;
        
        
        
        //the JSON formatted String representing the quote model to add a product to
        String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', qt.id);
        String currencyCode = 'USD';
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
        
        //qt.ApprovalStatus__c = 'Approved';
        //update qt;
        
        
        SBQQ__Quote__c qtq =[select id,name,SBQQ__NetAmount__c,SBQQ__PricebookId__c from SBQQ__Quote__c where id=:qt.id ];
        
        List<SBQQ__QuoteLine__c> qliList =[select id,SBQQ__NetPrice__c,SBQQ__NetTotal__c,SBQQ__Product__r.productcode,SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c, SBQQ__Product__c   from SBQQ__QuoteLine__c where  SBQQ__Quote__c =:qt.id];
        
        
        Test.startTest();
        
        List<PO_Stage__c> poStageList = new List<PO_Stage__c>();
        PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.pp','test123',system.today().addDays(10),2,'test@test.com','test partner',system.today(),1,'test12345',qtq.name,qliList[0].SBQQ__NetTotal__c);
        pos.Bill_To_Name__c=act.Id;
        Pos.Consult_Splitted__c = true;
        pos.Payment_schedule_type__c = 'test';
        poStageList.add(pos);
        
        PO_Stage__c pos1 = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.pp','test1234',system.today().addDays(10),2,'test@test.com','test partner',system.today(),2,'test12345',qtq.name,qliList[1].SBQQ__NetTotal__c);
        pos1.Bill_To_Name__c=act.Id;
        poStageList.add(pos1);
        pos.Note_on_Contingency_and_Special_Language__c='test';
        pos.Payment_schedule_type__c='test';
        insert poStageList;
        
        List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>();
        
        for(integer i=0;i<qliList.size();i++){
            
            string ediLinenum = 0+''+i;
            PO_Item_Stage__c poi;
            if(i==0)
                poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos.id,qliList[i].SBQQ__SubscriptionTerm__c,qliList[i].SBQQ__NetPrice__c);
            else
                poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos1.id,qliList[i].SBQQ__SubscriptionTerm__c,qliList[i].SBQQ__NetPrice__c);
            
            poItem.add(poi);
        }
        //PO_Item_Stage__c poi = ShGl_TestFactoryHelper.createPOItem('1234','01',prdHW.productcode,10,pos.id,null,(qtq.SBQQ__NetAmount__c/10));
        
        insert poItem;
        
        List<PO_Stage_Address__c> poAs = new List<PO_Stage_Address__c>();
        PO_Stage_Address__c spa = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com',pos.id,'292005','test','test2');
        poAs.add(spa);
        PO_Stage_Address__c spa1 = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com',pos1.id,'292005','test','test2');
        poAs.add(spa1);
        insert poAs;
        
        
        
        
        List<PO_Stage__c> upStageList = new  List<PO_Stage__c>();
        pos.PO_Validation_Status__c='Staged';
        
        upStageList.add(pos);
        pos1.PO_Validation_Status__c='Staged';
        
        upStageList.add(pos1);
        update upStageList;
                
        poStageList = [select id,PO_Validation_Status__c from PO_Stage__c where id=: pos.id];
        
        Test.stopTest();
    }
    /**
    * @author Siva Kumar
    * @date 12-03-2025
    * @description test method to vover Rubrik Go
    */ 
    static testMethod void testMethod3() {

        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_QuoteLine_Validation_Rules__c =  true, Disable_Product2_Validation_Rules__c = true, Disable_SBQQ_Quote_Triggers__c = true,Disable_SBQQ_Quote_Validation_Rules__c = true);
        insert disableLogic;
        
        FlowControll.AccountTrigger = false;
        FlowControll.opportunityTriggerHandler = false;
        
        ShGl_TestFactoryHelper.insertTriggerControls();
        System.runAs(new User(Id=UserInfo.getUSerId())) {
        //Generate the Account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.name='Promark Technology, Inc.';
        act.Type ='Distributor';
        act.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        act.Contract_Status__c = 'Pending';
        insert act;
            Assert.areEqual('Promark Technology, Inc.', act.Name);
            act.Id = getPromarkAccount().Sfdc_Id__c;
        update act;
        
        //Create custom setting record for promark EDI Process
        SkipManualOrder__c cusset = new SkipManualOrder__c();
        cusset.Account_Id__c =act.id;
        cusset.Enabled__c = true;
        cusset.name='Promark Technology, Inc.';
        insert cusset;
        
        createCustomSetPOValidationError();
        
        
        
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => act.Id
                };
                    Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt;
        
        Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'Standalone',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit',
                'productcode' => 'RBK-CONSULT'
                };
                    
                    Map<String, Object> prdMap1 = new Map<String, Object> {
                        'Name' => 'Subscription', 
                            'IsActive' => true, 
                            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                            'SBQQ__SubscriptionTerm__c' => 12, 
                            'SBQQ__SubscriptionType__c' => 'Renewable',
                            'Product_Payment_Option__c' => 'Annual',
                            'productcode' => 'GO1'
                            };
                                Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
        prdSubs.Product_Payment_Option__c='Annual';
        prdList.add(prdHW);
        prdList.add(prdSubs);
        insert prdList;
        
        prdList[0].ProductCode='RBK-REF-HW-CREDIT';
        update prdList;
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
                'RecordTypeId' => Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId()
                };
                    Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        opp.Distributor_Lookup__c =act.id;
        opp.Pricebook2id = system.label.CPQPricebookID;
        insert opp;
        
        
        Test.startTest();
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__SubscriptionTerm__c = 36;
        qt.SBQQ__PaymentTerms__c = 'Net 45';
        
        insert qt; 
        
        SBQQ__QuoteLineGroup__c qlg=new SBQQ__QuoteLineGroup__c(
        Name='Renewal Quote',
        SBQQ__Quote__c=qt.id);
        
        insert qlg;
        
        Asset assestIns = new Asset();
        assestIns.Name = '09092019APMSP1250';
        assestIns.SerialNumber = '09092019APMSP1250';
        assestIns.serial_number__c= '09092019APMSP1250';
        assestIns.AccountId = act.Id;
        assestIns.Product2Id = prdList[0].Id;
        insert assestIns;
        
        FlowControll.AccountTrigger = true;
        FlowControll.opportunityTriggerHandler = false;
        
        
        //the JSON formatted String representing the quote model to add a product to
        String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', qt.id);
        String currencyCode = 'USD';
        //the JSON formatted String representing the product to be added to the quote
        String productModel = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdSubs.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
        String productModel2 = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdHW.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
        
        List<ProductModel> productModels = new List<ProductModel>();
        productModels.add((ProductModel) JSON.deserialize(productModel, ProductModel.class));
        productModels.add((ProductModel) JSON.deserialize(productModel2, ProductModel.class));
        ProductAdder adder = new ProductAdder();
        QuoteModel quoteWithProducts = adder.add((QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class), productModels, 0);
        quoteWithProducts.lineItems[0].record.SBQQ__Quantity__c = 10;
        quoteWithProducts.lineItems[0].record.SBQQ__SubscriptionTerm__c = 36;
        
        quoteWithProducts.lineItems[1].record.SBQQ__Quantity__c = 20;
        quoteWithProducts.lineItems[1].record.SBQQ__SubscriptionTerm__c = 36;
        
        //the JSON formatted String represeting the saved quote
        String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
        
        
        QuoteCalculator calculator = new QuoteCalculator();
        calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
        
        qt.ApprovalStatus__c = 'Approved';
        update qt;
        
        
        SBQQ__Quote__c qtq =[select id,name,SBQQ__NetAmount__c,SBQQ__PricebookId__c from SBQQ__Quote__c where id=:qt.id ];
        
        List<SBQQ__QuoteLine__c> qliList =[select id,SBQQ__Quote__c,SBQQ__Group__c,SBQQ__Bundle__c,SBQQ__NetPrice__c,SBQQ__NetTotal__c,SBQQ__Product__r.productcode,SBQQ__Quantity__c,SBQQ__Product__r.Product_Payment_Option__c, SBQQ__SubscriptionTerm__c, SBQQ__Product__c   from SBQQ__QuoteLine__c where  SBQQ__Quote__c =:qt.id];
        
        qliList[0].SBQQ__Bundle__c=true;
        qliList[0].SBQQ__Group__c=qlg.id;
        qliList[0].SBQQ__Quantity__c=50;
        qliList[0].Special_Program__c = 'Refresh';
        qliList[0].SBQQ__UpgradedAsset__c=assestIns.id;
        qliList[1].Special_Program__c = 'Refresh';
        qliList[1].SBQQ__UpgradedAsset__c=assestIns.id;
        qliList[0].SBQQ__RequiredBy__c = qliList[1].Id;
        
        update qliList;
        
        
        List<PO_Stage__c> poStageList = new List<PO_Stage__c>();
        PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.pp','test123',system.today().addDays(10),2,'test@test.com','test partner',system.today(),1,'test12345',qtq.name,qliList[0].SBQQ__NetTotal__c);
        pos.Bill_To_Name__c=act.Id;
        pos.Payment_schedule_type__c = 'test';
        pos.Quote__c=qt.id;
        poStageList.add(pos);
        
        PO_Stage__c pos1 = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.pp','test1234',system.today().addDays(10),2,'test@test.com','test partner',system.today(),2,'test12345',qtq.name,qliList[1].SBQQ__NetTotal__c);
        pos1.Bill_To_Name__c=act.Id;
        pos1.Payment_schedule_type__c = 'test';
        poStageList.add(pos1);
        
        PO_Stage__c pos2 = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.pp','test1234',system.today().addDays(10),2,'test@test.com','test partner',system.today(),2,'test12345',qtq.name,qliList[1].SBQQ__NetTotal__c);
        pos2.Bill_To_Name__c=act.Id;
        pos2.Payment_schedule_type__c = 'test';
        poStageList.add(pos2);
        
        insert poStageList;
        
        List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>();
        
        
        for(integer i=0;i<qliList.size();i++){
            
            string ediLinenum = 0+''+i;
            PO_Item_Stage__c poi,poi1,poi2;
            if(qliList[i].SBQQ__Product__r.Product_Payment_Option__c =='Annual'){
                Decimal j= qliList[i].SBQQ__SubscriptionTerm__c != null? (qliList[i].SBQQ__SubscriptionTerm__c/12) : 1;
                for(integer k=0;k<j;k++){
                    poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos.id,12,((qliList[i].SBQQ__NetPrice__c)/36)*12);
					poi1 = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos.id,14,qliList[i].SBQQ__NetPrice__c);
					poi2 = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos.id,11,qliList[i].SBQQ__NetPrice__c);
					poi.quantity__c=50;
                    poItem.add(poi);
                    poi1.ProductCode__c = 'RBK-TRAVEL-EXPENSES';
                    poItem.add(poi1);
                    poi2.UnitPrice__c=1000;
                    poItem.add(poi2);
                    poi = new PO_Item_Stage__c();
                    poi1 = new PO_Item_Stage__c();
                    poi2 = new PO_Item_Stage__c();
                }
            }
            else{
                poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos1.id,qliList[i].SBQQ__SubscriptionTerm__c,qliList[i].SBQQ__NetPrice__c);
                poItem.add(poi);
            }
            
        }
        //PO_Item_Stage__c poi = ShGl_TestFactoryHelper.createPOItem('1234','01',prdHW.productcode,10,pos.id,null,(qtq.SBQQ__NetAmount__c/10));
        
        insert poItem;
        
        List<PO_Stage_Address__c> poAs = new List<PO_Stage_Address__c>();
        PO_Stage_Address__c spa = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com',pos.id,'292005','test','test2');
        poAs.add(spa);
        PO_Stage_Address__c spa1 = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com',pos1.id,'292005','test','test2');
        poAs.add(spa1);
        insert poAs;
        
        
        
        
        List<PO_Stage__c> upStageList = new  List<PO_Stage__c>();
        pos.PO_Validation_Status__c='Staged';
        
        upStageList.add(pos);
        pos1.PO_Validation_Status__c='Staged';
        
       POStageHelper.allStagePOmap.clear(); 
        POStageHelper.quoteMap.clear(); 
         upStageList.add(pos1);
        
        pos2.PO_Validation_Status__c='Failure';
        upStageList.add(pos2);
        update upStageList;
        
        
        poStageList = [select id,PO_Validation_Status__c from PO_Stage__c where id=: pos.id];
        
        Test.stopTest();
    }
    }
	/**
    * @author Siva Kumar
    * @date 12-03-2025
    * @description test method to vover Rubrik Go
    */
    static testMethod void testMethod4() {

        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_QuoteLine_Validation_Rules__c =  true, Disable_SBQQ_Quote_Triggers__c = true,Disable_SBQQ_Quote_Validation_Rules__c = true);
        insert disableLogic;
        
        FlowControll.AccountTrigger = false;
        FlowControll.opportunityTriggerHandler = false;
        
        ShGl_TestFactoryHelper.insertTriggerControls();
        System.runAs(new User(Id=UserInfo.getUSerId())) {
        //Generate the Account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.name='Promark Technology, Inc.';
        act.Type ='Distributor';
        act.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        act.Contract_Status__c = 'Pending';
        insert act;
            Assert.areEqual('Promark Technology, Inc.', act.Name);
            act.Id = getPromarkAccount().Sfdc_Id__c;
        update act;
        
        //Create custom setting record for promark EDI Process
        SkipManualOrder__c cusset = new SkipManualOrder__c();
        cusset.Account_Id__c =act.id;
        cusset.Enabled__c = true;
        cusset.name='Promark Technology, Inc.';
        insert cusset;
        
        createCustomSetPOValidationError();
        
        
        
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => act.Id
                };
                    Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt;
        
        Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'Standalone',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit',
                'ProductCode' => 'test xyz1'
                };
                    
                    Map<String, Object> prdMap1 = new Map<String, Object> {
                        'Name' => 'Subscription', 
                            'IsActive' => true, 
                            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                            'SBQQ__SubscriptionTerm__c' => 12, 
                            'SBQQ__SubscriptionType__c' => 'Renewable',
                            'ProductCode' => 'test xyz'
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
                'RecordTypeId' => Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId()
                };
                    Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        opp.Distributor_Lookup__c =act.id;
      
        opp.Pricebook2id = system.label.CPQPricebookID;
        insert opp;
        
        
        
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__SubscriptionTerm__c = 36;
        qt.SBQQ__PaymentTerms__c = 'Net 45';
        
        insert qt; 
        
        FlowControll.AccountTrigger = true;
        FlowControll.opportunityTriggerHandler = true;
        
        
        
        //the JSON formatted String representing the quote model to add a product to
        String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', qt.id);
        String currencyCode = 'USD';
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
        
        List<SBQQ__QuoteLine__c> qliList =[select id,SBQQ__NetPrice__c,SBQQ__Quote__r.name,SBQQ__NetTotal__c,SBQQ__Product__r.productcode,SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c, SBQQ__Product__c   from SBQQ__QuoteLine__c where  SBQQ__Quote__c =:qt.id];
        
        
        
        
        List<PO_Stage__c> poStageList = new List<PO_Stage__c>();
        PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.pp','test123',system.today().addDays(10),2,'test@test.com','test partner',system.today(),1,'test12345',qliList[0].SBQQ__Quote__r.name,qliList[0].SBQQ__NetTotal__c);
        pos.Bill_To_Name__c=act.Id;
        pos.Payment_schedule_type__c = 'test';
        poStageList.add(pos);
        
        PO_Stage__c pos1 = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.pp','test1234',system.today().addDays(10),2,'test@test.com','test partner',system.today(),2,'test12345',qliList[0].SBQQ__Quote__r.name,qliList[1].SBQQ__NetTotal__c);
        pos1.Bill_To_Name__c=act.Id;
        pos1.Payment_schedule_type__c = 'test';
        poStageList.add(pos1);
        
        insert poStageList;
        
        List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>();
        
        
        for(integer i=0;i<qliList.size();i++){
            
            string ediLinenum = 0+''+i;
            PO_Item_Stage__c poi;
            if(i==0){
                poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos.id,qliList[i].SBQQ__SubscriptionTerm__c,qliList[i].SBQQ__NetPrice__c);
                break;
            }
            poItem.add(poi);
        }
        
        insert poItem;
        
        List<PO_Stage_Address__c> poAs = new List<PO_Stage_Address__c>();
        PO_Stage_Address__c spa = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com',pos.id,'292005','test','test2');
        poAs.add(spa);
        PO_Stage_Address__c spa1 = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com',pos1.id,'292005','test','test2');
        poAs.add(spa1);
        insert poAs;
                
        Test.startTest();
        
        List<PO_Stage__c> upStageList = new  List<PO_Stage__c>();
        pos.PO_Validation_Status__c='Staged';
        
        upStageList.add(pos);
        pos1.PO_Validation_Status__c='Staged';
        
        POStageHelper.allStagePOmap.clear(); 
        POStageHelper.quoteMap.clear();
          upStageList.add(pos1);
        update upStageList;
        
        
        Test.stopTest();
    }
    }
    /**
    * @author Siva Kumar
    * @date 12-03-2025
    * @description test method to vover Rubrik Go
    */
    static testMethod void testMethod5() {
        
        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_QuoteLine_Validation_Rules__c =  true, Disable_SBQQ_Quote_Triggers__c = true,Disable_SBQQ_Quote_Validation_Rules__c = true);
        insert disableLogic;
        FlowControll.AccountTrigger = false;
        FlowControll.opportunityTriggerHandler = false;
        
        ShGl_TestFactoryHelper.insertTriggerControls();
        System.runAs(new User(Id=UserInfo.getUSerId())) {
        //Generate the Account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.name='Promark Technology, Inc.';
        act.Type ='Distributor';
        act.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        act.Contract_Status__c = 'Pending';
        
        insert act;
            Assert.areEqual('Promark Technology, Inc.', act.Name);
            act.Id = getPromarkAccount().Sfdc_Id__c;
        update act;
        
        //Create custom setting record for promark EDI Process
        SkipManualOrder__c cusset = new SkipManualOrder__c();
        cusset.Account_Id__c =act.id;
        cusset.Enabled__c = true;
        cusset.name='Promark Technology, Inc.';
        insert cusset;
        
        createCustomSetPOValidationError();
        
        
        
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => act.Id
                };
                    Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt;
        
        Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'Standalone',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit',
                'ProductCode' => 'test xyz1'
                };
                    
                    Map<String, Object> prdMap1 = new Map<String, Object> {
                        'Name' => 'Subscription', 
                            'IsActive' => true, 
                            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                            'SBQQ__SubscriptionTerm__c' => 12, 
                            'SBQQ__SubscriptionType__c' => 'Renewable',
                            'ProductCode' => 'test xyz'
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
                'RecordTypeId' => Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId()
                };
                    Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        opp.Distributor_Lookup__c =act.id;
        opp.Pricebook2id = system.label.CPQPricebookID;
        insert opp;
        
        
        
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__SubscriptionTerm__c = 36;
        qt.SBQQ__PaymentTerms__c = 'Net 45';
        
        insert qt; 
        
        
        FlowControll.AccountTrigger = true;
        FlowControll.opportunityTriggerHandler = true;
        
        
        //the JSON formatted String representing the quote model to add a product to
        String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', qt.id);
        String currencyCode = 'USD';
        
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
        
        
        //the JSON formatted String represeting the saved quote
        String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
        
        
        QuoteCalculator calculator = new QuoteCalculator();
        calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
        
        
        SBQQ__Quote__c qtq =[select id,name,SBQQ__NetAmount__c,SBQQ__PricebookId__c from SBQQ__Quote__c where id=:qt.id ];
        
        List<SBQQ__QuoteLine__c> qliList =[select Id, SBQQ__Bundle__c, SBQQ__Quote__c,SBQQ__NetPrice__c,SBQQ__NetTotal__c,SBQQ__Product__r.productcode,SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c, SBQQ__Product__c   from SBQQ__QuoteLine__c where  SBQQ__Quote__c =:qt.id];
        
        List<SBQQ__QuoteLine__c> newQlis = qliList.deepClone();
        newQlis[1].SBQQ__Bundle__c = true;
        newQlis[1].SBQQ__RequiredBy__c = newQlis[0].Id;
        insert newQlis;
                
        qliList.addAll(newQlis);

        Test.startTest();
        
        List<PO_Stage__c> poStageList = new List<PO_Stage__c>();
        PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.pp','test123',system.today().addDays(10),2,'test@test.com','test partner',system.today(),1,'test12345',qtq.name,qliList[0].SBQQ__NetTotal__c);
        pos.Bill_To_Name__c=act.Id;
        pos.Payment_schedule_type__c = 'test';
        poStageList.add(pos);
        
        PO_Stage__c pos1 = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.pp','test1234',system.today().addDays(10),2,'test@test.com','test partner',system.today(),2,'test12345',qtq.name,qliList[1].SBQQ__NetTotal__c);
        pos1.Bill_To_Name__c=act.Id;
        pos1.Payment_schedule_type__c = 'test';
        poStageList.add(pos1);
        
        insert poStageList;
        
        List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>();
        
        
        for(integer i=0;i<qliList.size();i++){
            
            string ediLinenum = 0+''+i;
            PO_Item_Stage__c poi;
            if(i==0)
                poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c+10,pos.id,qliList[i].SBQQ__SubscriptionTerm__c,qliList[i].SBQQ__NetPrice__c);
            else
                poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos1.id,qliList[i].SBQQ__SubscriptionTerm__c,qliList[i].SBQQ__NetPrice__c);
            poItem.add(poi);

            PO_Item_Stage__c clonedPOI = poi.clone();
            clonedPOI.Quantity__c = 2;
            clonedPOI.SubscriptionTerm__c = 10;

            poItem.add(clonedPOI);

        }   
        
        insert poItem;
        
        List<PO_Stage_Address__c> poAs = new List<PO_Stage_Address__c>();
        PO_Stage_Address__c spa = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com',pos.id,'292005','test','test2');
        poAs.add(spa);
        PO_Stage_Address__c spa1 = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com',pos1.id,'292005','test','test2');
        poAs.add(spa1);
        insert poAs;
        
        
        
        POStageHelper.allStagePOmap.clear(); 
        POStageHelper.quoteMap.clear();
        List<PO_Stage__c> upStageList = new  List<PO_Stage__c>();
        pos.PO_Validation_Status__c='Staged';
        upStageList.add(pos);
        pos1.PO_Validation_Status__c='Staged';
       POStageHelper.allStagePOmap.clear(); 
        POStageHelper.quoteMap.clear();
          upStageList.add(pos1);
        update upStageList;
        
        
        Test.stopTest();
    }
    }
    /**
    * @author Siva Kumar
    * @date 12-03-2025
    * @description test method to cover PO Stage trigger logic 
    */
    public static void createCustomSetPOValidationError(){
        List<POValidation_ErrorCode__c> poErrList = new List<POValidation_ErrorCode__c>();
        POValidation_ErrorCode__c poErr1 = new POValidation_ErrorCode__c();
        poErr1.name='PO-01';
        poErr1.Code__c='PO-01';
        poErr1.Error_Issue__c = 'error reported';
        poErrList.add(poErr1);
        
        POValidation_ErrorCode__c poErr2 = new POValidation_ErrorCode__c();
        poErr2.name='PO-02';
        poErr2.Code__c='PO-02';
        poErr2.Error_Issue__c = 'error reported';
        poErrList.add(poErr2);
        
        POValidation_ErrorCode__c poErr3 = new POValidation_ErrorCode__c();
        poErr3.name='PO-03';
        poErr3.Code__c='PO-03';
        poErr3.Error_Issue__c = 'error reported';
        poErrList.add(poErr3);
        
        POValidation_ErrorCode__c poErr4 = new POValidation_ErrorCode__c();
        poErr4.name='PO-04';
        poErr4.Code__c='PO-04';
        poErr4.Error_Issue__c = 'error reported';
        poErrList.add(poErr4);
        
        POValidation_ErrorCode__c poErr5 = new POValidation_ErrorCode__c();
        poErr5.name='PO-05';
        poErr5.Code__c='PO-05';
        poErr5.Error_Issue__c = 'error reported';
        poErrList.add(poErr5);
        
        POValidation_ErrorCode__c poErr6 = new POValidation_ErrorCode__c();
        poErr6.name='PO-06';
        poErr6.Code__c='PO-06';
        poErr6.Error_Issue__c = 'error reported';
        poErrList.add(poErr6);
        
        POValidation_ErrorCode__c poErr7 = new POValidation_ErrorCode__c();
        poErr7.name='PO-07';
        poErr7.Code__c='PO-07';
        poErr7.Error_Issue__c = 'error reported';
        poErrList.add(poErr7);
        
        POValidation_ErrorCode__c poErr8 = new POValidation_ErrorCode__c();
        poErr8.name='PO-08';
        poErr8.Code__c='PO-01';
        poErr8.Error_Issue__c = 'error reported';
        poErrList.add(poErr8);
        
        POValidation_ErrorCode__c poErr9 = new POValidation_ErrorCode__c();
        poErr9.name='PO-09';
        poErr9.Code__c='PO-01';
        poErr9.Error_Issue__c = 'error reported';
        poErrList.add(poErr9);
        
        
        
        POValidation_ErrorCode__c poErr10 = new POValidation_ErrorCode__c();
        poErr10.name='PO-10';
        poErr10.Code__c='PO-01';
        poErr10.Error_Issue__c = 'error reported';
        poErrList.add(poErr10);
        
        POValidation_ErrorCode__c poErr11 = new POValidation_ErrorCode__c();
        poErr11.name='PO-11';
        poErr11.Code__c='PO-01';
        poErr11.Error_Issue__c = 'error reported';
        poErrList.add(poErr11);
        
        POValidation_ErrorCode__c poErr12 = new POValidation_ErrorCode__c();
        poErr12.name='PO-12';
        poErr12.Code__c='PO-01';
        poErr12.Error_Issue__c = 'error reported';
        poErrList.add(poErr12);
        
        POValidation_ErrorCode__c poErr13 = new POValidation_ErrorCode__c();
        poErr13.name='PO-13';
        poErr13.Code__c='PO-01';
        poErr13.Error_Issue__c = 'error reported';
        poErrList.add(poErr13);
        
        POValidation_ErrorCode__c poErr14 = new POValidation_ErrorCode__c();
        poErr14.name='PO-14';
        poErr14.Code__c='PO-01';
        poErr14.Error_Issue__c = 'error reported';
        poErrList.add(poErr14);
        
        POValidation_ErrorCode__c poErr20 = new POValidation_ErrorCode__c();
        poErr20.name='PO-20';
        poErr20.Code__c='PO-01';
        poErr20.Error_Issue__c = 'error reported';
        poErrList.add(poErr20);
        
        insert poErrList;
    }
    /**
    * @author Siva Kumar
    * @date 12-03-2025
    * @description Added to Cover SplitOrder Go
    */
    static testMethod void testMethod12() {
        FlowControll.AccountTrigger = false;
        FlowControll.opportunityTriggerHandler = false;
        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_QuoteLine_Validation_Rules__c =  true, Disable_SBQQ_Quote_Triggers__c = true,Disable_SBQQ_Quote_Validation_Rules__c = true, Disable_Opportunity_Validation_Rules__c = true);
        insert disableLogic;
        List<TriggerControl__c> triggerControls = new List<TriggerControl__c> {
            new TriggerControl__c(Name='Contact', DisableTrigger__c=true),
                new TriggerControl__c(Name='Opportunity', DisableTrigger__c=true),
                new TriggerControl__c(Name='Entitlement', DisableTrigger__c=true),
                new TriggerControl__c(Name='Asset', DisableTrigger__c=true),
                new TriggerControl__c(Name='User', DisableTrigger__c=true),
                new TriggerControl__c(Name='Order', DisableTrigger__c=true)
                };
        insert triggerControls;
        System.runAs(new User(Id=UserInfo.getUSerId())) {
        //Generate the Account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.name='Promark Technology, Inc.';
        act.Type ='Distributor';
        act.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        act.Contract_Status__c = 'Pending';
        insert act;
            Assert.areEqual('Promark Technology, Inc.', act.name);
            act.Id = getPromarkAccount().Sfdc_Id__c;
        update act;
        
        //Create custom setting record for promark EDI Process
        SkipManualOrder__c cusset = new SkipManualOrder__c();
        cusset.Account_Id__c =act.id;
        cusset.Enabled__c = true;
        cusset.name='Promark Technology, Inc.';
        insert cusset;
        
        createCustomSetPOValidationError();
        
        
        
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => act.Id
                };
                    Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt;
        
        Map<String, Object> prdMapStd = new Map<String, Object> {
            'Name' => 'Standalone',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit',
                'productcode' => 'HW2'
                };
                    
                    Map<String, Object> prdMap = new Map<String, Object> {
                        'Name' => 'Standalone',
                            'IsActive' => true,
                            'SBQQ__AssetConversion__c' => 'One per unit',
                            'productcode' => 'HW1'
                            };
                                
                                Map<String, Object> prdMap1 = new Map<String, Object> {
                                    'Name' => 'Subscription', 
                                        'IsActive' => true, 
                                        'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                                        'SBQQ__SubscriptionTerm__c' => 12, 
                                        'SBQQ__SubscriptionType__c' => 'Renewable',
                                        'Product_Payment_Option__c' => 'Annual',
                                        'productcode' => 'GO1'
                                        };
                                            Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        Product2 prdHWSTD = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMapStd);
        
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 3, prdMap);
        prdList.add(prdHW);
        prdList.add(prdSubs);
        prdList.add(prdHWSTD);
        insert prdList;
        
        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        // Create a custom price book
        Pricebook2 customPB = new Pricebook2(Name='CPQ PriceBook', isActive=true);
        insert customPB;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry pbeHWstd1 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHWstd1.Product2Id = prdHWSTD.Id;
        pbeHWstd1.UnitPrice = 1500;
        pbeHWstd1.Pricebook2id = pricebookId;
        pBList.add(pbeHWstd1);
        
        
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
        pbeSubs.Pricebook2id = system.label.CPQPricebookID;
        
        PricebookEntry pbeHWstd12 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHWstd12.Product2Id = prdHWSTD.Id;
        pbeHWstd12.UnitPrice = 1500;
        pbeHWstd12.Pricebook2id = system.label.CPQPricebookID;
        pBList.add(pbeHWstd12);
        
        
        pBList.add(pbeSubs);
        insert pBList;
        
        
        //Generate the Opportunity
        Opportunity opp = TestDataFactory.getOpportunity(act);
        opp.Distributor_Lookup__c =act.id;
        opp.Pricebook2id = system.label.CPQPricebookID;
        insert opp;
        
        
        
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__SubscriptionTerm__c = 36;
        qt.SBQQ__PaymentTerms__c = 'Net 45';
        
        insert qt; 
        
                
        //the JSON formatted String representing the quote model to add a product to
        String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', qt.id);
        String currencyCode = 'USD';
        
        //the JSON formatted String representing the product to be added to the quote
        String productModel = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdSubs.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
        String productModel2 = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdHW.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
        String productModel3 = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdHWSTD.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
        
        List<ProductModel> productModels = new List<ProductModel>();
        
        productModels.add((ProductModel) JSON.deserialize(productModel, ProductModel.class));
        productModels.add((ProductModel) JSON.deserialize(productModel2, ProductModel.class));
        productModels.add((ProductModel) JSON.deserialize(productModel3, ProductModel.class));
        
        
        ProductAdder adder = new ProductAdder();
        QuoteModel quoteWithProducts = adder.add((QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class), productModels, 0);
        
        quoteWithProducts.lineItems[0].record.SBQQ__Quantity__c = 10;
        quoteWithProducts.lineItems[0].record.SBQQ__SubscriptionTerm__c = 36;
        
        quoteWithProducts.lineItems[1].record.SBQQ__Quantity__c = 20;
        quoteWithProducts.lineItems[1].record.SBQQ__SubscriptionTerm__c = 36;
        
        quoteWithProducts.lineItems[2].record.SBQQ__Quantity__c = 15;
        quoteWithProducts.lineItems[2].record.SBQQ__SubscriptionTerm__c = 36;
        
        
        //the JSON formatted String represeting the saved quote
        String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
        
        
        QuoteCalculator calculator = new QuoteCalculator();
        calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
        
        qt.ApprovalStatus__c = 'Approved';
        update qt;
            String replaceDet = '{"rowValues":[{"rowId":"20.0", "selectedAsset" : "test1" , "partial_Quantity":"Yes","selectedQty":2,"selectedTerm":12}],"mode":"1to1", "skuSelectedName":"RS-BT-EE-SC-PE-PP", "skuSelected":"01t6f00000NUivYAAT","disposition":"Converted"}';
        SBQQ__Quote__c qtq =[select id,name,SBQQ__NetAmount__c,SBQQ__PricebookId__c from SBQQ__Quote__c where id=:qt.id ];
        
            List<SBQQ__QuoteLine__c> qliList =[select id,SBQQ__NetPrice__c,SBQQ__NetTotal__c,SBQQ__Product__r.productcode,SBQQ__Quantity__c,SBQQ__Product__r.Product_Payment_Option__c, SBQQ__SubscriptionTerm__c, SBQQ__Product__c,Replacement_details__c   from SBQQ__QuoteLine__c where  SBQQ__Quote__c =:qt.id];
        
            for(SBQQ__QuoteLine__c qli : qliList){
               qli.Special_Program__c = Constants.PROGRAM_REFRESH;
               qli.Replacement_Details__c = replaceDet;
            }
            
            update qliList;
        Test.startTest();
        
        List<PO_Stage__c> poStageList = new List<PO_Stage__c>();
        PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.','test123',system.today().addDays(10),2,'test@test.com','test partner',system.today(),1,'test12345',qtq.name,qliList[0].SBQQ__NetTotal__c+qliList[1].SBQQ__NetTotal__c);
        pos.Bill_To_Name__c=act.Id;
        pos.Payment_schedule_type__c = 'test';
        poStageList.add(pos);
        
        PO_Stage__c pos1 = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.','test1234',system.today().addDays(10),2,'test@test.com','test partner',system.today(),2,'test12345',qtq.name,qliList[2].SBQQ__NetTotal__c);
        pos1.Bill_To_Name__c=act.Id;
        pos1.Payment_schedule_type__c = 'test';
        poStageList.add(pos1);
        
        insert poStageList;
        
        List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>();
        
        qliList[0].SBQQ__RequiredBy__c = qliList[1].id;
        qliList[0].SBQQ__Quantity__c=50;
        qliList[0].SBQQ__Bundle__c=true;
        update qliList[0];   
        for(integer i=0;i<qliList.size();i++){
            
            string ediLinenum = 0+''+i;
            PO_Item_Stage__c poi;
            if(qliList[i].SBQQ__Product__r.Product_Payment_Option__c =='Annual'){
                
                Decimal j= qliList[i].SBQQ__SubscriptionTerm__c != null? (qliList[i].SBQQ__SubscriptionTerm__c/12) : 1;
                for(integer k=0;k<j;k++){
                    poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum+'_'+k,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos.id,12,((qliList[i].SBQQ__NetPrice__c)/36)*12);
                    poi.Quote_Line__c = qliList[i].Id;
                    poItem.add(poi);
                    poi = new PO_Item_Stage__c();
                }
            }
            else if(qliList[i].SBQQ__Product__r.productcode=='HW1'){
                poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos.id,qliList[i].SBQQ__SubscriptionTerm__c,qliList[i].SBQQ__NetPrice__c);
                poi.Quote_Line__c = qliList[i].Id;
                poItem.add(poi);
                poi = new PO_Item_Stage__c();
            }else IF(qliList[i].SBQQ__Product__r.productcode=='HW2'){
                poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos1.id,qliList[i].SBQQ__SubscriptionTerm__c,qliList[i].SBQQ__NetPrice__c);
                poi.Quote_Line__c = qliList[i].Id;
                poItem.add(poi);
                poi = new PO_Item_Stage__c();
            }
            
        }
        
        insert poItem;
        
        
        PO_Item_Stage__c PoIS = new PO_Item_Stage__c();
            PoIS.Buyer_Part_Number__c='1234';
            PoIS.EDI_Line_Number__c ='100';
            PoIS.ProductCode__c =qliList[0].SBQQ__Product__r.productcode;
            PoIS.Quantity__c = 50;
            PoIS.Stage_PO__c= pos1.id;
            PoIS.SubscriptionTerm__c =qliList[0].SBQQ__SubscriptionTerm__c;
            PoIS.UnitPrice__c=qliList[0].SBQQ__NetPrice__c;
        insert PoIS;
        
        List<PO_Stage_Address__c> poAs = new List<PO_Stage_Address__c>();
        PO_Stage_Address__c spa = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com',pos.id,'292005','test','test2');
        poAs.add(spa);
        PO_Stage_Address__c spa1 = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com',pos1.id,'292005','test','test2');
        poAs.add(spa1);
        insert poAs;        
        
        
        List<PO_Stage__c> upStageList = new  List<PO_Stage__c>();
        pos.PO_Validation_Status__c='Staged';
        
        upStageList.add(pos);
        pos1.PO_Validation_Status__c='Staged';
        
       POStageHelper.allStagePOmap.clear(); 
        POStageHelper.quoteMap.clear();
          upStageList.add(pos1);
        update upStageList;
                
        poStageList = [select id,PO_Validation_Status__c from PO_Stage__c where id=: pos.id];
        
        List<PO_Stage__c> upStageList1 = new  List<PO_Stage__c>();
        pos.PO_Validation_Status__c='Success';
        
        upStageList1.add(pos);
        pos1.PO_Validation_Status__c='Success';
        
        upStageList1.add(pos1);
        update upStageList1;
        
        opp.StageName = '6 PO With Channel';
        opp.SBQQ__Ordered__c = true;
        opp.Is_Order_Split__c = true;
        opp.Lost_To_Won_Against__c = 'Actifio';
        opp.Opportunity_Sub_Type__c='Regular';
        opp.Partner_Level_Of_Involvement__c='1.Rubrik initiated, Partner was fulfillment only';
        opp.Installation_Assigned_To__c='FE Install';
        opp.Primary_Competitor__c = 'Actifio';
        FlowControll.opportunityTriggerHandler = false;
        update opp;
        
            Map<String, Object>  OrderMap = new Map<String, Object> {
                'Type' => 'Revenue',
                    'AccountId' => act.Id,
                    'OpportunityId' => opp.Id,
                    'Sync_to_NetSuite__c' => true,
                    'EffectiveDate' => system.today(),
                    'Status' => 'Pending',
                    'Bill_To_Name__c'=>act.Id,
                    'SBQQ__Quote__c'=>qt.id  
                    };
                        
                        Order phantomOrd =  (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
            phantomOrd.Order_Sub_type__c = 'Surviving Partial';
            //lstofOrdToInsert.add(phantomOrd);
            insert phantomOrd;
            
            
            List<Order> lstOrder = new List<order>([SELECT Id, Ordernumber,Order_Sub_type__c, Order_Split_Type__c FROM Order WHERE (OpportunityId =: opp.id OR Order_Sub_type__c = 'Surviving Partial') ]);
            String phantomOrdNum; 
            Order replacedOrd = new Order();
            for(Order ord : lstOrder){
                if(ord.Order_Sub_type__c == 'Surviving Partial'){
                    phantomOrdNum = ord.Ordernumber;
                }
                else{
                    replacedOrd = ord;
                }
            }
            replacedOrd.Order_Status__c = 'Pending';
            replacedOrd.Order_Split_Type__c = 'EDI';
            replacedOrd.Type = 'Revenue';
            replacedOrd.Associated_Order_Numbers__c = phantomOrdNum;
            replacedOrd.Line_Types__c = 'Conversion';
            update replacedOrd;
        lstOrder[0].Order_Status__c = 'Pending';
        lstOrder[0].Order_Split_Type__c = 'EDI';
        update lstOrder;
        
        SplitOrder scbat = new SplitOrder();
        string jobID =Database.executeBatch(scbat);
        
        Test.stopTest();
    }
    }
	/**
    * @author Siva Kumar
    * @date 12-03-2025
    * @description Added to Cover SplitOrder Go
    */
    static testMethod void testMethod13() {
      

        FlowControll.AccountTrigger = false;
        FlowControll.opportunityTriggerHandler = false;
        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_QuoteLine_Validation_Rules__c =  true, Disable_SBQQ_Quote_Triggers__c = true,Disable_SBQQ_Quote_Validation_Rules__c = true, Disable_Opportunity_Validation_Rules__c = true,Disable_Order_Triggers__c = true,Disable_OrderItem_Trigger__c = true,setupOwnerId = userinfo.getuserid());
        insert disableLogic;
        List<TriggerControl__c> triggerControls = new List<TriggerControl__c> {
            new TriggerControl__c(Name='Contact', DisableTrigger__c=true),
                new TriggerControl__c(Name='Opportunity', DisableTrigger__c=true),
                new TriggerControl__c(Name='Entitlement', DisableTrigger__c=true),
                new TriggerControl__c(Name='Asset', DisableTrigger__c=true),
                new TriggerControl__c(Name='User', DisableTrigger__c=true),
                new TriggerControl__c(Name='Order', DisableTrigger__c=true)
                };
        insert triggerControls;
       // testutilitymethod();
        System.runAs(new User(Id=UserInfo.getUSerId())) {
        //Generate the Account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.name='Promark Technology, Inc.';
        act.Type ='Distributor';
        act.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        act.Contract_Status__c = 'Pending';
        insert act;
             Assert.areEqual('Promark Technology, Inc.', act.name);
             act.Id = getPromarkAccount().Sfdc_Id__c;
        update act;
        
        //Create custom setting record for promark EDI Process
        SkipManualOrder__c cusset = new SkipManualOrder__c();
        cusset.Account_Id__c =act.id;
        cusset.Enabled__c = true;
        cusset.name='Promark Technology, Inc.';
        insert cusset;
        
        createCustomSetPOValidationError();
        
        
        
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => act.Id
                };
                    Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt;
        
        Map<String, Object> prdMapStd = new Map<String, Object> {
            'Name' => 'Standalone',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit',
                'productcode' => 'HW2',
                'Product_Subtype__c' => 'FEDRAMP'
                };
                    
                    Map<String, Object> prdMap = new Map<String, Object> {
                        'Name' => 'Standalone',
                            'IsActive' => true,
                            'SBQQ__AssetConversion__c' => 'One per unit',
                            'productcode' => 'HW1',
                            'Product_Subtype__c' => 'FEDRAMP'
                            };
                                
                                Map<String, Object> prdMap1 = new Map<String, Object> {
                                    'Name' => 'Subscription', 
                                        'IsActive' => true, 
                                        'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                                        'SBQQ__SubscriptionTerm__c' => 12, 
                                        'SBQQ__SubscriptionType__c' => 'Renewable',
                                        'Product_Payment_Option__c' => 'Annual',
                                        'productcode' => 'GO1',
                                        'Product_Subtype__c' => null
                                        };
                                            Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        Product2 prdHWSTD = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMapStd);
        
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 3, prdMap);
        prdList.add(prdHW);
        prdList.add(prdSubs);
        prdList.add(prdHWSTD);
        insert prdList;
        
        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        // Create a custom price book
        Pricebook2 customPB = new Pricebook2(Name='CPQ PriceBook', isActive=true);
        insert customPB;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry pbeHWstd1 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHWstd1.Product2Id = prdHWSTD.Id;
        pbeHWstd1.UnitPrice = 1500;
        pbeHWstd1.Pricebook2id = pricebookId;
        pBList.add(pbeHWstd1);
        
        
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
        pbeSubs.Pricebook2id = system.label.CPQPricebookID;
        
        PricebookEntry pbeHWstd12 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHWstd12.Product2Id = prdHWSTD.Id;
        pbeHWstd12.UnitPrice = 1500;
        pbeHWstd12.Pricebook2id = system.label.CPQPricebookID;
        pBList.add(pbeHWstd12);
        
        
        pBList.add(pbeSubs);
        insert pBList;
        
        //Generate the Opportunity
        Opportunity opp = TestDataFactory.getOpportunity(act);
        opp.Distributor_Lookup__c =act.id;
        opp.Pricebook2id = system.label.CPQPricebookID;
        insert opp;
        
        
        
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__SubscriptionTerm__c = 36;
        qt.SBQQ__PaymentTerms__c = 'Net 45';
        qt.Is_RWD_Polaris_Quote__c = true;
        
        insert qt; 
        
                
        //the JSON formatted String representing the quote model to add a product to
        String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', qt.id);
        String currencyCode = 'USD';
        
        //the JSON formatted String representing the product to be added to the quote
        String productModel = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdSubs.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
        String productModel2 = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdHW.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
        String productModel3 = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdHWSTD.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
        
        List<ProductModel> productModels = new List<ProductModel>();
        
        productModels.add((ProductModel) JSON.deserialize(productModel, ProductModel.class));
        productModels.add((ProductModel) JSON.deserialize(productModel2, ProductModel.class));
        productModels.add((ProductModel) JSON.deserialize(productModel3, ProductModel.class));
        
        
        ProductAdder adder = new ProductAdder();
        QuoteModel quoteWithProducts = adder.add((QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class), productModels, 0);
        
        quoteWithProducts.lineItems[0].record.SBQQ__Quantity__c = 10;
        quoteWithProducts.lineItems[0].record.SBQQ__SubscriptionTerm__c = 36;
        
        quoteWithProducts.lineItems[1].record.SBQQ__Quantity__c = 20;
        quoteWithProducts.lineItems[1].record.SBQQ__SubscriptionTerm__c = 36;
        
        quoteWithProducts.lineItems[2].record.SBQQ__Quantity__c = 15;
        quoteWithProducts.lineItems[2].record.SBQQ__SubscriptionTerm__c = 36;
        
        
        //the JSON formatted String represeting the saved quote
        String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
        
        
        QuoteCalculator calculator = new QuoteCalculator();
        calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
        
        qt.ApprovalStatus__c = 'Approved';
        update qt;
        
        SBQQ__Quote__c qtq =[select id,name,SBQQ__NetAmount__c,SBQQ__PricebookId__c from SBQQ__Quote__c where id=:qt.id ];
        
             List<SBQQ__QuoteLine__c> qliList =[select id,SBQQ__NetPrice__c,SBQQ__NetTotal__c,SBQQ__Product__r.productcode,SBQQ__Product__r.Product_Subtype__c, SBQQ__Quantity__c,SBQQ__Product__r.Product_Payment_Option__c, SBQQ__SubscriptionTerm__c, SBQQ__Product__c,SBQQ__PricebookEntryId__c,Arroyo_Subscribed_Asset_Name__c   from SBQQ__QuoteLine__c where  SBQQ__Quote__c =:qt.id];
             
             Asset assestIns = new Asset();
             assestIns.Name = '09092019APMSP1250';
             assestIns.SerialNumber = '09092019APMSP1250';
             assestIns.serial_number__c= '09092019APMSP1250';
             assestIns.AccountId = act.Id;
             assestIns.Product2Id = prdList[0].Id;
             insert assestIns;
        
        Test.startTest();
        
             PO_Stage__c hardWarePO = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.pp', 'abc123',
                                                                           system.today().addDays(10),
                                                                           2,'test@test.com.invalid',
                                                                           'test partner',system.today(),
                                                                           1,
                                                                           'test12345',
                                                                           qtq.name,
                                                                           0
                                                                          );
             insert hardWarePO;
        List<PO_Stage__c> poStageList = new List<PO_Stage__c>();
        PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.','test123',system.today().addDays(10),2,'test@test.com','test partner',system.today(),1,'test12345',qtq.name,qliList[0].SBQQ__NetTotal__c+qliList[1].SBQQ__NetTotal__c);
            pos.Name = 'test123';
            pos.Bill_To_Name__c=act.Id;
            pos.Payment_schedule_type__c = 'test';
             pos.Hardware_PO_Id__c = hardWarePO.Id;//'aBE8Y000000Xfa0WAC';
            poStageList.add(pos);
        
        PO_Stage__c pos1 = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.','test1234',system.today().addDays(10),2,'test@test.com','test partner',system.today(),2,'test12345',qtq.name,qliList[2].SBQQ__NetTotal__c);
            pos.Name = 'test1234';
            pos1.Bill_To_Name__c=act.Id;
            pos1.Payment_schedule_type__c = 'test';
             pos1.Hardware_PO_Id__c =  hardWarePO.Id;//'aBE8Y000000Xfa0WAC';
            poStageList.add(pos1);
        
        insert poStageList;
        
        List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>();
        
        qliList[0].SBQQ__RequiredBy__c = qliList[1].id;
        qliList[0].SBQQ__Quantity__c=50;
        qliList[0].SBQQ__Bundle__c=true;
        //qliList[0].SBQQ__Product__r.Product_Subtype__c = 'FEDRAMP';
        update qliList[0];   
        for(integer i=0;i<qliList.size();i++){
            
            string ediLinenum = 0+''+i;
            PO_Item_Stage__c poi;
            if(qliList[i].SBQQ__Product__r.Product_Payment_Option__c =='Annual'){
                
                Decimal j= qliList[i].SBQQ__SubscriptionTerm__c != null? (qliList[i].SBQQ__SubscriptionTerm__c/12) : 1;
                for(integer k=0;k<j;k++){
                    poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum+'_'+k,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos.id,12,((qliList[i].SBQQ__NetPrice__c)/36)*12);
                    poi.Quote_Line__c = qliList[i].Id;
                    poItem.add(poi);
                    poi = new PO_Item_Stage__c();
                }
            }
            else if(qliList[i].SBQQ__Product__r.productcode=='HW1'){
                poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos.id,qliList[i].SBQQ__SubscriptionTerm__c,qliList[i].SBQQ__NetPrice__c);
                poi.Quote_Line__c = qliList[i].Id;
                poItem.add(poi);
                poi = new PO_Item_Stage__c();
            }else IF(qliList[i].SBQQ__Product__r.productcode=='HW2'){
                poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos1.id,qliList[i].SBQQ__SubscriptionTerm__c,qliList[i].SBQQ__NetPrice__c);
                poi.Quote_Line__c = qliList[i].Id;
                poItem.add(poi);
                poi = new PO_Item_Stage__c();
            }
                 qliList[i].Arroyo_Subscribed_Asset_Name__c = '09092019APMSP1250';
                 if(i == 0 || i == 1){
                     qliList[i].SBQQ__RequiredBy__c = qliList[i+1].id;
        }
             }
             update qliList;
        insert poItem;
        
        
        PO_Item_Stage__c PoIS = new PO_Item_Stage__c();
            PoIS.Buyer_Part_Number__c='1234';
            PoIS.EDI_Line_Number__c ='100';
            PoIS.ProductCode__c =qliList[0].SBQQ__Product__r.productcode;
            PoIS.Quantity__c = 50;
            PoIS.Stage_PO__c= pos1.id;
            PoIS.SubscriptionTerm__c =qliList[0].SBQQ__SubscriptionTerm__c;
            PoIS.UnitPrice__c=qliList[0].SBQQ__NetPrice__c;
        insert PoIS;
        
        List<PO_Stage_Address__c> poAs = new List<PO_Stage_Address__c>();
        PO_Stage_Address__c spa = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com',pos.id,'292005','test','test2');
        poAs.add(spa);
        PO_Stage_Address__c spa1 = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com',pos1.id,'292005','test','test2');
        poAs.add(spa1);
        insert poAs;        
        
        
        List<PO_Stage__c> upStageList = new  List<PO_Stage__c>();
        pos.PO_Validation_Status__c='Staged';
        
        upStageList.add(pos);
        pos1.PO_Validation_Status__c='Staged';
        
       POStageHelper.allStagePOmap.clear(); 
        POStageHelper.quoteMap.clear();
          upStageList.add(pos1);
        update upStageList;
                
        poStageList = [select id,PO_Validation_Status__c from PO_Stage__c where id=: pos.id];
        
        List<PO_Stage__c> upStageList1 = new  List<PO_Stage__c>();
        pos.PO_Validation_Status__c='Success';
        
        upStageList1.add(pos);
        pos1.PO_Validation_Status__c='Success';
        
        upStageList1.add(pos1);
        update upStageList1;
        
        opp.StageName = '6 PO With Channel';
        opp.SBQQ__Ordered__c = true;
        opp.Is_Order_Split__c = true;
        opp.Lost_To_Won_Against__c = 'Actifio';
        opp.Opportunity_Sub_Type__c='Regular';
        opp.Partner_Level_Of_Involvement__c='1.Rubrik initiated, Partner was fulfillment only';
        opp.Installation_Assigned_To__c='FE Install';
        opp.Primary_Competitor__c = 'Actifio';
        FlowControll.opportunityTriggerHandler = false;
        update opp;
        
        List<Order> lstOrder = new List<order>([SELECT Id,Pricebook2Id,AccountId,OpportunityId,Sync_to_NetSuite__c, EffectiveDate,Status ,Mosaic_SKUs__c ,ShippingCountryCode,Polaris_Fulfillment_Status__c,Is_RWD_Polaris_Quote__c,Stage_PO__c,Order_Status__c ,Order_Split_Type__c ,Bill_To_Name__c ,SBQQ__Quote__c,Sell_to_Partner__c  FROM Order WHERE OpportunityId =: opp.id]);
        lstOrder[0].Order_Status__c = 'Pending';
        lstOrder[0].Order_Split_Type__c = 'Non-EDI';

        lstOrder[0].RSC_G_Enabled__c = true;
        update lstOrder;

        Order ord1 = lstOrder[0].clone();

        insert ord1;


        List<OrderItem> lstOrdrItems = new List<OrderItem>(); 
        Set<Id> pbeIds = new Set<Id>();
        for(integer i=0;i<qliList.size();i++){
            pbeIds.add(qliList[i].SBQQ__PricebookEntryId__c);
            lstOrdrItems.add(new OrderItem( SBQQ__QuotedQuantity__c = qliList[i].SBQQ__Quantity__c,OrderId = lstOrder[0].Id, Quantity = qliList[i].SBQQ__Quantity__c, PricebookEntryId = qliList[i].SBQQ__PricebookEntryId__c, unitprice =qliList[i].SBQQ__NetPrice__c,Sales_Price__c = qliList[i].SBQQ__NetPrice__c,SBQQ__QuoteLine__c=qliList[i].id, SBQQ__SubscriptionTerm__c =qliList[i].SBQQ__SubscriptionTerm__c));
        }
        Id PBEId;
        PricebookEntry PBE =  [Select Id,Product2.Name,Product2.Product_Subtype__c  from PricebookEntry where id IN :pbeIds AND Product2.Name = 'Subscription' LIMIT 1];
        lstOrdrItems.add(new OrderItem(product2Id = null, SBQQ__QuotedQuantity__c = qliList[2].SBQQ__Quantity__c,OrderId = ord1.Id, Quantity = qliList[2].SBQQ__Quantity__c, PricebookEntryId = PBE.Id, unitprice =qliList[2].SBQQ__NetPrice__c,Sales_Price__c = qliList[2].SBQQ__NetPrice__c, SBQQ__SubscriptionTerm__c =qliList[2].SBQQ__SubscriptionTerm__c));
        insert lstOrdrItems;
        
        PreviousTransRefWrapper repJSON = new PreviousTransRefWrapper(lstOrdrItems[0].Id,0,null,0,null,null,null,false);
        List<OrderItem> ordItems = new List<OrderItem>();
        OrderItem oItem = lstOrdrItems[0].clone();
        oItem.Program__c = Constants.PROGRAM_REFRESH;
        oItem.Previous_Transaction_Reference__c = JSON.serialize(new List<PreviousTransRefWrapper>{repJSON});
        ordItems.add(oItem);
        OrderItem oItem1 = oItem.clone();
        oItem1.Program__c = Constants.PROGRAM_CONVERSION;
        ordItems.add(oItem1);
        insert ordItems;
        
        SplitOrder scbat = new SplitOrder();
        string jobID =Database.executeBatch(scbat);

        Test.stopTest();
        }
    }
    /**
    * @author Siva Kumar
    * @date 12-03-2025
    * @description Added to Cover SplitOrder Go
    */
    static testMethod void testMethod10() {
        FlowControll.AccountTrigger = false;
        FlowControll.opportunityTriggerHandler = false;
        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_QuoteLine_Validation_Rules__c =  true, Disable_SBQQ_Quote_Triggers__c = true,Disable_SBQQ_Quote_Validation_Rules__c = true, Disable_Opportunity_Validation_Rules__c = true, Disable_Product2_Validation_Rules__c = true);
        insert disableLogic;
        List<TriggerControl__c> triggerControls = new List<TriggerControl__c> {
            new TriggerControl__c(Name='Contact', DisableTrigger__c=true),
                new TriggerControl__c(Name='Opportunity', DisableTrigger__c=true),
                new TriggerControl__c(Name='Entitlement', DisableTrigger__c=true),
                new TriggerControl__c(Name='Asset', DisableTrigger__c=true),
                new TriggerControl__c(Name='User', DisableTrigger__c=true),
                new TriggerControl__c(Name='Order', DisableTrigger__c=true)
                };
        insert triggerControls;
        System.runAs(new User(Id=UserInfo.getUSerId())) {
        //Generate the Account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.name='Promark Technology, Inc.';
        act.Type ='Distributor';
        act.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        act.Contract_Status__c = 'Pending';
        insert act;
            Assert.areEqual('Promark Technology, Inc.', act.name);
            act.Id = getPromarkAccount().Sfdc_Id__c;
        update act;
        
        //Create custom setting record for promark EDI Process
        SkipManualOrder__c cusset = new SkipManualOrder__c();
        cusset.Account_Id__c =act.id;
        cusset.Enabled__c = true;
        cusset.name='Promark Technology, Inc.';
        insert cusset;
        
        createCustomSetPOValidationError();
        
        
        
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => act.Id
                };
                    Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt;
        
        Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'Standalone',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit',
                'productcode' => 'HW1'
                };
                    
                    Map<String, Object> prdMap1 = new Map<String, Object> {
                        'Name' => 'Subscription', 
                            'IsActive' => true, 
                            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                            'SBQQ__SubscriptionTerm__c' => 12, 
                            'SBQQ__SubscriptionType__c' => 'Renewable',
                            'Product_Payment_Option__c' => 'Annual',
                            'productcode' => 'GO1'
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
        pbeSubs.Pricebook2id = system.label.CPQPricebookID;
        
        pBList.add(pbeSubs);
        insert pBList;
        
        
        //Generate the Opportunity
        Opportunity opp = TestDataFactory.getOpportunity(act);
        opp.Distributor_Lookup__c =act.id;
        opp.Pricebook2id = system.label.CPQPricebookID;
        insert opp;
        
        
        
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__SubscriptionTerm__c = 36;
        qt.SBQQ__PaymentTerms__c = 'Net 45';
        qt.Is_RWD_Polaris_Quote__c = true;
        
        insert qt; 
        
        
        //the JSON formatted String representing the quote model to add a product to
        String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', qt.id);
        String currencyCode = 'USD';
        
        //the JSON formatted String representing the product to be added to the quote
        String productModel = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdSubs.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
        String productModel2 = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdHW.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
        
        List<ProductModel> productModels = new List<ProductModel>();
        productModels.add((ProductModel) JSON.deserialize(productModel, ProductModel.class));
        productModels.add((ProductModel) JSON.deserialize(productModel2, ProductModel.class));
        ProductAdder adder = new ProductAdder();
        QuoteModel quoteWithProducts = adder.add((QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class), productModels, 0);
        quoteWithProducts.lineItems[0].record.SBQQ__Quantity__c = 10;
        quoteWithProducts.lineItems[0].record.SBQQ__SubscriptionTerm__c = 36;
        
        quoteWithProducts.lineItems[1].record.SBQQ__Quantity__c = 20;
        quoteWithProducts.lineItems[1].record.SBQQ__SubscriptionTerm__c = 36;
        
        
        //the JSON formatted String represeting the saved quote
        String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
        
        
        QuoteCalculator calculator = new QuoteCalculator();
        calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
        
        qt.ApprovalStatus__c = 'Approved';
        update qt;
        
        
        SBQQ__Quote__c qtq =[select id,name,SBQQ__NetAmount__c,SBQQ__PricebookId__c from SBQQ__Quote__c where id=:qt.id ];
        
        List<SBQQ__QuoteLine__c> qliList =[select id,SBQQ__NetPrice__c,SBQQ__NetTotal__c,SBQQ__Product__r.productcode,SBQQ__Quantity__c,SBQQ__Product__r.Product_Payment_Option__c, SBQQ__SubscriptionTerm__c, SBQQ__Product__c   from SBQQ__QuoteLine__c where  SBQQ__Quote__c =:qt.id];
        
        update new Product2(Id = qliList[0].SBQQ__Product__c, ProductCode = 'RBK-CONSULT', Name = 'RBK-CONSULT');

        Test.startTest();
        
        List<PO_Stage__c> poStageList = new List<PO_Stage__c>();
        PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.','test123',system.today().addDays(10),2,'test@test.com','test partner',system.today(),1,'test12345',qtq.name,qliList[0].SBQQ__NetTotal__c);
        pos.Bill_To_Name__c=act.Id;
        pos.Payment_schedule_type__c = 'test';
        poStageList.add(pos);
        
        PO_Stage__c pos1 = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.','test1234',system.today().addDays(10),2,'test@test.com','test partner',system.today(),2,'test12345',qtq.name,qliList[1].SBQQ__NetTotal__c);
        pos1.Bill_To_Name__c=act.Id;
        pos1.Payment_schedule_type__c = 'test';
        poStageList.add(pos1);
        
        insert poStageList;
        
        List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>();
        
        qliList[0].SBQQ__RequiredBy__c = qliList[1].id;
        update qliList[0];  
        for(integer i=0;i<qliList.size();i++){
            
            string ediLinenum = 0+''+i;
            PO_Item_Stage__c poi;
            if(qliList[i].SBQQ__Product__r.Product_Payment_Option__c =='Annual'){
                Decimal j= qliList[i].SBQQ__SubscriptionTerm__c != null? (qliList[i].SBQQ__SubscriptionTerm__c/12) : 1;
                for(integer k=0;k<j;k++){
                    poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum+'_'+k,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos.id,12,((qliList[i].SBQQ__NetPrice__c)/36)*12);
                    poi.Quote_Line__c = qliList[i].Id;
                    poItem.add(poi);
                    poi = new PO_Item_Stage__c();
                }
            }
            else{
                poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos1.id,qliList[i].SBQQ__SubscriptionTerm__c,qliList[i].SBQQ__NetPrice__c);
                poi.Quote_Line__c = qliList[i].Id;
                poItem.add(poi);
                poi = new PO_Item_Stage__c();
            }
            
        }
        
        insert poItem;
        
        List<PO_Stage_Address__c> poAs = new List<PO_Stage_Address__c>();
        PO_Stage_Address__c spa = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com',pos.id,'292005','test','test2');
        poAs.add(spa);
        PO_Stage_Address__c spa1 = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com',pos1.id,'292005','test','test2');
        poAs.add(spa1);
        insert poAs;
                
        
        
        List<PO_Stage__c> upStageList = new  List<PO_Stage__c>();
        pos.PO_Validation_Status__c='Staged';
        
        upStageList.add(pos);
        pos1.PO_Validation_Status__c='Staged';
        
       POStageHelper.allStagePOmap.clear(); 
        POStageHelper.quoteMap.clear();
          upStageList.add(pos1);
        update upStageList;
        
        
        
        List<PO_Stage__c> upStageList1 = new  List<PO_Stage__c>();
        pos.PO_Validation_Status__c='Success';
        
        upStageList1.add(pos);
        pos1.PO_Validation_Status__c='Success';
        
        upStageList1.add(pos1);
        update upStageList1;
        
        opp.StageName = '6 PO With Channel';
        opp.SBQQ__Ordered__c = true;
        opp.Is_Order_Split__c = true;
        opp.Lost_To_Won_Against__c = 'Actifio';
        opp.Opportunity_Sub_Type__c='Regular';
        opp.Partner_Level_Of_Involvement__c='1.Rubrik initiated, Partner was fulfillment only';
        opp.Installation_Assigned_To__c='FE Install';
        opp.Primary_Competitor__c = 'Actifio';
        FlowControll.opportunityTriggerHandler = false;
        update opp;
        
        List<Order> lstOrder = new List<order>([SELECT Id, Order_Split_Type__c FROM Order WHERE OpportunityId =: opp.id]);
        lstOrder[0].Order_Split_Type__c = 'EDI';
        update lstOrder;

        SplitOrder scbat = new SplitOrder();
        string jobID =Database.executeBatch(scbat);
        
        Test.stopTest();
    }
    }
    /**
    * @author Siva Kumar
    * @date 12-03-2025
    * @description Added to cover Initiate Internal validation Coverage
    */
    static testMethod void testMethod78() {

        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_QuoteLine_Validation_Rules__c =  true, Disable_SBQQ_Quote_Triggers__c = true,Disable_SBQQ_Quote_Validation_Rules__c = true);
        insert disableLogic;

        FlowControll.AccountTrigger = false;
        FlowControll.opportunityTriggerHandler = false;
        
        ShGl_TestFactoryHelper.insertTriggerControls();
        System.runAs(new User(Id=UserInfo.getUSerId())) {
        //Generate the Account.
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.name='Promark Technology, Inc.';
        act.Type ='Distributor';
        act.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        act.Contract_Status__c = 'Pending';
        insert act;
            Assert.areEqual('Promark Technology, Inc.', act.name);
            act.Id = getPromarkAccount().Sfdc_Id__c;
        update act;
        
        Account act1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act1.name='Target Tech';
        insert act1;
        
        //Create custom setting record for promark EDI Process
        SkipManualOrder__c cusset = new SkipManualOrder__c();
        cusset.Account_Id__c =act.id;
        cusset.Enabled__c = true;
        cusset.name='Promark Technology, Inc.';
        insert cusset;
        
        createCustomSetPOValidationError();
        
        
        
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => act.Id
                };
                    Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt;
        
        Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'Standalone',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit',
                'ProductCode' => 'test xyz1'
                };
                    
                    Map<String, Object> prdMap1 = new Map<String, Object> {
                        'Name' => 'Subscription', 
                            'IsActive' => true, 
                            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                            'SBQQ__SubscriptionTerm__c' => 12, 
                            'SBQQ__SubscriptionType__c' => 'Renewable',
                            'ProductCode' => 'test xyz'
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
        pbeSubs.Pricebook2id = system.label.CPQPricebookID;
        
        pBList.add(pbeSubs);
        insert pBList;
        
        
        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => act.Id,
                'RecordTypeId' => Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId()
                };
                    Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        opp.Distributor_Lookup__c =act.id;
        opp.Pricebook2id = system.label.CPQPricebookID;
        insert opp;
        
        
        Test.startTest();
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__SubscriptionTerm__c = 36;
        qt.SBQQ__PaymentTerms__c = 'Net 45';
        
        insert qt; 
        
        
        FlowControll.AccountTrigger = true;
        FlowControll.opportunityTriggerHandler = true;
        
        
        //the JSON formatted String representing the quote model to add a product to
        String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', qt.id);
        String currencyCode = 'USD';
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
      
        //the JSON formatted String represeting the saved quote
        String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
        
        
        QuoteCalculator calculator = new QuoteCalculator();
        calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
        
        
        SBQQ__Quote__c qtq =[select id,name,SBQQ__NetAmount__c,SBQQ__PricebookId__c from SBQQ__Quote__c where id=:qt.id ];
        
        List<SBQQ__QuoteLine__c> qliList =[select id,SBQQ__NetPrice__c,SBQQ__NetTotal__c,SBQQ__Product__r.productcode,SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c, SBQQ__Product__c   from SBQQ__QuoteLine__c where  SBQQ__Quote__c =:qt.id];
        
        List<PO_Stage__c> poStageList = new List<PO_Stage__c>();
        PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.pp','test123',system.today().addDays(10),2,'test@test.com','test partner',system.today(),1,'test12345',qtq.name,qliList[0].SBQQ__NetTotal__c);
        pos.Bill_To_Name__c=act1.Id;
        pos.Service_Level__c = '';
        pos.Shipping_Carrier__c = '';
        pos.Shipping_Account_Number__c = '1234';
        pos.Payment_schedule_type__c = 'test';
        poStageList.add(pos);
        
        PO_Stage__c pos1 = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.pp','test1234',system.today().addDays(10),2,'test@test.com','test partner',system.today(),2,'test12345',qtq.name,qliList[1].SBQQ__NetTotal__c);
        pos1.Bill_To_Name__c=act.Id;
        pos1.Payment_schedule_type__c = 'test';
        poStageList.add(pos1);
        
        insert poStageList;
        
        List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>();
        
        
        for(integer i=0;i<qliList.size();i++){
            
            string ediLinenum = 0+''+i;
            PO_Item_Stage__c poi;
            if(i==0)
                poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos.id,qliList[i].SBQQ__SubscriptionTerm__c,qliList[i].SBQQ__NetPrice__c);
            else
                poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos1.id,qliList[i].SBQQ__SubscriptionTerm__c,qliList[i].SBQQ__NetPrice__c);
            
            poItem.add(poi);
        }
        //PO_Item_Stage__c poi = ShGl_TestFactoryHelper.createPOItem('1234','01',prdHW.productcode,10,pos.id,null,(qtq.SBQQ__NetAmount__c/10));
        
        insert poItem;
        
        List<PO_Stage_Address__c> poAs = new List<PO_Stage_Address__c>();
        PO_Stage_Address__c spa = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com',pos.id,'292005','test','test2');
        poAs.add(spa);
        PO_Stage_Address__c spa1 = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com',pos1.id,'292005','test','test2');
        poAs.add(spa1);
        insert poAs; 
        
        List<PO_Stage__c> upStageList = new  List<PO_Stage__c>();
        pos.PO_Validation_Status__c='Staged';
        
        upStageList.add(pos);
        pos1.PO_Validation_Status__c='Staged';
        
       POStageHelper.allStagePOmap.clear(); 
        POStageHelper.quoteMap.clear();
          upStageList.add(pos1);
        update upStageList;
                
        poStageList = [select id,PO_Validation_Status__c from PO_Stage__c where id=: pos.id];
        
        Test.stopTest();
    }
    }
    /**
    * @author Siva Kumar
    * @date 12-03-2025
    * @description Added to check one conult and one travel in diff POs
    */
    static testMethod void testMethodTravelConsult() {

        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_QuoteLine_Validation_Rules__c =  true,Disable_SBQQ_Quote_Triggers__c = true,Disable_SBQQ_Quote_Validation_Rules__c = true);
        insert disableLogic;

        FlowControll.AccountTrigger = false;
        FlowControll.opportunityTriggerHandler = false;
        
        ShGl_TestFactoryHelper.insertTriggerControls();
        System.runAs(new User(Id=UserInfo.getUSerId())) {
        //Generate the Account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.name='Promark Technology, Inc.';
        act.Type ='Distributor';
        act.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        act.Contract_Status__c = 'Pending';
        insert act;
            Assert.areEqual('Promark Technology, Inc.', act.name);
            act.Id = getPromarkAccount().Sfdc_Id__c;
        update act;
        
        //Create custom setting record for promark EDI Process
        SkipManualOrder__c cusset = new SkipManualOrder__c();
        cusset.Account_Id__c =act.id;
        cusset.Enabled__c = true;
        cusset.name='Promark Technology, Inc.';
        insert cusset;
        
        createCustomSetPOValidationError();
        
        
        
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => act.Id
                };
                    Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt;
        
        Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'Standalone',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit',
                'ProductCode' => 'test xyz1'
                };
                    
                    Map<String, Object> prdMap1 = new Map<String, Object> {
                        'Name' => 'Subscription', 
                            'IsActive' => true, 
                            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                            'SBQQ__SubscriptionTerm__c' => 12, 
                            'SBQQ__SubscriptionType__c' => 'Renewable',
                            'ProductCode' => 'test xyz'
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
        pbeSubs.Pricebook2id = system.label.CPQPricebookID;
        
        pBList.add(pbeSubs);
        insert pBList;
        
        
        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => act.Id,
                'RecordTypeId' => Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId()
                };
                    Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        opp.Distributor_Lookup__c =act.id;
        opp.Pricebook2id = system.label.CPQPricebookID;
        insert opp;
        
        
        
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__SubscriptionTerm__c = 36;
        qt.SBQQ__PaymentTerms__c = 'Net 45';
        
        insert qt; 
        
        
        FlowControll.AccountTrigger = true;
        FlowControll.opportunityTriggerHandler = true;
        
        
        //the JSON formatted String representing the quote model to add a product to
        String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', qt.id);
        String currencyCode = 'USD';
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
        Test.startTest();
        update qt;
        
        SBQQ__Quote__c qtq =[select id,name,SBQQ__NetAmount__c,SBQQ__PricebookId__c from SBQQ__Quote__c where id=:qt.id ];
        
        List<SBQQ__QuoteLine__c> qliList =[select id,SBQQ__NetPrice__c,SBQQ__NetTotal__c,SBQQ__Product__r.productcode,SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c, SBQQ__Product__c   from SBQQ__QuoteLine__c where  SBQQ__Quote__c =:qt.id];
        
        
       
        
        List<PO_Stage__c> poStageList = new List<PO_Stage__c>();
        PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.','test123',system.today().addDays(10),2,'test@test.com','test partner',system.today(),1,'test12345',qtq.name,qliList[0].SBQQ__NetTotal__c);
        pos.Bill_To_Name__c=act.Id;
        pos.Payment_schedule_type__c = 'test';
        poStageList.add(pos);
        
        PO_Stage__c pos1 = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.','test1234',system.today().addDays(10),2,'test@test.com','test partner',system.today(),2,'test12345',qtq.name,qliList[1].SBQQ__NetTotal__c);
        pos1.Bill_To_Name__c=act.Id;
        pos1.Payment_schedule_type__c = 'test';
        poStageList.add(pos1);
        
        insert poStageList;
        
        List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>();
        
        
        for(integer i=0;i<qliList.size();i++){
            string ediLinenum = 0+''+i;
            PO_Item_Stage__c poi;
            if(i==0){
                poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos.id,qliList[i].
                SBQQ__SubscriptionTerm__c,qliList[i].SBQQ__NetPrice__c);
                poi.ProductCode__c = 'RBK-CONSULT';}
            else{ 
                poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos1.id,qliList[i].SBQQ__SubscriptionTerm__c,qliList[i].SBQQ__NetPrice__c);
                poi.ProductCode__c = 'RBK-TRAVEL-EXPENSES';}
            
            poItem.add(poi);
        }
        //PO_Item_Stage__c poi = ShGl_TestFactoryHelper.createPOItem('1234','01',prdHW.productcode,10,pos.id,null,(qtq.SBQQ__NetAmount__c/10));
        
        insert poItem;
        
        List<PO_Stage_Address__c> poAs = new List<PO_Stage_Address__c>();
        PO_Stage_Address__c spa = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com',pos.id,'292005','test','test2');
        poAs.add(spa);
        PO_Stage_Address__c spa1 = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com',pos1.id,'292005','test','test2');
        poAs.add(spa1);
        insert poAs;
          
        List<PO_Stage__c> upStageList = new  List<PO_Stage__c>();
        pos.PO_Validation_Status__c='Staged';
        
        upStageList.add(pos);
        pos1.PO_Validation_Status__c='Staged';
        
       POStageHelper.allStagePOmap.clear(); 
        POStageHelper.quoteMap.clear();
          upStageList.add(pos1);
        update upStageList;
                
        poStageList = [select id,PO_Validation_Status__c from PO_Stage__c where id=: pos.id];
        
        Test.stopTest();
    }
    }
    /**
    * @author Siva Kumar
    * @date 12-03-2025
    * @description Added to check only consult sku
    */
    static testMethod void testMethodOnlyConsult() {
        FlowControll.AccountTrigger = false;
        FlowControll.opportunityTriggerHandler = false;

        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_QuoteLine_Validation_Rules__c =  true, Disable_SBQQ_Quote_Triggers__c = true,Disable_SBQQ_Quote_Validation_Rules__c = true);
        insert disableLogic;
        
        ShGl_TestFactoryHelper.insertTriggerControls();
        System.runAs(new User(Id=UserInfo.getUSerId())) {
        //Generate the Account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.name='Promark Technology, Inc.';
        act.Type ='Distributor';
        act.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        act.Contract_Status__c = 'Pending';
        insert act;
            Assert.areEqual('Promark Technology, Inc.', act.name);
            act.Id = getPromarkAccount().Sfdc_Id__c;
        update act;
        
        //Create custom setting record for promark EDI Process
        SkipManualOrder__c cusset = new SkipManualOrder__c();
        cusset.Account_Id__c =act.id;
        cusset.Enabled__c = true;
        cusset.name='Promark Technology, Inc.';
        insert cusset;
        
        createCustomSetPOValidationError();
        
        
        
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => act.Id
                };
                    Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt;
        
        Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'Standalone',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit',
                'ProductCode' => 'test xyz1'
                };
                    
                    Map<String, Object> prdMap1 = new Map<String, Object> {
                        'Name' => 'Subscription', 
                            'IsActive' => true, 
                            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                            'SBQQ__SubscriptionTerm__c' => 12, 
                            'SBQQ__SubscriptionType__c' => 'Renewable',
                            'ProductCode' => 'test xyz'
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
        pbeSubs.Pricebook2id = system.label.CPQPricebookID;
        
        pBList.add(pbeSubs);
        insert pBList;
         
        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => act.Id,
                'RecordTypeId' => Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId()
                };
                    Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        opp.Distributor_Lookup__c =act.id;
        opp.Pricebook2id = system.label.CPQPricebookID;
        insert opp;
        
        
        
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__SubscriptionTerm__c = 36;
        qt.SBQQ__PaymentTerms__c = 'Net 45';
        
        insert qt; 
        
        
        FlowControll.AccountTrigger = true;
        FlowControll.opportunityTriggerHandler = true;
        
        
        //the JSON formatted String representing the quote model to add a product to
        String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', qt.id);
        String currencyCode = 'USD';
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
        
        //the JSON formatted String represeting the saved quote
        String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
        
        
        QuoteCalculator calculator = new QuoteCalculator();
        calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
        
        qt.ApprovalStatus__c = 'Approved';
        Test.startTest();
        update qt;
                
        SBQQ__Quote__c qtq =[select id,name,SBQQ__NetAmount__c,SBQQ__PricebookId__c from SBQQ__Quote__c where id=:qt.id ];
        
        List<SBQQ__QuoteLine__c> qliList =[select id,SBQQ__NetPrice__c,SBQQ__NetTotal__c,SBQQ__Product__r.productcode,SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c, SBQQ__Product__c   from SBQQ__QuoteLine__c where  SBQQ__Quote__c =:qt.id];
        
        List<PO_Stage__c> poStageList = new List<PO_Stage__c>();
        PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.','test123',system.today().addDays(10),2,'test@test.com','test partner',system.today(),1,'test12345',qtq.name,qliList[0].SBQQ__NetTotal__c);
        pos.Bill_To_Name__c=act.Id;
        pos.Payment_schedule_type__c = 'test';
        poStageList.add(pos);
        
        PO_Stage__c pos1 = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.','test1234',system.today().addDays(10),2,'test@test.com','test partner',system.today(),2,'test12345',qtq.name,qliList[1].SBQQ__NetTotal__c);
        pos1.Bill_To_Name__c=act.Id;
        pos1.Payment_schedule_type__c = 'test';
        poStageList.add(pos1);
        
        insert poStageList;
        
        List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>();
          
        for(integer i=0;i<qliList.size();i++){
            
            string ediLinenum = 0+''+i;
            PO_Item_Stage__c poi;
            if(i==0){
                poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos.id,qliList[i].
                SBQQ__SubscriptionTerm__c,qliList[i].SBQQ__NetPrice__c);
                poi.ProductCode__c = 'RBK-CONSULT';}
            else{ 
                poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos1.id,qliList[i].SBQQ__SubscriptionTerm__c,qliList[i].SBQQ__NetPrice__c);
                poi.ProductCode__c = 'RBK-CONSULT';}
            
            poItem.add(poi);
        }
        
        insert poItem;
        
        List<PO_Stage_Address__c> poAs = new List<PO_Stage_Address__c>();
        PO_Stage_Address__c spa = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com',pos.id,'292005','test','test2');
        poAs.add(spa);
        PO_Stage_Address__c spa1 = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com',pos1.id,'292005','test','test2');
        poAs.add(spa1);
        insert poAs;
        
        List<PO_Stage__c> upStageList = new  List<PO_Stage__c>();
        pos.PO_Validation_Status__c='Staged';
        
        upStageList.add(pos);
        pos1.PO_Validation_Status__c='Staged';
       POStageHelper.allStagePOmap.clear(); 
        POStageHelper.quoteMap.clear();
          upStageList.add(pos1);
        update upStageList;
                
        poStageList = [select id,PO_Validation_Status__c from PO_Stage__c where id=: pos.id];
        
        Test.stopTest();
    }
    }
    /**
    * @author Siva Kumar
    * @date 12-03-2025
    * @description Added to check stage amount greater than quote
    */
    static testMethod void testMethodError() {

        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_QuoteLine_Validation_Rules__c= true, Disable_SBQQ_Quote_Triggers__c = true,Disable_SBQQ_Quote_Validation_Rules__c = true);
        insert disableLogic;

        FlowControll.AccountTrigger = false;
        FlowControll.opportunityTriggerHandler = false;
        ShGl_TestFactoryHelper.insertTriggerControls();
        System.runAs(new User(Id=UserInfo.getUSerId())) {
        //Generate the Account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.name='Promark Technology, Inc.';
        act.Type ='Distributor';
        act.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        act.Contract_Status__c = 'Pending';
        insert act;
            Assert.areEqual('Promark Technology, Inc.', act.name);
            act.Id = getPromarkAccount().Sfdc_Id__c;
        //Create custom setting record for promark EDI Process
        SkipManualOrder__c cusset = new SkipManualOrder__c();
        cusset.Account_Id__c =act.id;
        cusset.Enabled__c = true;
        cusset.name='Promark Technology, Inc.';
        insert cusset;
        
        createCustomSetPOValidationError();
        
        
        
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => act.Id
                };
                    Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt;
        
        Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'Standalone',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit',
                'ProductCode' => 'test xyz1'
                };
                    
                    Map<String, Object> prdMap1 = new Map<String, Object> {
                        'Name' => 'Subscription', 
                            'IsActive' => true, 
                            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                            'SBQQ__SubscriptionTerm__c' => 12, 
                            'SBQQ__SubscriptionType__c' => 'Renewable',
                            'ProductCode' => 'test xyz'
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
        pbeSubs.Pricebook2id = system.label.CPQPricebookID;
        
        pBList.add(pbeSubs);
        insert pBList;
        
        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => act.Id,
                'RecordTypeId' => Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId()
                };
                    Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        opp.Distributor_Lookup__c =act.id;
        opp.Pricebook2id = system.label.CPQPricebookID;
        insert opp;
        
        
        
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id; 
        qt.SBQQ__Opportunity2__c = opp.Id; 
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__SubscriptionTerm__c = 36;
        qt.SBQQ__PaymentTerms__c = 'Net 45';
        
        insert qt; 
        
        
        FlowControll.AccountTrigger = true;
        FlowControll.opportunityTriggerHandler = true;
        
        
        //the JSON formatted String representing the quote model to add a product to
        String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', qt.id);
        String currencyCode = 'USD';
        //the JSON formatted String representing the product to be added to the quote.
        String productModel = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdSubs.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
        String productModel2 = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdHW.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
        
        List<ProductModel> productModels = new List<ProductModel>();
        productModels.add((ProductModel) JSON.deserialize(productModel, ProductModel.class));
        productModels.add((ProductModel) JSON.deserialize(productModel2, ProductModel.class));
        ProductAdder adder = new ProductAdder();
        QuoteModel quoteWithProducts = adder.add((QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class), productModels, 0);
        quoteWithProducts.lineItems[0].record.SBQQ__Quantity__c = 10;
        quoteWithProducts.lineItems[1].record.SBQQ__Quantity__c = 20;
          
        //the JSON formatted String represeting the saved quote
        String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
        
        
        QuoteCalculator calculator = new QuoteCalculator();
        calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
        
        qt.ApprovalStatus__c = 'Approved';
        
        Test.startTest();
        update qt;
          
        SBQQ__Quote__c qtq =[select id,name,SBQQ__NetAmount__c,SBQQ__PricebookId__c from SBQQ__Quote__c where id=:qt.id ];
        
        List<SBQQ__QuoteLine__c> qliList =[select id,SBQQ__NetPrice__c,SBQQ__NetTotal__c,SBQQ__Product__r.productcode,SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c, SBQQ__Product__c   from SBQQ__QuoteLine__c where  SBQQ__Quote__c =:qt.id];
        
        
        
        
        List<PO_Stage__c> poStageList = new List<PO_Stage__c>();
        PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.','test123',system.today().addDays(10),2,'test@test.com','test partner',system.today(),1,'test12345',qtq.name,qliList[0].SBQQ__NetTotal__c);
        pos.Bill_To_Name__c=act.Id;
        pos.TotalAmount__c = qtq.SBQQ__NetAmount__c + 1000000;
        pos.Payment_schedule_type__c = 'test';
        poStageList.add(pos);
        
        PO_Stage__c pos1 = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.','test1234',system.today().addDays(10),2,'test@test.com','test partner',system.today(),2,'test12345',qtq.name,qliList[1].SBQQ__NetTotal__c);
        pos1.Bill_To_Name__c=act.Id;
        pos1.Payment_schedule_type__c = 'test';
        poStageList.add(pos1);
        
        insert poStageList;
        
        List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>();
        
        for(integer i=0;i<qliList.size();i++){
            string ediLinenum = 0+''+i;
            PO_Item_Stage__c poi;
            if(i==0){
                poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos.id,qliList[i].
                SBQQ__SubscriptionTerm__c,qliList[i].SBQQ__NetPrice__c);
                poi.ProductCode__c = 'RBK-CONSULT';}
            else{ 
                poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos1.id,qliList[i].SBQQ__SubscriptionTerm__c,qliList[i].SBQQ__NetPrice__c);
                poi.ProductCode__c = 'RBK-TRAVEL-EXPENSES';}
            
            poItem.add(poi);
        }
        
        insert poItem;
        
        List<PO_Stage_Address__c> poAs = new List<PO_Stage_Address__c>();
        PO_Stage_Address__c spa = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com',pos.id,'292005','test','test2');
        poAs.add(spa);
        PO_Stage_Address__c spa1 = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com',pos1.id,'292005','test','test2');
        poAs.add(spa1);
        insert poAs;
        
        List<PO_Stage__c> upStageList = new  List<PO_Stage__c>();
        pos.PO_Validation_Status__c='Staged';
        
        upStageList.add(pos);
        pos1.PO_Validation_Status__c='Staged';
        POStageHelper.allStagePOmap.clear(); 
        POStageHelper.quoteMap.clear(); 
        upStageList.add(pos1);
        update upStageList;
                
        poStageList = [select id,PO_Validation_Status__c from PO_Stage__c where id=: pos.id];
        
        Test.stopTest();
    }
    }
    /**
    * @author Siva Kumar
    * @date 12-03-2025
    * @description Added to cover netapp changes 
    */
    static testMethod void testNetappSplitOrderBatch() {
        SBQQ.TriggerControl.disable();
        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_QuoteLine_Validation_Rules__c =  true, Disable_Opportunity_Validation_Rules__c = true,Disable_Opportunity_Triggers__c =true,Disable_SBQQ_Quote_Triggers__c = true,Disable_SBQQ_Quote_Validation_Rules__c = true, Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_Order_Old_Trigger__c = true, Disable_Account_Triggers__c = true);
        insert disableLogic;
        FlowControll.opportunityTriggerHandler = false;
        System.runAs(new User(Id=UserInfo.getUSerId())) {
        Id accDistiRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Map<String, Object> accMap = new Map<String, Object> {
            'RecordtypeId' => accDistiRecTypeId ,
            'Type' =>'Distributor'
        };
      
        List<account> accList = (List<account>) ShGl_TestFactory.createSObjectList(new Account(),2,accMap); 
        accList[0].name='Promark Technology, Inc.';
        accList[1].name='Net app, Inc.';
        
        insert accList;
            Assert.areEqual('Promark Technology, Inc.', accList[0].name);
            accList[0].Id = getPromarkAccount().Sfdc_Id__c;
        update accList;
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => accList[0].Id
        };
        Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt;
        
        Opportunity opp = new Opportunity(
            AccountId = accList[0].Id,
            Name = 'Test',
            CloseDate = System.today().addMonths(12),
            StageName = 'Test',
            Pricebook2Id = Test.getStandardPricebookId(),
            Distributor_Lookup__c = accList[0].Id,
            Partner_Lookup__c = accList[0].id,
            Alliance_Partner_Name__c='Amazon',
            Alliance_Source_Type__c='Alliance Initiated Deal');
        insert opp;

        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__StartDate__c = System.today(),
            SBQQ__SubscriptionTerm__c = 12,
            SBQQ__Primary__c = true,
            SBQQ__PriceBook__c = Test.getStandardPricebookId());
        insert quote;

        List<Product2> sampleProducts = new List<Product2>{
                // 0
                new Product2(
                    Name = 'CPQ Bundle Product',
                    ProductCode = 'CPQ Bundle Product',
                    Product_Type__c = 'Foundation Edition',
                    IsActive = true,
                    SBQQ__Hidden__c = true,
                    Support_Type__c = 'L3',
                    SBQQ__ExcludeFromOpportunity__c = true,
                    New_CPQ_Product__c = true
                ),
                // 1
                new Product2(
                    Name = 'RBK-R344-01',
                    ProductCode = 'RBK-R344-01',
                    Category__c = 'Platform',
                    Family = 'r300',
                    Product_Type__c = 'Appliance',
                    Appliance_Model__c='RBK-R344',
                    Appliance_Model_HW__c = 'RBK-R344',
                    SBQQ__AssetConversion__c = null,
                    SBQQSC__EntitlementConversion__c = 'None',
                    Create_Asset_Entitlement__c = true,
                    IsActive = true,
                    Support_Type__c = 'L3',
                    Asset_Priority__c = 0,
                    New_CPQ_Product__c = true,
                    GPL_Name__c = 'NetApp'
                ),
                // 2
                new Product2(
                    Name = 'RBK-SVC-PREM-APPLIANCE',
                    ProductCode = 'RBK-SVC-PREM-APPLIANCE',
                    Category__c = 'Support',
                    Product_Type__c = 'HW Support',
                    SBQQ__AssetConversion__c = 'None',
                    SBQQSC__EntitlementConversion__c = 'One per unit',
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 12,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable',
                    IsActive = true,
                    Support_Type__c = 'L3',
                    Asset_Priority__c = 1,
                    New_CPQ_Product__c = true
                ),
                // 3
                new Product2(
                    Name = 'RBK-POLARIS-GPS',
                    ProductCode = 'RBK-POLARIS-GPS',
                    Category__c = 'SaaS',
                    Family = 'POLARIS',
                    Product_Type__c = 'O365',
                    SBQQ__AssetConversion__c = 'None',
                    SBQQSC__EntitlementConversion__c = 'One per unit',
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 12,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable',
                    IsActive = true,
                    Support_Type__c = 'L3',
                    Asset_Priority__c = 2,
                    New_CPQ_Product__c = true
                ),
                // 4
                new Product2(
                    Name = 'RBK-CLOUT-UNLIMITED',
                    ProductCode = 'RBK-CLOUT-UNLIMITED',
                    Category__c = 'Software',
                    Family = 'CLOUT',
                    Product_Type__c = null,
                    SBQQ__AssetConversion__c = 'None',
                    SBQQSC__EntitlementConversion__c = 'One per unit',
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 12,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable',
                    IsActive = true,
                    Support_Type__c = 'L3',
                    Asset_Priority__c = 2,
                    New_CPQ_Product__c = true
                ),
                // 5
                new Product2(
                    Name = 'RBK-F3M-CBL-01',
                    ProductCode = 'RBK-F3M-CBL-01',
                    Category__c = 'Platform',
                    Family = 'CABLE',
                    Product_Type__c = 'Accessories',
                    SBQQ__AssetConversion__c = null,
                    SBQQSC__EntitlementConversion__c = 'None',
                    SBQQ__SubscriptionPricing__c = null,
                    SBQQ__SubscriptionTerm__c = null,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = null,
                    IsActive = true,
                    Support_Type__c = 'L3',
                    Asset_Priority__c = null,
                    New_CPQ_Product__c = true,
                    GPL_Name__c = 'NetApp'
                ),
                // 6
                new Product2(
                    Name = 'RBK-SFP-TSR-01',
                    ProductCode = 'RBK-SFP-TSR-01',
                    Category__c = 'Platform',
                    Family = 'SFP',
                    Product_Type__c = 'Accessories',
                    SBQQ__AssetConversion__c = null,
                    SBQQSC__EntitlementConversion__c = 'None',
                    SBQQ__SubscriptionPricing__c = null,
                    SBQQ__SubscriptionTerm__c = null,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = null,
                    IsActive = true,
                    Support_Type__c = 'L3',
                    Asset_Priority__c = 0,
                    New_CPQ_Product__c = true
                ),
                // 7
                new Product2(
                    Name = 'RBK-HDD-4TB-01',
                    ProductCode = 'RBK-HDD-4TB-01',
                    Category__c = 'Platform',
                    Family = 'r300',
                    Product_Type__c = 'Spares',
                    SBQQ__AssetConversion__c = null,
                    SBQQSC__EntitlementConversion__c = 'None',
                    SBQQ__SubscriptionPricing__c = null,
                    SBQQ__SubscriptionTerm__c = null,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable',
                    Create_Asset__c = true,
                    IsActive = true,
                    Asset_Priority__c = 0,
                    Support_Type__c = 'L3',
                    New_CPQ_Product__c = true
                ),
                // 8
                new Product2(
                    Name = 'RBK-NRD-R300',
                    ProductCode = 'RBK-NRD-R300',
                    Category__c = 'Support',
                    Family = 'Non-Returnable Disk Service',
                    Product_Type__c = null,
                    SBQQ__AssetConversion__c = 'None',
                    SBQQSC__EntitlementConversion__c = 'One per unit',
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 12,
                    SBQQ__SubscriptionBase__c = 'List',
                    Support_Type__c = 'L3',
                    SBQQ__SubscriptionType__c = 'Renewable',
                    IsActive = true,
                    Asset_Priority__c = 1,
                    New_CPQ_Product__c = true
                ),
                // 9
                new Product2(
                    Name = 'RBK-OBJ-STORAGE',
                    ProductCode = 'RBK-OBJ-STORAGE',
                    Category__c = 'Software',
                    Family = 'OBJ',
                    Product_Type__c = null,
                    SBQQ__AssetConversion__c = 'None',
                    SBQQSC__EntitlementConversion__c = 'None',
                    SBQQ__SubscriptionPricing__c = null,
                    SBQQ__SubscriptionTerm__c = null,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = null,
                    IsActive = true,
                    Support_Type__c = 'L3',
                    Asset_Priority__c = null,
                    New_CPQ_Product__c = true
                ),
                // 10
                new Product2(
                    Name = 'RBK-CONSULT',
                    ProductCode = 'RBK-CONSULT',
                    Category__c = 'Professional Services',
                    Product_Type__c = null,
                    SBQQ__AssetConversion__c = 'None',
                    SBQQSC__EntitlementConversion__c = 'None',
                    SBQQ__SubscriptionPricing__c = null,
                    SBQQ__SubscriptionTerm__c = null,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = null,
                    IsActive = true,
                    Support_Type__c = 'L3',
                    Asset_Priority__c = null,
                    New_CPQ_Product__c = true
                )
        };
        insert sampleProducts;

        List<PricebookEntry>entries = new List<PricebookEntry>();

        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[0].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[1].Id, IsActive = true, UnitPrice = 200));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[2].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[3].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[4].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[5].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[6].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[7].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[8].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[9].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[10].Id, IsActive = true, UnitPrice = 100));
        insert entries;

        List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[0].Id, SBQQ__PricebookEntryId__c = entries[0].Id, SBQQ__Quantity__c = 1,  SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(GPL_Name__c = 'NetApp', SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[1].Id, SBQQ__PricebookEntryId__c = entries[1].Id, SBQQ__Quantity__c = 15, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[2].Id, SBQQ__PricebookEntryId__c = entries[2].Id, SBQQ__Quantity__c = 15, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[3].Id, SBQQ__PricebookEntryId__c = entries[3].Id, SBQQ__Quantity__c = 15, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[4].Id, SBQQ__PricebookEntryId__c = entries[4].Id, SBQQ__Quantity__c = 15, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c( GPL_Name__c = 'NetApp',SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[5].Id, SBQQ__PricebookEntryId__c = entries[5].Id,  SBQQ__Quantity__c = 15, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[6].Id, SBQQ__PricebookEntryId__c = entries[6].Id,  SBQQ__Quantity__c = 15, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[7].Id, SBQQ__PricebookEntryId__c = entries[7].Id, SBQQ__Quantity__c = 15, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[8].Id, SBQQ__PricebookEntryId__c = entries[8].Id, SBQQ__Quantity__c = 15, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[9].Id, SBQQ__PricebookEntryId__c = entries[9].Id, SBQQ__Quantity__c = 15, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[10].Id, SBQQ__PricebookEntryId__c = entries[10].Id, SBQQ__Quantity__c = 15, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        insert lines;

        lines[0].SBQQ__Bundle__c = true;
        lines[1].SBQQ__RequiredBy__c = lines[0].Id;
        lines[2].SBQQ__RequiredBy__c = lines[1].Id;
        lines[3].SBQQ__RequiredBy__c = lines[1].Id;
        lines[4].SBQQ__RequiredBy__c = lines[1].Id;
        lines[5].SBQQ__RequiredBy__c = lines[1].Id;
        lines[6].SBQQ__RequiredBy__c = lines[1].Id;
        lines[7].SBQQ__RequiredBy__c = lines[1].Id;
        lines[8].SBQQ__RequiredBy__c = lines[1].Id;
        lines[9].SBQQ__RequiredBy__c = lines[1].Id;
        lines[10].SBQQ__RequiredBy__c = lines[1].Id;
        update lines;
        
        quote.ApprovalStatus__c = 'Approved';
        update quote;
        
        opp.StageName ='6 PO With Channel';
        opp.SBQQ__PrimaryQuote__c = quote.id;
        opp.Pricebook2Id = Test.getStandardPricebookId();
        opp.Polaris_Region__c = 'US';
        //opp.SBQQ__Ordered__c = true;
        //update opp;
        
        opp.SBQQ__Ordered__c = true;
        //update opp;
        
        //FlowControll.opportunityTriggerHandler = true;
        
        SBQQ__Quote__c qtq =[select id,name,SBQQ__NetAmount__c,SBQQ__PricebookId__c,(select id,SBQQ__NetPrice__c,SBQQ__NetTotal__c,SBQQ__Product__r.productcode,SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c, SBQQ__Product__c,SBQQ__PricebookEntryId__c from SBQQ__LineItems__r) from SBQQ__Quote__c where id=:quote.id ];
        
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c>(qtq.SBQQ__LineItems__r);
        Map<String, Object>  OrderMap = new Map<String, Object> {
            'Type' => 'Revenue',
            'AccountId' => accList[0].Id,
            'OpportunityId' => opp.Id,
            'Sync_to_NetSuite__c' => true,
            'EffectiveDate' => system.today(),
            'Status' => 'Pending',
            'Sell_to_Partner__c'=>accList[1].Id,
            'Bill_To_Name__c'=>accList[0].Id,
            'SBQQ__Quote__c'=>quote.id  
            };
            
        Order ord = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
    
        test.startTest();
        insert Ord;

        List<OrderItem> lstOrdrItems = new List<OrderItem>(); 
      
        for(integer i=0;i<qliList.size();i++){
            lstOrdrItems.add(new OrderItem( SBQQ__QuotedQuantity__c = qliList[i].SBQQ__Quantity__c,/* SBQQ__OrderedQuantity__c = qliList[i].SBQQ__Quantity__c, */OrderId = Ord.Id, Quantity = qliList[i].SBQQ__Quantity__c, PricebookEntryId = qliList[i].SBQQ__PricebookEntryId__c, unitprice =qliList[i].SBQQ__NetPrice__c,Sales_Price__c = qliList[i].SBQQ__NetPrice__c,SBQQ__QuoteLine__c=qliList[i].id, SBQQ__SubscriptionTerm__c =qliList[i].SBQQ__SubscriptionTerm__c));
        }
        insert lstOrdrItems;

        Integer count = 0;
        for(OrderItem OI : lstOrdrItems){
            count ++;
            if(count  <=2 ) continue;
            OI.SBQQ__RequiredBy__c = lstOrdrItems[1].Id; 
        }   
        
        update lstOrdrItems;
        Ord.Order_Split_Type__c = 'Netapp';
        Ord.Order_Status__c = 'Pending';
        Ord.Hold_Code__c = '';
        update Ord;
        SplitOrder scbat = new SplitOrder();
        string jobID =Database.executeBatch(scbat,1);
        Test.StopTest();
    }
    }
    /**
    * @author Siva Kumar
    * @date 12-03-2025
    * @description Added to cover netapp changes 
    */
    static testMethod void testNetappSplitOrderBatchV2() {
        SBQQ.TriggerControl.disable();
        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_QuoteLine_Validation_Rules__c =  true, Disable_SBQQ_Quote_Validation_Rules__c = true,Disable_Opportunity_Validation_Rules__c = true,Disable_Opportunity_Triggers__c =true,Disable_SBQQ_Quote_Triggers__c = true, Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_Order_Old_Trigger__c = true, Disable_Account_Triggers__c = true);
        insert disableLogic;
        FlowControll.opportunityTriggerHandler = false;
        System.runAs(new User(Id=UserInfo.getUSerId())) {
        Id accDistiRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Map<String, Object> accMap = new Map<String, Object> {
            'RecordtypeId' => accDistiRecTypeId ,
            'Type' =>'Distributor'
        };
      
        List<account> accList = (List<account>) ShGl_TestFactory.createSObjectList(new Account(),2,accMap); 
        accList[0].name='Promark Technology, Inc.';
        accList[1].name='Net app, Inc.';
        insert accList;
            Assert.areEqual('Promark Technology, Inc.', accList[0].name);
            accList[0].Id = getPromarkAccount().Sfdc_Id__c;
        update accList;

        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => accList[0].Id
        };
        Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt;
        
        Opportunity opp = new Opportunity(
            AccountId = accList[0].Id,
            Name = 'Test',
            CloseDate = System.today().addMonths(12),
            StageName = 'Test',
            Pricebook2Id = Test.getStandardPricebookId(),
            Distributor_Lookup__c = accList[0].Id,
            Partner_Lookup__c = accList[0].id,
            Alliance_Partner_Name__c='Amazon',
            Alliance_Source_Type__c='Alliance Initiated Deal');
        insert opp;

        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__StartDate__c = System.today(),
            SBQQ__SubscriptionTerm__c = 12,
            SBQQ__Primary__c = true,
            Is_RWD_Polaris_Quote__c = true,
            SBQQ__PriceBook__c = Test.getStandardPricebookId());
        insert quote;

        List<Product2> sampleProducts = new List<Product2>{
                // 0
                new Product2(
                    Name = 'RS-BT-FE-PE-PP',
                    ProductCode = 'RS-BT-FE-PE-PP',
                    Product_Level__c = 'Hybrid Software',
                    IsActive = true,
                    SBQQ__Hidden__c = true,
                    Support_Type__c = 'Premium',
                    SBQQ__ExcludeFromOpportunity__c = true,
                    New_CPQ_Product__c = true,
                    GPL_Name__c = 'NetApp'
                ),
                // 1
                new Product2(
                    Name = 'RH-6416S-02',
                    ProductCode = 'RH-6416S-02',
                    Category__c = 'Platform',
                    Family = 'R6000',
					Usable_Capacity__c = 50,
                    Product_Type__c = 'Hardware',
                    Product_Level__c = 'Hardware',
                    Appliance_Model__c='RBK-R6416S',
                    Appliance_Model_HW__c = 'RBK-R6416S',
                    SBQQ__AssetConversion__c = null,
                    SBQQSC__EntitlementConversion__c = 'None',
                    Create_Asset_Entitlement__c = true,
                    IsActive = true,
                    Asset_Priority__c = 0,
                    New_CPQ_Product__c = true,
                    GPL_Name__c = 'NetApp'
                ),
                // 2
                new Product2(
                    Name = 'RS-HW-SVC-PE',
                    ProductCode = 'RS-HW-SVC-PE',
                    Category__c = 'Support',
                    Product_Type__c = 'HW Support',
					Product_Level__c = 'Support',
                    SBQQ__AssetConversion__c = 'None',
                    SBQQSC__EntitlementConversion__c = 'One per unit',
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 12,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable',
                    IsActive = true,
                    Support_Type__c = 'L3',
                    Asset_Priority__c = 1,
                    New_CPQ_Product__c = true,
                    GPL_Name__c = 'NetApp'
                ),
				//3
				new Product2(
                    Name = 'Professional-Services',
                    ProductCode = 'Professional-Services',
                    Category__c = 'Professional Services',
                    Product_Type__c = '',
					Product_Level__c = '',
                    SBQQ__AssetConversion__c = 'None',
                    SBQQSC__EntitlementConversion__c = null,
                    SBQQ__SubscriptionPricing__c = null,
                    SBQQ__SubscriptionTerm__c = null,
                    SBQQ__SubscriptionBase__c = null,
                    SBQQ__SubscriptionType__c = null,
                    IsActive = true,
                    New_CPQ_Product__c = true,
                    GPL_Name__c = 'NetApp'
                ),
				//4
				new Product2(
                    Name = 'RC-F3M-CBL-01',
                    ProductCode = 'RC-F3M-CBL-01',
                    Category__c = 'Platform',
                    Product_Type__c = 'Accessories',
					Product_Level__c = 'Hardware',
					Family = 'CABLE',
                    SBQQ__AssetConversion__c = 'None',
                    SBQQSC__EntitlementConversion__c = 'One per unit',
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 12,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable',
                    IsActive = true,
                    Support_Type__c = null,
                    Asset_Priority__c = 1,
                    New_CPQ_Product__c = true,
                    GPL_Name__c = 'NetApp'
                ),
				//5
				new Product2(
                    Name = 'RS-BT-NDA-PE-PP',
                    ProductCode = 'RS-BT-NDA-PE-PP',
                    Category__c = 'Software',
                    Product_Type__c = 'NAS',
					Product_Level__c = 'SaaS Software Addon',
					Family = 'POLARIS',
                    SBQQ__AssetConversion__c = 'None',
                    SBQQSC__EntitlementConversion__c = 'One per quote line',
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 1,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable',
                    IsActive = true,
                    Support_Type__c = null,
                    Asset_Priority__c = 1,
                    New_CPQ_Product__c = true,
                    GPL_Name__c = 'NetApp'
                ),
				//6
				new Product2(
                    Name = 'RS-NRD-R6000S',
                    ProductCode = 'RS-NRD-R6000S',
                    Category__c = 'Support',
                    Product_Type__c = null,
					Product_Level__c = null,
					Family = 'Non-Returnable Disk Service',
                    SBQQ__AssetConversion__c = 'None',
                    SBQQSC__EntitlementConversion__c = 'One per unit',
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 1,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable',
                    IsActive = true,
                    Support_Type__c = null,
                    Asset_Priority__c = 1,
                    New_CPQ_Product__c = true,
                    GPL_Name__c = 'NetApp'
                ),
                //7
                new Product2(
                    Name = 'SAAS',
                    ProductCode = 'SAAS',
                    License_Category__c = 'SaaS',
                    Category__c = 'Platform',
                    Product_Type__c = 'Accessories',
					Product_Level__c = 'Hardware',
					Family = 'SFP',
                    SBQQ__AssetConversion__c = 'None',
                    SBQQSC__EntitlementConversion__c = null,
                    SBQQ__SubscriptionPricing__c = null,
                    SBQQ__SubscriptionTerm__c = 1,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = null,
                    IsActive = true,
                    Support_Type__c = null,
                    Asset_Priority__c = 1,
                    New_CPQ_Product__c = true,
                    GPL_Name__c = 'NetApp'
                ),
                   //8
                   new Product2(
                    Name = 'RS-BT-RCDM-T',
                    ProductCode = 'RS-BT-RCDM-T',
                    License_Category__c = 'On Prem',
                    Category__c = 'Software',
					Product_Level__c = 'OnPrem',
					Family = 'OnPrem',
                    SBQQSC__EntitlementConversion__c = 'One per quote line',
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 1,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'One-time',
                    IsActive = true,
                    Support_Type__c = 'Premium',
                    New_CPQ_Product__c = false,
                    GPL_Name__c = 'NetApp'
                ),
                //9
                new Product2(
                    Name = 'RS-BT-NDA-PE-PP',
                    ProductCode = 'RS-BT-NDA-PE-PP',
                    Category__c = 'Software',
                    Product_Type__c = 'NAS',
					Product_Level__c = 'SaaS Software Addon',
                    License_Category__c = 'SaaS',
					Family = 'POLARIS',
                    SBQQ__AssetConversion__c = 'None',
                    SBQQSC__EntitlementConversion__c = 'One per quote line',
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 1,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable',
                    IsActive = true,
                    Support_Type__c = null,
                    Asset_Priority__c = 1,
                    New_CPQ_Product__c = true,
                    GPL_Name__c = 'NetApp'
                )
        };
        insert sampleProducts;

        List<PricebookEntry>entries = new List<PricebookEntry>();

        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[0].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[1].Id, IsActive = true, UnitPrice = 200));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[2].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[3].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[4].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[5].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[6].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[7].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[8].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[9].Id, IsActive = true, UnitPrice = 100));
        insert entries;

        List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
        lines.add(new SBQQ__QuoteLine__c(GPL_Name__c = 'NetApp', SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[0].Id, SBQQ__PricebookEntryId__c = entries[0].Id, SBQQ__Quantity__c = 300,  SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = 1, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(GPL_Name__c = 'NetApp', SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[1].Id, SBQQ__PricebookEntryId__c = entries[1].Id, SBQQ__Quantity__c = 6, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(GPL_Name__c = 'NetApp', SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[2].Id, SBQQ__PricebookEntryId__c = entries[2].Id, SBQQ__Quantity__c = 6, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = 1, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(GPL_Name__c = 'NetApp', SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[3].Id, SBQQ__PricebookEntryId__c = entries[3].Id, SBQQ__Quantity__c = 6, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(GPL_Name__c = 'NetApp', SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[4].Id, SBQQ__PricebookEntryId__c = entries[4].Id, SBQQ__Quantity__c = 6, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(GPL_Name__c = 'NetApp', SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[5].Id, SBQQ__PricebookEntryId__c = entries[5].Id,  SBQQ__Quantity__c = 6, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(GPL_Name__c = 'NetApp', SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[6].Id, SBQQ__PricebookEntryId__c = entries[6].Id,  SBQQ__Quantity__c = 6, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(GPL_Name__c = 'NetApp', SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[7].Id, SBQQ__PricebookEntryId__c = entries[7].Id,  SBQQ__Quantity__c = 6, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(GPL_Name__c = 'NetApp', SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[8].Id, SBQQ__PricebookEntryId__c = entries[8].Id, SBQQ__Quantity__c = 42, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today().addMonths(4).addDays(-6), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(GPL_Name__c = 'NetApp', SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[9].Id, SBQQ__PricebookEntryId__c = entries[9].Id, SBQQ__Quantity__c = 42, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today().addMonths(4).addDays(-6), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        insert lines;

        lines[0].SBQQ__Bundle__c = true;
        lines[1].SBQQ__RequiredBy__c = lines[0].Id;
        lines[2].SBQQ__RequiredBy__c = lines[1].Id;
        lines[3].SBQQ__RequiredBy__c = null;
        lines[4].SBQQ__RequiredBy__c = lines[1].Id;
        lines[5].SBQQ__RequiredBy__c = lines[1].Id;
        lines[6].SBQQ__RequiredBy__c = lines[1].Id;
        lines[7].SBQQ__RequiredBy__c = lines[1].Id;
        lines[8].SBQQ__RequiredBy__c = lines[0].Id;
        lines[9].SBQQ__RequiredBy__c = lines[1].Id;

        update lines;
        
        quote.ApprovalStatus__c = 'Approved';
        update quote;
        
        opp.StageName ='6 PO With Channel';
        opp.SBQQ__PrimaryQuote__c = quote.id;
        opp.Pricebook2Id = Test.getStandardPricebookId();
        opp.Polaris_Region__c = 'US';
        //opp.SBQQ__Ordered__c = true;
        //update opp;
        
        opp.SBQQ__Ordered__c = true;
        //update opp;
        
        //FlowControll.opportunityTriggerHandler = true;
        
        SBQQ__Quote__c qtq =[select id,name,SBQQ__NetAmount__c,SBQQ__PricebookId__c,(select id,SBQQ__NetPrice__c,SBQQ__NetTotal__c,SBQQ__Product__r.productcode,SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c, SBQQ__Product__c,SBQQ__PricebookEntryId__c from SBQQ__LineItems__r) from SBQQ__Quote__c where id=:quote.id ];
        
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c>(qtq.SBQQ__LineItems__r);
        Map<String, Object>  OrderMap = new Map<String, Object> {
            'Type' => 'Revenue',
            'AccountId' => accList[0].Id,
            'OpportunityId' => opp.Id,
            'Sync_to_NetSuite__c' => true,
            'EffectiveDate' => system.today(),
            'Status' => 'Pending',
            'Sell_to_Partner__c'=>accList[1].Id,
            'Bill_To_Name__c'=>accList[0].Id,
            'SBQQ__Quote__c'=>quote.id  
            };
            
        Order ord = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
    
        test.startTest();
        insert Ord;

        List<OrderItem> lstOrdrItems = new List<OrderItem>(); 
      
        for(integer i=0;i<qliList.size();i++){
            lstOrdrItems.add(new OrderItem( Product2Id = qliList[i].SBQQ__Product__c,SBQQ__QuotedQuantity__c = qliList[i].SBQQ__Quantity__c, OrderId = Ord.Id, Quantity = qliList[i].SBQQ__Quantity__c, PricebookEntryId = qliList[i].SBQQ__PricebookEntryId__c, unitprice =qliList[i].SBQQ__NetPrice__c,Sales_Price__c = qliList[i].SBQQ__NetPrice__c,SBQQ__QuoteLine__c=qliList[i].id, SBQQ__SubscriptionTerm__c =qliList[i].SBQQ__SubscriptionTerm__c));
        }
        insert lstOrdrItems;
 
        Integer count = 0;
        for(OrderItem OI : lstOrdrItems){
            if(count == 1 || count == 8){
                 OI.SBQQ__RequiredBy__c = lstOrdrItems[0].Id; 
            }else if(count != 1 && count != 3){
                 OI.SBQQ__RequiredBy__c = lstOrdrItems[1].Id; 
            }
            count++;
        }   
        
        update lstOrdrItems;
        Ord.Order_Split_Type__c = 'Netapp';
        Ord.Order_Status__c = 'Pending';
        Ord.Is_RWD_Polaris_Quote__c = true;
        Ord.Hold_Code__c = '';
        update Ord;
        SplitOrder scbat = new SplitOrder();
        string jobID =Database.executeBatch(scbat,1);
        Test.StopTest();
    }
    }
	/**
    * @author Siva Kumar
    * @date 12-03-2025
    * @description Added to cover utility methods 
    */
     static void testutilitymethod(){
 FlowControll.AccountTrigger = false;
        FlowControll.opportunityTriggerHandler = false;
        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_QuoteLine_Validation_Rules__c =  true, Disable_SBQQ_Quote_Triggers__c = true,Disable_SBQQ_Quote_Validation_Rules__c = true, Disable_Opportunity_Validation_Rules__c = true,setupOwnerId = userinfo.getuserid());
        insert disableLogic;
        ShGl_DisableFunctionalityLogic__c disableFunctionalLogic = new ShGl_DisableFunctionalityLogic__c(Disable_OpportunityValidationRules__c  = true,setupOwnerId = userinfo.getuserid());
        insert disableFunctionalLogic;

        List<TriggerControl__c> triggerControls = new List<TriggerControl__c> {
            new TriggerControl__c(Name='Contact', DisableTrigger__c=true),
                new TriggerControl__c(Name='Opportunity', DisableTrigger__c=true),
                new TriggerControl__c(Name='Entitlement', DisableTrigger__c=true),
                new TriggerControl__c(Name='Asset', DisableTrigger__c=true),
                new TriggerControl__c(Name='User', DisableTrigger__c=true),
                new TriggerControl__c(Name='Order', DisableTrigger__c=true)
                };
        insert triggerControls; 
       /*  FlowControll.AccountTrigger = false;
        FlowControll.opportunityTriggerHandler = false;
        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_QuoteLine_Validation_Rules__c =  true, Disable_SBQQ_Quote_Triggers__c = true,Disable_SBQQ_Quote_Validation_Rules__c = true, Disable_Opportunity_Validation_Rules__c = true);
        insert disableLogic;
        List<TriggerControl__c> triggerControls = new List<TriggerControl__c> {
            new TriggerControl__c(Name='Contact', DisableTrigger__c=true),
                new TriggerControl__c(Name='Opportunity', DisableTrigger__c=true),
                new TriggerControl__c(Name='Entitlement', DisableTrigger__c=true),
                new TriggerControl__c(Name='Asset', DisableTrigger__c=true),
                new TriggerControl__c(Name='User', DisableTrigger__c=true),
                new TriggerControl__c(Name='Order', DisableTrigger__c=true)
                };
        insert triggerControls;*/
         System.runAs(new User(Id=UserInfo.getUSerId())) {
        //Generate the Account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.name='Promark Technology, Inc.';
        act.Type ='Distributor';
        act.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        act.Contract_Status__c = 'Pending';
        insert act;
             Assert.areEqual('Promark Technology, Inc.', act.name);
             act.Id = getPromarkAccount().Sfdc_Id__c;
        update act;
        
        //Create custom setting record for promark EDI Process
        SkipManualOrder__c cusset = new SkipManualOrder__c();
        cusset.Account_Id__c =act.id;
        cusset.Enabled__c = true;
        cusset.name='Promark Technology, Inc.';
        insert cusset;
        
        createCustomSetPOValidationError();
        
        
        
        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => act.Id
                };
                    Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt;
          Map<String, Object> prdMapStd = new Map<String, Object> {
            'Name' => 'Standalone',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit',
                'productcode' => 'HW2'
                };
                    
                    Map<String, Object> prdMap = new Map<String, Object> {
                        'Name' => 'Standalone',
                            'IsActive' => true,
                            'SBQQ__AssetConversion__c' => 'One per unit',
                            'productcode' => 'HW1'
                            };
                                
                                Map<String, Object> prdMap1 = new Map<String, Object> {
                                    'Name' => 'Subscription', 
                                        'IsActive' => true, 
                                        'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                                        'SBQQ__SubscriptionTerm__c' => 12, 
                                        'SBQQ__SubscriptionType__c' => 'Renewable',
                                        'Product_Payment_Option__c' => 'Annual',
                                        'productcode' => 'GO1'
                                        };
                                            Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        Product2 prdHWSTD = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMapStd);
        
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 3, prdMap);
        prdList.add(prdHW);
        prdList.add(prdSubs);
        prdList.add(prdHWSTD);
        insert prdList;
        
        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        // Create a custom price book
        Pricebook2 customPB = new Pricebook2(Name='CPQ PriceBook', isActive=true);
        insert customPB;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry pbeHWstd1 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHWstd1.Product2Id = prdHWSTD.Id;
        pbeHWstd1.UnitPrice = 1500;
        pbeHWstd1.Pricebook2id = pricebookId;
        pBList.add(pbeHWstd1);
        
        
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
        pbeSubs.Pricebook2id = system.label.CPQPricebookID;
        
        PricebookEntry pbeHWstd12 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHWstd12.Product2Id = prdHWSTD.Id;
        pbeHWstd12.UnitPrice = 1500;
        pbeHWstd12.Pricebook2id = system.label.CPQPricebookID;
        pBList.add(pbeHWstd12);
        
        
        pBList.add(pbeSubs);
        insert pBList;
        
        
        //Generate the Opportunity
        Opportunity opp = TestDataFactory.getOpportunity(act);
        opp.Distributor_Lookup__c =act.id;
        opp.Amount = 0;
        opp.Pricebook2id = system.label.CPQPricebookID;
        insert opp;
        
        
        
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__SubscriptionTerm__c = 36;
        qt.SBQQ__PaymentTerms__c = 'Net 45';
        
        insert qt; 
        
                
        //the JSON formatted String representing the quote model to add a product to
        String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', qt.id);
        String currencyCode = 'USD';
        
        //the JSON formatted String representing the product to be added to the quote
        String productModel = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdSubs.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
        String productModel2 = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdHW.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
        String productModel3 = SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prdHWSTD.id, '{"pricebookId" : "' + customPB.id + '", "currencyCode" : "' + currencyCode + '"}');
        
        List<ProductModel> productModels = new List<ProductModel>();
        
        productModels.add((ProductModel) JSON.deserialize(productModel, ProductModel.class));
        productModels.add((ProductModel) JSON.deserialize(productModel2, ProductModel.class));
        productModels.add((ProductModel) JSON.deserialize(productModel3, ProductModel.class));
        
        
        ProductAdder adder = new ProductAdder();
        QuoteModel quoteWithProducts = adder.add((QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class), productModels, 0);
        
        quoteWithProducts.lineItems[0].record.SBQQ__Quantity__c = 10;
        quoteWithProducts.lineItems[0].record.SBQQ__SubscriptionTerm__c = 36;
        
        quoteWithProducts.lineItems[1].record.SBQQ__Quantity__c = 20;
        quoteWithProducts.lineItems[1].record.SBQQ__SubscriptionTerm__c = 36;
        
        quoteWithProducts.lineItems[2].record.SBQQ__Quantity__c = 15;
        quoteWithProducts.lineItems[2].record.SBQQ__SubscriptionTerm__c = 36;
        
        
        //the JSON formatted String represeting the saved quote
        String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
        
        
        QuoteCalculator calculator = new QuoteCalculator();
        calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
        
        qt.ApprovalStatus__c = 'Approved';
        update qt;
        
        SBQQ__Quote__c qtq =[select id,name,SBQQ__NetAmount__c,SBQQ__PricebookId__c from SBQQ__Quote__c where id=:qt.id ];
        
        List<SBQQ__QuoteLine__c> qliList =[select id,SBQQ__PricebookEntryId__c,SBQQ__NetPrice__c,SBQQ__NetTotal__c,SBQQ__Product__r.productcode,SBQQ__Quantity__c,SBQQ__Product__r.Product_Payment_Option__c, SBQQ__SubscriptionTerm__c, SBQQ__Product__c   from SBQQ__QuoteLine__c where  SBQQ__Quote__c =:qt.id];
        
        
      /*  List<PO_Stage__c> poStageList = new List<PO_Stage__c>();
        PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.','test123',system.today().addDays(10),2,'test@test.com','test partner',system.today(),1,'test12345',qtq.name,qliList[0].SBQQ__NetTotal__c+qliList[1].SBQQ__NetTotal__c);
        pos.Bill_To_Name__c=act.Id;
        pos.Payment_schedule_type__c = 'test';
        poStageList.add(pos);
        
        PO_Stage__c pos1 = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.','test1234',system.today().addDays(10),2,'test@test.com','test partner',system.today(),2,'test12345',qtq.name,qliList[2].SBQQ__NetTotal__c);
        pos1.Bill_To_Name__c=act.Id;
        pos1.Payment_schedule_type__c = 'test';
        poStageList.add(pos1);
        
        insert poStageList;
        
        List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>();
        
        qliList[0].SBQQ__RequiredBy__c = qliList[1].id;
        qliList[0].SBQQ__Quantity__c=50;
        qliList[0].SBQQ__Bundle__c=true;
        update qliList[0];   
        for(integer i=0;i<qliList.size();i++){
            
            string ediLinenum = 0+''+i;
            PO_Item_Stage__c poi;
            if(qliList[i].SBQQ__Product__r.Product_Payment_Option__c =='Annual'){
                
                Decimal j= qliList[i].SBQQ__SubscriptionTerm__c != null? (qliList[i].SBQQ__SubscriptionTerm__c/12) : 1;
                for(integer k=0;k<j;k++){
                    poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum+'_'+k,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos.id,12,((qliList[i].SBQQ__NetPrice__c)/36)*12);
                    poi.Quote_Line__c = qliList[i].Id;
                    poItem.add(poi);
                    poi = new PO_Item_Stage__c();
                }
            }
            else if(qliList[i].SBQQ__Product__r.productcode=='HW1'){
                poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos.id,qliList[i].SBQQ__SubscriptionTerm__c,qliList[i].SBQQ__NetPrice__c);
                poi.Quote_Line__c = qliList[i].Id;
                poItem.add(poi);
                poi = new PO_Item_Stage__c();
            }else IF(qliList[i].SBQQ__Product__r.productcode=='HW2'){
                poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos1.id,qliList[i].SBQQ__SubscriptionTerm__c,qliList[i].SBQQ__NetPrice__c);
                poi.Quote_Line__c = qliList[i].Id;
                poItem.add(poi);
                poi = new PO_Item_Stage__c();
            }
            
        }
        
        insert poItem;
        
        
        PO_Item_Stage__c PoIS = new PO_Item_Stage__c();
            PoIS.Buyer_Part_Number__c='1234';
            PoIS.EDI_Line_Number__c ='100';
            PoIS.ProductCode__c =qliList[0].SBQQ__Product__r.productcode;
            PoIS.Quantity__c = 50;
            PoIS.Stage_PO__c= pos1.id;
            PoIS.SubscriptionTerm__c =qliList[0].SBQQ__SubscriptionTerm__c;
            PoIS.UnitPrice__c=qliList[0].SBQQ__NetPrice__c;
        insert PoIS;
        
        List<PO_Stage_Address__c> poAs = new List<PO_Stage_Address__c>();
        PO_Stage_Address__c spa = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com',pos.id,'292005','test','test2');
        poAs.add(spa);
        PO_Stage_Address__c spa1 = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com',pos1.id,'292005','test','test2');
        poAs.add(spa1);
        insert poAs;        
        
        
        List<PO_Stage__c> upStageList = new  List<PO_Stage__c>();
        pos.PO_Validation_Status__c='Staged';
        
        upStageList.add(pos);
        pos1.PO_Validation_Status__c='Staged';
        
       POStageHelper.allStagePOmap.clear(); 
        POStageHelper.quoteMap.clear();
          upStageList.add(pos1);
        update upStageList;
                
        poStageList = [select id,PO_Validation_Status__c from PO_Stage__c where id=: pos.id];
        
        List<PO_Stage__c> upStageList1 = new  List<PO_Stage__c>();
        pos.PO_Validation_Status__c='Success';
        
        upStageList1.add(pos);
        pos1.PO_Validation_Status__c='Success';
        
        upStageList1.add(pos1);
        update upStageList1;*/
        
        opp.StageName = '6 PO With Channel';
        opp.SBQQ__Ordered__c = true;
        opp.Is_Order_Split__c = true;
        opp.Lost_To_Won_Against__c = 'Actifio';
        opp.Opportunity_Sub_Type__c='Regular';
        opp.Partner_Level_Of_Involvement__c='1.Rubrik initiated, Partner was fulfillment only';
        opp.Installation_Assigned_To__c='FE Install';
        opp.Primary_Competitor__c = 'Actifio';
        //opp.SBQQ__PrimaryQuote__c = ''; 
        update opp;
          List<Order> lstOrder = new List<order>([SELECT Id, Order_Split_Type__c FROM Order WHERE OpportunityId =: opp.id]);
        lstOrder[0].Order_Status__c = 'Pending';
        lstOrder[0].Order_Split_Type__c = 'Non-EDI';

        lstOrder[0].RSC_G_Enabled__c = true;
        update lstOrder;

        //Order ord1 = lstOrder[0].clone();

       // insert ord1;

        // ord1.Order_Split_Type__c = 'Non-EDI';
        // update ord1;

        List<OrderItem> lstOrdrItems = new List<OrderItem>(); 
      
        for(integer i=0;i<qliList.size();i++){
            lstOrdrItems.add(new OrderItem( SBQQ__QuotedQuantity__c = qliList[i].SBQQ__Quantity__c,OrderId = lstOrder[0].Id, Quantity = qliList[i].SBQQ__Quantity__c, PricebookEntryId = qliList[i].SBQQ__PricebookEntryId__c, unitprice =qliList[i].SBQQ__NetPrice__c,Sales_Price__c = qliList[i].SBQQ__NetPrice__c,SBQQ__QuoteLine__c=qliList[i].id, SBQQ__SubscriptionTerm__c =qliList[i].SBQQ__SubscriptionTerm__c));
            //lstOrdrItems.add(new OrderItem( SBQQ__QuotedQuantity__c = qliList[i].SBQQ__Quantity__c,OrderId = Ord1.Id, Quantity = qliList[i].SBQQ__Quantity__c, PricebookEntryId = qliList[i].SBQQ__PricebookEntryId__c, unitprice =qliList[i].SBQQ__NetPrice__c,Sales_Price__c = qliList[i].SBQQ__NetPrice__c,SBQQ__QuoteLine__c=qliList[i].id, SBQQ__SubscriptionTerm__c =qliList[i].SBQQ__SubscriptionTerm__c));
        }
        insert lstOrdrItems;
         }

    }
	/**
    * @author Siva Kumar
    * @date 12-03-2025
    * @description Added to cover Renewal and Expansion scenarios 
    */
    static testMethod void testRenewalandExpansionScenario(){
        SBQQ.TriggerControl.disable();
        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_QuoteLine_Validation_Rules__c =  true, Disable_SBQQ_Quote_Validation_Rules__c = true,Disable_Opportunity_Validation_Rules__c = true,Disable_Opportunity_Triggers__c =true,Disable_SBQQ_Quote_Triggers__c = true, Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_Order_Old_Trigger__c = true, Disable_Account_Triggers__c = true,Disable_Account_Validation_Rules__c = true);
        insert disableLogic;
        FlowControll.opportunityTriggerHandler = false;
        System.runAs(new User(Id=UserInfo.getUSerId())) {
        Id accDistiRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Map<String, Object> accMap = new Map<String, Object> {
            'RecordtypeId' => accDistiRecTypeId ,
            'Type' =>'Distributor'
        };
      
        List<account> accList = (List<account>) ShGl_TestFactory.createSObjectList(new Account(),2,accMap); 
        accList[0].name='Promark Technology, Inc.';
        accList[1].name='Net app, Inc.';
        insert accList;
            Assert.areEqual('Promark Technology, Inc.', accList[0].name);
            accList[0].Id = getIngramMicroUSAccount().Sfdc_Id__c;
        update accList;

        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => accList[0].Id
        };
        Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt;

            
        Opportunity opp = new Opportunity(
            AccountId = accList[0].Id,
            Name = 'Test',
            CloseDate = System.today().addMonths(12),
            StageName = 'Test',
            Pricebook2Id = Test.getStandardPricebookId(),
            Distributor_Lookup__c = accList[0].Id,
            Partner_Lookup__c = accList[0].id,
            Alliance_Partner_Name__c='Amazon',
            Alliance_Source_Type__c='Alliance Initiated Deal');
        insert opp;

        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Type__c = 'Renewal+Expansion',
            SBQQ__StartDate__c = System.today(),
            SBQQ__SubscriptionTerm__c = 12,
            SBQQ__Primary__c = true,
            Is_RWD_Polaris_Quote__c = true,
            SBQQ__PriceBook__c = Test.getStandardPricebookId());
        insert quote;
        List<Product2> sampleProducts = new List<Product2>{
                // 0
                new Product2(
                    Name = 'RS-BT-FE-PE-PP',
                    ProductCode = 'RS-BT-FE-PE-PP',
                    Product_Level__c = 'Hybrid Software',
                    IsActive = true,
                    SBQQ__Hidden__c = true,
                    Support_Type__c = 'Premium',
                    SBQQ__ExcludeFromOpportunity__c = true,
                    New_CPQ_Product__c = true
                ),
                // 1
                new Product2(
                    Name = 'RH-6416S-02',
                    ProductCode = 'RH-6416S-02',
                    Category__c = 'Platform',
                    Family = 'R6000',
					Usable_Capacity__c = 50,
                    Product_Type__c = 'Hardware',
                    Product_Level__c = 'Hardware',
                    Appliance_Model__c='RBK-R6416S',
                    Appliance_Model_HW__c = 'RBK-R6416S',
                    SBQQ__AssetConversion__c = null,
                    SBQQSC__EntitlementConversion__c = 'None',
                    Create_Asset_Entitlement__c = true,
                    IsActive = true,
                    Asset_Priority__c = 0,
                    New_CPQ_Product__c = true
                ),
                // 2
                new Product2(
                    Name = 'RS-HW-SVC-PE',
                    ProductCode = 'RS-HW-SVC-PE',
                    Category__c = 'Support',
                    Product_Type__c = 'HW Support',
					Product_Level__c = 'Support',
                    SBQQ__AssetConversion__c = 'None',
                    SBQQSC__EntitlementConversion__c = 'One per unit',
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 12,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable',
                    IsActive = true,
                    Support_Type__c = 'L3',
                    Asset_Priority__c = 1,
                    New_CPQ_Product__c = true
                ),
				//3
				new Product2(
                    Name = 'Professional-Services',
                    ProductCode = 'Professional-Services',
                    Category__c = 'Professional Services',
                    Product_Type__c = '',
					Product_Level__c = '',
                    SBQQ__AssetConversion__c = 'None',
                    SBQQSC__EntitlementConversion__c = null,
                    SBQQ__SubscriptionPricing__c = null,
                    SBQQ__SubscriptionTerm__c = null,
                    SBQQ__SubscriptionBase__c = null,
                    SBQQ__SubscriptionType__c = null,
                    IsActive = true,
                    New_CPQ_Product__c = true
                ),
				//4
				new Product2(
                    Name = 'RC-F3M-CBL-01',
                    ProductCode = 'RC-F3M-CBL-01',
                    Category__c = 'Platform',
                    Product_Type__c = 'Accessories',
					Product_Level__c = 'Hardware',
					Family = 'CABLE',
                    SBQQ__AssetConversion__c = 'None',
                    SBQQSC__EntitlementConversion__c = 'One per unit',
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 12,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable',
                    IsActive = true,
                    Support_Type__c = null,
                    Asset_Priority__c = 1,
                    New_CPQ_Product__c = true,
                    Product_Payment_Option__c = 'Annual'
                ),
				//5
				new Product2(
                    Name = 'RS-BT-NDA-PE-PP',
                    ProductCode = 'RS-BT-NDA-PE-PP',
                    Category__c = 'Software',
                    Product_Type__c = 'NAS',
					Product_Level__c = 'SaaS Software Addon',
					Family = 'POLARIS',
                    SBQQ__AssetConversion__c = 'None',
                    SBQQSC__EntitlementConversion__c = 'One per quote line',
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 1,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable',
                    IsActive = true,
                    Support_Type__c = null,
                    Asset_Priority__c = 1,
                    New_CPQ_Product__c = true,
                    Product_Payment_Option__c = 'Annual'
                ),
				//6
				new Product2(
                    Name = 'RS-NRD-R6000S',
                    ProductCode = 'RS-NRD-R6000S',
                    Category__c = 'Support',
                    Product_Type__c = null,
					Product_Level__c = null,
					Family = 'Non-Returnable Disk Service',
                    SBQQ__AssetConversion__c = 'None',
                    SBQQSC__EntitlementConversion__c = 'One per unit',
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 1,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable',
                    IsActive = true,
                    Support_Type__c = null,
                    Asset_Priority__c = 1,
                    New_CPQ_Product__c = true,
                    Product_Payment_Option__c = 'Annual'
                ),
                //7
                new Product2(
                    Name = 'SAAS',
                    ProductCode = 'SAAS',
                    License_Category__c = 'SaaS',
                    Category__c = 'Platform',
                    Product_Type__c = 'Accessories',
					Product_Level__c = 'Hardware',
					Family = 'SFP',
                    SBQQ__AssetConversion__c = 'None',
                    SBQQSC__EntitlementConversion__c = null,
                    SBQQ__SubscriptionPricing__c = null,
                    SBQQ__SubscriptionTerm__c = 1,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = null,
                    IsActive = true,
                    Support_Type__c = null,
                    Asset_Priority__c = 1,
                    New_CPQ_Product__c = true
                )
        };
        insert sampleProducts;

        List<PricebookEntry>entries = new List<PricebookEntry>();

        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[0].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[1].Id, IsActive = true, UnitPrice = 200));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[2].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[3].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[4].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[5].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[6].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[7].Id, IsActive = true, UnitPrice = 100));
        insert entries;

        List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[0].Id, SBQQ__PricebookEntryId__c = entries[0].Id, SBQQ__Quantity__c = 300,  SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = 1, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[1].Id, SBQQ__PricebookEntryId__c = entries[1].Id, SBQQ__Quantity__c = 6, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[2].Id, SBQQ__PricebookEntryId__c = entries[2].Id, SBQQ__Quantity__c = 6, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = 1, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[3].Id, SBQQ__PricebookEntryId__c = entries[3].Id, SBQQ__Quantity__c = 6, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[4].Id, SBQQ__PricebookEntryId__c = entries[4].Id, SBQQ__Quantity__c = 6, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[5].Id, SBQQ__PricebookEntryId__c = entries[5].Id,  SBQQ__Quantity__c = 6, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[6].Id, SBQQ__PricebookEntryId__c = entries[6].Id,  SBQQ__Quantity__c = 6, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[7].Id, SBQQ__PricebookEntryId__c = entries[7].Id,  SBQQ__Quantity__c = 6, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        
        insert lines;

        lines[0].SBQQ__Bundle__c = true;
        lines[1].SBQQ__RequiredBy__c = lines[0].Id;
        lines[2].SBQQ__RequiredBy__c = lines[1].Id;
        lines[3].SBQQ__RequiredBy__c = null;
        lines[4].SBQQ__RequiredBy__c = lines[1].Id;
        lines[5].SBQQ__RequiredBy__c = lines[1].Id;
        lines[6].SBQQ__RequiredBy__c = lines[1].Id;
        lines[7].SBQQ__RequiredBy__c = lines[1].Id;
        update lines;
        
        quote.ApprovalStatus__c = 'Approved';
        update quote;
        
        opp.StageName ='6 PO With Channel';
        opp.SBQQ__PrimaryQuote__c = quote.id;
        opp.Pricebook2Id = Test.getStandardPricebookId();
        opp.Polaris_Region__c = 'US';
        //opp.SBQQ__Ordered__c = true;
        //update opp;
        
        opp.SBQQ__Ordered__c = true;
        //update opp;
        
        //FlowControll.opportunityTriggerHandler = true;
        
        SBQQ__Quote__c qtq =[select id,name,SBQQ__NetAmount__c,SBQQ__PricebookId__c,(select id,SBQQ__NetPrice__c,SBQQ__NetTotal__c,SBQQ__Product__r.productcode,SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c, SBQQ__Product__c,SBQQ__PricebookEntryId__c from SBQQ__LineItems__r) from SBQQ__Quote__c where id=:quote.id ];
        
        PO_Stage__c poStage = new PO_Stage__c(
            Name='Test PO Stage',
            Account__c=accList[0].Id,
            Quote__c=qtq.id,
            Expected_number_of_POs__c = 1,
            PO_Index__c =1,
            PO_Validation_Status__c ='Success',
            Opportunity__c=opp.Id);
        insert poStage;
        
        List<PO_Item_Stage__c> lstPoStageItem = new List<PO_Item_Stage__c>();
        PO_Item_Stage__c poStageItem= new PO_Item_Stage__c(
            Name='Test PO Stage Item',
            Product__c=sampleProducts[0].id,
            Quote_Line__c=lines[0].Id,
            Stage_PO__c=poStage.id,
            Type__c='New'
        );
        lstPoStageItem.add(poStageItem);
        
        PO_Item_Stage__c poStageItem1= new PO_Item_Stage__c(
            Name='Test PO Stage Item1',
            Product__c=sampleProducts[1].id,
            Quote_Line__c=lines[1].Id,
            Stage_PO__c=poStage.id,
            Type__c='New'
        );
        lstPoStageItem.add(poStageItem1);
        
        PO_Item_Stage__c poStageItem2= new PO_Item_Stage__c(
            Name='Test PO Stage Item2',
            Product__c=sampleProducts[2].id,
            Quote_Line__c=lines[2].Id,
            Stage_PO__c=poStage.id,
            Type__c='New'
        );
        lstPoStageItem.add(poStageItem2);
        
        PO_Item_Stage__c poStageItem3= new PO_Item_Stage__c(
            Name='Test PO Stage Item13',
            Product__c=sampleProducts[3].id,
            Quote_Line__c=lines[3].Id,
            Stage_PO__c=poStage.id,
            Type__c='New'
        );
        
        PO_Item_Stage__c poStageItem4= new PO_Item_Stage__c(
            Name='Test PO Stage Item14',
            Product__c=sampleProducts[4].id,
            Quote_Line__c=lines[4].Id,
            Stage_PO__c=poStage.id,
            Type__c='New'
        );
        lstPoStageItem.add(poStageItem4);
        
        PO_Item_Stage__c poStageItem5= new PO_Item_Stage__c(
            Name='Test PO Stage Item15',
            Product__c=sampleProducts[5].id,
            Quote_Line__c=lines[5].Id,
            Stage_PO__c=poStage.id,
            Type__c='New'
        );
        lstPoStageItem.add(poStageItem5);
        
        PO_Item_Stage__c poStageItem6= new PO_Item_Stage__c(
            Name='Test PO Stage Item16',
            Product__c=sampleProducts[6].id,
            Quote_Line__c=lines[6].Id,
            Stage_PO__c=poStage.id,
            Type__c='New'
        );
        lstPoStageItem.add(poStageItem6);
        
        PO_Item_Stage__c poStageItem7= new PO_Item_Stage__c(
            Name='Test PO Stage Item7',
            Product__c=sampleProducts[7].id,
            Quote_Line__c=lines[7].Id,
            Stage_PO__c=poStage.id,
            Type__c='New'
        );
        lstPoStageItem.add(poStageItem7);
        insert lstPoStageItem;
        
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c>(qtq.SBQQ__LineItems__r);
        Map<String, Object>  OrderMap = new Map<String, Object> {
            'Type' => 'Revenue',
            'AccountId' => accList[0].Id,
            'OpportunityId' => opp.Id,
            'Sync_to_NetSuite__c' => true,
            'EffectiveDate' => system.today(),
            'Status' => 'Pending',
            'Sell_to_Partner__c'=>accList[1].Id,
            'Bill_To_Name__c'=>accList[0].Id,
            'SBQQ__Quote__c'=>quote.id  
            };
            
        Order ord = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
    
        test.startTest();
        insert Ord;

        List<OrderItem> lstOrdrItems = new List<OrderItem>(); 
      
        for(integer i=0;i<qliList.size();i++){
            lstOrdrItems.add(new OrderItem( Product2Id = qliList[i].SBQQ__Product__c,SBQQ__QuotedQuantity__c = qliList[i].SBQQ__Quantity__c, OrderId = Ord.Id, Quantity = qliList[i].SBQQ__Quantity__c, PricebookEntryId = qliList[i].SBQQ__PricebookEntryId__c, unitprice =qliList[i].SBQQ__NetPrice__c,Sales_Price__c = qliList[i].SBQQ__NetPrice__c,SBQQ__QuoteLine__c=qliList[i].id, SBQQ__SubscriptionTerm__c =qliList[i].SBQQ__SubscriptionTerm__c));
        }
        insert lstOrdrItems;

        
        Integer count = 0; 
        for(OrderItem OI : lstOrdrItems){
            if(count == 1){
                 OI.SBQQ__RequiredBy__c = lstOrdrItems[0].Id; 
            }else if(count != 1 && count != 3){
                 OI.SBQQ__RequiredBy__c = lstOrdrItems[1].Id; 
            }
            count++;
        }   
        
        update lstOrdrItems;
        Ord.Order_Split_Type__c = 'EDI';
        Ord.Order_Status__c = 'Pending';
        Ord.Is_RWD_Polaris_Quote__c = true;
        Ord.Hold_Code__c = '';
        update Ord;
        SplitOrder scbat = new SplitOrder();
        string jobID =Database.executeBatch(scbat,1);
        System.assert(jobID != null);	
        Test.StopTest();
        }
    }
   /** 
    * @description get sfdc disti metadata for Ingram.
    * @return Sfdc_Disti_Mapping__mdt
    */
    public static Sfdc_Disti_Mapping__mdt getIngramMicroUSAccount(){
    	return getDistributorCustomMetadata('Ingram_Micro_US');    
    }
    /**
    * @description get sfdc disti metadata for Promark.
    * @return Sfdc_Disti_Mapping__mdt
    */
    public static Sfdc_Disti_Mapping__mdt getPromarkAccount(){
    	return getDistributorCustomMetadata('Promark_Technology_Inc');    
    }
    private static Sfdc_Disti_Mapping__mdt getDistributorCustomMetadata(String distributorName){
    	return [SELECT Sfdc_Id__c FROM Sfdc_Disti_Mapping__mdt WHERE DeveloperName = :distributorName LIMIT 1];    
    }
    /**
    * @author Siva Kumar
    * @date 12-03-2025
    * @description test method to cover PO Stage trigger logic 
    */
    public static testMethod void populateRequiredByOnQLITest(){
        System.runAs(new User(Id=UserInfo.getUSerId()))  {
            SBQQ.TriggerControl.disable();
            ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_QuoteLine_Validation_Rules__c =  true, Disable_SBQQ_Quote_Validation_Rules__c = true,Disable_Opportunity_Validation_Rules__c = true,Disable_Opportunity_Triggers__c =true,Disable_SBQQ_Quote_Triggers__c = true,Disable_Order_Old_Trigger__c = true, Disable_Account_Triggers__c = true);
            insert disableLogic;
            
            Id partner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            Account customer = new Account(Name = 'Customer',recordtypeId = partner,Phone = '123-456-7890',AccountNumber = 'Test',BillingStreet = '123 street',BillingCity = 'Santa Clara',BillingState = 'California',BillingPostalCode = '95050',BillingCountry = 'United States',ShippingStreet = '123 street',ShippingCity = 'Santa Clara',ShippingState = 'California',ShippingPostalCode = '95050',ShippingCountry = 'United States');
            insert customer;
            Assert.areEqual('Customer', customer.Name);
            
            Opportunity opp = new Opportunity(
                AccountId = customer.Id,
                Name = 'Test',
                Opportunity_Sub_Type__c = 'Regular',
                CloseDate = System.today().addMonths(12),
                StageName = 'Test',
                Pricebook2Id = Test.getStandardPricebookId(),
                Distributor_Lookup__c = customer.Id,
                Partner_Lookup__c = customer.id,
                Alliance_Partner_Name__c='Amazon',
                Alliance_Source_Type__c='Alliance Initiated Deal');
            insert opp;
            SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Opportunity2__c = opp.Id,
                SBQQ__StartDate__c = System.today(),
                SBQQ__SubscriptionTerm__c = 12,
                SBQQ__Primary__c = true,
                SBQQ__Type__c = 'Quote',
                OpportunitySubType__c = 'Regular',
                Is_RWD_Polaris_Quote__c = true,
                SBQQ__PriceBook__c = Test.getStandardPricebookId());
            insert quote;
            
            List<Product2> sampleProducts = new List<Product2>{
                // 0
                new Product2(Name='RS-TB-FUE-RSV-PE',ProductCode ='RS-TB-FUE-RSV-PE',
                             Product_Level__c = 'Hardware',
                             Support_Type__c='Premium',License_Type__c='Consumption',
                             Product_Type__c='Hardware',Product_Subtype__c='Scale MSP',
                             License_Category__c = 'SaaS',
                             SBQQ__SubscriptionPricing__c='Fixed Price',SBQQ__SubscriptionType__c='Renewable',
                             SBQQSC__EntitlementConversion__c='One per quote line',SBQQ__AssetAmendmentBehavior__c='Default'),
                    
                    
                    new Product2(Name='RS-TB-EE-RSV-PE',ProductCode ='RS-TB-EE-RSV-PE',
                                 Support_Type__c='Premium',License_Category__c = 'SaaS',Product_Level__c='Hybrid Software',License_Type__c='Consumption',
                                 Product_Type__c='Enterprise Edition',Product_Subtype__c='Scale MSP',
                                 Product_Payment_Option__c='Monthly',Approval_Category__c='Scale Utility RSV',
                                 SBQQ__SubscriptionPricing__c='Fixed Price',SBQQ__SubscriptionType__c='Renewable',
                                 SBQQSC__EntitlementConversion__c='One per quote line',SBQQ__AssetAmendmentBehavior__c='Default')
                    
                    
                    
                    };
                        insert sampleProducts;
            
            Id pricebookId = Test.getStandardPricebookId();
            List<PricebookEntry>entries = new List<PricebookEntry>();
            
            entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = pricebookId, Product2Id = sampleProducts[0].Id, IsActive = true, UnitPrice = 100));
            entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = pricebookId, Product2Id = sampleProducts[1].Id, IsActive = true, UnitPrice = 100));
            
            insert entries; 
            Pricebook2 customPB = new Pricebook2(Name='CPQ PriceBook', isActive=true);
            insert customPB;
            
            List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
            Date stDate = System.Today();
            Date endDate = System.Today().addYears(1);
            
            lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id,  SBQQ__Product__c = sampleProducts[0].Id, SBQQ__PricebookEntryId__c = entries[0].Id, SBQQ__Quantity__c = 800,  SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__StartDate__c = stDate, SBQQ__EndDate__c = endDate, SBQQ__DefaultSubscriptionTerm__c = 1, SBQQ__ListPrice__c = 10, SBQQ__NetPrice__c = 10,SBQQ__SubscriptionTerm__c = 10));
            lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id,  SBQQ__Product__c = sampleProducts[1].Id, SBQQ__PricebookEntryId__c = entries[1].Id, SBQQ__Quantity__c = 800,  SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__StartDate__c = stDate, SBQQ__EndDate__c = endDate, SBQQ__DefaultSubscriptionTerm__c = 1, SBQQ__ListPrice__c = 10, SBQQ__NetPrice__c = 10,Product_Subtype__c = 'Scale MSP',License_Category__c = 'SaaS',SBQQ__SubscriptionTerm__c = 10));
            
            
            insert lines;
            
            lines[1].SBQQ__RequiredBy__c = lines[0].Id;
            update lines[1];
            
            quote.ApprovalStatus__c = 'Approved';
            update quote;
            
            SBQQ__Quote__c qtq =[select id,name,SBQQ__NetAmount__c,SBQQ__PricebookId__c,(select id,SBQQ__NetPrice__c,SBQQ__NetTotal__c,SBQQ__Product__r.productcode,SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c, SBQQ__Product__c,SBQQ__PricebookEntryId__c from SBQQ__LineItems__r) from SBQQ__Quote__c where id=:quote.id ];
            
            List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c>(qtq.SBQQ__LineItems__r);
            List<Order> ordersList = new List<Order>();
            Map<String, Object>  OrderMap = new Map<String, Object> {
                'Type' => 'Revenue',
                    'AccountId' => customer.Id,
                    'OpportunityId' => opp.Id,
                    'Sync_to_NetSuite__c' => true,
                    'EffectiveDate' => system.today(),
                    'Status' => 'Pending',
                    'Sell_to_Partner__c'=>customer.Id,
                    'Bill_To_Name__c'=>customer.Id,
                    'SBQQ__Quote__c'=>quote.id  
                    };
                        
                        Order ord = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
            ord.Order_Status__c = 'Pending';
            ord.Order_Split_Type__c = 'Not needed';
            ordersList.add(ord);
            Order ord1 = ord.clone();
            ordersList.add(ord1);
            test.startTest();
            insert ordersList;
            
            List<OrderItem> lstOrdrItems = new List<OrderItem>(); 
            
            for(integer i=0;i<qliList.size();i++){
                lstOrdrItems.add(new OrderItem( Product2Id = qliList[i].SBQQ__Product__c,SBQQ__QuotedQuantity__c = qliList[i].SBQQ__Quantity__c, OrderId = Ord.Id, Quantity = qliList[i].SBQQ__Quantity__c, PricebookEntryId = qliList[i].SBQQ__PricebookEntryId__c, unitprice =qliList[i].SBQQ__NetPrice__c,Sales_Price__c = qliList[i].SBQQ__NetPrice__c,SBQQ__QuoteLine__c=qliList[i].id, SBQQ__SubscriptionTerm__c =qliList[i].SBQQ__SubscriptionTerm__c));
            }
            lstOrdrItems[0].Program__c = Constants.PROGRAM_REFRESH;
            OrderItem oitem2 = lstOrdrItems[1].clone();
            oitem2.OrderId = ordersList[1].Id;
            lstOrdrItems.add(oitem2);
            insert lstOrdrItems;
            List<Order> orders = [SELECT Id, OrderNumber, HW_Order__c, Order_Index__c FROM Order];
            List<OrderItem> orderItems = [SELECT Id, OrderId, Order.OrderNumber FROM OrderItem];
            Map<id, Order> mapordersInserted = new Map<id, Order>();
            Map<string, set<string>> maphwOdrNoWithChildOrders = new Map<string, set<string>>();
            Map<Id, String> refreshHwToOldAst = new Map<Id, String>{lstOrdrItems[0].Id=>'test'};
            UtilityClass.RefreshPrgmWrapper refreshWrapper = new UtilityClass.RefreshPrgmWrapper(Constants.SKU_TYPE_LICENSE, orderItems[0]);
            Map<String, UtilityClass.refreshPrgmWrapper> oldastToRefreshWrapper = new Map<String, UtilityClass.refreshPrgmWrapper>();
            oldastToRefreshWrapper.put('test', refreshWrapper);
            Set<String> replacedOrderNums = new Set<String>();
            Map<String, Order> OrdsByOrdNum = new Map<String, Order>();
            for(Order ordRec : Orders){
            	mapordersInserted.put(ordRec.Id, ordRec);   
                maphwOdrNoWithChildOrders.put(ordRec.OrderNumber, new Set<string>{ordRec.OrderNumber});
                replacedOrderNums.add(ordRec.OrderNumber);
                OrdsByOrdNum.put(ordRec.OrderNumber, ordRec);
            }
            SplitOrder splitOrd = new SplitOrder();
            splitOrd.populateRequiredByOnQLI(
                mapordersInserted,
                maphwOdrNoWithChildOrders,
                refreshHwToOldAst,
                oldastToRefreshWrapper,
                replacedOrderNums,
                OrdsByOrdNum
            );
            Test.stopTest();
        }
    }
    /**
    * @author Siva Kumar
    * @date 12-03-2025
    * @description Added to Cover SplitOrder Go
    */
    public static testMethod void splitNetAppOrderTest(){
        System.runAs(new User(Id=UserInfo.getUSerId()))  {
            SBQQ.TriggerControl.disable();
            ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_QuoteLine_Validation_Rules__c =  true, Disable_SBQQ_Quote_Validation_Rules__c = true,Disable_Opportunity_Validation_Rules__c = true,Disable_Opportunity_Triggers__c =true,Disable_SBQQ_Quote_Triggers__c = true,Disable_Order_Old_Trigger__c = true, Disable_Account_Triggers__c = true);
            insert disableLogic;
            
            Id partner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            Account customer = new Account(Name = 'Customer',recordtypeId = partner,Phone = '123-456-7890',AccountNumber = 'Test',BillingStreet = '123 street',BillingCity = 'Santa Clara',BillingState = 'California',BillingPostalCode = '95050',BillingCountry = 'United States',ShippingStreet = '123 street',ShippingCity = 'Santa Clara',ShippingState = 'California',ShippingPostalCode = '95050',ShippingCountry = 'United States');
            insert customer;
            Assert.areEqual('Customer', customer.Name);
            
            Opportunity opp = new Opportunity(
                AccountId = customer.Id,
                Name = 'Test',
                Opportunity_Sub_Type__c = 'Regular',
                CloseDate = System.today().addMonths(12),
                StageName = 'Test',
                Pricebook2Id = Test.getStandardPricebookId(),
                Distributor_Lookup__c = customer.Id,
                Partner_Lookup__c = customer.id,
                Alliance_Partner_Name__c='Amazon',
                Alliance_Source_Type__c='Alliance Initiated Deal');
            insert opp;
            SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Opportunity2__c = opp.Id,
                SBQQ__StartDate__c = System.today(),
                SBQQ__SubscriptionTerm__c = 12,
                SBQQ__Primary__c = true,
                SBQQ__Type__c = 'Quote',
                OpportunitySubType__c = 'Regular',
                Is_RWD_Polaris_Quote__c = true,
                SBQQ__PriceBook__c = Test.getStandardPricebookId());
            insert quote;
            
            List<Product2> sampleProducts = new List<Product2>{
                new Product2(Name='RS-TB-FUE-RSV-PE',ProductCode ='RS-TB-FUE-RSV-PE',
                             Product_Level__c = 'Hardware',Product_Type__c='Hardware', Appliance_Model_HW__c='RBK-R6000S-64G'),
                new Product2(Name='RS-TB-FUE-RSV-PE',ProductCode ='RS-TB-FUE-RSV-PE',
                             Product_Level__c = 'Hybrid Software',Product_Type__c='Business Edition'),
                new Product2(Name='RS-TB-FUE-RSV-PE',ProductCode ='RS-TB-FUE-RSV-PE',
                             Product_Type__c='O365'),
                new Product2(Name='RS-TB-FUE-RSV-PE',ProductCode ='RS-TB-FUE-RSV-PE',
                             Category__c = 'Professional Services'),
                new Product2(Name='RS-TB-FUE-RSV-PE',ProductCode ='RS-TB-FUE-RSV-PE',
                             Product_Level__c ='SaaS Software Addon'),
                new Product2(Name='RS-TB-FUE-RSV-PE',ProductCode ='RS-TB-FUE-RSV-PE',
                             Family = 'Non-Returnable Disk Service'),
                new Product2(Name='RS-TB-FUE-RSV-PE',ProductCode ='RS-TB-FUE-RSV-PE',
                             Product_Type__c = 'HW Support', Product_Level__c = 'Support'),
                new Product2(Name='RS-TB-FUE-RSV-PE',ProductCode ='RS-TB-FUE-RSV-PE',
                             Product_Type__c = 'Business Edition', Product_Level__c = 'OnPrem'),
                new Product2(Name='RS-TB-FUE-RSV-PE',ProductCode ='RS-TB-FUE-RSV-PE',
                             License_Category__c = 'SaaS', Product_Level__c = 'Standalone Software Addon'),
                new Product2(Name='RS-TB-FUE-RSV-PE',ProductCode ='RS-TB-FUE-RSV-PE',
                             Product_Type__c = 'FED M365', Product_Level__c = 'OnPrem'),
                new Product2(Name='RS-TB-FUE-RSV-PE',ProductCode ='RS-TB-FUE-RSV-PE',
                             Product_Type__c='Accessories')                           
                    };
                insert sampleProducts;
            
            Id pricebookId = Test.getStandardPricebookId();
            List<PricebookEntry>entries = new List<PricebookEntry>();

            for(Product2 prd : sampleProducts){
                entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = pricebookId, Product2Id = prd.Id, IsActive = true, UnitPrice = 100));
            }
            insert entries; 
            Pricebook2 customPB = new Pricebook2(Name='CPQ PriceBook', isActive=true);
            insert customPB;
            
            List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
            Date stDate = System.Today();
            Date endDate = System.Today().addYears(1);
            for(Integer i=0; i<sampleProducts.size(); i++){
                lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id,  SBQQ__Product__c = sampleProducts[i].Id, SBQQ__PricebookEntryId__c = entries[i].Id, SBQQ__Quantity__c = 800,  SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__StartDate__c = stDate, SBQQ__EndDate__c = endDate, SBQQ__DefaultSubscriptionTerm__c = 1, SBQQ__ListPrice__c = 10, SBQQ__NetPrice__c = 10,SBQQ__SubscriptionTerm__c = 10));
            }
            insert lines;
            
            lines[1].SBQQ__RequiredBy__c = lines[0].Id;
            update lines[1];
            
            quote.ApprovalStatus__c = 'Approved';
            update quote;
            
            SBQQ__Quote__c qtq =[select id,name,SBQQ__NetAmount__c,SBQQ__PricebookId__c,(select id,SBQQ__NetPrice__c,SBQQ__NetTotal__c,SBQQ__Product__r.productcode,SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c, SBQQ__Product__c,SBQQ__PricebookEntryId__c from SBQQ__LineItems__r) from SBQQ__Quote__c where id=:quote.id ];
            
            List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c>(qtq.SBQQ__LineItems__r);
            List<Order> ordersList = new List<Order>();
            Map<String, Object>  OrderMap = new Map<String, Object> {
                'Type' => 'Revenue',
                    'AccountId' => customer.Id,
                    'OpportunityId' => opp.Id,
                    'Sync_to_NetSuite__c' => true,
                    'EffectiveDate' => system.today(),
                    'Status' => 'Pending',
                    'Sell_to_Partner__c'=>customer.Id,
                    'Bill_To_Name__c'=>customer.Id,
                    'SBQQ__Quote__c'=>quote.id  
                    };
                        
                        Order ord = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
            ord.Order_Status__c = 'Pending';
            ord.Order_Split_Type__c = 'Netapp';
            ord.Is_RWD_Polaris_Quote__c = true;
            ordersList.add(ord);
            Order ord1 = ord.clone();
            ord1.Is_RWD_Polaris_Quote__c = false;
            ord.Order_Split_Type__c = 'Not needed';
            ordersList.add(ord1);
            Order ord2 = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
            ord2.Order_Status__c = 'Pending';
            ord2.Order_Split_Type__c = 'Netapp';
            ord2.Is_RWD_Polaris_Quote__c = true;
            ordersList.add(ord2);
            test.startTest();
            insert ordersList;
            
            List<OrderItem> lstOrdrItems = new List<OrderItem>(); 
            lstOrdrItems.add(new OrderItem( Product2Id = qliList[0].SBQQ__Product__c, OrderId = Ord.Id, Quantity = 800, PricebookEntryId = qliList[0].SBQQ__PricebookEntryId__c, unitprice = 10,Sales_Price__c = 10,SBQQ__QuoteLine__c=qliList[0].id, SBQQ__SubscriptionTerm__c =10));
            lstOrdrItems.add(new OrderItem( Product2Id = qliList[0].SBQQ__Product__c, OrderId = Ord.Id, Quantity = 800, PricebookEntryId = qliList[0].SBQQ__PricebookEntryId__c, unitprice =10,Sales_Price__c = 10,SBQQ__QuoteLine__c=qliList[0].id, SBQQ__SubscriptionTerm__c =10));
            lstOrdrItems.add(new OrderItem( Product2Id = qliList[1].SBQQ__Product__c, OrderId = Ord1.Id, Quantity = 800, PricebookEntryId = qliList[1].SBQQ__PricebookEntryId__c, unitprice =10,Sales_Price__c = 10,SBQQ__QuoteLine__c=qliList[1].id, SBQQ__SubscriptionTerm__c =10));
            lstOrdrItems.add(new OrderItem( Product2Id = qliList[1].SBQQ__Product__c, OrderId = Ord1.Id, Quantity = 800, PricebookEntryId = qliList[1].SBQQ__PricebookEntryId__c, unitprice =10,Sales_Price__c =10,SBQQ__QuoteLine__c=qliList[1].id, SBQQ__SubscriptionTerm__c =10));
            lstOrdrItems.add(new OrderItem( Product2Id = qliList[2].SBQQ__Product__c, OrderId = Ord1.Id, Quantity = 800, PricebookEntryId = qliList[2].SBQQ__PricebookEntryId__c, unitprice =10,Sales_Price__c = 10,SBQQ__QuoteLine__c=qliList[2].id, SBQQ__SubscriptionTerm__c =10));
            lstOrdrItems.add(new OrderItem( Product2Id = qliList[2].SBQQ__Product__c, OrderId = Ord1.Id, Quantity = 800, PricebookEntryId = qliList[2].SBQQ__PricebookEntryId__c, unitprice =10,Sales_Price__c = 10,SBQQ__QuoteLine__c=qliList[2].id, SBQQ__SubscriptionTerm__c =10));
            lstOrdrItems.add(new OrderItem( Product2Id = qliList[3].SBQQ__Product__c, OrderId = Ord1.Id, Quantity = 800, PricebookEntryId = qliList[3].SBQQ__PricebookEntryId__c, unitprice =10,Sales_Price__c = 10,SBQQ__QuoteLine__c=qliList[3].id, SBQQ__SubscriptionTerm__c =10));
            lstOrdrItems.add(new OrderItem( Product2Id = qliList[3].SBQQ__Product__c, OrderId = Ord1.Id, Quantity = 800, PricebookEntryId = qliList[3].SBQQ__PricebookEntryId__c, unitprice =10,Sales_Price__c = 10,SBQQ__QuoteLine__c=qliList[3].id, SBQQ__SubscriptionTerm__c =10));
            lstOrdrItems.add(new OrderItem( Product2Id = qliList[3].SBQQ__Product__c, OrderId = Ord.Id, Quantity = 800, PricebookEntryId = qliList[3].SBQQ__PricebookEntryId__c, unitprice =10,Sales_Price__c = 10,SBQQ__QuoteLine__c=qliList[3].id, SBQQ__SubscriptionTerm__c =10, Is_Hardware_Line__c = true));
            lstOrdrItems.add(new OrderItem( Product2Id = qliList[3].SBQQ__Product__c, OrderId = Ord.Id, Quantity = 800, PricebookEntryId = qliList[3].SBQQ__PricebookEntryId__c, unitprice =10,Sales_Price__c = 10,SBQQ__QuoteLine__c=qliList[3].id, SBQQ__SubscriptionTerm__c =10, Is_Hardware_Line__c = true));
            lstOrdrItems.add(new OrderItem( Product2Id = qliList[4].SBQQ__Product__c, OrderId = Ord.Id, Quantity = 800, PricebookEntryId = qliList[4].SBQQ__PricebookEntryId__c, unitprice =10,Sales_Price__c = 10,SBQQ__QuoteLine__c=qliList[4].id, SBQQ__SubscriptionTerm__c =10));
            lstOrdrItems.add(new OrderItem( Product2Id = qliList[4].SBQQ__Product__c, OrderId = Ord.Id, Quantity = 800, PricebookEntryId = qliList[4].SBQQ__PricebookEntryId__c, unitprice =10,Sales_Price__c = 10,SBQQ__QuoteLine__c=qliList[4].id, SBQQ__SubscriptionTerm__c =10));
            lstOrdrItems.add(new OrderItem( Product2Id = qliList[4].SBQQ__Product__c, OrderId = Ord2.Id, Quantity = 800, PricebookEntryId = qliList[4].SBQQ__PricebookEntryId__c, unitprice =10,Sales_Price__c = 10,SBQQ__QuoteLine__c=qliList[4].id, SBQQ__SubscriptionTerm__c =10));
            lstOrdrItems.add(new OrderItem( Product2Id = qliList[4].SBQQ__Product__c, OrderId = Ord2.Id, Quantity = 800, PricebookEntryId = qliList[4].SBQQ__PricebookEntryId__c, unitprice =10,Sales_Price__c = 10,SBQQ__QuoteLine__c=qliList[4].id, SBQQ__SubscriptionTerm__c =10));
            lstOrdrItems.add(new OrderItem( Product2Id = qliList[5].SBQQ__Product__c, OrderId = Ord.Id, Quantity = 800, PricebookEntryId = qliList[5].SBQQ__PricebookEntryId__c, unitprice =10,Sales_Price__c = 10,SBQQ__QuoteLine__c=qliList[5].id, SBQQ__SubscriptionTerm__c =10));
            lstOrdrItems.add(new OrderItem( Product2Id = qliList[5].SBQQ__Product__c, OrderId = Ord2.Id, Quantity = 800, PricebookEntryId = qliList[5].SBQQ__PricebookEntryId__c, unitprice =10,Sales_Price__c = 10,SBQQ__QuoteLine__c=qliList[5].id, SBQQ__SubscriptionTerm__c =10));
            lstOrdrItems.add(new OrderItem( Product2Id = qliList[5].SBQQ__Product__c, OrderId = Ord2.Id, Quantity = 800, PricebookEntryId = qliList[5].SBQQ__PricebookEntryId__c, unitprice =10,Sales_Price__c = 10,SBQQ__QuoteLine__c=qliList[5].id, SBQQ__SubscriptionTerm__c =10));
            lstOrdrItems.add(new OrderItem( Product2Id = qliList[6].SBQQ__Product__c, OrderId = Ord.Id, Quantity = 800, PricebookEntryId = qliList[6].SBQQ__PricebookEntryId__c, unitprice =10,Sales_Price__c = 10,SBQQ__QuoteLine__c=qliList[6].id, SBQQ__SubscriptionTerm__c =10));
            lstOrdrItems.add(new OrderItem( Product2Id = qliList[7].SBQQ__Product__c, OrderId = Ord.Id, Quantity = 800, PricebookEntryId = qliList[7].SBQQ__PricebookEntryId__c, unitprice =10,Sales_Price__c = 10,SBQQ__QuoteLine__c=qliList[7].id, SBQQ__SubscriptionTerm__c =10));
            lstOrdrItems.add(new OrderItem( Product2Id = qliList[8].SBQQ__Product__c, OrderId = Ord.Id, Quantity = 800, PricebookEntryId = qliList[8].SBQQ__PricebookEntryId__c, unitprice =10,Sales_Price__c = 10,SBQQ__QuoteLine__c=qliList[8].id, SBQQ__SubscriptionTerm__c =10));
            lstOrdrItems.add(new OrderItem( Product2Id = qliList[8].SBQQ__Product__c, OrderId = Ord.Id, Quantity = 800, PricebookEntryId = qliList[8].SBQQ__PricebookEntryId__c, unitprice =10,Sales_Price__c = 10,SBQQ__QuoteLine__c=qliList[8].id, SBQQ__SubscriptionTerm__c =10));
            lstOrdrItems.add(new OrderItem( Product2Id = qliList[0].SBQQ__Product__c, OrderId = Ord1.Id, Quantity = 800, PricebookEntryId = qliList[0].SBQQ__PricebookEntryId__c, unitprice =10,Sales_Price__c = 10,SBQQ__QuoteLine__c=qliList[0].id, SBQQ__SubscriptionTerm__c =10));
            lstOrdrItems.add(new OrderItem( Product2Id = qliList[9].SBQQ__Product__c, OrderId = Ord.Id, Quantity = 800, PricebookEntryId = qliList[9].SBQQ__PricebookEntryId__c, unitprice =10,Sales_Price__c = 10,SBQQ__QuoteLine__c=qliList[9].id, SBQQ__SubscriptionTerm__c =10));
            lstOrdrItems.add(new OrderItem( Product2Id = qliList[9].SBQQ__Product__c, OrderId = Ord.Id, Quantity = 800, PricebookEntryId = qliList[9].SBQQ__PricebookEntryId__c, unitprice =10,Sales_Price__c = 10,SBQQ__QuoteLine__c=qliList[9].id, SBQQ__SubscriptionTerm__c =10));
            lstOrdrItems.add(new OrderItem( Product2Id = qliList[10].SBQQ__Product__c, OrderId = Ord1.Id, Quantity = 800, PricebookEntryId = qliList[10].SBQQ__PricebookEntryId__c, unitprice =10,Sales_Price__c = 10,SBQQ__QuoteLine__c=qliList[10].id, SBQQ__SubscriptionTerm__c =10));
            lstOrdrItems.add(new OrderItem( Product2Id = qliList[10].SBQQ__Product__c, OrderId = Ord1.Id, Quantity = 800, PricebookEntryId = qliList[10].SBQQ__PricebookEntryId__c, unitprice =10,Sales_Price__c = 10,SBQQ__QuoteLine__c=qliList[10].id, SBQQ__SubscriptionTerm__c =10));
            insert lstOrdrItems;
            lstOrdrItems[14].SBQQ__RequiredBy__c = lstOrdrItems[18].Id;
            lstOrdrItems[17].SBQQ__RequiredBy__c = lstOrdrItems[18].Id;
            lstOrdrItems[2].SBQQ__RequiredBy__c = lstOrdrItems[21].Id;
            lstOrdrItems[3].SBQQ__RequiredBy__c = lstOrdrItems[21].Id;
            update lstOrdrItems;
            List<Order> orders = [SELECT Id, OrderNumber, opportunityId, Is_RWD_Polaris_Quote__c, Have_Hardware_Products__c,
                                  SBQQ__Quote__c,Order_Index__c, (Select Id, OrderId, Product2.Product_Level__c,
                                                   Product_Type__c,
                                                   Product2.Product_Type__c, 
                                                   Product2.Product_Subtype__c,
                                                   Product2.ProductCode,
                                                   Product2.Category__c,
                                                   Product2.License_Category__c,
                                                   Product2.Family,
                                                   Product2.Appliance_Model_HW__c,
                                                   SBQQ__RequiredBy__c,
                                                   SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,
                                                   SBQQ__RequiredBy__r.Product2.ProductCode,
                                                   SBQQ__RequiredBy__r.SBQQ__SubscriptionTerm__c,
                                                   Quantity,
                                                   SBQQ__SubscriptionTerm__c 
                                                   FROM OrderItems) FROM Order];
            SplitOrder splitOrd = new SplitOrder();
            Set<String> rcdmSkus = new Set<String>();
            splitOrd.SplitNetAppOrder(orders, null, rcdmSkus);
            Test.stopTest();
        }
    }
    /**
    * @author Siva Kumar
    * @date 12-03-2025
    * @description Added to Partial Replacement
    */
    public static testMethod void testPartialReplacements(){

        FlowControll.AccountTrigger = false;
        FlowControll.opportunityTriggerHandler = false;
        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_QuoteLine_Validation_Rules__c =  true, Disable_SBQQ_Quote_Triggers__c = true,Disable_SBQQ_Quote_Validation_Rules__c = true, Disable_Opportunity_Validation_Rules__c = true);
        insert disableLogic;
        List<TriggerControl__c> triggerControls = new List<TriggerControl__c> {
            new TriggerControl__c(Name='Contact', DisableTrigger__c=true),
                new TriggerControl__c(Name='Opportunity', DisableTrigger__c=true),
                new TriggerControl__c(Name='Entitlement', DisableTrigger__c=true),
                new TriggerControl__c(Name='Asset', DisableTrigger__c=true),
                new TriggerControl__c(Name='User', DisableTrigger__c=true),
                new TriggerControl__c(Name='Order', DisableTrigger__c=true)
                };
        insert triggerControls;
        System.runAs(new User(Id=UserInfo.getUSerId())) {
            //Generate the Account.
            Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            act.name='Promark Technology, Inc.';
            act.Type ='Distributor';
            act.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            act.Contract_Status__c = 'Pending';
            Assert.areEqual('Promark Technology, Inc.', act.Name);
            insert act;

            Opportunity opp = new Opportunity(
                AccountId = act.Id,
                Name = 'Test',
                Opportunity_Sub_Type__c = 'Regular',
                CloseDate = System.today().addMonths(12),
                StageName = 'Test',
                Pricebook2Id = Test.getStandardPricebookId(),
                Distributor_Lookup__c = act.Id,
                Partner_Lookup__c = act.id,
                Alliance_Partner_Name__c='Amazon',
                Alliance_Source_Type__c='Alliance Initiated Deal');
            insert opp;

            SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Opportunity2__c = opp.Id,
                SBQQ__StartDate__c = System.today(),
                SBQQ__SubscriptionTerm__c = 12,
                SBQQ__Primary__c = true,
                SBQQ__Type__c = 'Quote',
                OpportunitySubType__c = 'Regular',
                Is_RWD_Polaris_Quote__c = false,
                SBQQ__PriceBook__c = Test.getStandardPricebookId());
            insert quote;

            Map<String, Object> prdMap = new Map<String, Object> {
                'Name' => 'Standalone',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit',
                'ProductCode' => 'test xyz1'
                };
            List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
            insert prdList;

            Id pricebookId = Test.getStandardPricebookId();
            List<PricebookEntry>entries = new List<PricebookEntry>();

            for(Product2 prd : prdList){
                entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = pricebookId, Product2Id = prd.Id, IsActive = true, UnitPrice = 100));
            }
            insert entries; 

            Pricebook2 customPB = new Pricebook2(Name='CPQ PriceBook', isActive=true);
            insert customPB;
            
            List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c>();
            Date stDate = System.Today();
            Date endDate = System.Today().addYears(1);
            for(Integer i=0; i<prdList.size(); i++){
                qliList.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id,  SBQQ__Product__c = prdList[i].Id, SBQQ__PricebookEntryId__c = entries[i].Id, SBQQ__Quantity__c = 800,  SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__StartDate__c = stDate, SBQQ__EndDate__c = endDate, SBQQ__DefaultSubscriptionTerm__c = 1, SBQQ__ListPrice__c = 10, SBQQ__NetPrice__c = 10,SBQQ__SubscriptionTerm__c = 10));
            }
            insert qliList;
            
            qliList[1].SBQQ__RequiredBy__c = qliList[0].Id;
            update qliList[1];
            
            quote.ApprovalStatus__c = 'Approved';
            update quote;

            qliList = [SELECT Id, SBQQ__Product__r.productcode, SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c, SBQQ__NetPrice__c, SBQQ__Quote__r.Name, SBQQ__NetTotal__c FROM SBQQ__QuoteLine__c];
            List<PO_Stage__c> poStageList = new List<PO_Stage__c>();
            PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage('Promark Technology, Inc.pp','test123',system.today().addDays(10),2,'test@test.com.invalid','test partner',system.today(),1,'test12345',qliList[0].SBQQ__Quote__r.Name,qliList[0].SBQQ__NetTotal__c);
            pos.Bill_To_Name__c=act.Id;
            pos.Quote__c = quote.Id;
            pos.PO_Validation_Status__c='Success';
            poStageList.add(pos);
            insert poStageList;

            List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>();
            for(integer i=0;i<qliList.size();i++){
                
                string ediLinenum = 0+''+i;
                PO_Item_Stage__c poi = ShGl_TestFactoryHelper.createPOItem('1234'+ediLinenum,ediLinenum,qliList[i].SBQQ__Product__r.productcode,qliList[i].SBQQ__Quantity__c,pos.id,qliList[i].SBQQ__SubscriptionTerm__c,qliList[i].SBQQ__NetPrice__c);
                poi.Type__c='New';
                poi.Quote_Line__c = qliList[i].Id;
                poItem.add(poi);
            }
            insert poItem;

            List<PO_Stage_Address__c> poAs = new List<PO_Stage_Address__c>();
            PO_Stage_Address__c spa = ShGl_TestFactoryHelper.createPOStageAddress('Shipp to Address','test','testname','9036002236','USA','AL','test@test.com.invalid',pos.id,'292005','test','test2');
            poAs.add(spa);
            insert poAs; 
            
            opp.StageName = '6 PO With Channel';
            opp.SBQQ__Ordered__c = true;
            opp.Is_Order_Split__c = true;
            opp.Lost_To_Won_Against__c = 'Actifio';
            opp.Opportunity_Sub_Type__c='Regular';
            opp.Partner_Level_Of_Involvement__c='1.Rubrik initiated, Partner was fulfillment only';
            opp.Installation_Assigned_To__c='FE Install';
            opp.Primary_Competitor__c = 'Actifio';
            FlowControll.opportunityTriggerHandler = false;
            update opp;
            
            Map<String, Object>  OrderMap = new Map<String, Object> {
                'Type' => 'Revenue',
                    'AccountId' => act.Id,
                    'OpportunityId' => opp.Id,
                    'Sync_to_NetSuite__c' => true,
                    'EffectiveDate' => system.today(),
                    'Status' => 'Pending',
                    'Bill_To_Name__c'=>act.Id,
                    'SBQQ__Quote__c'=>quote.id  
                    };
                        
            Order phantomOrd =  (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
            phantomOrd.Order_Sub_type__c = 'Surviving Partial';
            insert phantomOrd;
            
            List<Order> lstOrder = new List<order>([SELECT Id, Ordernumber,Order_Sub_type__c, Order_Split_Type__c FROM Order WHERE (OpportunityId =: opp.id OR Order_Sub_type__c = 'Surviving Partial') ]);
            String phantomOrdNum; 
            Order replacedOrd = new Order();
            for(Order ord : lstOrder){
                if(ord.Order_Sub_type__c == 'Surviving Partial'){
                    phantomOrdNum = ord.Ordernumber;
                }
                else{
                    replacedOrd = ord;
                }
            }
            replacedOrd.Order_Status__c = 'Pending';
            replacedOrd.Order_Split_Type__c = 'EDI';
            replacedOrd.Type = 'Revenue';
            replacedOrd.Associated_Order_Numbers__c = phantomOrdNum;
            replacedOrd.Line_Types__c = 'Conversion';
            update replacedOrd;
            lstOrder[0].Order_Status__c = 'Pending';
            lstOrder[0].Order_Split_Type__c = 'EDI';
            List<OrderItem> ordItems = [SELECT Id, Replacement_Type__c FROM OrderItem ];
            for(OrderItem oItem : ordItems){
                oItem.Replacement_Type__c = 'Partial';
                oItem.Credit_Amount__c = 150;
            }
            update ordItems;
            update lstOrder;
            
            SplitOrder scbat = new SplitOrder();
            string jobID =Database.executeBatch(scbat);
        }

    }
}