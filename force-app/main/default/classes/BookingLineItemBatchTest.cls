@isTest
public class BookingLineItemBatchTest {
  /**   
   * PMD Rule: AvoidComplexity (complexity)
   * @description : to setup test data for BookingLineItemBatchTest class
  */
  @testSetup
  public static void setup() {
    String uniqueUserName = 'BookingLineItemBatchTest' + DateTime.now().getTime() + '@testclass.com';
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
      username = uniqueUserName,
      RBAC_Department__c = 'Service Account',
      RBAC_Group__c = 'API'
    );
    System.runAs(usr) {
      ShGl_DisableFunctionalityLogic__c setting = new ShGl_DisableFunctionalityLogic__c();
      setting.Name = 'System Administrator';
      setting.Disable_Opportunity_Old_Trigger__c = true;
      setting.Disable_Order_Old_Trigger__c = true;
      setting.Disable_Account_Old_Trigger__c = true;

      insert setting;

      ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c();
      settingDisable.Name = 'System Administrator';
      settingDisable.Disable_Opportunity_Validation_Rules__c = true;
      settingDisable.Disable_Order_Validation_Rules__c = true;
      settingDisable.Disable_SBQQ_Quote_Triggers__c = true;
      settingDisable.Disable_Opportunity_Triggers__c = true;
      insert settingDisable;

      List<TriggerControl__c> triggerList = new List<TriggerControl__c>();
      TriggerControl__c setting0 = new TriggerControl__c();
      setting0.Name = 'Order';
      setting0.DisableTrigger__c = true;
      triggerList.add(setting0);
      TriggerControl__c setting1 = new TriggerControl__c();
      setting1.Name = 'Opportunity';
      setting1.DisableTrigger__c = true;
      triggerList.add(setting1);
      insert triggerList;

      //create account and contact to assign to opportunity
      account acct = new account(name = 'test account', AccountNumber = '123456');
      insert acct;
      contact con = new contact(lastname = 'test contact', leadsource = 'web', email = 'testc@test.com', accountId = acct.id);
      insert con;
      acct.AdvocateHub__Referral_Source__c = con.id;
      update acct;
      //insert new opportunity
      List<Opportunity> oppList = new List<Opportunity>();
      Opportunity oppy1 = new Opportunity(
        Name = 'test Opportunity',
        AccountId = acct.id,
        StageName = '1 Discovery',
        CloseDate = system.Today(),
        ForecastCategoryName = 'Omitted',
        Initial_Contacts_Name__c = con.id,
        Business_Unit__c = 'Rubrik',
        Installation_Assigned_To__c = 'FE Install'
      );
      oppList.add(oppy1);
      Opportunity oppy2 = new Opportunity(
        Name = 'test Opportunity2',
        AccountId = acct.id,
        StageName = '1 Discovery',
        CloseDate = system.Today(),
        ForecastCategoryName = 'Omitted',
        Initial_Contacts_Name__c = con.id,
        Business_Unit__c = 'Rubrik',
        Installation_Assigned_To__c = 'FE Install'
      );
      oppList.add(oppy2);
      Opportunity oppy3 = new Opportunity(
        Name = 'test Opportunity1',
        AccountId = acct.id,
        StageName = '1 Discovery',
        CloseDate = system.Today(),
        ForecastCategoryName = 'Best Case',
        Initial_Contacts_Name__c = con.id,
        Business_Unit__c = 'Rubrik',
        Installation_Assigned_To__c = 'FE Install'
      );
      oppList.add(oppy3);

      Opportunity oppy4 = new Opportunity(
      Name = 'test Opportunity1',
      AccountId = acct.id,
      StageName = '1 Discovery',
      CloseDate = system.Today(),
      ForecastCategoryName = 'Omitted',
      Initial_Contacts_Name__c = con.id,
      Business_Unit__c = 'Rubrik',
      Installation_Assigned_To__c = 'FE Install'
      );
      oppList.add(oppy4);

      insert oppList;

      oppList[2].Opportunity_Split_Parent__c = oppList[0].id;
      oppList[2].Split_percentage__c = oppList[0].Split_percentage__c = 50.00;
      oppList[2].Split_Amount__c = oppList[1].Split_Amount__c = 100.00;

      list<Product2> prodlist = new List<Product2>();
      Map<String, Object> prodMap = new Map<String, Object>{
        'Name' => 'Pord A',
        'ProductCode' => 'ProductXYZ',
        'isActive' => true,
        'Family' => 'AIR',
        'Product_Type__c' => 'Appliance'
      };

      Map<String, Object> prodMap1 = new Map<String, Object>{
      'Name' => 'Pord B',
      'ProductCode' => 'ProductABC',
      'isActive' => true,
      'Family' => 'AIR',
      'Product_Type__c' => 'Appliance'
      };
      Product2 pd = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap);
      Product2 pd1 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap1);

      prodlist.add(pd);
      prodlist.add(pd1);

      insert prodlist;

      Id pricebookId = Test.getStandardPricebookId();
      Map<String, Object> quoteMap = new Map<String, Object>{ 'SBQQ__Account__c' => acct.Id, 'SBQQ__Opportunity2__c' => oppList[0].Id };
      SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
      qt1.SBQQ__Opportunity2__c = oppList[0].Id;
      qt1.SBQQ__Primary__c = true;
      qt1.SBQQ__PriceBook__c = pricebookId;
      qt1.ApprovalStatus__c = 'Approved';
      insert qt1;

      oppList[0].Pricebook2Id = pricebookId;
      oppList[0].StageName = '4 Business Justification';
      oppList[0].Partner_Level_Of_Involvement__c = '4.Partner or joint initiated opportunity, partner brought substantial value in sales cycle and getting deal closed';
      oppList[0].SBQQ__PrimaryQuote__c = qt1.Id;
      oppList[0].Amount = 50000;
      oppList[0].New_Expansion_TCV__c = 3000;
      oppList[0].Subsumed_Renewal_TCV__c = 3000;
      oppList[0].ACV_Amount__c = 40000;
      oppList[0].New_Expansion_ACV__c = 2000;
      oppList[0].Renewal_Subsumed_ACV__c = 2000;

      update oppList[0];
      //Create your pricebook entry
      List<PricebookEntry> pbEntry = new List<PricebookEntry>{
        new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prodlist[0].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prodlist[1].Id, UnitPrice = 100.00, IsActive = true)};
      insert pbEntry;

      List<OpportunityLineItem> lstoli = new List<OpportunityLineItem>{
      new OpportunityLineItem(
      OpportunityId = oppList[0].Id,
      Quantity = 5,
      PricebookEntryId = pbEntry[0].Id,
      TotalPrice = 250,
      ACV_Amount__c = 4000,
      New_Expansion_TCV__c = 3000,
      Subsumed_Renewal_TCV__c = 2000,
      New_Expansion_ACV__c = 2000,
      Subsumed_Renewal_Amount__c = 2000
      ),
      new OpportunityLineItem(
      OpportunityId = oppList[0].Id,
      Quantity = 5,
      PricebookEntryId = pbEntry[1].Id,
      TotalPrice = 250,
      ACV_Amount__c = 4000,
      New_Expansion_TCV__c = 3000,
      Subsumed_Renewal_TCV__c = 2000,
      New_Expansion_ACV__c = 2000,
      Subsumed_Renewal_Amount__c = 2000
      ),
      new OpportunityLineItem(
      OpportunityId = oppList[3].Id,
      Quantity = 5,
      PricebookEntryId = pbEntry[0].Id,
      TotalPrice = 0,
      ACV_Amount__c = null,
      New_Expansion_TCV__c = null,
      Subsumed_Renewal_TCV__c = null,
      New_Expansion_ACV__c = null,
      Subsumed_Renewal_Amount__c = null
      ),
      new OpportunityLineItem(
      OpportunityId = oppList[3].Id,
      Quantity = 5,
      PricebookEntryId = pbEntry[0].Id,
      TotalPrice = 0,
      ACV_Amount__c = null,
      New_Expansion_TCV__c = null,
      Subsumed_Renewal_TCV__c = null,
      New_Expansion_ACV__c = null,
      Subsumed_Renewal_Amount__c = null
      )                                                            
      };
      insert lstoli;

      test.startTest();
      Order od = new Order();
      od.Name = 'testOrder1';
      od.Status = 'Draft';
      od.Order_Status__c = 'Pending';
      //od.BookingStatus__c='None';
      od.AccountId = acct.Id;
      od.OpportunityId = oppList[0].Id;
      od.EffectiveDate = Date.Today();
      od.ShippingStreet = 'Test Street';
      od.ShippingCity = 'Test City';
      od.ShippingState = 'California';
      od.ShippingCountry = 'United States';
      od.ShippingPostalcode = '94820';
      od.ship_To_Name__c = acct.id;
      od.Type = 'Revenue';
      od.Est_Ship_Date__c = system.today();
      od.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Revenue Order').getRecordTypeId();
      od.Pricebook2Id = pricebookId;
      //od.Hold_Code__c = 'Missing freight forwarder details';
      insert od;

      od.Pricebook2Id = pricebookId;
      update od;

    Order od2 = od.clone();
	  od2.OpportunityId = oppList[3].Id;
    insert od2;
    List<OrderItem> oritem = new List<OrderItem>{
      new OrderItem(
    OrderId = od.Id,
    Quantity = 10,
    Opportunity_Product__c = lstoli[0].Id,
    PricebookEntryId = pbEntry[0].Id,
    UnitPrice = 10,
    Product2Id = prodlist[0].Id,
    SerialNumber__c = 'AA162403440008,AB162403440009,AC162403440009,AD162403440009'
    ),
    new OrderItem(
    OrderId = od.Id,
    Quantity = 10,
    Opportunity_Product__c = lstoli[1].Id,
    PricebookEntryId = pbEntry[1].Id,
    UnitPrice = 10,
    Product2Id = prodlist[1].Id,
    SerialNumber__c = 'AA162403440008,AB162403440009,AC162403440009,AD162403440009'
    ),
    new OrderItem(
    OrderId = od2.Id,
    Quantity = 10,
    Opportunity_Product__c = lstoli[3].Id,
    PricebookEntryId = pbEntry[1].Id,
    UnitPrice = 10,
    Product2Id = prodlist[1].Id,
    SerialNumber__c = 'AA162403440008,AB162403440009,AC162403440009,AD162403440009'
    ),
    new OrderItem(
    OrderId = od2.Id,
    Quantity = 10,
    Opportunity_Product__c = lstoli[3].Id,
    PricebookEntryId = pbEntry[1].Id,
    UnitPrice = 10,
    Product2Id = prodlist[1].Id,
    SerialNumber__c = 'AA162403440008,AB162403440009,AC162403440009,AD162403440009'
    )
    };
  insert oritem;
      od.Hold_Code__c = ' ';
      od.Order_Status__c = 'Order Accepted';
      od.SBQQ__Contracted__c = false;
      od.Order_Accepted_By__c = usr.id;
      update od;

      od2.Hold_Code__c = ' ';
      od2.Order_Status__c = 'Order Accepted';
      od2.SBQQ__Contracted__c = false;
      od2.Order_Accepted_By__c = usr.id;
      update od2;

      Order od1 = od.clone();
      od1.OpportunityId = oppList[2].Id;
      insert od1;

      List<CCR__c> ccrList = new List<CCR__c>();
      CCR__c cc = new CCR__C(
        Comment__c = 'test1',
        Opportunity__c = oppList[0].id,
        AssignmentStatus__c = 'Unassigned',
        User__c = 'Approved',
        CCR_Type__c = 'Partner Referral Fee',
        Referral_Fee_Amount__c = 100,
        Account_Name__c = acct.id,
        Impacts_Commission__c = true
      );
      ccrList.add(cc);
      Booking__c bkg = new Booking__c(
        Order__c = od1.id,
        Opportunity__c = OppList[0].id,
        Account_Name__c = acct.id,
        status__c = 'Completed',
        RecordTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking').getRecordTypeId()
      );
      insert bkg;

      Booking_Line_item__c newBLI = new Booking_Line_item__c(Booking__c = bkg.Id, Type__c = 'Distributor Fee', Rebate__c = 3);
      insert newBLI;

      CCR__c cc1 = new CCR__C(
        Comment__c = 'test',
        Opportunity__c = oppList[0].id,
        AssignmentStatus__c = 'Unassigned',
        User__c = 'Approved',
        CCR_Type__c = 'Customer Returns / Refunds',
        Amount__c = 500,
        booking__c = bkg.id,
        Account_Name__c = acct.id,
        Impacts_Commission__c = true
      );
      ccrList.add(cc1);
      insert ccrList;
      List<Booking_AdjustmentItems__c> ba = new List<Booking_AdjustmentItems__c>{
      new Booking_AdjustmentItems__c(CCR__c = ccrList[1].id, OrderLineItemId__c = oritem[0].id, Quantity__c = 1),
      new Booking_AdjustmentItems__c(CCR__c = ccrList[1].id, OrderLineItemId__c = oritem[1].id, Quantity__c = 1)};
      insert ba;
      /*OppList[0].CCR__c=ccrList[1].id;
       update OppList[0]; */
      OppList[0].CCR__c = ccrList[1].id;
      update OppList[0];

      CreateDebookingOPPandOrder.CreateNegativeOrder(new List<Id>{ ccrList[1].id });
      test.stoptest();
    }
  }
  /**   
    * PMD Rule: AvoidComplexity (complexity)
    * @description : Call BookingBatch which will call BookingLineItemBatch
   */
  public static testMethod void testAcceptedOrder() {
    test.startTest();

    User usr = [SELECT id FROM User WHERE isActive = TRUE LIMIT 1];
    System.runAs(usr) {
      BookingBatch bb = new BookingBatch();
      ID batchprocessid = database.executeBatch(bb);
    }
    test.stopTest();
    delete [SELECT id FROM orderItem LIMIT 1];
    List<CCR__c> ccrlist= [Select id from CCR__c];
    system.assertEquals(2, ccrlist.size());
  }

    
  /**   
  * PMD Rule: AvoidComplexity (complexity)
  * @description : BookingLineItem DebookOpportunity
  */
  @isTest
  public static void debookOpportunityTest1(){
      system.runAs(new user(Id = UserInfo.getUserId())){
      BookingHelper.isTestRunning = true;
      CCR__c ccrNew = [select Id, CCR_Type__c from CCR__c Where CCR_Type__c = 'Customer Returns / Refunds' limit 1];
      opportunity oppty = [Select id, Name, StageName, CloseDate, AccountId From opportunity Limit 1];
      opportunity debookopp1 = oppty.clone();  
      debookopp1.CCR__c = ccrNew.Id ;
      insert debookopp1;
      debookopp1.StageName = '7 Closed Won';
      update debookopp1;
      Order objOrder = [Select id, OpportunityId, Order_Status__c, Status, EffectiveDate, RecordTypeId, AccountId, Type From Order LIMIT 1];
      Order objDebookOrder = objOrder.clone();
      objDebookOrder.OpportunityId = debookopp1.Id;
      objDebookOrder.Type = 'Booking Adjustment';
      objDebookOrder.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Booking Adjustment Order').getRecordTypeId();
      objDebookOrder.Order_Status__c = 'Order Accepted';
      insert objDebookOrder;
      List<Booking__c> bkgList=new List<Booking__c>();
      bkgList.add(new Booking__c(
      Order__c=objDebookOrder.id,
      Opportunity__c=oppty.Id,
      Account_Name__c=objOrder.AccountId,
      Field_Update_Status__c=' ',
      RecordTypeId=Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking Adjustment').getRecordTypeId(),
      Opportunity_Close_Date__c =system.Today()
      ));
      insert bkgList;
      List<Booking_Line_Item__c>  lstInsertBLI = new List<Booking_Line_Item__c>();
      lstInsertBLI.add(
      new Booking_Line_Item__c(
      Booking__c = bkgList[0].Id,
      Rebate__c = 3,
      Total_price__c = -10,
      New_Expansion_TCV__c = -10,
      Subsumed_Renewal_TCV__c = -10,
      Gross_ACV_Amount__c = -10,
      Gross_New_Expansion_ACV__c = -10,
      Gross_Subsumed_Renewal_ACV__c = -10,
      Type__c = 'Distributor Fee'
      )
      );
      insert lstInsertBLI;
      test.startTest();
      List<id> allSuccessBookingIdsList = new List<id>{bkgList[0].Id};
      BookingLineItemBatch BLI = new BookingLineItemBatch(allSuccessBookingIdsList);
      database.executebatch(BLI);            
      system.assert(bkgList != null);
      test.stopTest();
      }
  }

}