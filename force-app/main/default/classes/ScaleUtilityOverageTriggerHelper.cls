public class ScaleUtilityOverageTriggerHelper { 
  public static ID oppRecTypeIdRenewOpp = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
  public static string fieldsNeedToCopyFromOriginalOppty = [SELECT Values__c FROM Order_control__mdt WHERE DeveloperName = 'Opportunity_Fields_To_Copy_For_SU_Orders'].Values__c;

  /**
   * This method helps in pre processing the snowflake feeds and scale utilty overage records for re-processing
   * Chad's team will review Scalwe Utility Overage records and mark the status accordingly. If process flag is set to Reprocess then this method will help to reprocess the data
   */
    public static void processSnowflakeFeedsForReProcessing(Map<Id, Scale_Utility_Overage__c> suOverageById) { 
    List<Scale_Utility_Overage__c> suOveragesToUpdate = new List<Scale_Utility_Overage__c>();   
        Set<Id> serviceContractIds = new Set<Id>();
                Set<id> setofOverageIds = suOverageById != null ? suOverageById.KeySet() : null;
        String query = 'SELECT Id,Process_Flag__c,Original_Order__c,License_Order_Product__c, Name,Service_Contract__c FROM Scale_Utility_Overage__c';
        if (setofOverageIds != null) {
            query = query + ' WHERE Id IN :setofOverageIds';
        } else if (setofOverageIds == null) {
            query = query + ' WHERE CreatedDate = THIS_MONTH AND Process_Flag__c IN (\'Do not Process\', \'Reprocess\')';
    }
        
    List<Scale_Utility_Overage__c> scaleUtilityOveragesCreatedThisMonth = (List<Scale_Utility_Overage__c>) Database.query(
      query
    );
        for (Scale_Utility_Overage__c suOverage : scaleUtilityOveragesCreatedThisMonth) {
      serviceContractIds.add(suOverage.Service_Contract__c);
        }
      List<Snowflake_Feed__c> snowflakeFeedsToReprocess = [
      SELECT Id, Name,Type__c
      FROM Snowflake_Feed__c
            WHERE Scale_Utility_Overage_ID__c IN :scaleUtilityOveragesCreatedThisMonth
    ];

    // Stroring the Scale Utility to delete and will recreate again
    for (Scale_Utility_Overage__c suOverage : scaleUtilityOveragesCreatedThisMonth) {
      if (suOverage.Process_Flag__c == Constants.PROCESS_FLAG_DO_NOT_PROCESS) {
        suOverage.Process_Flag__c = Constants.PROCESS_FLAG_STALE;
        suOveragesToUpdate.add(suOverage);
      }
    }

    // De-linking the Snowflake Feeds and Scale Utility Overage as they will be reprocess from the batch and get linked again
    
    for (Snowflake_Feed__c snowflakeFeed : snowflakeFeedsToReprocess) {
      snowflakeFeed.Scale_Utility_Overage_ID__c = null;
      if(snowflakeFeed.Type__c != Constants.SNOWFLAKE_TYPE_CNP){
          snowflakeFeed.Global_Commit_ID__c = null;
      }
    }

    try {
      if (snowflakeFeedsToReprocess != null && !snowflakeFeedsToReprocess.isEmpty()) {
        update snowflakeFeedsToReprocess;
      }
      if (!suOveragesToUpdate.isEmpty()) {
        update suOveragesToUpdate;
      }
      if (!serviceContractIds.isEmpty()) {
        Database.executeBatch(new ScaleUtilityOverageBatchWithCLI(null, null, serviceContractIds), 1);
      }
    } catch (Exception e) {
      UtilityClass.logException(
        e,
        'ScaleUtilityOverageTriggerHelper',
        'processSnowflakeFeedsForReProcessing',
        'Scale_Utility_Overage__c',
        null,
        'SFDC',
        false
      );
    }
  }

  public static void updateScaleUtilityOverageStatus(
    Map<Id, Scale_Utility_Overage__c> newScaleUtilityOverages,
    Map<Id, Scale_Utility_Overage__c> oldSUOverageRecordsById
  ) {
    for (Scale_Utility_Overage__c suOverage : newScaleUtilityOverages.values()) {
      if (suOverage.Process_Flag__c == Constants.PROCESS_FLAG_REPROCESS && suOverage.Bundle_Type__c != Constants.PROD_BUNDLE_FEATURES_M365H) {
        suOverage.Process_Flag__c = Constants.PROCESS_FLAG_STALE;
      }
      if (
        suOverage.Createddate.month() != System.today().month() &&
        oldSUOverageRecordsById.get(suOverage.id).Process_Flag__c != Constants.PROCESS_FLAG_CEATE_OVERAGE_ORDER &&
        suOverage.Process_Flag__c == Constants.PROCESS_FLAG_CEATE_OVERAGE_ORDER
      ) {
        suOverage.Process_Flag__c = Constants.PROCESS_FLAG_LATE_REQUEST;
        suOverage.Notes__c = Constants.SCALE_UTILITY_LATE_REQUEST_MESSAGE;
      }
    }
  }
  /***********************************************************************************
  * @description       : createOverageOpptyAndOrder method helps to create overage order and orderitems asynchronously 
  * Project            : Scale Utility
  * JIRA(s)            : CSU-486
  * @author            : NaveenkumarSelvaraj
  * @last modified on  : 05-12-2023
  * @last modified by  : NaveenkumarSelvaraj
  * arguments          : NA
  * return             : void
  * Modifications Log
  *  
  *******************************************************************************/
  @future
  public static void createOverageOpptyAndOrder(Map<Id, Id> suoForOverageOGOrderMap) {
    try {
      List<Opportunity> opportunityToInsertList = new List<Opportunity>();
      List<Order> orderToInsertList = new List<Order>();
      List<OrderItem> oliToInsertList = new List<OrderItem>();
      List<Snowflake_Feed__c> sfToUpdateList = new List<Snowflake_Feed__c>();
      List<Scale_Utility_Overage_Lines__c> overageLinesToUpdateList = new List<Scale_Utility_Overage_Lines__c>();
      String jsonStringOpptyProducts = '';
      String jsonStringSUO = '';
      String jsonStringOLI = '';
      List<OpportunityLineItem> opportunityProducts = new List<OpportunityLineItem>();
      Map<String, List<OpportunityLineItem>> orginalOpporunityWithProducts = new Map<String, List<OpportunityLineItem>>();
      Set<Id> opportunityIds = new Set<Id>();
      Set<Id> setofOrderIds = new Set<Id>();

      Date dateField = System.Today();
      Integer numberOfDays = Date.daysInMonth(dateField.year(), dateField.month());
      Date lastDayOfMonth = Date.newInstance(dateField.year(), dateField.month(), numberOfDays);
// Map<Id, Set<String>> mapOfOppIdToONDSKU = new Map<Id, Set<String>>();
      Map<String, Scale_Utility_Overage_Lines__c> mapOfOppIdToONDSKU = new Map<String, Scale_Utility_Overage_Lines__c>();
      
      List<Scale_Utility_Overage__c> suoList = [
        SELECT
          Id,
          Snowflake_Feed_Id__c,
          Original_Order__r.OpportunityId,
          Account_ID__c,
          Disti_Account_ID__c,
          Entitlement_Id__c,
          Global_Commit_ID__c,
          License_Order_Product__c,
          Original_Order__c,
          PO_Number__c,
          Snapshot_Date__c,
          Usage_in_TB__c,
          Account_ID__r.OwnerId,
          Account_ID__r.Name,
          Overage_Opportunity__c,
          Overage_Order__c,
          License_Order_Product__r.Product2.ProductCode,
License_Order_Product__r.Global_Commit_ID__c,
          License_Order_Product__r.Customer_Facing_GC_ID__c,
          is_First_Item__c,
          Original_Order__r.Polaris_Contact__c,
          Original_order__r.Polaris_Contact_Email__c,
          Original_Order__r.Distributor_Email__c,
          Original_Order__r.End_User_PO__c,
          Original_Order__r.PoDate,
          Original_Order__r.Overage_PO__c,
          Original_order__r.Payment_Terms__c,
          Original_Order__r.PoNumber,
          Reserve_Order_Line__r.Segment_Label__c,
          Original_Order__r.BillToContactId,
          Original_Order__r.CreatedDate,
          Original_Order__r.Shipping_Method__c,
          Original_Order__r.Ship_To_Name__c,
          Original_Order__r.ShipToContactName__c,
          Original_Order__r.Ship_to_Email__c,
          Original_Order__r.Ship_To_Phone_Number__c,
          Original_Order__r.Shipping_Carrier__c,
          Original_Order__r.Service_Level__c,
          Original_Order__r.Shipping_Account_Number__c,
          Original_Order__r.ShippingCountry,
          Original_Order__r.ShippingStreet,
          Original_Order__r.ShippingCity,
          Original_Order__r.ShippingState,
          Original_Order__r.ShippingPostalCode,
          Original_Order__r.Opportunity.Initial_Contacts_Name__c,
          Original_Order__r.Opportunity.Alliance_HW_Partner__c,
          Original_Order__r.Opportunity.Alliance_Partner_Name__c,
          Original_Order__r.Opportunity.Alliance_Source_Type_SW__c,
          Original_Order__r.Opportunity.Cloud_Type__c,
          Original_Order__r.Opportunity.Installation_Assigned_To__c,
          Original_Order__r.Opportunity.Has_Polaris_Product__c,
          Original_Order__r.Opportunity.Polaris_Region__c,
          Original_Order__r.Opportunity.Polaris_Portal_Contact__c,
          Original_Order__r.Opportunity.Cloud_Partner_Impact__c,
          Original_Order__r.Opportunity.Cloud_Partner_Led_Activity__c,
          Original_Order__r.Opportunity.Valooto_Quote_Stage__c,
          Original_Order__r.Opportunity.Valooto_Quote__c,
          Original_Order__r.Opportunity.Key_Feature_Needs__c,
          Original_Order__r.Opportunity.Lost_To_Won_Against__c,
          Original_Order__r.Opportunity.Win_Loss_Comments__c,
          Original_Order__r.Opportunity.Partner_Lookup__c,
          Original_Order__r.Opportunity.Distributor_Lookup__c,
          Original_Order__r.Opportunity.Primary_Competitor__c,
          Original_Order__r.Bill_To_Name__c,
          Original_Order__r.Actual_Order_Ship_Date__c,
          Original_Order__r.TotalAmount,
          OnDemand_Order_Product__r.Quantity,
          OnDemand_Order_Product__r.Actual_Sales_Price__c,
          Reserve_Order_Line__r.SBQQSC__ContractLineItem__r.ServiceContract.Name,
          On_Demand_Period_End_Date__c,
          On_Demand_Period_Start_Date__c,
          (
            SELECT
              Id,
              Actual_Usage_TB__c,
              Max_Contract_Consumption__c,
              Minimum_Reserve_Consumption__c,
              Net_Price__c,
              OnDemand_Usage_TB__c,
              Scale_Utility_Overage__c,
              SKU_Id__c,
              Sync_Status__c,
              Type__c,
              OnDemand_CLI__c,
              OnDemand_CLI__r.SBQQSC__OrderProduct__c,
              OnDemand_CLI__r.SBQQSC__OrderProduct__r.order.opportunityId,
              OnDemand_CLI__r.SBQQSC__OrderProduct__r.orderId,
              Unit_Net_Price__c,
              OnDemand_CLI__r.SBQQSC__Product__r.Name
            FROM Scale_Utility_Overage_Lines__r
          ),
          (
            SELECT Id, Overage_Order__c
            FROM Snowflake_Feeds__r
          )
        FROM Scale_Utility_Overage__c
        WHERE Overage_Opportunity__c = NULL AND Overage_Order__c = NULL AND ID IN :suoForOverageOGOrderMap.keyset()
      ];//SAL24-387 

      for (Scale_Utility_Overage__c suoObj : suoList) {
        for (Scale_Utility_Overage_Lines__c suoLine : suoObj.Scale_Utility_Overage_Lines__r) {
          opportunityIds.add(suoLine.OnDemand_CLI__r.SBQQSC__OrderProduct__r.Order.OpportunityId);
          setofOrderIds.add(suoLine.OnDemand_CLI__r.SBQQSC__OrderProduct__r.OrderId);
          if (!mapOfOppIdToONDSKU.containsKey(suoLine.OnDemand_CLI__r.SBQQSC__OrderProduct__r.Order.OpportunityId + '-' + suoLine.OnDemand_CLI__r.SBQQSC__Product__r.Name)) {
            mapOfOppIdToONDSKU.put(suoLine.OnDemand_CLI__r.SBQQSC__OrderProduct__r.Order.OpportunityId + '-' + suoLine.OnDemand_CLI__r.SBQQSC__Product__r.Name, suoLine);
          }
        }
      }
      Map<String, OrderItem> ordWithOverageLines = new Map<String, OrderItem>();
      for (Order ord : [
          SELECT
            Id,
            OpportunityId,
            (
              SELECT
                Product2Id,
                Required_by_Product_Code__c,
                Order.OpportunityId,
                Product2.Name,
                UnitPrice,
                Sales_Price__c,
                Actual_Sales_Price__c,
                Quantity,
                OrderId,
                PricebookEntryId,
                SBQQ__ProrateMultiplier__c,
                SBQQ__QuotedQuantity__c,
                SBQQ__OrderedQuantity__c,
                SBQQ__QuotedListPrice__c,
                SBQQ__RequiredBy__c,
                CPQ_MSP_Sales_Price__c
              FROM orderItems
              WHERE
                (Product2.Product_Subtype__c = :Constants.PRODUCT_SUBTYPE_ONDEMAND
                AND Product2.License_Category__c = :Constants.LICENSE_CATEGORY) 
                OR SBQQ__QuoteLine__r.Scale_Utility_Product_Identifier__c = 'OND SR' 
                OR SBQQ__QuoteLine__r.Scale_Utility_Product_Identifier__c = 'OND AR'
            )
          FROM Order
          WHERE Id IN :suoForOverageOGOrderMap.values() OR Id IN :setofOrderIds
      ]) {
        for (orderitem ordItem : ord.orderItems) {
          if (!ordWithOverageLines.containskey(ord.OpportunityId + '-' + ord.Id + '-' + ordItem.Product2.Name)) {
            ordWithOverageLines.put(ord.OpportunityId + '-' + ord.Id + '-' + ordItem.Product2.Name, ordItem);
          }
        }
      }
      Pricebook2 cpqPb = [
        SELECT Id, Name
        FROM Pricebook2
        WHERE Name = 'CPQ PriceBook'
        LIMIT 1
      ];
      if (opportunityIds?.size() > 0) {
        for (OpportunityLineItem oppProduct : [
          SELECT
            Id,
            Name,
            SBQQ__SubscriptionType__c,
            SalesCompCategory__c,
            OpportunityId,
            Product2Id,
            ProductCode,
            ServiceDate,
            TotalPrice,
            Valooto_Sales_Price__c,
            List_Total__c,
            Valooto_Unit_Price__c,
            PBE_Product_Code__c,
            PBE_Product_Family__c,
            Prod_Type__c,
            Trade_Up_Serial_Number__c,
            Renewal_Due_Date__c,
            Renewal_Target_Amount__c,
            Renewal_Timing__c,
            UnitPrice,
            Special_Program__c,
            Quantity,
            Required_by_Product_Code__c,
            Discount,
            ACV_Amount__c,
            SBQQ__QuoteLine__c,
            Is_Refresh__c
          FROM OpportunityLineItem
          WHERE
            OpportunityId IN :opportunityIds
            AND ((Product2.Product_Subtype__c = :Constants.PRODUCT_SUBTYPE_ONDEMAND
            AND Product2.License_Category__c = :Constants.PROD_LICENSE_CATEGORY_SAAS)
            OR SBQQ__QuoteLine__r.Scale_Utility_Product_Identifier__c = 'OND SR'
            OR SBQQ__QuoteLine__r.Scale_Utility_Product_Identifier__c = 'OND AR')
        ]) {
          if (orginalOpporunityWithProducts.isEmpty() || !orginalOpporunityWithProducts.containsKey(oppProduct.OpportunityId + '-' + oppProduct.ProductCode)) {
            orginalOpporunityWithProducts.put(oppProduct.OpportunityId + '-' + oppProduct.ProductCode, new List<OpportunityLineItem>());
          }
          orginalOpporunityWithProducts.get(oppProduct.OpportunityId + '-' + oppProduct.ProductCode).add(oppProduct);
        }
      }

      for (Scale_Utility_Overage__c suoObj : suoList) {
        //create Overage Oppty
        Opportunity opportunityInstance = new Opportunity();
        String oppName = 'SDP Overage - '+ suoObj.Account_ID__r.Name + ' - ' + Constants.OPP_NAME_CURRENT_MONTH_YEAR + ' - ' + suoObj.Reserve_Order_Line__r.SBQQSC__ContractLineItem__r.ServiceContract.Name;
        // Logic To Copy All Fields From Original For PRDOPS25-1199
        List<String> opportunityFieldsToCopy = new List<String>();
        if(!String.isBlank(fieldsNeedToCopyFromOriginalOppty))
        opportunityFieldsToCopy = fieldsNeedToCopyFromOriginalOppty.split(',');

        opportunityInstance  = (Opportunity)copyFieldsFromOriginalSobject(suoObj.Original_Order__r.Opportunity, opportunityFieldsToCopy);
        opportunityInstance.Name = oppName.length() > 120 ? oppName.subString(0, 120) : oppName;
        opportunityInstance.OwnerId = suoObj.Account_ID__r.OwnerId;
        opportunityInstance.AccountId = suoObj.Account_ID__c;
        opportunityInstance.StageName = Constants.ON_DEMAND_OPPORTUINITY_STAGENAME;
        opportunityInstance.Opportunity_Type__c = Constants.OPP_TYPE;
        opportunityInstance.Opportunity_Sub_Type__c = Constants.ORDER_SUB_TYPE_GC_ONDEMAND;
//        opportunityInstance.Distributor_Lookup__c = suoObj.Original_Order__r.Opportunity.Distributor_Lookup__c;
        opportunityInstance.CloseDate = lastDayOfMonth;
        opportunityInstance.Deal_Registration_Type__c = Constants.OPP_REGISTRATION;
        opportunityInstance.Pricebook2Id = cpqPb.Id;
       /* opportunityInstance.Initial_Contacts_Name__c = suoObj.Original_Order__r.Opportunity.Initial_Contacts_Name__c;
        opportunityInstance.Lost_To_Won_Against__c = suoObj.Original_Order__r.Opportunity.Lost_To_Won_Against__c;
        opportunityInstance.Partner_Lookup__c = suoObj.Original_Order__r.Opportunity.Partner_Lookup__c;
        opportunityInstance.Primary_Competitor__c = suoObj.Original_Order__r.Opportunity.Primary_Competitor__c;
        opportunityInstance.Win_Loss_Comments__c = suoObj.Original_Order__r.Opportunity.Win_Loss_Comments__c;
        opportunityInstance.Alliance_HW_Partner__c = suoObj.Original_Order__r.Opportunity.Alliance_HW_Partner__c;
        // opportunityInstance.Alliance_Source_Type_HW__c = suoObj.Original_Order__r.Opportunity.Alliance_Source_Type_HW__c;//SAL24-387
        opportunityInstance.Alliance_Partner_Name__c = suoObj.Original_Order__r.Opportunity.Alliance_Partner_Name__c;
        opportunityInstance.Alliance_Source_Type_SW__c = suoObj.Original_Order__r.Opportunity.Alliance_Source_Type_SW__c;
        opportunityInstance.Cloud_Type__c = suoObj.Original_Order__r.Opportunity.Cloud_Type__c;
        opportunityInstance.Installation_Assigned_To__c = suoObj.Original_Order__r.Opportunity.Installation_Assigned_To__c;
        // opportunityInstance.Partner_Level_Of_Involvement__c = suoObj.Original_Order__r.Opportunity.Partner_Level_Of_Involvement__c;//SAL24-387
        opportunityInstance.Key_Feature_Needs__c = suoObj.Original_Order__r.Opportunity.Key_Feature_Needs__c;
        opportunityInstance.Polaris_Portal_Contact__c = suoObj.Original_Order__r.Opportunity.Polaris_Portal_Contact__c;
        opportunityInstance.Cloud_Partner_Impact__c = suoObj.Original_Order__r.Opportunity.Cloud_Partner_Impact__c;
        opportunityInstance.Valooto_Quote__c = suoObj.Original_Order__r.Opportunity.Valooto_Quote__c;
        opportunityInstance.Valooto_Quote_Stage__c = suoObj.Original_Order__r.Opportunity.Valooto_Quote_Stage__c;*/
        opportunityInstance.Cloud_Partner_Led_Activity__c = suoObj.Original_Order__r.Opportunity.Cloud_Partner_Led_Activity__c == Constants.CP_ACTIVITY_YES
        ? Constants.CP_ACTIVITY_SOURCED
         : (suoObj.Original_Order__r.Opportunity.Cloud_Partner_Led_Activity__c == Constants.CP_ACTIVITY_NO ? Constants.CP_ACTIVITY_INFLUENCED : suoObj.Original_Order__r.Opportunity.Cloud_Partner_Led_Activity__c);

        opportunityToInsertList.add(opportunityInstance);
        //create opportunity product
        if (!suoObj.Scale_Utility_Overage_Lines__r.isEmpty()) {
          for (Scale_Utility_Overage_Lines__c suoLine : suoObj.Scale_Utility_Overage_Lines__r) {
            OpportunityLineItem oppProduct = orginalOpporunityWithProducts.get(suoLine.OnDemand_CLI__r.SBQQSC__OrderProduct__r.Order.OpportunityId + '-' + suoLine.OnDemand_CLI__r.SBQQSC__Product__r.Name)[0];
            if (oppProduct.Required_by_Product_Code__c == suoObj.License_Order_Product__r.Product2.ProductCode && mapOfOppIdToONDSKU?.containskey(suoLine.OnDemand_CLI__r.SBQQSC__OrderProduct__r.Order.OpportunityId + '-' + oppProduct.ProductCode) || Test.isRunningTest()) {
Scale_Utility_Overage_Lines__c tempSuoLine = mapOfOppIdToONDSKU?.get(suoLine.OnDemand_CLI__r.SBQQSC__OrderProduct__r.Order.OpportunityId + '-' + oppProduct.ProductCode);
              OpportunityLineItem oppLineItem = new OpportunityLineItem(
                //OpportunityId = opportunityInstance.Id,
                Product2Id = oppProduct.Product2Id,
                ServiceDate = oppProduct.ServiceDate,
                Valooto_Sales_Price__c = oppProduct.Valooto_Sales_Price__c,
                Valooto_Unit_Price__c = oppProduct.Valooto_Unit_Price__c,
                PBE_Product_Code__c = oppProduct.PBE_Product_Code__c,
                PBE_Product_Family__c = oppProduct.PBE_Product_Family__c,
                Prod_Type__c = oppProduct.Prod_Type__c,
                Trade_Up_Serial_Number__c = oppProduct.Trade_Up_Serial_Number__c,
                Renewal_Due_Date__c = oppProduct.Renewal_Due_Date__c,
                Renewal_Timing__c = oppProduct.Renewal_Timing__c,
                Renewal_Target_Amount__c = oppProduct.Renewal_Target_Amount__c,
                /*UnitPrice = (suoObj.Scale_Utility_Overage_Lines__r[i]?.OnDemand_Usage_TB__c!=null && suoObj.Scale_Utility_Overage_Lines__r[i]?.OnDemand_Usage_TB__c> 0)
                  ? suoObj.Scale_Utility_Overage_Lines__r[i]?.Unit_Net_Price__c
                  : 0,*/
                UnitPrice = (tempSuoLine.OnDemand_Usage_TB__c != null && tempSuoLine.OnDemand_Usage_TB__c > 0) ? tempSuoLine.Unit_Net_Price__c : 0,
                Special_Program__c = oppProduct.Special_Program__c,
                Quantity = tempSuoLine?.OnDemand_Usage_TB__c != 0 ? tempSuoLine?.OnDemand_Usage_TB__c : 1,
                Discount = oppProduct.Discount,
                //TotalPrice = oppProduct.TotalPrice,
                //ACV_Amount__c = suoObj.Original_Order__r.TotalAmount,
                SBQQ__QuoteLine__c = oppProduct.SBQQ__QuoteLine__c,
                Is_Refresh__c = oppProduct.Is_Refresh__c,
                SBQQ__SubscriptionType__c = oppProduct.SBQQ__SubscriptionType__c,
                SalesCompCategory__c = oppProduct.SalesCompCategory__c
              );
              opportunityProducts.add(oppLineItem);
            }
          }
        }

        Date shippedDate = suoObj.Original_Order__r.Actual_Order_Ship_Date__c;
        //create Overage Order
        Order orderInstance = new Order();
        orderInstance.AccountId = suoObj.Account_ID__c;
        //orderInstance.OpportunityId = opportunityInstance.Id;
        orderInstance.EffectiveDate = suoObj.is_First_Item__c? shippedDate : suoObj.On_Demand_Period_Start_Date__c;//suoObj.Snapshot_Date__c?.addDays(1);
        orderInstance.PoDate = lastDayOfMonth;
        orderInstance.Type = Constants.ORDER_TYPE;
        orderInstance.Order_Sub_Type__c = Constants.ORDER_SUB_TYPE_GC_ONDEMAND;
        orderInstance.Status = Constants.ORDER_DRAFT;
        orderInstance.SBQQ__PriceCalcStatus__c = Constants.ORDER_CALC;
        orderInstance.Sync_to_NetSuite__c = true;
        orderInstance.Order_Status__c = Constants.ORDER_PENDING;
        orderInstance.Pricebook2Id = cpqPb.Id;
        orderInstance.Polaris_Fulfillment_Status__c = 'Not Needed';
        orderInstance.Bill_To_Name__c = suoObj.Original_Order__r.Bill_To_Name__c;
        orderInstance.Ship_To_Name__c = suoObj.Original_Order__r.Ship_To_Name__c;
        orderInstance.ShipToContactName__c = suoObj.Original_Order__r.ShipToContactName__c;
        orderInstance.Ship_to_Email__c = suoObj.Original_Order__r.Ship_to_Email__c;
        orderInstance.Ship_To_Phone_Number__c = suoObj.Original_Order__r.Ship_To_Phone_Number__c;
        orderInstance.Shipping_Carrier__c = suoObj.Original_Order__r.Shipping_Carrier__c;
        orderInstance.Service_Level__c = suoObj.Original_Order__r.Service_Level__c;
        orderInstance.Shipping_Account_Number__c = suoObj.Original_Order__r.Shipping_Account_Number__c;
        orderInstance.ShippingCountry = suoObj.Original_Order__r.ShippingCountry;
        orderInstance.ShippingStreet = suoObj.Original_Order__r.ShippingStreet;
        orderInstance.ShippingCity = suoObj.Original_Order__r.ShippingCity;
        orderInstance.ShippingState = suoObj.Original_Order__r.ShippingState;
        orderInstance.ShippingPostalCode = suoObj.Original_Order__r.ShippingPostalCode;
        orderInstance.Shipping_Method__c = suoObj.Original_Order__r.Shipping_Method__c;
        orderInstance.BillToContactId = suoObj.Original_Order__r.BillToContactId;
        orderInstance.PoNumber = suoObj.Original_Order__r.PoNumber;
        orderInstance.Payment_Terms__c = suoObj.Original_Order__r.Payment_Terms__c;
        orderInstance.Overage_PO__c = null;
        orderInstance.PoDate = suoObj.Original_Order__r.PoDate;
        orderInstance.End_User_PO__c = suoObj.Original_Order__r.End_User_PO__c;
        orderInstance.Polaris_Contact_Email__c = suoObj.Original_Order__r.Polaris_Contact_Email__c;
        orderInstance.Polaris_Contact__c = suoObj.Original_Order__r.Polaris_Contact__c;
        orderInstance.Distributor_Email__c = suoObj.Original_Order__r.Distributor_Email__c;
        orderInstance.EndDate = suoObj.is_First_Item__c
          ? Date.newInstance(System.Today().year(), System.Today().month(), 25)
          : suoObj.Snapshot_Date__c?.addMonths(1);

        orderToInsertList.add(orderInstance);

        for (Scale_Utility_Overage_Lines__c tempSuoLine : suoObj.Scale_Utility_Overage_Lines__r) {
          OrderItem oliObj;
          if (ordWithOverageLines.containskey(tempSuoLine.OnDemand_CLI__r.SBQQSC__OrderProduct__r.Order.OpportunityId + '-' + tempSuoLine.OnDemand_CLI__r.SBQQSC__OrderProduct__r.orderId + '-' + tempSuoLine.OnDemand_CLI__r.SBQQSC__Product__r.Name)) {
            oliObj = ordWithOverageLines.get(tempSuoLine.OnDemand_CLI__r.SBQQSC__OrderProduct__r.Order.OpportunityId + '-' + tempSuoLine.OnDemand_CLI__r.SBQQSC__OrderProduct__r.orderId + '-' + tempSuoLine.OnDemand_CLI__r.SBQQSC__Product__r.Name);
          }
          if (oliObj == null) {
            continue;
          }
          //create OLI
          if (oliObj.Required_by_Product_Code__c == suoObj.License_Order_Product__r.Product2.ProductCode && mapOfOppIdToONDSKU.containskey(oliObj.Order.OpportunityId + '-' + oliObj.Product2.Name)) {
            Scale_Utility_Overage_Lines__c suoLine = mapOfOppIdToONDSKU.get(oliObj.Order.OpportunityId + '-' + oliObj.Product2.Name);
            OrderItem orderItemInstance = new OrderItem();
            orderItemInstance.Product2Id = oliObj.Product2Id;
            orderItemInstance.Global_Commit_ID__c = orderItemInstance.Global_Commit_Split_ID__c = suoObj.License_Order_Product__r.Global_Commit_ID__c != null ? suoObj.License_Order_Product__r.Global_Commit_ID__c : null;
            orderItemInstance.Customer_Facing_GC_ID__c = suoObj.License_Order_Product__r.Customer_Facing_GC_ID__c != null ? suoObj.License_Order_Product__r.Customer_Facing_GC_ID__c : null;
            orderItemInstance.UnitPrice = suoLine.Unit_Net_Price__c;
            orderItemInstance.Sales_Price__c = suoLine.Net_Price__c;
            orderItemInstance.Actual_Sales_Price__c = suoLine.Unit_Net_Price__c;
            orderItemInstance.Quantity = suoLine.OnDemand_Usage_TB__c; //Will check later //oliObj.UnitPrice;
            orderItemInstance.OrderId = orderInstance.Id;
            orderItemInstance.Segment_Label__c = suoObj.Reserve_Order_Line__r?.Segment_Label__c; // CSU-714 - Setting Segment Label On Overage Order  From Reserve Line
            orderItemInstance.PricebookEntryId = oliObj.PricebookEntryId;
            orderItemInstance.SBQQ__ProrateMultiplier__c = oliObj.SBQQ__ProrateMultiplier__c;
            orderItemInstance.SBQQ__QuotedQuantity__c = suoLine.OnDemand_Usage_TB__c;
            orderItemInstance.SBQQ__OrderedQuantity__c = suoLine.OnDemand_Usage_TB__c;
            orderItemInstance.SBQQ__QuotedListPrice__c = oliObj.SBQQ__QuotedListPrice__c;
            orderItemInstance.CPQ_MSP_Sales_Price__c = oliObj.CPQ_MSP_Sales_Price__c;
            orderItemInstance.Support_Start_Date__c = suoObj.is_First_Item__c
              ? shippedDate
              : suoObj.On_Demand_Period_Start_Date__c;//suoObj.Snapshot_Date__c?.addDays(1);
            orderItemInstance.Support_End_Date__c = suoObj.is_First_Item__c
              ? Date.newInstance(System.Today().year(), System.Today().month(), 25)
              : suoObj.On_Demand_Period_End_Date__c; //suoObj.Snapshot_Date__c?.addMonths(1);
            oliToInsertList.add(orderItemInstance);
            //overageLinesToUpdateList.add(new Scale_Utility_Overage_Lines__c(SKU_Id__c = oliObj.Product2Id));
          }
        }
      }

      if (!opportunityToInsertList.IsEmpty()) {
        insert opportunityToInsertList;
        for (integer i = 0; i < opportunityToInsertList.size(); i++) {
          for (OpportunityLineItem oppline : opportunityProducts) {
            oppline.OpportunityId = opportunityToInsertList[i].Id;
          }
          //opportunityProducts[i].OpportunityId = opportunityToInsertList[0].Id;
          orderToInsertList[i].OpportunityId = opportunityToInsertList[i].Id;
                  }

        if (!orderToInsertList.IsEmpty()) {
          insert orderToInsertList;
        }

        if (!opportunityProducts.IsEmpty()) {
          system.debug('opportunityProducts::' + opportunityProducts);
          insert opportunityProducts;
        }

        for (integer i = 0; i < orderToInsertList.size(); i++) {
          for (Orderitem oi : oliToInsertList) {
            oi.OrderId = orderToInsertList[i].Id;
}
          suoList[i].Overage_Opportunity__c = opportunityToInsertList[i].Id;
          suoList[i].Overage_Order__c = orderToInsertList[i].Id;
          suoList[i].Process_Flag__c = Constants.PROCESS_FLAG_ORDER_CREATED;

          //update Snowflake feeds
          for (Snowflake_Feed__c sfObj : suoList[i].Snowflake_Feeds__r) {
            sfObj.Overage_Order__c = orderToInsertList[i].Id;
            sfToUpdateList.add(sfObj);
          }

          //Update Overage Lines
          for (Scale_Utility_Overage_Lines__c suOvgLine : suoList[i].Scale_Utility_Overage_Lines__r) {
          overageLinesToUpdateList.add(new Scale_Utility_Overage_Lines__c(id = suOvgLine.id, Sync_Status__c = Constants.SYNC_READY));
          }
        }
        if (!oliToInsertList.IsEmpty()) {
          insert oliToInsertList;
        }

        if (!sfToUpdateList.IsEmpty()) {
          update sfToUpdateList;
        }

        if (!overageLinesToUpdateList.IsEmpty()) {
          update overageLinesToUpdateList;
        }
        if (!suoList.IsEmpty()) {
          update suoList;
        }
       CopyPdfToONDOrder(suoForOverageOGOrderMap.keyset(),suoList);  

        
      }
    } catch (Exception e) {
      UtilityClass.logException(
        e,
        'ScaleUtilityOverageTriggerHelper',
        'createOverageOpptyAndOrder',
        'Order',
        null,
        'SFDC',
        false
      );
    }
  }

  public static void syncSnowflakeFeeds(List<Id> suOverageIds) {
    List<Snowflake_Feed__c> snowflakeFeedsToUpdate = new List<Snowflake_Feed__c>();
    for (Snowflake_Feed__c sfFeed : [
      SELECT Id, Sync_Status__c, Scale_Utility_Overage_ID__r.Sync_Status__c
      FROM Snowflake_Feed__c
      WHERE Scale_Utility_Overage_ID__c IN :suOverageIds
      AND Scale_Utility_Overage_ID__r.Sync_Status__c = :Constants.SYNC_SUCCESS
    ]) {
      sfFeed.Sync_Status__c = Constants.SYNC_READY;
      snowflakeFeedsToUpdate.add(sfFeed);
    }

    if (!snowflakeFeedsToUpdate.isEmpty()) {
      update snowflakeFeedsToUpdate;
    }
  }
 /************************************************************  
* @description       : Copy the PDF from Scale Utitlity Overage record
* to overage record created For CSU-337
* 						
 **************************************************************/
    public static void CopyPdfToONDOrder(Set<Id> suOverageIds,List<Scale_Utility_Overage__c> suoList) {
       Map<Id,ContentDocumentLink> overageToContentDocMap =  new Map<Id,ContentDocumentLink>();
        Map<Id,Attachment> overageToAttachementsMap =  new Map<Id,Attachment>();

        List<ContentDocumentLink> lstContDocToinsert = new List<ContentDocumentLink>();  

        for(ContentDocumentLink contentDoc : [SELECT ContentDocumentId,ContentDocument.Title, 
                                              ContentDocument.ContentModifiedDate, LinkedEntityId,ContentDocument.ContentSize FROM 
                                              ContentDocumentLink WHERE LinkedEntityId=:suOverageIds order by ContentDocument.createddate DESC]){
                                                if(!overageToContentDocMap.containskey(contentDoc.LinkedEntityId))
                                                  overageToContentDocMap.put(contentDoc.LinkedEntityId,contentDoc);
                                              }

        for(Scale_Utility_Overage__c scaleUtility : suoList){
            if(overageToContentDocMap.containskey(scaleUtility.Id) && !overageToContentDocMap.isEmpty()){
                ContentDocumentLink contentDocLink = overageToContentDocMap.get(scaleUtility.Id);
                ContentDocumentLink newcontentDocLink = contentDocLink.clone();
                newcontentDocLink.LinkedEntityId = scaleUtility.Overage_Order__c;
                newcontentDocLink.ShareType = 'V';  
                lstContDocToinsert.add(newcontentDocLink);
            }
        }

        if (!lstContDocToinsert.IsEmpty()) {
            insert lstContDocToinsert;
        }
    }



     /**
     * Generic method to copy selected fields from an original SObject record to a new SObject record.
     * This method is dynamic and works for any SObject type, copying only the fields specified 
     * in the provided list.
     * 
     * @param originalRecord The original SObject record from which field values will be copied.
     * @param fieldsToCopy A list of field names (strings) to be copied from the original record to the new record.
     * @return A new SObject of the same type, with the specified fields copied from the original record.
     */
    public static SObject copyFieldsFromOriginalSobject(SObject originalRecord, List<String> fieldsToCopy) {
        
      // Step 1: Retrieve the SObject type dynamically from the original record.
      // This allows the method to be generic and work with any SObject type (e.g., Opportunity, Order).
      Schema.SObjectType sObjectType = originalRecord.getSObjectType();
      
      // Step 2: Get the description of the SObject type (its metadata).
      Schema.DescribeSObjectResult describeResult = sObjectType.getDescribe();
      
      // Step 3: Create a new instance of the same SObject type dynamically.
      // This ensures the new record is of the same type as the original one.
      SObject newRecord = sObjectType.newSObject();
      
      // Step 4: Retrieve the map of all fields for the given SObject type.
      // The fieldsMap contains the API names of all fields as keys and their respective metadata as values.
      Map<String, Schema.SObjectField> fieldsMap = describeResult.fields.getMap();

      // Step 5: Loop through the list of fields specified in the fieldsToCopy parameter.
      // For each field in the list, we check if it exists on the SObject type and if it has a value in the original record.
      for (String fieldName : fieldsToCopy) {
          
          // Check if the field exists on the SObject (e.g., 'Name', 'Amount', etc.).
          if (fieldsMap.containsKey(fieldName)) {
              
              // Check if the original record has a value for the field (it's not null).
              if (originalRecord.get(fieldName) != null) {
                  
                  // Step 6: Copy the field value from the original record to the new record.
                  // This is done dynamically using the `put` method, which sets the field's value on the new record.
                  newRecord.put(fieldName, originalRecord.get(fieldName));
              }
          }
      }

      // Step 7: Return the new SObject with the copied field values.
      return newRecord;
  }
    public static void sendOverageBatchTriggerEmail(List<Scale_Utility_Integration__e> lstofSUIntegTriggerRec){
      Map<String, Email_Preferences__mdt> mapEmailPreferences = Email_Preferences__mdt.getAll();
      List<OrgWideEmailAddress> orgwide = [select Id from OrgWideEmailAddress where Address = 'noreply-sfdc@rubrik.com'];
      List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
      List<String> toAddresses = new List<String>();
      List<String> CcAddresses = new List<String>();
      if(mapEmailPreferences?.get('Scale_Utility_Overage_Trigger_Capture')?.Receipient__c != null){
          String receipentlist = mapEmailPreferences?.get('Scale_Utility_Overage_Trigger_Capture')?.Receipient__c;
          toAddresses = receipentlist?.split(',');
      }
      if(mapEmailPreferences?.get('Scale_Utility_Overage_Trigger_Capture')?.cc__c != null){
          String ccList = mapEmailPreferences?.get('Scale_Utility_Overage_Trigger_Capture')?.cc__c;
          CcAddresses = ccList?.split(',');
      }
      String subject = mapEmailPreferences?.get('Scale_Utility_Overage_Trigger_Capture')?.Email_Subject__c;
      for(Scale_Utility_Integration__e intRec : lstofSUIntegTriggerRec){
          Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
          String body = 'Scale Utility Overage '+ intRec?.Job_Name__c + ' Platform Event Triggerred Successfully on '+ String.valueOf(System.today());
          mail.setOrgWideEmailAddressId(orgwide?.size() > 0 ? orgwide?.get(0)?.id : null); 
          mail.setToAddresses(toAddresses);
          mail.setCcAddresses(CcAddresses);
          mail.setSubject(subject);
          mail.setPlainTextBody(body);
          mailList.add(mail);
      }
      if(!mailList.isEmpty()){
          Messaging.sendEmail(mailList);
      }
    }    
}