/***************************************************************************** 
* @description       : This is a test class for CreateBLIOrBLIWithBooking
* @author            : 
* @last modified on  : 10-06-2025
* @last modified by  : Shrutika
* Modifications Log
* Ver   Date          Author               Modification
* 1.0   10-06-2025    Shrutika             Updated for PRDOPS26-982
******************************************************************************/
@isTest
public class CreateBLIorBLIwithBookingTest {
    public static List<Booking_Line_Item__c> BLIList = new List<Booking_Line_Item__c>();

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
        TriggerControl__c setting2 = new TriggerControl__c();
        setting2.Name = 'Booking';
        setting2.DisableTrigger__c = TRUE;
        triggerList.add(setting2);
        insert triggerList;
        
        TriggerControls.disableQuoteTrigger = true;
    	TriggerControls.disableQuoteLineTrigger = true;
        
        String uniqueUserName = 'CreateBLIorBLIwithBookingTest' + DateTime.now().getTime() + '@testclass.com.sandbox';
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User usr=new user(alias = 'std', email='aneeja.shaik@rubrik.com',
                          emailencodingkey='UTF-8', firstname='test', lastname='user', languagelocalekey='en_US',
                          localesidkey='en_US', profileid = p.Id,
                          timezonesidkey='America/Los_Angeles', username=uniqueUserName);
        insert usr;
        
        System.runAs(usr){
            
            //create account and contact to assign to opportunity
            account acct=new account(name='test account',AccountNumber='123456');
            insert acct;
            contact con=new contact(lastname='test contact',leadsource='web',
                                    email='testc@test.com.sandbox',accountId=acct.id);
            insert con;
            acct.AdvocateHub__Referral_Source__c=con.id;
            update acct;
            //insert new opportunity.
            List<Opportunity> OpportunitList=new List<Opportunity>();
            Opportunity Oppty=new Opportunity(
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
            OpportunitList.add(Oppty);
            Opportunity oppty1=new Opportunity(
                Name='test Opportunity1',
                AccountId=acct.id, 
                StageName='1 Discovery', 
                CloseDate=system.Today(),
                ForecastCategoryName='Best Case',
                Initial_Contacts_Name__c=con.id,Business_Unit__c='Rubrik',
                Installation_Assigned_To__c='FE Install',
                OwnerId=usr.id,
                ACV_Amount__c = 200,
                Opportunity_Sub_Type__c = 'Partial'
            );
            OpportunitList.add(oppty1); 
            Opportunity oppty2=new Opportunity(
                Name='test Opportunity2',
                AccountId=acct.id, 
                StageName='1 Discovery', 
                CloseDate=system.Today(),
                ACV_Amount__c = 200,
                ForecastCategoryName='Best Case',
                Initial_Contacts_Name__c=con.id,Business_Unit__c='Rubrik',
                Installation_Assigned_To__c='FE Install',
                OwnerId=usr.id
            );
            OpportunitList.add(oppty2);
            insert OpportunitList;
            
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
                    'SBQQ__Opportunity2__c' => OpportunitList[0].Id
                    };
                        SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
            qt1.SBQQ__Opportunity2__c = OpportunitList[0].Id;
            qt1.SBQQ__Primary__c = true;
            qt1.SBQQ__PriceBook__c = pricebookId;
            qt1.ApprovalStatus__c = 'Approved';
            insert qt1;
            
            Map<String, Object>  quoteMap1 = new Map<String, Object> {
                'SBQQ__Account__c' => acct.Id,
                    'SBQQ__Opportunity2__c' => OpportunitList[1].Id
                    };        
                        SBQQ__Quote__c qt2 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap1);
            qt2.SBQQ__Opportunity2__c = OpportunitList[1].Id;
            qt2.SBQQ__Primary__c = true;
            qt2.SBQQ__PriceBook__c = pricebookId;
            qt2.ApprovalStatus__c = 'Approved';
            insert qt2;        
            
            Map<String, Object>  quoteMap2 = new Map<String, Object> {
                'SBQQ__Account__c' => acct.Id,
                    'SBQQ__Opportunity2__c' => OpportunitList[2].Id
                    };        
                        SBQQ__Quote__c qt3 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap2);
            qt2.SBQQ__Opportunity2__c = OpportunitList[2].Id;
            qt2.SBQQ__Primary__c = true;
            qt2.SBQQ__PriceBook__c = pricebookId;
            qt2.ApprovalStatus__c = 'Approved';
            insert qt3;
            
            OpportunitList[0].Pricebook2Id = pricebookId;
            OpportunitList[0].StageName = '4 Business Justification';
            OpportunitList[0].Partner_Level_Of_Involvement__c = '4.Partner or joint initiated opportunity, partner brought substantial value in sales cycle and getting deal closed';
            OpportunitList[0].SBQQ__PrimaryQuote__c = qt1.Id;
            OpportunitList[0].Amount = 150;
            OpportunitList[0].Split_percentage__c = 50;        
            OpportunitList[0].New_Expansion_TCV__c = 75;
            OpportunitList[0].Subsumed_Renewal_TCV__c = 75;                  
            update OpportunitList[0];
            
            OpportunitList[1].Pricebook2Id = pricebookId;
            OpportunitList[1].StageName = '4 Business Justification';
            OpportunitList[1].Partner_Level_Of_Involvement__c = '4.Partner or joint initiated opportunity, partner brought substantial value in sales cycle and getting deal closed';
            OpportunitList[1].SBQQ__PrimaryQuote__c = qt2.Id;
            OpportunitList[1].Amount = 300;
            OpportunitList[1].Split_percentage__c = 50;        
            OpportunitList[1].New_Expansion_TCV__c = 150;
            OpportunitList[1].Subsumed_Renewal_TCV__c = 150;          
            update OpportunitList[1];  
            
            OpportunitList[2].Pricebook2Id = pricebookId;
            OpportunitList[2].StageName = '4 Business Justification';
            OpportunitList[2].Partner_Level_Of_Involvement__c = '4.Partner or joint initiated opportunity, partner brought substantial value in sales cycle and getting deal closed';
            OpportunitList[2].SBQQ__PrimaryQuote__c = qt3.Id;
            OpportunitList[2].Amount = 220;
            OpportunitList[2].Split_percentage__c = 50;        
            OpportunitList[2].New_Expansion_TCV__c = 110;
            OpportunitList[2].Subsumed_Renewal_TCV__c = 110;          
            update OpportunitList[2];          
            
            
            
            
            List<Order> OrderList=new List<Order>();
            Order od1 = new Order();
            od1.Name='testOrder1';
            od1.Status = 'Draft';
            od1.Order_Status__c='Pending';
            //od1.BookingStatus__c='None';
            od1.AccountId = acct.Id;
            od1.OpportunityId = OpportunitList[0].Id;
            od1.EffectiveDate = Date.Today();
            od1.ShippingStreet ='Test Street';
            od1.ShippingCity ='Test City';
            od1.ShippingState ='California';
            od1.ShippingCountry ='United States';
            od1.ShippingPostalcode ='94820';
            od1.ship_To_Name__c = acct.id;
            od1.Type = 'Revenue';
            od1.Est_Ship_Date__c = system.today();
            od1.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Revenue Order').getRecordTypeId();
            od1.Pricebook2Id = pricebookId;
            //od1.Hold_Code__c = 'Missing freight forwarder details';
            OrderList.add(od1);
            Order od2 = new Order();
            od2.Name='testOrder1';
            od2.Status = 'Draft';
            od2.Order_Status__c='Pending';
            //od2.BookingStatus__c='None';
            od2.AccountId = acct.Id;
            od2.OpportunityId = OpportunitList[1].Id;
            od2.EffectiveDate = Date.Today();
            od2.ShippingStreet ='Test Street';
            od2.ShippingCity ='Test City';
            od2.ShippingState ='California';
            od2.ShippingCountry ='United States';
            od2.ShippingPostalcode ='94820';
            od2.ship_To_Name__c = acct.id;
            od2.Type = 'Revenue';
            od2.Est_Ship_Date__c = system.today();
            od2.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Revenue Order').getRecordTypeId();
            od2.Pricebook2Id = pricebookId;
            //od2.Hold_Code__c = 'Missing freight forwarder details';
            OrderList.add(od2);
            
            Order od3 = new Order();
            od3.Name='testOrder3';
            od3.Status = 'Draft';
            od3.Order_Status__c='Pending';
            //od3.BookingStatus__c='None';
            od3.AccountId = acct.Id;
            od3.OpportunityId = OpportunitList[2].Id;
            od3.EffectiveDate = Date.Today();
            od3.ShippingStreet ='Test Street';
            od3.ShippingCity ='Test City';
            od3.ShippingState ='California';
            od3.ShippingCountry ='United States';
            od3.ShippingPostalcode ='94820';
            od3.ship_To_Name__c = acct.id;
            od3.Type = 'Revenue';
            od3.Est_Ship_Date__c = system.today();
            od3.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Revenue Order').getRecordTypeId();
            od3.Pricebook2Id = pricebookId;
            //od3.Hold_Code__c = 'Missing freight forwarder details';
            OrderList.add(od3);
            insert OrderList;
            
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
                OpportunityId = OpportunitList[1].Id,
                Quantity = 5,
                PricebookEntryId = pbEntry.Id,
                TotalPrice = 5 * pbEntry.UnitPrice,
                Product2Id = prodlist[0].Id,
                ACV_Amount__c = 100,
                New_Expansion_ACV__c = 150,
                New_Expansion_TCV__c = 50,
                Renewal_TCV__c =100,
                Subsumed_Renewal_TCV__c = 50
                //  SBQQ__QuoteLine__c = 
                //ProductCode = prodlist[0].ProductCode  
                
            );
            insert oli;
            
            OpportunityLineItem oli1 = new OpportunityLineItem(
                OpportunityId = OpportunitList[2].Id,
                Quantity = 5,
                PricebookEntryId = pbEntry.Id,
                TotalPrice = 5 * pbEntry.UnitPrice,
                Product2Id = prodlist[1].Id,
                ACV_Amount__c = 100,
                New_Expansion_ACV__c = 150,
                New_Expansion_TCV__c = 50,
                Renewal_TCV__c =100,
                Subsumed_Renewal_TCV__c = 50
                //  SBQQ__QuoteLine__c = 
                //ProductCode = prodlist[0].ProductCode                
            );
            insert oli1;   
            
            orderList[0].Pricebook2Id = pricebookId;
            update orderList[0];
            OrderItem oritem = new OrderItem(OrderId=orderList[0].Id, Quantity=10, PricebookEntryId=pbEntry.Id, UnitPrice = 10, Product2Id = prodlist[0].Id, SerialNumber__c = 'AA162403440008,AB162403440009,AC162403440009,AD162403440009');
            insert oritem;
            orderList[0].Hold_Code__c=' ';
            //update od;
            //system.debug('status 2-->'+orderList[0].Order_Status__c);
            orderList[0].Order_Status__c = 'Order Accepted';  
            orderList[0].SBQQ__Contracted__c = false;  
            orderList[0].Order_Accepted_By__c=usr.id;
            update orderList[0];
            orderList[0].Order_Accepted_Timestamp__c =System.today()-180;
            update orderList[0];
            orderList[1].Order_Accepted_Timestamp__c =System.today()+180;
            //update orderList[1];
            
            List<Booking__C> BookingList=new List<Booking__c>(); 
            Booking__c bkg=new Booking__c(
                Order__c=orderList[0].id,
                Opportunity__c=OpportunitList[0].id,
                Account_Name__c=acct.id,
                status__c='Completed',
                RecordTypeId=Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking').getRecordTypeId()
            );
            BookingList.add(bkg);
            
            Booking__c bkg1=new Booking__c(
                Order__c=orderList[1].id,
                Opportunity__c=OpportunitList[1].id,
                Account_Name__c=acct.id,
                status__c='Completed',
                RecordTypeId=Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking').getRecordTypeId()
            );
            BookingList.add(bkg1);
            
            Booking__c bkg11=new Booking__c(
                Order__c=orderList[2].id,
                Opportunity__c=OpportunitList[2].id,
                Account_Name__c=acct.id,
                status__c='Completed',
                RecordTypeId=Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking').getRecordTypeId()
            );
            BookingList.add(bkg11); 
             
            insert BookingList;
            //List<Booking_Line_Item__c> BLIList = new List<Booking_Line_Item__c>();
            
            /*  BLIList.add(new Booking_Line_Item__c(Booking__c = BookingList[0].id, Total_Price__c = 10.0,Rebate__c= 2.0,Impacts_Gross_Bookings__c = true,Impacts_Net_Bookings__c= true,Impacts_Commission__c= true, Type__c='Distributor Fee'));
BLIList.add(new Booking_Line_Item__c(Booking__c = BookingList[0].id,Total_Price__c = 10.0,Rebate__c= 2.0,Impacts_Gross_Bookings__c = true,Impacts_Net_Bookings__c= true,Impacts_Commission__c= true, Type__c='Partner Referral Fee'));
insert BLIList; */
            //EXCL-6
            Booking__c bkgAdj=new Booking__c(
                Order__c=orderList[0].id,
                Opportunity__c=OpportunitList[0].id,
                Account_Name__c=acct.id,
                status__c='Completed',
                Order_Type__c = 'Booking Adjustment',    
                Original_Booking__c = BookingList[0].Id,
                RecordTypeId=Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking Adjustment').getRecordTypeId()
            );
            bkgAdj.Opportunity_Close_Date__c = system.today();
            insert bkgAdj;
            bkgAdj.Opportunity_Close_Date__c = system.today() + 7;
            update bkgAdj;
            
            Booking__c bkgAdj2=new Booking__c(
                Order__c=orderList[1].id,
                Opportunity__c=OpportunitList[1].id,
                Account_Name__c=acct.id,
                status__c='Completed',
                Order_Type__c = 'Booking Adjustment',    
                Original_Booking__c = BookingList[1].Id,
                RecordTypeId=Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking Adjustment').getRecordTypeId()
            );
            bkgAdj.Opportunity_Close_Date__c = system.today();
            insert bkgAdj2;
            bkgAdj.Opportunity_Close_Date__c = system.today() + 7;
            update bkgAdj2;
            
            Booking__c bkgAdj3=new Booking__c(
                Order__c=orderList[2].id,
                Opportunity__c=OpportunitList[2].id,
                Account_Name__c=acct.id,
                status__c='Completed',
                Order_Type__c = 'Booking Adjustment',  
                Original_Booking__c = BookingList[2].Id,
                RecordTypeId=Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking Adjustment').getRecordTypeId()
            );
            bkgAdj.Opportunity_Close_Date__c = system.today();
            insert bkgAdj3;
            bkgAdj.Opportunity_Close_Date__c = system.today() + 7;
            update bkgAdj3;         
            
            List<CCR__c> ccrToInsert=new List<CCR__c>(); 
            
            
            CCR__c cc=new CCR__C(
                Comment__c='test',
                Opportunity__c=OpportunitList[0].id,
                AssignmentStatus__c='Unassigned',
                User__c='Approved',
                CCR_Type__c='Change in Booking Policy / De-Risk Decision',   
                Amount__c=50,
                Referral_Fee_Amount__c=100,
                booking__c=BookingList[0].id,
                Account_Name__c=acct.id,
                Impacts_Commission__c = TRUE,
                Affective_Person__c=usr.id,
                Effective_Date__c = system.Today(),
                Customer_Returns_Type__c ='AmountItem Based'
                
            );
            ccrToInsert.add(cc); 
            OpportunitList[0].CCR__c = ccrToInsert[0].id;
            update OpportunitList[0];         
            
            CCR__c cc1=new CCR__C(
                Comment__c='test',
                Opportunity__c=OpportunitList[1].id,
                AssignmentStatus__c='Unassigned',
                User__c='Approved',
                CCR_Type__c='Customer Returns / Refunds',    
                Referral_Fee_Amount__c=100,
                booking__c=BookingList[1].id,
                Account_Name__c=acct.id,
                Amount__c=1000,
                Impacts_Commission__c = TRUE,
                Affective_Person__c=usr.id,
                Reason_for_late_payment__c='test',
                Effective_Date__c = system.Today(),
                Customer_Returns_Type__c ='AmountItem Based'
            );
            ccrToInsert.add(cc1); 
            
            OpportunitList[1].CCR__c = ccrToInsert[1].id;
            update OpportunitList[1]; 
            
            
            CCR__c cc2=new CCR__C(
                Comment__c='test',
                Opportunity__c=OpportunitList[0].id,
                AssignmentStatus__c='Unassigned',
                User__c='Approved',
                CCR_Type__c='Partner Referral Fee',    
                Referral_Fee_Amount__c=0.15,
                booking__c=BookingList[2].id,
                Account_Name__c=acct.id,
                Amount__c=100,
                Impacts_Commission__c = TRUE,
                Affective_Person__c=usr.id,
                Reason_for_late_payment__c='test',
                Effective_Date__c = system.Today()
                //Customer_Returns_Type__c ='AmountItem Based'
            );
            ccrToInsert.add(cc2); 
            insert ccrToInsert;     
            //OpportunitList[2].CCR__c = ccrToInsert[2].id;
            //update OpportunitList[2];         
            
            //  list<Booking_Line_Item__c> objBLIListt = new list<Booking_Line_Item__c>();
            
            Booking_Line_Item__c obBLlI = new Booking_Line_Item__c();         
            obBLlI.Booking__c = BookingList[0].id;
            obBLlI.CCR__c = ccrToInsert[0].id;
            //obBLlI.OrderProduct__c = orderList[0].id;
            obBLlI.Total_Price__c = 10.0;
            obBLlI.Rebate__c= 2.0;
            obBLlI.Impacts_Gross_Bookings__c = true;
            obBLlI.Impacts_Net_Bookings__c= true;
            obBLlI.Impacts_Commission__c= true;
            obBLlI.Type__c='Distributor Fee';
            BLIList.add(obBLlI); 
            
            Booking_Line_Item__c obBLlII = new Booking_Line_Item__c();                 
            obBLlII.Booking__c = BookingList[1].id;
            obBLlII.CCR__c = ccrToInsert[1].id;
            //obBLlI.OrderProduct__c = ;
            obBLlII.Total_Price__c = 10.0;
            obBLlII.Rebate__c= 2.0;
            obBLlII.Impacts_Gross_Bookings__c = true;
            obBLlII.Impacts_Net_Bookings__c= true;
            obBLlII.Impacts_Commission__c= true;
            //obBLlII.Type__c='Revenue';
            obBLlII.Type__c=ccrToInsert[1].CCR_Type__c;        
            BLIList.add(obBLlII);          
            
            Booking_Line_Item__c obBLlI1=new Booking_Line_Item__c();         
            obBLlI1.Booking__c = BookingList[2].id;
            obBLlI.CCR__c = ccrToInsert[2].id;        
            obBLlI1.Total_Price__c = 10.0;
            obBLlI1.Rebate__c= 2.0;
            obBLlI1.Impacts_Gross_Bookings__c = true;
            obBLlI1.Impacts_Net_Bookings__c= true;
            obBLlI1.Impacts_Commission__c= true;
            obBLlI1.Type__c=ccrToInsert[2].CCR_Type__c;
            BLIList.add(obBLlI1); 
            
            Insert BLIList;
            
            
            Booking_split__c bs  = new Booking_split__c(Booking__c = bookingList[0].id,Opportunity__c = OpportunitList[0].id,Opportunity_Split__c = 15.00);
            insert bs;
            test.stoptest();     
        }
        
    }
    /**
     * @description Test method to test Derisk CCR
     */
    public static testMethod void testDeriskCCR() {
        test.startTest();
        User usr=[select id from User Where isActive = true limit 1];
        system.runAs(usr){ 
            // CCR__c ccrDerisk = [select id,AssignmentStatus__c,Amount__c,booking__c from CCR__c where CCR_Type__c IN ('Change in Booking Policy / De-Risk Decision','Partner Referral Fee')  limit 1];
            CCR__c ccrDerisk = [select id,AssignmentStatus__c,Amount__c,booking__c, Opportunity__c, Referral_Fee_Amount__c from CCR__c where CCR_Type__c IN ('Change in Booking Policy / De-Risk Decision','Partner Referral Fee') limit 1];
            List<CCR__c> ccList1=new List<CCR__c>(); 
            ccList1.add(ccrDerisk); 
            CreateBLIorBLIwithBooking.createBLIorBLIwithBkg(ccList1);
            System.assert(ccList1.size() > 0);
        }
        test.stopTest();
        
    }
    
    /**
     * @description Test method to test PRF CCR
     */
    public static testMethod void testPRFCCR() {
        test.startTest();
        User usr=[select id from User Where isActive = true limit 1];
        system.runAs(usr){
            CCR__c ccrLateFee = [select id,AssignmentStatus__c,Amount__c,booking__c from CCR__c where CCR_Type__c='Partner Referral Fee' limit 1];
            List<CCR__c> ccList2=new List<CCR__c>();
            ccList2.add(ccrLateFee);             
            CreateBLIorBLIwithBooking.createBLIorBLIwithBkg(ccList2); 
            System.assert(ccList2.size() > 0);
        }
        test.stopTest();
    }
    
    /**
     * @description Test method to test PRF CCR with Oppty CLosed Date
     */
    public static testMethod void testPRFCCROppty() {
        test.startTest();
        User usr=[select id from User Where isActive = true limit 1];
        system.runAs(usr){
            Order ord = [Select Id,AccountId,OpportunityId FROM Order Limit 1];
            ord.Order_Accepted_Timestamp__c = null;
            update ord;
            CCR__c ccrLateFee = [select id,AssignmentStatus__c,Amount__c,booking__c from CCR__c where CCR_Type__c='Partner Referral Fee' limit 1];
            List<CCR__c> ccList2=new List<CCR__c>();
            ccList2.add(ccrLateFee);             
            CreateBLIorBLIwithBooking.createBLIorBLIwithBkg(ccList2); 
            System.assert(ccList2.size() > 0);
        }
        test.stopTest();
    }
    
    @isTest static void testMethod3() {
        test.startTest();
        User usr=[select id from User Where isActive = true limit 1];
        system.runAs(usr){ 
            Opportunity oppty = [Select Id,Name FROM Opportunity Where Name Like 'test Opportunity1%%' LIMIT 1];
            
            CreateBLIorBLIwithBooking.SuccessOpportunityInsertIdSet.add(oppty.Id);
            CreateBLIorBLIwithBooking.bliTobeInserted.addAll(BLIList);
            CCR__c ccrDerisk = [select id,AssignmentStatus__c,Booking__c from CCR__c where CCR_Type__c IN ('Change in Booking Policy / De-Risk Decision','Partner Referral Fee')  limit 1];
            List<CCR__c> ccList1=new List<CCR__c>(); 
            ccList1.add(ccrDerisk);   
            CreateBLIorBLIwithBooking.createBLIorBLIwithBkg(ccList1);
            System.assert(ccList1.size() > 0);
            
        }
        test.stopTest();
        
    }
    @isTest static void testMethod4() {
        test.startTest();
        User usr=[select id from User Where isActive = true limit 1];
        system.runAs(usr){ 
            Opportunity oppty = [Select Id,Name, CloseDate FROM Opportunity Where Name = 'test Opportunity2' Limit 1]; 
            if(system.today().month() <= 11){
                oppty.CloseDate = system.today().addMonths(12 - system.today().month());
            } else if(system.today().month() >= 11){
                oppty.CloseDate = system.today().addMonths(-(system.today().month() - 1));
            }
            update oppty;
            Booking__c bkgAdj = [Select Id from Booking__c where RecordType.Name = 'Booking Adjustment' And Opportunity__c =: oppty.Id limit 1];
            Account acct = [Select Id from Account Limit 1];
            CCR__c cc1=new CCR__C(
                Comment__c='test',
                Opportunity__c=oppty.id,
                AssignmentStatus__c='Unassigned',
                CCR_Type__c='Partner Referral Fee',    
                Referral_Fee_Amount__c=100,
                booking__c=bkgAdj.id,
                Account_Name__c=acct.id,
                Impacts_Commission__c = TRUE,
                /*Affective_Person__c=usr.id,*/
                Reason_for_late_payment__c='test'       
            );
            insert cc1;
            cc1.User__c='Approved';
            update cc1;
            
            List<CCR__c> ccList1=new List<CCR__c>();
            CreateBLIorBLIwithBooking.createBLIorBLIwithBkg(ccList1);
            ccList1.add(cc1);   
            CreateBLIorBLIwithBooking.createBLIorBLIwithBkg(ccList1);
            List<Booking_Line_Item__c> bkl = [Select Id,Type__c From Booking_Line_Item__c Where CCR__c IN: ccList1 LIMIT 5];
            System.assert(bkl.size() > 0);
        }
        test.stopTest();
        
    } 
    
    @isTest static void testMethodBookingAdjustment() {
        test.startTest();
        User usr=[select id from User Where isActive = true limit 1];
        system.runAs(usr){ 
            Order ord = [Select Id,AccountId,OpportunityId FROM Order Limit 1]; 
            if(system.today().month() <= 11){
                ord.Order_Accepted_Timestamp__c = system.now().addMonths(12 - system.today().month());
            } else if(system.today().month() >= 11){
                ord.Order_Accepted_Timestamp__c = system.now().addMonths(-(system.today().month() - 1));
            }
            update ord;
            
            Booking__c bkgAdj=new Booking__c(
                Order__c=ord.id,
                Opportunity__c=ord.OpportunityId,
                Account_Name__c=ord.AccountId,
                status__c='Completed',
                Order_Type__c = 'Booking Adjustment',
                RecordTypeId=Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking Adjustment').getRecordTypeId()
            );
            insert bkgAdj;
            
            CCR__c originalPRFCCR = new CCR__C(
                Comment__c = 'Original PRF',
                Opportunity__c = ord.OpportunityId,
                AssignmentStatus__c = 'Assigned',
                User__c = 'Pending',
                CCR_Type__c = 'Partner Referral Fee',
                Referral_Fee_Amount__c = 100,
                booking__c = bkgAdj.Id,
                Account_Name__c = ord.AccountId,
                Impacts_Commission__c = true
            );
            insert originalPRFCCR;
            originalPRFCCR.User__c =  'Approved';
            update originalPRFCCR;
            
            // Create original PRF BLI with known values
            Booking_Line_Item__c originalPRFBLI = new Booking_Line_Item__c(
                Booking__c = bkgAdj.Id,
                //CCR__c = originalPRFCCR.Id,
                Type__c = 'Partner Referral Fee',
                Total_Price__c = 100,
                New_Expansion_TCV__c = 60,
                Subsumed_Renewal_TCV__c = 40,
                Gross_ACV_Amount__c = 50,
                Gross_New_Expansion_ACV__c = 30,
                Gross_Subsumed_Renewal_ACV__c = 20
            );
            insert originalPRFBLI;
            
            List<CCR__c> ccList1=new List<CCR__c>();
            CreateBLIorBLIwithBooking.createBLIorBLIwithBkg(ccList1);
            ccList1.add(originalPRFCCR);   
            CreateBLIorBLIwithBooking.createBLIorBLIwithBkg(ccList1);
            List<Booking_Line_Item__c> bkl = [Select Id,Type__c From Booking_Line_Item__c Where CCR__c IN: ccList1 LIMIT 5];
            System.assert(bkl.size() == 0);
            test.stopTest(); 
        }
    } 
    
    @isTest static void testUpdateBLIforDistributorAndPRF() {
        test.startTest();
        User usr = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        System.runAs(usr){ 
            List<Booking_Line_Item__c> originalBLIs = new List<Booking_Line_Item__c>();
            
            Account acct = [SELECT Id FROM Account LIMIT 1];
            List<Opportunity> opps = [SELECT Id, Name, Amount, New_Expansion_TCV__c, Subsumed_Renewal_TCV__c, ACV_Amount__c, New_Expansion_ACV__c, Renewal_Subsumed_ACV__c FROM Opportunity LIMIT 3];
            Opportunity opp0 = opps[0];
            Opportunity opp1 = opps[1]; 
            
            List<Booking__c> bookings = [SELECT Id, Opportunity__c, Original_Booking__c,Order__c FROM Booking__c WHERE RecordType.Name = 'Booking' LIMIT 3];
            Booking__c bkg0 = bookings[0]; 
            Booking__c bkg1 = bookings[1]; 
            
            opp0.New_Expansion_TCV__c = 75.00;
            opp0.Subsumed_Renewal_TCV__c = 75.00;
            opp0.New_Expansion_ACV__c = 30.00; 
            opp0.Renewal_Subsumed_ACV__c = 20.00;
            
            opp1.New_Expansion_TCV__c = 150.00;
            opp1.Subsumed_Renewal_TCV__c = 150.00;
            opp1.New_Expansion_ACV__c = 60.00;
            opp1.Renewal_Subsumed_ACV__c = 40.00;
            update new List<Opportunity>{opp0, opp1};
                
                CCR__c prfCcrForOriginalBli = new CCR__c(
                    Comment__c = 'Original PRF for BLI mapping',
                    Opportunity__c = opp1.id,
                    AssignmentStatus__c = 'Assigned', 
                    User__c = 'Pending',
                    CCR_Type__c = 'Partner Referral Fee',   
                    Referral_Fee_Amount__c = 200.00,
                    booking__c = bkg1.id,
                    Account_Name__c = acct.id,
                    Impacts_Commission__c = TRUE,
                    Effective_Date__c = System.Today().addDays(-5) 
                );
            insert prfCcrForOriginalBli;
            
            originalBLIs.add(new Booking_Line_Item__c(
                Booking__c = bkg1.id,
                CCR__c = prfCcrForOriginalBli.Id, 
                Total_Price__c = 200.0, 
                New_Expansion_TCV__c = 100.0,
                Subsumed_Renewal_TCV__c = 50.0,
                Gross_ACV_Amount__c = 40.0,
                Gross_New_Expansion_ACV__c = 25.0,
                Gross_Subsumed_Renewal_ACV__c = 15.0,
                Impacts_Gross_Bookings__c = true,
                Impacts_Net_Bookings__c = true,
                Impacts_Commission__c = true,
                Type__c = 'Partner Referral Fee'
            ));
            
            originalBLIs.add(new Booking_Line_Item__c(
                Booking__c = bkg0.id,
                Total_Price__c = 1000.0, 
                Rebate__c = 10.0,
                Impacts_Gross_Bookings__c = true,
                Impacts_Net_Bookings__c = true,
                Impacts_Commission__c = true,
                Type__c = 'Distributor Fee'
            ));
            insert originalBLIs;
            
            
            List<CCR__c> ccrsToProcess = new List<CCR__c>();
            
            // CCR for Distributor Fee scenario
            CCR__c distFeeDebookingCcr = new CCR__C(
                Comment__c = 'Distributor Fee Debooking Trigger',
                Opportunity__c = opp0.id,
                AssignmentStatus__c = 'Unassigned',
                User__c = 'Pending',
                CCR_Type__c = 'Change in Booking Policy / De-Risk Decision',    
                Amount__c = 50, 
                booking__c = bkg0.id, 
                Account_Name__c = acct.id,
                Impacts_Commission__c = TRUE,
                Effective_Date__c = System.Today(),
                Customer_Returns_Type__c = 'AmountItem Based'
            );
            ccrsToProcess.add(distFeeDebookingCcr);   
            
            // CCR for Partner Referral Fee debooking
            CCR__c prfDebookingCcr = new CCR__C(
                Comment__c = 'Partner Referral Fee Debooking Trigger',
                Opportunity__c = opp1.id,
                AssignmentStatus__c = 'Unassigned',
                User__c = 'Pending',
                CCR_Type__c = 'Partner Referral Fee',    
                Referral_Fee_Amount__c = 100, 
                booking__c = bkg1.id, 
                Account_Name__c = acct.id,
                Impacts_Commission__c = TRUE,
                Effective_Date__c = System.Today()
            );
            ccrsToProcess.add(prfDebookingCcr);   
            insert ccrsToProcess;
            
            CreateBLIorBLIwithBooking.createBLIorBLIwithBkg(ccrsToProcess);
            System.assert(ccrsToProcess.size() > 0);
        }
        test.stopTest();
    }
    
    @isTest static void testUpdateBLIforDistributorAndPRF1() {
        test.startTest();
        User usr = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        System.runAs(usr){ 
            CreateBLIorBLIwithBooking.currentDate= system.today().adddays(93);
            List<Booking_Line_Item__c> originalBLIs = new List<Booking_Line_Item__c>();
            
            Account acct = [SELECT Id FROM Account LIMIT 1];
            List<Opportunity> opps = [SELECT Id, Name, Amount, New_Expansion_TCV__c, Subsumed_Renewal_TCV__c, ACV_Amount__c, New_Expansion_ACV__c, Renewal_Subsumed_ACV__c FROM Opportunity LIMIT 3];
            Opportunity opp0 = opps[0];
            Opportunity opp1 = opps[1]; 
            
            List<Booking__c> bookings = [SELECT Id, Opportunity__c, Original_Booking__c,Order__c FROM Booking__c WHERE RecordType.Name = 'Booking' LIMIT 3];
            Booking__c bkg0 = bookings[0]; 
            Booking__c bkg1 = bookings[1]; 
            
            opp0.New_Expansion_TCV__c = 75.00;
            opp0.Subsumed_Renewal_TCV__c = 75.00;
            opp0.New_Expansion_ACV__c = 30.00; 
            opp0.Renewal_Subsumed_ACV__c = 20.00;
            
            opp1.New_Expansion_TCV__c = 150.00;
            opp1.Subsumed_Renewal_TCV__c = 150.00;
            opp1.New_Expansion_ACV__c = 60.00;
            opp1.Renewal_Subsumed_ACV__c = 40.00;
            update new List<Opportunity>{opp0, opp1};
                
                CCR__c prfCcrForOriginalBli = new CCR__c(
                    Comment__c = 'Original PRF for BLI mapping',
                    Opportunity__c = opp1.id,
                    AssignmentStatus__c = 'Assigned', 
                    User__c = 'Pending',
                    CCR_Type__c = 'Partner Referral Fee',   
                    Referral_Fee_Amount__c = 200.00,
                    booking__c = bkg1.id,
                    Account_Name__c = acct.id,
                    Impacts_Commission__c = TRUE,
                    Effective_Date__c = System.Today().addDays(-5) 
                );
            insert prfCcrForOriginalBli;
            CCR__c prfCcrForOriginalBli1 = new CCR__c(
                    Comment__c = 'Original PRF for BLI mapping',
                    Opportunity__c = opp1.id,
                    AssignmentStatus__c = 'Assigned', 
                    User__c = 'Pending',
                    CCR_Type__c = 'Partner Referral Fee',   
                    Referral_Fee_Amount__c = 200.00,
                    booking__c = bkg1.id,
                    Account_Name__c = acct.id,
                    Impacts_Commission__c = TRUE,
                    Effective_Date__c = System.Today().addDays(-5) 
                );
            insert prfCcrForOriginalBli1;
            
            originalBLIs.add(new Booking_Line_Item__c(
                Booking__c = bkg1.id,
                //CCR__c = prfCcrForOriginalBli.Id, 
                Total_Price__c = 200.0, 
                New_Expansion_TCV__c = 100.0,
                Subsumed_Renewal_TCV__c = 50.0,
                Gross_ACV_Amount__c = 40.0,
                Gross_New_Expansion_ACV__c = 25.0,
                Gross_Subsumed_Renewal_ACV__c = 15.0,
                Impacts_Gross_Bookings__c = true,
                Impacts_Net_Bookings__c = true,
                Impacts_Commission__c = true,
                Type__c = 'Partner Referral Fee'
            ));
            
            originalBLIs.add(new Booking_Line_Item__c(
                Booking__c = bkg0.id,
                Total_Price__c = 1000.0, 
                Rebate__c = 10.0,
                Impacts_Gross_Bookings__c = true,
                Impacts_Net_Bookings__c = true,
                Impacts_Commission__c = true,
                Type__c = 'Distributor Fee'
            ));
            
            originalBLIs.add(new Booking_Line_Item__c(
                Booking__c = bkg0.id,
                Total_Price__c = 1000.0, 
                Rebate__c = 10.0,
                Impacts_Gross_Bookings__c = true,
                Impacts_Net_Bookings__c = true,
                Impacts_Commission__c = true,
                Type__c = 'Partner Referral Fee'
            ));
            insert originalBLIs;
            Booking_Line_Item__c nbli1 = new Booking_Line_Item__c(
                Booking__c = bkg0.id,
                Total_Price__c = 1000.0, 
                Rebate__c = 10.0,
                Impacts_Gross_Bookings__c = true,
                Impacts_Net_Bookings__c = true,
                Impacts_Commission__c = true,
                Type__c = 'Partner Referral Fee'
            );
            CreateBLIorBLIwithBooking.bliTobeInserted.add(nbli1);
            
            CreateBLIorBLIwithBooking.mapCCROppIdToOriginalPRF.put(bkg0.Opportunity__c,originalBLIs[0] );
                
            CreateBLIorBLIwithBooking.mapBookingIdToOppId.put(bkg0.id, bkg0.Opportunity__c);
            List<CCR__c> ccrsToProcess = new List<CCR__c>();
            
            // CCR for Distributor Fee scenario
            CCR__c distFeeDebookingCcr = new CCR__C(
                Comment__c = 'Distributor Fee Debooking Trigger',
                Opportunity__c = opp0.id,
                AssignmentStatus__c = 'Unassigned',
                User__c = 'Pending',
                CCR_Type__c = 'Change in Booking Policy / De-Risk Decision',    
                Amount__c = 50, 
                booking__c = bkg0.id, 
                Account_Name__c = acct.id,
                Impacts_Commission__c = TRUE,
                Effective_Date__c = System.Today(),
                Customer_Returns_Type__c = 'AmountItem Based'
            );
            ccrsToProcess.add(distFeeDebookingCcr);   
            
            // CCR for Partner Referral Fee debooking
            CCR__c prfDebookingCcr = new CCR__C(
                Comment__c = 'Partner Referral Fee Debooking Trigger',
                Opportunity__c = opp1.id,
                AssignmentStatus__c = 'Unassigned',
                User__c = 'Pending',
                CCR_Type__c = 'Partner Referral Fee',    
                Referral_Fee_Amount__c = 100, 
                booking__c = bkg1.id, 
                Account_Name__c = acct.id,
                Impacts_Commission__c = TRUE,
                Effective_Date__c = System.Today()
            );
            ccrsToProcess.add(prfDebookingCcr);   
            insert ccrsToProcess;
            
            CreateBLIorBLIwithBooking.createBLIorBLIwithBkg(ccrsToProcess);
            System.assert(ccrsToProcess.size() > 0);
        }
        test.stopTest();
    }
    
    @isTest
    static void testPartnerReferralFeeBLIUpdate() {
        test.startTest();
        User usr = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        System.runAs(usr) {
            // Get existing test data
            Booking__c originalBooking = [SELECT Id, Account_Name__c, Opportunity__c FROM Booking__c 
                                          WHERE RecordType.Name = 'Booking' AND Order__r.Order_Status__c != 'Order Accepted'
                                          LIMIT 1];
            
            // Create original PRF CCR and BLI (simulates initial referral fee booking)
            CCR__c originalPRFCCR = new CCR__C(
                Comment__c = 'Original PRF',
                Opportunity__c = originalBooking.Opportunity__c,
                AssignmentStatus__c = 'Assigned',
                User__c = 'Pending',
                CCR_Type__c = 'Partner Referral Fee',
                Referral_Fee_Amount__c = 100,
                booking__c = originalBooking.Id,
                Account_Name__c = originalBooking.Account_Name__c,
                Impacts_Commission__c = true
            );
            insert originalPRFCCR;
            originalPRFCCR.User__c =  'Approved';
            update originalPRFCCR;
            
            // Create original PRF BLI with known values
            Booking_Line_Item__c originalPRFBLI = new Booking_Line_Item__c(
                Booking__c = originalBooking.Id,
                //CCR__c = originalPRFCCR.Id,
                Type__c = 'Partner Referral Fee',
                Total_Price__c = 100,
                New_Expansion_TCV__c = 60,
                Subsumed_Renewal_TCV__c = 40,
                Gross_ACV_Amount__c = 50,
                Gross_New_Expansion_ACV__c = 30,
                Gross_Subsumed_Renewal_ACV__c = 20
            );
            insert originalPRFBLI;
            
            // Execute the processing
            CreateBLIorBLIwithBooking.createBLIorBLIwithBkg(new List<CCR__c>{originalPRFCCR});
            
            List<Booking_Line_Item__c> bkl = [Select Id,Type__c From Booking_Line_Item__c Where CCR__c =: originalPRFCCR.Id  LIMIT 1];
            System.assert(bkl.size() == 0);
        }
        test.stopTest();
    }

     @isTest
    static void testUnPaidReplacement() {
        test.startTest();
        User usr = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        System.runAs(usr) {
            // Get existing test data
            Booking__c originalBooking = [SELECT Id, Account_Name__c, Opportunity__c FROM Booking__c 
                                          WHERE RecordType.Name = 'Booking' AND Order__r.Order_Status__c != 'Order Accepted'
                                          LIMIT 1];
            List<Booking_Line_Item__c> lstBLI = [Select Id, Type__c  From Booking_Line_Item__c Where Booking__c = : originalBooking.Id];
            lstBLI[0].Type__c = 'Revenue';
            update lstBLI;
            CCR__c ccrReplacement = new CCR__C(
                Comment__c = 'ccrReplacement',
                Opportunity__c = originalBooking.Opportunity__c,
                AssignmentStatus__c = 'Unassigned',
                Customer_Returns_Type__c = 'Amount Based',
                User__c = 'Pending',
                CCR_Type__c = 'Unpaid Replacement Debooking',
                Amount__c = 100,
                booking__c = originalBooking.Id,
                Account_Name__c = originalBooking.Account_Name__c,
                Impacts_Commission__c = true
            );
            insert ccrReplacement;
            ccrReplacement.User__c =  'Approved';
            update ccrReplacement;
            
            // Execute the processing
            CreateBLIorBLIwithBooking.createBLIorBLIwithBkg(new List<CCR__c>{ccrReplacement});
            
            List<Booking_Line_Item__c> bkl = [Select Id,Type__c From Booking_Line_Item__c Where CCR__c =: ccrReplacement.Id  LIMIT 1];
            System.assert(bkl.size() != 0);
            CCR__c ccrMisQuote = [Select id, Amount__c, CCR_Type__c, Account_Name__c, Opportunity__c, booking__c, AssignmentStatus__c from CCR__c where CCR_Type__c = 'Unpaid Replacement Debooking' limit 1];
            ccrMisQuote.CCR_Type__c = 'Incorrect Order/Mis-quote';
            update ccrMisQuote;
            try{
            CreateBLIorBLIwithBooking.createBLIorBLIwithBkg(new List<CCR__c>{ccrMisQuote});
            }Catch(Exception ex){
                System.assert(ex != null);
            }
            
            CCR__c ccrNonPayment = [Select id, Amount__c, CCR_Type__c, Account_Name__c, Opportunity__c, booking__c, AssignmentStatus__c from CCR__c where CCR_Type__c = 'Incorrect Order/Mis-quote' limit 1];
            ccrNonPayment.CCR_Type__c = 'Non-Payment';
            update ccrNonPayment;
            try{
            CreateBLIorBLIwithBooking.createBLIorBLIwithBkg(new List<CCR__c>{ccrNonPayment});
            }Catch(Exception ex){
                System.assert(ex != null);
            }


        }
        test.stopTest();
    }

    
}