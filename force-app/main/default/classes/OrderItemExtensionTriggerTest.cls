/************************************************************
 * @description       : Test class that covers OrderItemExtensionHelper, OrderItemExtensionHandler & OrderItemExtensionTrigger
 * @author            : Ravi
 * @last modified on  : 24-04-2025
 * @last modified by  : Siva Kumar
 * Modifications Log
 * Ver   Date          Author        Modification
 * 1.0   24-05-2024   Ravi        Initial Version
 **************************************************************/
@IsTest
public class OrderItemExtensionTriggerTest {
  /**
   * @description		Setup method that creates initial required data.
   * @author 			Ravi
   * @last modified on 24-04-2025
   */
  @testSetup
  static void setup() {
    String uniqueUserName = 'AdminUser' + DateTime.now().getTime() + '@rubrik.com';
    Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
    User runningUser = new User(
      Alias = 'adminU',
      Email = 'AdminUser@rubrik.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = adminProfile.Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = uniqueUserName
    );
    insert runningUser;
    System.runAs(runningUser) {
      TriggerControls.disableQuoteTrigger = true;
      TriggerControls.disableQuoteLineTrigger = true;

      insert new ShGl_DisableBusinessLogic__c(
        Disable_POC_Validation_Rules__c = true,
        Disable_Entitlement_Validation_Rules__c = true,
        Disable_SBQQ_Quote_Triggers__c = true,
        Disable_SBQQ_QuoteLine_Triggers__c = true,
        Disable_Opportunity_Validation_Rules__c = true,
        Disable_Opportunity_Triggers__c = true,
        Disable_Order_Email_Alerts__c = true,
        Disable_Order_Old_Trigger__c = true,
        Disable_Order_Triggers__c = true,
        Disable_Contact_Triggers__c = true,
        setupOwnerId = userinfo.getuserid(),
        Disable_POC_Trigger__c = true
      );
      insert new ShGl_DisableFunctionalityLogic__c(Disable_Opportunity_Old_Trigger__c = true, setupOwnerId = userinfo.getuserid());

      Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();

      Account act = new Account(
        BillingCountryCode = 'US',
        Is_Refreshed__c = false,
        Name = 'Test',
        Sync_to_NetSuite__c = false,
        RecordTypeId = devRecordTypeId,
        Website = 'www.test3.com',
        OwnerId = userinfo.getUserId(),
        type = 'Customer'
      );

      insert act;

      Id pricebookId = Test.getStandardPricebookId();
      opportunity oppr = new opportunity(
        Name = 'test Opp',
        Opportunity_Sub_Type__c = 'Regular',
        Distributor_Lookup__c = act.Id,
        AccountId = act.Id,
        StageName = '1 Discovery',
        pricebook2Id = pricebookId,
        CloseDate = System.today().addYears(1)
      );
      insert oppr;

      test.startTest();
      List<Product2> productList = new List<Product2>();
      Product2 prod1 = new Product2(
        Name = 'RBK-SVC-PREM-R344',
        ProductCode = 'RBK-SVC-PREM-R344',
        Family = 'POLARIS',
        Appliance_Model_HW__c = 'RBK-R6408E',
        isActive = true,
        Bundle_Features__c = 'Polaris',
        Allow_PSO_Task_Creation__c = true,
        usable_Capacity__c = 60
      );
      productList.add(prod1);
      Product2 prod2 = new Product2(
        Name = 'RBK-SVC-PREM-R345',
        ProductCode = 'RBK-SVC-PREM-R345',
        Family = 'POLARIS',
        Appliance_Model_HW__c = 'RBK-R6408E',
        isActive = true,
        Bundle_Features__c = 'Polaris',
        Allow_PSO_Task_Creation__c = true,
        usable_Capacity__c = 60,
        Product_Level__c = 'OnPrem'
      );
      productList.add(prod2);
      insert productList;

      List<Asset> assetsToInsert = new List<Asset>{
        new Asset(Name = 'SN123', SerialNumber = 'SN123', Serial_Number__c = 'SN123', Accountid = act.Id, Product2id = prod1.id),
        new Asset(Name = 'SN456', SerialNumber = 'SN456', Serial_Number__c = 'SN456', Accountid = act.Id, Product2id = prod1.id)
      };
      insert assetsToInsert;

      PricebookEntry pbEntry = new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = prod1.Id, UnitPrice = 100.00, IsActive = true);
      insert pbEntry;

      Map<String, Object> OrderMap = new Map<String, Object>{
        'Type' => 'Revenue',
        'Send_for_Polaris_Fulfilment__c' => true,
        'AccountId' => act.Id,
        'POC_Opportunity__c' => oppr.Id,
        'EffectiveDate' => system.today(),
        'Order_Status__c' => null,
        'Status' => 'Pending',
        'Sync_to_NetSuite__c' => true,
        'ShippingCountryCode' => 'US',
        'ShippingStateCode' => 'CA',
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
        'Order_Splitted__c' => true,
        'Order_Sub_Type__c' => 'Renewal'
      };

      Order ord = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
      insert Ord;

      List<OrderItem> ordItemsList = new List<OrderItem>();

      OrderItem ordItem1 = new OrderItem(
        OrderId = Ord.Id,
        Quantity = 5,
        PricebookEntryId = pbEntry.Id,
        UnitPrice = pbEntry.UnitPrice,
        SerialNumber__c = 'SN123,SN456',
        Failed_Serial_Number__c = 'S3F4NXM416324'
      );
      ordItemsList.add(ordItem1);

      OrderItem ordItem2 = new OrderItem(OrderId = Ord.Id, Quantity = 5, PricebookEntryId = pbEntry.Id, UnitPrice = pbEntry.UnitPrice);
      ordItemsList.add(ordItem2);

      OrderItem ordItem3 = new OrderItem(OrderId = Ord.Id, Quantity = 5, PricebookEntryId = pbEntry.Id, UnitPrice = pbEntry.UnitPrice, Product2Id = prod1.Id);
      ordItemsList.add(ordItem3);

      OrderItem ordItem4 = new OrderItem(OrderId = Ord.Id, Quantity = 5, PricebookEntryId = pbEntry.Id, UnitPrice = pbEntry.UnitPrice, Product2Id = prod1.Id);
      ordItemsList.add(ordItem4);

      OrderItem ordItem5 = new OrderItem(OrderId = Ord.Id, Quantity = 5, PricebookEntryId = pbEntry.Id, UnitPrice = pbEntry.UnitPrice);
      ordItemsList.add(ordItem5);

      insert ordItemsList;
      test.stopTest();
    }

  }
  /**
   * @description 		Method to test Amount fields calculation on OrderItem Extension.
   * @author 			Siva Kumar
   * @last modified on 24-04-2025
   */
  @IsTest
  static void testOrdItemExtensionUpsert() {
    User runningUser = [SELECT Id FROM User WHERE Email = 'AdminUser@rubrik.com' LIMIT 1];
    System.runAs(runningUser) {
      Account acct = [SELECT Id FROM Account WHERE Name = 'Test' LIMIT 1];
      Opportunity oppr = [SELECT Id, pricebook2Id, CreatedById FROM Opportunity WHERE AccountId = :acct.Id LIMIT 1];
      List<OrderItem> ordItemsList = [SELECT Id FROM OrderItem];
      test.startTest();
      Integer counter = 0;
      for (OrderItem ordrItem : ordItemsList) {
        if (counter != 4) {
          ordrItem.Support_End_Date__c = System.Today().addYears(1);
          ordrItem.Support_Start_Date__c = System.Today();
        }
        counter++;
      }
      update ordItemsList;

      List<Order_Item_Extension__c> lstOIEToInsert = new List<Order_Item_Extension__c>{
        new Order_Item_Extension__c(
          OI_ExternalID__c = ordItemsList[0].Id,
          Order_Line_ID__c = ordItemsList[0].Id,
          Paid_Quantity__c = 3,
          Credit_Calculation_Status__c = 'To Process'
        ),
        new Order_Item_Extension__c(
          OI_ExternalID__c = ordItemsList[1].Id,
          Order_Line_ID__c = ordItemsList[1].Id,
          Paid_Quantity__c = 3,
          Credit_Calculation_Status__c = 'To Process'
        ),
        new Order_Item_Extension__c(
          OI_ExternalID__c = ordItemsList[2].Id,
          Order_Line_ID__c = ordItemsList[2].Id,
          Paid_Quantity__c = 3,
          Credit_Calculation_Status__c = 'To Process'
        ),
        new Order_Item_Extension__c(
          OI_ExternalID__c = ordItemsList[3].Id,
          Order_Line_ID__c = ordItemsList[3].Id,
          Paid_Quantity__c = null,
          Credit_Calculation_Status__c = 'To Process'
        ),
        new Order_Item_Extension__c(
          OI_ExternalID__c = ordItemsList[4].Id,
          Order_Line_ID__c = ordItemsList[4].Id,
          Paid_Quantity__c = 10,
          Credit_Calculation_Status__c = 'To Process'
        )
      };

      insert lstOIEToInsert;
      List<Order_Item_Extension__c> oItemExtension = [
        SELECT Id, Order_Line_ID__r.Support_Start_Date__c, Order_Line_ID__r.Support_End_Date__c, Quantity_Type__c, Per_DayQuantity_Amount__c, Remaining_Amount__c
        FROM Order_Item_Extension__c
        WHERE Order_Line_ID__c = :ordItemsList[1].Id
      ];

      Integer totalNoDays = oItemExtension[0]?.Order_Line_ID__r?.Support_Start_Date__c.daysBetween(oItemExtension[0]?.Order_Line_ID__r?.Support_End_Date__c) + 1;
      Decimal expectedPerDayQtyAmount = 500.0 / (5 * totalNoDays);
      System.assertEquals(oItemExtension[0].Remaining_Amount__c, 40);
      System.assertEquals(oItemExtension[0].Per_DayQuantity_Amount__c.setScale(2), expectedPerDayQtyAmount.setScale(2));
      System.assertEquals(oItemExtension[0].Quantity_Type__c, 'Quantity');
      lstOIEToInsert[0].Credit_Calculation_Status__c = 'To Process';
      update lstOIEToInsert;
      test.stopTest();
    }
  }
}