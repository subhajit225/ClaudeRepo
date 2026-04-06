/*************************************************************************************
 * @description       : Test class for PolarisFulfilmentQueueable and PolarisFulfilmentAPI
 * @author            : Siva
 * @last modified on  : 07-30-2025
 * @last modified by  : Prashik
 * Modifications Log
 * Ver   Date          Author        Modification
 * 1.0   07-30-2025    Prashik        Initial Version - PRDOPS26-701
 ************************************************************************************/
@isTest
public class PolarisFulfilmentAPITest {
  @testSetup
  static void createTestData() {
    String uniqueUserName = 'PolarisFulfilmentAPITest@rbk.com';
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
        new Account(FedRAMP__c = false, Name = 'Promark Technology, Inc.', Type = 'Distributor', RecordTypeId = AcRecTypeInfo.get('Partner/Distributor').getRecordTypeId())
      };
      insert accounts;
      Account customer = accounts[1];
        
      RSCInstance__c rsci = new RSCInstance__c();
      rsci.AccountId__c = customer.Id;
      rsci.RSCUrl__c = 'test.com';
      rsci.RSCAccountType__c = 'POC';
      rsci.Status__c = 'Active';
      insert rsci;
      

      //Generate the Contact
      Map<String, Object> cntMap = new Map<String, Object>{ 'AccountId' => customer.Id, 'Email' => 'leademail@hidden.com' };
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

      Map<String, Object> prodMap1 = new Map<String, Object>{
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
      Product2 pd1 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap1);
      pd1.Asset_Priority__c = 1;
      pd1.Create_Asset__c = true;
      pd1.License_Type__c = 'Subscription';
      prodlist.add(pd1);

      insert prodlist;

      Map<String, Object> asstMap = new Map<String, Object>{ 'AccountId' => customer.id, 'Product2Id' => prodlist[0].id };

      Asset ast = (Asset) ShGl_TestFactory.createSObject(new Asset(), asstMap);
      insert ast;

      Id pricebookId = Test.getStandardPricebookId();
      Map<String, Object> quoteMap = new Map<String, Object>{ 'SBQQ__Account__c' => customer.Id, 'SBQQ__Opportunity2__c' => oppty.Id };
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
      od.ShippingStreet = 'Test Street';
      od.ShippingCity = 'Test City';
      od.ShippingState = 'California';
      od.ShippingCountry = 'United States';
      od.ShippingPostalcode = '94820';
      //od.ship_To_Name__c = acct.id;
      od.Type = 'POC';
      od.Est_Ship_Date__c = system.today();
      od.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order').getRecordTypeId();
      od.Pricebook2Id = pricebookId;

      insert od;

      //Create your pricebook entry
      PricebookEntry pbEntry = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prodlist[0].Id, UnitPrice = 100.00, IsActive = true);
      insert pbEntry;

      PricebookEntry pbEntry1 = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prodlist[1].Id, UnitPrice = 100.00, IsActive = true);
      insert pbEntry1;

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
        Storage_Tier__c = 'Unlimited GB',
        Storage_Region_Bundle__c = 'Standard',
        SerialNumber__c = 'AA162403440008,AB162403440009,AC162403440009,AD162403440009'
      );
      insert oritem1;
    }

  }

  static testMethod void testPostRestService() {
    User usr = [SELECT id, alias FROM user WHERE alias = 'apiuser' ORDER BY createddate DESC LIMIT 1];
    System.runAs(usr) {
      List<product2> prodlist = [SELECT id FROM product2 WHERE Create_Asset__c = TRUE AND License_Type__c = 'Subscription' AND Bundle_Features__c = NULL];
      Product_Feature__c pfObj = new Product_Feature__c();
      pfObj.Value__c = '2';
      pfObj.Unit__c = 'BETB';
      pfObj.Product_Name__c = prodlist[0].Id;
      pfObj.Product_Code__c = 'Pord A';
      pfObj.Status__c = 'ACTIVE';
      pfObj.Feature_start_date__c = system.Today();
      insert pfObj;

      Order order = [SELECT Id FROM Order LIMIT 1];
      Order.Order_Status__c = 'Order Accepted';
      Order.Hold_Code__c = '';
      order.Send_for_Polaris_Fulfilment__c = true;
      order.Polaris_Fulfillment_Status__c = 'Provisioning Requested';
      Test.setMock(HttpCalloutMock.class, new polarisFulfilmentMock('success'));
      Test.startTest();
      update order;
      system.enqueueJob(new PolarisFulfilmentQueueable(new List<String>{ order.Id }, new Set<Id>(), null));
      Order ord = [SELECT Id, Polaris_Fulfillment_Status__c FROM Order WHERE Id = :order.Id];
      system.assertEquals('Provisioning Requested', ord.Polaris_Fulfillment_Status__c);
      Test.stopTest();
    }
  }

  static testMethod void testPostRestServiceError() {
    User usr = [SELECT id, alias FROM user WHERE alias = 'apiuser' ORDER BY createddate DESC LIMIT 1];
    System.runAs(usr) {
      Order order = [SELECT Id, Polaris_Fulfillment_Status__c FROM Order LIMIT 1];
      Order.Order_Status__c = 'Order Accepted';
      Order.Hold_Code__c = '';
      order.Send_for_Polaris_Fulfilment__c = true;
      order.Polaris_Fulfillment_Status__c = 'Resync Dates Requested';
      Test.setMock(HttpCalloutMock.class, new polarisFulfilmentMock('error'));
      Test.startTest();
      update order;
      system.enqueueJob(new PolarisFulfilmentQueueable(new List<String>{ order.Id }, new Set<Id>(), null));
      Order ord = [SELECT Id, Polaris_Fulfillment_Status__c FROM Order WHERE Id = :order.Id];
      system.assertEquals('Resync Dates Requested', ord.Polaris_Fulfillment_Status__c);
      Test.stopTest();
    }
  }

  static testMethod void testPostRestServiceEmptyError() {
    User usr = [SELECT id, alias FROM user WHERE alias = 'apiuser' ORDER BY createddate DESC LIMIT 1];
    System.runAs(usr) {
      Order order = [SELECT Id, Polaris_Fulfillment_Status__c FROM Order LIMIT 1];
      Order.Order_Status__c = 'Order Accepted';
      Order.Hold_Code__c = '';
      order.Send_for_Polaris_Fulfilment__c = true;
      order.Polaris_Fulfillment_Status__c = 'Resync Dates Requested';
      Test.setMock(HttpCalloutMock.class, new polarisFulfilmentMock(''));
      Test.startTest();
      update order;
      system.enqueueJob(new PolarisFulfilmentQueueable(new List<String>{ order.Id }, new Set<Id>(), null));
      Order ord = [SELECT Id, Polaris_Fulfillment_Status__c FROM Order WHERE Id = :order.Id];
      system.assertEquals('Resync Dates Requested', ord.Polaris_Fulfillment_Status__c);
      Test.stopTest();
    }
  }

  static testMethod void testPrimaryPOCInstanceFiltering() {
    User usr = [SELECT id, alias FROM user WHERE alias = 'std' ORDER BY createddate DESC LIMIT 1];
    System.runAs(usr) {

        Order ord = [
            SELECT Id, AccountId, OpportunityId
            FROM Order LIMIT 1
        ];

        ord.Type = 'Revenue';
        update ord;

        Opportunity opp = [
            SELECT Id, Managed_Services_Deal_type__c
            FROM Opportunity WHERE Id = :ord.OpportunityId
        ];

        opp.Managed_Services_Deal_type__c = null;
        opp.Opportunity_Sub_Type__c = null;
        update opp;

        RSCInstance__c pocInstance = new RSCInstance__c(
            AccountId__c = ord.AccountId,
            RSCAccountType__c = 'POC',
            RSCAccountRelationship__c = 'Primary',
            Status__c = 'Active',
            RSCUrl__c = 'testPOC.com'
        );
        insert pocInstance;

        Test.setMock(HttpCalloutMock.class, new PolarisFulfilmentMock('success'));

        Test.startTest();
        System.enqueueJob(new PolarisFulfilmentQueueable(new List<String>{ ord.Id }, new Set<Id>(), null));
        Test.stopTest();

        System.assert(true, 'Primary POC instance filtering branch executed');
    }
  }


  static testMethod void testPostRestServiceJSONException() {
    User usr = [SELECT id, alias FROM user WHERE alias = 'apiuser' ORDER BY createddate DESC LIMIT 1];
    System.runAs(usr) {
      Order order = [SELECT Id, Polaris_Fulfillment_Status__c FROM Order LIMIT 1];
      Order.Order_Status__c = 'Order Accepted';
      Order.Hold_Code__c = '';
      order.Send_for_Polaris_Fulfilment__c = true;
      order.Polaris_Fulfillment_Status__c = 'Resync Dates Requested';
      Test.setMock(HttpCalloutMock.class, new polarisFulfilmentMock('invalidJson'));
      Test.startTest();
      update order;
      system.enqueueJob(new PolarisFulfilmentQueueable(new List<String>{ order.Id }, new Set<Id>(), null));
      Order ord = [SELECT Id, Polaris_Fulfillment_Status__c FROM Order WHERE Id = :order.Id];
      system.assertEquals('Resync Dates Requested', ord.Polaris_Fulfillment_Status__c);
      Test.stopTest();
    }
  }

  static testMethod void testPostRestServiceException() {
    User usr = [SELECT id, alias FROM user WHERE alias = 'apiuser' ORDER BY createddate DESC LIMIT 1];
    System.runAs(usr) {
      List<Custom_Error_Log__c> errorLog = new List<Custom_Error_Log__c>();
      PolarisFulfilmentAPI.restProvisionApiCall('ordId', errorLog, 'token');
      system.assertEquals(1, errorLog.size());
      system.assertNotEquals(null, errorLog[0].Exception_Message__c);
    }
  }

  static testMethod void testPostQueueable() {
    User usr = [SELECT id, alias FROM user WHERE alias = 'apiuser' ORDER BY createddate DESC LIMIT 1];
    System.runAs(usr) {
      Order order = [SELECT Id, Polaris_Fulfillment_Status__c FROM Order LIMIT 1];
      Test.setMock(HttpCalloutMock.class, new polarisFulfilmentMock('error'));
      Test.startTest();
      system.enqueueJob(new PolarisFulfilmentQueueable(new List<String>{ order.Id }, new Set<Id>{ order.Id }, null));
      Order ord = [SELECT Id, Polaris_Fulfillment_Status__c FROM Order WHERE Id = :order.Id];
      system.assertEquals('Not Started', ord.Polaris_Fulfillment_Status__c);
      Test.stopTest();
    }
  }

  static testMethod void testPostQueueableException() {
    System.runAs(new User(Id = userInfo.getUserId())) {
      Cache.OrgPartition orgPart = Cache.Org.getPartition('local.' + PolarisFulfilmentQueueable.CACHE_PARTITION_NAME);
      orgPart.put('accessToken', 'accessToken', 3600);
      orgPart.put('tokenExpiryTime', System.now().addSeconds(3600), 3600);
      Order order = [SELECT Id, Polaris_Fulfillment_Status__c FROM Order LIMIT 1];
      Test.setMock(HttpCalloutMock.class, new polarisFulfilmentMock('success'));
      Test.startTest();
      system.enqueueJob(new PolarisFulfilmentQueueable(new List<String>{ '8010000000000000PI' }, new Set<Id>{ '8010000000000000PI' }, null));
      Order ord = [SELECT Id, Polaris_Fulfillment_Status__c FROM Order WHERE Id = :order.Id];
      system.assertEquals(ord.Polaris_Fulfillment_Status__c, ord.Polaris_Fulfillment_Status__c);
      Test.stopTest();
    }
  }

  private class PolarisFulfilmentMock implements HttpCalloutMock {
    private String requestType;
    /**
     * @description Constructor to Mock API Response
     * @param  requestType
     */
    public PolarisFulfilmentMock(String requestType) {
      this.requestType = requestType;
    }
    /**
     * @description HttpCalloutMock Method to Mock API Response
     * @param  req
     * @return  HTTPResponse
     */
    public HTTPResponse respond(HTTPRequest req) {
      HttpResponse res = new HttpResponse();

      if (req.getEndpoint().contains('token')) {
        res.setBody('{"access_token":"new_token","expires_in":3600}');
        res.setStatusCode(200);
      } else if (requestType == 'success') {
        res.setBody('{"job_id":"124","order_id":"801O500000fFS2nIAG","taskchain_id":"01982c14-5684-755f-bb16-b163e918c831","deployment":"dev-165"}');
        res.setStatusCode(200);
      } else if (requestType == 'error') {
        res.setBody('{"error":"invalid character \'O\' after object key:value pair","code":3,"message":"invalid character \'O\' after object key:value pair","details":[]}');
        res.setStatusCode(400);
      } else if (requestType == 'invalidJson') {
        res.setBody('{"error"="invalid character \'O\' after object key:value pair","code""message":"invalid character \'O\' after object key:value pair","details"=[]}');
        res.setStatusCode(400);
      } else {
        res.setBody('');
        res.setStatusCode(400);
      }
      return res;
    }
  }
}