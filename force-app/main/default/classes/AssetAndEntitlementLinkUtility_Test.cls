//  *************************************************************************
//  Requirements
//  1. Test class for AssetAndEntitlementLinkUtility.
//
//    Test Class : NA
//    Requirements developed by - Jayaraman Iyer
//    Last Modified by - Jayaraman Iyer
//    Last Modified - 24/01/2022
//  *************************************************************************
@isTest
public class AssetAndEntitlementLinkUtility_Test {

    @testSetup
    public static void testData() {

           insert new ShGl_DisableFunctionalityLogic__c(setupOwnerId = UserInfo.getUserId(), Disable_Account_Old_Trigger__c = TRUE);
        
        insert new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getUserId(), 
              Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
              Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
              Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true);
        TriggerControl.stopOrderItemTrigger = true;
        
        TriggerControl.stopOrderTrigger = true;
        
        
        ShGl_TestFactoryHelper.insertTriggerControls();

        insert new ShGl_DisableBusinessLogic__c(SetupOwnerId=UserInfo.getOrganizationId(), Disable_Opportunity_Old_Trigger__c=false);

        List<TriggerControl__c> lsttoins = new List<TriggerControl__c>();
        TriggerControl__c enttrg1 = new TriggerControl__c();
        enttrg1.Name ='Entitlement';
        enttrg1.DisableTrigger__c = true;
        lsttoins.add(enttrg1);
        
        TriggerControl__c enttrg2 = new TriggerControl__c();
        enttrg2.Name = 'Renewal Case';
        enttrg2.DisableTrigger__c = true;
        //lsttoins.add(enttrg2);
        insert lsttoins;
        
        
        Account account = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        account.Name = 'NewAccount';
        insert account;

        List<Product2> lstProduct = new List<Product2>();
        Product2 productObj = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
        productObj.ProductCode = 'RBK-SVC-test-product';
        productObj.Product_Subtype__c = 'GO';
        productObj.Name = 'RBK-SVC-test-product';
        productObj.IsActive = true;
        lstProduct.add(productObj);

        Product2 productNewObj = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
        productNewObj.ProductCode = 'RBH-SVC-test-product';
        productNewObj.Product_Subtype__c = 'GO';
        productNewObj.Name = 'RBH-SVC-test-product';
        productNewObj.IsActive = true;
        lstProduct.add(productNewObj);

        Product2 productNewObjsecond = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
        productNewObjsecond.ProductCode = 'RBH-SVC-test';
        productNewObjsecond.Product_Subtype__c = 'GO';
        productNewObjsecond.Name = 'RBH-SVC-test';
        productNewObjsecond.IsActive = true;
        lstProduct.add(productNewObjsecond);
        
        Product2 productNewObj3 = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
        productNewObj3.ProductCode = 'RBH-SVC-test2';
        productNewObj3.Product_Subtype__c = 'GO';
        productNewObj3.Name = 'RBH-Pe-PP-test';
        productNewObj3.IsActive = true;
        productNewObj3.Product_Type__c = 'HW Support';
        productNewObj3.Product_Level__c = 'Support';
        productNewObj3.SBQQSC__EntitlementConversion__c= 'One per quote line';
        lstProduct.add(productNewObj3);
        insert lstProduct;
        

        /* Polaris_SKU_Mapping__c polarisSKUMappingObj = new Polaris_SKU_Mapping__c();
        polarisSKUMappingObj.Old_Product__c = lstProduct[0].Id;
        polarisSKUMappingObj.New_Product__c = lstProduct[1].Id;
        insert polarisSKUMappingObj; */
        
        PricebookEntry pricebookObj = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pricebookObj.Product2Id = productObj.Id;
        pricebookObj.UnitPrice = 100;
        pricebookObj.Pricebook2Id = Test.getStandardPricebookId();
        pricebookObj.IsActive = true;
        insert pricebookObj;
        
         PricebookEntry pricebookObj1 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pricebookObj1.Product2Id = productNewObj3.Id;
        pricebookObj1.UnitPrice = 100;
        pricebookObj1.Pricebook2Id = Test.getStandardPricebookId();
        pricebookObj1.IsActive = true;
        insert pricebookObj1;
        
        Asset assetObj = (Asset) ShGl_TestFactory.createSObject(new Asset(), null);
        assetObj.AccountId =account.Id;
        assetObj.Name = 'EntitlementTriggerHelperAsset';
        assetObj.Product2Id = productObj.Id;
        // assetObj.Eligible_for_Free_HW__c = true; // add later with string value
        assetObj.Justification_for_HW_Eligibility_Overrid__c = '-';
        assetObj.serial_number__c = 'JAY8486304222k4';
        insert assetObj;

        List<Opportunity> lstOpportunity = new List<Opportunity>();
        Opportunity opportunityObj = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
        opportunityObj.AccountId = account.Id;
        opportunityObj.Name = 'EntitlementTriggerHelper Opportunity';
        opportunityObj.CloseDate = System.today().addMonths(12);
        opportunityObj.StageName = 'Prospecting';
        opportunityObj.Pricebook2Id = Test.getStandardPricebookId();
        lstOpportunity.add(opportunityObj);

        Opportunity opportunityNewObj = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
        opportunityNewObj.AccountId = account.Id;
        opportunityNewObj.Name = 'EntitlementTriggerHelper Opportunity';
        opportunityNewObj.CloseDate = System.today().addMonths(12);
        opportunityNewObj.StageName = 'Prospecting';
        opportunityNewObj.Pricebook2Id = Test.getStandardPricebookId();
        lstOpportunity.add(opportunityNewObj);
        insert lstOpportunity;

        List<ServiceContract> lstServiceContract = new List<ServiceContract>();

        ServiceContract serviceContractObj = new ServiceContract();
        serviceContractObj.Name = 'EntitlementTriggerHelper Contract';
        serviceContractObj.SBQQSC__Opportunity__c = lstOpportunity[0].Id;
        //serviceContractObj.SBQQSC__RenewalOpportunity__c = lstOpportunity[1].Id;
        serviceContractObj.AccountId = account.Id;
        serviceContractObj.StartDate = System.today();
        serviceContractObj.PriceBook2Id = Test.getStandardPricebookId();
        serviceContractObj.Term = 36;
        lstServiceContract.add(serviceContractObj);

        ServiceContract renewServiceContractObj = new ServiceContract();
        renewServiceContractObj.Name = 'EntitlementTriggerHelper Contract';
        renewServiceContractObj.SBQQSC__Opportunity__c = lstOpportunity[1].Id;
        //renewServiceContractObj.SBQQSC__RenewalOpportunity__c = lstOpportunity[0].Id;
        renewServiceContractObj.AccountId = account.Id;
        renewServiceContractObj.StartDate = System.today();
        renewServiceContractObj.PriceBook2Id = Test.getStandardPricebookId();
        renewServiceContractObj.Term = 36;
        lstServiceContract.add(renewServiceContractObj);
        insert lstServiceContract;

        ContractLineItem ContractLineItemObj = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj.SBQQSC__Account__c = account.Id;
        ContractLineItemObj.AssetId = assetObj.Id;
        ContractLineItemObj.PricebookEntryId = pricebookObj.Id;
        ContractLineItemObj.ServiceContractId = lstServiceContract[0].Id;
        ContractLineItemObj.Quantity = 10;
        ContractLineItemObj.UnitPrice = 100;
        insert ContractLineItemObj;
           ContractLineItem ContractLineItemObj1 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj1.SBQQSC__Account__c = account.Id;
        ContractLineItemObj1.AssetId = assetObj.Id;
        ContractLineItemObj1.PricebookEntryId = pricebookObj1.Id;
        ContractLineItemObj1.ServiceContractId = lstServiceContract[0].Id;
        ContractLineItemObj1.Quantity = 10;
        ContractLineItemObj1.UnitPrice = 100;
        //insert ContractLineItemObj1;

        List<Entitlement> lstEntitlement = new List<Entitlement>();
        Entitlement enttitlementObj = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        enttitlementObj.AccountId = account.Id;
        enttitlementObj.StartDate = Date.today().addDays(-365);
        enttitlementObj.EndDate = Date.today().addDays(365);
        enttitlementObj.AssetId = assetObj.Id;
        enttitlementObj.ContractLineItemId = ContractLineItemObj.Id;
        enttitlementObj.Renewable__c = true;
        enttitlementObj.Type = 'Phone Support';
        enttitlementObj.Name = 'EntitlementTriggerHelper';
        enttitlementObj.Product__c = lstProduct[0].Id;
        enttitlementObj.Refreshed_Opportunity_Link__c = lstOpportunity[0].Id;
        enttitlementObj.ServiceContractId = lstServiceContract[0].Id;
        lstEntitlement.add(enttitlementObj);

        Entitlement enttitlementNewObj = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        enttitlementNewObj.AccountId = account.Id;
        enttitlementNewObj.StartDate = Date.today().addDays(-365);
        enttitlementNewObj.EndDate = Date.today().addDays(365);
        enttitlementNewObj.AssetId = assetObj.Id;
        enttitlementNewObj.ContractLineItemId = ContractLineItemObj.Id;
        enttitlementNewObj.Renewable__c = true;
        enttitlementNewObj.Type = 'Phone Support';
        enttitlementNewObj.Name = 'EntitlementTriggerHelper';
        enttitlementNewObj.Product__c = lstProduct[0].Id;
        enttitlementNewObj.Refreshed_Opportunity_Link__c = lstOpportunity[1].Id;
        enttitlementNewObj.ServiceContractId = lstServiceContract[1].Id;
        lstEntitlement.add(enttitlementNewObj);

        Entitlement enttitlementNewObjSecond = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        enttitlementNewObjSecond.AccountId = account.Id;
        enttitlementNewObjSecond.StartDate = Date.today().addDays(-365);
        enttitlementNewObjSecond.EndDate = Date.today().addDays(365);
        enttitlementNewObjSecond.AssetId = assetObj.Id;
        enttitlementNewObjSecond.ContractLineItemId = ContractLineItemObj.Id;
        enttitlementNewObjSecond.Renewable__c = true;
        enttitlementNewObjSecond.Type = 'Phone Support';
        enttitlementNewObjSecond.Name = 'EntitlementTriggerHelper';
        enttitlementNewObjSecond.Product__c = lstProduct[2].Id;
        enttitlementNewObjSecond.Refreshed_Opportunity_Link__c = lstOpportunity[1].Id;
        enttitlementNewObjSecond.ServiceContractId = lstServiceContract[1].Id;
        lstEntitlement.add(enttitlementNewObjSecond);
        //insert lstEntitlement;
        
        
        Entitlement enttitlementNewObj3 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        enttitlementNewObj3.AccountId = account.Id;
        enttitlementNewObj3.StartDate = Date.today().addDays(-365);
        enttitlementNewObj3.EndDate = Date.today().addDays(365);
        enttitlementNewObj3.AssetId = assetObj.Id;
        enttitlementNewObj3.ContractLineItemId = ContractLineItemObj1.Id;
        enttitlementNewObj3.Renewable__c = true;
        enttitlementNewObj3.Type = 'Phone Support';
        enttitlementNewObj3.Name = 'EntitlementTriggerHelper';
        enttitlementNewObj3.Product__c = lstProduct[2].Id;
        enttitlementNewObj3.Refreshed_Opportunity_Link__c = lstOpportunity[1].Id;
        enttitlementNewObj3.ServiceContractId = lstServiceContract[1].Id;
        //lstEntitlement.add(enttitlementNewObj3);
        insert lstEntitlement;
        
        
            //Entitltment link start
     Id partner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account customer = new Account(
            Name = 'Customer',
            recordtypeId = partner,
            Phone = '123-456-7890',
            AccountNumber = 'Test',
            BillingStreet = '123 street',
            BillingCity = 'Santa Clara',
            BillingState = 'California',
            BillingPostalCode = '95050',
            BillingCountry = 'United States',
            ShippingStreet = '123 street',
            ShippingCity = 'Santa Clara',
            ShippingState = 'California',
            ShippingPostalCode = '95050',
            ShippingCountry = 'United States'
        );
        insert customer;
        Account vAccount = new Account();
        vAccount.Name = 'Test Account';
        vAccount.Type='Distributor';
        vAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        insert vAccount;

        Opportunity opp = TestDataFactory.getOpportunity();
        opp.Distributor_Lookup__c = vAccount.Id;
        opp.Partner_Lookup__c = customer.Id;
        opp.AccountId = customer.Id;
        insert opp;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__SubscriptionTerm__c = 12,
            SBQQ__Primary__c = true,
            SBQQ__PriceBook__c = Test.getStandardPricebookId());
        insert quote;

        List<Product2> sampleProducts = new List<Product2>{
                // 0
                new Product2(
                    Name = 'CPQ Bundle Product',
                    ProductCode = 'CPQ Bundle Product',
                    IsActive = true,
                    MSP_Segment_Product__c = true,
                    SBQQ__Hidden__c = true,
                    SBQQ__ExcludeFromOpportunity__c = true,
                    Product_Type__c='HW Support',
                    Product_Level__c = 'Support',
                    
                    New_CPQ_Product__c = true
                ),
                // 1
                new Product2(
                    Name = 'RBK-R6412-CONS',
                    ProductCode = 'RBK-R6412-CONS',
                    Category__c = 'Platform',
                    Family = 'r300',

                    Appliance_Model__c='RBK-R344',
                    Appliance_Model_HW__c = 'RBK-R344',
                    CPQ_MSP_Base_Price__c = 0.13,
                    SBQQSC__EntitlementConversion__c = 'None',
                    SBQQ__AssetAmendmentBehavior__c = 'Default',
                    Product_Type__c='HW Support',
                    Product_Level__c = 'Support',
                    IsActive = true,
                    Asset_Priority__c = 0,
                    MSP_Segment_Product__c = true,
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 1,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable'
                ),
                // 2
                new Product2(
                    Name = 'RBK-RADAR-CONS',
                    ProductCode = 'RBK-RADAR-CONS',
                    Category__c = 'Support',
                    SBQQ__AssetAmendmentBehavior__c = 'Default',
                    SBQQSC__EntitlementConversion__c = 'One per quote line',
                    IsActive = true,
                    CPQ_MSP_Base_Price__c = 0.02,
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 36,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable'
                ),
                 new Product2(
                    Name = 'RBK-RADAR-CONS1',
                    ProductCode = 'RBK-RADAR-CONS1',
                    Category__c = 'Support',
                    SBQQ__AssetAmendmentBehavior__c = 'Default',
                    SBQQSC__EntitlementConversion__c = 'One per quote line',
                    IsActive = true,
                    CPQ_MSP_Base_Price__c = 0.02,
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 36,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable'
                )   
        };
        insert sampleProducts;
        system.debug('sampleProducts***'+sampleProducts);
        system.debug('sample3***'+sampleProducts[3]);
        List<PricebookEntry>entries = new List<PricebookEntry>();

        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[0].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[1].Id, IsActive = true, UnitPrice = 200));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[2].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[3].Id, IsActive = true, UnitPrice = 100));
        insert entries;
        system.debug('entries****'+entries);
        List<SBQQ__ProductOption__c>prodOptions = new List<SBQQ__ProductOption__c>();
        prodOptions.add(new SBQQ__ProductOption__c(SBQQ__Number__c = 20, SBQQ__ConfiguredSKU__c = sampleProducts[1].Id, SBQQ__OptionalSKU__c = sampleProducts[1].Id));
        prodOptions.add(new SBQQ__ProductOption__c(SBQQ__Number__c = 30, SBQQ__ConfiguredSKU__c = sampleProducts[2].Id, SBQQ__OptionalSKU__c = sampleProducts[1].Id));
        prodOptions.add(new SBQQ__ProductOption__c(SBQQ__Number__c = 30, SBQQ__ConfiguredSKU__c = sampleProducts[3].Id, SBQQ__OptionalSKU__c = sampleProducts[1].Id));
        insert prodOptions;
        Test.startTest();
        Asset assestIns = new Asset();
        assestIns.Name = '09092019APMSP1250';
        assestIns.SerialNumber = '09092019APMSP1250';
        assestIns.serial_number__c= '09092019APMSP1250';
        assestIns.AccountId = customer.Id;
        assestIns.Product2Id = sampleProducts[0].Id;
        insert assestIns;
        String cliid = String.valueof(ContractLineItemObj.Id);
        List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
        lines.add(new SBQQ__QuoteLine__c(SBQQ__SubscribedAssetIds__c=assestIns.Id,SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[0].Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id ,CCLI__c =ContractLineItemObj1.Id  ,SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__SubscribedAssetIds__c=assestIns.Id,SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[1].Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 1,SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id,CCLI__c =ContractLineItemObj1.Id, SBQQ__Segmentindex__c  =1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[2].Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = null,SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, SBQQ__DefaultSubscriptionTerm__c = 12,CCLI__c = cliid, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__SubscribedAssetIds__c=assestIns.Id,SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[3].Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 1, SBQQ__Segmentindex__c  =1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        insert lines;

        lines[0].SBQQ__Bundle__c = true;
        lines[1].SBQQ__RequiredBy__c = lines[0].Id;
        lines[2].SBQQ__RequiredBy__c = lines[0].Id;
        lines[3].SBQQ__RequiredBy__c = lines[0].Id;
        update lines;
        
        system.debug('Lines***'+lines);      

        Order orderInstance = new Order();
        orderInstance.AccountId = customer.Id;
        orderInstance.OpportunityId = opp.Id;
        orderInstance.EffectiveDate = system.today();  
        orderInstance.Status = 'Draft';
        orderInstance.Type = 'Revenue';
        orderInstance.Order_Sub_Type__c = 'MSP Consumption Renewal'; 
        orderInstance.Pricebook2Id = Test.getStandardPricebookId(); 
        insert orderInstance;
        
        Order orderInstance1 = new Order();
        orderInstance1.AccountId = customer.Id;
        orderInstance1.OpportunityId = opp.Id;
        orderInstance1.EffectiveDate = system.today();  
        orderInstance1.Status = 'Draft';
        orderInstance1.Type = 'Revenue';
        orderInstance1.Pricebook2Id = Test.getStandardPricebookId(); 
        
        List<OrderItem> orderItemList = new List<OrderItem>();
        
        OrderItem orderItemAdd1 = new OrderItem();
        orderItemAdd1.OrderId = orderInstance.Id;
        orderItemAdd1.Product2Id = sampleProducts[1].Id;
        orderItemAdd1.UnitPrice = entries[1].UnitPrice;
        orderItemAdd1.SBQQ__QuoteLine__c = lines[1].Id;
        orderItemAdd1.Quantity = 20;
        orderItemAdd1.SBQQ__Segmentindex__c =1; 
        orderItemAdd1.SerialNumber__c = '09092019APMSP1250';
        orderItemAdd1.Support_Start_Date__c = System.today();
        orderItemAdd1.Support_End_Date__c = System.today().addMonths(36);
        orderItemAdd1.PricebookEntryId = entries[1].Id;
        orderItemList.add(orderItemAdd1);
      
        OrderItem orderItemCons = new OrderItem();
        orderItemCons.OrderId = orderInstance.Id;
        orderItemCons.Product2Id = sampleProducts[0].Id;
        orderItemCons.UnitPrice = entries[0].UnitPrice;
        orderItemCons.SBQQ__QuoteLine__c = lines[0].Id;
        orderItemCons.SerialNumber__c = '09092019APMSP1250';        
        orderItemCons.Quantity = 20;
        orderItemCons.PricebookEntryId = entries[0].Id;
        insert orderItemCons;
        //orderItemList.add(orderItemCons);
        
        OrderItem orderItemAdd = new OrderItem();
        orderItemAdd.OrderId = orderInstance.Id;
        orderItemAdd.Product2Id = sampleProducts[2].Id;
        orderItemAdd.UnitPrice = entries[2].UnitPrice;
        orderItemAdd.SBQQ__RequiredBy__c = orderItemCons.Id;
        orderItemAdd.SBQQ__Segmentindex__c = 1; 
        orderItemAdd.Support_Start_Date__c = System.today();
        orderItemAdd.MSP_Segment_Product__c = TRUE;
        orderItemAdd.Quantity = 20;
        orderItemAdd.SBQQ__QuoteLine__c = lines[1].Id;
        orderItemAdd.PricebookEntryId = entries[1].Id;
        insert orderItemAdd;
        //orderItemList.add(orderItemAdd);

        OrderItem oi = new OrderItem();
        oi.OrderId = orderInstance.Id;
        oi.Product2Id = sampleProducts[3].Id;
        oi.UnitPrice = entries[3].UnitPrice;
        oi.SBQQ__Segmentindex__c = 1; 
        oi.Support_Start_Date__c = System.today();
        oi.Quantity = 20;
        oi.SBQQ__QuoteLine__c = lines[1].Id;
        oi.PricebookEntryId = entries[1].Id;
        orderItemList.add(oi);
        
        insert orderItemList;
        
        ServiceContract sc = new ServiceContract();
        sc.Name = 'Test opp - 30 Sept - Contract';
        sc.AccountId = customer.Id;
        sc.SBQQSC__Order__c = orderInstance.Id;
        sc.SBQQSC__Quote__c = quote.Id;
        sc.SBQQSC__Opportunity__c = opp.Id;
        sc.Pricebook2Id = Test.getStandardPricebookId();
        sc.Term = 36;
        sc.StartDate = System.Today();
        sc.EndDate = System.today().addMonths(36);
        insert sc;
        
        List<contractLineItem> cliList = new List<contractLineItem>();
        ContractLineItem contractLineItem2 = new ContractLineItem();
        contractLineItem2.ServiceContractID = sc.Id;
        contractLineItem2.AssetId = assetObj.Id;
        contractLineItem2.SBQQSC__QuoteLine__c = lines[0].Id;
        contractLineItem2.SBQQSC__Account__c = customer.Id;
        contractLineItem2.SBQQSC__Product__c = sampleProducts[1].Id;       
        contractLineItem2.SBQQSC__OrderProduct__c = orderItemList[0].id;
        contractLineItem2.MSP_Segment_Product__c = true;
        contractLineItem2.PricebookEntryId = entries[1].Id;
        contractLineItem2.Quantity = 10;
        contractLineItem2.UnitPrice = entries[1].UnitPrice;
        cliList.add(contractLineItem2);
        
        ContractLineItem contractLineItem1 = new ContractLineItem();
        contractLineItem1.ServiceContractID = sc.Id;
        contractLineItem1.AssetId = assetObj.Id;
        contractLineItem1.SBQQSC__QuoteLine__c = lines[1].Id;
        contractLineItem1.SBQQSC__Account__c = customer.Id;
        contractLineItem1.SBQQSC__Product__c = sampleProducts[2].Id;       
        contractLineItem1.SBQQSC__OrderProduct__c = orderItemAdd.id;
        contractLineItem1.MSP_Segment_Product__c = TRUE;
        contractLineItem1.PricebookEntryId = entries[2].Id;
        contractLineItem1.Quantity = 10;
        contractLineItem1.UnitPrice = entries[2].UnitPrice;
        cliList.add(contractLineItem1);
        
        ContractLineItem contractLineItem3 = new ContractLineItem();
        contractLineItem3.ServiceContractID = sc.Id;
        contractLineItem3.SBQQSC__QuoteLine__c = lines[2].Id;
        contractLineItem3.SBQQSC__Account__c = customer.Id;
        contractLineItem3.SBQQSC__Product__c = sampleProducts[3].Id;       
        contractLineItem3.SBQQSC__OrderProduct__c = orderItemList[1].id;
        contractLineItem3.MSP_Segment_Product__c = TRUE;
        contractLineItem3.PricebookEntryId = entries[3].Id;
        contractLineItem3.Quantity = 10;
        contractLineItem3.UnitPrice = entries[3].UnitPrice;
        cliList.add(contractLineItem3);
        
        insert cliList;
        
         List<Entitlement> lstEntitlement1 = new List<Entitlement>();
        Entitlement enttitlement1 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
         enttitlement1.AccountId = customer.Id;
        enttitlement1.StartDate = Date.today().addDays(-365);
        enttitlement1.EndDate = Date.today().addDays(365);
        enttitlement1.AssetId = assetObj.Id;
        enttitlement1.ContractLineItemId = cliList[0].Id;
        enttitlement1.Renewable__c = true;
        enttitlement1.Type = 'Phone Support';
        enttitlement1.Name = 'EntitlementTriggerHelper';
        enttitlement1.Product__c = sampleProducts[0].Id;
        enttitlement1.Refreshed_Opportunity_Link__c = lstOpportunity[0].Id;
        enttitlement1.ServiceContractId = lstServiceContract[0].Id;
        lstEntitlement1.add(enttitlement1);

        Entitlement enttitlement2 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        enttitlement2.AccountId = customer.Id;
        enttitlement2.StartDate = Date.today().addDays(-365);
        enttitlement2.EndDate = Date.today().addDays(365);
        enttitlement2.AssetId = assetObj.Id;
        enttitlement2.ContractLineItemId = cliList[1].Id;
        enttitlement2.Renewable__c = true;
        enttitlement2.Type = 'Phone Support';
        enttitlement2.Name = 'EntitlementTriggerHelper';
        enttitlement2.Product__c = sampleProducts[1].Id;
        enttitlement2.Refreshed_Opportunity_Link__c = lstOpportunity[1].Id;
        enttitlement2.ServiceContractId = lstServiceContract[1].Id;
        lstEntitlement1.add(enttitlement2);

        Entitlement enttitlement3 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        enttitlement3.AccountId = customer.Id;
        enttitlement3.StartDate = Date.today().addDays(-365);
        enttitlement3.EndDate = Date.today().addDays(365);
        enttitlement3.AssetId = assetObj.Id;
        enttitlement3.ContractLineItemId = cliList[2].Id;
        enttitlement3.Renewable__c = true;
        enttitlement3.Type = 'Phone Support';
        enttitlement3.Name = 'EntitlementTriggerHelper';
        enttitlement3.Product__c = sampleProducts[2].Id;
        enttitlement3.Refreshed_Opportunity_Link__c = lstOpportunity[1].Id;
        enttitlement3.ServiceContractId = lstServiceContract[1].Id;
        lstEntitlement1.add(enttitlement3);
        //insert lstEntitlement;
        
        
        Entitlement enttitlement4 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        enttitlement4.AccountId = customer.Id;
        enttitlement4.StartDate = Date.today().addDays(-365);
        enttitlement4.EndDate = Date.today().addDays(365);
        enttitlement4.AssetId = assetObj.Id;
        enttitlement4.ContractLineItemId = ContractLineItemObj1.Id;
        enttitlement4.Renewable__c = true;
        enttitlement4.Type = 'Phone Support';
        enttitlement4.Name = 'EntitlementTriggerHelper';
        enttitlement4.Product__c = sampleProducts[3].Id;
        enttitlement4.Refreshed_Opportunity_Link__c = lstOpportunity[1].Id;
        enttitlement4.ServiceContractId = lstServiceContract[1].Id;
       // lstEntitlement1.add(enttitlement4);
        insert lstEntitlement1;
    }

    @isTest
    public static void insertEntitlementLinksTest() {
        
        List<Entitlement> entitlementNewList =[SELECT Id
                                                    , AccountId
                                                    , StartDate
                                                    , EndDate
                                                    , AssetId
                                                    , ContractLineItemId
                                                    , Renewable__c
                                                    , Type
                                                    , Name
                                                    , Product__c
                                                    , ServiceContractId
                                                    , Subscription_Term__c
                                                    , Service_Contract_Opportunity__c
                                                    , ServiceContract.SBQQSC__Opportunity__c
                                                    , Product__r.Product_Level__c
                                                    ,OldContractLineItem__c
                                                 FROM Entitlement];

        
        
        Test.startTest();
        AssetAndEntitlementLinkUtility.insertEntLinksAndUpdateEligForFreeHW(entitlementNewList);
        Test.stopTest();
    }


    /* removing this method as the original one is not in use
    @isTest
    public static void updateEligibleForFreeHWTest() {
        
        List<Entitlement> entitlementNewList =[SELECT Id
                                                    , AccountId
                                                    , StartDate
                                                    , EndDate
                                                    , AssetId
                                                    , ContractLineItemId
                                                    , Renewable__c
                                                    , Type
                                                    , Name
                                                    , Product__c
                                                    , Product__r.Product_Subtype__c
                                                    , ServiceContractId
                                                    , Subscription_Term__c
                                                    , Refreshed_Opportunity_Link__c
                                                    , ServiceContract.SBQQSC__Opportunity__c
                                                    , Service_Contract_Opportunity__c
                                                    , Product__r.Product_Level__c
                                                 FROM Entitlement];

        System.debug('entitlementNewList===='+entitlementNewList);

        Map<Id, List<Entitlement>> oldOpportunityIdVsOldEntitlementListMap = new Map<Id, List<Entitlement>>();
        Map<Id, Id> oldProductVsNewProductIdMap = new Map<Id, Id>();
        Map<Id, Id> assetIdVsEntitlementIdMap = new Map<Id, Id>();
        Map<Id, Id> serviceContractIdVsOpportunityIdMap = new Map<Id, Id>();

        for(Entitlement entitlementObj : entitlementNewList) {

            List<Entitlement> entitlementTempList = oldOpportunityIdVsOldEntitlementListMap.get(entitlementObj.Service_Contract_Opportunity__c);
            System.debug('225 entitlementTempList===='+entitlementTempList);

            if(entitlementTempList == null) entitlementTempList = new List<Entitlement>();

            entitlementTempList.add(entitlementObj);
            oldOpportunityIdVsOldEntitlementListMap.put(entitlementObj.Service_Contract_Opportunity__c, entitlementTempList);
        }
        
        Test.startTest();
        AssetAndEntitlementLinkUtility.updateEligibleForFreeHW(oldOpportunityIdVsOldEntitlementListMap);                                                                                                    
        Test.stopTest();
    } */

}