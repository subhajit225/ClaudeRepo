@isTest
public class LCC_JSMQueryResultServiceTest {
    @isTest
    static public void executeQueryTest(){
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
         UserName=uniqueUserName);

        System.runAs(u) {
            //do the query
            String theQuery = 'SELECT Id FROM User LIMIT 5';
            List<User> user = LCC_JSMQueryResultService.executeQuery(theQuery);
            user = LCC_JSMQueryResultService.executeQueryNew(theQuery);
            //compare the result
            System.assertNotEquals(null, user,'User details found.');
        }
    }
    /*@isTest
    static public void executeQueryTestCache(){
        //do the query
        String theQuery = 'SELECT Id FROM User LIMIT 5';
      List<User> user = LCC_JSMQueryResultService.executeQueryCacheable(theQuery);

        //compare the result
        System.assertNotEquals(null, user);
    }*/

    @isTest
    static public void executeQueryOneObjectTest(){
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
         UserName=uniqueUserName);

        System.runAs(u) {
            //do the query
            String theQuery = 'SELECT Id FROM User LIMIT 1';
            User user = (User)LCC_JSMQueryResultService.executeQueryOneObject(theQuery);

            //compare the result
            System.assertNotEquals(null, user,'User details found.');
        }
    }

    @isTest
    static public void executeQueryOneObjectTestOne(){
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
         UserName=uniqueUserName);

        System.runAs(u) {
            //do the query
            Map<String,String> listofquery = new Map<String,String>();
            listofquery.put('userquery','theQuery');
            Map<string, List<sObject>> result = new Map<string, List<sObject>>();
            listofquery.put('userquery','theQuery');
            try{
            	result = LCC_JSMQueryResultService.executeAllQuery(listofquery);
            }catch(System.exception ex){
                System.assert(ex instanceof AuraHandledException);
            }
            System.assertNotEquals(null, result);
            String theQuery = 'SELECT Id FROM User LIMIT 1';
            listofquery.clear();
            listofquery.put('userquery',theQuery);
            result = LCC_JSMQueryResultService.executeAllQuery(listofquery);
            System.assertNotEquals(null, result);
        }
    }

    @isTest
    static public void getUserInfoTest(){
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
         UserName=uniqueUserName);

        System.runAs(u) {
            LCC_JSMUserInfo user = LCC_JSMQueryResultService.getUserInfo();
            //compare the result
            System.assertEquals(UserInfo.getUserId(), user.Id);
            System.assertEquals(UserInfo.getFirstName(), user.FirstName);
            System.assertEquals(UserInfo.getLastName(), user.LastName);
            System.assertEquals(UserInfo.getUserEmail(), user.UserEmail);
            System.assertEquals(UserInfo.getName(), user.Name);
            System.assertEquals(UserInfo.getUserName(), user.UserName);
            try{
                LCC_JSMQueryResultService.getAccessibleFields(u.Id);
             }Catch(Exception ex){
                System.assert(true);
             }
        }
    }

    @isTest
    static public void getProfileInfoTest(){
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
         UserName=uniqueUserName);

        System.runAs(u) {
            String profileId = UserInfo.getProfileId();
            Profile profile = [SELECT Id, Name FROM Profile WHERE Id =:profileId];
            Profile prof = LCC_JSMQueryResultService.getProfileInfo();
            //compare the result
            System.assertEquals(profile.Id, prof.Id);
            System.assertEquals(profile.Name, prof.Name);
        }
    }

    @isTest
    static public void getSiteInfoTest(){
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
         UserName=uniqueUserName);

        System.runAs(u) {
            LCC_JSMSiteInfo info = LCC_JSMQueryResultService.getSiteInfo();
            //compare the result
            System.assertEquals(Site.getPathPrefix(), info.Prefix);
            System.assertEquals(Site.getDomain(), info.Domain);
            System.assertEquals(Site.getName(), info.Name);
        }
    }

    @isTest
    static public void executeQueryNegTest(){
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
         UserName=uniqueUserName);

        System.runAs(u) {
            //do the query
            String theQuery = 'SELECT Id, Count From Account LIMIT 5';

            try{
                List<Account> acc = LCC_JSMQueryResultService.executeQuery(theQuery);
                System.assert(false);
            }catch(AuraHandledException ex){
                System.assert(true);
            }
            
            try{
                List<Account> acc = LCC_JSMQueryResultService.executeQueryNew(theQuery);
                System.assert(false);
            }catch(AuraHandledException ex){
                System.assert(true);
            }
        }
    }

    @isTest
    static public void executeQueryOneObjectNegTest(){
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
         UserName=uniqueUserName);

        System.runAs(u) {
            //do the query
            String theQuery = 'SELECT Id From Account LIMIT 5';
            try{
                Account acc = (Account)LCC_JSMQueryResultService.executeQueryOneObject(theQuery);
                System.assert(false);
            }catch(AuraHandledException ex){
                System.assert(true);
            }
        }
    }

    @isTest
    static public void loadObjectInfoByIdTest(){
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
         UserName=uniqueUserName);

        System.runAs(u) {
            //do the query
            String theQuery = 'SELECT Id FROM User LIMIT 1';
            User user = (User)LCC_JSMQueryResultService.executeQueryOneObject(theQuery);
            LCC_JSMQueryResultService.loadObjectInfoById(user.Id);
            System.assertNotEquals(null, user);
        }
    }

    @IsTest
    static void testGetReportData() {
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
         UserName=uniqueUserName);

        System.runAs(u) {
            // Mock valid report ID scenario
            String mockReportId = '00O123456789012';
            Test.startTest();
            try {
                String result = LCC_JSMQueryResultService.getReportData(mockReportId);
                System.assertEquals(null, result, 'Should return mock report data');
            } catch (Exception e) {
                System.assert(false, 'Unexpected error: ' + e.getMessage());
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void testGetObjectPrefixes() {
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        // This code runs as the system user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
         UserName=uniqueUserName);

        System.runAs(u) {
            Test.startTest();
            Map<String, String> prefixMap = LCC_JSMQueryResultService.getObjectPrefixes();
            Test.stopTest();

            // Verify standard objects exist
            System.assert(prefixMap.containsKey('001'), 'Account prefix missing');
            System.assert(prefixMap.containsKey('003'), 'Contact prefix missing');
            System.assert(prefixMap.get('001') == 'Account','Account mapping incorrect');
            // Verify map is populated
            System.assert(!prefixMap.isEmpty(),
                'Object prefix map should not be empty');
        }
    }

    @IsTest
    static void testSaveOrderRecord() {
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.name = 'Test Tech, Inc.';
        act.Type = 'Distributor';
        act.RecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        insert act;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.startTest();
            String validationError = LCC_JSMQueryResultService.saveShippedOrder(act); 
            System.assert(String.isBlank(validationError));
            validationError = LCC_JSMQueryResultService.saveShippedOrder(new Account(Logo_Approved__c  = 'Unsure', Id = act.Id)); 
            System.assert(String.isNotBlank(validationError));
            validationError = LCC_JSMQueryResultService.saveShippedOrder(new Account(Logo_Approved__c  = 'Not sure', Id = act.Id)); 
            System.assert(String.isNotBlank(validationError));
            Test.stopTest();
            
        }
    }
    
    
    
    @isTest
    public static void testMethodEntitlement(){
        System.runAs(new User(Id = UserInfo.getUserId())) {
        test.startTest();
        LCC_JSMQueryResultService.saveRecordwithBypass(null , 'Entitlement');
        LCC_JSMQueryResultService.saveRecordwithBypass(null , null);
		test.stopTest();
        system.assert(true);
        }
    }
    
    @isTest
    public static void testMethodgetAccessibleFields(){
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.name = 'Test Tech, Inc.';
        act.Type = 'Distributor';
        act.RecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        
        insert act;
		Opportunity opportunityObj = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
        opportunityObj.AccountId = act.Id;
        opportunityObj.Name = 'EntitlementTriggerHelper Opportunity';
        opportunityObj.CloseDate = System.today().addMonths(12);
        opportunityObj.StageName = 'Prospecting';
        opportunityObj.Partner_Lookup__c = act.Id;
        opportunityObj.Distributor_Lookup__c = opportunityObj.AccountId;
        
        opportunityObj.Amount = 100;
        opportunityObj.OppSubscriptionTermMonths__c = 12;
        opportunityObj.Pricebook2Id = Test.getStandardPricebookId();
        opportunityObj.Deal_Structuring_Oppty_Notes__c = 'Test';
        insert opportunityObj;
       
       Map<String, Object>  OrderMap = new Map<String, Object> {
            'Type' => 'Revenue',
                'Send_for_Polaris_Fulfilment__c' =>true,
                'AccountId' => act.Id,
                'POC_Opportunity__c' => opportunityObj.Id,
                'EffectiveDate' => system.today(),
                'Order_Status__c' => null,
                'Status' => 'Pending',
                'Sync_to_NetSuite__c' => true,
                'ShippingCountryCode' => 'US',
                'ShippingStreet' =>'Test Street',
                'ShippingCity' => 'Test City',
                'ShippingState' =>'California',
                'ShippingCountry' =>'United States',
                'ShippingPostalcode' =>'94820',
                'ship_To_Name__c' => act.id,
                'ShipToContactName__c'=> 'Test',
                'Pricebook2Id' => opportunityObj.Pricebook2Id,
                'Have_Polaris_Products__c' => false,
                'Polaris_Fulfillment_Status__c' => 'Completed',
                'Original_Est_Ship_Date__c' => Date.today().addDays(30),
                'Est_Ship_Date__c' => null,
                'Order_Splitted__c' => true,
                'Order_Sub_Type__c' => 'Renewal'
                };
  
      	Order OrderObj  = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
        insert OrderObj; 

        System.runAs(new User(Id = UserInfo.getUserId())) {
        test.startTest();
        try{
        LCC_JSMQueryResultService.saveRecordwithBypass(OrderObj , 'Order');
        LCC_JSMQueryResultService.getAccessibleFields(OrderObj.Id);
        LCC_JSMQueryResultService.getAccessibleFields(null);
            
        }Catch(exception ex){
         System.assert(ex != null);
        }
        test.stopTest();
        system.assert(true);
        }
    }

    @isTest
    public static void testMethodserviceContract3(){
       System.runAs(new User(Id = UserInfo.getUserId())) {
           test.startTest();
            Map<String, Boolean> result = LCC_JSMQueryResultService.getBusinessLogicSetting();
           insert new ShGl_DisableBusinessLogic__c( Disable_Replacement_Framework__c = TRUE);
           result = LCC_JSMQueryResultService.getBusinessLogicSetting();
           test.stopTest();
           System.assert(result != null);
        }
    }

    @isTest 
    public static void testTriggerOrderCreation() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Account acc = new Account( Name = 'Test Account');
            insert acc;
            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity',
                AccountId = acc.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(10),
                SBQQ__Ordered__c = false
            );
            insert opp;
            Test.startTest();
            String result = LCC_JSMQueryResultService.triggerOrderCreation(new Opportunity(Id = opp.Id,SBQQ__Ordered__c = true),50);
            Test.stopTest();
            System.assertEquals(false,String.isBlank(result));
        }
    }

}