@isTest
private class CreateEntitlementAndUpdateAssetsTest {

    @isTest
    private static void testAssetAndEntitlement() {
        insert new ShGl_DisableFunctionalityLogic__c(setupOwnerId = UserInfo.getUserId(), Disable_Account_Old_Trigger__c = TRUE);
        insert new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getUserId(), 
              Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
              Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
              Disable_Opportunity_Triggers__c=true);
        TriggerControl.stopOrderItemTrigger = true;
        TriggerControl.stopOrderTrigger = true;
        //TriggerControl__c objOrderTrigger = new TriggerControl__c(Name = 'Order', Disable_Trigger__c = false, 
                                                           //  DisableTrigger__c = true, SendEmail__c = false);
        //insert objOrderTrigger;
        
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

        Opportunity opp = TestDataFactory.getOpportunity();
        opp.Distributor_Lookup__c = customer.Id;
        opp.Partner_Lookup__c = customer.Id;
        opp.AccountId = customer.Id;
        insert opp;
        
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__SubscriptionTerm__c = 12,
            SBQQ__Primary__c = true,
            SBQQ__PriceBook__c = Test.getStandardPricebookId());
        insert quote;

        List<Product2> sampleProducts = new List<Product2>();
        Product2 prodq = new Product2(
            Name = 'ACPQ Bundle Product',
            ProductCode = 'ACPQ Bundle Product',
            IsActive = true,
            MSP_Segment_Product__c = true,
            SBQQ__Hidden__c = true,
            SBQQ__ExcludeFromOpportunity__c = true,
            New_CPQ_Product__c = true
        );

        Product2 prodq1 = 
                new Product2(
                    Name = 'RBK-R6412-CONS',
                    ProductCode = 'RBK-R6412-CONS',
                    Category__c = 'Platform',
                    Family = 'r300',
                    Product_Type__c = 'Appliance',
                    Appliance_Model__c='RBK-R344',
                    Appliance_Model_HW__c = 'RBK-R344',
                    CPQ_MSP_Base_Price__c = 0.133,
                    SBQQSC__EntitlementConversion__c = 'None',
                    SBQQ__AssetAmendmentBehavior__c = 'Default',
                    IsActive = true,
                    Asset_Priority__c = 0,
                    MSP_Segment_Product__c = true,
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 1,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable'
                );
                
                Product2 prodq2 = new Product2(
                    Name = 'RBK-RADAR-CONS',
                    ProductCode = 'RBK-RADAR-CONS',
                    Category__c = 'Support',
                    SBQQ__AssetAmendmentBehavior__c = 'Default',
                    SBQQSC__EntitlementConversion__c = 'One per quote line',
                    IsActive = true,
                    CPQ_MSP_Base_Price__c = 0.22,
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 36,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable'
                );
                Product2 prodq3 = new Product2(
                    Name = 'RBK-RADAR-CONS1',
                    ProductCode = 'RBK-RADAR-CONS1',
                    Category__c = 'Support',
                    SBQQ__AssetAmendmentBehavior__c = 'Default',
                    SBQQSC__EntitlementConversion__c = 'One per quote line',
                    IsActive = true,
                    CPQ_MSP_Base_Price__c = 0.12,
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 36,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable'
                );
                sampleProducts.add(prodq1);
                sampleProducts.add(prodq);
                sampleProducts.add(prodq2);
                sampleProducts.add(prodq3);
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
        List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
        lines.add(new SBQQ__QuoteLine__c(SBQQ__SubscribedAssetIds__c=assestIns.Id,SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[0].Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SubscribedAssetNames__c = 'Test Subscribed Asset', Subscribed_Asset_Name__c = 'Test Asset'));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__SubscribedAssetIds__c=assestIns.Id,SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[1].Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 1, SBQQ__Segmentindex__c  =1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200,SubscribedAssetNames__c = 'Test Subscribed Asset', Subscribed_Asset_Name__c = 'Test Asset'));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[2].Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__SubscribedAssetIds__c=assestIns.Id,SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[3].Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 1, SBQQ__Segmentindex__c  =1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200,SubscribedAssetNames__c = 'Test Subscribed Asset', Subscribed_Asset_Name__c = 'Test Asset'));
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
        orderInstance.Support_Start_Date__c = system.today(); 
        orderInstance.Support_End_Date__c = System.today().addMonths(50);
        orderInstance.Status = 'Draft';
        orderInstance.Type = 'Revenue';
        orderInstance.Order_Sub_Type__c = 'MSP Consumption Renewal'; 
        orderInstance.Pricebook2Id = Test.getStandardPricebookId(); 
        insert orderInstance;
        
        Order orderInstance1 = new Order();
        orderInstance1.AccountId = customer.Id;
        orderInstance1.OpportunityId = opp.Id;
        orderInstance1.EffectiveDate = system.today().addMonths(10);
        orderInstance1.Support_Start_Date__c = system.today().addMonths(5); 
        orderInstance1.Support_End_Date__c = System.today().addMonths(55);
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
        orderItemAdd1.SerialNumber__c = 'Test Asset,09092019APMSP1250';
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
        orderItemCons.SBQQ__RequiredBy__c = orderItemAdd1.Id;
        orderItemCons.Quantity = 20;
        orderItemCons.Support_Start_Date__c = System.today().addMonths(3);
        orderItemCons.Support_End_Date__c = System.today().addMonths(30);
        orderItemCons.PricebookEntryId = entries[0].Id;
        insert orderItemCons;
        //orderItemList.add(orderItemCons);
        
        OrderItem orderItemAdd = new OrderItem();
        orderItemAdd.OrderId = orderInstance.Id;
        orderItemAdd.Product2Id = sampleProducts[2].Id;
        orderItemAdd.UnitPrice = entries[2].UnitPrice;
        orderItemAdd.SBQQ__RequiredBy__c = orderItemCons.Id;
        orderItemAdd.SerialNumber__c = '09092019APMSP1250';
        orderItemAdd.SBQQ__Segmentindex__c = 1; 
        orderItemAdd.Support_Start_Date__c = System.today().addMonths(3);
        orderItemAdd.Support_End_Date__c = System.today().addMonths(30);
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
        oi.SerialNumber__c = '09092019APMSP1250';
        oi.SBQQ__Segmentindex__c = 1; 
        oi.Support_Start_Date__c = System.today().addMonths(5);
        oi.Support_End_Date__c = System.today().addMonths(40);
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
        
        Asset asst = new Asset();
        asst.Name = 'Test Asset';
        asst.Product2Id = sampleProducts[0].Id;
        asst.AccountId = customer.Id;
        insert asst;
        
        List<contractLineItem> cliList = new List<contractLineItem>();
        ContractLineItem contractLineItem2 = new ContractLineItem();
        contractLineItem2.ServiceContractID = sc.Id;
        contractLineItem2.SBQQSC__QuoteLine__c = lines[1].Id;
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
        contractLineItem1.SBQQSC__QuoteLine__c = lines[2].Id;
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
        contractLineItem3.SBQQSC__QuoteLine__c = lines[3].Id;
        contractLineItem3.SBQQSC__Account__c = customer.Id;
        contractLineItem3.SBQQSC__Product__c = sampleProducts[3].Id;       
        contractLineItem3.SBQQSC__OrderProduct__c = orderItemList[1].id;
        contractLineItem3.MSP_Segment_Product__c = TRUE;
        contractLineItem3.PricebookEntryId = entries[3].Id;
        contractLineItem3.Quantity = 10;
        contractLineItem3.UnitPrice = entries[3].UnitPrice;
        cliList.add(contractLineItem3);
        
        
        
        insert cliList;
        
        system.debug('contractLineItem--1' + cliList[0].Id);
        system.debug('contractLineItem--1 SerialNum' + cliList[0].SBQQSC__OrderProduct__r.SBQQ__RequiredBy__r.SerialNumber__c);
        system.debug('contractLineItem--2' + cliList[1].Id);
        system.debug('contractLineItem--2 SerialNum' + cliList[1].SBQQSC__OrderProduct__r.SBQQ__RequiredBy__r.SerialNumber__c);
        system.debug('contractLineItem--3' + cliList[2].Id);
        system.debug('contractLineItem--3 SerialNum' + cliList[2].SBQQSC__OrderProduct__r.SBQQ__RequiredBy__r.SerialNumber__c);
        
        //Test.stopTest();
        //Test.startTest();
        CreateEntitlementAndUpdateAssetsBatch batchInstance = new CreateEntitlementAndUpdateAssetsBatch();
        Database.executeBatch(batchInstance);
        Test.stopTest();
       
    }
    
     @isTest
    private static void testAssetAndEntitlement2() {
        String uniqueUserName = 'AdminUser' + DateTime.now().getTime() + '@rubrik.com';
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User u = new User(
            Alias = 'adminU', Email='AdminUser@rubrik.com',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles',
            UserName=uniqueUserName
        );
        insert u;
        System.runAs(u) {
        insert new ShGl_DisableFunctionalityLogic__c(setupOwnerId = UserInfo.getUserId(), Disable_Account_Old_Trigger__c = TRUE);
        insert new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getUserId(), 
              Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
              Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
              Disable_Opportunity_Triggers__c=true,Name = 'System Administrator',
              Disable_Entitlement_Validation_Rules__c = true);
        TriggerControl.stopOrderItemTrigger = true;
        TriggerControl.stopOrderTrigger = true;
        triggerControl.stopEntitlementTrigger = true;
        TriggerControl__c objOrderTrigger2 = new TriggerControl__c(Name = 'Entitlement', Disable_Trigger__c = true, 
                                                           DisableTrigger__c = true, SendEmail__c = false);
        insert objOrderTrigger2;
        
        Id partner2 = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account customer2 = new Account(
            Name = 'Customer',
            recordtypeId = partner2,
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
        insert customer2;

        Opportunity opp2 = TestDataFactory.getOpportunity();
        opp2.Distributor_Lookup__c = customer2.Id;
        opp2.Partner_Lookup__c = customer2.Id;
        opp2.AccountId = customer2.Id;
        insert opp2;
        
        SBQQ__Quote__c quote2 = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp2.Id,
            SBQQ__SubscriptionTerm__c = 12,
            SBQQ__Primary__c = true,
            SBQQ__PriceBook__c = Test.getStandardPricebookId());
        insert quote2;

        List<Product2> sampleProducts2 = new List<Product2>();
        
            Product2 prods = 
                new Product2(
                    Name = 'CPQ Bundle Product',
                    ProductCode = 'CPQ Bundle Product',
                    IsActive = true,
                    MSP_Segment_Product__c = true,
                    SBQQ__Hidden__c = true,
                    SBQQ__ExcludeFromOpportunity__c = true,
                    New_CPQ_Product__c = true
                );
                Product2 prods1 = 
                new Product2(
                    Name = 'ARBK-R6412-CONS',
                    ProductCode = 'ARBK-R6412-CONS',
                    Category__c = 'Platform',
                    Family = 'r300',
                    Product_Type__c = 'Appliance',
                    Appliance_Model__c='RBK-R344',
                    Appliance_Model_HW__c = 'RBK-R344',
                    CPQ_MSP_Base_Price__c = 0.313,
                    SBQQSC__EntitlementConversion__c = 'None',
                    SBQQ__AssetAmendmentBehavior__c = 'Default',
                    IsActive = true,
                    Asset_Priority__c = 0,
                    MSP_Segment_Product__c = true,
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 1,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable'
                );
                Product2 prods2 = 
                new Product2(
                    Name = 'ARBK-RADAR-CONS',
                    ProductCode = 'ARBK-RADAR-CONS',
                    Category__c = 'Support',
                    SBQQ__AssetAmendmentBehavior__c = 'Default',
                    SBQQSC__EntitlementConversion__c = 'One per quote line',
                    IsActive = true,
                    CPQ_MSP_Base_Price__c = 0.302,
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 36,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable'
                );
                Product2 prods4 = 
                 new Product2(
                    Name = 'ARBK-RADAR-CONS1',
                    ProductCode = 'ARBK-RADAR-CONS1',
                    Category__c = 'Support',
                    SBQQ__AssetAmendmentBehavior__c = 'Default',
                    SBQQSC__EntitlementConversion__c = 'One per quote line',
                    IsActive = true,
                    CPQ_MSP_Base_Price__c = 0.032,
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 36,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable'
                ); 
        sampleProducts2.add(prods);
        sampleProducts2.add(prods1);
        sampleProducts2.add(prods2);
        sampleProducts2.add(prods4);
        insert sampleProducts2;
        system.debug('sampleProducts2***'+sampleProducts2);
        system.debug('sample3***'+sampleProducts2[3]);
        List<PricebookEntry>entries2 = new List<PricebookEntry>();

        entries2.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts2[0].Id, IsActive = true, UnitPrice = 100));
        entries2.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts2[1].Id, IsActive = true, UnitPrice = 200));
        entries2.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts2[2].Id, IsActive = true, UnitPrice = 100));
        entries2.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts2[3].Id, IsActive = true, UnitPrice = 100));
        insert entries2;
        system.debug('entries2****'+entries2);
        List<SBQQ__ProductOption__c>prodOptions = new List<SBQQ__ProductOption__c>();
        prodOptions.add(new SBQQ__ProductOption__c(SBQQ__Number__c = 20, SBQQ__ConfiguredSKU__c = sampleProducts2[1].Id, SBQQ__OptionalSKU__c = sampleProducts2[1].Id));
        prodOptions.add(new SBQQ__ProductOption__c(SBQQ__Number__c = 30, SBQQ__ConfiguredSKU__c = sampleProducts2[2].Id, SBQQ__OptionalSKU__c = sampleProducts2[1].Id));
        prodOptions.add(new SBQQ__ProductOption__c(SBQQ__Number__c = 30, SBQQ__ConfiguredSKU__c = sampleProducts2[3].Id, SBQQ__OptionalSKU__c = sampleProducts2[1].Id));
        insert prodOptions;
        Test.startTest();
        
        Asset assestIns2 = new Asset();
        assestIns2.Name = '09092019APMSP1250';
        assestIns2.SerialNumber = '09092019APMSP1250';
        assestIns2.serial_number__c= '09092019APMSP1250';
        assestIns2.AccountId = customer2.Id;
        assestIns2.Product2Id = sampleProducts2[0].Id;
        insert assestIns2;
        
        List<SBQQ__QuoteLine__c>lines2 = new List<SBQQ__QuoteLine__c>();
        lines2.add(new SBQQ__QuoteLine__c(SBQQ__SubscribedAssetIds__c=assestIns2.Id,SBQQ__Quote__c = quote2.Id, SBQQ__Product__c = sampleProducts2[0].Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SubscribedAssetNames__c = 'Test Subscribed Asset', Subscribed_Asset_Name__c = 'Test Asset'));
        lines2.add(new SBQQ__QuoteLine__c(SBQQ__SubscribedAssetIds__c=assestIns2.Id,SBQQ__Quote__c = quote2.Id, SBQQ__Product__c = sampleProducts2[1].Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 1, SBQQ__Segmentindex__c  =1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200,SubscribedAssetNames__c = 'Test Subscribed Asset', Subscribed_Asset_Name__c = 'Test Asset'));
        lines2.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote2.Id, SBQQ__Product__c = sampleProducts2[2].Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines2.add(new SBQQ__QuoteLine__c(SBQQ__SubscribedAssetIds__c=assestIns2.Id,SBQQ__Quote__c = quote2.Id, SBQQ__Product__c = sampleProducts2[3].Id, MSP_Segment_Product__c = true, SBQQ__Quantity__c = 1, SBQQ__Segmentindex__c  =1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200,SubscribedAssetNames__c = 'Test Subscribed Asset', Subscribed_Asset_Name__c = 'Test Asset'));
        insert lines2;

        lines2[0].SBQQ__Bundle__c = true;
        lines2[1].SBQQ__RequiredBy__c = lines2[0].Id;
        lines2[2].SBQQ__RequiredBy__c = lines2[0].Id;
        lines2[3].SBQQ__RequiredBy__c = lines2[0].Id;
        update lines2;
        
        system.debug('lines2***'+lines2);      

        Order orderInstance2 = new Order();
        orderInstance2.AccountId = customer2.Id;
        orderInstance2.OpportunityId = opp2.Id;
        orderInstance2.EffectiveDate = system.today(); 
        orderInstance2.Support_Start_Date__c = system.today(); 
        orderInstance2.Support_End_Date__c = System.today().addMonths(50);
        orderInstance2.Status = 'Draft';
        orderInstance2.Type = 'Revenue';
        orderInstance2.Order_Sub_Type__c = 'MSP Consumption Renewal'; 
        orderInstance2.Pricebook2Id = Test.getStandardPricebookId(); 
        insert orderInstance2;
        
        Order orderInstance2_2 = new Order();
        orderInstance2_2.AccountId = customer2.Id;
        orderInstance2_2.OpportunityId = opp2.Id;
        orderInstance2_2.EffectiveDate = system.today().addMonths(10);
        orderInstance2_2.Support_Start_Date__c = system.today().addMonths(5); 
        orderInstance2_2.Support_End_Date__c = System.today().addMonths(55);
        orderInstance2_2.Status = 'Draft';
        orderInstance2_2.Type = 'Revenue';
        orderInstance2_2.Pricebook2Id = Test.getStandardPricebookId(); 
        orderInstance2_2.Order_Sub_Type__c= 'MSP Consumption Renewal';
         insert orderInstance2_2;
        List<OrderItem> orderItemList2 = new List<OrderItem>();
        
        OrderItem orderItemAdd1_2 = new OrderItem();
        orderItemAdd1_2.OrderId = orderInstance2.Id;
        orderItemAdd1_2.Product2Id = sampleProducts2[1].Id;
        orderItemAdd1_2.UnitPrice = entries2[1].UnitPrice;
        orderItemAdd1_2.SBQQ__QuoteLine__c = lines2[1].Id;
        orderItemAdd1_2.Quantity = 20;
        orderItemAdd1_2.SBQQ__Segmentindex__c =1;
        orderItemAdd1_2.SerialNumber__c = 'Test Asset,09092019APMSP1250';
        orderItemAdd1_2.Support_Start_Date__c = System.today();
        orderItemAdd1_2.Support_End_Date__c = System.today().addMonths(36);
        orderItemAdd1_2.PricebookEntryId = entries2[1].Id;
        orderItemList2.add(orderItemAdd1_2);
      
        OrderItem orderItemCons2 = new OrderItem();
        orderItemCons2.OrderId = orderInstance2.Id;
        orderItemCons2.Product2Id = sampleProducts2[0].Id;
        orderItemCons2.UnitPrice = entries2[0].UnitPrice;
        orderItemCons2.SBQQ__QuoteLine__c = lines2[0].Id;
        orderItemCons2.SerialNumber__c = '09092019APMSP1250';   
        orderItemCons2.SBQQ__RequiredBy__c = orderItemAdd1_2.Id;
        orderItemCons2.Quantity = 20;
        orderItemCons2.Support_Start_Date__c = System.today().addMonths(3);
        orderItemCons2.Support_End_Date__c = System.today().addMonths(30);
        orderItemCons2.PricebookEntryId = entries2[0].Id;
        insert orderItemCons2;
        //orderItemList2.add(orderItemCons2);
        
        OrderItem orderItemAdd_2 = new OrderItem();
        orderItemAdd_2.OrderId = orderInstance2.Id;
        orderItemAdd_2.Product2Id = sampleProducts2[2].Id;
        orderItemAdd_2.UnitPrice = entries2[2].UnitPrice;
        orderItemAdd_2.SBQQ__RequiredBy__c = orderItemCons2.Id;
        orderItemAdd_2.SerialNumber__c = '09092019APMSP1250';
        orderItemAdd_2.SBQQ__Segmentindex__c = 1; 
        orderItemAdd_2.Support_Start_Date__c = System.today().addMonths(3);
        orderItemAdd_2.Support_End_Date__c = System.today().addMonths(30);
        orderItemAdd_2.MSP_Segment_Product__c = TRUE;
        orderItemAdd_2.Quantity = 20;
        orderItemAdd_2.SBQQ__QuoteLine__c = lines2[1].Id;
        orderItemAdd_2.PricebookEntryId = entries2[1].Id;
        insert orderItemAdd_2;
        //orderItemList2.add(orderItemAdd_2);

        OrderItem oi2 = new OrderItem();
        oi2.OrderId = orderInstance2.Id;
        oi2.Product2Id = sampleProducts2[3].Id;
        oi2.UnitPrice = entries2[3].UnitPrice;
        oi2.SerialNumber__c = '09092019APMSP1250';
        oi2.SBQQ__Segmentindex__c = 1; 
        oi2.Support_Start_Date__c = System.today().addMonths(5);
        oi2.Support_End_Date__c = System.today().addMonths(40);
        oi2.Quantity = 20;
        oi2.SBQQ__QuoteLine__c = lines2[1].Id;
        oi2.PricebookEntryId = entries2[1].Id;
        orderItemList2.add(oi2);
        
        insert orderItemList2;
        
        ServiceContract sc2 = new ServiceContract();
        sc2.Name = 'Test opp2 - 30 Sept - Contract';
        sc2.AccountId = customer2.Id;
        sc2.SBQQSC__Order__c = orderInstance2.Id;
        sc2.SBQQSC__Quote__c = quote2.Id;
        sc2.SBQQSC__Opportunity__c = opp2.Id;
        sc2.Pricebook2Id = Test.getStandardPricebookId();
        sc2.Term = 36;
        sc2.StartDate = System.Today();
        sc2.EndDate = System.today().addMonths(36);
        insert sc2;
        
        Asset asst2 = new Asset();
        asst2.Name = 'Test Asset';
        asst2.Product2Id = sampleProducts2[0].Id;
        asst2.AccountId = customer2.Id;
        insert asst2;
        
        List<contractLineItem> cliList2 = new List<contractLineItem>();
        ContractLineItem contractLineItem2 = new ContractLineItem();
        contractLineItem2.ServiceContractID = sc2.Id;
        contractLineItem2.SBQQSC__QuoteLine__c = lines2[1].Id;
        contractLineItem2.SBQQSC__Account__c = customer2.Id;
        contractLineItem2.SBQQSC__Product__c = sampleProducts2[1].Id;       
        contractLineItem2.SBQQSC__OrderProduct__c = orderItemList2[0].id;
        contractLineItem2.MSP_Segment_Product__c = true;
        contractLineItem2.PricebookEntryId = entries2[1].Id;
        contractLineItem2.Quantity = 10;
        contractLineItem2.UnitPrice = entries2[1].UnitPrice;
        cliList2.add(contractLineItem2);
        
        ContractLineItem contractLineItem1_2 = new ContractLineItem();
        contractLineItem1_2.ServiceContractID = sc2.Id;
        contractLineItem1_2.SBQQSC__QuoteLine__c = lines2[2].Id;
        contractLineItem1_2.SBQQSC__Account__c = customer2.Id;
        contractLineItem1_2.SBQQSC__Product__c = sampleProducts2[2].Id;       
        contractLineItem1_2.SBQQSC__OrderProduct__c = orderItemAdd_2.id;
        contractLineItem1_2.MSP_Segment_Product__c = TRUE;
        contractLineItem1_2.PricebookEntryId = entries2[2].Id;
        contractLineItem1_2.Quantity = 10;
        contractLineItem1_2.UnitPrice = entries2[2].UnitPrice;
        cliList2.add(contractLineItem1_2);
        
        ContractLineItem contractLineItem3_2 = new ContractLineItem();
        contractLineItem3_2.ServiceContractID = sc2.Id;
        contractLineItem3_2.SBQQSC__QuoteLine__c = lines2[3].Id;
        contractLineItem3_2.SBQQSC__Account__c = customer2.Id;
        contractLineItem3_2.SBQQSC__Product__c = sampleProducts2[3].Id;       
        contractLineItem3_2.SBQQSC__OrderProduct__c = orderItemList2[1].id;
        contractLineItem3_2.MSP_Segment_Product__c = TRUE;
        contractLineItem3_2.PricebookEntryId = entries2[3].Id;
        contractLineItem3_2.Quantity = 10;
        contractLineItem3_2.UnitPrice = entries2[3].UnitPrice;
        cliList2.add(contractLineItem3_2);
        
        insert cliList2;
        
          
        Entitlement entitle_2 = new Entitlement();
        entitle_2.Name = 'Test Entitlement';
        entitle_2.AccountId = customer2.Id;
        entitle_2.AssetId = asst2.Id;
        entitle_2.ContractLineItemId = cliList2[0].Id;
        entitle_2.MSP_Segment_Product__c = true;
        entitle_2.ServiceContractId = sc2.Id;
        entitle_2.StartDate = System.Today();
        entitle_2.EndDate = System.today().addMonths(36);
        insert entitle_2;
        
        Entitlement entitle1_2 = new Entitlement();
        entitle1_2.Name = 'Test Entitlement1';
        entitle1_2.AssetId = asst2.Id;
        entitle1_2.AccountId = customer2.Id;
        entitle1_2.ServiceContractId = sc2.Id;
        entitle1_2.ContractLineItemId = cliList2[1].Id;
        entitle1_2.MSP_Segment_Product__c = true;
        entitle1_2.StartDate = System.Today();
        entitle1_2.EndDate = System.today().addMonths(30);
        insert entitle1_2;
        
        Entitlement entitle2_2 = new Entitlement();
        entitle2_2.Name = 'Test Entitlement1';
        entitle2_2.AccountId = customer2.Id;
        entitle2_2.AssetId = asst2.Id;
        entitle2_2.ServiceContractId = sc2.Id;
        entitle2_2.ContractLineItemId = cliList2[1].Id;
        entitle2_2.MSP_Segment_Product__c = true;
        entitle2_2.StartDate = System.Today();
        entitle2_2.EndDate = System.today().addMonths(20);
        insert entitle2_2;
      
        system.debug('contractLineItem--1' + cliList2[0].Id);
        system.debug('contractLineItem--1 SerialNum' + cliList2[0].SBQQSC__OrderProduct__r.SBQQ__RequiredBy__r.SerialNumber__c);
        system.debug('contractLineItem--2' + cliList2[1].Id);
        system.debug('contractLineItem--2 SerialNum' + cliList2[1].SBQQSC__OrderProduct__r.SBQQ__RequiredBy__r.SerialNumber__c);
        system.debug('contractLineItem--3' + cliList2[2].Id);
        system.debug('contractLineItem--3 SerialNum' + cliList2[2].SBQQSC__OrderProduct__r.SBQQ__RequiredBy__r.SerialNumber__c);
        
        //Test.stopTest();
        //Test.startTest();
        CreateEntitlementAndUpdateAssetsBatch batchInstance = new CreateEntitlementAndUpdateAssetsBatch();
        Database.executeBatch(batchInstance);
        Test.stopTest();
        }
    }
    
    
    @isTest
    private static void testEntitlementWithoutAsset() {
        insert new ShGl_DisableFunctionalityLogic__c(setupOwnerId = UserInfo.getUserId(), Disable_Account_Old_Trigger__c = TRUE);
        insert new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getUserId(), 
              Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
              Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
              Disable_Opportunity_Triggers__c=true);
        TriggerControl.stopOrderItemTrigger = true;
        TriggerControl.stopOrderTrigger = true; 
       
        
        Id partner3 = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account customer3 = new Account(
            Name = 'Customer',
            recordtypeId = partner3,
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
        insert customer3;


        Opportunity opp3 = TestDataFactory.getOpportunity();
        opp3.Distributor_Lookup__c = customer3.Id;
        opp3.Partner_Lookup__c = customer3.Id;
        opp3.AccountId = customer3.Id;
        insert opp3;
        SBQQ__Quote__c quote3 = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp3.Id,
            SBQQ__SubscriptionTerm__c = 12,
            SBQQ__Primary__c = true,
            SBQQ__PriceBook__c = Test.getStandardPricebookId());
        insert quote3;
        
        Product2 product_3 = new Product2(Name = 'RBK-R6412-CONS',ProductCode = 'RBK-R6412-CONS',
                    Category__c = 'Platform',
                    Family = 'r300',
                    Product_Type__c = 'Appliance',
                    Appliance_Model__c='RBK-R344',
                    Appliance_Model_HW__c = 'RBK-R344',
                    CPQ_MSP_Base_Price__c = 0.13,
                    SBQQSC__EntitlementConversion__c = 'None',
                    SBQQ__AssetAmendmentBehavior__c = 'Default',
                    IsActive = true,
                    Asset_Priority__c = 0,
                    MSP_Segment_Product__c = true,
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 1,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable'
                );
         insert product_3;
        PricebookEntry pe3 = new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = product_3.Id, IsActive = true, UnitPrice = 100);
        insert pe3;
        SBQQ__QuoteLine__c quoteline3 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote3.Id, SBQQ__Product__c = product_3.Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200);
        insert quoteline3;
        
        Order orderInstance3 = new Order();
        orderInstance3.AccountId = customer3.Id;
        orderInstance3.OpportunityId = opp3.Id;
        orderInstance3.EffectiveDate = system.today();  
        orderInstance3.Status = 'Draft';
        orderInstance3.Type = 'Revenue';
        orderInstance3.Pricebook2Id = Test.getStandardPricebookId(); 
        insert orderInstance3;
        
        Asset asst3 = new Asset();
        asst3.Name = 'Test Asset';
        asst3.Product2Id = product_3.Id; 
        asst3.AccountId = customer3.Id;
        insert asst3;
        
        OrderItem orderItemAdd3 = new OrderItem();
        orderItemAdd3.OrderId = orderInstance3.Id;
        orderItemAdd3.Product2Id = product_3.Id;
        orderItemAdd3.UnitPrice = pe3.UnitPrice;
        orderItemAdd3.SBQQ__Segmentindex__c = 1; 
        orderItemAdd3.Support_Start_Date__c = System.today().addMonths(7);
        orderItemAdd3.Support_End_Date__c = System.today().addMonths(45);
        orderItemAdd3.Quantity = 20;
        orderItemAdd3.SBQQ__QuoteLine__c = quoteline3.Id;
        orderItemAdd3.PricebookEntryId = pe3.Id;
        insert orderItemAdd3;
        
        ServiceContract sc3 = new ServiceContract();
        sc3.Name = 'Test opp3 - 30 Sept - Contract';
        sc3.AccountId = customer3.Id;
        sc3.SBQQSC__Order__c = orderInstance3.Id;
        sc3.SBQQSC__Quote__c = quote3.Id;
        sc3.SBQQSC__Opportunity__c = opp3.Id;
        sc3.Pricebook2Id = Test.getStandardPricebookId();
        sc3.Term = 60;
        sc3.StartDate = System.Today();
        sc3.EndDate = System.today().addMonths(36);
        insert sc3;
        
        ContractLineItem contractLineItem2_3 = new ContractLineItem();
        contractLineItem2_3.ServiceContractID = sc3.Id;
        contractLineItem2_3.SBQQSC__QuoteLine__c = quoteline3.Id;
        contractLineItem2_3.SBQQSC__Account__c = customer3.Id;
        contractLineItem2_3.SBQQSC__Product__c = product_3.Id;       
        contractLineItem2_3.SBQQSC__OrderProduct__c = orderItemAdd3.id;
        contractLineItem2_3.MSP_Segment_Product__c = true;
        contractLineItem2_3.PricebookEntryId = pe3.Id;
        contractLineItem2_3.Quantity = 10;
        contractLineItem2_3.UnitPrice = pe3.UnitPrice;
        insert contractLineItem2_3;
        
        Test.startTest();
        CreateEntitlementAndUpdateAssetsBatch batchInstance = new CreateEntitlementAndUpdateAssetsBatch();
        Database.executeBatch(batchInstance);
        Test.stopTest();
    }
    
    @isTest
    private static void testEntitlementWithSubscribedAsset() {
        insert new ShGl_DisableFunctionalityLogic__c(setupOwnerId = UserInfo.getUserId(), Disable_Account_Old_Trigger__c = TRUE);
        insert new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getUserId(), 
              Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
              Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
              Disable_Opportunity_Triggers__c=true);
        TriggerControl.stopOrderItemTrigger = true;
        TriggerControl.stopOrderTrigger = true;


        Id partner4 = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account customer4 = new Account(
            Name = 'Customer',
            recordtypeId = partner4,
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
        insert customer4;

        
        Opportunity opp4 = TestDataFactory.getOpportunity();
        opp4.Distributor_Lookup__c = customer4.Id;
        opp4.Partner_Lookup__c = customer4.Id;
        opp4.AccountId = customer4.Id;
        insert opp4;
        SBQQ__Quote__c quote4 = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = opp4.Id,
            SBQQ__SubscriptionTerm__c = 12,
            SBQQ__Primary__c = true,
            SBQQ__PriceBook__c = Test.getStandardPricebookId());
        insert quote4;
        
        Product2 product4 = new Product2(Name = 'RBK-R6412-CONS',ProductCode = 'RBK-R6412-CONS',
                    Category__c = 'Platform',
                    Family = 'r300',
                    Product_Type__c = 'Appliance',
                    Appliance_Model__c='RBK-R344',
                    Appliance_Model_HW__c = 'RBK-R344',
                    CPQ_MSP_Base_Price__c = 0.13,
                    SBQQSC__EntitlementConversion__c = 'None',
                    SBQQ__AssetAmendmentBehavior__c = 'Default',
                    IsActive = true,
                    Asset_Priority__c = 0,
                    MSP_Segment_Product__c = true,
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 1,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable'
                );
         insert product4;
        
        Asset assestIns4 = new Asset();
        assestIns4.Name = '09092019APMSP1250';
        assestIns4.SerialNumber = '09092019APMSP1250';
        assestIns4.serial_number__c= '09092019APMSP1250';
        assestIns4.AccountId = customer4.Id;
        assestIns4.Product2Id = product4.Id;
        insert assestIns4;
        
        PricebookEntry pe4 = new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = product4.Id, IsActive = true, UnitPrice = 100);
        insert pe4;
        SBQQ__QuoteLine__c quoteline4 = new SBQQ__QuoteLine__c(SBQQ__SubscribedAssetIds__c=assestIns4.Id,SubscribedAssetNames__c=assestIns4.serial_number__c,SBQQ__Quote__c = quote4.Id, SBQQ__Product__c = product4.Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200);
        insert quoteline4;
        
        Order orderInstance4 = new Order();
        orderInstance4.AccountId = customer4.Id;
        orderInstance4.OpportunityId = opp4.Id;
        orderInstance4.EffectiveDate = system.today();  
        orderInstance4.Status = 'Draft';
        orderInstance4.Type = 'Revenue';
        orderInstance4.Initial_Order_Number__c = '25';
        orderInstance4.Order_Sub_Type__c = 'MSP Consumption Renewal';
        orderInstance4.Pricebook2Id = Test.getStandardPricebookId(); 
        insert orderInstance4;
        
        OrderItem orderItemAdd4 = new OrderItem();
        orderItemAdd4.OrderId = orderInstance4.Id;
        orderItemAdd4.Product2Id = product4.Id;
        orderItemAdd4.UnitPrice = pe4.UnitPrice;
        orderItemAdd4.SBQQ__Segmentindex__c = 1; 
        orderItemAdd4.Support_Start_Date__c = System.today().addMonths(8);
        orderItemAdd4.Support_End_Date__c = System.today().addMonths(42);
        orderItemAdd4.Quantity = 20;
        orderItemAdd4.SBQQ__QuoteLine__c = quoteline4.Id;
        orderItemAdd4.PricebookEntryId = pe4.Id;
        insert orderItemAdd4;
        
        ServiceContract sc4 = new ServiceContract();
        sc4.Name = 'Test opp4 - 30 Sept - Contract';
        sc4.AccountId = customer4.Id;
        sc4.SBQQSC__Order__c = orderInstance4.Id;
        sc4.SBQQSC__Quote__c = quote4.Id;
        sc4.SBQQSC__Opportunity__c = opp4.Id;
        sc4.Pricebook2Id = Test.getStandardPricebookId();
        sc4.Term = 36;
        sc4.StartDate = System.Today();
        sc4.EndDate = System.today().addMonths(36);
        insert sc4;
        
        ContractLineItem contractLineItem2_4 = new ContractLineItem();
        contractLineItem2_4.ServiceContractID = sc4.Id;
        contractLineItem2_4.SBQQSC__QuoteLine__c = quoteline4.Id;
        contractLineItem2_4.SBQQSC__Account__c = customer4.Id;
        contractLineItem2_4.SBQQSC__Product__c = product4.Id;       
        contractLineItem2_4.SBQQSC__OrderProduct__c = orderItemAdd4.id;
        contractLineItem2_4.MSP_Segment_Product__c = true;
        contractLineItem2_4.PricebookEntryId = pe4.Id;
        contractLineItem2_4.Quantity = 10;
        contractLineItem2_4.UnitPrice = pe4.UnitPrice;
        insert contractLineItem2_4;
        Test.startTest();
        CreateEntitlementAndUpdateAssetsBatch batchInstance = new CreateEntitlementAndUpdateAssetsBatch();
        Database.executeBatch(batchInstance);
        Test.stopTest();
    }



}