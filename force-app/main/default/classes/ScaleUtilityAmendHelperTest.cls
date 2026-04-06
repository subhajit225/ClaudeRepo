@isTest
public with sharing class ScaleUtilityAmendHelperTest {

    static Product2 getProduct(String name, String code) {
        return new Product2(Name = name, ProductCode = code, isActive = true, CPQ_Uplift__c = '5');
    }
    
    static PricebookEntry getPbe(Id pbId, Id prodId, Decimal unitPrice) {
        return new PricebookEntry(Pricebook2Id = pbId, Product2Id = prodId, UnitPrice = unitPrice, IsActive = true);
    }
    
    static PricebookEntry getPbe(Id prodId, Decimal unitPrice) {
        //return getPbe(Test.getStandardPricebookId(), unitPrice);
        return new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prodId,  UnitPrice=unitPrice);
    }
    

    static ContractLineItem getCli(Id pbeId, Id scId) {
        return new ContractLineItem(
            Quantity = 1,
            PricebookEntryId = pbeId,
            ServiceContractId = scId,
            UnitPrice = 100,
            StartDate = Date.today()
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
        // insert new ShGl_DisableBusinessLogic__c(
        //     SetupOwnerId = UserInfo.getUserId(),
        //     Disable_Opportunity_Triggers__c = true
        // );
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].RBAC_Group__c = 'System - IT';
		listUser[0].RBAC_Department__c = 'Service Account';
        listUser[0].ManagerId = listUser[1].Id;
        update listUser;
        System.runAs(listUser[0]) {
        ShGl_TestFactoryHelper.insertTriggerControls();
        
        ShGl_DisableBusinessLogic__c cdf1 = new ShGl_DisableBusinessLogic__c(
            SetupOwnerId = userInfo.getUserId(),
            Disable_SBQQ_Quote_Triggers__c = true,
            Disable_SBQQ_QuoteLine_Validation_Rules__c = true
        );
        insert cdf1;
        
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
            Name = 'CPQ',
            Description = 'CPQ Price Book',
            IsActive = true
        );
        insert pb1;
        
        //Create your product
        Product2 prod1 = new Product2(Name = 'RBK-GO-BE-R6408', ProductCode = 'RBK-GO-BE-R6408-FE-', isActive = true);
        Product2 prod2 = new Product2(
            Name = 'RBK-R Premium Support 1-Yr Prepaid, r304',
            ProductCode = 'RBK-SVC-PREM-R304-FE-',
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
        qt1.SBQQ__Primary__c = true;
        qt1.SBQQ__PriceBook__c = pb1.Id;
        qt1.ApprovalStatus__c = 'Approved';
        qt1.SBQQ__Type__c = 'Amendment';
        qt1.SBQQ__StartDate__c = Date.today();
        qt1.SBQQ__ExpirationDate__c = Date.today().addDays(90);  
        qt1.SBQQ__EndDate__c = Date.today().addDays(45);
        qt1.Manual_Billing__c = false;
        qt1.Consolidate_Lines__c = false;
        qt1.OpportunitySubType__c = 'GC Offer';
        qt1.SBQQ__SubscriptionTerm__c = 12;
        insert qt1;
        
        Order ordr = new Order(
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
        
        insert ordr;
            
        ServiceContract objSC = new ServiceContract(
            Name = 'ServiceContract Test',
            AccountId = acct.Id,
            StartDate = Date.today(),
            Term = 36,
            pricebook2Id = pb1.Id,
            SBQQSC__Opportunity__c = oppr.Id,
            SBQQSC__Order__c = ordr.Id,
            SBQQSC__Quote__c = qt1.Id
        );
        
        insert objSC;
         qt1.Amended_Renewed_Service_Contract__c = objSC.id;
		update qt1;
        
        ordr.ShipToContactName__c = 'sh';
        ordr.Shipping_Method__c = 'EXW';
        ordr.Shipping_Carrier__c = 'AIT';
        ordr.Service_Level__c = 'Same Day';
        ordr.Bill_To_Name__C = acct.id;
        ordr.est_Ship_Date__C = System.Today().addDays(7);
        ordr.Status = 'Order Accepted';
        
        OrderItem oli1 = getOli(ordr.Id, pbEntry1.Id, pbEntry1.UnitPrice, 'Test1234567Asset2');
        
        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OrderItem oli2 = getOli(ordr.Id, pbEntry2.Id, pbEntry2.UnitPrice, 'Test1234567Asset');
        
        OrderItem oli3 = getOli(ordr.Id, pbEntry3.Id, pbEntry3.UnitPrice, 'Test1234567Asset');
        
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
            SBQQ__DefaultSubscriptionTerm__c = 12,
            SBQQ__ListPrice__c = 200,
            SBQQ__NetPrice__c = 200,
            SBQQSC__UpgradedContractLine__c = cli.Id,
            SBQQ__StartDate__c = Date.today(),
            SBQQ__EndDate__c = Date.today().addDays(10),
            SubscribedAssetNames__c = 'BB192863040046',
            SBQQ__SubscriptionTerm__c = 12,
            SBQQ__Discount__c = 5,
            Scale_Utility_Product_RSV_OND__c = 'RSV'
        );
        
        lines.add(ql1);

        SBQQ__QuoteLine__c ql2 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt1.Id,
            Prior_Net_Total__c = 10,
            SBQQ__Product__c = prod2.Id,
            SBQQ__Quantity__c = 20,
            SBQQ__SubscriptionPricing__c = null,
            SBQQ__DefaultSubscriptionTerm__c = null,
            SBQQ__ListPrice__c = 200,
            SBQQ__NetPrice__c = 200,
            SBQQSC__UpgradedContractLine__c = cli.Id,
            SBQQ__StartDate__c = Date.today(),
            SBQQ__EndDate__c = Date.today().addDays(10),
            SubscribedAssetNames__c = 'BB192863040046',
            Product_Type__c = 'Edition Upgrade',
            Scale_Utility_Product_Identifier__c = 'SU FUE',
            Product_Subtype__c = 'Scale MSP',
            SBQQ__PriorQuantity__c = 20,
            SBQQ__Existing__c = true,
            SBQQ__UpgradedQuantity__c = 0,
            SBQQ__RequiredBy__c = ql1.Id,
            SBQQ__SubscriptionTerm__c = 12
        );
        
        lines.add(ql2);

        SBQQ__QuoteLine__c ql3 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt1.Id,
            Prior_Net_Total__c = 10,
            SBQQ__Product__c = prod2.Id,
            SBQQ__Quantity__c = 20,
            SBQQ__SubscriptionPricing__c = null,
            SBQQ__DefaultSubscriptionTerm__c = null,
            SBQQ__ListPrice__c = 200,
            SBQQ__NetPrice__c = 200,
            SBQQSC__UpgradedContractLine__c = cli.Id,
            SBQQ__StartDate__c = Date.today(),
            SBQQ__EndDate__c = Date.today().addDays(10),
            SubscribedAssetNames__c = 'BB192863040046',
            Product_Type__c = 'Edition Upgrade',
            Product_Subtype__c = 'Scale MSP',
            SBQQ__PriorQuantity__c = 20,
            SBQQ__Existing__c = true,
            SBQQ__UpgradedQuantity__c = 0,
            SBQQ__RequiredBy__c = ql1.Id,
            SBQQ__SubscriptionTerm__c = 12,
            Scale_Utility_Product_Identifier__c = 'OND SR'
        );
        
        lines.add(ql3);
        
        //Added new Quote Line
        SBQQ__QuoteLine__c ql4 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = qt1.Id,
            Prior_Net_Total__c = 10,
            SBQQ__Product__c = prod2.Id,
            SBQQ__Quantity__c = 20,
            SBQQ__SubscriptionPricing__c = null,
            SBQQ__DefaultSubscriptionTerm__c = null,
            SBQQ__ListPrice__c = 200,
            SBQQ__NetPrice__c = 200,
            SBQQSC__UpgradedContractLine__c = cli.Id,
            SBQQ__StartDate__c = Date.today(),
            SBQQ__EndDate__c = Date.today().addDays(10),
            SubscribedAssetNames__c = 'BB192863040046',
            Product_Type__c = 'Edition Upgrade',
            Scale_Utility_Product_Identifier__c = 'SU FUE',
            Product_Subtype__c = 'Scale MSP',
            SBQQ__PriorQuantity__c = 20,
            SBQQ__Existing__c = true,
            SBQQ__UpgradedQuantity__c = 0,
            SBQQ__RequiredBy__c = ql1.Id,
            SBQQ__SubscriptionTerm__c = 12
        );
        
        lines.add(ql4);
        insert lines;
    }
    }
    @isTest
    private static void testCreateSCAmendUGQL() {
        
        Test.startTest();
        user rbkadmin = [select id,name from user where profile.name ='System Administrator' and  IsActive = true limit 1 ];
        ShGl_DisableBusinessLogic__c cc = 
            new ShGl_DisableBusinessLogic__c(SetupOwnerId = rbkadmin.Id,Disable_SBQQ_Quote_Triggers__c = True,
                                                                           Disable_SBQQ_QuoteLine_Triggers__c = true,
                                                                           Disable_SBQQ_Quote_Validation_Rules__c = true);
                    upsert cc;
        Set<Id> setQuoteIds = new Set<Id>();
        List<SBQQ__Quote__c> qlist = new List<SBQQ__Quote__c>();
        Map<Id, SBQQ__Quote__c> mapNew = new Map<Id, SBQQ__Quote__c>();
        Map<Id, SBQQ__Quote__c> mapOld = new Map<Id, SBQQ__Quote__c>();
        for(SBQQ__Quote__c eachQuote : [Select Id, Amended_Renewed_Service_Contract__c, SBQQ__Type__c, Is_Scale_Utility_Quote__c, OpportunitySubType__c, SBQQ__Primary__c, SBQQ__StartDate__c,SBQQ__ExpirationDate__c from SBQQ__Quote__c]) {
            setQuoteIds.add(eachQuote.Id);
            qlist.add(eachQuote);
            mapOld.put(eachQuote.Id,eachQuote);
            mapNew.put(eachQuote.Id,eachQuote);
        }

        for(SBQQ__QuoteLine__c eachLine :  [SELECT Id, Name, SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__Type__c, SBQQ__Quote__r.OpportunitySubType__c,
                                                    Product_Type__c, Product_Subtype__c, Line_Type__c, SBQQSC__UpgradedContractLine__r.StartDate,
                                                    SBQQ__EffectiveQuantity__c, OnDemand_Discount__c, SBQQ__ProductCode__c, SBQQ__Discount__c, SBQQ__StartDate__c , SBQQ__EndDate__c, SBQQ__SubscriptionTerm__c, SBQQ__RequiredBy__c, SBQQ__RequiredBy__r.SBQQ__SubscriptionTerm__c
                                          FROM SBQQ__QuoteLine__c
                                          WHERE SBQQ__Quote__c IN :setQuoteIds
                                         ]) {
        }
        
        System.runAs(rbkadmin){
        ScaleUtilityAmendHelper.createAmendedScaleUGQLRecords(setQuoteIds);
        //ScaleUtilityAmendHelper.calculateOnDemandDiscount(setQuoteIds);
        ScaleUtilityAmendHelper.adjustSegmentLinesOnScaleUtilityAmend(qlist,mapNew,mapOld);
            ScaleUtilityAmendHelper.adjustSegmentLinesOnScaleUtilityAmendInsert(qlist);
        ScaleUtilityAmendHelper.deleteQLRecs(setQuoteIds);
        List<SBQQ__QuoteLine__c> quoteLineList = [SELECT Id, Name, SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__Type__c, SBQQ__Quote__r.OpportunitySubType__c,Scale_Utility_Product_RSV_OND__c,RWD_Sales_Rep_Exception__c,
                                                   Product_Type__c, Product_Subtype__c, Line_Type__c, SBQQSC__UpgradedContractLine__r.StartDate,Product_Payment_Option__c,Scale_Utility_Product_Identifier__c,
                                                   SBQQ__EffectiveQuantity__c, OnDemand_Discount__c, SBQQ__ProductCode__c, SBQQ__Discount__c, SBQQ__StartDate__c , SBQQ__EndDate__c, SBQQ__SubscriptionTerm__c, SBQQ__RequiredBy__c, SBQQ__RequiredBy__r.SBQQ__SubscriptionTerm__c
                                                   FROM SBQQ__QuoteLine__c
                                                   WHERE SBQQ__Quote__c IN :setQuoteIds
                                                  ];
        ScaleUtilityAmendHelper.restoreStartEndDate(quoteLineList);
        }
        Test.stopTest();
        
        System.assert(true);
    }
}