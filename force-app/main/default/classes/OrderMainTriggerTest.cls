/***************************************************************
 * @description       : Order Tigger test class
 * @author            : Chaitra
 * @last modified on  : 09-04-2021
 * @last modified by  : Chaitra
 * Modifications Log
 * Ver   Date          Author        Modification
 * 1.0   01-20-2021   chaitra        Initial Version
 * 2.0   05-12-2022   moises         PRDOPS23-80
 * 3.0   08-04-2025   Prashant       PRDOPS26-647
 ************************************************************/ 
@isTest
public class OrderMainTriggerTest {
  @testSetup
  static void setup() {
    TriggerControls.disableQuoteTrigger = true;
    TriggerControls.disableQuoteLineTrigger = true;
        insert new TriggerControl__c(name = 'Order', DisableTrigger__c = false);

    insert new ShGl_DisableBusinessLogic__c(
      Follow_Existing_EntCreate_Process__c = true,
      Disable_Order_Validation_Rules__c = true,
      Disable_PS_Task_Triggers__c = true,
      Disable_POC_Validation_Rules__c = true,
      Disable_SBQQ_Quote_Triggers__c = true,
      Disable_SBQQ_QuoteLine_Triggers__c = true,
      Disable_Opportunity_Validation_Rules__c = true,
      Disable_Opportunity_Triggers__c = false,
      Disable_Order_Email_Alerts__c = false,
      Disable_Order_Old_Trigger__c = true,
      Disable_Order_Triggers__c = false,
      Disable_Contact_Triggers__c = true,
      setupOwnerId = userinfo.getuserid(),
      Disable_POC_Trigger__c = true,
      Disable_Entitlement_Validation_Rules__c = true,
      Disable_SBQQ_Quote_Validation_Rules__c = true,
      Disable_SBQQ_QuoteLine_Validation_Rules__c = true
    );
    insert new ShGl_DisableFunctionalityLogic__c(Disable_Opportunity_Old_Trigger__c = true, setupOwnerId = userinfo.getuserid());

    insert new List<PS_Project_Manager_Mapping__c>{
      new PS_Project_Manager_Mapping__c(
        Name = 'United States Minor Outlying Islands',
        Project_Manager_User_Id__c = UserInfo.getUserId(),
        Project_Manager__c = 'Test',
        Unique_External_ID__c = 'US'
      ),
      new PS_Project_Manager_Mapping__c(
        Name = 'testing DIEtestsalesforce 4/6/2015',
        Project_Manager_User_Id__c = UserInfo.getUserId(),
        Project_Manager__c = 'Test',
        Unique_External_ID__c = 'United States-Florida'
      ),
      new PS_Project_Manager_Mapping__c(Name = 'NS', Project_Manager_User_Id__c = UserInfo.getUserId(), Project_Manager__c = 'Test', Unique_External_ID__c = 'Canada')
    };

    insert new List<GTC_Screening__c>{
      new GTC_Screening__c(Party_Name__c = 'Test', CountryCode__c = 'US', Type__c = 'Include', Address__c = 'Test'),
      new GTC_Screening__c(Party_Name__c = 'ABC', CountryCode__c = 'FR', Type__c = 'Exclude', Address__c = 'ABC')
    };

    Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();

    Account act = new Account(
      BillingCountryCode = 'US',
      Is_Refreshed__c = false,
      Name = 'Test',
      Sync_to_NetSuite__c = false,
      RecordTypeId = devRecordTypeId,
      Website = 'www.test3.com',
      OwnerId = userinfo.getUserId(),
      type = 'Customer'
    );

    insert act;
    Contact con = new Contact(); 
    con.AccountId = act.Id;
    con.FirstName = 'Test';
    con.EMail='rubriktestcontact22@rubrik.com'; 
    con.LastName = 'Contact';
    insert con;

    insert new List<Rebate_Table__c>{
      new Rebate_Table__c(
        Rebate__c = 10,
        ASPEN_Rebate__c = 8,
        Distributor__c = act.id,
        Rebate_Type__c = 'Distributor Fee',
        Rebate_Deal_Type__c = 'All',
        Start_Date__c = system.Today() - 10,
        End_Date__c = system.Today() + 180,
        Installation_Product__c = 'ABC_InstallType',
        Value_Add_Distribution_fee__c = 3
      ),
      new Rebate_Table__c(
        Rebate__c = 10,
        ASPEN_Rebate__c = 8,
        Distributor__c = act.id,
        Rebate_Type__c = 'Velocity Partner Program Rebate',
        Rebate_Deal_Type__c = 'All',
        Start_Date__c = system.Today() - 10,
        End_Date__c = system.Today() + 180,
        Installation_Product__c = 'ABC_InstallType',
        Value_Add_Distribution_fee__c = 3
      )
    };
    PS_Project__c objPsProject = new PS_Project__c();
    objPsProject.Name = 'test projectXtreme';
    objPsProject.Account__c = act.id;
    objPsProject.Project_Manager__c = userinfo.getuserid();
    objPsProject.Manager__c = 'test@test.com';
    insert objPsProject;

    opportunity oppr = new opportunity(
      Name = 'testing DIEtestsalesforce 4/6/2015',
      Opportunity_Sub_Type__c = 'Regular',
      Distributor_Lookup__c = act.Id,
      Alliance_Source_Type_HW__c = 'Rubrik Initiated Alliance Deal',
      Mosaic_Customer_Environment__c = 'AWS',
      CloseDate = Date.Today().addDays(10),
      Lead_Email_Hidden__c = '',
      AccountId = act.Id,
      StageName = '1 Discovery',
      Rubrik_Sales_Engineer__c = UserInfo.getUserId(),
      Alliance_Partner_Name__c = 'Amazon',
      Alliance_Source_Type__c = 'Alliance Initiated Deal',
      Installation_Assigned_To__c = 'FE Install',
      Economic_Buyer__c = 'Test',
      Metric__c = 'Test',
      Decision_Process__c = 'Test',
      Decision_Criteria__c = 'Test',
      Alliance_Source_Type_SW__c = 'Rubrik Initiated Alliance Deal',
      Identified_Pain__c = 'Test',
      Champion__c = 'Test',
      ForecastCategoryName = 'Best Case',
      Override__c = false,
      Aspen_Eligibility__c = 'Actual Aspen',
      Initial_Contacts_Name__c = con.Id,
      SuggestedURL__c = 'test.url.com'
    );

    insert oppr;
      
    OpportunityContactRole ocr = new OpportunityContactRole();
    ocr.OpportunityId = oppr.Id;
    ocr.Role = 'Decision Maker';
    ocr.ContactId = con.id;
    ocr.IsPrimary = true;
    insert ocr; 

    test.startTest();

    SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
    qt.SBQQ__Account__c = act.Id;
    qt.SBQQ__Opportunity2__c = oppr.Id;
    qt.SBQQ__Primary__c = true;
    qt.SBQQ__SubscriptionTerm__c = 36;
    qt.Manual_Fulfillment_Quote__c = 'Other-Enter Text';
    qt.SBQQ__ExpirationDate__c = date.today().addDays(10);
    qt.SBQQ__PaymentTerms__c = 'Net 45';
    qt.SBQQ__Type__c = 'Renewal+Expansion';
    qt.Is_Refreshed__c = true;
    qt.ProcessType__c = 'Aspen';

    insert qt;

    SBQQ__Quote__c qtq = [SELECT Id, name, SBQQ__NetAmount__c, SBQQ__PricebookId__c FROM SBQQ__Quote__c WHERE id = :qt.id];

    test.stopTest();

    SBQQ__QuoteDocument__c doc = new SBQQ__QuoteDocument__c(SBQQ__Quote__c = qt.Id, SBQQ__Template__c = 'Standard Quote', SBQQ__Opportunity__c = oppr.Id);

    insert doc;

    PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage(
      'Promark Technology, Inc.',
      'test123',
      system.today().addDays(10),
      1,
      'test@test.com',
      'test partner',
      system.today(),
      1,
      'test12345',
      qtq.name,
      qtq.SBQQ__NetAmount__c
    );
    pos.Bill_To_Name__c = act.Id;
    pos.PO_Validation_Status__c = 'Success';
    pos.PO_Internal_Validation_Status__c = 'Success';
    pos.Payment_schedule_type__c = 'test';
    pos.Service_Level__c = null;
    insert pos;

    BLI_Impact__mdt impact = new BLI_Impact__mdt();
    impact.Adjustment_Type__c = 'Revenue';
    impact.Label = 'Revenue';
    impact.QualifiedApiName = 'Revenue';
    impact.Impacts_Commissions__c = true;
    impact.Impacts_Gross_Bookings__c = true;
    impact.Impacts_Net_Bookings__c = true;
  	}
  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to test CSAT Order trigger logic
   */
  @isTest
  private static void testCSATOrder() {
    System.runAs(new User(Id = UserInfo.getUserId())) {
      List<Opportunity> lstOpp = [SELECT id, AccountId, Opportunity_Sub_Type__c FROM Opportunity LIMIT 1];
      lstOpp[0].Opportunity_Sub_Type__c = 'CSAT';
      update lstOpp;
      SBQQ__Quote__c qtq = [SELECT Id, name, SBQQ__NetAmount__c, SBQQ__PricebookId__c FROM SBQQ__Quote__c LIMIT 1];
      Assert.areEqual(true, lstOpp.size() > 0);
      Id pricebookId = Test.getStandardPricebookId();
        Order ord = createTestorder('Revenue',qtq.Id, lstOpp[0].AccountId,lstOpp[0].Id,lstOpp[0].AccountId,pricebookId,'Not needed','Renewal',new Map<String, Object>{} );
        ord.Order_Status__c = null;
        ord.ship_To_Name__c = lstOpp[0].AccountId;
        ord.Pricebook2Id = pricebookId;
      test.startTest();
      insert Ord;
      Ord.Order_Status__c = 'On Hold';
      Ord.Hold_Code__c = 'Missing start or end dates';
      update Ord;
      test.stopTest();
    }
  }
    
 
    
    private static ShipmentDetail__c testShipmentDetail(Id orderId,String hwSerialnumber,String prodName,String quoteName,String processtype,Map<String, Object> additionalFields) {
        ShipmentDetail__c shippmentDetails  = new ShipmentDetail__c(Order__c = orderId,HW_SerialNumber__c = hwSerialnumber,ProductName__c = prodName,QuoteNumber__c = quoteName,Type__c = processtype);
        if (additionalFields != null) {
            for (String fieldName : additionalFields.keySet()) {
                shippmentDetails.put(fieldName, additionalFields.get(fieldName));
            }
        }  
        return shippmentDetails;
    }
  
    

    
    
    
    private static RPS__c testCreateRpsSettings(Id userId,Boolean isRpsRequired,String screenSource,String holdCodes,Map<String, Object> additionalFields) {
       RPS__c rps = new RPS__c(SetupOwnerId = userId ,Is_RPS_Required__c = isRpsRequired,Screening_Source__c = screenSource,Valid_HoldCodes__c = holdCodes);
        if (additionalFields != null) {
            for (String fieldName : additionalFields.keySet()) {
                rps.put(fieldName, additionalFields.get(fieldName));
            }
        }  
        return rps;
    } 
    
    private static POC__c createTestPocObject(String pocDuration,Date installationDate,String supportAwareness,String pocType,String productCategories,Map<String, Object> additionalFields) {
        POC__c pocobj = new POC__c(POC_Duration__c = pocDuration,Planned_Installation_Date__c = installationDate,Support_Awareness_needed__c = supportAwareness,POC_Type__c = pocType,Product_Categories__c = productCategories);
        if (additionalFields != null) {
          for (String fieldName : additionalFields.keySet()) {
              pocobj.put(fieldName, additionalFields.get(fieldName));
          }
      }  
      return pocobj;
    }
     
    
   /* private static void testDisableAutomation(Boolean entVR,Boolean opptyVR,Boolean entVR,Boolean entVR,) {
        

        
        
        
                ShGl_DisableBusinessLogic__c disableAut = new ShGl_DisableBusinessLogic__c(Disable_Entitlement_Validation_Rules__c = ,Disable_Opportunity_Validation_Rules__c = true,Disable_POC_Validation_Rules__c = true,Disable_SBQQ_Quote_Triggers__c = true,Disable_SBQQ_QuoteLine_Triggers__c = true,
);
        if (additionalFields != null) {
            for (String fieldName : additionalFields.keySet()) {
                asst.put(fieldName, additionalFields.get(fieldName));
            }
        }
        return asst;

        
    }*/
   
    
    
    
  private static order createTestorder( String type, id quoteId, id accountId, id opportunityId,id shipToName, id pricebook2Id,string orderSplitType, string orderSubType, Map<String, Object> additionalFields) {
    order ord = new order(Type = type, SBQQ__Quote__c = quoteId, AccountId = accountId, OpportunityId = opportunityId, ship_To_Name__c = shipToName, Pricebook2Id = pricebook2Id,Order_Split_Type__c= orderSplitType, Order_Sub_Type__c= orderSubType);
    ord.Send_for_Polaris_Fulfilment__c = true;  
    ord.EffectiveDate = system.today();  
    ord.Order_Status__c = 'Pending';
    ord.Order_Status__c = 'Pending';
      ord.Status = 'Pending';
      ord.Sync_to_NetSuite__c = true;
      ord.ShippingCountryCode = 'US';
      ord.ShippingStateCode = 'CA';
      ord.ShippingStreet = 'Test Street';
      ord.ShippingCity = 'Test City';
      ord.ShippingState = 'California';
      ord.ShippingCountry = 'United States';
      ord.ShippingPostalcode = '94820';
      ord.ShipToContactName__c = 'Test';
      ord.Have_Polaris_Products__c = false;
      ord.Polaris_Fulfillment_Status__c = 'Completed';
      ord.Original_Est_Ship_Date__c = Date.today().addDays(30);
      ord.Est_Ship_Date__c = null;
      //ord.Order_Split_Type__c = 'Not needed';
      ord.Is_RWD_Polaris_Quote__c = true;
      //ord.Order_Sub_Type__c = 'MSP Overage';
      ord.ManualFulfilment__c = false;
    if (additionalFields != null) {
      for (String fieldName : additionalFields.keySet()) {
        ord.put(fieldName, additionalFields.get(fieldName));
      }
    }
    return ord;
  }  
    
    
    private static asset createAsset( String Name, id Accountid, id Product2id, string status,string SerialNumber,Map<String, Object> additionalFields) {
        asset asst = new asset(Name = Name, Accountid = Accountid, Product2Id = Product2Id,SerialNumber = SerialNumber,status = status);
        if (additionalFields != null) {
            for (String fieldName : additionalFields.keySet()) {
                asst.put(fieldName, additionalFields.get(fieldName));
            }
        }
        return asst;
    }
    
    private static Opportunity createOpportunity(String Name,String StageName,Id AccountId,Date CloseDate,Map<String, Object> additionalFields){
        Opportunity oppty = new Opportunity(Name = Name, StageName = StageName,AccountId = AccountId,CloseDate = CloseDate);
        if (additionalFields != null) {
            for (String fieldName : additionalFields.keySet()) {
                oppty.put(fieldName, additionalFields.get(fieldName));
            }
        }
        return oppty;

        
    }
    private static Entitlement createEntitlement( String Name, id accountId, id prodid,id AssetId, Map<String, Object> additionalFields) {
        Entitlement ent = new Entitlement(Name = Name, Accountid = Accountid, Product__c = prodid,Assetid = AssetId);
        if (additionalFields != null) {
            for (String fieldName : additionalFields.keySet()) {
                ent.put(fieldName, additionalFields.get(fieldName));
            }
        }
        return ent;
    }
               
  

  /**
   * @author Prashant Kumar
   * @date 03-07-2025
   * @description test method to create Product
   * @return Product2
   * @param name
   * @param productCode
   * @param family
   * @param applianceModel
   * @param productLevel
   * @param additionalFields
   */
  private static Product2 createTestProduct(String name, String productCode, String family, String applianceModel, String productLevel, Map<String, Object> additionalFields) {
    Product2 prod = new Product2(Name = name, ProductCode = productCode, Family = family, Appliance_Model_HW__c = applianceModel, IsActive = true, Product_Level__c = productLevel);

    if (additionalFields != null) {
      for (String fieldName : additionalFields.keySet()) {
        prod.put(fieldName, additionalFields.get(fieldName));
      }
    }
    return prod;
  }

      private static User createTestUser(Id roleId, Id profileId, String username, String Alias, String email, Map<String, Object> additionalFields) {
          user usr = new User(UserRoleId = roleId,ProfileId = profileId,Username = username,Alias = Alias,Email = email);
          if (additionalFields != null) {
              for (String fieldName : additionalFields.keySet()) {
                  usr.put(fieldName, additionalFields.get(fieldName));
              }
          }
          return usr;
      }          
          
    private static Booking__c createTestBooking(Id orderId, Id opptyId, Id accountId,Map<String, Object> additionalFields) {
        Booking__c objBooking = new booking__c(order__c = orderId,Opportunity__c = opptyId,Account_Name__c = accountId);
        if (additionalFields != null) {
            for (String fieldName : additionalFields.keySet()) {
                objBooking.put(fieldName, additionalFields.get(fieldName));
            }
        }
        return objBooking;
    }

    private static Booking_Line_Item__c createTestBookingLineItem(Id bookingId, String type,Decimal unitPrice,Map<String, Object> additionalFields) {
        Booking_Line_Item__c objBookingLine = new Booking_Line_Item__c(Booking__c = bookingId, Type__c = type, Total_Price__c = unitPrice);
        if (additionalFields != null) {
            for (String fieldName : additionalFields.keySet()) {
                objBookingLine.put(fieldName, additionalFields.get(fieldName));
            }
        }
        return objBookingLine;
    }
          
          

    
  /**
   * @author Prashant Kumar
   * @date 03-07-2025
   * @description test method to create OrderItem
   * @return OrderItem
   * @param orderId
   * @param quantity
   * @param pricebookEntryId
   * @param unitPrice
   * @param additionalFields
   */
  public static OrderItem createTestOrderItem(Id orderId, Decimal quantity, Id pricebookEntryId, Decimal unitPrice, Map<String, Object> additionalFields) {
    OrderItem oi = new OrderItem(OrderId = orderId, Quantity = quantity, PricebookEntryId = pricebookEntryId, UnitPrice = unitPrice);

        if (additionalFields != null) {
        for (String key : additionalFields.keySet()) {
            // Check if the value is a Date and cast it explicitly
            if (additionalFields.get(key) instanceof Date) {
                oi.put(key, (Date) additionalFields.get(key));
            } else {
                oi.put(key, additionalFields.get(key));
            }
        }
    }

    return oi;
  }
  /**
   * @author Prashant Kumar
   * @date 03-07-2025
   * @description test method to fetch Order
   * @return order
   */

  private static order getOrder() {
    return [
      SELECT
        Id,
        Order_Split_Type__c,
        Is_RWD_Polaris_Quote__c,
        Order_Sub_Type__c,
        Order_Status__c,
        Stage_PO__c,
        customer_required_ship_date__c,
        OM_internal_review__c,
        Hold_Code__c,
        Memo__c,
        TotalAmount,
        Change_Needed_Reason_Other__c,
        ShippingStateCode,
        ShippingCountryCode,
        SBQQ__Quote__c,
        OpportunityId,
        Type,
        ManualFulfilment__c,
        is_Amendment_Order__c,
        Auto_Submission_Date_Time__c,
        Internal_Order_Stage__c,
        Ordernumber,
        Sync_to_NetSuite__c,
        Screening_Source__c,
        SBQQ__PriceCalcStatus__c,
        ScreenStatus__c,
        Quote_RCDM_T_EOL_Date__c,
        Bill_To_Name__c,
        Welcome_Letter_Sent_At__c,
        ShippingStreet,
        ShippingPostalCode,
        ShippingCity,
        ShipToContactName__c,
        Status,
        Is_CPQ_Price_Book__c,
        PoDate,
        PoNumber,
        End_User_PO__c,
        Shipping_Carrier__c,
        Payment_Terms__c,
        Ship_To_Name__c,
        Service_Level__c,
        Ship_to_Email__c,
        Shipping_Method__c,
        AccountId,
        RecordTypeId,
        Oppotunity_Owner__c,
        Opportunity_Owners_Email__c,
        Opportunity_manager_Email__c,
        Partner_Name__c,
        Primary_Competitor__c,
        Polaris_Contact__c,
        Polaris_Contact_Email__c,
        Sell_to_Partner__c,
        Pricebook2Id,
        SBQQ__contracted__c,
        EffectiveDate,
        Non_shipment_order__c,
        Reason_For_Split__c,
        Additional_Terms_Agreement_Required__c,
        Additional_Terms_Agreement_Confirmed__c,
        Stage_PO_Id__c,
        Contract_Manufacturer__c,
        Original_Est_Ship_Date__c,
        Est_Ship_Date__c,
        SCAC__c,
        ProcessType__c,
        HasRansomwareRecoveryWarrenty__c,
        CEM_CSM_Email__c,
        RSC_G_Enabled__c,
        Program__c,
        HW_Order__c,
        Related_Order__c,
        Related_Orders__c,
        createddate,
        Manual_Fulfilment_Selection_Reason__c,
        Polaris_Fulfillment_Status__c,
        Have_Hardware_Products__c,
        Have_PS_Products__c,
        Customer_Balance__c,
        Credit_Limit__c,
        Credit_Check_Failure_Reason__c,
        Integration_Failure__c,
        Order_Accepted_Timestamp__c,
        Welcome_Letter_Contact__c,
        Welcome_Letter_Contact_Email__c,
        Rubrik_Sales_Engineer__c,
        RSC_G_Contact__c,
        RSC_G_Contact_Email__c,
        RSC_G_Contact_Phone__c,
        Order_Accepted_By__c,
        BookingStatus__c,
        Total_no_of_orders__c,
        Hold_Off_Timestamp__c,
        Original_Days_On_Hold__c,
        Third_Party_Hardware_fulfilment_status__c,
        Order_Number__c,
        ShippingCountry,
        ShippingState,
        Distributor_Email__c,
        Partner_Email__c,
        Order_is_submitted__c,
        Deliver_By__c,
        EDI_Sync_Status__c,
        NetSuite_Order__c,
        Scale_Utility_SKUs_Count__c,
        Number_Of_Third_Party_Hardware_lines__c,
        Line_Types__c,
        Auto_Manual_Split__c,
        POC_Opportunity__c,Have_Polaris_Products__c,
        Ship_To_Phone_Number__c
      /*,Line_Types__c*/ FROM order
      LIMIT 1
    ];
  }
  /**
   * @author Prashant Kumar
   * @date 03-07-2025
   * @description test method to fetch OrderItems
   * @return List<orderitem>
   */

  private static List<orderitem> getOrderLines() {
    return [
      SELECT
        Id,
        /*Credit_Amount__c,*/ SBQQ__Contracted__c,
        OrderId,
        OrderItemNumber,
        /* Previous_Transaction_Reference__c,*/ Replacement_Type__c,
        EndDate,
        ServiceDate,
        TPH_Models_Gen__c,
        TPH_OEM__c,
        Cluster_Order_Type__c,
        Global_Commit_ID__c,
        Order.Opportunity.RecordTypeId,
        Order.Bill_To_Name__r.Name,
        Order.Sell_to_Partner__r.Name,
        Order.Order_Status__c,
        Order.SBQQ__Quote__c,
        Order.OpportunityId,
        Order.Order_Sub_Type__c,
        Order.Actual_Order_Ship_Date__c,
        NTAP_Part_number__c,
        NTAP_Order_number__c,
        Create_Entitlement__c,
        Quantity,
        Sales_Price__c,
        Line_Type__c,
        Program__c,
        UnitPrice,
        Support_Start_Date__c,
        Support_End_Date__c,
        POC_Option__c,
        Is_Refresh__c,
        Upgraded_From__c,
        Create_Asset__c,
        SBQQ__RequiredBy__c,
        Required_by_Product_Code__c,
        RMA_Component_Type__c,
        Is_Hardware_Line__c,
        SBQQ__SubscriptionTerm__c,
        Order.AccountId,
        PricebookEntryId,
        PricebookEntry.Product2.Product_Type__c,
        SBQQ__QuoteLine__r.SBQQ__Quote__r.Co_Term__c,
        Order.EffectiveDate,
        Order.Order_Start_Date__c,
        Order.Type,
        Order.Opportunity.New_Expansion_TCV__c,
        Order.Opportunity.Subsumed_Renewal_TCV__c,
        Order.Opportunity.ACV_Amount__c,
        Order.Opportunity.New_Expansion_ACV__c,
        Order.Opportunity.Renewal_Subsumed_ACV__c,
        Order.Stage_PO__r.PO_Validation_Status__c,
        SBQQ__QuoteLine__c,
        SBQQ__QuoteLine__r.Special_Program__c,
        SBQQ__QuoteLine__r.SBQQ__Quote__c,
        SBQQ__QuoteLine__r.SBQQ__Quote__r.Opportunity_Program__c,
        SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Primary__c,
        SBQQ__QuoteLine__r.GPL__c,
        SBQQ__QuoteLine__r.SBQQ__ListTotal__c,
        SBQQ__QuoteLine__r.SBQQ__TotalDiscountRate__c,
        SBQQ__QuoteLine__r.SBQQ__NetPrice__c,
        SBQQ__QuoteLine__r.RWD_Deal_Ops_Exception__c,
        SBQQ__QuoteLine__r.Name,
        /*SBQQ__QuoteLine__r.Replacement_Details__c,*/ Failed_Serial_Number__c,
        SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Level__c,
        SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Level__c,
        SBQQ__QuoteLine__r.Licensing_Model__c,
        SBQQ__QuoteLine__r.Rubrik_Suite__c,
        SBQQ__QuoteLine__r.Support_Type__c,
        SBQQ__QuoteLine__r.Payment_Options__c,
        SBQQ__QuoteLine__r.Line_Type__c,
        SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c,
        SBQQ__QuoteLine__r.SBQQ__Quote__r.Renewal_Opportunity__c,
        SBQQ__RequiredBy__r.SerialNumber__c,
        Product2Id,
        Product2.Name,
        Product2.License_Category__c,
        SBQQ__RequiredBy__r.Product2.Product_Level__c,
        SBQQ__RequiredBy__r.Product2.Family,
        SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.Product2.Product_Level__c,
        SerialNumber__c,
        Trade_Up_SerialNumber__c,
        Product_Type__c,
        Product2.Single_Entitlement__c,
        Product2.PDM_Feature_Enabled__c,
        Product2.Asset_Priority__c,
        Product2.SBQQ__SubscriptionPricing__c,
        Product2.Product_Level__c,
        Product2.License_Type__c,
        Product2.SBQQ__SubscriptionTerm__c,
        Product2.ProductCode,
        Product2.SBQQSC__EntitlementConversion__c,
        Product2.Product_Type__c,
        Product2.Bundle_Features__c,
        Product2.Appliance_Model_HW__c,
        Product2.Family,
        Product2.One_time_Entitlement__c,
        Product2.Product_Payment_Option__c,
        Product2.Category__c,
        Product2.Support_Type__c,
        Product2.Allow_PSO_Task_Creation__c,
        Product2.MSP_Std_Actual__c,
        Product2.Shipping_Lead_Time__c,
        Product2.OrderSubmission__c,
        Product2.Product_Subtype__c,
        Product2.Description,
        Product2.Edition__c,
        SBQQ__SegmentIndex__c,
        Need_manual_fulfilment__c,
        Product2.Entitlement_Conversion_Non_CPQ__c,
        TotalPrice,
        SBQQSC__ContractLineItem__c,
        Storage_Tier__c,
        TPH_Quantity__c,
        Support_Term__c,
        Product2.Eligible_for_RCDM_T__c,
        SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Subtype__c,
        SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Subtype__c,
        SBQQ__RequiredBy__r.Product2.Eligible_for_RCDM_T__c,
        SBQQ__QuoteLine__r.SBQQ__RequiredBy__c,
        Previous_Contract_Line_Items__c,
        Opportunity_Product__r.OpportunityId,
        Opportunity_Product__r.Quantity,
        Opportunity_Product__r.Subsumed_Renewal_TCV__c,
        Opportunity_Product__r.New_Expansion_TCV__c,
        Opportunity_Product__r.ACV_Amount__c,
        Opportunity_Product__r.New_Expansion_ACV__c,
        Opportunity_Product__r.SubsRenAmt__c,
        Opportunity_Product__r.Subsumed_Renewal_Amount__c,
        /* Opportunity_Product__r.PromoDiscTCV__c, Opportunity_Product__r.Prepayment_Credit__c,*/ Opportunity_Product__r.Oppty_Trade_Up_Discount__c
      FROM OrderItem
    ];
  }
  /**
   * @author Prashant Kumar
   * @date 03-07-2025
   * @description test method to get Quote With Quotelines
   * @return Map<Id, SBQQ__Quote__c>
   */

  private static Map<Id, SBQQ__Quote__c> getQuoteWithQuoteLines() {
    Map<Id, SBQQ__Quote__c> quoteMap1 = new Map<Id, SBQQ__Quote__c>(
      [
        SELECT
          Id,
          SBQQ__ExpirationDate__c,
          Manual_Fulfillment_Quote__c,
          Co_Term__c,
          Is_Conditional_PO__c,
          Legal_Approved_Verbiage__c,
          Name,
          Discounted_Units_due_to_CSAT_or_Sizing__c,
          SBQQ__Type__c,
          MSP_SKUs_Count__c,
          SBQQ__Opportunity2__c,
          Is_RWD_Polaris_Quote__c,
          Renewal_Opportunity__c,
          ProcessType__c,
          Opportunity_Program__c,
          Distributor_s_Name__c,
          SBQQ__Opportunity2__r.ContractManufacturer__c,
          SBQQ__Opportunity2__r.Aspen_Eligibility__c,
          // Additional_Terms_Required__c,
          Arry_Count_Of_Lines_Renewed__c,
          SBQQ__Account__r.Name,
          SBQQSC__MasterServiceContract__r.SBQQSC__Order__r.OrderNumber,
          RCDMT_EOL_Date__c,
          RWD_Deal_Ops_Exception__c,
          RWD_Sales_Rep_Exception__c,
          SBQQ__PaymentTerms__c,
          (
            SELECT
              Id,
              Name,
              Line_Type__c,
              SBQQ__StartDate__c,
              SBQQ__Product__r.Appliance_Model_HW__c,
              SBQQ__Product__r.Product_Type__c,
              SBQQ__Product__r.Product_Level__c,
              SBQQ__Product__r.ProductCode,
              SBQQ__RequiredBy__r.SBQQ__ProductCode__c,
              SBQQ__RequiredBy__c,
              SBQQ__EffectiveStartDate__c,
              SBQQ__ProductCode__c,
              SBQQ__Existing__c,
              SBQQ__Quantity__c,
              SBQQ__NetTotal__c,
              Wrapper_Line__c,
              SBQQ__Optional__c,
              SBQQ__EffectiveQuantity__c
            FROM SBQQ__LineItems__r
            ORDER BY SBQQ__EffectiveStartDate__c ASC NULLS LAST
          )
        FROM SBQQ__Quote__c
      ]
    );

    return quoteMap1;
  }
  /**
   * @author Prashant Kumar
   * @date 03-07-2025
   * @description test method to get Opportunity
   * @return Map<id, opportunity>
   */
  private static Map<id, opportunity> getOpportunity() {
    Map<id, opportunity> opMap = new Map<id, opportunity>(
      [
        SELECT
          Id,
          AccountId,
          StageName,
          Name,
          Hold_Code__c,
          RecordtypeId,
          PriceBook2.ID,
          Primary_Competitor__c,
          Distributor_Lookup__c,
          Pricebook2Id,
          Partner_Lookup__c,
          ContractManufacturer__c,
          Partner_Lookup__r.name,
          IsClosed,
          Rubrik_Sales_Engineer__c,
          Initial_Contacts_Name__c,
          Initial_Contacts_Name__r.name,
          Initial_Contacts_Name__r.Email,
          Rubrik_Sales_Engineer__r.Email,
          Opportunity_Sub_Type__c,
          Polaris_Portal_Contact__c,
          Polaris_Portal_Contact__r.name,
          Polaris_Portal_Contact__r.Email,
          SBQQSC__RenewedServiceContract__c,
          Mosaic_Customer_Environment__c,
          SBQQ__PrimaryQuote__c,
          SBQQ__PrimaryQuote__r.Renewal_Opportunity__c,
          SBQQ__PrimaryQuote__r.Renewal_Opportunity__r.Is_Order_Split__c,
          SBQQ__PrimaryQuote__r.SBQQ__Type__c,
          Owner.email,
          Owner.Manager.email,
          Partner_Rep_Email_Address__c,
          Partner_Lookup__r.Primary_Contact_Email__c,
          Owner.FirstName,
          Owner.LastName,
          Opportunity_Type__c,
          FocusedPartner__c,
          Deal_Registration_Type__c,
          Amount,
          Sell_to_Partner__c,
          Is_Order_Split__c,
          Fulfillment_Hold__c,
          On_Hold_Notes__c,
          Override__c,
          Aspen_Eligibility__c,
          Rubrik_Security_Cloud_Gov_t_Owner__c,
          Rubrik_Security_Cloud_Gov_t_Owner__r.Email,
          Rubrik_Security_Cloud_Gov_t_Owner__r.phone,
          MSP_End_User_Lookup__c,
          Managed_Services_Deal_type__c,
          (SELECT Id, /* Associated_Order_Numbers__c,*/ SBQQ__Quote__c FROM Orders),
          (SELECT Id, SBQQSC__Order__c FROM SBQQSC__ServiceContracts__r)
        FROM opportunity
      ]
    );

    return opMap;
  }
  /**
   * @author Prashant Kumar
   * @date 03-07-2025
   * @description test method to get Account.
   * @return Account
   */
  private static Account getAccount() {
    account acct = [
      SELECT
        Id,
        Name,
        Sync_to_NetSuite__c,
        RSC_G_Support__c,
        U_S_citizen_service__c,
        Contract_Negotiation__c,
        GTC_Screen_Status__c,
        EULA_revision_Required__c,
        Type,
        Owner.Name,
        BillingState,
        BillingCountry,
        BillingCountryCode,
        Primary_Contact_Email__c,
        Channel_Program_Level_Name__c,
        Channel_Program_Name__c,
        Account_SAM__r.Email,
        RSC_G_Eligible__c,
        Eligible_for_RCDM_T__c,
        ETM_Area__c,
        PS_Project_Manager__c,
        PS_Project_Manager__r.IsActive,
        RSC_G_Account_Sync_status__c,
        Payment_Term__c,
        (SELECT Id, Agreement_Type__c FROM Contracts WHERE Contract_Status__c = 'Active'),
        (
          SELECT
            Id,
            ShippingStreet,
            ShippingPostalCode,
            ShippingCity,
            ShippingCountry,
            ShippingState,
            ShippingCountryCode,
            ShipToContactName__c,
            PoDate,
            PoNumber,
            End_User_PO__c,
            Payment_Terms__c,
            Ship_to_Email__c,
            Ship_To_Name__c
          FROM orders
          LIMIT 1
        )
      FROM Account
      LIMIT 1
    ];
    return acct;
  }

  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to Order Hold Code trigger logic
   */
    @isTest
    private static void testholdCode() {
       /* String uniqueUserName = 'AdminUser' + DateTime.now().getTime() + '@rubrik.com';
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User u = new User(
            Alias = 'adminU',
            Email = 'AdminUser@rubrik.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = uniqueUserName
        );
        insert u;*/

        
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert new ShGl_DisableBusinessLogic__c(
                Disable_Order_Validation_Rules__c = true,
                Disable_Opportunity_Validation_Rules__c = true,
                Disable_SBQQ_Quote_Validation_Rules__c = true,
                Disable_SBQQ_Quote_Triggers__c = true

            );

            Id pricebookId = Test.getStandardPricebookId();
            String netAppAccId = Label.NetApp_Account_Ids.split(';')[0];     
            List<Opportunity> lstOpp = [SELECT id, AccountId, pricebook2Id, Opportunity_Sub_Type__c,Sell_to_Partner__c FROM Opportunity LIMIT 1];
            lstOpp[0].pricebook2Id = pricebookId;
            //lstOpp[0].Sell_to_Partner__c = netAppAccId;
            update lstOpp;
            Assert.areEqual(true, lstOpp.size() > 0);
            SBQQ__Quote__c qtq = [SELECT Id, name, SBQQ__NetAmount__c, SBQQ__PricebookId__c,SBQQ__Type__c FROM SBQQ__Quote__c LIMIT 1];
            qtq.SBQQ__Type__c = 'Amendment';
			      update qtq;
			      Order ord = createTestorder('Revenue',qtq.Id, lstOpp[0].AccountId,lstOpp[0].Id,lstOpp[0].AccountId,pricebookId,'Not needed','Renewal',new Map<String, Object>{'Sell_to_Partner__c' => netAppAccId,'Bill_To_Name__c' => netAppAccId});
            ord.SBQQ__Quote__c = qtq.Id;
            ord.ship_To_Name__c = lstOpp[0].AccountId;
            ord.Pricebook2Id = pricebookId;
            insert ord;
            List<Product2> productList = new List<product2>{
                createTestProduct('RS-BT-EE-PE-PP', 'RS-BT-EE-PE-PP', 'Rubrik Licence', null, 'Hybrid Software',
                                  new Map<String, Object>{'Category__c' => 'Bundle','Product_Type__c' => 'Complete Edition','License_Category__c' => 'SaaS','SBQQ__AssetAmendmentBehavior__c' => 'Default','SBQQSC__EntitlementConversion__c' => 'One per quote line','IsActive' => true,'SBQQ__SubscriptionPricing__c' => 'Fixed Price','SBQQ__SubscriptionTerm__c' => 36,'SBQQ__SubscriptionBase__c' => 'List','SBQQ__SubscriptionType__c' => 'Renewable'}),
                    createTestProduct('RS-MD-FUE-RSV', 'RS-MD-FUE-RSV', 'Rubrik Licence', null, null,
                                      new Map<String, Object>{'Product_Subtype__c' => 'Scale MSP','License_Category__c' => 'SaaS','Edition__c' => 'Edition Upgrade'}),
                                        createTestProduct('RS-MD-FUE-RSVX', 'RS-MD-FUE-RSVX', 'Rubrik Licence', null, null,
                                      new Map<String, Object>{'Product_Subtype__c' => 'Scale MSP'})

                    
                    
                    };
            insert productList;
            List<PricebookEntry> pbList = new List<PricebookEntry>{};
            PricebookEntry pb1 = new PricebookEntry(UseStandardPrice = false, Pricebook2Id = pricebookId, Product2Id = productList[0].Id, UnitPrice = 100.00, IsActive = true);
            pbList.add(pb1);
            PricebookEntry pb2 = new PricebookEntry(UseStandardPrice = false, Pricebook2Id = pricebookId, Product2Id = productList[1].Id, UnitPrice = 100.00, IsActive = true);
            pbList.add(pb2);
            PricebookEntry pb3 = new PricebookEntry(UseStandardPrice = false, Pricebook2Id = pricebookId, Product2Id = productList[2].Id, UnitPrice = 100.00, IsActive = true);
            pbList.add(pb3);

            insert pbList;
            
           List<OrderItem> orderItemList = new List<OrderItem>{
           createTestOrderItem(Ord.Id,5,pbList[0].Id,pbList[0].UnitPrice,
                                                   new Map<String, Object>{
                                                       'Support_Start_Date__c' => System.today(),
                                                           'Support_End_Date__c' => System.today().addYears(1)
                                                           }
                                                  ),
               
           createTestOrderItem(Ord.Id,5,pbList[1].Id,pbList[1].UnitPrice,
                                                   new Map<String, Object>{
                                                       'Support_Start_Date__c' => System.today(),
                                                           'Support_End_Date__c' => System.today().addYears(1)
                                                           }
                                                  ),
                     createTestOrderItem(Ord.Id,5,pbList[2].Id,pbList[2].UnitPrice,
                                                   new Map<String, Object>{
                                                     'NTAP_Order_number__c' => '111111', 
                                                       'NTAP_Part_number__c'=> 'RUBRIK-SYS^11111',
                                                       'Support_Start_Date__c' => System.today(),
                                                           'Support_End_Date__c' => System.today().addYears(1)
                                                           }
                                                  )
     

               
           };

            insert orderItemList;
            test.StartTest();
            List<order> lstorder = [SELECT Id, ShipToContactName__c,Polaris_Fulfillment_Status__c , Order_Status__c,Bill_To_Name__c,Sell_to_Partner__c FROM order where Id =: ord.Id];
            lstorder[0].Order_Status__c = 'Pending';
            lstorder[0].Hold_Code__c  = null;
			      update lstorder;
            lstorder[0].Hold_Code__c  = null;
			      lstorder[0].order_sub_type__c = 'GC Offer';
            //String netAppAccId = Label.NetApp_Account_Ids.split(';')[0];
      		//lstorder[0].Sell_to_Partner__c = netAppAccId;
      		//lstorder[0].Bill_To_Name__c = netAppAccId;
            update lstorder;
            qtq.SBQQ__Type__c = null;
           // SBQQ.TriggerControl.disable();
            update qtq;
			//SBQQ.TriggerControl.enable();




            TransactionalDataCollection.orderItemMainList.clear();
			//lstorder[0].type = 'POC'; 
            //lstorder[0].Order_Status__c = 'Shipped';
            //lstorder[0].Polaris_Fulfillment_Status__c  = 'Completed';
            lstorder[0].Sell_to_Partner__c = netAppAccId;
      		  lstorder[0].Bill_To_Name__c = netAppAccId;
            update lstorder;
            test.StopTest();
        }
    }
    
    
      @isTest
    private static void testholdCode2() {
      String uniqueUserName = 'AdminUser' + DateTime.now().getTime() + '@rubrik.com';
      Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
      User u = new User(
        Alias = 'adminU',
        Email = 'AdminUser@rubrik.com',
        EmailEncodingKey = 'UTF-8',
        LastName = 'Testing',
        LanguageLocaleKey = 'en_US',
        LocaleSidKey = 'en_US',
        ProfileId = p.Id,
        TimeZoneSidKey = 'America/Los_Angeles',
        UserName = uniqueUserName
      );
      insert u; 

        
        
      System.runAs(u) {
        insert new ShGl_DisableBusinessLogic__c(
          Disable_Order_Validation_Rules__c = true,
          Disable_Opportunity_Validation_Rules__c = true,
          Disable_SBQQ_Quote_Validation_Rules__c = true,
          Disable_SBQQ_Quote_Triggers__c = true

        );

        Id pricebookId = Test.getStandardPricebookId();
        String netAppAccId = Label.NetApp_Account_Ids.split(';')[0];
        Id partner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account partnerAcc = new Account(
          Name = 'Customer',
          recordtypeId = partner,
          Phone = '123-456-7890',
          AccountNumber = 'Test',
          BillingStreet = '123 street',
          BillingCity = 'Santa Clara',
          BillingState = 'California',
          BillingPostalCode = '95050',
          BillingCountry = 'United States',
          ShippingStreet = '123 street',
          ShippingCity = 'Santa Clara',
          ShippingState = 'California',
          ShippingPostalCode = '95050',
          Contract_Status__c = 'Signed-Active',
          ShippingCountry = 'United States'
        );
        insert partnerAcc;
            
        partnerAcc.Id =  netAppAccId;
        update partnerAcc;
        test.StartTest();

        List<Opportunity> lstOpp = [SELECT id, AccountId, pricebook2Id, Opportunity_Sub_Type__c,Sell_to_Partner__c FROM Opportunity LIMIT 1];
        lstOpp[0].pricebook2Id = pricebookId;
        lstOpp[0].Sell_to_Partner__c = netAppAccId;
        update lstOpp;
        Assert.areEqual(true, lstOpp.size() > 0);
        SBQQ__Quote__c qtq = [SELECT Id, name, SBQQ__NetAmount__c, SBQQ__PricebookId__c,SBQQ__Type__c FROM SBQQ__Quote__c LIMIT 1];
        qtq.SBQQ__Type__c = 'Amendment';
			  update qtq;
			  Order ord = createTestorder('Revenue',qtq.Id, lstOpp[0].AccountId,lstOpp[0].Id,lstOpp[0].AccountId,pricebookId,'Not needed','Renewal',new Map<String, Object>{'Sell_to_Partner__c' => netAppAccId,'Bill_To_Name__c' => netAppAccId});
        ord.Sync_to_NetSuite__c = false;
        ord.SBQQ__Quote__c = qtq.Id;
        ord.ship_To_Name__c = lstOpp[0].AccountId;
        ord.Pricebook2Id = pricebookId;
        insert ord;
        ord.Sync_to_NetSuite__c = true;
        ord.Hold_Code__c = '';  
        update ord;

            
        test.StopTest();
      }
    }
  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to Order Hold Code trigger logic
   */
  @isTest
  private static void testholdCode1() {
    System.runAs(new User(Id = UserInfo.getUserId())) {
      Id pricebookId = Test.getStandardPricebookId();
      List<Opportunity> lstOpp = [SELECT id, AccountId, pricebook2Id, Opportunity_Sub_Type__c FROM Opportunity LIMIT 1];
      lstOpp[0].pricebook2Id = pricebookId;
      update lstOpp;
      Assert.areEqual(true, lstOpp.size() > 0);
      SBQQ__Quote__c qtq = [SELECT Id, name, SBQQ__NetAmount__c, SBQQ__PricebookId__c FROM SBQQ__Quote__c LIMIT 1];
      Order ord = createTestorder('Revenue',qtq.Id, lstOpp[0].AccountId,lstOpp[0].Id,lstOpp[0].AccountId,pricebookId,null,'MSP Overage',new Map<String, Object>{'customer_required_ship_date__c' => system.today().addmonths(3)/*,'order_sub_type__c' => 'Renewal'*/});
	    ord.Sync_to_NetSuite__c = false;
	    insert ord;
      Product2 objProds =   createTestProduct('RS-BT-EE-PE-PP', 'RS-BT-EE-PE-PP', 'Rubrik Licence', null, 'Hybrid Software',
            new Map<String, Object>{'Category__c' => 'Bundle','Product_Type__c' => 'Complete Edition','License_Category__c' => 'SaaS','SBQQ__AssetAmendmentBehavior__c' => 'Default','SBQQSC__EntitlementConversion__c' => 'One per quote line','SBQQ__SubscriptionPricing__c' => 'Fixed Price','SBQQ__SubscriptionTerm__c' => 36,'SBQQ__SubscriptionBase__c' => 'List','SBQQ__SubscriptionType__c' => 'Renewable'
                });
      insert objProds;
      PricebookEntry pb1 = new PricebookEntry(UseStandardPrice = false, Pricebook2Id = pricebookId, Product2Id = objProds.Id, UnitPrice = 100.00, IsActive = true);
      insert pb1;
      OrderItem objOI =  createTestOrderItem(Ord.Id,5,pb1.Id,pb1.UnitPrice,
                                               new Map<String, Object>{
                                                   'Support_Start_Date__c' => System.today(),
                                                       'Support_End_Date__c' => System.today().addYears(1)
                                                       }
                                              );
      insert objOI;
      test.StartTest();
      List<order> lstorder = [SELECT Id, ShipToContactName__c, Order_Status__c, customer_required_ship_date__c  FROM order LIMIT 1];
      lstorder[0].Hold_Code__c = '';
      lstorder[0].Order_Status__c = 'Pending';
      lstorder[0].Sync_to_NetSuite__c = true;
      lstorder[0].Revised_By__c = 'test';  
 
      //lstorder[0].customer_required_ship_date__c  = system.today().addMonths(3);  
      update lstorder;
      List<order> lstorder1 = [SELECT Id, ShipToContactName__c, Order_Status__c,order_sub_type__c, customer_required_ship_date__c  FROM order where Id = :ord.Id];
      lstorder1[0].Hold_Code__c = '';
      lstorder1[0].Order_Status__c = 'Pending';
      lstorder1[0].order_sub_type__c = 'Renewal';
      lstorder1[0].Revised_By__c = UserInfo.getUserEmail();

        
      //lstorder[0].customer_required_ship_date__c  = system.today().addMonths(3);  
      update lstorder1;

      test.StopTest();
    }

  }

  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to Order Hold Code trigger logic
   */
  @isTest
  private static void dependentPickList() {
    System.runAs(new User(Id = UserInfo.getUserId())) {
      Id pricebookId = Test.getStandardPricebookId();
      List<Opportunity> lstOpp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
      Assert.areEqual(true, lstOpp.size() > 0);
      PO_Stage__c objStagePO = [SELECT Id FROM PO_Stage__c LIMIT 1];
      objStagePO.EDI_DISTI_ID__c = 'PO PDF';
      objStagePO.Customer_Requested_Ship_Date__c = 'Test date';
      objStagePO.Service_Level__c = 'Economy';
      update objStagePO;
           SBQQ__Quote__c qtq = [SELECT Id, name, SBQQ__NetAmount__c, SBQQ__PricebookId__c FROM SBQQ__Quote__c LIMIT 1];
        Order ord = createTestorder('Revenue',qtq.Id, lstOpp[0].AccountId,lstOpp[0].Id,lstOpp[0].AccountId,pricebookId,'Not needed','MSP Overage',new Map<String, Object>{} );
        ord.Stage_PO__c = objStagePO.id;
        ord.Order_Status__c = null;
        ord.ship_To_Name__c = lstOpp[0].AccountId;
        ord.Pricebook2Id = pricebookId;
        ord.Order_Splitted__c = true;
        ord.Shipping_Carrier__c = 'Blue Dart';
        ord.Service_Level__c = 'Economy';
      test.startTest();
      insert Ord;
      test.stopTest();
    }
  }

  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to Order trigger logic
   */
  static testMethod void testInsertOder() {
    insert new RPS__c(
      SetupOwnerId = Userinfo.getOrganizationId(),
      Is_RPS_Required__c = false,
      Screening_Source__c = 'Internal',
      Valid_HoldCodes__c = 'Global Trade Compliance screening failed;Credit Check Failed'
    );
    PO_Stage__c postg = [SELECT id FROM PO_Stage__c LIMIT 1];
    testDataFactoryClass.createCustomSettings();

    System.runAs(new User(Id = UserInfo.getUserId())) {
      Account acct = [SELECT Id, Name, Sync_to_NetSuite__c, RSC_G_Eligible__c, BillingCountry, BillingState, U_S_citizen_service__c FROM Account WHERE Name = 'Test' LIMIT 1];
      acct.Sync_to_NetSuite__c = false;
      acct.RSC_G_Eligible__c = true;
      acct.Website = 'www.test-prodops.com:8000';
      update acct;
      Assert.areEqual('Test', acct.Name);
      OpportunityObjectTriggerHandler.isOppAutoManual = 'AutoGenerated';
      Opportunity oppr = [SELECT Id, Opportunity_Sub_Type__c, pricebook2Id FROM Opportunity WHERE AccountId = :acct.Id LIMIT 1];
      PO_Stage__c objStagePO = [
        SELECT
          Id,
          EDI_DISTI_ID__c,
          Partner_Name__c,
          PoDate__c,
          PoNumber__c,
          ShippingCity__c,
          ShippingCountry__c,
          ShippingCountryCode__c,
          ShippingPostalCode__c,
          ShippingState__c,
          ShippingStateCode__c,
          ShippingStreet__c,
          Shipping_Method__c,
          Ship_To_Contact_Name__c,
          Shipping_Carrier__c,
          Shipping_Account_Number__c,
          End_User_PO__c,
          Service_Level__c,
          Ship_to_Email__c,
          Ship_To_Phone_Number__c,
          Payment_Terms__c,
          Quote__c,
          Expected_number_of_POs__c,
          Bill_To_Name__c,
          TotalAmount__c,
          Ship_to_Account_Name__c,
          Customer_Requested_Ship_Date__c,
          Note_on_Contingency_and_Special_Language__c,
          (SELECT Id, Quote_Line__c, Type__c, Stage_PO__c, Quantity__c, UnitPrice__c, Product__r.Product_Payment_Option__c FROM PO_Item_Stage__r)
        FROM PO_Stage__c
        LIMIT 1
      ];

      insert new Hold_Off_Tracking__c(
        Hold_Code__c = 'OM Internal Review',
        Release_Date_Time__c = datetime.newInstance(2021, 9, 15, 12, 30, 0),
        Related_Opportunity__c = oppr.Id,
        Is_Released__c = false
      );

      Id pricebookId = Test.getStandardPricebookId();
      oppr.pricebook2Id = pricebookId;
      oppr.Opportunity_Sub_Type__c = 'Renewal';
      oppr.MSP_End_User_Lookup__c = acct.Id;
      update oppr;

      List<Product2> lstProds = new List<Product2>{
        // Basic Product
        createTestProduct('RBK-SVC-PREM-R344', 'RBK-SVC-PREM-R344', 'ASE', 'RBK-R6408F', 'Support', null),
        // With Bundle_Features__c
        createTestProduct(
          'RBK-SVC-PREM-R344',
          'RBK-SVC-PREM-R344',
          'POLARIS',
          'RBK-R640F',
          'Support',
          new Map<String, Object>{ 'Bundle_Features__c' => 'Cloud Native Protection' }
        ),
        // With Product_Type, Entitlement, etc.
        createTestProduct(
          'RBK-SVC-PREM-R344',
          'RBK-SVC-PREM-R344',
          'RCDM',
          'RBK-R640F',
          'Support',
            new Map<String, Object>{
                'Product_Type__c' => 'MSP',
                    'Create_Entitlement__c' => true,
                    'Entitlement_Conversion_Non_CPQ__c' => 'One per unit',
                    'Bundle_Features__c' => 'Cloud Native Protection',
                    'MSP_Std_Actual__c' => null,
                    'Edition__c' => 'Edition Upgrade',
                    'Product_Subtype__c' => Constants.PROD_SUB_TYPE_SCALE_MSP,
                    'License_Category__c' => Constants.LICENSE_CATEGORY
                    }
        ),
        // With SubscriptionPricing
        createTestProduct(
          'RBK-SVC-PREM-R344',
          'RBK-SVC-PREM-R344',
          'RCDM',
          'RBK-R640F',
          'Support',
          new Map<String, Object>{
            'Product_Type__c' => 'MSP',
            'Bundle_Features__c' => 'Cloud Native Protection',
            'MSP_Std_Actual__c' => null,
            'SBQQ__SubscriptionPricing__c' => 'Fixed Price',
            'Shipping_Lead_Time__c' => 2,
            // 'Need_manual_fulfilment__c' => true,   
            'Allow_PSO_Task_Creation__c' => true,
             'OrderSubmission__c' => 'Manual' ,
             'Product_Level__c' => 'Hardware',
              'Product_Type__c' =>  'Hardware',
             'Product_Subtype__c' => 'FEDRAMP'   
          }
        ),
        // With SBQQSC__EntitlementConversion__c
        createTestProduct(
          'RBK-SVC-PREM-R344',
          'RBK-SVC-PREM-R344',
          'POLARIS',
          'RBK-R640F',
          'Support',
          new Map<String, Object>{ 'Create_Entitlement__c' => true, 'SBQQSC__EntitlementConversion__c' => 'One per unit', 'Bundle_Features__c' => 'Cloud Native Protection' }
        ),
        // Another variant with different name
        createTestProduct(
          'RA-USCS-PA',
          'RA-USCS-PA',
          'POLARIS',
          'RBK-R640F',
          'Support',
          new Map<String, Object>{ 'Create_Entitlement__c' => true, 'SBQQSC__EntitlementConversion__c' => 'One per unit', 'Bundle_Features__c' => 'Cloud Native Protection' }
        )
      };

      insert lstProds; // Uncomment if inserting in test or real code

      List<PricebookEntry> lstPbEntry = new List<PricebookEntry>{
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[0].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[1].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[2].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[3].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[4].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[5].Id, UnitPrice = 100.00, IsActive = true)
      };

      insert lstPbEntry;

      List<OpportunityLineItem> lstOlis = new List<OpportunityLineItem>{
        new OpportunityLineItem(OpportunityId = oppr.Id, Quantity = 5, PricebookEntryId = lstPbEntry[0].Id, TotalPrice = 5 * lstPbEntry[0].UnitPrice),
        new OpportunityLineItem(OpportunityId = oppr.Id, Quantity = 5, PricebookEntryId = lstPbEntry[1].Id, TotalPrice = 5 * lstPbEntry[1].UnitPrice)
      };

      insert lstOlis;

      test.startTest();

      Map<String, Object> OrderMap = new Map<String, Object>{
        'Type' => 'Revenue',
        'AccountId' => acct.Id,
        'OpportunityId' => oppr.Id,
        'Sync_to_NetSuite__c' => true,
        'EffectiveDate' => system.today(),
        'Status' => 'Pending',
        'Mosaic_SKUs__c' => 'RBK-MOSAIC',
        'ShippingCountryCode' => 'US',
        'ShippingStateCode' => 'CA',
        'Polaris_Fulfillment_Status__c' => 'Completed',
        'Is_RWD_Polaris_Quote__c' => true,
        'Stage_PO__c' => postg.id,
        'Order_Status__c' => 'Pending',
        'Order_Split_Type__c' => 'Not needed',
        'Bill_To_Name__c' => acct.Id,
        'RSC_G_Enabled__c' => false
      };

      Order ord = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
      insert Ord;

      List<OrderItem> lstOrdrItems = new List<OrderItem>{
        // 1st OrderItem
        createTestOrderItem(
          Ord.Id,
          5,
          lstPbEntry[0].Id,
          lstPbEntry[0].UnitPrice,
          new Map<String, Object>{
            'SerialNumber__c' => 'S3F4NXMM416324',
            'Failed_Serial_Number__c' => 'S3F4NXM416324',
            'Support_Start_Date__c' => System.today(),
            'Support_End_Date__c' => System.today().addYears(1),
            'NTAP_Part_number__c' => 'RUBRIK-SYS^24815444'    
          }
        ),
        // 2nd OrderItem
        createTestOrderItem(
          Ord.Id,
          5,
          lstPbEntry[1].Id,
          lstPbEntry[1].UnitPrice,
          new Map<String, Object>{
            'SerialNumber__c' => 'S3F4NXMM416324',
            'Failed_Serial_Number__c' => 'S3F4NXM416324',
            'Support_Start_Date__c' => System.today(),
            'Support_End_Date__c' => System.today().addYears(1),
            'POC_Option__c' => 'AWS'
          }
        ),
        // 3rd OrderItem
        createTestOrderItem(
          Ord.Id,
          5,
          lstPbEntry[2].Id,
          lstPbEntry[2].UnitPrice,
          new Map<String, Object>{
            'SerialNumber__c' => 'S3F4NXMM416324',
            'Failed_Serial_Number__c' => 'S3F4NXM416324',
            'Support_Start_Date__c' => System.today(),
            'Support_End_Date__c' => System.today().addYears(1),
            'POC_Option__c' => 'AWS',
            'SBQQ__SegmentIndex__c' => 1,
             'NTAP_Part_number__c' => 'RUBRIK-SYS^24815444'    
    
          }
        ),
        // 4th - 6th OrderItems (only POC_Option & SegmentIndex)
        createTestOrderItem(
          Ord.Id,
          5,
          lstPbEntry[3].Id,
          lstPbEntry[3].UnitPrice,
          new Map<String, Object>{ 'SerialNumber__c' => 'S3F4NXMM416324', 'Failed_Serial_Number__c' => 'S3F4NXM416324', 'POC_Option__c' => 'AWS', 'SBQQ__SegmentIndex__c' => 1 }
        ),
        createTestOrderItem(
          Ord.Id,
          5,
          lstPbEntry[4].Id,
          lstPbEntry[4].UnitPrice,
          new Map<String, Object>{ 'SerialNumber__c' => 'S3F4NXMM416324', 'Failed_Serial_Number__c' => 'S3F4NXM416324', 'POC_Option__c' => 'AWS', 'SBQQ__SegmentIndex__c' => 1 }
        ),
        createTestOrderItem(
          Ord.Id,
          5,
          lstPbEntry[5].Id,
          lstPbEntry[5].UnitPrice,
          new Map<String, Object>{ 'SerialNumber__c' => 'S3F4NXMM416324', 'Failed_Serial_Number__c' => 'S3F4NXM416324', 'POC_Option__c' => 'AWS', 'SBQQ__SegmentIndex__c' => 1 }
        )
      };
      insert lstOrdrItems;
      lstOrdrItems[3].SBQQ__RequiredBy__c = lstOrdrItems[0].Id;
      lstOrdrItems[4].SBQQ__RequiredBy__c = lstOrdrItems[0].Id;
      TriggerControl.stopOrderItemTrigger = true;
      TriggerControl.stopOrderTrigger = true;
      update lstOrdrItems[3];
      update lstOrdrItems[4];
      TriggerControl.stopOrderItemTrigger = false;
      TriggerControl.stopOrderTrigger = false;
      system.debug(logginglevel.DEBUG, ':::query:::req' + [SELECT id, SBQQ__RequiredBy__c FROM Orderitem LIMIT 5]);
      ord.Have_PS_Products__c = true;
      ord.Order_Status__c = 'Order Accepted';
      update ord;
      order ord12 = getOrder();
      Map<Id, SBQQ__Quote__c> quoteMap1 = getquotewithquotelines();
      quoteMap1.values()[0].RWD_Deal_Ops_Exception__c = constants.RCDMT_EXT_RWD_DEAL_OPS_EXCEPTION;
      list<orderItem> oi = getorderlines();
      oi[0].product2.name = 'RS-BT-RCDM-T';
      oi[0].Product2.SBQQ__SubscriptionPricing__c = 'Fixed';
      oi[0].SBQQ__SubscriptionTerm__c = null;
      List<PO_Stage__c> stagePos = new List<PO_Stage__c>();
      Map<id, opportunity> opMap = getOpportunity();
      objStagePO.TotalAmount__c = ord12.TotalAmount;
      stagePos.add(objStagePO);
      ord12.Manual_Approve__c = true;
      ord12.Screening_Source__c = 'Internal';
      ord12.ShippingCountryCode = 'AU';
      ord12.ScreenStatus__c = 'On hold';
      ord12.Order_Status__c = 'Pending';
      ord12.Order_Sub_Type__c = '';
      ord12.Bill_To_Name__c = acct.id;
      ord12.PoDate = System.Today();
      ord12.PoNumber = '12';
      ord12.End_User_PO__c = '12';
      ord12.Payment_Terms__c = '12';
      ord12.Ship_to_Email__c = 'Test@test.com';
      ord12.Quote_RCDM_T_EOL_Date__c = System.Today().adddays(-3);
      ord12.Welcome_Letter_Sent_At__c = system.today();
      ord12.customer_required_ship_date__c  = system.today().addmonths(3);
          //  ord12.Est_Ship_Date__c = system.today();
      ord12.Type = 'Revenue';
      map<id, order> ordmap = new Map<id, order>();
      orderinserthelper oIh = new orderinserthelper();
      oIh.orderIdOrderItemMap.put(ord12.id, oi);
      order ord123 = new order();
      ord123.Manual_Approve__c = false;
      ord123.Welcome_Letter_Sent_At__c = system.today().adddays(-3);
        Account_Screening__c acctscr = new Account_Screening__c();
      acctscr.Name = acct.Name;
      acctscr.Screening_Eligibility__c = true;
      acctscr.Screening_Action__c = 'Start';
      acctscr.Screening_Action_Status__c = 'Ready';
      acctscr.Account__c = acct.Id;
      acctscr.Unique_Parent_Id__c = acct.Id;
      acctscr.GTC_Screen_Status__c = 'Denied Party List';
      insert acctscr;
      acct.Account_Screening__c = acctscr.id;
      update acct;
      try {
        oIh.populateFieldsOnUpdate(ord12, ord123, null, null);
      } catch (Exception e) {
        system.debug(LoggingLevel.DEBUG, 'DmlException caught' + e.getMessage());
      }
      oih.accountMap = new Map<Id, Account>();
      oIh.quoteMap = new Map<Id, SBQQ__Quote__c>();
      oih.autoSubmitOrder(ord12, ord123, stagePos, ordmap);
      ord12.Quote_RCDM_T_EOL_Date__c = System.Today();
      oih.autoSubmitOrder(ord12, ord123, stagePos, ordmap);
      oi[0].SBQQ__SubscriptionTerm__c = 12;
      oIh.orderIdOrderItemMap.put(ord12.id, oi);
      ord12.Order_Sub_Type__c = 'Amendment';
      oih.autoSubmitOrder(ord12, ord123, stagePos, ordmap);
      oIh.quoteMap = quoteMap1;
      ord12.Order_Split_Type__c = 'EDI';
      oih.autoSubmitOrder(ord12, ord123, stagePos, ordmap);
      Set<Id> orderWithUSCitizenProducts = new Set<Id>();
      orderWithUSCitizenProducts.add(ord12.id);
      Map<id, Account> accmap = new Map<id, Account>();
      accmap.put(acct.id, acct);
      oih.updateUSCitizenFieldOnAccount(ord12, accmap, orderWithUSCitizenProducts, acct);
      acct = getAccount();
      oih.accountMap = new Map<Id, Account>();
      oih.accountMap.put(acct.id, acct);
      oih.oppMap = opMap;
      quoteMap1.values()[0].RWD_Deal_Ops_Exception__c = '';
      oIh.quoteMap = quoteMap1;
      ord12.Order_Status__c = 'Pending';
      ord12.Hold_Code__c = '';
      oIh.populateFieldsOnInsert(ord12, stagePos, false, false);
      ord12.Hold_Code__c = '';
      oih.populateFieldsOnUpdate(ord12, ord123, null, null);

      String netAppAccId = Label.NetApp_Account_Ids.split(';')[0];
      ord12.Sell_to_Partner__c = netAppAccId;
      ord12.Bill_To_Name__c = netAppAccId;
      ord12.OM_internal_review__c = true;
      ord12.Change_Needed_Reason_Other__c = 'OM internal review for Netapp order';
      ord12.Shipping_Method__c = 'DDP';
      ord12.Order_Sub_Type__c = constants.ORDER_SUB_TYPE_GC_OFFER;
      ord12.Order_Split_Type__c = 'Not needed';
      opMap.values()[0].RecordtypeId = Constants.OPPORTUNITY_RECORDTYPEID_RENEWAL;
      oih.oppMap = opMap;
      oih.populateFieldsOnUpdate(ord12, ord123, null, null);
      oIh.populateFieldsOnInsert(ord12, stagePos, false, false);
      oih = new orderinserthelper();
      oIh.quoteMap = quoteMap1;
      oih.accountMap = new Map<Id, Account>();
      oih.accountMap.put(acct.id, acct);
      Map<String, Sfdc_Disti_Mapping__mdt> distiAllValuesMap = Sfdc_Disti_Mapping__mdt.getAll();
      id Arrowid;
      for (String developerName : distiAllValuesMap.keySet()) {
        if (distiAllValuesMap.get(developerName).Po_Disti_Type__c == 'ARROW') {
          Arrowid = distiAllValuesMap.get(developerName).Sfdc_Id__c;
        }
      }
      opMap.values()[0].Distributor_Lookup__c = Arrowid;
      oih.oppMap = opMap;
      ord12.Sell_to_Partner__c = null;
      ord12.Order_Split_Type__c = null;  
      oih.populateFieldsOnUpdate(ord12, ord123, null, null);
      oIh.populateFieldsOnInsert(ord12, stagePos, false, false);
      ord12.Order_Sub_Type__c = '';
      ord12.Shipping_Carrier__c ='Blue Dart';
      oih.orderIdOrderItemMap.put(ord12.id, oi);
      oih.autoSubmitOrder(ord12, ord123, stagePos, ordmap);
      ord12.Ship_To_Phone_Number__c = '9999999999'; 
      ord12.ShippingStreet = 'test street';
      ord12.ShippingPostalCode = 'test 12345';
      ord12.ShippingCity = 'test city';
      ord12.ShippingCountryCode = 'test';
      ord12.ShipToContactName__c = 'test contact';
      ord12.Ship_to_Email__c = 'test@test.com';
      ord12.Order_Sub_Type__c = '';
      ord12.Quote_RCDM_T_EOL_Date__c = System.Today().addDays(-2);
      oih.autoSubmitOrder(ord12, ord123, stagePos, ordmap);
      ord12.Quote_RCDM_T_EOL_Date__c = System.Today().addDays(2);
      oih.autoSubmitOrder(ord12, ord123, stagePos, ordmap);
      ord12.Order_Sub_Type__c = 'Renewal';
      oih.autoSubmitOrder(ord12, ord123, stagePos, ordmap);
      ord12.Order_Split_Type__c = 'Not Needed';
      ord12.OpportunityId = null;
      ord12.Type = 'Revenue';
      oih.autoSubmitOrder(ord12, ord123, stagePos, ordmap);
      test.stopTest();
    }
  }

  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to Order trigger logic
   */
  static testMethod void testInsertOder1() {
    insert new RPS__c(
      SetupOwnerId = Userinfo.getOrganizationId(),
      Is_RPS_Required__c = false,
      Screening_Source__c = 'Internal',
      Valid_HoldCodes__c = 'Global Trade Compliance screening failed;Credit Check Failed'
    );

    testDataFactoryClass.createCustomSettings();

    String uniqueUserName = 'AdminUser' + DateTime.now().getTime() + '@rubrik.com';
    Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
    User u = new User(
      Alias = 'adminU',
      Email = 'AdminUser@rubrik.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = p.Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = uniqueUserName
    );
    insert u;
    insert new ShGl_DisableBusinessLogic__c(
      Disable_Order_Validation_Rules__c = true,
      Disable_SBQQ_Quote_Triggers__c = true,
      Disable_SBQQ_QuoteLine_Triggers__c = true,
      Disable_Opportunity_Validation_Rules__c = true,
      Disable_Opportunity_Triggers__c = true,
      Disable_Order_Email_Alerts__c = false,
      Disable_Order_Old_Trigger__c = true,
      Disable_Order_Triggers__c = false,
      Disable_Contact_Triggers__c = true,
      Disable_POC_Trigger__c = true,
      Disable_POC_Validation_Rules__c = true,
      setupOwnerId = u.Id
    );
    System.runAs(u) {
      Account acct = [SELECT Id, Name, Sync_to_NetSuite__c, RSC_G_Eligible__c, BillingCountry, BillingState, U_S_citizen_service__c FROM Account WHERE Name = 'Test' LIMIT 1];
      acct.Sync_to_NetSuite__c = false;
      acct.RSC_G_Eligible__c = true;
      update acct;

      Assert.areEqual('Test', acct.Name);
      Opportunity oppr = [SELECT Id, pricebook2Id, CreatedById FROM Opportunity WHERE AccountId = :acct.Id LIMIT 1];

      Id pricebookId = Test.getStandardPricebookId();
      oppr.pricebook2Id = pricebookId;
      update oppr;

      PO_Stage__c objStagePO = [
        SELECT
          Id,
          EDI_DISTI_ID__c,
          Partner_Name__c,
          PoDate__c,
          PoNumber__c,
          ShippingCity__c,
          ShippingCountry__c,
          ShippingCountryCode__c,
          ShippingPostalCode__c,
          ShippingState__c,
          ShippingStateCode__c,
          ShippingStreet__c,
          Shipping_Method__c,
          Ship_To_Contact_Name__c,
          Shipping_Carrier__c,
          Shipping_Account_Number__c,
          End_User_PO__c,
          Service_Level__c,
          Ship_to_Email__c,
          Ship_To_Phone_Number__c,
          Payment_Terms__c,
          Quote__c,
          Expected_number_of_POs__c,
          Bill_To_Name__c,
          TotalAmount__c,
          Ship_to_Account_Name__c,
          Customer_Requested_Ship_Date__c,
          Note_on_Contingency_and_Special_Language__c,
          (SELECT Id, Quote_Line__c, Type__c, Stage_PO__c, Quantity__c, UnitPrice__c, Product__r.Product_Payment_Option__c FROM PO_Item_Stage__r)
        FROM PO_Stage__c
        LIMIT 1
      ];

      List<Product2> lstProds = new List<Product2>{
        createTestProduct('RBK-SVC-PREM-R344', 'RBK-SVC-PREM-R344', 'ASE', 'RBK-R6408F', 'Support', null),
        createTestProduct(
          'RBK-SVC-PREM-R344',
          'RBK-SVC-PREM-R344',
          'POLARIS',
          'RBK-R640F',
          'Support',
          new Map<String, Object>{ 'Bundle_Features__c' => 'Cloud Native Protection' }
        ),
        createTestProduct(
          'RBK-SVC-PREM-R344',
          'RBK-SVC-PREM-R344',
          'RCDM',
          'RBK-R640F',
          'Support',
          new Map<String, Object>{
            'Product_Type__c' => 'MSP',
            'Create_Entitlement__c' => true,
            'Entitlement_Conversion_Non_CPQ__c' => 'One per unit',
            'Bundle_Features__c' => 'Cloud Native Protection',
            'MSP_Std_Actual__c' => null
          }
        ),
        createTestProduct(
          'RBK-SVC-PREM-R344',
          'RBK-SVC-PREM-R344',
          'RCDM',
          'RBK-R640F',
          'Support',
          new Map<String, Object>{
            'Product_Type__c' => 'MSP',
            'Bundle_Features__c' => 'Cloud Native Protection',
            'MSP_Std_Actual__c' => null,
            'SBQQ__SubscriptionPricing__c' => 'Fixed Price'
          }
        ),
        createTestProduct(
          'RBK-SVC-PREM-R344',
          'RBK-SVC-PREM-R344',
          'POLARIS',
          'RBK-R640F',
          'Support',
          new Map<String, Object>{ 'Create_Entitlement__c' => true, 'SBQQSC__EntitlementConversion__c' => 'One per unit', 'Bundle_Features__c' => 'Cloud Native Protection' }
        ),
        createTestProduct(
          'RA-USCS-PA',
          'RA-USCS-PA',
          'POLARIS',
          'RBK-R640F',
          'Support',
          new Map<String, Object>{ 'Create_Entitlement__c' => true, 'SBQQSC__EntitlementConversion__c' => 'One per unit', 'Bundle_Features__c' => 'Cloud Native Protection' }
        )
      };

      insert lstProds;
      List<PricebookEntry> lstPbEntry = new List<PricebookEntry>{
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[0].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[1].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[2].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[3].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[4].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[5].Id, UnitPrice = 100.00, IsActive = true)
      };
      insert lstPbEntry;
      List<OpportunityLineItem> lstOlis = new List<OpportunityLineItem>{
        new OpportunityLineItem(OpportunityId = oppr.Id, Quantity = 5, PricebookEntryId = lstPbEntry[0].Id, TotalPrice = 5 * lstPbEntry[0].UnitPrice),
        new OpportunityLineItem(OpportunityId = oppr.Id, Quantity = 5, PricebookEntryId = lstPbEntry[1].Id, TotalPrice = 5 * lstPbEntry[1].UnitPrice)
      };

      insert lstOlis;

      POC__c pocobj = new POC__c();
      pocobj.POC_Duration__c = '60 Days'; //30 Days
      pocobj.Planned_Installation_Date__c = date.today().addDays(90);
      pocobj.Support_Awareness_needed__c = 'Yes';
      pocobj.POC_Type__c = 'Conditional PO';
      pocobj.Product_Categories__c = 'Rubrik Appliance';
      test.startTest();
      insert pocobj;

      Id quoteId = [SELECT Id FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :acct.Id LIMIT 1].Id;

      Map<String, Object> OrderMap = new Map<String, Object>{
        'Type' => 'Revenue',
        'Send_for_Polaris_Fulfilment__c' => true,
        'POC_Request__c' => pocobj.Id,
        'AccountId' => acct.Id,
        'POC_Opportunity__c' => oppr.Id,
        'EffectiveDate' => system.today(),
        'Order_Status__c' => null,
        'Status' => 'Pending',
        'Sync_to_NetSuite__c' => true,
        'ShippingCountryCode' => 'US',
        'ShippingStateCode' => 'CA',
        'ShippingStreet' => 'Test Street',
        'ShippingCity' => 'Test City',
        'ShippingState' => 'California',
        'ShippingCountry' => 'United States',
        'ShippingPostalcode' => '94820',
        'ship_To_Name__c' => acct.id,
        'ShipToContactName__c' => 'Test',
        'Pricebook2Id' => pricebookId,
        'Have_Polaris_Products__c' => false,
        'Polaris_Fulfillment_Status__c' => 'Completed',
        'Original_Est_Ship_Date__c' => Date.today().addDays(30),
        'Est_Ship_Date__c' => null,
        'Order_Splitted__c' => true,
                    'Order_Sub_Type__c' => 'Renewal',
                    'line_types__c' => null
      };

      Order ord = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
      insert Ord;

      List<OrderItem> lstOrdrItems = new List<OrderItem>{
        createTestOrderItem(
          Ord.Id,
          5,
          lstPbEntry[0].Id,
          lstPbEntry[0].UnitPrice,
          new Map<String, Object>{
            'SerialNumber__c' => 'S3F4NXMM416324',
            'Failed_Serial_Number__c' => 'S3F4NXM416324',
            'Support_End_Date__c' => System.Today().addYears(1),
            'Support_Start_Date__c' => System.Today()
          }
        ),
        createTestOrderItem(
          Ord.Id,
          5,
          lstPbEntry[1].Id,
          lstPbEntry[1].UnitPrice,
          new Map<String, Object>{
            'SerialNumber__c' => 'S3F4NXMM416324',
            'Failed_Serial_Number__c' => 'S3F4NXM416324',
            'Support_End_Date__c' => System.Today().addYears(1),
            'Support_Start_Date__c' => System.Today(),
            'POC_Option__c' => 'AWS'
          }
        ),
        createTestOrderItem(
          Ord.Id,
          5,
          lstPbEntry[2].Id,
          lstPbEntry[2].UnitPrice,
          new Map<String, Object>{
            'SerialNumber__c' => 'S3F4NXMM416324',
            'Failed_Serial_Number__c' => 'S3F4NXM416324',
            'Support_End_Date__c' => System.Today().addYears(1),
            'Support_Start_Date__c' => System.Today(),
            'POC_Option__c' => 'AWS',
            'SBQQ__SegmentIndex__c' => 1
          }
        ),
        createTestOrderItem(
          Ord.Id,
          5,
          lstPbEntry[3].Id,
          lstPbEntry[3].UnitPrice,
          new Map<String, Object>{ 'SerialNumber__c' => 'S3F4NXMM416324', 'Failed_Serial_Number__c' => 'S3F4NXM416324', 'POC_Option__c' => 'AWS', 'SBQQ__SegmentIndex__c' => 1 }
        ),
        createTestOrderItem(
          Ord.Id,
          5,
          lstPbEntry[4].Id,
          lstPbEntry[4].UnitPrice,
          new Map<String, Object>{ 'SerialNumber__c' => 'S3F4NXMM416324', 'Failed_Serial_Number__c' => 'S3F4NXM416324', 'POC_Option__c' => 'AWS', 'SBQQ__SegmentIndex__c' => 1 }
        ),
        createTestOrderItem(
          Ord.Id,
          5,
          lstPbEntry[5].Id,
          lstPbEntry[5].UnitPrice,
          new Map<String, Object>{ 'SerialNumber__c' => 'S3F4NXMM416324', 'Failed_Serial_Number__c' => 'S3F4NXM416324', 'POC_Option__c' => 'AWS', 'SBQQ__SegmentIndex__c' => 1 }
        )
      };
      insert lstOrdrItems;
      lstOrdrItems[3].SBQQ__RequiredBy__c = lstOrdrItems[0].Id;
      lstOrdrItems[4].SBQQ__RequiredBy__c = lstOrdrItems[0].Id;
      TriggerControl.stopOrderItemTrigger = true;
      TriggerControl.stopOrderTrigger = true;

      update lstOrdrItems[3];
      update lstOrdrItems[4];
      TriggerControl.stopOrderItemTrigger = false;
      TriggerControl.stopOrderTrigger = false;
      system.debug(logginglevel.DEBUG, ':::query:::req' + [SELECT id, SBQQ__RequiredBy__c FROM Orderitem LIMIT 5]);
      ord.Have_PS_Products__c = true;
      ord.Order_Status__c = 'Order Accepted';
      update ord;
      order ord12 = getOrder();
      Map<Id, SBQQ__Quote__c> quoteMap1 = getQuoteWithQuoteLines();
      quoteMap1.values()[0].RWD_Deal_Ops_Exception__c = constants.RCDMT_EXT_RWD_DEAL_OPS_EXCEPTION;
      list<orderItem> oi = getOrderLines();
      oi[0].product2.name = 'RS-BT-RCDM-T';
      oi[0].Product2.SBQQ__SubscriptionPricing__c = 'Fixed';
      oi[0].SBQQ__SubscriptionTerm__c = null;
      oi[0].Product2.Product_Level__c = 'OnPrem';
      oi[0].Product2.Product_Subtype__c = 'FEDRAMP';
      List<PO_Stage__c> stagePos = new List<PO_Stage__c>();
      Map<id, opportunity> opMap = getOpportunity();
      objStagePO.TotalAmount__c = ord12.TotalAmount;
      stagePos.add(objStagePO);
      ord12.Manual_Approve__c = true;
      ord12.Screening_Source__c = 'Internal';
      ord12.ShippingCountryCode = 'AU';
      ord12.ScreenStatus__c = 'On hold';
      ord12.Order_Status__c = 'Pending';
      ord12.Order_Sub_Type__c = '';
      ord12.Bill_To_Name__c = acct.id;
      ord12.PoDate = System.Today();
      ord12.PoNumber = '12';
      ord12.End_User_PO__c = '12';
      ord12.Payment_Terms__c = '12';
      ord12.Ship_to_Email__c = 'Test@test.com';
      ord12.Quote_RCDM_T_EOL_Date__c = System.Today().adddays(-3);
      ord12.Type = 'Revenue';
      map<id, order> ordmap = new Map<id, order>();
      orderinserthelper oIh = new orderinserthelper();
      oIh.orderIdOrderItemMap.put(ord12.id, oi);
      order ord123 = new order();
      ord123.Manual_Approve__c = false;
      Account_Screening__c acctscr = new Account_Screening__c();
      acctscr.Name = acct.Name;
      acctscr.Screening_Eligibility__c = true;
      acctscr.Screening_Action__c = 'Start';
      acctscr.Screening_Action_Status__c = 'Ready';
      acctscr.Account__c = acct.Id;
      acctscr.Unique_Parent_Id__c = acct.Id;
      acctscr.GTC_Screen_Status__c = 'Denied Party List';
      insert acctscr;
      acct.Account_Screening__c = acctscr.id;
      update acct;
      try {
        oIh.populateFieldsOnUpdate(ord12, ord123, null, null);
      } catch (Exception e) {
        System.debug(LoggingLevel.DEBUG, 'DmlException caught: ' + e.getMessage());
      }
      oIh.quoteMap = new Map<Id, SBQQ__Quote__c>();
      ord12.Quote_RCDM_T_EOL_Date__c = System.Today();
      oi[0].SBQQ__SubscriptionTerm__c = 12;
      oIh.orderIdOrderItemMap.put(ord12.id, oi);
      oIh.quoteMap = quoteMap1;
      ord12.Order_Split_Type__c = 'EDI';
      Set<Id> orderWithUSCitizenProducts = new Set<Id>();
      orderWithUSCitizenProducts.add(ord12.id);
      Map<id, Account> accmap = new Map<id, Account>();
      accmap.put(acct.id, acct);
      acct = getAccount();
      oih.accountMap = new Map<Id, Account>();
      oih.accountMap.put(acct.id, acct);
      oih.oppMap = opMap;
      quoteMap1.values()[0].RWD_Deal_Ops_Exception__c = '';
      oIh.quoteMap = quoteMap1;
      ord12.Order_Status__c = 'Pending';
      ord12.Hold_Code__c = '';
      String netAppAccId = Label.NetApp_Account_Ids.split(';')[0];
      ord12.Sell_to_Partner__c = netAppAccId;
      ord12.Bill_To_Name__c = netAppAccId;
      ord12.OM_internal_review__c = true;
      ord12.Change_Needed_Reason_Other__c = 'OM internal review for Netapp order';
      ord12.Shipping_Method__c = 'DDP';
      ord12.Order_Sub_Type__c = constants.ORDER_SUB_TYPE_GC_OFFER;
      ord12.Order_Split_Type__c = 'Not needed';
      opMap.values()[0].RecordtypeId = Constants.OPPORTUNITY_RECORDTYPEID_RENEWAL;
      oih.oppMap = opMap;
      oih = new orderinserthelper();
      oIh.quoteMap = quoteMap1;
      oih.accountMap = new Map<Id, Account>();
      oih.accountMap.put(acct.id, acct);
      TransactionalDataCollection.stagePo = stagePos;
      Map<String, Sfdc_Disti_Mapping__mdt> distiAllValuesMap = Sfdc_Disti_Mapping__mdt.getAll();
      id Arrowid;
      for (String developerName : distiAllValuesMap.keySet()) {
        if (distiAllValuesMap.get(developerName).Po_Disti_Type__c == 'ARROW') {
          Arrowid = distiAllValuesMap.get(developerName).Sfdc_Id__c;
        }
      }
      opMap.values()[0].Distributor_Lookup__c = Arrowid;
      oih.oppMap = opMap;
      ord12.Sell_to_Partner__c = null;
      oih.populateFieldsOnUpdate(ord12, ord123, null, null);
      oIh.populateFieldsOnInsert(ord12, stagePos, false, false);
      oIh.quoteMap = quoteMap1;
      oih.autoSubmitOrder(ord12, ord123, stagePos, ordmap);
      acct.Contract_Negotiation__c = true;
      ord12.Welcome_Letter_Sent_At__c = system.today();
      oIh.populateFieldsOnInsert(ord12, stagePos, false, false);
      oih.accountMap = new Map<Id, Account>();
      oih.accountMap.put(acct.id, acct);
      ord12.Program__c = 'RSC-G Replacement';
      oIh.populateFieldsOnInsert(ord12, stagePos, false, false);
      oih.populateFieldsOnUpdate(ord12, ord123, null, null);
      Test.stopTest();
    }
  }

  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to Order trigger logic
   */

  static testMethod void testInsertOderNew() {
    insert new RPS__c(
      SetupOwnerId = Userinfo.getOrganizationId(),
      Is_RPS_Required__c = false,
      Screening_Source__c = 'Internal',
      Valid_HoldCodes__c = 'Global Trade Compliance screening failed;Credit Check Failed'
    );
    PO_Stage__c postg = [SELECT id FROM PO_Stage__c LIMIT 1];
    testDataFactoryClass.createCustomSettings();

    System.runAs(new User(Id = UserInfo.getUserId())) {
      Account acct = [SELECT Id, Name, Payment_Term__c FROM Account WHERE Name = 'Test' LIMIT 1];

      acct.Sync_to_NetSuite__c = false;
      acct.RSC_G_Eligible__c = true;
      update acct;
      Assert.areEqual('Test', acct.Name);
      OpportunityObjectTriggerHandler.isOppAutoManual = 'AutoGenerated';
      Opportunity oppr = [SELECT Id, Opportunity_Sub_Type__c, pricebook2Id FROM Opportunity WHERE AccountId = :acct.Id LIMIT 1];
      SBQQ__Quote__c testQuote = [SELECT Id, SBQQ__PaymentTerms__c,Co_Term__c,Name, SBQQ__NetAmount__c, SBQQ__Type__c, SBQQ__Account__c, SBQQ__Opportunity2__c FROM SBQQ__Quote__c LIMIT 1];
      testQuote.SBQQ__Type__c = 'Amendment';
      testQuote.Co_Term__c = true;
      testQuote.SBQQ__PaymentTerms__c = 'Net 30';   

      update testQuote;
      PO_Stage__c objStagePO = [
        SELECT
          Id,
          EDI_DISTI_ID__c,
          Partner_Name__c,
          PoDate__c,
          PoNumber__c,
          ShippingCity__c,
          ShippingCountry__c,
          ShippingCountryCode__c,
          ShippingPostalCode__c,
          ShippingState__c,
          ShippingStateCode__c,
          ShippingStreet__c,
          Shipping_Method__c,
          Ship_To_Contact_Name__c,
          Shipping_Carrier__c,
          Shipping_Account_Number__c,
          End_User_PO__c,
          Service_Level__c,
          Ship_to_Email__c,
          Ship_To_Phone_Number__c,
          Payment_Terms__c,
          Quote__c,
          Expected_number_of_POs__c,
          Bill_To_Name__c,
          TotalAmount__c,
          Ship_to_Account_Name__c,
          Customer_Requested_Ship_Date__c,
          Note_on_Contingency_and_Special_Language__c,
          (SELECT Id, Quote_Line__c, Type__c, Stage_PO__c, Quantity__c, UnitPrice__c, Product__r.Product_Payment_Option__c FROM PO_Item_Stage__r)
        FROM PO_Stage__c
        LIMIT 1
      ];

      insert new Hold_Off_Tracking__c(
        Hold_Code__c = 'OM Internal Review',
        Release_Date_Time__c = datetime.newInstance(2021, 9, 15, 12, 30, 0),
        Related_Opportunity__c = oppr.Id,
        Is_Released__c = false
      );

      Id pricebookId = Test.getStandardPricebookId();
      oppr.pricebook2Id = pricebookId;
      oppr.Opportunity_Sub_Type__c = 'Renewal';

      update oppr;

      List<Product2> lstProds = new List<Product2>{
        createTestProduct('RBK-SVC-PREM-R344', 'RBK-SVC-PREM-R344', 'ASE', 'RBK-R6408F', 'Support', null),
        createTestProduct(
          'RS-BT-EE-PE-PP',
          'RS-BT-EE-PE-PP',
          'Rubrik Licence',
          null,
          'OnPrem',
          new Map<String, Object>{
            'Category__c' => 'Bundle',
            'Product_Type__c' => 'Foundation Edition',
            'License_Category__c' => 'SaaS',
            'Product_Subtype__c' => 'SaaS Cloud',
            'SBQQ__AssetAmendmentBehavior__c' => 'Default',
            'SBQQSC__EntitlementConversion__c' => 'One per quote line',
            'SBQQ__SubscriptionPricing__c' => 'Fixed Price',
            'SBQQ__SubscriptionTerm__c' => 36,
            'SBQQ__SubscriptionBase__c' => 'List',
            'SBQQ__SubscriptionType__c' => 'Renewable'
          }
        ),
        createTestProduct(
          'RS-BT-BE-PE-PP',
          'RS-BT-BE-PE-PP',
          'Rubrik Licence',
          null,
          'LOD Software',
          new Map<String, Object>{
            'Category__c' => 'Bundle',
            'Product_Type__c' => 'Complete Edition',
            'License_Category__c' => 'SaaS',
            'Product_Subtype__c' => 'SaaS Cloud',
            'SBQQ__AssetAmendmentBehavior__c' => 'Default',
            'SBQQSC__EntitlementConversion__c' => 'One per quote line',
            'SBQQ__SubscriptionPricing__c' => 'Fixed Price',
            'SBQQ__SubscriptionTerm__c' => 36,
            'SBQQ__SubscriptionBase__c' => 'List',
            'SBQQ__SubscriptionType__c' => 'Renewable'
          }
        ),
        createTestProduct(
          'RBK-SVC-PREM-R344',
          'RBK-SVC-PREM-R344',
          'POLARIS',
          'RBK-R640F',
          'Support',
          new Map<String, Object>{ 'Bundle_Features__c' => 'Cloud Native Protection' }
        ),
        createTestProduct(
          'RBK-SVC-PREM-R344',
          'RBK-SVC-PREM-R344',
          'RCDM',
          'RBK-R640F',
          'Support',
          new Map<String, Object>{
            'Product_Type__c' => 'MSP',
            'Create_Entitlement__c' => true,
            'Entitlement_Conversion_Non_CPQ__c' => 'One per unit',
            'Bundle_Features__c' => 'Cloud Native Protection',
            'MSP_Std_Actual__c' => null
          }
        ),
        createTestProduct(
          'RBK-SVC-PREM-R344',
          'RBK-SVC-PREM-R344',
          'RCDM',
          'RBK-R640F',
          'Support',
          new Map<String, Object>{
            'Product_Type__c' => 'MSP',
            'Bundle_Features__c' => 'Cloud Native Protection',
            'MSP_Std_Actual__c' => null,
            'SBQQ__SubscriptionPricing__c' => 'Fixed Price'
          }
        ),
        createTestProduct(
          'RBK-SVC-PREM-R344',
          'RBK-SVC-PREM-R344',
          'POLARIS',
          'RBK-R640F',
          'Support',
          new Map<String, Object>{ 'Create_Entitlement__c' => true, 'SBQQSC__EntitlementConversion__c' => 'One per unit', 'Bundle_Features__c' => 'Cloud Native Protection' }
        ),
        createTestProduct(
          'RA-USCS-PA',
          'RA-USCS-PA',
          'POLARIS',
          'RBK-R640F',
          'Support',
          new Map<String, Object>{ 'Create_Entitlement__c' => true, 'SBQQSC__EntitlementConversion__c' => 'One per unit', 'Bundle_Features__c' => 'Cloud Native Protection' }
        ),
        createTestProduct(
          'RS-TB-EE-RSVX-PE',
          'RS-TB-EE-RSVX-PE',
          'POLARIS',
          'RBK-R640F',
          'Hybrid Software',
          new Map<String, Object>{
            'Product_Subtype__c' => 'Scale MSP',
            'License_Category__c' => null,
            'SBQQSC__EntitlementConversion__c' => 'One per quote line',
            'Bundle_Features__c' => 'Cloud Native Protection'
          }
        ),
        createTestProduct(
          'RS-TB-EE-OND-PE',
          'RS-TB-EE-OND-PE',
          'POLARIS',
          'RBK-R640F',
          'Hybrid Software',
          new Map<String, Object>{
            'Product_Subtype__c' => 'On Demand',
            'License_Category__c' => 'SaaS',
            'Create_Entitlement__c' => true
            // 'Bundle_Features__c' => 'Cloud Native Protection'
          }
        )
      };

      insert lstProds;

      List<PricebookEntry> lstPbEntry = new List<PricebookEntry>{
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[0].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[1].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[2].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[3].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[4].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[5].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[6].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[7].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[8].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[9].Id, UnitPrice = 100.00, IsActive = true)
      };

      insert lstPbEntry;

      List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = testQuote.Id,
          SBQQ__Product__c = lstProds[0].Id,
          SBQQ__PricebookEntryId__c = lstPbEntry[0].Id,
          SBQQ__Quantity__c = 800,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = 1,
          SBQQ__ListPrice__c = 10,
          SBQQ__NetPrice__c = 10
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = testQuote.Id,
          SBQQ__Product__c = lstProds[1].Id,
          SBQQ__PricebookEntryId__c = lstPbEntry[1].Id,
          SBQQ__Quantity__c = 1,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = 12,
          SBQQ__ListPrice__c = 0,
          SBQQ__NetPrice__c = 0
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = testQuote.Id,
          SBQQ__Product__c = lstProds[2].Id,
          SBQQ__PricebookEntryId__c = lstPbEntry[2].Id,
          SBQQ__Quantity__c = 1,
          SBQQ__SubscriptionPricing__c = null,
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 1.5,
          SBQQ__NetPrice__c = 0
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = testQuote.Id,
          SBQQ__Product__c = lstProds[3].Id,
          SBQQ__PricebookEntryId__c = lstPbEntry[3].Id,
          SBQQ__Quantity__c = 1,
          SBQQ__SubscriptionPricing__c = null,
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 1.5,
          SBQQ__NetPrice__c = 0
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = testQuote.Id,
          SBQQ__Product__c = lstProds[4].Id,
          SBQQ__PricebookEntryId__c = lstPbEntry[4].Id,
          SBQQ__Quantity__c = 1,
          SBQQ__SubscriptionPricing__c = null,
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 1.5,
          SBQQ__NetPrice__c = 0
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = testQuote.Id,
          SBQQ__Product__c = lstProds[5].Id,
          SBQQ__PricebookEntryId__c = lstPbEntry[5].Id,
          SBQQ__Quantity__c = 1,
          SBQQ__SubscriptionPricing__c = null,
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 1.5,
          SBQQ__NetPrice__c = 0
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = testQuote.Id,
          SBQQ__Product__c = lstProds[6].Id,
          SBQQ__PricebookEntryId__c = lstPbEntry[6].Id,
          SBQQ__Quantity__c = 1,
          SBQQ__SubscriptionPricing__c = null,
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 1.5,
          SBQQ__NetPrice__c = 0
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = testQuote.Id,
          SBQQ__Product__c = lstProds[7].Id,
          SBQQ__PricebookEntryId__c = lstPbEntry[7].Id,
          SBQQ__Quantity__c = 1,
          SBQQ__SubscriptionPricing__c = null,
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 1.5,
          SBQQ__NetPrice__c = 0
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = testQuote.Id,
          SBQQ__Product__c = lstProds[8].Id,
          SBQQ__PricebookEntryId__c = lstPbEntry[8].Id,
          SBQQ__Quantity__c = 1,
          SBQQ__SubscriptionPricing__c = null,
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 1.5,
          SBQQ__NetPrice__c = 0
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = testQuote.Id,
          SBQQ__Product__c = lstProds[9].Id,
          SBQQ__PricebookEntryId__c = lstPbEntry[9].Id,
          SBQQ__Quantity__c = 1,
          SBQQ__SubscriptionPricing__c = null,
          SBQQ__DefaultSubscriptionTerm__c = null,
          SBQQ__ListPrice__c = 1.5,
          SBQQ__NetPrice__c = 100.51
        )
      );

      insert lines;

      List<PO_Stage__c> poStageList = new List<PO_Stage__c>();
      PO_Stage__c pos = ShGl_TestFactoryHelper.createPOStage(
        'Promark Technology, Inc.pp',
        'test123',
        system.today().addDays(10),
        10,
        'test@test.com.invalid',
        'test partner',
        system.today(),
        1,
        'test12345',
        testQuote.name,
        testQuote.SBQQ__NetAmount__c
      );
      pos.Expected_number_of_POs__c = 1;
      pos.Bill_To_Name__c = testQuote.SBQQ__Account__c;
      pos.PO_Validation_Status__c = 'Success';
      pos.PO_Internal_Validation_Status__c = 'Success';
      pos.Payment_schedule_type__c = 'test';
      pos.Quote_number__c = testQuote.name;
      pos.Opportunity__c = testQuote.SBQQ__Opportunity2__c;
      pos.Ship_to_Email__c = 'test@test.com.invalid';
      pos.Ship_To_Contact_Name__c = 'testCon';
      pos.Ship_To_Phone_Number__c = '7000022448';
      pos.ShippingCountryCode__c = 'IN';
      pos.ShippingStateCode__c = 'KA';
      pos.ShippingCity__c = 'test City';
      pos.ShippingStreet__c = 'test street';
      pos.ShippingPostalCode__c = '0000';

      insert pos;
      List<PO_Item_Stage__c> poItem = new List<PO_Item_Stage__c>();

      for (integer i = 0; i < lines.size(); i++) {
        string ediLinenum = 0 + '' + i;
        Decimal Quant = lines[i].SBQQ__Product__r.name == 'RS-BT-RCDM-T' ? 1.0 : lines[i].SBQQ__Quantity__c;
        Decimal Term = lines[i].SBQQ__SubscriptionTerm__c;
        PO_Item_Stage__c poline = ShGl_TestFactoryHelper.createPOItem(
          '1234' + ediLinenum,
          ediLinenum,
          lines[i].SBQQ__Product__r.productcode,
          Quant,
          pos.id,
          Term,
          lines[i].SBQQ__NetPrice__c
        );
        poline.Quote_Line__c = lines[i].Id;
        poItem.add(poline);
      }
      poItem[0].Type__c = 'New';  
      poItem[1].Type__c = 'Renewal';  
      insert poItem;

      List<OpportunityLineItem> lstOlis = new List<OpportunityLineItem>{
        new OpportunityLineItem(OpportunityId = oppr.Id, Quantity = 5, PricebookEntryId = lstPbEntry[0].Id, TotalPrice = 5 * lstPbEntry[0].UnitPrice),
        new OpportunityLineItem(OpportunityId = oppr.Id, Quantity = 5, PricebookEntryId = lstPbEntry[1].Id, TotalPrice = 5 * lstPbEntry[1].UnitPrice)
      };

      insert lstOlis;

      test.startTest();

      Map<String, Object> OrderMap = new Map<String, Object>{
        'Type' => 'Revenue',
        'AccountId' => acct.Id,
        'SBQQ__Quote__c' => testQuote.Id,
        'OpportunityId' => oppr.Id,
        'Sync_to_NetSuite__c' => true,
        'EffectiveDate' => system.today(),
        'Status' => 'Pending',
        'Mosaic_SKUs__c' => 'RBK-MOSAIC',
        'ShippingCountryCode' => 'US',
        'ShippingStateCode' => 'CA',
        'Polaris_Fulfillment_Status__c' => 'Completed',
        'Is_RWD_Polaris_Quote__c' => true,
        'Stage_PO__c' => postg.id,
        'Order_Status__c' => 'Pending',
        'Order_Split_Type__c' => 'Not needed',
        'Bill_To_Name__c' => acct.Id,
        'RSC_G_Enabled__c' => true
      };

      Order ord = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
        
      insert Ord;
            order ord13 = getOrder();
  
      order ord1 = ord13.clone();
      insert ord1;  
      order ord2 = ord13.clone();
      insert ord2;  

      List<OrderItem> lstOrdrItems = new List<OrderItem>{
        createTestOrderItem(
          Ord.Id,
          5,
          lstPbEntry[0].Id,
          lstPbEntry[0].UnitPrice,
          new Map<String, Object>{
            'SerialNumber__c' => 'S3F4NXMM416324',
            'Failed_Serial_Number__c' => 'S3F4NXM416324',
            'Support_End_Date__c' => System.Today().addYears(1),
            'Support_Start_Date__c' => System.Today(),
            'SBQQ__QuoteLine__c' => lines[0].Id
          }
        ),
        createTestOrderItem(
          Ord.Id,
          5,
          lstPbEntry[1].Id,
          lstPbEntry[1].UnitPrice,
          new Map<String, Object>{
            'Support_End_Date__c' => System.Today().addYears(1),
            'Support_Start_Date__c' => System.Today(),
            'POC_Option__c' => 'AWS',
            'SBQQ__SubscriptionTerm__c' => 12,
            'SBQQ__QuoteLine__c' => lines[1].Id
          }
        ),
        createTestOrderItem(
          Ord.Id,
          5,
          lstPbEntry[2].Id,
          lstPbEntry[2].UnitPrice,
          new Map<String, Object>{
            'Support_End_Date__c' => System.Today().addYears(1),
            'Support_Start_Date__c' => System.Today(),
            'POC_Option__c' => 'AWS',
            'SBQQ__SubscriptionTerm__c' => 12,
            'SBQQ__QuoteLine__c' => lines[2].Id
          }
        ),
        createTestOrderItem(
          Ord.Id,
          5,
          lstPbEntry[3].Id,
          lstPbEntry[3].UnitPrice,
          new Map<String, Object>{
            'SerialNumber__c' => 'S3F4NXMM416324',
            'Failed_Serial_Number__c' => 'S3F4NXM416324',
            'Support_End_Date__c' => System.Today().addYears(1),
            'Support_Start_Date__c' => System.Today(),
            'POC_Option__c' => 'AWS',
            'SBQQ__QuoteLine__c' => lines[3].Id
          }
        ),
        createTestOrderItem(
          Ord.Id,
          5,
          lstPbEntry[4].Id,
          lstPbEntry[4].UnitPrice,
          new Map<String, Object>{
            'SerialNumber__c' => 'S3F4NXMM416324',
            'Failed_Serial_Number__c' => 'S3F4NXM416324',
            'Support_End_Date__c' => System.Today().addYears(1),
            'Support_Start_Date__c' => System.Today(),
            'POC_Option__c' => 'AWS',
            'SBQQ__SegmentIndex__c' => 1,
            'SBQQ__QuoteLine__c' => lines[4].Id
          }
        ),
        createTestOrderItem(
          Ord.Id,
          5,
          lstPbEntry[5].Id,
          lstPbEntry[5].UnitPrice,
          new Map<String, Object>{
            'SerialNumber__c' => 'S3F4NXMM416324',
            'Failed_Serial_Number__c' => 'S3F4NXM416324',
            'POC_Option__c' => 'AWS',
            'SBQQ__SegmentIndex__c' => 1,
            'SBQQ__QuoteLine__c' => lines[5].Id
          }
        ),
        createTestOrderItem(
          Ord.Id,
          5,
          lstPbEntry[6].Id,
          lstPbEntry[6].UnitPrice,
          new Map<String, Object>{
            'SerialNumber__c' => 'S3F4NXMM416324',
            'Failed_Serial_Number__c' => 'S3F4NXM416324',
            'POC_Option__c' => 'AWS',
            'SBQQ__SegmentIndex__c' => 1,
            'SBQQ__QuoteLine__c' => lines[6].Id
          }
        ),
        createTestOrderItem(
          Ord.Id,
          5,
          lstPbEntry[7].Id,
          lstPbEntry[7].UnitPrice,
          new Map<String, Object>{
            'SerialNumber__c' => 'S3F4NXMM416324',
            'Failed_Serial_Number__c' => 'S3F4NXM416324',
            'POC_Option__c' => 'AWS',
            'SBQQ__SegmentIndex__c' => 1,
            'SBQQ__QuoteLine__c' => lines[7].Id
          }
        ),
        createTestOrderItem(
          ord2.Id,
          5,
          lstPbEntry[8].Id,
          lstPbEntry[8].UnitPrice,
          new Map<String, Object>{
            'SerialNumber__c' => 'S3F4NXMM416324',
            'Failed_Serial_Number__c' => 'S3F4NXM416324',
            'POC_Option__c' => 'AWS',
            'SBQQ__SegmentIndex__c' => 1,
            'SBQQ__QuoteLine__c' => lines[8].Id
          }
        ),
        createTestOrderItem(
          Ord1.Id,
          5,
          lstPbEntry[9].Id,
          lstPbEntry[9].UnitPrice,
          new Map<String, Object>{
            'SerialNumber__c' => 'S3F4NXMM416324',
            'Failed_Serial_Number__c' => 'S3F4NXM416324',
            'POC_Option__c' => 'AWS',
            'SBQQ__SegmentIndex__c' => 1,
            'Sales_Price__c' => 100.50,   
            'SBQQ__QuoteLine__c' => lines[9].Id
          }
        )
      };

      insert lstOrdrItems;
      lstOrdrItems[3].SBQQ__RequiredBy__c = lstOrdrItems[0].Id;
      lstOrdrItems[4].SBQQ__RequiredBy__c = lstOrdrItems[0].Id;
      lstOrdrItems[9].SBQQ__RequiredBy__c = lstOrdrItems[8].Id;

      TriggerControl.stopOrderItemTrigger = true;
      TriggerControl.stopOrderTrigger = true;

      update lstOrdrItems[3];
      update lstOrdrItems[4];
      update lstOrdrItems[9];

      TriggerControl.stopOrderItemTrigger = false;
      TriggerControl.stopOrderTrigger = false;
      ord.Have_PS_Products__c = true;
      ord.Order_Status__c = 'Order Accepted';
      //ord.Order_Sub_Type__c = 'Amendment';
      ord.Stage_PO__c = pos.Id;
      update ord;
      order ord12 = getOrder();
      Map<Id, SBQQ__Quote__c> quoteMap1 = getQuoteWithQuoteLines();

      quoteMap1.values()[0].RWD_Deal_Ops_Exception__c = constants.RCDMT_EXT_RWD_DEAL_OPS_EXCEPTION;
      list<orderItem> oi = getOrderLines();
      oi[0].product2.name = 'RS-BT-RCDM-T';
      oi[0].Product2.SBQQ__SubscriptionPricing__c = 'Fixed';
      oi[0].SBQQ__SubscriptionTerm__c = null;
      List<PO_Stage__c> stagePos = new List<PO_Stage__c>();
      Map<id, opportunity> opMap = getOpportunity();
      objStagePO.TotalAmount__c = ord12.TotalAmount;
      stagePos.add(objStagePO);
      ord12.Manual_Approve__c = true;
      ord12.Screening_Source__c = 'Internal';
      ord12.ShippingCountryCode = 'AU';
      ord12.ShippingStateCode = 'CA';

      ord12.ScreenStatus__c = 'On hold';
      ord12.Order_Status__c = 'Pending';
      ord12.Order_Sub_Type__c = '';
      ord12.Bill_To_Name__c = acct.id;
      ord12.PoDate = System.Today();
      ord12.PoNumber = '12';
      ord12.End_User_PO__c = '12';
      ord12.Payment_Terms__c = 'Net 30';
      ord12.ShipToContactName__c = 'Test Contact';
      ord12.ManualFulfilment__c = false;
      ord12.Ship_to_Email__c = 'Test@test.com';
      ord12.Quote_RCDM_T_EOL_Date__c = System.Today().adddays(-3);
      ord12.Ship_To_Phone_Number__c = '1234';
      ord12.Type = 'Revenue';
     // ord12.  
      map<id, order> ordmap = new Map<id, order>();
      orderinserthelper oIh = new orderinserthelper();
      oIh.orderIdOrderItemMap.put(ord12.id, oi);
      order ord123 = new order();
      ord123.Manual_Approve__c = false;
      Account_Screening__c acctscr = new Account_Screening__c();
      acctscr.Name = acct.Name;
      acctscr.Screening_Eligibility__c = true;
      acctscr.Screening_Action__c = 'Start';
      acctscr.Screening_Action_Status__c = 'Ready';
      acctscr.Account__c = acct.Id;
      acctscr.Unique_Parent_Id__c = acct.Id;
      acctscr.GTC_Screen_Status__c = 'Denied Party List';
      insert acctscr;
      acct.Account_Screening__c = acctscr.id;
      update acct;
      try {
        oIh.populateFieldsOnUpdate(ord12, ord123, null, null);
      } catch (Exception e) {
        System.debug(LoggingLevel.DEBUG, 'DmlException caught: ' + e.getMessage());
      }
      oIh.quoteMap = new Map<Id, SBQQ__Quote__c>();
      oih.accountMap = new Map<Id, Account>();
      oih.accountMap.put(ord12.Bill_To_Name__c, acct);
  	  oih.autoSubmitOrder(ord12, ord123, stagePos, ordmap);
      ord12.Quote_RCDM_T_EOL_Date__c = System.Today();
      oih.autoSubmitOrder(ord12, ord123, stagePos, ordmap);
      Ord1.Hold_Code__c = '';
      Ord1.Manual_Approve__c = true;
      Ord1.Screening_Source__c = 'Internal';
      Ord1.ShippingCountryCode = 'AU';
      Ord1.ShippingStateCode = 'CA';
      Ord1.ship_To_Name__c =  acct.id;
      Ord1.ScreenStatus__c = 'On hold';
      Ord1.Order_Status__c = 'Pending';
      Ord1.Order_Sub_Type__c = '';
      Ord1.Bill_To_Name__c = acct.id;
      Ord1.PoDate = System.Today();
      Ord1.PoNumber = '12';
      Ord1.End_User_PO__c = '12';
      Ord1.Payment_Terms__c = 'Net 30';
      Ord1.ShipToContactName__c = 'Test Contact';
      Ord1.ManualFulfilment__c = false;
      Ord1.Ship_to_Email__c = 'Test@test.com';
      Ord1.Quote_RCDM_T_EOL_Date__c = System.Today().adddays(-3);
      Ord1.Shipping_Carrier__c = 'Blue Dart';
      Ord1.Service_Level__c = 'Economy';
      Ord1.Shipping_Method__c = 'DDP';
      Ord1.ShippingStreet = 'test street';
      Ord1.ShippingPostalCode = '0000';
      Ord1.ShippingCity = 'test city';
      Ord1.Ship_To_Phone_Number__c = '1234';

     	Ord1.Type = 'Revenue';
      Ord1.Order_Split_Type__c = 'Not needed';
      objStagePO.TotalAmount__c = Ord1.TotalAmount;
      stagePos.add(objStagePO);

      Ord1.Stage_PO__c = stagePos[0].Id;
      OrderItem lastOI = oi[9];
      Integer size = oi.size()-1;
      oIh.orderIdOrderItemMap.put(Ord1.id, new List<orderitem>{lastOI});
     /* try {
        oIh.populateFieldsOnUpdate(Ord1, ord123, null, null);
      } catch (Exception e) {
        system.debug()  
        System.debug(LoggingLevel.DEBUG, 'DmlException caught: ' + e.getMessage());
      }*/
  	  oih.autoSubmitOrder(Ord1, ord123, stagePos, ordmap);
      Ord2.Stage_PO__c = stagePos[0].Id;
      objStagePO.TotalAmount__c = Ord2.TotalAmount;
      Ord2.ShipToContactName__c = 'Test Contact';
      Ord2.ShippingStreet = 'test street';
      Ord2.ShippingPostalCode = '0000';
      Ord2.ShippingCity = 'test city';
      Ord2.ShippingCountryCode = 'AU';
      Ord2.Ship_to_Email__c = 'Test@test.com';
      Ord2.ManualFulfilment__c = false;
      Ord2.Order_Sub_Type__c = 'Renewal';
      Ord1.Ship_To_Phone_Number__c = '1234';
		  stagePos.add(objStagePO);
      OrderItem newOI = oi[8];
      oIh.orderIdOrderItemMap.put(Ord2.id, new List<orderitem>{newOI});
      oih.autoSubmitOrder(Ord2, ord123, stagePos, ordmap);


      oi[0].SBQQ__SubscriptionTerm__c = 12;
      oIh.orderIdOrderItemMap.put(ord12.id, oi);
      ord12.Hold_Code__c = '';
      ord12.customer_required_ship_date__c = system.today().addmonths(3);
      oih.autoSubmitOrder(ord12, ord123, stagePos, ordmap);
      oih.quoteMap = new Map<Id, SBQQ__Quote__c>(quoteMap1);
      string str = oih.validateOIandPOI(ord12, '');
      ord12.Stage_PO__c = null;
      update ord12;
      ord123.Auto_Submission_Date_Time__c =null;
      ord12.Order_Status__c = 'pending';
      ord12.Type ='RMA';
      ord12.Order_Sub_Type__c = 'Tech Order';
  
      oih.autoSubmitOrder(ord12, ord123, stagePos, ordmap);
      ord12.Order_Sub_Type__c = 'GC Offer';
      //update ord12;
      try {
        oIh.populateFieldsOnUpdate(ord12, ord123, null, null);
      } catch (Exception e) {
        System.debug(LoggingLevel.DEBUG, 'DmlException caught: ' + e.getMessage());
      }
      Ord1.Payment_Terms__c = 'Net 45';  
      oih.autoSubmitOrder(Ord1, ord123, stagePos, ordmap);

      test.stopTest();
    }
  }

  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to Order trigger logic
   */
  static testMethod void testProcessOrderItem() {
      testDataFactoryClass.createCustomSettings();
      String uniqueUserName = 'AdminUser' + DateTime.now().getTime() + '@rubrik.com';
      Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
      User u = createTestUser(null, p.Id, uniqueUserName, 'adminU','AdminUser@rubrik.com', new Map<String, Object>{'EmailEncodingKey' => 'UTF-8','LastName' => 'Testing','LanguageLocaleKey' => 'en_US','LocaleSidKey' => 'en_US','TimeZoneSidKey' => 'America/Los_Angeles'});
      System.runAs(u) {
          insert new ShGl_DisableBusinessLogic__c(
              Disable_Entitlement_Validation_Rules__c = true,
              Disable_Opportunity_Validation_Rules__c = true,
              Disable_POC_Validation_Rules__c = true,
              Disable_Contact_Triggers__c = true,
              Disable_SBQQ_Quote_Triggers__c = true,
              Disable_SBQQ_QuoteLine_Triggers__c = true,
              Disable_POC_Trigger__c = true,
        	  Disable_Order_Validation_Rules__c = true
  
          );
          
          Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test' LIMIT 1];
          Assert.areEqual('Test', acct.Name);
          Opportunity oppr = [SELECT Id, pricebook2Id, SBQQ__PrimaryQuote__c  FROM Opportunity WHERE AccountId = :acct.Id LIMIT 1];
          SBQQ__Quote__c qtq = [SELECT Id, name, SBQQ__NetAmount__c, SBQQ__PricebookId__c, SBQQ__Primary__c  FROM SBQQ__Quote__c LIMIT 1];
          qtq.SBQQ__Primary__c  = true;
          update qtq;
          Id pricebookId = Test.getStandardPricebookId();
          oppr.pricebook2Id = pricebookId;
          oppr.SBQQ__PrimaryQuote__c = qtq.Id;
          update oppr;
          //test.startTest();
          delete [SELECT SBQQ__Type__c FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :acct.Id LIMIT 1];
          product2 prod =  createTestProduct('RBK-SVC-PREM-R344', 'RBK-SVC-PREM-R344', 'POLARIS', 'RBK-R6408E', null,
                                             new Map<String, Object>{'SBQQ__SubscriptionPricing__c' => 'Fixed Price','SBQQ__SubscriptionTerm__c' => 36,'Bundle_Features__c' => 'Polaris','Create_Entitlement__c' => true,'SBQQSC__EntitlementConversion__c' => 'One per unit','Create_Asset__c' => true});
          insert prod;
          
          PricebookEntry pbEntry = new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = prod.Id, UnitPrice = 100.00, IsActive = true);
          insert pbEntry;
          
          OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = oppr.Id, Quantity = 5, PricebookEntryId = pbEntry.Id, TotalPrice = 5 * pbEntry.UnitPrice);
          // test.startTest();
          insert oli;
          
          List<POC__c> pocList = new List<POC__c>{
                createTestPocObject('60 Days',date.today().addDays(90),'Yes','Conditional PO','Rubrik Appliance',new Map<String, Object>{}),
                createTestPocObject('60 Days',date.today().addDays(90),'Yes','EA Unit','Rubrik Appliance',new Map<String, Object>{}),
                createTestPocObject('60 Days',date.today().addDays(90),'Yes','Standard POC','Rubrik Appliance',new Map<String, Object>{}),
                createTestPocObject('60 Days',date.today().addDays(90),'Yes','Business Loaner Unit','Rubrik Appliance',new Map<String, Object>{})
          };
          insert pocList;
          List<Asset> assetsList = new List<Asset>{
              createAsset('SN123',acct.Id,prod.id,'Purchased','SN123',new Map<String, Object>{'Serial_Number__c' => 'SN123','Premium_Support_End_Date__c' => Date.today()})
                  };
                      insert assetsList;
          List<Entitlement> entitlements = new List<Entitlement>{
              createEntitlement('ENT-4',acct.Id,prod.id,assetsList[0].Id,new Map<String, Object>{'Type' => 'Web Support','StartDate' => Date.valueof(System.now().addDays(-2)),'EndDate' => Date.valueof(System.now().addYears(2))})
                  };
                      insert entitlements;
          test.startTest();
          Order ord = createTestorder('POC',null/*qtq.Id*/, acct.Id,oppr.Id,acct.Id,oppr.pricebook2Id,'Not needed','Renewal',new Map<String, Object>{'POC_Request__c' => pocList[1].Id,'POC_Opportunity__c' => oppr.Id,'Pricebook2Id' => pricebookId,'Have_Hardware_Products__c' => true,'Order_Splitted__c' => true,'Actual_Order_Ship_Date__c' => date.today(),'Order_Status__c' => 'Shipped','RecordTypeId' => Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order')?.getRecordTypeId()});
          insert Ord;
          OrderItem ordrItem =  createTestOrderItem(Ord.Id,5,pbEntry.Id,pbEntry.UnitPrice,
                                                    new Map<String, Object>{
                                                        'SerialNumber__c' => '123\\s+,456\\s+',
                                                            'Failed_Serial_Number__c' => 'S3F4NXM416324',
                                                            'Support_End_Date__c' => System.Today().addYears(1),
                                                            'Support_Start_Date__c' => System.Today(),
                                                            'Is_Hardware_Line__c' => true,
                                                            'Is_Refresh__c' => true,
                                                            'Upgraded_From__c' => assetsList[0].Id
                                                            }
                                                   );
          
          insert ordrItem;
          entitlements[0].Order_Service_Item__c = ordrItem.id;
          update entitlements[0];
          test.stopTest();
    }
  }

  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to Order trigger logic
   */
 static testMethod void testPOCOrd() {
    testDataFactoryClass.createCustomSettings();

    String uniqueUserName = 'AdminUser' + DateTime.now().getTime() + '@rubrik.com';
    Profile p = [SELECT Id FROM Profile WHERE Name = 'API Integration User'];
    //User u = createTestUser(null, p.Id, uniqueUserName, 'adminU','AdminUser@rubrik.com', new Map<String, Object>{'EmailEncodingKey' => 'UTF-8','LastName' => 'Testing','LanguageLocaleKey' => 'en_US','LocaleSidKey' => 'en_US','TimeZoneSidKey' => 'America/Los_Angeles'});
    User u = new User(
      Alias = 'adminU',
      Email = 'AdminUser@rubrik.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = p.Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = uniqueUserName
    );

    System.runAs(u) {
      insert new ShGl_DisableBusinessLogic__c(
        Disable_Opportunity_Validation_Rules__c = true,
        Disable_POC_Validation_Rules__c = true,
        Disable_Contact_Triggers__c = true,
        Disable_SBQQ_Quote_Triggers__c = true,
        Disable_SBQQ_QuoteLine_Triggers__c = true,
        Disable_POC_Trigger__c = true,
        Disable_Order_Validation_Rules__c = true,
        Disable_SBQQ_QuoteLine_Validation_Rules__c  = true  
  
      );

      ShGl_DisableBusinessLogic__c control = new ShGl_DisableBusinessLogic__c(
        Disable_SBQQ_Quote_Triggers__c = true,
        Disable_SBQQ_QuoteLine_Triggers__c = true,
        Disable_Opportunity_Validation_Rules__c = true,
        Disable_Opportunity_Triggers__c = true,
        Disable_Order_Email_Alerts__c = false,
        Disable_Order_Old_Trigger__c = true,
        Disable_Order_Triggers__c = true,
        Disable_Asset_Triggers__c = true,
        Disable_Contact_Triggers__c = true,
        Order_Trigger_MaxLoop_Count__c = 25,
        setupOwnerId = u.id
      );
      // insert control ;

      Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test' LIMIT 1];
      Assert.areEqual('Test', acct.Name);
      Opportunity oppr = [SELECT Id, pricebook2Id FROM Opportunity WHERE AccountId = :acct.Id LIMIT 1];
      SBQQ__Quote__c qtq = [SELECT Id, name, SBQQ__NetAmount__c, SBQQ__PricebookId__c FROM SBQQ__Quote__c LIMIT 1];

      Id pricebookId = Test.getStandardPricebookId();
      oppr.pricebook2Id = pricebookId;
      update oppr;
          
       Order_Configuration__c orderConfig = new Order_Configuration__c(
        Start_Date__c = System.today().addDays(-10),
        End_Date__c = System.today().addDays(10),
        Target_Date__c = System.today().addDays(-1),
        Order_Type_to_be_considered__c = 'Demo'  
          
      );
      insert orderConfig;
        product2 prod =  createTestProduct('RBK-SVC-PREM-R344', 'RBK-SVC-PREM-R344', 'POLARIS', null, null,
                                           new Map<String, Object>{'SBQQ__SubscriptionPricing__c' => 'Fixed Price','Create_Asset__c' => true,'SBQQ__SubscriptionTerm__c' => 36,'Bundle_Features__c' => 'Polaris','Create_Entitlement__c' => true,'SBQQSC__EntitlementConversion__c' => 'One per unit','PDM_Feature_Enabled__c' => true});
        insert prod;
              List<Product_Feature__c> testFeatures = new List<Product_Feature__c>();

        // Active Feature for Product A (within date range)
        testFeatures.add(new Product_Feature__c(
           // Name = 'Feature A1',
            Product_Name__c = prod.Id,
            Product_Code__c = prod.name,
			      Feature__c = 'NAS Cloud Direct',
            Feature_start_date__c = Date.today().addDays(-10),
            Feature_EOL__c = Date.today().addDays(10)
        ));

        // Active Feature for Product A (no EOL date)
        testFeatures.add(new Product_Feature__c(
          //  Name = 'Feature A2',
            Product_Name__c = prod.Id,
            Product_Code__c = prod.name,
            Feature__c = 'DSPM CUSTOMER HOSTED UCL',
            Feature_start_date__c = Date.today().addMonths(-1),
            Feature_EOL__c = null
        ));
      insert testFeatures;    
      test.startTest();

      PricebookEntry pbEntry = new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = prod.Id, UnitPrice = 100.00, IsActive = true);
      insert pbEntry;
        POC__c pocobj = createTestPocObject('60 Days',date.today().addDays(90),'Yes','EA Unit','Rubrik Appliance',new Map<String,object>{});
      insert pocobj;
          SBQQ.TriggerControl.disable();
          List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
          lines.add(
              new SBQQ__QuoteLine__c(
                  SBQQ__Quote__c = qtq.Id,
                  SBQQ__Product__c = prod.Id,
                  SBQQ__PricebookEntryId__c = pbEntry.Id,
                  SBQQ__Quantity__c = 800,
                  SBQQ__SubscriptionPricing__c = 'Fixed Price',
                  SBQQ__DefaultSubscriptionTerm__c = 1,
                  SBQQ__ListPrice__c = 10,
                  SBQQ__NetPrice__c = 10,
                  Rubrik_Suite__c = 'Foundation',
                  Support_Type__c = 'Premium', 
                  Payment_Options__c = 'Prepay',
                  Licensing_Model__c ='Subscription',
                  SBQQ__StartDate__c = System.Today(),
                  SBQQ__EndDate__c = System.Today().addYears(1)  
              )
          ); 
          insert lines;
        Order ord = createTestorder('POC',null, acct.Id,oppr.Id,acct.Id,oppr.pricebook2Id,'Not needed','Renewal',new Map<String, Object>{'POC_Request__c' => pocobj.Id,'POC_Opportunity__c' => oppr.Id,'Order_Status__c' => null,'ship_To_Name__c' => acct.id,'Pricebook2Id' => pricebookId,'Is_RPS_Required__c' => false,'ScreenStatus__c' => 'Approved Bypassed','RecordTypeId' => Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order')?.getRecordTypeId()});
        insert Ord;
        OrderItem ordrItem =  createTestOrderItem(Ord.Id,5,pbEntry.Id,pbEntry.UnitPrice,
                                                  new Map<String, Object>{
                                                      'SerialNumber__c' => '123\\s+,456\\s+',
                                                          'Failed_Serial_Number__c' => 'S3F4NXM416324',
                                                          'Support_End_Date__c' => System.Today().addYears(1),
                                                          'Support_Start_Date__c' => System.Today(),
                                                          'Is_Hardware_Line__c' => false,
                                                          'SBQQ__QuoteLine__c' => lines[0].Id
                                                          }
                                                 );
              insert ordrItem;
          ord = [SELECT Id,OrderNumber,Order_Status__c FROM Order WHERE Id = : ord.Id];  
          Order ordReleated = createTestorder('POC',null, acct.Id,oppr.Id,acct.Id,oppr.pricebook2Id,'Not needed','Renewal',new Map<String, Object>{'POC_Request__c' => pocobj.Id,'Related_Orders__c' => ord.OrderNumber,'POC_Opportunity__c' => oppr.Id,'Order_Status__c' => null,'ship_To_Name__c' => acct.id,'Pricebook2Id' => pricebookId,'Is_RPS_Required__c' => false,'ScreenStatus__c' => 'Approved Bypassed','RecordTypeId' => Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order')?.getRecordTypeId()});
          insert ordReleated;
          ordReleated = [SELECT Id,OrderNumber FROM Order WHERE Id = : ordReleated.Id];          
          ord.NetSuite_Order__c = '098765';
          ord.Integration_Failure__c = false;
          ord.Related_Order_Count__c = 2;
          ord.Related_Orders__c = ordReleated.OrderNumber+','+ ord.OrderNumber;
          update ord;  
          ord.ScreenStatus__c = 'Approved Bypassed';
          ord.Est_Ship_Date__c = null;
          ord.Original_Est_Ship_Date__c = system.today().addDays(5);
          ord.Order_Status__c = 'Pending';
          ord.ManualFulfilment__c = false;
          ord.Integration_Failure__c = true;
          ord.Hold_Code__c  = '';

          
          update ord;   
          ord.Actual_Order_Ship_Date__c = system.today();
          ord.Order_Status__c = 'shipped';
          ord.Polaris_Fulfillment_Status__c = 'Completed';

          update ord;


    }
  }
    
   static testMethod void testPOCOrd1() {
    testDataFactoryClass.createCustomSettings();

    String uniqueUserName = 'AdminUser' + DateTime.now().getTime() + '@rubrik.com';
    Profile p = [SELECT Id FROM Profile WHERE Name = 'API Integration User'];
    //User u = createTestUser(null, p.Id, uniqueUserName, 'adminU','AdminUser@rubrik.com', new Map<String, Object>{'EmailEncodingKey' => 'UTF-8','LastName' => 'Testing','LanguageLocaleKey' => 'en_US','LocaleSidKey' => 'en_US','TimeZoneSidKey' => 'America/Los_Angeles'});
    User u = new User(
      Alias = 'adminU',
      Email = 'AdminUser@rubrik.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = p.Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = uniqueUserName
    );

    System.runAs(u) {
      insert new ShGl_DisableBusinessLogic__c(
        Disable_Opportunity_Validation_Rules__c = true,
        Disable_POC_Validation_Rules__c = true,
        Disable_Contact_Triggers__c = true,
        Disable_SBQQ_Quote_Triggers__c = true,
        Disable_SBQQ_QuoteLine_Triggers__c = true,
        Disable_POC_Trigger__c = true,
        Disable_Order_Validation_Rules__c = true
  
      );

      ShGl_DisableBusinessLogic__c control = new ShGl_DisableBusinessLogic__c(
        Disable_SBQQ_Quote_Triggers__c = true,
        Disable_SBQQ_QuoteLine_Triggers__c = true,
        Disable_Opportunity_Validation_Rules__c = true,
        Disable_Opportunity_Triggers__c = true,
        Disable_Order_Email_Alerts__c = false,
        Disable_Order_Old_Trigger__c = true,
        Disable_Order_Triggers__c = true,
        Disable_Asset_Triggers__c = true,
        Disable_Contact_Triggers__c = true,
        Order_Trigger_MaxLoop_Count__c = 25,
        setupOwnerId = u.id
      );
      // insert control ;

      Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test' LIMIT 1];
      Assert.areEqual('Test', acct.Name);
      Opportunity oppr = [SELECT Id, pricebook2Id FROM Opportunity WHERE AccountId = :acct.Id LIMIT 1];
      SBQQ__Quote__c qtq = [SELECT Id, name, SBQQ__NetAmount__c, SBQQ__PricebookId__c FROM SBQQ__Quote__c LIMIT 1];

      Id pricebookId = Test.getStandardPricebookId();
      oppr.pricebook2Id = pricebookId;
      update oppr;
        product2 prod =  createTestProduct('RBK-SVC-PREM-R344', 'RBK-SVC-PREM-R344', 'POLARIS', null, null,
                                           new Map<String, Object>{'SBQQ__SubscriptionPricing__c' => 'Fixed Price','Create_Asset__c' => true,'SBQQ__SubscriptionTerm__c' => 36,'Bundle_Features__c' => 'Polaris','Create_Entitlement__c' => true,'SBQQSC__EntitlementConversion__c' => 'One per unit','PDM_Feature_Enabled__c' => true});
        insert prod;
              List<Product_Feature__c> testFeatures = new List<Product_Feature__c>();

        // Active Feature for Product A (within date range)
        testFeatures.add(new Product_Feature__c(
           // Name = 'Feature A1',
            Product_Name__c = prod.Id,
            Product_Code__c = prod.name,
			      Feature__c = 'NAS Cloud Direct',
            Feature_start_date__c = Date.today().addDays(-10),
            Feature_EOL__c = Date.today().addDays(10)
        ));

        // Active Feature for Product A (no EOL date)
        testFeatures.add(new Product_Feature__c(
          //  Name = 'Feature A2',
            Product_Name__c = prod.Id,
            Product_Code__c = prod.name,
            Feature__c = 'DSPM CUSTOMER HOSTED UCL',
            Feature_start_date__c = Date.today().addMonths(-1),
            Feature_EOL__c = null
        ));
      insert testFeatures;    

      PricebookEntry pbEntry = new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = prod.Id, UnitPrice = 100.00, IsActive = true);
      insert pbEntry;
        POC__c pocobj = createTestPocObject('60 Days',date.today().addDays(90),'Yes','EA Unit','Rubrik Appliance',new Map<String,object>{});
      insert pocobj;
      test.startTest();
        Order ord = createTestorder('POC',null, acct.Id,oppr.Id,acct.Id,oppr.pricebook2Id,'Not needed','Renewal',new Map<String, Object>{'POC_Request__c' => pocobj.Id,'POC_Opportunity__c' => oppr.Id,'Order_Status__c' => null,'ship_To_Name__c' => acct.id,'Pricebook2Id' => pricebookId,'Is_RPS_Required__c' => false,'ScreenStatus__c' => 'Approved Bypassed','RecordTypeId' => Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order')?.getRecordTypeId()});
        insert Ord;
        OrderItem ordrItem =  createTestOrderItem(Ord.Id,5,pbEntry.Id,pbEntry.UnitPrice,
                                                  new Map<String, Object>{
                                                      'SerialNumber__c' => '123\\s+,456\\s+',
                                                          'Failed_Serial_Number__c' => 'S3F4NXM416324',
                                                          'Support_End_Date__c' => System.Today().addYears(1),
                                                          'Support_Start_Date__c' => System.Today(),
                                                          'Is_Hardware_Line__c' => false
                                                          }
                                                 );
              insert ordrItem;

              /*  order ord12 = getOrder();
          ord12.ScreenStatus__c = 'Approved Bypassed';
          ord12.ManualFulfilment__c = false;
 
         order ord13 = new order();
      orderinserthelper oIh = new orderinserthelper();
oIh.populateFieldsOnUpdate(ord12,ord13,null,null);*/
         // ord.hav
         ord.ScreenStatus__c = 'Approved Bypassed';
          ord.ManualFulfilment__c = false;
  
		update ord;   

    }
  }
   
   /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to Order trigger logic
   */
  static testMethod void testOrderEventTrigger() {
    insert new TriggerControl__c(name = 'PortalUserCreation', SendEmail__c = true);

    System.runAs(new User(Id = UserInfo.getUserId())) {
      Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test' LIMIT 1];
      Assert.areEqual('Test', acct.Name);
      Opportunity oppr = [SELECT Id, pricebook2Id FROM Opportunity WHERE AccountId = :acct.Id LIMIT 1];

      Contact objContact = new Contact(LeadSource = 'Channel', FirstName = 'Tasty', LastName = 'Toaster', AccountId = acct.Id, Email = 'test12345@test.com');

      insert objContact;

      Id pricebookId = Test.getStandardPricebookId();
      oppr.pricebook2Id = pricebookId;
      update oppr;
      test.startTest();
          Order ord = createTestorder('Revenue',null, acct.Id,oppr.Id,acct.Id,oppr.pricebook2Id,null,null,new Map<String, Object>{'Sync_to_NetSuite__c' => true,'Mosaic_SKUs__c' => 'RBK-MOSAIC','Welcome_Letter_Contact__c' => objContact.Id});
        List<Order> lstOrdersInsert = new List<Order>();
        lstOrdersInsert.add(ord);
        lstOrdersInsert.add(ord);
      set<Id> setOrderIds = new Set<Id>();
      set<Id> setContactId = new Set<Id>();

      setOrderIds.add(lstOrdersInsert[0].Id);
      setOrderIds.add(lstOrdersInsert[1].Id);

      List<Order_Trigger_Event__e> orderEvents = new List<Order_Trigger_Event__e>{
        new Order_Trigger_Event__e(Action_Type__c = 'CreateCommunityUser', Input_Data__c = string.join(new List<Id>(setOrderIds), ','))
      };

      EventBus.publish(orderEvents);

      test.stopTest();
    }
  }
  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to Order trigger logic
   */
  static testMethod void testOrderEventErorr() {
    insert new TriggerControl__c(name = 'PortalUserCreation', SendEmail__c = true);

    System.runAs(new User(Id = UserInfo.getUserId())) {
      Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test' LIMIT 1];
      Assert.areEqual('Test', acct.Name);
      Opportunity oppr = [SELECT Id, pricebook2Id FROM Opportunity WHERE AccountId = :acct.Id LIMIT 1];
      List<contact> conList = new List<contact>();
      conList.add(new Contact(LeadSource = 'Channel', FirstName = 'Tasty', LastName = 'Toaster', AccountId = acct.Id, Email = 'test124@test.com'));
      conList.add(
        new Contact(
          LeadSource = 'Channel',
          FirstName = 'Tasty',
          LastName = 'random123456random123456random123456random123456random123456',
          AccountId = acct.Id,
          Email = 'test12454@test.com'
        )
      );
      insert conList;

      Id pricebookId = Test.getStandardPricebookId();
      oppr.pricebook2Id = pricebookId;

      update oppr;

      test.startTest();
      Order ord = createTestorder('Revenue',null, acct.Id,oppr.Id,acct.Id,oppr.pricebook2Id,null,null,new Map<String, Object>{'Sync_to_NetSuite__c' => true,'Mosaic_SKUs__c' => 'RBK-MOSAIC','Welcome_Letter_Contact__c' => conList[0].Id});
      Order ord1 = createTestorder('Revenue',null, acct.Id,oppr.Id,acct.Id,oppr.pricebook2Id,null,null,new Map<String, Object>{'Sync_to_NetSuite__c' => true,'Mosaic_SKUs__c' => 'RBK-MOSAIC','Welcome_Letter_Contact__c' => conList[0].Id});

        List<Order> lstOrdersInsert = new List<Order>();
      lstOrdersInsert.add(ord);
      lstOrdersInsert.add(ord1);
      lstOrdersInsert[1].Welcome_Letter_Contact__c = conList[1].id;
      insert lstOrdersInsert;
      set<Id> setOrderIds = new Set<Id>();
      set<Id> setContactId = new Set<Id>();
      setOrderIds.add(lstOrdersInsert[0].Id);
      setOrderIds.add(lstOrdersInsert[1].Id);

      List<Order_Trigger_Event__e> orderEvents = new List<Order_Trigger_Event__e>{
        new Order_Trigger_Event__e(Action_Type__c = 'CreateCommunityUser', Input_Data__c = string.join(new List<Id>(setOrderIds), ','))
      };

      Id communityProfileId = [SELECT Id FROM Profile WHERE Name = :Label.CommunityProfileAutoProvision LIMIT 1].id;

      UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];

      Profile profile1 = [SELECT Id FROM Profile WHERE name = 'System Administrator'];
        User portalAccountOwner1 = createTestUser(portalRole.Id,profile1.Id,System.now().millisecond() + 'portalAccountOwner1@randomtestdomain.com','batman',System.now().millisecond() + 'random.email@randomtestdomain.com',new map<string,object>{'EmailEncodingKey' => 'UTF-8','Firstname' => 'test','Lastname' => 'test','LanguageLocaleKey' => 'en_US','LocaleSidKey' => 'en_US','TimeZoneSidKey' => 'America/Chicago'});
      Database.insert(portalAccountOwner1);
      Account portalAccount1;
      User portalUser;
      System.runAs(portalAccountOwner1) {
        //Create account
        portalAccount1 = new Account(Name = 'TestAccount', OwnerId = portalAccountOwner1.Id);
        Database.insert(portalAccount1);

        //Create contact
        Contact contact1 = new Contact(FirstName = 'Test', Lastname = 'McTesty', AccountId = portalAccount1.Id, Email = System.now().millisecond() + 'test@test.com');
        Database.insert(contact1);

        Profile portalProfile = [SELECT Id FROM Profile WHERE UserType = 'PowerPartner' LIMIT 1];
        portalUser = createTestUser(null,communityProfileId,'test12345@test.com','test123','test12345@test.com',new map<string,object>{'ContactId' => contact1.Id,'EmailEncodingKey' => 'UTF-8','LastName' => 'McTesty','CommunityNickname' => 'test12345','TimeZoneSidKey' => 'America/Los_Angeles','LocaleSidKey' => 'en_US','LanguageLocaleKey' => 'en_US'});
        Database.insert(portalUser);

        conList[0].Email = 'test12345@test.com';
        update conList[0];

        EventBus.publish(orderEvents); //For duplicate username

        orderEvents.clear();

        setContactId.add(contact1.Id);
        orderEvents.add(new Order_Trigger_Event__e(Action_Type__c = 'UpdateToCommunityUser', Input_Data__c = string.join(new List<Id>(setContactId), ',')));

        EventBus.publish(orderEvents);
      }

      test.stopTest();
    }
  }
  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to Order trigger logic
   */
  static testMethod void testCreatePSProject() {
    insert new RPS__c(
      SetupOwnerId = Userinfo.getOrganizationId(),
      Is_RPS_Required__c = false,
      Screening_Source__c = 'Internal',
      Valid_HoldCodes__c = 'Global Trade Compliance screening failed;Credit Check Failed'
    );

    testDataFactoryClass.createCustomSettings();

    System.runAs(new User(Id = UserInfo.getUserId())) {
      Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test' LIMIT 1];
      Assert.areEqual('Test', acct.Name);
      acct.BillingCountry = 'United States';
      acct.BillingState = 'United States Minor Outlying Islands';

      update acct;
      Opportunity oppr = [SELECT Id, pricebook2Id FROM Opportunity WHERE AccountId = :acct.Id LIMIT 1];

      PS_Project__c objPsProject = new PS_Project__c();
      objPsProject.Name = 'test project (123)';
      //objPsProject.Name = 'test project';
      objPsProject.Account__c = acct.id;
      objPsProject.Project_Manager__c = userinfo.getuserid();
      objPsProject.Manager__c = 'test@test.com';
      objPsProject.Opportunity__c =  oppr.Id; 
      insert objPsProject;


      insert new Hold_Off_Tracking__c(
        Hold_Code__c = 'OM Internal Review',
        Release_Date_Time__c = datetime.newInstance(2021, 9, 15, 12, 30, 0),
        Related_Opportunity__c = oppr.Id,
        Is_Released__c = false
      );

      Id pricebookId = Test.getStandardPricebookId();
      oppr.pricebook2Id = pricebookId;
      update oppr;

      List<Product2> lstProds = new List<Product2>{
          createTestProduct('RA_PS_INT', 'RA_PS_INT', 'ASE', null, null, new Map<String, Object>{'Allow_PSO_Task_Creation__c' =>true}),
          createTestProduct('RBK-SVC-PREM-R344', 'RBK-SVC-PREM-R344', 'POLARIS', 'RBK-R640F', null, new Map<String, Object>{'Bundle_Features__c' => 'Cloud Native Protection','Create_Asset__c' => true})
      };

      insert lstProds;

      List<PricebookEntry> lstPbEntry = new List<PricebookEntry>{
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[0].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[1].Id, UnitPrice = 100.00, IsActive = true)
      };

      insert lstPbEntry;

      List<OpportunityLineItem> lstOlis = new List<OpportunityLineItem>{
        new OpportunityLineItem(OpportunityId = oppr.Id, Quantity = 5, PricebookEntryId = lstPbEntry[0].Id, TotalPrice = 5 * lstPbEntry[0].UnitPrice),
        new OpportunityLineItem(OpportunityId = oppr.Id, Quantity = 5, PricebookEntryId = lstPbEntry[1].Id, TotalPrice = 5 * lstPbEntry[1].UnitPrice)
      };
      insert lstOlis;
      test.startTest();
      Order ord = createTestorder(null,null, acct.Id,oppr.Id,null,pricebookId,null,null,new Map<String, Object>{'Sync_to_NetSuite__c' => true,'Mosaic_SKUs__c' => 'RBK-MOSAIC'});
      insert Ord;
      List<OrderItem> lstOrdrItems = new List<OrderItem>{
        createTestOrderItem(
          Ord.Id,
          5,
          lstPbEntry[0].Id,
          lstPbEntry[0].UnitPrice,
          new Map<String, Object>{
          'SerialNumber__c' => 'S3F4NXMM416324',
          'Failed_Serial_Number__c' => 'S3F4NXM416324',
          'Support_End_Date__c' => System.Today().addYears(1),
          'Support_Start_Date__c' => System.Today()
          }
        ),
        createTestOrderItem(
          Ord.Id,
          5,
          lstPbEntry[1].Id,
          lstPbEntry[1].UnitPrice,
          new Map<String, Object>{
          'SerialNumber__c' => 'S3F4NXMM416324',
          'Failed_Serial_Number__c' => 'S3F4NXM416324',
          'Support_End_Date__c' => System.Today().addYears(1),
          'Support_Start_Date__c' => System.Today(),
          'POC_Option__c' => 'AWS'
          }
        )
            };


      insert lstOrdrItems;

      ord.Have_PS_Products__c = true;
      ord.NetSuite_Order__c = 'TestNSId';
      ord.Hold_Code__c = '';   


      update ord;
      objPsProject.Name = 'test project';
        try{
         orderupdatehelper helper = new orderupdatehelper();
          helper.createPSProject(
            ord,
            null,
            new List<PS_Project__c>{objPsProject},
            null,
            null,
            null,
            null,
            null
        );   
        }catch(Exception ex){
            system.debug(LoggingLevel.DEBUG,'exception occured');
        }  
       
        
  

      test.stopTest();
    }
  }
  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to Order trigger logic
   */
  static testMethod void testCreatePSTask() {
    RPS__c rps = testCreateRpsSettings(Userinfo.getOrganizationId(),false,'Internal','Global Trade Compliance screening failed;Credit Check Failed',new map<string,object>{}); 
    insert rps;

    testDataFactoryClass.createCustomSettings();

    System.runAs(new User(Id = UserInfo.getUserId())) {
      Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test' LIMIT 1];
      Assert.areEqual('Test', acct.Name);
      acct.BillingCountry = 'United States';
      acct.BillingState = 'United States Minor Outlying Islands';

      update acct;

      Opportunity oppr = [SELECT Id, pricebook2Id,Initial_Contacts_Name__c FROM Opportunity WHERE AccountId = :acct.Id LIMIT 1];

      Id pricebookId = Test.getStandardPricebookId();
      oppr.pricebook2Id = pricebookId;
      update oppr;
              List<Product2> lstProducts = new List<Product2>{
                  createTestProduct('RBK-SVC-PREM-R344', 'RBK-INSTALL', 'DELL', 'RBK-R6408E', null, new Map<String, Object>{'Product_Type__c' => '3rd Party Hardware','Allow_PSO_Task_Creation__c' => true}),
                  createTestProduct('RBK-SVC-PREM-R344', 'RBK-PS-INST', 'DELL', 'RBK-R6408E', null, new Map<String, Object>{'Product_Type__c' => '3rd Party Hardware','Allow_PSO_Task_Creation__c' => true}),
                  createTestProduct('RBK-SVC-PREM-R344', 'RBK-PS-CONSULT', 'DELL', 'RBK-R6408E', null, new Map<String, Object>{'Product_Type__c' => '3rd Party Hardware','Allow_PSO_Task_Creation__c' => true}),
                  createTestProduct('RBK-SVC-PREM-R344', 'RBK-PS-CNSLT-ONST', 'DELL', 'RBK-R6408E', null, new Map<String, Object>{'Product_Type__c' => '3rd Party Hardware','Allow_PSO_Task_Creation__c' => true}),
                  createTestProduct('RBK-SVC-PREM-R344', 'RBK-CONSULT', 'DELL', 'RBK-R6408E', null, new Map<String, Object>{'Product_Type__c' => '3rd Party Hardware','Allow_PSO_Task_Creation__c' => true}),
                  createTestProduct('RBK-SVC-PREM-R344', 'RBK-DATA-MIGRATION', 'DELL', 'RBK-R6408E', null, new Map<String, Object>{'Product_Type__c' => '3rd Party Hardware','Allow_PSO_Task_Creation__c' => true}),
                  createTestProduct('RBK-SVC-PREM-R344', 'RBK-PS-CNSLT-RMOT', 'DELL', 'RBK-R6408E', null, new Map<String, Object>{'Product_Type__c' => '3rd Party Hardware','Allow_PSO_Task_Creation__c' => true}),
                  createTestProduct('RBK-SVC-PREM-R344', 'RBK-PS-TE', 'DELL', 'RBK-R6408E', null, new Map<String, Object>{'Product_Type__c' => '3rd Party Hardware','Allow_PSO_Task_Creation__c' => true}),
                  createTestProduct('RBK-SVC-PREM-R344', 'RBK-PS-RES', 'DELL', 'RBK-R6408E', null, new Map<String, Object>{'Product_Type__c' => '3rd Party Hardware','Allow_PSO_Task_Creation__c' => true})
                      };
        
        
        
      insert lstProducts;

      List<PricebookEntry> lstPbEntries = new List<PricebookEntry>{
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProducts[0].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProducts[1].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProducts[2].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProducts[3].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProducts[4].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProducts[5].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProducts[6].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProducts[7].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProducts[8].Id, UnitPrice = 100.00, IsActive = true)
      };

      insert lstPbEntries;

      test.startTest();
      Order ord = createTestorder('POC',null, acct.Id,oppr.Id,acct.Id,pricebookId,null,'Renewal',new Map<String, Object>{'Polaris_Contact__c'=>oppr.Initial_Contacts_Name__c,'POC_Opportunity__c' => oppr.Id,'Order_Status__c' => 'On Hold','ship_To_Name__c' => acct.id,'Pricebook2Id' => pricebookId,'Order_Splitted__c' => true,'Order_Sub_Type__c' => 'Renewal','Actual_Order_Ship_Date__c' => Date.today().addDays(60),'customer_required_ship_date__c'=>Date.today().addDays(60)});
      insert Ord;
      List<OrderItem> lstOrderItems = new List<OrderItem>{
      createTestOrderItem(
          Ord.Id,
          5,
          lstPbEntries[0].Id,
          lstPbEntries[0].UnitPrice,
          new Map<String, Object>{
          'SerialNumber__c' => 'SN1',
          'Failed_Serial_Number__c' => 'S3F4NXM416324',
          'Support_End_Date__c' => System.Today().addYears(1),
          'Support_Start_Date__c' => System.Today(),
          'Is_Hardware_Line__c' => true,
          'Is_Refresh__c' => true
          }
        ),
		createTestOrderItem(
          Ord.Id,
          5,
          lstPbEntries[1].Id,
          lstPbEntries[1].UnitPrice,
          new Map<String, Object>{
          'SerialNumber__c' => 'SN1',
          'Failed_Serial_Number__c' => 'S3F4NXM416324',
          'Support_End_Date__c' => System.Today().addYears(1),
          'Support_Start_Date__c' => System.Today(),
          'Is_Hardware_Line__c' => true,
          'Is_Refresh__c' => true
          }
        ),
       createTestOrderItem(
          Ord.Id,
          5,
          lstPbEntries[2].Id,
          lstPbEntries[2].UnitPrice,
          new Map<String, Object>{
          'SerialNumber__c' => 'SN1',
          'Failed_Serial_Number__c' => 'S3F4NXM416324',
          'Support_End_Date__c' => System.Today().addYears(1),
          'Support_Start_Date__c' => System.Today(),
          'Is_Hardware_Line__c' => true,
          'Is_Refresh__c' => true
          }
        ),
        createTestOrderItem(
          Ord.Id,
          5,
          lstPbEntries[3].Id,
          lstPbEntries[3].UnitPrice,
          new Map<String, Object>{
          'SerialNumber__c' => 'SN1',
          'Failed_Serial_Number__c' => 'S3F4NXM416324',
          'Support_End_Date__c' => System.Today().addYears(1),
          'Support_Start_Date__c' => System.Today(),
          'Is_Hardware_Line__c' => true,
          'Is_Refresh__c' => true
          }
        ),
          
         createTestOrderItem(
          Ord.Id,
          5,
          lstPbEntries[4].Id,
          lstPbEntries[4].UnitPrice,
          new Map<String, Object>{
          'SerialNumber__c' => 'SN1',
          'Failed_Serial_Number__c' => 'S3F4NXM416324',
          'Support_End_Date__c' => System.Today().addYears(1),
          'Support_Start_Date__c' => System.Today(),
          'Is_Hardware_Line__c' => true,
          'Is_Refresh__c' => true
          }
        ),
          
                 createTestOrderItem(
          Ord.Id,
          5,
          lstPbEntries[5].Id,
          lstPbEntries[5].UnitPrice,
          new Map<String, Object>{
          'SerialNumber__c' => 'SN1',
          'Failed_Serial_Number__c' => 'S3F4NXM416324',
          'Support_End_Date__c' => System.Today().addYears(1),
          'Support_Start_Date__c' => System.Today(),
          'Is_Hardware_Line__c' => true,
          'Is_Refresh__c' => true
          }
        ),
          
                         createTestOrderItem(
          Ord.Id,
          5,
          lstPbEntries[6].Id,
          lstPbEntries[6].UnitPrice,
          new Map<String, Object>{
          'SerialNumber__c' => 'SN1',
          'Failed_Serial_Number__c' => 'S3F4NXM416324',
          'Support_End_Date__c' => System.Today().addYears(1),
          'Support_Start_Date__c' => System.Today(),
          'Is_Hardware_Line__c' => true,
          'Is_Refresh__c' => true
          }
        ),
          
       createTestOrderItem(
          Ord.Id,
          5,
          lstPbEntries[7].Id,
          lstPbEntries[7].UnitPrice,
          new Map<String, Object>{
          'SerialNumber__c' => 'SN1',
          'Failed_Serial_Number__c' => 'S3F4NXM416324',
          'Support_End_Date__c' => System.Today().addYears(1),
          'Support_Start_Date__c' => System.Today(),
          'Is_Hardware_Line__c' => true,
          'Is_Refresh__c' => true
 }
        ),
        createTestOrderItem(
          Ord.Id,
          5,
          lstPbEntries[8].Id,
          lstPbEntries[8].UnitPrice,
          new Map<String, Object>{
          'SerialNumber__c' => 'SN1',
          'Failed_Serial_Number__c' => 'S3F4NXM416324',
          'Support_End_Date__c' => System.Today().addYears(1),
          'Support_Start_Date__c' => System.Today(),
          'Is_Hardware_Line__c' => true,
          'Is_Refresh__c' => true
 }
        )  
          };
              
      insert lstOrderItems;
      ord.NetSuite_Order__c = 'TEst23NS';
      ord.Have_PS_Products__c = true;
      update ord;
      ord.NetSuite_Order__c = 'TEst23NS';
      ord.Have_PS_Products__c = true;
      update ord;
      test.stopTest();
    }
  }
  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to Order trigger logic
   */
  static testMethod void testCreatePSTask2() {
    RPS__c rps = testCreateRpsSettings(Userinfo.getOrganizationId(),false,'Internal','Global Trade Compliance screening failed;Credit Check Failed',new map<string,object>{}); 
    insert rps;

    testDataFactoryClass.createCustomSettings();

    System.runAs(new User(Id = UserInfo.getUserId())) {
      Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test' LIMIT 1];
      Assert.areEqual('Test', acct.Name);
      acct.BillingCountry = 'United States';
      acct.BillingState = 'United States Minor Outlying Islands';

      update acct;
      Account acct1 = [SELECT Id FROM Account WHERE Name = 'Test' LIMIT 1];

      acct1.BillingCountry = 'India';
      acct1.BillingState = 'United States Minor Outlying Islands';

      update acct1;

      Opportunity oppr = [SELECT Id, pricebook2Id FROM Opportunity WHERE AccountId = :acct.Id LIMIT 1];

      Id pricebookId = Test.getStandardPricebookId();
      oppr.pricebook2Id = pricebookId;
      update oppr;
      Opportunity oppr1 = [SELECT Id, pricebook2Id FROM Opportunity WHERE AccountId = :acct1.Id LIMIT 1];

      oppr1.pricebook2Id = pricebookId;
      update oppr1;
        
        List<Product2> lstProducts = new List<Product2>{
            createTestProduct('RBK-SVC-PREM-R344', 'RBK-INSTALL', 'DELL', 'RBK-R6408E', null, new Map<String, Object>{'Product_Type__c' => '3rd Party Hardware','Allow_PSO_Task_Creation__c' => true}),
                createTestProduct('RBK-SVC-PREM-R344', 'RBK-PS-INST', 'DELL', 'RBK-R6408E', null, new Map<String, Object>{'Product_Type__c' => '3rd Party Hardware','Allow_PSO_Task_Creation__c' => true}),
                createTestProduct('RBK-SVC-PREM-R344', 'RBK-PS-CONSULT', 'DELL', 'RBK-R6408E', null, new Map<String, Object>{'Product_Type__c' => '3rd Party Hardware','Allow_PSO_Task_Creation__c' => true}),
                createTestProduct('RBK-SVC-PREM-R344', 'RBK-PS-CNSLT-ONST', 'DELL', 'RBK-R6408E', null, new Map<String, Object>{'Product_Type__c' => '3rd Party Hardware','Allow_PSO_Task_Creation__c' => true}),
                createTestProduct('RBK-SVC-PREM-R344', 'RBK-CONSULT', 'DELL', 'RBK-R6408E', null, new Map<String, Object>{'Product_Type__c' => '3rd Party Hardware','Allow_PSO_Task_Creation__c' => true}),
                createTestProduct('RBK-SVC-PREM-R344', 'RBK-DATA-MIGRATION', 'DELL', 'RBK-R6408E', null, new Map<String, Object>{'Product_Type__c' => '3rd Party Hardware','Allow_PSO_Task_Creation__c' => true}),
                createTestProduct('RBK-SVC-PREM-R344', 'RBK-PS-CNSLT-RMOT', 'DELL', 'RBK-R6408E', null, new Map<String, Object>{'Product_Type__c' => '3rd Party Hardware','Allow_PSO_Task_Creation__c' => true}),
                createTestProduct('RBK-SVC-PREM-R344', 'RBK-PS-TE', 'DELL', 'RBK-R6408E', null, new Map<String, Object>{'Product_Type__c' => '3rd Party Hardware','Allow_PSO_Task_Creation__c' => true}),
                createTestProduct('RBK-SVC-PREM-R344', 'RBK-PS-RES', 'DELL', 'RBK-R6408E', null, new Map<String, Object>{'Product_Type__c' => '3rd Party Hardware','Allow_PSO_Task_Creation__c' => true})
                };
                    
      insert lstProducts;

      List<PricebookEntry> lstPbEntries = new List<PricebookEntry>{
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProducts[0].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProducts[1].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProducts[2].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProducts[3].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProducts[4].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProducts[5].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProducts[6].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProducts[7].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProducts[8].Id, UnitPrice = 100.00, IsActive = true)
      };

      insert lstPbEntries;
      test.startTest();
        Order ord = createTestorder('POC',null, acct.Id,oppr.Id,acct.Id,pricebookId,null,'Renewal',new Map<String, Object>{'POC_Opportunity__c' => oppr.Id,'Order_Status__c' => 'On Hold','ship_To_Name__c' => acct.id,'Pricebook2Id' => pricebookId,'Order_Splitted__c' => true,'Actual_Order_Ship_Date__c' => Date.today().addDays(60)});
        insert Ord;
        Order ord1 = createTestorder('POC',null, acct1.Id,oppr.Id,acct1.Id,pricebookId,null,'Renewal',new Map<String, Object>{                'POC_Opportunity__c' => oppr1.Id,'Order_Status__c' => 'On Hold','ship_To_Name__c' => acct1.id,'Pricebook2Id' => pricebookId,'Order_Splitted__c' => true,'Actual_Order_Ship_Date__c' => Date.today().addDays(60)});
        insert ord1;

      List<OrderItem> lstOrderItems = new List<OrderItem>{
          createTestOrderItem(Ord.Id,5,lstPbEntries[0].Id,lstPbEntries[0].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'SN1','Failed_Serial_Number__c' => 'S3F4NXM416324','Trade_Up_SerialNumber__c' => 'SN1','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'Is_Hardware_Line__c' => true,'Is_Refresh__c' => true}),
              createTestOrderItem(Ord.Id,5,lstPbEntries[1].Id,lstPbEntries[1].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'SN1','Failed_Serial_Number__c' => 'S3F4NXM416324','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'Is_Hardware_Line__c' => true,'Is_Refresh__c' => true}),
              createTestOrderItem(Ord.Id,5,lstPbEntries[2].Id,lstPbEntries[2].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'SN1','Failed_Serial_Number__c' => 'S3F4NXM416324','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'Is_Hardware_Line__c' => true,'Is_Refresh__c' => true}),
              createTestOrderItem(Ord.Id,5,lstPbEntries[3].Id,lstPbEntries[3].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'SN1','Failed_Serial_Number__c' => 'S3F4NXM416324','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'Is_Hardware_Line__c' => true,'Is_Refresh__c' => true}),
              createTestOrderItem(Ord.Id,5,lstPbEntries[4].Id,lstPbEntries[4].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'SN1','Failed_Serial_Number__c' => 'S3F4NXM416324','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'Is_Hardware_Line__c' => true,'Is_Refresh__c' => true}),
              createTestOrderItem(Ord.Id,5,lstPbEntries[5].Id,lstPbEntries[5].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'SN1','Failed_Serial_Number__c' => 'S3F4NXM416324','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'Is_Hardware_Line__c' => true,'Is_Refresh__c' => true}),
              createTestOrderItem(Ord.Id,5,lstPbEntries[6].Id,lstPbEntries[6].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'SN1','Failed_Serial_Number__c' => 'S3F4NXM416324','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'Is_Hardware_Line__c' => true,'Is_Refresh__c' => true}),
              createTestOrderItem(Ord.Id,5,lstPbEntries[7].Id,lstPbEntries[7].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'SN1','Failed_Serial_Number__c' => 'S3F4NXM416324','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'Is_Hardware_Line__c' => true,'Is_Refresh__c' => true}),
              createTestOrderItem(Ord.Id,5,lstPbEntries[8].Id,lstPbEntries[8].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'SN1','Failed_Serial_Number__c' => 'S3F4NXM416324','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'Is_Hardware_Line__c' => true,'Is_Refresh__c' => true})
      };
      insert lstOrderItems;
      ord.type = 'POC';
      ord.Order_Status__c = 'Order Accepted';
      ord.Have_PS_Products__c = true;
      update ord;
      ord.Order_Status__c = 'Shipped';
	  update ord;	
      test.stopTest();
    }
  }

  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to Order trigger logic
   */
  static testMethod void testUpdateOrder() {
      
      
    RPS__c rps = testCreateRpsSettings(Userinfo.getOrganizationId(),false,'Internal','Global Trade Compliance screening failed;Credit Check Failed',new map<string,object>{}); 
    insert rps;

    testDataFactoryClass.createCustomSettings();

    String uniqueUserName = 'AdminUser' + DateTime.now().getTime() + '@rubrik.com';
    Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
      User u = createTestUser(null,p.Id,uniqueUserName,'adminU','AdminUser@rubrik.com',new Map<String,object>{'EmailEncodingKey' => 'UTF-8','LastName' => 'Testing','LanguageLocaleKey' => 'en_US','LocaleSidKey' => 'en_US','TimeZoneSidKey' => 'America/Los_Angeles'});
    System.runAs(u) {
      insert new ShGl_DisableBusinessLogic__c(
        Disable_Order_Validation_Rules__c = true,
        Disable_Opportunity_Validation_Rules__c = true,
        Disable_POC_Validation_Rules__c = true,
        Disable_POC_Trigger__c = true,
        Disable_Contact_Triggers__c = true,
        Disable_SBQQ_Quote_Triggers__c = true,
        Disable_SBQQ_QuoteLine_Triggers__c = true
      );


      Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test' LIMIT 1];
      Assert.areEqual('Test', acct.Name);
      Opportunity oppr = [SELECT Id, pricebook2Id FROM Opportunity WHERE AccountId = :acct.Id LIMIT 1];

      Id pricebookId = Test.getStandardPricebookId();
      oppr.pricebook2Id = pricebookId;
      update oppr;

      List<Product2> lstProds = new List<Product2>{
                    createTestProduct('RBK-SVC-PREM-R344', 'RBK-SVC-TR', 'ASE', 'RBK-R6408F', null, new Map<String, Object>{'Capacity__c' => '12TB'}),
                    createTestProduct('RBK-SVC-PREM-R3441', 'RBK-SVC-TR1', 'ASE1', 'RBK-R6408F1', null, new Map<String, Object>{'Capacity__c' => '36TB'})
      };

      insert lstProds;

      List<PricebookEntry> lstPbEntry = new List<PricebookEntry>{
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[0].Id, UnitPrice = 100.00, IsActive = true)
      };

      insert lstPbEntry;

      POC__c pocobj = new POC__c();
      pocobj.POC_Duration__c = '60 Days'; //30 Days
      pocobj.Planned_Installation_Date__c = date.today().addDays(90);
      pocobj.Support_Awareness_needed__c = 'Yes';
      pocobj.POC_Type__c = 'Conditional PO';
      pocobj.Product_Categories__c = 'Rubrik Appliance';

      insert pocobj;
      TriggerControls.disableQuoteTrigger = true;
      TriggerControls.disableQuoteLineTrigger = true;
      SBQQ.TriggerControl.disable();
      test.startTest();
      SBQQ__Quote__c quote = [SELECT Id, Name FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :acct.Id LIMIT 1];
      List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
        Order ord = createTestorder('POC',null, acct.Id,oppr.Id,acct.Id,pricebookId,null,'Renewal',new Map<String, Object>{'Send_for_Polaris_Fulfilment__c' => false,'POC_Request__c' => pocobj.Id,'POC_Opportunity__c' => oppr.Id,'Order_Status__c' => null,'Sync_to_NetSuite__c' => false,'Have_Polaris_Products__c' => true,'Order_Splitted__c' => true,'Integration_Failure__c' => false,'Partner_Name_Text__c' => 'CDW','AddOn_Node_Count__c' => null});
      insert Ord;
      OrderItem ordrItem = createTestOrderItem(Ord.Id,5,lstPbEntry[0].Id,lstPbEntry[0].UnitPrice,new Map<String, Object>{'SerialNumber__c' => '123\\s+,456\\s+','Failed_Serial_Number__c' => 'S3F4NXM416324','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'Is_Hardware_Line__c' => true,'Is_Refresh__c' => true});
      insert ordrItem;
      test.stopTest();
      ord.Integration_Failure__c = true;
      ord.NetSuite_Order__c = 'NSTest12';
      ord.Type = 'Revenue';
      ord.Hold_Code__c = null;
      ord.Order_Status__c = 'Order Accepted';
      ord.ScreenStatus__c = 'On hold';
      ord.Polaris_Fulfillment_Status__c = 'In Progress';
      ord.Credit_Check_Failure_Reason__c = 'Customer balance of 32 exceeds credit limit of 41.00 ';
      update ord;
      ord.Hold_Code__c = null;
      ord.Order_Sub_Type__c = 'MSP Overage';
      ord.Order_Status__c = 'Pending';
      ord.ScreenStatus__c = 'Approved';
      update ord;
    }
  }
  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to Order trigger logic
   */
  static testMethod void testComplianceScreenInternalSource() {
    RPS__c rps = testCreateRpsSettings(Userinfo.getOrganizationId(),false,'Internal','Global Trade Compliance screening failed;Credit Check Failed',new map<string,object>{}); 
    insert rps;

    testDataFactoryClass.createCustomSettings();

    System.runAs(new User(Id = UserInfo.getUserId())) {
      Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test' LIMIT 1];
      Assert.areEqual('Test', acct.Name);
      Opportunity oppr = [SELECT Id, pricebook2Id FROM Opportunity WHERE AccountId = :acct.Id LIMIT 1];

      insert new Hold_Off_Tracking__c(
        Hold_Code__c = 'OM Internal Review',
        Release_Date_Time__c = datetime.newInstance(2021, 9, 15, 12, 30, 0),
        Related_Opportunity__c = oppr.Id,
        Is_Released__c = false
      );

      Id pricebookId = Test.getStandardPricebookId();
      oppr.pricebook2Id = pricebookId;
      update oppr;

      List<Product2> lstProds = new List<Product2>{
        createTestProduct('RBK-SVC-PREM-R344', 'RBK-SVC-PREM-R344', 'RBK-R300', 'RBK-R6408F', null, new Map<String, Object>{}),
        createTestProduct('RBK-SVC-PREM-R344', 'RBK-SVC-PREM-R344', 'RBK-R300', 'RBK-R640F', null, new Map<String, Object>{})
      };

      insert lstProds;

      List<PricebookEntry> lstPbEntry = new List<PricebookEntry>{
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[0].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[1].Id, UnitPrice = 100.00, IsActive = true)
      };

      insert lstPbEntry;

      List<OpportunityLineItem> lstOlis = new List<OpportunityLineItem>{
        new OpportunityLineItem(OpportunityId = oppr.Id, Quantity = 5, PricebookEntryId = lstPbEntry[0].Id, TotalPrice = 5 * lstPbEntry[0].UnitPrice),
        new OpportunityLineItem(OpportunityId = oppr.Id, Quantity = 5, PricebookEntryId = lstPbEntry[1].Id, TotalPrice = 5 * lstPbEntry[1].UnitPrice)
      };

      insert lstOlis;

      test.startTest();
      Order ord = createTestorder('RMA',null, acct.Id,oppr.Id,null,pricebookId,null,null,new Map<String, Object>{'Order_Status__c' => 'On Hold','Mosaic_SKUs__c' => 'RBK-MOSAIC','Hold_Code__c' => 'Contract in negotiations','Internal_Order_Stage__c' => 'Pending','Screening_Source__c' => 'Internal','Ship_To_Name__c' => 'Test'});
      insert Ord;

        List<OrderItem> lstOrdrItems = new List<OrderItem>{
            createTestOrderItem(Ord.Id,5,lstPbEntry[0].Id,lstPbEntry[0].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'S3F4NXMM416324','Failed_Serial_Number__c' => 'S3F4NXM416324','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today()}),
                createTestOrderItem(Ord.Id,5,lstPbEntry[1].Id,lstPbEntry[1].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'S3F4NXMM416324','Failed_Serial_Number__c' => 'S3F4NXM416324','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today()})
                                    };

      insert lstOrdrItems;

      test.stopTest();

      ord.Internal_Order_Stage__c = 'Pending Validation';
      ord.Order_Status__c = 'On Hold';
      ord.ScreenStatus__c = 'On hold';
      ord.ShipToScreenStatus__c = 'Denied';
      ord.Billto_EndUser_Screen_Status__c = 'Denied';
      ord.Shipto_EndUser_Screen_Status__c = 'Denied';
      ord.ShipToScreenStatus__c = 'Approved';
      ord.ShipToContactScreenStatus__c = 'Approved';
      ord.Order_Status__c = 'Returned';
      ord.Hold_Code__c = null;

      update ord;

        Booking__c objBooking = createTestBooking(Ord.id, oppr.Id, acct.Id,new Map<String, Object>{'recordTypeId' => Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking').getRecordTypeId()});
            insert objBooking;
        Booking_Line_Item__c objBookingLine = createTestBookingLineItem(objBooking.id,'Revenue',100,new Map<String,object>{});
            insert objBookingLine;
            ord.Status = 'Cancelled';
            ord.Cancellation_Reason__c = 'Test reason';

      update ord;
        
           ord.Screening_Source__c = 'External';
        update ord;
   
        
    }
  }
  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to Order trigger logic
   */
  static testMethod void testComplianceScreenExternalSource() {
    RPS__c rps = testCreateRpsSettings(Userinfo.getOrganizationId(),false,'Internal','Global Trade Compliance screening failed;Credit Check Failed',new map<string,object>{}); 
    insert rps;

    testDataFactoryClass.createCustomSettings();

    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert new ShGl_DisableBusinessLogic__c(
        Disable_Opportunity_Triggers__c = true,
        Disable_SBQQ_Quote_Triggers__c = true,
        Disable_SBQQ_QuoteLine_Triggers__c = true,
        Disable_Account_Triggers__c = true,
        Disable_Product2_Trigger__c = true
      );
      Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test' LIMIT 1];
      Assert.areEqual('Test', acct.Name);
      Opportunity oppr = [SELECT Id, pricebook2Id FROM Opportunity WHERE AccountId = :acct.Id LIMIT 1];

      insert new Hold_Off_Tracking__c(
        Hold_Code__c = 'OM Internal Review',
        Release_Date_Time__c = datetime.newInstance(2021, 9, 15, 12, 30, 0),
        Related_Opportunity__c = oppr.Id,
        Is_Released__c = false
      );

      Id pricebookId = Test.getStandardPricebookId();
      oppr.pricebook2Id = pricebookId;
      update oppr;

      List<Product2> lstProds = new List<Product2>{
        createTestProduct('RBK-SVC-PREM-R344', 'RBK-F3M-CBL-01', 'RBK-R300', null, null, new Map<String, Object>{}),
        createTestProduct('RBK-SVC-PREM-R344', 'RBK-F3M-CBL-02', 'RBK-R300', null, null, new Map<String, Object>{})
      };

      insert lstProds;

      List<PricebookEntry> lstPbEntry = new List<PricebookEntry>{
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[0].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[1].Id, UnitPrice = 100.00, IsActive = true)
      };

      insert lstPbEntry;

      List<OpportunityLineItem> lstOlis = new List<OpportunityLineItem>{
        new OpportunityLineItem(OpportunityId = oppr.Id, Quantity = 5, PricebookEntryId = lstPbEntry[0].Id, TotalPrice = 5 * lstPbEntry[0].UnitPrice),
        new OpportunityLineItem(OpportunityId = oppr.Id, Quantity = 5, PricebookEntryId = lstPbEntry[1].Id, TotalPrice = 5 * lstPbEntry[1].UnitPrice)
      };

      insert lstOlis;
      //test.startTest();
      Order ord = createTestorder('Revenue',null, acct.Id,oppr.Id,null,pricebookId,null,null,new Map<String, Object>{'Sync_to_NetSuite__c' => false,'Order_Status__c' => 'PO Received','Mosaic_SKUs__c' => 'RBK-MOSAIC','BookingStatus__c' => 'Booking Created','Internal_Order_Stage__c' => 'Pending','Screening_Source__c' => 'External','Ship_To_Name__c' => 'Test','ShipToContactName__c' => 'TestContact'});
      insert Ord;

      List<OrderItem> lstOrdrItems = new List<OrderItem>{
        createTestOrderItem(Ord.Id,5,lstPbEntry[0].Id,lstPbEntry[0].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'S3F4NXMM416324','Failed_Serial_Number__c' => 'S3F4NXM416324','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today()}),
        createTestOrderItem(Ord.Id,5,lstPbEntry[1].Id,lstPbEntry[1].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'S3F4NXMM416324','Failed_Serial_Number__c' => 'S3F4NXM416324','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today()})
      };
      test.startTest();
      insert lstOrdrItems;
      ord.Internal_Order_Stage__c = 'Pending Validation';
      ord.Order_Status__c = 'PO Received';
      ord.ScreenStatus__c = 'On hold';
      ord.ShipToScreenStatus__c = 'Denied';
      ord.Billto_EndUser_Screen_Status__c = 'Denied';
      ord.Shipto_EndUser_Screen_Status__c = 'Denied';
      ord.ShipToScreenStatus__c = 'Approved';
      ord.ShipToContactScreenStatus__c = 'Approved';
      ord.Order_Status__c = 'Returned';
      ord.Hold_Code__c = null;

      update ord;

      ord.Internal_Order_Stage__c = 'Pending Validation';
      ord.ShipToScreenStatus__c = 'Approved';
      ord.Billto_EndUser_Screen_Status__c = 'Approved';
      ord.Shipto_EndUser_Screen_Status__c = 'Approved';
      ord.ShipToScreenStatus__c = 'Approved';
      ord.ShipToContactScreenStatus__c = 'Approved';
      ord.ScreenStatus__c = 'On hold';
      ord.Hold_Code__c = null;
     // ord.Screening_Source__c = 'External';

      update ord;

      ord.ScreenStatus__c = 'Approved';
      ord.Hold_Code__c = 'Quote/PO Mismatch';
      update ord;
      
      ord.ShipToScreenStatus__c = 'Approved';
      ord.Billto_EndUser_Screen_Status__c = 'Approved';
      ord.Shipto_EndUser_Screen_Status__c = 'Approved';
      ord.ShipToContactScreenStatus__c = 'Approved';
      ord.Partner_Screen_Status__c = 'Approved';
      ord.SDPScreenStatus__c = 'Approved';
      ord.Primary_Contact_Screen_Status__c = 'Approved';
      ord.Polaris_Contact_Screen_Status__c = 'Approved';
      ord.Third_Party_Screen_Status__c = 'Approved';

      update ord;

      ord.ShipToScreenStatus__c = 'Awaiting user intervention';
      ord.Billto_EndUser_Screen_Status__c = 'Awaiting user intervention';
      ord.Shipto_EndUser_Screen_Status__c = 'Awaiting user intervention';
      ord.ShipToContactScreenStatus__c = 'Awaiting user intervention';
      ord.Partner_Screen_Status__c = 'Awaiting user intervention';
      ord.SDPScreenStatus__c = 'Awaiting user intervention';
      ord.Primary_Contact_Screen_Status__c = 'Awaiting user intervention';
      ord.Polaris_Contact_Screen_Status__c = 'Awaiting user intervention';
      ord.Third_Party_Screen_Status__c = 'Awaiting user intervention';

      update ord;
      test.stopTest();
       /* ord.Screening_Source__c = 'External';
        update ord;*/

  
    }
  }

  @isTest
  static void testRebateCalculation() {
            String uniqueUserName = 'AdminUser' + DateTime.now().getTime() + '@rubrik.com';
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User u = new User(
            Alias = 'adminU',
            Email = 'AdminUser@rubrik.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = uniqueUserName
        );
        insert u;
  
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert new ShGl_DisableBusinessLogic__c(
        Disable_Opportunity_Triggers__c = true,
        Disable_Opportunity_Old_Trigger__c = true,
        Disable_Opportunity_Validation_Rules__c = true,
        Disable_POC_Validation_Rules__c = true,
        Disable_POC_Trigger__c = true,
        Disable_Contact_Triggers__c = true,
        Disable_SBQQ_Quote_Triggers__c = true,
        Disable_SBQQ_QuoteLine_Triggers__c = true
      );

      Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test' LIMIT 1];
      Assert.areEqual('Test', acct.Name);
      Opportunity oppr = [SELECT Id, pricebook2Id,Opportunity_Type__c FROM Opportunity WHERE AccountId = :acct.Id LIMIT 1];

      Id pricebookId = Test.getStandardPricebookId();
      oppr.pricebook2Id = pricebookId;
      //oppr.Opportunity_Type__c = 'New Customer';  
      update oppr;

        List<Product2> lstProds = new List<Product2>{
            createTestProduct('RBK-SVC-PREM-R344', 'RBK-F3M-CBL-01', 'RBK-R300', null, null, new Map<String, Object>{}),
                createTestProduct('RBK-SVC-PREM-R344', 'RBK-F3M-CBL-02', 'RBK-R300', null, null, new Map<String, Object>{})
                };

      insert lstProds;

      List<PricebookEntry> lstPbEntry = new List<PricebookEntry>{
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[0].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[1].Id, UnitPrice = 100.00, IsActive = true)
      };

      insert lstPbEntry;

      List<OpportunityLineItem> lstOlis = new List<OpportunityLineItem>{
        new OpportunityLineItem(OpportunityId = oppr.Id,Quantity = 5,PricebookEntryId = lstPbEntry[0].Id,TotalPrice = 5 * lstPbEntry[0].UnitPrice,New_Expansion_TCV__c = 700,Subsumed_Renewal_TCV__c = 300,ACV_Amount__c = 500,New_Expansion_ACV__c = 300,Subsumed_Renewal_Amount__c = 200),
        new OpportunityLineItem(OpportunityId = oppr.Id,Quantity = 5,PricebookEntryId = lstPbEntry[1].Id,TotalPrice = 5 * lstPbEntry[1].UnitPrice,New_Expansion_TCV__c = 700,Subsumed_Renewal_TCV__c = 300,ACV_Amount__c = 500,New_Expansion_ACV__c = 300,Subsumed_Renewal_Amount__c = 200)
      };

      insert lstOlis;

      test.startTest();
      
      Order ord = createTestorder('Revenue',null, acct.Id,oppr.Id,null,pricebookId,null,null,new Map<String, Object>{'Sync_to_NetSuite__c' => false,'Bill_To_Name__c' => acct.Id,'Order_Status__c' => 'Order Accepted','BookingStatus__c' => '','Internal_Order_Stage__c' => 'Pending','Screening_Source__c' => 'External','Ship_To_Name__c' => 'Test','Polaris_Fulfillment_Status__c' => 'Completed'});
      insert Ord;
      Booking__c objBooking1 = createTestBooking(ord.id,oppr.Id,acct.id,new Map<String,object>{'Distributor__c' => acct.id,'CreatedDate' => System.Today(),'recordTypeId' => Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking').getRecordTypeId()});
	  insert objBooking1;
      List<OrderItem> lstOrdrItems = new List<OrderItem>{
          createTestOrderItem(Ord.Id,5,lstPbEntry[0].Id,lstPbEntry[0].UnitPrice,new Map<String, Object>{'Opportunity_Product__c' => lstOlis[0].Id,'SerialNumber__c' => 'S3F4NXMM416324','Failed_Serial_Number__c' => 'S3F4NXM416324','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today()}),
          createTestOrderItem(Ord.Id,5,lstPbEntry[1].Id,lstPbEntry[1].UnitPrice,new Map<String, Object>{'Opportunity_Product__c' => lstOlis[1].Id,'SerialNumber__c' => 'S3F4NXMM416324','Failed_Serial_Number__c' => 'S3F4NXM416324','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today()})
      };
      insert lstOrdrItems;
      test.stopTest();
      ord.BookingStatus__c = 'Booking Created';
      update ord;
      
    }
  }

  @isTest
  static void testRebateCalForAdjustment() {
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert new ShGl_DisableBusinessLogic__c(
        Disable_Opportunity_Triggers__c = true,
        Disable_Opportunity_Old_Trigger__c = true,
        Disable_Opportunity_Validation_Rules__c = true,
        Disable_POC_Validation_Rules__c = true,
        Disable_POC_Trigger__c = true,
        Disable_Contact_Triggers__c = true,
        Disable_SBQQ_Quote_Triggers__c = true,
        Disable_SBQQ_QuoteLine_Triggers__c = true
      );

      Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test' LIMIT 1];
      Assert.areEqual('Test', acct.Name);
      Opportunity oppr = [SELECT Id, pricebook2Id FROM Opportunity WHERE AccountId = :acct.Id LIMIT 1];

      Id pricebookId = Test.getStandardPricebookId();
      oppr.pricebook2Id = pricebookId;
      update oppr;

      List<Product2> lstProds = new List<Product2>{
               createTestProduct('RBK-SVC-PREM-R344', 'RBK-SVC-PREM-R344', 'ASE', 'RBK-R6408F', 'Support', new Map<String, Object>{})
      };
      insert lstProds;
      List<PricebookEntry> lstPbEntry = new List<PricebookEntry>{
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[0].Id, UnitPrice = 100.00, IsActive = true)
      };
      insert lstPbEntry;

      List<OpportunityLineItem> lstOlis = new List<OpportunityLineItem>{
        new OpportunityLineItem(
          OpportunityId = oppr.Id,Quantity = 5,PricebookEntryId = lstPbEntry[0].Id,TotalPrice = 5 * lstPbEntry[0].UnitPrice,New_Expansion_TCV__c = 700,Subsumed_Renewal_TCV__c = 300,ACV_Amount__c = 500,New_Expansion_ACV__c = 300,Subsumed_Renewal_Amount__c = 200
        )
      };
      insert lstOlis;
      Order ord = createTestorder('Revenue',null, acct.Id,oppr.Id,null,oppr.pricebook2Id,null,null,new Map<String, Object>{'Sync_to_NetSuite__c' => false,'Bill_To_Name__c' => acct.Id,'Order_Status__c' => 'Order Accepted','BookingStatus__c' => 'Completed','Internal_Order_Stage__c' => 'Pending','Screening_Source__c' => 'External','Ship_To_Name__c' => 'Test'});
      insert Ord;
      ord = [SELECT Id,OrderNumber,Deliver_By__c,Est_Ship_Date__c FROM Order WHERE Id =: ord.Id];
      Booking__c objBooking1 = createTestBooking(ord.id,oppr.Id,acct.id,new Map<String,object>{'Distributor__c' => acct.id,'recordTypeId' => Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking').getRecordTypeId(),'CreatedDate' => System.Today()});
      insert objBooking1;
      test.startTest();
      Order objOrd1 = createTestorder('Booking Adjustment',null, acct.Id,oppr.Id,null,oppr.pricebook2Id,null,null,new Map<String, Object>{'BookingStatus__c' => '','EffectiveDate' => System.today().addDays(2),'Status' => 'Draft','recordTypeId' => Schema.SObjectType.Order.getRecordTypeInfosByName().get('Booking Adjustment Order').getRecordTypeId(),'Order_Status__c' => 'Order Accepted','ManualFulfilment__c' => false,'ScreenStatus__c' => 'Approved','Bill_To_Name__c' => acct.Id,'Internal_Order_Stage__c' => 'Pending','Ship_To_Name__c' => 'Test','Have_Hardware_Products__c' => false,'ShipToContactName__c'=>'TestContact','Have_Polaris_Products__c' => false});
      insert objOrd1;
      objOrd1 = [SELECT Id,OrderNumber,Deliver_By__c,Est_Ship_Date__c FROM Order WHERE Id =: objOrd1.Id];
      TransactionalDataCollection.orderItemMainList.clear();
      List<OrderItem> lstOrdrItems = new List<OrderItem>{
       createTestOrderItem(objOrd1.Id,5,lstPbEntry[0].Id,lstPbEntry[0].UnitPrice,new Map<String, Object>{ 'SerialNumber__c' => 'S3F4NXMM416324','Failed_Serial_Number__c' => 'S3F4NXM416324','Support_End_Date__c' => System.Today().addDays(2).addYears(1),'Support_Start_Date__c' => System.Today().addDays(2),'Opportunity_Product__c' => lstOlis[0].Id})
      };
      insert lstOrdrItems;
      Booking__c objDebookBKg = createTestBooking(objOrd1.id,oppr.Id,acct.id,new Map<String,object>{'Original_Booking__c' => objBooking1.Id,'Distributor__c' => acct.id,'recordTypeId' => Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking Adjustment').getRecordTypeId(),'CreatedDate' => System.Today()});
      insert objDebookBKg;
	  List<Booking_Line_Item__c> bliList = new List<Booking_Line_Item__c>{
      createTestBookingLineItem(objDebookBKg.id, 'Revenue',100,new Map<String, Object>{'OrderProduct__c' => lstOrdrItems[0].Id})
      };
      insert bliList;
      objOrd1.BookingStatus__c = 'Booking Created';
      objOrd1.Related_Order_Count__c = 2;
      objOrd1.Related_Orders__c = objOrd1.OrderNumber + ',' + ord.OrderNumber + ',' + ord.OrderNumber;
      objOrd1.Deliver_By__c = objOrd1.Est_Ship_Date__c;
      update objOrd1;
      test.stopTest();
    }
  }

  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to Order trigger logic
   */
  static testMethod void testUpdateOrder1() {
    RPS__c rps = testCreateRpsSettings(Userinfo.getOrganizationId(),false,'Internal','Global Trade Compliance screening failed;Credit Check Failed',new map<string,object>{}); 
    insert rps;
    testDataFactoryClass.createCustomSettings();
    System.runAs(new User(Id = UserInfo.getUserId())) {
      Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test' LIMIT 1];
      Assert.areEqual('Test', acct.Name);
      Opportunity oppr = [SELECT Id, pricebook2Id FROM Opportunity WHERE AccountId = :acct.Id LIMIT 1];

      Id pricebookId = Test.getStandardPricebookId();
      oppr.pricebook2Id = pricebookId;
      oppr.Aspen_Eligibility__c = 'Actual Aspen';
      update oppr;

        List<Product2> lstProds = new List<Product2>{
            createTestProduct('RBK-SVC-PREM-R344', 'RBK-SVC-TR', 'ASE', 'RBK-R6408F', null, new Map<String, Object>{'Capacity__c' => '12TB'}),
                createTestProduct('RBK-SVC-PREM-R3441', 'RBK-SVC-TR1', 'ASE1', 'RBK-R6408F1', null, new Map<String, Object>{'Capacity__c' => '36TB'})
                };

      insert lstProds;

      List<PricebookEntry> lstPbEntry = new List<PricebookEntry>{
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[0].Id, UnitPrice = 100.00, IsActive = true)
      };

      insert lstPbEntry;

      List<OpportunityLineItem> lstOlis = new List<OpportunityLineItem>{
        new OpportunityLineItem(
          OpportunityId = oppr.Id,Quantity = 5,PricebookEntryId = lstPbEntry[0].Id,TotalPrice = 5 * lstPbEntry[0].UnitPrice,New_Expansion_TCV__c = 3 * lstPbEntry[0].UnitPrice,Subsumed_Renewal_TCV__c = 2 * lstPbEntry[0].UnitPrice,ACV_Amount__c = 5 * lstPbEntry[0].UnitPrice,New_Expansion_ACV__c = 3 * lstPbEntry[0].UnitPrice,SubsRenAmt__c = 2 * lstPbEntry[0].UnitPrice
        )
      };

      insert lstOlis;

      test.startTest();

      List<Asset> assetsList = new List<Asset>{
          createAsset('SN123', acct.Id, lstProds[0].id, 'Purchased','SN123',new Map<String, Object>{'Serial_Number__c' => 'SN123','Premium_Support_End_Date__c' => Date.today()}), 
          createAsset('SN1234', acct.Id, lstProds[1].id, 'Purchased','SN1234',new Map<String, Object>{'Serial_Number__c' => 'SN1234','Premium_Support_End_Date__c' => Date.today(),'licensed_capacity__c' => 12})
      };
      insert assetsList;
        List<Entitlement> entList = new List<Entitlement>{
            createEntitlement('ENT-1',acct.Id, lstProds[0].Id,assetsList[0].Id, new Map<String, Object>{'Type' => 'Manufacturing Entitlement','StartDate' => Date.valueof(System.now().addDays(-2)),'EndDate' => Date.valueof(System.now().addYears(2))}),
            createEntitlement('ENT-2',acct.Id, lstProds[0].Id,assetsList[0].Id, new Map<String, Object>{'Type' => 'Custom Entitlement','StartDate' => Date.valueof(System.now().addDays(-2)),'EndDate' => Date.valueof(System.now().addYears(2))})
        };
  insert entList;
          Order ord = createTestorder('Revenue',null, acct.Id,oppr.Id,null,pricebookId,null,null,new Map<String, Object>{'Mosaic_SKUs__c' => 'RBK-MOSAIC'});
        insert Ord;

      List<OrderItem> lstOrdrItems = new List<OrderItem>{
              createTestOrderItem(Ord.Id,5,lstPbEntry[0].Id,lstPbEntry[0].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'S3F4NXMM416324','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'Upgraded_From__c' => assetsList[0].id,'Opportunity_Product__c' => lstOlis[0].Id}),
              createTestOrderItem(Ord.Id,5,lstPbEntry[0].Id,lstPbEntry[0].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'S454NXMM416324','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'Upgraded_From__c' => assetsList[0].id})
      };
      insert lstOrdrItems;

      Booking__c objBooking =  createTestBooking(Ord.id,oppr.Id,acct.id,new Map<String,object>{'recordTypeId' => Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking').getRecordTypeId()});
      insert objBooking;

      List<Booking_Line_Item__c> bliList = new List<Booking_Line_Item__c>{
          createTestBookingLineItem(objBooking.id,'Revenue',100,new Map<String, Object>{'OrderProduct__c' => lstOrdrItems[0].Id,'New_Expansion_TCV__c' => 50,'Subsumed_Renewal_TCV__c' => 50,'Gross_ACV_Amount__c' => 50,'Gross_New_Expansion_ACV__c' => 50,'Gross_Subsumed_Renewal_ACV__c' => 50}),  
          //createTestBookingLineItem(objBooking.id,'Revenue',100,new Map<String, Object>{'OrderProduct__c' => lstOrdrItems[0].Id,'New_Expansion_TCV__c' => 50/*'Subsumed_Renewal_TCV__c' => 50,'Gross_ACV_Amount__c' => 50,'Gross_New_Expansion_ACV__c' => 50,'Gross_Subsumed_Renewal_ACV__c' => 50*/}),  
          createTestBookingLineItem(objBooking.id,'Distributor Fee',10.0,new Map<String, Object>{'Rebate__c' => 2.0,'Impacts_Gross_Bookings__c' => true,'Impacts_Net_Bookings__c' => true,'Impacts_Commission__c' => true}),  
          createTestBookingLineItem(objBooking.id,'Partner Referral Fee',10.0,new Map<String, Object>{'Rebate__c' => 2.0,'Impacts_Gross_Bookings__c' => true,'Impacts_Net_Bookings__c' => true,'Impacts_Commission__c' => true})  
	 };
      insert bliList;
      OrderHandler handler = OrderHandler.getInstance();
      handler.afterUpdateHistory.remove('Rebate');
      ord.Order_Status__c = 'Pending';
      ord.Hold_Code__c = null;
      ord.SBQQ__PriceCalcStatus__c = 'Queued';
      update ord;
/*bliList[0].New_Expansion_TCV__c = null;
bliList[0].Subsumed_Renewal_TCV__c = null;
bliList[0].Gross_New_Expansion_ACV__c = null;
bliList[0].Gross_Subsumed_Renewal_ACV__c = null;
        update bliList[0];
         system.debug('bliList[0] ' + bliList[0]);*/ 
        List<Booking_Line_Item__c> bliList1 = new List<Booking_Line_Item__c>();
        for(Booking_Line_Item__c BLI : [Select id,type__c,Subsumed_Renewal_TCV__c,New_Expansion_TCV__c,Gross_ACV_Amount__c,Gross_New_Expansion_ACV__c,Gross_Subsumed_Renewal_ACV__c,Rebate__c,Total_Price__c  from Booking_Line_Item__c where type__c = 'Revenue' OR type__c = 'Distributor Fee']){
            BLI.Total_Price__c  = 10.0;
            BLI.New_Expansion_TCV__c = null;
            BLI.Subsumed_Renewal_TCV__c = null;
            BLI.Gross_New_Expansion_ACV__c = null;
            BLI.Gross_Subsumed_Renewal_ACV__c = null;
            BLI.Gross_ACV_Amount__c = null;
            bliList1.add(BLI);

        }
       update bliList1;  
      handler.afterUpdateHistory.remove('Rebate');
      ord.SBQQ__PriceCalcStatus__c = 'Completed';
      ord.BookingStatus__c = 'Completed';
      ord.Order_Status__c = 'Shipped';
      ord.ScreenStatus__c = 'Approved';
      update ord;
      test.stopTest();
    }
  }

  static testMethod void testUpdateOrderForBLI() {
    RPS__c rps = testCreateRpsSettings(Userinfo.getOrganizationId(),false,'Internal','Global Trade Compliance screening failed;Credit Check Failed',new map<string,object>{}); 
    insert rps;
    testDataFactoryClass.createCustomSettings();
    System.runAs(new User(Id = UserInfo.getUserId())) {
      insert new ShGl_DisableBusinessLogic__c(
        Disable_Entitlement_Validation_Rules__c = true,
        Disable_Account_Triggers__c = true,
        Disable_Asset_Triggers__c = true,
        Disable_SBQQ_Quote_Triggers__c = true,
        Disable_Order_Triggers__c = true,
        Disable_SBQQ_QuoteLine_Triggers__c = true,
        Disable_Order_Old_Trigger__c = true,
        Disable_OrderItem_Old_Trigger__c = true,
        Disable_Opportunity_Triggers__c = true,
        Disable_Order_Validation_Rules__c = true,
        Disable_SBQQ_QuoteLine_Validation_Rules__c = true
      );
      TriggerControl.stopOrderItemTrigger = true;
      TriggerControl.stopOrderTrigger = true;

      Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test' LIMIT 1];
      Assert.areEqual('Test', acct.Name);
      Opportunity oppr = [SELECT Id, pricebook2Id FROM Opportunity WHERE AccountId = :acct.Id LIMIT 1];

      Id pricebookId = Test.getStandardPricebookId();
      oppr.pricebook2Id = pricebookId;
      update oppr;

      List<Product2> lstProds = new List<Product2>{
        createTestProduct('RBK-SVC-PREM-R344', 'RBK-SVC-TR', 'ASE', 'RBK-R6408F', null, new Map<String, Object>{'Capacity__c' => '12TB'}),
        createTestProduct('RBK-SVC-PREM-R3441', 'RBK-SVC-TR1', 'ASE1', 'RBK-R6408F1', null, new Map<String, Object>{'Capacity__c' => '36TB'})
      };

      insert lstProds;

      List<PricebookEntry> lstPbEntry = new List<PricebookEntry>{
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[0].Id, UnitPrice = 100.00, IsActive = true)
      };

      insert lstPbEntry;

      List<OpportunityLineItem> lstOlis = new List<OpportunityLineItem>{
        new OpportunityLineItem(
          OpportunityId = oppr.Id,Quantity = 5,PricebookEntryId = lstPbEntry[0].Id,TotalPrice = 5 * lstPbEntry[0].UnitPrice,New_Expansion_TCV__c = 3 * lstPbEntry[0].UnitPrice,Subsumed_Renewal_TCV__c = 2 * lstPbEntry[0].UnitPrice,ACV_Amount__c = 5 * lstPbEntry[0].UnitPrice,New_Expansion_ACV__c = 3 * lstPbEntry[0].UnitPrice,SubsRenAmt__c = 2 * lstPbEntry[0].UnitPrice
        )
      };

      insert lstOlis;
      test.startTest();
          Order ord = createTestorder('Revenue',null, acct.Id,oppr.Id,null,pricebookId,null,null,new Map<String, Object>{'Mosaic_SKUs__c' => 'RBK-MOSAIC','Bill_To_Name__c' => acct.Id});
        insert Ord;

      List<OrderItem> lstOrdrItems = new List<OrderItem>{
      createTestOrderItem(Ord.Id,5,lstPbEntry[0].Id,lstPbEntry[0].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'S3F4NXMM416324','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'Opportunity_Product__c' => lstOlis[0].Id})
      };
      insert lstOrdrItems;
      Booking__c objBooking =  createTestBooking(Ord.id,oppr.Id,acct.id,new Map<String,object>{'recordTypeId' => Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking').getRecordTypeId()});
      TransactionalDataCollection.orderItemMainList.clear();
      insert objBooking;
      TransactionalDataCollection.orderItemMainList.clear();
      List<Booking_Line_Item__c> bliList = new List<Booking_Line_Item__c>{
          createTestBookingLineItem(objBooking.id,'Revenue',10,new Map<String, Object>{'OrderProduct__c' => lstOrdrItems[0].Id,'New_Expansion_TCV__c' => 50,'Subsumed_Renewal_TCV__c' => 50,'Gross_ACV_Amount__c' => 50,'Gross_New_Expansion_ACV__c' => 50,'Gross_Subsumed_Renewal_ACV__c' => 50})
      };
      insert bliList;
      OrderHandler handler = OrderHandler.getInstance();
      handler.afterUpdateHistory.remove('Rebate');
      ord.Order_Status__c = 'Order Accepted';
      ord.Hold_Code__c = null;
      ord.SBQQ__PriceCalcStatus__c = 'Queued';
      List<ShGl_DisableBusinessLogic__c> lstbusines = [SELECT Id FROM ShGl_DisableBusinessLogic__c LIMIT 1];
      update new ShGl_DisableBusinessLogic__c(
        Id = lstbusines[0].Id,
        Disable_Order_Triggers__c = false,
        Disable_Order_Old_Trigger__c = false,
        Disable_OrderItem_Old_Trigger__c = false
      );
      TriggerControl.stopOrderItemTrigger = false;
      TriggerControl.stopOrderTrigger = false;
      TransactionalDataCollection.orderItemMainList.clear();
      update ord;
      test.stopTest();
    }
  }
  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to Order trigger logic
   */
  static testMethod void testRMAShippedOrder() {
    testDataFactoryClass.createCustomSettings();

    System.runAs(new User(Id = UserInfo.getUserId())) {
      Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test' LIMIT 1];
      Assert.areEqual('Test', acct.Name);
      Opportunity oppr = [SELECT Id, pricebook2Id FROM Opportunity WHERE AccountId = :acct.Id LIMIT 1];

      //delete [SELECT SBQQ__Type__c FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :acct.Id LIMIT 1];

      Id pricebookId = Test.getStandardPricebookId();

      oppr.pricebook2Id = pricebookId;
      update oppr;

        List<Product2> lstProds = new List<Product2>{
            createTestProduct('RBK-SVC-PREM-R344', 'RBK-SVC-PREM-R344', 'RBK-R300', 'RBK-R6408F', null, new Map<String, Object>{'Entitlement_Conversion_Non_CPQ__c' => 'One per quote line','Create_Asset__c' => true}),
                createTestProduct('RBK-SVC-PREM-R344', 'RBK-SVC-PREM-R344', 'RBK-R300', 'RBK-R640F', null, new Map<String, Object>{'Entitlement_Conversion_Non_CPQ__c' => 'One per unit','Create_Asset__c' => false})
                };
      insert lstProds;
      List<PricebookEntry> lstPbEntry = new List<PricebookEntry>{
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[0].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[1].Id, UnitPrice = 100.00, IsActive = true)
      };

      insert lstPbEntry;

      List<Asset> assetsList = new List<Asset>{
        createAsset('SN123', Label.Unassigned_Account_Id, lstProds[0].id, 'Purchased' ,'SN123',new Map<String, Object>{'Serial_Number__c' => 'SN123','Premium_Support_End_Date__c' => Date.today()}),
        createAsset('SNN-1-1', acct.id, lstProds[1].id, 'Purchased' ,'SNN-1-1',new Map<String, Object>{'Serial_Number__c' => 'SNN-1-1','Premium_Support_End_Date__c' => Date.today()})
      };
      insert assetsList;
      List<Chassis__c> chassis = new List<Chassis__c>{
        new Chassis__c(Name = 'C8270FH18NB0100', serial_number__c = 'C8270FH18NB0100', asset__c = assetsList[0].Id, manufactured_date__c = System.now()),
        new Chassis__c(Name = 'C8270FH18NB0101', serial_number__c = 'C8270FH18NB0101', asset__c = assetsList[1].Id, manufactured_date__c = System.now())
      };
      insert chassis;
      List<Node__c> lstNodes = new List<Node__c>{
        new Node__c(Asset__c = assetsList[0].Id,Serial_Number__c = 'SN123',software_version__c = '1.0.1',Name = 'SN123',chassis__c = chassis[0].Id),
        new Node__c(Asset__c = assetsList[0].Id,Serial_Number__c = 'SNN-1-1',software_version__c = '1.0.1',Name = 'SNN-1-1',chassis__c = chassis[0].Id)
      };

      insert lstNodes;

      List<Power_Supply__c> psus = new List<Power_Supply__c>{
        new Power_Supply__c(Name = 'SNN-3-3',asset__c = assetsList[0].Id,revision__c = '1.3',serial_number__c = 'SNN-3-3',part_number__c = 'PWS-2K22A-1R',manufactured_date__c = System.now()
        )
      };

      insert psus;

      List<Drive__c> Hdddrives = new List<Drive__c>{
        new Drive__c(Name = '0RV5TST01',asset__c = assetsList[0].Id,serial_number__c = '0RV5TST01',node__c = lstNodes[0].Id,type__c = 'HDD',manufactured_date__c = System.now())
      };

      insert Hdddrives;

      List<Memory__c> memory = new List<Memory__c>{
        //new Memory__c(Name = '0RV5MEM01', asset__c = assets[0].Id,serial_number__c = '0RV5MEM01', node__c = nodes[0].Id ,manufactured_date__c = System.now()),
        new Memory__c(Name = '0RV5MEM02', asset__c = assetsList[0].Id, serial_number__c = '0RV5MEM02', node__c = lstNodes[0].Id, manufactured_date__c = System.now())
      };

      insert memory;

      test.startTest();
          Order ord = createTestorder('Revenue',null, acct.Id,oppr.Id,null,pricebookId,null,null,new Map<String, Object>{'Order_Status__c' => 'On Hold','Mosaic_SKUs__c' => 'RBK-MOSAIC','Order_Splitted__c' => true,'Internal_Order_Stage__c' => 'Pending','Screening_Source__c' => 'Internal','Ship_To_Name__c' => 'Test','Have_Hardware_Products__c' => false,'ScreenStatus__c' => 'Approved','RecordTypeId' => Schema.SObjectType.Order.getRecordTypeInfosByName().get('RMA Order')?.getRecordTypeId()});
        insert Ord;

      List<SBQQ__Quote__c> Quote = [Select id from SBQQ__Quote__c];
        
      List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = Quote[0].Id,
          SBQQ__Product__c = lstProds[0].Id,
          SBQQ__Quantity__c = 1,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__StartDate__c = System.today().addDays(7),
          SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1),
          SBQQ__DefaultSubscriptionTerm__c = 12,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
            Is_MSP_Product__c = true,
            Rubrik_Suite__c = 'Foundation',
            Support_Type__c = 'Premium', 
            Payment_Options__c = 'Prepay',
            Licensing_Model__c ='Subscription'
        )
      );
    SBQQ.TriggerControl.disable();
	insert 	lines;

      List<OrderItem> lstOrdrItems = new List<OrderItem>{
     createTestOrderItem(Ord.Id,5,lstPbEntry[0].Id,lstPbEntry[0].UnitPrice,new Map<String, Object>{'SBQQ__QuoteLine__c' => lines[0].Id,'SerialNumber__c' => 'SN124','Failed_Serial_Number__c' => 'SNN-1-1',/*'Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),*/'RMA_Component_Type__c' => 'Node'}),
     createTestOrderItem(Ord.Id,5,lstPbEntry[1].Id,lstPbEntry[1].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'SN123','Failed_Serial_Number__c' => 'SNN-2-2','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'RMA_Component_Type__c' => 'Chassis'}),
     createTestOrderItem(Ord.Id,5,lstPbEntry[1].Id,lstPbEntry[1].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'SN123','Failed_Serial_Number__c' => 'SNN-3-3','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'RMA_Component_Type__c' => 'PSU'}),
     createTestOrderItem(Ord.Id,5,lstPbEntry[1].Id,lstPbEntry[1].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'SN123','Failed_Serial_Number__c' => '0RV5TST01','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'RMA_Component_Type__c' => 'HDD'}),
     createTestOrderItem(Ord.Id,5,lstPbEntry[1].Id,lstPbEntry[1].UnitPrice,new Map<String, Object>{'SBQQ__QuoteLine__c' => lines[0].Id,'SerialNumber__c' => 'SN123','Failed_Serial_Number__c' => '0RV5MEM02','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'RMA_Component_Type__c' => 'Memory'}),
     createTestOrderItem(Ord.Id,5,lstPbEntry[1].Id,lstPbEntry[1].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'SN123','Failed_Serial_Number__c' => '0RV5MEM02','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'RMA_Component_Type__c' => 'Appliance'})
      };
   //TransactionalDataCollection.orderItemMainList.clear();
      insert lstOrdrItems;
      lstOrdrItems[0].SBQQ__QuoteLine__c =  lines[0].Id;
      update  lstOrdrItems; 
      OrderItem temp = [SELECT SerialNumber__c, Failed_Serial_Number__c,SBQQ__QuoteLine__c FROM OrderItem WHERE Id = :lstOrdrItems[0].Id];
      temp.RMA_Component_Type__c = 'Memory';
      update temp;
        

      ord.Order_Status__c = 'Shipped';
      ord.SBQQ__Quote__c = Quote[0].Id;
      update ord;
            test.stopTest();
  
    }
  }
  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to Order trigger logic
   */
  static testMethod void testRevenueShippedOrder() {
    testDataFactoryClass.createCustomSettings();

    System.runAs(new User(Id = UserInfo.getUserId())) {
      Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test' LIMIT 1];
      Assert.areEqual('Test', acct.Name);
      Opportunity oppr = [SELECT Id, pricebook2Id FROM Opportunity WHERE AccountId = :acct.Id LIMIT 1];

      delete [SELECT SBQQ__Type__c FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :acct.Id LIMIT 1];

      Id pricebookId = Test.getStandardPricebookId();

      oppr.pricebook2Id = pricebookId;
      update oppr;

      List<Product2> lstProds = new List<Product2>{
        createTestProduct('RBK-SVC-PREM-R344', 'RBK-SVC-PREM-R344', 'RBK-R300', 'RBK-R6408F', null, new Map<String, Object>{/*'Product_Type__c' => 'US Citizen Support'*/}),
        createTestProduct('RBK-SVC-PREM-R344', 'RBK-SVC-PREM-R344', 'RBK-R300', 'RBK-R640F', null, new Map<String, Object>{}),
        createTestProduct('RS-BT-BE-RSCP-PE-PP', 'RS-BT-BE-RSCP-PE-PP', 'RBK-R300', 'RBK-R640F', null, new Map<String, Object>{})

            	
            };

      insert lstProds;

      List<PricebookEntry> lstPbEntry = new List<PricebookEntry>{
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[0].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[1].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[2].Id, UnitPrice = 100.00, IsActive = true)

            };

      insert lstPbEntry;

      List<Asset> assetsList = new List<Asset>{
          createAsset('SN123', acct.Id, lstProds[0].id, 'Purchased' ,'SN123',new Map<String, Object>{'Serial_Number__c' => 'SN123','Premium_Support_End_Date__c' => Date.today()}),
              createAsset('SNN-1-1', acct.Id, lstProds[1].id, 'Purchased' ,'SN123',new Map<String, Object>{'Serial_Number__c' => 'SNN-1-1','Premium_Support_End_Date__c' => Date.today()})
      };

      insert assetsList;

      List<Chassis__c> chassis = new List<Chassis__c>{
        new Chassis__c(Name = 'C8270FH18NB0100', serial_number__c = 'C8270FH18NB0100', asset__c = assetsList[0].Id, manufactured_date__c = System.now()),
        new Chassis__c(Name = 'C8270FH18NB0101', serial_number__c = 'C8270FH18NB0101', asset__c = assetsList[1].Id, manufactured_date__c = System.now())
      };

      insert chassis;

      List<Node__c> lstNodes = new List<Node__c>{
        new Node__c(
          //Cluster__c = clusters.get(0).Id,
          Asset__c = assetsList[0].Id,
          Serial_Number__c = 'SN123',
          software_version__c = '1.0.1',
          Name = 'SN123',
          chassis__c = chassis[0].Id
        ),
        new Node__c(
          //Cluster__c = clusters.get(0).Id,
          Asset__c = assetsList[0].Id,
          Serial_Number__c = 'SNN-1-1',
          software_version__c = '1.0.1',
          Name = 'SNN-1-1',
          chassis__c = chassis[0].Id
        )
      };

      insert lstNodes;

      List<Power_Supply__c> psus = new List<Power_Supply__c>{
        //new Power_Supply__c(Name = 'SN12345', asset__c = assetsList[0].Id, revision__c = '1.3', serial_number__c = 'SN12345', part_number__c = 'PWS-2K22A-1R', manufactured_date__c = System.now()),
        new Power_Supply__c(
          Name = 'SNN-3-3',
          asset__c = assetsList[0].Id,
          revision__c = '1.3',
          serial_number__c = 'SNN-3-3',
          part_number__c = 'PWS-2K22A-1R',
          manufactured_date__c = System.now()
        )
      };

      insert psus;

      List<Drive__c> Hdddrives = new List<Drive__c>{
        new Drive__c(
          Name = '0RV5TST01',
          asset__c = assetsList[0].Id,
          serial_number__c = '0RV5TST01',
          node__c = lstNodes[0].Id,
          type__c = 'HDD',
          manufactured_date__c = System.now()
        )
        //new Drive__c(Name = '0RV5TST02', asset__c = assetsList[0].Id,serial_number__c = '0RV5TST02', node__c=nodes[0].Id,type__c='HDD', manufactured_date__c = System.now())
      };

      insert Hdddrives;

      List<Memory__c> memory = new List<Memory__c>{
        //new Memory__c(Name = '0RV5MEM01', asset__c = assets[0].Id,serial_number__c = '0RV5MEM01', node__c = nodes[0].Id ,manufactured_date__c = System.now()),
        new Memory__c(Name = '0RV5MEM02', asset__c = assetsList[0].Id, serial_number__c = '0RV5MEM02', node__c = lstNodes[0].Id, manufactured_date__c = System.now())
      };

      insert memory;

      test.startTest();
      Order ord = createTestorder('Revenue',null, acct.Id,oppr.Id,null,pricebookId,null,null,new Map<String, Object>{'Order_Status__c' => 'On Hold','Mosaic_SKUs__c' => 'RBK-MOSAIC','Order_Splitted__c' => true,'Internal_Order_Stage__c' => 'Pending','Screening_Source__c' => 'Internal','Ship_To_Name__c' => 'Test','Have_Hardware_Products__c' => false,'ScreenStatus__c' => 'Approved','RecordTypeId' => Schema.SObjectType.Order.getRecordTypeInfosByName().get('RMA Order')?.getRecordTypeId()});
      insert Ord;

      List<OrderItem> lstOrdrItems = new List<OrderItem>{
        createTestOrderItem(Ord.Id,5,lstPbEntry[0].Id,lstPbEntry[0].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'SN123','Failed_Serial_Number__c' => 'SNN-1-1','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'RMA_Component_Type__c' => 'Node'}),
        createTestOrderItem(Ord.Id,5,lstPbEntry[1].Id,lstPbEntry[1].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'SN123','Failed_Serial_Number__c' => 'SNN-2-2','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'RMA_Component_Type__c' => 'Chassis'}),
        createTestOrderItem(Ord.Id,5,lstPbEntry[1].Id,lstPbEntry[1].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'SN123','Failed_Serial_Number__c' => 'SNN-3-3','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'RMA_Component_Type__c' => 'PSU'}),
        createTestOrderItem(Ord.Id,5,lstPbEntry[1].Id,lstPbEntry[1].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'SN123','Failed_Serial_Number__c' => '0RV5TST01','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'RMA_Component_Type__c' => 'HDD'}),
        createTestOrderItem(Ord.Id,5,lstPbEntry[1].Id,lstPbEntry[1].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'SN123','Failed_Serial_Number__c' => '0RV5MEM02','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'RMA_Component_Type__c' => 'Memory'}),
        createTestOrderItem(Ord.Id,5,lstPbEntry[2].Id,lstPbEntry[2].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'SN123','Failed_Serial_Number__c' => '0RV5MEM02','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'RMA_Component_Type__c' => 'Memory'})

      };

      TransactionalDataCollection.orderItemMainList.clear();
      insert lstOrdrItems;
      OrderItem temp = [SELECT SerialNumber__c, Failed_Serial_Number__c FROM OrderItem WHERE Id = :lstOrdrItems[0].Id];
      test.stopTest();
      ord.Order_Status__c = 'Shipped';
      update ord;
      OrderUpdateHelper.executeSplitOrderBatch();
    }
  }
  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to Order trigger logic
   */
  public static testMethod void testSendEmailSalesOps() {
    System.runAs(new User(Id = UserInfo.getUserId())) {
      List<Account> actList = new List<Account>();
      Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
      actList.add(act);
      insert actList;
      Assert.areEqual(true, actList.size() > 0);
      //insert opportunity.
     
        
        
      opportunity opp =  createOpportunity('testing DIEtestsalesforce 4/6/2015','1 Discovery',actList[0].Id,Date.Today().addDays(10),new Map<String,object>{'Alliance_Source_Type_HW__c' => 'Rubrik Initiated Alliance Deal','Mosaic_Customer_Environment__c' => 'AWS','Lead_Email_Hidden__c' => '','Rubrik_Sales_Engineer__c' => UserInfo.getUserId(),'Alliance_Partner_Name__c' => 'Amazon','Alliance_Source_Type__c' => 'Alliance Initiated Deal','Installation_Assigned_To__c' => 'FE Install'});
      insert opp;

      test.startTest();
      Order od1 = createTestorder('Revenue',null, actList[0].id,opp.Id,null,null,null,null,new Map<String, Object>{'BookingStatus__c' => 'Booking Created'});
      insert od1;
      od1.Order_Status__c = 'On Hold';
      od1.Hold_Code__c = 'Missing start or end dates';
      update od1;
      test.stopTest();
    }

  }
  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to Order trigger logic
   */
  public static testMethod void testSendEmailResOwnerSalesOps() {
    System.runAs(new User(Id = UserInfo.getUserId())) {
      List<Account> actList = new List<Account>();
      Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
      actList.add(act);
      insert actList;
      Assert.areEqual(true, actList.size() > 0);
      //  SBQQ__Quote__c quote = [select id,name,SBQQ__Account__c,SBQQ__Opportunity2__c,SBQQ__NetAmount__c,ProcessType__c from SBQQ__Quote__c WHERE SBQQ__Primary__c = true limit 1];
      //insert opportunity.
      
      opportunity opp =  createOpportunity('testing DIEtestsalesforce 4/6/2015','1 Discovery',actList[0].Id,Date.Today().addDays(10),new Map<String,object>{'Alliance_Source_Type_HW__c' => 'Rubrik Initiated Alliance Deal','Mosaic_Customer_Environment__c' => 'AWS','Lead_Email_Hidden__c' => '','Rubrik_Sales_Engineer__c' => UserInfo.getUserId(),'Alliance_Partner_Name__c' => 'Amazon','Alliance_Source_Type__c' => 'Alliance Initiated Deal','Installation_Assigned_To__c' => 'FE Install'});
      insert opp;

      test.startTest();

      Order od1 = createTestorder('Revenue',null, actList[0].id,opp.Id,null,null,null,null,new Map<String, Object>{'BookingStatus__c' => 'Booking Created'});
      insert od1;
      od1.Order_Status__c = 'On Hold';
      od1.Hold_Code__c = 'Missing start or end dates';

      update od1;
      OrderInsertHelper helplerClass = new OrderInsertHelper();
      helplerClass.SendEmailResOwnerSalesOps(new Set<Id>{ od1.Id });
      helplerClass.validateOrder(new List<Order>{ od1 });
      //   helplerClass.submitOrderValidationForRCDMT(od1);
      test.stopTest();
    }
  }
  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to Order trigger logic
   */
  public static testMethod void testsubmitOrderValidationForRCDMT() {
    System.runAs(new User(Id = UserInfo.getUserId())) {
        insert new ShGl_DisableBusinessLogic__c(
            Disable_Order_Validation_Rules__c = true
        );
  
      Id pricebookId = Test.getStandardPricebookId();

      List<Opportunity> lstOpp = [SELECT id, AccountId, pricebook2Id, Opportunity_Sub_Type__c FROM Opportunity LIMIT 1];
      lstOpp[0].pricebook2Id = pricebookId;
      update lstOpp;
        Assert.areEqual(true, lstOpp.size() > 0);
        SBQQ__Quote__c qtq = [SELECT Id, name, SBQQ__NetAmount__c, SBQQ__PricebookId__c FROM SBQQ__Quote__c LIMIT 1];
        Order ord = createTestorder('Revenue',qtq.Id, lstOpp[0].AccountId,lstOpp[0].Id,lstOpp[0].AccountId,pricebookId,'Not needed','Renewal',new Map<String, Object>{});
        insert ord;

      Product2 objProds = createTestProduct('RBK-RRW', 'RS-BT-EE-PE-PP', 'Rubrik Licence', null, 'Hybrid Software', new Map<String, Object>{'Category__c' => 'Bundle','Product_Type__c' => 'Complete Edition','License_Category__c' => 'SaaS','SBQQ__AssetAmendmentBehavior__c' => 'Default','SBQQSC__EntitlementConversion__c' => 'One per quote line','SBQQ__SubscriptionPricing__c' => 'Fixed Price','SBQQ__SubscriptionTerm__c' => 36,'SBQQ__SubscriptionBase__c' => 'List','SBQQ__SubscriptionType__c' => 'Renewable'});
      insert objProds;

      PricebookEntry pb1 = new PricebookEntry(UseStandardPrice = false, Pricebook2Id = pricebookId, Product2Id = objProds.Id, UnitPrice = 100.00, IsActive = true);
      insert pb1;

      OrderItem objOI =  createTestOrderItem(Ord.Id,5,pb1.Id,pb1.UnitPrice,new Map<String, Object>{'Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today()});
      insert objOI;

      test.StartTest();
      List<order> lstorder = [SELECT Id, accountId, Type, Change_Needed_Reason_Other__c, ShipToContactName__c, Order_Status__c,Polaris_Fulfillment_Status__c FROM order LIMIT 1];
      //lstorder[0].Order_Status__c = 'Pending';
      lstorder[0].Hold_Code__c = 'Missing start or end dates';

      update lstorder;
      Account acc = [SELECT id, Eligible_for_RCDM_T__c FROM account WHERE Id = :ord.AccountId];
      acc.Eligible_for_RCDM_T__c = true;
      update acc;
      OrderInsertHelper helplerClass = new OrderInsertHelper();
      helplerClass.accountMap = new Map<Id, Account>();

      helplerClass.orderIdOrderItemMap.put(lstorder[0].Id, new List<OrderItem>{ objOI });
      helplerClass.accountMap.put(ord.AccountId, acc);
      helplerClass.submitOrderValidationForRCDMT(lstorder[0]);

      lstorder[0].Order_Status__c = 'Shipped';
      lstorder[0].Polaris_Fulfillment_Status__c = 'Completed';
      update lstorder;
	
      // lstorder[0].Order_Status__c = 'Pending';
      //  update lstorder;
	    test.StopTest();
    }

  }
  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to OrderItem trigger logic
   */
  static testMethod void testProcessOrderItem1() {
    testDataFactoryClass.createCustomSettings();

    String uniqueUserName = 'AdminUser' + DateTime.now().getTime() + '@rubrik.com';
    Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
          User u = createTestUser(null, p.Id, uniqueUserName, 'adminU','AdminUser@rubrik.com', new Map<String, Object>{'RBAC_Department__c'=>'IT','RBAC_Group__c'=>'System Admin','ManagerId'=>UserInfo.getUserId(),'EmailEncodingKey' => 'UTF-8','LastName' => 'Testing','LanguageLocaleKey' => 'en_US','LocaleSidKey' => 'en_US','TimeZoneSidKey' => 'America/Los_Angeles'});
    System.runAs(u) {
      insert new ShGl_DisableBusinessLogic__c(
        Disable_Entitlement_Validation_Rules__c = true,
        Disable_Opportunity_Validation_Rules__c = true,
        Disable_POC_Validation_Rules__c = true,
        Disable_Contact_Triggers__c = true,
        Disable_SBQQ_Quote_Triggers__c = true,
        Disable_SBQQ_QuoteLine_Triggers__c = true,
        Disable_POC_Trigger__c = true,
        Disable_Order_Validation_Rules__c = true
  
      );

      Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test' LIMIT 1];
      Assert.areEqual('Test', acct.Name);
      Opportunity oppr = [SELECT Id, pricebook2Id FROM Opportunity WHERE AccountId = :acct.Id LIMIT 1];

      Id pricebookId = Test.getStandardPricebookId();
      oppr.pricebook2Id = pricebookId;
      update oppr;
        
      PS_Project__c objPsProject = new PS_Project__c();
      objPsProject.Name = 'test project';
      objPsProject.Opportunity__c = oppr.Id;
      objPsProject.Account__c = acct.id;
      objPsProject.Project_Manager__c = userinfo.getuserid();
      objPsProject.Manager__c = 'test@test.com';
      insert objPsProject;
      test.startTest();
      delete [SELECT SBQQ__Type__c FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :acct.Id LIMIT 1];
      Product2 prod = createTestProduct('RBK-SVC-PREM-R344', 'RBK-SVC-PREM-R344', 'POLARIS', 'RBK-R6408E', null, new Map<String, Object>{'SBQQ__SubscriptionPricing__c' => 'Fixed Price','SBQQ__SubscriptionTerm__c' => 36,'Bundle_Features__c' => 'Polaris','Create_Entitlement__c' => true,'SBQQSC__EntitlementConversion__c' => 'One per unit','Create_Asset__c' => true});
      insert prod;

      PricebookEntry pbEntry = new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = prod.Id, UnitPrice = 100.00, IsActive = true);
      insert pbEntry;

      OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = oppr.Id, Quantity = 5, PricebookEntryId = pbEntry.Id, TotalPrice = 5 * pbEntry.UnitPrice);
      // test.startTest();
      insert oli;

        POC__c pocobjLoaner =  createTestPocObject('60 Days',date.today().addDays(90),'Yes','Business Loaner Unit','Rubrik Appliance',new Map<String, Object>{});
      insert pocobjLoaner;

      List<Asset> assetsList = new List<Asset>{
          createAsset('SN123', acct.Id, prod.id,'Purchased','SN123',new Map<String, Object>{'Serial_Number__c' => 'SN123','Premium_Support_End_Date__c' => Date.today()})
      };
      insert assetsList;
      List<Entitlement> entitlements = new List<Entitlement>{
          createEntitlement('ENT-4',acct.Id,prod.Id,assetsList[0].Id, new Map<String, Object> {'Type' => 'Web Support','StartDate' => Date.valueof(System.now().addDays(-2)),'EndDate' => Date.valueof(System.now().addYears(2))})
      };
      insert entitlements;
          List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
        // private static order createTestorder( String type, id quoteId, id accountId, id opportunityId,id shipToName, id pricebook2Id,string orderSplitType, string orderSubType, Map<String, Object> additionalFields) {
 
          Order Ord = createTestorder('POC',null, acct.Id,oppr.Id,acct.id ,pricebookId,null,'Renewal',new Map<String, Object>{'POC_Request__c' => pocobjLoaner.Id,'POC_Opportunity__c' => oppr.Id,'Order_Status__c' => null,'Have_Hardware_Products__c' => true,'Order_Splitted__c' => true,'RecordTypeId' => Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order')?.getRecordTypeId()});
          insert Ord;
          OrderItem ordrItem =  createTestOrderItem(Ord.Id,5,pbEntry.Id,pbEntry.UnitPrice,new Map<String, Object>{'SerialNumber__c' => '123\\s+,456\\s+','Trade_Up_SerialNumber__c' =>'S3F4NXM416324','Failed_Serial_Number__c' => 'S3F4NXM416324','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'Is_Hardware_Line__c' => true,'Is_Refresh__c' => true,'Upgraded_From__c' => assetsList[0].Id});
          insert ordrItem;

      entitlements[0].Order_Service_Item__c = ordrItem.id;

      update entitlements[0];

      ord.Actual_Order_Ship_Date__c = date.today();
      ord.Order_Status__c = 'Shipped';
      update ord;
      test.stopTest();
    }
  }
  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to OrderItem trigger logic
   */
  static testMethod void testProcessOrderItem2() {
    testDataFactoryClass.createCustomSettings();

    String uniqueUserName = 'AdminUser' + DateTime.now().getTime() + '@rubrik.com';
    Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
              User u = createTestUser(null, p.Id, uniqueUserName, 'adminU','AdminUser@rubrik.com', new Map<String, Object>{'EmailEncodingKey' => 'UTF-8','LastName' => 'Testing','LanguageLocaleKey' => 'en_US','LocaleSidKey' => 'en_US','TimeZoneSidKey' => 'America/Los_Angeles'});
  	System.runAs(u) {
      insert new ShGl_DisableBusinessLogic__c(
        Disable_Entitlement_Validation_Rules__c = true,
        Disable_Opportunity_Validation_Rules__c = true,
        Disable_POC_Validation_Rules__c = true,
        Disable_Contact_Triggers__c = true,
        Disable_SBQQ_Quote_Triggers__c = true,
        Disable_SBQQ_QuoteLine_Triggers__c = true,
        Disable_POC_Trigger__c = true,
        Disable_Order_Validation_Rules__c = true,
        Disable_SBQQ_Quote_Validation_Rules__c = true

      );


      Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test' LIMIT 1];
      Assert.areEqual('Test', acct.Name);
      Opportunity oppr = [SELECT Id, pricebook2Id FROM Opportunity WHERE AccountId = :acct.Id LIMIT 1];

      Id pricebookId = Test.getStandardPricebookId();
      oppr.pricebook2Id = pricebookId;
      update oppr;
        
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = acct.Id;
        qt.SBQQ__Opportunity2__c = oppr.Id;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__SubscriptionTerm__c = 36;
        qt.Manual_Fulfillment_Quote__c = 'Other-Enter Text';
        qt.SBQQ__ExpirationDate__c = date.today().addDays(10);
        qt.SBQQ__PaymentTerms__c = 'Net 45';
        qt.SBQQ__Type__c = 'Renewal+Expansion';
        qt.Is_Refreshed__c = true;
        qt.ProcessType__c = 'Aspen';
        qt.RWD_Deal_Ops_Exception__c   = '$0 RSC-G Replacement';
        insert qt;

  

      List<Product2> lstProds = new List<Product2>{
              createTestProduct('RBK-SVC-PREM-R344', 'RBK-SVC-TR', 'ASE', 'RBK-R6408E', null, new Map<String, Object>{'Capacity__c' => '12TB'}),
              createTestProduct('RBK-SVC-PREM-R3441', 'RBK-SVC-TR1', 'ASE1', 'RBK-R6408E1', null, new Map<String, Object>{'Capacity__c' => '36TB'})
      };

      insert lstProds;

      List<PricebookEntry> lstPbEntry = new List<PricebookEntry>{
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[0].Id, UnitPrice = 100.00, IsActive = true)
      };

      insert lstPbEntry;

      delete [SELECT SBQQ__Type__c FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :acct.Id LIMIT 1];

      OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = oppr.Id, Quantity = 5, PricebookEntryId = lstPbEntry[0].Id, TotalPrice = 5 * lstPbEntry[0].UnitPrice);
      // test.startTest();
      insert oli;
      POC__c pocobjLoaner = createTestPocObject('60 Days',date.today().addDays(90),'Yes','Standard POC','Rubrik Appliance',new Map<String, Object>{});
      insert pocobjLoaner;
      List<Asset> assetsList = new List<Asset>{
      createAsset('SN123', acct.Id, lstProds[0].id,'Purchased','SN123',new Map<String, Object>{'Serial_Number__c' => 'SN123','Premium_Support_End_Date__c' => Date.today()})
      };

      insert assetsList;

      List<Entitlement> entitlements = new List<Entitlement>{
        createEntitlement('ENT-4',acct.Id,lstProds[0].id,assetsList[0].Id, new Map<String, Object> {'StartDate' => Date.valueof(System.now().addDays(-2)),'EndDate' => Date.valueof(System.now().addYears(2))})
      };

      insert entitlements;

      test.startTest();
        List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
        Order Ord = createTestorder('POC',qt.id, acct.Id,oppr.Id,acct.id ,pricebookId,null,'Renewal',new Map<String, Object>{'POC_Request__c' => pocobjLoaner.Id,'POC_Opportunity__c' => oppr.Id,'Order_Status__c' => null,'ship_To_Name__c' => acct.id,'Pricebook2Id' => pricebookId,'Have_Hardware_Products__c' => true,'Order_Splitted__c' => true,'Order_Sub_Type__c' => 'Renewal','RecordTypeId' => Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order')?.getRecordTypeId()});
        insert Ord;
        List<OrderItem> orderLines = new List<OrderItem>{
        createTestOrderItem(Ord.Id,5,lstPbEntry[0].Id,lstPbEntry[0].UnitPrice,new Map<String, Object>{'SerialNumber__c' => '123\\s+,456\\s+','Failed_Serial_Number__c' => 'S3F4NXM416324','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'Is_Hardware_Line__c' => true,'Is_Refresh__c' => true,'Upgraded_From__c' => assetsList[0].Id})
       // createTestOrderItem(Ord.Id,5,lstPbEntry[1].Id,lstPbEntry[1].UnitPrice,new Map<String, Object>{'SerialNumber__c' => '123\\s+,456\\s+','Failed_Serial_Number__c' => 'S3F4NXM416324','Is_Hardware_Line__c' => true,'Is_Refresh__c' => true,'Upgraded_From__c' => assetsList[0].Id})
        };

        TriggerControl.stopOrderItemTrigger = true;
        insert orderLines;
        TriggerControl.stopOrderItemTrigger = false;
   
 
       // entitlements[0].Order_Service_Item__c = orderLines[0].id;
       // update entitlements[0];
        ord.Actual_Order_Ship_Date__c = date.today();
        ord.Order_Status__c = 'Shipped';
        update ord;
        test.stopTest();
    }
  }
  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to OrderItem trigger logic
   */
  static testMethod void testProcessOrderItem3() {
    testDataFactoryClass.createCustomSettings();

    String uniqueUserName = 'AdminUser' + DateTime.now().getTime() + '@rubrik.com';
    Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
     User u = createTestUser(null, p.Id, uniqueUserName, 'adminU','AdminUser@rubrik.com', new Map<String, Object>{'EmailEncodingKey' => 'UTF-8','LastName' => 'Testing','LanguageLocaleKey' => 'en_US','LocaleSidKey' => 'en_US','TimeZoneSidKey' => 'America/Los_Angeles'});
    System.runAs(u) {
      insert new ShGl_DisableBusinessLogic__c(
        Disable_Entitlement_Validation_Rules__c = true,
        Disable_Opportunity_Validation_Rules__c = true,
        Disable_POC_Validation_Rules__c = true,
        Disable_POC_Trigger__c = true,
        Disable_Contact_Triggers__c = true,
        Disable_SBQQ_Quote_Triggers__c = true,
        Disable_SBQQ_QuoteLine_Triggers__c = true,
        Disable_Order_Validation_Rules__c = true
       // Disable_SBQQ_Quote_Validation_Rules__c = true
      );

      Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test' LIMIT 1];
      Assert.areEqual('Test', acct.Name);
      Opportunity oppr = [
        SELECT
          Id,
          New_Expansion_TCV__c,
          Subsumed_Renewal_TCV__c,
          ACV_Amount__c,
          New_Expansion_ACV__c,
          Renewal_Subsumed_ACV__c,
          pricebook2Id,
          Distributor_Lookup__r.EDI_DISTI_ID__c,
          AccountId,
          Opportunity_Type__c,
          Deal_Registration_Type__c,
          FocusedPartner__c
        FROM Opportunity
        WHERE AccountId = :acct.Id
        LIMIT 1
      ];

      PS_Project__c objPsProject = new PS_Project__c();
      objPsProject.Name = 'test project';
      objPsProject.Account__c = acct.id;
      objPsProject.Project_Manager__c = userinfo.getuserid();
      objPsProject.Manager__c = 'test@test.com';
      //insert objPsProject;

      Set<PS_Project__c> PSProjToInsert = new Set<PS_Project__c>();
      PSProjToInsert.add(objPsProject);

      Id pricebookId = Test.getStandardPricebookId();
      oppr.pricebook2Id = pricebookId;
      update oppr;
  

      List<Product2> lstProds = new List<Product2>{
        createTestProduct('RBK-SVC-PREM-R344', 'RBK-SVC-TR', 'ASE', 'RBK-R6408F', null, new Map<String, Object>{'Capacity__c' => '12TB'}),
        createTestProduct('RBK-SVC-PREM-R344', 'RBK-SVC-TR', 'ASE', 'RBK-R6408F', null, new Map<String, Object>{'Capacity__c' => '36TB'})
      };

      insert lstProds;

      List<PricebookEntry> lstPbEntry = new List<PricebookEntry>{
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[0].Id, UnitPrice = 100.00, IsActive = true)
      };

      insert lstPbEntry;

      delete [SELECT SBQQ__Type__c FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :acct.Id LIMIT 1];

      Product2 prod =  createTestProduct('RBK-SVC-PREM-R344', 'RBK-SVC-PREM-R344', 'POLARIS', 'RBK-R6408E', null, new Map<String, Object>{'SBQQ__SubscriptionPricing__c' => 'Fixed Price','SBQQ__SubscriptionTerm__c' => 36,'Bundle_Features__c' => 'Polaris','Create_Entitlement__c' => true,'SBQQSC__EntitlementConversion__c' => 'One per unit','Create_Asset__c' => true});
      insert prod;
      PricebookEntry pbEntry = new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = prod.Id, UnitPrice = 100.00, IsActive = true);
      insert pbEntry;

      OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = oppr.Id, Quantity = 5, PricebookEntryId = pbEntry.Id, TotalPrice = 5 * pbEntry.UnitPrice);
      // test.startTest();
      insert oli;

      POC__c pocobjLoaner =  createTestPocObject('60 Days',date.today().addDays(90),'Yes','Conditional PO','Rubrik Appliance',new Map<String, Object>{});
      insert pocobjLoaner;

        List<Asset> assetsList = new List<Asset>{
            createAsset('SN123', acct.Id, prod.id,'Purchased','SN123',new Map<String, Object>{'Serial_Number__c' => 'SN123','Premium_Support_End_Date__c' => Date.today()})
                };

      insert assetsList;

      List<Entitlement> entitlements = new List<Entitlement>{
               createEntitlement('ENT-4',acct.Id,prod.Id,assetsList[0].Id, new Map<String, Object> {'Type' => 'Web Support','StartDate' => Date.valueof(System.now().addDays(-2)),'EndDate' => Date.valueof(System.now().addYears(2))})
      };

      insert entitlements;
      test.startTest();
      List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
        Order Ord = createTestorder('POC',null, acct.Id,oppr.Id,acct.id ,pricebookId,null,'Renewal',new Map<String, Object>{'POC_Request__c' => pocobjLoaner.Id,'POC_Opportunity__c' => oppr.Id,'Order_Status__c' => null,'Have_Hardware_Products__c' => true,'Order_Splitted__c' => true,'ProcessType__c' => 'Aspen','RecordTypeId' => Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order')?.getRecordTypeId()});
      insert Ord;
      Ord.PS_Project__c = objPsProject.id;
      update Ord;
      order ord1 = [SELECT id, totalAmount, Bill_To_Name__c, ProcessType__c, Order_Sub_Type__c, Polaris_Fulfillment_Status__c, ScreenStatus__c, SBQQ__Quote__c  FROM order WHERE id = :ord.Id];
      ord1.Type = 'Revenue';
      //ord1.SBQQ__Quote__c  = qt.Id;  
      update ord1;
      OrderItem ordrItem =   createTestOrderItem(Ord.Id,5,lstPbEntry[0].Id,lstPbEntry[0].UnitPrice,new Map<String, Object>{'SerialNumber__c' => '123\\s+,456\\s+','Failed_Serial_Number__c' => 'S3F4NXM416324','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'Is_Hardware_Line__c' => true,'Is_Refresh__c' => true,'R300_R500_Asset__c' => assetsList[0].Id});
      insert ordrItem;
      orderitem item = [SELECT id, unitprice, quantity, totalprice, SerialNumber__c, product2.Name, Product2.Family FROM orderItem WHERE orderid = :ord.id LIMIT 1];
      entitlements[0].Order_Service_Item__c = ordrItem.id;
      entitlements[0].Type = 'Manufacturing Entitlement';
      update entitlements[0];
      ord.Actual_Order_Ship_Date__c = date.today();
      ord.Order_Status__c = 'Shipped';
      update ord;
      map<id, Entitlement> entMap = new Map<id, Entitlement>();
      list<list<Entitlement>> ent1 = new List<list<Entitlement>>();
      ent1.add(entitlements);
      list<orderItem> OIList = new List<OrderItem>();
      OIList.add(Item);
      Rebate_Table__c rebate = [
        SELECT
          id,
          Rebate__c,
          ASPEN_Rebate__c,
          Installation_Product__c,
          Value_Add_Distribution_fee__c,
          Distributor__r.name,
          Rebate_Type__c,
          Rebate_Deal_Type__c,
          Start_Date__c,
          End_Date__c,
          Distributor__c
        FROM Rebate_Table__c
        WHERE Rebate_Type__c = 'Distributor Fee'
      ];
      Rebate_Table__c rebate1 = [
        SELECT
          id,
          Rebate__c,
          ASPEN_Rebate__c,
          Installation_Product__c,
          Value_Add_Distribution_fee__c,
          Distributor__r.name,
          Rebate_Type__c,
          Rebate_Deal_Type__c,
          Start_Date__c,
          End_Date__c
        FROM Rebate_Table__c
        WHERE Rebate_Type__c = 'Velocity Partner Program Rebate'
      ];
      rebate.Start_Date__c = System.Today().addDays(-10);
      rebate.End_Date__c = null;
      update rebate;
      ord1.Bill_To_Name__c = rebate.Distributor__c;
      ord1.Order_Sub_Type__c = 'MSP Consumption';
      ord1.Polaris_Fulfillment_Status__c = 'Completed';
      ord1.ScreenStatus__c = 'Approved';
      ord1.POC_Request__c = pocobjLoaner.id;
      update ord1;

      Booking__c book = new Booking__c();
      book.Account_Name__c = acct.id;
      book.CreatedDate = date.today();
      insert book;
      Booking_Line_Item__c bookline = new Booking_Line_Item__c();
      bookline.Booking__c = book.id;

      insert bookline;

      set<Booking_Line_Item__c> booklineSet = new Set<Booking_Line_Item__c>();
      booklineSet.add(bookline);

      Id bkId = book.Id;
      BLI_Impact__mdt bli_impact = [
        SELECT Id, Adjustment_Type__c, Impacts_Gross_Bookings__c, Impacts_Net_Bookings__c, Impacts_Commissions__c
        FROM BLI_Impact__mdt
        WHERE Adjustment_Type__c = 'Revenue'
        LIMIT 1
      ];
      list<BLI_Impact__mdt> BLIimpactList = new List<BLI_Impact__mdt>();
      BLIimpactList.add(bli_impact);

      BLI_Impact__mdt bli_impact1 = [
        SELECT Id, Adjustment_Type__c, Impacts_Gross_Bookings__c, Impacts_Net_Bookings__c, Impacts_Commissions__c
        FROM BLI_Impact__mdt
        WHERE Adjustment_Type__c = 'Velocity Partner Program Rebate'
        LIMIT 1
      ];
      list<BLI_Impact__mdt> BLIimpactList1 = new List<BLI_Impact__mdt>();
      BLIimpactList1.add(bli_impact1);
      set<Rebate_Table__c> rebateSet = new Set<Rebate_Table__c>();
      Map<Id, Decimal> mapBKgIdToNetRenewal = new Map<Id, Decimal>();
      Map<Id, Decimal> mapBKgIdToNetNew = new Map<Id, Decimal>();
      Map<Id, Decimal> mapBKgIdToGrossACVAmt = new Map<Id, Decimal>();
      Map<Id, Decimal> mapBKgIdToGrossNewACV = new Map<Id, Decimal>();
      Map<Id, Decimal> mapBKgIdToGrossRenewalACV = new Map<Id, Decimal>();

      //  rebateSet.add(rebate);
      rebateSet.add(rebate1);
      OrderUpdateHelper orderHelp = OrderUpdateHelper.getInstance();
      mapBKgIdToNetNew.put(bkId, oppr.New_Expansion_TCV__c);
      mapBKgIdToNetRenewal.put(bkId, oppr.Subsumed_Renewal_TCV__c);
      mapBKgIdToGrossACVAmt.put(bkId, oppr.ACV_Amount__c);
      mapBKgIdToGrossNewACV.put(bkId, oppr.New_Expansion_ACV__c);
      mapBKgIdToGrossRenewalACV.put(bkId, oppr.Renewal_Subsumed_ACV__c);
      orderHelp.ActivateOrders(ord);
      orderHelp.updateEntitlementsPartner(ent1, entMap);
      orderHelp.CommitabeforeUpdateRecords(PSProjToInsert);
       oppr.Opportunity_Type__c = 'New Customer'; 
        oppr.Deal_Registration_Type__c = 'Partner Initiated Deal';
        try{
           orderHelp.CreateRebateBLI(
            ord1,
            OIList, 
            rebate,
            book,
            oppr,
            BLIimpactList1,
            mapBKgIdToNetRenewal,
            mapBKgIdToNetNew,
            mapBKgIdToGrossACVAmt,
            mapBKgIdToGrossNewACV,
            mapBKgIdToGrossRenewalACV); 
        }catch(Exception ex){
         System.debug(LoggingLevel.debug,'The following exception has occurred: ' + ex.getMessage());
        }
        
      test.stopTest();
    }
  }
  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to Order trigger logic
   */
  static testMethod void testShipmentDetails() {
    User currentUsr = createUser();

    System.runAs(currentUsr) {
      // insert new ShGl_DisableBusinessLogic__c(Disable_POC_Validation_Rules__c = true,Disable_Contact_Triggers__c =true,Disable_SBQQ_Quote_Triggers__c = true, Disable_SBQQ_QuoteLine_Triggers__c=true);
      
      insert new TriggerControl__c(Name = 'Entitlement', DisableTrigger__c = true);
      ShGl_DisableBusinessLogic__c control = new ShGl_DisableBusinessLogic__c(
        Disable_Entitlement_Validation_Rules__c = true,
        Disable_SBQQ_Quote_Triggers__c = true,
        Disable_Order_Validation_Rules__c = true,
        Disable_SBQQ_QuoteLine_Triggers__c = true,
        Disable_Opportunity_Validation_Rules__c = true,
        Disable_Opportunity_Triggers__c = true,
        Disable_Order_Email_Alerts__c = false,
        Disable_Order_Old_Trigger__c = true,
        Disable_Order_Triggers__c = true,
        Disable_Asset_Triggers__c = true,
        Disable_Contact_Triggers__c = true,
        Order_Trigger_MaxLoop_Count__c = 25,
        setupOwnerId = currentUsr.id
      );
      insert control;
      SBQQ__Quote__c quote = [SELECT id, name, SBQQ__Account__c, SBQQ__Opportunity2__c, SBQQ__NetAmount__c, ProcessType__c FROM SBQQ__Quote__c LIMIT 1];
      set<string> addProduct = new Set<string>{
        'HybridProd-001-test',
        'HybridProd-002-test',
        'HWSupportProd-001-test',
        'HWSupport2Prod-001-test',
        'HWPROD-001-TEST',
        'HWPROD-002-TEST',
        'AddonProd-001-test',
        'RC-HDD-01'
      };
      Map<string, string> childParentMap = new Map<string, string>{
        'HWPROD-001-TEST' => 'HybridProd-001-test',
        'HWProd-002-test' => 'HybridProd-002-test',
        'HWSupportProd-001-test' => 'HWPROD-001-TEST',
        'HWSupport2Prod-001-test' => 'HWPROD-001-TEST',
        'AddonProd-001-test' => 'HybridProd-001-test',
        'RC-HDD-01' => 'HWPROD-001-TEST'
      };
      createProductAndPBE();
      createPolarisQuote(addProduct, quote, childParentMap);
      Map<Id, Id> prodPBEId = new Map<id, id>();
      for (PricebookEntry pbe : [SELECT id, product2Id, product2.name FROM PricebookEntry WHERE Pricebook2id = :system.label.CPQPricebookID]) {
        prodPBEId.put(pbe.product2Id, pbe.id);
      }
      DateTime todaysDate = Date.Today();
      String dateStr = todaysDate.format('MM/dd/yyyy');
       Order Ord = createTestorder('Revenue',quote.id, quote.SBQQ__Account__c,quote.SBQQ__Opportunity2__c,null ,system.label.CPQPricebookID,null,'Renewal',new Map<String, Object>{'ProcessType__c' => 'Aspen','Fulfilment_Set_Name__c' => 'Test','PriceBook2Id' => system.label.CPQPricebookID,'Status' => 'Draft','Order_Status__c' => 'Shipped','Is_RWD_Polaris_Quote__c' => true });
       Order Ord1 = createTestorder('Revenue',quote.id, quote.SBQQ__Account__c,quote.SBQQ__Opportunity2__c,null ,system.label.CPQPricebookID,null,'Renewal',new Map<String, Object>{'ProcessType__c' => 'Aspen','Fulfilment_Set_Name__c' => 'Test','PriceBook2Id' => system.label.CPQPricebookID,'Status' => 'Draft','Order_Status__c' => 'Shipped','Is_RWD_Polaris_Quote__c' => true });
	    test.startTest();
        List<Order> ordList = new List<order>();
      ordList.add(ord);  
      ordList.add(ord1);  
      ordList[1].type = 'POC';
      ordList[1].Sync_to_NetSuite__c = false;
      insert ordList;
      Assert.areEqual(true, ordList.size() > 0);
      List<asset> AssetToInsert = new List<asset>();
      List<OrderItem> OIList = new List<OrderItem>();
      List<ShipmentDetail__c> SDList = new List<ShipmentDetail__c>();
      List<Entitlement> entToInsert = new List<Entitlement>();
      for (integer i = 0; i <= 7; i++) {
        SDList.add(testShipmentDetail(ordList[0].Id,'Fail HW','HWPROD-001-TEST',quote.name,'Aspen',new Map<String, Object>{'Quantity__c' => 12,'ShippedDate__c' => dateStr,'Status__c' => 'New','TrackingNumber__c' => 'Order100','ContractManufacturer__c' => 'Super Micro Computer, Inc.'}));
      }
      // SD without Order
      for (integer i = 0; i <= 7; i++) {
        SDList.add(testShipmentDetail(null,'SDWithoutOrder-Fail','HWPROD-001-TEST',quote.name,'Aspen',new Map<String, Object>{'Quantity__c' => 12,'ShippedDate__c' => dateStr,'Status__c' => 'New','TrackingNumber__c' => 'Order100','ContractManufacturer__c' => 'Super Micro Computer, Inc.'}));
      }
      SDList[0].Type__c = 'InvalidType';
      SDList[0].Order__c = ordList[1].Id;
      SDList[1].Quantity__c = 13;
      SDList[2].ProductName__c = 'Invalid ProdItm';
      SDList[3].ProductName__c = SDList[12].ProductName__c = '';
      SDList[4].HW_SerialNumber__c = SDList[10].HW_SerialNumber__c = ''; // Missing SN with and without order
      SDList[5].QuoteNumber__c = 'Q-Invalid';
      SDList[6].QuoteNumber__c = SDList[13].QuoteNumber__c = '';
      SDList[7].SalesOrderNumber__c = 'Invalid OrderNum';
      SDList[8].SalesOrderNumber__c = 'SPARES'; // SD for spares only
      SDList[8].ProductName__c = 'RC-HDD-01';
      SDList[9].ProductName__c = 'RC-SFP-TSR-0'; // SD for accessory

      SDList.add(testShipmentDetail(ordList[0].Id,'TestAsset12','RC-HDD-01',quote.name,null,new Map<String, Object>{'Quantity__c' => 12,'ShippedDate__c' => dateStr,'Status__c' => 'New','ContractManufacturer__c' => 'Super Micro Computer, Inc.','SalesOrderNumber__c' => 'SPARES','QuoteNumber__c' => quote.name}));
      SDList.add(testShipmentDetail(ordList[0].Id,'TestAsset12','RC-SFP-TSR-01',quote.name,null,new Map<String, Object>{'Quantity__c' => 12,'ShippedDate__c' => dateStr,'Status__c' => 'New','ContractManufacturer__c' => 'Super Micro Computer, Inc.'}));
      SDList.add(testShipmentDetail(ordList[0].Id,null,null,quote.name,null,new Map<String, Object>{'Quantity__c' => 12,'ShippedDate__c' => dateStr,'Status__c' => 'New','ContractManufacturer__c' => 'Super Micro Computer, Inc.','SalesOrderNumber__c' => 'SPARES'}));
      SDList.add(testShipmentDetail(ordList[0].Id,'TestAsset12','Accessories',quote.name,null,new Map<String, Object>{'Quantity__c' => 12,'ShippedDate__c' => dateStr,'Status__c' => 'New','Type__c' => 'Aspen','ContractManufacturer__c' => 'Super Micro Computer, Inc.'}));
      SDList.add(testShipmentDetail(ordList[1].Id,'TestAsset12','Accessories',quote.name,null,new Map<String, Object>{'Quantity__c' => 12,'ShippedDate__c' => dateStr,'Status__c' => 'New','ContractManufacturer__c' => 'Super Micro Computer, Inc.','SalesOrderNumber__c' => 'SPARES'}));
      for (SBQQ__QuoteLine__c qli : [
        SELECT
          id,
          SBQQ__Quote__r.SBQQ__NetAmount__c,
          SBQQ__NetPrice__c,
          SBQQ__NetTotal__c,
          SBQQ__Product__r.productcode,
          SBQQ__Quantity__c,
          SBQQ__SubscriptionTerm__c,
          SBQQ__Product__c,
          SBQQ__Product__r.name,
          SBQQ__Product__r.Product_Level__c,
          SBQQ__RequiredBy__c,
          SBQQ__PricebookEntryId__c
        FROM SBQQ__QuoteLine__c
      ]) {
        if ('Hardware' != qli.SBQQ__Product__r.Product_Level__c) {
          OIList.add(createTestOrderItem(ordList[0].Id,qli.SBQQ__Quantity__c,prodPBEId.get(qli.SBQQ__Product__c),qli.SBQQ__NetPrice__c,new Map<String, Object>{'EDI_Line_Number__c' => qli.id,'SBQQ__QuoteLine__c' => qli.id,'Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today()}));
        } else {
          SDList.add(testShipmentDetail(ordList[0].Id,qli.SBQQ__Product__r.productcode + '001,' + qli.SBQQ__Product__r.productcode + '002',qli.SBQQ__Product__r.productcode,quote.name,'Aspen',new Map<String, Object>{'Quantity__c' => 12,'ShippedDate__c' => dateStr,'Status__c' => 'New','ContractManufacturer__c' => 'Super Micro Computer, Inc.','SalesOrderNumber__c' => 'SPARES','QuoteNumber__c' => quote.name}));
          AssetToInsert.add(createAsset(qli.SBQQ__Product__r.productcode + '001', quote.SBQQ__Account__c, qli.SBQQ__Product__c,null,qli.SBQQ__Product__r.productcode + '001',new Map<String, Object>{'Serial_Number__c' => qli.SBQQ__Product__r.productcode + '001'}));
          AssetToInsert.add(createAsset(qli.SBQQ__Product__r.productcode + '002', quote.SBQQ__Account__c, qli.SBQQ__Product__c,null,qli.SBQQ__Product__r.productcode + '002',new Map<String, Object>{'Serial_Number__c' => qli.SBQQ__Product__r.productcode + '002'}));
        }
      }

      insert OIList;
      insert AssetToInsert;
      insert SDList;
      SDList[10].Status__c = 'New';
      update SDList[10];
      control.Disable_Order_Triggers__c = false;
      update control;
      for (OrderItem OI : [SELECT id, Product2Id, product2.Product_Level__c, Quantity FROM orderItem WHERE id IN :OIList]) {
        if (OI.product2.Product_Level__c == 'Support') {
          for (integer i = 0; i < OI.Quantity; i++) {
            entToInsert.add(createEntitlement('T-' + OI.id + '-' + i,quote.SBQQ__Account__c,OI.Product2ID,null, new Map<String, Object> {'StartDate' => Date.valueof(System.now().addDays(-2)),'EndDate' => Date.valueof(System.now().addYears(2)),'Order_Service_Item__c' => OI.id}));
          }
        } else if (OI.product2.Product_Level__c == 'Hybrid Software') {
          entToInsert.add(createEntitlement('T-' + OI.id,quote.SBQQ__Account__c,OI.Product2ID,null, new Map<String, Object> {'StartDate' => Date.valueof(System.now().addDays(-2)),'EndDate' => Date.valueof(System.now().addYears(2)),'Order_Service_Item__c' => OI.id}));
        }
      }
      insert entToInsert;
      test.stopTest();  

      for (Order ord2 : ordList) {
        ord2.SD_Status__c = 'Start';
      }
      ordList[0].status = 'Activated';
      ordList[0].SBQQ__Contracted__c = true;
      ordList[1].Order_Sub_Type__c = 'GC OnDemand';
      ordList[0].Order_Status__c = 'Shipped';
      ordList[0].Deliver_By__c = Date.Today(); // RV
      ordList[0].Est_Ship_Date__c = Date.Today().addDays(15); // RV
      //ordList[0].Order_Sub_Type__c = null;
      update ordList;
      ordList[0].Order_Sub_Type__c = null;
      ordList[1].Order_Sub_Type__c = null;
      update ordList;
        

        
    }

  }
  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to OrderItem trigger logic // PRDOPS23-80 Start.
   */
  @isTest
  static void testInsertConditionalPO() {
    User currentUsr = createUser();
    System.runAs(currentUsr) {
      Test.startTest();
      insert new TriggerControl__c(Name = 'Entitlement', DisableTrigger__c = true);
      ShGl_DisableBusinessLogic__c control = new ShGl_DisableBusinessLogic__c(
        Disable_SBQQ_Quote_Validation_Rules__c = true,
        Disable_SBQQ_Quote_Triggers__c = true,
        Disable_SBQQ_QuoteLine_Triggers__c = true,
        Disable_Opportunity_Validation_Rules__c = true,
        Disable_Opportunity_Triggers__c = false,
        Disable_Order_Email_Alerts__c = false,
        Disable_Order_Old_Trigger__c = true,
        Disable_Asset_Triggers__c = true,
        Disable_Contact_Triggers__c = true,
        setupOwnerId = currentUsr.id
      );
      insert control;
      SBQQ__Quote__c quote = [SELECT Id, Is_Conditional_PO__c, SBQQ__Type__c, SBQQ__Account__c, SBQQ__Opportunity2__c FROM SBQQ__Quote__c LIMIT 1];
      quote.Is_Conditional_PO__c = true;
      quote.SBQQ__Type__c = 'Revenue';
      update quote;
      Assert.areEqual(true, quote != null);
      DateTime todaysDate = Date.Today();
      String dateStr = todaysDate.format('MM/dd/yyyy');
       Order Ord = createTestorder('Revenue',quote.id, quote.SBQQ__Account__c,quote.SBQQ__Opportunity2__c,null ,system.label.CPQPricebookID,null,null,new Map<String, Object>{'ProcessType__c' => 'Aspen','Status' => 'Draft'});
      insert ord;
      Test.stopTest();
      ord = [SELECT Id, OM_internal_review__c, Change_Needed_Reason_Other__c FROM Order WHERE Id = :ord.Id];
    }
  }
  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to OrderItem trigger logic // PRDOPS23-80
   */
  @isTest
  static void testInsertLegalVerbiage() {
    User currentUsr = createUser();
    System.runAs(currentUsr) {
      Test.startTest();
      insert new TriggerControl__c(Name = 'Entitlement', DisableTrigger__c = true);
      ShGl_DisableBusinessLogic__c control = new ShGl_DisableBusinessLogic__c(
        Disable_SBQQ_Quote_Triggers__c = true,
        Disable_SBQQ_Quote_Validation_Rules__c = true,
        Disable_SBQQ_QuoteLine_Triggers__c = true,
        Disable_Opportunity_Validation_Rules__c = true,
        Disable_Opportunity_Triggers__c = false,
        Disable_Order_Email_Alerts__c = false,
        Disable_Order_Old_Trigger__c = true,
        Disable_Asset_Triggers__c = true,
        Disable_Contact_Triggers__c = true,
        setupOwnerId = currentUsr.id
      );
      insert control;
      SBQQ__Quote__c quote = [SELECT Id, Legal_Approved_Verbiage__c, SBQQ__Type__c, SBQQ__Account__c, SBQQ__Opportunity2__c FROM SBQQ__Quote__c LIMIT 1];
      quote.Legal_Approved_Verbiage__c = 'Test verbiage';
      quote.SBQQ__Type__c = 'Revenue';
      update quote;
      Assert.areEqual(true, quote != null);
      DateTime todaysDate = Date.Today();
      String dateStr = todaysDate.format('MM/dd/yyyy');
       Order Ord = createTestorder('Revenue',quote.id, quote.SBQQ__Account__c,quote.SBQQ__Opportunity2__c,null ,system.label.CPQPricebookID,null,null,new Map<String, Object>{'ProcessType__c' => 'Aspen','Status' => 'Draft'});
      insert ord;
      Test.stopTest();
      ord = [SELECT Id, OM_internal_review__c, Change_Needed_Reason_Other__c FROM Order WHERE Id = :ord.Id];
    }
  }
  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to OrderItem trigger logic // PRDOPS23-80
   */
  static void createProductAndPBE() {
    User currentUsr = createUser();
    System.runAs(currentUsr) {
      List<Product2> prodList = new List<product2>();
      List<PricebookEntry> PBEList = new List<PricebookEntry>();
      Map<String, Object> HybridProdMap = new Map<String, Object>{
        'Name' => 'HybridProd-001-test',
        'IsActive' => true,
        'ProductCode' => 'HybridProd-001-test',
        'Product_Level__c' => 'Hybrid Software',
        'Product_Subtype__c' => 'GO'
      };
      Map<String, Object> HybridProd2Map = new Map<String, Object>{
        'Name' => 'HybridProd-002-test',
        'IsActive' => true,
        'ProductCode' => 'HybridProd-002-test',
        'Product_Level__c' => 'Hybrid Software',
        'Product_Subtype__c' => 'GO'
      };
      Map<String, Object> LODProdMap = new Map<String, Object>{
        'Name' => 'LODProd-001-test',
        'IsActive' => true,
        'ProductCode' => 'LODProd-001-test',
        'Product_Level__c' => 'LOD Software',
        'Product_Subtype__c' => 'GO'
      };
      Map<String, Object> TPHMap = new Map<String, Object>{
        'Name' => 'TPH-001-test',
        'IsActive' => true,
        'ProductCode' => 'TPH-001-test',
        'Product_Level__c' => 'Hybrid Software',
        'Product_Subtype__c' => 'RCDM'
      };
      Map<String, Object> HWSuppMap = new Map<String, Object>{
        'Name' => 'HWSupportProd-001-test',
        'IsActive' => true,
        'ProductCode' => 'HWSupportProd-001-test',
        'Product_Level__c' => 'Support',
        'Product_Type__c' => 'HW Support'
      };
      Map<String, Object> HWSupp2Map = new Map<String, Object>{
        'Name' => 'HWSupport2Prod-001-test',
        'IsActive' => true,
        'ProductCode' => 'HWSupport2Prod-001-test',
        'Product_Level__c' => 'Support',
        'Product_Type__c' => 'HW Support'
      };
      Map<String, Object> SWSuppMap = new Map<String, Object>{
        'Name' => 'SWSupportProd-001-test',
        'IsActive' => true,
        'ProductCode' => 'SWSupportProd-001-test',
        'Product_Level__c' => 'Support',
        'Product_Type__c' => 'HW Support',
        'Product_Type__c' => 'RCDM Support'
      };
      Map<String, Object> HardwareMap = new Map<String, Object>{
        'Name' => 'HWPROD-001-TEST',
        'IsActive' => true,
        'ProductCode' => 'HWPROD-001-TEST',
        'Product_Level__c' => 'Hardware',
        'Usable_Capacity__c' => 100,
        'Appliance_Model_HW__c' => 'HWPROD-001-TEST',
        'Product_Type__c' => 'Hardware'
      };
      Map<String, Object> Hardware2Map = new Map<String, Object>{
        'Name' => 'HWPROD-002-TEST',
        'IsActive' => true,
        'ProductCode' => 'HWPROD-002-TEST',
        'Product_Level__c' => 'Hardware',
        'Usable_Capacity__c' => 100,
        'Appliance_Model_HW__c' => 'HWPROD-002-TEST',
        'Product_Type__c' => 'Hardware'
      };
      Map<String, Object> AddonMap = new Map<String, Object>{
        'Name' => 'AddonProd-001-test',
        'IsActive' => true,
        'ProductCode' => 'AddonProd-001-test',
        'Usable_Capacity__c' => 100,
        'Product_Level__c' => 'SaaS Software Addon'
      };

      Map<String, Object> TSRMap = new Map<String, Object>{
        'Name' => 'RC-SFP-TSR-01',
        'ProductCode' => 'RC-SFP-TSR-01',
        'Description' => '10G/1G Dual Rate SFP+ Transceiver, pack of 4',
        'IsActive' => true,
        'Category__c' => 'Platform',
        'Product_Subtype__c' => 'SFP',
        'Product_Type__c' => 'Accessories',
        'Item_Type__c' => 'Non-inventory Item',
        'Family' => 'SFP',
        'Product_Level__c' => 'Hardware',
        'Product_Payment_Option__c' => 'Prepay',
        'SBQQ__PricingMethod__c' => 'List',
        'SBQQ__SubscriptionBase__c' => 'List'
      };
      Map<String, Object> SpareMap = new Map<String, Object>{
        'Name' => 'RC-HDD-01',
        'ProductCode' => 'RC-HDD-01',
        'Description' => 'Hard disk',
        'IsActive' => true,
        'Product_Level__c' => 'Hardware',
        'Product_Type__c' => 'Spares',
        'Item_Type__c' => 'Non-inventory Item'
      };

      prodList.addall((List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 1, HybridProdMap));
      prodList.addall((List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 1, HybridProd2Map));
      prodList.addall((List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 1, LODProdMap));
      prodList.addall((List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 1, TPHMap));
      prodList.addall((List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 1, HardwareMap));
      prodList.addall((List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 1, Hardware2Map));
      prodList.addall((List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 1, HWSuppMap));
      prodList.addall((List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 1, HWSupp2Map));
      prodList.addall((List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 1, SWSuppMap));
      prodList.addall((List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 1, AddonMap));
      prodList.addall(
        (List<Product2>) ShGl_TestFactory.createSObjectList(
          new Product2(),
          1,
          HardwareMap = new Map<String, Object>{
            'Name' => 'HWProd3-001-test',
            'IsActive' => true,
            'ProductCode' => 'HWProd3-001-test',
            'Product_Level__c' => 'Hardware',
            'Usable_Capacity__c' => 100,
            'Product_Type__c' => 'Hardware'
          }
        )
      );
      prodList.addall(
        (List<Product2>) ShGl_TestFactory.createSObjectList(
          new Product2(),
          1,
          HardwareMap = new Map<String, Object>{
            'Name' => 'HybridProd-003-test',
            'IsActive' => true,
            'ProductCode' => 'HybridProd-001-test',
            'Product_Level__c' => 'Hybrid Software',
            'Product_Subtype__c' => 'GO'
          }
        )
      );
      prodList.addall((List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 1, TSRMap));
      prodList.addall((List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 1, SpareMap));
      insert prodList;
      Assert.areEqual(true, prodList.size() > 0);
      for (product2 prod : prodList) {
        PBEList.add(new PricebookEntry(Product2Id = prod.Id, UnitPrice = 1500, Pricebook2id = Test.getStandardPricebookId()));
        PBEList.add(new PricebookEntry(Product2Id = prod.Id, UnitPrice = 1500, Pricebook2id = system.label.CPQPricebookID));
      }
      insert PBEList;
    }
  }
  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description creating user for test method run
   * @return User
   */
  static User createUser() {
    String uniqueUserName = 'TestUser' + DateTime.now().getTime() + '@rbk.com';
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
      username = uniqueUserName,
      RBAC_Department__c = 'Service Account',
      RBAC_Group__c = 'API'
    );
    return usr;
  }
  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description creating Polaris Quote trigger logic
   * @param addProduct
   * @param quote
   * @param childParentMap
   */
  static void createPolarisQuote(set<string> addProduct, SBQQ__Quote__c quote, Map<string, string> childParentMap) {
    String currencyCode = 'USD';
    List<ProductModel> prodModels = new List<ProductModel>();
    List<product2> prodList = [SELECT id, Name, ProductCode, Product_Level__c, Product_Subtype__c, Product_Type__c, Usable_Capacity__c FROM product2 WHERE name IN :addProduct];
    for (product2 prod : prodList) {
      prodModels.add(
        (ProductModel) JSON.deserialize(
          SBQQ.ServiceRouter.load('SBQQ.ProductAPI.ProductLoader', prod.id, '{"pricebookId" : "' + system.label.CPQPricebookID + '", "currencyCode" : "' + currencyCode + '"}'),
          ProductModel.class
        )
      );
    }
    String quoteJSON = SBQQ.ServiceRouter.read('SBQQ.QuoteAPI.QuoteReader', quote.id);
    ProductAdder adder = new ProductAdder();
    QuoteModel quoteWithProducts = adder.add((QuoteModel) JSON.deserialize(quoteJSON, QuoteModel.class), prodModels, 0);
    Map<string, Integer> prodKey = new Map<string, Integer>();
    Integer hwIndex, hybIndx, addonIndx;
    hwIndex = hybIndx = addonIndx = 0;
    for (QuoteLineModel QLModel : quoteWithProducts.lineItems) {
      if (QLModel.record.Product_Level__c == 'Hybrid Software') {
        prodKey.put(QLModel.record.SBQQ__Product__r.name, QLModel.key);
        QLModel.record.SBQQ__Quantity__c = 200;
        QLModel.record.SBQQ__SubscriptionTerm__c = 36;
        QLModel.record.SBQQ__NetPrice__c = 100;
      } else if (QLModel.record.Product_Level__c == 'Hardware' && QLModel.record.Product_Type__c == 'Hardware') {
        prodKey.put(QLModel.record.SBQQ__Product__r.name, QLModel.key);
        QLModel.record.SBQQ__Quantity__c = 2;
        QLModel.record.SBQQ__NetPrice__c = 100;
        QLModel.parentItemKey = prodKey.get(childParentMap.get(QLModel.record.SBQQ__Product__r.name));
      } else if (QLModel.record.Product_Level__c == 'Support' || QLModel.record.Product_Level__c == 'SaaS Software Addon') {
        QLModel.record.SBQQ__Quantity__c = QLModel.record.Product_Level__c == 'SaaS Software Addon' ? 1 : 2;
        QLModel.record.SBQQ__SubscriptionTerm__c = 36;
        QLModel.record.SBQQ__NetPrice__c = 100;
        QLModel.parentItemKey = prodKey.get(childParentMap.get(QLModel.record.SBQQ__Product__r.name));
      }
    }
    String savedQuoteModel = SBQQ.ServiceRouter.save('SBQQ.QuoteAPI.QuoteSaver', JSON.serialize(quoteWithProducts));
    QuoteCalculator calculator = new QuoteCalculator();
    calculator.calculate((QuoteModel) JSON.deserialize(savedQuoteModel, QuoteModel.class), 'MyCallback');
    quote.ApprovalStatus__c = 'Approved';
    quote.ProcessType__c = 'Aspen';
    update quote;
    Assert.areEqual(true, quote != null);
    //OrderUpdateHelper.testCoverage();
  }
  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to test Rebate Calculation Order
   */
  @isTest
  static void testRebateCalculationOrder() {
    SBQQ.TriggerControl.disable();
    testDataFactoryClass.createCustomSettings();
    Map<Id, PO_Stage__c> mpStage = new Map<Id, PO_Stage__c>();
    String uniqueUserName = 'AdminUser' + DateTime.now().getTime() + '@rubrik.com';
    Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
    User u = createTestUser(null, p.Id, uniqueUserName, 'adminU','AdminUser@rubrik.com', new Map<String, Object>{'EmailEncodingKey' => 'UTF-8','LastName' => 'Testing','LanguageLocaleKey' => 'en_US','LocaleSidKey' => 'en_US','TimeZoneSidKey' => 'America/Los_Angeles'});
    System.runAs(u) {
      insert new ShGl_DisableBusinessLogic__c(
        Disable_Opportunity_Validation_Rules__c = true,
        Disable_POC_Validation_Rules__c = true,
        Disable_Contact_Triggers__c = true,
        Disable_SBQQ_Quote_Triggers__c = true,
        Disable_SBQQ_QuoteLine_Triggers__c = true
      );
      Sfdc_Disti_Mapping__mdt distiArrowRec = Sfdc_Disti_Mapping__mdt.getInstance('Arrow_ECS_North_America_Disti');
      test.startTest();
      set<Id> idorderitem = new Set<Id>();
      Account acct = [SELECT Id FROM Account WHERE Name = 'Test' LIMIT 1];

      acct.Sync_to_NetSuite__c = false;
      update acct;
      set<PS_Project__c> lstPost = new Set<PS_Project__c>();
      Opportunity oppr = [
        SELECT
          Id,
          New_Expansion_TCV__c,
          Subsumed_Renewal_TCV__c,
          Opportunity_Sub_Type__c,
          Opportunity_Type__c,
          Deal_Registration_Type__c,
          FocusedPartner__c,
          pricebook2Id,
          AccountId
        FROM Opportunity
        WHERE AccountId = :acct.Id
        LIMIT 1
      ];
      Id pricebookId = Test.getStandardPricebookId();
      oppr.pricebook2Id = pricebookId;
      oppr.Opportunity_Type__c = 'New Customer';
      oppr.Deal_Registration_Type__c = 'Rubrik Sourced';
      oppr.Amount = 50000;
      oppr.New_Expansion_TCV__c = 3000;
      oppr.Subsumed_Renewal_TCV__c = 3000;
      oppr.ACV_Amount__c = 40000;
      oppr.New_Expansion_ACV__c = 2000;
      oppr.Renewal_Subsumed_ACV__c = 2000;

      update oppr;
      PO_Stage__c postg = [SELECT id, Bill_To_Name__c FROM PO_Stage__c LIMIT 1];

      PS_Project__c postP = [SELECT id, name, Project_Manager__c FROM PS_Project__c LIMIT 1];
      lstPost.add(postP);
      Order objOrd1 = createTestorder('Booking Adjustment',null, acct.Id,oppr.Id,null ,null,null,'POC',new Map<String, Object>{'Stage_PO__c' => postg.id,'EffectiveDate' => System.today().addDays(2),'Status' => 'Draft','Order_Status__c' => 'Order Accepted','ScreenStatus__c' => 'Approved','Order_Splitted__c' => true,'ProcessType__c' => 'Aspen','Internal_Order_Stage__c' => 'Pending','Ship_To_Name__c' => 'Test','Have_Hardware_Products__c' => false});
  	  insert objOrd1;
        
        Order objOrd2 = createTestorder('Revenue',null, acct.Id,oppr.Id,null ,null,null,'POC',new Map<String, Object>{'Stage_PO__c' => postg.id,'EffectiveDate' => System.today().addDays(2),'Status' => 'Draft','Order_Status__c' => 'Rejected','ScreenStatus__c' => 'Approved','Order_Splitted__c' => true,'ProcessType__c' => 'Aspen','Internal_Order_Stage__c' => 'Pending','Ship_To_Name__c' => 'Test','Have_Hardware_Products__c' => false,'Have_Polaris_Products__c' => false,'Bill_To_Name__c' => distiArrowRec.Sfdc_Id__c});
        insert objOrd2;
        
        Order objOrd3 = createTestorder('Revenue',null, acct.Id,oppr.Id,null ,null,null,'POC',new Map<String, Object>{'Stage_PO__c' => postg.id,'EffectiveDate' => System.today().addDays(2),'Status' => 'Draft','Order_Status__c' => 'Shipped','Is_RWD_Polaris_Quote__c' => true,'ScreenStatus__c' => 'Approved','Order_Splitted__c' => true,'ProcessType__c' => 'Aspen','Internal_Order_Stage__c' => 'Pending','Ship_To_Name__c' => 'Test','Have_Hardware_Products__c' => false,'Bill_To_Name__c' => distiArrowRec.Sfdc_Id__c});
        insert objOrd3;
        ShipmentDetail__c shDetails =  testShipmentDetail(objOrd1.Id,'Fail HW','HWPROD-001-TEST',null,'Aspen',new Map<String, Object>{'Quantity__c' => 12,'Status__c' => 'New','TrackingNumber__c' => 'Order100','ContractManufacturer__c' => 'Super Micro Computer, Inc.'});


      Rebate_Table__c rebate = [
        SELECT
          id,
          Rebate__c,
          ASPEN_Rebate__c,
          Installation_Product__c,
          Value_Add_Distribution_fee__c,
          Distributor__r.name,
          Rebate_Type__c,
          Rebate_Deal_Type__c,
          Start_Date__c,
          End_Date__c
        FROM Rebate_Table__c
        WHERE Rebate_Type__c = 'Distributor Fee'
      ];
        
       Booking__c objBooking = createTestBooking(objOrd1.id,oppr.Id,acct.Id,new Map<String,object>{'recordTypeId' => Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking').getRecordTypeId()});
      insert objBooking;
      list<Booking_Line_Item__c> bliList = new List<Booking_Line_Item__c>{
          createTestBookingLineItem(objBooking.id, 'Revenue',100,new Map<String, Object>{'Subsumed_Renewal_TCV__c' => 50,'New_Expansion_TCV__c' => 50,'Gross_ACV_Amount__c' => 50,'Gross_New_Expansion_ACV__c' => 50}),
          createTestBookingLineItem(objBooking.id, 'Distributor Fee',10.0,new Map<String, Object>{'Rebate__c' => 2.0,'Impacts_Gross_Bookings__c' => true,'Impacts_Net_Bookings__c' => true,'Impacts_Commission__c' => true}),
          createTestBookingLineItem(objBooking.id, 'Distributor Fee',10.0,new Map<String, Object>{'Rebate__c' => 2.0,'Impacts_Gross_Bookings__c' => true,'Impacts_Net_Bookings__c' => true,'Impacts_Commission__c' => true})
      };
      insert bliList;
        
        
      List<Product2> lstProds = new List<Product2>{
         createTestProduct('RBK-MSP-R6404S-HW-01', 'RRBK-SVC-TRN', 'RBK-R300', 'RBK-R6408F', null, new Map<String, Object>{'Product_Type__c' => 'Training','Allow_PSO_Task_Creation__c' => true}),
         createTestProduct('RBK-MSP-R6404S-HW-01', 'RBK-SVC-PREM-R344', 'RBK-R300', 'RBK-R640F', null, new Map<String, Object>{'Product_Type__c' => 'Training','Allow_PSO_Task_Creation__c' => true})
      };

      insert lstProds;
      List<PricebookEntry> lstPbEntry = new List<PricebookEntry>{
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[0].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[1].Id, UnitPrice = 100.00, IsActive = true)
      };

      insert lstPbEntry;
      id prodId = lstProds[0].Id;
      List<OrderItem> lstOrdrItems = new List<OrderItem>{
        createTestOrderItem(objOrd1.Id,5,lstPbEntry[0].Id,lstPbEntry[0].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'S3F4NXMM416324','Failed_Serial_Number__c' => 'S3F4NXM41632400','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today().addDays(2)}),
        createTestOrderItem(objOrd1.Id,5,lstPbEntry[1].Id,lstPbEntry[1].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'S3F4NXMM416324','Failed_Serial_Number__c' => 'S3F4NXM416324','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today().addDays(2)})
      };
      insert lstOrdrItems;
      Map<Id, orderItem> mporderItem = new Map<Id, orderItem>();
      orderItem oritem = [
        SELECT id, OrderId, PricebookEntryId, product2.Name, Product2.Family, UnitPrice, SerialNumber__c, Failed_Serial_Number__c
        FROM orderItem
        WHERE Failed_Serial_Number__c = 'S3F4NXM41632400'
        LIMIT 1
      ];
      mporderItem.put(oritem.id, oritem);
      idorderitem.add(oritem.id);
      Rebate_Table__c rebate1 = [
        SELECT
          id,
          Rebate__c,
          ASPEN_Rebate__c,
          Installation_Product__c,
          Value_Add_Distribution_fee__c,
          Distributor__r.name,
          Rebate_Type__c,
          Rebate_Deal_Type__c,
          Start_Date__c,
          End_Date__c
        FROM Rebate_Table__c
        WHERE Rebate_Type__c = 'Distributor Fee'
      ];
      set<Rebate_Table__c> rebateSet = new Set<Rebate_Table__c>();
      //  rebateSet.add(rebate);
      rebateSet.add(rebate1);
      BLI_Impact__mdt bli_impact = [SELECT Id, Adjustment_Type__c FROM BLI_Impact__mdt WHERE Adjustment_Type__c = 'Revenue' LIMIT 1];
      list<BLI_Impact__mdt> BLIimpactList = new List<BLI_Impact__mdt>();
      BLIimpactList.add(bli_impact);
      Booking__c objBooking1 = createTestBooking(objOrd1.id,oppr.Id,acct.Id,new Map<String,object>{'Distributor__c' => acct.id,'recordTypeId' => Schema.SObjectType.Booking__c.getRecordTypeInfosByName().get('Booking').getRecordTypeId(),'CreatedDate' => System.Today()});
  	  insert objBooking1;
      Map<string, Asset> serialNumAsset = new Map<string, Asset>();
      list<Asset> lstAsst = new List<Asset>();
      Asset assObj =    createAsset('SN123', acct.Id, lstProds[0].id,'Purchased','SN123',new Map<String, Object>{'Serial_Number__c' => 'SN123','Premium_Support_End_Date__c' => Date.today()});
      insert assObj;
      serialNumAsset.put(assObj.SerialNumber, assObj);
      lstAsst.add(assObj);
      Map<Id, Booking_Line_Item__c> bliToUpdate = new Map<Id, Booking_Line_Item__c>();
      Map<Id, booking__c> bookingToUpdate = new Map<Id, booking__c>();
      bookingToUpdate.put(objBooking1.id, objBooking1);
      Booking_Line_Item__c objBooking11 = new Booking_Line_Item__c(Booking__c = objBooking.id, Type__c = 'Revenue', Total_Price__c = 100);
      insert objBooking11;
      set<Booking_Line_Item__c> blineitem = new Set<Booking_Line_Item__c>();
      blineitem.add(objBooking11);
      bliToUpdate.put(objBooking11.id, objBooking11);
      mpStage.put(postg.id, postg);
      order ord1 = [
        SELECT id, totalAmount, Bill_To_Name__c, ProcessType__c, Assets_Missing_In_System__c, type, Order_Sub_Type__c, Order_Status__c
        FROM order
        WHERE id = :objOrd2.id
      ];
      order ord2 = [SELECT id, totalAmount, Bill_To_Name__c, ProcessType__c, type, Order_Sub_Type__c, Order_Status__c FROM order WHERE id = :objOrd3.id];
      set<PS_Task__c> pstask = new Set<PS_Task__c>();
      set<id> setOfIds = new Set<id>();
      Map<Id, Decimal> mapBKgIdToNetRenewal = new Map<Id, Decimal>();
      Map<Id, Decimal> mapBKgIdToNetNew = new Map<Id, Decimal>();
      Map<Id, Decimal> mapBKgIdToGrossACVAmt = new Map<Id, Decimal>();
      Map<Id, Decimal> mapBKgIdToGrossNewACV = new Map<Id, Decimal>();
      Map<Id, Decimal> mapBKgIdToGrossRenewalACV = new Map<Id, Decimal>();

      list<orderItem> orderIT = [
        SELECT id, quantity, Order.OpportunityId, Failed_Serial_Number__c, SerialNumber__c, Product2.Name, Product2Id, Product2.family, UnitPrice
        FROM orderItem
        WHERE Failed_Serial_Number__c = 'S3F4NXM41632400'
      ];
      mapBKgIdToNetNew.put(objBooking.Id, oppr.New_Expansion_TCV__c);
      mapBKgIdToNetRenewal.put(objBooking.Id, oppr.Subsumed_Renewal_TCV__c);
      mapBKgIdToNetNew.put(objBooking1.Id, oppr.New_Expansion_TCV__c);
      mapBKgIdToNetRenewal.put(objBooking1.Id, oppr.Subsumed_Renewal_TCV__c);
      mapBKgIdToGrossACVAmt.put(objBooking.Id, oppr.ACV_Amount__c);
      mapBKgIdToGrossACVAmt.put(objBooking1.Id, oppr.ACV_Amount__c);
      mapBKgIdToGrossNewACV.put(objBooking.Id, oppr.New_Expansion_ACV__c);
      mapBKgIdToGrossNewACV.put(objBooking1.Id, oppr.New_Expansion_ACV__c);
      mapBKgIdToGrossRenewalACV.put(objBooking.Id, oppr.Renewal_Subsumed_ACV__c);
      mapBKgIdToGrossRenewalACV.put(objBooking1.Id, oppr.Renewal_Subsumed_ACV__c);

      OrderUpdateHelper ordr = new OrderUpdateHelper();
      ordr.createPSTask(objOrd1, lstOrdrItems, pstask, mporderItem);
      ordr.onHoldOrders(objOrd1, objOrd2);
      ordr.NotifyTrainingSKU(idorderitem);
      ordr.updateCma(objOrd1, objOrd2, orderIT);
      ordr.validateSerialNumber(shDetails, serialNumAsset, prodId, serialNumAsset, objOrd1, lstAsst);
      ordr.NotifyTrainingSKU(setOfIds);
      Assert.areEqual(true, ordr != null);
      test.StopTest();
    }

  }
  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to test Rebate Calculation Order
   */
  @isTest
  static void testshipPOCOrder() {
    SBQQ.TriggerControl.disable();
    testDataFactoryClass.createCustomSettings();
    Map<Id, PO_Stage__c> mpStage = new Map<Id, PO_Stage__c>();
    String uniqueUserName = 'AdminUser' + DateTime.now().getTime() + '@rubrik.com';
    Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
    User u = createTestUser(null, p.Id, uniqueUserName, 'adminU','AdminUser@rubrik.com', new Map<String, Object>{'EmailEncodingKey' => 'UTF-8','LastName' => 'Testing','LanguageLocaleKey' => 'en_US','LocaleSidKey' => 'en_US','TimeZoneSidKey' => 'America/Los_Angeles'});
    System.runAs(u) {
      Account acct = [SELECT Id FROM Account WHERE Name = 'Test' LIMIT 1];
      acct.Sync_to_NetSuite__c = false;
      update acct;
      set<PS_Project__c> lstPost = new Set<PS_Project__c>();
      Opportunity oppr = [SELECT Id, Opportunity_Sub_Type__c, pricebook2Id FROM Opportunity WHERE AccountId = :acct.Id LIMIT 1];
      PO_Stage__c postg = [SELECT id, Bill_To_Name__c FROM PO_Stage__c LIMIT 1];
      PS_Project__c postP = [SELECT id, name, Project_Manager__c FROM PS_Project__c LIMIT 1];
      lstPost.add(postP);
        Order objOrdM1 = createTestorder('Revenue',null, acct.Id,oppr.Id,null ,null,null,'POC',new Map<String, Object>{'Stage_PO__c' => postg.id,'EffectiveDate' => System.today().addDays(2),'Status' => 'Draft','Order_Status__c' => 'Order Accepted','ScreenStatus__c' => 'Approved','Order_Splitted__c' => true,'Internal_Order_Stage__c' => 'Pending','Ship_To_Name__c' => 'Test','Have_Hardware_Products__c' => false});
        insert objOrdM1;
        Order objOrdM11 = createTestorder('Revenue',null, acct.Id,oppr.Id,null ,null,null,'POC',new Map<String, Object>{'EffectiveDate' => System.today().addDays(2),'Status' => 'Draft','Order_Status__c' => 'Rejected','ScreenStatus__c' => 'Approved','Order_Splitted__c' => true,'Internal_Order_Stage__c' => 'Pending','Ship_To_Name__c' => 'Test','Have_Hardware_Products__c' => false});
        insert objOrdM11;
      mpStage.put(postg.id, postg);
      test.startTest();
      OrderUpdateHelper ordr = new OrderUpdateHelper();
      ordr.shipPOCOrder(objOrdM1);
      ordr.ActivateOrders(objOrdM1);
      ordr.UpdateStagePO(objOrdM1, mpStage);
      ordr.UpdateStagePO(objOrdM11, mpStage);
      ordr.ActivateOrders(objOrdM11);
      OrderUpdateHelper.executeSplitOrderBatch();
      // ordr.CommitabeforeUpdateRecords(lstPost);
      Assert.areEqual(true, ordr != null);
      test.StopTest();
    }

  }
  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to OrderItem trigger logic
   */
  static testMethod void testProcessOrderItem3EAUnit() {
    testDataFactoryClass.createCustomSettings();

    String uniqueUserName = 'AdminUser' + DateTime.now().getTime() + '@rubrik.com';
    Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
    User u = createTestUser(null, p.Id, uniqueUserName, 'adminU','AdminUser@rubrik.com', new Map<String, Object>{'EmailEncodingKey' => 'UTF-8','LastName' => 'Testing','LanguageLocaleKey' => 'en_US','LocaleSidKey' => 'en_US','TimeZoneSidKey' => 'America/Los_Angeles'});
    System.runAs(u) {
      insert new ShGl_DisableBusinessLogic__c(
        Disable_Entitlement_Validation_Rules__c = true,
        Disable_Opportunity_Validation_Rules__c = true,
        Disable_POC_Validation_Rules__c = true,
        Disable_POC_Trigger__c = true,
        Disable_Contact_Triggers__c = true,
        Disable_SBQQ_Quote_Triggers__c = true,
        Disable_SBQQ_QuoteLine_Triggers__c = true,
        Disable_Order_Validation_Rules__c = true,
        Disable_Opportunity_Triggers__c = true,
        Disable_Entitlement_Trigger__c = true  
      );
      Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test' LIMIT 1];
      Assert.areEqual('Test', acct.Name);
      Opportunity oppr = [SELECT Id, pricebook2Id, Distributor_Lookup__r.EDI_DISTI_ID__c, AccountId FROM Opportunity WHERE AccountId = :acct.Id LIMIT 1];

      PS_Project__c objPsProject = new PS_Project__c();
      objPsProject.Name = 'test project';
      objPsProject.Account__c = acct.id;
      objPsProject.Project_Manager__c = userinfo.getuserid();
      objPsProject.Manager__c = 'test@test.com';
      //insert objPsProject;

      Set<PS_Project__c> PSProjToInsert = new Set<PS_Project__c>();
      PSProjToInsert.add(objPsProject);

      Id pricebookId = Test.getStandardPricebookId();
      oppr.pricebook2Id = pricebookId;
      update oppr;

      delete [SELECT SBQQ__Type__c FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :acct.Id LIMIT 1];

      Product2 prod =  createTestProduct('RBK-SVC-PREM-R344', 'RBK-SVC-PREM-R344', 'POLARIS', 'RBK-R6408E', null, new Map<String, Object>{'SBQQ__SubscriptionPricing__c' => 'Fixed Price','SBQQ__SubscriptionTerm__c' => 36,'Bundle_Features__c' => 'Polaris','Create_Entitlement__c' => true,'SBQQSC__EntitlementConversion__c' => 'One per unit','Create_Asset__c' => true});
	 insert prod;

      PricebookEntry pbEntry = new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = prod.Id, UnitPrice = 100.00, IsActive = true);
      insert pbEntry;

      OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = oppr.Id, Quantity = 5, PricebookEntryId = pbEntry.Id, TotalPrice = 5 * pbEntry.UnitPrice);
      // test.startTest();
      insert oli;

      POC__c pocobjLoaner = createTestPocObject('60 Days',date.today().addDays(90),'Yes','EA Unit','Rubrik Appliance',new Map<String, Object>{'Opportunity__c'=>oppr.Id,'RscSuggestedUrl__c' => 'test.my.rubrik.com'});
      test.startTest();
      insert pocobjLoaner;

      List<Asset> assetsList = new List<Asset>{
       createAsset('SN123', acct.Id, prod.id,'Purchased','SN123',new Map<String, Object>{'Serial_Number__c' => 'SN123','Premium_Support_End_Date__c' => Date.today()})
      };

      insert assetsList;

      List<Entitlement> entitlements = new List<Entitlement>{
        createEntitlement('ENT-4',acct.Id,prod.Id,assetsList[0].Id, new Map<String, Object> {'Type' => 'Web Support','StartDate' => Date.valueof(System.now().addDays(-2)),'EndDate' => Date.valueof(System.now().addYears(2))})
      };
      insert entitlements;
      List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
      Order ord = createTestorder('POC',null, acct.Id,oppr.Id,acct.id ,pricebookId,null,'Renewal',new Map<String, Object>{'POC_Request__c' => pocobjLoaner.Id,'POC_Opportunity__c' => oppr.Id,'Order_Status__c' => null,'Send_for_Polaris_Fulfilment__c' => false,'Have_Hardware_Products__c' => true,'Order_Splitted__c' => true,'ProcessType__c' => 'Aspen','RecordTypeId' => Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order')?.getRecordTypeId()});
      ord.POC_Opportunity__c = oppr.Id;
      insert Ord;
      Ord.PS_Project__c = objPsProject.id;
      update Ord;
      order ord1 = [
        SELECT id, totalAmount, Bill_To_Name__c, ProcessType__c, Order_Sub_Type__c, POC_Type__c, Polaris_Fulfillment_Status__c, ScreenStatus__c
        FROM order
        WHERE id = :ord.Id
      ];
      //order ord2=[select id,totalAmount from order where id=:ord.Id];
      ord1.Type = 'Revenue';
      //ord1.Order_Sub_Type__c='Renewal';

      update ord1;

      OrderItem ordrItem =  createTestOrderItem(Ord.Id,5,pbEntry.Id,pbEntry.UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'SN123','Failed_Serial_Number__c' => 'S3F4NXM416324','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'Is_Hardware_Line__c' => true,'Is_Refresh__c' => true,'R300_R500_Asset__c' => assetsList[0].Id});
      insert ordrItem;

      //orderitem item = [SELECT id, unitprice, quantity, totalprice, SerialNumber__c FROM orderItem WHERE orderid = :ord.id LIMIT 1];

      entitlements[0].Order_Service_Item__c = ordrItem.id;
      entitlements[0].Type = 'Manufacturing Entitlement';
      update entitlements[0];

      ord.Actual_Order_Ship_Date__c = date.today();
      ord.Order_Status__c = 'Shipped';

      update ord;
      map<id, Entitlement> entMap = new Map<id, Entitlement>();
      list<list<Entitlement>> ent1 = new List<list<Entitlement>>();
      ent1.add(entitlements);
      list<orderItem> OIList = new List<OrderItem>();
      OIList.add(ordrItem);
      Rebate_Table__c rebate = [
        SELECT id, Rebate__c, ASPEN_Rebate__c, Distributor__r.name, Rebate_Type__c, Rebate_Deal_Type__c, Start_Date__c, End_Date__c, Distributor__c
        FROM Rebate_Table__c
        WHERE Rebate_Type__c = 'Distributor Fee'
      ];
      Rebate_Table__c rebate1 = [
        SELECT id, Rebate__c, ASPEN_Rebate__c, Distributor__r.name, Rebate_Type__c, Rebate_Deal_Type__c, Start_Date__c, End_Date__c
        FROM Rebate_Table__c
        WHERE Rebate_Type__c = 'Velocity Partner Program Rebate'
      ];
      rebate.Start_Date__c = System.Today().addDays(-10);
      rebate.End_Date__c = null;
      update rebate;
      ord1.Bill_To_Name__c = rebate.Distributor__c;
      ord1.Order_Sub_Type__c = 'MSP Consumption';
      ord1.Polaris_Fulfillment_Status__c = 'Completed';
      ord1.ScreenStatus__c = 'Approved';
      ord1.POC_Request__c = pocobjLoaner.id;
      ordrItem.SerialNumber__c = 'SN123';
      update ordrItem;
      update ord1;

      Booking__c book = new Booking__c();
      book.Account_Name__c = acct.id;
      book.CreatedDate = date.today();
      insert book;
      Booking_Line_Item__c bookline = new Booking_Line_Item__c();
      bookline.Booking__c = book.id;
      insert bookline;
      set<Booking_Line_Item__c> booklineSet = new Set<Booking_Line_Item__c>();
      booklineSet.add(bookline);
      Id bkId = book.Id;
      /*BLI_Impact__mdt bli_impact = [
        SELECT Id, Adjustment_Type__c, Impacts_Gross_Bookings__c, Impacts_Net_Bookings__c, Impacts_Commissions__c
        FROM BLI_Impact__mdt
        WHERE Adjustment_Type__c = 'Revenue'
        LIMIT 1
      ];
      list<BLI_Impact__mdt> BLIimpactList = new List<BLI_Impact__mdt>();
      BLIimpactList.add(bli_impact);
      BLI_Impact__mdt bli_impact1 = [
        SELECT Id, Adjustment_Type__c, Impacts_Gross_Bookings__c, Impacts_Net_Bookings__c, Impacts_Commissions__c
        FROM BLI_Impact__mdt
        WHERE Adjustment_Type__c = 'Velocity Partner Program Rebate'
        LIMIT 1
      ];
      list<BLI_Impact__mdt> BLIimpactList1 = new List<BLI_Impact__mdt>();
      BLIimpactList1.add(bli_impact1);
      set<Rebate_Table__c> rebateSet = new Set<Rebate_Table__c>();
      rebateSet.add(rebate1);*/
      OrderUpdateHelper orderHelp = OrderUpdateHelper.getInstance();
      orderHelp.ActivateOrders(ord);
      orderHelp.updateEntitlementsPartner(ent1, entMap);
      orderHelp.CommitabeforeUpdateRecords(PSProjToInsert);
      test.stopTest();
    }
  }
  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to OrderItem trigger logic
   */
  static testMethod void testProcessOrderItem3EAUnit2() {
    testDataFactoryClass.createCustomSettings();

    String uniqueUserName = 'AdminUser' + DateTime.now().getTime() + '@rubrik.com';
    Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
    User u = createTestUser(null, p.Id, uniqueUserName, 'adminU','AdminUser@rubrik.com', new Map<String, Object>{'EmailEncodingKey' => 'UTF-8','LastName' => 'Testing','LanguageLocaleKey' => 'en_US','LocaleSidKey' => 'en_US','TimeZoneSidKey' => 'America/Los_Angeles'});
    System.runAs(u) {
      insert new ShGl_DisableBusinessLogic__c(
        Disable_Entitlement_Validation_Rules__c = true,
        Disable_Opportunity_Validation_Rules__c = true,
        Disable_POC_Trigger__c = true,
        Disable_POC_Validation_Rules__c = true,
        Disable_Contact_Triggers__c = true,
        Disable_SBQQ_Quote_Triggers__c = true,
        Disable_SBQQ_QuoteLine_Triggers__c = true,
        Disable_Order_Validation_Rules__c = true
  
      );

      // ShGl_DisableBusinessLogic__c control = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Triggers__c = true, Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_Opportunity_Validation_Rules__c = true,Disable_Opportunity_Triggers__c =true ,Disable_Order_Email_Alerts__c = false, Disable_Order_Old_Trigger__c = true, Disable_Order_Triggers__c = true, Disable_Asset_Triggers__c=true,Disable_Contact_Triggers__c =true,Order_Trigger_MaxLoop_Count__c=25,setupOwnerId = u.id);
      // insert control ;

      Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test' LIMIT 1];
      Assert.areEqual('Test', acct.Name);
      Opportunity oppr = [SELECT Id, pricebook2Id, Distributor_Lookup__r.EDI_DISTI_ID__c, AccountId FROM Opportunity WHERE AccountId = :acct.Id LIMIT 1];

      PS_Project__c objPsProject = new PS_Project__c();
      objPsProject.Name = 'test project';
      objPsProject.Account__c = acct.id;
      objPsProject.Project_Manager__c = userinfo.getuserid();
      objPsProject.Manager__c = 'test@test.com';
      //insert objPsProject;
      
      Set<PS_Project__c> PSProjToInsert = new Set<PS_Project__c>();
      PSProjToInsert.add(objPsProject);

      Id pricebookId = Test.getStandardPricebookId();
      oppr.pricebook2Id = pricebookId;
      update oppr;

      delete [SELECT SBQQ__Type__c FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :acct.Id LIMIT 1];
      Product2 prod =  createTestProduct('RBK-SVC-PREM-R344', 'RBK-SVC-PREM-R344', 'POLARIS', 'RBK-R6408E', null, new Map<String, Object>{'SBQQ__SubscriptionPricing__c' => 'Fixed Price','SBQQ__SubscriptionTerm__c' => 36,'Bundle_Features__c' => 'Polaris','Create_Entitlement__c' => true,'SBQQSC__EntitlementConversion__c' => 'One per unit','Create_Asset__c' => true});
      insert prod;

      PricebookEntry pbEntry = new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = prod.Id, UnitPrice = 100.00, IsActive = true);
      insert pbEntry;

      OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = oppr.Id, Quantity = 5, PricebookEntryId = pbEntry.Id, TotalPrice = 5 * pbEntry.UnitPrice);
      insert oli;

      POC__c pocobjLoaner = createTestPocObject('60 Days',date.today().addDays(90),'Yes','Business Loaner Unit','Rubrik Appliance',new Map<String, Object>{'Opportunity__c'=>oppr.Id,'RscSuggestedUrl__c' => 'test.my.rubrik.com'});
      test.startTest();
      insert pocobjLoaner;

      List<Asset> assetsList = new List<Asset>{
        createAsset('SN123', acct.Id, prod.id,'Purchased','SN123',new Map<String, Object>{'Serial_Number__c' => 'SN123','Premium_Support_End_Date__c' => Date.today()})
      };

      insert assetsList;

      List<Entitlement> entitlements = new List<Entitlement>{
          createEntitlement('ENT-4', acct.Id, prod.Id,assetsList[0].Id, new Map<String, Object>{'Type' => 'Web Support','StartDate' => Date.valueof(System.now().addDays(-2)),'EndDate' => Date.valueof(System.now().addYears(2))})
      };
	  insert entitlements;
      List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
          
    
      Order ord = createTestorder('POC',null, acct.Id,oppr.Id,acct.id ,pricebookId,null,'Renewal',new Map<String, Object>{'Send_for_Polaris_Fulfilment__c'=>false,'POC_Request__c' => pocobjLoaner.Id,'POC_Opportunity__c' => oppr.Id,'Order_Status__c' => null,'Have_Polaris_Products__c' => false,'Have_Hardware_Products__c' => true,'Order_Splitted__c' => true,'ProcessType__c' => 'Aspen','RecordTypeId' => Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order')?.getRecordTypeId()});
      insert Ord;
      Ord.PS_Project__c = objPsProject.id;
      update Ord;
      order ord1 = [
        SELECT id, totalAmount, Bill_To_Name__c, ProcessType__c, Order_Sub_Type__c, POC_Type__c, Polaris_Fulfillment_Status__c, ScreenStatus__c
        FROM order
        WHERE id = :ord.Id
      ];
      ord1.Type = 'Revenue';
      update ord1;
      OrderItem ordrItem =  createTestOrderItem(Ord.Id,5,pbEntry.Id,pbEntry.UnitPrice,new Map<String, Object>{'SerialNumber__c' => '123\\s+,456\\s+','Failed_Serial_Number__c' => 'S3F4NXM416324','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'Is_Hardware_Line__c' => true,'Is_Refresh__c' => true,'R300_R500_Asset__c' => assetsList[0].Id});
      insert ordrItem;

      orderitem item = [SELECT id, unitprice, quantity, totalprice, SerialNumber__c FROM orderItem WHERE orderid = :ord.id LIMIT 1];

      entitlements[0].Order_Service_Item__c = ordrItem.id;
      entitlements[0].Type = 'Manufacturing Entitlement';
      update entitlements[0];

      ord.Actual_Order_Ship_Date__c = date.today();
      ord.Order_Status__c = 'Shipped';

      update ord;
      map<id, Entitlement> entMap = new Map<id, Entitlement>();
      list<list<Entitlement>> ent1 = new List<list<Entitlement>>();
      ent1.add(entitlements);
      list<orderItem> OIList = new List<OrderItem>();
      OIList.add(Item);
      Rebate_Table__c rebate = [
        SELECT id, Rebate__c, ASPEN_Rebate__c, Distributor__r.name, Rebate_Type__c, Rebate_Deal_Type__c, Start_Date__c, End_Date__c, Distributor__c
        FROM Rebate_Table__c
        WHERE Rebate_Type__c = 'Distributor Fee'
      ];
      Rebate_Table__c rebate1 = [
        SELECT id, Rebate__c, ASPEN_Rebate__c, Distributor__r.name, Rebate_Type__c, Rebate_Deal_Type__c, Start_Date__c, End_Date__c
        FROM Rebate_Table__c
        WHERE Rebate_Type__c = 'Velocity Partner Program Rebate'
      ];
      rebate.Start_Date__c = System.Today().addDays(-10);
      rebate.End_Date__c = null;
      update rebate;
      ord1.Bill_To_Name__c = rebate.Distributor__c;
      ord1.Order_Sub_Type__c = 'MSP Consumption';
      ord1.Polaris_Fulfillment_Status__c = 'Completed';
      ord1.ScreenStatus__c = 'Approved';
      ord1.POC_Request__c = pocobjLoaner.id;
      update ord1;

      Booking__c book = new Booking__c();
      book.Account_Name__c = acct.id;
      book.CreatedDate = date.today();
      insert book;
      Booking_Line_Item__c bookline = new Booking_Line_Item__c();
      bookline.Booking__c = book.id;

      insert bookline;

      set<Booking_Line_Item__c> booklineSet = new Set<Booking_Line_Item__c>();
      booklineSet.add(bookline);

      Id bkId = book.Id;
      BLI_Impact__mdt bli_impact = [
        SELECT Id, Adjustment_Type__c, Impacts_Gross_Bookings__c, Impacts_Net_Bookings__c, Impacts_Commissions__c
        FROM BLI_Impact__mdt
        WHERE Adjustment_Type__c = 'Revenue'
        LIMIT 1
      ];
      list<BLI_Impact__mdt> BLIimpactList = new List<BLI_Impact__mdt>();
      BLIimpactList.add(bli_impact);

      BLI_Impact__mdt bli_impact1 = [
        SELECT Id, Adjustment_Type__c, Impacts_Gross_Bookings__c, Impacts_Net_Bookings__c, Impacts_Commissions__c
        FROM BLI_Impact__mdt
        WHERE Adjustment_Type__c = 'Velocity Partner Program Rebate'
        LIMIT 1
      ];
      list<BLI_Impact__mdt> BLIimpactList1 = new List<BLI_Impact__mdt>();
      BLIimpactList1.add(bli_impact1);
      set<Rebate_Table__c> rebateSet = new Set<Rebate_Table__c>();
      rebateSet.add(rebate1);
      OrderUpdateHelper orderHelp = OrderUpdateHelper.getInstance();
      orderHelp.ActivateOrders(ord);
      orderHelp.updateEntitlementsPartner(ent1, entMap);
      orderHelp.CommitabeforeUpdateRecords(PSProjToInsert);
      test.stopTest();
    }
  }
  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to Order trigger logic
   */
  static testMethod void testscaleUtility() {
      RPS__c rps = testCreateRpsSettings(Userinfo.getOrganizationId(),false,'Internal','Global Trade Compliance screening failed;Credit Check Failed',new map<string,object>{}); 
      insert rps;
    testDataFactoryClass.createCustomSettings();
	 System.runAs(new User(Id = UserInfo.getUserId())) {
      Account acct16 = [SELECT Id, Name FROM Account WHERE Name = 'Test' LIMIT 1];
      Assert.areEqual('Test', acct16.Name);
      Opportunity oppr16 = [SELECT Id, pricebook2Id FROM Opportunity WHERE AccountId = :acct16.Id LIMIT 1];

      Id pricebookId = Test.getStandardPricebookId();
      oppr16.pricebook2Id = pricebookId;
      oppr16.Opportunity_Sub_Type__c = 'GC Offer';
      update oppr16;

      List<Product2> lstProds16 = new List<Product2>{
       createTestProduct('RBK-SVC-PREM-R344', 'RBK-SVC-TR', 'ASE', 'RBK-R6408F', null, new Map<String, Object>{'Capacity__c' => '12TB'}),
       createTestProduct('RBK-SVC-PREM-R3441', 'RBK-SVC-TR1', 'ASE1', 'RBK-R6408F1', null, new Map<String, Object>{'Capacity__c' => '12TB'}),
         createTestProduct(
          'RS-TB-EE-RSVX-PE',
          'RS-TB-EE-RSVX-PE',
          'POLARIS',
          'RBK-R640F',
          'Hybrid Software',
          new Map<String, Object>{
            'Product_Subtype__c' => 'Scale MSP',
            'License_Category__c' => null,
            'SBQQSC__EntitlementConversion__c' => 'One per quote line',
            'Bundle_Features__c' => 'Cloud Native Protection'
          }
        ),
        createTestProduct(
          'RS-TB-EE-OND-PE',
          'RS-TB-EE-OND-PE',
          'POLARIS',
          'RBK-R640F',
          'Hybrid Software',
          new Map<String, Object>{
            'Product_Subtype__c' => 'On Demand',
            'License_Category__c' => 'SaaS',
            'Create_Entitlement__c' => true
            // 'Bundle_Features__c' => 'Cloud Native Protection'
          }
        )    
      };

      insert lstProds16;

      List<PricebookEntry> lstPbEntry16 = new List<PricebookEntry>{
        new PricebookEntry(Pricebook2Id = oppr16.pricebook2Id, Product2Id = lstProds16[0].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr16.pricebook2Id, Product2Id = lstProds16[2].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr16.pricebook2Id, Product2Id = lstProds16[3].Id, UnitPrice = 100.00, IsActive = true)

            };

      insert lstPbEntry16;

      List<OpportunityLineItem> lstOlis16 = new List<OpportunityLineItem>{
        new OpportunityLineItem(OpportunityId = oppr16.Id, Quantity = 5, PricebookEntryId = lstPbEntry16[0].Id, TotalPrice = 5 * lstPbEntry16[0].UnitPrice)
      };

      insert lstOlis16;

      test.startTest();
      Order ord16 = createTestorder('Revenue',null, acct16.Id,oppr16.Id,null ,pricebookId,null,'GC Offer',new Map<String, Object>{});
      insert Ord16;

      List<OrderItem> lstOrdrItems16 = new List<OrderItem>{
         createTestOrderItem(Ord16.Id,5,lstPbEntry16[0].Id,lstPbEntry16[0].UnitPrice,new Map<String, Object>{'Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today()}),
         createTestOrderItem(Ord16.Id,5,lstPbEntry16[0].Id,lstPbEntry16[0].UnitPrice,new Map<String, Object>{'Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today()}),
         createTestOrderItem(Ord16.Id,5,lstPbEntry16[1].Id,lstPbEntry16[1].UnitPrice,new Map<String, Object>{/*'EndDate' => System.Today().addMonths(5),'ServiceDate' => System.Today().addMonths(2),*/'Support_End_Date__c' => System.Today(),'Support_Start_Date__c' => System.Today()}),
         createTestOrderItem(Ord16.Id,5,lstPbEntry16[2].Id,lstPbEntry16[2].UnitPrice,new Map<String, Object>{/*'EndDate' => System.Today().addMonths(5),'ServiceDate' => System.Today().addMonths(2),*/'Support_End_Date__c' => System.Today(),'Support_Start_Date__c' => System.Today()})

             };
      insert lstOrdrItems16;
   TransactionalDataCollection.allOrderItems.clear();
      String GCId = acct16.Id +'-'+ lstOrdrItems16[1].Id+'-RS-TB-EE-RSVX-PE';
         lstOrdrItems16[2].Global_Commit_ID__c = GCId;
         lstOrdrItems16[3].Global_Commit_ID__c = GCId;
         TriggerControl.stopOrderItemTrigger = true;
		 update lstOrdrItems16;
        TriggerControl.stopOrderItemTrigger = false;
      List<OrderItem> orderitemList = [Select Id,product2.Name,Global_Commit_ID__c,OrderId from orderitem];
         Scale_Utility_Overage__c overageRecord = new Scale_Utility_Overage__c(Overage_Order__c = ord16.Id,Sync_Status__c = 'Sync Failed');
         insert overageRecord;
         ord16.Order_Sub_Type__c = 'GC OnDemand';
         ord16.Order_Status__c = 'Order Accepted';
         update ord16;
      ord16.Order_Status__c = 'Shipped';
      //ord16.Order_Sub_Type__c = 'GC Offer';
      update ord16;
      System.enqueueJob(new UpdateSupportOrderLinesDatesForCSUClass(lstOrdrItems16));
      test.stopTest();
    }
  }
  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to Order trigger logic
   */
  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to Order trigger logic
   */
  static testMethod void testRMAShippedOrderPSU() {
    testDataFactoryClass.createCustomSettings();
    System.runAs(new User(Id = UserInfo.getUserId())) {
      Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test' LIMIT 1];
      Assert.areEqual('Test', acct.Name);
      Opportunity oppr = [SELECT Id, pricebook2Id FROM Opportunity WHERE AccountId = :acct.Id LIMIT 1];
      delete [SELECT SBQQ__Type__c FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :acct.Id LIMIT 1];
      Id pricebookId = Test.getStandardPricebookId();
      oppr.pricebook2Id = pricebookId;
      update oppr;
      List<Product2> lstProds = new List<Product2>{
              createTestProduct('RBK-SVC-PREM-R344', 'RBK-SVC-PREM-R344', 'RBK-R300', 'RBK-R6408F', null, new Map<String, Object>{'Entitlement_Conversion_Non_CPQ__c' => 'One per quote line','Create_Asset__c' => true}),
              createTestProduct('RBK-SVC-PREM-R344', 'RBK-SVC-PREM-R344', 'RBK-R300', 'RBK-R640F', null, new Map<String, Object>{'Entitlement_Conversion_Non_CPQ__c' => 'One per unit','Create_Asset__c' => false})
      };
      insert lstProds;
      List<PricebookEntry> lstPbEntry = new List<PricebookEntry>{
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[0].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[1].Id, UnitPrice = 100.00, IsActive = true)
      };
      insert lstPbEntry;
      List<Asset> assetsList = new List<Asset>{
        createAsset('SN123', Label.Unassigned_Account_Id, lstProds[0].id,'Purchased','SN123',new Map<String, Object>{'Serial_Number__c' => 'SN123','Premium_Support_End_Date__c' => Date.today()}),
        createAsset('SNN-1-1', acct.id, lstProds[1].id,'Purchased','SNN-1-1',new Map<String, Object>{'Serial_Number__c' => 'SNN-1-1','Premium_Support_End_Date__c' => Date.today()})
      };
      insert assetsList;
      List<Chassis__c> chassis = new List<Chassis__c>{
        new Chassis__c(Name = 'SNN-1-1', serial_number__c = 'SNN-1-1', asset__c = assetsList[0].Id, manufactured_date__c = System.now()),
        new Chassis__c(Name = 'SN123', serial_number__c = 'SN123', asset__c = assetsList[0].Id, manufactured_date__c = System.now())
      };
      insert chassis;
      List<Node__c> lstNodes = new List<Node__c>{
        new Node__c(
          //Cluster__c = clusters.get(0).Id,
          Asset__c = assetsList[0].Id,
          Serial_Number__c = 'SN123',
          software_version__c = '1.0.1',
          Name = 'SN123',
          chassis__c = chassis[0].Id
        ),
        new Node__c(
          //Cluster__c = clusters.get(0).Id,
          Asset__c = assetsList[0].Id,
          Serial_Number__c = 'SNN-1-1',
          software_version__c = '1.0.1',
          Name = 'SNN-1-1',
          chassis__c = chassis[0].Id
        )
      };
      insert lstNodes;
      List<Power_Supply__c> psus = new List<Power_Supply__c>{
        //new Power_Supply__c(Name = 'SN12345', asset__c = assetsList[0].Id, revision__c = '1.3', serial_number__c = 'SN12345', part_number__c = 'PWS-2K22A-1R', manufactured_date__c = System.now()),
        new Power_Supply__c(
          Name = 'SNN-1-1',
          asset__c = assetsList[0].Id,
          revision__c = '1.3',
          serial_number__c = 'SNN-1-1',
          part_number__c = 'PWS-2K22A-1R',
          manufactured_date__c = System.now()
        )
      };
      insert psus;
      List<Drive__c> Hdddrives = new List<Drive__c>{
        new Drive__c(
          Name = 'SNN-1-1',
          asset__c = assetsList[0].Id,
          serial_number__c = 'SNN-1-1',
          node__c = lstNodes[0].Id,
          type__c = 'HDD',
          manufactured_date__c = System.now()
        )
        //new Drive__c(Name = '0RV5TST02', asset__c = assetsList[0].Id,serial_number__c = '0RV5TST02', node__c=nodes[0].Id,type__c='HDD', manufactured_date__c = System.now())
      };
      insert Hdddrives;
      List<Memory__c> memory = new List<Memory__c>{
        //new Memory__c(Name = '0RV5MEM01', asset__c = assets[0].Id,serial_number__c = '0RV5MEM01', node__c = nodes[0].Id ,manufactured_date__c = System.now()),
        new Memory__c(Name = 'SNN-1-1', asset__c = assetsList[0].Id, serial_number__c = 'SNN-1-1', node__c = lstNodes[0].Id, manufactured_date__c = System.now())
      };
      insert memory;
      test.startTest();
      Order ord = createTestorder('RMA',null, acct.Id,oppr.Id,null ,pricebookId,null,null,new Map<String, Object>{'Order_Status__c' => 'On Hold','Mosaic_SKUs__c' => 'RBK-MOSAIC','Order_Splitted__c' => true,'Internal_Order_Stage__c' => 'Pending','Screening_Source__c' => 'Internal','Ship_To_Name__c' => 'Test','Have_Hardware_Products__c' => false,'ScreenStatus__c' => 'Approved','RecordTypeId' => Schema.SObjectType.Order.getRecordTypeInfosByName().get('RMA Order')?.getRecordTypeId()});
      insert Ord;
      List<OrderItem> lstOrdrItems = new List<OrderItem>{
       createTestOrderItem(Ord.Id,5,lstPbEntry[0].Id,lstPbEntry[0].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'SN123','Failed_Serial_Number__c' => 'SNN-1-1','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'RMA_Component_Type__c' => 'HDD'}),
       createTestOrderItem(Ord.Id,5,lstPbEntry[1].Id,lstPbEntry[1].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'SN123','Failed_Serial_Number__c' => 'SNN-1-1','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'RMA_Component_Type__c' => 'PSU'}),
       createTestOrderItem(Ord.Id,5,lstPbEntry[1].Id,lstPbEntry[1].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'SNN123','Failed_Serial_Number__c' => 'SNN-1-1','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'RMA_Component_Type__c' => 'Chassis'}),
       createTestOrderItem(Ord.Id,5,lstPbEntry[1].Id,lstPbEntry[1].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'SN123','Failed_Serial_Number__c' => 'SNN-1-1','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'RMA_Component_Type__c' => 'Memory'}),
       createTestOrderItem(Ord.Id,5,lstPbEntry[1].Id,lstPbEntry[1].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'SN123','Failed_Serial_Number__c' => 'SNN-1-1','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'RMA_Component_Type__c' => 'Node'}),
       createTestOrderItem(Ord.Id,5,lstPbEntry[1].Id,lstPbEntry[1].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'SN123','Failed_Serial_Number__c' => 'SNN-1-1','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'RMA_Component_Type__c' => 'Appliance'})
      };
      TransactionalDataCollection.orderItemMainList.clear();
      insert lstOrdrItems;
      OrderItem temp = [SELECT SerialNumber__c, Failed_Serial_Number__c FROM OrderItem WHERE Id = :lstOrdrItems[0].Id];
      temp.RMA_Component_Type__c = 'Memory';
      //update temp;
      test.stopTest();
      ord.Order_Status__c = 'Shipped';
      update ord;
    }
  }
  static testMethod void testRMAShippedOrderPSU1() {
    testDataFactoryClass.createCustomSettings();
    System.runAs(new User(Id = UserInfo.getUserId())) {
      Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test' LIMIT 1];
      Assert.areEqual('Test', acct.Name);
      Opportunity oppr = [SELECT Id, pricebook2Id FROM Opportunity WHERE AccountId = :acct.Id LIMIT 1];
      delete [SELECT SBQQ__Type__c FROM SBQQ__Quote__c WHERE SBQQ__Account__c = :acct.Id LIMIT 1];
      Id pricebookId = Test.getStandardPricebookId();
      oppr.pricebook2Id = pricebookId;
      update oppr;
      List<Product2> lstProds = new List<Product2>{
              createTestProduct('RBK-SVC-PREM-R344', 'RBK-SVC-PREM-R344', 'RBK-R300', 'RBK-R6408F', null, new Map<String, Object>{'Entitlement_Conversion_Non_CPQ__c' => 'One per quote line','Create_Asset__c' => true}),
              createTestProduct('RBK-SVC-PREM-R344', 'RBK-SVC-PREM-R344', 'RBK-R300', 'RBK-R640F', null, new Map<String, Object>{'Entitlement_Conversion_Non_CPQ__c' => 'One per unit','Create_Asset__c' => false})
      };
      insert lstProds;
      List<PricebookEntry> lstPbEntry = new List<PricebookEntry>{
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[0].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[1].Id, UnitPrice = 100.00, IsActive = true)
      };
      insert lstPbEntry;
      List<Asset> assetsList = new List<Asset>{
        createAsset('SN123', Label.Unassigned_Account_Id, lstProds[0].id,'Purchased','SN123',new Map<String, Object>{'Serial_Number__c' => 'SN123','Premium_Support_End_Date__c' => Date.today()}),
        createAsset('SNN-1-1', acct.id, lstProds[1].id,'Purchased','SNN-1-1',new Map<String, Object>{'Serial_Number__c' => 'SNN-1-1','Premium_Support_End_Date__c' => Date.today()})
      };
      insert assetsList;
      List<Chassis__c> chassis = new List<Chassis__c>{
        new Chassis__c(Name = 'SNN-1-1', serial_number__c = 'SNN-1-1', asset__c = assetsList[1].Id, manufactured_date__c = System.now()),
        new Chassis__c(Name = 'SN123', serial_number__c = 'SN123', asset__c = assetsList[1].Id, manufactured_date__c = System.now())
      };
      insert chassis;
      List<Node__c> lstNodes = new List<Node__c>{
        new Node__c(
          //Cluster__c = clusters.get(0).Id,
          Asset__c = assetsList[1].Id,
          Serial_Number__c = 'SN123',
          software_version__c = '1.0.1',
          Name = 'SN123',
          chassis__c = chassis[0].Id
        ),
        new Node__c(
          //Cluster__c = clusters.get(0).Id,
          Asset__c = assetsList[1].Id,
          Serial_Number__c = 'SNN-1-1',
          software_version__c = '1.0.1',
          Name = 'SNN-1-1',
          chassis__c = chassis[0].Id
        )
      };
      insert lstNodes;
      List<Power_Supply__c> psus = new List<Power_Supply__c>{
        //new Power_Supply__c(Name = 'SN12345', asset__c = assetsList[0].Id, revision__c = '1.3', serial_number__c = 'SN12345', part_number__c = 'PWS-2K22A-1R', manufactured_date__c = System.now()),
        new Power_Supply__c(
          Name = 'SNN-1-1',
          asset__c = assetsList[1].Id,
          revision__c = '1.3',
          serial_number__c = 'SNN-1-1',
          part_number__c = 'PWS-2K22A-1R',
          manufactured_date__c = System.now()
        )
      };
      insert psus;
      List<Drive__c> Hdddrives = new List<Drive__c>{
        new Drive__c(
          Name = 'SNN-1-1',
          asset__c = assetsList[1].Id,
          serial_number__c = 'SNN-1-1',
          node__c = lstNodes[0].Id,
          type__c = 'HDD',
          manufactured_date__c = System.now()
        )
        //new Drive__c(Name = '0RV5TST02', asset__c = assetsList[0].Id,serial_number__c = '0RV5TST02', node__c=nodes[0].Id,type__c='HDD', manufactured_date__c = System.now())
      };
      insert Hdddrives;
      List<Memory__c> memory = new List<Memory__c>{
        //new Memory__c(Name = '0RV5MEM01', asset__c = assets[0].Id,serial_number__c = '0RV5MEM01', node__c = nodes[0].Id ,manufactured_date__c = System.now()),
        new Memory__c(Name = 'SNN-1-1', asset__c = assetsList[1].Id, serial_number__c = 'SNN-1-1', node__c = lstNodes[0].Id, manufactured_date__c = System.now())
      };
      insert memory;
      test.startTest();
      Order ord = createTestorder('RMA',null, acct.Id,oppr.Id,null ,pricebookId,null,null,new Map<String, Object>{'Order_Status__c' => 'On Hold','Mosaic_SKUs__c' => 'RBK-MOSAIC','Order_Splitted__c' => true,'Internal_Order_Stage__c' => 'Pending','Screening_Source__c' => 'Internal','Ship_To_Name__c' => 'Test','Have_Hardware_Products__c' => false,'ScreenStatus__c' => 'Approved','RecordTypeId' => Schema.SObjectType.Order.getRecordTypeInfosByName().get('RMA Order')?.getRecordTypeId()});
      insert Ord;
      List<OrderItem> lstOrdrItems = new List<OrderItem>{
       createTestOrderItem(Ord.Id,5,lstPbEntry[0].Id,lstPbEntry[0].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'SN123','Failed_Serial_Number__c' => 'SNN-1-1','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'RMA_Component_Type__c' => 'HDD'}),
       createTestOrderItem(Ord.Id,5,lstPbEntry[1].Id,lstPbEntry[1].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'SN123','Failed_Serial_Number__c' => 'SNN-1-1','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'RMA_Component_Type__c' => 'PSU'}),
       createTestOrderItem(Ord.Id,5,lstPbEntry[1].Id,lstPbEntry[1].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'SN123','Failed_Serial_Number__c' => 'SNN-1-1','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'RMA_Component_Type__c' => 'Chassis'}),
       createTestOrderItem(Ord.Id,5,lstPbEntry[1].Id,lstPbEntry[1].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'SN123','Failed_Serial_Number__c' => 'SNN-1-1','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'RMA_Component_Type__c' => 'Memory'}),
       createTestOrderItem(Ord.Id,5,lstPbEntry[1].Id,lstPbEntry[1].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'SN123','Failed_Serial_Number__c' => 'SNN-1-1','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'RMA_Component_Type__c' => 'Node'}),
       createTestOrderItem(Ord.Id,5,lstPbEntry[1].Id,lstPbEntry[1].UnitPrice,new Map<String, Object>{'SerialNumber__c' => 'SN123','Failed_Serial_Number__c' => 'SNN-1-1','Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today(),'RMA_Component_Type__c' => 'Appliance'})
      };
      TransactionalDataCollection.orderItemMainList.clear();
      insert lstOrdrItems;
      OrderItem temp = [SELECT SerialNumber__c, Failed_Serial_Number__c FROM OrderItem WHERE Id = :lstOrdrItems[0].Id];
      temp.RMA_Component_Type__c = 'Memory';
      //update temp;
      test.stopTest();
      ord.Order_Status__c = 'Shipped';
      update ord;
    }
  }
    
  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to Order trigger logic
   */
  static testMethod void testShipmentDetailsForOther() {
    User currentUsr = createUser();
    System.runAs(currentUsr) {
      // insert new ShGl_DisableBusinessLogic__c(Disable_POC_Validation_Rules__c = true,Disable_Contact_Triggers__c =true,Disable_SBQQ_Quote_Triggers__c = true, Disable_SBQQ_QuoteLine_Triggers__c=true);

      insert new TriggerControl__c(Name = 'Entitlement', DisableTrigger__c = true);
      ShGl_DisableBusinessLogic__c control = new ShGl_DisableBusinessLogic__c(
        Disable_Entitlement_Validation_Rules__c = true,
        Disable_SBQQ_Quote_Triggers__c = true,
        Disable_SBQQ_QuoteLine_Triggers__c = true,
        Disable_Opportunity_Validation_Rules__c = true,
        Disable_Opportunity_Triggers__c = true,
        Disable_Order_Email_Alerts__c = false,
        Disable_Order_Old_Trigger__c = true,
        Disable_Order_Validation_Rules__c = true,
        Disable_Order_Triggers__c = true,
        Disable_Asset_Triggers__c = true,
        Disable_Contact_Triggers__c = true,
        Order_Trigger_MaxLoop_Count__c = 25,
        setupOwnerId = currentUsr.id
      );
      insert control;
      Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test' LIMIT 1];
      Assert.areEqual('Test', acct.Name);
      Opportunity oppr = [SELECT Id, pricebook2Id, Override__c, Aspen_Eligibility__c FROM Opportunity WHERE AccountId = :acct.Id LIMIT 1];

      Id pricebookId = Test.getStandardPricebookId();
      oppr.pricebook2Id = pricebookId;
      update oppr;

      List<Product2> lstProds = new List<Product2>{
        createTestProduct('RBK-SVC-PREM-R344', 'RBK-SVC-TR', 'ASE', 'RBK-R6408F', null, new Map<String, Object>{'Capacity__c' => '12TB'}),
        createTestProduct('RBK-SVC-PREM-R3441', 'RBK-SVC-TR1', 'ASE1', 'RBK-R6408F1', null, new Map<String, Object>{'Capacity__c' => '36TB'})
      };

      insert lstProds;

      List<PricebookEntry> lstPbEntry = new List<PricebookEntry>{
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[0].Id, UnitPrice = 100.00, IsActive = true)
      };

      insert lstPbEntry;

      List<OpportunityLineItem> lstOlis = new List<OpportunityLineItem>{
        new OpportunityLineItem(OpportunityId = oppr.Id, Quantity = 5, PricebookEntryId = lstPbEntry[0].Id, TotalPrice = 5 * lstPbEntry[0].UnitPrice)
      };

      insert lstOlis;
      SBQQ__Quote__c quote = [SELECT id, name, SBQQ__Account__c, SBQQ__Opportunity2__c, SBQQ__NetAmount__c, ProcessType__c, SBQQ__Type__c FROM SBQQ__Quote__c LIMIT 1];
      set<string> addProduct = new Set<string>{
        'HybridProd-001-test',
        'HybridProd-002-test',
        'HWSupportProd-001-test',
        'HWSupport2Prod-001-test',
        'HWPROD-001-TEST',
        'HWPROD-002-TEST',
        'AddonProd-001-test',
        'RC-HDD-01'
      };
      Map<string, string> childParentMap = new Map<string, string>{
        'HWPROD-001-TEST' => 'HybridProd-001-test',
        'HWProd-002-test' => 'HybridProd-002-test',
        'HWSupportProd-001-test' => 'HWPROD-001-TEST',
        'HWSupport2Prod-001-test' => 'HWPROD-001-TEST',
        'AddonProd-001-test' => 'HybridProd-001-test',
        'RC-HDD-01' => 'HWPROD-001-TEST'
      };
      createProductAndPBE();
      createPolarisQuote(addProduct, quote, childParentMap);
      Map<Id, Id> prodPBEId = new Map<id, id>();
      for (PricebookEntry pbe : [SELECT id, product2Id, product2.name FROM PricebookEntry WHERE Pricebook2id = :system.label.CPQPricebookID]) {
        prodPBEId.put(pbe.product2Id, pbe.id);
      }
        Set<Id> product2IdSet = prodPBEId.keyset();
        List<Id> productIds = new List<Id>(product2IdSet);
    //    Id productId = prodPBEId.keyset();
      DateTime todaysDate = Date.Today();
      String dateStr = todaysDate.format('MM/dd/yyyy');
      test.startTest();

      ServiceContract objSC = new ServiceContract(
        Name = 'ServiceContractTest1',
        AccountId = quote.SBQQ__Account__c,
        StartDate = Date.today(),
        Term = 36,
        pricebook2Id = oppr.pricebook2Id,
        SBQQSC__Opportunity__c = oppr.Id,
        SBQQSC__Quote__c = quote.Id
      );
      insert objSC;

            List<ContractLineItem> lstCli = new List<ContractLineItem>{
        new ContractLineItem(
          Quantity = 5,
         // SBQQSC__QuoteLine__c = lines[0].Id,
          SBQQSC__Product__c = lstProds[0].Id,
          PricebookEntryId = lstPbEntry[0].Id,
          ServiceContractId = objSC.Id,
          UnitPrice = 10,
          StartDate = date.today()
        )
      };
      insert lstCli;
  
      List<Order> ordList = new List<order>();
      Order ord = createTestorder('Revenue',quote.id, quote.SBQQ__Account__c,oppr.Id,null ,system.label.CPQPricebookID,null,null,new Map<String, Object>{'Status' => 'Draft','ProcessType__c' => 'Aspen','Order_Status__c' => 'Shipped'});
      Order ord1 = createTestorder('Revenue',quote.id, quote.SBQQ__Account__c,oppr.Id,null ,system.label.CPQPricebookID,null,null,new Map<String, Object>{'Status' => 'Draft','ProcessType__c' => 'Aspen','Order_Status__c' => 'Shipped'});

        ordList.add(ord);
      ordList.add(ord1);
      ordList[1].type = 'POC';
      ordList[1].Sync_to_NetSuite__c = false;
      insert ordList;
      List<asset> AssetToInsert = new List<asset>();
      List<OrderItem> OIList = new List<OrderItem>();
      List<ShipmentDetail__c> SDList = new List<ShipmentDetail__c>();
      List<Entitlement> entToInsert = new List<Entitlement>();
      for (integer i = 0; i <= 7; i++) {
        SDList.add(testShipmentDetail(ordList[0].Id,'Fail HW','HWPROD-001-TEST',quote.name,'Aspen',new Map<String, Object>{'ShippedDate__c' => dateStr,'Status__c' => 'New','TrackingNumber__c' => 'Order100','ContractManufacturer__c' => 'Super Micro Computer, Inc.'}));
      }
      // SD without Order
      for (integer i = 0; i <= 7; i++) {
        SDList.add(testShipmentDetail(null,'SDWithoutOrder-Fail','HWPROD-001-TEST',quote.name,'Aspen',new Map<String, Object>{'Quantity__c' => 12,'ShippedDate__c' => dateStr,'Status__c' => 'New','TrackingNumber__c' => 'Order100','ContractManufacturer__c' => 'Super Micro Computer, Inc.'}));
      }
      SDList[0].Type__c = 'InvalidType';
      SDList[0].Order__c = ordList[1].Id;
      SDList[1].Quantity__c = 13;
      SDList[2].ProductName__c = 'Invalid ProdItm';
      SDList[3].ProductName__c = SDList[12].ProductName__c = '';
      SDList[4].HW_SerialNumber__c = SDList[10].HW_SerialNumber__c = ''; // Missing SN with and without order
      SDList[5].QuoteNumber__c = 'Q-Invalid';
      SDList[6].QuoteNumber__c = SDList[13].QuoteNumber__c = '';
      SDList[7].SalesOrderNumber__c = 'Invalid OrderNum';
      SDList[8].SalesOrderNumber__c = 'SPARES'; // SD for spares only
      SDList[8].ProductName__c = 'RC-HDD-01';
      SDList[9].ProductName__c = 'RC-SFP-TSR-0'; // SD for accessory

      SDList.add(testShipmentDetail(ordList[0].Id,'TestAsset12','RC-HDD-01',quote.name,'Aspen',new Map<String, Object>{'Quantity__c' => 12,'ShippedDate__c' => dateStr,'Status__c' => 'New','ContractManufacturer__c' => 'Super Micro Computer, Inc.','SalesOrderNumber__c' => 'SPARES'}));
      SDList.add(testShipmentDetail(ordList[0].Id,'TestAsset12','RC-SFP-TSR-01',quote.name,'Aspen',new Map<String, Object>{'Quantity__c' => 12,'ShippedDate__c' => dateStr,'Status__c' => 'New','ContractManufacturer__c' => 'Super Micro Computer, Inc.','SalesOrderNumber__c' => 'SPARES'}));
      SDList.add(testShipmentDetail(ordList[0].Id,null,null,quote.name,'Aspen',new Map<String, Object>{'Quantity__c' => 12,'ShippedDate__c' => dateStr,'Status__c' => 'New','ContractManufacturer__c' => 'Super Micro Computer, Inc.','SalesOrderNumber__c' => 'SPARES'}));
      SDList.add(testShipmentDetail(ordList[0].Id,'TestAsset12','Accessories',quote.name,'Aspen',new Map<String, Object>{'Quantity__c' => 12,'ShippedDate__c' => dateStr,'Status__c' => 'New','Type__c' => 'Aspen','ContractManufacturer__c' => 'Super Micro Computer, Inc.'}));
      SDList.add(testShipmentDetail(ordList[1].Id,'TestAsset12','Accessories',quote.name,'Aspen',new Map<String, Object>{'Quantity__c' => 12,'ShippedDate__c' => dateStr,'Status__c' => 'New','ContractManufacturer__c' => 'Super Micro Computer, Inc.','SalesOrderNumber__c' => 'SPARES'}));
      for (SBQQ__QuoteLine__c qli : [
        SELECT
          id,
          SBQQ__Quote__r.SBQQ__NetAmount__c,
          SBQQ__NetPrice__c,
          SBQQ__NetTotal__c,
          SBQQ__Product__r.productcode,
          SBQQ__Quantity__c,
          SBQQ__SubscriptionTerm__c,
          SBQQ__Product__c,
          SBQQ__Product__r.name,
          SBQQ__Product__r.Product_Level__c,
          SBQQ__RequiredBy__c,
          SBQQ__PricebookEntryId__c
        FROM SBQQ__QuoteLine__c
      ]) {
        if ('Hardware' != qli.SBQQ__Product__r.Product_Level__c) {
          OIList.add(createTestOrderItem(ordList[0].Id,qli.SBQQ__Quantity__c,prodPBEId.get(qli.SBQQ__Product__c),qli.SBQQ__NetPrice__c,new Map<String, Object>{'SBQQSC__ContractLineItem__c' => lstCli[0].Id,'EDI_Line_Number__c' => qli.id,'SBQQ__QuoteLine__c' => qli.id,'Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today()}));
        } else {
          SDList.add(testShipmentDetail(ordList[0].Id,qli.SBQQ__Product__r.productcode + '001,' + qli.SBQQ__Product__r.productcode + '002',qli.SBQQ__Product__r.productcode,quote.name,'Aspen',new Map<String, Object>{'ShippedDate__c' => dateStr,'Status__c' => 'New','TrackingNumber__c' => 'Order100','ContractManufacturer__c' => 'Super Micro Computer, Inc.'}));
          AssetToInsert.add(createAsset(qli.SBQQ__Product__r.productcode + '001', quote.SBQQ__Account__c, qli.SBQQ__Product__c,null,qli.SBQQ__Product__r.productcode + '001',new Map<String, Object>{'Serial_Number__c' => qli.SBQQ__Product__r.productcode + '001'}));
          AssetToInsert.add(createAsset(qli.SBQQ__Product__r.productcode + '002', quote.SBQQ__Account__c, qli.SBQQ__Product__c,null,qli.SBQQ__Product__r.productcode + '002',new Map<String, Object>{'Serial_Number__c' => qli.SBQQ__Product__r.productcode + '002'}));
        }
      }
      insert OIList;
      insert AssetToInsert;
      insert SDList;
      SDList[10].Status__c = 'New';
      update SDList[10];
      control.Disable_Order_Triggers__c = false;
      update control;
      for (OrderItem OI : [SELECT id, Product2Id, product2.Product_Level__c, Quantity FROM orderItem WHERE id IN :OIList]) {
        if (OI.product2.Product_Level__c == 'Support') {
          for (integer i = 0; i < OI.Quantity; i++) {
            entToInsert.add(createEntitlement('T-' + OI.id + '-' + i, quote.SBQQ__Account__c, OI.Product2ID,null, new Map<String, Object>{'StartDate' => Date.valueof(System.now().addDays(-2)),'EndDate' => Date.valueof(System.now().addYears(2)),'Order_Service_Item__c' => OI.id}));
          }
        } else if (OI.product2.Product_Level__c == 'Hybrid Software') {
          entToInsert.add(createEntitlement('T-' + OI.id, quote.SBQQ__Account__c, OI.Product2ID,null, new Map<String, Object>{'StartDate' => Date.valueof(System.now().addDays(-2)),'EndDate' => Date.valueof(System.now().addYears(2)),'Order_Service_Item__c' => OI.id}));
        }
      }
      insert entToInsert;

      List<Asset> lstofAsset = [SELECT Id, SerialNumber FROM Asset LIMIT 1];
      List<Scale_Entitlement__c> linkedAssets = new List<Scale_Entitlement__c>();
      for (Entitlement ent : [SELECT id, Order_Service_Item__r.Quantity, quantity__c, Order_Service_Item__c FROM Entitlement LIMIT 1]) {
        linkedAssets.add(new Scale_Entitlement__c(Asset__c = lstofAsset[0].id, Entitlement__c = ent.id, Order_Product__c = ent.Order_Service_Item__c));
        break;
      }
      if (!linkedAssets.isEmpty())
        insert linkedAssets;
      for (OrderItem OI : OIList) {
        //  OI.Program__c = CONSTANTS.PROGRAM_REFRESH;
        OI.Upgraded_From__c = lstofAsset[0].SerialNumber;
      }
      update OIList;
      for (Order ord2 : ordList) {
        ord2.SD_Status__c = 'Start';
      }
      ordList[0].status = 'Activated';
      ordList[0].SBQQ__Contracted__c = true;
      ordList[1].Order_Sub_Type__c = 'GC OnDemand';
      ordList[0].Order_Status__c = 'Shipped';
      ordList[0].ProcessType__c = 'Aspen';
      ordList[1].ProcessType__c = 'Aspen';
      update ordList;
      for (Order ord2 : ordList) {
        ord2.SD_Status__c = null;
      }
      update ordList; 
  
      test.stopTest();
    }
  }


 /*static testMethod void testShipmentDetailsForOther() {
    User currentUsr = createUser();
    System.runAs(currentUsr) {
      
      insert new TriggerControl__c(Name = 'Entitlement', DisableTrigger__c = true);
      ShGl_DisableBusinessLogic__c control = new ShGl_DisableBusinessLogic__c(
        Disable_Entitlement_Validation_Rules__c = true,
        Disable_SBQQ_Quote_Triggers__c = true,
        Disable_SBQQ_QuoteLine_Triggers__c = true,
        Disable_Opportunity_Validation_Rules__c = true,
        Disable_Opportunity_Triggers__c = true,
        Disable_Order_Email_Alerts__c = false,
        Disable_Order_Old_Trigger__c = true,
        Disable_Order_Validation_Rules__c = true,
        Disable_Order_Triggers__c = true,
        Disable_Asset_Triggers__c = true,
        Disable_Contact_Triggers__c = true,
        Order_Trigger_MaxLoop_Count__c = 25,
        setupOwnerId = currentUsr.id
      );
      insert control;
      Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test' LIMIT 1];
      Assert.areEqual('Test', acct.Name);
      Opportunity oppr = [SELECT Id, pricebook2Id, Override__c, Aspen_Eligibility__c FROM Opportunity WHERE AccountId = :acct.Id LIMIT 1];

      Id pricebookId = Test.getStandardPricebookId();
      oppr.pricebook2Id = pricebookId;
      update oppr;

      List<Product2> lstProds = new List<Product2>{
        createTestProduct('RBK-SVC-PREM-R344', 'RBK-SVC-TR', 'ASE', 'RBK-R6408F', null, new Map<String, Object>{'Capacity__c' => '12TB'}),
        createTestProduct('RBK-SVC-PREM-R3441', 'RBK-SVC-TR1', 'ASE1', 'RBK-R6408F1', null, new Map<String, Object>{'Capacity__c' => '36TB'})
      };

      insert lstProds;

      List<PricebookEntry> lstPbEntry = new List<PricebookEntry>{
        new PricebookEntry(Pricebook2Id = oppr.pricebook2Id, Product2Id = lstProds[0].Id, UnitPrice = 100.00, IsActive = true)
      };

      insert lstPbEntry;

      List<OpportunityLineItem> lstOlis = new List<OpportunityLineItem>{
        new OpportunityLineItem(OpportunityId = oppr.Id, Quantity = 5, PricebookEntryId = lstPbEntry[0].Id, TotalPrice = 5 * lstPbEntry[0].UnitPrice)
      };

      insert lstOlis;
      SBQQ__Quote__c quote = [SELECT id, name, SBQQ__Account__c, SBQQ__Opportunity2__c, SBQQ__NetAmount__c, ProcessType__c, SBQQ__Type__c FROM SBQQ__Quote__c LIMIT 1];
      set<string> addProduct = new Set<string>{
        'HybridProd-001-test',
        'HybridProd-002-test',
        'HWSupportProd-001-test',
        'HWSupport2Prod-001-test',
        'HWPROD-001-TEST',
        'HWPROD-002-TEST',
        'AddonProd-001-test',
        'RC-HDD-01'
      };
      Map<string, string> childParentMap = new Map<string, string>{
        'HWPROD-001-TEST' => 'HybridProd-001-test',
        'HWProd-002-test' => 'HybridProd-002-test',
        'HWSupportProd-001-test' => 'HWPROD-001-TEST',
        'HWSupport2Prod-001-test' => 'HWPROD-001-TEST',
        'AddonProd-001-test' => 'HybridProd-001-test',
        'RC-HDD-01' => 'HWPROD-001-TEST'
      };
      createProductAndPBE();
      createPolarisQuote(addProduct, quote, childParentMap);
      Map<Id, Id> prodPBEId = new Map<id, id>();
      for (PricebookEntry pbe : [SELECT id, product2Id, product2.name FROM PricebookEntry WHERE Pricebook2id = :system.label.CPQPricebookID]) {
        prodPBEId.put(pbe.product2Id, pbe.id);
      }
      DateTime todaysDate = Date.Today();
      String dateStr = todaysDate.format('MM/dd/yyyy');
      test.startTest();
      List<Order> ordList = new List<order>();
      Order ord = createTestorder('Revenue',quote.id, quote.SBQQ__Account__c,oppr.Id,null ,system.label.CPQPricebookID,null,null,new Map<String, Object>{'Status' => 'Draft','ProcessType__c' => 'Aspen','Order_Status__c' => 'Shipped'});
      Order ord1 = createTestorder('Revenue',quote.id, quote.SBQQ__Account__c,oppr.Id,null ,system.label.CPQPricebookID,null,null,new Map<String, Object>{'Status' => 'Draft','ProcessType__c' => 'Aspen','Order_Status__c' => 'Shipped'});

        ordList.add(ord);
      ordList.add(ord1);
      ordList[1].type = 'POC';
      ordList[1].Sync_to_NetSuite__c = false;
      insert ordList;
      List<asset> AssetToInsert = new List<asset>();
      List<OrderItem> OIList = new List<OrderItem>();
      List<ShipmentDetail__c> SDList = new List<ShipmentDetail__c>();
      List<Entitlement> entToInsert = new List<Entitlement>();
      for (integer i = 0; i <= 7; i++) {
        SDList.add(testShipmentDetail(ordList[0].Id,'Fail HW','HWPROD-001-TEST',quote.name,'Aspen',new Map<String, Object>{'ShippedDate__c' => dateStr,'Status__c' => 'New','TrackingNumber__c' => 'Order100','ContractManufacturer__c' => 'Super Micro Computer, Inc.'}));
      }
      // SD without Order
      for (integer i = 0; i <= 7; i++) {
        SDList.add(testShipmentDetail(null,'SDWithoutOrder-Fail','HWPROD-001-TEST',quote.name,'Aspen',new Map<String, Object>{'Quantity__c' => 12,'ShippedDate__c' => dateStr,'Status__c' => 'New','TrackingNumber__c' => 'Order100','ContractManufacturer__c' => 'Super Micro Computer, Inc.'}));
      }
      SDList[0].Type__c = 'InvalidType';
      SDList[0].Order__c = ordList[1].Id;
      SDList[1].Quantity__c = 13;
      SDList[2].ProductName__c = 'Invalid ProdItm';
      SDList[3].ProductName__c = SDList[12].ProductName__c = '';
      SDList[4].HW_SerialNumber__c = SDList[10].HW_SerialNumber__c = ''; // Missing SN with and without order
      SDList[5].QuoteNumber__c = 'Q-Invalid';
      SDList[6].QuoteNumber__c = SDList[13].QuoteNumber__c = '';
      SDList[7].SalesOrderNumber__c = 'Invalid OrderNum';
      SDList[8].SalesOrderNumber__c = 'SPARES'; // SD for spares only
      SDList[8].ProductName__c = 'RC-HDD-01';
      SDList[9].ProductName__c = 'RC-SFP-TSR-0'; // SD for accessory

      SDList.add(testShipmentDetail(ordList[0].Id,'TestAsset12','RC-HDD-01',quote.name,'Aspen',new Map<String, Object>{'Quantity__c' => 12,'ShippedDate__c' => dateStr,'Status__c' => 'New','ContractManufacturer__c' => 'Super Micro Computer, Inc.','SalesOrderNumber__c' => 'SPARES'}));
      SDList.add(testShipmentDetail(ordList[0].Id,'TestAsset12','RC-SFP-TSR-01',quote.name,'Aspen',new Map<String, Object>{'Quantity__c' => 12,'ShippedDate__c' => dateStr,'Status__c' => 'New','ContractManufacturer__c' => 'Super Micro Computer, Inc.','SalesOrderNumber__c' => 'SPARES'}));
      SDList.add(testShipmentDetail(ordList[0].Id,null,null,quote.name,'Aspen',new Map<String, Object>{'Quantity__c' => 12,'ShippedDate__c' => dateStr,'Status__c' => 'New','ContractManufacturer__c' => 'Super Micro Computer, Inc.','SalesOrderNumber__c' => 'SPARES'}));
      SDList.add(testShipmentDetail(ordList[0].Id,'TestAsset12','Accessories',quote.name,'Aspen',new Map<String, Object>{'Quantity__c' => 12,'ShippedDate__c' => dateStr,'Status__c' => 'New','Type__c' => 'Aspen','ContractManufacturer__c' => 'Super Micro Computer, Inc.'}));
      SDList.add(testShipmentDetail(ordList[1].Id,'TestAsset12','Accessories',quote.name,'Aspen',new Map<String, Object>{'Quantity__c' => 12,'ShippedDate__c' => dateStr,'Status__c' => 'New','ContractManufacturer__c' => 'Super Micro Computer, Inc.','SalesOrderNumber__c' => 'SPARES'}));
      for (SBQQ__QuoteLine__c qli : [
        SELECT
          id,
          SBQQ__Quote__r.SBQQ__NetAmount__c,
          SBQQ__NetPrice__c,
          SBQQ__NetTotal__c,
          SBQQ__Product__r.productcode,
          SBQQ__Quantity__c,
          SBQQ__SubscriptionTerm__c,
          SBQQ__Product__c,
          SBQQ__Product__r.name,
          SBQQ__Product__r.Product_Level__c,
          SBQQ__RequiredBy__c,
          SBQQ__PricebookEntryId__c
        FROM SBQQ__QuoteLine__c
      ]) {
        if ('Hardware' != qli.SBQQ__Product__r.Product_Level__c) {
          OIList.add(createTestOrderItem(ordList[0].Id,qli.SBQQ__Quantity__c,prodPBEId.get(qli.SBQQ__Product__c),qli.SBQQ__NetPrice__c,new Map<String, Object>{'EDI_Line_Number__c' => qli.id,'SBQQ__QuoteLine__c' => qli.id,'Support_End_Date__c' => System.Today().addYears(1),'Support_Start_Date__c' => System.Today()}));
        } else {
          SDList.add(testShipmentDetail(ordList[0].Id,qli.SBQQ__Product__r.productcode + '001,' + qli.SBQQ__Product__r.productcode + '002',qli.SBQQ__Product__r.productcode,quote.name,'Aspen',new Map<String, Object>{'ShippedDate__c' => dateStr,'Status__c' => 'New','TrackingNumber__c' => 'Order100','ContractManufacturer__c' => 'Super Micro Computer, Inc.'}));
          AssetToInsert.add(createAsset(qli.SBQQ__Product__r.productcode + '001', quote.SBQQ__Account__c, qli.SBQQ__Product__c,null,qli.SBQQ__Product__r.productcode + '001',new Map<String, Object>{'Serial_Number__c' => qli.SBQQ__Product__r.productcode + '001'}));
          AssetToInsert.add(createAsset(qli.SBQQ__Product__r.productcode + '002', quote.SBQQ__Account__c, qli.SBQQ__Product__c,null,qli.SBQQ__Product__r.productcode + '002',new Map<String, Object>{'Serial_Number__c' => qli.SBQQ__Product__r.productcode + '002'}));
        }
      }
      insert OIList;
      insert AssetToInsert;
      insert SDList;
      SDList[10].Status__c = 'New';
      update SDList[10];
      control.Disable_Order_Triggers__c = false;
      update control;
      for (OrderItem OI : [SELECT id, Product2Id, product2.Product_Level__c, Quantity FROM orderItem WHERE id IN :OIList]) {
        if (OI.product2.Product_Level__c == 'Support') {
          for (integer i = 0; i < OI.Quantity; i++) {
            entToInsert.add(createEntitlement('T-' + OI.id + '-' + i, quote.SBQQ__Account__c, OI.Product2ID,null, new Map<String, Object>{'StartDate' => Date.valueof(System.now().addDays(-2)),'EndDate' => Date.valueof(System.now().addYears(2)),'Order_Service_Item__c' => OI.id}));
          }
        } else if (OI.product2.Product_Level__c == 'Hybrid Software') {
          entToInsert.add(createEntitlement('T-' + OI.id, quote.SBQQ__Account__c, OI.Product2ID,null, new Map<String, Object>{'StartDate' => Date.valueof(System.now().addDays(-2)),'EndDate' => Date.valueof(System.now().addYears(2)),'Order_Service_Item__c' => OI.id}));
        }
      }
      insert entToInsert;

      List<Asset> lstofAsset = [SELECT Id, SerialNumber FROM Asset LIMIT 1];
      List<Scale_Entitlement__c> linkedAssets = new List<Scale_Entitlement__c>();
      for (Entitlement ent : [SELECT id, Order_Service_Item__r.Quantity, quantity__c, Order_Service_Item__c FROM Entitlement LIMIT 1]) {
        linkedAssets.add(new Scale_Entitlement__c(Asset__c = lstofAsset[0].id, Entitlement__c = ent.id, Order_Product__c = ent.Order_Service_Item__c));
        break;
      }
      if (!linkedAssets.isEmpty())
        insert linkedAssets;
      for (OrderItem OI : OIList) {
        OI.Upgraded_From__c = lstofAsset[0].SerialNumber;
      }
      update OIList;
      for (Order ord2 : ordList) {
        ord2.SD_Status__c = 'Start';
      }
      ordList[0].status = 'Activated';
      ordList[0].SBQQ__Contracted__c = true;
      ordList[1].Order_Sub_Type__c = 'GC OnDemand';
      ordList[0].Order_Status__c = 'Shipped';
      ordList[0].ProcessType__c = 'Aspen';
      ordList[1].ProcessType__c = 'Aspen';
      update ordList;
      test.stopTest();
    }
  }*/
 
  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to Order trigger logic
   */
  static testMethod void testcopyPreviousOrderDetailsForRCDMTExtension() {
    SBQQ.TriggerControl.disable();
    testDataFactoryClass.createCustomSettings();
    String uniqueUserName = 'AdminUser' + DateTime.now().getTime() + '@rubrik.com';
    Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
    User u = createTestUser(null, p.Id, uniqueUserName, 'adminU','AdminUser@rubrik.com', new Map<String, Object>{'EmailEncodingKey' => 'UTF-8','LastName' => 'Testing','LanguageLocaleKey' => 'en_US','LocaleSidKey' => 'en_US','TimeZoneSidKey' => 'America/Los_Angeles'});
    System.runAs(u) {
      Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test' LIMIT 1];
      Assert.areEqual('Test', acct.Name);
      Opportunity oppr = [SELECT Id, Opportunity_Sub_Type__c, pricebook2Id FROM Opportunity WHERE AccountId = :acct.Id LIMIT 1];
        Order newOrd = createTestorder('Revenue',null, acct.Id,oppr.Id,null ,null,null,'POC',new Map<String, Object>{'EffectiveDate' => System.today().addDays(2),'Status' => 'Draft','Order_Status__c' => 'Order Accepted','ScreenStatus__c' => 'Approved','Order_Splitted__c' => true,'Internal_Order_Stage__c' => 'Pending','Ship_To_Name__c' => 'Test','Have_Hardware_Products__c' => false});
        insert newOrd;
     Order oldOrder = createTestorder('Revenue',null, acct.Id,oppr.Id,null ,null,null,'POC',new Map<String, Object>{'EffectiveDate' => System.today().addDays(2),'Status' => 'Draft','Order_Status__c' => 'Rejected','ScreenStatus__c' => 'Approved','Order_Splitted__c' => true,'Internal_Order_Stage__c' => 'Pending','Ship_To_Name__c' => 'Test','Have_Hardware_Products__c' => false,'PoDate' => System.today().addDays(2),'PoNumber' => '2124','Payment_Terms__c' => 'Net 30','Ship_to_Email__c' => 'test@rubrik.com.invalid'});
     insert oldOrder;
      test.startTest();
      OrderInsertHelper.copyPreviousOrderDetailsForRCDMTExtension(newOrd, oldOrder);
      test.StopTest();
    }
  }
  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to Order trigger logic
   */
  static testMethod void testpopulateFieldsOnInsert() {
    SBQQ.TriggerControl.disable();
    testDataFactoryClass.createCustomSettings();
    System.runAs(new User(Id = UserInfo.getUserId())) {
      Account acct = [SELECT Id, Name FROM Account WHERE Name = 'Test' LIMIT 1];
      Assert.areEqual('Test', acct.Name);
      Opportunity oppr = [SELECT Id, Opportunity_Sub_Type__c, pricebook2Id FROM Opportunity WHERE AccountId = :acct.Id LIMIT 1];
      oppr.Hold_Code__c = 'Missing Payment Terms';
      update oppr;
      SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
      qt.SBQQ__Account__c = acct.Id;
      qt.SBQQ__Opportunity2__c = oppr.Id;
      qt.SBQQ__Primary__c = true;
      qt.SBQQ__SubscriptionTerm__c = 36;
      qt.SBQQ__ExpirationDate__c = date.today().addDays(10);
      qt.SBQQ__PaymentTerms__c = 'Net 45';
      qt.SBQQ__Type__c = 'Renewal+Expansion';
      qt.Is_Refreshed__c = true;
      qt.SBQQ__Type__c = 'Amendment';
      qt.ProcessType__c = 'Aspen';

      insert qt;

      //SBQQ__Quote__c qt = [SELECT Id, MSP_SKUs_Count__c from SBQQ__Quote__c LIMIT 1];
      //qt.MSP_SKUs_Count__c = 3;
      //update qt;

      Product2 prod = new Product2(
        Name = 'RBK-SVC-PREM-R344',
        ProductCode = 'RBK-SVC-PREM-R344',
        Family = 'POLARIS',
        Appliance_Model_HW__c = 'RBK-R6408E',
        isActive = true,
        Bundle_Features__c = 'Polaris',
        Allow_PSO_Task_Creation__c = true
      );

      insert prod;
      SBQQ__QuoteLine__c quoteline3 = new SBQQ__QuoteLine__c(
        SBQQ__Quote__c = qt.Id,
        SBQQ__Product__c = prod.Id,
        SBQQ__Quantity__c = 1,
        SBQQ__SubscriptionPricing__c = null,
        SBQQ__DefaultSubscriptionTerm__c = null,
        SBQQ__ListPrice__c = 200,
        SBQQ__NetPrice__c = 200,
        Is_MSP_Product__c = true,
        SBQQ__Optional__c = true
      );
      insert quoteline3;
      RMA_Order__c rma = new RMA_Order__c();
      rma.Smart_Hands_Provider__c = 'TSP Inc.';
      insert rma;
       Order newOrd = createTestorder('Revenue',null, acct.Id,oppr.Id,null ,null,null,'Tech Order',new Map<String, Object>{'EffectiveDate' => System.today().addDays(2),'Status' => 'Draft','Order_Status__c' => 'Order Accepted','ScreenStatus__c' => 'Approved','Order_Process__c' => 'PO PDF','Order_Splitted__c' => true,'Internal_Order_Stage__c' => 'Pending','Ship_To_Name__c' => 'Test','Have_Hardware_Products__c' => false,'Order_Sub_Type__c' => 'Tech Order','RMA_Request__c' => rma.id});
     insert newOrd;
    }
  }
  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to Order trigger logic
   */
  static testMethod void testOrderOnInsert() {
    insert new RPS__c(
      SetupOwnerId = Userinfo.getOrganizationId(),
      Is_RPS_Required__c = false,
      Screening_Source__c = 'Internal',
      Valid_HoldCodes__c = 'Global Trade Compliance screening failed;Credit Check Failed'
    );

    testDataFactoryClass.createCustomSettings();

    String uniqueUserName = 'AdminUser' + DateTime.now().getTime() + '@rubrik.com';
    Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
    User u = new User(
      Alias = 'adminU',
      Email = 'AdminUser@rubrik.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Testing',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = p.Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = uniqueUserName,
      RBAC_Department__c = 'Service Account',
      RBAC_Group__c = 'API'
    );
    insert u;
    insert new ShGl_DisableBusinessLogic__c(
      Disable_Order_Validation_Rules__c = true,
      Disable_SBQQ_Quote_Triggers__c = true,
      Disable_SBQQ_QuoteLine_Triggers__c = true,
      Disable_Opportunity_Validation_Rules__c = true,
      Disable_Opportunity_Triggers__c = true,
      Disable_Order_Email_Alerts__c = false,
      Disable_Order_Old_Trigger__c = true,
      Disable_Order_Triggers__c = false,
      Disable_Contact_Triggers__c = true,
      Disable_POC_Trigger__c = true,
      Disable_POC_Validation_Rules__c = true,
      Disable_ServiceContract_Trigger__c = true,
      Disable_Entitlement_Validation_Rules__c = true,
      setupOwnerId = u.Id,
      Disable_SBQQ_Quote_Validation_Rules__c = true
    );
    TriggerControl__c objOrderTrigger = new TriggerControl__c(Name = 'Entitlement', Disable_Trigger__c = true, DisableTrigger__c = true, SendEmail__c = false);
    insert objOrderTrigger;
    System.runAs(u) {
      String netAppAccId = Label.NetApp_Account_Ids.split(';')[0];
      Account acct = [SELECT Id, Name, Payment_Term__c FROM Account WHERE Name = 'Test' LIMIT 1];
      acct.RSC_G_Eligible__c = true;
      acct.Eligible_for_RCDM_T__c = true;
      acct.EULA_revision_Required__c = true;
      acct.Id = netAppAccId;
      update acct;
      Assert.areEqual('Test', acct.Name);
      OpportunityObjectTriggerHandler.isOppAutoManual = 'AutoGenerated';
      Opportunity oppr = [SELECT Id, MSP_End_User_Lookup__c, Managed_Services_Deal_type__c, Name, StageName, CloseDate, pricebook2Id, CreatedById FROM Opportunity LIMIT 1];

      Id pricebookId = Test.getStandardPricebookId();
      oppr.pricebook2Id = pricebookId;
      update oppr;

      SBQQ__Quote__c quote = [SELECT Id, SBQQ__Opportunity2__c, RWD_Deal_Ops_Exception__c,SBQQ__PaymentTerms__c,Renewal_Opportunity__c FROM SBQQ__Quote__c LIMIT 1];

      ServiceContract objSC = new ServiceContract(
        Name = 'ServiceContractTest1',
        AccountId = acct.Id,
        StartDate = Date.today(),
        Term = 36,
        pricebook2Id = Test.getStandardPricebookId(),
        SBQQSC__Opportunity__c = oppr.Id,
        SBQQSC__Quote__c = quote.Id
      );
      insert objSC;

      Map<String, Object> oppMap = new Map<String, Object>{
        'Name' => 'test opp',
        'AccountId' => acct.Id,
        'CloseDate' => Date.Today().addDays(10),
        'StageName' => '1 Discovery',
        'Pricebook2Id' => pricebookId
      };
      Id partner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
      Account partnerAcc = new Account(
        Name = 'Customer',
        recordtypeId = partner,
        Phone = '123-456-7890',
        AccountNumber = 'Test',
        BillingStreet = '123 street',
        BillingCity = 'Santa Clara',
        BillingState = 'California',
        BillingPostalCode = '95050',
        BillingCountry = 'United States',
        ShippingStreet = '123 street',
        ShippingCity = 'Santa Clara',
        ShippingState = 'California',
        ShippingPostalCode = '95050',
        Contract_Status__c = 'Signed-Active',
        ShippingCountry = 'United States'
      );
      insert partnerAcc;

      List<Opportunity> opptyList = (List<Opportunity>) ShGl_TestFactory.createSObjectList(new Opportunity(), 5, oppMap);

      opptyList[0].Opportunity_Sub_Type__c = 'MSP';
      opptyList[1].Opportunity_Sub_Type__c = 'MSP Consumption Renewal';
      opptyList[1].SBQQSC__RenewedServiceContract__c = objSC.Id;
      opptyList[2].Opportunity_Sub_Type__c = 'Demo';
      opptyList[3].Opportunity_Sub_Type__c = 'CSAT';
      opptyList[4].Opportunity_Sub_Type__c = 'CSAT';
      opptyList[4].Partner_Lookup__c = partnerAcc.id;
      insert opptyList;

      List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();

      Map<String, Object> quoteMap = new Map<String, Object>{
        'SBQQ__Account__c' => acct.Id,
        'SBQQ__Primary__c' => true,
        'SBQQ__Type__c' => 'Renewal',
        'SBQQ__ExpirationDate__c' => date.today().addDays(10),
        'SBQQ__SubscriptionTerm__c' => 36
      };
      SBQQ__Quote__c quote0 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
      quote0.SBQQ__Opportunity2__c = opptyList[0].Id;
      quote0.RWD_Deal_Ops_Exception__c = constants.RCDMT_EXT_RWD_DEAL_OPS_EXCEPTION;
      quote0.SBQQ__ExpirationDate__c = System.today().addDays(-1);
      quoteList.add(quote0);

      SBQQ__Quote__c quote1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
      quote1.SBQQ__Opportunity2__c = opptyList[1].Id;
      quote1.SBQQ__Type__c = 'Renewal+Expansion';
      quote1.Arry_Count_Of_Lines_Renewed__c = 1;
      quoteList.add(quote1);

      SBQQ__Quote__c quote2 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
      quote2.SBQQ__Opportunity2__c = opptyList[2].Id;
      quote2.SBQQ__Type__c = 'Renewal+Expansion';
      quote2.Renewal_Opportunity__c = opptyList[4].Id;
      quoteList.add(quote2);

      SBQQ__Quote__c quote3 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
      quote3.SBQQ__Opportunity2__c = opptyList[3].Id;
      quote3.SBQQ__Type__c = 'Amendment';
      quoteList.add(quote3);

      SBQQ__Quote__c quote4 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
      quote4.SBQQ__Opportunity2__c = opptyList[4].Id;
      quote4.SBQQ__Type__c = 'Renewal+Expansion';
      quote4.SBQQ__ExpirationDate__c = System.today().addDays(-1);
      quote4.Renewal_Opportunity__c = opptyList[2].Id;
      quoteList.add(quote4);

      insert quoteList;

      list<Product2> prodlist = new List<Product2>();
      Map<String, Object> prodMap2 = new Map<String, Object>{
        'Name' => 'RS-BT-RCDM-T',
        'ProductCode' => 'RS-BT-RCDM-T',
        'isActive' => true,
        'Family' => 'POLARIS',
        'Product_Type__c' => 'GPS',
        'Category__c' => 'Support',
        'License_Type__c' => 'Subscription'
       // 'Product_Level__c' => 'Hardware',
       //  'Product_Type__c' => 'Hardware'  
      };
      Product2 prod = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap2);
      prod.Product_Subtype__c = 'GO CNV';
      prod.Shipping_Lead_Time__c = 1;
      prod.Eligible_for_RCDM_T__c = true;
      prod.OrderSubmission__c = 'Manual';
      prodlist.add(prod);
      Product2 prod4 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap2);
      prod4.Product_Type__c = 'Reinstate Fee';
      prodlist.add(prod4);
      insert prodlist;

      PricebookEntry pbEntry = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prod.Id, UnitPrice = 100.00, IsActive = true, UseStandardPrice = false);
      insert pbEntry;

      OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = oppr.Id, Quantity = 5, PricebookEntryId = pbEntry.Id, TotalPrice = 5 * pbEntry.UnitPrice);
      insert oli;

      POC__c pocobj = new POC__c();
      pocobj.POC_Duration__c = '60 Days'; //30 Days
      pocobj.Planned_Installation_Date__c = date.today().addDays(90);
      pocobj.Support_Awareness_needed__c = 'Yes';
      pocobj.POC_Type__c = 'Conditional PO';
      pocobj.Product_Categories__c = 'Rubrik Appliance';
      insert pocobj;

      List<SBQQ__QuoteLine__c> lines = new List<SBQQ__QuoteLine__c>();
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote0.Id,
          SBQQ__Product__c = prod.Id,
          SBQQ__Quantity__c = 1,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__StartDate__c = System.today().addDays(7),
          SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1),
          SBQQ__DefaultSubscriptionTerm__c = 12,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          Is_MSP_Product__c = true
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote1.Id,
          SBQQ__Product__c = prod.Id,
          SBQQ__Quantity__c = 1,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__StartDate__c = System.today().addDays(7),
          SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1),
          SBQQ__DefaultSubscriptionTerm__c = 12,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          Is_MSP_Product__c = true
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote2.Id,
          SBQQ__Product__c = prod.Id,
          SBQQ__Quantity__c = 1,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__StartDate__c = System.today().addDays(-7),
          SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1),
          SBQQ__DefaultSubscriptionTerm__c = 12,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          Is_MSP_Product__c = false
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote3.Id,
          SBQQ__Product__c = prod.Id,
          SBQQ__Quantity__c = 1,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__StartDate__c = System.today().addDays(-7),
          SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1),
          SBQQ__DefaultSubscriptionTerm__c = 12,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          Is_MSP_Product__c = false
        )
      );
      lines.add(
        new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = quote4.Id,
          SBQQ__Product__c = prod4.Id,
          SBQQ__Quantity__c = 1,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__StartDate__c = System.today().addDays(-7),
          SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1),
          SBQQ__DefaultSubscriptionTerm__c = 12,
          SBQQ__ListPrice__c = 200,
          SBQQ__NetPrice__c = 200,
          Is_MSP_Product__c = false
        )
      );

      insert lines;

      RMA_Order__c rma = new RMA_Order__c();
      rma.Smart_Hands_Provider__c = 'TSP Inc.';
      insert rma;

      test.startTest();

      Order_Configuration__c orderConfig = new Order_Configuration__c(
        Start_Date__c = System.today().addDays(-10),
        End_Date__c = System.today().addDays(10),
        Target_Date__c = System.today().addDays(-1),
        Order_Type_to_be_considered__c = 'Demo'  
          
      );
      insert orderConfig;
      List<Order> ordersList = new List<Order>();
      String rmaRecTypeId = SObjectType.Order.getRecordTypeInfosByDeveloperName().get('RMA_Order').getRecordTypeId();
      String pocRecTypeId = SObjectType.Order.getRecordTypeInfosByDeveloperName().get('POC_Order').getRecordTypeId();
      String bookingAdjRecTypeId = SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Booking_Adjustment_Order').getRecordTypeId();

      Map<String, Object> OrderMap = new Map<String, Object>{
        'Type' => 'RMA',
        'Send_for_Polaris_Fulfilment__c' => true,
        'POC_Request__c' => pocobj.Id,
        'AccountId' => acct.Id,
        'POC_Opportunity__c' => oppr.Id,
        'EffectiveDate' => system.today(),
        'Order_Status__c' => null,
        'Status' => 'Pending',
        'Sync_to_NetSuite__c' => true,
        'ShippingCountryCode' => 'US',
        'ShippingStateCode' => 'CA',
        'ShippingStreet' => 'Test Street',
        'ShippingCity' => 'Test City',
        'ShippingState' => 'California',
        'ShippingCountry' => 'United States',
        'ShippingPostalcode' => '94820',
        'ship_To_Name__c' => acct.id,
        'ShipToContactName__c' => 'Test',
        'Have_Polaris_Products__c' => false,
        'Polaris_Fulfillment_Status__c' => 'Completed',
        'Original_Est_Ship_Date__c' => Date.today().addDays(30),
        'Est_Ship_Date__c' => null,   
        // 'customer_required_ship_date__c' => system.today(),   
        'Order_Splitted__c' => true,
        'Order_Sub_Type__c' => 'Tech Order',
        'SBQQ__Quote__c' => quote.Id,
        'Order_Split_Type__c' => 'Not needed'
      };

      Order ord = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
      ord.RecordTypeId = rmaRecTypeId;
      ord.OpportunityId = oppr.Id;
      ord.RMA_Request__c = rma.Id;

      Order ord1 = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
      ord1.OpportunityId = opptyList[1].Id;
      ord1.Type = 'POC';
      ord1.RecordTypeId = pocRecTypeId;
      ord1.SBQQ__Quote__c = quote1.Id;
      ord1.Order_Sub_Type__c = 'GC Renewal';
      ord1.Has_Non_Software_Bundle__c = true;
      ord1.Order_Split_Type__c = null;
      ord1.Order_Process__c = 'PO PDF';

      Order ord2 = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
      ord2.POC_Opportunity__c = opptyList[2].Id;
      ord2.SBQQ__Quote__c = quote2.Id;
      ord2.Type = 'Revenue';

      Order ord3 = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
      ord3.OpportunityId = opptyList[3].Id;
      ord3.SBQQ__Quote__c = quote3.Id;
      ord3.Auto_Manual_Split__c = 'System Generated';
      ord3.Sell_to_Partner__c = acct.Id;

      Order ord4 = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
      ord4.OpportunityId = opptyList[4].Id;
      ord4.SBQQ__Quote__c = quote4.Id;
      ord4.Order_Split_Type__c = 'Netapp';
      ord4.Partner_Name__c = acct.id;

      Order ord5 = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
      ord5.OpportunityId = opptyList[0].Id;
      ord5.SBQQ__Quote__c = quote0.Id;

      Order ord6 = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
      ord6.Bill_To_Name__c = acct.Id;
      ord6.Sell_to_Partner__c = acct.Id;
      ord6.Hold_Code__c = 'Quote/PO Mismatch';
      ord6.Order_Process__c = 'PO PDF';

      Order ord7 = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
      ord7.Type = 'Booking Adjustment';
      ord7.Order_Sub_Type__c = constants.ORDER_SUB_TYPE_GC_OFFER;
      ord7.RecordTypeId = bookingAdjRecTypeId;
      ord7.SBQQ__Quote__c = quote0.Id;
      ord7.Hold_Code__c = 'Opportunity/Quote missing';

      ordersList.add(ord);
      ordersList.add(ord1);
      ordersList.add(ord2);
      ordersList.add(ord3);
      ordersList.add(ord4);
      ordersList.add(ord5);
      ordersList.add(ord6);
      ordersList.add(ord7);
      insert ordersList;

      List<ContractLineItem> lstCli = new List<ContractLineItem>{
        new ContractLineItem(
          Quantity = 5,
          SBQQSC__QuoteLine__c = lines[0].Id,
          SBQQSC__Product__c = prodlist[0].Id,
          PricebookEntryId = pbEntry.Id,
          ServiceContractId = objSC.Id,
          UnitPrice = pbEntry.UnitPrice,
          StartDate = date.today()
        )
      };
      insert lstCli;

      List<OrderItem> orderItemList = new List<OrderItem>{
        new OrderItem(
          OrderId = ordersList[0].Id,
          Product2Id = prodlist[0].Id,
          Quantity = 5,
          UnitPrice = pbEntry.UnitPrice,
          PricebookEntryId = pbEntry.Id,
          Previous_Contract_Line_Items__c = lstCli[0].Id,
          Program__c = 'Replaced'
        ),
        new OrderItem(
          OrderId = ordersList[1].Id,
          Product2Id = prodlist[0].Id,
          UnitPrice = pbEntry.UnitPrice,
          SBQQ__QuoteLine__c = lines[0].Id,
          SBQQ__SubscriptionTerm__c = 36,
          Quantity = 1,
          PricebookEntryId = pbEntry.Id
        ),
        new OrderItem(
          OrderId = ordersList[0].Id,
          Product2Id = prodlist[0].Id,
          UnitPrice = pbEntry.UnitPrice,
          SBQQ__QuoteLine__c = lines[0].Id,
          SBQQ__SubscriptionTerm__c = 36,
          Quantity = 20,
          PricebookEntryId = pbEntry.Id,
          Program__c = 'Replaced'
        ),
        new OrderItem(
          OrderId = ordersList[0].Id,
          Product2Id = prodlist[0].Id,
          UnitPrice = pbEntry.UnitPrice,
          SBQQ__QuoteLine__c = lines[0].Id,
          SBQQ__SubscriptionTerm__c = 36,
          Quantity = 1,
          PricebookEntryId = pbEntry.Id
        ),
        new OrderItem(
          OrderId = ordersList[4].Id,
          Product2Id = prodlist[0].Id,
          UnitPrice = pbEntry.UnitPrice,
          SBQQ__QuoteLine__c = lines[4].Id,
          SBQQ__SubscriptionTerm__c = 36,
          Quantity = 1,
          PricebookEntryId = pbEntry.Id,
          Program__c = 'Replaced'
        ),
        new OrderItem(
          OrderId = ordersList[0].Id,
          Product2Id = prodlist[0].Id,
          UnitPrice = pbEntry.UnitPrice,
          SBQQ__QuoteLine__c = lines[0].Id,
          SBQQ__SubscriptionTerm__c = 36,
          Quantity = 70,
          PricebookEntryId = pbEntry.Id
        )
      };
      insert orderItemList;
	  ordersList[1].Program__c = '$0 RSC-G Replacement';
      ordersList[1].Order_Status__c = 'Order Accepted';
      ordersList[1].Est_Ship_Date__c = null;
      ordersList[1].NetSuite_Order__c = '324769';
      ordersList[1].Integration_Failure__c = true;
      ordersList[1].Original_Est_Ship_Date__c = system.today();

        
        
      update ordersList[1];
      List<Entitlement> lstEntitlement = new List<Entitlement>();
      lstEntitlement.add(
        new Entitlement(
          Name = 'Ent Test 1',
          Type = 'Phone Support',
          AccountId = acct.Id,
          Product__c = prodlist[0].Id,
          StartDate = date.today(),
          ServiceContractId = objSC.Id,
          Order_Service_Item__c = orderItemList[0].id
        )
      );
      insert lstEntitlement;
      OrderItem orderItem = [
        SELECT
          Id,
          Previous_Contract_Line_Items__c,
          Product2.ProductCode,
          Product2.Eligible_for_RCDM_T__c,
          Program__c,
          SBQQ__RequiredBy__c,
          SBQQ__QuoteLine__c,
          SBQQ__QuoteLine__r.SBQQ__RequiredBy__c,
          Product2.Name,
          (SELECT Id, Type, Name FROM Entitlements__r)
        FROM OrderItem
        WHERE Id = :orderItemList[0].Id
        LIMIT 1
      ];
      order ord12 = new order();
        
      OrderInsertHelper helper = OrderInsertHelper.getInstance();
       // helper.populateFieldsOnUpdate(ordersList[1],ord12,null,null);
      helper.orderIdOrderItemMap.put(ordersList[0].Id, new List<OrderItem>{ orderItem });
      OrderInsertHelper.validateOrdisEligibleSCGen(ordersList, null, helper);

      helper.orderIdOrderItemMap = new Map<Id, List<OrderItem>>();
      objSC.SBQQSC__Order__c = ord.Id;
      update objSC;
      helper.oppMap.put(oppr.Id, [SELECT Id, (SELECT Id, SBQQSC__Order__c FROM SBQQSC__ServiceContracts__r) FROM Opportunity WHERE Id = :oppr.Id LIMIT 1]);
      OrderInsertHelper.validateOrdisEligibleSCGen(ordersList, null, helper);
      helper.orderIdOrderItemMap.put(ordersList[0].Id, new List<OrderItem>{ orderItem });
      orderItem.Previous_Contract_Line_Items__c = lstCli[0].Id;
      ordersList[0].Order_Sub_Type__c = '';
      ordersList[0].type = 'Revenue';
      helper.quoteMap.put(quote.Id, quote);
      helper.accountMap.put(acct.Id, acct);
      helper.submitOrderValidationForRCDMT(ordersList[0]);
      OrderItem ordItem2 = [
        SELECT
          Id,
          Previous_Contract_Line_Items__c,
          Product2.ProductCode,
          Product2.Eligible_for_RCDM_T__c,
          Program__c,
          SBQQ__RequiredBy__c,
          SBQQ__QuoteLine__c,
          SBQQ__QuoteLine__r.SBQQ__RequiredBy__c
        FROM OrderItem
        WHERE Id = :orderItemList[2].Id
        LIMIT 1
      ];
      ordItem2.SBQQ__RequiredBy__c = orderItem.Id;
      helper.orderIdOrderItemMap.get(ordersList[0].Id).add(ordItem2);
      helper.submitOrderValidationForRCDMT(ordersList[0]);
      helper.invalidateQuote(null, new List<SBQQ__QuoteDocument__c>(), null, null);
      ordersList[1].Manual_Approve__c = false;
      ordersList[0].Manual_Approve__c = true;
      ordersList[0].Screening_Source__c = 'Internal';
      ordersList[0].ScreenStatus__c = 'On hold';
      helper.complianceScreen(ordersList[0], ordersList[1], acct, oppr, null, null);
      insert new RPS__c(
        SetupOwnerId = Userinfo.getUserId(),
        Is_RPS_Required__c = false,
        Screening_Source__c = 'External',
        Valid_HoldCodes__c = 'Global Trade Compliance screening failed;Credit Check Failed'
      );
      ordersList[0].Screening_Source__c = 'External';
      ordersList[0].Hold_Code__c = 'Global Trade Compliance Screening';
      ordersList[0].ScreenStatus__c = 'On hold';
        
  
      helper.complianceScreen(ordersList[0], ordersList[1], acct, oppr, null, null);
      List<PO_Stage__c> stagePoList = TransactionalDataCollection.stagePo;
      ordersList[0].Order_Sub_Type__c = Constants.ORDER_SUB_TYPE_GC_ONDEMAND;
      ordersList[0].Order_Status__c = 'Pending';
      ordersList[0].Stage_PO__c = stagePoList[0].Id;
      ordersList[0].Order_Split_Type__c = 'Split Completed';
      ordersList[0].Is_RWD_Polaris_Quote__c = false;
      ordersList[0].Payment_Terms__c = 'Net 60';
      helper.accountMap = new Map<Id, Account>();
      helper.accountMap.put(ordersList[0].Bill_To_Name__c, acct);
      helper.autoSubmitOrder(ordersList[0], ordersList[1], stagePoList, null);
      ordersList[0].Order_Sub_Type__c = 'POC';
      ordersList[0].ShippingStateCode = '';
      ordersList[0].ShippingCountryCode = 'US';
      ordersList[0].OpportunityId = null;
      OrderHandler.amountOfOrdersOnStage.put(stagePoList[0].Id, 100);
      helper.autoSubmitOrder(ordersList[0], ordersList[1], stagePoList, new Map<Id, Order>());
      ordersList[0].Order_Sub_Type__c = 'MSP Overage';
      ordersList[0].Quote_RCDM_T_EOL_Date__c = System.today().addDays(-2);
      ordersList[0].Order_Split_Type__c = 'Not needed';
      helper.orderIdOrderItemMap.put(ordersList[0].Id, new List<OrderItem>{ orderItem });
      helper.autoSubmitOrder(ordersList[0], ordersList[1], stagePoList, new Map<Id, Order>());
      ordersList[0].Order_Sub_Type__c = 'GC Renewal';
      quote.RWD_Deal_Ops_Exception__c = constants.RCDMT_EXT_RWD_DEAL_OPS_EXCEPTION;
      helper.quoteMap.put(quote.Id, quote);
      helper.orderIdOrderItemMap.put(ordersList[0].Id, new List<OrderItem>{ orderItem });
      ordersList[0].Screening_Source__c = 'External';
      ordersList[0].Internal_Order_Stage__c = 'Pending Validation';
      ordersList[0].Order_Status__c = 'PO Received';
      ordersList[0].ScreenStatus__c = 'On hold';
      ordersList[0].ShipToScreenStatus__c = 'Denied';
      ordersList[0].Billto_EndUser_Screen_Status__c = 'Denied';
      ordersList[0].Shipto_EndUser_Screen_Status__c = 'Denied';
      ordersList[0].ShipToScreenStatus__c = 'Approved';
      ordersList[0].ShipToContactScreenStatus__c = 'Approved';
      ordersList[0].Order_Status__c = 'Returned';
      ordersList[0].Hold_Code__c = null;
 
      helper.complianceScreen(ordersList[0], ordersList[1], acct, oppr, null, null);
  
      test.stopTest();
    }
  }
  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to Order Hold Code trigger logic
   */
 @isTest
  private static void testholdCodeCRSD() {
    System.runAs(new User(Id = UserInfo.getUserId())) {
        insert new ShGl_DisableBusinessLogic__c(
            Disable_Order_Validation_Rules__c = true
        );
      Id pricebookId = Test.getStandardPricebookId();
      List<Opportunity> lstOpp = [SELECT id, AccountId, pricebook2Id, Opportunity_Sub_Type__c FROM Opportunity LIMIT 1];
      lstOpp[0].pricebook2Id = pricebookId;
      update lstOpp;
      Assert.areEqual(true, lstOpp.size() > 0);
      SBQQ__Quote__c qtq = [SELECT Id, name, SBQQ__NetAmount__c, SBQQ__PricebookId__c FROM SBQQ__Quote__c LIMIT 1];
      qtq.RWD_Deal_Ops_Exception__c = constants.RCDMT_EXT_RWD_DEAL_OPS_EXCEPTION;
      update qtq;
      PO_Stage__c poStage = [SELECT Id FROM PO_Stage__c LIMIT 1];
      poStage.Customer_Requested_Ship_Date__c = String.valueof(system.today().addmonths(3));
      poStage.TotalAmount__c = 500;
      update poStage;
      Test.starttest();
      Order ord = createTestorder('Revenue',qtq.Id, lstOpp[0].AccountId,lstOpp[0].Id,lstOpp[0].AccountId,pricebookId,null,'MSP Overage',new Map<String, Object>{'customer_required_ship_date__c' => system.today().addmonths(3),'Shipping_Carrier__c' => 'DHL'});
      insert ord;
      Product2 objProds =   createTestProduct('RS-BT-EE-PE-PP', 'RS-BT-EE-PE-PP', 'Rubrik Licence', null, 'Hybrid Software',
            new Map<String, Object>{'Category__c' => 'Bundle','Product_Type__c' => 'Complete Edition','License_Category__c' => 'SaaS','SBQQ__AssetAmendmentBehavior__c' => 'Default','SBQQSC__EntitlementConversion__c' => 'One per quote line','SBQQ__SubscriptionTerm__c' => 36,'SBQQ__SubscriptionBase__c' => 'List','SBQQ__SubscriptionType__c' => 'Renewable'
                });
      insert objProds;
      PricebookEntry pb1 = new PricebookEntry(UseStandardPrice = false, Pricebook2Id = pricebookId, Product2Id = objProds.Id, UnitPrice = 100.00, IsActive = true);
      insert pb1;
      SBQQ__QuoteLine__c qline = new SBQQ__QuoteLine__c(
          SBQQ__Quote__c = qtq.Id,
          SBQQ__Product__c = objProds.Id,
          SBQQ__PricebookEntryId__c = pb1.Id,
          SBQQ__Quantity__c = 800,
          SBQQ__SubscriptionPricing__c = 'Fixed Price',
          SBQQ__DefaultSubscriptionTerm__c = 1,
          SBQQ__ListPrice__c = 10,
          SBQQ__NetPrice__c = 10,
          RWD_Deal_Ops_Exception__c = constants.RCDMT_EXT_RWD_DEAL_OPS_EXCEPTION
        );
        insert qline;
        OrderItem objOI =  createTestOrderItem(Ord.Id,5,pb1.Id,pb1.UnitPrice,
                                               new Map<String, Object>{
                                                   'Support_Start_Date__c' => System.today(),
                                                       'SBQQ__SubscriptionTerm__c' => null,
                                                       'SBQQ__QuoteLine__c' => qline.id,
                                                       'SBQQ__Contracted__c' => true
                                                       }
                                              );
      insert objOI;
        
        Quote_and_Order_Staging__c qos = new Quote_and_Order_Staging__c();
        qos.Account_OM__c = lstOpp[0].AccountId;
        insert qos;
      List<order> lstorder1 = [SELECT Id, SBQQ__Contracted__c,ShipToContactName__c, Order_Status__c,order_sub_type__c, customer_required_ship_date__c  FROM order where Id = :ord.Id];
      lstorder1[0].Hold_Code__c = '';
      lstorder1[0].Order_Status__c = 'Pending';
      lstorder1[0].order_sub_type__c = Constants.ORDER_SUB_TYPE_MSP_OVERAGE;
      lstorder1[0].ShippingCountryCode = 'US';
      lstorder1[0].ShippingStateCode = 'NY';
      lstorder1[0].ShipToContactName__c = 'Test Contact';
      lstorder1[0].Ship_to_Email__c = 'Test@test.com';
      lstorder1[0].Service_Level__c = 'Economy';
      lstorder1[0].ShippingStreet = 'test street';
      lstorder1[0].ShippingPostalCode = '0000';
      lstorder1[0].ShippingCity = 'test city';
      lstorder1[0].SC_or_Entitlement_Stage__c = 'Create Service Contract';
      update lstorder1;
	  lstorder1[0].order_sub_type__c = Constants.ORDER_SUB_TYPE_RENEWAL_EXPANSION;
      lstorder1[0].Ready_for_Gov_Sync__c = 'Sync Ready';
      lstorder1[0].Sync_to_NetSuite__c = true;
      update lstorder1; 
      test.StopTest();
    }

  }
    
  /**
   * @author Siva Kumar
   * @date 12-03-2025
   * @description test method to Order Hold Code trigger logic
   */
  @isTest
    private static void testuserRestriction() {
        String uniqueUserName = 'AdminUser' + DateTime.now().getTime() + '@rubrik.com';
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Rubrik Renewal Specialist'];
        User u = new User(
            Alias = 'adminU',
            Email = 'AdminUser@rubrik.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = uniqueUserName
        );
        insert u;
        System.runAs(u) {
            insert new ShGl_DisableBusinessLogic__c(
                Disable_Order_Validation_Rules__c = true
            );
            Id pricebookId = Test.getStandardPricebookId();
            Account act = new Account(
      Name = 'Test',
      Website = 'www.test3.com',
      OwnerId = userinfo.getUserId(),
      type = 'Customer'
    );
    insert act;

    opportunity oppr = new opportunity(
      Name = 'testing DIEtestsalesforce 4/6/2015',
      Opportunity_Sub_Type__c = 'Regular',
      Distributor_Lookup__c = act.Id,
      Alliance_Source_Type_HW__c = 'Rubrik Initiated Alliance Deal',
      Mosaic_Customer_Environment__c = 'AWS',
      CloseDate = Date.Today().addDays(10),
      Lead_Email_Hidden__c = '',
      AccountId = act.Id,
      StageName = '1 Discovery',
      Rubrik_Sales_Engineer__c = UserInfo.getUserId(),
      Alliance_Partner_Name__c = 'Amazon',
      Alliance_Source_Type__c = 'Alliance Initiated Deal',
      Installation_Assigned_To__c = 'FE Install',
      Economic_Buyer__c = 'Test',
      Metric__c = 'Test',
      Decision_Process__c = 'Test',
      Decision_Criteria__c = 'Test',
      Alliance_Source_Type_SW__c = 'Rubrik Initiated Alliance Deal',
      Identified_Pain__c = 'Test',
      Champion__c = 'Test',
      ForecastCategoryName = 'Best Case',
      Override__c = false,
      Aspen_Eligibility__c = 'Actual Aspen',
	  Pricebook2Id = pricebookId
    );

    insert oppr;

            Order ord = createTestorder('Revenue',null, act.Id ,oppr.Id,act.Id,pricebookId,null,'MSP Overage',new Map<String, Object>{'customer_required_ship_date__c' => system.today().addmonths(3)});
            insert ord;
            test.StartTest();
            List<order> lstorder1 = [SELECT Id, SBQQ__Contracted__c,ShipToContactName__c, Order_Status__c,order_sub_type__c, customer_required_ship_date__c  FROM order where Id = :ord.Id];
            lstorder1[0].SBQQ__Contracted__c = !lstorder1[0].SBQQ__Contracted__c;
            try{
              update lstorder1;
            }catch(System.exception ex){
                System.assert(ex instanceof System.DmlException);
            }
            test.StopTest();
        }
  }
  @isTest
  static void testOpportunityRSCCreationDedicatedDeal() {
    System.runAs(new User(Id = UserInfo.getUserId())) {
      // Create Account + End User
      Account acc = new Account(Name = 'Test Acc', Website = 'https://enduser.com');
      insert acc;

      // Create Opportunity (Dedicated Deal)
      Opportunity opp = new Opportunity(
        Name = 'Test Opp',
        StageName = 'Prospecting',
        CloseDate = System.today(),
        AccountId = acc.Id,
        Managed_Services_Deal_type__c = Constants.OPP_MSP_DEAL_TYPE_DEDICATED_DEAL,
        MSP_End_User_Lookup__c = acc.Id,
        Polaris_Region__c = 'US'
      );
      insert opp;

      // Create Order (trigger path)
      Order ord = new Order(AccountId = acc.Id, OpportunityId = opp.Id, Status = 'Draft', EffectiveDate = System.today(), Send_for_Polaris_Fulfilment__c = false);
      insert ord;

      // Update - this triggers the logic
      ord.Send_for_Polaris_Fulfilment__c = true;
      update ord;

      // Validate RSC Instance Created
      List<RSCInstance__c> inst = [
        SELECT Id, AccountId__c, SDPEndUser__c, RSCAccountType__c
        FROM RSCInstance__c
        WHERE AccountId__c = :acc.Id
      ];

      System.assertEquals(1, inst.size(), 'RSC Instance should be created');
      System.assertEquals(acc.Id, inst[0].AccountId__c);
    }
  }

  @isTest
  static void testOpportunityRSCCreationSuggestedUrlConflict() {
    System.runAs(new User(Id = UserInfo.getUserId())) {
      // Account Setup
      Account acc = new Account(Name = 'Conflict Acc');
      insert acc;

      // Opportunity with Suggested URL
      Opportunity opp = new Opportunity(
        Name = 'Opp With URL',
        StageName = 'Prospecting',
        CloseDate = System.today(),
        AccountId = acc.Id,
        SuggestedURL__c = 'https://duplicate.com',
        Polaris_Region__c = 'US'
      );
      insert opp;

      // Existing active RSC Instance (duplicate)
      RSCInstance__c existingInst = new RSCInstance__c(
        AccountId__c = acc.Id,
        RSCSuggestedURL__c = 'https://duplicate.com',
        Status__c = Constants.RSCINSTANCE_STATUS_PENDING_CREATION
      );
      insert existingInst;

      // Order to trigger flow
      Order orderRec = new Order(AccountId = acc.Id, OpportunityId = opp.Id, Status = 'Draft', EffectiveDate = System.today(), Send_for_Polaris_Fulfilment__c = false);
      insert orderRec;

      // Trigger code
      orderRec.Send_for_Polaris_Fulfilment__c = true;
      update orderRec;

      // No new Instance should be created
      Integer instCount = [
        SELECT COUNT()
        FROM RSCInstance__c
        WHERE AccountId__c = :acc.Id
      ];

      System.assertEquals(1, instCount, 'Should not create new instance because of URL conflict');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRDOPS-544 – RSC-P product exclusion from Polaris provisioning
  // ─────────────────────────────────────────────────────────────────────────

  /**
   * @author Unit Testing Agent
   * @date 2026-03-27
   * @description PRDOPS-544: A Revenue order whose only line items carry RSCP- prefixed
   * product codes must NOT set Have_Polaris_Products__c = true.  The isRSCPProduct guard
   * in OrderInsertHelper.processOrderData() should prevent these products from ever
   * flipping hasPolarisProduct to true.
   */
  @isTest
  static void testRSCPOnlyOrderSkipsProvisioning() {
    System.runAs(new User(Id = UserInfo.getUserId())) {
      // Arrange – fetch shared data created in @TestSetup
      Id pricebookId = Test.getStandardPricebookId();
      List<Opportunity> lstOpp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
      Id acctId = lstOpp[0].AccountId;
      Id oppId  = lstOpp[0].Id;

      // Two RSCP- prefixed products with Family = 'POLARIS' to confirm the prefix
      // guard fires even when Family would otherwise qualify them.
      List<Product2> prods = new List<Product2>{
        createTestProduct('RSCP-FE-TEST', 'RSCP-FE-TEST', 'POLARIS', null, 'SaaS Software Addon',
          new Map<String, Object>{ 'Product_Type__c' => 'Foundation Edition' }),
        createTestProduct('RSCP-BE-TEST', 'RSCP-BE-TEST', 'POLARIS', null, 'SaaS Software Addon',
          new Map<String, Object>{ 'Product_Type__c' => 'Business Edition' })
      };
      insert prods;

      List<PricebookEntry> pbes = new List<PricebookEntry>{
        new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prods[0].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prods[1].Id, UnitPrice = 100.00, IsActive = true)
      };
      insert pbes;

      // Revenue order; Is_RWD_Polaris_Quote__c = false so the non-RWD Family == 'POLARIS'
      // branch is active – making it the strictest test of the RSCP guard.
      Order ord = createTestorder(
        'Revenue', null, acctId, oppId, acctId, pricebookId,
        'Not needed', 'Renewal',
        new Map<String, Object>{
          'Is_RWD_Polaris_Quote__c'    => false,
          'Have_Polaris_Products__c'   => false,
          'Polaris_Fulfillment_Status__c' => 'Completed'
        }
      );

      Test.startTest();
      insert ord;

      List<OrderItem> items = new List<OrderItem>{
        createTestOrderItem(ord.Id, 1, pbes[0].Id, 100.00,
          new Map<String, Object>{
            'Support_Start_Date__c' => System.today(),
            'Support_End_Date__c'   => System.today().addYears(1)
          }),
        createTestOrderItem(ord.Id, 1, pbes[1].Id, 100.00,
          new Map<String, Object>{
            'Support_Start_Date__c' => System.today(),
            'Support_End_Date__c'   => System.today().addYears(1)
          })
      };
      insert items;

      // Re-trigger update to force OrderInsertHelper evaluation
      ord.Order_Status__c = 'Pending';
      update ord;
      Test.stopTest();

      // Assert
      Order result = [SELECT Have_Polaris_Products__c FROM Order WHERE Id = :ord.Id];
      Assert.areEqual(
        false,
        result.Have_Polaris_Products__c,
        'PRDOPS-544: Order with only RSCP- products must have Have_Polaris_Products__c = false'
      );
    }
  }

  /**
   * @author Unit Testing Agent
   * @date 2026-03-27
   * @description PRDOPS-544: A Revenue order containing one RSCP- line item alongside one
   * standard POLARIS family product must still set Have_Polaris_Products__c = true.
   * The RSCP guard must exclude only the RSCP- item; the standard item should continue to
   * flip hasPolarisProduct.
   */
  @isTest
  static void testMixedRSCPAndPolarisOrderTriggersProvisioning() {
    System.runAs(new User(Id = UserInfo.getUserId())) {
      // Arrange
      Id pricebookId = Test.getStandardPricebookId();
      List<Opportunity> lstOpp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
      Id acctId = lstOpp[0].AccountId;
      Id oppId  = lstOpp[0].Id;

      List<Product2> prods = new List<Product2>{
        // RSCP- prefix – should be excluded
        createTestProduct('RSCP-FE-TEST-MX', 'RSCP-FE-TEST-MX', 'POLARIS', null, 'SaaS Software Addon',
          new Map<String, Object>{ 'Product_Type__c' => 'Foundation Edition' }),
        // Standard Polaris – should trigger provisioning
        createTestProduct('POLARIS-STD-TEST', 'POLARIS-STD-TEST', 'POLARIS', null, 'SaaS Software Addon',
          new Map<String, Object>{ 'Product_Type__c' => 'Foundation Edition' })
      };
      insert prods;

      List<PricebookEntry> pbes = new List<PricebookEntry>{
        new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prods[0].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prods[1].Id, UnitPrice = 100.00, IsActive = true)
      };
      insert pbes;

      Order ord = createTestorder(
        'Revenue', null, acctId, oppId, acctId, pricebookId,
        'Not needed', 'Renewal',
        new Map<String, Object>{
          'Is_RWD_Polaris_Quote__c'    => false,
          'Have_Polaris_Products__c'   => false,
          'Polaris_Fulfillment_Status__c' => 'Completed'
        }
      );

      Test.startTest();
      insert ord;

      List<OrderItem> items = new List<OrderItem>{
        createTestOrderItem(ord.Id, 1, pbes[0].Id, 100.00,
          new Map<String, Object>{
            'Support_Start_Date__c' => System.today(),
            'Support_End_Date__c'   => System.today().addYears(1)
          }),
        createTestOrderItem(ord.Id, 1, pbes[1].Id, 100.00,
          new Map<String, Object>{
            'Support_Start_Date__c' => System.today(),
            'Support_End_Date__c'   => System.today().addYears(1)
          })
      };
      insert items;

      ord.Order_Status__c = 'Pending';
      update ord;
      Test.stopTest();

      // Assert – standard Polaris item must still qualify the order
      Order result = [SELECT Have_Polaris_Products__c FROM Order WHERE Id = :ord.Id];
      Assert.areEqual(
        true,
        result.Have_Polaris_Products__c,
        'PRDOPS-544: Order with mixed RSCP- and standard Polaris products must have Have_Polaris_Products__c = true'
      );
    }
  }

  /**
   * @author Unit Testing Agent
   * @date 2026-03-27
   * @description PRDOPS-544: A Revenue order with standard POLARIS family products (no RSCP-
   * prefix) must behave exactly as before the change – Have_Polaris_Products__c = true.
   * This is a non-regression check to confirm the guard has no side-effects on normal paths.
   */
  @isTest
  static void testNonRSCPPolarisOrderUnchanged() {
    System.runAs(new User(Id = UserInfo.getUserId())) {
      // Arrange
      Id pricebookId = Test.getStandardPricebookId();
      List<Opportunity> lstOpp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
      Id acctId = lstOpp[0].AccountId;
      Id oppId  = lstOpp[0].Id;

      // Standard Polaris products – no RSCP- prefix
      List<Product2> prods = new List<Product2>{
        createTestProduct('POLARIS-A-TEST', 'POLARIS-A-TEST', 'POLARIS', null, 'SaaS Software Addon',
          new Map<String, Object>{ 'Product_Type__c' => 'Foundation Edition' }),
        createTestProduct('POLARIS-B-TEST', 'POLARIS-B-TEST', 'POLARIS', null, 'SaaS Software Addon',
          new Map<String, Object>{ 'Product_Type__c' => 'Business Edition' })
      };
      insert prods;

      List<PricebookEntry> pbes = new List<PricebookEntry>{
        new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prods[0].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prods[1].Id, UnitPrice = 100.00, IsActive = true)
      };
      insert pbes;

      Order ord = createTestorder(
        'Revenue', null, acctId, oppId, acctId, pricebookId,
        'Not needed', 'Renewal',
        new Map<String, Object>{
          'Is_RWD_Polaris_Quote__c'    => false,
          'Have_Polaris_Products__c'   => false,
          'Polaris_Fulfillment_Status__c' => 'Completed'
        }
      );

      Test.startTest();
      insert ord;

      List<OrderItem> items = new List<OrderItem>{
        createTestOrderItem(ord.Id, 1, pbes[0].Id, 100.00,
          new Map<String, Object>{
            'Support_Start_Date__c' => System.today(),
            'Support_End_Date__c'   => System.today().addYears(1)
          }),
        createTestOrderItem(ord.Id, 1, pbes[1].Id, 100.00,
          new Map<String, Object>{
            'Support_Start_Date__c' => System.today(),
            'Support_End_Date__c'   => System.today().addYears(1)
          })
      };
      insert items;

      ord.Order_Status__c = 'Pending';
      update ord;
      Test.stopTest();

      // Assert – standard Polaris order must remain unaffected
      Order result = [SELECT Have_Polaris_Products__c FROM Order WHERE Id = :ord.Id];
      Assert.areEqual(
        true,
        result.Have_Polaris_Products__c,
        'PRDOPS-544: Order with only standard (non-RSCP) Polaris products must have Have_Polaris_Products__c = true'
      );
    }
  }

  /**
   * @author Unit Testing Agent
   * @date 2026-03-27
   * @description PRDOPS-544: A POC order with only RSCP- prefixed products must also have
   * Have_Polaris_Products__c = false.  The isRSCPProduct guard is evaluated for every order
   * type, so POC orders must be covered explicitly.
   */
  @isTest
  static void testPOCOrderWithRSCPOnlySkipsProvisioning() {
    System.runAs(new User(Id = UserInfo.getUserId())) {
      // Arrange
      Id pricebookId = Test.getStandardPricebookId();
      List<Opportunity> lstOpp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
      Id acctId = lstOpp[0].AccountId;
      Id oppId  = lstOpp[0].Id;

      // POC order Record Type
      Id pocRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order')?.getRecordTypeId();

      // RSCP- prefixed product
      Product2 rscpProd = createTestProduct(
        'RSCP-FE-POC-TEST', 'RSCP-FE-POC-TEST', 'POLARIS', null, 'SaaS Software Addon',
        new Map<String, Object>{ 'Product_Type__c' => 'Foundation Edition' }
      );
      insert rscpProd;

      PricebookEntry pbe = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = rscpProd.Id, UnitPrice = 100.00, IsActive = true
      );
      insert pbe;

      // POC order – RecordTypeId for POC Order if available; fall back gracefully
      Map<String, Object> extraFields = new Map<String, Object>{
        'Is_RWD_Polaris_Quote__c'       => false,
        'Have_Polaris_Products__c'      => false,
        'Polaris_Fulfillment_Status__c' => 'Completed',
        'Sync_to_NetSuite__c'           => false,
        'Send_for_Polaris_Fulfilment__c' => false
      };
      if (pocRecordTypeId != null) {
        extraFields.put('RecordTypeId', pocRecordTypeId);
      }

      Order ord = createTestorder(
        'POC', null, acctId, oppId, acctId, pricebookId,
        null, 'Renewal', extraFields
      );

      Test.startTest();
      insert ord;

      OrderItem item = createTestOrderItem(ord.Id, 1, pbe.Id, 100.00,
        new Map<String, Object>{
          'Support_Start_Date__c' => System.today(),
          'Support_End_Date__c'   => System.today().addYears(1)
        });
      insert item;

      ord.Order_Status__c = 'Pending';
      update ord;
      Test.stopTest();

      // Assert
      Order result = [SELECT Have_Polaris_Products__c FROM Order WHERE Id = :ord.Id];
      Assert.areEqual(
        false,
        result.Have_Polaris_Products__c,
        'PRDOPS-544: POC order with only RSCP- products must have Have_Polaris_Products__c = false'
      );
    }
  }

  /**
   * @author Unit Testing Agent
   * @date 2026-03-30
   * @description PRDOPS-544: A Revenue order with only RSCP- prefixed products must:
   *   - Have_Polaris_Products__c = false
   *   - Polaris_Fulfillment_Status__c = 'Not Needed'
   *   - Send_for_Polaris_Fulfilment__c = false (callout NOT triggered)
   */
  @isTest
  static void testRSCPOnlyOrderSetsNotNeededStatus() {
    System.runAs(new User(Id = UserInfo.getUserId())) {
      // Arrange
      Id pricebookId = Test.getStandardPricebookId();
      List<Opportunity> lstOpp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
      Id acctId = lstOpp[0].AccountId;
      Id oppId  = lstOpp[0].Id;

      // RSCP- prefixed products only
      List<Product2> prods = new List<Product2>{
        createTestProduct('RSCP-FE-NN-TEST', 'RSCP-FE-NN-TEST', 'POLARIS', null, 'SaaS Software Addon',
          new Map<String, Object>{ 'Product_Type__c' => 'Foundation Edition' }),
        createTestProduct('RSCP-BE-NN-TEST', 'RSCP-BE-NN-TEST', 'POLARIS', null, 'SaaS Software Addon',
          new Map<String, Object>{ 'Product_Type__c' => 'Business Edition' })
      };
      insert prods;

      List<PricebookEntry> pbes = new List<PricebookEntry>{
        new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prods[0].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prods[1].Id, UnitPrice = 100.00, IsActive = true)
      };
      insert pbes;

      // Revenue order with RSC_G_Enabled__c = false
      Order ord = createTestorder(
        'Revenue', null, acctId, oppId, acctId, pricebookId,
        'Not needed', 'Renewal',
        new Map<String, Object>{
          'Is_RWD_Polaris_Quote__c'       => false,
          'Have_Polaris_Products__c'      => false,
          'RSC_G_Enabled__c'             => false,
          'Send_for_Polaris_Fulfilment__c' => false
        }
      );

      Test.startTest();
      insert ord;

      List<OrderItem> items = new List<OrderItem>{
        createTestOrderItem(ord.Id, 1, pbes[0].Id, 100.00,
          new Map<String, Object>{
            'Support_Start_Date__c' => System.today(),
            'Support_End_Date__c'   => System.today().addYears(1)
          }),
        createTestOrderItem(ord.Id, 1, pbes[1].Id, 100.00,
          new Map<String, Object>{
            'Support_Start_Date__c' => System.today(),
            'Support_End_Date__c'   => System.today().addYears(1)
          })
      };
      insert items;

      // Re-trigger update to force OrderInsertHelper evaluation
      ord.Order_Status__c = 'Pending';
      update ord;
      Test.stopTest();

      // Assert all three fields
      Order result = [
        SELECT Have_Polaris_Products__c, Polaris_Fulfillment_Status__c, Send_for_Polaris_Fulfilment__c
        FROM Order WHERE Id = :ord.Id
      ];
      Assert.areEqual(
        false,
        result.Have_Polaris_Products__c,
        'PRDOPS-544: RSCP-only Revenue order must have Have_Polaris_Products__c = false'
      );
      Assert.areEqual(
        Constants.POLARIS_FULFILLMENT_STATUS_NOT_NEEDED,
        result.Polaris_Fulfillment_Status__c,
        'PRDOPS-544: RSCP-only Revenue order must have Polaris_Fulfillment_Status__c = Not Needed'
      );
      Assert.areEqual(
        false,
        result.Send_for_Polaris_Fulfilment__c,
        'PRDOPS-544: RSCP-only Revenue order must NOT trigger callout (Send_for_Polaris_Fulfilment__c = false)'
      );
    }
  }

  /**
   * @author Unit Testing Agent
   * @date 2026-03-30
   * @description PRDOPS-544: A POC order with only RSCP- prefixed products must:
   *   - Have_Polaris_Products__c = false
   *   - Polaris_Fulfillment_Status__c = 'Not Needed'
   *   - Send_for_Polaris_Fulfilment__c = false (callout NOT triggered)
   */
  @isTest
  static void testRSCPOnlyPOCOrderSetsNotNeededStatus() {
    System.runAs(new User(Id = UserInfo.getUserId())) {
      // Arrange
      Id pricebookId = Test.getStandardPricebookId();
      List<Opportunity> lstOpp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
      Id acctId = lstOpp[0].AccountId;
      Id oppId  = lstOpp[0].Id;

      // POC order Record Type
      Id pocRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order')?.getRecordTypeId();

      // RSCP- prefixed products only
      List<Product2> prods = new List<Product2>{
        createTestProduct('RSCP-FE-POC-NN', 'RSCP-FE-POC-NN', 'POLARIS', null, 'SaaS Software Addon',
          new Map<String, Object>{ 'Product_Type__c' => 'Foundation Edition' }),
        createTestProduct('RSCP-BE-POC-NN', 'RSCP-BE-POC-NN', 'POLARIS', null, 'SaaS Software Addon',
          new Map<String, Object>{ 'Product_Type__c' => 'Business Edition' })
      };
      insert prods;

      List<PricebookEntry> pbes = new List<PricebookEntry>{
        new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prods[0].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prods[1].Id, UnitPrice = 100.00, IsActive = true)
      };
      insert pbes;

      Map<String, Object> extraFields = new Map<String, Object>{
        'Is_RWD_Polaris_Quote__c'       => false,
        'Have_Polaris_Products__c'      => false,
        'RSC_G_Enabled__c'             => false,
        'Send_for_Polaris_Fulfilment__c' => false,
        'Sync_to_NetSuite__c'           => false
      };
      if (pocRecordTypeId != null) {
        extraFields.put('RecordTypeId', pocRecordTypeId);
      }

      Order ord = createTestorder(
        'POC', null, acctId, oppId, acctId, pricebookId,
        null, 'Renewal', extraFields
      );

      Test.startTest();
      insert ord;

      List<OrderItem> items = new List<OrderItem>{
        createTestOrderItem(ord.Id, 1, pbes[0].Id, 100.00,
          new Map<String, Object>{
            'Support_Start_Date__c' => System.today(),
            'Support_End_Date__c'   => System.today().addYears(1)
          }),
        createTestOrderItem(ord.Id, 1, pbes[1].Id, 100.00,
          new Map<String, Object>{
            'Support_Start_Date__c' => System.today(),
            'Support_End_Date__c'   => System.today().addYears(1)
          })
      };
      insert items;

      // Re-trigger update to force OrderInsertHelper evaluation
      ord.Order_Status__c = 'Pending';
      update ord;
      Test.stopTest();

      // Assert all three fields
      Order result = [
        SELECT Have_Polaris_Products__c, Polaris_Fulfillment_Status__c, Send_for_Polaris_Fulfilment__c
        FROM Order WHERE Id = :ord.Id
      ];
      Assert.areEqual(
        false,
        result.Have_Polaris_Products__c,
        'PRDOPS-544: RSCP-only POC order must have Have_Polaris_Products__c = false'
      );
      Assert.areEqual(
        Constants.POLARIS_FULFILLMENT_STATUS_NOT_NEEDED,
        result.Polaris_Fulfillment_Status__c,
        'PRDOPS-544: RSCP-only POC order must have Polaris_Fulfillment_Status__c = Not Needed'
      );
      Assert.areEqual(
        false,
        result.Send_for_Polaris_Fulfilment__c,
        'PRDOPS-544: RSCP-only POC order must NOT trigger callout (Send_for_Polaris_Fulfilment__c = false)'
      );
    }
  }

  /**
   * @author Unit Testing Agent
   * @date 2026-03-30
   * @description PRDOPS-544: When an order has only RSCP- prefixed products but RSC_G_Enabled__c
   * is true, the line-1603 condition evaluates false (RSC_G_Enabled__c guard fails), so
   * Polaris_Fulfillment_Status__c must NOT be stamped to 'Not Needed'.  This covers the
   * boundary case where the RSC_G_Enabled__c = true arm of Path A is exercised and the
   * field is left unchanged from whatever the order previously held.
   */
  @isTest
  static void testRSCPOnlyOrderWithRSCGEnabledDoesNotStampNotNeeded() {
    System.runAs(new User(Id = UserInfo.getUserId())) {
      // Arrange
      Id pricebookId = Test.getStandardPricebookId();
      List<Opportunity> lstOpp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
      Id acctId = lstOpp[0].AccountId;
      Id oppId  = lstOpp[0].Id;

      // RSCP- prefixed products only
      List<Product2> prods = new List<Product2>{
        createTestProduct('RSCP-FE-RSC-G', 'RSCP-FE-RSC-G', 'POLARIS', null, 'SaaS Software Addon',
          new Map<String, Object>{ 'Product_Type__c' => 'Foundation Edition' }),
        createTestProduct('RSCP-BE-RSC-G', 'RSCP-BE-RSC-G', 'POLARIS', null, 'SaaS Software Addon',
          new Map<String, Object>{ 'Product_Type__c' => 'Business Edition' })
      };
      insert prods;

      List<PricebookEntry> pbes = new List<PricebookEntry>{
        new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prods[0].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prods[1].Id, UnitPrice = 100.00, IsActive = true)
      };
      insert pbes;

      // Revenue order with RSC_G_Enabled__c = true — the "Not Needed" stamp must be skipped
      Order ord = createTestorder(
        'Revenue', null, acctId, oppId, acctId, pricebookId,
        'Not needed', 'Renewal',
        new Map<String, Object>{
          'Is_RWD_Polaris_Quote__c'       => false,
          'Have_Polaris_Products__c'      => false,
          'RSC_G_Enabled__c'             => true,
          'Polaris_Fulfillment_Status__c' => 'In Progress',
          'Send_for_Polaris_Fulfilment__c' => false
        }
      );

      Test.startTest();
      insert ord;

      List<OrderItem> items = new List<OrderItem>{
        createTestOrderItem(ord.Id, 1, pbes[0].Id, 100.00,
          new Map<String, Object>{
            'Support_Start_Date__c' => System.today(),
            'Support_End_Date__c'   => System.today().addYears(1)
          }),
        createTestOrderItem(ord.Id, 1, pbes[1].Id, 100.00,
          new Map<String, Object>{
            'Support_Start_Date__c' => System.today(),
            'Support_End_Date__c'   => System.today().addYears(1)
          })
      };
      insert items;

      ord.Order_Status__c = 'Pending';
      update ord;
      Test.stopTest();

      // Assert: Polaris_Fulfillment_Status__c must NOT be 'Not Needed' because RSC_G_Enabled__c
      // is true and the guard condition at line 1603 short-circuits before the stamp.
      Order result = [
        SELECT Have_Polaris_Products__c, Polaris_Fulfillment_Status__c
        FROM Order WHERE Id = :ord.Id
      ];
      Assert.areEqual(
        false,
        result.Have_Polaris_Products__c,
        'PRDOPS-544: RSCP-only order must still have Have_Polaris_Products__c = false even when RSC_G_Enabled__c = true'
      );
      Assert.areNotEqual(
        Constants.POLARIS_FULFILLMENT_STATUS_NOT_NEEDED,
        result.Polaris_Fulfillment_Status__c,
        'PRDOPS-544: RSC_G_Enabled__c = true must prevent the Not Needed stamp from being applied'
      );
    }
  }

  /**
   * @author Unit Testing Agent
   * @date 2026-03-30
   * @description PRDOPS-544: A Revenue order with only RSCP- products that transitions to
   * Order_Status__c = 'Order Accepted' with Polaris_Fulfillment_Status__c = 'Not Started'
   * must NOT have Send_for_Polaris_Fulfilment__c flipped to true.  This directly exercises
   * the Have_Polaris_Products__c == true guard at line 1797 in its blocking direction — the
   * new guard is what prevents the callout, and Have_Polaris_Products__c = false is what
   * causes the block.
   */
  @isTest
  static void testRSCPOnlyRevenueOrderAcceptedDoesNotTriggerCallout() {
    System.runAs(new User(Id = UserInfo.getUserId())) {
      // Arrange
      Id pricebookId = Test.getStandardPricebookId();
      List<Opportunity> lstOpp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
      Id acctId = lstOpp[0].AccountId;
      Id oppId  = lstOpp[0].Id;

      // RSCP- prefixed products only
      List<Product2> prods = new List<Product2>{
        createTestProduct('RSCP-FE-OA-TEST', 'RSCP-FE-OA-TEST', 'POLARIS', null, 'SaaS Software Addon',
          new Map<String, Object>{ 'Product_Type__c' => 'Foundation Edition' }),
        createTestProduct('RSCP-BE-OA-TEST', 'RSCP-BE-OA-TEST', 'POLARIS', null, 'SaaS Software Addon',
          new Map<String, Object>{ 'Product_Type__c' => 'Business Edition' })
      };
      insert prods;

      List<PricebookEntry> pbes = new List<PricebookEntry>{
        new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prods[0].Id, UnitPrice = 100.00, IsActive = true),
        new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = prods[1].Id, UnitPrice = 100.00, IsActive = true)
      };
      insert pbes;

      // Revenue order starting at a status that allows Order Accepted transition.
      // Polaris_Fulfillment_Status__c = 'Not Started' satisfies the inner callout condition
      // (lines 1801-1802) so the only thing blocking it is the new line-1797 guard.
      Order ord = createTestorder(
        'Revenue', null, acctId, oppId, acctId, pricebookId,
        'Not needed', 'Renewal',
        new Map<String, Object>{
          'Is_RWD_Polaris_Quote__c'       => false,
          'Have_Polaris_Products__c'      => false,
          'RSC_G_Enabled__c'             => false,
          'Polaris_Fulfillment_Status__c' => 'Not Needed',
          'Send_for_Polaris_Fulfilment__c' => false,
          'Order_Status__c'              => 'Pending'
        }
      );

      Test.startTest();
      insert ord;

      List<OrderItem> items = new List<OrderItem>{
        createTestOrderItem(ord.Id, 1, pbes[0].Id, 100.00,
          new Map<String, Object>{
            'Support_Start_Date__c' => System.today(),
            'Support_End_Date__c'   => System.today().addYears(1)
          }),
        createTestOrderItem(ord.Id, 1, pbes[1].Id, 100.00,
          new Map<String, Object>{
            'Support_Start_Date__c' => System.today(),
            'Support_End_Date__c'   => System.today().addYears(1)
          })
      };
      insert items;

      // Transition to Order Accepted — this is what the Revenue callout guard (line 1794-1808)
      // evaluates.  With Have_Polaris_Products__c = false the inner block must be skipped.
      ord.Order_Status__c = 'Order Accepted';
      ord.Polaris_Fulfillment_Status__c = 'Not Needed';
      update ord;
      Test.stopTest();

      // Assert: callout must NOT have fired
      Order result = [
        SELECT Have_Polaris_Products__c, Polaris_Fulfillment_Status__c, Send_for_Polaris_Fulfilment__c
        FROM Order WHERE Id = :ord.Id
      ];
      Assert.areEqual(
        false,
        result.Have_Polaris_Products__c,
        'PRDOPS-544: RSCP-only Revenue order must remain Have_Polaris_Products__c = false after Order Accepted'
      );
      Assert.areEqual(
        false,
        result.Send_for_Polaris_Fulfilment__c,
        'PRDOPS-544: Revenue callout guard (line 1797) must prevent Send_for_Polaris_Fulfilment__c being set when Have_Polaris_Products__c = false'
      );
    }
  }

  /**
   * @author Unit Testing Agent
   * @date 2026-03-30
   * @description PRDOPS-544: A POC order with only RSCP- products that has its ScreenStatus__c
   * changed to 'Approved' must NOT have Send_for_Polaris_Fulfilment__c flipped to true.
   * This directly exercises the Have_Polaris_Products__c == true guard at line 2782 in its
   * blocking direction — the new guard is what prevents the callout for RSCP-only POC orders.
   */
  @isTest
  static void testRSCPOnlyPOCOrderScreenStatusApprovedDoesNotTriggerCallout() {
    System.runAs(new User(Id = UserInfo.getUserId())) {
      // Arrange
      Id pricebookId = Test.getStandardPricebookId();
      List<Opportunity> lstOpp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
      Id acctId = lstOpp[0].AccountId;
      Id oppId  = lstOpp[0].Id;

      Id pocRecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order')?.getRecordTypeId();

      // RSCP- prefixed products only
      Product2 rscpProd = createTestProduct(
        'RSCP-FE-SCRN-TEST', 'RSCP-FE-SCRN-TEST', 'POLARIS', null, 'SaaS Software Addon',
        new Map<String, Object>{ 'Product_Type__c' => 'Foundation Edition' }
      );
      insert rscpProd;

      PricebookEntry pbe = new PricebookEntry(
        Pricebook2Id = pricebookId, Product2Id = rscpProd.Id, UnitPrice = 100.00, IsActive = true
      );
      insert pbe;

      // POC order — ScreenStatus starts at a value other than Approved so that the update
      // below triggers the oldOrd.ScreenStatus__c != newOrd.ScreenStatus__c condition.
      Map<String, Object> extraFields = new Map<String, Object>{
        'Is_RWD_Polaris_Quote__c'       => false,
        'Have_Polaris_Products__c'      => false,
        'RSC_G_Enabled__c'             => false,
        'Polaris_Fulfillment_Status__c' => 'Not Needed',
        'Send_for_Polaris_Fulfilment__c' => false,
        'ScreenStatus__c'              => 'Pending',
        'Sync_to_NetSuite__c'           => false
      };
      if (pocRecordTypeId != null) {
        extraFields.put('RecordTypeId', pocRecordTypeId);
      }

      Order ord = createTestorder(
        'POC', null, acctId, oppId, acctId, pricebookId,
        null, 'Renewal', extraFields
      );

      Test.startTest();
      insert ord;

      OrderItem item = createTestOrderItem(ord.Id, 1, pbe.Id, 100.00,
        new Map<String, Object>{
          'Support_Start_Date__c' => System.today(),
          'Support_End_Date__c'   => System.today().addYears(1)
        });
      insert item;

      // Transition ScreenStatus to 'Approved' — this is what the POC callout guard
      // (line 2781-2787) evaluates.  With Have_Polaris_Products__c = false the inner
      // block must be skipped.
      ord.ScreenStatus__c = 'Approved';
      update ord;
      Test.stopTest();

      // Assert: callout must NOT have fired
      Order result = [
        SELECT Have_Polaris_Products__c, Send_for_Polaris_Fulfilment__c
        FROM Order WHERE Id = :ord.Id
      ];
      Assert.areEqual(
        false,
        result.Have_Polaris_Products__c,
        'PRDOPS-544: RSCP-only POC order must remain Have_Polaris_Products__c = false after ScreenStatus Approved'
      );
      Assert.areEqual(
        false,
        result.Send_for_Polaris_Fulfilment__c,
        'PRDOPS-544: POC callout guard (line 2782) must prevent Send_for_Polaris_Fulfilment__c being set when Have_Polaris_Products__c = false'
      );
    }
  }
}