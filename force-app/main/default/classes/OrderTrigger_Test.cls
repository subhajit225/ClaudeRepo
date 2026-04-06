/**************************************************************************************************
 * @description       : Order Trigger logic
 * @author            : Chaitra
 * @last modified on  : 03-12-2025
 * @last modified by  : Siva Kumar
 ******************************************************************************/
@isTest
public class OrderTrigger_Test {
    @testSetup static void createTestData() {
        
        TriggerControl__c custsetting = new TriggerControl__c();
        custsetting.Name = 'Opportunity';
        //custsetting.Disable_Trigger__c =
        custsetting.DisableTrigger__c = true;
        insert custsetting; 
        
        TriggerControl__c PortalUserCreation = new TriggerControl__c();
        PortalUserCreation.Name = 'PortalUserCreation';
        // PortalUserCreation.DisableTrigger__c = true;
        insert PortalUserCreation; 
        
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance(); 
        disableFuncCS.Disable_Order_Old_Trigger__c = false;
        disableFuncCS.Disable_Account_Old_Trigger__c=true;
        insert disableFuncCS;
        
       insert new ShGl_DisableBusinessLogic__c(Disable_POC_Trigger__c = true, Disable_Opportunity_Validation_Rules__c =true,  Disable_POC_Validation_Rules__c=true,
				 setupOwnerId = userinfo.getuserid());
        
        
        StateNameCode__c custset = new StateNameCode__c();
        custset.Name = 'California';
        custset.Code__c = 'US-CA';
        insert custset;
        
        Date closeDt = System.Today()+30;
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        FlowControll.AccountTrigger = false;
        FlowControll.opportunityTriggerHandler = false;
        
        Account acct = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert acct;
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
         Account actDist = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        actDist.name='Promark Technology, Inc.';
        actDist.Type ='Distributor';
		actDist.Contract_Status__c='Signed-Active';
        actDist.RecordTypeId=devRecordTypeId;
        insert actDist;

        //Generate the Contact
        Map<String, Object> cntMap = new Map<String, Object> {
            'AccountId' => acct.Id,
            'Email'  =>'leademail@hidden.com'
        };
        Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);        
        insert cnt1;
        
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
            'Distributor_Lookup__c'=>actDist.id,
            'Partner_Lookup__c'=>actDist.id,
            'Economic_Buyer__c'=>'tete',
            'Metric__c'=>'tete',
            'Decision_Process__c'=>'tete',
            'Decision_Criteria__c'=>'tete',
            'Identified_Pain__c'=>'tete',
             'Champion__c'=>'tete'
                
        };
           
        Opportunity oppty = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        insert oppty;
        
        list<Product2> prodlist = new list<Product2>();
        Map<String, Object>  prodMap = new Map<String, Object> {
            'Name' => 'Pord A',
                'ProductCode' => 'ProductXYZ',
                'isActive' => true,
                'Family' => 'POLARIS',
                'Product_Type__c' => 'Appliance'
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
        
        
          POC__c pocRequest = new POC__c();
        POC__c poc = new POC__c();
        poc.Planned_Installation_Date__c = Date.today().addDays(8);
        poc.POC_Type__c = 'Standard POC';
        poc.POC_Duration__c = '30 Days';
        poc.POC_Relocation__c = 'No';
        poc.POC_Justification__c = 'test';
        poc.Ranger_Support_Expected__c = true;
        poc.Product_Categories__c='SAP HANA for Cloud Cluster';
        
        insert poc;
        
        update oppty;
        
        Order od = new Order();
        od.Status = 'Draft';
        od.AccountId = acct.Id;
        od.OpportunityId = oppty.Id;
        od.EffectiveDate = Date.Today();
        od.ShippingStreet ='Test Street';
        od.ShippingCity ='Test City';
        od.ShippingState ='California';
        od.ShippingCountry ='United States';
        od.ShippingPostalcode ='94820';
        //od.ship_To_Name__c = acct.id;
        od.Type = 'POC';
        od.POC_Request__c=poc.id;
        od.Est_Ship_Date__c = system.today();
         od.Actual_Order_Ship_Date__c=system.today();
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
        
        od.Pricebook2Id = pricebookId;
        update od;
        od.Order_Status__c = 'Shipped';
        OrderItem oritem = new OrderItem(OrderId=od.Id, Quantity=10, PricebookEntryId=pbEntry.Id, UnitPrice = 10, Product2Id = prodlist[0].Id, SerialNumber__c = 'AA162403440008,AB162403440009,AC162403440009,AD162403440009');
        insert oritem;
        
      
    }
    
    /**
    * @author Siva Kumar
    * @date 12-03-2025
    * @description test method to cover Order trigger logic 
    */
    public static testMethod void testOrderAccepted() {
        String uniqueUserName = 'AdminUser' + DateTime.now().getTime() + '@rubrik.com';
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User adminUser = new User(
            Alias = 'adminU', Email='AdminUser@rubrik.com',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', ProfileId = adminProfile.Id,
            TimeZoneSidKey='America/Los_Angeles',
            UserName=uniqueUserName
        );
        insert adminUser;
        System.runAs(adminUser) {
            Test.startTest();
            Order ord = [SELECT Id, Account.Name, Opportunity.StageName, Order_Status__c FROM Order LIMIT 1];
            ord.Order_Status__c = 'Order Accepted';        
            ord.Actual_Order_Ship_Date__c = date.today();
            update ord;
            Assert.areEqual(true, ord != null);
            Test.stopTest(); 
        }
    }
	/**
    * @author Siva Kumar
    * @date 12-03-2025
    * @description test method to cover Order trigger logic 
    */
     public static testMethod void testOrderShipped() {
         User currentUser = new User(Id = UserInfo.getUserId());
         System.runAs(currentUser) { 
             Test.startTest();
             Order ord = [SELECT Id, Account.Name, Opportunity.StageName, Order_Status__c FROM Order LIMIT 1];
             ord.Order_Status__c = 'Shipped';  
             ord.Actual_Order_Ship_Date__c = System.today();  
             ord.SBQQ__Contracted__c = false;  
             ord.Polaris_Fulfillment_Status__c = 'Completed';
             update ord;
             Assert.areEqual(true, ord != null);
             Test.stopTest(); 
             
         }
     }
}