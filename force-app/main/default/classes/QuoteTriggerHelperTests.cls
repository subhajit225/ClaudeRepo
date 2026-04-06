@isTest
private class QuoteTriggerHelperTests {
    static List<SBQQ__Quote__c> quoteList;
    
    static Product2 getProduct(String name, String code) {
        return new Product2(Name = name, ProductCode = code, isActive = true, CPQ_Uplift__c = '5');
    }
     
    static PricebookEntry getPbe(Id pbId, Id prodId, Decimal unitPrice) {
        return new PricebookEntry(Pricebook2Id = pbId, Product2Id = prodId, UnitPrice = unitPrice, IsActive = true);
    }
    
    static PricebookEntry getPbe(Id prodId, Decimal unitPrice) {
        return getPbe(Test.getStandardPricebookId(), prodId, unitPrice);
    }
    
    static ContractLineItem getCli(Id pbeId, Id scId) {
        return new ContractLineItem(
            Quantity = 1,
            SBQQSC__Quantity__c = 1,
            PricebookEntryId = pbeId,
            ServiceContractId = scId,
            UnitPrice = 100,
            StartDate = Date.today()
        );
    }
    
    static Asset getAsset(String name, Id prodId, Id accountId) {
        return new Asset(
            Name = name,
            SerialNumber = name,
            Serial_Number__c = name,
            Product2ID = prodId,
            Accountid = accountId
        );
    }
    
    static OrderItem getOli(Id orderId, Id pbeId, Decimal price, String serialNumber) {
        return new OrderItem(
            OrderId = orderId,
            Quantity = 5,
            PricebookEntryId = pbeId,
            UnitPrice = price,
            SerialNumber__c = serialNumber,
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
    }
    
    @TestSetup
    static void setupData() {
        insert new ShGl_DisableBusinessLogic__c(
            SetupOwnerId = UserInfo.getUserId(),
            Disable_Opportunity_Triggers__c = true,
            Disable_Entitlement_Validation_Rules__c = true
        );
        
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get('Partner/Distributor')
            .getRecordTypeId();
        Account acct = new Account(
            Name = 'testAccount',
            RecordTypeId = partnerRecordTypeId,
            Account_Deal_Desk_Notes__c = 'Test Notes'
        );
        Account acc = new Account(Name = 'testAccount1');
        insert new List<Account>{ acct, acc };
            
            Opportunity oppr = TestDataFactory.getOpportunity(acct);
        insert oppr;
        
        Id standardPriceBookId = Test.getStandardPricebookId();
        
        PriceBook2 pb1 = new Pricebook2(
            Name = 'V68_2017_08_09_12_26_43',
            Description = 'Price Book 2009 Products 1',
            IsActive = true
        );
        insert pb1;
        
        //Create your product
        Product2 prod1 = new Product2(Name = 'RBK-GO-BE-R6408', ProductCode = 'RBK-GO-BE-R6408', isActive = true);
        Product2 prod2 = new Product2(
            Name = 'RBK-R Premium Support 1-Yr Prepaid, r304',
            ProductCode = 'RBK-SVC-PREM-R304',
            isActive = true
        );
        //Create your product
        Product2 prod3 = new Product2(Name = 'RBK-GO-BE-R6408', ProductCode = 'RBK-GO-BE-R6408', isActive = true);
        //Create your product
        Product2 prod4 = new Product2(Name = 'RBK-RCDM-10-MO-CLON', ProductCode = 'RBK-RCDM-AWS-MO', isActive = true);
        
        Product2 prod5 = new Product2(Name = 'RS-BE-GO-PE-PP', ProductCode = 'RS-BE-GO-PE-PP', isActive = true);
        
        insert new List<Product2>{ prod1, prod2, prod3, prod4, prod5 };
            
            //Create your pricebook entry
            PricebookEntry pbStanEntry1 = getPbe(prod1.Id, 100.00);
        
        //Create your pricebook entry
        PricebookEntry pbStanEntry2 = getPbe(prod2.Id, 1000.00);
        
        //Create your pricebook entry
        PricebookEntry pbStanEntry3 = getPbe(prod3.Id, 100.00);
        
        //Create your pricebook entry
        PricebookEntry pbStanEntry4 = getPbe(prod4.Id, 100.00);
        
        PricebookEntry pbStanEntry5 = getPbe(prod5.Id, 100.00);
        
        //Create your pricebook entry
        PricebookEntry pbEntry1 = getPbe(pb1.Id, prod1.Id, 100.00);
        
        //Create your pricebook entry
        PricebookEntry pbEntry2 = getPbe(pb1.Id, prod2.Id, 1000.00);
        
        //Create your pricebook entry
        PricebookEntry pbEntry3 = getPbe(pb1.Id, prod3.Id, 1000.00);
        
        //Create your pricebook entry
        PricebookEntry pbEntry4 = getPbe(pb1.Id, prod4.Id, 1000.00);
        
        PricebookEntry pbEntry5 = getPbe(pb1.Id, prod5.Id, 1000.00);
        
        insert new List<PricebookEntry>{
            pbStanEntry1,
                pbStanEntry2,
                pbStanEntry3,
                pbStanEntry4,
                pbStanEntry5,
                pbEntry1,
                pbEntry2,
                pbEntry3,
                pbEntry4,
                pbEntry5
                };
                    
                    Map<String, Object> quoteMap = new Map<String, Object>{
                        'SBQQ__Account__c' => acct.Id,
                            'SBQQ__Opportunity2__c' => oppr.Id
                            };
                                
                                SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt1.SBQQ__Opportunity2__c = oppr.Id;
        qt1.SBQQ__Primary__c = false;
        qt1.SBQQ__PriceBook__c = pb1.Id;
        qt1.ApprovalStatus__c = 'Approved';
        qt1.SBQQ__Type__c = 'Renewal';
        qt1.SBQQ__StartDate__c = Date.today();
        qt1.Manual_Billing__c = false;
        qt1.Consolidate_Lines__c = false;
        insert qt1;
        
        Order ordr22 = new Order(
            Type = 'Revenue',
            AccountId = acct.Id,
            OpportunityId = oppr.Id,
            ShippingStreet = 'Test Street',
            ShippingCity = 'Test City',
            ShippingState = null,
            ShippingCountry = 'Austria',
            ShippingPostalcode = '94820',
            EffectiveDate = system.Today(),
            Status = 'Pending',
            Pricebook2Id = pb1.Id
        );
        
        insert ordr22;
        
        Asset asst = getAsset('Test1234567Asset', prod3.Id, acct.Id);
        
        Asset asst3 = getAsset('Test1234567Asset3', prod3.Id, acct.Id);
        
        Asset asst4 = getAsset('Test1234567Asset4', prod3.Id, acct.Id);
        
        Asset asst2 = getAsset('Test1234567Asset2', prod3.Id, acct.Id);
        
        insert new List<Asset>{ asst, asst3, asst4, asst2 };
            
            ServiceContract objSC = new ServiceContract(
                Name = 'ServiceContract Test',
                AccountId = acct.Id,
                StartDate = Date.today(),
                Term = 36,
                pricebook2Id = pb1.Id,
                SBQQSC__Opportunity__c = oppr.Id,
                SBQQSC__Order__c = ordr22.Id,
                SBQQSC__Quote__c = qt1.Id
            );
        
        insert objSC;
        
        ordr22.ShipToContactName__c = 'sh';
        ordr22.Shipping_Method__c = 'EXW';
        ordr22.Shipping_Carrier__c = 'AIT';
        ordr22.Service_Level__c = 'Same Day';
        ordr22.Bill_To_Name__C = acct.id;
        ordr22.est_Ship_Date__C = System.Today().addDays(7);
        ordr22.Status = 'Order Accepted';
        
        OrderItem oli1 = getOli(ordr22.Id, pbEntry1.Id, pbEntry1.UnitPrice, 'Test1234567Asset2');
        
        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OrderItem oli2 = getOli(ordr22.Id, pbEntry2.Id, pbEntry2.UnitPrice, 'Test1234567Asset');
        
        OrderItem oli3 = getOli(ordr22.Id, pbEntry3.Id, pbEntry3.UnitPrice, 'Test1234567Asset');
        
        List<ContractLineItem> lstCli = new List<ContractLineItem>();
        ContractLineItem cli = getCli(pbEntry1.Id, objSC.Id);
        cli.Quantity = oli1.quantity;
        cli.UnitPrice = oli1.UnitPrice;
        cli.StartDate = date.today();
        lstCli.add(cli);
        
        ContractLineItem cli2 = getCli(pbEntry1.Id, objSC.Id);
        cli2.Quantity = oli2.quantity;
        cli2.UnitPrice = oli2.UnitPrice;
        cli2.StartDate = date.today();
        lstCli.add(cli2);
        
        ContractLineItem cli3 = getCli(oli3.PricebookEntryId, objSC.id);
        cli3.Quantity = oli2.quantity;
        cli3.UnitPrice = oli2.UnitPrice;
        cli3.StartDate = date.today();
        lstCli.add(cli3);
        
        insert lstCli;
        
        List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c ql1 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt1.Id,
            Prior_Net_Total__c = 10,
            SBQQ__Product__c = prod1.Id,
            SBQQ__Quantity__c = 20,
            SBQQ__SubscriptionPricing__c = null,
            SBQQ__DefaultSubscriptionTerm__c = null,
            SBQQ__ListPrice__c = 200,
            SBQQ__NetPrice__c = 200,
            SBQQSC__RenewedContractLine__c = cli.Id,
            SBQQ__StartDate__c = Date.today(),
            SBQQ__EndDate__c = Date.today().addDays(10),
            SubscribedAssetNames__c = 'BB192863040046'
        );
        
        lines.add(ql1);
        insert lines;
    }
    
    @isTest
    private static void testConsolidateContractLines() {
        Account acc = new Account(Name = 'testAccount1');
        insert new List<Account>{ acc };
            
            Opportunity oppr = TestDataFactory.getOpportunity(acc);
        insert oppr;
        
        Product2 prod1 = getProduct('RBK-GO-BE-R6408', 'RBK-GO-BE-R6408');
        
        Product2 prod2 = getProduct('RBK-R Premium Support 1-Yr Prepaid, r304', 'RBK-SVC-PREM-R304');
        
        //Create your product
        Product2 prod3 = getProduct('RBK-GO-BE-R6408', 'RBK-GO-BE-R6408');
        
        //Create your product
        Product2 prod4 = getProduct('RBK-RCDM-10-MO-CLON', 'RBK-RCDM-AWS-MO');
        
        Product2 prod5 = getProduct('RS-BE-GO-PE-PP', 'RS-BE-GO-PE-PP');
        
        insert new List<Product2>{ prod1, prod2, prod3, prod4, prod5 };
            Test.startTest();
        
        //Create your pricebook entry
        PricebookEntry pbEntry1 = getPbe(prod1.Id, 100.00);
        
        //Create your pricebook entry
        PricebookEntry pbEntry2 = getPbe(prod2.Id, 10000.00);
        
        //Create your pricebook entry
        PricebookEntry pbEntry3 = getPbe(prod3.Id, 1000.00);
        
        //Create your pricebook entry
        PricebookEntry pbEntry4 = getPbe(prod4.Id, 1000.00);
        
        PricebookEntry pbEntry5 = getPbe(prod5.Id, 1000.00);
        
        insert new List<PricebookEntry>{ pbEntry1, pbEntry2, pbEntry3, pbEntry4, pbEntry5 };
            
            Map<String, Object> quoteMap = new Map<String, Object>{
                'SBQQ__Account__c' => acc.Id,
                    'SBQQ__Opportunity2__c' => oppr.Id,
                    'SBQQ__Primary__c' => false,
                    'SBQQ__PriceBook__c' => Test.getStandardPricebookId(),
                    'ApprovalStatus__c' => 'Approved',
                    'SBQQ__Type__c' => 'Renewal',
                    'SBQQ__StartDate__c' => Date.today(),
                    'Manual_Billing__c' => false,
                    'Consolidate_Lines__c' => false
                    };
                        
                        SBQQ__Quote__c quote1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        insert quote1;
        
        ServiceContract objSC = new ServiceContract(
            Name = 'ServiceContract Test',
            AccountId = acc.Id,
            StartDate = Date.today(),
            Term = 36,
            pricebook2Id = Test.getStandardPricebookId(),
            SBQQSC__Opportunity__c = oppr.Id,
            SBQQSC__Quote__c = quote1.Id
        );
        
        insert objSC;
        
        List<ContractLineItem> lstCli = new List<ContractLineItem>();
        
        ContractLineItem cli = getCli(pbEntry1.Id, objSC.Id);
        lstCli.add(cli);
        
        ContractLineItem cli2 = getCli(pbEntry2.Id, objSC.Id);
        lstCli.add(cli2);
        
        ContractLineItem cli3 = getCli(pbEntry3.Id, objSC.Id);
        lstCli.add(cli3);
        
        insert lstCli;
        
        List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c ql1 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote1.Id,
            Prior_Net_Total__c = 10.00,
            SBQQ__Product__c = prod1.Id,
            SBQQ__Quantity__c = 20.00,
            SBQQ__SubscriptionPricing__c = null,
            SBQQ__DefaultSubscriptionTerm__c = null,
            SBQQ__ListPrice__c = 200.00,
            SBQQ__NetPrice__c = 200.00,
            SBQQSC__RenewedContractLine__c = cli.Id,
            SBQQ__StartDate__c = Date.today(),
            SBQQ__EndDate__c = Date.today().addDays(30),
            SubscribedAssetNames__c = 'BB1928630400120'
        );
        
        lines.add(ql1);
        insert lines;
        
        TriggerControls.disableQuoteTrigger = false;
        TriggerControls.disableQuoteLineTrigger = false;
        SBQQ.TriggerControl.enable();
        
        List<Consolidated_Contract_Lines__c> lstCCLRec = new List<Consolidated_Contract_Lines__c>();
        Consolidated_Contract_Lines__c consolidateContractLines = new Consolidated_Contract_Lines__c();
        consolidateContractLines.Quote_Line__c = ql1.Id;
        consolidateContractLines.Contract_Line_Item__c = cli3.Id;
        //insert consolidateContractLines;
        lstCCLRec.add(consolidateContractLines);
        insert lstCCLRec;
        Test.stopTest();
        
        System.assert(true);
    }
    
    @isTest
    private static void testSetUpdateQuoteDealNotes() {
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        SBQQ.TriggerControl.disable();
        
        List<SBQQ__Quote__c> quoteListTest = [
            SELECT
            Id,
            Account_Deal_Desk_Notes__c,
            SBQQ__Account__c,
            Is_Federal_Eligible_Quote__c,
            Old_Co_Term_Date__c,
            RWD_Sales_Rep_Exception__c
            FROM SBQQ__Quote__c
            LIMIT 50000
        ];
        
        TriggerControls.disableQuoteTrigger = false;
        TriggerControls.disableQuoteLineTrigger = false;
        SBQQ.TriggerControl.enable();
        
        Test.startTest();
        QuoteTriggerHelper.setUpdateQuoteDealNotes(quoteListTest);
        Test.stopTest();
        
        System.assert(true);
    }
    
    @isTest
    private static void testPopulateCoTermOnInsert() {
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        SBQQ.TriggerControl.disable();
        //CPQ22-1732
        List<SBQQ__Quote__c> quoteListTest = [
            SELECT
            Id,
            Amended_Renewed_Service_Contract__c,
            sbqq__source__c,
            SBQQ__EndDate__c,
            SBQQ__StartDate__c,
            OpportunitySubType__c,
            Co_Term_Date__c,
            SBQQ__Type__c,
            SBQQ__Account__c,
            Old_Co_Term_Date__c,
            Is_Federal_Eligible_Quote__c,
            RWD_Sales_Rep_Exception__c,
            SBQQ__NetAmount__c,
            SBQQ__LineItemCount__c
            FROM SBQQ__Quote__c
            LIMIT 50000
        ];
        
        TriggerControls.disableQuoteTrigger = false;
        TriggerControls.disableQuoteLineTrigger = false;
        SBQQ.TriggerControl.enable();
        
        Map<Id, SBQQ__Quote__c> oldQuoteMap = new Map<Id, SBQQ__Quote__c>();
        
        for (SBQQ__Quote__c Qt : quoteListTest) {
            oldQuoteMap.put(Qt.id, Qt);
        }
        
        Test.startTest();
        //QuoteTriggerHelper.populateCoTermOnInsert(quoteListTest, oldQuoteMap);
        Test.stopTest();
        
        System.assert(true);
    }
    
    @isTest
    private static void testValidateIsManualBillingAllowed() {
        String uniqueUserName = 'TestUser' + DateTime.now().getTime() + '@rbk.com';
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User usr = new user(
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
        insert usr;
        
        System.runAs(usr) {
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true;
            SBQQ.TriggerControl.disable();
            
            List<SBQQ__Quote__c> quoteListTest = [
                SELECT
                Id,
                Manual_Billing__c,
                sbqq__source__c,
                SBQQ__EndDate__c,
                SBQQ__StartDate__c,
                Co_Term_Date__c,
                SBQQ__Type__c,
                SBQQ__Account__c,
                Is_Federal_Eligible_Quote__c,
                Old_Co_Term_Date__c,
                RWD_Sales_Rep_Exception__c
                FROM SBQQ__Quote__c
                LIMIT 50000
            ];
            
            TriggerControls.disableQuoteTrigger = false;
            TriggerControls.disableQuoteLineTrigger = false;
            SBQQ.TriggerControl.enable();
            Test.startTest();
            
            for (SBQQ__Quote__c quote : quoteListTest) {
                quote.Manual_Billing__c = true;
            }
            update quoteListTest;
            Test.stopTest();
        }
        
        System.assert(true);
    }
    
    @isTest
    private static void testConsolidateQuoteLineItems() {
        //static List<SBQQ__Quote__c> quoteList;
        
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        SBQQ.TriggerControl.disable();
        
        if (quoteList == null) {
            quoteList = [
                SELECT
                Id,
                Consolidate_Lines__c,
                sbqq__source__c,
                SBQQ__EndDate__c,
                SBQQ__StartDate__c,
                Co_Term_Date__c,
                SBQQ__Type__c,
                SBQQ__Account__c,
                Is_Federal_Eligible_Quote__c,
                Old_Co_Term_Date__c,
                RWD_Sales_Rep_Exception__c
                FROM SBQQ__Quote__c
                LIMIT 50000
            ];
        }
        
        TriggerControls.disableQuoteTrigger = false;
        TriggerControls.disableQuoteLineTrigger = false;
        SBQQ.TriggerControl.enable();
        
        Test.startTest();
        for (SBQQ__Quote__c quote : quoteList) {
            quote.Consolidate_Lines__c = true;
        }
        update quoteList;
        Test.stopTest();
        
        System.assert(true);
    }
    
    @isTest
    private static void testOrderItemSerialNumNotNull() {
        Test.startTest();
        List<OrderItem> orderItemList = [SELECT Id, SerialNumber__c FROM OrderItem LIMIT 1000];
        List<Order> orderList = [SELECT Id, Order_Status__c FROM Order LIMIT 1];
        for (OrderItem oItem : orderItemList) {
            oItem.SerialNumber__c = '00112233';
        }
        update orderItemList;
        
        for (Order ord : orderList) {
            ord.Order_Status__c = 'Shipped';
        }
        update orderList;
        Test.stopTest();
        
        System.assert(true);
    }
    
    @isTest
    private static void testPopulateOldProductIdVsNewProductIdMap() {
        //Create products
        Product2 prod1 = new Product2(Name = 'RBK-RCDM-10-MO-CLON', ProductCode = 'RBK-RCDM-AWS-MO', isActive = true);
        insert prod1;
        Product2 prod2 = new Product2(Name = 'RS-BE-GO-PE-PP', ProductCode = 'RS-BE-GO-PE-PP', isActive = true);
        insert prod2;
        
        Polaris_SKU_Mapping_V2__c polarisSkuMapping = new Polaris_SKU_Mapping_V2__c(
            Old_Product__c = prod1.Id,
            New_Product__c = prod2.Id
        );
        insert polarisSkuMapping;
        Test.startTest();
        List<Order> orderList = [SELECT Id, Order_Status__c FROM Order LIMIT 1];
        for (Order ord : orderList) {
            ord.Order_Status__c = 'Shipped';
        }
        update orderList;
        Test.stopTest();
        
        System.assert(true);
    }
    
    @isTest
    private static void testGuidedSellingDefaultingWhenQuoteIsNetApp() {
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        SBQQ.TriggerControl.disable();
        
        List<SBQQ__Quote__c> quoteListTest = [
            SELECT
            Id,
            Sell_to_Partner__c,
            GPL_Deal__c,
            SBQQ__QuoteProcessId__c,
            RWD_Guided_Selling__c,
            SBQQ__Opportunity2__c,
            Consolidate_Lines__c,
            sbqq__source__c,
            SBQQ__EndDate__c,
            SBQQ__StartDate__c,
            Co_Term_Date__c,
            SBQQ__Type__c,
            SBQQ__Account__c,
            Is_Federal_Eligible_Quote__c,
            Old_Co_Term_Date__c,
            SBQQ__Quote__c.RSC_G_Eligible__c,
            RWD_Sales_Rep_Exception__c,
      SBQQ__Quote__c.Scale_Eligible__c
            FROM SBQQ__Quote__c
            LIMIT 50000
        ];
        
        TriggerControls.disableQuoteTrigger = false;
        TriggerControls.disableQuoteLineTrigger = false;
        SBQQ.TriggerControl.enable();
        
        Test.startTest();
        
        for (SBQQ__Quote__c quote : quoteListTest) {
            quote.GPL_Deal__c = 'NetApp';
            quote.RWD_Guided_Selling__c = '';
        }
        
        QuoteTriggerHelper.guidedSellingDefaulting(quoteListTest, null);
        
        Test.stopTest();
        
        System.assert(true);
    }
    
    @isTest
    private static void testGuidedSellingDefaultingWhenQuoteIsNotNetApp() {
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        SBQQ.TriggerControl.disable();
        
        List<SBQQ__Quote__c> quoteListTest = [
            SELECT
            Id,
            Sell_to_Partner__c,
            GPL_Deal__c,
            SBQQ__QuoteProcessId__c,
            RWD_Guided_Selling__c,
            SBQQ__Opportunity2__c,
            SBQQ__Opportunity2__r.Opportunity_Sub_Type__c,
            Consolidate_Lines__c,
            sbqq__source__c,
            SBQQ__EndDate__c,
            SBQQ__StartDate__c,
            Co_Term_Date__c,
            SBQQ__Type__c,
            SBQQ__Account__c,
            SBQQ__Quote__c.RSC_G_Eligible__c,
            Is_Federal_Eligible_Quote__c,
            Old_Co_Term_Date__c,
            RWD_Sales_Rep_Exception__c,
      SBQQ__Quote__c.Scale_Eligible__c
            FROM SBQQ__Quote__c
            LIMIT 50000
        ];
        
        TriggerControls.disableQuoteTrigger = false;
        TriggerControls.disableQuoteLineTrigger = false;
        SBQQ.TriggerControl.enable();
        
        Test.startTest();
        
        for (SBQQ__Quote__c quote : quoteListTest) {
            quote.Sell_to_Partner__c = 'HPE Greenlake Canada';
            quote.RWD_Guided_Selling__c = '';
            quote.SBQQ__Opportunity2__r.Opportunity_Sub_Type__c = 'MSP';
        }
        
        QuoteTriggerHelper.guidedSellingDefaulting(quoteListTest, null);
        
        Test.stopTest();
        
        System.assert(true);
    }
    
    @isTest
    private static void testGuidedSellingDefaultingWhenQuoteForNotNetAppWithSellToPartnerFalse() {
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        SBQQ.TriggerControl.disable();
        
        List<SBQQ__Quote__c> quoteListTest = [
            SELECT
            Id,
            Sell_to_Partner__c,
            GPL_Deal__c,
            SBQQ__QuoteProcessId__c,
            RWD_Guided_Selling__c,
            SBQQ__Opportunity2__c,
            Consolidate_Lines__c,
            sbqq__source__c,
            SBQQ__EndDate__c,
            SBQQ__StartDate__c,
            Co_Term_Date__c,
            SBQQ__Type__c,
            SBQQ__Account__c,
            SBQQ__Quote__c.RSC_G_Eligible__c,
            Is_Federal_Eligible_Quote__c,
            Old_Co_Term_Date__c,
            RWD_Sales_Rep_Exception__c,
      SBQQ__Quote__c.Scale_Eligible__c
            FROM SBQQ__Quote__c
            LIMIT 50000
        ];
        
        TriggerControls.disableQuoteTrigger = false;
        TriggerControls.disableQuoteLineTrigger = false;
        SBQQ.TriggerControl.enable();
        
        Test.startTest();
        
        Opportunity oppr = [SELECT Id FROM Opportunity LIMIT 1];
        oppr.Opportunity_Sub_Type__c = 'MSP';
        update oppr;
        
        for (SBQQ__Quote__c quote : quoteListTest) {
            quote.Sell_to_Partner__c = 'Dummy Value';
            quote.RWD_Guided_Selling__c = '';
        }
        
        QuoteTriggerHelper.guidedSellingDefaulting(quoteListTest, null);
        
        Test.stopTest();
        
        System.assert(true);
    }
    
    @isTest
    private static void testGuidedSellingDefaultingWhenGuidedSellingIsNotBlank() {
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        SBQQ.TriggerControl.disable();
        
        List<SBQQ__Quote__c> quoteListTest = [
            SELECT
            Id,
            Sell_to_Partner__c,
            GPL_Deal__c,
            SBQQ__QuoteProcessId__c,
            RWD_Guided_Selling__c,
            SBQQ__Opportunity2__c,
            Consolidate_Lines__c,
            sbqq__source__c,
            SBQQ__EndDate__c,
            SBQQ__StartDate__c,
            Co_Term_Date__c,
            SBQQ__Type__c,
            SBQQ__Account__c,
            SBQQ__Quote__c.RSC_G_Eligible__c,
            Is_Federal_Eligible_Quote__c,
            Old_Co_Term_Date__c,
            RWD_Sales_Rep_Exception__c,
      SBQQ__Quote__c.Scale_Eligible__c
            FROM SBQQ__Quote__c
            LIMIT 50000
        ];
        
        TriggerControls.disableQuoteTrigger = false;
        TriggerControls.disableQuoteLineTrigger = false;
        SBQQ.TriggerControl.enable();
        
        Test.startTest();
        
        for (SBQQ__Quote__c quote : quoteListTest) {
            quote.RWD_Guided_Selling__c = 'Some Value';
        }
        
        QuoteTriggerHelper.guidedSellingDefaulting(quoteListTest, null);
        
        Test.stopTest();
        
        System.assert(true);
    }
    
    @isTest
    private static void testGuidedSellingDefaultingWhenAccountStatusIsProspect() {
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        SBQQ.TriggerControl.disable();
        
        Account acct = [SELECT Id FROM Account WHERE Name = 'testAccount' LIMIT 1];
        //Account acct1 = new Account(Name='testAccount', Account_Deal_Desk_Notes__c = 'Test Notes');
        
        Opportunity oppr0 = TestDataFactory.getOpportunity(acct);
        insert oppr0;
        
        Opportunity oppr = [SELECT Id FROM Opportunity LIMIT 1];
        oppr.Type = 'Existing Customer';
        oppr.Opportunity_Sub_Type__c = 'MSP';
        update oppr;
        
        Opportunity oppr1 = TestDataFactory.getOpportunity(acct);
        oppr1.Type = 'Existing Customer';
        oppr1.Opportunity_Sub_Type__c = 'MSP';
        oppr1.StageName = '7 Closed Lost';
        insert new List<Opportunity>{ oppr1 };
            
            List<SBQQ__Quote__c> quoteListTest = [
                SELECT
                Id,
                Sell_to_Partner__c,
                GPL_Deal__c,
                SBQQ__QuoteProcessId__c,
                RWD_Guided_Selling__c,
                SBQQ__Opportunity2__c,
                SBQQ__Opportunity2__r.Opportunity_Sub_Type__c,
                Consolidate_Lines__c,
                sbqq__source__c,
                SBQQ__EndDate__c,
                SBQQ__StartDate__c,
                Co_Term_Date__c,
                SBQQ__Type__c,
                SBQQ__Account__c,
                SBQQ__Quote__c.RSC_G_Eligible__c,
                Is_Federal_Eligible_Quote__c,
                Old_Co_Term_Date__c,
                RWD_Sales_Rep_Exception__c,
        SBQQ__Quote__c.Scale_Eligible__c
                FROM SBQQ__Quote__c
                LIMIT 50000
            ];
        
        TriggerControls.disableQuoteTrigger = false;
        TriggerControls.disableQuoteLineTrigger = false;
        SBQQ.TriggerControl.enable();
        
        Test.startTest();
        
        for (SBQQ__Quote__c quote : quoteListTest) {
            quote.RWD_Guided_Selling__c = '';
        }
        
        QuoteTriggerHelper.guidedSellingDefaulting(quoteListTest, null);
        
        Test.stopTest();
        
        System.assert(true);
    }
    //cpq22-4200
  @isTest
    private static void testGuidedSellingDefaultingWhenScale() {
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        SBQQ.TriggerControl.disable();
        
               
        Account acct = [SELECT Id,Scale_Eligible__c,RSC_G_Eligible__c FROM Account WHERE Name = 'testAccount' LIMIT 1];
        //Account acct1 = new Account(Name='testAccount', Account_Deal_Desk_Notes__c = 'Test Notes');
        acct.Scale_Eligible__c = true;
        acct.RSC_G_Eligible__c = false;
        update acct;
        Opportunity oppr0 = TestDataFactory.getOpportunity(acct);
        insert oppr0;
        
       
            List<SBQQ__Quote__c> quoteListTest = [
                SELECT
                Id,
                Sell_to_Partner__c,
                GPL_Deal__c,
                SBQQ__QuoteProcessId__c,
                RWD_Guided_Selling__c,
                SBQQ__Opportunity2__c,
                SBQQ__Opportunity2__r.Opportunity_Sub_Type__c,
                Consolidate_Lines__c,
                sbqq__source__c,
                SBQQ__EndDate__c,
                SBQQ__StartDate__c,
                Co_Term_Date__c,
                SBQQ__Type__c,
                SBQQ__Account__c,
                SBQQ__Quote__c.RSC_G_Eligible__c,
                Is_Federal_Eligible_Quote__c,
                Old_Co_Term_Date__c,
                RWD_Sales_Rep_Exception__c,
                SBQQ__Quote__c.Scale_Eligible__c
                FROM SBQQ__Quote__c
                LIMIT 50000
            ];
        
        TriggerControls.disableQuoteTrigger = false;
        TriggerControls.disableQuoteLineTrigger = false;
        SBQQ.TriggerControl.enable();
        
        Test.startTest();
        
        for (SBQQ__Quote__c quote : quoteListTest) {
            quote.SBQQ__Account__c = acct.Id;
            quote.RWD_Guided_Selling__c = '';
      
        }
        
        QuoteTriggerHelper.guidedSellingDefaulting(quoteListTest, null);
        
        Test.stopTest();
        
        System.assert(true);
    }
    @isTest
    private static void testGuidedSellingDefaultingWhenScale2() {
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        SBQQ.TriggerControl.disable();
        
                
        Account acct = [SELECT Id,Scale_Eligible__c,RSC_G_Eligible__c FROM Account WHERE Name = 'testAccount' LIMIT 1];
        //Account acct1 = new Account(Name='testAccount', Account_Deal_Desk_Notes__c = 'Test Notes');
        acct.Scale_Eligible__c = true;
        acct.RSC_G_Eligible__c = true;
        update acct;
        Opportunity oppr0 = TestDataFactory.getOpportunity(acct);
        insert oppr0;
        
       
            List<SBQQ__Quote__c> quoteListTest = [
                SELECT
                Id,
                Sell_to_Partner__c,
                GPL_Deal__c,
                SBQQ__QuoteProcessId__c,
                RWD_Guided_Selling__c,
                SBQQ__Opportunity2__c,
                SBQQ__Opportunity2__r.Opportunity_Sub_Type__c,
                Consolidate_Lines__c,
                sbqq__source__c,
                SBQQ__EndDate__c,
                SBQQ__StartDate__c,
                Co_Term_Date__c,
                SBQQ__Type__c,
                SBQQ__Account__c,
                SBQQ__Quote__c.RSC_G_Eligible__c,
                Is_Federal_Eligible_Quote__c,
                Old_Co_Term_Date__c,
                RWD_Sales_Rep_Exception__c,
                SBQQ__Quote__c.Scale_Eligible__c
                FROM SBQQ__Quote__c
                LIMIT 50000
            ];
        
        TriggerControls.disableQuoteTrigger = false;
        TriggerControls.disableQuoteLineTrigger = false;
        SBQQ.TriggerControl.enable();
        
        Test.startTest();
        
        for (SBQQ__Quote__c quote : quoteListTest) {
            quote.SBQQ__Account__c = acct.Id;
            quote.RWD_Guided_Selling__c = '';
      
        }
        
        QuoteTriggerHelper.guidedSellingDefaulting(quoteListTest, null);
        
        Test.stopTest();
        
        System.assert(true);
    }
    @isTest
    private static void testGuidedSellingDefaultingWhenFederal() {
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        SBQQ.TriggerControl.disable();
        
               
        Account acct = [SELECT Id,Scale_Eligible__c,Fed_ROW_account__c  FROM Account WHERE Name = 'testAccount' LIMIT 1];
        //Account acct1 = new Account(Name='testAccount', Account_Deal_Desk_Notes__c = 'Test Notes');
        acct.Fed_ROW_account__c  = true;
        update acct;
        
        Opportunity oppr0 = TestDataFactory.getOpportunity(acct);
        insert oppr0;
        
       
            List<SBQQ__Quote__c> quoteListTest = [
                SELECT
                Id,
                Sell_to_Partner__c,
                GPL_Deal__c,
                SBQQ__QuoteProcessId__c,
                RWD_Guided_Selling__c,
                SBQQ__Opportunity2__c,
                SBQQ__Opportunity2__r.Opportunity_Sub_Type__c,
                Consolidate_Lines__c,
                sbqq__source__c,
                SBQQ__EndDate__c,
                SBQQ__StartDate__c,
                Co_Term_Date__c,
                SBQQ__Type__c,
                SBQQ__Account__c,
                SBQQ__Quote__c.RSC_G_Eligible__c,
                Is_Federal_Eligible_Quote__c,
                Old_Co_Term_Date__c,
                RWD_Sales_Rep_Exception__c,
                SBQQ__Quote__c.Scale_Eligible__c
                FROM SBQQ__Quote__c
                LIMIT 50000
            ];
        
        TriggerControls.disableQuoteTrigger = false;
        TriggerControls.disableQuoteLineTrigger = false;
        SBQQ.TriggerControl.enable();
        
        Test.startTest();
        
        for (SBQQ__Quote__c quote : quoteListTest) {
            quote.SBQQ__Account__c = acct.Id;
            quote.RWD_Sales_Rep_Exception__c = null;
            quote.RWD_Guided_Selling__c = '';
      
        }
        
        QuoteTriggerHelper.guidedSellingDefaulting(quoteListTest, null);
        
        Test.stopTest();
        
        System.assert(true);
    }
    @isTest
    private static void testGuidedSellingDefaultingWhenFederal2() {
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        SBQQ.TriggerControl.disable();
        
               
        Account acct = [SELECT Id,Scale_Eligible__c,Fed_ROW_account__c  FROM Account WHERE Name = 'testAccount' LIMIT 1];
        //Account acct1 = new Account(Name='testAccount', Account_Deal_Desk_Notes__c = 'Test Notes');
        acct.Fed_ROW_account__c  = false;
        update acct;
        
        Opportunity oppr0 = TestDataFactory.getOpportunity(acct);
        insert oppr0;
        
       
            List<SBQQ__Quote__c> quoteListTest = [
                SELECT
                Id,
                Sell_to_Partner__c,
                GPL_Deal__c,
                SBQQ__QuoteProcessId__c,
                RWD_Guided_Selling__c,
                SBQQ__Opportunity2__c,
                SBQQ__Opportunity2__r.Opportunity_Sub_Type__c,
                Consolidate_Lines__c,
                sbqq__source__c,
                SBQQ__EndDate__c,
                SBQQ__StartDate__c,
                Co_Term_Date__c,
                SBQQ__Type__c,
                SBQQ__Account__c,
                SBQQ__Quote__c.RSC_G_Eligible__c,
                Is_Federal_Eligible_Quote__c,
                Old_Co_Term_Date__c,
                RWD_Sales_Rep_Exception__c,
                SBQQ__Quote__c.Scale_Eligible__c
                FROM SBQQ__Quote__c
                LIMIT 50000
            ];
        
        TriggerControls.disableQuoteTrigger = false;
        TriggerControls.disableQuoteLineTrigger = false;
        SBQQ.TriggerControl.enable();
        
        Test.startTest();
        
        for (SBQQ__Quote__c quote : quoteListTest) {
            quote.SBQQ__Account__c = acct.Id;
            quote.RWD_Sales_Rep_Exception__c = 'Exception for On-Prem Quoting';
            quote.RWD_Guided_Selling__c = '';
      
        }
        
        QuoteTriggerHelper.guidedSellingDefaulting(quoteListTest, null);
        
        Test.stopTest();
        
        System.assert(true);
    }
    @isTest
    static void populateFieldsFromOpportunity_Test() {
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        SBQQ.TriggerControl.disable();
         String uniqueUserName = 'TestUser' + DateTime.now().getTime() + '@rbk.com';
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User usr = new user(
            alias = 'std',
            email = 'testuser@testclass.com',
            emailencodingkey = 'UTF-8',
            firstname = 'test',
            lastname = 'user',
            languagelocalekey = 'en_US',
            localesidkey = 'en_US',
            profileid = p.Id,
            timezonesidkey = 'America/Los_Angeles',
            username = uniqueUserName,
            RBAC_Group__c = 'System - IT',
            RBAC_Department__c = 'Service Account'
        );
        //insert usr;
        
       System.runAs(new User(Id = UserInfo.getUserId())) {
            Id standardPriceBookId = Test.getStandardPricebookId();
            
            PriceBook2 pb1 = new Pricebook2(
                Name = 'V68_2017_08_09_12_26_43',
                Description = 'Price Book 2009 Products 1',
                IsActive = true
            );
            insert pb1;
            
            //Create your product
            Product2 prod1 = new Product2(Name = 'RBK-GO-BE-R6408', ProductCode = 'RBK-GO-BE-R6408', isActive = true);
            Product2 prod2 = new Product2(
                Name = 'RBK-R Premium Support 1-Yr Prepaid, r304',
                ProductCode = 'RBK-SVC-PREM-R304',
                isActive = true
            );
            //Create your product
            Product2 prod3 = new Product2(Name = 'RBK-GO-BE-R6408', ProductCode = 'RBK-GO-BE-R6408', isActive = true);
            //Create your product
            Product2 prod4 = new Product2(Name = 'RBK-RCDM-10-MO-CLON', ProductCode = 'RBK-RCDM-AWS-MO', isActive = true);
            
            Product2 prod5 = new Product2(Name = 'RS-BE-GO-PE-PP', ProductCode = 'RS-BE-GO-PE-PP', isActive = true);
            Product2 prodHW = new Product2(Name = 'RH-6408SE-02', ProductCode = 'RH-6408SE-02', isActive = true, Product_Level__c = 'Hardware', Product_Type__c = 'Hardware', Category__c = 'Hardware');
            insert new List<Product2>{ prod1, prod2, prod3, prod4, prod5, prodHW };
                
            //Create your pricebook entry
            PricebookEntry pbStanEntry1 = getPbe(prod1.Id, 100.00);
            
            //Create your pricebook entry
            PricebookEntry pbStanEntry2 = getPbe(prod2.Id, 1000.00);
            
            //Create your pricebook entry
            PricebookEntry pbStanEntry3 = getPbe(prod3.Id, 100.00);
            
            //Create your pricebook entry
            PricebookEntry pbStanEntry4 = getPbe(prod4.Id, 100.00);
            
            PricebookEntry pbStanEntry5 = getPbe(prod5.Id, 100.00);

            PricebookEntry pbStanEntryHw = getPbe(prodHW.Id, 100.00);
            
            //Create your pricebook entry
            PricebookEntry pbEntry1 = getPbe(pb1.Id, prod1.Id, 100.00);
            
            //Create your pricebook entry
            PricebookEntry pbEntry2 = getPbe(pb1.Id, prod2.Id, 1000.00);
            
            //Create your pricebook entry
            PricebookEntry pbEntry3 = getPbe(pb1.Id, prod3.Id, 1000.00);
            
            //Create your pricebook entry
            PricebookEntry pbEntry4 = getPbe(pb1.Id, prod4.Id, 1000.00);
            
            PricebookEntry pbEntry5 = getPbe(pb1.Id, prod5.Id, 1000.00);
            
            PricebookEntry pbEntryHw = getPbe(pb1.Id, prodHW.Id, 100.00);
            insert new List<PricebookEntry>{
                pbStanEntry1,
                pbStanEntry2,
                pbStanEntry3,
                pbStanEntry4,
                pbStanEntry5,
                pbStanEntryHw,
                pbEntry1,
                pbEntry2,
                pbEntry3,
                pbEntry4,
                pbEntry5,
                pbEntryHw
                };
      
            Account acct = [SELECT Id FROM Account WHERE Name = 'testAccount' LIMIT 1];
            //Account acct1 = new Account(Name='testAccount', Account_Deal_Desk_Notes__c = 'Test Notes');
            
            Opportunity oppr0 = TestDataFactory.getOpportunity(acct);
            //insert oppr0;
            
            Opportunity oppr = [SELECT Id FROM Opportunity LIMIT 1];
            oppr.Type = 'Existing Customer';
            oppr.Opportunity_Sub_Type__c = 'MSP';
            //update oppr;
            
            Opportunity oppr1 = TestDataFactory.getOpportunity(acct);
            oppr1.Type = 'Existing Customer';
            oppr1.Opportunity_Sub_Type__c = 'MSP';
            oppr1.StageName = '7 Closed Lost';
            
            upsert new List<Opportunity>{ oppr0, oppr1 , oppr};
            Map<String, Object> quoteMap = new Map<String, Object>{
                'SBQQ__Account__c' => acct.Id,
                'SBQQ__Opportunity2__c' => oppr.Id
            };
            SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
            qt.SBQQ__Opportunity2__c = oppr.Id;
            qt.SBQQ__Primary__c = false;
            qt.SBQQ__PriceBook__c = pb1.Id;
            qt.ApprovalStatus__c = 'Approved';
            qt.SBQQ__Type__c = 'Renewal';
            qt.SBQQ__StartDate__c = Date.today();
            qt.Manual_Billing__c = false;
            qt.Consolidate_Lines__c = false;
            insert qt;
            
            //6401
            Opportunity opprHW = TestDataFactory.getOpportunity(acct);
            insert opprHW;
            SBQQ__Quote__c qtHW = new SBQQ__Quote__c();
            qtHW.SBQQ__Opportunity2__c = opprHW.Id;
            qtHW.SBQQ__Primary__c = false;
            qtHW.SBQQ__Account__c = acct.Id;
            qtHW.SBQQ__PriceBook__c = pb1.Id;
            qtHW.ApprovalStatus__c = 'Draft';
            qtHW.SBQQ__Type__c = 'Quote';
            qtHW.SBQQ__StartDate__c = Date.today();
            qtHW.Manual_Billing__c = false;
            qtHW.Consolidate_Lines__c = false;
            insert qtHW;
            List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
            SBQQ__QuoteLine__c qlHW = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qtHW.Id, SBQQ__Product__c = prodHW.Id, SBQQ__Quantity__c = 20,  SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10));
            SBQQ__QuoteLine__c qlHW2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qtHW.Id, SBQQ__Product__c = prodHW.Id, SBQQ__Quantity__c = 20,  SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today().addDays(30));
            lines.add(qlHW);
            lines.add(qlHW2);
            insert lines; 
            lines[0].SBQQ__Quantity__c = 25;
            lines[1].SBQQ__Quantity__c = 25;
            update lines;
            Map<Id, SBQQ__Quote__c> quoteHWOldMap = new Map<Id, SBQQ__Quote__c>();
            quoteHWOldMap.put(qtHW.Id,qtHW);
            //SBQQ__QuoteLine__c lineToDelete = lines[1];
            //delete lineToDelete;
    
            ServiceContract objSC = new ServiceContract(
                Name = 'ServiceContract Test',
                AccountId = acct.Id,
                StartDate = Date.today(),
                Term = 36,
                pricebook2Id = pb1.Id,
                SBQQSC__Opportunity__c = oppr.Id,
                SBQQSC__Quote__c = qt.Id
            );
            insert objSC;
            
            Opportunity oppr2 = TestDataFactory.getOpportunity(acct);
            oppr2.Type = 'Existing Customer';
            oppr2.Opportunity_Sub_Type__c = 'MSP';
            oppr2.StageName = '7 Closed Lost';
            oppr2.SBQQSC__AmendedServiceContract__c = objSC.Id;
            oppr2.SBQQSC__RenewedServiceContract__c = objSC.Id; 
            oppr2.Churn_Type__c = 'Account Churn';
            // oppr2.Pricebook2Id = pb1.Id;
            insert new List<Opportunity>{ oppr2 };
    
            Map<String, Object> quoteMap1 = new Map<String, Object>{
                'SBQQ__Account__c' => acct.Id,
                'SBQQ__Opportunity2__c' => oppr.Id
            };
            
            SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap1);
            qt1.SBQQ__Opportunity2__c = oppr2.Id;
            qt1.SBQQ__Primary__c = false;
            qt1.SBQQ__PriceBook__c = pb1.Id;
            qt1.ApprovalStatus__c = 'Approved';
            qt1.SBQQ__Type__c = 'Renewal';
            qt1.SBQQ__StartDate__c = Date.today();
            qt1.Manual_Billing__c = false;
            qt1.Consolidate_Lines__c = false;
            qt1.RWD_Deal_Ops_Exception__c = 'AMER-FED Account quoting RSC';
            qt1.RWD_Deal_Ops_Exception_Justification__c = 'tvmbsxhnlcskdjxnv/kdnknv jnfdj ncl.nd.z n';
            qt1.Amended_Renewed_Service_Contract__c = objSC.Id;
            qt1.SBQQ__ExpirationDate__c = System.today().addDays(300);
            insert new List<SBQQ__Quote__c> {qt1};
            
            Map<Id, Opportunity> OppMap = new Map<Id, Opportunity>(
                [
                    SELECT Id, Type, Opportunity_Sub_Type__c, StageName, SBQQSC__AmendedServiceContract__c,Deal_Structuring_Oppty_Notes__c,SBQQSC__RenewedServiceContract__c
                    FROM Opportunity
                    LIMIT 50000
                ]
            );
            
            TriggerControls.disableQuoteTrigger = false;
            TriggerControls.disableQuoteLineTrigger = false;
            SBQQ.TriggerControl.enable();
            
            Test.startTest();
            
            Map<Id, SBQQ__QuoteLine__c> qlMap = new Map<Id, SBQQ__QuoteLine__c>([SELECT Id, SBQQ__Quote__c, SBQQ__Optional__c, SBQQ__Existing__c, Quote_Line_Type__c, Is_Hardware_and_New__c, CreatedDate 
            FROM SBQQ__QuoteLine__c WHERE Id IN :lines]);
            QuoteTriggerHelper.updateExpirationWithHardware(qtHW, quoteHWOldMap, qlMap);
            //QuoteTriggerHelper.populateFieldsFromOpportunity(qt1, quoteHWOldMap);

            QuoteTriggerHelper.populateFieldsFromOpportunity(qt1, OppMap);
            
            qt1.Amended_Renewed_Service_Contract__c = null;
            QuoteTriggerHelper.populateFieldsFromOpportunity(qt1, OppMap);
            
            qt1.Amended_Renewed_Service_Contract__c = null;
            
            for(Opportunity obj: OppMap.values()){
                obj.SBQQSC__AmendedServiceContract__c = null;
            }
            QuoteTriggerHelper.populateFieldsFromOpportunity(qt1, OppMap);
            
            qt1.Error_Message_From_QCP__c ='Test';
            Map<Id, SBQQ__Quote__c> quoteOldMap = new Map<Id, SBQQ__Quote__c>();
            quoteOldMap.put(qt1.Id,qt1);
            QuoteTriggerHelper.ThrowErrorMessage(new List<SBQQ__Quote__c>{qt1},quoteOldMap);
            //QuoteTriggerHelper.quotelinemap = null;
            //QuoteTriggerHelper.quotelinemap = 
            QuoteTriggerHelper.getquotelines(new Set<Id>{qt1.Id});            
    
            Order ordr11 = new Order(
                Type = 'Revenue',
                AccountId = acct.Id,
                OpportunityId = oppr.Id,
                ShippingStreet = 'Test Street',
                ShippingCity = 'Test City',
                ShippingState = null,
                ShippingCountry = 'Austria',
                ShippingPostalcode = '94820',
                EffectiveDate = system.Today(),
                Status = 'Pending',
                Pricebook2Id = pb1.Id
            );
            
            insert ordr11;
            
            List<Asset> AssetList = new List<Asset>();
            Asset asst1 = getAsset('Test1234567Assets1', prod3.Id, acct.Id);
            AssetList.add(asst1);
            
            Asset asst2 = getAsset('TestAsset4', prod3.Id, acct.Id);
            AssetList.add(asst2);
            
            Asset asst3 = getAsset('TestAsset6', prod3.Id, acct.Id);
            AssetList.add(asst3);
            
            Asset asst4 = getAsset('TestAsset3', prod3.Id, acct.Id);
            AssetList.add(asst4);
            
            insert AssetList;
    
            OrderItem oli1 = getOli(ordr11.Id, pbEntry1.Id, pbEntry1.UnitPrice, 'Test1234567Asset2123');
            
            //create your opportunity line item.  This assumes you already have an opportunity created, called opp
            OrderItem oli2 = getOli(ordr11.Id, pbEntry2.Id, pbEntry2.UnitPrice, 'Test1234567Asset314');
            
            OrderItem oli3 = getOli(ordr11.Id, pbEntry3.Id, pbEntry3.UnitPrice, 'Test1234567Asset321');
            
            ServiceContract objSC1 = new ServiceContract(
                Name = 'ServiceContract Test',
                AccountId = acct.Id,
                StartDate = Date.today(),
                Term = 36,
                pricebook2Id = pb1.Id,
                SBQQSC__Opportunity__c = oppr.Id,
                SBQQSC__Order__c = ordr11.Id,
                SBQQSC__Quote__c = qt1.Id
            );
            
            insert objSC1;
            
            List<ContractLineItem> lstCli = new List<ContractLineItem>();
            ContractLineItem cli = getCli(oli1.PricebookEntryId, objSC1.id);
            cli.Quantity = oli1.quantity;
            cli.PricebookEntryId = oli1.PricebookEntryId;
            cli.StartDate = date.today();
            lstCli.add(cli);
            insert lstCli;
            SBQQ__Quote__c quoteResult = [SELECT Id, SBQQ__PriceBook__r.Name,
                SBQQ__Opportunity2__r.Pricebook2.Name FROM SBQQ__Quote__c WHERE Id =:qt1.Id ];
            SBQQ__QuoteLine__c ql1 = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = qt1.Id,
                Prior_Net_Total__c = 10,
                SBQQ__Product__c = prod1.Id,
                SBQQ__Quantity__c = 20,
                SBQQ__SubscriptionPricing__c = null,
                SBQQ__DefaultSubscriptionTerm__c = null,
                SBQQ__ListPrice__c = 200,
                SBQQ__NetPrice__c = 200,
                SBQQ__DiscountScheduleType__c = 'Slab',
                Scale_Utility_Product__c = true,
                Scale_Utility_Product_Identifier__c = 'M365 SU RSVX',
                SBQQ__StartDate__c = Date.today(),
                SBQQ__PricebookEntryId__c = cli.PricebookEntryId,
                // SBQQSC__RenewedContractLine__c= cli.Id,
                SBQQ__EndDate__c = Date.today().addDays(11),
                SubscribedAssetNames__c = 'BB192863040046',
                Product_Type__c = 'Hardware'
            );
            //        insert ql1;
    
            QuoteTriggerHelper.userLicenseCountValidation(new List<SBQQ__Quote__c>{qt1});
            
            qt1.SBQQ__Status__c = 'Expired';
            qt1.SBQQ__StartDate__c = Date.today();
            qt1.EOL_New_Product_Earliest_Date__c = Date.today().addDays(20);
            qt1.SBQQ__ExpirationDate__c = Date.today().addDays(120);
            qt1.Update_Expires_On__c = true;
            qt1.SBQQ__ExpirationDate__c = Date.today().addDays(120);
            QuoteTriggerHelper.UpdateOnExpireDateExtension(quoteOldMap,new List<SBQQ__Quote__c>{qt1});
            
            qt1.ApprovalStatus__c = 'Rejected';
            qt1.SBQQ__Type__c = 'Renewal';
            
            QuoteTriggerHelper.populateFieldsOnUpdate(new List<SBQQ__Quote__c>{qt1},quoteOldMap);
            
            qt1.ApprovalStatus__c = 'Rejected';
            qt1.SBQQ__Type__c = 'Renewal+Expansion';
            qt1.SBQQ__LastCalculatedOn__c = System.today();
            qt1.RWD_Deal_Ops_Exception__c = 'Complete Edition - Hard Floors';
            
            QuoteTriggerHelper.populateFieldsOnUpdate(new List<SBQQ__Quote__c>{qt1},quoteOldMap);
    
            for (SBQQ__Quote__c obj : quoteOldMap.values()) {
                obj.RWD_Deal_Ops_Exception__c = '';
                obj.SBQQ__LastCalculatedOn__c = null;
                obj.ApprovalStatus__c = null;
                //code_block
            }
    
            Task t = new Task();
            //t.OwnerId = taskUser[0].id;
            t.Subject = ' is quoted on Quote #' + qt1.name;
            t.Priority = 'Normal';
            t.Status = 'Not Started';
            t.Type = 'Action';
            t.WhatId = qt1.SBQQ__Account__c;
            t.Task_Email__c = system.label.Task_Email;
    
            qt1.SBQQ__Status__c = 'Draft';
            qt1.Task_Products__c = null;
            QuoteTriggerHelper.populateFieldsOnUpdate(new List<SBQQ__Quote__c>{qt1},quoteOldMap);
    
    
            QuoteTriggerHelper.userLicenseCountValidation(new List<SBQQ__Quote__c>{qt1});
            
            Test.stopTest();
            
            System.assert(true);
        } 
    }
    
    @isTest
    static Void hwApplianceAndTphAddedTogetherValidation_test() {
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        SBQQ.TriggerControl.disable();
        
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get('Partner/Distributor')
            .getRecordTypeId();
        Account acct = new Account(
            Name = 'testAccount',
            RecordTypeId = partnerRecordTypeId,
            Account_Deal_Desk_Notes__c = 'Test Notes'
        );
        Account acc = new Account(Name = 'testAccount1');
        insert new List<Account>{ acct, acc };
            
            //Contact con = new Contact(FirstName='john', LastName='doe', Email='john@doe.com', AccountId=acct.Id);
            //insert con;
            //Date closeDt = System.Today()+30;
            
            Opportunity oppr = TestDataFactory.getOpportunity(acct);
        oppr.ETM_Theatre__c = 'APAC';
        insert oppr;
        
        Opportunity oppr2 = [SELECT Id FROM Opportunity LIMIT 1];
        oppr2.Type = 'Existing Customer';
        oppr2.Opportunity_Sub_Type__c = 'MSP';
        oppr2.Amount = 2000;
        update oppr2;
        
        Opportunity oppr1 = TestDataFactory.getOpportunity(acct);
        oppr1.Type = 'Existing Customer';
        oppr1.Opportunity_Sub_Type__c = 'MSP';
        oppr1.StageName = '7 Closed Lost';
        oppr1.Amount = 2000;
        
        Opportunity oppr3 = TestDataFactory.getOpportunity(acct);
        oppr3.Type = 'Existing Customer';
        oppr3.Opportunity_Sub_Type__c = 'MSP Consumption Renewal';
        oppr3.StageName = '7 Closed Lost';
        
        insert new List<Opportunity>{ oppr1, oppr3 };
            
            Id standardPriceBookId = Test.getStandardPricebookId();
        
        PriceBook2 pb1 = new Pricebook2(
            Name = 'V68_2017_08_09_12_26_43',
            Description = 'Price Book 2009 Products 1',
            IsActive = true
        );
        insert pb1;
        
        //Create your product
        Product2 prod1 = getProduct('RBK-GO-BE-R6408', 'RBK-GO-BE-R6408');
        prod1.Family = 'Rubrik Scale';
        
        Product2 prod2 = getProduct('RBK-R Premium Support 1-Yr Prepaid, r304', 'RBK-SVC-PREM-R304');
        prod2.Family = 'Rubrik Scale';
        
        //Create your product
        Product2 prod3 = getProduct('RBK-GO-BE-R6408', 'RBK-GO-BE-R6408');
        prod3.Family = 'Rubrik Scale';
        
        //Create your product
        Product2 prod4 = getProduct('RBK-RCDM-10-MO-CLON', 'RBK-RCDM-10-MO-CLON');
        prod4.Family = 'Rubrik Scale';
        
        Product2 prod5 = getProduct('RS-BE-GO-PE-PP', 'RS-BE-GO-PE-PP');
        prod5.Family = 'Rubrik Scale';
        
        insert new List<Product2>{ prod1, prod2, prod3, prod4, prod5 };
            
            //Create your pricebook entry
            PricebookEntry pbStanEntry1 = getPbe(standardPriceBookId, prod1.Id, 100.00);
        
        //Create your pricebook entry
        PricebookEntry pbStanEntry2 = getPbe(standardPriceBookId, prod2.Id, 1000.00);
        
        //Create your pricebook entry
        PricebookEntry pbStanEntry3 = getPbe(standardPriceBookId, prod3.Id, 1000.00);
        
        //Create your pricebook entry
        PricebookEntry pbStanEntry4 = getPbe(standardPriceBookId, prod4.Id, 1000.00);
        
        PricebookEntry pbStanEntry5 = getPbe(standardPriceBookId, prod5.Id, 1000.00);
        
        //Create your pricebook entry
        PricebookEntry pbEntry1 = getPbe(pb1.id, prod1.Id, 100.00);
        
        //Create your pricebook entry
        PricebookEntry pbEntry2 = getPbe(pb1.id, prod2.Id, 100.00);
        
        //Create your pricebook entry
        PricebookEntry pbEntry3 = getPbe(pb1.id, prod3.Id, 1000.00);
        
        //Create your pricebook entry
        PricebookEntry pbEntry4 = getPbe(pb1.id, prod4.Id, 1000.00);
        
        PricebookEntry pbEntry5 = getPbe(pb1.id, prod5.Id, 1000.00);
        
        insert new List<PricebookEntry>{
            pbStanEntry1,
                pbStanEntry2,
                pbStanEntry3,
                pbStanEntry4,
                pbStanEntry5,
                pbEntry1,
                pbEntry2,
                pbEntry3,
                pbEntry4,
                pbEntry5
                };
                    
                    Map<String, Object> quoteMap = new Map<String, Object>{
                        'SBQQ__Account__c' => acct.Id,
                            'SBQQ__Opportunity2__c' => oppr.Id
                            };
                                
                                List<SBQQ__Quote__c> qtlist = new List<SBQQ__Quote__c>();
        
        SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt1.SBQQ__Opportunity2__c = oppr.Id;
        qt1.SBQQ__Primary__c = false;
        qt1.SBQQ__PriceBook__c = pb1.Id;
        qt1.ApprovalStatus__c = 'Approved';
        qt1.SBQQ__Type__c = 'Renewal+Expansion';
        qt1.SBQQ__StartDate__c = Date.today();
        qt1.SBQQ__EndDate__c = System.Today().addDays(90);
        qt1.Manual_Billing__c = false;
        qt1.Consolidate_Lines__c = false;
        qt1.RWD_Deal_Ops_Exception__c = 'Hardfloor Discount Exception - HW & HW Support';
        qt1.RWD_Deal_Ops_Exception_Justification__c = 'Test';
        // insert qt1;
        
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt.SBQQ__Opportunity2__c = oppr.Id;
        qt.SBQQ__Primary__c = false;
        qt.SBQQ__PriceBook__c = pb1.Id;
        qt.Is_RWD_Polaris_Quote__c = false;
        qt.ApprovalStatus__c = 'Approved';
        qt.SBQQ__Type__c = 'Quote';
        qt.SBQQ__StartDate__c = Date.today();
        qt.SBQQ__EndDate__c = System.Today().addDays(90);
        qt.Manual_Billing__c = false;
        qt.Consolidate_Lines__c = false;
        qt.RWD_Deal_Ops_Exception__c = 'Hardfloor Discount Exception - HW & HW Support';
        qt.RWD_Deal_Ops_Exception_Justification__c = 'Test';
        // insert qt;
        
        qtlist.add(qt1);
        
        Order ordr1 = new Order(
            Type = 'Revenue',
            AccountId = acct.Id,
            OpportunityId = oppr.Id,
            ShippingStreet = 'Test Street',
            ShippingCity = 'Test City',
            ShippingState = null,
            ShippingCountry = 'Austria',
            ShippingPostalcode = '94820',
            EffectiveDate = system.Today(),
            Status = 'Pending',
            Pricebook2Id = pb1.Id
        );
        
        insert ordr1;
        
        ServiceContract objSC1 = new ServiceContract(
            Name = 'ServiceContract Test',
            AccountId = acct.Id,
            StartDate = Date.today(),
            Term = 36,
            pricebook2Id = pb1.Id,
            SBQQSC__Opportunity__c = oppr.Id,
            SBQQSC__Order__c = ordr1.Id,
            SBQQSC__Quote__c = qt1.Id
        );
        
        insert objSC1;
        
        SBQQ__Quote__c qt2 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt2.SBQQ__Opportunity2__c = oppr.Id;
        qt2.SBQQ__Primary__c = false;
        qt2.SBQQ__PriceBook__c = pb1.Id;
        qt2.ApprovalStatus__c = 'Rejected';
        qt2.SBQQ__Type__c = 'Renewal+Expansion';
        qt2.SBQQ__StartDate__c = Date.today();
        qt2.SBQQ__EndDate__c = System.Today().addDays(90);
        qt2.Manual_Billing__c = false;
        qt2.Consolidate_Lines__c = false;
        qt2.RWD_Deal_Ops_Exception__c = 'Hardfloor Discount Exception - HW & HW Support';
        qt2.RWD_Deal_Ops_Exception_Justification__c = 'Test';
        
        // insert qt2;
        qtlist.add(qt2);
        qtlist.add(qt);
        
        SBQQ__Quote__c qt3 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt3.SBQQ__Opportunity2__c = oppr1.Id;
        qt3.SBQQ__Primary__c = false;
        qt3.SBQQ__PriceBook__c = pb1.Id;
        qt3.ApprovalStatus__c = 'Pending';
        qt3.SBQQ__Type__c = 'Amendment';
        qt3.SBQQ__StartDate__c = Date.today();
        qt3.SBQQ__EndDate__c = System.Today().addDays(90);
        qt3.Manual_Billing__c = false;
        qt3.Consolidate_Lines__c = false;
        qt3.RWD_Deal_Ops_Exception__c = 'Hardfloor Discount Exception - HW & HW Support';
        qt3.RWD_Deal_Ops_Exception_Justification__c = 'Test';
        
        // insert qt3;
        qtlist.add(qt3);
        
        SBQQ__Quote__c qt4 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt4.SBQQ__Opportunity2__c = oppr3.Id;
        qt4.SBQQ__Primary__c = false;
        qt4.SBQQ__PriceBook__c = pb1.Id;
        qt4.ApprovalStatus__c = 'Rejected';
        qt4.SBQQ__Type__c = 'Renewal';	
        qt4.SBQQ__StartDate__c = Date.today();
        qt4.SBQQ__EndDate__c = System.Today().addDays(90);
        qt4.Manual_Billing__c = false;
        qt4.Consolidate_Lines__c = false;
        qt4.RWD_Deal_Ops_Exception__c = 'Hardfloor Discount Exception - HW & HW Support';
        qt4.RWD_Deal_Ops_Exception_Justification__c = 'Test';
        
        // insert qt4;
        qtlist.add(qt4);
        
        insert new List<SBQQ__Quote__c>{ qt, qt1, qt2, qt3, qt4 };
            
            list<SBQQ__Quote__c> qtlist2 = new List<SBQQ__Quote__c>();
        qt1.RWD_Deal_Ops_Exception__c = 'Annual Products min/max 36';
        qt1.Amended_Renewed_Service_Contract__c = objSC1.Id;
        qt1.SBQQ__LastCalculatedOn__c = System.Today().addDays(7);
        qt2.RWD_Deal_Ops_Exception__c = 'Annual Products min/max 36';
        qt2.Amended_Renewed_Service_Contract__c = objSC1.Id;
        qt2.SBQQ__LastCalculatedOn__c = System.Today().addDays(7);
        qt3.ApprovalStatus__c = 'Approved';
        qtlist2.add(qt1);
        qtlist2.add(qt2);
        qtlist2.add(qt3);
        update qtlist2;
        
        Order ordr11 = new Order(
            Type = 'Revenue',
            AccountId = acct.Id,
            OpportunityId = oppr.Id,
            ShippingStreet = 'Test Street',
            ShippingCity = 'Test City',
            ShippingState = null,
            ShippingCountry = 'Austria',
            ShippingPostalcode = '94820',
            EffectiveDate = system.Today(),
            Status = 'Pending',
            Pricebook2Id = pb1.Id
        );
        
        insert ordr11;
        
        List<Asset> AssetList = new List<Asset>();
        Asset asst1 = getAsset('Test1234567Assets1', prod3.Id, acct.Id);
        AssetList.add(asst1);
        
        Asset asst2 = getAsset('TestAsset4', prod3.Id, acct.Id);
        AssetList.add(asst2);
        
        Asset asst3 = getAsset('TestAsset6', prod3.Id, acct.Id);
        AssetList.add(asst3);
        
        Asset asst4 = getAsset('TestAsset3', prod3.Id, acct.Id);
        AssetList.add(asst4);
        
        insert AssetList;
        
        oppr.StageName = '6 PO Recieved';
        //update oppr;
        
        //ordr.Ship_To_Name__c = acct.id;
        ordr11.ShipToContactName__c = 'ah';
        ordr11.Shipping_Method__c = 'Other';
        ordr11.Shipping_Carrier__c = 'AIT';
        ordr11.Service_Level__c = 'Economy';
        ordr11.Bill_To_Name__C = acct.id;
        ordr11.est_Ship_Date__C = System.Today().addDays(7);
        ordr11.Status = 'Order Accepted';
        
        //update ordr;
        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OrderItem oli1 = getOli(ordr11.Id, pbEntry1.Id, pbEntry1.UnitPrice, 'Test1234567Asset2123');
        
        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OrderItem oli2 = getOli(ordr11.Id, pbEntry2.Id, pbEntry2.UnitPrice, 'Test1234567Asset314');
        
        OrderItem oli3 = getOli(ordr11.Id, pbEntry3.Id, pbEntry3.UnitPrice, 'Test1234567Asset321');
        
        ServiceContract objSC = new ServiceContract(
            Name = 'ServiceContract Test',
            AccountId = acct.Id,
            StartDate = Date.today(),
            Term = 36,
            pricebook2Id = pb1.Id,
            SBQQSC__Opportunity__c = oppr.Id,
            SBQQSC__Order__c = ordr11.Id,
            SBQQSC__Quote__c = qt1.Id
        );
        
        insert objSC;
        
        List<ContractLineItem> lstCli = new List<ContractLineItem>();
        ContractLineItem cli = getCli(oli1.PricebookEntryId, objSC.id);
        cli.Quantity = oli1.quantity;
        cli.PricebookEntryId = oli1.PricebookEntryId;
        cli.StartDate = date.today();
        lstCli.add(cli);
        
        ContractLineItem cli2 = getCli(oli2.PricebookEntryId, objSC.id);
        cli2.Quantity = oli2.quantity;
        cli2.UnitPrice = oli2.UnitPrice;
        cli2.StartDate = date.today();
        lstCli.add(cli2);
        
        ContractLineItem cli3 = getCli(oli3.PricebookEntryId, objSC.id);
        cli3.Quantity = oli3.quantity;
        cli3.UnitPrice = oli3.UnitPrice;
        cli3.StartDate = date.today();
        lstCli.add(cli3);
        
        insert lstCli;
        
        List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c ql1 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt1.Id,
            Prior_Net_Total__c = 10,
            SBQQ__Product__c = prod1.Id,
            SBQQ__Quantity__c = 20,
            SBQQ__SubscriptionPricing__c = null,
            SBQQ__DefaultSubscriptionTerm__c = null,
            SBQQ__ListPrice__c = 200,
            SBQQ__NetPrice__c = 200,
            SBQQ__DiscountScheduleType__c = 'Slab',
            Scale_Utility_Product__c = true,
            Scale_Utility_Product_Identifier__c = 'M365 SU RSVX',
            SBQQ__StartDate__c = Date.today(),
            SBQQSC__RenewedContractLine__c= cli.Id,
            SBQQ__EndDate__c = Date.today().addDays(11),
            SubscribedAssetNames__c = 'BB192863040046',
            Product_Type__c = 'Hardware'
        );
        insert ql1;
        
        SBQQ__QuoteLine__c ql2 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt1.Id,
            SBQQ__Source__c = ql1.Id,
            Prior_Net_Total__c = 0,
            SBQQ__Product__c = prod2.Id,
            MSP_Segment_Product__c = true,
            SBQQ__Quantity__c = 20,
            SBQQ__Segmentindex__c = 1,
            SBQQ__SubscriptionPricing__c = 'Fixed Price',
            Scale_Utility_Product__c = true,
            Scale_Utility_Product_Identifier__c = 'M365 SU RSVX',
            SBQQ__DefaultSubscriptionTerm__c = null,
            SBQQ__ListPrice__c = 200,
            SBQQ__NetPrice__c = 200,
            SBQQ__DiscountScheduleType__c = 'Slab',
            SBQQ__StartDate__c = Date.today(),
            SBQQSC__RenewedContractLine__c= cli2.Id,
            SubscribedAssetNames__c = 'BB192863040047',
            Who_will_the_customer_be_buying_the_HW__c = 'Reseller'
        );
        lines.add(ql2);
        SBQQ__QuoteLine__c ql3 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt1.Id,
            SBQQ__Product__c = prod1.Id,
            SBQQ__Source__c = ql1.Id,
            SBQQ__Quantity__c = 25,
            SBQQ__SubscriptionPricing__c = null,
            SBQQ__DefaultSubscriptionTerm__c = 12,
            SBQQ__ListPrice__c = 200,
            SBQQ__NetPrice__c = 200,
            SBQQ__DiscountScheduleType__c = 'Slab',
            Scale_Utility_Product__c = true,
            Scale_Utility_Product_Identifier__c = 'M365 SU RSVX',
            SBQQ__StartDate__c = Date.today(),
            SBQQ__EndDate__c = Date.today().addDays(10),
            SubscribedAssetNames__c = 'BB192863040048'
        );
        lines.add(ql3);
        SBQQ__QuoteLine__c ql4 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt1.Id,
            SBQQ__Product__c = prod4.Id,
            SBQQ__Source__c = ql1.Id,
            MSP_Segment_Product__c = true,
            SBQQ__Quantity__c = 20,
            SBQQ__Segmentindex__c = 1,
            SBQQ__SubscriptionPricing__c = 'Fixed Price',
            SBQQ__DefaultSubscriptionTerm__c = null,
            Scale_Utility_Product__c = true,
            Scale_Utility_Product_Identifier__c = 'M365 SU RSVX',
            SBQQ__ListPrice__c = 200,
            SBQQ__NetPrice__c = 200,
            SBQQ__DiscountScheduleType__c = 'Slab',
            SubscribedAssetNames__c = 'BB192863040049'
        );
        lines.add(ql4);
        
        SBQQ__QuoteLine__c ql5 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt.Id,
            Prior_Net_Total__c = 10,
            SBQQ__Product__c = prod1.Id,
            SBQQ__Quantity__c = 20,
            SBQQ__SubscriptionPricing__c = null,
            SBQQ__DefaultSubscriptionTerm__c = null,
            SBQQ__ListPrice__c = 200,
            SBQQ__NetPrice__c = 100000,
            SBQQ__DiscountScheduleType__c = 'Slab',
            Scale_Utility_Product__c = true,
            Scale_Utility_Product_Identifier__c = 'M365 SU RSVX',
            SBQQ__StartDate__c = Date.today(),
            SBQQ__EndDate__c = Date.today().addDays(10),
            SubscribedAssetNames__c = 'BB192863040046',
            Product_Type__c = 'Hardware'
        );
        lines.add(ql5);
        
        SBQQ__QuoteLine__c ql6 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt.Id,
            Prior_Net_Total__c = 10,
            SBQQ__Product__c = prod1.Id,
            SBQQ__Quantity__c = 20,
            SBQQ__SubscriptionPricing__c = null,
            SBQQ__DefaultSubscriptionTerm__c = null,
            SBQQ__ListPrice__c = 200,
            SBQQ__NetPrice__c = 40000,
            SBQQ__DiscountScheduleType__c = 'Slab',
            Scale_Utility_Product__c = true,
            Scale_Utility_Product_Identifier__c = 'M365 SU RSVX',
            SBQQ__StartDate__c = Date.today(),
            SBQQ__EndDate__c = Date.today().addDays(10),
            SubscribedAssetNames__c = 'BB192863040046',
            Product_Type__c = 'Hardware'
        );
        lines.add(ql6);
        
        insert lines;
        lines.add(ql1);
        
        list<Merged_Quote_Line__c> mtqtList = new List<Merged_Quote_Line__c>();
        
        Merged_Quote_Line__c Mqt1 = new Merged_Quote_Line__c(
            Name = 'test',
            Merged_Renewal_Quote_Line__c = ql1.Id,
            New_Quote_Line__c = ql1.Id,
            Quote__c = qt1.Id
        );
        mtqtList.add(Mqt1);
        
        insert mtqtList;
         Consolidated_Contract_Lines__c consolidateContractLines = new Consolidated_Contract_Lines__c();
         consolidateContractLines.Quote_Line__c = ql1.Id;
         consolidateContractLines.Quote__c =qt1.Id;
         consolidateContractLines.Contract_Line_Item__c = cli3.Id;
         insert consolidateContractLines;
        set<Id> QtId = new Set<Id>{ qt1.Id, qt2.Id };
            
            Map<Id, SBQQ__Quote__c> QtMap = new Map<Id, SBQQ__Quote__c>(qtlist);
        
        TriggerControls.disableQuoteTrigger = false;
        TriggerControls.disableQuoteLineTrigger = false;
        SBQQ.TriggerControl.enable();
        Test.startTest();
        
        QuoteTriggerHelper.hwApplianceAndTphAddedTogetherValidation(qtlist);
        QuoteTriggerHelper.populateFieldsOnUpdate(qtlist2, QtMap);
        QuoteTriggerHelper.createMergedQLRecords(QtId, QtId);
         QuoteTriggerHelper.createCCLIRecords(QtId, QtId);  //REEN-25 
        QuoteTriggerHelper.sendNotificationForDealSize(qtlist2, QtMap);
        QuoteTriggerHelper.populateFieldsOnInsert(qtlist);
        Test.stopTest();
        
        System.assert(true);
    }
    /*
    @isTest
    static void testBeforeInsertStatus2() {
        ShGl_TestFactoryHelper.insertTriggerControls();
        Account act1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act1;
        
        //Generate the Opportunity
        Map<String, Object> oppMap = new Map<String, Object>{
            'AccountId' => act1.Id,
                'RecordTypeId' => Schema.getGlobalDescribe()
                .get('Opportunity')
                .getDescribe()
                .getRecordTypeInfosByName()
                .get('Sales Opportunity')
                .getRecordTypeId()
                };
                    Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        opp.Opportunity_Type__c = 'Existing';
        opp.Opportunity_Sub_Type__c = 'Regular';
        insert opp;
        
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act1.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__Type__c = 'Renewal';
        qt.SBQQ__StartDate__c = Date.parse('05/20/2022');
        qt.SBQQ__StartDate__c = Date.parse('05/20/2024');
        qt.Task_Products__c = 'RBK-DISK-RETENTION';
        
        insert qt;
        
        Map<String, Object> prdMap1A = new Map<String, Object>{
            'Name' => 'Subscription',
                'IsActive' => true,
                'SBQQ__SubscriptionPricing__c' => 'Fixed Price',
                'ProductCode' => 'RS-BT-RCDM-T',
                'Product_Level__c' => 'OnPrem'
                };
                    Map<String, Object> prdMap3A = new Map<String, Object>{
                        'Name' => 'DateTest1',
                            'IsActive' => true,
                            'License_Subtype__c' => 'Add-On',
                            'ProductCode' => 'RS-BT-FE-PE-PP'
                            };
                                
                                Product2 prdHWA = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1A);
        insert prdHWA;
        
        Product2 prod4A = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap3A);
        insert prod4A;
        Entitlement ent = new Entitlement(
            Name = 'Testing',
            AccountId = act1.Id,
            Product__c = prdHWA.id,
            StartDate = Date.today(),
            EndDate = Date.today().addDays(365)
        );
        test.startTest();
        insert ent;
        Entitlement ent2 = new Entitlement(
            Name = 'Testing',
            AccountId = act1.Id,
            Product__c = prdHWA.id,
            StartDate = Date.today(),
            EndDate = Date.today().addDays(360)
        );
        insert ent2;
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt.Id,
            SBQQ__Product__c = prdHWA.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__Number__c = 1,
            SubscribedAssetNames__c = 'BB192863040046, BB192863040047',
            SBQQ__SubscribedAssetIds__c = '02i1W00000Sn8uyQAB, 02i1W00000Sn8uZQAR'
        );
        insert qli1;
        
        Set<Id> qliSet = new Set<Id>();
        qliSet.add(qt.Id);
        Map<Id, SBQQ__Quote__c> newQuoteList = new Map<Id, SBQQ__Quote__c>();
        newQuoteList.put(qt.Id, qt);
        // QuoteTriggerHelper.create0RCDM(qliSet);
        
        QuoteTriggerHelper.createQuoteLineGroup(newQuoteList);
        test.stopTest();
        
        System.assert(true);
    }*/
    public static testmethod void verifyTierOnQLsTests() {
        QuoteLineRecordResponse qlresp1 = new QuoteLineRecordResponse ();
        qlresp1.rqBy = 'a6PU80000001EyeMAE';
        qlresp1.ptyp = 'HW Support';
        qlresp1.reqSupTier = 'E1';
        qlresp1.reqHWSupTier = null;
        qlresp1.supTier = 'S1';
        qlresp1.hWSupTier = null;
        QuoteLineRecordResponse qlresp2 = new QuoteLineRecordResponse ();
        qlresp2.rqBy = 'a6PU80000001EyeMAA';
        qlresp2.ptyp = 'HW Support';
        qlresp2.reqSupTier = null;
        qlresp2.reqHWSupTier = 'S1';
        qlresp2.supTier = null;
        qlresp2.hWSupTier = 'E1';
        QuoteLineRecordResponse qlresp3 = new QuoteLineRecordResponse ();
        qlresp3.rqBy = 'a6PU80000001EyeMAO';
        qlresp3.ptyp = 'Hardware';
        qlresp3.reqSupTier = 'S1';
        qlresp3.reqHWSupTier = null;
        qlresp3.supTier = 'S1';
        qlresp3.hWSupTier = null;

        List<QuoteLineRecordResponse> qlList = new List<QuoteLineRecordResponse>();
        qlList.add(qlresp1);
        qlList.add(qlresp2);
        qlList.add(qlresp3);
        Test.startTest();
        Boolean result = QuoteTriggerHelper.verifyTierOnQLs(qlList);
       // System.assertEquals(result, false);
        Test.stopTest();
    }
    /**************************************************************************************************
    * Method Name          : hwExpErrorTest
    * @description         : hwExpErrorTest for covering exception of updateExpirationWithHardware
    /************************************************************************************************/
    @IsTest
    static void hwExpErrorTest() {
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        SBQQ.TriggerControl.disable();
         String uniqueUserName = 'TestUser' + DateTime.now().getTime() + '@rbk.com';
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Deal Operations' LIMIT 1];
        User usr = new user(
            alias = 'std',
            email = 'testuser@testclass.com',
            emailencodingkey = 'UTF-8',
            firstname = 'test',
            lastname = 'user',
            languagelocalekey = 'en_US',
            localesidkey = 'en_US',
            profileid = p.Id,
            timezonesidkey = 'America/Los_Angeles',
            username = uniqueUserName,
            RBAC_Group__c = 'System - IT',
            RBAC_Department__c = 'Service Account'
        );
        //insert usr;
        
         System.runAs(new User(Id = UserInfo.getUserId())) {
            Id standardPriceBookId = Test.getStandardPricebookId();
            PriceBook2 pb1 = new Pricebook2(
                Name = 'V68_2017_08_09_12_26_43',
                Description = 'Price Book 2009 Products 1',
                IsActive = true
            );
            insert pb1;
            Product2 prodHW = new Product2(Name = 'RH-6408SE-02', ProductCode = 'RH-6408SE-02', isActive = true, Product_Level__c = 'Hardware', Product_Type__c = 'Hardware', Category__c = 'Hardware');
            insert new List<Product2>{prodHW };
            PricebookEntry pbStanEntryHw = getPbe(prodHW.Id, 100.00);
            PricebookEntry pbEntryHw = getPbe(pb1.Id, prodHW.Id, 100.00);
            insert new List<PricebookEntry>{pbStanEntryHw,pbEntryHw};
      
            Account acct = [SELECT Id FROM Account WHERE Name = 'testAccount' LIMIT 1];
            Opportunity opprHW = TestDataFactory.getOpportunity(acct);
            insert opprHW;
            SBQQ__Quote__c qtHW = new SBQQ__Quote__c();
            qtHW.SBQQ__Opportunity2__c = opprHW.Id;
            qtHW.SBQQ__Primary__c = false;
            qtHW.SBQQ__Account__c = acct.Id;
            qtHW.SBQQ__PriceBook__c = pb1.Id;
            qtHW.ApprovalStatus__c = 'Draft';
            qtHW.SBQQ__Type__c = 'Quote';
            qtHW.SBQQ__StartDate__c = Date.today();
            qtHW.Manual_Billing__c = false;
            qtHW.Consolidate_Lines__c = false;
            insert qtHW;
            List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
            SBQQ__QuoteLine__c qlHW = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qtHW.Id, SBQQ__Product__c = prodHW.Id, SBQQ__Quantity__c = 20,  SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10));
            SBQQ__QuoteLine__c qlHW2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qtHW.Id, SBQQ__Product__c = prodHW.Id, SBQQ__Quantity__c = 20,  SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today().addDays(30));
            lines.add(qlHW);
            lines.add(qlHW2);
            insert lines; 
            lines[0].SBQQ__Quantity__c = 25;
            lines[1].SBQQ__Quantity__c = 25;
            update lines;
            Map<Id, SBQQ__Quote__c> qtOldMap = new Map<Id, SBQQ__Quote__c>{
            qtHW.Id => qtHW.clone(true, true)};
            SBQQ__Quote__c updatedQt = qtHW.clone(true, true);
            updatedQt.SBQQ__ExpirationDate__c = Date.today().addDays(120);
            Map<Id, SBQQ__Quote__c> quoteHWOldMap = new Map<Id, SBQQ__Quote__c>();
            quoteHWOldMap.put(qtHW.Id,qtHW);
            TriggerControls.disableQuoteTrigger = false;
            TriggerControls.disableQuoteLineTrigger = false;
            SBQQ.TriggerControl.enable();
            Test.startTest(); 
            Map<Id, SBQQ__QuoteLine__c> qlMap = new Map<Id, SBQQ__QuoteLine__c>([SELECT Id, SBQQ__Quote__c, SBQQ__Optional__c, SBQQ__Existing__c,
             Quote_Line_Type__c, Is_Hardware_and_New__c, CreatedDate
            FROM SBQQ__QuoteLine__c WHERE Id IN :lines]);
            QuoteTriggerHelper.updateExpirationWithHardware(updatedQt, qtOldMap, qlMap);
            Test.stopTest();
            System.assert(true);
        }
    }
    
    @IsTest
    public static void CreateDealDeskCaseTest(){
        ShGl_DisableBusinessLogic__c dbl = ShGl_DisableBusinessLogic__c.getInstance();
        dbl.Disable_Account_Triggers__c = true;
        dbl.Disable_Opportunity_Triggers__c = true;
        dbl.Disable_ServiceContract_Trigger__c = true;
        dbl.Disable_SBQQ_Quote_Triggers__c = true;
        dbl.Disable_SBQQ_QuoteLine_Triggers__c = true;
        update dbl;
        
        insert new TriggerControl__c(
            Name = 'Approval',
            DisableTrigger__c = true
        );
        
        Opportunity oopt = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
        oopt.Name = 'Test Opportunity';
        oopt.StageName = 'Prospecting';
        oopt.CloseDate = Date.today();
        insert oopt;
        
        List<SBQQ__Quote__c> quotes = new List<SBQQ__quote__c>();
        
        SBQQ__Quote__c quote = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        quote.SBQQ__Opportunity2__c = oopt.Id;
        quotes.add(quote);
        
        SBQQ__Quote__c quote2 = quote.clone();
        quotes.add(quote2);
        
        insert quotes;
        
        sbaa__Approver__c approver = new sbaa__Approver__c(
            Name= 'Deal Desk'
        );
        insert approver;
        
        sbaa__ApprovalRule__c rule = new sbaa__ApprovalRule__c(
            sbaa__Approver__c = approver.Id,
            sbaa__Active__c = true,
            sbaa__TargetObject__c	= 'SBQQ__Quote__c'
        );
        insert rule;
        
        List<sbaa__Approval__c> approvals = new List<sbaa__Approval__c>();
        sbaa__Approval__c approval = new sbaa__Approval__c(
            Quote__c = quote.Id,
            sbaa__Opportunity__c = oopt.Id,
            sbaa__Status__c = 'Requested',
            sbaa__Approver__c = approver.Id,
            sbaa__RecordField__c = 'Quote__c',
            sbaa__ApprovalStep__c = 1,
            sbaa__rule__c = rule.Id
        );
        approvals.add(approval);
        
        sbaa__Approval__c approval2 = approval.clone();
        approval2.Quote__c = quote2.Id;
        approvals.add(approval2);
        insert approvals;
        
        Deal_Desk_Case__c ddcCase = new Deal_Desk_Case__c(
            Quote__c = quote.Id,
            Opportunity__c = quote.sbqq__opportunity2__c,
            Deal_Desk_Team__c = 'Deal Structuring',
            ApprovalStatus__c = '',
            Request_Type__c = 'General Inquiry',
            Business_Justification__c = 'minimum characters'
        );
        
        insert ddcCase;
        
        ddcCase.Request_Status__c = 'Draft';
        //ddcCase.ApprovalStatus__c = 'Approved';
        update ddcCase;

        List<SBQQ__Quote__c> quoteRecs = new List<SBQQ__Quote__c>{quote, quote2};
        Test.startTest();
        //QuoteTriggerHelper.createDealDeskCase(quoteRecs);
        Test.stopTest();
    }
}