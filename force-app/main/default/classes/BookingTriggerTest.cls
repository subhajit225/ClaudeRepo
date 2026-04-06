/***************************************************************************** 
* @description       : This is a test class for Booking Line Item trigger
* @author            : 
* @last modified on  : 10-06-2025
* @last modified by  : Shrutika
* Modifications Log
* Ver   Date          Author               Modification
* 1.0   10-06-2025    Shrutika             Updated for PRDOPS26-982
******************************************************************************/
@isTest
public class BookingTriggerTest {
    /**
     * @description This is test setup
     */
    @testSetup
    public static void setup() 
    { 
          String uniqueUserName = 'BookingSyncBatchTest' + DateTime.now().getTime() + '@testclass.com';                               
            Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
            User usr=new user(alias = 'std', email='testuser@testclass.com',
            emailencodingkey='UTF-8', firstname='test', lastname='user', languagelocalekey='en_US',
            localesidkey='en_US', profileid = p.Id,
            timezonesidkey='America/Los_Angeles', username=uniqueUserName);
            system.runAs(usr){
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
                
              //create account and contact to assign to opportunity
              account acct=new account(name='test account',AccountNumber='123456');
              insert acct;
              contact con=new contact(lastname='test contact',leadsource='web',
                                  email='testc@test.com',accountId=acct.id);
              insert con;
              acct.AdvocateHub__Referral_Source__c=con.id;
              update acct;
              //insert new opportunity
              List<Opportunity> oppList=new List<Opportunity>();
              Opportunity oppy1=new Opportunity(
                                           Name='test Opportunity',
                                           AccountId=acct.id, 
                                           StageName='1 Discovery', 
                                           CloseDate=system.Today(),
                                           ForecastCategoryName='Best Case',
                                           Initial_Contacts_Name__c=con.id,Business_Unit__c='Rubrik',
                                           Installation_Assigned_To__c='FE Install'
                                           );
              oppList.add(oppy1);
              insert oppList;
              List<Product2> prodlist = new List<Product2>();
              Map<String, Object>  prodMap = new Map<String, Object> {
                'Name' => 'Pord A',
                'ProductCode' => 'ProductXYZ',
                'isActive' => true,
                'Family' => 'AIR',
                'Product_Type__c' => 'Appliance'
              };
              Product2 pd = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap);  
              prodlist.add(pd);
              insert prodlist;
            
        Id pricebookId = Test.getStandardPricebookId();
        Map<String, Object>  quoteMap = new Map<String, Object> {
            'SBQQ__Account__c' => acct.Id,
            'SBQQ__Opportunity2__c' => oppList[0].Id
        };
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
        update oppList[0];
        test.startTest();
        List<Order>OrderList = new List<Order>();
        for(integer i=0;i<2;i++){
        
        OrderList.add(new order(
          Name='BkgtestOrder'+i,
          Status = 'Draft',
          Order_Status__c='Pending',
        //od.BookingStatus__c='None',
           AccountId = acct.Id,
           OpportunityId = oppList[0].Id,
           EffectiveDate = Date.Today(),
           ShippingStreet ='Test Street',
           ShippingCity ='Test City',
           ShippingState ='California',
           ShippingCountry ='United States',
           ShippingPostalcode ='94820',
           ship_To_Name__c = acct.id,
           Type = 'Revenue',
           Est_Ship_Date__c = system.today(),
           RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Revenue Order').getRecordTypeId(),
           Pricebook2Id = pricebookId
        ));
        }
        //od.Hold_Code__c = 'Missing freight forwarder details';
        insert OrderList;
        
        //Create your pricebook entry
        PricebookEntry pbEntry = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prodlist[0].Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbEntry;
        List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prodlist[0].Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200));
        insert lines;
        //OrderList[0].Pricebook2Id=OrderList[1].Pricebook2Id = pricebookId;
        //update OrderList;
        List<OrderItem> OrdItems = new List<OrderItem>();
        OrdItems.add(new orderItem(SBQQ__QuoteLine__c = lines[0].id, OrderId=OrderList[0].Id, Quantity=10, PricebookEntryId=pbEntry.Id, UnitPrice = 10, Product2Id = prodlist[0].Id, SerialNumber__c = 'AA162403440008,AB162403440009,AC162403440009,AD162403440009'));
        OrdItems.add(new orderItem(SBQQ__QuoteLine__c = lines[0].id, OrderId=OrderList[1].Id, Quantity=10, PricebookEntryId=pbEntry.Id, UnitPrice = 10, Product2Id = prodlist[0].Id, SerialNumber__c = 'AA162403440007,AB162403440006,AC162403440005,AD162403440004'));
        insert OrdItems;

        List<OrderItem> oiList = [Select SBQQ__QuoteLine__c, SBQQ__QuoteLine__r.SBQQ__Quote__c, Order.SBQQ__Quote__c from OrderItem where ID IN :OrdItems];
         OrderList[0].Hold_Code__c= OrderList[1].Hold_Code__c=' ';
         OrderList[0].Order_Status__c =OrderList[1].Order_Status__c = 'Order Accepted';  
         OrderList[0].SBQQ__Contracted__c =OrderList[1].SBQQ__Contracted__c = false;  
         OrderList[0].Order_Accepted_By__c=OrderList[1].Order_Accepted_By__c=usr.id;
         OrderList[0].SBQQ__Quote__c=OrderList[1].SBQQ__Quote__c=qt1.id;
         update OrderList;

         
         List<Booking__c> bkgList=new List<Booking__c>();
         bkgList.add(new Booking__c(
         Order__c=OrderList[0].id,
         Opportunity__c=oppList[0].id,
         Account_Name__c=acct.id,
         Field_Update_Status__c=' ',
         RecordTypeId=Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking').getRecordTypeId(),
         Opportunity_Close_Date__c =system.Today()
          ));
          bkgList.add(new Booking__c(
         Order__c=OrderList[1].id,
         Opportunity__c=oppList[0].id,
         Account_Name__c=acct.id,
         Field_Update_Status__c=' ',
         RecordTypeId=Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking Adjustment').getRecordTypeId(),
         Opportunity_Close_Date__c =system.Today()
          ));
         insert bkgList;
                List<Booking_Line_Item__c> lstInsertBLI = new List<Booking_Line_Item__c>{
          new Booking_Line_Item__c(
          Booking__c = bkgList[0].id,
          Type__c = 'Revenue',
          OrderProduct__c = oiList[0].Id,
          Impacts_Gross_Bookings__c = true,
          Impacts_Net_Bookings__c = true,
          Total_Price__c = 10.0,
          Net_TCV_Amount__c = 8,
          New_Expansion_TCV__c = 2,
          Gross_ACV_Amount__c = 5,
          Gross_New_Expansion_ACV__c = 5
        ),
        new Booking_Line_Item__c(
          Booking__c = bkgList[0].id,
          Type__c = 'Revenue',
          OrderProduct__c = oiList[1].Id,
          Impacts_Gross_Bookings__c = true,
          Impacts_Net_Bookings__c = true,
          Total_Price__c = 10.0,
          Net_TCV_Amount__c = 8,
          New_Expansion_TCV__c = 2,
          Gross_ACV_Amount__c = 5,
          Gross_New_Expansion_ACV__c = 5
        )
        };
        insert lstInsertBLI;         
                

            }
    }

    /**
     * @description This is test method for Booking History Tracking
     */
    public static testmethod void testTrackBookingChangesTest()
    {
        system.runAs(new user(Id = UserInfo.getUserId())){
            List<Booking__c> bkgList=[SELECT id,RecordType.name from Booking__c order by RecordType.name];
        List<Booking_Line_Item__c> lstBLI = [Select Id,Booking__c, Net_TCV_Amount__c From Booking_Line_Item__c Where Booking__c =: bkgList[0].Id];

            String addressString = 'Salesforce Tower, 415 Mission Street, 3rd Floor, San Francisco, CA 94105, United States,Salesforce Tower, 415 Mission Street, 3rd Floor, San Francisco, CA 94105, United States,Salesforce Tower, 415 Mission Street, 3rd Floor, San Francisco, CA 94105, United States';
            Id bkgId ;
            test.startTest();
            BookingHelper.isTestRunning = true;
           lstBLI[0].Net_TCV_Amount__c = 9;
        update lstBLI;
            for(Booking__c bkg : bkgList){
               if(bkg.RecordType.name == 'Booking'){
                  bkg.Field_Update_Status__c='Core Attributes - Frozen';
                  bkgId = bkg.id;
               }
               else{
                  bkg.Opportunity_Close_Date__c = system.today().addDays(7);
                  bkg.Original_Booking__c = bkgId;
               }
               bkg.Address__c= addressString;
            }  
            update bkgList;

            for(Booking__c bkg : bkgList){
                bkg.Address__c= '';
            }  
            update bkgList;

            List<Booking_Audit__c> bookingHistiry = [SELECT Id FROM Booking_Audit__c];
            system.assert(bookingHistiry.size()>0);
             
            test.stopTest();
        }
    }
    /**
     * @description This is test method for Booking Edit Error
     */
    public static testmethod void testTrackBookingError()
    {
        String uniqueUserName = 'BookingMain' + DateTime.now().getTime() + '@testclass.com.sandbox';
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
            List<Booking__c> bkgList=[SELECT id,RecordType.name, Order__c from Booking__c order by RecordType.name];
            List<Order> lstOrder = [Select Id, Order_Status__c From Order Where Id = : bkgList[0].Order__c];
            lstOrder[0].Order_Status__c = 'Shipped';
            update lstOrder[0];
            Id bkgId ;
            test.startTest();
            BookingHelper.bypassBookingValidationRule = false;
                for(Booking__c bkg : bkgList){
                if(bkg.RecordType.name == 'Booking'){
                    bkg.Field_Update_Status__c='Core Attributes - Frozen';
                    bkgId = bkg.id;
                }
                else{
                    bkg.Opportunity_Close_Date__c = system.today().addDays(7);
                    bkg.Original_Booking__c = bkgId;
                }
                }  
            try{
                update bkgList;
            }catch(Exception ex){
                System.assert(ex.getMessage().containsIgnorecase('prodops'));
            }      
            test.stopTest();
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
            Booking__c bkg=[SELECT id from Booking__c where Original_Booking__c=NULL LIMIT 1 ];
            test.startTest();
                bkg.Field_Update_Status__c='Core Attributes - Frozen';
                update bkg;
                system.assert(bkg != null);                
            test.stopTest();
        }
    }
}