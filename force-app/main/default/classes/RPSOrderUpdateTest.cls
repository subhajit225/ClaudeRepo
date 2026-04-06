@isTest
public class RPSOrderUpdateTest {
 @testSetup 
 static void setupData() {  
        //EXCL-6
        FlowControll.AccountTrigger = false;
        FlowControll.opportunityTriggerHandler = false;       
        //create user
         insert new TriggerControl__c(name='Opportunity',DisableTrigger__c=false);
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User u=new user(alias = 'std', email='testuser@testclass.com',
            emailencodingkey='UTF-8', firstname='test', lastname='user', languagelocalekey='en_US',
            localesidkey='en_US', profileid = p.Id,
            timezonesidkey='America/Los_Angeles', username='testuser99@testclass.com');
        
        System.runAs(u) {
            
            //create account and contact to assign to opportunity
            account acct=new account(name='test account',AccountNumber='123456');
            insert acct;
            contact con=new contact(lastname='test contact',leadsource='web',
                                  email='testc@test.com',accountId=acct.id);
            insert con;
            acct.AdvocateHub__Referral_Source__c=con.id;
            update acct;
            //insert new opportunity
            Opportunity oppty = TestDataFactory.getOpportunity(acct);
            insert oppty;

        list<Product2> prodlist = new list<Product2>();
        Map<String, Object>  prodMap = new Map<String, Object> {
            'Name' => 'Pord A',
                'ProductCode' => 'ProductXYZ',
                'isActive' => true,
                'Family' => 'AIR',
                'Product_Type__c' => 'Appliance'
                };
                    Product2 pd = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap);  
        prodlist.add(pd);
        Map<String, Object>  prodMap2 = new Map<String, Object> {
            'Name' => 'Pord A',
                'ProductCode' => 'ProductXYZ',
                'isActive' => true,
                'Family' => 'AIR',
                'Product_Type__c' => 'GPS'
                };
                    Product2 pd2 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap2);  
        //prodlist.add(pd2);
        Map<String, Object>  prodMap3 = new Map<String, Object> {
            'Name' => 'Pord A',
                'ProductCode' => 'ProductXYZ',
                'isActive' => true,
                'Family' => 'AIR',
                'Product_Type__c' => 'RADAR'
                };
                    Product2 pd3 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap3);  
        //prodlist.add(pd3);
        insert prodlist;
        Id pricebookId = Test.getStandardPricebookId();
        Map<String, Object>  quoteMap = new Map<String, Object> {
            'SBQQ__Account__c' => acct.Id,
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
        oppty.Partner_Level_Of_Involvement__c = '4.Partner or joint initiated opportunity, partner brought substantial value in sales cycle and getting deal closed';
        oppty.SBQQ__PrimaryQuote__c = qt1.Id;
        oppty.Installation_Assigned_To__c ='FE Install    ';
        oppty.ForecastCategoryName = 'Best Case';
        update oppty;
        
        Order od = new Order();
        od.Name='testOrder1';
        od.Status = 'Draft';
        od.Order_Status__c='Pending';
        //od.BookingStatus__c='None';
        od.AccountId = acct.Id;
        od.OpportunityId = oppty.Id;
        od.EffectiveDate = Date.Today();
        od.ShippingStreet ='Test Street';
        od.ShippingCity ='Test City';
        od.ShippingState ='California';
        od.ShippingCountry ='United States';
        od.ShippingPostalcode ='94820';
        od.ship_To_Name__c = acct.id;
        od.Type = 'Revenue';
        od.Est_Ship_Date__c = system.today();
        od.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Revenue Order').getRecordTypeId();
        od.Pricebook2Id = pricebookId;
        //od.Hold_Code__c = 'Missing freight forwarder details';
        insert od;
        
    }   
    } 
    @isTest
    static void updateFieldsOnInsertTestMethod () {
      Order ord =[select id from order limit 1];
      Account acc =[Select id from account limit 1];
      List<Error_Logs__c> errLogs = new List<Error_Logs__c>();
      errLogs.add(new Error_Logs__c(Error_Type__c = 'Order Error',Related_Order__c=ord.id, Success__c=true, Type__c = 'Integration'));
      errLogs.add(new Error_Logs__c(Error_Type__c = 'Order Error',Related_Order__c=ord.id, Success__c=false, Type__c = 'Integration'));
      errLogs.add(new Error_Logs__c(Error_Type__c = 'Order Error', Account__c =acc.id, Success__c=false));
      errLogs.add(new Error_Logs__c(Error_Type__c = 'Order Error', Account__c =acc.id, Success__c=true));
      IntegrationLogMainTriggerHelper.updateFieldsOnInsert(errLogs);
  
  }
  @isTest
    static void updateScreeningStatusTest(){
        RestResponse res = new RestResponse();
        Order ord =[select id from order limit 1];
        String myJSON = '{\"Billto_EndUser_Screening_Id__c\" :\"1234-e\",\"Billto_EndUser_Screen_Status__c\":\"DENIED\",\"Billto_EndUser_Screen_StatusMessage__c\" :\"test failure\",\"id\":\"';
        myJSON+= +ord.id+'\"}';
        system.debug('MyJsn'+myJSON);
        RestRequest request = new RestRequest();
        string requrl = URL.getSalesforceBaseUrl().toExternalForm();
        request.requestUri = requrl +'/services/apexrest/UpdateOrder';
        request.httpMethod = 'Patch';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueof(myJSON);
        RestContext.request = request;
        RestContext.response = res;
        RPSOrderUpdate.updateScreeningStatus();
        test.starttest();
        ord.Billto_EndUser_Screening_Id__c = '1234-e';
        update ord;
        RPSOrderUpdate.updateScreeningStatus();
        delete ord;
        RPSOrderUpdate.updateScreeningStatus();
        test.stoptest();   
    }
    
}