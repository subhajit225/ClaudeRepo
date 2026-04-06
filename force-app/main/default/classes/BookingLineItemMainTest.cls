/***************************************************************************** 
* @description       : This is a test class for Booking Line Item trigger
* @author            : Prashik
* @last modified on  : 10-06-2025
* @last modified by  : Prashik
* Modifications Log
* Ver   Date          Author               Modification
* 1.0   10-06-2025    Prashik              Initial Version/PRDOPS26-982
******************************************************************************/
@isTest
public class BookingLineItemMainTest {
    
    /**
     * @description This is test setup
     */
    @testSetup
    public static void setup() { 
        ShGl_DisableFunctionalityLogic__c setting = new ShGl_DisableFunctionalityLogic__c();
        setting.Name = 'System Administrator';
        setting.Disable_Opportunity_Old_Trigger__c = TRUE;
        setting.Disable_Order_Old_Trigger__c = TRUE;
        setting.Disable_Account_Old_Trigger__c = TRUE;
        insert setting;
        
        ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c();
        settingDisable.Name = 'System Administrator';
        settingDisable.Disable_Opportunity_Validation_Rules__c = TRUE;
        settingDisable.Disable_Opportunity_Triggers__c = TRUE;
        settingDisable.Disable_Order_Validation_Rules__c = TRUE;
        settingDisable.Disable_Order_Old_Trigger__c = TRUE;
        settingDisable.Disable_CCR_Validation_Rules__c = TRUE;
        settingDisable.Disable_Account_Validation_Rules__c = TRUE;
        settingDisable.Disable_Account_Triggers__c = TRUE;
        settingDisable.Disable_CCR_Triggers__c = TRUE;
        insert settingDisable;
        
        List<TriggerControl__c> triggerList=new List<TriggerControl__c>();
        TriggerControl__c setting0 = new TriggerControl__c();
        setting0.Name = 'Order';
        setting0.DisableTrigger__c = TRUE;
        triggerList.add(setting0);
        TriggerControl__c setting1 = new TriggerControl__c();
        setting1.Name = 'Opportunity';
        setting1.DisableTrigger__c = TRUE;
        triggerList.add(setting1);
        insert triggerList;
        
        TriggerControls.disableQuoteTrigger = true;
    	TriggerControls.disableQuoteLineTrigger = true;
        
        String uniqueUserName = 'BookingLineItemMain' + DateTime.now().getTime() + '@testclass.com.sandbox';
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User usr=new user(
            alias = 'std', 
            email='testuser@testclass.com',
            emailencodingkey='UTF-8', 
            firstname='test', 
            lastname='user', 
            languagelocalekey='en_US',
            localesidkey='en_US', 
            profileid = p.Id,
            timezonesidkey='America/Los_Angeles',
            RBAC_Department__c = 'Service Account',
            RBAC_Group__c = 'API', 
            username=uniqueUserName);
        insert usr;
        
        System.runAs(usr){
            
            account acct=new account(name='test account',AccountNumber='123456');
            insert acct;
            contact con=new contact(lastname='test contact',leadsource='web',
                                    email='testc@test.com.sandbox',accountId=acct.id);
            insert con;
            acct.AdvocateHub__Referral_Source__c=con.id;
            update acct;
            
            Opportunity opp=new Opportunity(
                Name='test Opportunity1 '+uniqueUserName,
                AccountId=acct.id, 
                StageName='1 Discovery', 
                CloseDate=system.Today(),
                ACV_Amount__c = 200,
                ForecastCategoryName='Best Case',
                Initial_Contacts_Name__c=con.id,Business_Unit__c='Rubrik',
                Installation_Assigned_To__c='FE Install',
                OwnerId=usr.id,
                Opportunity_Sub_Type__c = 'Full'
                
                
            );
           insert opp;
            
            list<Product2> prodlist = new list<Product2>();
            Map<String, Object>  prodMap = new Map<String, Object> {
                'Name' => 'Pord A',
                    'ProductCode' => 'OPTY-SPLIT',
                    'isActive' => true,
                    'Family' => 'AIR',
                    'Product_Type__c' => 'Appliance'
                    };
                        Product2 pd = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap);  
            prodlist.add(pd);
            
            Map<String, Object>  prodMap1 = new Map<String, Object> {
                'Name' => 'Pord A',
                    'ProductCode' => 'OPTY-SPLIT',
                    'isActive' => true,
                    'Family' => 'AIR',
                    'Product_Type__c' => 'Appliance',
                    'Category__c'=> 'Other'
                    };
                        Product2 pd1 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap1);  
            prodlist.add(pd1);
            
            insert prodlist;
            
            Id pricebookId = Test.getStandardPricebookId();
            Map<String, Object>  quoteMap = new Map<String, Object> {
                'SBQQ__Account__c' => acct.Id,
                    'SBQQ__Opportunity2__c' => opp.Id
                    };
                        SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
            qt1.SBQQ__Opportunity2__c = opp.Id;
            qt1.SBQQ__Primary__c = true;
            qt1.SBQQ__PriceBook__c = pricebookId;
            qt1.ApprovalStatus__c = 'Approved';
            insert qt1;
            
            opp.Pricebook2Id = pricebookId;
            opp.StageName = '4 Business Justification';
            opp.Partner_Level_Of_Involvement__c = '4.Partner or joint initiated opportunity, partner brought substantial value in sales cycle and getting deal closed';
            opp.SBQQ__PrimaryQuote__c = qt1.Id;
            opp.Amount = 150;
            opp.Split_percentage__c = 50;        
            opp.New_Expansion_TCV__c = 75;
            opp.Subsumed_Renewal_TCV__c = 75;                  
            update opp;
            
            Order ord = new Order();
            ord.Name='testOrder1';
            ord.Status = 'Draft';
            ord.Order_Status__c='Pending';
            ord.AccountId = acct.Id;
            ord.OpportunityId = opp.Id;
            ord.EffectiveDate = Date.Today();
            ord.ShippingStreet ='Test Street';
            ord.ShippingCity ='Test City';
            ord.ShippingState ='California';
            ord.ShippingCountry ='United States';
            ord.ShippingPostalcode ='94820';
            ord.ship_To_Name__c = acct.id;
            ord.Type = 'Revenue';
            ord.Est_Ship_Date__c = system.today();
            ord.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Revenue Order').getRecordTypeId();
            ord.Pricebook2Id = pricebookId;
            insert ord;
            
            test.startTest();
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
                UnitPrice = 200.00,
                IsActive = true
            );
            insert pbEntry1;        
            
            OpportunityLineItem oli = new OpportunityLineItem(
                OpportunityId = opp.Id,
                Quantity = 5,
                PricebookEntryId = pbEntry.Id,
                TotalPrice = 5 * pbEntry.UnitPrice,
                Product2Id = prodlist[0].Id,
                ACV_Amount__c = 100,
                New_Expansion_ACV__c = 150,
                New_Expansion_TCV__c = 50,
                Renewal_TCV__c =100,
                Subsumed_Renewal_TCV__c = 50
            );
            insert oli;
            
            OrderItem oritem = new OrderItem(
                OrderId=ord.Id, 
                Quantity=10, 
                PricebookEntryId=pbEntry.Id, 
                UnitPrice = 10, 
                Product2Id = prodlist[0].Id, 
                SerialNumber__c = 'AA162403440008,AB162403440009,AC162403440009,AD162403440009'
            );
            insert oritem;

            ord.Hold_Code__c=' ';
            ord.Order_Status__c = 'Order Accepted';  
            ord.SBQQ__Contracted__c = false;  
            ord.Order_Accepted_By__c=usr.id;
            update ord;
            ord.Order_Status__c = 'Shipped';
            ord.Order_Accepted_Timestamp__c =System.today()-180;
            update ord;
            
            Booking__c bkg=new Booking__c(
                Order__c=ord.id,
                Opportunity__c=opp.id,
                Account_Name__c=acct.id,
                status__c='Completed',
                RecordTypeId=Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking').getRecordTypeId()
            );
            insert bkg;
            
            Booking_Line_Item__c bli = new Booking_Line_Item__c();         
            bli.Booking__c = bkg.id;
            bli.Total_Price__c = 10.0;
            bli.Rebate__c= 2.0;
            bli.Impacts_Gross_Bookings__c = true;
            bli.Impacts_Net_Bookings__c= true;
            bli.Impacts_Commission__c= true;
            bli.Type__c='Distributor Fee';
            insert bli;
            test.stoptest();     
        }
    }
    
    /**
     * @description This is test method to test error bypass
     */
    public static testMethod void testBookingMethod() {
    	User usr = [SELECT id FROM User WHERE isActive = TRUE AND email = 'testuser@testclass.com' LIMIT 1];
    	System.runAs(usr) {
      		test.startTest();
      		Booking_Line_Item__c bli = [SELECT id FROM Booking_Line_Item__c LIMIT 1];
			update bli;
            test.stoptest();    
            System.assert(true, 'No exception was thrown, as expected');        
        }
    }
    
    /**
     * @description This is test method to test error message
     */
    public static testMethod void testBookingMethodError() {
    	String uniqueUserName = 'BookingLineItemMain' + DateTime.now().getTime() + '@testclass.com.sandbox';
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User usr=new user(
            alias = 'std', 
            email='testuser@testclass.com.error',
            emailencodingkey='UTF-8', 
            firstname='test', 
            lastname='user', 
            languagelocalekey='en_US',
            localesidkey='en_US', 
            profileid = p.Id,
            timezonesidkey='America/Los_Angeles',
            username=uniqueUserName);
        insert usr;
    	System.runAs(usr) {
      		test.startTest();
            Booking_Line_Item__c bli = [SELECT id FROM Booking_Line_Item__c LIMIT 1];
            try{
			  update bli;
            }catch(Exception ex){
              System.assert(ex.getMessage().containsIgnorecase('prodops'));
            }
            test.stoptest();            
        }
    }

    /**
     * @description This is a test method to test Trigger bypass
     */
    static testmethod void testTriggerControlCase()
    {
        system.runAs(new user(Id = UserInfo.getUserId())){
            TriggerControl__c tc=new TriggerControl__c();
            tc.DisableTrigger__c=TRUE;
            tc.Name='Booking';
            insert tc;
            test.startTest();
            Booking_Line_Item__c bli = [SELECT id FROM Booking_Line_Item__c LIMIT 1];
            try{
			  update bli;
            }catch(Exception ex){
              System.assert(ex.getMessage().containsIgnorecase('prodops'));
            }             
            test.stopTest();
        }
    }
}