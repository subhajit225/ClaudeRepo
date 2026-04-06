@isTest
public class OrderCreationMetricsClassTest {
  @testSetup
  static void insertData() {
    String uniqueUserName = 'TestUser' + DateTime.now().getTime() + '@rbk.com';
    String uniqueUserName1 = 'TestUser1' + DateTime.now().getTime() + '@rbk.com';
    String uniqueUserName2 = 'TestUser2' + DateTime.now().getTime() + '@rbk.com';
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
    List<User> ursList = new List<User>{ usr1 };
    insert ursList;
    System.runAs(usr1) {
      insert new ShGl_DisableFunctionalityLogic__c(setupOwnerId = UserInfo.getUserId(), Disable_Account_Old_Trigger__c = true);
      insert new ShGl_DisableBusinessLogic__c(
        setupownerid = userinfo.getUserId(),
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
      opp.Pricebook2id = Test.getStandardPricebookId();
      insert opp;

      Opportunity opp1 = TestDataFactory.getOpportunity();
      opp1.Partner_Lookup__c = customer.Id;
      opp1.AccountId = customer.Id;
      opp1.Distributor_Lookup__c = opp.AccountId;
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

      insert entries;

      Asset assestIns = new Asset();
      assestIns.Name = '09092019APMSP1250';
      assestIns.SerialNumber = '09092019APMSP1250';
      assestIns.serial_number__c = '09092019APMSP1250';
      assestIns.AccountId = customer.Id;
      assestIns.Product2Id = sampleProducts[0].Id;
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
        )
      };
      Test.startTest();
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
        )
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
      orderItemList[2].SBQQ__RequiredBy__c = orderItemList[0].Id;

      update orderItemList;
      Test.stopTest();
    }
  }

  @isTest
  static void orderSuccessMatrixTest() {
    List<user> usr3 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com'];
    System.runAs(usr3[0]) {
      TriggerControls.disableQuoteTrigger = true;
      TriggerControls.disableQuoteLineTrigger = true;
      SBQQ.TriggerControl.disable();
      TriggerControl.stopOrderItemTrigger = true;
      TriggerControl.stopOrderTrigger = true;

      Test.startTest();

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
      orderListMethod3[0].SBQQ__Contracted__c = true;
      orderListMethod3[0].Polaris_Fulfillment_Status__c = 'Completed';
      orderListMethod3[0].Status = 'Activated';
      orderListMethod3[0].Order_Status__c = 'Shipped';
      //orderListMethod3[0].Program__c = 'Refresh';
      orderListMethod3[0].Actual_Order_Ship_Date__c = System.today();
      orderListMethod3[0].Welcome_letter_sent_for_the_first_time__c = true;
      orderListMethod3[0].Auto_Submission_Date_Time__c = System.today();
      update orderListMethod3;
      orderListMethod3[0].BookingStatus__c = 'Completed';
      update orderListMethod3;
      List<id> OrderIdlist = new List<id>();
      for (order o : orderListMethod3) {
        OrderIdlist.add(o.id);
      }
      OrderCreationMetricsClass.createOrderSuccessMatrix(OrderIdlist);
      system.assertequals(orderListMethod3[0].SBQQ__Contracted__c, true);
      SBQQ.TriggerControl.enable();
      Test.stopTest();
    }
  }
}