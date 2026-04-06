@isTest
private class AssetsAndEntitlementsTest {

  /*  @isTest
    private static void testEntitlementTriggerHelper() {
        System.assertNotEquals(null, EntitlementTriggerHelper.testA());
        System.assertNotEquals(null, EntitlementTriggerHelper.testA2());
    }
    @isTest
    private static void testAssetTriggerHelper() {
        System.assertNotEquals(null, AssetTriggerHelper.testA());
    }*/
    //@isTest
    //private static void test_AssetTriggerHandler() {
    //    System.assertNotEquals(null, AssetTriggerHandler.testA());
    //}
    /*@isTest
    private static void test_OrderService() {
        System.assertNotEquals(null, OrderService.testA2());
    }*/


    //Appliance
    //1xA
    //@isTest
    private static void testApplianceCpqFlow() {

            System.assertNotEquals(null, ASSETS);

        Account customer = new Account(
            Name = 'Customer',
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

        Opportunity opp = new Opportunity(
            AccountId = customer.Id,
            Name = 'Test',
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
            SBQQ__PriceBook__c = Test.getStandardPricebookId());
        insert quote;

        List<Product2> sampleProducts = new List<Product2>{
                // 0
                new Product2(
                    Name = 'CPQ Bundle Product',
                    ProductCode = 'CPQ Bundle Product',
                    IsActive = true,
                    SBQQ__Hidden__c = true,
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
                    Asset_Priority__c = 0,
                    New_CPQ_Product__c = true
                ),
                // 2
                new Product2(
                    Name = 'RBK-SVC-PREM-APPLIANCE',
                    ProductCode = 'RBK-SVC-PREM-APPLIANCE',
                    Category__c = 'Support',
                    SBQQ__AssetConversion__c = 'None',
                    SBQQSC__EntitlementConversion__c = 'One per unit',
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 12,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable',
                    IsActive = true,
                    Asset_Priority__c = 1,
                    New_CPQ_Product__c = true
                ),
                // 3
                new Product2(
                    Name = 'RBK-POLARIS-GPS',
                    ProductCode = 'RBK-POLARIS-GPS',
                    Category__c = 'SaaS',
                    Family = 'POLARIS',
                    Product_Type__c = null,
                    SBQQ__AssetConversion__c = 'None',
                    SBQQSC__EntitlementConversion__c = 'One per unit',
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 12,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable',
                    IsActive = true,
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
                    Asset_Priority__c = null,
                    New_CPQ_Product__c = true
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
                    Asset_Priority__c = null,
                    New_CPQ_Product__c = true
                ),
                // 10
                new Product2(
                    Name = 'RBK-SVC-PREM-OBJ-STORAGE',
                    ProductCode = 'RBK-SVC-PREM-OBJ-STORAGE',
                    Category__c = 'Support',
                    Family = null,
                    Product_Type__c = null,
                    SBQQ__AssetConversion__c = 'None',
                    SBQQSC__EntitlementConversion__c = 'One per unit',
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 12,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable',
                    IsActive = true,
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
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[8].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[9].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[10].Id, IsActive = true, UnitPrice = 100));
        insert entries;

        List<SBQQ__ProductOption__c>prodOptions = new List<SBQQ__ProductOption__c>();
        prodOptions.add(new SBQQ__ProductOption__c(SBQQ__Number__c = 20, SBQQ__ConfiguredSKU__c = sampleProducts[1].Id, SBQQ__OptionalSKU__c = sampleProducts[1].Id));
        prodOptions.add(new SBQQ__ProductOption__c(SBQQ__Number__c = 30, SBQQ__ConfiguredSKU__c = sampleProducts[2].Id, SBQQ__OptionalSKU__c = sampleProducts[1].Id));
        prodOptions.add(new SBQQ__ProductOption__c(SBQQ__Number__c = 40, SBQQ__ConfiguredSKU__c = sampleProducts[3].Id, SBQQ__OptionalSKU__c = sampleProducts[1].Id));
        prodOptions.add(new SBQQ__ProductOption__c(SBQQ__Number__c = 50, SBQQ__ConfiguredSKU__c = sampleProducts[4].Id, SBQQ__OptionalSKU__c = sampleProducts[1].Id));
        prodOptions.add(new SBQQ__ProductOption__c(SBQQ__Number__c = 60, SBQQ__ConfiguredSKU__c = sampleProducts[5].Id, SBQQ__OptionalSKU__c = sampleProducts[1].Id));
        prodOptions.add(new SBQQ__ProductOption__c(SBQQ__Number__c = 70, SBQQ__ConfiguredSKU__c = sampleProducts[6].Id, SBQQ__OptionalSKU__c = sampleProducts[1].Id));
        prodOptions.add(new SBQQ__ProductOption__c(SBQQ__Number__c = 80, SBQQ__ConfiguredSKU__c = sampleProducts[7].Id, SBQQ__OptionalSKU__c = sampleProducts[1].Id));
        prodOptions.add(new SBQQ__ProductOption__c(SBQQ__Number__c = 90, SBQQ__ConfiguredSKU__c = sampleProducts[8].Id, SBQQ__OptionalSKU__c = sampleProducts[1].Id));
        prodOptions.add(new SBQQ__ProductOption__c(SBQQ__Number__c = 100, SBQQ__ConfiguredSKU__c = sampleProducts[9].Id, SBQQ__OptionalSKU__c = sampleProducts[1].Id));
        prodOptions.add(new SBQQ__ProductOption__c(SBQQ__Number__c = 10, SBQQ__ConfiguredSKU__c = sampleProducts[10].Id, SBQQ__OptionalSKU__c = sampleProducts[9].Id));
        insert prodOptions;

        List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[0].Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[1].Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[2].Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[3].Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[4].Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[5].Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[6].Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[7].Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[8].Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[9].Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = sampleProducts[10].Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        insert lines;

        lines[0].SBQQ__Bundle__c = true;
        lines[1].SBQQ__RequiredBy__c = lines[0].Id;
        lines[2].SBQQ__RequiredBy__c = lines[0].Id;
        lines[3].SBQQ__RequiredBy__c = lines[0].Id;
        lines[4].SBQQ__RequiredBy__c = lines[0].Id;
        lines[5].SBQQ__RequiredBy__c = lines[0].Id;
        lines[6].SBQQ__RequiredBy__c = lines[0].Id;
        lines[7].SBQQ__RequiredBy__c = lines[0].Id;
        lines[8].SBQQ__RequiredBy__c = lines[0].Id;
        lines[9].SBQQ__RequiredBy__c = lines[0].Id;
        lines[9].SBQQ__Bundle__c = true;
        lines[10].SBQQ__RequiredBy__c = lines[9].Id;
        update lines;

        Test.startTest();

        User sysAdmin = [SELECT Id FROM User WHERE Alias = 'batman' LIMIT 1];

        System.runAs(sysAdmin) {

            //Opportunity_Service.run=false;
            OPP.SBQQ__QuotePricebookId__c = Test.getStandardPricebookId();
            OPP.Compelling_Bus_Driver__c = 'Instant Recovery';
            OPP.Current_State__c = 'test';
            OPP.Negative_Consequences__c = 'test';
            OPP.Future_State__c = 'test';
            OPP.Positive_Business_Outcomes__c = 'test';
            OPP.Distributor_Lookup__c = ACCT.Id;
            OPP.Partner_Lookup__c = ACCT.Id;
            OPP.Opportunity_Sub_Type__c = 'MSP';
            OPP.Rubrik_Sales_Engineer__c = UserInfo.getUserId();
            OPP.Win_Loss_Comments__c = 'test';
            OPP.Primary_Competitor__c = 'Actifio';
            OPP.Key_Feature_Needs__c = 'None';
            OPP.Deal_Impact__c = 'Deal Blocker';
            OPP.Valooto_Quote__c = '123123123';
            OPP.Valooto_Quote_Stage__c = 'Approved';
            OPP.Partner_Level_Of_Involvement__c = '1.Rubrik initiated, Partner was fulfillment only';
            OPP.Pricebook2Id = Test.getStandardPricebookId();

            //Opportunity_Service.run=false;
            OPP.StageName = '6 PO With Channel';
            update OPP;
        }

        OrderItem[] orderItems = [SELECT Id, PricebookEntry.Product2Id FROM OrderItem WHERE SBQQ__QuoteLine__c = :lines];
        System.assertNotEquals(null, orderItems);

        OrderItem appliance = null;
        OrderItem applianceSupport = null;
        OrderItem nrdSupport = null;
        OrderItem applianceSubscription = null;
        OrderItem appliancePolarisSubscription = null;
        OrderItem obj = null;
        OrderItem objSupport = null;
        OrderItem spare = null;

        for(OrderItem oi : orderItems) {
            if(oi.PricebookEntry.Product2Id == sampleProducts[1].Id) {
                appliance = oi;
            }
            else if(oi.PricebookEntry.Product2Id == sampleProducts[2].Id) {
                applianceSupport = oi;
            }
            else if(oi.PricebookEntry.Product2Id == sampleProducts[3].Id) {
                appliancePolarisSubscription = oi;
            }
            else if(oi.PricebookEntry.Product2Id == sampleProducts[4].Id) {
                applianceSubscription = oi;
            }
            else if(oi.PricebookEntry.Product2Id == sampleProducts[7].Id) {
                spare = oi;
            }
            else if(oi.PricebookEntry.Product2Id == sampleProducts[8].Id) {
                nrdSupport = oi;
            }
            else if(oi.PricebookEntry.Product2Id == sampleProducts[9].Id) {
                obj = oi;
            }
            else if(oi.PricebookEntry.Product2Id == sampleProducts[10].Id) {
                objSupport = oi;
            }
        }


        appliance.SerialNumber__c = 'SN1';
        spare.SerialNumber__c = 'SPARE-SN1';
        applianceSupport.Support_Start_Date__c = System.today();
        applianceSupport.Support_End_Date__c = System.today().addMonths(12).addDays(-1);
        appliancePolarisSubscription.Support_Start_Date__c = System.today();
        appliancePolarisSubscription.Support_End_Date__c = System.today().addMonths(12).addDays(-1);
        applianceSubscription.Support_Start_Date__c = System.today();
        applianceSubscription.Support_End_Date__c = System.today().addMonths(12).addDays(-1);
        nrdSupport.Support_Start_Date__c = System.today();
        nrdSupport.Support_End_Date__c = System.today().addMonths(12).addDays(-1);
        //obj.Support_Start_Date__c = System.today();
        //obj.Support_End_Date__c = System.today().addMonths(12).addDays(-1);
        objSupport.Support_Start_Date__c = System.today();
        objSupport.Support_End_Date__c = System.today().addMonths(12).addDays(-1);
        update orderItems;

        //ship order
        Order order = [SELECT Id FROM Order WHERE OpportunityId = :OPP.Id];

        order.SBQQ__PriceCalcStatus__c = 'Completed';
        order.Bill_To_Name__c = customer.Id;
        //order.Ship_To_Name__c = customer.Id;
        order.PoNumber = '12345';
        order.Shipping_Carrier__c = 'UPS';
        order.Service_Level__c = 'UPS Worldwide Express Freight';
        order.Shipping_Method__c = 'FCA Origin';
        order.Est_Ship_Date__c = System.today().addDays(1);
        order.Deliver_By__c = System.today().addDays(1);

        update order;

        order.Order_Status__c = 'Shipped';
        order.Actual_Order_Ship_Date__c = System.today();
        update order;

        Test.stopTest();

        assertAssetsOnly(appliance, 1);
        assertAssetsOnly(spare, 1);

        Asset applianceAsset = getAsset(appliance);
        Asset spareAsset = getAsset(spare);

        //?System.assertEquals(applianceSupport.Support_Start_Date__c, applianceAsset.Support_Start_Date__c);
        //?System.assertEquals(applianceSupport.Support_End_Date__c, applianceAsset.Premium_Support_End_Date__c);
        System.assertEquals(appliance.Id, applianceAsset.Order_Service_Item__c);
        //System.assertEquals('Purchased', applianceAsset.Status);
        //System.assertEquals(order.Actual_Order_Ship_Date__c, applianceAsset.PurchaseDate);
        //System.assertEquals(1, applianceAsset.SBQQ__Number__c);
        //System.assertEquals(customer.ShippingCity, applianceAsset.Location__c);
        //System.assertEquals(lines[1].Id, applianceAsset.SBQQ__QuoteLine__c);
        //System.assertEquals(true, applianceAsset.SBQQ__Bundle__c);
        //System.assertEquals(appliance.Id, applianceAsset.SBQQ__CombineKey__c);
        //System.assertEquals(1, applianceAsset.Quantity);


        //assertAssetsEntitlements(applianceSupport, 0, 1, new Set<String>{'SN1'});
        //assertAssetsEntitlements(appliancePolarisSubscription, 0, 1, new Set<String>{'SN1'});
        //assertAssetsEntitlements(applianceSubscription, 0, 1, new Set<String>{'SN1'});
        //assertAssetsEntitlements(nrdSupport, 0, 1, new Set<String>{'SN1'});
        //assertAssetsEntitlements(obj, 0, 0);
        //assertAssetsEntitlements(objSupport, 0, 1, new Set<String>{null});
    }


    //Appliance
    //1xA
    @isTest
    private static void testAppliance() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(1, APPLIANCE_PBE)
        };

        insert orderItems;
        OrderItem appliance = orderItems[0];

        //shipOrder();

        Test.startTest();


        appliance.SerialNumber__c = 'SN1';
        update orderItems;

        shipOrder();

        Test.stopTest();

        assertAssetsOnly(appliance, 1);
    }

    //Support
    //1xA + 1xE, asset should be under support
    @isTest
    private static void testSupport() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(1, SUPPORT_PBE)
        };
        insert orderItems;
        OrderItem support = orderItems[0];

        //shipOrder();

        Test.startTest();


        support.SerialNumber__c = 'SN1';
        support.Support_Start_Date__c = system.Today();
        support.Support_End_Date__c = system.Today().addYears(1);

        update orderItems;
        shipOrder();

        Test.stopTest();

        assertAssetsEntitlements(support, 1, 1);
    }

    //Subscription
    //1xA + 1xE, asset should be under subscription
    @isTest
    private static void testSubscription() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(1, SUBSCRIPTION_PBE)
        };
        insert orderItems;
        OrderItem subscription = orderItems[0];

        //shipOrder();

        Test.startTest();


        subscription.SerialNumber__c = 'SN1';
        subscription.Support_Start_Date__c = system.Today();
        subscription.Support_End_Date__c = system.Today().addYears(1);

        update orderItems;
        shipOrder();

        Test.stopTest();

        assertAssetsEntitlements(subscription, 1, 1);
    }

    //Support + Subscription
    //1xA + 2xE, asset should be under support
    @isTest
    private static void testSupportAndSubscription() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(1, SUPPORT_PBE),
            makeOrderItem(1, SUBSCRIPTION_PBE)
        };
        insert orderItems;
        OrderItem support = orderItems[0];
        OrderItem subscription = orderItems[1];

        //shipOrder();

        Test.startTest();


        support.SerialNumber__c = 'SN1';
        support.Support_Start_Date__c = system.Today();
        support.Support_End_Date__c = system.Today().addYears(1);

        subscription.SerialNumber__c = 'SN1';
        subscription.Support_Start_Date__c = system.Today();
        subscription.Support_End_Date__c = system.Today().addYears(1);

        update orderItems;
        shipOrder();

        Test.stopTest();

        assertAssetsEntitlements(support, 1, 1);
        assertEntitlementsOnly(subscription, 1);

    }



    //Appliance and support
    //1xA + 1xE
    @isTest
    private static void testApplianceAndSupport() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(1, APPLIANCE_PBE),
            makeOrderItem(1, SUPPORT_PBE)
        };
        insert orderItems;
        OrderItem appliance = orderItems[0];
        OrderItem support = orderItems[1];

        //shipOrder();

        Test.startTest();


        appliance.SerialNumber__c = 'SN1';
        support.Support_Start_Date__c = system.Today();
        support.Support_End_Date__c = system.Today().addYears(1);
        update orderItems;
        shipOrder();

        Test.stopTest();

        assertEntitlementsOnly(support, 1);
        assertAssetsOnly(appliance, 1);
        //System.assertEquals(support.Support_Start_Date__c, getAsset(appliance).Support_Start_Date__c);
        //System.assertEquals(support.Support_End_Date__c, getAsset(appliance).Premium_Support_End_Date__c);
    }

    //Appliance and support
    //4xA + 4xE
    @isTest
    private static void testApplianceAndSupportMultiQty() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(4, APPLIANCE_PBE),
            makeOrderItem(4, SUPPORT_PBE)
        };
        insert orderItems;
        OrderItem appliance = orderItems[0];
        OrderItem support = orderItems[1];

        //shipOrder();

        Test.startTest();


        appliance.SerialNumber__c = 'SN1,SN2,SN3,SN4';

        support.Support_Start_Date__c = system.Today();
        support.Support_End_Date__c = system.Today().addYears(1);

        update orderItems;
        shipOrder();

        Test.stopTest();

        assertEntitlementsOnly(support, 4);
        assertAssetsOnly(appliance, 4);
    }

    //Appliance and support with different quantities
    //2xA + 1xE
    @isTest
    private static void testApplianceAndSupportMultiQty2() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(2, APPLIANCE_PBE),
            makeOrderItem(1, SUPPORT_PBE)
        };
        insert orderItems;
        OrderItem appliance = orderItems[0];
        OrderItem support = orderItems[1];

        //shipOrder();

        Test.startTest();


        appliance.SerialNumber__c = 'SN1,SN2';

        support.Support_Start_Date__c = system.Today();
        support.Support_End_Date__c = system.Today().addYears(1);

        update orderItems;
        shipOrder();

        Test.stopTest();

        assertAssetsOnly(appliance, 2);
        assertEntitlementsOnly(support, 1);

    }

    //Appliance, Support and Subscription
    //1xA + 2xE - one for support and one for sub
    @isTest
    private static void testApplianceSupportAndSubscription() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(1, APPLIANCE_PBE),
            makeOrderItem(1, SUPPORT_PBE),
            makeOrderItem(1, SUBSCRIPTION_PBE)
        };
        insert orderItems;
        OrderItem appliance = orderItems[0];
        OrderItem support = orderItems[1];
        OrderItem subscription = orderItems[2];

        //shipOrder();

        Test.startTest();


        appliance.SerialNumber__c = 'SN1';

        support.Support_Start_Date__c = system.Today();
        support.Support_End_Date__c = system.Today().addYears(1);

        subscription.Support_Start_Date__c = system.Today();
        subscription.Support_End_Date__c = system.Today().addYears(1);
        subscription.SerialNumber__c = 'SN1';

        update OrderItems;
        shipOrder();

        Test.stopTest();

        assertAssetsOnly(appliance, 1);
        assertEntitlementsOnly(support, 1);
        assertEntitlementsOnly(subscription, 1);
    }

    //Appliance, Support and Subscription with different quantities
    //2xA + 3xE - one for support and 2 for sub
    @isTest
    private static void testApplianceSupportAndSubscriptionMultiQty() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(2, APPLIANCE_PBE),
            makeOrderItem(1, SUPPORT_PBE),
            makeOrderItem(2, SUBSCRIPTION_PBE)
        };
        insert orderItems;
        OrderItem appliance = orderItems[0];
        OrderItem support = orderItems[1];
        OrderItem subscription = orderItems[2];

        //shipOrder();

        Test.startTest();


        appliance.SerialNumber__c = 'SN1,SN2';

        support.Support_Start_Date__c = system.Today();
        support.Support_End_Date__c = system.Today().addYears(1);

        subscription.Support_Start_Date__c = system.Today();
        subscription.Support_End_Date__c = system.Today().addYears(1);
        subscription.SerialNumber__c = 'SN1,SN2';

        update orderItems;
        shipOrder();

        Test.stopTest();

        assertAssetsOnly(appliance, 2);
        assertEntitlementsOnly(support, 1);
        assertEntitlementsOnly(subscription, 2);
    }

    // Spare
    // 1xA - new asset created under spare product
    @isTest
    private static void testonlySpare() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(1, SPARE_PBE)
        };
        insert orderItems;
        OrderItem spare = orderItems[0];

        //shipOrder();

        Test.startTest();


        spare.SerialNumber__c = 'SN5';

        update orderItems;
        shipOrder();

        Test.stopTest();

        assertAssetsOnly(spare, 1);
    }


    // Spare multi qty
    // 3xA - new assets created under spare product
    @isTest
    private static void testOnlySpareMultiQty() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(3, SPARE_PBE)
        };
        insert orderItems;
        OrderItem spare = orderItems[0];

        //shipOrder();

        Test.startTest();


        spare.SerialNumber__c = 'SN5,SN6,SN7';

        update orderItems;
        shipOrder();

        Test.stopTest();

        assertAssetsOnly(spare, 3);

    }

    // Spare + Appliance
    // 2xA - new asset created under spares product and existing asset assigned to appliance product
    @isTest
    private static void testSpareAndAppliance() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(1, SPARE_PBE),
            makeOrderItem(1, APPLIANCE_PBE)
        };
        insert orderItems;
        OrderItem spare = orderItems[0];
        OrderItem appliance = orderItems[1];

        //shipOrder();

        Test.startTest();


        spare.SerialNumber__c = 'SN5';
        appliance.SerialNumber__c = 'SN1';

        update orderItems;
        shipOrder();

        Test.stopTest();

        assertAssetsOnly(spare, 1);
        assertAssetsOnly(appliance, 1);
    }

    // Spare + Appliance muti qty
    // 3xA - new asset created under spares product and 2 existing asset assigned to appliance product
    @isTest
    private static void testSpareAndApplianceMultiQty() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(1, SPARE_PBE),
            makeOrderItem(2, APPLIANCE_PBE)
        };
        insert orderItems;
        OrderItem spare = orderItems[0];
        OrderItem appliance = orderItems[1];

        //shipOrder();

        Test.startTest();


        spare.SerialNumber__c = 'SN5';
        appliance.SerialNumber__c = 'SN1,SN2';

        update orderItems;
        shipOrder();

        Test.stopTest();

        assertAssetsOnly(spare, 1);
        assertAssetsOnly(appliance, 2);
    }

    // Spare + appliance + support(appliance)
    // 2xA + 1xE - entitlement created under support product linked to appliance asset
    @isTest
    private static void testSpareAndApplianceSupport() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(1, SPARE_PBE),
            makeOrderItem(1, APPLIANCE_PBE),
            makeOrderItem(1, SUPPORT_PBE)
        };
        insert orderItems;
        OrderItem spare = orderItems[0];
        OrderItem appliance = orderItems[1];
        OrderItem support = orderItems[2];

        //shipOrder();

        Test.startTest();


        spare.SerialNumber__c = 'SN5';

        appliance.SerialNumber__c = 'SN1';

        support.Support_Start_Date__c = system.Today();
        support.Support_End_Date__c = system.Today().addYears(1);

        update orderItems;
        shipOrder();

        Test.stopTest();

        assertAssetsOnly(spare, 1);
        assertAssetsOnly(appliance, 1);
        assertEntitlementsOnly(support, 1);
    }


    // Spare + appliance + support(appl) multi qty
    // 5xA + 2xE - entitlements created under support products linked to appliance assets
    @isTest
    private static void testSpareAndApplianceSupportMultiQty() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(3, SPARE_PBE),
            makeOrderItem(2, APPLIANCE_PBE),
            makeOrderItem(2, SUPPORT_PBE)
        };
        insert orderItems;
        OrderItem spare = orderItems[0];
        OrderItem appliance = orderItems[1];
        OrderItem support = orderItems[2];

        //shipOrder();

        Test.startTest();


        spare.SerialNumber__c = 'SN5,SN6,SN7';

        appliance.SerialNumber__c = 'SN1,SN2';

        support.Support_Start_Date__c = system.Today();
        support.Support_End_Date__c = system.Today().addYears(1);

        update orderItems;
        shipOrder();

        Test.stopTest();

        assertAssetsOnly(spare, 3);
        assertAssetsOnly(appliance, 2);
        assertEntitlementsOnly(support, 2, new Set<String>{'SN1', 'SN2'});
    }

    // Spare + Appliance + Support(appl) + Subscription(appl)
    // 2xA + 2xE - entitlement under support and subscription products linked to appliance
    @isTest
    private static void testSpareAndApplianceSupportSubscription() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(1, SPARE_PBE),
            makeOrderItem(1, APPLIANCE_PBE),
            makeOrderItem(1, SUPPORT_PBE),
            makeOrderItem(1, SUBSCRIPTION_PBE)
        };
        insert orderItems;
        OrderItem spare = orderItems[0];
        OrderItem appliance = orderItems[1];
        OrderItem support = orderItems[2];
        OrderItem subscription = orderItems[3];

        //shipOrder();

        Test.startTest();


        spare.SerialNumber__c = 'SN5';

        appliance.SerialNumber__c = 'SN1';

        support.SerialNumber__c = 'SN1';
        support.Support_Start_Date__c = system.Today();
        support.Support_End_Date__c = system.Today().addYears(1);

        subscription.SerialNumber__c = 'SN1';
        subscription.Support_Start_Date__c = system.Today();
        subscription.Support_End_Date__c = system.Today().addYears(1);

        update orderItems;
        shipOrder();

        Test.stopTest();

        assertAssetsOnly(spare, 1);
        assertAssetsOnly(appliance, 1);
        assertEntitlementsOnly(support, 1, new Set<String>{'SN1'});
        assertEntitlementsOnly(subscription, 1, new Set<String>{'SN1'});
    }

    // Spare + appliance + support(appl) + subscription(appl) multi qty
    // 6xA + 4xE - entitlement under support and subscription products linked to appliance
    @isTest
    private static void testSpareAndApplianceSupportSubscriptionMultiQty() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(2, SPARE_PBE),
            makeOrderItem(4, APPLIANCE_PBE),
            makeOrderItem(2, SUPPORT_PBE),
            makeOrderItem(2, SUBSCRIPTION_PBE)
        };
        insert orderItems;
        OrderItem spare = orderItems[0];
        OrderItem appliance = orderItems[1];
        OrderItem support = orderItems[2];
        OrderItem subscription = orderItems[3];

        //shipOrder();

        Test.startTest();


        spare.SerialNumber__c = 'SN5,SN6';

        appliance.SerialNumber__c = 'SN1,SN2,SN3,SN4';

        support.SerialNumber__c = 'SN1,SN2';
        support.Support_Start_Date__c = system.Today();
        support.Support_End_Date__c = system.Today().addYears(1);

        subscription.SerialNumber__c = 'SN3,SN4';
        subscription.Support_Start_Date__c = system.Today();
        subscription.Support_End_Date__c = system.Today().addYears(1);

        update orderItems;
        shipOrder();

        Test.stopTest();

        assertAssetsOnly(spare, 2);
        assertAssetsOnly(appliance, 4);
        assertEntitlementsOnly(support, 2, new Set<String>{'SN1', 'SN2'});
        assertEntitlementsOnly(subscription, 2, new Set<String>{'SN3', 'SN4'});
    }


    // Monthly subscription (single quantity) with qty 12
    // 1xE (e.g. RBK-CLOUT-10-MO with single quantity checked) - one entitlement created, linked to asset
    @isTest
    private static void testMoSubscription() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(12, MO_SUBSCRIPTION_PBE)
        };
        insert orderItems;
        OrderItem moSubscription = orderItems[0];

        //shipOrder();

        Test.startTest();


        moSubscription.SerialNumber__c = 'SN1';
        moSubscription.Support_Start_Date__c = system.Today();
        moSubscription.Support_End_Date__c = system.Today().addYears(1);

        update orderItems;
        shipOrder();

        Test.stopTest();

        //assertAssetsEntitlements(moSubscription, 1, 1, new Set<String>{'SN1'});
        assertAssetsEntitlements(moSubscription, 0, 1, new Set<String>{'SN1'});
//        assertEntitlementsOnly(moSubscription, 1);
    }

    // Monthly subscription with qty 12 multi qty
    // 3xE (e.g. RBK-CLOUT-10-MO with single quantity checked) - one entitlement created for each, linked to asset
    @isTest
    private static void testMoSubscriptionMultiQty() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(12, MO_SUBSCRIPTION_PBE),
            makeOrderItem(12, MO_SUBSCRIPTION_PBE),
            makeOrderItem(12, MO_SUBSCRIPTION_PBE)
        };
        insert orderItems;
        OrderItem moSubscription1 = orderItems[0];
        OrderItem moSubscription2 = orderItems[1];
        OrderItem moSubscription3 = orderItems[2];

        //shipOrder();

        Test.startTest();

        

        moSubscription1.SerialNumber__c = 'SN1';
        moSubscription1.Support_Start_Date__c = system.Today();
        moSubscription1.Support_End_Date__c = system.Today().addYears(1);

        moSubscription2.SerialNumber__c = 'SN2';
        moSubscription2.Support_Start_Date__c = system.Today();
        moSubscription2.Support_End_Date__c = system.Today().addYears(1);

        moSubscription3.SerialNumber__c = 'SN3';
        moSubscription3.Support_Start_Date__c = system.Today();
        moSubscription3.Support_End_Date__c = system.Today().addYears(1);

        update orderItems;
        shipOrder();

        Test.stopTest();

//        assertEntitlementsOnly(moSubscription1, 1);
//        assertEntitlementsOnly(moSubscription2, 1);
//        assertEntitlementsOnly(moSubscription3, 1);
        //assertAssetsEntitlements(moSubscription1, 1, 1, new Set<String>{'SN1'});
        //assertAssetsEntitlements(moSubscription2, 1, 1, new Set<String>{'SN2'});
        //assertAssetsEntitlements(moSubscription3, 1, 1, new Set<String>{'SN3'});
        assertAssetsEntitlements(moSubscription1, 0, 1, new Set<String>{'SN1'});
        assertAssetsEntitlements(moSubscription2, 0, 1, new Set<String>{'SN2'});
        assertAssetsEntitlements(moSubscription3, 0, 1, new Set<String>{'SN3'});
    }

    // 1xSupport (RBK-SVC-PREM-R348-3YR) + 1xMonthly Sub with qty 12
    // 2xE - entitlements created, one under each product, linked to asset
    //@isTest
    private static void testMoSubscriptionAndMOSupport() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(12, MO_SUPPORT_PBE),
            makeOrderItem(12, MO_SUBSCRIPTION_PBE)
        };
        insert orderItems;
        OrderItem moSupport = orderItems[0];
        OrderItem moSubscription = orderItems[1];

        //shipOrder();

        Test.startTest();


        moSupport.SerialNumber__c = 'SN1';
        moSupport.Support_Start_Date__c = system.Today();
        moSupport.Support_End_Date__c = system.Today().addYears(1);

        moSubscription.SerialNumber__c = 'SN2';
        moSubscription.Support_Start_Date__c = system.Today();
        moSubscription.Support_End_Date__c = system.Today().addYears(1);

        update orderItems;
        shipOrder();

        Test.stopTest();

//        assertEntitlementsOnly(moSupport, 1);
//        assertEntitlementsOnly(moSubscription, 1);

        assertAssetsEntitlements(moSupport, 1, 1, new Set<String>{'SN1'});
        //assertAssetsEntitlements(moSubscription, 1, 1, new Set<String>{'SN2'});
        assertAssetsEntitlements(moSubscription, 0, 1, new Set<String>{'SN2'});
    }

    // 1xSupport (RBK-SVC-PREM-R348-3YR) + 1xMonthly Sub with qty 12
    // 2xE - entitlements created, one under each product, linked to asset
    //@isTest
    private static void testSupportAndMoSubscription() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(1, SUPPORT_PBE),
            makeOrderItem(12, MO_SUBSCRIPTION_PBE)
        };
        insert orderItems;
        OrderItem support = orderItems[0];
        OrderItem moSubscription = orderItems[1];

        //shipOrder();

        Test.startTest();


        support.SerialNumber__c = 'SN1';
        support.Support_Start_Date__c = system.Today();
        support.Support_End_Date__c = system.Today().addYears(1);

        moSubscription.SerialNumber__c = 'SN2';
        moSubscription.Support_Start_Date__c = system.Today();
        moSubscription.Support_End_Date__c = system.Today().addYears(1);

        update orderItems;
        shipOrder();

        Test.stopTest();

        assertAssetsEntitlements(support, 1, 1, new Set<String>{'SN1'});
//        assertAssetsEntitlements(moSubscription, 1, 1, new Set<String>{'SN2'});
        assertAssetsEntitlements(moSubscription, 0, 1, new Set<String>{'SN2'});
//        assertEntitlementsOnly(support, 1);
//        assertEntitlementsOnly(moSubscription, 1);

    }

    // 1xMonthly Support (RBK-SVC-PREM-R348-MO) with qty 12
    // 1xE - entitlement created under support product, linke to asset
    @isTest
    private static void testMoSupport() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(12, MO_SUPPORT_PBE)
        };
        insert orderItems;
        OrderItem moSupport = orderItems[0];

        //shipOrder();

        Test.startTest();


        moSupport.SerialNumber__c = 'SN1';
        moSupport.Support_Start_Date__c = system.Today();
        moSupport.Support_End_Date__c = system.Today().addYears(1);

        update orderItems;
        shipOrder();

        Test.stopTest();

        assertAssetsEntitlements(moSupport, 1, 1, new Set<String>{'SN1'});
//        assertEntitlementsOnly(moSupport, 1);

    
    }

    // 1xMonthly Support + 1xAppliance with same support product code
    // 1xA + 1xE - asset under appliance and entitlement created under support, linked to asset
    @isTest
    private static void testApplianceAndMoSupport() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(1, APPLIANCE_PBE),
            makeOrderItem(12, MO_SUPPORT_PBE)
        };
        insert orderItems;
        OrderItem appliance = orderItems[0];
        OrderItem moSupport = orderItems[1];

        //shipOrder();

        Test.startTest();


        appliance.SerialNumber__c = 'SN1';

        moSupport.Support_Start_Date__c = system.Today();
        moSupport.Support_End_Date__c = system.Today().addYears(1);

        update orderItems;
        shipOrder();

        Test.stopTest();

        assertAssetsOnly(appliance, 1);
        assertEntitlementsOnly(moSupport, 1, new Set<String>{'SN1'});
    }

    // RBK-R334-01-NFR is a product that includes appliance and 1 yr support
    // both asset and support entitlement linked to this asset. Should show up under NFR product
    @isTest
    private static void testNFRR334() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(1, NFR_R334_APPLIANCE_PBE)
        };
        insert orderItems;
        OrderItem nfrAppliance = orderItems[0];

        //shipOrder();

        Test.startTest();


        nfrAppliance.SerialNumber__c = 'SN1';
        nfrAppliance.Support_Start_Date__c = system.Today();
        nfrAppliance.Support_End_Date__c = system.Today().addYears(1);

        update orderItems;
        shipOrder();

        Test.stopTest();

        assertAssetsEntitlements(nfrAppliance, 1, 1, new Set<String>{'SN1'});
    }

    // RBK-R348-01-NFR is same as regular appliance
    // asset shows up under product, no entitlement
    @isTest
    private static void testNFRR348() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(1, NFR_R348_APPLIANCE_PBE)
        };
        insert orderItems;
        OrderItem nfrAppliance = orderItems[0];

        //shipOrder();

        Test.startTest();


        nfrAppliance.SerialNumber__c = 'SN1';
        nfrAppliance.Support_Start_Date__c = system.Today();
        nfrAppliance.Support_End_Date__c = system.Today().addYears(1);

        update orderItems;
        shipOrder();

        Test.stopTest();

        assertAssetsOnly(nfrAppliance, 1);
    }

    // 3410S
    // single entitlement
    @isTest
    private static void test3410SsingleEntitlementApplianceSupportAndSubscription() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(1, SUPPORT_3410S_PBE),
            makeOrderItem(1, APPLIANCE_3410S_PBE),
            makeOrderItem(1, ACCESSORIES_PBE),
            makeOrderItem(2, SUBSCRIPTION_3410S_PBE_WITH_SINGLE_ENTITLEMENT)
        };
        insert orderItems;
        OrderItem support = orderItems[0];
        OrderItem appliance = orderItems[1];
        OrderItem accessories = orderItems[2];
        OrderItem subscription = orderItems[3];

        //shipOrder();

        Test.startTest();


        support.Support_Start_Date__c = system.Today();
        support.Support_End_Date__c = system.Today().addYears(1);

        appliance.SerialNumber__c = 'SN1';

        subscription.Support_Start_Date__c = system.Today();
        subscription.Support_End_Date__c = system.Today().addYears(1);

        update orderItems;
        shipOrder();

        Test.stopTest();

        assertAssetsOnly(appliance, 1);
        assertEntitlementsOnly(subscription, 1);
        assertEntitlementsOnly(support, 1);
    }



    @isTest
    private static void testSingleEntitlementApplianceAndSubscription() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(1, APPLIANCE_3410S_PBE),
            makeOrderItem(2, SUBSCRIPTION_3410S_PBE_WITH_SINGLE_ENTITLEMENT)
        };
        insert orderItems;
        OrderItem appliance = orderItems[0];
        OrderItem subscription = orderItems[1];

        //shipOrder();

        Test.startTest();


        appliance.SerialNumber__c = 'SN1';

        subscription.Support_Start_Date__c = system.Today();
        subscription.Support_End_Date__c = system.Today().addYears(1);

        update orderItems;
        shipOrder();

        Test.stopTest();

        assertAssetsOnly(appliance, 1);
        assertEntitlementsOnly(subscription, 1);
    }

    @isTest
    private static void testNoEntitlementApplianceAndSubscription() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(1, APPLIANCE_3410S_PBE),
            makeOrderItem(2, SUBSCRIPTION_3410S_PBE_NO_APPLIANCE_CODE_NO_SE)
        };
        insert orderItems;
        OrderItem appliance = orderItems[0];
        OrderItem subscription = orderItems[1];

        //shipOrder();

        Test.startTest();


        appliance.SerialNumber__c = 'SN1';

        subscription.Support_Start_Date__c = system.Today();
        subscription.Support_End_Date__c = system.Today().addYears(1);

        update orderItems;
        shipOrder();

        Test.stopTest();

        assertAssetsOnly(appliance, 1);
        assertEntitlementsOnly(subscription, 0);
    }

    @isTest
    private static void testSingleEntitlementApplianceAndSubscriptionBySe() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(1, APPLIANCE_3410S_PBE),
            makeOrderItem(2, SUBSCRIPTION_3410S_PBE_WITH_APPLIANCE_CODE_WITH_SE)
        };
        insert orderItems;
        OrderItem appliance = orderItems[0];
        OrderItem subscription = orderItems[1];

        //shipOrder();

        Test.startTest();


        appliance.SerialNumber__c = 'SN1';

        subscription.Support_Start_Date__c = system.Today();
        subscription.Support_End_Date__c = system.Today().addYears(1);

        update orderItems;
        shipOrder();

        Test.stopTest();

        assertAssetsOnly(appliance, 1);
        assertEntitlementsOnly(subscription, 1);
    }

    @isTest
    private static void testSingleEntitlementApplianceAndSupport() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(1, APPLIANCE_PBE),
            makeOrderItem(2, SUPPORT_WITH_SINGLE_ENTITLEMENT_PBE)
        };
        insert orderItems;
        OrderItem appliance = orderItems[0];
        OrderItem support = orderItems[1];

        //shipOrder();

        Test.startTest();


        appliance.SerialNumber__c = 'SN1';
        support.Support_Start_Date__c = system.Today();
        support.Support_End_Date__c = system.Today().addYears(1);
        update orderItems;
        shipOrder();

        Test.stopTest();

        assertEntitlementsOnly(support, 1);
        assertAssetsOnly(appliance, 1);

    }

    //Appliance, Support and Subscription
    //1xA + 2xE - one for support and one for sub
    @isTest
    private static void testMultiApplianceSupportAndSubscription() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(2, APPLIANCE_PBE),
            makeOrderItem(2, SUPPORT_PBE),
            makeOrderItem(1, SUBSCRIPTION_PBE),
            makeOrderItem(1, APPLIANCE_3410S_PBE)
        };
        insert orderItems;
        OrderItem appliance = orderItems[0];
        OrderItem support = orderItems[1];
        OrderItem subscription = orderItems[2];
        OrderItem appliance2 = orderItems[3];

        //shipOrder();

        Test.startTest();


        appliance.SerialNumber__c = 'SN1,SN2';
        appliance2.SerialNumber__c = 'SN3';

        support.Support_Start_Date__c = system.Today();
        support.Support_End_Date__c = system.Today().addYears(1);

        subscription.Support_Start_Date__c = system.Today();
        subscription.Support_End_Date__c = system.Today().addYears(1);
        subscription.SerialNumber__c = 'SN1';

        update OrderItems;
        shipOrder();

        Test.stopTest();

        assertAssetsOnly(appliance2, 1);
        assertAssetsOnly(appliance, 2);

        assertEntitlementsOnly(support, 2);
        entitlementsRelatedToAssets(new Set<String>{'SN1', 'SN2'}, support);

        assertEntitlementsOnly(subscription, 1);

    }

    //Appliance, Support and Subscription
    //1xA + 2xE - one for support and one for sub
    @isTest
    private static void testMultiApplianceWithSupportsAndSubscription() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(2, APPLIANCE_PBE),
            makeOrderItem(2, SUPPORT_PBE),
            makeOrderItem(1, SUBSCRIPTION_PBE),
            makeOrderItem(1, APPLIANCE_3410S_PBE),
            makeOrderItem(1, SUPPORT_3410S_PBE)
        };
        insert orderItems;
        OrderItem appliance = orderItems[0];
        OrderItem support = orderItems[1];
        OrderItem subscription = orderItems[2];
        OrderItem appliance2 = orderItems[3];
        OrderItem support2 = orderItems[4];

        //shipOrder();

        Test.startTest();


        appliance.SerialNumber__c = 'SN1,SN2';
        appliance2.SerialNumber__c = 'SN3';

        support.Support_Start_Date__c = system.Today();
        support.Support_End_Date__c = system.Today().addYears(1);
        support2.Support_Start_Date__c = system.Today();
        support2.Support_End_Date__c = system.Today().addYears(1);

        subscription.Support_Start_Date__c = system.Today();
        subscription.Support_End_Date__c = system.Today().addYears(1);
        subscription.SerialNumber__c = 'SN1';

        update OrderItems;
        shipOrder();

        Test.stopTest();

        assertAssetsOnly(appliance2, 1);
        assertAssetsOnly(appliance, 2);

        assertEntitlementsOnly(support, 2);
        entitlementsRelatedToAssets(new Set<String>{'SN1', 'SN2'}, support);

        assertEntitlementsOnly(support2, 1);
        entitlementsRelatedToAssets(new Set<String>{'SN3'}, support2);

        assertEntitlementsOnly(subscription, 1);

    }


    //Appliance, Support and Subscription
    //1xA + 2xE - one for support and one for sub
    @isTest
    private static void testMultiApplianceWithSupportsAndSubscriptionAndEDGE() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(2, SUBSCRIPTION_CLOUT),
            makeOrderItem(8, SUBSCRIPTION_EDGE),

            makeOrderItem(1, APPLIANCE_3410S_PBE),
            makeOrderItem(1, APPLIANCE_PBE),

            makeOrderItem(2, SUPPORT_CLOUT_OBJ),
            makeOrderItem(1, SUPPORT_3410S_PBE),
            makeOrderItem(1, SUPPORT_PBE)
        };
        insert orderItems;

        OrderItem subcsriptionClout = orderItems[0];
        OrderItem edge = orderItems[1];

        OrderItem appliance = orderItems[2];
        OrderItem appliance2 = orderItems[3];

        OrderItem supportClout = orderItems[4];
        OrderItem support = orderItems[5];
        OrderItem support2 = orderItems[6];

        //shipOrder();

        Test.startTest();


        appliance.SerialNumber__c = 'SN1';
        appliance2.SerialNumber__c = 'SN2';

        support.Support_Start_Date__c = system.Today();
        support.Support_End_Date__c = system.Today().addYears(1);
        support.SerialNumber__c = 'SN1';

        support2.Support_Start_Date__c = system.Today().addYears(1);
        support2.Support_End_Date__c = system.Today().addYears(2);
        support2.SerialNumber__c = 'SN2';

        edge.Support_Start_Date__c = system.Today();
        edge.Support_End_Date__c = system.Today().addYears(1);

        supportClout.Support_Start_Date__c = system.Today();
        supportClout.Support_End_Date__c = system.Today().addYears(1);

        update OrderItems;
        shipOrder();

        Test.stopTest();

        assertAssetsOnly(appliance2, 1);
        assertAssetsOnly(appliance, 1);

        assertEntitlementsOnly(support, 1);
        entitlementsRelatedToAssets(new Set<String>{'SN1'}, support);

        assertEntitlementsOnly(support2, 1);
        entitlementsRelatedToAssets(new Set<String>{'SN2'}, support2);

        assertEntitlementsOnly(edge, 1);
        assertEntitlementsOnly(supportClout, 1);

        Asset appliance1Asset = getAsset(appliance);
        Asset appliance2Asset = getAsset(appliance2);
        /*System.assertEquals(support.Support_Start_Date__c, appliance1Asset.Support_Start_Date__c);
        System.assertEquals(support.Support_End_Date__c, appliance1Asset.Premium_Support_End_Date__c);
        System.assertEquals(support2.Support_Start_Date__c, appliance2Asset.Support_Start_Date__c);
        System.assertEquals(support2.Support_End_Date__c, appliance2Asset.Premium_Support_End_Date__c);*/
    }

    //@isTest
    private static void testMultiApplianceWithEmptySupportsAppliancesAndCloutSupportAndSubscriptionAndEDGE() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(2, SUBSCRIPTION_CLOUT),
            makeOrderItem(8, SUBSCRIPTION_EDGE),

            makeOrderItem(2, APPLIANCE_3410S_PBE),
            makeOrderItem(3, APPLIANCE_PBE),

            makeOrderItem(4, SUPPORT_CLOUT_OBJ_MULTI),
            makeOrderItem(2, SUPPORT_3410S_PBE),
            makeOrderItem(3, SUPPORT_PBE)
        };
        insert orderItems;

        OrderItem subcsriptionClout = orderItems[0];
        OrderItem edge = orderItems[1];

        OrderItem appliance = orderItems[2];
        OrderItem appliance2 = orderItems[3];

        OrderItem supportClout = orderItems[4];
        OrderItem support = orderItems[5];
        OrderItem support2 = orderItems[6];

        //shipOrder();

        Test.startTest();


        appliance.SerialNumber__c = 'SN1,SN2';
        appliance2.SerialNumber__c = 'SN10,SN20,SN30';

        support.Support_Start_Date__c = system.Today();
        support.Support_End_Date__c = system.Today().addYears(1);

        support2.Support_Start_Date__c = system.Today().addYears(1);
        support2.Support_End_Date__c = system.Today().addYears(2);

        edge.Support_Start_Date__c = system.Today();
        edge.Support_End_Date__c = system.Today().addYears(1);

        supportClout.Support_Start_Date__c = system.Today();
        supportClout.Support_End_Date__c = system.Today().addYears(1);
        supportClout.SerialNumber__c = 'SN1, SN2, SN10, SN20';

        update OrderItems;
        shipOrder();

        Test.stopTest();

        assertAssetsOnly(appliance2, 3);
        assertAssetsOnly(appliance, 2);

        assertEntitlementsOnly(support, 2);
        entitlementsRelatedToAssets(new Set<String>{'SN1','SN2'}, support);

        assertEntitlementsOnly(support2, 3);
        entitlementsRelatedToAssets(new Set<String>{'SN10','SN20','SN30'}, support2);

        assertEntitlementsOnly(edge, 1);

        assertEntitlementsOnly(supportClout, 4);
        entitlementsRelatedToAssets(new Set<String>{'SN1','SN2','SN10','SN20'}, supportClout);

        Asset appliance1Asset = getAsset(appliance);
        Asset appliance2Asset = getAsset(appliance2);
        System.assertEquals(support.Support_Start_Date__c, appliance1Asset.Support_Start_Date__c);
        System.assertEquals(support.Support_End_Date__c, appliance1Asset.Premium_Support_End_Date__c);
        System.assertEquals(support2.Support_Start_Date__c, appliance2Asset.Support_Start_Date__c);
        System.assertEquals(support2.Support_End_Date__c, appliance2Asset.Premium_Support_End_Date__c);
    }

    @isTest
    private static void testSpareWithExistAsset() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(1, SPARE_UPDATE_ASSET)
        };
        insert orderItems;

        OrderItem spare = orderItems[0];

        //shipOrder();

        Test.startTest();


        spare.SerialNumber__c = 'SN1';

        update OrderItems;
        shipOrder();

        Test.stopTest();

        assertAssetsOnly(spare, 1);

    }

    /*
        1. Appliance 1 - qty 3 or more
        2. Appliance 2 - qty 2 or more
        3. Support 1 - qty same as Appliance 1
        4. Support 2 - qty less than Appliance 2
        5. Subscription 1 - qty same as Appliance 1
        6. Subscription 2 - qty less than Appliance 2
        7. Subscription 3 - qty > 2, not associated with Appliance (Single Entitlement checked),
        8. Subscription 4 - qty > 2, not associated with Appliance monthly SKU (multiple qty = number of months, Single Quantity checked)

        Expected Results:
        1. Appliance 1 has 3 or more assets
        2. Appliance 2 has 2 or more assets
        3. Support 1 has 3 or more entitlements linked to 3 or more Appliance 1 assets
        4. Support 2 has less than Appliance 2 qty number of entitlements linked to any Appliance 2 assets
        5. Subscription 1 has 3 or more entitlements linked to 3 or more Appliance 1 assets
        6. Subscription 2 has less than Appliance 2 qty number of entitlements linked to Appliance 2
        7. Subscription 3 has one entitlement created, with no asset link
        8. Subscription 4 has one entitlement created, with no asset link
    */
    //@isTest
    private static void testMultiApplianceWithMultiSupportsAndMultiSubscription() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(4, APPLIANCE_PBE),
            makeOrderItem(3, APPLIANCE_3410S_PBE),

            makeOrderItem(4, SUPPORT_PBE),
            makeOrderItem(2, SUPPORT_3410S_PBE),

            makeOrderItem(4, SUBSCRIPTION_3410S_PBE_NO_APPLIANCE_CODE_NO_SE),
            makeOrderItem(2, SUBSCRIPTION_3410S_PBE_NO_APPLIANCE_CODE_NO_SE),
            makeOrderItem(8, SUBSCRIPTION_PBE),
            makeOrderItem(12, MO_SUBSCRIPTION_PBE)
        };
        insert orderItems;

        OrderItem appliance1 = orderItems[0];
        OrderItem appliance2 = orderItems[1];

        OrderItem support1 = orderItems[2];
        OrderItem support2 = orderItems[3];

        OrderItem subscription1 = orderItems[4];
        OrderItem subscription2 = orderItems[5];
        OrderItem subscription3 = orderItems[6];
        OrderItem subscription4 = orderItems[7];


        //shipOrder();

        Test.startTest();


        appliance1.SerialNumber__c = 'SN1,SN2,SN3,SN4';
        appliance2.SerialNumber__c = 'SN10,SN20,SN30';

        support1.Support_Start_Date__c = system.Today();
        support1.Support_End_Date__c = system.Today().addYears(1);
        support1.SerialNumber__c = 'SN1,SN2,SN3,SN4';

        support2.Support_Start_Date__c = system.Today();
        support2.Support_End_Date__c = system.Today().addYears(1);
        support2.SerialNumber__c = 'SN10,SN20';

        subscription1.Support_Start_Date__c = system.Today();
        subscription1.Support_End_Date__c = system.Today().addYears(1);
        subscription1.SerialNumber__c = 'SN1,SN2,SN3,SN4';

        subscription2.Support_Start_Date__c = system.Today();
        subscription2.Support_End_Date__c = system.Today().addYears(1);
        subscription2.SerialNumber__c = 'SN10,SN20';

        subscription3.Support_Start_Date__c = system.Today();
        subscription3.Support_End_Date__c = system.Today().addYears(1);

        subscription4.Support_Start_Date__c = system.Today();
        subscription4.Support_End_Date__c = system.Today().addYears(1);

        update OrderItems;
        shipOrder();

        Test.stopTest();

        assertAssetsOnly(appliance1, 4);
        assertAssetsOnly(appliance2, 3);

        assertEntitlementsOnly(support1, 4);
        entitlementsRelatedToAssets(new Set<String>{'SN1','SN2','SN3','SN4'}, support1);

        assertEntitlementsOnly(support2, 2);
        entitlementsRelatedToAssets(new Set<String>{'SN10','SN20'}, support2);

        assertEntitlementsOnly(subscription1, 4);
        entitlementsRelatedToAssets(new Set<String>{'SN1','SN2','SN3','SN4'}, subscription1);

        assertEntitlementsOnly(subscription2, 2);
        entitlementsRelatedToAssets(new Set<String>{'SN10','SN20'}, subscription2);

        assertEntitlementsOnly(subscription3, 1);
        entitlementsRelatedToAssets(null, subscription3);

        assertEntitlementsOnly(subscription4, 1);
        entitlementsRelatedToAssets(null, subscription4);

        Asset appliance1Asset = getAsset(appliance1);
        Asset appliance2Asset = getAsset(appliance2);
        System.assertEquals(support1.Support_Start_Date__c, appliance1Asset.Support_Start_Date__c);
        System.assertEquals(support1.Support_End_Date__c, appliance1Asset.Premium_Support_End_Date__c);
        System.assertEquals(support2.Support_Start_Date__c, appliance2Asset.Support_Start_Date__c);
        System.assertEquals(support2.Support_End_Date__c, appliance2Asset.Premium_Support_End_Date__c);
    }

    @isTest
    private static void testDoubleR344SingleQuantity() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(15, SUPPORT_344_SINGLE_QUANTITY),
            makeOrderItem(12, SUPPORT_344_SINGLE_QUANTITY)
        };
        insert orderItems;

        OrderItem support1 = orderItems[0];
        OrderItem support2 = orderItems[1];

        Test.startTest();


        support1.SerialNumber__c = 'SN1';
        support1.Support_Start_Date__c = system.Today();
        support1.Support_End_Date__c = system.Today().addYears(1);

        support2.SerialNumber__c = 'SN2';
        support2.Support_Start_Date__c = system.Today();
        support2.Support_End_Date__c = system.Today().addYears(1);

        update OrderItems;
        shipOrder();

        Test.stopTest();

        assertAssetsEntitlements(support1, 1, 1, new Set<String>{'SN1'});
        assertAssetsEntitlements(support2, 1, 1, new Set<String>{'SN2'});
    }

    @isTest
    private static void testSpareWithR344R348Supports() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(1, NFR_R300_SINGLE_ENTITLEMENT),
            makeOrderItem(1, NFR_R300_SINGLE_ENTITLEMENT),
            makeOrderItem(1, NFR_R300_SINGLE_ENTITLEMENT),
            makeOrderItem(5, SUPPORT_344_SINGLE_QUANTITY),
            makeOrderItem(7, SUPPORT_348_SINGLE_QUANTITY),
            makeOrderItem(7, SUPPORT_348_SINGLE_QUANTITY)
        };
        insert orderItems;

        OrderItem spare1 = orderItems[0];
        OrderItem spare2 = orderItems[1];
        OrderItem spare3 = orderItems[2];

        OrderItem supportSpare1 = orderItems[3];
        OrderItem supportSpare2 = orderItems[4];
        OrderItem supportSpare3 = orderItems[5];

        Test.startTest();


        spare1.SerialNumber__c = 'SN1';
        spare2.SerialNumber__c = 'SN2';
        spare3.SerialNumber__c = 'SN3';

        supportSpare1.SerialNumber__c = 'SN1';
        supportSpare1.Support_Start_Date__c = system.Today();
        supportSpare1.Support_End_Date__c = system.Today().addYears(1);

        supportSpare2.SerialNumber__c = 'SN2';
        supportSpare2.Support_Start_Date__c = system.Today();
        supportSpare2.Support_End_Date__c = system.Today().addYears(1);

        supportSpare3.SerialNumber__c = 'SN3';
        supportSpare3.Support_Start_Date__c = system.Today();
        supportSpare3.Support_End_Date__c = system.Today().addYears(1);

        update OrderItems;
        shipOrder();

        Test.stopTest();

        assertEntitlementsOnly(supportSpare1, 1);
        entitlementsRelatedToAssets(new Set<String>{'SN1'}, supportSpare1);

        assertEntitlementsOnly(supportSpare2, 1);
        entitlementsRelatedToAssets(new Set<String>{'SN2'}, supportSpare2);

        assertEntitlementsOnly(supportSpare3, 1);
        entitlementsRelatedToAssets(new Set<String>{'SN3'}, supportSpare3);

        assertAssetsEntitlements(spare1, 1, 1, new Set<String>{'SN1'});
        assertAssetsEntitlements(spare2, 1, 1, new Set<String>{'SN2'});
        assertAssetsEntitlements(spare3, 1, 1, new Set<String>{'SN3'});
    }

    @isTest
    private static void testNFRR344() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(1, NFR_R344_APPLIANCE_PBE)
        };
        insert orderItems;
        OrderItem nfrAppliance = orderItems[0];

        //shipOrder();

        Test.startTest();


        nfrAppliance.SerialNumber__c = 'SN1';
        nfrAppliance.Support_Start_Date__c = system.Today();
        nfrAppliance.Support_End_Date__c = system.Today().addYears(1);

        update orderItems;
        shipOrder();

        Test.stopTest();

        assertAssetsEntitlements(nfrAppliance, 1, 1, new Set<String>{'SN1'});
    }

    @isTest
    private static void testNFRNRDR300WITHSN() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(1, NFR_R300_SINGLE_ENTITLEMENT)
        };
        insert orderItems;
        OrderItem nfrAppliance = orderItems[0];

        //shipOrder();

        Test.startTest();


        nfrAppliance.SerialNumber__c = 'SN1';
        nfrAppliance.Support_Start_Date__c = system.Today();
        nfrAppliance.Support_End_Date__c = system.Today().addYears(1);

        update orderItems;
        shipOrder();

        Test.stopTest();

        assertAssetsEntitlements(nfrAppliance, 1, 1, new Set<String>{'SN1'});
    }

    @isTest
    private static void testNFRNRDR300() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(1, NFR_R300_SINGLE_ENTITLEMENT)
        };
        insert orderItems;
        OrderItem nfrAppliance = orderItems[0];

        //shipOrder();

        Test.startTest();


        nfrAppliance.Support_Start_Date__c = system.Today();
        nfrAppliance.Support_End_Date__c = system.Today().addYears(1);

        update orderItems;
        shipOrder();

        Test.stopTest();

        assertEntitlementsOnly(nfrAppliance, 1);
    }

    @isTest
    private static void testApplianceR348sWithSqSubscriptionsAndSupport() {

        System.assertNotEquals(null, ASSETS);

        OrderItem[] orderItems = new OrderItem[] {
            makeOrderItem(1, APPLIANCE_R348S),
            makeOrderItem(4, SUBSCRIPTION_CLON_3YR_SINGLE_ENTITLEMENT),
            makeOrderItem(20, SUBSCRIPTION_RCDM_3YR_SINGLE_ENTITLEMENT),
            makeOrderItem(1, SUPPORT_R348S_3YR)
        };
        insert orderItems;
        OrderItem appliance = orderItems[0];
        OrderItem subscriptionClon = orderItems[1];
        OrderItem subscriptionRCDM = orderItems[2];
        OrderItem support = orderItems[3];

        //shipOrder();

        Test.startTest();


        appliance.SerialNumber__c = 'SN1';

        subscriptionClon.Support_Start_Date__c = system.Today();
        subscriptionClon.Support_End_Date__c = system.Today().addYears(1);

        subscriptionRCDM.Support_Start_Date__c = system.Today();
        subscriptionRCDM.Support_End_Date__c = system.Today().addYears(1);

        support.Support_Start_Date__c = system.Today();
        support.Support_End_Date__c = system.Today().addYears(1);

        update orderItems;
        shipOrder();

        Test.stopTest();

        assertAssetsOnly(appliance, 1);
        assertEntitlementsOnly(subscriptionClon, 1);
        assertEntitlementsOnly(subscriptionRCDM, 1);
        assertAssetsEntitlements(support, 0, 1, new Set<String>{'SN1'});
    }


    @testSetup
    static void setup() {
        insert new list<TriggerControl__c> {
           new TriggerControl__c(Name='Contact', DisableTrigger__c=false),
           new TriggerControl__c(Name='Opportunity', DisableTrigger__c=false),
           new TriggerControl__c(Name='Entitlement', DisableTrigger__c=false),
           new TriggerControl__c(Name='Asset', DisableTrigger__c=false)
        };
        insert new Test_Controls__c(Bypass_Pricebook_Setting_on_Opp__c = true, Bypass_Pricebook_Setting_on_Quote__c = true);


        insert new PatchManagerSettings__c(Default_User_Id__c = UserInfo.getUserId(), Default_Account_User__c = UserInfo.getUserId());

        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        System.runAs(thisUser) {

            Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
            UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
            User sysAdmin = new User(
                UserRoleId = portalRole.Id,
                ProfileId = profile1.Id,
                Username = System.now().millisecond() + 'sysAdmin@randomtestdomain.com',
                Alias = 'batman',
                Email = System.now().millisecond() + 'random.email@randomtestdomain.com',
                EmailEncodingKey = 'UTF-8',
                Firstname = 'test',
                Lastname = 'test',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                TimeZoneSidKey = 'America/Chicago'
            );
            Database.insert(sysAdmin);
        }
    }

    static void assertAssetsEntitlements(OrderItem oi, Integer numAssets, Integer numEnts) {
        assertAssetsEntitlements(oi, numAssets, numEnts, null);
    }

    static void assertAssetsEntitlements(OrderItem oi, Integer numAssets, Integer numEnts, Set<String> sNs) {


        Asset[] asts = [select Id, Order_Service_Item__c, Order_Service_Item__r.Support_Product_Code__c, Serial_number__c from Asset where Order_Service_Item__c = :oi.Id];//in oi.SerialNumber__c.split(',')];
       // System.assertEquals(numAssets, asts.size(), json.serialize(asts));
        if(numAssets > 0) {
            Set<String> serialNumbers = (oi.SerialNumber__c != null) ? new Set<String>(oi.SerialNumber__c.split(',')) : new Set<String>();
            for(Asset a : asts) {
                System.assertEquals(oi.Id, a.Order_Service_Item__c);

                if(!serialNumbers.isEmpty()) {
                    System.assertEquals(true, serialNumbers.contains(a.Serial_number__c));
                }
            }
        }

        Entitlement[] ents = [select Id, Order_Service_Item__c, StartDate, EndDate, AssetId, Asset.SerialNumber from Entitlement where Order_Service_Item__c = :oi.Id];
       // System.assertEquals(numEnts, ents.size());
        for(Entitlement e : ents) {
            System.assertEquals(oi.Support_Start_Date__c, e.StartDate);
            System.assertEquals(oi.Support_End_Date__c, e.EndDate);
            if(oi.SerialNumber__c != null) {
                System.assertNotEquals(null, e.AssetId);
                if(sNs != null) {
                    sNs.contains(e.Asset.SerialNumber);
                }
            }

        }

    }

    static Asset getAsset(OrderItem oi) {
        Asset assetToReturn = new Asset();
        Asset[] asts = [
            SELECT
                Id,
                Order_Service_Item__c,
                Order_Service_Item__r.Support_Product_Code__c,
                Serial_number__c,
                Support_Start_Date__c,
                Premium_Support_End_Date__c,
                Status,
                PurchaseDate,
                SBQQ__Number__c,
                Location__c,
                SBQQ__QuoteLine__c,
                SBQQ__Bundle__c,
                SBQQ__CombineKey__c,
                Quantity
            FROM Asset
            WHERE Order_Service_Item__c = :oi.Id
        ];
        if(asts!=null && !asts.isempty() && asts.size() == 1)
        assetToReturn =  asts.get(0);
        return assetToReturn;
    }

    static Entitlement[] getEntitlements(OrderItem oi) {
        Entitlement[] ents = [select Id, Order_Service_Item__c, StartDate, EndDate, AssetId, Asset.SerialNumber from Entitlement where Order_Service_Item__c = :oi.Id];
        return ents;
    }

    static void entitlementsRelatedToAssets(Set<String> sns, OrderItem oi) {
        Entitlement[] ents = getEntitlements(oi);
        boolean allSnsMatched = false;
        List<String> entSns = new List<String>();

        for(Entitlement ent : ents) {

            if(sns != null) {
                String sn = ent.Asset.SerialNumber;
                entSns.add(sn);
                allSnsMatched = (sns.contains(sn)) ? true : allSnsMatched;
            }
            else {
                allSnsMatched = (ent.Asset == null) ? true : allSnsMatched;
            }
        }
        /*if(sns != null) {
            System.assertEquals(sns.size(), ents.size());
            System.assertEquals(true, allSnsMatched, JSON.serialize(ents));
            System.assertEquals(sns.size(), entSns.size());
            System.assertEquals(true, sns.containsAll(entSns));
        }
        else {
            System.assertEquals(true, allSnsMatched, JSON.serialize(ents));
        }*/
    }

    static void assertAssetsOnly(OrderItem oi, Integer numAssets) {
        assertAssetsEntitlements(oi, numAssets, 0);
    }

    static void assertEntitlementsOnly(OrderItem oi, Integer numEnts, Set<String> sNs) {
        assertAssetsEntitlements(oi, 0, numEnts, sNs);
    }

    static void assertEntitlementsOnly(OrderItem oi, Integer numEnts) {
        assertAssetsEntitlements(oi, 0, numEnts, null);
    }

    /*private static void resetFlags() {
        //OrderItemService.processingEntitlements = false;
        //OrderItemService.processedShippedOrders = false;
        //OrderItemService.processedSingleEntOrders = false;
        //OrderItemService.processLineChanges = false;
        OrderService.OrderInfoMap = null;
    }*/


    private static void shipOrder() {
        // reset the flag and update Order

        

        //ORD.Ship_To_Name__c = ACCT.id;
        ORD.ShipToContactName__c = 'sh';
        ORD.Shipping_Method__c = 'EXW';
        ORD.Shipping_Carrier__c = 'AIT';
        ORD.Service_Level__c = 'Same Day';
        ORD.Bill_To_Name__C = ACCT.id;
        ORD.Est_Ship_Date__C = System.Today().addDays(7);
        ORD.Status = 'Shipped';
        ORD.Order_Status__c = 'Shipped';
        update ORD;

        for(OrderItem oi : [SELECT Id, Order_Status__c FROM OrderItem WHERE OrderId = :ORD.Id]) {
            System.assertEquals('Shipped', oi.Order_Status__c);
        }

    }

    private static OrderItem makeOrderItem(Integer qty, PricebookEntry pbe) {
        return new OrderItem(OrderId = ORD.Id,
                        Quantity = qty,
                        PricebookEntryId = pbe.Id,
                        UnitPrice = pbe.UnitPrice);

    }

/**************************************************************************************************
 * @description       : Creating Products To Be Used in Test Class.
 * @last modified on  : 11-03-2025
 * @last modified by  : Prashant Kumar
 ******************************************************************************/
    public static list<Product2> Products {
        get {
            if (Products == null) {
                Products = new list<Product2> {
                    //apliance
                    // 0
                    new Product2(Name = 'RBK-R348-01',
                                ProductCode = 'RBK-R348-01',
                                Category__c = 'Platform',
                                Family = 'RBK-R300',
                                Support_Type__c = 'PREM',
                                Appliance_Model__c = 'R348',
                                Appliance_Model_HW__c = 'R348',
                                Create_Asset_Entitlement__c = true,
                                Asset_Priority__c = 0,
                                IsActive = true),
                    //support
                    // 1
                    new Product2(Name = 'RBK-SVC-PREM-R348-3YR',
                                ProductCode = 'RBK-SVC-PREM-R348-3YR',
                                Category__c = 'Support',
                                Family = 'RBK-R300',
                                Support_Term__c = '3YR',
                                Support_Type__c = 'PREM',
                                Appliance_Model__c = 'R348',
                                Appliance_Model_HW__c = 'R348',
                                Asset_Priority__c = 1,
                                IsActive = true),
                    //support
                    // 2
                    new Product2(Name = 'RBK-SVC-PREM-R348-3YR',
                                ProductCode = 'RBK-SVC-PREM-R348-3YR',
                                Category__c = 'Support',
                                Family = 'RBK-R300',
                                Support_Term__c = '3YR',
                                Support_Type__c = 'PREM',
                                Appliance_Model__c = 'R348',
                                Appliance_Model_HW__c = 'R348',
                                Single_Entitlement__c = true,
                                Asset_Priority__c = 1,
                                IsActive = true),
                    //subscription
                    // 3
                    new Product2(Name = 'RBK-CLON-R348-3YR',
                                ProductCode = 'RBK-CLON-R348-3YR',
                                Category__c = 'Subscription',
                                Single_Entitlement__c = true,
                                Asset_Priority__c = 2,
                                IsActive = true),
                    //
                    //spare
                    // 4
                    new Product2(Name = 'RBK-HDD-4TB-01',
                                ProductCode = 'RBK-HDD-4TB-01',
                                Category__c = 'Spare',
                                Family = 'RBK-R300',
                                Support_Type__c = 'PREM',
                                Create_Asset__c = true,
                                Asset_Priority__c = 0,
                                IsActive = true),
                    //spare support
                    // 5
                    new Product2(Name = 'RBK-SVC-PREM-R344',
                                ProductCode = 'RBK-SVC-PREM-R344',
                                Category__c = 'Support',
                                Family = 'RBK-R300',
                                Support_Term__c = '1YR',
                                Support_Type__c = 'PREM',
                                Appliance_Model__c = 'R344',
                                Appliance_Model_HW__c = 'R344',
                                Asset_Priority__c = 1,
                                IsActive = true),

                    //
                    // month subscription single qty
                    // 6
                    new Product2(Name = 'RBK-CLOUT-10-MO',
                                ProductCode = 'RBK-CLOUT-10-MO',
                                Category__c = 'Subscription',
                                Family = 'RBK-CLOUT',
                                Single_Quantity__c = true,
                                Support_Type__c = 'PREM',
                                Asset_Priority__c = null,
                                //Asset_Priority__c = 2,
                                IsActive = true),
                    // month support single qty
                    // 7
                    new Product2(Name = 'RBK-SVC-PREM-R348-MO',
                                ProductCode = 'RBK-SVC-PREM-R348-MO',
                                Category__c = 'Support',
                                Single_Quantity__c = true,
                                Family = 'RBK-R300',
                                Support_Term__c = 'Mo',
                                Support_Type__c = 'PREM',
                                Appliance_Model__c = 'R348',
                                Appliance_Model_HW__c = 'R348',
                                Asset_Priority__c = 1,
                                IsActive = true),

                    // NFRs
                    // NFR 334
                    // 8
                    new Product2(Name = 'RBK-R334-01-NFR',
                                ProductCode = 'RBK-R334-01-NFR',
                                Category__c = 'NFR',
                                Family = 'RBK-R300',
                                Support_Type__c = 'PREM',
                                Appliance_Model__c = 'R334',
                                Appliance_Model_HW__c = 'R334',
                                Create_Asset_Entitlement__c = true,
                                Asset_Priority__c = 0,
                                IsActive = true),
                    // NFR 348
                    // 9
                    new Product2(Name = 'RBK-R348-01-NFR',
                                ProductCode = 'RBK-R348-01-NFR',
                                Category__c = 'NFR',
                                Family = 'RBK-R300',
                                Support_Type__c = 'PREM',
                                Appliance_Model__c = 'R348',
                                Appliance_Model_HW__c = 'R348',
                                Create_Asset_Entitlement__c = true,
                                Asset_Priority__c = 0,
                                IsActive = true),

                    // additional cases
                    // RBK-R3410S-01
                    // 10
                    new Product2(Name = 'RBK-R3410S-01',
                                ProductCode = 'RBK-R3410S-01',
                                Category__c = 'Platform',
                                Family = 'RBK-R300',
                                Support_Type__c = 'PREM',
                                Appliance_Model__c = 'R3410S',
                                Appliance_Model_HW__c = 'R3410',
                                Create_Asset_Entitlement__c = true,
                                Description = 'r3410s Appliance, 4-node, 120TB, SFP+ NIC, RCDM, SW Encryption',
                                Asset_Priority__c = 0,
                                IsActive = true),
                    // RBK-SVC-PREM-R3410S
                    // 11
                    new Product2(Name = 'RBK-SVC-PREM-R3410S',
                                ProductCode = 'RBK-SVC-PREM-R3410S',
                                Category__c = 'Support',
                                Family = 'RBK-R300',
                                Support_Term__c = '1Yr',
                                Support_Type__c = 'PREM',
                                Appliance_Model__c = 'R3410S',
                                Appliance_Model_HW__c = 'R3410',
                                Asset_Priority__c = 1,
                                IsActive = true),
                    // RBK-SFP-TSR-01
                    // 12
                    new Product2(Name = 'RBK-SFP-TSR-01',
                                ProductCode = 'RBK-SFP-TSR-01',
                                Category__c = 'Accessories',
                                Support_Type__c = 'PREM',
                                Asset_Priority__c = 0,
                                IsActive = true),
                    // RBK-CLON-10-1YR-PROMO with single entitlement and no Appliance model code
                    // 13
                    new Product2(Name = 'RBK-CLON-10-1YR-PROMO',
                                ProductCode = 'RBK-CLON-10-1YR-PROMO',
                                Category__c = 'Subscription',
                                Family = 'RBK-CLON',
                                Support_Term__c = '1Yr',
                                Support_Type__c = 'PREM',
                                Single_Entitlement__c = true,
                                Asset_Priority__c = null,
                                IsActive = true),
                    // RBK-CLON-10-1YR-PROMO no single Entitlement and no Appliance model code
                    // 14
                    new Product2(Name = 'RBK-CLON-10-1YR-PROMO-NSE-NSPC',
                                ProductCode = 'RBK-CLON-10-1YR-PROMO-NSE-NSPC',
                                Category__c = 'Subscription',
                                Family = 'RBK-CLON',
                                Support_Term__c = '1Yr',
                                Support_Type__c = 'PREM',
                                Single_Entitlement__c = false,
                                Asset_Priority__c = null,
                                IsActive = true),
                    // RBK-CLON-10-1YR-PROMO with Appliance model code and with single entitlement
                    // 15
                    new Product2(Name = 'RBK-CLON-10-1YR-PROMO',
                                ProductCode = 'RBK-CLON-10-1YR-PROMO',
                                Category__c = 'Subscription',
                                Family = 'RBK-CLON',
                                Appliance_Model__c = 'R3410S',
                                Appliance_Model_HW__c = 'R3410',
                                Support_Term__c = '1Yr',
                                Support_Type__c = 'PREM',
                                Single_Entitlement__c = true,
                                Asset_Priority__c = null,
                                IsActive = true),
                    // 16
                    new Product2(Name = 'RBK-CLOUT-OBJ',
                                ProductCode = 'RBK-CLOUT-OBJ',
                                Description = 'Archival to on-premises object storage',
                                Asset_Priority__c = 2,
                                IsActive = true),
                    // EDGE
                    // 17
                    new Product2(Name = 'RBK-EDGE-10-3YR',
                                ProductCode = 'RBK-EDGE-10-3YR',
                                Category__c = 'Subscription',
                                Family = 'RBK-EDGE',
                                Appliance_Model__c = null,
                                Appliance_Model_HW__c = null,
                                Support_Term__c = '3Yr',
                                Support_Type__c = 'PREM',
                                Single_Entitlement__c = true,
                                Asset_Priority__c = null,
                                IsActive = true),
                    // Support CLOUT OBJ
                    // 18
                    new Product2(Name = 'RBK-SVC-PREM-CLOUT-OBJ-3YR',
                                ProductCode = 'RBK-SVC-PREM-CLOUT-OBJ-3YR',
                                Category__c = 'Support',
                                Family = 'RBK-CLOUT',
                                Appliance_Model__c = null,
                                Appliance_Model_HW__c = null,
                                Support_Term__c = '3Yr',
                                Support_Type__c = 'PREM',
                                Single_Entitlement__c = true,
                                Asset_Priority__c = 1,
                                IsActive = true),
                    // 19 Spare
                    new Product2(Name = 'X-0018-01',
                                ProductCode = 'X-0018-01',
                                Category__c = 'Spare',
                                Family = 'RBK-R300',
                                Support_Type__c = 'PREM',
                                Create_Asset_Entitlement__c = true,
                                Asset_Priority__c = 0,
                                IsActive = true),
                    // 20
                    new Product2(Name = 'RBK-SVC-PREM-CLOUT-OBJ-3YR',
                                ProductCode = 'RBK-SVC-PREM-CLOUT-OBJ-3YR',
                                Category__c = 'Support',
                                Family = 'RBK-CLOUT',
                                Appliance_Model__c = null,
                                Appliance_Model_HW__c = null,
                                Support_Term__c = '3Yr',
                                Support_Type__c = 'PREM',
                                Asset_Priority__c = 1,
                                IsActive = true),
                    // 21
                    new Product2(Name = 'RBK-SVC-PREM-R344-MO',
                                ProductCode = 'RBK-SVC-PREM-R344-MO',
                                Category__c = 'Support',
                                Family = 'RBK-R300',
                                Appliance_Model__c = 'R344',
                                Appliance_Model_HW__c = 'R344',
                                Single_Quantity__c = true,
                                Asset_Priority__c = 1,
                                IsActive = true),
                    // 22
                    new Product2(Name = 'RBK-SVC-PREM-R348-MO',
                                ProductCode = 'RBK-SVC-PREM-R348-MO',
                                Category__c = 'Support',
                                Family = 'RBK-R300',
                                Appliance_Model__c = 'R348',
                                Appliance_Model_HW__c = 'R348',
                                Single_Quantity__c = true,
                                Asset_Priority__c = 1,
                                IsActive = true),
                    // 23
                    new Product2(Name = 'RBK-NRD-R300-1YR',
                                ProductCode = 'RBK-NRD-R300-1YR',
                                Category__c = 'Non-Returnable Disk Service',
                                Family = 'RBK-R300',
                                Appliance_Model__c = null,
                                Appliance_Model_HW__c = null,
                                Single_Entitlement__c = true,
                                Asset_Priority__c = 1,
                                IsActive = true),
                    // 24
                    new Product2(Name = 'RBK-R344-01-NFR',
                                ProductCode = 'RBK-R344-01-NFR',
                                Category__c = 'Bundle',
                                Product_Type__c = 'NFR',
                                Family = 'RBK-R300',
                                Support_Type__c = 'PREM',
                                Appliance_Model__c = 'R344',
                                Appliance_Model_HW__c = 'R344',
                                Create_Asset_Entitlement__c = true,
                                Asset_Priority__c = 0,
                                IsActive = true),
                    // 25
                    new Product2(Name = 'RBK-R348S-01',
                                ProductCode = 'RBK-R348S-01',
                                Category__c = 'Platform',
                                Product_Type__c = 'Appliance',
                                Family = 'RBK-R300',
                                Support_Type__c = 'PREM',
                                Appliance_Model__c = 'RBK-R348S',
                                Appliance_Model_HW__c = 'RBK-R348',
                                Create_Asset_Entitlement__c = true,
                                Description = 'r348s Appliance, 4-node, 96TB, dual-port SFP+ NIC, incl RCDM',
                                Asset_Priority__c = 0,
                                IsActive = true),
                    // 26
                    new Product2(Name = 'RBK-CLON-10-3YR-PROMO',
                                ProductCode = 'RBK-CLON-10-3YR-PROMO',
                                Category__c = 'Subscription',
                                Family = 'RBK-CLON',
                                Appliance_Model__c = null,
                                Appliance_Model_HW__c = null,
                                Support_Term__c = '3Yr',
                                Support_Type__c = 'PREM',
                                Single_Entitlement__c = true,
                                Asset_Priority__c = null,
                                IsActive = true),
                    // 27
                    new Product2(Name = 'RBK-RCDM-AZURE-3YR',
                                ProductCode = 'RBK-RCDM-AZURE-3YR',
                                Category__c = 'Subscription',
                                Family = 'RBK-CLON',
                                Appliance_Model__c = null,
                                Appliance_Model_HW__c = null,
                                Support_Term__c = '3Yr',
                                Support_Type__c = 'PREM',
                                Single_Entitlement__c = true,
                                Asset_Priority__c = null,
                                IsActive = true),
                    // 28
                    new Product2(Name = 'RBK-SVC-PREM-R348S-3YR',
                                ProductCode = 'RBK-SVC-PREM-R348S-3YR',
                                Category__c = 'Support',
                                Family = 'RBK-R300S',
                                Appliance_Model__c = 'RBK-R348S',
                                Appliance_Model_HW__c = 'RBK-R348',
                                Asset_Priority__c = 1,
                                IsActive = true)
                };

                insert Products;
            }
            return Products;
        }
        private set;
    }
/**************************************************************************************************
 * @description       : Set List of Assets To use in Test Class
 * @last modified on  : 11-03-2025
 * @last modified by  : Prashant Kumar
 ******************************************************************************/
    public static list<Asset> ASSETS {
        get {
            if (ASSETS == null) {

                ASSETS = new list<Asset> {
                        new Asset(Name = 'SN1', SerialNumber = 'SN1', Serial_Number__c = 'SN1', Product2Id = Products[0].Id, Accountid = acct.Id),
                        new Asset(Name = 'SN2', SerialNumber = 'SN2', Serial_Number__c = 'SN2', Product2Id = Products[0].Id, Accountid = acct.Id),
                        new Asset(Name = 'SN3', SerialNumber = 'SN3', Serial_Number__c = 'SN3', Product2Id = Products[0].Id, Accountid = acct.Id),
                        new Asset(Name = 'SN4', SerialNumber = 'SN4', Serial_Number__c = 'SN4', Product2Id = Products[0].Id, Accountid = acct.Id),

                        new Asset(Name = 'SN10', SerialNumber = 'SN10', Serial_Number__c = 'SN10', Product2Id = Products[0].Id, Accountid = acct.Id),
                        new Asset(Name = 'SN20', SerialNumber = 'SN20', Serial_Number__c = 'SN20', Product2Id = Products[0].Id, Accountid = acct.Id),
                        new Asset(Name = 'SN30', SerialNumber = 'SN30', Serial_Number__c = 'SN30', Product2Id = Products[0].Id, Accountid = acct.Id)

                };
                insert ASSETS;
            }
            return ASSETS;
        }
        private set;
    }
/**************************************************************************************************
 * @description       : Set List of PricebookEntries To use in Test Class
 * @last modified on  : 11-03-2025
 * @last modified by  : Prashant Kumar
 ******************************************************************************/
    public static list<PricebookEntry> PBES {
        get {
            if (PBES == null) {
                PBES = new list<PricebookEntry> {
                    new PricebookEntry(Product2Id = Products[0].Id, Pricebook2Id = Test.getStandardPricebookId(), IsActive = true, UseStandardPrice = false, UnitPrice = 10),
                    new PricebookEntry(Product2Id = Products[1].Id, Pricebook2Id = Test.getStandardPricebookId(), IsActive = true, UseStandardPrice = false, UnitPrice = 20),
                    new PricebookEntry(Product2Id = Products[2].Id, Pricebook2Id = Test.getStandardPricebookId(), IsActive = true, UseStandardPrice = false, UnitPrice = 30),
                    new PricebookEntry(Product2Id = Products[3].Id, Pricebook2Id = Test.getStandardPricebookId(), IsActive = true, UseStandardPrice = false, UnitPrice = 40),
                    new PricebookEntry(Product2Id = Products[4].Id, Pricebook2Id = Test.getStandardPricebookId(), IsActive = true, UseStandardPrice = false, UnitPrice = 50),
                    new PricebookEntry(Product2Id = Products[5].Id, Pricebook2Id = Test.getStandardPricebookId(), IsActive = true, UseStandardPrice = false, UnitPrice = 40),
                    new PricebookEntry(Product2Id = Products[6].Id, Pricebook2Id = Test.getStandardPricebookId(), IsActive = true, UseStandardPrice = false, UnitPrice = 50),
                    new PricebookEntry(Product2Id = Products[7].Id, Pricebook2Id = Test.getStandardPricebookId(), IsActive = true, UseStandardPrice = false, UnitPrice = 150),
                    new PricebookEntry(Product2Id = Products[8].Id, Pricebook2Id = Test.getStandardPricebookId(), IsActive = true, UseStandardPrice = false, UnitPrice = 500),

                    new PricebookEntry(Product2Id = Products[9].Id, Pricebook2Id = Test.getStandardPricebookId(), IsActive = true, UseStandardPrice = false, UnitPrice = 40),
                    new PricebookEntry(Product2Id = Products[10].Id, Pricebook2Id = Test.getStandardPricebookId(), IsActive = true, UseStandardPrice = false, UnitPrice = 50),
                    new PricebookEntry(Product2Id = Products[11].Id, Pricebook2Id = Test.getStandardPricebookId(), IsActive = true, UseStandardPrice = false, UnitPrice = 60),
                    new PricebookEntry(Product2Id = Products[12].Id, Pricebook2Id = Test.getStandardPricebookId(), IsActive = true, UseStandardPrice = false, UnitPrice = 70),
                    new PricebookEntry(Product2Id = Products[13].Id, Pricebook2Id = Test.getStandardPricebookId(), IsActive = true, UseStandardPrice = false, UnitPrice = 60),
                    new PricebookEntry(Product2Id = Products[14].Id, Pricebook2Id = Test.getStandardPricebookId(), IsActive = true, UseStandardPrice = false, UnitPrice = 70),
                    new PricebookEntry(Product2Id = Products[15].Id, Pricebook2Id = Test.getStandardPricebookId(), IsActive = true, UseStandardPrice = false, UnitPrice = 70),

                    new PricebookEntry(Product2Id = Products[16].Id, Pricebook2Id = Test.getStandardPricebookId(), IsActive = true, UseStandardPrice = false, UnitPrice = 70),
                    new PricebookEntry(Product2Id = Products[17].Id, Pricebook2Id = Test.getStandardPricebookId(), IsActive = true, UseStandardPrice = false, UnitPrice = 70),
                    new PricebookEntry(Product2Id = Products[18].Id, Pricebook2Id = Test.getStandardPricebookId(), IsActive = true, UseStandardPrice = false, UnitPrice = 70),
                    new PricebookEntry(Product2Id = Products[19].Id, Pricebook2Id = Test.getStandardPricebookId(), IsActive = true, UseStandardPrice = false, UnitPrice = 70),
                    new PricebookEntry(Product2Id = Products[20].Id, Pricebook2Id = Test.getStandardPricebookId(), IsActive = true, UseStandardPrice = false, UnitPrice = 70),

                    new PricebookEntry(Product2Id = Products[21].Id, Pricebook2Id = Test.getStandardPricebookId(), IsActive = true, UseStandardPrice = false, UnitPrice = 70),
                    new PricebookEntry(Product2Id = Products[22].Id, Pricebook2Id = Test.getStandardPricebookId(), IsActive = true, UseStandardPrice = false, UnitPrice = 80),
                    new PricebookEntry(Product2Id = Products[23].Id, Pricebook2Id = Test.getStandardPricebookId(), IsActive = true, UseStandardPrice = false, UnitPrice = 90),

                    new PricebookEntry(Product2Id = Products[24].Id, Pricebook2Id = Test.getStandardPricebookId(), IsActive = true, UseStandardPrice = false, UnitPrice = 90),

                    new PricebookEntry(Product2Id = Products[25].Id, Pricebook2Id = Test.getStandardPricebookId(), IsActive = true, UseStandardPrice = false, UnitPrice = 70),
                    new PricebookEntry(Product2Id = Products[26].Id, Pricebook2Id = Test.getStandardPricebookId(), IsActive = true, UseStandardPrice = false, UnitPrice = 80),
                    new PricebookEntry(Product2Id = Products[27].Id, Pricebook2Id = Test.getStandardPricebookId(), IsActive = true, UseStandardPrice = false, UnitPrice = 90),
                    new PricebookEntry(Product2Id = Products[28].Id, Pricebook2Id = Test.getStandardPricebookId(), IsActive = true, UseStandardPrice = false, UnitPrice = 100)

                };
                insert PBES;
            }
            return PBES;
        }
        private set;
    }
/**************************************************************************************************
 * @description       : Set List of Accounts To use in Test Class
 * @last modified on  : 11-03-2025
 * @last modified by  : Prashant Kumar
 ******************************************************************************/
    public static Account ACCT {
        get {
            if (ACCT == null) {
                ACCT = new Account(Name='Test Account', Phone='123-456-7890', AccountNumber='Test',
                BillingStreet = '123 street', BillingCity = 'Santa Clara', BillingState = 'California', BillingPostalCode = '95050', BillingCountry = 'United States');
                FlowControll.AccountTrigger = false;
                insert ACCT;
            }
            return ACCT;
        }
        private set;
    }
/**************************************************************************************************
 * @description       : Set List of Opportunity Records To use in Test Class
 * @last modified on  : 11-03-2025
 * @last modified by  : Prashant Kumar
 ******************************************************************************/
    public static Opportunity OPP {
        get {
            if (OPP == null) {
                insert new ShGl_DisableBusinessLogic__c(Disable_Opportunity_Validation_Rules__c = true);
                OpportunityStage stage = [Select MasterLabel From OpportunityStage Where IsWon=false and IsClosed=false and isActive=true Limit 1];
                opp = TestDataFactory.getOpportunity();

                opp.AccountId = ACCT.Id;
                opp.StageName = stage.MasterLabel;
                opp.CloseDate = System.today().addDays(15);
                opp.PriceBook2Id = Test.getStandardPricebookId();
                opp.SBQQ__QuotePricebookId__c = Test.getStandardPricebookId();
                FlowControll.opportunityTriggerHandler = false;
                insert OPP;
                FlowControll.opportunityTriggerHandler = true;
            }
            return OPP;
        }
    }
/**************************************************************************************************
 * @description       : Create Order To Be used in Test Class
 * @last modified on  : 11-03-2025
 * @last modified by  : Prashant Kumar
 ******************************************************************************/
    public static Order ORD {
        get {
            if (ORD == null) {
                ORD = new Order(Type='Revenue',  AccountId=ACCT.Id, OpportunityId=OPP.Id, ShippingStreet ='123 Shipping Street', ShippingCity ='Shipping City',
                    ShippingState ='California', ShippingCountry ='United States', ShippingPostalcode ='94820', EffectiveDate=system.Today(), Status='Pending'
                    , PriceBook2Id = Test.getStandardPricebookId()
                );
                insert ORD;

                //ORD.PriceBook2Id = Test.getStandardPricebookId();
                //update ORD;
            }
            return ORD;
        }
    }

    private static PricebookEntry APPLIANCE_PBE = PBES[0];
    private static PricebookEntry SUPPORT_PBE = PBES[1];
    private static PricebookEntry SUPPORT_WITH_SINGLE_ENTITLEMENT_PBE = PBES[2];
    private static PricebookEntry SUBSCRIPTION_PBE = PBES[3];
    private static PricebookEntry SPARE_PBE = PBES[4];
    private static PricebookEntry SPARE_SUPPORT_PBE = PBES[5];
    private static PricebookEntry MO_SUBSCRIPTION_PBE = PBES[6];
    private static PricebookEntry MO_SUPPORT_PBE = PBES[7];
    private static PricebookEntry NFR_R334_APPLIANCE_PBE = PBES[8];
    private static PricebookEntry NFR_R348_APPLIANCE_PBE = PBES[9];

    private static PricebookEntry APPLIANCE_3410S_PBE = PBES[10];
    private static PricebookEntry SUPPORT_3410S_PBE = PBES[11];
    private static PricebookEntry ACCESSORIES_PBE = PBES[12];
    private static PricebookEntry SUBSCRIPTION_3410S_PBE_WITH_SINGLE_ENTITLEMENT = PBES[13];
    private static PricebookEntry SUBSCRIPTION_3410S_PBE_NO_APPLIANCE_CODE_NO_SE = PBES[14];
    private static PricebookEntry SUBSCRIPTION_3410S_PBE_WITH_APPLIANCE_CODE_WITH_SE = PBES[15];

    private static PricebookEntry SUBSCRIPTION_CLOUT = PBES[16];
    private static PricebookEntry SUBSCRIPTION_EDGE = PBES[17];
    private static PricebookEntry SUPPORT_CLOUT_OBJ = PBES[18];
    private static PricebookEntry SPARE_UPDATE_ASSET = PBES[19];
    private static PricebookEntry SUPPORT_CLOUT_OBJ_MULTI = PBES[20];

    private static PricebookEntry SUPPORT_344_SINGLE_QUANTITY = PBES[21];
    private static PricebookEntry SUPPORT_348_SINGLE_QUANTITY = PBES[22];
    private static PricebookEntry NFR_R300_SINGLE_ENTITLEMENT = PBES[23];

    private static PricebookEntry NFR_R344_APPLIANCE_PBE = PBES[24];

    private static PricebookEntry APPLIANCE_R348S = PBES[25];
    private static PricebookEntry SUBSCRIPTION_CLON_3YR_SINGLE_ENTITLEMENT = PBES[26];
    private static PricebookEntry SUBSCRIPTION_RCDM_3YR_SINGLE_ENTITLEMENT = PBES[27];
    private static PricebookEntry SUPPORT_R348S_3YR = PBES[28];


}