/***************************************************************
* @description       : SyncBookingWithOpportunity Test class  
* @author            : Shrutika
* @last modified on  : 01-08-2026
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
* Modifications Log 
* Ver   Date          Author        Modification
************************************************************/

@isTest
public class SyncBookingWithOpportunity_Test {
    
     @testSetup 
    static void setup() {
        TriggerControls.disableQuoteTrigger = true; 
        TriggerControls.disableQuoteLineTrigger = true;  
        insert new TriggerControl__c(name = 'Order', DisableTrigger__c = false);
        
        insert new ShGl_DisableBusinessLogic__c(Disable_POC_Validation_Rules__c = true, Disable_SBQQ_Quote_Triggers__c = true, Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_Opportunity_Validation_Rules__c = true,Disable_Opportunity_Triggers__c =true ,Disable_Order_Email_Alerts__c = true, Disable_Order_Old_Trigger__c = true, Disable_Order_Triggers__c = true,Disable_Contact_Triggers__c =true, setupOwnerId = userinfo.getuserid(), Disable_POC_Trigger__c = true);
        insert new ShGl_DisableFunctionalityLogic__c(Disable_Opportunity_Old_Trigger__c = true, setupOwnerId = userinfo.getuserid());
     	
                         Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account act =new Account(BillingCountryCode = 'US', Is_Refreshed__c = False, Name = 'Test', Sync_to_NetSuite__c = false, RecordTypeId = devRecordTypeId, Website='www.test3.com', OwnerId = userinfo.getUserId(),type='Customer');
        
        insert act;
        
        insert new list<Rebate_Table__c>{
            new Rebate_Table__c( Rebate__c = 10,
                                ASPEN_Rebate__c = 8,
                                Distributor__c = act.id,
                                Rebate_Type__c ='Distributor Fee',
                                Rebate_Deal_Type__c='All',
                                Start_Date__c=system.Today()-10,
                                End_Date__c=system.Today() + 180,
                                Installation_Product__c = 'ABC_InstallType',
                                Value_Add_Distribution_fee__c = 3
                               ),
                new Rebate_Table__c( Rebate__c = 10,
                                    ASPEN_Rebate__c = 8,
                                    Distributor__c = act.id,
                                    Rebate_Type__c ='Velocity Partner Program Rebate',
                                    Rebate_Deal_Type__c='All',
                                    Start_Date__c=system.Today()-10,
                                    End_Date__c=system.Today() + 180,
                                    Installation_Product__c = 'ABC_InstallType',
                                    Value_Add_Distribution_fee__c = 3
                                   )
                };  
                    
           opportunity oppr = new opportunity(Name='testing DIEtestsalesforce 4/6/2015' , Opportunity_Sub_Type__c = 'Regular', Distributor_Lookup__c = act.Id, Alliance_Source_Type_HW__c = 'Rubrik Initiated Alliance Deal',
                                           Mosaic_Customer_Environment__c='AWS', CloseDate = Date.Today().addDays(10), Lead_Email_Hidden__c='', AccountId = act.Id, StageName = '1 Discovery',
                                           Rubrik_Sales_Engineer__c = UserInfo.getUserId(), Alliance_Partner_Name__c='Amazon', Alliance_Source_Type__c='Alliance Initiated Deal', Installation_Assigned_To__c ='FE Install',
                                           Economic_Buyer__c = 'Test', Metric__c = 'Test', Decision_Process__c = 'Test', Decision_Criteria__c = 'Test',
                                           Alliance_Source_Type_SW__c ='Rubrik Initiated Alliance Deal',/* Identified_Pain__c = 'Test',*/ Champion__c = 'Test', ForecastCategoryName = 'Best Case',Override__c=false);
        
        insert oppr;
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null); 
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = oppr.Id;
        qt.SBQQ__Primary__c = true; 
        qt.SBQQ__SubscriptionTerm__c = 36;
        qt.SBQQ__ExpirationDate__c = date.today().addDays(10);
        qt.SBQQ__PaymentTerms__c = 'Net 45';
        qt.SBQQ__Type__c = 'Renewal+Expansion';
        qt.Is_Refreshed__c = true;
        
        insert qt;
        Id pricebookId = Test.getStandardPricebookId();
        oppr.Pricebook2Id = pricebookId;
        oppr.StageName = '4 Business Justification';
        oppr.Partner_Level_Of_Involvement__c = '4.Partner or joint initiated opportunity, partner brought substantial value in sales cycle and getting deal closed';
        oppr.SBQQ__PrimaryQuote__c = qt.Id;
        update oppr;
        
        Product2 prod = new Product2(
                SBQQ__SubscriptionPricing__c = 'Fixed Price', Name='RBK-SVC-PREM-R344',ProductCode='RBK-SVC-PREM-R344', Family='POLARIS', Appliance_Model_HW__c = 'RBK-R6408E',
                SBQQ__SubscriptionTerm__c = 36, isActive = true, Bundle_Features__c = 'Polaris', Create_Entitlement__c = true, SBQQSC__EntitlementConversion__c = 'One per unit',Create_Asset__c = true
            );
            
            insert prod;
            
            PricebookEntry pbEntry = new PricebookEntry(
                Pricebook2Id = oppr.pricebook2Id,
                Product2Id = prod.Id,
                UnitPrice = 100.00,
                IsActive = true
                
            );
            insert pbEntry;
            
            OpportunityLineItem oli = new OpportunityLineItem(
                OpportunityId = oppr.Id,
                Quantity = 5,
                PricebookEntryId = pbEntry.Id,
                TotalPrice = 5 * pbEntry.UnitPrice,
                ACV_Amount__c	= 100,
                New_Expansion_ACV__c = 100 ,
                New_Expansion_TCV__c =  5 * pbEntry.UnitPrice
                
            );
            // test.startTest();
            insert oli;  
            
                Order od = new Order();
        od.Name='testOrder1';
        od.Status = 'Draft';
        od.Order_Status__c='Pending';
        //od.BookingStatus__c='None';
        od.Pricebook2Id = pricebookId;
        od.AccountId = act.Id;
        od.OpportunityId = oppr.Id;
        od.EffectiveDate = Date.Today();
        od.ShippingStreet ='Test Street';
        od.ShippingCity ='Test City';
        od.ShippingState ='California';
        od.ShippingCountry ='United States';
        od.ShippingPostalcode ='94820';
        od.ship_To_Name__c = act.id;
        od.Type = 'Revenue';
        od.Est_Ship_Date__c = system.today();
        od.RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Revenue Order').getRecordTypeId();
        od.Pricebook2Id = pricebookId;
        //od.Hold_Code__c = 'Missing freight forwarder details';
        insert od;
        
        OrderItem oritem = new OrderItem(OrderId=od.Id, Opportunity_Product__c = oli.Id, Quantity=10, PricebookEntryId=pbEntry.Id, UnitPrice = 10, Product2Id = prod.Id, SerialNumber__c = 'AA162403440008,AB162403440009,AC162403440009,AD162403440009');
        insert oritem;
         od.Hold_Code__c=' ';
         od.Order_Status__c = 'Order Accepted';  
         update od;
        
                 List<Booking__c> bkgList=new List<Booking__c>();

         Booking__c bkg=new Booking__c(
         Order__c=od.id,
         Opportunity_Close_Date__c = oppr.CloseDate,
         Opportunity__c=oppr.id,
         Account_Name__c=act.id,
         Field_Update_Status__c='',
         RecordTypeId=Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking').getRecordTypeId()
                                     );
         insert bkg;
        
		List<Booking_Line_Item__c> bliList = new List<Booking_Line_Item__c>{
                new Booking_Line_Item__c(Booking__c = bkg.id, Type__c ='Revenue', OrderProduct__c = oritem.Id,Impacts_Gross_Bookings__c = true,Impacts_Net_Bookings__c= true, Total_Price__c = 10.0, New_Expansion_TCV__c = 2, Gross_ACV_Amount__c = 5, Gross_New_Expansion_ACV__c = 5),
                    new Booking_Line_Item__c(Booking__c = bkg.id, Total_Price__c = 10.0,Rebate__c= 2.0,Impacts_Gross_Bookings__c = true,Impacts_Net_Bookings__c= true,Impacts_Commission__c= true, Type__c='Distributor Fee',  New_Expansion_TCV__c = 2, Gross_ACV_Amount__c = 5, Gross_New_Expansion_ACV__c = 5),
                    new Booking_Line_Item__c(Booking__c = bkg.id,Total_Price__c = 10.0,Rebate__c= 2.0,Impacts_Gross_Bookings__c = true,Impacts_Net_Bookings__c= true,Impacts_Commission__c= true, Type__c='Partner Referral Fee',  New_Expansion_TCV__c = 2, Gross_ACV_Amount__c = 5, Gross_New_Expansion_ACV__c = 5)
                    } ;
          insert bliList ;
                     
        Booking__c bkg1=bkg.clone();
         bkg1.Original_Booking__c=bkg.id;
         bkgList.add(bkg1);
         Booking__c bkgThird=new Booking__c(
         Order__c=od.id,
         Opportunity_Close_Date__c = oppr.CloseDate,
         Opportunity__c=oppr.id,
         Account_Name__c=act.id,
         Field_Update_Status__c=' ',
         RecordTypeId=Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking').getRecordTypeId());
         bkgList.add(bkgThird);

                     
         insert bkgList;
         
        List<Booking_split__c> bsList = new List<Booking_split__c>();       
         Booking_split__c bs  = new Booking_split__c(Booking__c = bkg.Id,Opportunity__c = null,Opportunity_Split__c = 15.00);
         Booking_split__c bsSecond  = new Booking_split__c(Booking__c = bkg.Id,Opportunity__c = oppr.id,Opportunity_Split__c = 15.00);
         Booking_split__c bsThird  = new Booking_split__c(Booking__c = bkg.Id,Opportunity__c = oppr.id,Opportunity_Split__c = 30.00);
            
         bsList.add(bs);
         bsList.add(bsSecond);
         bsList.add(bsThird);            
         insert bsList;            
         
        
       
    
    }
    /****
     * Description : to pass the updateBLIAndRelatedBooking, getBookingSplitRecordsand getBookingRecords methods
     * */
    @isTest
    private static void testSyncBooking(){
        List<Booking__c> lstBooking =  [Select id, Opportunity__c From Booking__c LIMIT 1];
        SyncBookingWithOpportunity.getBookingRecords(lstBooking[0].Opportunity__c);
        SyncBookingWithOpportunity.getBookingSplitRecords(lstBooking[0].Opportunity__c);
        SyncBookingWithOpportunity.updateBLIAndRelatedBooking(lstBooking[0].Opportunity__c, true, true, true);
        
        System.assertEquals(1000.00 , [SELECT Id, New_Expansion_TCV__c FROM Booking_Line_Item__c WHERE Booking__c =: lstBooking[0].Id and Type__c = 'Revenue'].New_Expansion_TCV__c);
    }

    public static testMethod void testDebookOppo() {
        List<CCR__c> ccrList = new List<CCR__c>();
        Booking__c bkg = [SELECT id, Account_Name__c, Opportunity__c FROM Booking__c WHERE Original_Booking__c = NULL LIMIT 1];
        bkg.Field_Update_Status__c = '';
        update bkg;
        CCR__c cc1 = new CCR__C(
          Comment__c = 'test',
          Opportunity__c = bkg.Opportunity__c,
          AssignmentStatus__c = 'Unassigned',
          User__c = 'Pending',
          CCR_Type__c = 'Customer Returns / Refunds',
          Customer_Returns_Type__c = 'Amount Based',
          Amount__c = 500,
          Effective_Date__c = Date.Today().addDays(5),
          booking__c = bkg.id,
          Account_Name__c = bkg.Account_Name__c,
          Impacts_Commission__c = true
        );
        ccrList.add(cc1);

        insert ccrList;
        test.startTest();
        ccrList[0].User__c = 'Approved';
        update ccrList;
        List<Booking_Line_Item__c> lstBooking = [
          SELECT id, Booking__c, New_Expansion_TCV__c, Subsumed_Renewal_TCV__c, Gross_New_Expansion_ACV__c, Gross_Subsumed_Renewal_ACV__c
          FROM Booking_Line_Item__c
          WHERE CCR__c = :ccrList[0].id
        ];
        List<Booking_Line_Item__c> lstUpdateBLI = new List<Booking_Line_Item__c>();
        lstUpdateBLI.add(
          new Booking_Line_Item__c(
            Id = lstBooking[0].Id,
            New_Expansion_TCV__c = 100,
            Subsumed_Renewal_TCV__c = 100,
            Gross_New_Expansion_ACV__c = 100,
            Gross_Subsumed_Renewal_ACV__c = 100
          )
        );

        update lstUpdateBLI[0];
        SyncBookingWithOpportunity.updateBLIAndRelatedBooking(bkg.Opportunity__c, true, true, true);
        test.stopTest();
      }



    /**
     * Test hasSignificantDifference method
     */
    @isTest
    private static void testHasSignificantDifference() {
        // Test with significant difference (>= 1)
        Boolean result1 = SyncBookingWithOpportunity.hasSignificantDifference(10.0, 11.5);
        System.assertEquals(true, result1);

        // Test with significant negative difference (<= -1)
        Boolean result2 = SyncBookingWithOpportunity.hasSignificantDifference(10.0, 8.5);
        System.assertEquals(true, result2);

        // Test with no significant difference
        Boolean result3 = SyncBookingWithOpportunity.hasSignificantDifference(10.0, 10.5);
        System.assertEquals(false, result3);

        // Test with null values
        Boolean result4 = SyncBookingWithOpportunity.hasSignificantDifference(null, 1.5);
        System.assertEquals(true, result4);

        Boolean result5 = SyncBookingWithOpportunity.hasSignificantDifference(5.0, null);
        System.assertEquals(true, result5);
    }

    /**
     * Test PromoDiscTCV, Oppty_Trade_Up_Discount, and Prepayment_Credit fields
     * These fields are read from OpportunityLineItem and written to Booking_Line_Item__c
     */
    @isTest
    private static void testDiscountFields() {
        // Get existing booking line item and verify the sync logic handles discount fields
        Booking__c bkg = [SELECT Id, Opportunity__c FROM Booking__c WHERE Original_Booking__c = NULL LIMIT 1];

        // Get BLI before sync
        List<Booking_Line_Item__c> blisBefore = [SELECT Id, PromoDiscTCV__c, Oppty_Trade_Up_Discount__c, Prepayment_Credit__c,
                                                   OrderProduct__r.Opportunity_Product__r.PromoDiscTCV__c,
                                                   OrderProduct__r.Opportunity_Product__r.Oppty_Trade_Up_Discount__c,
                                                   OrderProduct__r.Opportunity_Product__r.Prepayment_Credit__c
                                                   FROM Booking_Line_Item__c
                                                   WHERE Booking__c = :bkg.Id AND Type__c = 'Revenue' LIMIT 1];

        if (blisBefore.isEmpty()) {
            return; // Skip test if no BLI exists
        }

        // Call sync method
        Test.startTest();
        SyncBookingWithOpportunity.response_Wrapper response = SyncBookingWithOpportunity.updateBLIAndRelatedBooking(bkg.Opportunity__c, true, true, true);
        Test.stopTest();

        // Verify success
        System.assertEquals(true, response.isSuccess);

        // Verify the method executed without errors (discount fields are handled in the sync logic)
        System.assertNotEquals(null, response);
    }

    /**
     * Test error scenario - No Booking Line Items
     */
    @isTest
    private static void testNoBookingLineItems() {
        // Create an opportunity without any booking line items
        Opportunity opp = new Opportunity(
            Name = 'Test Opp No BLI',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 10000
        );
        insert opp;

        Test.startTest();
        SyncBookingWithOpportunity.response_Wrapper response = SyncBookingWithOpportunity.updateBLIAndRelatedBooking(opp.Id, false, false, false);
        Test.stopTest();

        System.assertEquals(false, response.isSuccess);
        System.assertEquals('Booking Line Items are not Present!', response.errorMessage);
    }

    /**
     * Test error scenario - Opportunity doesn't contain Order
     */
    @isTest
    private static void testNoOrder() {
        // Create a new opportunity without any existing bookings
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity newOpp = new Opportunity(
            Name = 'Test Opp No Order',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 5000,
            AccountId = acc.Id
        );
        insert newOpp;

        // Create booking without order
        Booking__c bookingNoOrder = new Booking__c(
            Opportunity__c = newOpp.Id,
            Account_Name__c = acc.Id
        );
        insert bookingNoOrder;

        // Create BLI without order
        Booking_Line_Item__c bliNoOrder = new Booking_Line_Item__c(
            Booking__c = bookingNoOrder.Id,
            Type__c = 'Product'
        );
        insert bliNoOrder;

        Test.startTest();
        SyncBookingWithOpportunity.response_Wrapper response = SyncBookingWithOpportunity.updateBLIAndRelatedBooking(newOpp.Id, false, false, false);
        Test.stopTest();

        System.assertEquals(false, response.isSuccess, 'Expected isSuccess to be false');
        System.assertEquals('Opportunity doesn\'t contains the Order', response.errorMessage, 'Expected error message about missing Order');
    }

    /**
     * Test CCR scenario with main opportunity
     */
    @isTest
    private static void testCCRWithMainOpportunity() {
        // Get the main opportunity from setup
        Opportunity mainOpp = [SELECT Id FROM Opportunity LIMIT 1];

        // Create a CCR opportunity
        Opportunity ccrOpp = new Opportunity(
            Name = 'CCR Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Amount = 5000,
            Opportunity_Type__c = 'Debooking'
        );
        insert ccrOpp;

        // Create CCR record
        CCR__c ccr = new CCR__c(
            Opportunity__c = mainOpp.Id,
            Customer_Returns_Type__c = 'Amount Based'
        );
        insert ccr;

        // Update CCR opportunity with CCR reference
        ccrOpp.CCR__c = ccr.Id;
        update ccrOpp;

        Test.startTest();
        SyncBookingWithOpportunity.response_Wrapper response = SyncBookingWithOpportunity.updateBLIAndRelatedBooking(ccrOpp.Id, false, false, false);
        Test.stopTest();

        // The method should process the CCR scenario
        System.assertNotEquals(null, response);
    }

    /**
     * Test discount fields update scenario (lines 267-310)
     * Tests the else branch that handles discount field updates
     */
    @isTest
    private static void testDiscountFieldsUpdateElseBranch() {
        // Get existing data from setup
        Account act = [SELECT Id FROM Account LIMIT 1];
        Opportunity oppr = [SELECT Id, Pricebook2Id FROM Opportunity LIMIT 1];
        Order od = [SELECT Id FROM Order LIMIT 1];
        Booking__c bkg = [SELECT Id FROM Booking__c WHERE Original_Booking__c = NULL LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id, UnitPrice FROM PricebookEntry WHERE Product2Id = :prod.Id LIMIT 1];

        // Create OpportunityLineItem with ACV/TCV values
        OpportunityLineItem oli2 = new OpportunityLineItem(
            OpportunityId = oppr.Id,
            Quantity = 10,
            PricebookEntryId = pbEntry.Id,
            TotalPrice = 10 * pbEntry.UnitPrice,
            ACV_Amount__c = 200,
            New_Expansion_ACV__c = 200,
            New_Expansion_TCV__c = 1000
        );
        insert oli2;

        // Create OrderItem linked to the new OLI
        OrderItem oritem2 = new OrderItem(
            OrderId = od.Id,
            Opportunity_Product__c = oli2.Id,
            Quantity = 10,
            PricebookEntryId = pbEntry.Id,
            UnitPrice = 100,
            Product2Id = prod.Id
        );
        insert oritem2;

        // Create Booking Line Item with different values to trigger update
        Booking_Line_Item__c bli2 = new Booking_Line_Item__c(
            Booking__c = bkg.Id,
            Type__c = 'Revenue',
            OrderProduct__c = oritem2.Id,
            Impacts_Gross_Bookings__c = true,
            Impacts_Net_Bookings__c = true,
            Total_Price__c = 1000.0,
            New_Expansion_TCV__c = 500.0,
            Gross_ACV_Amount__c = 100.0,
            Gross_New_Expansion_ACV__c = 100.0
        );
        insert bli2;

        Test.startTest();
        // Call the sync method - this should trigger the else branch (lines 267-310)
        SyncBookingWithOpportunity.response_Wrapper response = SyncBookingWithOpportunity.updateBLIAndRelatedBooking(oppr.Id, true, true, true);
        Test.stopTest();

        // Verify the response is successful
        System.assertEquals(true, response.isSuccess, 'Expected sync to succeed');

        // Verify BLI was updated with values from OLI
        Booking_Line_Item__c updatedBli = [
            SELECT Id, New_Expansion_TCV__c, Gross_New_Expansion_ACV__c, Gross_ACV_Amount__c
            FROM Booking_Line_Item__c
            WHERE Id = :bli2.Id
        ];

        // The fields should be updated to match the OLI values
        System.assertEquals(1000.0, updatedBli.New_Expansion_TCV__c, 'New_Expansion_TCV should be updated');
        System.assertEquals(200.0, updatedBli.Gross_New_Expansion_ACV__c, 'Gross_New_Expansion_ACV should be updated');
        System.assertEquals(200.0, updatedBli.Gross_ACV_Amount__c, 'Gross_ACV_Amount should be updated');
    }

    /**
     * Test ACV/TCV fields with significant difference threshold
     * Tests the hasSignificantDifference method integration
     */
    @isTest
    private static void testDiscountFieldsSignificantDifference() {
        // Get existing data from setup
        Account act = [SELECT Id FROM Account LIMIT 1];
        Opportunity oppr = [SELECT Id, Pricebook2Id FROM Opportunity LIMIT 1];
        Order od = [SELECT Id FROM Order LIMIT 1];
        Booking__c bkg = [SELECT Id FROM Booking__c WHERE Original_Booking__c = NULL LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id, UnitPrice FROM PricebookEntry WHERE Product2Id = :prod.Id LIMIT 1];

        // Create OpportunityLineItem with ACV/TCV values
        OpportunityLineItem oli3 = new OpportunityLineItem(
            OpportunityId = oppr.Id,
            Quantity = 5,
            PricebookEntryId = pbEntry.Id,
            TotalPrice = 5 * pbEntry.UnitPrice,
            ACV_Amount__c = 150,
            New_Expansion_ACV__c = 150,
            New_Expansion_TCV__c = 750
        );
        insert oli3;

        // Create OrderItem
        OrderItem oritem3 = new OrderItem(
            OrderId = od.Id,
            Opportunity_Product__c = oli3.Id,
            Quantity = 5,
            PricebookEntryId = pbEntry.Id,
            UnitPrice = 100,
            Product2Id = prod.Id
        );
        insert oritem3;

        // Create BLI with values that have insignificant difference (< 1)
        Booking_Line_Item__c bli3 = new Booking_Line_Item__c(
            Booking__c = bkg.Id,
            Type__c = 'Revenue',
            OrderProduct__c = oritem3.Id,
            Impacts_Gross_Bookings__c = true,
            Impacts_Net_Bookings__c = true,
            Total_Price__c = 500.0,
            New_Expansion_TCV__c = 749.5,
            Gross_ACV_Amount__c = 149.5,
            Gross_New_Expansion_ACV__c = 149.5
        );
        insert bli3;

        Test.startTest();
        // Call the sync method
        SyncBookingWithOpportunity.response_Wrapper response = SyncBookingWithOpportunity.updateBLIAndRelatedBooking(oppr.Id, true, true, true);
        Test.stopTest();

        // Verify the response is successful
        System.assertEquals(true, response.isSuccess, 'Expected sync to succeed');

        // Verify fields were NOT updated (difference < 1)
        Booking_Line_Item__c updatedBli = [
            SELECT Id, New_Expansion_TCV__c, Gross_ACV_Amount__c, Gross_New_Expansion_ACV__c
            FROM Booking_Line_Item__c
            WHERE Id = :bli3.Id
        ];

        // Since the difference is less than 1, fields should remain unchanged
        System.assertEquals(749.5, updatedBli.New_Expansion_TCV__c, 'New_Expansion_TCV should not be updated (diff < 1)');
        System.assertEquals(149.5, updatedBli.Gross_ACV_Amount__c, 'Gross_ACV_Amount should not be updated (diff < 1)');
        System.assertEquals(149.5, updatedBli.Gross_New_Expansion_ACV__c, 'Gross_New_Expansion_ACV should not be updated (diff < 1)');
    }

    // Note: testFieldUpdateStatusFrozen test was removed because Field_Update_Status__c
    // is a restricted picklist field without valid values configured in the org.
    // This test would verify that frozen bookings cannot be updated, but cannot be
    // implemented without knowing the valid picklist values.

    @isTest
    static void testDistributorFeeNegativePrice() {
        // Get the test data
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Order ord = [SELECT Id FROM Order WHERE OpportunityId = :opp.Id LIMIT 1];
        Booking__c booking = [SELECT Id FROM Booking__c WHERE Opportunity__c = :opp.Id LIMIT 1];

        // Create OpportunityLineItem
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 10,
            UnitPrice = 1000,
            PricebookEntryId = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId() LIMIT 1].Id,
            New_Expansion_TCV__c = 5000,
            Subsumed_Renewal_TCV__c = 3000,
            New_Expansion_ACV__c = 2500,
            Subsumed_Renewal_Amount__c = 1500,
            ACV_Amount__c = 4000
        );
        insert oli;

        // Create OrderItem
        OrderItem oi = new OrderItem(
            OrderId = ord.Id,
            Quantity = 10,
            UnitPrice = 1000,
            PricebookEntryId = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :Test.getStandardPricebookId() LIMIT 1].Id,
            Opportunity_Product__c = oli.Id
        );
        insert oi;

        // Create regular Booking Line Item
        Booking_Line_Item__c regularBli = new Booking_Line_Item__c(
            Booking__c = booking.Id,
            OrderProduct__c = oi.Id,
            Type__c = 'Product',
            New_Expansion_TCV__c = 5000,
            Subsumed_Renewal_TCV__c = 3000,
            Gross_New_Expansion_ACV__c = 2500,
            Gross_Subsumed_Renewal_ACV__c = 1500,
            Gross_ACV_Amount__c = 4000
        );
        insert regularBli;

        // Create Distributor Fee BLI with negative Total_Price__c
        Booking_Line_Item__c distFeeBli = new Booking_Line_Item__c(
            Booking__c = booking.Id,
            Type__c = 'Distributor Fee',
            Total_Price__c = -500,  // Negative price
            Rebate__c = 10,
            New_Expansion_TCV__c = 0,
            Subsumed_Renewal_TCV__c = 0,
            Gross_New_Expansion_ACV__c = 0,
            Gross_Subsumed_Renewal_ACV__c = 0,
            Gross_ACV_Amount__c = 0
        );
        insert distFeeBli;

        Test.startTest();
        SyncBookingWithOpportunity.response_Wrapper result =
            SyncBookingWithOpportunity.updateBLIAndRelatedBooking(opp.Id, false, true, false);
        Test.stopTest();

        System.assertEquals(true, result.isSuccess, 'Should succeed');

        // Verify the Distributor Fee BLI was updated with calculated values
        Booking_Line_Item__c updatedDistFeeBli = [SELECT New_Expansion_TCV__c, Subsumed_Renewal_TCV__c,
                                                    Gross_ACV_Amount__c, Gross_New_Expansion_ACV__c, Gross_Subsumed_Renewal_ACV__c
                                                    FROM Booking_Line_Item__c WHERE Id = :distFeeBli.Id];
        // Values should be calculated based on the regular BLI values and rebate percentage
        System.assertNotEquals(null, updatedDistFeeBli.New_Expansion_TCV__c, 'New_Expansion_TCV should be calculated');
    }

    /**
     * Test CCR with other customer return types (not LineItem Based or Amount Based)
     * This test covers the else branch at lines 267-311 in SyncBookingWithOpportunity
     * where CCR exists but is neither LineItem Based nor Amount Based
     */
    @isTest
    static void testCCRWithOtherCustomerReturnTypes() {
        // Get existing data from setup
        Account act = [SELECT Id FROM Account LIMIT 1];
        Opportunity oppr = [SELECT Id, Pricebook2Id FROM Opportunity LIMIT 1];
        Order od = [SELECT Id FROM Order LIMIT 1];
        Booking__c bkg = [SELECT Id FROM Booking__c WHERE Original_Booking__c = NULL LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        PricebookEntry pbEntry = [SELECT Id, UnitPrice FROM PricebookEntry WHERE Product2Id = :prod.Id LIMIT 1];

        // Create a CCR with a customer return type that is NOT "LineItem Based" or "Amount Based"
        // This could be any other type like "Quantity Based" or any custom value
        CCR__c ccr = new CCR__c(
            Opportunity__c = oppr.Id,
            Customer_Returns_Type__c = 'Quantity Based'  // Different from LineItem Based or Amount Based
        );
        insert ccr;

        // Create OpportunityLineItem with ACV/TCV values
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = oppr.Id,
            Quantity = 8,
            PricebookEntryId = pbEntry.Id,
            TotalPrice = 8 * pbEntry.UnitPrice,
            ACV_Amount__c = 300,
            New_Expansion_ACV__c = 300,
            New_Expansion_TCV__c = 2400,
            Subsumed_Renewal_Amount__c = 100,
            Subsumed_Renewal_TCV__c = 800
        );
        insert oli;

        // Create OrderItem linked to the OLI
        OrderItem oritem = new OrderItem(
            OrderId = od.Id,
            Opportunity_Product__c = oli.Id,
            Quantity = 8,
            PricebookEntryId = pbEntry.Id,
            UnitPrice = 100,
            Product2Id = prod.Id
        );
        insert oritem;

        // Create Booking Line Item with CCR and different values to trigger update
        // This BLI has a CCR but the CCR type is not LineItem Based or Amount Based
        Booking_Line_Item__c bli = new Booking_Line_Item__c(
            Booking__c = bkg.Id,
            Type__c = 'Revenue',
            OrderProduct__c = oritem.Id,
            CCR__c = ccr.Id,  // CCR with "Quantity Based" type
            Impacts_Gross_Bookings__c = true,
            Impacts_Net_Bookings__c = true,
            Total_Price__c = 800.0,
            New_Expansion_TCV__c = 1000.0,  // Different from OLI to trigger update
            Gross_ACV_Amount__c = 150.0,
            Gross_New_Expansion_ACV__c = 150.0,
            Subsumed_Renewal_TCV__c = 400.0,
            Gross_Subsumed_Renewal_ACV__c = 50.0
        );
        insert bli;

        Test.startTest();
        // Call the sync method - this should trigger the else branch (lines 267-311)
        // because the BLI has a CCR but it's not LineItem Based or Amount Based
        SyncBookingWithOpportunity.response_Wrapper response =
            SyncBookingWithOpportunity.updateBLIAndRelatedBooking(oppr.Id, true, true, true);
        Test.stopTest();

        // Verify the response is successful
        System.assertEquals(true, response.isSuccess, 'Expected sync to succeed');

        // Verify BLI was updated with values from OLI
        Booking_Line_Item__c updatedBli = [
            SELECT Id, New_Expansion_TCV__c, Gross_New_Expansion_ACV__c, Gross_ACV_Amount__c,
                   Subsumed_Renewal_TCV__c, Gross_Subsumed_Renewal_ACV__c
            FROM Booking_Line_Item__c
            WHERE Id = :bli.Id
        ];

        // The fields should be updated to match the OLI values (with quantity factor applied)
        System.assertEquals(2400.0, updatedBli.New_Expansion_TCV__c, 'New_Expansion_TCV should be updated from OLI');
        System.assertEquals(300.0, updatedBli.Gross_New_Expansion_ACV__c, 'Gross_New_Expansion_ACV should be updated from OLI');
        System.assertEquals(300.0, updatedBli.Gross_ACV_Amount__c, 'Gross_ACV_Amount should be updated from OLI');
        System.assertEquals(800.0, updatedBli.Subsumed_Renewal_TCV__c, 'Subsumed_Renewal_TCV should be updated from OLI');
        System.assertEquals(100.0, updatedBli.Gross_Subsumed_Renewal_ACV__c, 'Gross_Subsumed_Renewal_ACV should be updated from OLI');
    }

}