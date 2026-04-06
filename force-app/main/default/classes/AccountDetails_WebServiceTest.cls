@isTest
public class AccountDetails_WebServiceTest {
  @testSetup
  static void setup() {
    String uniqueUserName = 'TestUser1' + DateTime.now().getTime() + '@rbk.com';
    Profile p = [SELECT Id FROM Profile WHERE Name = 'API Integration User'];
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
    Account objAccount = new Account();
    Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
    objAccount.Name = 'Test Account';
    objAccount.RecordTypeId = recordTypeId;
    insert objAccount;
    Opportunity oppr = new Opportunity(
      Name = 'test Opportunity',
      AccountId = objAccount.id,
      StageName = '1 Discovery',
      CloseDate = system.Today(),
      ForecastCategoryName = 'Best Case',
      Business_Unit__c = 'Rubrik',
      Installation_Assigned_To__c = 'FE Install',
      Partner_Lookup__c = objAccount.id,
      Distributor_Lookup__c = objAccount.id
    );
    insert oppr;
    Product2 pd = new Product2(Name = 'Pord B', ProductCode = 'Product123XYZ', isActive = true, PDM_Feature_Enabled__c = false, Bundle_Features__c = 'App Flows;OnPrem NoSQL;OnPrem CDM;OnPrem UCL');
    pd.IsActive = true;
    insert pd;
    Product2 pd2 = new Product2(Name = 'Pord Bv1', ProductCode = 'Product123XYZ', isActive = true, PDM_Feature_Enabled__c = true, Bundle_Features__c = 'App Flows;OnPrem NoSQL;OnPrem CDM;OnPrem UCL');
    pd2.IsActive = true;
    insert pd2;

    System.runAs(usr) {
      Product_Feature__c pfObj = new Product_Feature__c();
      pfObj.Value__c = '2';
      pfObj.Unit__c = 'BETB';
      pfObj.Product_Name__c = pd2.Id;
      pfObj.Product_Code__c = 'Pord Bv1';
      pfObj.Status__c = 'ACTIVE';
      pfObj.Feature__c = 'APP FLOWS';
      pfObj.Feature_start_date__c = system.Today();

      insert pfObj;
    }
    Id standardPriceBookId = Test.getStandardPricebookId();
    PriceBook2 pb1 = new Pricebook2(Name = 'Test PriceBook', Description = 'Price Book 2009 Products 1', IsActive = true);
    insert pb1;

    PricebookEntry pbestandard = new PricebookEntry(Pricebook2Id = standardPriceBookId, Product2Id = pd.Id, UnitPrice = 99, isActive = true);
    PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pb1.id, Product2Id = pd.Id, UnitPrice = 99, isActive = true);
    insert new List<PricebookEntry>{ pbestandard, pbe };
    Asset asst = new Asset(Name = 'Test1234567Asset', SerialNumber = 'Test1234567Asset', Serial_Number__c = 'Test1234567Asset', Product2ID = pd.Id, Accountid = objAccount.Id);
    insert asst;
    Order ordr = new Order(
      Type = 'Revenue',
      AccountId = objAccount.Id,
      OpportunityId = oppr.Id,
      ShippingStreet = 'Test Street',
      ShippingCity = 'Test City',
      ShippingState = null,
      ShippingCountry = 'Austria',
      ShippingPostalcode = '94820',
      EffectiveDate = system.Today(),
      Status = 'Pending'
    );
    insert ordr;
    ordr.Pricebook2Id = pb1.Id;
    update ordr;
    OrderItem oli1 = new OrderItem(
      OrderId = ordr.Id,
      Quantity = 5,
      PricebookEntryId = pbe.Id,
      UnitPrice = pbe.UnitPrice,
      SerialNumber__c = 'Test1234567Asset2',
      Support_End_Date__c = System.Today().addYears(1),
      Support_Start_Date__c = System.Today()
    );
    insert oli1;
    TriggerControl__c tc = new TriggerControl__c();
    tc.Name = 'Entitlement';
    tc.DisableTrigger__c = true;
    insert tc;
    triggerControl.stopEntitlementTrigger = true;
    Entitlement ent1 = new Entitlement(
      Name = 'Testing',
      AccountId = objAccount.Id,
      StartDate = Date.valueof(System.now().addDays(-2)),
      EndDate = Date.valueof(System.now().addYears(2)),
      AssetId = asst.Id,
      Product__c = pd.Id,
      Order_Service_Item__c = oli1.id
    );
    insert ent1;
    Entitlement ent2 = new Entitlement(
      Name = 'Testingv1',
      AccountId = objAccount.Id,
      StartDate = Date.valueof(System.now().addDays(-2)),
      EndDate = Date.valueof(System.now().addYears(2)),
      AssetId = asst.Id,
      Product__c = pd2.Id,
      Order_Service_Item__c = oli1.id
    );
    insert ent2;
  }
  @isTest
  static void testGetRequest() {
    Test.startTest();
    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();
    req.requestURI = '/services/apexrest/getAccounts'; //Request URL
    req.httpMethod = 'GET';
    req.addHeader('Content-Type', 'application/json');
    req.addHeader('Accept', 'application/json');
    req.addHeader('getdata', 'latestFeature');
    req.addHeader('bundlefeature', 'App Flows,Cloud Native Protection,Polaris Radar,Sonar,Hybrid RCDM,Cloud Cluster ES,Kubernetes,NoSQL,Active Directory');
    RestContext.request = req;
    RestContext.response = res;
    AccountDetails_WebService.getAccountDetails();
    system.assert(res != null);
    Test.stopTest();
  }
  @isTest
  static void testGetRequest2() {
    Test.startTest();
    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();
    req.requestURI = '/services/apexrest/getAccounts';
    req.httpMethod = 'GET';
    req.addHeader('Content-Type', 'application/json');
    req.addHeader('Accept', 'application/json');
    req.addHeader('getdata', 'latestFeature');
    req.addHeader('productname', 'Pord B');
    RestContext.request = req;
    RestContext.response = res;
    AccountDetails_WebService.getAccountDetails();
    system.assert(res != null);
    Test.stopTest();
  }
  @isTest
  static void testGetRequest3() {
    Test.startTest();
    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();
    req.requestURI = '/services/apexrest/getAccounts';
    req.httpMethod = 'GET';
    req.addHeader('Content-Type', 'application/json');
    req.addHeader('Accept', 'application/json');
    req.addHeader('getdata', 'latestFeatures');
    req.addHeader('bundlefeature', 'App Flows,Cloud Cluster ES,Kubernetes,NoSQL,Active Directory');
    RestContext.request = req;
    RestContext.response = res;
    AccountDetails_WebService.getAccountDetails();
    system.assert(res != null);
    Test.stopTest();
  }
  @isTest
  static void testGetRequest4() {
    Test.startTest();
    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();
    req.requestURI = '/services/apexrest/getAccounts'; //Request URL
    req.httpMethod = 'GET';
    req.addHeader('Content-Type', 'application/json');
    req.addHeader('Accept', 'application/json');
    req.addHeader('getdata', 'latestFeature');
    req.addHeader('bundlefeature', 'App Flows,Cloud Native Protection,Polaris Radar,Sonar,Hybrid RCDM,Cloud Cluster ES,Kubernetes,NoSQL,Active Directory');
    RestContext.request = req;
    RestContext.response = res;
    AccountDetails_WebService.getAccountDetails();
    system.assert(res != null);
    Test.stopTest();
  }

  @isTest
  static void testGetRequestHeader() {
    Test.startTest();
    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();
    req.requestURI = '/services/apexrest/getAccounts'; //Request URL
    req.httpMethod = 'GET';
    req.addHeader('Content-Type', 'application/json');
    req.addHeader('Accept', 'application/json');
    req.addHeader('bundlefeature', 'App Flows,Cloud Native Protection,Polaris Radar,Sonar,Hybrid RCDM,Cloud Cluster ES,Kubernetes,NoSQL,Active Directory');
    RestContext.request = req;
    RestContext.response = res;
    AccountDetails_WebService.getAccountDetails();
    system.assert(res != null);
    Test.stopTest();
  }
  @isTest
  static void testGetRequestHeader2() {
    Test.startTest();
    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();
    req.requestURI = '/services/apexrest/getAccounts';
    req.httpMethod = 'GET';
    req.addHeader('Content-Type', 'application/json');
    req.addHeader('Accept', 'application/json');
    req.addHeader('getdata', 'latestFeature');
    RestContext.request = req;
    RestContext.response = res;
    AccountDetails_WebService.getAccountDetails();
    system.assert(res != null);
    Test.stopTest();
  }
}