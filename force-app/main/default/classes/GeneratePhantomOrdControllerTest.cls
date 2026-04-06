/**
 * @file Name : GeneratePhantomOrdControllerTest.cls
 * @description : Apex test class for GeneratePhantomOrdController
 * @author : Siva Kumar.V
 * @last Modified By : September 8, 2025
 * @last Modified On : September 8, 2025
 * @modification Log :
 *==============================================================================
 * Ver | Date | Author | Modification
 *==============================================================================
 * 1.0 | September 8, 2025 |   | Initial Version
 **/
@isTest
public class GeneratePhantomOrdControllerTest {
  /**
   * @description This method is used to create test data required to cover apex methods
   */
  @testSetup
  static void makeData() {
    User usr = (User) ShGl_TestFactory.createSObject(new User(), null);
    usr.Email = 'PhantomOrder@creation.com';
    insert usr;
    System.runAs(usr) {
      insert new ShGl_DisableBusinessLogic__c(
        Disable_Opportunity_Triggers__c = true,
        Disable_Opportunity_Validation_Rules__c = true,
        Disable_Order_Email_Alerts__c = true,
        Disable_Order_Old_Trigger__c = true,
        Disable_OrderItem_Old_Trigger__c = true,
        Disable_Order_Validation_Rules__c = true,
        Disable_Account_Triggers__c = true,
        Disable_Account_Validation_Rules__c = true,
        Disable_Product2_Validation_Rules__c = true,
        Disable_SBQQ_Quote_Triggers__c = true,
        Disable_SBQQ_QuoteLine_Triggers__c = true,
        Disable_SBQQ_QuoteLine_Validation_Rules__c = true,
        Disable_SBQQ_Quote_Validation_Rules__c = true,
        Disable_Entitlement_Validation_Rules__c = true,
        setupOwnerId = usr.id
      );
      TriggerControls.disableQuoteTrigger = true;
      TriggerControls.disableQuoteLineTrigger = true;
      SBQQ.TriggerControl.disable();
      insert new List<TriggerControl__c>{ new TriggerControl__c(Name = 'Entitlement', DisableTrigger__c = true) };
      Account acc = (Account) ShGl_TestFactory.createSObject(new Account(), new Map<String, Object>{ 'name' => 'Promark Technology', 'Type' => 'Distributor' });
      insert acc;
      Id pricebookId = Test.getStandardPricebookId();
      Map<String, Object> prdMap = new Map<String, Object>{ 'Name' => 'HW', 'ProductCode' => 'RS-BT-EE-PE-PP', 'IsActive' => true };
      Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
      insert prdHW;

      List<PricebookEntry> pbEntryList = new List<PricebookEntry>();
      PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
      pbeHW.Product2Id = prdHW.Id;
      pbEntryList.add(pbeHW);
      insert pbEntryList;

      List<Opportunity> oppList = (List<Opportunity>) ShGl_TestFactory.createSObjectList(
        new Opportunity(),
        1,
        new Map<String, Object>{
          'AccountId' => acc.Id,
          'Pricebook2Id' => pricebookId,
          'stageName' => '6 PO With Channel',
          'RecordTypeId' => Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId()
        }
      );
      insert oppList;

      Map<String, Object> quoteMap = new Map<String, Object>{
        'SBQQ__Account__c' => acc.Id,
        'SBQQ__Opportunity2__c' => oppList[0].Id,
        'SBQQ__SubscriptionTerm__c' => 12,
        'SBQQ__Primary__c' => true,
        'SBQQ__Type__c' => 'Quote',
        'SBQQ__PriceBook__c' => pricebookId
      };

      SBQQ__Quote__c quote = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
      insert quote;

      List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
      quoteLines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Product__c = prdHW.Id,
          SBQQ__Quote__c = quote.Id,
          SBQQ__Quantity__c = 30.0,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = 1,
          SBQQ__ListPrice__c = 228,
          SBQQ__NetPrice__c = 8208,
          SBQQ__PricebookEntryId__c = pbEntryList[0].Id
        )
      );
      insert quoteLines;

      Map<String, Object> orderMap = new Map<String, Object>{
        'Type' => 'Revenue',
        'Send_for_Polaris_Fulfilment__c' => true,
        'AccountId' => acc.Id,
        'SBQQ__Quote__c' => quote.Id,
        'OpportunityId' => oppList[0].Id,
        'EffectiveDate' => system.today(),
        'Status' => 'Pending',
        'ShippingCountryCode' => 'US',
        'ShippingStateCode' => 'CA',
        'ShippingStreet' => 'Test Street',
        'ShippingCity' => 'Test City',
        'ShippingState' => 'California',
        'ShippingCountry' => 'United States',
        'ShippingPostalcode' => '94820',
        'ship_To_Name__c' => acc.id,
        'ShipToContactName__c' => 'Test',
        'Pricebook2Id' => pricebookId,
        'Original_Est_Ship_Date__c' => Date.today().addDays(30)
      };

      Order revenueOrd = (Order) ShGl_TestFactory.createSObject(new Order(), orderMap);
      insert revenueOrd;

      Map<String, Object> orderItemMap = new Map<String, Object>{
        'PricebookEntryId' => pbEntryList[0].id,
        'OrderId' => revenueOrd.id,
        'SBQQ__QuoteLine__c' => quoteLines[0].Id,
        'PricebookEntryId' => pbEntryList[0].Id,
        'UnitPrice' => 10,
        'Quantity' => 1,
        'Product2Id' => prdHW.Id,
        'SBQQ__SubscriptionTerm__c' => 36,
        'Support_Start_Date__c' => System.today(),
        'Program__c' => Constants.PROGRAM_CONVERSION
      };

      SObject sObj = new OrderItem();
      for (String field : orderItemMap.keySet()) {
        if (sObj.get(field) == null) {
          sObj.put(field, orderItemMap.get(field));
        }
      }
      OrderItem oldOrderItem = (OrderItem) sObj;
      insert oldOrderItem;

      List<Entitlement> entitlements = new List<Entitlement>{
        (Entitlement) ShGl_TestFactory.createSObject(
          new Entitlement(),
          new Map<String, Object>{
            'Name' => 'Product SKU-104',
            'AccountId' => acc.Id,
            'StartDate' => Date.today().addDays(-365),
            'EndDate' => Date.today().addDays(365),
            'Product__c' => prdHW.Id,
            'Order_Service_Item__c' => oldOrderItem.Id
          }
        )
      };
      insert entitlements;

      PreviousTransRefWrapper repJSON = new PreviousTransRefWrapper(oldOrderItem.Id, 10, entitlements[0].Id, 0, null, null, null, false);
      OrderItem replacementOrdItem = oldOrderItem.clone(false, true);
      replacementOrdItem.Previous_Transaction_Reference__c = JSON.serialize(new List<PreviousTransRefWrapper>{ repJSON });
      replacementOrdItem.Replacement_Type__c = 'Partial';
      replacementOrdItem.Credit_Amount__c = 150;
      insert replacementOrdItem;

      Order_Item_Extension__c orderItemExtn = new Order_Item_Extension__c(
        OI_ExternalID__c = oldOrderItem.Id,
        Order_Line_ID__c = oldOrderItem.Id,
        Paid_Quantity__c = 3,
        End_of_Paid_Term__c = System.today().addYears(2)
      );
      insert orderItemExtn;
    }
  }
  /**
   * @description This method is used to test if order is eligible for Phantom Order creation
   */
  @isTest
  static void phantomOrderEligibilityTest() {
    User runningUser = [SELECT Id FROM User WHERE Email = 'PhantomOrder@creation.com' LIMIT 1];
    System.runAs(runningUser) {
      Test.startTest();

      Order revenueOrd = [SELECT Id FROM Order WHERE Type = 'Revenue' ORDER BY CreatedDate DESC LIMIT 1];
      revenueOrd.Line_Types__c = 'Conversion';
      SplitOrder.isNonEDISplit = true;
      update revenueOrd;
      GeneratePhantomOrdController.isNonITuser = false;
      Map<String, String> validOrdItemsorderStatusToResponse = GeneratePhantomOrdController.checkEligibilityForPhantomOrder(revenueOrd.Id);
      List<String> orderStatus = new List<String>(validOrdItemsorderStatusToResponse.keyset());
      System.assertEquals('ValidOrder', orderStatus[0]);
      GeneratePhantomOrdController.createPhantomOrder(validOrdItemsorderStatusToResponse.get('ValidOrder'));

      validOrdItemsorderStatusToResponse = GeneratePhantomOrdController.checkEligibilityForPhantomOrder(revenueOrd.Id);
      System.assertEquals(GeneratePhantomOrdController.phantomOrderExistsMessage, validOrdItemsorderStatusToResponse.values()[0]);

      Test.stopTest();
    }
  }
  /**
   * @description This method is used to test validation errors on non phantom orders
   */
  @isTest
  static void testNonEligibleOrders() {
    User runningUser = [SELECT Id FROM User WHERE Email = 'PhantomOrder@creation.com' LIMIT 1];
    System.runAs(runningUser) {
      Test.startTest();
      Order revenueOrd = [SELECT Id, (SELECT Id FROM OrderItems) FROM Order WHERE Type = 'Revenue' ORDER BY CreatedDate DESC LIMIT 1];
      List<OrderItem> revenueOrdItems = revenueOrd.orderItems;

      Map<String, String> validOrdItemsStatusToResponse = GeneratePhantomOrdController.checkEligibilityForPhantomOrder(revenueOrd.Id);
      System.assertEquals(GeneratePhantomOrdController.noAccessMessage, validOrdItemsStatusToResponse.values()[0]);

      GeneratePhantomOrdController.isNonITuser = false;
      validOrdItemsStatusToResponse = GeneratePhantomOrdController.checkEligibilityForPhantomOrder(revenueOrd.Id);
      System.assertEquals(GeneratePhantomOrdController.invalidOrderMessage, validOrdItemsStatusToResponse.values()[0]);

      revenueOrd.Line_Types__c = 'Conversion';
      SplitOrder.isNonEDISplit = true;
      update revenueOrd;

      for (OrderItem ordItem : revenueOrdItems) {
        ordItem.credit_amount__c = 0;
        ordItem.Support_End_Date__c = System.today().addYears(2);
      }
      update revenueOrdItems;
      validOrdItemsStatusToResponse = GeneratePhantomOrdController.checkEligibilityForPhantomOrder(revenueOrd.Id);
      System.assertEquals(GeneratePhantomOrdController.invalidOrderItemsMessage, validOrdItemsStatusToResponse.values()[0]);
      Test.stopTest();
    }

  }
  /**
   * @description This method is used to test Phantom order creation
   */
  @isTest
  static void testPhantomOrderCreation() {
    User runningUser = [SELECT Id FROM User WHERE Email = 'PhantomOrder@creation.com' LIMIT 1];
    System.runAs(runningUser) {
      Test.startTest();

      Order revenueOrd = [SELECT Id, OrderNumber, (SELECT Id FROM OrderItems) FROM Order WHERE Type = 'Revenue' ORDER BY CreatedDate DESC LIMIT 1];
      revenueOrd.Line_Types__c = 'Conversion';
      SplitOrder.isNonEDISplit = true;
      update revenueOrd;
      List<OrderItem> ordItems = revenueOrd.OrderItems;

      GeneratePhantomOrdController.isNonITuser = false;
      Map<String, String> validOrdItemsorderStatusToResponse = GeneratePhantomOrdController.checkEligibilityForPhantomOrder(revenueOrd.Id);
      List<String> orderStatus = new List<String>(validOrdItemsorderStatusToResponse.keyset());
      System.assertEquals('ValidOrder', orderStatus[0]);
      try {
        PreviousTransRefWrapper repJSON = new PreviousTransRefWrapper(ordItems[0].Id, 10, null, 0, null, null, revenueOrd.OrderNumber, false);

        for (OrderItem ordItem : ordItems) {
          ordItem.Previous_Transaction_Reference__c = JSON.serialize(new List<PreviousTransRefWrapper>{ repJSON });
        }
        update ordItems;
        GeneratePhantomOrdController.createPhantomOrder(validOrdItemsorderStatusToResponse.get('ValidOrder'));
      } catch (Exception error) {
        System.debug(loggingLevel.DEBUG, 'error' + error.getMessage());
      }
    }
  }
}