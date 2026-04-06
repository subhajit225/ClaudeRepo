@isTest
public class BookedOrdersPerQuarterBatchTest {
  /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : To setup intial data for test class
   */
  @testSetup
  public static void setup() {
  String uniqueUserName = 'BookedOrdersPerQuarterBatchTest' + DateTime.now().getTime() + '@testclass.com';
    Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
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

    TriggerControls.disableQuoteTrigger = true;
    TriggerControls.disableQuoteLineTrigger = true;
    insert new TriggerControl__c(name = 'Order', DisableTrigger__c = true);

    insert new ShGl_DisableBusinessLogic__c(
      Follow_Existing_EntCreate_Process__c = true,
      Disable_Order_Validation_Rules__c = true,
      Disable_POC_Validation_Rules__c = true,
      Disable_SBQQ_Quote_Triggers__c = true,
      Disable_SBQQ_QuoteLine_Triggers__c = true,
      Disable_Opportunity_Validation_Rules__c = true,
      Disable_Opportunity_Triggers__c = false,
      Disable_Order_Email_Alerts__c = false,
      Disable_Order_Old_Trigger__c = true,
      Disable_Order_Triggers__c = true,
      Disable_Contact_Triggers__c = true,
      setupOwnerId = userinfo.getuserid(),
      Disable_POC_Trigger__c = true,
      Disable_SBQQ_Quote_Validation_Rules__c = true
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
      Name = 'testing Opportunity1',
      Opportunity_Sub_Type__c = 'Regular',
      Distributor_Lookup__c = act.Id,
      Alliance_Source_Type_HW__c = 'Rubrik Initiated Alliance Deal',
      Mosaic_Customer_Environment__c = 'AWS',
      CloseDate = Date.Today().addDays(10),
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
      Alliance_Source_Type_SW__c = 'Rubrik Initiated Alliance Deal',
      Identified_Pain__c = 'Test',
      Champion__c = 'Test',
      ForecastCategoryName = 'Best Case',
      Override__c = false
    );

    insert oppr;
    
    SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
    qt.SBQQ__Account__c = act.Id;
    qt.SBQQ__Opportunity2__c = oppr.Id;
    qt.SBQQ__Primary__c = true;
    qt.SBQQ__SubscriptionTerm__c = 36;
    qt.SBQQ__ExpirationDate__c = date.today().addDays(10);
    qt.SBQQ__PaymentTerms__c = 'Net 45';
    qt.SBQQ__Type__c = 'Renewal+Expansion';

    insert qt;
	Date currentDate = Date.Today();
    Map<String, Object> OrderMap = new Map<String, Object>{
        'Type' => 'Revenue',
        'Send_for_Polaris_Fulfilment__c' => true,
        'AccountId' => oppr.AccountId,
        'OpportunityId' => oppr.Id,
        'EffectiveDate' => system.today(),
        'Order_Status__c' => 'On Hold',
        'Status' => 'Draft',
        'Hold_Code__c' => Constants.ORDER_CRSD_HOLD_CODE,
        'Sync_to_NetSuite__c' => true,
        'ShippingCountryCode' => 'US',
        'ShippingStateCode' => 'CA',
        'ShippingStreet' => 'Test Street',
        'ShippingCity' => 'Test City',
        'ShippingState' => 'California',
        'ShippingCountry' => 'United States',
        'ShippingPostalcode' => '94820',
        'ship_To_Name__c' => oppr.AccountId,
        'ShipToContactName__c' => 'Test',
        'Pricebook2Id' => pricebookId,
        'Have_Polaris_Products__c' => false,
        'Polaris_Fulfillment_Status__c' => 'Completed',
        'Original_Est_Ship_Date__c' => Date.today().addDays(30),
        'Est_Ship_Date__c' => null,
        'Order_Split_Type__c' => 'Not needed',
        'customer_required_ship_date__c' => date.newInstance(currentDate.Year(), 2, currentDate.day())

      };
	
      Order ord = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
      insert Ord;
    
  }
  /**
   * @author Shrutika Kesarkar
   * @date 19-06-2026
   * @description test method to call batch
   */
  @isTest
  private static void testBookedOrderFirstquartBatch() {
  System.runAs(new User(Id = UserInfo.getUserId())) {
    test.startTest();
    list<Order> lstOrder = [Select Id, Order_Status__c, Hold_Code__c, customer_required_ship_date__c from Order];
    BookedOrdersPerQuarterBatch bob=new BookedOrdersPerQuarterBatch();
    bob.currentDate = date.newInstance(lstOrder[0].customer_required_ship_date__c.Year(), 2, 1);
  	database.executeBatch(bob);
    test.stopTest();
    system.assertEquals(lstOrder.size(), 1);
  }
  }
/**
   * @author Shrutika Kesarkar
   * @date 19-06-2026
   * @description test method to call batch
   */
  @isTest
  private static void testBookedOrderSecondquartBatch() {
  System.runAs(new User(Id = UserInfo.getUserId())) {
    test.startTest();
    list<Order> lstOrder = [Select Id, Order_Status__c, Hold_Code__c, customer_required_ship_date__c from Order];
    lstOrder[0].customer_required_ship_date__c = date.newInstance(lstOrder[0].customer_required_ship_date__c.Year(), 6, lstOrder[0].customer_required_ship_date__c.day());
    update lstOrder;
    BookedOrdersPerQuarterBatch bob=new BookedOrdersPerQuarterBatch();
    bob.currentDate = date.newInstance(lstOrder[0].customer_required_ship_date__c.Year(), 6, 1);
  	database.executeBatch(bob, 1);
    test.stopTest();
    system.assertEquals(lstOrder.size(), 1);

  }
  }
  /**
   * @author Shrutika Kesarkar
   * @date 19-06-2026
   * @description test method to call batch
   */
  @isTest
  private static void testBookedOrderThirdQuartBatch() {
  System.runAs(new User(Id = UserInfo.getUserId())) {
    test.startTest();
    list<Order> lstOrder = [Select Id, Order_Status__c, Hold_Code__c, customer_required_ship_date__c from Order];
    lstOrder[0].customer_required_ship_date__c = date.newInstance(lstOrder[0].customer_required_ship_date__c.Year(), 8, lstOrder[0].customer_required_ship_date__c.day());
    update lstOrder;
    BookedOrdersPerQuarterBatch bob=new BookedOrdersPerQuarterBatch();
    bob.currentDate = date.newInstance(lstOrder[0].customer_required_ship_date__c.Year(), 8, 1);
  	database.executeBatch(bob, 1);
    test.stopTest();
    system.assertEquals(lstOrder.size(), 1);

  }
  }
  /**
   * @author Shrutika Kesarkar
   * @date 19-06-2026
   * @description test method to call batch
   */
  @isTest
  private static void testBookedOrderFourQuartBatch() {
  System.runAs(new User(Id = UserInfo.getUserId())) {
    test.startTest();
    list<Order> lstOrder = [Select Id, Order_Status__c, Hold_Code__c, customer_required_ship_date__c from Order];
    lstOrder[0].customer_required_ship_date__c = date.newInstance(lstOrder[0].customer_required_ship_date__c.Year(), 11, lstOrder[0].customer_required_ship_date__c.day());
    update lstOrder;
    BookedOrdersPerQuarterBatch bob=new BookedOrdersPerQuarterBatch();
    bob.currentDate = date.newInstance(lstOrder[0].customer_required_ship_date__c.Year(), 11 , 1);
  	database.executeBatch(bob, 1);
    test.stopTest();
    system.assertEquals(lstOrder.size(), 1);

  }
  }
   /**
   * @author Shrutika Kesarkar
   * @date 19-06-2026
   * @description test method to call batch
   */
  @isTest
  private static void testBookedOrderFiveQuartBatch() {
  System.runAs(new User(Id = UserInfo.getUserId())) {
    test.startTest();
    list<Order> lstOrder = [Select Id, Order_Status__c, Hold_Code__c, customer_required_ship_date__c from Order];
    lstOrder[0].customer_required_ship_date__c = date.newInstance(lstOrder[0].customer_required_ship_date__c.Year(), 12, lstOrder[0].customer_required_ship_date__c.day());
    update lstOrder;
    BookedOrdersPerQuarterBatch bob=new BookedOrdersPerQuarterBatch();
    bob.currentDate = date.newInstance(lstOrder[0].customer_required_ship_date__c.Year(), 1, 1);
  	database.executeBatch(bob, 1);
    test.stopTest();
    system.assertEquals(lstOrder.size(), 1);

  }
  }
  
  /**
   * @author Shrutika Kesarkar
   * @date 19-06-2026
   * @description test method to call batch
   */
  @isTest
  private static void testBookedOrderErrorquartBatch() {
  System.runAs(new User(Id = UserInfo.getUserId())) {
    test.startTest();
    list<Order> lstOrder = [Select Id, Order_Status__c, Hold_Code__c, customer_required_ship_date__c from Order];
    lstOrder[0].EU_PO_Review_Status__c = 'Required Further Review';
    update lstOrder;
   
    List<ShGl_DisableBusinessLogic__c> lstValidate = [Select id, Disable_Order_Validation_Rules__c from ShGl_DisableBusinessLogic__c Order by createddate desc limit 1];
    lstValidate[0].Disable_Order_Validation_Rules__c = false;
    update lstValidate;
    BookedOrdersPerQuarterBatch bob=new BookedOrdersPerQuarterBatch();
    bob.currentDate = date.newInstance(lstOrder[0].customer_required_ship_date__c.Year(), 2, 1);
    database.executeBatch(bob, 1);
    test.stopTest();
    system.assertEquals(lstOrder.size(), 1);
  }
  }
 
}