@isTest
public class BookingSyncBatchTest {
  /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : To setup intial data for test class
   */
  @testSetup
  public static void setup() {
    TriggerControls.disableQuoteTrigger = true;
    TriggerControls.disableQuoteLineTrigger = true;
    String uniqueUserName = 'BookingSyncBatchTest' + DateTime.now().getTime() + '@testclass.com';
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
      TriggerControl__c setting2 = new TriggerControl__c();
      setting2.Name = 'Booking';
      setting2.DisableTrigger__c = true;
      triggerList.add(setting2);
      TriggerControl__c setting3 = new TriggerControl__c();
      setting3.Name = 'BookingAudit';
      setting3.DisableTrigger__c = true;
      triggerList.add(setting3);
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
        ForecastCategoryName = 'Best Case',
        Split_percentage__c = 25.00,
        Initial_Contacts_Name__c = con.id,
        Business_Unit__c = 'Rubrik',
        Installation_Assigned_To__c = 'FE Install',
        ETM_Theatre__c = 'APAC',
        ETM_Area__c = 'APAC',
        ETM_Region__c= 'APAC',
        ETM_Territory__c = 'APAC'
      );
      oppList.add(oppy1);
      Opportunity oppy2 = new Opportunity(
        Name = 'test Opportunity1',
        AccountId = acct.id,
        StageName = '1 Discovery',
        CloseDate = system.Today(),
        ForecastCategoryName = 'Best Case',
        Initial_Contacts_Name__c = con.id,
        Business_Unit__c = 'Rubrik',
        Installation_Assigned_To__c = 'FE Install',
        Opp_PLS_ETM_Area__c = 'APAC',
        Opp_PLS_ETM_Region__c = 'APAC',
        Opp_PLS_ETM_Territory__c = 'APAC',
        Opp_PLS_ETM_Theatre__c = 'APAC' 
      );
      oppList.add(oppy2);
      Opportunity oppy3 = new Opportunity(
        Name = 'test Opportunity3',
        AccountId = acct.id,
        StageName = '1 Discovery',
        CloseDate = system.Today(),
        ForecastCategoryName = 'Best Case',
        Initial_Contacts_Name__c = con.id,
        Business_Unit__c = 'Rubrik',
        Installation_Assigned_To__c = 'FE Install'
      );
      oppList.add(oppy3);
      insert oppList;
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
        'ProductCode' => 'ProductXYZ1',
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
      oppList[0].Amount = 1000;
      oppList[0].ACV_Amount__c = 500;
      oppList[2].Opportunity_Split_Parent__c = oppList[0].id;
      oppList[2].Pricebook2Id = pricebookId;
      update oppList;
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
      Order od1 = od.Clone();
      od1.OpportunityId = oppList[1].Id;
      insert od1;

      //Create your pricebook entry
        List<PricebookEntry> lstpbEntry = new List<PricebookEntry>{
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prodlist[0].Id, UnitPrice = 100.00, IsActive = true),
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prodlist[1].Id, UnitPrice = 500.00, IsActive = true)
        };
      insert lstpbEntry;
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>{
        new OpportunityLineItem(
        OpportunityId = oppList[0].Id,
        Quantity = 10,
        PricebookEntryId = lstpbEntry[0].Id,
        TotalPrice = 5 * lstpbEntry[0].UnitPrice,
        ACV_Amount__c = 100,
        New_Expansion_ACV__c = 100,
        New_Expansion_TCV__c = 5 * lstpbEntry[0].UnitPrice,
        Subsumed_Renewal_TCV__c = 100,
        Subsumed_Renewal_Amount__c = 100
      ),
      new OpportunityLineItem(
        OpportunityId = oppList[0].Id,
        Quantity = 10,
        PricebookEntryId = lstpbEntry[1].Id,
        TotalPrice = 5 * lstpbEntry[1].UnitPrice,
        ACV_Amount__c = 500,
        New_Expansion_ACV__c = 500,
        New_Expansion_TCV__c = 250,
        Subsumed_Renewal_TCV__c = 250,
        Subsumed_Renewal_Amount__c = 250
      )
        };

      // test.startTest();

      insert oliList;

      od.Pricebook2Id = pricebookId;
      update od;
        List<OrderItem> lstOrItem = new List<OrderItem>{
        new OrderItem(
        OrderId = od.Id,
        Opportunity_Product__c = oliList[0].id,
        Quantity = 10,
        PricebookEntryId = lstpbEntry[1].Id,
        UnitPrice = 10,
        Product2Id = prodlist[0].Id,
        SerialNumber__c = 'AA162403440008,AB162403440009,AC162403440009,AD162403440009'
      ),
      new OrderItem(
        OrderId = od.Id,
        Opportunity_Product__c = oliList[1].id,
        Quantity = 10,
        PricebookEntryId = lstpbEntry[1].Id,
        UnitPrice = 10,
        Product2Id = prodlist[1].Id
      )
        };
      insert lstOrItem;
      od.Hold_Code__c = ' ';
      od.Order_Status__c = 'Order Accepted';
      od.SBQQ__Contracted__c = false;
      od.Order_Accepted_By__c = usr.id;
      update od;

      List<Booking__c> bkgList = new List<Booking__c>();
      Booking__c bkg = new Booking__c(
        Order__c = od.id,
        Opportunity_Close_Date__c = oppList[0].CloseDate,
        Opportunity__c = oppList[0].id,
        Account_Name__c = acct.id,
        Field_Update_Status__c = ' ',
        RecordTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking').getRecordTypeId()
      );
      insert bkg;

      Booking__c bkg1 = bkg.clone();
      bkg1.Original_Booking__c = bkg.id;
      bkgList.add(bkg1);
      Booking__c bkgThird = new Booking__c(
        Order__c = od.id,
        Opportunity_Close_Date__c = oppList[2].CloseDate,
        Opportunity__c = oppList[2].id,
        Account_Name__c = acct.id,
        Field_Update_Status__c = ' ',
        RecordTypeId = Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking').getRecordTypeId()
      );
      bkgList.add(bkgThird);

      insert bkgList;
      //insert bkgList;
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
      CCR__c cc1 = new CCR__C(
        Comment__c = 'test',
        Opportunity__c = oppList[0].id,
        AssignmentStatus__c = 'Unassigned',
        User__c = 'Approved',
        CCR_Type__c = 'Customer Returns / Refunds',
        Amount__c = od.TotalAmount,
        booking__c = bkg.id,
        Account_Name__c = acct.id,
        Impacts_Commission__c = true
      );
      ccrList.add(cc1);
      insert ccrList;
      Booking_AdjustmentItems__c ba = new Booking_AdjustmentItems__c(CCR__c = ccrList[1].id, OrderLineItemId__c = lstOrItem[0].id, Quantity__c = 1);
      insert ba;
      //OppList[0].CCR__c=ccrList[1].id;
      //update OppList[0];
      List<Booking_Line_Item__c> bliList = new List<Booking_Line_Item__c>{
        new Booking_Line_Item__c(
          Booking__c = bkgList[0].id,
          Type__c = 'Revenue',
          OrderProduct__c = lstOrItem[0].Id,
          Impacts_Gross_Bookings__c = true,
          Impacts_Net_Bookings__c = true,
          Total_Price__c = 10.0,
          New_Expansion_TCV__c = 2,
          Gross_ACV_Amount__c = 5,
          Gross_New_Expansion_ACV__c = 5
        ),
        new Booking_Line_Item__c(
          Booking__c = bkgList[0].id,
          Type__c = 'Revenue',
          OrderProduct__c = lstOrItem[1].Id,
          Impacts_Gross_Bookings__c = true,
          Impacts_Net_Bookings__c = true,
          Total_Price__c = 10.0,
          New_Expansion_TCV__c = 2,
          Gross_ACV_Amount__c = 5,
          Gross_New_Expansion_ACV__c = 5
        ),
        new Booking_Line_Item__c(
          Booking__c = bkgList[0].id,
          Total_Price__c = 10.0,
          Rebate__c = 2.0,
          Impacts_Gross_Bookings__c = true,
          Impacts_Net_Bookings__c = true,
          Impacts_Commission__c = true,
          Type__c = 'Distributor Fee',
          New_Expansion_TCV__c = 2,
          Gross_ACV_Amount__c = 5,
          Gross_New_Expansion_ACV__c = 5
        ),
        new Booking_Line_Item__c(
          Booking__c = bkgList[0].id,
          OrderProduct__c = lstOrItem[0].Id,
          Total_Price__c = 10.0,
          Rebate__c = 2.0,
          Impacts_Gross_Bookings__c = true,
          Impacts_Net_Bookings__c = true,
          Impacts_Commission__c = true,
          Type__c = 'Partner Referral Fee',
          New_Expansion_TCV__c = 2,
          Gross_ACV_Amount__c = 5,
          Gross_New_Expansion_ACV__c = 5,
          CCR__c = ccrList[1].id
        )
      };
      insert bliList;

      List<Booking_split__c> bsList = new List<Booking_split__c>();
      Booking_split__c bs = new Booking_split__c(Booking__c = bkg.Id, Opportunity__c = null, Opportunity_Split__c = 15.00);
      Booking_split__c bsSecond = new Booking_split__c(Booking__c = bkg.Id, Opportunity__c = oppList[0].id, Opportunity_Split__c = 15.00, Theatre__c = 'APAC-C' , Area__c= 'APAC-C', Region__c = 'APAC-C', Territory__c = 'APAC-C', Opp_PLS_ETM_Area__c = 'APAC-C', Opp_PLS_ETM_Region__c = 'APAC-C', Opp_PLS_ETM_Territory__c = 'APAC-C', Opp_PLS_ETM_Theatre__c ='APAC-C');
      Booking_split__c bsThird = new Booking_split__c(Booking__c = bkg.Id, Opportunity__c = oppList[1].id, Opportunity_Split__c = 30.00, Opp_PLS_ETM_Area__c = 'APAC-C', Opp_PLS_ETM_Region__c = 'APAC-C', Opp_PLS_ETM_Territory__c = 'APAC-C', Opp_PLS_ETM_Theatre__c ='APAC-C');

      bsList.add(bs);
      bsList.add(bsSecond);
      bsList.add(bsThird);
      insert bsList;

      oppList[0].closeDate = system.Today().addDays(5);
      test.stoptest();
      system.assertEquals(2, ccrlist.size());
    }

  }
    /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : Test Split Case
   */
    
    public static testMethod void testSplitCase(){
     User usr = [SELECT id FROM User WHERE isActive = TRUE AND email = 'testuser@testclass.com' LIMIT 1];
 	     System.runAs(usr) {
             List<Opportunity> lstOppotunity = [Select Id, Split_percentage__c,OwnerId, ETM_Theatre__c,ETM_Area__c,ETM_Region__c,ETM_Territory__c,Opp_PLS_ETM_Area__c, Opp_PLS_ETM_Region__c,Opp_PLS_ETM_Territory__c, Opp_PLS_ETM_Theatre__c FROM Opportunity limit 2];
             Set<Id> setOppIds = new Set<Id> {lstOppotunity[0].Id,lstOppotunity[1].Id };
             List<Booking_split__c> lstBookingSplit = [SELECT Id, Opportunity__c, Opportunity_Split__c, Sales_Rep__c, Opp_PLS_ETM_Area__c, Opp_PLS_ETM_Region__c, Opp_PLS_ETM_Territory__c, Opp_PLS_ETM_Theatre__c,Theatre__c, Area__c, Region__c, Territory__c FROM booking_split__c where Opportunity__c IN : setOppIds];
         	 lstOppotunity[0].ETM_Theatre__c = 'AMER';
             lstBookingSplit[0].Sales_Rep__c = lstOppotunity[0].OwnerId;
             lstOppotunity[0].Split_percentage__c = 15.00;
             update lstOppotunity[0];
             update lstBookingSplit[0];
		
             test.startTest();
             Booking__c bkg = [SELECT id FROM Booking__c WHERE Original_Booking__c = NULL LIMIT 1];
             List<OpportunityLineItem> lstOppoItem = [Select id, TotalPrice, ACV_Amount__c, New_Expansion_TCV__c, New_Expansion_ACV__c, Subsumed_Renewal_TCV__c, Subsumed_Renewal_Amount__c from OpportunityLineItem where OpportunityId = : lstOppotunity[0].Id];
             lstOppoItem[0].TotalPrice = 10;
			 lstOppoItem[0].ACV_Amount__c = 5;
			 lstOppoItem[0].New_Expansion_TCV__c = 2;
			 lstOppoItem[0].New_Expansion_ACV__c = 5;
			 lstOppoItem[0].Subsumed_Renewal_TCV__c = 10;
		     lstOppoItem[0].Subsumed_Renewal_Amount__c = 10;
			 lstOppoItem[1].TotalPrice = 10;
			 lstOppoItem[1].ACV_Amount__c = 5;
			 lstOppoItem[1].New_Expansion_TCV__c = 2;
			 lstOppoItem[1].New_Expansion_ACV__c = 5;
			 lstOppoItem[1].Subsumed_Renewal_TCV__c = 10;
		     lstOppoItem[1].Subsumed_Renewal_Amount__c = 10;
			 update lstOppoItem;

             List<Booking_Line_Item__c> lstBLI = [SELECT Id , Type__c, Total_Price__c, New_Expansion_TCV__c, Net_Subsumed_Renewal_TCV__c, Gross_ACV_Amount__c, Gross_New_Expansion_ACV__c, Gross_Subsumed_Renewal_ACV__c FROM Booking_Line_Item__c where OrderProduct__r.Opportunity_Product__r.OpportunityId = :lstOppotunity[0].Id ];

             BookingSyncBatch bsb = new BookingSyncBatch(Date.Today());
             ID batchprocessid = database.executeBatch(bsb);
             test.stopTest();
             system.assertEquals([Select id, Theatre__c From Booking_split__c LIMIT 1].Theatre__c, lstOppotunity[0].ETM_Theatre__c);
             
         }
    }
  
  /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : Call BookingSyncBatch
   */
  public static testMethod void testAreaMethod() {
    User usr = [SELECT id FROM User WHERE isActive = TRUE AND email = 'testuser@testclass.com' LIMIT 1];
    System.runAs(usr) {
       
      test.startTest();
      Booking__c bkg = [SELECT id FROM Booking__c WHERE Original_Booking__c = NULL LIMIT 1];
      List<Opportunity> lstOppotunity = [Select Id, Split_percentage__c,OwnerId, ETM_Theatre__c,ETM_Area__c,ETM_Region__c,ETM_Territory__c,Opp_PLS_ETM_Area__c, Opp_PLS_ETM_Region__c,Opp_PLS_ETM_Territory__c, Opp_PLS_ETM_Theatre__c FROM Opportunity limit 2];
      Set<Id> setOppIds = new Set<Id> {lstOppotunity[0].Id,lstOppotunity[1].Id };
      List<Booking_split__c> lstBookingSplit = [SELECT Id, Opportunity__c, Opportunity_Split__c, Sales_Rep__c, Opp_PLS_ETM_Area__c, Opp_PLS_ETM_Region__c, Opp_PLS_ETM_Territory__c, Opp_PLS_ETM_Theatre__c,Theatre__c, Area__c, Region__c, Territory__c FROM booking_split__c where Opportunity__c IN : setOppIds];
        lstOppotunity[0].Opp_PLS_ETM_Area__c = 'APAC';
        lstOppotunity[0].Opp_PLS_ETM_Region__c = 'APAC';
        lstOppotunity[0].Opp_PLS_ETM_Territory__c = 'AMER-C';
        lstBookingSplit[0].Theatre__c='APAC';
        lstBookingSplit[0].Area__c='APAC';
        lstBookingSplit[0].Region__c='APAC';
       lstBookingSplit[0].Territory__c='APAC';
        lstBookingSplit[0].Sales_Rep__c = lstOppotunity[0].OwnerId;
        lstOppotunity[0].Split_percentage__c = 15.00;
        update lstOppotunity[0];
        update lstBookingSplit;
        
        BookingSyncBatch bsb = new BookingSyncBatch(Date.Today());
      	ID batchprocessid = database.executeBatch(bsb);
       	test.stopTest();
        system.assertEquals([Select id, Opp_PLS_ETM_Area__c From Booking_split__c LIMIT 1].Opp_PLS_ETM_Area__c, lstOppotunity[0].Opp_PLS_ETM_Area__c);
    }
  }
  
  /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : Call BookingSyncBatch
   */
  public static testMethod void testBookingMethod() {
    User usr = [SELECT id FROM User WHERE isActive = TRUE AND email = 'testuser@testclass.com' LIMIT 1];
    System.runAs(usr) {
      test.startTest();
      Booking__c bkg = [SELECT id FROM Booking__c WHERE Original_Booking__c = NULL LIMIT 1];
      List<Opportunity> lstOppotunity = [Select Id, Split_percentage__c,OwnerId, ETM_Theatre__c,ETM_Area__c,ETM_Region__c,ETM_Territory__c,Opp_PLS_ETM_Area__c, Opp_PLS_ETM_Region__c,Opp_PLS_ETM_Territory__c, Opp_PLS_ETM_Theatre__c FROM Opportunity limit 2];
      Set<Id> setOppIds = new Set<Id> {lstOppotunity[0].Id,lstOppotunity[1].Id };
      List<Booking_split__c> lstBookingSplit = [SELECT Id, Opportunity__c, Opportunity_Split__c, Sales_Rep__c, Opp_PLS_ETM_Area__c, Opp_PLS_ETM_Region__c, Opp_PLS_ETM_Territory__c, Opp_PLS_ETM_Theatre__c,Theatre__c, Area__c, Region__c, Territory__c FROM booking_split__c where Opportunity__c IN : setOppIds];
        lstOppotunity[0].ETM_Theatre__c = 'APAC-C';
        lstOppotunity[0].ETM_Area__c = 'APAC-C';
        lstOppotunity[0].ETM_Region__c = 'AMER';
        lstBookingSplit[0].Sales_Rep__c = lstOppotunity[0].OwnerId;
        lstOppotunity[0].Split_percentage__c = 15.00;
        lstOppotunity[1].Split_percentage__c = 30.00;
        lstBookingSplit[1].Sales_Rep__c = lstOppotunity[1].OwnerId;
        lstOppotunity[1].Opp_PLS_ETM_Area__c = 'APAC-C';
        lstOppotunity[1].Opp_PLS_ETM_Region__c = 'APAC-C';
        lstOppotunity[1].Opp_PLS_ETM_Territory__c ='APAC-C';
        lstOppotunity[1].Opp_PLS_ETM_Theatre__c = 'AMER';
        update lstOppotunity;
        update lstBookingSplit;
  	  
        
      List<OpportunityLineItem> lstOppoItem = [Select id, TotalPrice, ACV_Amount__c, New_Expansion_TCV__c, New_Expansion_ACV__c, Subsumed_Renewal_TCV__c, Subsumed_Renewal_Amount__c from OpportunityLineItem where OpportunityId = : lstOppotunity[0].Id];
      lstOppoItem[0].TotalPrice = 10;
	  lstOppoItem[0].New_Expansion_TCV__c = 2;
      lstOppoItem[0].Subsumed_Renewal_TCV__c = null;
	  lstOppoItem[0].New_Expansion_ACV__c = 5;
      lstOppoItem[0].ACV_Amount__c = 10;
	  update lstOppoItem[0];
      BookingSyncBatch bsb = new BookingSyncBatch(Date.Today());
      ID batchprocessid = database.executeBatch(bsb);
      test.stopTest();
      List<CCR__c> ccrlist = [SELECT id FROM CCR__c];
      system.assertEquals(2, ccrlist.size());
    }
  }
    /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : Call BookingSyncBatch
   */
  public static testMethod void testBookingMethodforQuarterStartDate() {
    User usr = [SELECT id FROM User WHERE isActive = TRUE AND email = 'testuser@testclass.com' LIMIT 1];
    System.runAs(usr) {
      test.startTest();
      Booking__c bkg = [SELECT id FROM Booking__c WHERE Original_Booking__c = NULL LIMIT 1];
        Date currentDate = getCurrentDate();
        if(currentDate != null){
        	BookingSyncBatch bsb = new BookingSyncBatch(currentDate);
      		ID batchprocessid = database.executeBatch(bsb);    
        }
      test.stopTest();
      List<CCR__c> ccrlist = [SELECT id FROM CCR__c];
      system.assertEquals(2, ccrlist.size());
    }
  }
  /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : Call BookingSyncBatch
   */
  public static testMethod void testBookingMethodplusDay2() {
    User usr = [SELECT id FROM User WHERE isActive = TRUE AND email = 'testuser@testclass.com' LIMIT 1];
    System.runAs(usr) {
      test.startTest();
      Booking__c bkg = [SELECT id FROM Booking__c WHERE Original_Booking__c = NULL LIMIT 1];
      bkg.Field_Update_Status__c = ' ';
      update bkg;
      Integer currentYear = Date.today().year();
      BookingSyncBatch bsb2 = new BookingSyncBatch(Date.newInstance(currentYear, 5, 2));
      ID batchprocessid2 = database.executeBatch(bsb2);
      test.stopTest();
      List<CCR__c> ccrlist = [SELECT id FROM CCR__c];
      system.assertEquals(2, ccrlist.size());
    }
  }
  /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : Call BookingSyncBatch
   */
  public static testMethod void testBookingMethodplusDay5() {
    User usr = [SELECT id FROM User WHERE isActive = TRUE AND email = 'testuser@testclass.com' LIMIT 1];
    System.runAs(usr) {
      test.startTest();
      Booking__c bkg = [SELECT id FROM Booking__c WHERE Original_Booking__c = NULL LIMIT 1];
      bkg.Field_Update_Status__c = 'Core Attributes - Frozen';
      update bkg;
      Integer currentYear = Date.today().year();
      BookingSyncBatch bsb2 = new BookingSyncBatch(Date.newInstance(currentYear, 5, 5));
      ID batchprocessid2 = database.executeBatch(bsb2);
      test.stopTest();
      List<CCR__c> ccrlist = [SELECT id FROM CCR__c];
      system.assertEquals(2, ccrlist.size());
    }
  }
  /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : Call BookingSyncBatch
   */
  public static testMethod void testBookingMethodQ4() {
    User usr = [SELECT id FROM User WHERE isActive = TRUE AND email = 'testuser@testclass.com' LIMIT 1];
    System.runAs(usr) {
      test.startTest();
      Booking__c bkg = [SELECT id FROM Booking__c WHERE Original_Booking__c = NULL LIMIT 1];
      bkg.Field_Update_Status__c = 'Core Attributes - Frozen';
      update bkg;
      Integer currentYear = Date.Today().Year();
      BookingSyncBatch bsb2 = new BookingSyncBatch(Date.newInstance(currentYear, 1, 5));
      ID batchprocessid2 = database.executeBatch(bsb2);
      test.stopTest();
      List<CCR__c> ccrlist = [SELECT id FROM CCR__c];
      system.assertEquals(2, ccrlist.size());
    }
  }
   /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : Call BookingSyncBatch
   */ 
    
    
    public static testMethod void testBookingMethodsQ4() {
      
      
    User usr = [SELECT id FROM User WHERE isActive = TRUE AND email = 'testuser@testclass.com' LIMIT 1];
    System.runAs(usr) {
      test.startTest();
      Booking__c bkg = [SELECT id FROM Booking__c WHERE Original_Booking__c = NULL LIMIT 1];
      bkg.Field_Update_Status__c = '';
      update bkg;
      Integer currentYear = Date.Today().Year();
      BookingSyncBatch bsb2 = new BookingSyncBatch(Date.newInstance(currentYear, 12, 5));
      ID batchprocessid2 = database.executeBatch(bsb2);
      test.stopTest();
      List<CCR__c> ccrlist = [SELECT id FROM CCR__c];
      system.assertEquals(2, ccrlist.size());
    }
  }


    /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : Debook functionality
   */
  public static testMethod void testDebookOppo() {
    User usr = [SELECT id FROM User WHERE isActive = TRUE AND email = 'testuser@testclass.com' LIMIT 1];
    System.runAs(usr) {
      List<CCR__c> ccrList = new List<CCR__c>();
      Booking__c bkg = [SELECT id, Account_Name__c, Opportunity__c FROM Booking__c WHERE Original_Booking__c = NULL LIMIT 1];
      bkg.Field_Update_Status__c = '';
      update bkg;
      List<Opportunity> lstOppotunity = [Select Id, Split_percentage__c,OwnerId, ETM_Theatre__c,ETM_Area__c,ETM_Region__c,ETM_Territory__c,Opp_PLS_ETM_Area__c, Opp_PLS_ETM_Region__c,Opp_PLS_ETM_Territory__c, Opp_PLS_ETM_Theatre__c FROM Opportunity limit 2];
      Set<Id> setOppIds = new Set<Id> {lstOppotunity[0].Id,lstOppotunity[1].Id };
      List<Booking_split__c> lstBookingSplit = [SELECT Id, Opportunity__c, Opportunity_Split__c, Sales_Rep__c, Opp_PLS_ETM_Area__c, Opp_PLS_ETM_Region__c, Opp_PLS_ETM_Territory__c, Opp_PLS_ETM_Theatre__c,Theatre__c, Area__c, Region__c, Territory__c FROM booking_split__c where Opportunity__c IN : setOppIds];
        lstOppotunity[0].ETM_Theatre__c = 'APAC-C';
        lstOppotunity[0].ETM_Area__c = 'APAC-C';
        lstOppotunity[0].ETM_Region__c = 'APAC-C';
        lstOppotunity[0].ETM_Territory__c = 'AMER';
        lstBookingSplit[0].Sales_Rep__c = lstOppotunity[0].OwnerId;
        lstOppotunity[0].Split_percentage__c = 15.00;
      	update lstOppotunity[0];
        update lstBookingSplit[0];
      List<Booking_Line_Item__c> lstInsertBLI = new List<Booking_Line_Item__c>();
      lstInsertBLI.add(
        new Booking_Line_Item__c(
          Booking__c = bkg.Id,
          Total_price__c = 100,
          New_Expansion_TCV__c = 50,
          Subsumed_Renewal_TCV__c = 50,
          Gross_ACV_Amount__c = 100,
          Gross_New_Expansion_ACV__c = 50,
          Gross_Subsumed_Renewal_ACV__c = 50
        )
      );
      lstInsertBLI.add(
        new Booking_Line_Item__c(
          Booking__c = bkg.Id,
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
      CCR__c cc1 = new CCR__C(
        Comment__c = 'test',
        Opportunity__c = bkg.Opportunity__c,
        AssignmentStatus__c = 'Unassigned',
        User__c = 'Pending',
        CCR_Type__c = 'Customer Returns / Refunds',
        Customer_Returns_Type__c = 'Amount Based',
        Amount__c = 100.00,
        Effective_Date__c = Date.Today().addDays(5),
        booking__c = bkg.id,
        Account_Name__c = bkg.Account_Name__c,
        Impacts_Commission__c = true
      );
      ccrList.add(cc1);

      insert ccrList;
      test.startTest();
      ccrList[0].User__c = 'Approved';
      update ccrList;
        
      
      List<Booking_Line_Item__c> lstUpdateBLI = new List<Booking_Line_Item__c>();
      lstUpdateBLI.add(
        new Booking_Line_Item__c(
           CCR__c = ccrList[0].Id,
           Booking__c = bkg.id,
          Total_Price__c = -2,
          New_Expansion_TCV__c = -3,
          Subsumed_Renewal_TCV__c = -3,
          Gross_ACV_Amount__c = -2,
          Gross_New_Expansion_ACV__c = -3,
          Gross_Subsumed_Renewal_ACV__c = -1
        )
      );
      lstUpdateBLI.add(
        new Booking_Line_Item__c(
          Booking__c = bkg.id,
          Rebate__c = 3,
          Total_Price__c = 3,
          New_Expansion_TCV__c = 2,
          Subsumed_Renewal_TCV__c = 1,
          Gross_ACV_Amount__c = 34,
          Gross_New_Expansion_ACV__c = 10,
          Gross_Subsumed_Renewal_ACV__c = 10,
          Type__c = 'Distributor Fee'
        )
      );

      insert lstUpdateBLI;
      List<Opportunity> lstOpprtunity = new List<Opportunity>();
      Opportunity opp1 = TestDataFactory.getOpportunity();
        opp1.Opportunity_Type__c = 'Debooking';
        opp1.CCR__c = ccrList[0].Id;
          opp1.Amount = -100.00;
          opp1.New_Expansion_ACV__c = -50;
          opp1.New_Expansion_TCV__c = -50;
          opp1.ACV_Amount__c = -100;
          opp1.Subsumed_Renewal_TCV__c = -50;
          opp1.Renewal_Subsumed_ACV__c = -50;
	  insert opp1;
        BookingSyncBatch bsb2 = new BookingSyncBatch(Date.Today());
      //BookingSyncBatch bsb2=new BookingSyncBatch(Date.today());
      ID batchprocessid2 = database.executeBatch(bsb2);
      system.assertEquals(1, ccrList.size());
      test.stopTest();
    }
  }
  
     /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : execute scheduler
   */
    public static testMethod void testExecuteSyncBookingBatch(){
      User usr = [SELECT id FROM User WHERE isActive = TRUE AND email = 'testuser@testclass.com' LIMIT 1];
      System.runAs(usr) { 
      Booking__c bkg = [SELECT id, Account_Name__c, Opportunity__c FROM Booking__c WHERE Original_Booking__c = NULL LIMIT 1];
      bkg.Field_Update_Status__c = '';
      update bkg;
      
      test.startTest();
		  BookingSyncBatch.executeSyncBookingBatch();
      test.stopTest();
      List<CCR__c> ccrlist = [SELECT id FROM CCR__c];
      system.assertEquals(2, ccrlist.size());
      }
    }
    
   /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : Error for message
   */
    public static testMethod void testErrorForMessage(){
      User usr = [SELECT id FROM User WHERE isActive = TRUE AND email = 'testuser@testclass.com' LIMIT 1];
    System.runAs(usr) { 
      Booking__c bkg = [SELECT id, Account_Name__c, Opportunity__c FROM Booking__c WHERE Original_Booking__c = NULL LIMIT 1];
      bkg.Field_Update_Status__c = '';
      update bkg;
      String errorMessage = 'E'.repeat(131073);
      String UnProcessedRecord = String.valueOf(bkg.Id).repeat(255);
      String strBookingOrAdj = 'Error';
        test.startTest();
		    BookingSyncBatch.getErrorForMessage(UnProcessedRecord, errorMessage, strBookingOrAdj, 'ClassName', 'Error');
        test.stopTest();
        List<CCR__c> ccrlist = [SELECT id FROM CCR__c];
        system.assertEquals(2, ccrlist.size());


    }
    }
    
    /**
   * PMD Rule: AvoidComplexity (complexity)
   * @description : Debook functionality
   */
    public static testMethod void testDebookOppoForQuarterEnd() {
        User usr = [SELECT id FROM User WHERE isActive = TRUE AND email = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr) {
            Date currentDate =  getCurrentDate();
            if(currentDate != null){
                List<CCR__c> ccrList = new List<CCR__c>();
                Booking__c bkg = [SELECT id, Account_Name__c, Opportunity__c FROM Booking__c WHERE Original_Booking__c = NULL LIMIT 1];
                bkg.Field_Update_Status__c = '';
                update bkg;
                
                List<Booking_Line_Item__c> lstInsertBLI = new List<Booking_Line_Item__c>();
                lstInsertBLI.add(
                    new Booking_Line_Item__c(
                        Booking__c = bkg.Id,
                        Total_price__c = 100,
                        New_Expansion_TCV__c = 50,
                        Subsumed_Renewal_TCV__c = 50,
                        Gross_ACV_Amount__c = 100,
                        Gross_New_Expansion_ACV__c = 50,
                        Gross_Subsumed_Renewal_ACV__c = 50
                    )
                );
                 lstInsertBLI.add(
                    new Booking_Line_Item__c(
                        Booking__c = bkg.Id,
                        Total_price__c = 200,
                        New_Expansion_TCV__c = 100,
                        Subsumed_Renewal_TCV__c = 100,
                        Gross_ACV_Amount__c = 200,
                        Gross_New_Expansion_ACV__c = 100,
                        Gross_Subsumed_Renewal_ACV__c = 100
                    )
                );
                lstInsertBLI.add(
                    new Booking_Line_Item__c(
                        Booking__c = bkg.Id,
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
                CCR__c cc1 = new CCR__C(
                    Comment__c = 'test',
                    Opportunity__c = bkg.Opportunity__c,
                    AssignmentStatus__c = 'Unassigned',
                    User__c = 'Pending',
                    CCR_Type__c = 'Customer Returns / Refunds',
                    Customer_Returns_Type__c = 'Amount Based',
                    Amount__c = 100.00,
                    Effective_Date__c = Date.Today().addDays(5),
                    booking__c = bkg.id,
                    Account_Name__c = bkg.Account_Name__c,
                    Impacts_Commission__c = true
                );
                ccrList.add(cc1);
                
                insert ccrList;
                test.startTest();
                ccrList[0].User__c = 'Approved';
                update ccrList;
                
                
                List<Booking_Line_Item__c> lstUpdateBLI = new List<Booking_Line_Item__c>();
                lstUpdateBLI.add(
                    new Booking_Line_Item__c(
                        CCR__c = ccrList[0].Id,
                        Booking__c = bkg.id,
                        Total_Price__c = -2,
                        New_Expansion_TCV__c = -3,
                        Subsumed_Renewal_TCV__c = -3,
                        Gross_ACV_Amount__c = -2,
                        Gross_New_Expansion_ACV__c = -3,
                        Gross_Subsumed_Renewal_ACV__c = -1
                    )
                );
                lstUpdateBLI.add(
                    new Booking_Line_Item__c(
                        Booking__c = bkg.id,
                        Rebate__c = 3,
                        Total_Price__c = 3,
                        New_Expansion_TCV__c = 2,
                        Subsumed_Renewal_TCV__c = 1,
                        Gross_ACV_Amount__c = 34,
                        Gross_New_Expansion_ACV__c = 10,
                        Gross_Subsumed_Renewal_ACV__c = 10,
                        Type__c = 'Distributor Fee'
                    )
                );
                
                insert lstUpdateBLI;
                List<Opportunity> lstOpprtunity = new List<Opportunity>();
                Opportunity opp1 = TestDataFactory.getOpportunity();
                opp1.Opportunity_Type__c = 'Debooking';
                opp1.CCR__c = ccrList[0].Id;
                opp1.Amount = -100.00;
                opp1.New_Expansion_ACV__c = -50;
                opp1.New_Expansion_TCV__c = -50;
                opp1.ACV_Amount__c = -100;
                opp1.Subsumed_Renewal_TCV__c = -50;
                opp1.Renewal_Subsumed_ACV__c = -50;
                insert opp1;
                BookingSyncBatch bsb2 = new BookingSyncBatch(currentDate);
                ID batchprocessid2 = database.executeBatch(bsb2);
                system.assertEquals(1, ccrList.size());
                test.stopTest();
                
            }
            
        }
    }
    
    /**
     * @description This method is used to return current date during Quarter StartDate 
     * that will help to get the code coverage on BookingSyncBatch
     * @return Date
     */
    private static Date getCurrentDate(){
        Date currentDate = System.today();
        Integer currentMonth = currentDate.month();
        Integer currentDay = currentDate.day();
        if(currentDay >= 1 && currentDay <= 5 && (
            currentMonth == 2 ||
            currentMonth == 5 ||
            currentMonth == 8 ||
            currentMonth == 11))
        {
            return currentDate = currentDate.addDays(6);    
        }
        return null;
    }
}