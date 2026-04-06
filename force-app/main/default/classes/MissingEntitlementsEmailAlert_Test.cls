@isTest
private class MissingEntitlementsEmailAlert_Test {
  
    /**
   * @description setup
   */
    @testSetup 
    public static void setup() { 
        
    String uniqueUserName1 = 'MissingEntitlementsEmailAlertTest' + DateTime.now().getTime() + '@testclass.com';
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
      username = uniqueUserName1
    );
    System.runAs(usr) {
        TriggerControl__c custsetting = new TriggerControl__c();
        custsetting.Name = 'Opportunity';
        //custsetting.Disable_Trigger__c =
        custsetting.DisableTrigger__c = true;
        insert custsetting; 
        
        TriggerControl__c orderTrigger = new TriggerControl__c();
        orderTrigger.Name = 'Order';
        //custsetting.Disable_Trigger__c =
        orderTrigger.DisableTrigger__c = true;
        insert orderTrigger;
        
        TriggerControl__c PortalUserCreation = new TriggerControl__c();
        PortalUserCreation.Name = 'PortalUserCreation';
        // PortalUserCreation.DisableTrigger__c = true;
        insert PortalUserCreation; 
        
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance(); 
        disableFuncCS.Disable_Order_Old_Trigger__c = false;
        insert disableFuncCS;
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Validation_Rules__c = True,
                                                                            Disable_SBQQ_Quote_Triggers__c = True,
                                                                            Disable_SBQQ_QuoteLine_Validation_Rules__c = True,
                                                                            Disable_SBQQ_QuoteLine_Triggers__c = True,
                                                                            Disable_Opportunity_Validation_Rules__c = True,
                                                                            Disable_Opportunity_Triggers__c = True,
                                                                            Disable_Account_Validation_Rules__c = True,
                                                                            Disable_Order_Validation_Rules__c = true);
        insert cdf;

        StateNameCode__c custset = new StateNameCode__c();
        custset.Name = 'California';
        custset.Code__c = 'US-CA';
        insert custset;
        
        Date closeDt = System.Today()+30;
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        
        Account acct = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert acct;

        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => acct.Id,
            'Email'  =>'leademail@hidden.com'
        };
        Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);        
        insert cnt1;

        Map<String, Schema.RecordTypeInfo> AcRecTypeInfo = Schema.SObjectType.Account.getRecordTypeInfosByName();
	Account partnerDistriAccount = new Account(Name = 'Promark Technology, Inc.', Type = 'Distributor', RecordTypeId = AcRecTypeInfo.get('Partner/Distributor').getRecordTypeId());
        insert partnerDistriAccount;
        
        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => acct.Id,
            'Initial_Contacts_Name__c' => cnt1.Id,
            'Primary_Competitor__c' => 'Other',
            'Other_Primary_Competitor__c' => 'Other',

            'StageName' => '1 Discovery',
            'Other_Competitor_Field__c' => 'Other',
            'ForecastCategoryName' => 'Best Case',
            'SE_Forecast_Category__c' =>'Commit',
            'Partner_Lookup__c' => partnerDistriAccount.Id,
            'Distributor_Lookup__c' => partnerDistriAccount.Id
        };
        Opportunity oppty = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        insert oppty;
        
        list<Product2> prodlist = new list<Product2>();
        Map<String, Object>  prodMap = new Map<String, Object> {
            'Name' => 'Pord A',
                'ProductCode' => 'ProductXYZ',
                'isActive' => true,
                'Family' => 'POLARIS',
                'Product_Type__c' => 'Appliance',
                'SBQQSC__EntitlementConversion__c'=> 'One per quote line'
                };
                    Product2 pd = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap);  
        prodlist.add(pd);
        Map<String, Object>  prodMap2 = new Map<String, Object> {
            'Name' => 'Pord A',
                'ProductCode' => 'ProductXYZ',
                'isActive' => true,
                'Family' => 'POLARIS',
                'Product_Type__c' => 'GPS'
                };
                    Product2 pd2 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap2);  
        //prodlist.add(pd2);
        Map<String, Object>  prodMap3 = new Map<String, Object> {
            'Name' => 'Pord A',
                'ProductCode' => 'ProductXYZ',
                'isActive' => true,
                'Family' => 'POLARIS',
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
        oppty.Partner_Level_Of_Involvement__c = '1.Rubrik initiated, Partner was fulfillment only';
        oppty.SBQQ__PrimaryQuote__c = qt1.Id;
        update oppty;
        
  
        Order od = new Order();
        od.Status = 'Draft';
        od.AccountId = acct.Id;
        od.OpportunityId = oppty.Id;
        od.EffectiveDate = Date.Today();
        od.ShippingStreet ='Test Street';
        od.ShippingCity ='Test City';
        od.ShippingCountry ='United States';
        od.ShippingState ='California';
        od.ShippingPostalcode ='94820';
        //od.ship_To_Name__c = acct.id;
        od.Type = 'Revenue';
        od.Est_Ship_Date__c = system.today();
        //od.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order').getRecordTypeId();
        od.Pricebook2Id = pricebookId;
        insert od;
        
        Order order2 = od.clone();
        order2.Order_Accepted_Timestamp__c = System.today().addDays(-1);
        order2.Type = 'Revenue';
        order2.Order_Status__c = 'Shipped';
        insert order2;
        
        //Added By Amit
       /* Account acct = new Account(
            Name = 'Test Account',
            Phone = '123-456-7890',
            AccountNumber = 'Test',
            BillingStreet = '123 street',
            BillingCity = 'Santa Clara',
            BillingState = 'California',
            BillingPostalCode = '95050',
            BillingCountry = 'United States'
        );
        insert acct;*/
        
        //Generate the Opportunity
        /*Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => acct.Id,
                //'Initial_Contacts_Name__c' => cnt1.Id,
                'Primary_Competitor__c' => 'Other',
                'Other_Primary_Competitor__c' => 'Other',
                'Other_Competitor_Field__c' => 'Other',
                'Lost_To_Won_Against__c' => 'Other',
                'Polaris_Region__c' => 'US'
                };*/
        
         List<Opportunity> opptyList = (List<Opportunity>) ShGl_TestFactory.createSObjectList(new Opportunity(), 1, oppMap);
        //insert opptyList;

        List<Product2> prodslist = new List<Product2> {
            //startup product
            new Product2(Name = 'X-0001-01',
                ProductCode = 'X-0001-01',
                Category__c = 'Platform',
                Family = 'RBK-R300',
                Support_Type__c = 'PREM',
                Appliance_Model__c = 'R348',
                Appliance_Model_HW__c = 'R348',
                Create_Asset_Entitlement__c = true,
                Asset_Priority__c = 0,
                Product_Subtype__c = 'Start Up',
                IsActive = true
            ),
            //non-startup product
            new Product2(Name = 'X-0001-01',
                ProductCode = 'X-0001-01',
                Category__c = 'Platform',
                Family = 'RBK-R300',
                Support_Type__c = 'PREM',
                Appliance_Model__c = 'R348',
                Appliance_Model_HW__c = 'R348',
                Create_Asset_Entitlement__c = true,
                Asset_Priority__c = 0,
                IsActive = true
            )
        };
        insert prodslist;
        
        
       
        /*ßßId pricebookId = Test.getStandardPricebookId();*/
      
        
        List<Asset> assets = new list<Asset> {
            new Asset(Name = 'SN123', SerialNumber = 'SN123', Serial_Number__c = 'SN123', Accountid = acct.Id,Product2id = prodslist[0].id),
            new Asset(Name = 'SN234', SerialNumber = 'SN234', Serial_Number__c = 'SN234',  Accountid = acct.Id,Product2id = prodslist[0].id),
            new Asset(Name = 'SN356', SerialNumber = 'SN356', Serial_Number__c = 'SN356',  Accountid = acct.Id,Product2id = prodslist[1].id)
        };
        insert assets;
        
        Error_Logs__c errorLogs = new Error_Logs__c();
        errorLogs.Error_Type__c = 'AssetSetEligibleFreeHWBatch - Error in the batch while setting Eligible for Free HW field';
        errorLogs.Error_Message__c = 'Test Message';
        errorLogs.RecordId__c = assets[0].Id;
        errorLogs.Object__c = 'Asset';
        errorLogs.CreatedDate = System.today();
        insert errorLogs;
        System.debug(LoggingLevel.debug,'errorLogs :::>'+errorLogs);
        
         List<Cluster__c> clusters = new List<Cluster__c> {
            new Cluster__c(UUID__c = 'Test1', Name = 'Test1', Location__c = 'Alamo', MSP_Consumption__c = true),
            new Cluster__c(UUID__c = 'Test2', Name = 'Test2', Location__c = 'Albany'),
            new Cluster__c(UUID__c = 'Test3', Name = 'Test3', Location__c = 'Alhambra')
        };
        insert clusters;
        
         List<Node__c> Nodes = new List<Node__c> {
            new Node__c(Name = 'RVMHM2', Serial_Number__c = 'RVMHM2',cluster__c = clusters[0].id,asset__c=assets[0].id),
            new Node__c(Name = 'RVMHM22', Serial_Number__c = 'RVMHM22',cluster__c = clusters[1].id,asset__c=assets[1].id),
            new Node__c(Name = 'RVMHM23', Serial_Number__c = 'RVMHM23',cluster__c = clusters[2].id,asset__c=assets[2].id)
         };
 
        insert Nodes;
        
        //Create your pricebook entry
        PricebookEntry pbEntry = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prodlist[0].Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbEntry;
        
        od.Pricebook2Id = pricebookId;
        od.Polaris_Fulfillment_Status__c = 'Not Started';
        update od;
        OrderItem oritem = new OrderItem(OrderId=od.Id, 
            Quantity=10, 
            PricebookEntryId=pbEntry.Id, 
            UnitPrice = 10, 
            SerialNumber__c = 'AA162403440008',
            Support_Start_Date__c = Date.today(),
            Support_End_Date__c = Date.today().addYears(1)
            );
        insert oritem;
       
    }   
    }
    
   /**
   * @description test method to testMissingEntitlementEmailAlert
   */
  @isTest
  private static void testMissingEntitlementEmailAlert() {
    System.runAs(new User(Id = UserInfo.getUserId())) {
    Test.startTest();
    List<Order> lstOrder = [Select Id, Order_Status__c,Actual_Order_Ship_Date__c,Polaris_Fulfillment_Status__c From Order];
    List<OrderItem> lstOrderItem = [Select Id From OrderItem];
    List<Asset> lstAssets = [Select Id From Asset];
    List<Cluster__c> lstCuster = [Select Id, MSP_Consumption__c,Location__c,UUID__c  From Cluster__c];
    List<Node__c> lstNodes = [Select Id, Name, Serial_Number__c, cluster__c, asset__c From Node__c];
    lstOrder[0].Order_Status__c = 'Shipped';
    lstOrder[0].Actual_Order_Ship_Date__c = Date.today().addDays(-1);
    lstOrder[0].Polaris_Fulfillment_Status__c = 'Completed';
    update lstOrder;
    System.schedule('MissingEntitlementsEmailAlert', '0 0 2 * * ?', new MissingEntitlementsEmailAlert());
    MissingEntitlementsEmailAlert.sendEmail();
    MissingEntitlementsEmailAlert.sendAssetSetEligibleFreeHWBatchFailureReport();
    Test.stopTest();
    system.assertEquals(lstOrder[0].Polaris_Fulfillment_Status__c, 'Completed');
    }
  }
  /**
   * @description test method to testMissingEntitlementEmailAlert
   */
  @isTest
    private static void testMissingEntitlementEmailAlertWoOI(){
        System.runAs(new User(Id = UserInfo.getUserId())) {
        Test.startTest();
        List<Order> lstOrder = [Select Id, Order_Status__c,Actual_Order_Ship_Date__c,Polaris_Fulfillment_Status__c From Order];
        List<OrderItem> lstOrderItem = [Select Id From OrderItem];
        delete lstOrderItem;
        System.schedule('MissingEntitlementsEmailAlert', '0 0 2 * * ?', new MissingEntitlementsEmailAlert());
        Test.stopTest();
        system.assertEquals(lstOrder.size(), 2);
        } 
    }
}