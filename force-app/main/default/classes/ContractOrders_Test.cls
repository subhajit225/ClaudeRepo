@isTest
public class ContractOrders_Test {
  @testSetup
  static void insertData() {
        String uniqueUserName = 'TestUser' + DateTime.now().getTime() + '@rbk.com';
        String uniqueUserName1 = 'TestUser1' + DateTime.now().getTime() + '@rbk.com';
        String uniqueUserName2 = 'TestUser2' + DateTime.now().getTime() + '@rbk.com';
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        
        User usr1 = new user(
            alias = 'std',
            email = 'testuser@testclass.com.invalid',    
            emailencodingkey = 'UTF-8',
            firstname = 'test',
            lastname = 'user',
            languagelocalekey = 'en_US',
            localesidkey = 'en_US',
            profileid = p.Id,
            timezonesidkey = 'America/Los_Angeles',
            username = uniqueUserName,
            RBAC_Department__c = 'Service Account',
            RBAC_Group__c = 'API'
        );
        User usr2 = new user(
            alias = 'std',
            email = 'testuser@testclass.com.invalid',
            emailencodingkey = 'UTF-8',
            firstname = 'test',
            lastname = 'user',
            languagelocalekey = 'en_US',
            localesidkey = 'en_US',
            profileid = p.Id,
            timezonesidkey = 'America/Los_Angeles',
            username = uniqueUserName1,
            RBAC_Department__c = 'Service Account',
            RBAC_Group__c = 'API'
        );
        User usr3 = new user(
            alias = 'std',
      email = 'testuser@testclass.com.invalid',
            emailencodingkey = 'UTF-8',
            firstname = 'test',
            lastname = 'user',
            languagelocalekey = 'en_US',
            localesidkey = 'en_US',
            profileid = p.Id,
            timezonesidkey = 'America/Los_Angeles',
            username = uniqueUserName2,
            RBAC_Department__c = 'Service Account',
            RBAC_Group__c = 'API'
        );
    List<User> ursList = new List<User>{ usr1, usr2, usr3 };
            insert ursList;
        System.runAs(usr1) {
      insert new ShGl_DisableFunctionalityLogic__c(setupOwnerId = UserInfo.getUserId(), Disable_Account_Old_Trigger__c = true);
      insert new ShGl_DisableBusinessLogic__c(
        setupownerid = userinfo.getUserId(),
                                                    Disable_Entitlement_Validation_Rules__c = true,
        Disable_Account_Triggers__c = true,
        Disable_Asset_Triggers__c = true,
        Disable_SBQQ_Quote_Triggers__c = true,
        Disable_SBQQ_QuoteLine_Triggers__c = true,
                                                    Disable_Product2_Validation_Rules__c = true,
        Disable_Order_Old_Trigger__c = true,
        Disable_OrderItem_Old_Trigger__c = true,
        Disable_Opportunity_Triggers__c = true,
        Disable_Product2_Trigger__c = true,
                                                    Disable_Order_Validation_Rules__c = true,
        Disable_SBQQ_QuoteLine_Validation_Rules__c = true
      );
            TriggerControl.stopOrderItemTrigger = true;
            TriggerControl.stopOrderTrigger = true;
      TriggerControl__c objOrderTrigger = new TriggerControl__c(Name = 'Entitlement', Disable_Trigger__c = true, DisableTrigger__c = true, SendEmail__c = false);
            insert objOrderTrigger;
            
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
            
            //Contact cont = TestDataFactory.getContact(customer);
            //insert cont;
            
            Opportunity opp = TestDataFactory.getOpportunity();
            opp.Partner_Lookup__c = customer.Id;
            opp.AccountId = customer.Id;
            opp.Distributor_Lookup__c = opp.AccountId;
            //opp.Initial_Contacts_Name__c = cont.Id;
            opp.Pricebook2id = Test.getStandardPricebookId();
            insert opp;
            
            Opportunity opp1 = TestDataFactory.getOpportunity();
            opp1.Partner_Lookup__c = customer.Id;
            opp1.AccountId = customer.Id;
            opp1.Distributor_Lookup__c = opp.AccountId;
            //opp.Initial_Contacts_Name__c = cont.Id;
            opp1.Pricebook2id = Test.getStandardPricebookId();
            insert opp1;

      SBQQ__Quote__c quote = new SBQQ__Quote__c(
        SBQQ__Opportunity2__c = opp.Id,
        SBQQ__SubscriptionTerm__c = 12,
        Is_RWD_Polaris_Quote__c = true,
        SBQQ__Primary__c = true,
        ApprovalStatus__c = 'Recalled',
        SBQQ__Type__c = 'Quote',
        SBQQ__PriceBook__c = Test.getStandardPricebookId()
      );
            insert quote;
            
      SBQQ__Quote__c quote2 = new SBQQ__Quote__c(
        SBQQ__Opportunity2__c = opp1.Id,
        SBQQ__SubscriptionTerm__c = 12,
        Is_RWD_Polaris_Quote__c = true,
        SBQQ__Primary__c = true,
        ApprovalStatus__c = 'Recalled',
        SBQQ__Type__c = 'Renewal+Expansion',
        SBQQ__PriceBook__c = Test.getStandardPricebookId()
      );
            insert quote2;
            
            List<Product2> sampleProducts = new List<Product2>{
                // 0
                new Product2(
                    Name = 'RS-BT-EE-PE-PP',
                    ProductCode = 'RS-BT-EE-PE-PP',
                    Category__c = 'Bundle',
                    Family = 'Rubrik Licence',
                    Product_Type__c = 'Enterprise Edition',
                    License_Category__c = 'SaaS',
                    Product_Level__c = 'Hybrid Software',
                    SBQQ__AssetAmendmentBehavior__c = 'Default',
                    SBQQSC__EntitlementConversion__c = 'One per quote line',
                    IsActive = true,
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 36,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable'
                ),
                    // 1
                    new Product2(
                        Name = 'RBK-R6412-CONS',
                        ProductCode = 'RBK-R6412-CONS',
                        Category__c = 'Platform',
                        Family = 'r300',
          Usable_Capacity__c = 1,
          Product_Level__c = 'Hardware',
                        Product_Type__c = 'Hardware',
          Appliance_Model__c = 'RBK-R344',
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
                    ),
                    // 2
                    new Product2(
                        Name = 'RBK-RADAR-CONS',
                        ProductCode = 'RBK-RADAR-CONS',
                        Category__c = 'Support',
          Product_Level__c = 'Support',
                        SBQQ__AssetAmendmentBehavior__c = 'Default',
                        SBQQSC__EntitlementConversion__c = 'One per quote line',
                        IsActive = true,
                        CPQ_MSP_Base_Price__c = 0.02,
                        SBQQ__SubscriptionPricing__c = 'Fixed Price',
                        SBQQ__SubscriptionTerm__c = 36,
                        SBQQ__SubscriptionBase__c = 'List',
                        SBQQ__SubscriptionType__c = 'Renewable'
                    ),
                    //3
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
                    ), 
                    //4
                    new Product2(
                        Name = 'RS-HW-SVC-PE-S1',
                        ProductCode = 'RS-HW-SVC-PE-S1',
                        Category__c = 'Support',
                        Family = 'Support',
                        Product_Type__c = 'HW Support',
                        SBQQSC__EntitlementConversion__c = 'One per unit',
                        IsActive = true,
                        Product_Level__c = 'Support',
                        SBQQ__SubscriptionPricing__c = 'Fixed Price',
                        SBQQ__SubscriptionTerm__c = 36,
                        SBQQ__SubscriptionBase__c = 'List',
                        SBQQ__SubscriptionType__c = 'Renewable'
                    ),
                    //5
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
                //6
                    new Product2(
                        Name = 'RH-6408S-01',
                        ProductCode = 'RH-6408S-01',
                        Category__c = 'Hardware',
                        Family = 'R6000',
          Usable_Capacity__c = 60,
          Product_Level__c = 'Hardware',
                        Product_Type__c = 'Hardware',
          Appliance_Model__c = 'RBK-R6408S',
                        Appliance_Model_HW__c = 'RBK-R6408S',
                        SBQQSC__EntitlementConversion__c = 'None',
                        SBQQ__AssetAmendmentBehavior__c = 'Default',
                        IsActive = true,
                        MSP_Segment_Product__c = true,
                        SBQQ__SubscriptionBase__c = 'List'
                    ),
                    //7
                   
        new Product2(
          Name = 'RS-UR-FE-MD-PE-PP',
          ProductCode = 'RS-UR-FE-MD-PE-PP',
                    License_Category__c = 'Subscriptions',
                    Category__c = 'SaaS',
                    Product_Level__c = 'SaaS Software Addon',
                    Product_Type__c = 'M365H',
                    Family = 'POLARIS',
                    SBQQSC__EntitlementConversion__c = 'One per quote line',
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 1,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable',
                    IsActive = true,
          Support_Type__c = 'Premium'
        ),
                //8
        new Product2(
          Name = 'RS-UR-M365-PE-PP',
          ProductCode = 'RS-UR-M365-PE-PP',
                    License_Category__c = 'Subscriptions',
                    Category__c = 'SaaS',
                    Product_Level__c = 'Standalone Software Addon',
                    Product_Type__c = 'Hybrid M365H',
                    Family = 'POLARIS',
                    SBQQSC__EntitlementConversion__c = 'One per quote line',
                    SBQQ__SubscriptionPricing__c = 'Fixed Price',
                    SBQQ__SubscriptionTerm__c = 1,
                    SBQQ__SubscriptionBase__c = 'List',
                    SBQQ__SubscriptionType__c = 'Renewable',
                    IsActive = true,
          Support_Type__c = 'Premium'
        ),
                    //9
        new Product2(
          Name = 'RS-TB-EE-RSV-PE',
          ProductCode = 'RS-TB-EE-RSV-PE',
          Support_Type__c = 'Premium',
          Product_Level__c = 'Hybrid Software',
          License_Type__c = 'Consumption',
          Product_Type__c = 'Enterprise Edition',
          Product_Subtype__c = 'Scale MSP',
          Product_Payment_Option__c = 'Monthly',
          Approval_Category__c = 'Scale Utility RSV',
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__SubscriptionType__c = 'Renewable',
          SBQQSC__EntitlementConversion__c = 'One per quote line',
          SBQQ__AssetAmendmentBehavior__c = 'Default'
        ),
                     //10
                    new Product2(
                        Name = 'RBK-HW-CONS1',
                        ProductCode = 'RBK-Hw-CONS1',
                        Category__c = 'Support',
                        SBQQ__AssetAmendmentBehavior__c = 'Default',
                        SBQQSC__EntitlementConversion__c = 'One per unit',
                        IsActive = true,
                        Product_Type__c = '3rd Party Hardware',
                        CPQ_MSP_Base_Price__c = 0.02,
                        SBQQ__SubscriptionPricing__c = 'Fixed Price',
                        SBQQ__SubscriptionTerm__c = 36,
                        SBQQ__SubscriptionBase__c = 'List',
                        SBQQ__SubscriptionType__c = 'Renewable'
                    ),
                     //11
                    new Product2(
                        Name = 'RBK-HW-Addon',
                        ProductCode = 'RBK-Hw-Addon',
                        Category__c = 'Support',
                        SBQQ__AssetAmendmentBehavior__c = 'Default',
                        SBQQSC__EntitlementConversion__c = 'One per unit',
                        IsActive = true,
            Product_Level__c = 'Standalone Software Addon',
                        CPQ_MSP_Base_Price__c = 0.02,
                        SBQQ__SubscriptionPricing__c = 'Fixed Price',
                        SBQQ__SubscriptionTerm__c = 36,
                        SBQQ__SubscriptionBase__c = 'List',
                        SBQQ__SubscriptionType__c = 'Renewable'
                    ),
            // 12
                              new Product2(
                        Name = 'RS-TB-EE-RSVX-PE',
                        ProductCode = 'RS-TB-EE-RSVX-PE',
                        Product_Level__c = 'Hybrid Software',
                        Product_Type__c = 'Enterprise Edition',
                        Product_Subtype__c = 'Scale MSP',
                        License_Category__c = null,
                        License_Type__c = 'Consumption',
                        Quotable_Date__c = system.today(),
                        IsActive = true,
                        SBQQ__Hidden__c = false,
                        Support_Type__c = 'Premium',
                        SBQQ__ExcludeFromOpportunity__c = true,
                        SBQQSC__EntitlementConversion__c = 'One per quote line',
                        New_CPQ_Product__c = true
                    ),
                    // 13
                     new Product2(
                        Name = 'RS-UR-EE-MD-RSVX-L3',
                        ProductCode = 'RS-UR-EE-MD-RSVX-L3',
                        Product_Type__c = 'Enterprise Edition',
                        Product_Subtype__c = 'Scale MSP',
                        License_Category__c = null,
                        License_Type__c = 'Consumption',
                        Quotable_Date__c = system.today(),
                        IsActive = true,
                        SBQQ__Hidden__c = false,
                        Support_Type__c = 'Premium',
                        SBQQ__ExcludeFromOpportunity__c = true,
                        SBQQSC__EntitlementConversion__c = 'One per quote line',
                        New_CPQ_Product__c = true
                    ),  
                    //14
        new Product2(
          Name = 'RS-UR-FE-MD-RSV-PE',
          ProductCode = 'RS-UR-FE-MD-RSV-PE',
          Support_Type__c = 'Premium',
          License_Type__c = 'Consumption',
          Product_Type__c = 'M365H',
          Product_Subtype__c = 'Scale MSP',
          License_Category__c = 'SaaS',
          Product_Payment_Option__c = 'Monthly',
          Approval_Category__c = 'Scale Utility RSV',
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__SubscriptionType__c = 'Renewable',
          SBQQSC__EntitlementConversion__c = 'One per quote line',
          SBQQ__AssetAmendmentBehavior__c = 'Default'
        ),
        //15
        new Product2(
          Name = 'RS-TB-FUE-RSV-PE',
          ProductCode = 'RS-TB-FUE-RSV-PE',
          Support_Type__c = 'Premium',
          License_Type__c = 'Consumption',
          Product_Type__c = 'Edition Upgrade',
          Product_Subtype__c = 'Scale MSP',
          License_Category__c = 'SaaS',
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__SubscriptionType__c = 'Renewable',
          SBQQSC__EntitlementConversion__c = 'One per quote line',
          SBQQ__AssetAmendmentBehavior__c = 'Default'
        ),
                      //16 LicenseAddon v1
                    new Product2(
                        Name = 'RBK-GO-FNDN-R6412-ADDON-NODE',
                        ProductCode = 'RBK-GO-FNDN-R6412-ADDON-NODE',
                        Category__c = 'Bundle',
                        Family = 'R6000',
                        Product_Type__c = 'Foundation Edition',
          Edition__c = 'Foundation Edition',
                        SBQQSC__EntitlementConversion__c = 'One per unit',
                        IsActive = true,
                        SBQQ__SubscriptionPricing__c = 'Fixed Price',
                        SBQQ__SubscriptionTerm__c = 1,
                        SBQQ__SubscriptionBase__c = 'List',
                        SBQQ__SubscriptionType__c = 'Renewable'
                    ), 
                    //17 V1 Hw Support
                    new Product2(
          Name = 'RBK-SVC-PREM-HW',
          ProductCode = 'RBK-SVC-PREM-HW',
          Support_Type__c = 'Premium',
          Category__c = 'Support',
          IsActive = true,
          Product_Type__c = 'HW Support',
          License_Category__c = 'Subscriptions',
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__SubscriptionType__c = 'Renewable',
          SBQQSC__EntitlementConversion__c = 'One per unit',
          SBQQ__AssetAmendmentBehavior__c = 'Default'
        )
                    };
                        insert sampleProducts;
      List<PricebookEntry> entries = new List<PricebookEntry>();
            
            entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[0].Id, IsActive = true, UnitPrice = 100));
            entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[1].Id, IsActive = true, UnitPrice = 200));
            entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[2].Id, IsActive = true, UnitPrice = 300));
            entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[3].Id, IsActive = true, UnitPrice = 400));
            entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[4].Id, IsActive = true, UnitPrice = 400));
            entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[5].Id, IsActive = true, UnitPrice = 100));
            entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[6].Id, IsActive = true, UnitPrice = 100));
            entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[7].Id, IsActive = true, UnitPrice = 100));
            entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[8].Id, IsActive = true, UnitPrice = 100));
            entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[9].Id, IsActive = true, UnitPrice = 100));
            entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[10].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[11].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[12].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[13].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[14].Id, IsActive = true, UnitPrice = 100));
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[15].Id, IsActive = true, UnitPrice = 100));
            entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[16].Id, IsActive = true, UnitPrice = 100));
            entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = sampleProducts[17].Id, IsActive = true, UnitPrice = 100));           
        
        insert entries;
            
            List<Asset> assestIns = new List<Asset>{
        new Asset(
          Name = '09092019APMSP1250',
          SerialNumber = '09092019APMSP1250',
          serial_number__c = '09092019APMSP1250',
          AccountId = customer.Id,
          Product2Id = sampleProducts[0].Id
        ),
        new Asset(
          Name = '09092019APMSP1253',
          SerialNumber = '09092019APMSP1253',
          serial_number__c = '09092019APMSP1253',
          AccountId = customer.Id,
          Product2Id = sampleProducts[6].Id
        ),
        new Asset(
          Name = '09092019APMSP1254',
          SerialNumber = '09092019APMSP1254',
          serial_number__c = '09092019APMSP1254',
          AccountId = customer.Id,
          Product2Id = sampleProducts[6].Id
        )
      };

      insert assestIns;
      List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote.Id,
          SBQQ__Product__c = sampleProducts[0].Id,
          SBQQ__PricebookEntryId__c = entries[0].Id,
          SBQQ__Quantity__c = 70,
          SBQQ__SubscriptionPricing__c = null,
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote.Id,
          SBQQ__Product__c = sampleProducts[1].Id,
          SBQQ__PricebookEntryId__c = entries[1].Id,
          MSP_Segment_Product__c = true,
          SBQQ__Quantity__c = 20,
          SBQQ__Segmentindex__c = 1,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          SBQQ__Existing__c = true
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote.Id,
          SBQQ__Product__c = sampleProducts[2].Id,
          SBQQ__PricebookEntryId__c = entries[2].Id,
          SBQQ__Quantity__c = 20,
          SBQQ__SubscriptionPricing__c = null,
          SBQQ__DefaultSubscriptionTerm__c = 12,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote.Id,
          SBQQ__Product__c = sampleProducts[3].Id,
          SBQQ__PricebookEntryId__c = entries[3].Id,
          MSP_Segment_Product__c = true,
          SBQQ__Quantity__c = 20,
          SBQQ__Segmentindex__c = 1,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote.Id,
          SBQQ__Product__c = sampleProducts[4].Id,
          SBQQ__PricebookEntryId__c = entries[4].Id,
          MSP_Segment_Product__c = true,
          SBQQ__Quantity__c = 1,
          SBQQ__Segmentindex__c = 1,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote.Id,
          SBQQ__Product__c = sampleProducts[5].Id,
          SBQQ__PricebookEntryId__c = entries[5].Id,
          SBQQ__Quantity__c = 42,
          SBQQ__SubscriptionPricing__c = null,
          SBQQ__StartDate__c = System.today().addMonths(4).addDays(-6),
          SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1),
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote.Id,
          SBQQ__Product__c = sampleProducts[6].Id,
          SBQQ__PricebookEntryId__c = entries[6].Id,
          MSP_Segment_Product__c = true,
          SBQQ__Quantity__c = 20,
          SBQQ__Segmentindex__c = 1,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          SBQQ__Existing__c = true
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote.Id,
          SBQQ__Product__c = sampleProducts[7].Id,
          SBQQ__PricebookEntryId__c = entries[7].Id,
          SBQQ__Quantity__c = 20,
          SBQQ__SubscriptionPricing__c = null,
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote.Id,
          SBQQ__Product__c = sampleProducts[8].Id,
          SBQQ__PricebookEntryId__c = entries[8].Id,
          SBQQ__Quantity__c = 20,
          SBQQ__SubscriptionPricing__c = null,
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          SBQQ__Optional__c = true,
          Disposition_Reason__c = 'Replaced'
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote.Id,
          SBQQ__Product__c = sampleProducts[9].Id,
          SBQQ__PricebookEntryId__c = entries[9].Id,
          SBQQ__Quantity__c = 20,
          SBQQ__SubscriptionPricing__c = null,
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote.Id,
          SBQQ__Product__c = sampleProducts[10].Id,
          SBQQ__PricebookEntryId__c = entries[10].Id,
          SBQQ__Quantity__c = 20,
          SBQQ__SubscriptionPricing__c = null,
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote.Id,
          SBQQ__Product__c = sampleProducts[10].Id,
          SBQQ__PricebookEntryId__c = entries[10].Id,
          SBQQ__Quantity__c = 20,
          SBQQ__SubscriptionPricing__c = null,
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote.Id,
          SBQQ__Product__c = sampleProducts[11].Id,
          SBQQ__PricebookEntryId__c = entries[11].Id,
          SBQQ__Quantity__c = 20,
          SBQQ__SubscriptionPricing__c = null,
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote.Id,
          SBQQ__Product__c = sampleProducts[12].Id,
          SBQQ__PricebookEntryId__c = entries[12].Id,
          SBQQ__Quantity__c = 20,
          SBQQ__SubscriptionPricing__c = null,
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote.Id,
          SBQQ__Product__c = sampleProducts[13].Id,
          SBQQ__PricebookEntryId__c = entries[13].Id,
          SBQQ__Quantity__c = 20,
          SBQQ__SubscriptionPricing__c = null,
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote.Id,
          SBQQ__Product__c = sampleProducts[14].Id,
          SBQQ__PricebookEntryId__c = entries[14].Id,
          SBQQ__Quantity__c = 20,
          SBQQ__SubscriptionPricing__c = null,
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote.Id,
          SBQQ__Product__c = sampleProducts[15].Id,
          SBQQ__PricebookEntryId__c = entries[15].Id,
          SBQQ__Quantity__c = 20,
          SBQQ__SubscriptionPricing__c = null,
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          SBQQ__StartDate__c = System.today(),
          SBQQ__EndDate__c = System.today().addMonths(3).addDays(-1)
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote.Id,
          SBQQ__Product__c = sampleProducts[16].Id,
          SBQQ__PricebookEntryId__c = entries[16].Id,
          SBQQ__Quantity__c = 2,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          SBQQ__StartDate__c = System.today(),
          SBQQ__EndDate__c = System.today().addMonths(3).addDays(-1)
        )
      ); //Licensev1 17
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote.Id,
          SBQQ__Product__c = sampleProducts[17].Id,
          SBQQ__PricebookEntryId__c = entries[17].Id,
          SBQQ__Quantity__c = 2,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          SBQQ__StartDate__c = System.today(),
          SBQQ__EndDate__c = System.today().addMonths(3).addDays(-1)
        )
      ); //HW Supportv1 18
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote.Id,
          SBQQ__Product__c = sampleProducts[6].Id,
          SBQQ__PricebookEntryId__c = entries[6].Id,
          MSP_Segment_Product__c = true,
          SBQQ__Quantity__c = 2,
          SBQQ__Segmentindex__c = 1,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          Usable_Capacity__c = sampleProducts[6].Usable_Capacity__c
        )
      ); //HW v1 19

            insert lines;
            
            lines[0].SBQQ__Bundle__c = true;
            lines[1].SBQQ__RequiredBy__c = lines[0].Id;
            lines[2].SBQQ__RequiredBy__c = lines[1].Id;
            lines[3].SBQQ__RequiredBy__c = lines[0].Id;
            lines[4].SBQQ__RequiredBy__c = lines[1].Id;
            lines[5].SBQQ__RequiredBy__c = lines[0].Id;
            lines[10].SBQQ__RequiredBy__c = lines[1].Id;
            lines[11].SBQQ__RequiredBy__c = lines[1].Id;
            lines[12].SBQQ__RequiredBy__c = lines[1].Id;
        lines[9].SBQQ__RequiredBy__c = lines[12].Id;
        lines[14].SBQQ__RequiredBy__c = lines[13].Id;
        lines[15].SBQQ__RequiredBy__c = lines[12].Id;
            lines[17].SBQQ__RequiredBy__c = lines[19].Id;
            lines[18].SBQQ__RequiredBy__c = lines[19].Id;

            update lines;
            
            quote.ApprovalStatus__c = 'Approved';
            update quote;
            
            Order orderInstanceNew = new Order();
            orderInstanceNew.AccountId = customer.Id;
            orderInstanceNew.OpportunityId = opp.Id;
            orderInstanceNew.EffectiveDate = system.today();  
            orderInstanceNew.Status = 'Draft';
            orderInstanceNew.Type = 'Revenue';
            orderInstanceNew.Order_Status__c = 'Pending'; 
      orderInstanceNew.Status = 'Draft';
            //orderInstanceNew.Program__c = 'Refresh';
            orderInstanceNew.Pricebook2Id = Test.getStandardPricebookId(); 
            insert orderInstanceNew;
      Order ordNew = orderInstanceNew.clone();
      ordNew.EffectiveDate = Date.newInstance(2023, 6, 2);
      ordNew.Order_Sub_Type__c = 'Renewal';
            //ordNew.SBQQ__Quote__c=quote2.Id;
            insert ordNew;
      Order ordNew1 = orderInstanceNew.clone();
      ordNew1.EffectiveDate = Date.newInstance(2023, 6, 2);
      ordNew1.Order_Sub_Type__c = 'Renewal';
          //  ordNew1.SBQQ__Quote__c=quote2.Id;
            insert ordNew1;
            
      Order phantomORD = orderInstanceNew.clone();
      phantomORD.EffectiveDate = Date.newInstance(2023, 6, 2);
      phantomORD.recordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Phantom Order').getRecordTypeId();      
      phantomORD.Type = 'Revenue Internal';
      insert phantomORD;

            List<OrderItem> orderItemList = new List<OrderItem>{
        new OrderItem(
          OrderId = orderInstanceNew.Id,
          Product2Id = sampleProducts[0].Id,
          SerialNumber__c = '09092019APMSP1250',
          UnitPrice = entries[0].UnitPrice,
          SBQQ__QuoteLine__c = lines[0].Id,
          SBQQ__SubscriptionTerm__c = 36,
          Quantity = 70,
          PricebookEntryId = entries[0].Id
        ),
        new OrderItem(
          OrderId = orderInstanceNew.Id,
          Product2Id = sampleProducts[4].Id,
          SerialNumber__c = '09092019APMSP1250',
          UnitPrice = entries[4].UnitPrice,
          SBQQ__QuoteLine__c = lines[4].Id,
          SBQQ__SubscriptionTerm__c = 36,
          Quantity = 1,
          PricebookEntryId = entries[4].Id
        ),
        new OrderItem(
          OrderId = orderInstanceNew.Id,
          Product2Id = sampleProducts[5].Id,
          UnitPrice = entries[5].UnitPrice,
          SBQQ__QuoteLine__c = lines[5].Id,
          SBQQ__SubscriptionTerm__c = 36,
          Quantity = 20,
          PricebookEntryId = entries[5].Id
        ),
        new OrderItem(
          OrderId = orderInstanceNew.Id,
          Product2Id = sampleProducts[6].Id,
          SerialNumber__c = '09092019APMSP1250',
          UnitPrice = entries[6].UnitPrice,
          SBQQ__QuoteLine__c = lines[6].Id,
          SBQQ__SubscriptionTerm__c = 36,
          Quantity = 1,
          PricebookEntryId = entries[6].Id
        ),
        new OrderItem(
          OrderId = orderInstanceNew.Id,
          Product2Id = sampleProducts[7].Id,
          UnitPrice = entries[7].UnitPrice,
          SBQQ__QuoteLine__c = lines[7].Id,
          SBQQ__SubscriptionTerm__c = 36,
          Quantity = 1,
          PricebookEntryId = entries[6].Id,
          Program__c = 'Replaced'
        ),
        new OrderItem(
          OrderId = orderInstanceNew.Id,
          Product2Id = sampleProducts[2].Id,
          UnitPrice = entries[2].UnitPrice,
          SBQQ__QuoteLine__c = lines[2].Id,
          SBQQ__SubscriptionTerm__c = 36,
          Quantity = 70,
          PricebookEntryId = entries[2].Id
        ),
        new OrderItem(
          OrderId = orderInstanceNew.Id,
          Product2Id = sampleProducts[10].Id,
          UnitPrice = entries[10].UnitPrice,
          SBQQ__QuoteLine__c = lines[10].Id,
          SBQQ__SubscriptionTerm__c = 36,
          Quantity = 70,
          PricebookEntryId = entries[10].Id
        ),
        new OrderItem(
          OrderId = orderInstanceNew.Id,
          Product2Id = sampleProducts[10].Id,
          UnitPrice = entries[10].UnitPrice,
          SBQQ__QuoteLine__c = lines[11].Id,
          SBQQ__SubscriptionTerm__c = 36,
          Quantity = 70,
          PricebookEntryId = entries[10].Id
        ),
        new OrderItem(
          OrderId = orderInstanceNew.Id,
          Product2Id = sampleProducts[11].Id,
          UnitPrice = entries[10].UnitPrice,
          SBQQ__QuoteLine__c = lines[12].Id,
          SBQQ__SubscriptionTerm__c = 36,
          Quantity = 70,
          PricebookEntryId = entries[11].Id
        ),
        new OrderItem(
          OrderId = orderInstanceNew.Id,
          Product2Id = sampleProducts[9].Id,
          UnitPrice = entries[9].UnitPrice,
          SBQQ__QuoteLine__c = lines[9].Id,
          SBQQ__SubscriptionTerm__c = 36,
          Quantity = 70,
          PricebookEntryId = entries[9].Id
        ),
        new OrderItem(
          OrderId = orderInstanceNew.Id,
          Product2Id = sampleProducts[12].Id,
          UnitPrice = entries[12].UnitPrice,
          SBQQ__QuoteLine__c = lines[12].Id,
          SBQQ__SubscriptionTerm__c = 36,
          Quantity = 70,
          PricebookEntryId = entries[12].Id
        ),
        new OrderItem(
          OrderId = orderInstanceNew.Id,
          Product2Id = sampleProducts[13].Id,
          UnitPrice = entries[13].UnitPrice,
          SBQQ__QuoteLine__c = lines[13].Id,
          SBQQ__SubscriptionTerm__c = 36,
          Quantity = 70,
          PricebookEntryId = entries[13].Id
        ),
        new OrderItem(
          OrderId = orderInstanceNew.Id,
          Product2Id = sampleProducts[14].Id,
          UnitPrice = entries[14].UnitPrice,
          SBQQ__QuoteLine__c = lines[14].Id,
          SBQQ__SubscriptionTerm__c = 36,
          Quantity = 70,
          PricebookEntryId = entries[14].Id
        ),
        new OrderItem(
          OrderId = orderInstanceNew.Id,
          Product2Id = sampleProducts[15].Id,
          UnitPrice = entries[15].UnitPrice,
          SBQQ__QuoteLine__c = lines[15].Id,
          SBQQ__SubscriptionTerm__c = 36,
          Quantity = 70,
          PricebookEntryId = entries[15].Id
        ),
        new OrderItem(
          OrderId = orderInstanceNew.Id,
          Product2Id = sampleProducts[15].Id,
          UnitPrice = entries[15].UnitPrice,
          SBQQ__QuoteLine__c = lines[15].Id,
          SBQQ__SubscriptionTerm__c = 36,
          Quantity = 70,
          PricebookEntryId = entries[15].Id
        ),
        new OrderItem(
          OrderId = orderInstanceNew.Id,
          Product2Id = sampleProducts[15].Id,
          UnitPrice = entries[15].UnitPrice,
          SBQQ__QuoteLine__c = lines[15].Id,
          SBQQ__SubscriptionTerm__c = 36,
          Quantity = 70,
          PricebookEntryId = entries[15].Id
        ),
        new OrderItem(
          OrderId = orderInstanceNew.Id,
          Product2Id = sampleProducts[16].Id,
          UnitPrice = entries[16].UnitPrice,
          SBQQ__QuoteLine__c = lines[17].Id,
          SBQQ__SubscriptionTerm__c = 1,
          Quantity = 2,
          PricebookEntryId = entries[16].Id
        ), //License v1 16
        new OrderItem(
          OrderId = orderInstanceNew.Id,
          Product2Id = sampleProducts[1].Id,
          UnitPrice = entries[1].UnitPrice,
          SBQQ__QuoteLine__c = lines[19].Id,
          SBQQ__SubscriptionTerm__c = 1,
          Quantity = 2,
          PricebookEntryId = entries[1].Id
        ), //Hw v1 17
        new OrderItem(
          OrderId = orderInstanceNew.Id,
          Product2Id = sampleProducts[17].Id,
          SerialNumber__c = '09092019APMSP1253, 09092019APMSP1254',
          UnitPrice = entries[17].UnitPrice,
          SBQQ__QuoteLine__c = lines[18].Id,
          SBQQ__SubscriptionTerm__c = 1,
          Quantity = 2,
          PricebookEntryId = entries[17].Id
        ), // Hw Support v1 18
          new OrderItem(
          OrderId = phantomORD.Id,
          Product2Id = sampleProducts[17].Id,
          SerialNumber__c = '09092019APMSP1253, 09092019APMSP1254',
          UnitPrice = 0,
          SBQQ__QuoteLine__c = lines[18].Id,
          SBQQ__SubscriptionTerm__c = 1,
          Quantity = 2,
          PricebookEntryId = entries[17].Id,
          Previous_Transaction_Reference__c = '{"phantomOrderItemId":"802VI000003YuB5YAK","orderItemId":"802VI000003YuB5YAK","entId":"550VI000007SEtnYAG"}'
        ),
        new OrderItem(
          OrderId = ordNew.Id,
          Product2Id = sampleProducts[0].Id,
          SerialNumber__c = '09092019APMSP1253, 09092019APMSP1254',
          UnitPrice = entries[17].UnitPrice,
          SBQQ__QuoteLine__c = lines[18].Id,
          SBQQ__SubscriptionTerm__c = 1,
          Quantity = 2,
          PricebookEntryId = entries[17].Id
        )
                };

            Test.startTest();
            /*
             * 0-License, 1-Hw Support, 2-RCDM, 3-HW
             * ***/
            insert orderItemList;
    
      ServiceContract objSC = new ServiceContract(
        Name = 'ServiceContractTest1',
        AccountId = customer.Id,
        StartDate = Date.today(),
        Term = 36,
        pricebook2Id = Test.getStandardPricebookId(),
        SBQQSC__Opportunity__c = opp.Id,
        SBQQSC__Order__c = orderInstanceNew.Id,
        SBQQSC__Quote__c = quote.Id
      );
            
            insert objSC;
            List<ContractLineItem> lstCli = new List<ContractLineItem>{
        new ContractLineItem(
          SBQQSC__OrderProduct__c = orderItemList[0].Id,
          Quantity = orderItemList[0].quantity,
          SBQQSC__QuoteLine__c = orderItemList[0].SBQQ__QuoteLine__c,
          SBQQSC__Product__c = orderItemList[0].Product2Id,
          PricebookEntryId = orderItemList[0].PricebookEntryId,
          ServiceContractId = objSC.Id,
          UnitPrice = orderItemList[0].UnitPrice,
          StartDate = date.today()
        ),
        new ContractLineItem(
          SBQQSC__OrderProduct__c = orderItemList[1].Id,
          Quantity = orderItemList[1].quantity,
          SBQQSC__QuoteLine__c = orderItemList[1].SBQQ__QuoteLine__c,
          SBQQSC__Product__c = orderItemList[1].Product2Id,
          PricebookEntryId = orderItemList[1].PricebookEntryId,
          ServiceContractId = objSC.Id,
          UnitPrice = orderItemList[1].UnitPrice,
          StartDate = date.today()
        ),
        new ContractLineItem(
          SBQQSC__OrderProduct__c = orderItemList[2].Id,
          Quantity = orderItemList[2].quantity,
          SBQQSC__QuoteLine__c = orderItemList[2].SBQQ__QuoteLine__c,
          SBQQSC__Product__c = orderItemList[2].Product2Id,
          PricebookEntryId = orderItemList[2].PricebookEntryId,
          ServiceContractId = objSC.Id,
          UnitPrice = orderItemList[2].UnitPrice,
          StartDate = date.today()
        ),
        new ContractLineItem(
          SBQQSC__OrderProduct__c = orderItemList[5].Id,
          Quantity = orderItemList[5].quantity,
          SBQQSC__QuoteLine__c = orderItemList[5].SBQQ__QuoteLine__c,
          SBQQSC__Product__c = orderItemList[5].Product2Id,
          PricebookEntryId = orderItemList[5].PricebookEntryId,
          ServiceContractId = objSC.Id,
          UnitPrice = orderItemList[5].UnitPrice,
          StartDate = date.today()
        ),
        new ContractLineItem(
          SBQQSC__OrderProduct__c = orderItemList[6].Id,
          Quantity = orderItemList[6].quantity,
          SBQQSC__QuoteLine__c = orderItemList[6].SBQQ__QuoteLine__c,
          SBQQSC__Product__c = orderItemList[6].Product2Id,
          PricebookEntryId = orderItemList[6].PricebookEntryId,
          ServiceContractId = objSC.Id,
          UnitPrice = orderItemList[6].UnitPrice,
          StartDate = date.today()
        ),
        new ContractLineItem(
          SBQQSC__OrderProduct__c = orderItemList[7].Id,
          Quantity = orderItemList[7].quantity,
          SBQQSC__QuoteLine__c = orderItemList[7].SBQQ__QuoteLine__c,
          SBQQSC__Product__c = orderItemList[7].Product2Id,
          PricebookEntryId = orderItemList[7].PricebookEntryId,
          ServiceContractId = objSC.Id,
          UnitPrice = orderItemList[7].UnitPrice,
          StartDate = date.today()
        ),
        new ContractLineItem(
          SBQQSC__OrderProduct__c = orderItemList[8].Id,
          Quantity = orderItemList[8].quantity,
          SBQQSC__QuoteLine__c = orderItemList[8].SBQQ__QuoteLine__c,
          SBQQSC__Product__c = orderItemList[8].Product2Id,
          PricebookEntryId = orderItemList[8].PricebookEntryId,
          ServiceContractId = objSC.Id,
          UnitPrice = orderItemList[8].UnitPrice,
          StartDate = date.today()
        ),
        new ContractLineItem(
          SBQQSC__OrderProduct__c = orderItemList[9].Id,
          Quantity = orderItemList[9].quantity,
          SBQQSC__QuoteLine__c = orderItemList[9].SBQQ__QuoteLine__c,
          SBQQSC__Product__c = orderItemList[9].Product2Id,
          PricebookEntryId = orderItemList[9].PricebookEntryId,
          ServiceContractId = objSC.Id,
          UnitPrice = orderItemList[9].UnitPrice,
          StartDate = date.today()
        ),
        new ContractLineItem(
          SBQQSC__OrderProduct__c = orderItemList[10].Id,
          Quantity = orderItemList[10].quantity,
          SBQQSC__QuoteLine__c = orderItemList[10].SBQQ__QuoteLine__c,
          SBQQSC__Product__c = orderItemList[10].Product2Id,
          PricebookEntryId = orderItemList[10].PricebookEntryId,
          ServiceContractId = objSC.Id,
          UnitPrice = orderItemList[10].UnitPrice,
          StartDate = date.today()
        ),
        new ContractLineItem(
          SBQQSC__OrderProduct__c = orderItemList[11].Id,
          Quantity = orderItemList[11].quantity,
          SBQQSC__QuoteLine__c = orderItemList[11].SBQQ__QuoteLine__c,
          SBQQSC__Product__c = orderItemList[11].Product2Id,
          PricebookEntryId = orderItemList[11].PricebookEntryId,
          ServiceContractId = objSC.Id,
          UnitPrice = orderItemList[11].UnitPrice,
          StartDate = date.today()
        ),
        new ContractLineItem(
          SBQQSC__OrderProduct__c = orderItemList[12].Id,
          Quantity = orderItemList[12].quantity,
          SBQQSC__QuoteLine__c = orderItemList[12].SBQQ__QuoteLine__c,
          SBQQSC__Product__c = orderItemList[12].Product2Id,
          PricebookEntryId = orderItemList[12].PricebookEntryId,
          ServiceContractId = objSC.Id,
          UnitPrice = orderItemList[12].UnitPrice,
          StartDate = date.today()
        ),
        new ContractLineItem(
          SBQQSC__OrderProduct__c = orderItemList[13].Id,
          Quantity = orderItemList[13].quantity,
          SBQQSC__QuoteLine__c = orderItemList[13].SBQQ__QuoteLine__c,
          SBQQSC__Product__c = orderItemList[13].Product2Id,
          PricebookEntryId = orderItemList[13].PricebookEntryId,
          ServiceContractId = objSC.Id,
          UnitPrice = orderItemList[13].UnitPrice,
          StartDate = date.today()
        ),
        new ContractLineItem(
          SBQQSC__OrderProduct__c = orderItemList[16].Id,
          SBQQSC__RenewalQuantity__c = orderItemList[16].quantity,
          Quantity = orderItemList[16].quantity,
          SBQQSC__QuoteLine__c = orderItemList[16].SBQQ__QuoteLine__c,
          SBQQSC__Product__c = orderItemList[16].Product2Id,
          PricebookEntryId = orderItemList[16].PricebookEntryId,
          ServiceContractId = objSC.Id,
          UnitPrice = orderItemList[16].UnitPrice,
          StartDate = date.today().addDays(-80)
        ), //12 - license
        new ContractLineItem(
          SBQQSC__OrderProduct__c = orderItemList[18].Id,
          SBQQSC__RenewalQuantity__c = orderItemList[18].quantity,
          Quantity = orderItemList[18].quantity,
          SBQQSC__QuoteLine__c = orderItemList[18].SBQQ__QuoteLine__c,
          SBQQSC__Product__c = orderItemList[18].Product2Id,
          PricebookEntryId = orderItemList[18].PricebookEntryId,
          ServiceContractId = objSC.Id,
          UnitPrice = orderItemList[18].UnitPrice,
          StartDate = date.today().addDays(-80)
        ) //13- HW suppo
            }; 
                        
                        insert lstCli;
            orderItemList[0].SBQQSC__ContractLineItem__c = lstCli[0].Id;
            orderItemList[1].SBQQSC__ContractLineItem__c = lstCli[1].Id;
            orderItemList[2].SBQQSC__ContractLineItem__c = lstCli[2].Id;
            orderItemList[5].SBQQSC__ContractLineItem__c = lstCli[3].Id;
            orderItemList[6].SBQQSC__ContractLineItem__c = lstCli[4].Id;
            orderItemList[7].SBQQSC__ContractLineItem__c = lstCli[5].Id;
            orderItemList[8].SBQQSC__ContractLineItem__c = lstCli[6].Id;
            orderItemList[9].SBQQSC__ContractLineItem__c = lstCli[7].Id;
            orderItemList[10].SBQQSC__ContractLineItem__c = lstCli[8].Id;
            orderItemList[11].SBQQSC__ContractLineItem__c = lstCli[9].Id;
            orderItemList[12].SBQQSC__ContractLineItem__c = lstCli[10].Id;
            orderItemList[16].SBQQSC__ContractLineItem__c = lstCli[12].Id;
            orderItemList[18].SBQQSC__ContractLineItem__c = lstCli[13].Id;
            orderItemList[2].SBQQ__RequiredBy__c = orderItemList[0].Id;
            orderItemList[16].SBQQ__RequiredBy__c = orderItemList[17].Id;
            orderItemList[18].SBQQ__RequiredBy__c = orderItemList[17].Id;
            update orderItemList;
            Test.stopTest();
            Id supportRecordTypeId = Schema.SObjectType.Entitlement.getRecordTypeInfosByName().get('Support').getRecordTypeId();
            
      List<Entitlement> lstEntitlement = new List<Entitlement>{
        new Entitlement(
          Name = 'Ent Test 1',
          RecordTypeId = supportRecordTypeId,
          Type = 'Phone Support',
          AccountId = customer.Id,
          Product__c = sampleProducts[0].Id,
          StartDate = date.today(),
          ServiceContractId = objSC.Id,
          ContractLineItemId = lstCli[0].Id,
          Order_Service_Item__c = orderItemList[0].id
        ),
        new Entitlement(
          Name = 'Ent Test 2',
          RecordTypeId = supportRecordTypeId,
          Type = 'Phone Support',
          AccountId = customer.Id,
          Product__c = sampleProducts[4].Id,
          StartDate = date.today(),
          AssetId = assestIns[0].Id,
          ServiceContractId = objSC.Id,
          ContractLineItemId = lstCli[1].Id,
          Order_Service_Item__c = orderItemList[1].Id
        ),
        new Entitlement(
          Name = sampleProducts[5].ProductCode,
          RecordTypeId = supportRecordTypeId,
          Type = 'Phone Support',
          AccountId = customer.Id,
          Product__c = sampleProducts[5].Id,
          StartDate = date.today(),
          ServiceContractId = objSC.Id,
          ContractLineItemId = lstCli[2].Id,
          Order_Service_Item__c = orderItemList[2].Id
        ),
        new Entitlement(
          Name = sampleProducts[2].ProductCode,
          RecordTypeId = supportRecordTypeId,
          Type = 'Phone Support',
          AccountId = customer.Id,
          Product__c = sampleProducts[2].Id,
          StartDate = date.today(),
          ServiceContractId = objSC.Id,
          ContractLineItemId = lstCli[3].Id,
          Order_Service_Item__c = orderItemList[5].Id
        ),
        new Entitlement(
          Name = sampleProducts[10].ProductCode,
          RecordTypeId = supportRecordTypeId,
          Type = 'Phone Support',
          AccountId = customer.Id,
          Product__c = sampleProducts[10].Id,
          StartDate = date.today(),
          ServiceContractId = objSC.Id,
          AssetId = assestIns[0].Id,
          ContractLineItemId = lstCli[4].Id,
          Order_Service_Item__c = orderItemList[6].Id
        ),
        new Entitlement(
          Name = sampleProducts[10].ProductCode,
          RecordTypeId = supportRecordTypeId,
          Type = 'Phone Support',
          AccountId = customer.Id,
          Product__c = sampleProducts[11].Id,
          StartDate = date.today(),
          ServiceContractId = objSC.Id,
          ContractLineItemId = lstCli[5].Id,
          Order_Service_Item__c = orderItemList[7].Id
        ),
        new Entitlement(
          Name = sampleProducts[11].ProductCode,
          RecordTypeId = supportRecordTypeId,
          Type = 'Phone Support',
          AccountId = customer.Id,
          Product__c = sampleProducts[11].Id,
          StartDate = date.today(),
          ServiceContractId = objSC.Id,
          ContractLineItemId = lstCli[6].Id,
          Order_Service_Item__c = orderItemList[8].Id
        ),
        new Entitlement(
          Name = sampleProducts[14].ProductCode,
          RecordTypeId = supportRecordTypeId,
          Type = 'Phone Support',
          AccountId = customer.Id,
          Product__c = sampleProducts[14].Id,
          StartDate = date.today(),
          ServiceContractId = objSC.Id,
          ContractLineItemId = lstCli[11].Id,
          Order_Service_Item__c = orderItemList[13].Id
        ),
        new Entitlement(
          Name = sampleProducts[16].ProductCode,
          RecordTypeId = supportRecordTypeId,
          Type = 'Phone Support',
          AccountId = customer.Id,
          Product__c = sampleProducts[16].Id,
          StartDate = date.today(),
          ServiceContractId = objSC.Id,
          ContractLineItemId = lstCli[12].Id,
          Order_Service_Item__c = orderItemList[16].Id,
          AssetId = assestIns[1].Id
        ), //license addon
        new Entitlement(
          Name = sampleProducts[16].ProductCode,
          RecordTypeId = supportRecordTypeId,
          Type = 'Phone Support',
          AccountId = customer.Id,
          Product__c = sampleProducts[16].Id,
          StartDate = date.today(),
          ServiceContractId = objSC.Id,
          ContractLineItemId = lstCli[12].Id,
          Order_Service_Item__c = orderItemList[16].Id
        ), //license addon
        new Entitlement(
          Name = sampleProducts[17].ProductCode,
          RecordTypeId = supportRecordTypeId,
          Type = 'Phone Support',
          AccountId = customer.Id,
          Product__c = sampleProducts[17].Id,
          StartDate = date.today(),
          ServiceContractId = objSC.Id,
          ContractLineItemId = lstCli[13].Id,
          Order_Service_Item__c = orderItemList[18].Id,
          AssetId = assestIns[1].Id
        ), //Hw Support addon
        new Entitlement(
          Name = sampleProducts[17].ProductCode,
          RecordTypeId = supportRecordTypeId,
          Type = 'Phone Support',
          AccountId = customer.Id,
          Product__c = sampleProducts[17].Id,
          StartDate = date.today(),
          ServiceContractId = objSC.Id,
          ContractLineItemId = lstCli[13].Id,
          Order_Service_Item__c = orderItemList[18].Id
        ) //Hw Support addon
                    };
                   insert lstEntitlement; 
        }
    }
    
    @isTest
  static void renewalConversionMethod() {
    List<user> usr = [SELECT Id FROM User WHERE email = 'testuser@testclass.com.invalid'];
        System.runAs(usr[1]) {
          //  insert new ShGl_DisableFunctionalityLogic__c(setupOwnerId = UserInfo.getUserId(), Disable_Account_Old_Trigger__c = TRUE);
      insert new ShGl_DisableBusinessLogic__c(
        setupownerid = userinfo.getUserId(),
                                                    Disable_Entitlement_Validation_Rules__c = true,
        Disable_Account_Triggers__c = true,
        Disable_Asset_Triggers__c = true,
        Disable_SBQQ_Quote_Triggers__c = true,
                                                    Disable_Product2_Validation_Rules__c = true,
        Disable_SBQQ_QuoteLine_Triggers__c = true,
        Disable_Order_Old_Trigger__c = true,
        Disable_OrderItem_Old_Trigger__c = true,
        Disable_Opportunity_Triggers__c = true,
                                                    Disable_Order_Validation_Rules__c = true,
        Disable_SBQQ_QuoteLine_Validation_Rules__c = true
      );
            TriggerControl.stopOrderItemTrigger = true;
            TriggerControl.stopOrderTrigger = true;
            
            Test.startTest();
       
        List<Account> lstAccount1 = [SELECT Id FROM Account LIMIT 1];
      List<Asset> lstAsset = [SELECT Id, SerialNumber FROM Asset WHERE SerialNumber = '09092019APMSP1250'];
         Opportunity opp3 = TestDataFactory.getOpportunity();
            opp3.Partner_Lookup__c = lstAccount1[0].Id;
            opp3.AccountId = lstAccount1[0].Id;
            opp3.Distributor_Lookup__c = opp3.AccountId;
            opp3.Pricebook2id = Test.getStandardPricebookId();
            insert opp3;
      Entitlement entRec = [SELECT id FROM Entitlement LIMIT 1];
            
      SBQQ__Quote__c quoteObjNew = new SBQQ__Quote__c(
        SBQQ__Opportunity2__c = opp3.Id,
        SBQQ__SubscriptionTerm__c = 12,
        Is_RWD_Polaris_Quote__c = true,
        SBQQ__Primary__c = true,
        ApprovalStatus__c = 'Recalled',
        SBQQ__Type__c = 'Renewal+Expansion',
        SBQQ__PriceBook__c = Test.getStandardPricebookId()
      );
            insert quoteObjNew;
            List<Product2> sampleProducts2 = [SELECT Id, ProductCode FROM Product2 LIMIT 12];
            List<PricebookEntry> entries = [SELECT Id, UnitPrice FROM PricebookEntry LIMIT 12];
      List<SBQQ__QuoteLine__c> lines10 = new List<SBQQ__QuoteLine__c>();
      lines10.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quoteObjNew.Id,
          SBQQ__Product__c = sampleProducts2[0].Id,
          SBQQ__PricebookEntryId__c = entries[0].Id,
          MSP_Segment_Product__c = true,
          SBQQ__Quantity__c = 70,
          SBQQ__Segmentindex__c = 1,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          Disposition_Reason__c = 'Renewing',
          Special_Program__c = 'Conversion'
        )
      );
      lines10.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quoteObjNew.Id,
          SBQQ__Product__c = sampleProducts2[6].Id,
          SBQQ__PricebookEntryId__c = entries[6].Id,
          MSP_Segment_Product__c = true,
          SBQQ__Quantity__c = 1,
          SBQQ__Segmentindex__c = 1,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          SBQQ__Existing__c = true
        )
      );
      lines10.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quoteObjNew.Id,
          SBQQ__Product__c = sampleProducts2[4].Id,
          SBQQ__PricebookEntryId__c = entries[4].Id,
          MSP_Segment_Product__c = true,
          SBQQ__Quantity__c = 1,
          SBQQ__Segmentindex__c = 1,
          SBQQ__Renewal__c = true,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          Disposition_Reason__c = 'Renewing',
          Special_Program__c = 'Conversion'
        )
      );
      lines10.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quoteObjNew.Id,
          SBQQ__Product__c = sampleProducts2[5].Id,
          SBQQ__PricebookEntryId__c = entries[5].Id,
          SBQQ__Quantity__c = 42,
          SBQQ__SubscriptionPricing__c = null,
          SBQQ__StartDate__c = System.today().addMonths(4).addDays(-6),
          SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1),
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200
        )
      );
            insert lines10;
            
            Product2 prod = new Product2(Id = sampleProducts2[4].Id, Upgrade_Path__c = 'Foundation to Enterprise');
            update prod;
            List<Product2> sampleProductslistupd = new List<Product2>();
      for (Product2 pd : sampleProducts2) {
        pd.Custom_Renewal_Attributes__c = '{"RCVProd":"' + pd.id + '", "RCVProdPricebook":"01u6f00000JkJEVAA3", "RCVProdOption":"a6LVI0000000lwf2AA", "RCVQuantRatio":3}';
                sampleProductslistupd.add(pd);
            }
            update sampleProductslistupd;  
            List<ContractLineItem> lstContractLineItems  = [SELECT Id FROM ContractLineItem Limit 7]; 
            lines10[0].SBQQ__Bundle__c = true;
            lines10[0].Arroyo_Subscribed_Asset_Name__c = lstAsset[0].SerialNumber;
            lines10[0].Disposition_Reason__c = 'Converted';
            lines10[0].Arroyo_Subsumed_Old_Contract_Line_Items__c = lstContractLineItems[0].Id;
            lines10[1].SBQQ__RequiredBy__c = lines10[0].Id;   
            lines10[2].SBQQ__RequiredBy__c = lines10[1].Id;
            lines10[2].Arroyo_Subscribed_Asset_Name__c = lstAsset[0].SerialNumber;
            lines10[2].Disposition_Reason__c = 'Renewing';
      lines10[2].Arroyo_Subsumed_Old_Contract_Line_Items__c = lstContractLineItems[0].Id;
      lines10[2].Special_Program__c = 'Conversion';
            lines10[3].SBQQ__RequiredBy__c = lines10[0].Id;
            
            update lines10;
            
    quoteObjNew.ApprovalStatus__c = 'Approved';
    update quoteObjNew;
          
    Order orderInstance1 = new Order();
            orderInstance1.AccountId = lstAccount1[0].Id;
            orderInstance1.OpportunityId = opp3.Id;
            orderInstance1.EffectiveDate = system.today();  
            orderInstance1.Status = 'Draft';
            orderInstance1.Type = 'Revenue';
            orderInstance1.Order_Status__c = 'Pending'; 
            //orderInstance1.Program__c = 'Conversion';
            orderInstance1.Order_Sub_type__c = 'Renewal'; 
            orderInstance1.Pricebook2Id = Test.getStandardPricebookId(); 
            orderInstance1.SC_or_Entitlement_Stage__c = Constants.SC_ENT_STAGE_CREATE_SERVICE_CONTRACT;
            insert orderInstance1;
            
            List<OrderItem> orderItemList = new List<OrderItem>{
        new OrderItem(
          OrderId = orderInstance1.Id,
          Previous_Contract_Line_Items__c = lstContractLineItems[0].Id + ',' + lstContractLineItems[4].Id,
          Product2Id = sampleProducts2[0].Id,
          Upgraded_From__c = '09092019APMSP1250',
          SerialNumber__c = '09092019APMSP1250',
          UnitPrice = entries[0].UnitPrice,
          SBQQ__QuoteLine__c = lines10[0].Id,
          SBQQ__SubscriptionTerm__c = 36,
          SBQQ__Segmentindex__c = 2,
          Support_Start_Date__c = System.today(),
          Program__c = 'Conversion',
          Quantity = 20,
          PricebookEntryId = entries[0].Id
        ),
        new OrderItem(
          OrderId = orderInstance1.Id,
          Previous_Contract_Line_Items__c = lstContractLineItems[3].Id,
          Entitlement_Id__c = String.valueof(entRec.id),
          Product2Id = sampleProducts2[4].Id,
          Upgraded_From__c = '09092019APMSP1250',
          SerialNumber__c = '09092019APMSP1250',
          UnitPrice = entries[4].UnitPrice,
          SBQQ__QuoteLine__c = lines10[2].Id,
          SBQQ__SubscriptionTerm__c = 36,
          SBQQ__Segmentindex__c = 2,
          Support_Start_Date__c = System.today(),
          Program__c = 'Conversion',
          Quantity = 20,
          PricebookEntryId = entries[4].Id
        ),
        new OrderItem(
          OrderId = orderInstance1.Id,
          TPH_Quantity__c = '1',
          Previous_Contract_Line_Items__c = lstContractLineItems[5].Id,
          Product2Id = sampleProducts2[0].Id,
          UnitPrice = entries[0].UnitPrice,
          SBQQ__QuoteLine__c = lines10[0].Id,
          SBQQ__SubscriptionTerm__c = 36,
          SBQQ__Segmentindex__c = 2,
          Support_Start_Date__c = System.today(),
          Program__c = 'Conversion',
          Quantity = 20,
          PricebookEntryId = entries[0].Id
        ),
        new OrderItem(
          OrderId = orderInstance1.Id,
          Previous_Contract_Line_Items__c = lstContractLineItems[6].Id,
          Product2Id = sampleProducts2[0].Id,
          UnitPrice = entries[0].UnitPrice,
          SBQQ__QuoteLine__c = lines10[0].Id,
          SBQQ__SubscriptionTerm__c = 36,
          SBQQ__Segmentindex__c = 2,
          Support_Start_Date__c = System.today(),
          Program__c = 'Conversion',
          Quantity = 20,
          PricebookEntryId = entries[0].Id
        )
                };
           insert orderItemList;  
            
      List<String> lstOldCliIds = new List<String>{
        lstContractLineItems[0].Id,
        lstContractLineItems[3].Id,
        lstContractLineItems[4].Id,
        lstContractLineItems[5].Id,
        lstContractLineItems[6].Id
      };
                
      ServiceContract objSC = new ServiceContract(
        Name = 'ServiceContractTest2',
        AccountId = lstAccount1[0].Id,
        StartDate = Date.today(),
        Term = 36,
        pricebook2Id = Test.getStandardPricebookId(),
        SBQQSC__Opportunity__c = opp3.Id,
        SBQQSC__Order__c = orderInstance1.Id,
        SBQQSC__Quote__c = quoteObjNew.Id
      );
            
            insert objSC;
            
            List<ContractLineItem> lstCli = new List<ContractLineItem>{
        new ContractLineItem(
          Quantity = orderItemList[0].quantity,
          PricebookEntryId = orderItemList[0].PricebookEntryId,
          ServiceContractId = objSC.Id,
          UnitPrice = orderItemList[0].UnitPrice,
          StartDate = date.today()
        ),
        new ContractLineItem(
          Quantity = orderItemList[1].quantity,
          PricebookEntryId = orderItemList[1].PricebookEntryId,
          ServiceContractId = objSC.Id,
          UnitPrice = orderItemList[1].UnitPrice,
          StartDate = date.today()
        ),
        new ContractLineItem(
          Quantity = orderItemList[2].quantity,
          PricebookEntryId = orderItemList[2].PricebookEntryId,
          ServiceContractId = objSC.Id,
          UnitPrice = orderItemList[2].UnitPrice,
          StartDate = date.today()
        ),
        new ContractLineItem(
          Quantity = orderItemList[3].quantity,
          PricebookEntryId = orderItemList[3].PricebookEntryId,
          ServiceContractId = objSC.Id,
          UnitPrice = orderItemList[3].UnitPrice,
          StartDate = date.today()
        )
                    }; 
                        
                        insert lstCli;
            orderItemList[0].SBQQSC__ContractLineItem__c = lstCli[0].Id;
                        orderItemList[2].SBQQSC__ContractLineItem__c = lstCli[2].Id;

            update orderItemList;
            Id supportRecordTypeId = Schema.SObjectType.Entitlement.getRecordTypeInfosByName().get('Support').getRecordTypeId();
            
      List<Entitlement> lstEntitlement1 = new List<Entitlement>{
        new Entitlement(
          Name = sampleProducts2[4].ProductCode,
          RecordTypeId = supportRecordTypeId,
          Type = 'Phone Support',
          AccountId = lstAccount1[0].Id,
          Product__c = sampleProducts2[0].Id,
          StartDate = date.today(),
          AssetId = lstAsset[0].Id,
          ServiceContractId = objSC.Id,
          ContractLineItemId = lstCli[0].Id,
          Order_Service_Item__c = orderItemList[0].id
        ),
        new Entitlement(
          Name = sampleProducts2[4].ProductCode,
          RecordTypeId = supportRecordTypeId,
          Type = 'Phone Support',
          AccountId = lstAccount1[0].Id,
          Product__c = sampleProducts2[4].Id,
          StartDate = date.today(),
          AssetId = lstAsset[0].Id,
          ServiceContractId = objSC.Id,
          ContractLineItemId = lstCli[1].Id,
          Order_Service_Item__c = orderItemList[1].id
        ),
        new Entitlement(
          Name = sampleProducts2[4].ProductCode,
          RecordTypeId = supportRecordTypeId,
          Type = 'Phone Support',
          AccountId = lstAccount1[0].Id,
          Product__c = sampleProducts2[4].Id,
          StartDate = date.today(),
          ServiceContractId = objSC.Id,
          ContractLineItemId = lstCli[2].Id,
          Order_Service_Item__c = orderItemList[2].id
        ),
        new Entitlement(
          Name = sampleProducts2[4].ProductCode,
          RecordTypeId = supportRecordTypeId,
          Type = 'Phone Support',
          AccountId = lstAccount1[0].Id,
          Product__c = sampleProducts2[4].Id,
          StartDate = date.today(),
          ServiceContractId = objSC.Id,
          ContractLineItemId = lstCli[3].Id,
          Order_Service_Item__c = orderItemList[3].id
        )
                    };
                        insert lstEntitlement1; 
            List<String> lstNewEntitlementIds = new List<String>();
      for (Entitlement ojEnt : lstEntitlement1) {
                lstNewEntitlementIds.add(ojEnt.Id);
            }
            
            orderInstance1.SBQQ__Contracted__c = false;
            orderInstance1.Polaris_Fulfillment_Status__c = 'Completed';
            orderInstance1.Status = 'Activated';
            orderInstance1.Order_Status__c = 'Shipped';
            //orderInstance1.Program__c = 'Conversion';
            orderInstance1.SBQQ__Quote__c = quoteObjNew.Id;
      orderInstance1.Actual_Order_Ship_Date__c = System.today();
            orderInstance1.Welcome_letter_sent_for_the_first_time__c = true;
            
            update orderInstance1;
            
      ContractOrders conVersionMethod = new ContractOrders();
            System.schedule('Test_Contract_Orders_Conversion', '0 0 * * * ?', conVersionMethod);
            conVersionMethod.execute(null);      
            System.assertEquals(4, lstEntitlement1.size());
                       Test.stopTest();
        }
        
    }
    @istest
  static void renewalConversionMethod3() {
    List<user> usr = [SELECT Id FROM User WHERE email = 'testuser@testclass.com.invalid'];
    System.runAs(usr[1]) {
          //  insert new ShGl_DisableFunctionalityLogic__c(setupOwnerId = UserInfo.getUserId(), Disable_Account_Old_Trigger__c = TRUE);
      insert new ShGl_DisableBusinessLogic__c(
        setupownerid = userinfo.getUserId(),
                                                    Disable_Entitlement_Validation_Rules__c = true,
        Disable_Account_Triggers__c = true,
        Disable_Asset_Triggers__c = true,
        Disable_SBQQ_Quote_Triggers__c = true,
                                                    Disable_Product2_Validation_Rules__c = true,
        Disable_SBQQ_QuoteLine_Triggers__c = true,
        Disable_Order_Old_Trigger__c = true,
        Disable_OrderItem_Old_Trigger__c = true,
        Disable_Opportunity_Triggers__c = true,
                                                    Disable_Order_Validation_Rules__c = true,
        Disable_SBQQ_QuoteLine_Validation_Rules__c = true
      );
      TriggerControl.stopOrderItemTrigger = true;
      TriggerControl.stopOrderTrigger = true;

      Test.startTest();

      List<Account> lstAccount1 = [SELECT Id FROM Account LIMIT 1];
      List<Asset> lstAsset = [SELECT Id, SerialNumber FROM Asset WHERE SerialNumber = '09092019APMSP1250'];
      Opportunity opp3 = TestDataFactory.getOpportunity();
      opp3.Partner_Lookup__c = lstAccount1[0].Id;
      opp3.AccountId = lstAccount1[0].Id;
      opp3.Distributor_Lookup__c = opp3.AccountId;
      opp3.Pricebook2id = Test.getStandardPricebookId();
      insert opp3;
      Entitlement entRec = [SELECT id FROM Entitlement LIMIT 1];

      SBQQ__Quote__c quoteObjNew = new SBQQ__Quote__c(
        SBQQ__Opportunity2__c = opp3.Id,
        SBQQ__SubscriptionTerm__c = 12,
        Is_RWD_Polaris_Quote__c = true,
        SBQQ__Primary__c = true,
        ApprovalStatus__c = 'Recalled',
        SBQQ__Type__c = 'Renewal+Expansion',
        SBQQ__PriceBook__c = Test.getStandardPricebookId()
      );
      insert quoteObjNew;
      List<Product2> sampleProducts2 = [SELECT Id, ProductCode FROM Product2 LIMIT 12];
      List<PricebookEntry> entries = [SELECT Id, UnitPrice FROM PricebookEntry LIMIT 12];
      List<SBQQ__QuoteLine__c> lines10 = new List<SBQQ__QuoteLine__c>();
      lines10.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quoteObjNew.Id,
          SBQQ__Product__c = sampleProducts2[0].Id,
          SBQQ__PricebookEntryId__c = entries[0].Id,
          MSP_Segment_Product__c = true,
          SBQQ__Quantity__c = 70,
          SBQQ__Segmentindex__c = 1,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          Disposition_Reason__c = 'Renewing',
          Special_Program__c = 'Conversion'
        )
      );
      lines10.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quoteObjNew.Id,
          SBQQ__Product__c = sampleProducts2[6].Id,
          SBQQ__PricebookEntryId__c = entries[6].Id,
          MSP_Segment_Product__c = true,
          SBQQ__Quantity__c = 1,
          SBQQ__Segmentindex__c = 1,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          SBQQ__Existing__c = true
        )
      );
      lines10.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quoteObjNew.Id,
          SBQQ__Product__c = sampleProducts2[4].Id,
          SBQQ__PricebookEntryId__c = entries[4].Id,
          MSP_Segment_Product__c = true,
          SBQQ__Quantity__c = 1,
          SBQQ__Segmentindex__c = 1,
          SBQQ__Renewal__c = true,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          Disposition_Reason__c = 'Renewing',
          Special_Program__c = 'Conversion'
        )
      );
      lines10.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quoteObjNew.Id,
          SBQQ__Product__c = sampleProducts2[5].Id,
          SBQQ__PricebookEntryId__c = entries[5].Id,
          SBQQ__Quantity__c = 42,
          SBQQ__SubscriptionPricing__c = null,
          SBQQ__StartDate__c = System.today().addMonths(4).addDays(-6),
          SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1),
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200
        )
      );
      insert lines10;

      Product2 prod = new Product2(Id = sampleProducts2[4].Id, Upgrade_Path__c = 'Foundation to Enterprise');
      update prod;
      List<Product2> sampleProductslistupd = new List<Product2>();
      for (Product2 pd : sampleProducts2) {
        pd.Custom_Renewal_Attributes__c = '{"RCVProd":"' + pd.id + '", "RCVProdPricebook":"01u6f00000JkJEVAA3", "RCVProdOption":"a6LVI0000000lwf2AA", "RCVQuantRatio":3}';
        sampleProductslistupd.add(pd);
      }
      update sampleProductslistupd;
      List<ContractLineItem> lstContractLineItems = [SELECT Id FROM ContractLineItem LIMIT 7];
      lines10[0].SBQQ__Bundle__c = true;
      lines10[0].Arroyo_Subscribed_Asset_Name__c = lstAsset[0].SerialNumber;
      lines10[0].Disposition_Reason__c = 'Converted';
      lines10[0].Arroyo_Subsumed_Old_Contract_Line_Items__c = lstContractLineItems[0].Id;
      lines10[1].SBQQ__RequiredBy__c = lines10[0].Id;
      lines10[2].SBQQ__RequiredBy__c = lines10[1].Id;
      lines10[2].Arroyo_Subscribed_Asset_Name__c = lstAsset[0].SerialNumber;
      lines10[2].Disposition_Reason__c = 'Renewing';
      lines10[2].Arroyo_Subsumed_Old_Contract_Line_Items__c = lstContractLineItems[1].Id;
      lines10[3].SBQQ__RequiredBy__c = lines10[0].Id;

      update lines10;

      quoteObjNew.ApprovalStatus__c = 'Approved';
      update quoteObjNew;
      List<Order> OrderListUp = new List<Order>();
      for (Order o : [SELECT id FROM order]) {
        o.Is_RWD_Polaris_Quote__c = false;
        OrderListUp.add(o);
      }
      update OrderListUp;
      Order orderInstance1 = new Order();
      orderInstance1.AccountId = lstAccount1[0].Id;
      orderInstance1.OpportunityId = opp3.Id;
      orderInstance1.EffectiveDate = system.today();
      orderInstance1.Status = 'Draft';
      orderInstance1.Type = 'Revenue';
      orderInstance1.Order_Status__c = 'Pending';
      //orderInstance1.Program__c = 'Conversion';
      orderInstance1.Order_Sub_type__c = 'Renewal';
      orderInstance1.Is_RWD_Polaris_Quote__c = true;
      orderInstance1.Pricebook2Id = Test.getStandardPricebookId();
      orderInstance1.SC_or_Entitlement_Stage__c = Constants.SC_ENT_STAGE_CREATE_SERVICE_CONTRACT;
      insert orderInstance1;

      List<OrderItem> orderItemList = new List<OrderItem>{
        new OrderItem(
          OrderId = orderInstance1.Id,
          Previous_Contract_Line_Items__c = lstContractLineItems[0].Id + ',' + lstContractLineItems[4].Id,
          Product2Id = sampleProducts2[0].Id,
          Upgraded_From__c = '09092019APMSP1250',
          SerialNumber__c = '09092019APMSP1250',
          UnitPrice = entries[0].UnitPrice,
          SBQQ__QuoteLine__c = lines10[0].Id,
          SBQQ__SubscriptionTerm__c = 36,
          SBQQ__Segmentindex__c = 2,
          Support_Start_Date__c = System.today(),
          Program__c = 'Conversion',
          Quantity = 20,
          PricebookEntryId = entries[0].Id
        ),
        new OrderItem(
          OrderId = orderInstance1.Id,
          Previous_Contract_Line_Items__c = lstContractLineItems[3].Id,
          Entitlement_Id__c = String.valueof(entRec.id),
          Product2Id = sampleProducts2[4].Id,
          Upgraded_From__c = '09092019APMSP1250',
          SerialNumber__c = '09092019APMSP1250',
          UnitPrice = entries[4].UnitPrice,
          SBQQ__QuoteLine__c = lines10[2].Id,
          SBQQ__SubscriptionTerm__c = 36,
          SBQQ__Segmentindex__c = 2,
          Support_Start_Date__c = System.today(),
          Program__c = 'Conversion',
          Quantity = 20,
          PricebookEntryId = entries[4].Id
        ),
        new OrderItem(
          OrderId = orderInstance1.Id,
          TPH_Quantity__c = '1',
          Previous_Contract_Line_Items__c = lstContractLineItems[5].Id,
          Product2Id = sampleProducts2[0].Id,
          UnitPrice = entries[0].UnitPrice,
          SBQQ__QuoteLine__c = lines10[0].Id,
          SBQQ__SubscriptionTerm__c = 36,
          SBQQ__Segmentindex__c = 2,
          Support_Start_Date__c = System.today(),
          Program__c = 'Conversion',
          Quantity = 20,
          PricebookEntryId = entries[0].Id
        ),
        new OrderItem(
          OrderId = orderInstance1.Id,
          Previous_Contract_Line_Items__c = lstContractLineItems[6].Id,
          Product2Id = sampleProducts2[0].Id,
          UnitPrice = entries[0].UnitPrice,
          SBQQ__QuoteLine__c = lines10[0].Id,
          SBQQ__SubscriptionTerm__c = 36,
          SBQQ__Segmentindex__c = 2,
          Support_Start_Date__c = System.today(),
          Program__c = 'Conversion',
          Quantity = 20,
          PricebookEntryId = entries[0].Id
        )
      };
      insert orderItemList;

      List<String> lstOldCliIds = new List<String>{
        lstContractLineItems[0].Id,
        lstContractLineItems[3].Id,
        lstContractLineItems[4].Id,
        lstContractLineItems[5].Id,
        lstContractLineItems[6].Id
      };

      ServiceContract objSC = new ServiceContract(
        Name = 'ServiceContractTest2',
        AccountId = lstAccount1[0].Id,
        StartDate = Date.today(),
        Term = 36,
        pricebook2Id = Test.getStandardPricebookId(),
        SBQQSC__Opportunity__c = opp3.Id,
        SBQQSC__Order__c = orderInstance1.Id,
        SBQQSC__Quote__c = quoteObjNew.Id
      );

      insert objSC;

      List<ContractLineItem> lstCli = new List<ContractLineItem>{
        new ContractLineItem(
          Quantity = orderItemList[0].quantity,
          PricebookEntryId = orderItemList[0].PricebookEntryId,
          ServiceContractId = objSC.Id,
          UnitPrice = orderItemList[0].UnitPrice,
          StartDate = date.today()
        ),
        new ContractLineItem(
          Quantity = orderItemList[1].quantity,
          PricebookEntryId = orderItemList[1].PricebookEntryId,
          ServiceContractId = objSC.Id,
          UnitPrice = orderItemList[1].UnitPrice,
          StartDate = date.today()
        ),
        new ContractLineItem(
          Quantity = orderItemList[2].quantity,
          PricebookEntryId = orderItemList[2].PricebookEntryId,
          ServiceContractId = objSC.Id,
          UnitPrice = orderItemList[2].UnitPrice,
          StartDate = date.today()
        ),
        new ContractLineItem(
          Quantity = orderItemList[3].quantity,
          PricebookEntryId = orderItemList[3].PricebookEntryId,
          ServiceContractId = objSC.Id,
          UnitPrice = orderItemList[3].UnitPrice,
          StartDate = date.today()
        )
      };

      insert lstCli;
      orderItemList[0].SBQQSC__ContractLineItem__c = lstCli[0].Id;
      orderItemList[2].SBQQSC__ContractLineItem__c = lstCli[2].Id;

      update orderItemList;
      Id supportRecordTypeId = Schema.SObjectType.Entitlement.getRecordTypeInfosByName().get('Support').getRecordTypeId();

      List<Entitlement> lstEntitlement1 = new List<Entitlement>{
        new Entitlement(
          Name = sampleProducts2[4].ProductCode,
          RecordTypeId = supportRecordTypeId,
          Type = 'Phone Support',
          AccountId = lstAccount1[0].Id,
          Product__c = sampleProducts2[0].Id,
          StartDate = date.today(),
          AssetId = lstAsset[0].Id,
          ServiceContractId = objSC.Id,
          ContractLineItemId = lstCli[0].Id,
          Order_Service_Item__c = orderItemList[0].id
        ),
        new Entitlement(
          Name = sampleProducts2[4].ProductCode,
          RecordTypeId = supportRecordTypeId,
          Type = 'Phone Support',
          AccountId = lstAccount1[0].Id,
          Product__c = sampleProducts2[4].Id,
          StartDate = date.today(),
          AssetId = lstAsset[0].Id,
          ServiceContractId = objSC.Id,
          ContractLineItemId = lstCli[1].Id,
          Order_Service_Item__c = orderItemList[1].id
        ),
        new Entitlement(
          Name = sampleProducts2[4].ProductCode,
          RecordTypeId = supportRecordTypeId,
          Type = 'Phone Support',
          AccountId = lstAccount1[0].Id,
          Product__c = sampleProducts2[4].Id,
          StartDate = date.today(),
          ServiceContractId = objSC.Id,
          ContractLineItemId = lstCli[2].Id,
          Order_Service_Item__c = orderItemList[2].id
        ),
        new Entitlement(
          Name = sampleProducts2[4].ProductCode,
          RecordTypeId = supportRecordTypeId,
          Type = 'Phone Support',
          AccountId = lstAccount1[0].Id,
          Product__c = sampleProducts2[4].Id,
          StartDate = date.today(),
          ServiceContractId = objSC.Id,
          ContractLineItemId = lstCli[3].Id,
          Order_Service_Item__c = orderItemList[3].id
        )
      };
      insert lstEntitlement1;
      List<String> lstNewEntitlementIds = new List<String>();
      for (Entitlement ojEnt : lstEntitlement1) {
        lstNewEntitlementIds.add(ojEnt.Id);
      }

      orderInstance1.SBQQ__Contracted__c = false;
      orderInstance1.Polaris_Fulfillment_Status__c = 'Completed';
      orderInstance1.Status = 'Activated';
      orderInstance1.Order_Status__c = 'Shipped';
      //orderInstance1.Program__c = 'Conversion';
      orderInstance1.SBQQ__Quote__c = quoteObjNew.Id;
      orderInstance1.Actual_Order_Ship_Date__c = System.today();
      orderInstance1.Welcome_letter_sent_for_the_first_time__c = true;

      update orderInstance1;

      ContractOrders conVersionMethod = new ContractOrders();
      System.schedule('Test_Contract_Orders_Conversion', '0 0 * * * ?', conVersionMethod);
      conVersionMethod.execute(null);
      System.assertEquals(4, lstEntitlement1.size());
      Test.stopTest();
    }

  }
  @isTest
  static void renewalconversionmethod2() {
    List<user> usr = [SELECT Id FROM User WHERE email = 'testuser@testclass.com.invalid'];
    System.runAs(usr[1]) {
      //  insert new ShGl_DisableFunctionalityLogic__c(setupOwnerId = UserInfo.getUserId(), Disable_Account_Old_Trigger__c = TRUE);
      insert new ShGl_DisableBusinessLogic__c(
        setupownerid = userinfo.getUserId(),
        Disable_Entitlement_Validation_Rules__c = true,
        Disable_Account_Triggers__c = true,
        Disable_Asset_Triggers__c = true,
        Disable_SBQQ_Quote_Triggers__c = true,
        Disable_Product2_Validation_Rules__c = true,
        Disable_SBQQ_QuoteLine_Triggers__c = true,
        Disable_Order_Old_Trigger__c = true,
        Disable_OrderItem_Old_Trigger__c = true,
        Disable_Opportunity_Triggers__c = true,
        Disable_Order_Validation_Rules__c = true,
        Disable_SBQQ_QuoteLine_Validation_Rules__c = true
      );
      TriggerControl.stopOrderItemTrigger = true;
      TriggerControl.stopOrderTrigger = true;

      Test.startTest();

      List<Account> lstAccount1 = [SELECT Id FROM Account LIMIT 1];
      List<Asset> lstAsset = [SELECT Id, SerialNumber FROM Asset WHERE SerialNumber = '09092019APMSP1250'];
      Opportunity opp3 = TestDataFactory.getOpportunity();
      opp3.Partner_Lookup__c = lstAccount1[0].Id;
      opp3.AccountId = lstAccount1[0].Id;
      opp3.Distributor_Lookup__c = opp3.AccountId;
      opp3.Pricebook2id = Test.getStandardPricebookId();
      insert opp3;
      Entitlement entRec = [SELECT id FROM Entitlement LIMIT 1];

      SBQQ__Quote__c quoteObjNew = new SBQQ__Quote__c(
        SBQQ__Opportunity2__c = opp3.Id,
        SBQQ__SubscriptionTerm__c = 12,
        Is_RWD_Polaris_Quote__c = true,
        SBQQ__Primary__c = true,
        ApprovalStatus__c = 'Recalled',
        SBQQ__Type__c = 'Renewal+Expansion',
        SBQQ__PriceBook__c = Test.getStandardPricebookId(),
        Manual_Fulfillment_Quote__c = Constants.MANUAL_FULFILL_Quote_RSCP_CONVERSION+';'+Constants.MANUAL_FULFILL_Quote_GO_RSCP_CONVERSION
      );
      insert quoteObjNew;
      List<Product2> sampleProducts2 = [SELECT Id, ProductCode FROM Product2 LIMIT 12];
      List<PricebookEntry> entries = [SELECT Id, UnitPrice FROM PricebookEntry LIMIT 12];
      List<SBQQ__QuoteLine__c> lines10 = new List<SBQQ__QuoteLine__c>();
      lines10.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quoteObjNew.Id,
          SBQQ__Product__c = sampleProducts2[0].Id,
          SBQQ__PricebookEntryId__c = entries[0].Id,
          MSP_Segment_Product__c = true,
          SBQQ__Quantity__c = 70,
          SBQQ__Segmentindex__c = 1,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          Disposition_Reason__c = 'Renewing',
          Special_Program__c = 'Conversion'
        )
      );
      lines10.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quoteObjNew.Id,
          SBQQ__Product__c = sampleProducts2[6].Id,
          SBQQ__PricebookEntryId__c = entries[6].Id,
          MSP_Segment_Product__c = true,
          SBQQ__Quantity__c = 1,
          SBQQ__Segmentindex__c = 1,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          SBQQ__Existing__c = true
        )
      );
      lines10.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quoteObjNew.Id,
          SBQQ__Product__c = sampleProducts2[4].Id,
          SBQQ__PricebookEntryId__c = entries[4].Id,
          MSP_Segment_Product__c = true,
          SBQQ__Quantity__c = 1,
          SBQQ__Segmentindex__c = 1,
          SBQQ__Renewal__c = true,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          Disposition_Reason__c = 'Renewing',
          Special_Program__c = 'Conversion'
        )
      );
      lines10.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quoteObjNew.Id,
          SBQQ__Product__c = sampleProducts2[5].Id,
          SBQQ__PricebookEntryId__c = entries[5].Id,
          SBQQ__Quantity__c = 42,
          SBQQ__SubscriptionPricing__c = null,
          SBQQ__StartDate__c = System.today().addMonths(4).addDays(-6),
          SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1),
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200
        )
      );
      insert lines10;

      Product2 prod = new Product2(Id = sampleProducts2[4].Id, Upgrade_Path__c = 'Foundation to Enterprise', SBQQSC__EntitlementConversion__c = 'One per unit');
      update prod;
      List<Product2> sampleProductslistupd = new List<Product2>();
      for (Product2 pd : sampleProducts2) {
        pd.SBQQSC__EntitlementConversion__c = 'One per unit';
        pd.Custom_Renewal_Attributes__c = '{"RCVProd":"01t6f00000O6ft0AAB", "RCVProdPricebook":"01u6f00000JkJEVAA3", "RCVProdOption":"a6LVI0000000lwf2AA", "RCVQuantRatio":3}';
        sampleProductslistupd.add(pd);
      }
      update sampleProductslistupd;
      List<ContractLineItem> lstContractLineItems = [SELECT Id FROM ContractLineItem LIMIT 7];
      lines10[0].SBQQ__Bundle__c = true;
      lines10[0].Arroyo_Subscribed_Asset_Name__c = lstAsset[0].SerialNumber;
      lines10[0].Disposition_Reason__c = 'Converted';
      lines10[0].Arroyo_Subsumed_Old_Contract_Line_Items__c = lstContractLineItems[0].Id;
      lines10[1].SBQQ__RequiredBy__c = lines10[0].Id;
      lines10[2].SBQQ__RequiredBy__c = lines10[1].Id;
      lines10[2].Arroyo_Subscribed_Asset_Name__c = lstAsset[0].SerialNumber;
      lines10[2].Disposition_Reason__c = 'Renewing';
      lines10[2].Arroyo_Subsumed_Old_Contract_Line_Items__c = lstContractLineItems[1].Id;
      lines10[3].SBQQ__RequiredBy__c = lines10[0].Id;

      update lines10;

      quoteObjNew.ApprovalStatus__c = 'Approved';
      update quoteObjNew;

      Order orderInstance1 = new Order();
      orderInstance1.AccountId = lstAccount1[0].Id;
      orderInstance1.OpportunityId = opp3.Id;
      orderInstance1.EffectiveDate = system.today();
      orderInstance1.Status = 'Draft';
      orderInstance1.Type = 'Revenue';
      orderInstance1.Order_Status__c = 'Pending';
      orderInstance1.SBQQ__Quote__c = quoteObjNew.Id;
      //orderInstance1.Program__c = 'Conversion';
      orderInstance1.Order_Sub_type__c = 'Renewal';
      orderInstance1.Pricebook2Id = Test.getStandardPricebookId();
      orderInstance1.SC_or_Entitlement_Stage__c = Constants.SC_ENT_STAGE_CREATE_SERVICE_CONTRACT;
      insert orderInstance1;

      List<OrderItem> orderItemList = new List<OrderItem>{
        new OrderItem(
          OrderId = orderInstance1.Id,
          Previous_Contract_Line_Items__c = lstContractLineItems[0].Id + ',' + lstContractLineItems[4].Id,
          Product2Id = sampleProducts2[0].Id,
          Upgraded_From__c = '09092019APMSP1250',
          SerialNumber__c = '09092019APMSP1250',
          UnitPrice = entries[0].UnitPrice,
          SBQQ__QuoteLine__c = lines10[0].Id,
          SBQQ__SubscriptionTerm__c = 36,
          SBQQ__Segmentindex__c = 2,
          Support_Start_Date__c = System.today(),
          Program__c = 'Conversion',
          Quantity = 20,
          PricebookEntryId = entries[0].Id
        ),
        new OrderItem(
          OrderId = orderInstance1.Id,
          Previous_Contract_Line_Items__c = lstContractLineItems[3].Id,
          Entitlement_Id__c = String.valueof(entRec.id),
          Product2Id = sampleProducts2[4].Id,
          Upgraded_From__c = '09092019APMSP1250',
          SerialNumber__c = '09092019APMSP1250',
          UnitPrice = entries[4].UnitPrice,
          SBQQ__QuoteLine__c = lines10[2].Id,
          SBQQ__SubscriptionTerm__c = 36,
          SBQQ__Segmentindex__c = 2,
          Support_Start_Date__c = System.today(),
          Program__c = 'Conversion',
          Quantity = 20,
          PricebookEntryId = entries[4].Id
        ),
        new OrderItem(
          OrderId = orderInstance1.Id,
          TPH_Quantity__c = '1',
          Previous_Contract_Line_Items__c = lstContractLineItems[5].Id,
          Product2Id = sampleProducts2[0].Id,
          UnitPrice = entries[0].UnitPrice,
          SBQQ__QuoteLine__c = lines10[0].Id,
          SBQQ__SubscriptionTerm__c = 36,
          SBQQ__Segmentindex__c = 2,
          Support_Start_Date__c = System.today(),
          Program__c = 'Conversion',
          Quantity = 20,
          PricebookEntryId = entries[0].Id
        ),
        new OrderItem(
          OrderId = orderInstance1.Id,
          Previous_Contract_Line_Items__c = lstContractLineItems[6].Id,
          Product2Id = sampleProducts2[0].Id,
          UnitPrice = entries[0].UnitPrice,
          SBQQ__QuoteLine__c = lines10[0].Id,
          SBQQ__SubscriptionTerm__c = 36,
          SBQQ__Segmentindex__c = 2,
          Support_Start_Date__c = System.today(),
          Program__c = 'Conversion',
          Quantity = 20,
          PricebookEntryId = entries[0].Id
        )
      };
      insert orderItemList;

      List<String> lstOldCliIds = new List<String>{
        lstContractLineItems[0].Id,
        lstContractLineItems[3].Id,
        lstContractLineItems[4].Id,
        lstContractLineItems[5].Id,
        lstContractLineItems[6].Id
      };

      ServiceContract objSC = new ServiceContract(
        Name = 'ServiceContractTest2',
        AccountId = lstAccount1[0].Id,
        StartDate = Date.today(),
        Term = 36,
        pricebook2Id = Test.getStandardPricebookId(),
        SBQQSC__Opportunity__c = opp3.Id,
        SBQQSC__Order__c = orderInstance1.Id,
        SBQQSC__Quote__c = quoteObjNew.Id
      );

      insert objSC;

      List<ContractLineItem> lstCli = new List<ContractLineItem>{
        new ContractLineItem(
          Quantity = orderItemList[0].quantity,
          PricebookEntryId = orderItemList[0].PricebookEntryId,
          ServiceContractId = objSC.Id,
          UnitPrice = orderItemList[0].UnitPrice,
          StartDate = date.today()
        ),
        new ContractLineItem(
          Quantity = orderItemList[1].quantity,
          PricebookEntryId = orderItemList[1].PricebookEntryId,
          ServiceContractId = objSC.Id,
          UnitPrice = orderItemList[1].UnitPrice,
          StartDate = date.today()
        ),
        new ContractLineItem(
          Quantity = orderItemList[2].quantity,
          PricebookEntryId = orderItemList[2].PricebookEntryId,
          ServiceContractId = objSC.Id,
          UnitPrice = orderItemList[2].UnitPrice,
          StartDate = date.today()
        ),
        new ContractLineItem(
          Quantity = orderItemList[3].quantity,
          PricebookEntryId = orderItemList[3].PricebookEntryId,
          ServiceContractId = objSC.Id,
          UnitPrice = orderItemList[3].UnitPrice,
          StartDate = date.today()
        )
      };

      insert lstCli;
      orderItemList[0].SBQQSC__ContractLineItem__c = lstCli[0].Id;
      orderItemList[2].SBQQSC__ContractLineItem__c = lstCli[2].Id;

      update orderItemList;
      Id supportRecordTypeId = Schema.SObjectType.Entitlement.getRecordTypeInfosByName().get('Support').getRecordTypeId();

      List<Entitlement> lstEntitlement1 = new List<Entitlement>{
        new Entitlement(
          Name = sampleProducts2[4].ProductCode,
          RecordTypeId = supportRecordTypeId,
          Type = 'Phone Support',
          AccountId = lstAccount1[0].Id,
          Product__c = sampleProducts2[0].Id,
          StartDate = date.today(),
          AssetId = lstAsset[0].Id,
          ServiceContractId = objSC.Id,
          ContractLineItemId = lstCli[0].Id,
          Order_Service_Item__c = orderItemList[0].id
        ),
        new Entitlement(
          Name = sampleProducts2[4].ProductCode,
          RecordTypeId = supportRecordTypeId,
          Type = 'Phone Support',
          AccountId = lstAccount1[0].Id,
          Product__c = sampleProducts2[4].Id,
          StartDate = date.today(),
          AssetId = lstAsset[0].Id,
          ServiceContractId = objSC.Id,
          ContractLineItemId = lstCli[1].Id,
          Order_Service_Item__c = orderItemList[1].id
        ),
        new Entitlement(
          Name = sampleProducts2[4].ProductCode,
          RecordTypeId = supportRecordTypeId,
          Type = 'Phone Support',
          AccountId = lstAccount1[0].Id,
          Product__c = sampleProducts2[4].Id,
          StartDate = date.today(),
          ServiceContractId = objSC.Id,
          ContractLineItemId = lstCli[2].Id,
          Order_Service_Item__c = orderItemList[2].id
        ),
        new Entitlement(
          Name = sampleProducts2[4].ProductCode,
          RecordTypeId = supportRecordTypeId,
          Type = 'Phone Support',
          AccountId = lstAccount1[0].Id,
          Product__c = sampleProducts2[4].Id,
          StartDate = date.today(),
          ServiceContractId = objSC.Id,
          ContractLineItemId = lstCli[3].Id,
          Order_Service_Item__c = orderItemList[3].id
        )
      };
      insert lstEntitlement1;
      List<String> lstNewEntitlementIds = new List<String>();
      for (Entitlement ojEnt : lstEntitlement1) {
        lstNewEntitlementIds.add(ojEnt.Id);
      }

      orderInstance1.SBQQ__Contracted__c = false;
      orderInstance1.Polaris_Fulfillment_Status__c = 'Completed';
      orderInstance1.Status = 'Activated';
      orderInstance1.Order_Status__c = 'Shipped';
      //orderInstance1.Program__c = 'Conversion';
      orderInstance1.SBQQ__Quote__c = quoteObjNew.Id;
      orderInstance1.Actual_Order_Ship_Date__c = System.today();
      orderInstance1.Welcome_letter_sent_for_the_first_time__c = true;

      update orderInstance1;

      ContractOrders conVersionMethod = new ContractOrders();
      System.schedule('Test_Contract_Orders_Conversion', '0 0 * * * ?', conVersionMethod);
      conVersionMethod.execute(null);
      System.assertEquals(4, lstEntitlement1.size());
      Test.stopTest();
    }
  }
  @isTest
  static void newConversionMethod() {
    List<user> usr2 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com.invalid'];
    System.runAs(usr2[1]) {
      //  insert new ShGl_DisableFunctionalityLogic__c(setupOwnerId = UserInfo.getUserId(), Disable_Account_Old_Trigger__c = TRUE);
      insert new ShGl_DisableBusinessLogic__c(
        setupownerid = userinfo.getUserId(),
        Disable_Entitlement_Validation_Rules__c = true,
        Disable_Account_Triggers__c = true,
        Disable_Asset_Triggers__c = true,
        Disable_SBQQ_Quote_Triggers__c = true,
        Disable_SBQQ_QuoteLine_Triggers__c = true,
        Disable_Product2_Validation_Rules__c = true,
        Disable_Order_Old_Trigger__c = true,
        Disable_OrderItem_Old_Trigger__c = true,
        Disable_Opportunity_Triggers__c = true,
        Disable_Order_Validation_Rules__c = true,
        Disable_SBQQ_QuoteLine_Validation_Rules__c = true
      );
            TriggerControl.stopOrderItemTrigger = true;
            TriggerControl.stopOrderTrigger = true;
            
            Test.startTest();
       
        List<Account> lstAccount2 = [SELECT Id FROM Account LIMIT 1];
      List<Asset> lstAsset = [SELECT Id, SerialNumber FROM Asset WHERE SerialNumber = '09092019APMSP1250'];
         Opportunity opp2 = TestDataFactory.getOpportunity();
            opp2.Partner_Lookup__c = lstAccount2[0].Id;
            opp2.AccountId = lstAccount2[0].Id;
            opp2.Distributor_Lookup__c = opp2.AccountId;
            opp2.Pricebook2id = Test.getStandardPricebookId();
            insert opp2;
            
      SBQQ__Quote__c quote2 = new SBQQ__Quote__c(
        SBQQ__Opportunity2__c = opp2.Id,
        SBQQ__SubscriptionTerm__c = 12,
        Is_RWD_Polaris_Quote__c = true,
        SBQQ__Primary__c = true,
        ApprovalStatus__c = 'Recalled',
        SBQQ__Type__c = 'Renewal+Expansion',
        SBQQ__PriceBook__c = Test.getStandardPricebookId()
      );
        insert quote2;
        List<Product2> sampleProducts = [SELECT Id, ProductCode FROM Product2 LIMIT 8];
        List<PricebookEntry> entries = [SELECT Id, UnitPrice FROM PricebookEntry LIMIT 8];
      List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote2.Id,
          SBQQ__Product__c = sampleProducts[0].Id,
          SBQQ__PricebookEntryId__c = entries[0].Id,
          MSP_Segment_Product__c = true,
          SBQQ__Quantity__c = 70,
          SBQQ__Segmentindex__c = 1,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          Disposition_Reason__c = 'Renewing',
          Special_Program__c = 'Conversion'
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote2.Id,
          SBQQ__Product__c = sampleProducts[6].Id,
          SBQQ__PricebookEntryId__c = entries[6].Id,
          MSP_Segment_Product__c = true,
          SBQQ__Quantity__c = 1,
          SBQQ__Segmentindex__c = 1,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          SBQQ__Existing__c = true
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote2.Id,
          SBQQ__Product__c = sampleProducts[4].Id,
          SBQQ__PricebookEntryId__c = entries[4].Id,
          MSP_Segment_Product__c = true,
          SBQQ__Quantity__c = 1,
          SBQQ__Segmentindex__c = 1,
          SBQQ__Renewal__c = true,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          Disposition_Reason__c = 'Renewing',
          Special_Program__c = 'Conversion'
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote2.Id,
          SBQQ__Product__c = sampleProducts[5].Id,
          SBQQ__PricebookEntryId__c = entries[5].Id,
          SBQQ__Quantity__c = 42,
          SBQQ__SubscriptionPricing__c = null,
          SBQQ__StartDate__c = System.today().addMonths(4).addDays(-6),
          SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1),
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200
        )
      );
        insert lines;
      List<ContractLineItem> lstContractLineItems = [SELECT Id FROM ContractLineItem LIMIT 5];
    lines[0].SBQQ__Bundle__c = true;
    lines[0].Arroyo_Subscribed_Asset_Name__c = lstAsset[0].SerialNumber;
    lines[0].Disposition_Reason__c = 'Converted';
    lines[0].Arroyo_Subsumed_Old_Contract_Line_Items__c = lstContractLineItems[0].Id;
    lines[1].SBQQ__RequiredBy__c = lines[0].Id;   
    lines[2].SBQQ__RequiredBy__c = lines[1].Id;
    lines[2].Arroyo_Subscribed_Asset_Name__c = lstAsset[0].SerialNumber;
    lines[2].Disposition_Reason__c = 'Converted';
    lines[2].Arroyo_Subsumed_Old_Contract_Line_Items__c = lstContractLineItems[1].Id;
    lines[3].SBQQ__RequiredBy__c = lines[0].Id;
        
    update lines;
            
      List<String> lstOldCliIds = new List<String>{ lstContractLineItems[0].Id, lstContractLineItems[1].Id };
    quote2.ApprovalStatus__c = 'Approved';
    update quote2;
          
    Order orderInstanceObj = new Order();
            orderInstanceObj.AccountId = lstAccount2[0].Id;
            orderInstanceObj.OpportunityId = opp2.Id;
            orderInstanceObj.EffectiveDate = system.today();  
            orderInstanceObj.Status = 'Draft';
            orderInstanceObj.Type = 'Revenue';
            orderInstanceObj.Order_Status__c = 'Pending'; 
            orderInstanceObj.Pricebook2Id = Test.getStandardPricebookId(); 
            insert orderInstanceObj;
            
            List<OrderItem> orderItemList = new List<OrderItem>{
        new OrderItem(
          OrderId = orderInstanceObj.Id,
          Previous_Contract_Line_Items__c = lstContractLineItems[0].Id,
          Product2Id = sampleProducts[0].Id,
          SerialNumber__c = lstAsset[0].SerialNumber,
          UnitPrice = entries[0].UnitPrice,
          SBQQ__QuoteLine__c = lines[0].Id,
          SBQQ__SubscriptionTerm__c = 36,
          Quantity = 20,
          PricebookEntryId = entries[0].Id,
          Program__c = 'Conversion',
          Support_Start_Date__c = System.today().addDays(2)
        ),
        new OrderItem(
          OrderId = orderInstanceObj.Id,
          Previous_Contract_Line_Items__c = lstContractLineItems[1].Id,
          Product2Id = sampleProducts[4].Id,
          SerialNumber__c = lstAsset[0].SerialNumber,
          UnitPrice = entries[4].UnitPrice,
          SBQQ__QuoteLine__c = lines[2].Id,
          SBQQ__SubscriptionTerm__c = 36,
          Quantity = 20,
          PricebookEntryId = entries[4].Id,
          Program__c = 'Conversion',
          Support_Start_Date__c = System.today().addDays(2)
        ),
        new OrderItem(
          OrderId = orderInstanceObj.Id,
          Product2Id = sampleProducts[5].Id,
          UnitPrice = entries[5].UnitPrice,
          SBQQ__QuoteLine__c = lines[3].Id,
          SBQQ__SubscriptionTerm__c = 36,
          Quantity = 20,
          PricebookEntryId = entries[5].Id,
          Support_Start_Date__c = System.today().addDays(20)
        )
                };
           insert orderItemList;  
      List<ServiceContract> lstSC = new List<ServiceContract>{
        new ServiceContract(
          Name = 'ServiceContractTest2',
          AccountId = lstAccount2[0].Id,
          StartDate = Date.today(),
          Term = 36,
          pricebook2Id = Test.getStandardPricebookId(),
          SBQQSC__Opportunity__c = opp2.Id,
          SBQQSC__Order__c = orderInstanceObj.Id,
          SBQQSC__Quote__c = quote2.Id
        ),
        new ServiceContract(
          Name = 'ServiceContractTest3',
          AccountId = lstAccount2[0].Id,
          StartDate = Date.today(),
          Term = 36,
          pricebook2Id = Test.getStandardPricebookId(),
          SBQQSC__Opportunity__c = opp2.Id,
          SBQQSC__Order__c = orderInstanceObj.Id,
          SBQQSC__Quote__c = quote2.Id
        )
      };
            
            insert lstSC;
            
            List<ContractLineItem> lstCli = new List<ContractLineItem>{
        new ContractLineItem(
          SBQQSC__OrderProduct__c = orderItemList[0].Id,
          Quantity = orderItemList[0].quantity,
          SBQQSC__QuoteLine__c = orderItemList[0].SBQQ__QuoteLine__c,
          SBQQSC__Product__c = orderItemList[0].Product2Id,
          PricebookEntryId = orderItemList[0].PricebookEntryId,
          ServiceContractId = lstSC[0].Id,
          UnitPrice = orderItemList[0].UnitPrice,
          StartDate = date.today()
        ),
        new ContractLineItem(
          SBQQSC__OrderProduct__c = orderItemList[1].Id,
          Quantity = orderItemList[1].quantity,
          SBQQSC__QuoteLine__c = orderItemList[1].SBQQ__QuoteLine__c,
          SBQQSC__Product__c = orderItemList[1].Product2Id,
          PricebookEntryId = orderItemList[1].PricebookEntryId,
          ServiceContractId = lstSC[0].Id,
          UnitPrice = orderItemList[0].UnitPrice,
          StartDate = date.today()
        ),
        new ContractLineItem(
          SBQQSC__OrderProduct__c = orderItemList[2].Id,
          Quantity = orderItemList[2].quantity,
          SBQQSC__QuoteLine__c = orderItemList[2].SBQQ__QuoteLine__c,
          SBQQSC__Product__c = orderItemList[2].Product2Id,
          PricebookEntryId = orderItemList[2].PricebookEntryId,
          ServiceContractId = lstSC[1].Id,
          UnitPrice = orderItemList[1].UnitPrice,
          StartDate = date.today().addDays(10)
        )
            }; 
            
            insert lstCli;
            orderItemList[0].SBQQSC__ContractLineItem__c = lstCli[0].Id;
            orderItemList[1].SBQQSC__ContractLineItem__c = lstCli[1].Id;
            orderItemList[2].SBQQSC__ContractLineItem__c = lstCli[2].Id;
            orderItemList[2].SBQQ__RequiredBy__c = orderItemList[0].Id;

            update orderItemList;
            Id supportRecordTypeId = Schema.SObjectType.Entitlement.getRecordTypeInfosByName().get('Support').getRecordTypeId();
            
      List<Entitlement> lstEntitlement = new List<Entitlement>{
        new Entitlement(
          Name = sampleProducts[0].ProductCode,
          RecordTypeId = supportRecordTypeId,
          Type = 'Phone Support',
          AccountId = lstAccount2[0].Id,
          Product__c = sampleProducts[0].Id,
          StartDate = date.today(),
          ServiceContractId = lstSC[0].Id,
          ContractLineItemId = lstCli[0].Id,
          Order_Service_Item__c = orderItemList[0].id
        ),
        new Entitlement(
          Name = sampleProducts[4].ProductCode,
          AssetId = lstAsset[0].Id,
          RecordTypeId = supportRecordTypeId,
          Type = 'Phone Support',
          AccountId = lstAccount2[0].Id,
          Product__c = sampleProducts[4].Id,
          StartDate = date.today(),
          ServiceContractId = lstSC[0].Id,
          ContractLineItemId = lstCli[1].Id,
          Order_Service_Item__c = orderItemList[1].id
        ),
        new Entitlement(
          Name = sampleProducts[5].ProductCode,
          RecordTypeId = supportRecordTypeId,
          Type = 'Phone Support',
          AccountId = lstAccount2[0].Id,
          Product__c = sampleProducts[5].Id,
          StartDate = date.today().addDays(10),
          ServiceContractId = lstSC[1].Id,
          ContractLineItemId = lstCli[2].Id,
          Order_Service_Item__c = orderItemList[2].Id
        )
                    };
                   insert lstEntitlement; 
            
      List<String> lstNewEntitlementIds = new List<String>{ lstEntitlement[0].Id, lstEntitlement[1].Id };
                
                orderInstanceObj.SBQQ__Contracted__c = false;
            orderInstanceObj.Polaris_Fulfillment_Status__c = 'Completed';
            orderInstanceObj.Status = 'Activated';
            orderInstanceObj.Order_Status__c = 'Shipped';
            //orderInstanceObj.Program__c = 'Conversion';
            orderInstanceObj.SBQQ__Quote__c = quote2.Id;
      orderInstanceObj.Actual_Order_Ship_Date__c = System.today();
            orderInstanceObj.Welcome_letter_sent_for_the_first_time__c = true;
      orderInstanceObj.SC_or_Entitlement_Stage__c = Constants.SC_ENT_STAGE_CREATE_SERVICE_CONTRACT;
            
            update orderInstanceObj;
            
      ContractOrders conVersionMethod = new ContractOrders();
            System.schedule('Test_Contract_Orders_Conversion', '0 0 * * * ?', conVersionMethod);
            conVersionMethod.execute(null);      
            System.assertEquals(3, lstEntitlement.size());
                       Test.stopTest();
        }
    }
 
    @isTest
  static void refreshmethod3() {
    List<user> usr3 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com.invalid'];
        System.runAs(usr3[2]) {
            //insert new ShGl_DisableFunctionalityLogic__c(setupOwnerId = UserInfo.getUserId(), Disable_Account_Old_Trigger__c = TRUE);
      insert new ShGl_DisableBusinessLogic__c(
        setupownerid = userinfo.getUserId(),
                                                    Disable_Entitlement_Validation_Rules__c = true,
        Disable_Account_Triggers__c = true,
        Disable_Asset_Triggers__c = true,
        Disable_SBQQ_Quote_Triggers__c = true,
        Disable_SBQQ_QuoteLine_Triggers__c = true,
                                                    Disable_Product2_Validation_Rules__c = true,
                                                    Disable_ServiceContract_Trigger__c = true,
                                                    Disable_SBQQ_QuoteLine_Validation_Rules__c = true,
        Disable_Order_Old_Trigger__c = true,
        Disable_OrderItem_Old_Trigger__c = true,
                                                    Disable_Order_Validation_Rules__c = true,
        Disable_Opportunity_Triggers__c = true
      );
            
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true; 
            SBQQ.TriggerControl.disable();  
            TriggerControl.stopOrderItemTrigger = true;
            TriggerControl.stopOrderTrigger = true;
            
            Test.startTest();
      List<Asset> assestInsList = [
        SELECT id, Name, SerialNumber, serial_number__c, AccountId, Product2Id
        FROM Asset
        LIMIT 1
      ];
            
      List<SBQQ__Quote__c> quoteList3 = [
        SELECT id, SBQQ__Opportunity2__c, SBQQ__SubscriptionTerm__c, Is_RWD_Polaris_Quote__c, SBQQ__PriceBook__c, SBQQ__Type__c
        FROM SBQQ__Quote__c
        LIMIT 10
      ];
            
            quoteList3[0].SBQQ__Type__c = 'Quote';
            quoteList3[0].Opportunity_Program__c = 'Refresh';
            update quoteList3;
            
      List<ContractLineItem> cliList3 = [
        SELECT Id, Quantity, PricebookEntryId, ServiceContractId, UnitPrice, StartDate, SBQQSC__RenewalQuantity__c, SBQQSC__Product__c
        FROM ContractLineItem
        LIMIT 2
      ];

      List<SBQQ__QuoteLine__c> lines3 = [
        SELECT
          id,
          SBQQ__Quote__c,
          SBQQ__Product__c,
          SBQQ__Quantity__c,
          SBQQ__SubscriptionPricing__c,
          SBQQ__DefaultSubscriptionTerm__c,
          SBQQ__ListPrice__c,
          SBQQ__NetPrice__c,
          Arroyo_Subscribed_Asset_Name__c,
          Disposition_Reason__c,
          Do_not_Renew__c,//ITNPI-2901
          SBQQ__RequiredBy__c,
          Special_Program__c,
          SBQQ__Product__r.Product_Type__c,
          SBQQ__ProductOption__r.Refresh_Default_Option__c
        FROM SBQQ__QuoteLine__c
        LIMIT 10
      ];
            
    lines3[0].Arroyo_Subscribed_Asset_Name__c = cliList3[1].id;
    lines3[0].Special_Program__c = Constants.PROGRAM_REFRESH;
      for (integer i = 0; i < lines3.size(); i++) {
        if (lines3[i].Disposition_Reason__c != null) {
          lines3[i].Arroyo_Subsumed_Old_Contract_Line_Items__c = cliList3[1].Id + ' ,';
                }
            }
            update lines3;
            
      List<Product2> productList = [
        SELECT
          id,
          Name,
          ProductCode,
          Category__c,
          Product_Level__c,
          SBQQ__AssetAmendmentBehavior__c,
          SBQQSC__EntitlementConversion__c,
          IsActive,
          CPQ_MSP_Base_Price__c,
          SBQQ__SubscriptionPricing__c,
          SBQQ__SubscriptionTerm__c,
          SBQQ__SubscriptionBase__c,
          SBQQ__SubscriptionType__c,
          Gorefresh_Mark_SW_End_Date__c
        FROM Product2
        LIMIT 2
      ];
            
      productList[0].Gorefresh_Mark_SW_End_Date__c = true;
            //productList[0].Product_Level__c='Support';
      productList[1].Gorefresh_Mark_SW_End_Date__c = false;
            update productList;
            
      cliList3[0].SBQQSC__RenewalQuantity__c = 1;
      cliList3[0].SBQQSC__QuoteLine__c = lines3[0].id;
      cliList3[1].SBQQSC__RenewalQuantity__c = 1;
      cliList3[1].SBQQSC__QuoteLine__c = lines3[0].id;
      cliList3[0].SBQQSC__Product__c = productList[0].id;
            update cliList3;
            
      List<OrderItem> orderItemList3 = [
        SELECT
          id,
          OrderId,
          Product2Id,
          UnitPrice,
          SBQQ__QuoteLine__c,
          SBQQ__SubscriptionTerm__c,
          Quantity,
          PricebookEntryId,
          Upgraded_From__c,
          Previous_Contract_Line_Items__c,
          Program__c
        FROM OrderItem
        LIMIT 2
      ];
            
      orderItemList3[0].Upgraded_From__c = '09092019APMSP1250';
      orderItemList3[0].SerialNumber__c = '09092019APMSP1251';
      orderItemList3[0].Previous_Contract_Line_Items__c = cliList3[1].id;
            update orderItemList3;
            
      List<Entitlement> entList3 = [
        SELECT id, Name, RecordTypeId, Type, AccountId, Product__c, StartDate, ServiceContractId, ContractLineItemId, Order_Service_Item__c
        FROM Entitlement
        LIMIT 2
      ];
            
      entList3[1].Order_Service_Item__c = null;
      entList3[1].Product__c = null;
      entList3[1].Type = Constants.ENT_TYPE_PHONE_SUPPORT;
      entList3[1].AssetId = assestInsList[0].id;
      entList3[0].AssetId = assestInsList[0].id;
                        update entList3;

      List<order> orderListMethod3 = [
        SELECT
          id,
          OrderNumber,
          Status,
          Actual_Order_Ship_Date__c,
          SBQQ__Contracted__c,
          Polaris_Fulfillment_Status__c,
          AccountId,
          OpportunityId,
          Opportunity.Owner.Email,
          Order_Sub_Type__c,
          SBQQ__Quote__c,
          SBQQ__Quote__r.SBQQ__Type__c,
          Program__c,
          ProcessType__c,
          SBQQ__Quote__r.SBQQ__Opportunity2__c,
          Opportunity.Name,
          Opportunity.CloseDate,
          RecordTypeId,
          (
            SELECT
              id,
              quantity,
              product2.Product_Subtype__c,
              product2.Product_Level__c,
              product2.Product_Type__c,
              product2.Name,
              Upgraded_From__c,
              SerialNumber__c,
              Program__c,
              Previous_Contract_Line_Items__c
            FROM OrderItems
          )
        FROM Order
        LIMIT 1
      ];
            List<Orderitem> OIToUpdate = new List<Orderitem>();
      for (order ord : orderListMethod3) {
        for (orderitem oi : ord.OrderItems) {
                    oi.Program__c = 'Refresh';
                    OIToUpdate.add(oi);
                    
                     //      assestInsList[0].serial_number__c=oi.SerialNumber__c.trim();
                }
            }
            update OIToUpdate;
           update assestInsList;
            orderListMethod3[0].SBQQ__Contracted__c = false;
            orderListMethod3[0].Polaris_Fulfillment_Status__c = 'Completed';
            orderListMethod3[0].Status = 'Activated';
            orderListMethod3[0].Order_Status__c = 'Shipped';
            //orderListMethod3[0].Program__c = 'Refresh';
      orderListMethod3[0].Actual_Order_Ship_Date__c = System.today();
            orderListMethod3[0].Welcome_letter_sent_for_the_first_time__c = true;
      orderListMethod3[0].SC_or_Entitlement_Stage__c = Constants.SC_ENT_STAGE_CREATE_SERVICE_CONTRACT;
            update orderListMethod3; 
            
      ContractOrders absMethod3 = new ContractOrders();
            System.schedule('Test_Contract_Orders_method3', '0 0 * * * ?', absMethod3);
            absMethod3.execute(null);
            SBQQ.TriggerControl.enable();  
            System.assertEquals(1, orderListMethod3.size());
            Test.stopTest();        
        }
        
    }
    //@isTest
  static void method4() {
    List<user> usr4 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com.invalid'];
        System.runAs(usr4[1]) {
      insert new ShGl_DisableFunctionalityLogic__c(setupOwnerId = UserInfo.getUserId(), Disable_Account_Old_Trigger__c = true);
      insert new ShGl_DisableBusinessLogic__c(
        setupownerid = userinfo.getUserId(),
        Disable_Entitlement_Validation_Rules__c = true,
        Disable_Account_Triggers__c = true,
        Disable_Asset_Triggers__c = true,
        Disable_SBQQ_Quote_Triggers__c = true,
        Disable_SBQQ_QuoteLine_Triggers__c = true,
        Disable_Product2_Validation_Rules__c = true,
        Disable_Order_Old_Trigger__c = true,
        Disable_OrderItem_Old_Trigger__c = true,
        Disable_Opportunity_Triggers__c = true,
        Disable_Product2_Trigger__c = true,
        Disable_Order_Validation_Rules__c = true,
        Disable_SBQQ_QuoteLine_Validation_Rules__c = true
      );
            
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true; 
            SBQQ.TriggerControl.disable();  
            TriggerControl.stopOrderItemTrigger = true;
      TriggerControl__c objOrderTrigger = new TriggerControl__c(Name = 'Entitlement', Disable_Trigger__c = true, DisableTrigger__c = true, SendEmail__c = false);
      insert objOrderTrigger;
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
                  Id pricebookId = Test.getStandardPricebookId();
                Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();

      Account act = new Account(
        BillingCountryCode = 'US',
        BillingCountry = 'United States',
        BillingState = 'United States Minor Outlying Islands',
        Is_Refreshed__c = false,
        Name = 'Test',
        Sync_to_NetSuite__c = false,
        RecordTypeId = devRecordTypeId,
        Website = 'www.test3.com',
        OwnerId = userinfo.getUserId(),
        type = 'Customer'
      );
        
        insert act;
            
      opportunity oppr = new opportunity(
        Name = 'testing DIEtestsalesforce 4/6/2015',
        Lead_Email_Hidden__c = '',
        AccountId = act.Id,
        StageName = '1 Discovery',
        Rubrik_Sales_Engineer__c = UserInfo.getUserId(),
        Alliance_Partner_Name__c = 'Amazon',
        Alliance_Source_Type__c = 'Alliance Initiated Deal',
        Installation_Assigned_To__c = 'FE Install',
        Economic_Buyer__c = 'Test',
        Metric__c = 'Test',
        Decision_Process__c = 'Test',
        Decision_Criteria__c = 'Test',
        Opportunity_Sub_Type__c = 'Regular',
        Partner_Lookup__c = act.Id,
        Distributor_Lookup__c = act.Id,
        Alliance_Source_Type_HW__c = 'Rubrik Initiated Alliance Deal',
        Mosaic_Customer_Environment__c = 'AWS',
        CloseDate = Date.Today().addDays(10),
        Alliance_Source_Type_SW__c = 'Rubrik Initiated Alliance Deal',
        Identified_Pain__c = 'Test',
        Champion__c = 'Test',
        ForecastCategoryName = 'Best Case',
        pricebook2Id = pricebookId
      );
        
        insert oppr;
            
      SBQQ__Quote__c quote4 = new SBQQ__Quote__c(
        SBQQ__Opportunity2__c = oppr.Id,
        SBQQ__SubscriptionTerm__c = 12,
        Is_RWD_Polaris_Quote__c = true,
        SBQQ__Primary__c = true,
        ApprovalStatus__c = 'Recalled',
        SBQQ__Type__c = 'Quote',
        SBQQ__PriceBook__c = pricebookId
      );
            insert quote4;
            
            List<Product2> lstProducts4 = new List<Product2>{
                new Product2(
          Name = 'RBK-SVC-PREM-R344',
          ProductCode = 'RBK-INSTALL',
          Family = 'DELL',
          Appliance_Model_HW__c = 'RBK-R6408E',
          isActive = true,
          Allow_PSO_Task_Creation__c = true,
          Product_Type__c = '3rd Party Hardware',
          License_Category__c = Constants.PROD_LICENSE_CATEGORY_SAAS,
          Product_Subtype__c = Constants.PROD_SUB_TYPE_SCALE_MSP,
          Product_Level__c = 'LOD Software'
                ),
                    new Product2(
          ProductCode = 'RBK-PS-INST',
          Family = 'DELL',
          Appliance_Model_HW__c = 'RBK-R6408E',
          License_Category__c = Constants.PROD_LICENSE_CATEGORY_SAAS,
          Product_Subtype__c = Constants.PROD_SUB_TYPE_SCALE_MSP,
          Product_Level__c = 'LOD Software',
          isActive = true,
          Product_Type__c = '3rd Party Hardware',
          Allow_PSO_Task_Creation__c = true,
          Name = 'RBK-SVC-PREM-R344'
                    ),
                    new Product2(
          Name = 'RBK-SVC-PREM-R344',
          Family = 'DELL',
          Appliance_Model_HW__c = 'RBK-R6408E',
          License_Category__c = Constants.PROD_LICENSE_CATEGORY_SAAS,
          Product_Subtype__c = Constants.PROD_SUB_TYPE_SCALE_MSP,
          Product_Level__c = 'LOD Software',
          ProductCode = 'RBK-PS-CONSULT',
          isActive = true,
          Product_Type__c = '3rd Party Hardware',
          Allow_PSO_Task_Creation__c = true
                    ),
                    new Product2(
          Family = 'DELL',
          Appliance_Model_HW__c = 'RBK-R6408E',
          Name = 'RBK-SVC-PREM-R344',
          ProductCode = 'RBK-PS-CNSLT-ONST',
          isActive = true,
          Product_Type__c = '3rd Party Hardware',
          Allow_PSO_Task_Creation__c = true,
          Product_Subtype__c = Constants.PROD_SUB_TYPE_SCALE_MSP,
          Product_Level__c = 'LOD Software'
                    ),
                    new Product2(
          Name = 'RBK-SVC-PREM-R344',
          ProductCode = 'RBK-CONSULT',
          Family = 'DELL',
          Appliance_Model_HW__c = 'RBK-R6408E',
          isActive = true,
          Product_Type__c = '3rd Party Hardware',
          Allow_PSO_Task_Creation__c = true,
          Product_Subtype__c = Constants.PROD_SUB_TYPE_SCALE_MSP,
          Product_Level__c = 'LOD Software'
                    ),
                    new Product2(
          Family = 'DELL',
          Name = 'RBK-SVC-PREM-R344',
          ProductCode = 'RBK-DATA-MIGRATION',
          Appliance_Model_HW__c = 'RBK-R6408E',
          isActive = true,
          Product_Type__c = '3rd Party Hardware',
          Allow_PSO_Task_Creation__c = true,
          Product_Subtype__c = Constants.PROD_SUB_TYPE_SCALE_MSP,
          Product_Level__c = 'LOD Software'
                    ),
                    new Product2(
          Name = 'RBK-SVC-PREM-R344',
          ProductCode = 'RBK-PS-CNSLT-RMOT',
          Family = 'DELL',
          Appliance_Model_HW__c = 'RBK-R6408E',
          isActive = true,
          Product_Type__c = '3rd Party Hardware',
          Allow_PSO_Task_Creation__c = true,
          License_Category__c = Constants.PROD_LICENSE_CATEGORY_SAAS,
          Product_Subtype__c = Constants.PROD_SUB_TYPE_SCALE_MSP,
          Product_Level__c = 'LOD Software'
                    ),
                    new Product2(
          Appliance_Model_HW__c = 'RBK-R6408E',
          Name = 'RBK-SVC-PREM-R344',
          ProductCode = 'RBK-PS-TE',
          Family = 'DELL',
          License_Category__c = Constants.PROD_LICENSE_CATEGORY_SAAS,
          Product_Subtype__c = Constants.PROD_SUB_TYPE_SCALE_MSP,
          Product_Level__c = 'LOD Software',
          isActive = true,
          Product_Type__c = '3rd Party Hardware',
          Allow_PSO_Task_Creation__c = true
                    ),
                    new Product2(
          isActive = true,
          Product_Type__c = '3rd Party Hardware',
          Name = 'RBK-SVC-PREM-R344',
          ProductCode = 'RBK-PS-RES',
          Family = 'DELL',
          Appliance_Model_HW__c = 'RBK-R6408E',
          Allow_PSO_Task_Creation__c = true,
          License_Category__c = Constants.PROD_LICENSE_CATEGORY_SAAS,
          Product_Subtype__c = Constants.PROD_SUB_TYPE_SCALE_MSP,
          Product_Level__c = 'LOD Software'
                    )  
                    };
                        
                        insert lstProducts4;
            
      List<PricebookEntry> lstPbEntries4 = new List<PricebookEntry>{
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProducts4[0].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProducts4[1].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProducts4[2].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProducts4[3].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProducts4[4].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProducts4[5].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProducts4[6].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProducts4[7].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProducts4[8].Id, UnitPrice = 100.00, IsActive = true)
                    };
                        
                        insert lstPbEntries4;
          
            Test.startTest();
            
      Map<String, Object> OrderMap = new Map<String, Object>{
                'Type' => 'RMA',
                    'AccountId' => act.Id,
                    'Status' => 'Activated',
                    'Sync_to_NetSuite__c' => true,
                     'Est_Ship_Date__c' => null,
                    'Order_Splitted__c' => true,
                    'Order_Sub_Type__c' => Constants.ORDER_SUB_TYPE_GC_OFFER,
                    'ShippingCountryCode' => 'US',
        'ShippingStreet' => 'Test Street',
                    'ShippingCity' => 'Test City',
        'ShippingState' => 'California',
        'ShippingCountry' => 'United States',
        'ShippingPostalcode' => '94820',
                    'ship_To_Name__c' => act.id,
        'ShipToContactName__c' => 'Test',
                    'Pricebook2Id' => pricebookId,
                    'Have_Polaris_Products__c' => false,
                    'Polaris_Fulfillment_Status__c' => 'Completed',
                    'Original_Est_Ship_Date__c' => Date.today().addDays(30),
                    'POC_Opportunity__c' => oppr.Id,
                    'EffectiveDate' => system.today(),
        'SBQQ__Quote__c' => quote4.Id,
                    'Actual_Order_Ship_Date__c' => Date.today().addDays(60)
                    };
                        
                        Order ord = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
                        insert Ord;      

             List<OrderItem> lstOrderItems4 = new List<OrderItem>{
        new OrderItem(
          OrderId = Ord.Id,
          Quantity = 5,
          PricebookEntryId = lstPbEntries4[0].Id,
          UnitPrice = lstPbEntries4[0].UnitPrice,
          SerialNumber__c = 'SN1',
          Failed_Serial_Number__c = 'S3F4NXM416324',
          Support_End_Date__c = System.Today().addYears(1),
          Support_Start_Date__c = System.Today(),
          Is_Hardware_Line__c = true,
          Is_Refresh__c = true,
          TPH_Quantity__c = 'Test'
        ),
        new OrderItem(
          OrderId = Ord.Id,
          Quantity = 5,
          PricebookEntryId = lstPbEntries4[1].Id,
          UnitPrice = lstPbEntries4[1].UnitPrice,
          SerialNumber__c = 'SN1',
          Failed_Serial_Number__c = 'S3F4NXM416324',
          Support_End_Date__c = System.Today().addYears(1),
          Support_Start_Date__c = System.Today(),
          Is_Hardware_Line__c = true,
          Is_Refresh__c = true,
          TPH_Quantity__c = 'Test'
        ),
        new OrderItem(
          OrderId = Ord.Id,
          Quantity = 5,
          PricebookEntryId = lstPbEntries4[2].Id,
          UnitPrice = lstPbEntries4[2].UnitPrice,
          SerialNumber__c = 'SN1',
          Failed_Serial_Number__c = 'S3F4NXM416324',
          Support_End_Date__c = System.Today().addYears(1),
          Support_Start_Date__c = System.Today(),
          Is_Hardware_Line__c = true,
          Is_Refresh__c = true,
          TPH_Quantity__c = 'Test'
        ),
        new OrderItem(
          OrderId = Ord.Id,
          Quantity = 5,
          PricebookEntryId = lstPbEntries4[3].Id,
          UnitPrice = lstPbEntries4[3].UnitPrice,
          SerialNumber__c = 'SN1',
          Failed_Serial_Number__c = 'S3F4NXM416324',
          Support_End_Date__c = System.Today().addYears(1),
          Support_Start_Date__c = System.Today(),
          Is_Hardware_Line__c = true,
          Is_Refresh__c = true
        ),
        new OrderItem(
          OrderId = Ord.Id,
          Quantity = 5,
          PricebookEntryId = lstPbEntries4[4].Id,
          UnitPrice = lstPbEntries4[4].UnitPrice,
          SerialNumber__c = 'SN1',
          Failed_Serial_Number__c = 'S3F4NXM416324',
          Support_End_Date__c = System.Today().addYears(1),
          Support_Start_Date__c = System.Today(),
          Is_Hardware_Line__c = true,
          Is_Refresh__c = true
        ),
        new OrderItem(
          OrderId = Ord.Id,
          Quantity = 5,
          PricebookEntryId = lstPbEntries4[5].Id,
          UnitPrice = lstPbEntries4[5].UnitPrice,
          SerialNumber__c = 'SN1',
          Failed_Serial_Number__c = 'S3F4NXM416324',
          Support_End_Date__c = System.Today().addYears(1),
          Support_Start_Date__c = System.Today(),
          Is_Hardware_Line__c = true,
          Is_Refresh__c = true
        ),
        new OrderItem(
          OrderId = Ord.Id,
          Quantity = 5,
          PricebookEntryId = lstPbEntries4[6].Id,
          UnitPrice = lstPbEntries4[6].UnitPrice,
          SerialNumber__c = 'SN1',
          Failed_Serial_Number__c = 'S3F4NXM416324',
          Support_End_Date__c = System.Today().addYears(1),
          Support_Start_Date__c = System.Today(),
          Is_Hardware_Line__c = true,
          Is_Refresh__c = true,
          TPH_Quantity__c = 'Test'
        ),
        new OrderItem(
          OrderId = Ord.Id,
          Quantity = 5,
          PricebookEntryId = lstPbEntries4[7].Id,
          UnitPrice = lstPbEntries4[7].UnitPrice,
          SerialNumber__c = 'SN1',
          Failed_Serial_Number__c = 'S3F4NXM416324',
          Support_End_Date__c = System.Today().addYears(1),
          Support_Start_Date__c = System.Today(),
          Is_Hardware_Line__c = true,
          Is_Refresh__c = true
        ),
        new OrderItem(
          OrderId = Ord.Id,
          Quantity = 5,
          PricebookEntryId = lstPbEntries4[8].Id,
          UnitPrice = lstPbEntries4[8].UnitPrice,
          SerialNumber__c = 'SN1',
          Failed_Serial_Number__c = 'S3F4NXM416324',
          Support_End_Date__c = System.Today().addYears(1),
          Support_Start_Date__c = System.Today(),
          Is_Hardware_Line__c = true,
          Is_Refresh__c = true
        )
                    };
                        insert lstOrderItems4;
            
      List<SBQQ__QuoteLine__c> lines4 = new List<SBQQ__QuoteLine__c>();
      lines4.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote4.Id,
          SBQQ__Product__c = lstProducts4[0].Id,
          SBQQ__Quantity__c = 20,
          SBQQ__SubscriptionPricing__c = null,
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200
        )
      );
      lines4.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote4.Id,
          SBQQ__Product__c = lstProducts4[1].Id,
          MSP_Segment_Product__c = true,
          SBQQ__Quantity__c = 20,
          SBQQ__Segmentindex__c = 1,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200
        )
      );
      lines4.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote4.Id,
          SBQQ__Product__c = lstProducts4[2].Id,
          SBQQ__Quantity__c = 20,
          SBQQ__SubscriptionPricing__c = null,
          SBQQ__DefaultSubscriptionTerm__c = 12,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200
        )
      );
      lines4.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote4.Id,
          SBQQ__Product__c = lstProducts4[3].Id,
          MSP_Segment_Product__c = true,
          SBQQ__Quantity__c = 20,
          SBQQ__Segmentindex__c = 1,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200
        )
      );
      lines4.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote4.Id,
          SBQQ__Product__c = lstProducts4[4].Id,
          MSP_Segment_Product__c = true,
          SBQQ__Quantity__c = 1,
          SBQQ__Segmentindex__c = 1,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200
        )
      );
      lines4.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote4.Id,
          SBQQ__Product__c = lstProducts4[5].Id,
          MSP_Segment_Product__c = true,
          SBQQ__Quantity__c = 1,
          SBQQ__Segmentindex__c = 1,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200
        )
      );
      lines4.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote4.Id,
          SBQQ__Product__c = lstProducts4[6].Id,
          MSP_Segment_Product__c = true,
          SBQQ__Quantity__c = 1,
          SBQQ__Segmentindex__c = 1,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200
        )
      );
      lines4.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote4.Id,
          SBQQ__Product__c = lstProducts4[7].Id,
          MSP_Segment_Product__c = true,
          SBQQ__Quantity__c = 1,
          SBQQ__Segmentindex__c = 1,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200
        )
      );
      lines4.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote4.Id,
          SBQQ__Product__c = lstProducts4[8].Id,
          MSP_Segment_Product__c = true,
          SBQQ__Quantity__c = 1,
          SBQQ__Segmentindex__c = 1,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200
        )
      );

            insert lines4;
            
      ord.Order_Status__c = 'Order Accepted';
      ord.NetSuite_Order__c = 'TEst23NS';
            ord.Have_PS_Products__c = true; 
            ord.SBQQ__Contracted__c = false;
            //ord.Program__c = 'Refresh';
      ord.Actual_Order_Ship_Date__c = System.today();
            ord.Welcome_letter_sent_for_the_first_time__c = true;
            update ord;
        
     TriggerControl.stopSCTrigger = true;       

      ServiceContract objSC4 = new ServiceContract(
        Name = 'ServiceContractTest_' + System.currentTimeMillis(),
        AccountId = act.Id,
        StartDate = Date.today(),
        Term = 36,
        pricebook2Id = pricebookId,
        SBQQSC__Opportunity__c = oppr.Id,
        SBQQSC__Order__c = ord.Id,
        SBQQSC__Quote__c = quote4.Id
      );
            
            insert objSC4;
            
      List<ContractLineItem> cliList4 = new List<ContractLineItem>{
        new ContractLineItem(
          Quantity = lstOrderItems4[0].quantity,
          PricebookEntryId = lstOrderItems4[0].PricebookEntryId,
          ServiceContractId = objSC4.id,
          UnitPrice = lstOrderItems4[0].UnitPrice,
          StartDate = date.today(),
          SBQQSC__QuoteLine__c = lines4[0].Id,
          SBQQSC__OrderProduct__c = lstOrderItems4[0].Id,
          SBQQSC__Product__c = lstProducts4[0].Id
        ),
        new ContractLineItem(
          Quantity = lstOrderItems4[1].quantity,
          PricebookEntryId = lstOrderItems4[1].PricebookEntryId,
          ServiceContractId = objSC4.id,
          UnitPrice = lstOrderItems4[1].UnitPrice,
          StartDate = date.today(),
          SBQQSC__QuoteLine__c = lines4[1].Id,
          SBQQSC__OrderProduct__c = lstOrderItems4[1].Id,
          SBQQSC__Product__c = lstProducts4[1].Id
        ),
        new ContractLineItem(
          Quantity = lstOrderItems4[2].quantity,
          PricebookEntryId = lstOrderItems4[2].PricebookEntryId,
          ServiceContractId = objSC4.id,
          UnitPrice = lstOrderItems4[2].UnitPrice,
          StartDate = date.today(),
          SBQQSC__QuoteLine__c = lines4[2].Id,
          SBQQSC__OrderProduct__c = lstOrderItems4[2].Id,
          SBQQSC__Product__c = lstProducts4[2].Id
        ),
        new ContractLineItem(
          Quantity = lstOrderItems4[3].quantity,
          PricebookEntryId = lstOrderItems4[3].PricebookEntryId,
          ServiceContractId = objSC4.id,
          UnitPrice = lstOrderItems4[3].UnitPrice,
          StartDate = date.today(),
          SBQQSC__QuoteLine__c = lines4[3].Id,
          SBQQSC__OrderProduct__c = lstOrderItems4[3].Id,
          SBQQSC__Product__c = lstProducts4[3].Id
        ),
        new ContractLineItem(
          Quantity = lstOrderItems4[4].quantity,
          PricebookEntryId = lstOrderItems4[4].PricebookEntryId,
          ServiceContractId = objSC4.id,
          UnitPrice = lstOrderItems4[4].UnitPrice,
          StartDate = date.today(),
          SBQQSC__QuoteLine__c = lines4[4].Id,
          SBQQSC__OrderProduct__c = lstOrderItems4[4].Id,
          SBQQSC__Product__c = lstProducts4[4].Id
        ),
        new ContractLineItem(
          Quantity = lstOrderItems4[5].quantity,
          PricebookEntryId = lstOrderItems4[5].PricebookEntryId,
          ServiceContractId = objSC4.id,
          UnitPrice = lstOrderItems4[5].UnitPrice,
          StartDate = date.today(),
          SBQQSC__QuoteLine__c = lines4[5].Id,
          SBQQSC__OrderProduct__c = lstOrderItems4[5].Id,
          SBQQSC__Product__c = lstProducts4[5].Id
        ),
        new ContractLineItem(
          Quantity = lstOrderItems4[6].quantity,
          PricebookEntryId = lstOrderItems4[6].PricebookEntryId,
          ServiceContractId = objSC4.id,
          UnitPrice = lstOrderItems4[6].UnitPrice,
          StartDate = date.today(),
          SBQQSC__QuoteLine__c = lines4[6].Id,
          SBQQSC__OrderProduct__c = lstOrderItems4[6].Id,
          SBQQSC__Product__c = lstProducts4[6].Id
        ),
        new ContractLineItem(
          Quantity = lstOrderItems4[7].quantity,
          PricebookEntryId = lstOrderItems4[7].PricebookEntryId,
          ServiceContractId = objSC4.id,
          UnitPrice = lstOrderItems4[7].UnitPrice,
          StartDate = date.today(),
          SBQQSC__QuoteLine__c = lines4[7].Id,
          SBQQSC__OrderProduct__c = lstOrderItems4[7].Id,
          SBQQSC__Product__c = lstProducts4[7].Id
        )
            };
           insert cliList4;
        /*    for(Product2 prods:[SELECT Id,Product_Subtype__c,License_Category__c,Product_Level__c FROM Product2 WHERE Id IN :lstProducts4]){
                prods.
                prods.;
                prods.;
            }
            update lstProducts4;*/
           /*  List<ContractLineItem> cliList4 = [Select Id,Quantity,PricebookEntryId,ServiceContractId,UnitPrice,
                                              StartDate,SBQQSC__RenewalQuantity__c,SBQQSC__Product__c from ContractLineItem limit 2];
            
            cliList4[0].SBQQSC__RenewalQuantity__c=1;
            cliList4[0].SBQQSC__QuoteLine__c=lines4[0].id;
            cliList4[0].SBQQSC__OrderProduct__c=lstOrderItems4[0].Id;
            cliList4[1].SBQQSC__RenewalQuantity__c=1;
            cliList4[1].SBQQSC__QuoteLine__c=lines4[0].id;
            cliList4[1].SBQQSC__OrderProduct__c=lstOrderItems4[0].Id;
            cliList4[0].SBQQSC__Product__c=lstProducts4[0].id;
            update cliList4;
            
            */
      List<Entitlement> entList4 = [SELECT Id, Type, Order_Service_Item__c FROM Entitlement WHERE Order_Service_Item__c = :ord.Id];
      for (Entitlement ent : entList4) {
        ent.Type = Constants.ENT_TYPE_PHONE_SUPPORT;
            }
            update entList4;
            ord.SBQQ__Contracted__c = false;
            ord.Polaris_Fulfillment_Status__c = 'Completed';
            ord.Status = 'Activated';
            ord.Order_Status__c = 'Shipped';
            //ord.Program__c = 'Refresh';
      ord.Actual_Order_Ship_Date__c = System.today();
            ord.Welcome_letter_sent_for_the_first_time__c = true;
            ord.Order_Sub_Type__c = Constants.ORDER_SUB_TYPE_GC_OFFER;
            ord.SC_or_Entitlement_Stage__c = Constants.SC_ENT_STAGE_CREATE_SERVICE_CONTRACT;
            update ord; 
      ContractOrders batch = new ContractOrders();
           // System.schedule('Test_Contract_Orders_method4', '0 0 * * * ?', batch);
            batch.execute(null);
            System.assertEquals(8, cliList4.size());
            Test.stopTest();
        }
    }
     @isTest
  static void method5() {
    List<user> usr5 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com.invalid'];
        System.runAs(usr5[0]) {
      List<ContractLineItem> cliList5 = [
        SELECT Id, Quantity, PricebookEntryId, ServiceContractId, UnitPrice, StartDate, SBQQSC__RenewalQuantity__c, SBQQSC__Product__c
        FROM ContractLineItem
        LIMIT 2
      ];
      Account customer = [SELECT Id, Name FROM Account WHERE Name = 'Customer' LIMIT 1];
      Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
      List<SBQQ__Quote__c> quoteList5 = [
        SELECT id, SBQQ__Opportunity2__c, SBQQ__SubscriptionTerm__c, Is_RWD_Polaris_Quote__c, SBQQ__PriceBook__c, SBQQ__Type__c
        FROM SBQQ__Quote__c
        LIMIT 10
      ];
                quoteList5[0].SBQQ__Type__c = 'Quote';
                quoteList5[0].Opportunity_Program__c = 'Refresh';
                quoteList5[1].SBQQ__Type__c = 'Renewal+Expansion';
                quoteList5[1].Opportunity_Program__c = 'Refresh';
            update quoteList5;
      List<order> orderList5 = [
        SELECT
          id,
          OrderNumber,
          Status,
          Actual_Order_Ship_Date__c,
          SBQQ__Contracted__c,
          Polaris_Fulfillment_Status__c,
          AccountId,
          OpportunityId,
          Opportunity.Owner.Email,
          Order_Sub_Type__c,
          SBQQ__Quote__c,
          SBQQ__Quote__r.SBQQ__Type__c,
          Program__c,
          ProcessType__c,
          SBQQ__Quote__r.SBQQ__Opportunity2__c,
          Opportunity.Name,
          Opportunity.CloseDate,
          RecordTypeId,
          (
            SELECT
              id,
              quantity,
              product2.Product_Subtype__c,
              product2.Product_Level__c,
              product2.Product_Type__c,
              product2.Name,
              Upgraded_From__c,
              SerialNumber__c,
              Program__c,
              Previous_Contract_Line_Items__c
            FROM OrderItems
          )
        FROM Order
        LIMIT 1
      ];
            orderList5[0].SBQQ__Contracted__c = false;
            orderList5[0].Polaris_Fulfillment_Status__c = 'Completed';
            orderList5[0].Status = 'Activated';
            orderList5[0].Order_Status__c = 'Shipped';
            orderList5[0].Program__c = 'Refresh';
      orderList5[0].Actual_Order_Ship_Date__c = System.today();
            orderList5[0].Welcome_letter_sent_for_the_first_time__c = true;
      orderList5[0].SBQQ__Quote__c = quoteList5[0].Id;
            orderList5[0].Order_Sub_Type__c = 'Renewal';
            orderList5[0].SC_or_Entitlement_Stage__c = Constants.SC_ENT_STAGE_CREATE_SERVICE_CONTRACT;
            update orderList5; 
            
            //List<Order> ordNew=[SELECT Id,Name from Order WHERE Order_Sub_Type__c='Renewal' LIMIT 2];
            
      ServiceContract objSC1Obj = new ServiceContract(
        Name = 'ServiceContractTest1',
        AccountId = customer.Id,
        StartDate = Date.today(),
        Term = 36,
        pricebook2Id = Test.getStandardPricebookId(),
        SBQQSC__Opportunity__c = opp.Id,
        SBQQSC__Order__c = orderList5[0].Id,
        SBQQSC__Quote__c = quoteList5[0].Id
      );
            insert objSC1Obj;
             
      List<OrderItem> orderItemList5 = [
        SELECT
          id,
          OrderId,
          Product2Id,
          UnitPrice,
          SBQQ__QuoteLine__c,
          SBQQ__SubscriptionTerm__c,
          Quantity,
          PricebookEntryId,
          Upgraded_From__c,
          Previous_Contract_Line_Items__c,
          Program__c
        FROM OrderItem
        LIMIT 2
      ];
            
      List<SBQQ__QuoteLine__c> lines5 = [
        SELECT
          id,
          SBQQ__Quote__c,
          SBQQ__Product__c,
          SBQQ__Quantity__c,
          SBQQ__SubscriptionPricing__c,
          SBQQ__DefaultSubscriptionTerm__c,
          SBQQ__ListPrice__c,
          Line_Type__c,
          SBQQ__NetPrice__c,
          Arroyo_Subscribed_Asset_Name__c,
          Disposition_Reason__c,          
          Do_not_Renew__c,//ITNPI-2901
          SBQQ__RequiredBy__c,
          Special_Program__c,
          SBQQ__Product__r.Product_Type__c,
          SBQQ__ProductOption__r.Refresh_Default_Option__c
        FROM SBQQ__QuoteLine__c
        LIMIT 10
      ];
            
      List<Asset> assestInsList5 = [
        SELECT id, Name, SerialNumber, serial_number__c, AccountId, Product2Id
        FROM Asset
        LIMIT 1
      ];
            
            Test.startTest();
            
      SBQQ__QuoteLine__c sbQLIObj = lines5[0].clone();
      sbQLIObj.SBQQ__Renewal__c = true;
      sbQLIObj.SBQQ__Existing__c = true;
      sbQLIObj.SBQQ__Quote__c = quoteList5[0].Id;
      sbQLIObj.SBQQ__RenewedAsset__c = assestInsList5[0].Id;
            
            insert sbQLIObj;

      List<Entitlement> entList5 = [
        SELECT id, Name, RecordTypeId, Type, AccountId, Product__c, StartDate, ServiceContractId, ContractLineItemId, Order_Service_Item__c
        FROM Entitlement
        LIMIT 2
      ];
      entList5[1].Order_Service_Item__c = null;
      entList5[1].Product__c = null;
      entList5[1].Type = Constants.ENT_TYPE_PHONE_SUPPORT;
      entList5[1].AssetId = assestInsList5[0].id;
      entList5[0].AssetId = assestInsList5[0].id;
            update entList5;

      List<Product2> productList5 = [
        SELECT
          id,
          Name,
          ProductCode,
          Category__c,
          Product_Level__c,
          SBQQ__AssetAmendmentBehavior__c,
          SBQQSC__EntitlementConversion__c,
          IsActive,
          CPQ_MSP_Base_Price__c,
          SBQQ__SubscriptionPricing__c,
          SBQQ__SubscriptionTerm__c,
          SBQQ__SubscriptionBase__c,
          SBQQ__SubscriptionType__c,
          Gorefresh_Mark_SW_End_Date__c
        FROM Product2
        WHERE Name = 'RS-TB-EE-RSV-PE'
        LIMIT 2
      ];

      productList5[0].Gorefresh_Mark_SW_End_Date__c = true;
      productList5[0].Product_Level__c = 'LOD Software';
      productList5[0].Name = entList5[1].Name;
            productList5[0].Product_Subtype__c = Constants.PROD_SUB_TYPE_SCALE_MSP;
            productList5[0].License_Category__c = Constants.PROD_LICENSE_CATEGORY_SAAS;
            update productList5;
             
      cliList5[0].SBQQSC__RenewalQuantity__c = 1;
      cliList5[0].SBQQSC__QuoteLine__c = lines5[0].id;
      cliList5[0].SBQQSC__OrderProduct__c = orderItemList5[0].Id;
      cliList5[0].SBQQSC__Product__c = productList5[0].id;
            update cliList5;
          
            ContractLineItem cliObj = new ContractLineItem();
            cliObj.Quantity = orderItemList5[0].quantity;
            cliObj.PricebookEntryId = orderItemList5[0].PricebookEntryId;
      cliObj.ServiceContractId = objSC1Obj.id;
      cliObj.UnitPrice = orderItemList5[0].UnitPrice;
            cliObj.StartDate = date.today();
      cliObj.SBQQSC__RenewalQuantity__c = 1;
      cliObj.SBQQSC__QuoteLine__c = lines5[0].id;
      cliObj.SBQQSC__OrderProduct__c = orderItemList5[0].Id;
            
      ContractLineItem cli2Obj = new ContractLineItem();
            cli2Obj.Quantity = orderItemList5[0].quantity;
            cli2Obj.PricebookEntryId = orderItemList5[0].PricebookEntryId;
      cli2Obj.ServiceContractId = objSC1Obj.id;
      cli2Obj.UnitPrice = orderItemList5[0].UnitPrice;
            cli2Obj.StartDate = date.today();
      cli2Obj.SBQQSC__RenewalQuantity__c = 1;
      cli2Obj.SBQQSC__QuoteLine__c = sbQLIObj.id;
      cli2Obj.SBQQSC__OrderProduct__c = orderItemList5[0].Id;
      insert new List<ContractLineItem>{ cliObj, cli2Obj };
      ContractOrders batch = new ContractOrders();
            batch.execute(null);
            System.assertEquals(1, orderList5.size());
            Test.stopTest();
        }
    }
   @isTest
  static void method6() {
    List<user> usr6 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com.invalid'];
        System.runAs(usr6[0]) {
      List<order> orderList6 = [
        SELECT
          id,
          OrderNumber,
          Status,
          Actual_Order_Ship_Date__c,
          SBQQ__Contracted__c,
          Polaris_Fulfillment_Status__c,
          AccountId,
          OpportunityId,
          Opportunity.Owner.Email,
          Order_Sub_Type__c,
          SBQQ__Quote__c,
          SBQQ__Quote__r.SBQQ__Type__c,
          ProcessType__c,
          SBQQ__Quote__r.SBQQ__Opportunity2__c,
          Opportunity.Name,
          Opportunity.CloseDate,
          RecordTypeId,
          (
            SELECT
              id,
              order.opportunity.name,
              Global_Commit_ID__c,
              Order.Order_Sub_Type__c,
              quantity,
              Product2.License_Category__c,
              product2.Product_Subtype__c,
              product2.Product_Level__c,
              product2.Product_Type__c,
              product2.Name,
              Upgraded_From__c,
              SerialNumber__c,
              Program__c,
              Previous_Contract_Line_Items__c
            FROM OrderItems
            ORDER BY product2.name ASC
          )
        FROM Order
      ];
            
      List<OrderItem> orderItemList6 = [
        SELECT
          id,
          Global_Commit_ID__c,
          Order.Order_Sub_Type__c,
          Product2.Product_Subtype__c,
          Product2.Product_Type__c,
          Product2.License_Category__c,
          product2.Name,
          order.AccountId,
          SBQQ__RequiredBy__c,
          SBQQ__RequiredBy__r.Product2.Name,
          OrderId,
          Product2Id,
          UnitPrice,
          SBQQ__QuoteLine__c,
          SBQQ__SubscriptionTerm__c,
          Quantity,
          PricebookEntryId,
          Upgraded_From__c,
          Previous_Contract_Line_Items__c,
          Program__c,
          product2.Bundle_Features__c
        FROM OrderItem
      ];
            
      List<SBQQ__Quote__c> quoteList6 = [
        SELECT id, SBQQ__Opportunity2__c, SBQQ__SubscriptionTerm__c, Is_RWD_Polaris_Quote__c, SBQQ__PriceBook__c, SBQQ__Type__c
        FROM SBQQ__Quote__c
        LIMIT 10
      ];
            
            quoteList6[0].SBQQ__Type__c = 'Quote';
            quoteList6[0].Opportunity_Program__c = 'Refresh';
            update quoteList6;
      List<SBQQ__QuoteLine__c> lines6 = [
        SELECT
          id,
          SBQQ__Quote__c,
          SBQQ__Product__c,
          SBQQ__Quantity__c,
          SBQQ__SubscriptionPricing__c,
          SBQQ__DefaultSubscriptionTerm__c,
          SBQQ__ListPrice__c,
          SBQQ__NetPrice__c,
          Arroyo_Subscribed_Asset_Name__c,
          Disposition_Reason__c,
          Do_not_Renew__c,//ITNPI-2901
          SBQQ__RequiredBy__c,
          Special_Program__c,
          SBQQ__Product__r.Product_Type__c,
          SBQQ__ProductOption__r.Refresh_Default_Option__c
        FROM SBQQ__QuoteLine__c
        LIMIT 10
      ];
            
      List<Product2> productList6 = [
        SELECT
          id,
          Name,
          ProductCode,
          Category__c,
          Product_Level__c,
          SBQQ__AssetAmendmentBehavior__c,
          SBQQSC__EntitlementConversion__c,
          IsActive,
          CPQ_MSP_Base_Price__c,
          SBQQ__SubscriptionPricing__c,
          SBQQ__SubscriptionTerm__c,
          SBQQ__SubscriptionBase__c,
          SBQQ__SubscriptionType__c,
          Gorefresh_Mark_SW_End_Date__c
        FROM Product2
        LIMIT 2
      ];
            
      productList6[0].Gorefresh_Mark_SW_End_Date__c = true;
      productList6[0].Product_Level__c = 'LOD Software';
            productList6[0].Product_Subtype__c = Constants.PROD_SUB_TYPE_SCALE_MSP;
            productList6[0].License_Category__c = Constants.PROD_LICENSE_CATEGORY_SAAS;
           // productList6[1].Gorefresh_Mark_SW_End_Date__c=false;
            update productList6;
            
            Test.startTest();
            
            orderList6[0].SBQQ__Contracted__c = false;
            orderList6[0].Polaris_Fulfillment_Status__c = 'Completed';
            orderList6[0].Status = 'Activated';
            orderList6[0].Order_Status__c = 'Shipped';
            orderList6[0].Program__c = 'Refresh';
      orderList6[0].Actual_Order_Ship_Date__c = System.today();
            orderList6[0].Welcome_letter_sent_for_the_first_time__c = true;
      orderList6[0].SBQQ__Quote__c = quoteList6[0].Id;
            orderList6[0].Order_Sub_Type__c = Constants.ORDER_SUB_TYPE_GC_OFFER;
            orderList6[0].SC_or_Entitlement_Stage__c = Constants.SC_ENT_STAGE_CREATE_SERVICE_CONTRACT;
            update orderList6; 
               List<Orderitem> OIToUpdate = new List<Orderitem>();
      for (order ord : orderList6) {
        for (orderitem oi : ord.OrderItems) {
          if (
            ord.Order_Sub_Type__c == Constants.ORDER_SUB_TYPE_GC_OFFER &&
            OI.Product2.Product_Subtype__c == 'Scale MSP' &&
            OI.Product2.Product_Type__c != 'M365H' &&
            (OI.Product2.License_Category__c == null ||
            OI.Product2.License_Category__c == 'SaaS')
          ) {
                        OI.Global_Commit_ID__c = OI.Global_Commit_Split_ID__c = ord.Id + '-' + 'RS-TB-EE-RSVX-PE';  
                    } 
          if (
            ord.Order_Sub_Type__c == Constants.ORDER_SUB_TYPE_GC_OFFER &&
            OI.Product2.Product_Subtype__c == 'Scale MSP' &&
            OI.Product2.Product_Type__c == 'M365H' &&
            (OI.Product2.License_Category__c == null ||
            OI.Product2.License_Category__c == 'SaaS')
          ) {
            OI.Global_Commit_ID__c = OI.Global_Commit_Split_ID__c = ord.Id + '-' + 'RS-UR-EE-MD-RSVX-L3';
                    } 
                    
                    oi.Program__c = 'Refresh';
                    oi.Upgraded_From__c = '09092019APMSP1250';
                    OIToUpdate.add(oi);
                }
            }
            update OIToUpdate;
      Map<String, Id> globalCommitIToOrder = new Map<String, Id>(); // CSU-444
      Map<String, String> globalCommitIdToLicenceName = new Map<String, String>(); // CSU-686
    
      for (orderitem OI : OIToUpdate) {
        if (OI.Global_Commit_ID__c != null) {
          globalCommitIdToLicenceName.put(OI.Global_Commit_Split_ID__c, OI.product2.Name + '-' + OI.order.opportunity.Name);
          globalCommitIToOrder.put(OI.Global_Commit_Split_ID__c, OI.OrderId);
                 }
            }
                  Map<String, ContractLineItem> upgradedQLICLIMap = new Map<String, ContractLineItem>();

      List<ContractLineItem> cliList6 = [
        SELECT
          Id,
          Global_Commit_Split_ID__c,
          Global_Commit_ID__c,
          SBQQSC__QuoteLine__c,
          SBQQSC__Product__r.Name,
          SBQQSC__Product__r.Product_Type__c,
          SBQQSC__Product__r.License_Category__c,
          SBQQSC__Product__r.Product_Subtype__c,
          Quantity,
          PricebookEntryId,
          ServiceContractId,
          UnitPrice,
          StartDate,
          SBQQSC__RenewalQuantity__c,
          SBQQSC__Product__c
        FROM ContractLineItem
        ORDER BY SBQQSC__Product__r.name ASC
      ];
      for (ContractLineItem CLI : cliList6) {
        if (
          CLI.SBQQSC__Product__r.Product_Type__c == Constants.PRODUCT_TYPE_EDITION_UPGRADE &&
                    CLI.SBQQSC__Product__r.Product_Subtype__c == Constants.PROD_SUB_TYPE_SCALE_MSP &&
          CLI.SBQQSC__Product__r.License_Category__c == Constants.LICENSE_CATEGORY
        ) {
                        upgradedQLICLIMap.put(CLI.SBQQSC__QuoteLine__c, CLI);
                    }
            }
            
      cliList6[0].SBQQSC__RenewalQuantity__c = 1;
      cliList6[0].SBQQSC__QuoteLine__c = lines6[0].id;
      cliList6[0].SBQQSC__OrderProduct__c = orderItemList6[0].Id;
      cliList6[1].SBQQSC__RenewalQuantity__c = 1;
      cliList6[1].SBQQSC__QuoteLine__c = lines6[0].id;
      cliList6[1].SBQQSC__OrderProduct__c = orderItemList6[0].Id;
      cliList6[0].SBQQSC__Product__c = productList6[0].id;
            
      cliList6[7].SBQQSC__OrderProduct__c = OIToUpdate[9].id;
      cliList6[8].SBQQSC__OrderProduct__c = OIToUpdate[10].id;
      cliList6[9].SBQQSC__OrderProduct__c = OIToUpdate[11].id;
      cliList6[10].SBQQSC__OrderProduct__c = OIToUpdate[14].id;
            
            update cliList6;
            
      ContractOrders batch = new ContractOrders();
            System.schedule('Test_Contract_Orders_method4', '0 0 * * * ?', batch);
            batch.execute(null);
            Queueable nextJob; 
      if (!globalCommitIToOrder.isEmpty() && globalCommitIToOrder.keyset().size() > 1) {
        nextJob = new SplitGCOfferServiceContractQueueable(globalCommitIToOrder.keyset(), globalCommitIToOrder.values()[0], globalCommitIdToLicenceName, nextJob);
            }
                
             System.enqueueJob(nextJob);
            
      if (!upgradedQLICLIMap.isempty())
            nextJob = new SplitGCOfferServiceContractQueueable(upgradedQLICLIMap, nextJob);
 
             System.enqueueJob(nextJob);
           
      System.assertEquals(4, orderList6.size());
            Test.stopTest();
        }
    }
    @isTest
  static void method7() {
    List<user> usr7 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com.invalid'];
        System.runAs(usr7[0]) {
      List<ContractLineItem> cliList = [
        SELECT Id, Quantity, PricebookEntryId, ServiceContractId, UnitPrice, StartDate, SBQQSC__RenewalQuantity__c, SBQQSC__Product__c
        FROM ContractLineItem
        LIMIT 2
      ];
      Account customer = [SELECT Id, Name FROM Account WHERE Name = 'Customer' LIMIT 1];
      Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
      List<SBQQ__Quote__c> quoteList7 = [
        SELECT id, SBQQ__Opportunity2__c, SBQQ__SubscriptionTerm__c, Is_RWD_Polaris_Quote__c, SBQQ__PriceBook__c, SBQQ__Type__c
        FROM SBQQ__Quote__c
        LIMIT 10
      ];
                quoteList7[0].SBQQ__Type__c = 'Quote';
                quoteList7[0].Opportunity_Program__c = 'Refresh';
                quoteList7[1].SBQQ__Type__c = 'Renewal+Expansion';
                quoteList7[1].Opportunity_Program__c = 'Refresh';
            update quoteList7;
      List<order> orderList7 = [
        SELECT
          id,
          OrderNumber,
          Status,
          Actual_Order_Ship_Date__c,
          SBQQ__Contracted__c,
          Polaris_Fulfillment_Status__c,
          AccountId,
          OpportunityId,
          Opportunity.Owner.Email,
          Order_Sub_Type__c,
          SBQQ__Quote__c,
          SBQQ__Quote__r.SBQQ__Type__c,
          ProcessType__c,
          SBQQ__Quote__r.SBQQ__Opportunity2__c,
          Opportunity.Name,
          Opportunity.CloseDate,
          RecordTypeId,
          (
            SELECT
              id,
              Support_Start_Date__c,
              Support_End_Date__c,
              TPH_Quantity__c,
              Product2Id,
              quantity,
              product2.Product_Subtype__c,
              product2.Product_Level__c,
              product2.Product_Type__c,
              product2.Name,
              Upgraded_From__c,
              SerialNumber__c,
              Program__c,
              Previous_Contract_Line_Items__c
            FROM OrderItems
          )
        FROM Order
        LIMIT 1
      ];
            orderList7[0].SBQQ__Contracted__c = false;
            orderList7[0].Polaris_Fulfillment_Status__c = 'Completed';
            orderList7[0].Status = 'Activated';
            orderList7[0].Order_Status__c = 'Shipped';
            orderList7[0].Program__c = 'Refresh';
      orderList7[0].Actual_Order_Ship_Date__c = System.today();
            orderList7[0].Welcome_letter_sent_for_the_first_time__c = true;
      orderList7[0].SBQQ__Quote__c = quoteList7[0].Id;
            orderList7[0].Order_Sub_Type__c = Constants.ORDER_SUB_TYPE_GC_OFFER;
            orderList7[0].Actual_Order_Ship_Date__c = system.today();
            orderList7[0].SC_or_Entitlement_Stage__c = Constants.SC_ENT_STAGE_CREATE_SERVICE_CONTRACT;
            update orderList7; 
            
            //List<Order> ordNew=[SELECT Id,Name from Order WHERE Order_Sub_Type__c='Renewal' LIMIT 2];
            
      ServiceContract objSC1 = new ServiceContract(
        Name = 'ServiceContractTest1',
        AccountId = customer.Id,
        StartDate = Date.today(),
        Term = 36,
        pricebook2Id = Test.getStandardPricebookId(),
        SBQQSC__Opportunity__c = opp.Id,
        SBQQSC__Order__c = orderList7[0].Id,
        SBQQSC__Quote__c = quoteList7[0].Id
      );
            insert objSC1;

      List<OrderItem> orderItemList = [
        SELECT
          id,
          OrderId,
          Product2Id,
          UnitPrice,
          SBQQ__QuoteLine__c,
          SBQQ__SubscriptionTerm__c,
          Quantity,
          PricebookEntryId,
          Upgraded_From__c,
          Previous_Contract_Line_Items__c,
          Program__c
        FROM OrderItem
        LIMIT 2
      ];
            
      List<SBQQ__QuoteLine__c> lines = [
        SELECT
          id,
          SBQQ__Quote__c,
          SBQQ__Product__c,
          SBQQ__Quantity__c,
          SBQQ__SubscriptionPricing__c,
          SBQQ__DefaultSubscriptionTerm__c,
          SBQQ__ListPrice__c,
          Line_Type__c,
          SBQQ__NetPrice__c,
          Arroyo_Subscribed_Asset_Name__c,
          Disposition_Reason__c,
          Do_not_Renew__c,//ITNPI-2901
          SBQQ__RequiredBy__c,
          Special_Program__c,
          SBQQ__Product__r.Product_Type__c,
          SBQQ__ProductOption__r.Refresh_Default_Option__c
        FROM SBQQ__QuoteLine__c
        LIMIT 10
      ];
            
      List<Asset> assestInsList = [
        SELECT id, Name, SerialNumber, serial_number__c, AccountId, Product2Id
        FROM Asset
        LIMIT 1
      ];
             Test.startTest();
      SBQQ__QuoteLine__c sbQLI = lines[0].clone();
      sbQLI.SBQQ__Renewal__c = true;
      sbQLI.SBQQ__Existing__c = true;
      sbQLI.SBQQ__Quote__c = quoteList7[0].Id;
      sbQLI.SBQQ__RenewedAsset__c = assestInsList[0].Id;
            
            insert sbQLI;

      List<Entitlement> entList = [
        SELECT id, Name, RecordTypeId, Type, AccountId, Product__c, StartDate, ServiceContractId, ContractLineItemId, Order_Service_Item__c
        FROM Entitlement
        LIMIT 2
      ];
      entList[1].Order_Service_Item__c = null;
      entList[1].Product__c = null;
      entList[1].Type = Constants.ENT_TYPE_PHONE_SUPPORT;
      entList[1].AssetId = assestInsList[0].id;
      entList[0].AssetId = assestInsList[0].id;
            update entList;
            
      List<Product2> productList = [
        SELECT
          id,
          Name,
          ProductCode,
          Category__c,
          Product_Level__c,
          SBQQ__AssetAmendmentBehavior__c,
          SBQQSC__EntitlementConversion__c,
          IsActive,
          CPQ_MSP_Base_Price__c,
          SBQQ__SubscriptionPricing__c,
          SBQQ__SubscriptionTerm__c,
          SBQQ__SubscriptionBase__c,
          SBQQ__SubscriptionType__c,
          Gorefresh_Mark_SW_End_Date__c
        FROM Product2
        WHERE Name = 'RS-TB-EE-RSV-PE'
        LIMIT 2
      ];
            
      productList[0].Gorefresh_Mark_SW_End_Date__c = true;
      productList[0].Product_Level__c = 'LOD Software';
      productList[0].Name = entList[1].Name;
            productList[0].Product_Subtype__c = Constants.PROD_SUB_TYPE_SCALE_MSP;
            productList[0].License_Category__c = Constants.PROD_LICENSE_CATEGORY_SAAS;
            update productList;
             
      cliList[0].SBQQSC__RenewalQuantity__c = 1;
      cliList[0].SBQQSC__QuoteLine__c = lines[0].id;
      cliList[0].SBQQSC__OrderProduct__c = orderItemList[0].Id;
      cliList[0].SBQQSC__Product__c = productList[0].id;
      cliList[1].SBQQSC__RenewalQuantity__c = 1;
      cliList[1].SBQQSC__QuoteLine__c = lines[0].id;
      cliList[1].SBQQSC__OrderProduct__c = orderItemList[0].Id;
      cliList[1].SBQQSC__Product__c = productList[0].id;
            update cliList;
          
            ContractLineItem cli = new ContractLineItem();
            cli.Quantity = orderItemList[0].quantity;
            cli.PricebookEntryId = orderItemList[0].PricebookEntryId;
      cli.ServiceContractId = objSC1.id;
      cli.UnitPrice = orderItemList[0].UnitPrice;
            cli.StartDate = date.today();
      cli.SBQQSC__RenewalQuantity__c = 1;
      cli.SBQQSC__QuoteLine__c = lines[0].id;
      cli.SBQQSC__OrderProduct__c = orderItemList[0].Id;
            
      ContractLineItem cli2 = new ContractLineItem();
            cli2.Quantity = orderItemList[0].quantity;
            cli2.PricebookEntryId = orderItemList[0].PricebookEntryId;
      cli2.ServiceContractId = objSC1.id;
      cli2.UnitPrice = orderItemList[0].UnitPrice;
            cli2.StartDate = date.today();
      cli2.SBQQSC__RenewalQuantity__c = 1;
      cli2.SBQQSC__QuoteLine__c = sbQLI.id;
      cli2.SBQQSC__OrderProduct__c = orderItemList[1].Id;
      insert new List<ContractLineItem>{ cli, cli2 };
      ContractOrders batch = new ContractOrders();
            batch.execute(null);
            
      entList.add(
        new Entitlement(
          Name = 'Manufacturing ENT',
          Type = 'Manufacturing Entitlement',
          AccountId = customer.Id,
          Product__c = productList[0].Id,
          StartDate = null,
          EndDate = null,
          ServiceContractId = objSC1.Id,
          ContractLineItemId = cliList[0].Id,
          Order_Service_Item__c = orderList7[0].OrderItems[0].id
        )
      );
            insert  entList[2]; 
            
            orderList7[0].OrderItems[0].Support_Start_Date__c = system.today();
            orderList7[0].OrderItems[0].Support_End_Date__c = system.today().addMonths(1);
            orderList7[0].OrderItems[0].TPH_Quantity__c = '0';
            update orderList7[0].OrderItems[0];
            
      product2 prObj = new product2(id = orderList7[0].OrderItems[0].Product2Id, Product_Subtype__c = Constants.PROD_SUB_TYPE_SCALE_MSP, License_Category__c = '');
            update prObj;
      ManufacturingEntitlementsDateUpdate mbatch = new ManufacturingEntitlementsDateUpdate();
            mbatch.execute(null);
            
            orderList7[0].OrderItems[0].Support_Start_Date__c = null;
            orderList7[0].OrderItems[0].Support_End_Date__c = null;
            orderList7[0].OrderItems[0].TPH_Quantity__c = '0';
            update orderList7[0].OrderItems[0];
            
      ManufacturingEntitlementsDateUpdate mbatchNew = new ManufacturingEntitlementsDateUpdate();
            mbatchNew.execute(null);
            System.assertEquals(1, orderList7.size());
            Test.stopTest();
        }
    }
  @isTest
  static void testReplacementOrd1() {
  
    insert new ShGl_DisableBusinessLogic__c(
      setupownerid = userinfo.getUserId(),
      Disable_Entitlement_Validation_Rules__c = true,
      Disable_Account_Triggers__c = true,
      Disable_Asset_Triggers__c = true,
      Disable_SBQQ_Quote_Triggers__c = true,
      Disable_SBQQ_QuoteLine_Triggers__c = true,
      Disable_Product2_Validation_Rules__c = true,
      Disable_Order_Old_Trigger__c = true,
      Disable_OrderItem_Old_Trigger__c = true,
      Disable_Opportunity_Triggers__c = true,
      Disable_Product2_Trigger__c = true,
      Disable_Order_Validation_Rules__c = true,
      Disable_SBQQ_QuoteLine_Validation_Rules__c = true
    );
    List<Asset> lstofAsset = [SELECT id FROM Asset LIMIT 1];
    List<OrderItem> existingOrdItem = [SELECT id FROM OrderItem WHERE quantity != NULL LIMIT 1];
    List<SBQQ__QuoteLine__c> qliList = [SELECT id, Replacement_details__c FROM SBQQ__QuoteLine__c];
    List<OrderItem> lstofordItem = new List<OrderItem>();
    List<Scale_Entitlement__c> linkedAssets = new List<Scale_Entitlement__c>();
    List<Entitlement> lstofEnt = [SELECT id, Order_Service_Item__r.Quantity, quantity__c, Order_Service_Item__c FROM Entitlement];
    for (Entitlement ent : lstofEnt) {
      ent.startdate = System.today();
      ent.EndDate = System.today().addMonths(1);
      ent.Quantity__c = 10;
      ent.Order_Service_Item__c = existingOrdItem[0].Id;
      linkedAssets.add(new Scale_Entitlement__c(Asset__c = lstofAsset[0].id, Entitlement__c = ent.id, Order_Product__c = ent.Order_Service_Item__c));
    }
    update lstofent;
    String replacementDetails = '{"targetProductType" : "Non-Hardware","skuStorageTierVal":null,"skuStorageBundleVal":null,"skuSFDCVal":null,"skuSelectedName":"RS-BT-EE-PE-PA","skuSelected":"01t6f00000O6dT0AAJ","skuM365HVal":null,"skuAttlasianVal":null,"SeamlessCutover":null,"rowValues":[{"UpgradeLines":null,"selectedQty":300,"selectedAssetList":{"02i6f00000IfP9gAAF":"BB210464100059","02i6f00000IfPBSAA3":"BB210364100020","02i6f00000IrOTzAAN":"BB211364100028","02i6f00000IrOUJAA3":"BB211364100030"},"selectedAsset":"02i6f00000IrOUJAA3,02i6f00000IrOTzAAN,02i6f00000IfPBSAA3,02i6f00000IfP9gAAF","rowId":"2.1.0","InactiveLines":[{"childrowId":null,"childQnty":270,"childEntId":"550VI00000938QkYAI"}],"entId":"550VI000007aYKAYA2","disposition":"Converted","selectedTerm":12}],"mode":"1to1"}';
    for (SBQQ__QuoteLine__c qli : qliList) {
      qli.Replacement_details__c = replacementDetails;
      qli.special_program__c = 'Conversion';
    }

    update qlilist;
    insert linkedAssets;
    Entitlement_Links__c entLink = new Entitlement_Links__c();
    entLink.Previous_Entitlement__c = lstofEnt[0].id;
    entLink.Renewed_Entitlement__c = lstofEnt[0].id;
    entLink.quantity__c = 10;
    //entLink.Renewal_Category__c = 'Converted';
    entLink.Type__c = 'Split-Surviving';
    insert entLink;
    SplitOrder sp = new SplitOrder();
    List<Order> replacedOrds = [
      SELECT
        id,
        Ordernumber,
        Order_Sub_Type__c,
        SBQQ__Contracted__c,
        Polaris_Fulfillment_Status__c,
        Status,
        Order_Status__c,
        Actual_Order_Ship_Date__c,
        Welcome_letter_sent_for_the_first_time__c,
        (SELECT id, Enddate, order.ordernumber, Previous_Transaction_Reference__c FROM orderitems)
      FROM Order
      LIMIT 2
    ];
    Order phantomOrder = [SELECT Id, Ordernumber FROM Order WHERE Type = 'Revenue Internal' LIMIT 1];

    replacedOrds[0].SBQQ__Contracted__c = false;
    replacedOrds[0].Polaris_Fulfillment_Status__c = 'Completed';
    replacedOrds[0].Status = 'Activated';
    replacedOrds[0].Order_Status__c = 'Shipped';
    replacedOrds[0].Actual_Order_Ship_Date__c = System.today().addDays(-30);
    replacedOrds[0].Order_Accepted_Timestamp__c = Datetime.newInstance(2025, 2, 20);
    replacedOrds[0].Line_Types__c = 'Conversion';
    replacedOrds[0].Welcome_letter_sent_for_the_first_time__c = true;
    replacedOrds[0].Associated_Order_Numbers__c = phantomOrder.Ordernumber;

    List<Order_Item_Extension__c> oiExtension = new List<Order_Item_Extension__c>();

    for (Orderitem oi : replacedOrds[0].orderitems) {
      oi.Previous_Transaction_Reference__c =
        '[{\"usedEntitlementQuantity\":5.00,\"phantomOrderItemId\":null,\"orderItemId\":\"' +
        lstofEnt[0].Order_Service_Item__c +
        '\",\"orderItemRemainingQuantity\":5.00,\"entId\":\"' +
        lstofEnt[0].id +
        '\"}]';
      oi.SBQQ__Contracted__c = false;
      oi.Program__c = 'Conversion';
      oiExtension.add(
        new Order_Item_Extension__c(
          Name = 'Test' + oi.id,
          Invoice_Number__c = oi.order.ordernumber,
          OI_ExternalID__c = oi.id,
          Order_Line_ID__c = oi.id,
          End_of_Paid_Term__c = system.today().addDays(90)
        )
      );
      lstofordItem.add(oi);
    }
    update lstofordItem;
    Test.starttest();
    update replacedOrds;
    insert oiExtension;

    ContractOrders replacedordtest = new ContractOrders();
    System.schedule('Test_Contract_Orders_Conversion', '0 0 * * * ?', replacedordtest);
    replacedordtest.execute(null);
    System.assert(replacedOrds[0].id != null);
    Test.stoptest();
  }
 

  @isTest
   static void renewalConversionMethod4() {
    List<user> usr = [SELECT Id FROM User WHERE email = 'testuser@testclass.com.invalid'];
    System.runAs(usr[1]) {
          
      insert new ShGl_DisableBusinessLogic__c(
        setupownerid = userinfo.getUserId(),
        Disable_Entitlement_Validation_Rules__c = true,
        Disable_Account_Triggers__c = true,
        Disable_Asset_Triggers__c = true,
        Disable_SBQQ_Quote_Triggers__c = true,
        Disable_Product2_Validation_Rules__c = true,
        Disable_SBQQ_QuoteLine_Triggers__c = true,
        Disable_Order_Old_Trigger__c = true,
        Disable_OrderItem_Old_Trigger__c = true,
        Disable_Opportunity_Triggers__c = true,
                                                    Disable_Order_Validation_Rules__c = true,
        Disable_SBQQ_QuoteLine_Validation_Rules__c = true
      );
      TriggerControl.stopOrderItemTrigger = true;
      TriggerControl.stopOrderTrigger = true;

      Test.startTest();

      List<Account> lstAccount1 = [SELECT Id FROM Account LIMIT 1];
      List<Asset> lstAsset = [SELECT Id, SerialNumber FROM Asset WHERE SerialNumber = '09092019APMSP1250'];
      Opportunity opp3 = TestDataFactory.getOpportunity();
      opp3.Partner_Lookup__c = lstAccount1[0].Id;
      opp3.AccountId = lstAccount1[0].Id;
      opp3.Distributor_Lookup__c = opp3.AccountId;
      opp3.Pricebook2id = Test.getStandardPricebookId();
      insert opp3;
      Entitlement entRec = [SELECT id FROM Entitlement LIMIT 1];

      SBQQ__Quote__c quoteObjNew = new SBQQ__Quote__c(
        SBQQ__Opportunity2__c = opp3.Id,
        SBQQ__SubscriptionTerm__c = 12,
        Is_RWD_Polaris_Quote__c = true,
        SBQQ__Primary__c = true,
        ApprovalStatus__c = 'Recalled',
        SBQQ__Type__c = 'Renewal+Expansion',
        SBQQ__PriceBook__c = Test.getStandardPricebookId()
      );
      insert quoteObjNew;
      List<Product2> sampleProducts2 = [SELECT Id, ProductCode FROM Product2 LIMIT 12];
      List<PricebookEntry> entries = [SELECT Id, UnitPrice FROM PricebookEntry LIMIT 12];
      List<SBQQ__QuoteLine__c> lines10 = new List<SBQQ__QuoteLine__c>();
      lines10.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quoteObjNew.Id,
          SBQQ__Product__c = sampleProducts2[0].Id,
          SBQQ__PricebookEntryId__c = entries[0].Id,
          MSP_Segment_Product__c = true,
          SBQQ__Quantity__c = 70,
          SBQQ__Segmentindex__c = 1,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          Disposition_Reason__c = 'Renewing',
          Special_Program__c = 'Conversion'
        )
      );
      lines10.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quoteObjNew.Id,
          SBQQ__Product__c = sampleProducts2[6].Id,
          SBQQ__PricebookEntryId__c = entries[6].Id,
          MSP_Segment_Product__c = true,
          SBQQ__Quantity__c = 1,
          SBQQ__Segmentindex__c = 1,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          SBQQ__Existing__c = true
        )
      );
      lines10.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quoteObjNew.Id,
          SBQQ__Product__c = sampleProducts2[4].Id,
          SBQQ__PricebookEntryId__c = entries[4].Id,
          MSP_Segment_Product__c = true,
          SBQQ__Quantity__c = 1,
          SBQQ__Segmentindex__c = 1,
          SBQQ__Renewal__c = true,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          Disposition_Reason__c = 'Renewing',
          Special_Program__c = 'Conversion'
        )
      );
      lines10.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quoteObjNew.Id,
          SBQQ__Product__c = sampleProducts2[5].Id,
          SBQQ__PricebookEntryId__c = entries[5].Id,
          SBQQ__Quantity__c = 42,
          SBQQ__SubscriptionPricing__c = null,
          SBQQ__StartDate__c = System.today().addMonths(4).addDays(-6),
          SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1),
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200
        )
      );
      insert lines10;

      Product2 prod = new Product2(Id = sampleProducts2[4].Id, Upgrade_Path__c = 'Foundation to Enterprise');
      update prod;
      List<Product2> sampleProductslistupd = new List<Product2>();
      for (Product2 pd : sampleProducts2) {
        pd.Custom_Renewal_Attributes__c = '{"RCVProd":"' + pd.id + '", "RCVProdPricebook":"01u6f00000JkJEVAA3", "RCVProdOption":"a6LVI0000000lwf2AA", "RCVQuantRatio":3}';
        sampleProductslistupd.add(pd);
      }
      update sampleProductslistupd;
      List<ContractLineItem> lstContractLineItems = [SELECT Id FROM ContractLineItem LIMIT 7];
      lines10[0].SBQQ__Bundle__c = true;
      lines10[0].Arroyo_Subscribed_Asset_Name__c = lstAsset[0].SerialNumber;
      lines10[0].Disposition_Reason__c = 'Churn';
      lines10[0].Arroyo_Subsumed_Old_Contract_Line_Items__c = lstContractLineItems[0].Id;
      lines10[1].SBQQ__RequiredBy__c = lines10[0].Id;
      lines10[2].SBQQ__RequiredBy__c = lines10[1].Id;
      lines10[2].Arroyo_Subscribed_Asset_Name__c = lstAsset[0].SerialNumber;
      lines10[2].Disposition_Reason__c = 'Replaced';
      lines10[2].Arroyo_Subsumed_Old_Contract_Line_Items__c = lstContractLineItems[1].Id;
      lines10[3].SBQQ__RequiredBy__c = lines10[0].Id;

      update lines10;

      quoteObjNew.ApprovalStatus__c = 'Approved';
      update quoteObjNew;
      List<Order> OrderListUp = new List<Order>();
      for (Order o : [SELECT id FROM order]) {
        o.Is_RWD_Polaris_Quote__c = false;
        OrderListUp.add(o);
      }
      update OrderListUp;
      Order orderInstance1 = new Order();
      orderInstance1.AccountId = lstAccount1[0].Id;
      orderInstance1.OpportunityId = opp3.Id;
      orderInstance1.EffectiveDate = system.today();
      orderInstance1.Status = 'Draft';
      orderInstance1.Type = 'Revenue';
      orderInstance1.Order_Status__c = 'Pending';
      //orderInstance1.Program__c = 'Conversion';
      //orderInstance1.Order_Sub_type__c = 'Renewal';
      orderInstance1.Order_Sub_type__c = 'CSAT Extension';
      orderInstance1.Is_RWD_Polaris_Quote__c = true;
      orderInstance1.Pricebook2Id = Test.getStandardPricebookId();
      orderInstance1.SC_or_Entitlement_Stage__c = Constants.SC_ENT_STAGE_CREATE_SERVICE_CONTRACT;
      orderInstance1.Program__c ='25% Premium RSC-G Replacement';
      insert orderInstance1;

      List<OrderItem> orderItemList = new List<OrderItem>{
        new OrderItem(
          OrderId = orderInstance1.Id,
          Previous_Contract_Line_Items__c = lstContractLineItems[0].Id + ',' + lstContractLineItems[4].Id,
          Product2Id = sampleProducts2[0].Id,
          Upgraded_From__c = '09092019APMSP1250',
          SerialNumber__c = '09092019APMSP1250',
          UnitPrice = entries[0].UnitPrice,
          SBQQ__QuoteLine__c = lines10[0].Id,
          SBQQ__SubscriptionTerm__c = 36,
          SBQQ__Segmentindex__c = 2,
          Support_Start_Date__c = System.today(),
          Program__c = 'Conversion',
          Quantity = 20,
          PricebookEntryId = entries[0].Id
        ),
        new OrderItem(
          OrderId = orderInstance1.Id,
          Previous_Contract_Line_Items__c = lstContractLineItems[3].Id,
          Entitlement_Id__c = String.valueof(entRec.id),
          Product2Id = sampleProducts2[4].Id,
          Upgraded_From__c = '09092019APMSP1250',
          SerialNumber__c = '09092019APMSP1250',
          UnitPrice = entries[4].UnitPrice,
          SBQQ__QuoteLine__c = lines10[2].Id,
          SBQQ__SubscriptionTerm__c = 36,
          SBQQ__Segmentindex__c = 2,
          Support_Start_Date__c = System.today(),
          Program__c = 'Conversion',
          Quantity = 20,
          PricebookEntryId = entries[4].Id
        ),
        new OrderItem(
          OrderId = orderInstance1.Id,
          TPH_Quantity__c = '1',
          Previous_Contract_Line_Items__c = lstContractLineItems[5].Id,
          Product2Id = sampleProducts2[0].Id,
          UnitPrice = entries[0].UnitPrice,
          SBQQ__QuoteLine__c = lines10[0].Id,
          SBQQ__SubscriptionTerm__c = 36,
          SBQQ__Segmentindex__c = 2,
          Support_Start_Date__c = System.today(),
          Program__c = 'Conversion',
          Quantity = 20,
          PricebookEntryId = entries[0].Id
        ),
        new OrderItem(
          OrderId = orderInstance1.Id,
          Previous_Contract_Line_Items__c = lstContractLineItems[6].Id,
          Product2Id = sampleProducts2[0].Id,
          UnitPrice = entries[0].UnitPrice,
          SBQQ__QuoteLine__c = lines10[0].Id,
          SBQQ__SubscriptionTerm__c = 36,
          SBQQ__Segmentindex__c = 2,
          Support_Start_Date__c = System.today(),
          Program__c = 'Conversion',
          Quantity = 20,
          PricebookEntryId = entries[0].Id
        )
      };
      insert orderItemList;

      List<String> lstOldCliIds = new List<String>{
        lstContractLineItems[0].Id,
        lstContractLineItems[3].Id,
        lstContractLineItems[4].Id,
        lstContractLineItems[5].Id,
        lstContractLineItems[6].Id
      };

      ServiceContract objSC = new ServiceContract(
        Name = 'ServiceContractTest2',
        AccountId = lstAccount1[0].Id,
        StartDate = Date.today(),
        Term = 36,
        pricebook2Id = Test.getStandardPricebookId(),
        SBQQSC__Opportunity__c = opp3.Id,
        SBQQSC__Order__c = orderInstance1.Id,
        SBQQSC__Quote__c = quoteObjNew.Id
      );

      insert objSC;

      List<ContractLineItem> lstCli = new List<ContractLineItem>{
        new ContractLineItem(
          Quantity = orderItemList[0].quantity,
          PricebookEntryId = orderItemList[0].PricebookEntryId,
          ServiceContractId = objSC.Id,
          UnitPrice = orderItemList[0].UnitPrice,
          StartDate = date.today()
        ),
        new ContractLineItem(
          Quantity = orderItemList[1].quantity,
          PricebookEntryId = orderItemList[1].PricebookEntryId,
          ServiceContractId = objSC.Id,
          UnitPrice = orderItemList[1].UnitPrice,
          StartDate = date.today()
        ),
        new ContractLineItem(
          Quantity = orderItemList[2].quantity,
          PricebookEntryId = orderItemList[2].PricebookEntryId,
          ServiceContractId = objSC.Id,
          UnitPrice = orderItemList[2].UnitPrice,
          StartDate = date.today()
        ),
        new ContractLineItem(
          Quantity = orderItemList[3].quantity,
          PricebookEntryId = orderItemList[3].PricebookEntryId,
          ServiceContractId = objSC.Id,
          UnitPrice = orderItemList[3].UnitPrice,
          StartDate = date.today()
        )
      };

      insert lstCli;
      orderItemList[0].SBQQSC__ContractLineItem__c = lstCli[0].Id;
      orderItemList[2].SBQQSC__ContractLineItem__c = lstCli[2].Id;

      update orderItemList;
      Id supportRecordTypeId = Schema.SObjectType.Entitlement.getRecordTypeInfosByName().get('Support').getRecordTypeId();

      List<Entitlement> lstEntitlement1 = new List<Entitlement>{
        new Entitlement(
          Name = sampleProducts2[4].ProductCode,
          RecordTypeId = supportRecordTypeId,
          Type = 'Phone Support',
          AccountId = lstAccount1[0].Id,
          Product__c = sampleProducts2[0].Id,
          StartDate = date.today(),
          AssetId = lstAsset[0].Id,
          ServiceContractId = objSC.Id,
          ContractLineItemId = lstCli[0].Id,
          Order_Service_Item__c = orderItemList[0].id
        ),
        new Entitlement(
          Name = sampleProducts2[4].ProductCode,
          RecordTypeId = supportRecordTypeId,
          Type = 'Phone Support',
          AccountId = lstAccount1[0].Id,
          Product__c = sampleProducts2[4].Id,
          StartDate = date.today(),
          AssetId = lstAsset[0].Id,
          ServiceContractId = objSC.Id,
          ContractLineItemId = lstCli[1].Id,
          Order_Service_Item__c = orderItemList[1].id
        ),
        new Entitlement(
          Name = sampleProducts2[4].ProductCode,
          RecordTypeId = supportRecordTypeId,
          Type = 'Phone Support',
          AccountId = lstAccount1[0].Id,
          Product__c = sampleProducts2[4].Id,
          StartDate = date.today(),
          ServiceContractId = objSC.Id,
          ContractLineItemId = lstCli[2].Id,
          Order_Service_Item__c = orderItemList[2].id
        ),
        new Entitlement(
          Name = sampleProducts2[4].ProductCode,
          RecordTypeId = supportRecordTypeId,
          Type = 'Phone Support',
          AccountId = lstAccount1[0].Id,
          Product__c = sampleProducts2[4].Id,
          StartDate = date.today(),
          ServiceContractId = objSC.Id,
          ContractLineItemId = lstCli[3].Id,
          Order_Service_Item__c = orderItemList[3].id
        )
      };
      insert lstEntitlement1;
      List<String> lstNewEntitlementIds = new List<String>();
      for (Entitlement ojEnt : lstEntitlement1) {
        lstNewEntitlementIds.add(ojEnt.Id);
      }

      orderInstance1.SBQQ__Contracted__c = false;
      orderInstance1.Polaris_Fulfillment_Status__c = 'Completed';
      orderInstance1.Status = 'Activated';
      orderInstance1.Order_Status__c = 'Shipped';
      //orderInstance1.Program__c = 'Conversion';
      orderInstance1.SBQQ__Quote__c = quoteObjNew.Id;
      orderInstance1.Actual_Order_Ship_Date__c = System.today();
      orderInstance1.Welcome_letter_sent_for_the_first_time__c = true;

      update orderInstance1;
      
      List<Polaris_SKU_Mapping_V2__c> skuMappings = new List<Polaris_SKU_Mapping_V2__c>();
        
        for (Integer i = 0; i < sampleProducts2.size(); i++) {
            for (Integer j = 0; j < sampleProducts2.size(); j++) {
                skuMappings.add(new Polaris_SKU_Mapping_V2__c(
                    Old_Product__c = sampleProducts2[i].Id,
                    New_Product__c = sampleProducts2[j].Id,
                    Quantity_Ratio__c = 10
                ));
            }
        }
        
        insert skuMappings;  

      ContractOrders conVersionMethod = new ContractOrders();
      System.schedule('Test_Contract_Orders_Conversion', '0 0 * * * ?', conVersionMethod);
      conVersionMethod.execute(null);
      System.assertEquals(4, lstEntitlement1.size());
      Test.stopTest();
    }
  }

    @isTest
  static void testVirtualAddon() {
      List<User> testUser = [SELECT Id FROM User WHERE email = 'testuser@testclass.com.invalid'];
      System.runAs(testUser[0]) {
        // Query all QLIs from setup
        List<SBQQ__QuoteLine__c> allQLIs = [
        SELECT Id, SBQQ__Product__c, SBQQ__RequiredBy__c, Disposition_Reason__c, Special_Program__c, SBQQ__Quote__c, SBQQ__Quote__r.Id, SBQQ__Bundle__c,
            Do_not_Renew__c,SBQQ__Product__r.Product_Type__c,SBQQ__ProductOption__r.Refresh_Default_Option__c FROM SBQQ__QuoteLine__c
        ];

        // Identify License, Hardware, Hardware Support
        SBQQ__QuoteLine__c licenseQLI;
        SBQQ__QuoteLine__c hardwareQLI;
        SBQQ__QuoteLine__c hwSupportQLI;
        SBQQ__Quote__c quote;

        for (SBQQ__QuoteLine__c qli : allQLIs) {
        if (licenseQLI == null && qli.SBQQ__Bundle__c) {
                licenseQLI = qli;
                quote = qli.SBQQ__Quote__r;  
            }
        }
        for (SBQQ__QuoteLine__c qli : allQLIs) {
        if (hardwareQLI == null && qli.SBQQ__RequiredBy__c == licenseQLI.Id) {
                hardwareQLI = qli;
        } else if (hwSupportQLI == null && hardwareQLI != null && qli.SBQQ__RequiredBy__c == hardwareQLI.Id) {
                hwSupportQLI = qli;
            }
        }


        // Update only Hardware Product2
        Product2 hwProd = [
            SELECT Id, Product_Level__c, Product_Type__c, Item_Type__c
            FROM Product2
            WHERE Id = :hardwareQLI.SBQQ__Product__c
        ];
        hwProd.Product_Level__c = 'Hardware';
        hwProd.Product_Type__c = 'Add-On Node';
        hwProd.Item_Type__c = 'Non-inventory Item';
        update hwProd;

        // Nullify fields on HW Support and Hardware QLIs
        hwSupportQLI.Special_Program__c = null;
        hwSupportQLI.Disposition_Reason__c = null;
        hardwareQLI.Special_Program__c = null;
        hardwareQLI.Disposition_Reason__c = null;

        quote.Is_RWD_Polaris_Quote__c = true;
        update quote;

        update new List<SBQQ__QuoteLine__c>{ hwSupportQLI, hardwareQLI };

        List<Order> ordList = new List<Order>(); // moved declaration outside
        if (quote != null) {
          ordList = [
          SELECT
            Id,
                    SBQQ__Contracted__c,
                    Polaris_Fulfillment_Status__c,
                    Status,
                    Order_Status__c,
                    Program__c,
                    Actual_Order_Ship_Date__c,
                    Welcome_letter_sent_for_the_first_time__c,
                    Order_Sub_Type__c,
                    SC_or_Entitlement_Stage__c
              FROM Order
              WHERE SBQQ__Quote__c = :quote.Id
              LIMIT 1
          ];
          if (!ordList.isEmpty()) {
              ordList[0].SBQQ__Contracted__c = false;
              ordList[0].Polaris_Fulfillment_Status__c = 'Completed';
              ordList[0].Status = 'Activated';
              ordList[0].Order_Status__c = 'Shipped';
              ordList[0].Program__c = 'Refresh';
              ordList[0].Actual_Order_Ship_Date__c = System.today();
              ordList[0].Welcome_letter_sent_for_the_first_time__c = true;
              ordList[0].Order_Sub_Type__c = 'Renewal';
              ordList[0].SC_or_Entitlement_Stage__c = Constants.SC_ENT_STAGE_CREATE_SERVICE_CONTRACT;
              update ordList[0];
          }
      }

        // 4️⃣ Run the batch
        Test.startTest();
        ContractOrders batch = new ContractOrders();
        batch.execute(null);
        System.assertEquals(1, ordList.size());
        Test.stopTest();
      }
  }
}