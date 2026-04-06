@istest
public class PolarisFulfilment_WebServiceTest {
 private static Map<Integer, String> OPP_STAGENAME_MAP = new Map<Integer, String>{ 4 => '4 Business Justification', 5 => '5 Negotiate & Close', 6 => '6 PO With Channel' };
    @testSetup static void createTestData() {
    String uniqueUserName = 'TestUser1' + DateTime.now().getTime() + '@rbk.com';
    Profile pf = [SELECT Id FROM Profile WHERE Name = 'API Integration User'];
      User usr2 = new user(
      Username = 'api.integration.user@example.com',
      firstname = 'test123',
      lastname = 'user123',
            Email = 'api.integration.user@example.com',
            Alias = 'apiuser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
      profileid = pf.Id
    );
    insert usr2;
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
    System.runAs(usr) {
      insert new ShGl_DisableBusinessLogic__c(
        Disable_SBQQ_Quote_Triggers__c = true,
        Disable_SBQQ_QuoteLine_Triggers__c = true,
        Disable_Opportunity_Triggers__c = true,
        Disable_Order_Email_Alerts__c = false,
        Disable_Order_Triggers__c = true,
        Disable_Opportunity_Validation_Rules__c = true,
        Disable_Entitlement_Validation_Rules__c = true,
        setupOwnerId = usr.id
      );

      TriggerControl__c custsetting = new TriggerControl__c();
      custsetting.Name = 'Opportunity';
      custsetting.DisableTrigger__c = true;

      insert custsetting;
      TriggerControl__c custsetting2 = new TriggerControl__c();
      custsetting2.Name = 'Entitlement';
      custsetting2.DisableTrigger__c = true;

      insert custsetting2;

      TriggerControl__c custsetting3 = new TriggerControl__c();
      custsetting3.Name = 'Order';
      custsetting3.DisableTrigger__c = true;

      insert custsetting3;

      TriggerControl__c PortalUserCreation = new TriggerControl__c();
      PortalUserCreation.Name = 'PortalUserCreation';
      insert PortalUserCreation;

      ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
      disableFuncCS.Disable_Order_Old_Trigger__c = true;
      insert disableFuncCS;
      StateNameCode__c custset = new StateNameCode__c();
      custset.Name = 'California';
      custset.Code__c = 'US-CA';
      insert custset;

      Date closeDt = System.Today() + 30;
      String uniqueUserNameOne = 'standarduser' + DateTime.now().getTime() + '@testorg.com';


      Account acct = (Account) ShGl_TestFactory.createSObject(new Account(), null);
      insert acct;
        Id partner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
          Map<String, Schema.RecordTypeInfo> AcRecTypeInfo = Schema.SObjectType.Account.getRecordTypeInfosByName();
            List<Account> accounts = new List<Account>{
                new Account(Name = 'Test Account', RecordTypeId = AcRecTypeInfo.get('Customer/Prospect').getRecordTypeId()),
                new Account(FedRAMP__c = false,Name = 'Promark Technology, Inc.', Type = 'Distributor', RecordTypeId = AcRecTypeInfo.get('Partner/Distributor').getRecordTypeId())
            };
            insert accounts;
            Opportunity opp = TestDataFactory.getOpportunity(accounts[0]);
            opp.Distributor_Lookup__c = accounts[1].Id;
            opp.Partner_Lookup__c = accounts[1].Id;
            opp.Aspen_Eligibility__c = 'Proposed Aspen';
            opp.StageName = OPP_STAGENAME_MAP.get(4);
            opp.Pricebook2Id =  System.Label.CPQPricebookId;
            insert opp;
            Account customer = accounts[1];
       /* Account customer = new Account(
        Name = 'Customer',
        recordtypeId = partner,
        Phone = '123-456-7890',
        AccountNumber = 'Test',
        Distributor__c = acct.Id,
        Contract_Status__c = 'Pending',
        BillingStreet = '123 street',
        BillingCity = 'Santa Clara',
        BillingState = 'California',
        BillingPostalCode = '95050',
        BillingCountry = 'United States',
        ShippingStreet = '123 street',
        ShippingCity = 'Santa Clara',
        ShippingState = 'California',
        ShippingPostalCode = '95050',
            ShippingCountry = 'United States',
            FedRAMP__c = false
      );
        insert customer;*/

      Map<String, Object> entMap = new Map<String, Object>{ 'Accountid' => customer.Id };

      //Creating Entitlements
      TriggerControl__c trgCnt = new TriggerControl__c(Name = 'Entitlement', DisableTrigger__c = false);
      insert trgCnt;

      Test.startTest();
      List<Entitlement> entLst = (List<Entitlement>) ShGl_TestFactory.createSObjectList(new Entitlement(), 2, entMap);
      insert entLst;

      //Generate the Contact
      Map<String, Object> cntMap = new Map<String, Object>{
        'AccountId' => customer.Id,
        'Email' => 'leademail@hidden.com'
      };
      Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);

      insert cnt1;

      //Generate the Opportunity
      Map<String, Object> oppMap = new Map<String, Object>{
        'AccountId' => customer.Id,
        'Initial_Contacts_Name__c' => cnt1.Id,
        'Primary_Competitor__c' => 'Other',
        'Other_Primary_Competitor__c' => 'Other',
        'StageName' => '1 Discovery',
        'Other_Competitor_Field__c' => 'Other',
        'ForecastCategoryName' => 'Best Case'
      };
      Opportunity oppty = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
      oppty.Opportunity_Sub_Type__c = 'Renewal';
      insert oppty;

      list<Product2> prodlist = new List<Product2>();
      Map<String, Object> prodMap = new Map<String, Object>{
        'Name' => 'Pord A',
        'ProductCode' => 'ProductXYZ',
        'isActive' => true,
        'Family' => 'POLARIS',
        'Category__c' => 'NFR',
        'Product_Level__c' => 'Hybrid Software',
        'Bundle_Features__c' => '',
        'Product_Type__c' => 'EDGE'
      };
      Product2 pd = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap);
      pd.Asset_Priority__c = 1;
      pd.Create_Asset__c = true;
      pd.License_Type__c = 'Subscription';
      prodlist.add(pd);

      Map<String, Object> prodMap2 = new Map<String, Object>{
        'Name' => 'Pord A',
        'ProductCode' => 'ProductXYZ',
        'isActive' => true,
        'Family' => 'POLARIS',
        'Product_Type__c' => 'GPS',
        'Category__c' => 'Support',
        'License_Type__c' => 'Subscription'
      };
      Product2 pd2 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap2);
      pd2.Asset_Priority__c = 0;
      prodlist.add(pd2);

      Map<String, Object> prodMap3 = new Map<String, Object>{
        'Name' => 'Pord A',
        'ProductCode' => 'ProductXYZ',
        'isActive' => true,
        'Family' => 'POLARIS',
        'Product_Type__c' => 'RADAR'
      };
      Product2 pd3 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap3);
      //prodlist.add(pd3);
      pd3.Asset_Priority__c = 1;

      Map<String, Object> prodMap4 = new Map<String, Object>{
        'Name' => 'Pord A',
        'ProductCode' => 'ProductXYZ',
        'isActive' => true,
        'Family' => 'POLARIS',
        'Category__c' => 'NFR',
        'Product_Level__c' => 'Hybrid Software',
        'Bundle_Features__c' => 'Polaris Radar;CloudOn;CloudOut;Polaris GPS;Premium Support;RCDM;Edge',
        'Product_Type__c' => 'Enterprise Edition',
        'Upgrade_Path__c' => 'Business to Enterprise',
        'Family' => 'Rubrik Scale',
        'Product_Subtype__c' => 'GO CNV'
      };
      Product2 pd4 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap4);
      pd4.Asset_Priority__c = 1;
      pd4.Create_Asset__c = true;
      pd4.License_Type__c = 'Subscription';
      prodlist.add(pd4);

      Map<String, Object> prodMap5 = new Map<String, Object>{
        'Name' => 'Pord A',
        'ProductCode' => 'ProductXYZ',
        'isActive' => true,
        'Family' => 'POLARIS',
        'Category__c' => 'NFR',
        'Product_Level__c' => 'Hybrid Software',
        'Bundle_Features__c' => 'Polaris Radar;CloudOn;CloudOut;Polaris GPS;Premium Support;RCDM;Edge',
        'Product_Type__c' => 'Enterprise Edition',
        'Family' => 'Rubrik Scale',
        'Product_Subtype__c' => 'GO CNV'
      };
      Product2 pd5 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap5);
      pd5.Asset_Priority__c = 1;
      pd5.Create_Asset__c = true;
      pd5.License_Type__c = 'Subscription';
      prodlist.add(pd5);

      insert prodlist;

      Map<String, Object> asstMap = new Map<String, Object>{
        'AccountId' => customer.id,
        'Product2Id' => prodlist[0].id
      };

      Asset ast = (Asset) ShGl_TestFactory.createSObject(new Asset(), asstMap);
      insert ast;

      Id pricebookId = Test.getStandardPricebookId();
      Map<String, Object> quoteMap = new Map<String, Object>{
        'SBQQ__Account__c' => customer.Id,
        'SBQQ__Opportunity2__c' => oppty.Id
      };
      SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
      qt1.SBQQ__Opportunity2__c = oppty.Id;
      qt1.SBQQ__Primary__c = true;
      qt1.SBQQ__PriceBook__c = pricebookId;
      qt1.ApprovalStatus__c = 'Approved';
      insert qt1;

      oppty.Pricebook2Id = pricebookId;
      oppty.StageName = '4 Business Justification';
      oppty.Partner_Level_Of_Involvement__c = '1.Rubrik initiated, Partner was fulfillment only';
      oppty.SBQQ__PrimaryQuote__c = qt1.Id;
        //oppty.Distributor_Lookup__c = acct.Id;
        //oppty.Partner_Lookup__c = customer.Id;
        update oppty;
        
        Order od = new Order();
        od.Status = 'Draft';
        od.AccountId = customer.Id;
        od.OpportunityId = oppty.Id;
        od.EffectiveDate = Date.Today();
        od.ShippingStreet ='Test Street';
        od.ShippingCity ='Test City';
        od.ShippingState ='California';
        od.ShippingCountry ='United States';
        od.ShippingPostalcode ='94820';
        //od.ship_To_Name__c = acct.id;
        od.Type = 'POC';
        od.Est_Ship_Date__c = system.today();
        od.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order').getRecordTypeId();
        od.Pricebook2Id = pricebookId;
        
        insert od;
        
        //Create your pricebook entry
        PricebookEntry pbEntry = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prodlist[0].Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbEntry;
        
        PricebookEntry pbEntry1 = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prodlist[1].Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbEntry1;
       
       PricebookEntry pbEntry2 = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prodlist[2].Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbEntry2;
            
        PricebookEntry pbEntry3 = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prodlist[3].Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbEntry3;
       
      od.Pricebook2Id = pricebookId;
      update od;
      OrderItem oritem = new OrderItem(
        OrderId = od.Id,
        Quantity = 10,
        PricebookEntryId = pbEntry.Id,
        UnitPrice = 10,
        Product2Id = prodlist[0].Id,
        SerialNumber__c = 'AA162403440008,AB162403440009,AC162403440009,AD162403440009'
      );
      insert oritem;

      OrderItem oritem1 = new OrderItem(
        OrderId = od.Id,
        Quantity = 10,
        PricebookEntryId = pbEntry1.Id,
        UnitPrice = 10,
        Product2Id = prodlist[1].Id,
        SerialNumber__c = 'AA162403440008,AB162403440009,AC162403440009,AD162403440009'
      );
      insert oritem1;

      OrderItem oritem2 = new OrderItem(
        OrderId = od.Id,
        Quantity = 10,
        PricebookEntryId = pbEntry2.Id,
        UnitPrice = 10,
        Product2Id = prodlist[2].Id,
        SerialNumber__c = 'AA162403440078,AA162403440079,AA1624034400710,AA162403440011'
      );
      insert oritem2;

      OrderItem oritem3 = new OrderItem(
        OrderId = od.Id,
        Quantity = 10,
        PricebookEntryId = pbEntry3.Id,
        UnitPrice = 10,
        Product2Id = prodlist[3].Id,
        SerialNumber__c = 'AA162403440018,AA162403440029,AA1624034400740,AA162403440061'
      );
      insert oritem3;

      entLst[0].Order_Service_Item__c = oritem.id;
      entLst[1].Order_Service_Item__c = oritem1.id;
      //entLst[2].Order_Service_Item__c  = oritem2.id;

      update entLst[0];
      update entLst[1];

      Test.stopTest();
    }
  }

  static testMethod void testPostRestService() {
    User usr = [SELECT id, alias FROM user where alias = 'apiuser' ORDER BY createddate DESC LIMIT 1];
    System.runAs(usr) {
      List<product2> prodlist = [select id from product2 where Create_Asset__c = true and License_Type__c = 'Subscription'];
    Product_Feature__c pfObj = new Product_Feature__c();
        pfObj.Value__c = '2';
        pfObj.Unit__c = 'BETB';
        pfObj.Product_Name__c = prodlist[0].Id;
        pfObj.Product_Code__c = 'Pord A';
        pfObj.Status__c = 'ACTIVE';
        pfObj.Feature_start_date__c = system.Today();
        
        insert pfObj;
      Order order = [
        SELECT
          Id,
          AccountId,
          Account.Name,
          Account.Region__c,
          /*Ship_To_Name__c,*/ Ship_to_Email__c,
          Order_Status__c,
          Polaris_GPS_Region__c,
          Polaris_Fulfillment_Status__c,
          (
            SELECT id, PricebookEntry.Product2.Name, Quantity, PricebookEntry.Product2.Bundle_Features__c
            FROM orderItems
          )
        FROM Order
        LIMIT 1
      ];
      Order.Order_Status__c = 'Order Accepted';
      Order.Hold_Code__c = '';
      order.Send_for_Polaris_Fulfilment__c = true;
      update order;
      Test.startTest();

      //As Per Best Practice it is important to instantiate the Rest Context

      RestRequest req = new RestRequest();
      RestResponse res = new RestResponse();

      req.requestURI = '/services/apexrest/getPolarisOrders'; //Request URL
      req.httpMethod = 'GET';
      req.addHeader('Content-Type', 'application/json');
      req.addHeader('orderid', order.id);
      req.addHeader('ordfields', 'LastModifiedBy.Name');
      req.addHeader('orditemfields', 'Product2.Id');
      
      RestContext.request = req;
      RestContext.response = res;

      PolarisFulfilment_WebService.getPolarisOrders();
      system.assert(res != null);
      Test.stopTest();
    }

  }
    
    static testMethod void testPostRestServiceException() {
    User usr = [SELECT id, alias FROM user where alias = 'apiuser' ORDER BY createddate DESC LIMIT 1];
    System.runAs(usr) {
      Order order = [
        SELECT
          Id,
          AccountId,
          Account.Name,
          Account.Region__c,
          /*Ship_To_Name__c,*/ Ship_to_Email__c,
          Order_Status__c,
          Polaris_GPS_Region__c,
          Polaris_Fulfillment_Status__c,
          (
            SELECT id, PricebookEntry.Product2.Name, Quantity, PricebookEntry.Product2.Bundle_Features__c
            FROM orderItems
          )
        FROM Order
        LIMIT 1
      ];
      Order.Order_Status__c = 'Order Accepted';
      Order.Hold_Code__c = '';
      order.Send_for_Polaris_Fulfilment__c = true;
      update order;
      Test.startTest();

      //As Per Best Practice it is important to instantiate the Rest Context

      RestRequest req = new RestRequest();
      RestResponse res = new RestResponse();

      req.requestURI = '/services/apexrest/getPolarisOrders'; //Request URL
      req.httpMethod = 'GET';
      req.addHeader('Content-Type', 'application/json');
      req.addHeader('readonly', 'true');
      req.addHeader('orderid', 'orderid');
      req.addHeader('ordFields', 'LastModifiedBy.Name');
      req.addHeader('ordItemFields', 'Product2.Id');
      RestContext.request = req;
      RestContext.response = res;

      PolarisFulfilment_WebService.getPolarisOrders();
      system.assert(res != null);
      Test.stopTest();
    }

  }
}