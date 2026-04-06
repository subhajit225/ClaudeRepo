/*******************************************************************************************************************
* @description       : to generate Entitlement Links, Scale Entitlements and update Contracted checkbox on Order
* @author            : 
* @last modified on  : 09-08-2025
* @last modified by  : Shrutika - PMD Rule
**/
global with sharing class ContractOrders implements Database.Batchable<sObject>, Database.Stateful, System.Schedulable {
    Queueable nextJob; // CSU-444.
    Set<Id> failedOrders = new Set<Id>();
    Set<Id> setQuoteId = new Set<Id>();
    Set<Id> setOldCliCSAT = new Set<Id>();
    List<Error_Logs__c> errorLogs = new List<Error_Logs__c>();
      Map<Id, OrderItem> orderItemDetById = new Map<Id, OrderItem>();
      Map<Id, SBQQ__QuoteLine__c> qliRecById = new Map<Id, SBQQ__QuoteLine__c>(); 
      Public Set<String> exitingLinkedAssetsKey = new Set<String>(); 
    /**
     * Start method to prepare data by querying the Eligible Orders to contract.
     * orderQuery -- > String query prepared and used by querying Database.getQueryLocator method.
     * @description start method
     * @param BC
     * @return list of Orders
     */
    global Database.QueryLocator start(Database.BatchableContext BC) {
      List<string> byPassOrderNum = new List<string>();

      if (System.Label.Bypass_Contracting_Orders != 'NA') {
        byPassOrderNum = System.Label.Bypass_Contracting_Orders.split(',');
      }

      String orderQuery = Constants.CONTRACT_ORDERS_BASE_QUERY;

      if (getBusinessLogic().Follow_Old_ContractOrders_Process__c) {
        orderQuery += Constants.CONTRACT_ORDERS_OLD_FILTERS;
      } else {
        orderQuery += Constants.CONTRACT_ORDERS_NEW_FILTERS;
      }
      // Return the query locator using the constructed query
      return Database.getQueryLocator(orderQuery);
    }
    /**
     * @description getBusinessLogic
     * @return ShGl_DisableBusinessLogic__c
     */
    public ShGl_DisableBusinessLogic__c getBusinessLogic() {
      return ShGl_DisableBusinessLogic__c.getInstance();
    }

    /**
   * @description execute method
   * @param SC
   */
    global void execute(SchedulableContext SC) {
      Database.executeBatch(new ContractOrders(), 1);
    }
    /**
   * @description Execute method to process the list of eligible orders.
   * @param BC
   * @param orders
     */
    global void execute(Database.BatchableContext BC, List<Order> orders) {
      /** gcOfferMDQEntitlementsToCreate is used to clone the OOTB generated entitlement for MDQ product.
       * The reason we are cloing is because Salesforce CPQ create just one entitlement against all the line
       * but business need one entitlement against each line. So, we clone the placehgolder entitlement and create one for each line
       */
      for(Order ord : Orders){ 
        if(ord.Scale_Utility_SKUs_Count__c > 200){
            TriggerControls.disableQuoteLineTrigger = true;
            TriggerControls.disableQuoteTrigger = true;
            List<OrderItem> orderitems = [Select Id from OrderItem where SBQQ__Contracted__c = false and orderId =: ord.id];
            if(orderitems.size() > 200){
              System.enqueueJob(new BulkOrderItemsToContract(ord.id));
              return;
            }
        }
      }
      List<Entitlement> gcOfferMDQEntitlementsToCreate = new List<Entitlement>(); //CSU-65
      Map<Id, List<ContractLineItem>> gcOfferSCIdContractLinesMap = new Map<Id, List<ContractLineItem>>(); //CSU-65 Change
      Map<String, List<ContractLineItem>> gcOfferSCLicenseToContractLines = new Map<String, List<ContractLineItem>>(); //CSU-65 Change
      Map<Id, ReplacementEntSplitManager.EntitlementDetails> origEntIdToWrapper = new Map<Id, ReplacementEntSplitManager.EntitlementDetails>();
      Map<Id, Set<OrderItem>> origEntToNewOrdItems = new Map<Id, Set<OrderItem>>();
      Map<Id, OrderItem> newOrdItemDetail = new Map<Id, OrderItem>();
      Map<Id, List<Entitlement>> repOrderItemToEntitlements = new Map<Id, List<Entitlement>>();
      Savepoint sp = Database.setSavepoint();
      List<String> orderNumbers = new List<String>();
      List<String> exceptionSCOrdersList = new List<String>();
      String orderType;
      List<Order> updateOrdersList = new List<Order>();

          //Summar Release Variables
        Map<String, Set<String>> newSerialNumsByOld = new Map<String, Set<String>>();
        Map<Id, OrderItem> replacementOrRefreshOrRenewalOIs = new Map<Id, OrderItem>();
          Map<Id, List<Entitlement>> entitlementsByOIId = new Map<Id, List<Entitlement>>();

        //Holds the Refresh OIs related old and new ENT details to create the ENT Links
        ReplacementEntSplitManager.RefreshOrderItemsWrapper refreshOIsWrapper = new ReplacementEntSplitManager.RefreshOrderItemsWrapper();
      
      if (String.isNotBlank(Order_control__mdt.getInstance('ExceptionSCOrders').Value__c)) {
        exceptionSCOrdersList = Order_control__mdt.getInstance('ExceptionSCOrders').Value__c.split(',');
      }
      String bypassSplitSKU = String.isNotBlank(Order_control__mdt.getInstance('SKU_With_Split_Renewal_Products')?.Value__c)
        ? Order_control__mdt.getInstance('SKU_With_Split_Renewal_Products').Value__c : null;
      try {
        Set<Id> orderIds = new Set<Id>();
        List<Id> excludeOrderIds = new List<Id>();
        Set<Id> successOrders = new Set<Id>();
        List<Order> lstOfOrders = new List<Order>();
        Set<Id> setQuoteIds = new Set<Id>();
        Map<Id, SBQQ__QuoteLine__c> mapOfCLIToQLI = new Map<Id, SBQQ__QuoteLine__c>();
        Map<Id, ServiceContract> SCToUpdate = new Map<Id, ServiceContract>();
        Map<Id, ContractLineItem> CLITOUpdate = new Map<Id, ContractLineItem>();
        Map<Id, Entitlement> EntToUpdate = new Map<Id, Entitlement>();
        Set<Id> churnLineoldCLI = new Set<Id>();
        List<Asset> lstAssets = new List<Asset>();
        Map<String, Scale_Entitlement__c> mapAssetEntToSELst = new Map<String, Scale_Entitlement__c>(); //insert Scale Asset
        Map<string, Id> olCLIConvProdId = new Map<string, Id>(); // Map to store previous CLI vs v2 converted productId
        Map<String, X0_RCDM_Dates__mdt> rcdmMdt = new Map<String, X0_RCDM_Dates__mdt>();
        for (X0_RCDM_Dates__mdt mdt : X0_RCDM_Dates__mdt.getAll().values()) {
          if (mdt.Product_Name__c != null)
            rcdmMdt.put(mdt.Product_Name__c, mdt);
        }

        Map<id, Error_Logs__c> mapOrderIdWithErrorLog = new Map<id, Error_Logs__c>();
        List<Order> orderList = [
          SELECT
            id,
            (
              SELECT id, Error_Type__c, Order_ID__c, Error_Message__c, CreatedDate
              FROM Dev_Integration_Logs__r
              WHERE Error_Type__c = 'Contract Order Error'
              ORDER BY createddate DESC
              LIMIT 1
            )
          FROM order
          WHERE id IN :Orders
        ];
        // List<Error_Logs__c> failedErrorLogsList = [Select id, Error_Type__c, Order_ID__c,Error_Message__c,CreatedDate from Error_Logs__c where Order_ID__c IN :orderIds and Error_Type__c = 'Contract Order Error' order by createddate desc];
        for (order odr : orderList) {
          //for(Error_Logs__c errorLogs : failedErrorLogsList){}
          if (!mapOrderIdWithErrorLog.Containskey(odr.id) && odr.Dev_Integration_Logs__r.size() > 0) {
            mapOrderIdWithErrorLog.put(odr.id, odr.Dev_Integration_Logs__r[0]);
          }
        }
        for (Error_Logs__c errorLogs : mapOrderIdWithErrorLog.values()) {
          if (errorLogs.CreatedDate.date() == system.Today() &&
            (system.now().hour() - errorLogs.CreatedDate.hour()) < Integer.valueOf(Order_control__mdt.getInstance('Contract_Order_Execute_After_3hrs').Value__c)
          ) {
            excludeOrderIds.add(errorLogs.Order_ID__c);
          }
        }
        List<Order> failedOrdersUpdate = new List<Order>();
        String operationType;
        for (Order ord : orders) {
          orderIds.add(ord.Id);
          orderNumbers.add(ord.OrderNumber);
          if (!excludeOrderIds.Contains(ord.id)) {
            operationType = ord.SC_or_Entitlement_Stage__c;
            updateOrdersList.add(ord);
          }
        }
        if (updateOrdersList.isEmpty()) {return;}

        Set<String> operationTypeSet = new Set<String>(operationType.split(';'));

        Set<String> contractOrdersStageIntersections = new Set<String>{ Constants.SC_ENT_STAGE_CREATE_SERVICE_CONTRACT, Constants.SC_ENT_STAGE_SC_CREATION_FAILED };
        contractOrdersStageIntersections.retainAll(operationTypeSet);

        if (contractOrdersStageIntersections.isEmpty()) {return;}

        for (Order ord : updateOrdersList) {
          failedOrders.add(ord.Id);
          if (!Test.isRunningTest()) {
            ord.SBQQ__Contracted__c = true;
          }
          if (String.isNotBlank(ord.SC_or_Entitlement_Stage__c)) {
            String currentOrderStage = ord?.SC_or_Entitlement_Stage__c.contains(Constants.SC_ENT_STAGE_CREATE_SERVICE_CONTRACT)
              ? Constants.SC_ENT_STAGE_CREATE_SERVICE_CONTRACT
              : Constants.SC_ENT_STAGE_SC_CREATION_FAILED;
            String updatedSCorENTStage = ord.SC_or_Entitlement_Stage__c.replace(
              currentOrderStage,
              CustomEntitlementGenerationQueueable.serviceContractEntStageMap.get(currentOrderStage).successMessage
            );
            ord.SC_or_Entitlement_Stage__c = updatedSCorENTStage;
          }

          if (ord.Is_RWD_Polaris_Quote__c) {
            setQuoteId.add(ord.SBQQ__Quote__c);
          }
          setQuoteIds.add(ord.SBQQ__Quote__c);
        }
        Database.SaveResult[] srList = Database.update(updateOrdersList, false);

        for (Integer i = 0; i < srList.size(); i++) {
          if (srList.get(i).isSuccess()) {
            failedOrders.remove(srList.get(i).Id);
            successOrders.add(srList.get(i).Id);
            }
          if (!srList.get(i).isSuccess() || Test.isRunningTest()) {
            if (!Test.isRunningTest()) {
              Database.Error err = srList.size() > 0 ? srList.get(i).getErrors().get(0) : null;
              errorLogs.add(new Error_Logs__c(Error_Type__c = 'Contract Order Error',Error_Message__c = err?.getMessage() + '\r\n' + err?.getFields() + '\r\n' + 'Order ID: ' + updateOrdersList.get(i).Id,Order_ID__c = updateOrdersList.get(i).Id,Type__c = 'SFDC'));
            }
            String currentStages = updateOrdersList.get(i).SC_or_Entitlement_Stage__c;

            Order failedOrder = new Order(Id = updateOrdersList.get(i).Id);
            if (String.isNotBlank(currentStages)) {
            String currentOrderStage = currentStages.contains(Constants.SC_ENT_STAGE_CREATE_SERVICE_CONTRACT)
              ? Constants.SC_ENT_STAGE_CREATE_SERVICE_CONTRACT : Constants.SC_ENT_STAGE_SC_CREATION_FAILED;
            String updatedSCorENTStage = currentStages.replace(currentOrderStage,CustomEntitlementGenerationQueueable.serviceContractEntStageMap.get(currentOrderStage).successMessage);
            failedOrder.SC_or_Entitlement_Stage__c = updatedSCorENTStage;
            }
            failedOrdersUpdate.add(failedOrder);
          }
        }

        if (!failedOrdersUpdate.isEmpty()) {
          update failedOrdersUpdate;
        }

        if (!successOrders.isEmpty()) {
          lstOfOrders = [
            SELECT
              id,
              Type,
              OrderNumber,
              SD_Status__c,
              Status,
              Actual_Order_Ship_Date__c,
              SBQQ__Contracted__c,
              Polaris_Fulfillment_Status__c,
              AccountId,
              OpportunityId,
              Opportunity.Owner.Email,
              Order_Sub_Type__c,
              SBQQ__Quote__c,
              SBQQ__Quote__r.SBQQ__Type__c,
              ProcessType__c,
              SBQQ__Quote__r.SBQQ__Opportunity2__c,
              SBQQ__Quote__r.Renewal_Opportunity__c,
              Opportunity.Name,
              Opportunity.CloseDate,
              (
                SELECT
                  id,
                  Product2.SBQQSC__EntitlementConversion__c,
                  SBQQ__RequiredBy__c,
                  Previous_Transaction_Reference__c,
                  order.is_Amendment_Order__c,
                  OrderId,
                  Line_Type__c,
                  Order.Associated_Order_Numbers__c,
                  Order.OpportunityId,
                  ServiceDate,
                  EndDate,
                  Global_Commit_Split_ID__c,
                  SBQQ__QuotedQuantity__c,
                  Support_Start_Date__c,
                  Order.Actual_Order_Ship_Date__c,
                          SBQQ__QuoteLine__r.Replacement_Details__c,
                  SBQQ__QuoteLine__r.SubscribedAssetNames__c,
                  Product2.Bundle_Features__c,
                  Product2.License_Category__c,
                  quantity,
                  product2.Product_Subtype__c,
                  product2.Product_Level__c,
                  product2.Product_Type__c,
                  product2.Name,
                  Upgraded_From__c,
                  SerialNumber__c,
                  Program__c,
                  Previous_Contract_Line_Items__c,
                  Global_Commit_ID__c,
                  Product2Id,
                  Order.Order_Sub_Type__c,
                  Order.Line_Types__c
                FROM OrderItems
              )
            FROM Order
            WHERE Id IN :successOrders
          ];
        }
        Map<String, List<Order>> mapQuoteToOrders = new Map<String, List<Order>>();
        Map<Id, ContractLineItem> mapCLIData = new Map<Id, ContractLineItem>();
        set<Id> setOfQuoteids = new Set<Id>();
        Set<String> setOrders = new Set<String>();
        Set<String> SerialNumber = new Set<String>();
        List<Order> goRefreshOrders = new List<Order>();
        Map<Id, Order> mapOfGCOrders = new Map<Id, Order>();
        Set<String> setOldCLI = new Set<String>();
        Boolean emailSend = false;
        Boolean isRefresh = false;
        Set<Id> setAddonLicHWSupQLIs = new Set<Id>();
        List<Order> updateOrdersLst = new List<Order>();
        if (!lstOfOrders.isEmpty()) {
          for (Order objOrder : lstOfOrders) {
            if (objOrder.SD_Status__c != null && objOrder.SD_Status__c == 'ASN Received') {
              updateOrdersLst.add(new Order(Id = objOrder.Id, SD_Status__c = 'Start', SD_Failure_Reason__c = ''));
            }

            if (objOrder.Order_Sub_Type__c == Constants.ORDER_SUB_TYPE_GC_OFFER) {
              mapOfGCOrders.put(objOrder.id, objOrder);
            }
            if (objOrder?.Type == 'Revenue') {
              if (!mapQuoteToOrders.containsKey(objOrder.SBQQ__Quote__c)) {
                mapQuoteToOrders.put(objOrder.SBQQ__Quote__c, new List<Order>{ objOrder });
              } else {
                mapQuoteToOrders.get(objOrder.SBQQ__Quote__c).add(objOrder);
              }
            }

            if (objOrder.Type == 'Revenue') {
              setOrders.add(objOrder.Id);
                      for (OrderItem objOrderItem : objOrder.OrderItems) {
                          orderItemDetById.put(objOrderItem.id, objOrderItem);
                          if (String.isNotBlank(objOrderItem.Previous_Contract_Line_Items__c)) {
                              for (string strString : objOrderItem.Previous_Contract_Line_Items__c.trim().split(',')) {
                    setOldCLI.add(strString.trim());
                  }
                }

                if (objOrderItem.Program__c == 'Refresh' && !isRefresh) {
                  isRefresh = true;
                }
                if (
                  (objOrderItem.Program__c == 'Conversion' ||
                  objOrderItem.Program__c == 'Refresh') &&
                  objOrderItem.Order.Order_Sub_Type__c == null &&
                  objOrder.Type == 'Revenue' &&
                  !emailSend
                ) {
                  emailSend = true;
                }

                Boolean checkIfRSCSku = (objOrderItem?.Product2?.Product_Level__c == 'OnPrem' &&
                (objOrderItem?.Product2?.Product_Subtype__c == 'OnPrem LOD Addon' ||
                objOrderItem?.Product2?.Product_Subtype__c == 'LOD Addon') && objOrder.type == 'Revenue');

                if (
                  (objOrderItem.Program__c != null && (objOrderItem.Program__c == 'Conversion' || objOrderItem.Program__c == 'Refresh' || objOrderItem.Program__c == 'Replaced')) ||
                  checkIfRSCSku ||
                  objOrder.Order_Sub_Type__c == 'Renewal'
                ) {
                  if (String.isNotBlank(objOrderItem.SerialNumber__c)) {
                    for (string strString : objOrderItem.SerialNumber__c.trim().split(',')) {
                      SerialNumber.add(strString.trim());
                    }
                  }
                  if (String.isNotBlank(objOrderItem.Upgraded_From__c)) {
                    for (string strString : objOrderItem.Upgraded_From__c.trim().split(',')) {
                      if (!SerialNumber.contains(strString.trim()))
                        SerialNumber.add(strString.trim());
                    }
                  }
                }
              }
            }
            if (isRefresh) {
              goRefreshOrders.add(objOrder);
            }
          }
        }
        Set<String> dispositionReasons = new Set<String>{ 'Churn', 'Refreshed', 'Refreshed', 'Replaced' };
        if (!mapQuoteToOrders.isEmpty()) {
          for (SBQQ__QuoteLine__c QLI : [
            SELECT
              Id,
              Subscribed_Asset_Name__c,
              Arroyo_Subsumed_Old_Contract_Line_Items__c,
              Disposition_Reason__c,
              Special_Program__c,
              Do_not_Renew__c,//ITNPI-2901
              SBQQ__Product__r.Product_Level__c,
              SBQQ__RequiredBy__c,
              SBQQ__RequiredBy__r.Subscribed_Asset_Name__c,
              SBQQ__Group__r.Name,
              SBQQ__Quote__r.SBQQ__Type__c,
              SBQQ__Quote__r.Is_RWD_Polaris_Quote__c,
              SBQQ__Product__r.Product_Type__c,
              SBQQ__Product__r.Item_Type__c,
              SBQQ__ProductOption__r.Refresh_Default_Option__c, //ITNPI-2901
              SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Level__c,
              SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Type__c,
              SBQQ__RequiredBy__r.SBQQ__Product__r.Item_Type__c,
              (SELECT Id FROM sbqq__OrderProducts__r WHERE SBQQ__Contracted__c = TRUE)  
            FROM SBQQ__QuoteLine__c 
            WHERE SBQQ__Quote__c IN :mapQuoteToOrders.keySet()
            ]) {
              qliRecById.put(QLI.id, QLI);
            if (
    (dispositionReasons.contains(QLI.Disposition_Reason__c) && QLI.SBQQ__Group__r.Name == 'Disposition Quote') || (QLI.Special_Program__c != null)
    ) {
              if (
    QLI.Arroyo_Subsumed_Old_Contract_Line_Items__c != null
    ) {
                for (String cli : QLI.Arroyo_Subsumed_Old_Contract_Line_Items__c.trim().split(',')) {
                  if (mapOfCLIToQLI.containskey(cli?.trim())) {
                    if (mapOfCLIToQLI.get(cli?.trim()).Disposition_Reason__c == 'Converted' && qli.Disposition_Reason__c == 'Renewing' && qli.Special_Program__c == 'Conversion') {
                      mapOfCLIToQLI.put(cli?.trim(), qli);
                    }
                  } else {
                    mapOfCLIToQLI.put(cli?.trim(), qli);
                  }
                  if (QLI.Disposition_Reason__c == 'Churn') {
                    churnLineoldCLI.add(cli.trim());
                  }
                  if (QLI.Disposition_Reason__c == 'Replaced') {
                    olCLIConvProdId.put(QLI.Arroyo_Subsumed_Old_Contract_Line_Items__c.trim(), QLI.SBQQ__Product__c);
                  }
                }
              }
            } else if (string.isBlank(QLI.Disposition_Reason__c) && QLI?.SBQQ__Quote__r?.Is_RWD_Polaris_Quote__c && QLI?.SBQQ__RequiredBy__c != null) {
              if (
                QLI.SBQQ__Product__r?.Product_Level__c == 'Hardware' &&
                QLI.SBQQ__Product__r?.Product_Type__c == 'Add-On Node' &&
                QLI.SBQQ__Product__r?.Item_Type__c == 'Non-inventory Item'
              ) {
                setAddonLicHWSupQLIs.add(QLI.SBQQ__RequiredBy__c);
              }
              if (
                QLI.SBQQ__RequiredBy__r?.SBQQ__Product__r?.Product_Level__c == 'Hardware' &&
                QLI?.SBQQ__RequiredBy__r?.SBQQ__Product__r?.Product_Type__c == 'Add-On Node' &&
                QLI?.SBQQ__RequiredBy__r?.SBQQ__Product__r?.Item_Type__c == 'Non-inventory Item'
              ) {
                setAddonLicHWSupQLIs.add(QLI.Id);
              }
            }
          }
        }
       Map<Id,OrderItem> oldReplacedOrderItemById = new Map<Id,OrderItem>();
       Map<String,Order> globalCommitIToOrder = new Map<String,Order>();   // CSU-444   
       Map<String,String> globalCommitIdToLicenceName = new Map<String,String>(); // CSU-686
        Map<String, ContractLineItem> upgradedQLICLIMap = new Map<String, ContractLineItem>(); // CSU-473 : Defining the Upgrade Variable
        Boolean checkforHwSupportInAmendment = false; // CSU-554 : define for  Hw Line in Service Contract
        Set<String> phantomOrdNo = new Set<String>();
        Map<String, Map<String, Id>> ordNoToOIs = new Map<String, Map<String, Id>>();
        Map<String, ContractLineItem> mapOLIToCLIobjContractLI = new Map<String, ContractLineItem>(); //LicenseSKUData
        Set<Id> inactiveEntIds = new Set<Id>();
        if (!mapQuoteToOrders.isEmpty() || !mapOfCLIToQLI.isEmpty()) {
          for (ContractLineItem eachCLI : [
            SELECT
              Id,
              SBQQSC__OrderProduct__r.SBQQ__RequiredBy__c,
              SBQQSC__OrderProduct__r.Previous_Transaction_Reference__c,
              PA_Quote_Type__c,
              SBQQSC__Dimension__c,
              SBQQSC__OrderProduct__r.order.is_Amendment_Order__c,
              Global_Commit_ID__c,
              Product_Category__c,
              ServiceContractId,
              SBQQSC__OrderProduct__r.OrderId,
              SBQQSC__OrderProduct__r.Line_Type__c,
              SBQQSC__OrderProduct__r.Order.Order_Sub_Type__c,
              SBQQSC__OrderProduct__r.Order.Line_Types__c,
              SBQQSC__OrderProduct__r.Order.Associated_Order_Numbers__c,
              ServiceContract.SBQQSC__Order__r.Order_Sub_Type__c,
              ServiceContract.SBQQSC__Order__r.OpportunityId,
              SBQQSC__QuoteLine__r.SBQQ__Quote__r.Additional_Month_added__c,
              SBQQSC__QuoteLine__r.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c,
              SBQQSC__SegmentIndex__c,
              ServiceContract.SBQQSC__Opportunity__c,
              ServiceContract.SBQQSC__Order__c,
              SBQQSC__QuoteLine__c,
              SBQQSC__QuoteLine__r.SBQQ__Quote__c,
              SBQQSC__QuoteLine__r.SBQQ__Group__r.Name,
              SBQQSC__QuoteLine__r.SBQQ__Quantity__c,
              StartDate,
              EndDate,
              PricebookEntryId,
              Quantity,
              UnitPrice,
              SBQQSC__Account__c,
              SBQQSC__Product__r.Family,
              SBQQSC__Product__r.Eligible_for_RCDM_T__c,
              SBQQSC__Bundle__c,
              SBQQSC__BundledQuantity__c,
              SBQQSC__Product__r.Edition__c,
              SBQQSC__Bundled__c,
              SBQQSC__ComponentDiscountedByPackage__c,
              SBQQSC__CustomerPrice__c,
              SBQQSC__Discount__c,
              SBQQSC__DynamicOptionId__c,
              SBQQSC__ListPrice__c,
              SBQQSC__NetPrice__c,
              SBQQSC__Number__c,
              SBQQSC__OptionLevel__c,
              SBQQSC__Product__r.ProductCode,
              SBQQSC__Product__r.Name,
              SBQQSC__OptionType__c,
              SBQQSC__OrderProduct__c,
              SBQQSC__OriginalQuoteLine__c,
              SBQQSC__OrderProduct__r.Order.OpportunityId,
              SBQQSC__OriginalUnitCost__c,
              SBQQSC__PricingMethod__c,
              SBQQSC__ProductOption__c,
              SBQQSC__Product__c,
              SBQQSC__Product__r.License_Category__c,
              Subscription_Term__c,
              Status,
              SBQQSC__ProrateMultiplier__c,
              SBQQSC__Quantity__c,
              SBQQSC__RegularPrice__c,
              SBQQSC__RenewalPrice__c,
              SBQQSC__RenewalQuantity__c,
              SBQQSC__RequiredById__c,
              SBQQSC__RequiredByProduct__c,
              SBQQSC__RevisedSubscription__c,
              SBQQSC__RootId__c,
              SBQQSC__SegmentEndDate__c,
              SBQQSC__SpecialPrice__c,
              SBQQSC__SubscriptionStartDate__c,
              Licensing_Model__c,
              SBQQSC__OrderProduct__r.Quantity,
              ServiceContract.SBQQSC__Order__r.is_Amendment_Order__c,
              Payment_Options__c,
              Rubrik_Suite__c,
              Support_Type__c,
              SBQQSC__ProductSubscriptionType__c,
              SBQQSC__SubscriptionType__c,
              SBQQSC__HasConsumptionSchedule__c,
              CPQ_Uplift__c,
              ServiceContract.SBQQSC__Opportunity__r.Name,
              MSP_Segment_Product__c,
              Per_Year_Price__c,
              SBQQSC__QuoteLine__r.Line_Type__c,
              SBQQSC__Product__r.Product_Subtype__c,
              SBQQSC__Product__r.Product_Level__c,
              SBQQSC__Product__r.Product_Type__c,
              Global_Commit_Split_ID__c,
              SBQQSC__OrderProduct__r.ServiceDate,
              SBQQSC__OrderProduct__r.EndDate,
              SBQQSC__OrderProduct__r.Program__c,
              SBQQSC__OrderProduct__r.Global_Commit_Split_ID__c,
              SBQQSC__OrderProduct__r.SerialNumber__c,
              SBQQSC__OrderProduct__r.SBQQ__QuotedQuantity__c,
              SBQQSC__OrderProduct__r.Support_Start_Date__c,
              SBQQSC__OrderProduct__r.Order.Actual_Order_Ship_Date__c,
                      SBQQSC__OrderProduct__r.SBQQ__QuoteLine__r.SubscribedAssetNames__c,
                      SBQQSC__OrderProduct__r.SBQQ__QuoteLine__r.Replacement_Details__c
            FROM ContractLineItem
            WHERE SBQQSC__QuoteLine__r.SBQQ__Quote__c IN :mapQuoteToOrders.KeySet() OR Id IN :mapOfCLIToQLI.Keyset()
          ]) {
            if (
              orderIds.contains(eachCLI.SBQQSC__OrderProduct__r.OrderId) &&
              (UtilityClass.isReplacementOrder(eachCLI.SBQQSC__OrderProduct__r.Order) || eachCLI.SBQQSC__OrderProduct__r.Order.Order_Sub_Type__c == 'Renewal') &&
              eachCLI.SBQQSC__OrderProduct__r.Previous_Transaction_Reference__c != null
            ) {
              phantomOrdNo.add(eachCLI.SBQQSC__OrderProduct__r.Order.Associated_Order_Numbers__c);
              List<PreviousTransRefWrapper> wrapper = (List<PreviousTransRefWrapper>) JSON.deserialize(
                eachCLI.SBQQSC__OrderProduct__r.Previous_Transaction_Reference__c,
                List<PreviousTransRefWrapper>.class
              );
              orderType = eachCLI.SBQQSC__OrderProduct__r.Line_Type__c == 'Renewal' ? 'Renewal' : 'Replacement';
              for (PreviousTransRefWrapper wrp : wrapper) {
                if (eachCLI.SBQQSC__OrderProduct__r.Program__c != Constants.PROGRAM_REFRESH) {
                    if (!origEntToNewOrdItems.containsKey(wrp.entId)) {
                      origEntToNewOrdItems.put(wrp.entId, new Set<OrderItem>());
                    }
                    origEntToNewOrdItems.get(wrp.entId).add(eachCLI.SBQQSC__OrderProduct__r);
                }
                newOrdItemDetail.put(eachCLI.SBQQSC__OrderProduct__r.Id, new OrderItem());
                if (wrp?.orderItemId != null) {
                   oldReplacedOrderItemById.put(wrp.orderItemId, null);
                }
                if(wrp.relatedInactiveEntitlements != null && !wrp.relatedInactiveEntitlements.isEmpty()){
                   for (PreviousTransRefWrapper.RelatedInactiveEntitlement inactiveEnt : wrp.relatedInactiveEntitlements){
                      if(inactiveEnt.entitlementId != null){
                        inactiveEntIds.add(inactiveEnt.entitlementId);
                      }
                    }
                }
                
              }
            } else {
              // CSU-473 : Here We are Check If CLI had any Upgrade Line
              Boolean IsUpgraded = false;
              Product2 prod = eachCLI.SBQQSC__Product__r;
              if (prod != null)
                IsUpgraded = (OrderItemTriggerHelper.isScaleUtilityUpgradeSKU(eachCLI.SBQQSC__Product__r));
              if (IsUpgraded) {
                upgradedQLICLIMap.put(eachCLI.SBQQSC__QuoteLine__c, eachCLI);
              }

              // Setting Map to store Licence With Oppty Name
              // Based on Global Commit Id For Naming Multiple Contracts For CSU-686
              if (
                eachCLI.ServiceContract.SBQQSC__Order__r.Order_Sub_Type__c == Constants.ORDER_SUB_TYPE_GC_OFFER &&
                ((eachCLI.SBQQSC__Product__r.Product_Type__c == 'HW Support' && eachCLI.SBQQSC__Product__r.Product_Level__c == 'Support') ||
                (eachCLI.SBQQSC__Product__r.Product_Subtype__c == Constants.PROD_SUB_TYPE_SCALE_MSP &&
                eachCLI.SBQQSC__Product__r.License_Category__c == null))
              ) {
                globalCommitIdToLicenceName.put(eachCLI.Global_Commit_Split_ID__c, eachCLI.SBQQSC__Product__r.Name + ' - ' + eachCLI.ServiceContract.SBQQSC__Opportunity__r.Name);
              }

              mapCLIData.put(eachCLI.Id, eachCLI);
              if (
                eachCLI?.ServiceContract?.SBQQSC__Opportunity__c != null &&
                eachCLI?.ServiceContract?.SBQQSC__Order__r?.OpportunityId != null &&
                eachCLI.ServiceContract.SBQQSC__Opportunity__c != eachCLI.ServiceContract.SBQQSC__Order__r.OpportunityId &&
                !SCToUpdate.containsKey(eachCLI.ServiceContractId) && successOrders.contains(eachCLI?.ServiceContract?.SBQQSC__Order__c)
              ) {
                SCToUpdate.put(eachCLI.ServiceContractId,new ServiceContract(id = eachCLI.ServiceContractId, SBQQSC__Opportunity__c = eachCLI.ServiceContract.SBQQSC__Order__r.OpportunityId));
              }
              if (
                !mapOLIToCLIobjContractLI.containsKey(eachCLI.SBQQSC__OrderProduct__c) &&
                (eachCLI?.SBQQSC__Product__r?.Product_Level__c == 'LOD Software' ||
                eachCLI?.SBQQSC__Product__r?.Product_Level__c == 'Hybrid Software' ||
                (eachCLI?.SBQQSC__Product__r?.Family == 'EDGE' && eachCLI?.SBQQSC__Product__r?.Eligible_for_RCDM_T__c) ||
                (eachCLI?.SBQQSC__Product__r?.Product_Level__c == 'OnPrem' &&
                String.isBlank(eachCLI?.SBQQSC__Product__r?.Product_Subtype__c) &&
                (eachCLI?.SBQQSC__Product__r?.Product_Type__c == 'Foundation Edition' ||
                eachCLI?.SBQQSC__Product__r?.Product_Type__c == 'Business Edition' ||
                eachCLI?.SBQQSC__Product__r?.Product_Type__c == 'Enterprise Edition')))
              ) {
                mapOLIToCLIobjContractLI.put(eachCLI.SBQQSC__OrderProduct__c, eachCLI);
              }
              //CSU-65 Change Start
              if (
                eachCLI.SBQQSC__OrderProduct__r.Order.Order_Sub_Type__c == Constants.ORDER_SUB_TYPE_GC_OFFER &&
                eachCLI.SBQQSC__Product__r.Product_Subtype__c == Constants.PROD_SUB_TYPE_SCALE_MSP &&
                eachCLI.SBQQSC__Product__r.License_Category__c == Constants.PROD_LICENSE_CATEGORY_SAAS
              ) {
                if (!gcOfferSCIdContractLinesMap.containsKey(eachCLI.ServiceContractId)) {
                  gcOfferSCIdContractLinesMap.put(eachCLI.ServiceContractId, new List<ContractLineItem>());
                }
                gcOfferSCIdContractLinesMap.get(eachCLI.ServiceContractId).add(eachCLI);

                String contractAndLicenseKey = eachCLI.ServiceContractId + '-' + eachCLI.SBQQSC__Product__r.Name;
                if (!gcOfferSCLicenseToContractLines.containsKey(contractAndLicenseKey)) {
                  gcOfferSCLicenseToContractLines.put(contractAndLicenseKey, new List<ContractLineItem>());
                }
                gcOfferSCLicenseToContractLines.get(contractAndLicenseKey).add(eachCLI);
              }

              // Collect All Global Commit Ids For Each Licence Bundle - CSU-444
              if (eachCLI.ServiceContract.SBQQSC__Order__r.Order_Sub_Type__c == Constants.ORDER_SUB_TYPE_GC_OFFER) {
                if (eachCLI?.SBQQSC__OrderProduct__r?.order?.is_Amendment_Order__c && eachCLI.SBQQSC__Product__r.Product_Type__c == 'HW Support' && eachCLI.SBQQSC__Product__r.Product_Level__c == 'Support')
                  checkforHwSupportInAmendment = true;
                globalCommitIToOrder.put(eachCLI.Global_Commit_Split_ID__c, eachCLI.SBQQSC__OrderProduct__r.Order);
              }

              //CSU-65 Change End
              if (
                eachCLI.ServiceContract.SBQQSC__Order__r.Order_Sub_Type__c == Constants.ORDER_SUB_TYPE_GC_OFFER &&
                eachCLI.SBQQSC__Product__r.Product_Subtype__c == Constants.PROD_SUB_TYPE_SCALE_MSP &&
                eachCLI.SBQQSC__Product__r.License_Category__c == Constants.PROD_LICENSE_CATEGORY_SAAS
              ) {
                eachCLI.EndDate = eachCLI.SBQQSC__SegmentEndDate__c;
                if (eachCLI.ServiceContract.SBQQSC__Order__r.is_Amendment_Order__c) {
                  eachCLI.Quantity = eachCLI.SBQQSC__OrderProduct__r.Quantity;
                } else {
                  eachCLI.Quantity = eachCLI.SBQQSC__QuoteLine__r.SBQQ__Quantity__c;
                } /**
                     * Since the end date on the Segment Order Items can't be changed so Oi was not having an extra support month
                     * in the standard start and end date that's why CLI also not having that extra month 
                     * so this next block handles the same

                    if(eachCLI.SBQQSC__SegmentIndex__c == eachCLI.SBQQSC__QuoteLine__r.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c && 
                      eachCLI.SBQQSC__QuoteLine__r.SBQQ__Quote__r.Additional_Month_added__c == true
                    ) {
                      eachCLI.EndDate = eachCLI.SBQQSC__SegmentEndDate__c.addMonths(1);
                    } */
                CLITOUpdate.put(eachCLI.Id, eachCLI);
              }
              if (eachCLI.SBQQSC__QuoteLine__c != null && setAddonLicHWSupQLIs.contains(eachCLI.SBQQSC__QuoteLine__c)) {
                eachCLI.Product_Category__c = 'Virtual Addon';
                CLITOUpdate.put(eachCLI.Id, eachCLI);
              }
            }
          }
        }

        if (!phantomOrdNo.isEmpty() || !newOrdItemDetail.KeySet().isEmpty() || !oldReplacedOrderItemById.KeySet().isEmpty()) {
          for (OrderItem oi : [
            SELECT
              Id,
              Credit_Amount__c,
              EndDate,
              Previous_Transaction_Reference__c,
              Order.Order_Accepted_Timestamp__c,
              Order.Actual_Order_Ship_Date__c,
              Program__c,
              Order.Associated_Order_Numbers__c,
              Product2Id,
              Product2.Name,
              Quantity,
              Order.OrderNumber,
              (SELECT id, End_of_Paid_Term__c, Payment_Schedule__c FROM Order_Item_Extensions__r)
            FROM OrderItem
            WHERE Order.OrderNumber IN :phantomOrdNo OR Id IN :newOrdItemDetail.KeySet() OR Id IN :oldReplacedOrderItemById.KeySet()
          ]) {
            if (phantomOrdNo.contains(oi.order.ordernumber)) {
            PreviousTransRefWrapper.PhantomPrevLineDetail prevLine = (PreviousTransRefWrapper.PhantomPrevLineDetail) JSON.deserialize(
                (oi.Previous_Transaction_Reference__c),
              PreviousTransRefWrapper.PhantomPrevLineDetail.class
              ); //RV
              if (!ordNoToOIs.containsKey(oi.Order.OrderNumber)) {
                ordNoToOIs.put(oi.Order.OrderNumber, new Map<String, Id>());
              }
              Map<String, Id> ordPCToId = ordNoToOIs.get(oi.Order.OrderNumber);
              ordPCToId.put(oi.Product2.Name + prevLine.entId, oi.Id); //RV
              ordNoToOIs.put(oi.Order.OrderNumber, ordPCToId);
            }
            if (newOrdItemDetail.keySet().contains(oi.id)) {
              newOrdItemDetail.put(oi.id, oi);
            }
            if (oldReplacedOrderItemById.containsKey(oi.id)) {
              oldReplacedOrderItemById.put(oi.id, oi);
            }
          }
        }
        /**
         * Calling SplitGCOfferServiceContractQueueable Class If Upgrade Sku is found FOR CSU-473
         */
        if (!upgradedQLICLIMap.isEmpty()) {
          nextJob = new SplitGCOfferServiceContractQueueable(upgradedQLICLIMap, nextJob);
        }

        /**
         * Checking Size of Global Commit Ids
         * as that will determine Number Of Service Contracts Needs to Be Created For CSU-444
         */
        if (!globalCommitIToOrder.isEmpty() && globalCommitIToOrder.keyset().size() > 1 || checkforHwSupportInAmendment) {
          Id gcCommitOrderId = new List<Id>(orderIds).get(0);
          nextJob = new SplitGCOfferServiceContractQueueable(globalCommitIToOrder.keyset(), gcCommitOrderId, globalCommitIdToLicenceName, nextJob);
        }

        List<Entitlement> lstEntitlement = new List<Entitlement>();
        Map<String, Entitlement> mapRCDMEntitlement = new Map<String, Entitlement>();
        List<Entitlement> duplicateEntitlementsToDelete = new List<Entitlement>();
        List<Entitlement_Links__c> lstUpsertEntitlementLinks = new List<Entitlement_Links__c>();
        Map<Id, Scale_Entitlement__c> mapUpdateScaleEnt = new Map<Id, Scale_Entitlement__c>();
        Map<Id, Entitlement> mapIdToupdateOldEntitlement = new Map<Id, Entitlement>();
        Map<Id, ContractLineItem> mapIdToUpdateOldCLI = new Map<Id, ContractLineItem>();
     	Boolean isNewSaleEnt = false;
    
        if (!setQuoteIds.isEmpty() || (!setOrders.isEmpty() && !SerialNumber.isEmpty()) || !mapOfCLIToQLI.isEmpty() || !setOldCLI.isEmpty() || !mapCLIData?.values().isEmpty() || !gcOfferSCIdContractLinesMap.isEmpty() || !origEntToNewOrdItems.keySet().isEmpty() || !newOrdItemDetail.KeySet().isEmpty() || !inactiveEntIds.isEmpty()) {
          set<Id> cliIdSet = mapOfCLIToQLI.keyset();
          set<Id> scIdSet = gcOfferSCIdContractLinesMap.keyset();
          Set<Id> setNewEntitlements = new Set<Id>();
          Set<Id> entIdSet = new Set<Id>();
          Map<String, Id> assetNoToId = new Map<String, Id>();
          Set<String> setEntType = new Set<String>{ Constants.ENT_TYPE_PMC, Constants.ENT_TYPE_PHONE_SUPPORT };
          Schema.SObjectType objectType = Entitlement.getSObjectType();
          List<String> entFields = new List<String>(objectType.getDescribe().fields.getMap().keySet());
          String soqlStr =
            'SELECT Order_Service_Item__r.SBQQ__OrderedQuantity__c,Order_Service_Item__r.product2.Upgrade_Path__c,Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Level__c,Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.Usable_Capacity__c,Order_Service_Item__r.Entitlement_Id__c, Order_Service_Item__r.SBQQ__QuoteLine__r.Line_Type__c,Order_Service_Item__r.Product2.Custom_Renewal_Attributes__c, Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Type__c, ContractLineItem.Resync_Line__c, Order_Service_Item__r.TPH_Quantity__c, ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__c, ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.Arroyo_Subscribed_Asset_Name__c, ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.SubscribedAssetNames__c,Order_Service_Item__r.Order.Is_RWD_Polaris_Quote__c,Order_Service_Item__r.Order.Type,Order_Service_Item__r.Order.Order_Status__c,ContractLineItem.SBQQSC__QuoteLine__r.SubscribedAssetNames__c,Order_Service_Item__r.SBQQ__RequiredBy__c,Order_Service_Item__r.product2.SBQQSC__EntitlementConversion__c,ContractLineItem.SBQQSC__QuoteLine__r.Arroyo_Subscribed_Asset_Name__c,Order_Service_Item__r.Previous_Contract_Line_Items__c,ContractLineItem.SBQQSC__QuoteLine__r.Subscribed_Asset_Name__c,ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.Subscribed_Asset_Name__c,asset.SerialNumber,asset.Program__c,asset.UsageEndDate,asset.serial_number__c,Order_Service_Item__r.SerialNumber__c,Order_Service_Item__r.Quantity,Order_Service_Item__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,Order_Service_Item__r.Product2Id,Order_Service_Item__r.Order.Order_Sub_Type__c,Order_Service_Item__r.SBQQ__QuoteLine__r.Disposition_Reason__c,Order_Service_Item__r.product2.Product_Level__c,Product__r.Product_Type__c, Product__r.Product_Level__c,Order_Service_Item__r.Order.Program__c,' + //RM
            'Order_Service_Item__r.SBQQ__QuoteLine__r.Replacement_Details__c, Order_Service_Item__r.Order.Actual_Order_Ship_Date__c,Product__r.Name,Product__r.Product_Subtype__c,Product__r.License_Category__c, ContractLineItem.SBQQSC__RequiredById__c,ContractLineItem.Product_Category__c, Order_Service_Item__r.Upgraded_From__c,Order_Service_Item__r.Product2.Product_Subtype__c, Order_Service_Item__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQSC__ContractLineItem__c,' +
            'Order_Service_Item__r.Order.SBQQ__Quote__c,Order_Service_Item__r.OrderId,Order_Service_Item__r.product2.ProductCode,Order_Service_Item__r.Program__c,ContractLineItem.LineItemNumber, ContractLineItem.SBQQSC__OrderProduct__r.Order.OpportunityId, ContractLineItem.SBQQSC__OrderProduct__r.Order.Opportunity.Name,ContractLineItem.SBQQSC__OrderProduct__r.Order.Order_Sub_Type__c,Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__RequiredBy__c, Order_Service_Item__r.SBQQ__QuoteLine__c,ContractLineItem.SBQQSC__Product__r.Product_Level__c, ContractLineItem.SBQQSC__Product__r.Product_Type__c,ContractLineItem.SBQQSC__Product__r.Product_Subtype__c,ContractLineItem.SBQQSC__TerminatedDate__c,ContractLineItem.Quantity,ContractLineItem.SBQQSC__RenewalQuantity__c,ContractLineItem.SBQQSC__Quantity__c,ContractLineItem.ServiceContractId,ContractLineItem.ServiceContract.SBQQSC__RenewalQuoted__c,ContractLineItem.SBQQSC__RootId__c,Product__r.Gorefresh_Mark_SW_End_Date__c,Product__r.SBQQSC__EntitlementConversion__c,ContractLineItem.EndDate,Order_Service_Item__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__QuoteLine__r.Disposition_Reason__c,Order_Service_Item__r.product2.License_Subtype__c, Order_Service_Item__r.product2.Product_Type__c, Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c, Order_Service_Item__r.Order.SBQQ__Quote__r.Manual_Fulfillment_Quote__c, Order_Service_Item__r.product2.Family, ContractLineItem.SBQQSC__Product__r.SBQQSC__EntitlementConversion__c    ,       ServiceContract.SBQQSC__Order__r.Order_Sub_Type__c, ' +
                    ' Order_Service_Item__r.SBQQ__RequiredBy__r.Product2.Product_Level__c,Order_Service_Item__r.Previous_Transaction_Reference__c, Order_Service_Item__r.Line_Type__c,Order_Service_Item__r.SBQQ__RequiredBy__r.SerialNumber__c, Order_Service_Item__r.SBQQ__RequiredBy__r.Upgraded_From__c,Order_Service_Item__r.SBQQ__RequiredBy__r.Program__c,Order_Service_Item__r.Order.ProcessType__c,(SELECT Id, Asset__r.SerialNumber,Type__c FROM Scale_Entitlements__r),Product__r.Edition__c, ' +
            String.join(entFields, ',') +
          ' FROM Entitlement where Type  IN : setEntType  AND (Order_Service_Item__r.Order.SBQQ__Quote__c IN: setQuoteIds OR Order_Service_Item__r.OrderId IN: setOrders OR Asset.SerialNumber IN: SerialNumber OR Asset.serial_number__c IN: SerialNumber OR ContractLineItemId IN: setOldCLI OR ContractLineItemId IN: cliIdSet OR ServiceContractID IN: scIdSet OR Id IN: inactiveEntIds) ORDER BY Id';

          List<Entitlement> entListQuery = Database.query(String.escapeSingleQuotes(soqlStr));
          Map<Id, List<Entitlement_Links__c>> entLinksByCliId = new Map<Id, List<Entitlement_Links__c>>();
          Set<Id> replacedOrgCLIs = new Set<Id>();
          Set<Id> setOldProducts = new Set<Id>();
          Set<Id> setNewProducts = new Set<Id>();
          Map<String, Polaris_SKU_Mapping_V2__c> mapProductToPolarisMappings = new Map<String, Polaris_SKU_Mapping_V2__c>();
          Map<Id, Entitlement> entMapquery = new Map<Id, Entitlement>(entListQuery);
        Map<Id, Entitlement> inactiveEntbyId = new Map<Id, Entitlement>();
          for (Entitlement objEntitlement : entListQuery) {
                    OrderItem newEntOI = objEntitlement?.Order_Service_Item__r;
            String oldENTCLI = objEntitlement?.ContractLineItemId != null ? String.valueOf(objEntitlement.ContractLineItemId).trim().substring(0, 15) : null;
                    String newOIId = objEntitlement?.Order_Service_Item__c;

                    Boolean isNewEnt = setQuoteIds.contains(objEntitlement.Order_Service_Item__r.Order.SBQQ__Quote__c);
                    Boolean isNewReplacementENT = isNewEnt && CONSTANTS.REPLACEMENT_PROGRAMS.contains(objEntitlement?.Order_Service_Item__r?.Program__c);
                    Boolean isNewRefreshENT = isNewEnt && objEntitlement?.Order_Service_Item__r?.Program__c == CONSTANTS.PROGRAM_REFRESH;
                    Boolean isNewRenewalENT = isNewEnt && objEntitlement?.Order_Service_Item__r?.Line_Type__c == Constants.ORDER_TYPE_RENEWAL;
                    
                    List<PreviousTransRefWrapper> wrapper;
                    if (newEntOI != null && !isNewSaleEnt && orderIds.contains(newEntOI?.OrderId) && UtilityClass.isNewSaleOrderItem(newEntOI)) {
                      isNewSaleEnt = true;
                    }
                    if (inactiveEntIds.contains(objEntitlement.Id)){
                        inactiveEntbyId.put(objEntitlement.id, objEntitlement);
                    }
                    
                    if(objEntitlement?.Order_Service_Item__r != null && setQuoteIds.contains(objEntitlement.Order_Service_Item__r.Order.SBQQ__Quote__c)){
                        
                    if (objEntitlement?.Order_Service_Item__r?.Previous_Transaction_Reference__c != null) {
                        wrapper = UtilityClass.getPreviousLineDetails(objEntitlement?.Order_Service_Item__r);
                    }

                    if (wrapper != null && !wrapper.isEmpty()) {
                     if (isNewRefreshENT || isNewReplacementENT || isNewRenewalENT) {
                            for (PreviousTransRefWrapper wrp : wrapper) {
                                if (String.isBlank(wrp.entId)) continue;

                                // Framing Refresh OIs data for the entitlement link creation
                                if (isNewRefreshENT && newOIId != null) {
                                    if (!refreshOIsWrapper.oldENTIdsByNewOI.containsKey(newOIId)) {
                                    refreshOIsWrapper.oldENTIdsByNewOI.put(newOIId, new Set<Id>());
                                    }
                                    refreshOIsWrapper.oldENTIdsByNewOI.get(newOIId).add(wrp.entId);
                            if(String.isNotBlank(wrp.orderItemId)){
                                refreshOIsWrapper.origOrdItmIds.add(wrp.orderItemId);
                            }
                                }

                                // Frame a mapping between old ENT and new ENT Ids to create the entitlement link between the Refresh Delta and Replacement License
                        if ((isNewReplacementENT || isNewRenewalENT) && UtilityClass.IsLicenseSku(objEntitlement.Product__r)) {
                                    if (!refreshOIsWrapper.newEntIdsByOriginalENTId.containsKey(wrp.entId)) {
                                    refreshOIsWrapper.newEntIdsByOriginalENTId.put(wrp.entId, new Set<Id>());
                                    }
                                    refreshOIsWrapper.newEntIdsByOriginalENTId.get(wrp.entId).add(objEntitlement.Id);
                                }
                            }
                        }
                    }

                    // Capture refresh entitlement details for entitlement link creation
                    if (isNewRefreshENT && objEntitlement.Order_Service_Item__r.Previous_Transaction_Reference__c != null) {
                        if (!refreshOIsWrapper.newENTsByNewOI.containsKey(objEntitlement.Order_Service_Item__c)) {
                            refreshOIsWrapper.newENTsByNewOI.put(objEntitlement.Order_Service_Item__c, new Set<Entitlement>());
                        }
                        refreshOIsWrapper.newENTsByNewOI.get(objEntitlement.Order_Service_Item__c).add(objEntitlement);
                        
                    }
                        
              setNewProducts.add(objEntitlement?.Order_Service_Item__r?.product2Id);
                        //Framing data to handle the Replacement/Renewal + Refresh scenarios
                if (
                  objEntitlement?.Order_Service_Item__r != null &&
                            String.isNotBlank(objEntitlement.Order_Service_Item__r?.Previous_Transaction_Reference__c) &&
                            objEntitlement.Order_Service_Item__r?.Upgraded_From__c != null &&
                            (isNewRefreshENT || isNewReplacementENT || isNewRenewalENT)
                ) {
                  OrderItem orderItem = objEntitlement.Order_Service_Item__r;

                            // For non-Aspen, take serial numbers from Hardware OI 
                            OrderItem OIWithSN = orderItem.SBQQ__RequiredBy__r != null && orderItem.Order.ProcessType__c != 'Aspen'
                                    ? orderItem?.SBQQ__RequiredBy__r
                                    : orderItem;

                  // If it's a REFRESH program, get new assets mapped by old serial numbers
                            if (isNewRefreshENT) {
                                UtilityClass.getNewAssetsByOldAssetMapping(OIWithSN, newSerialNumsByOld);
                                refreshOIsWrapper.newSerialNumsByOld = newSerialNumsByOld;
                  }

                  //Preparing data to handle Delta & License Line
                            if (!replacementOrRefreshOrRenewalOIs.containsKey(orderItem.Id)) {
                            replacementOrRefreshOrRenewalOIs.put(orderItem.Id, orderItem);
                    }
                            if (!entitlementsByOIId.containsKey(orderItem.Id)) {
                            entitlementsByOIId.put(orderItem.Id, new List<Entitlement>{});
                    }
                            entitlementsByOIId.get(orderItem.Id).add(objEntitlement);
                        }
                    } else if (setOldCLI.contains(objEntitlement?.ContractLineItemId) || (String.isNotBlank(oldENTCLI) && setOldCLI.contains(oldENTCLI))) {
                        setOldProducts.add(objEntitlement?.Order_Service_Item__r?.product2Id);
                    }

                    //To Avoid duplicate Linked Asset Creation
                    if (objEntitlement.Scale_Entitlements__r != null && objEntitlement.Scale_Entitlements__r.size() > 0) {
                      for (Scale_Entitlement__c scaleEnt : objEntitlement.Scale_Entitlements__r) {
                        if (scaleEnt.Asset__r != null && scaleEnt.Asset__r?.SerialNumber != null) {
                          String entAssetKey = objEntitlement.Id + '-' + scaleEnt.Asset__r?.SerialNumber;
                                exitingLinkedAssetsKey.add(entAssetKey); //This is to hold the existing linked assets key to avoid duplicates
                      }
                    }
                  }

                    //Framing old V1 license data to create a linked asset with the new serial number in the case of a refresh (V1 → V2).
                    String entAssetKey = objEntitlement?.Asset != null && objEntitlement?.Asset.SerialNumber != null ? objEntitlement.Id + '-' + objEntitlement?.Asset?.SerialNumber : null;
                    if (
                        entAssetKey != Null && 
                        !exitingLinkedAssetsKey.contains(entAssetKey) &&
                        UtilityClass.isV1LicenseProduct(objEntitlement?.Product__r)
                    ) {
                        ReplacementEntSplitManager.oldV1Entitlements.put(objEntitlement.Id, objEntitlement);
                }

                    
                    if(!olCLIConvProdId.isEmpty()){
              setNewProducts.addall(olCLIConvProdId.values());
            }
            if (
              objEntitlement?.Product__r?.Product_Level__c != null &&
              ((objEntitlement?.Product__r?.Product_Level__c == 'Support' && objEntitlement?.Product__r?.Product_Type__c == 'RCDM Support') ||
              (objEntitlement?.Product__r?.Product_Level__c == 'LOD Software' ||
              objEntitlement?.Product__r?.Product_Level__c == 'Hybrid Software' ||
              (objEntitlement?.Product__r?.Product_Level__c == 'OnPrem' &&
              (objEntitlement?.Product__r?.Product_Subtype__c == null || objEntitlement?.Product__r?.Product_Subtype__c == 'OnPrem LOD Addon') &&
              (objEntitlement?.Product__r?.Product_Type__c == 'Foundation Edition' ||
              objEntitlement?.Product__r?.Product_Type__c == 'Business Edition' ||
              objEntitlement?.Product__r?.Product_Type__c == 'Enterprise Edition'))))
            ) {
              entIdSet.add(objEntitlement.Id);
            } else {
              SerialNumber.add(objEntitlement.Asset.SerialNumber);
            }
            //If it is an Original Entitlement
            if (origEntToNewOrdItems.keyset() != null && origEntToNewOrdItems.keyset().contains(objEntitlement.Id)) {
              entIdSet.add(objEntitlement.Id);
              if (objEntitlement.ContractLineItemId != null && !replacedOrgCLIs.contains(objEntitlement.ContractLineItemId)) {
                replacedOrgCLIs.add(objEntitlement.ContractLineItemId);
              }
              ReplacementEntSplitManager.EntitlementDetails origEntWrapDet = new ReplacementEntSplitManager.EntitlementDetails();
              origEntWrapDet.orgEntRec = objEntitlement;
              origEntWrapDet.newEntitlementsByNewOrdItemId = new Map<Id, List<Entitlement>>();
              for (OrderItem oi : origEntToNewOrdItems.get(objEntitlement.Id)) {
                origEntWrapDet.newEntitlementsByNewOrdItemId.put(oi.id, new List<Entitlement>());
                if(origEntWrapDet.orderId == null) {
                    origEntWrapDet.orderId = oi.orderId;
                }
              }
              origEntWrapDet.orderType = orderType;
              origEntIdToWrapper.put(objEntitlement.Id, origEntWrapDet);
            } else if (newOrdItemDetail.KeySet() != null && newOrdItemDetail.KeySet().contains(objEntitlement.Order_Service_item__c)) {
              //If it is a Replaced or Renewed Entitlement
              entIdSet.add(objEntitlement.Id);
              if (!repOrderItemToEntitlements.containsKey(objEntitlement.Order_Service_item__c)) {
                repOrderItemToEntitlements.put(objEntitlement.Order_Service_item__c, new List<Entitlement>());
              }
              repOrderItemToEntitlements.get(objEntitlement.Order_Service_item__c).add(objEntitlement);
            } else {
              //CSU-65 Change Start
              if (!gcOfferSCIdContractLinesMap.isEmpty() && gcOfferSCIdContractLinesMap.containskey(objEntitlement.ServiceContractID)) {
                if (objEntitlement.Product__c == null && objEntitlement.Order_Service_Item__c == null) {
                  String contractAndLicenseKey = objEntitlement.ServiceContractID + '-' + objEntitlement.Name;
                  if(gcOfferSCLicenseToContractLines.containskey(contractAndLicenseKey)){
                  for (ContractLineItem cliObj : gcOfferSCLicenseToContractLines.get(contractAndLicenseKey)) {
                    Entitlement entCloneObj = objEntitlement.clone(false, true, false, false);
                    entCloneObj.ContractLineItemId = cliObj.Id;
                    entCloneObj.Order_Service_Item__c = cliObj.SBQQSC__OrderProduct__c;
                    entCloneObj.Product__c = cliObj.SBQQSC__Product__c;
                    entCloneObj.StartDate = cliObj.StartDate;
                    entCloneObj.EndDate = cliObj.EndDate;
                    entCloneObj.Quantity__c = cliObj.Quantity;
                    entCloneObj.SubType__c = Constants.ENT_SUBTYPE_RUBRIK_SUPPORT;
                    gcOfferMDQEntitlementsToCreate.add(entCloneObj);
                  }
                  }
                  duplicateEntitlementsToDelete.add(objEntitlement);
                }
              }
              //CSU-65 Change End
              lstEntitlement.add(objEntitlement);
              if (rcdmMdt.containsKey(objEntitlement.Order_Service_item__r.Product2.ProductCode)) {
                if (!mapRCDMEntitlement.containsKey(objEntitlement.Order_Service_item__c + '-' + objEntitlement.Product__c)) {
                  mapRCDMEntitlement.put(objEntitlement.Order_Service_item__c + '-' + objEntitlement.Product__c, objEntitlement);
                  if (EntToUpdate.containsKey(objEntitlement.Id)) {
                    EntToUpdate.get(objEntitlement.Id).AssetId = null;
                  } else {
                    EntToUpdate.put(objEntitlement.Id, new Entitlement(Id = objEntitlement.Id, AssetId = null));
                  }
                } else {
                  duplicateEntitlementsToDelete.add(objEntitlement);
                }
              }

              if (objEntitlement.Renewal_Category__c != 'Churn' && churnLineoldCLI.contains(objEntitlement.ContractLineItemId)) {
                EntToUpdate.put(objEntitlement.id, new entitlement(id = objEntitlement.id, Renewal_Category__c = 'Churn'));
              }
            }
          }
          if (!setOldProducts.isEmpty() && !setNewProducts.isEmpty()) {
            for (Polaris_SKU_Mapping_V2__c objPolarisSKU : [
              SELECT id, Old_Product__c, Old_Product__r.ProductCode, New_Product__c, New_Product__r.ProductCode, Quantity_Ratio__c
              FROM Polaris_SKU_Mapping_V2__c
              WHERE Quantity_Ratio__c > 1 AND Old_Product__c IN :setOldProducts AND New_Product__c IN :setNewProducts ]) {
              mapProductToPolarisMappings.put(objPolarisSKU.Old_Product__c + '-' + objPolarisSKU.New_Product__c, objPolarisSKU);
            }
          }
          if (!replacedOrgCLIs.isEmpty()) {
            for (Entitlement_Links__c entLink : [
              SELECT
                id,
                Quantity__c,
                Previous_Entitlement__r.Asset.SerialNumber,
                Renewed_Entitlement__r.Asset.SerialNumber,
                Previous_Entitlement__r.Order_Service_Item__r.Quantity,
                Renewed_Entitlement__r.Order_Service_Item__r.Quantity,
                Renewed_Entitlement__r.AccountId,
                Previous_Entitlement__r.AccountId,
                Previous_Entitlement__r.StartDate,
                Renewed_Entitlement__r.StartDate,
                Type__c,
                Previous_Entitlement__r.Name,
                Renewed_Entitlement__r.Name,
                Previous_Entitlement__r.ContractLineItem.SBQQSC__RenewalQuantity__c,
                Renewed_Entitlement__r.ContractLineItem.SBQQSC__RenewalQuantity__c,
                Previous_Entitlement__r.Product__c,
                Renewed_Entitlement__r.Product__c,
                Renewed_Entitlement__c,
                Renewed_Entitlement__r.order_service_item__r.serialnumber__c,
                Previous_Entitlement__r.order_service_item__r.serialnumber__c,
                Renewed_Entitlement__r.Product__r.Product_Level__c,
                Previous_Entitlement__r.Product__r.Product_Level__c,
                Renewed_Entitlement__r.id,
                Renewed_Entitlement__r.ContractLineItemId,
                Previous_Entitlement__c,
                Previous_Entitlement__r.ContractLineItemId,
                Previous_Entitlement__r.Terminated_Date__c,
                Renewed_Entitlement__r.Terminated_Date__c,
                Renewed_Entitlement__r.Entitlement_Status__c,
    			Previous_Entitlement__r.Entitlement_Status__c,
                Renewed_Entitlement__r.Renewal_Category__c,
                Previous_Entitlement__r.Renewal_Category__c,
                Renewed_Entitlement__r.Quantity__c,
                Previous_Entitlement__r.Quantity__c,
                Renewed_Entitlement__r.EndDate,
                Previous_Entitlement__r.EndDate,
    			Renewal_Category__c,
                Renewed_Entitlement__r.ServicecontractId,
    		    Previous_Entitlement__r.ServicecontractId,
    		    Renewed_Entitlement__r.Status,
    			Previous_Entitlement__r.Status,
                Renewed_Entitlement__r.Product__r.Product_Type__c,
                Previous_Entitlement__r.Product__r.Product_Type__c,
                Renewed_Entitlement__r.Product__r.Product_Subtype__c,
                Previous_Entitlement__r.Product__r.Product_Subtype__c
              FROM Entitlement_Links__c
              WHERE Renewed_Entitlement__r.ContractLineItemId IN :replacedOrgCLIs OR Previous_Entitlement__r.ContractLineItemId IN :replacedOrgCLIs
              ORDER BY createddate ASC
            ]) {
              if (!entLinksByCliId.containskey(entLink.Renewed_Entitlement__r.ContractLineItemId)) {
                entLinksByCliId.put(entLink.Renewed_Entitlement__r.ContractLineItemId, new List<Entitlement_Links__c>{ entLink });
              } else {
                entLinksByCliId.get(entLink.Renewed_Entitlement__r.ContractLineItemId).add(entLink);
              }
            }
          }
          //Set<Id> survEnts = new Set<Id>();
          for (Id entId : origEntIdToWrapper.keySet()) {
            ReplacementEntSplitManager.EntitlementDetails updatedOrigEntWrapper = ReplacementEntSplitManager.getSurvivingEnt(
              orderItemDetById,
              origEntIdToWrapper.get(entId),
              entLinksByCliId,
              newOrdItemDetail,
              repOrderItemToEntitlements,
              oldReplacedOrderItemById,
    		  origEntIdToWrapper.keySet(),
    		  errorLogs
            );
            origEntIdToWrapper.put(entId, updatedOrigEntWrapper);
            if (updatedOrigEntWrapper != null) {
              if (updatedOrigEntWrapper.survivingEnt != null) {
                entIdSet.add(updatedOrigEntWrapper.survivingEnt.id);
              }
            }
          }
          for (Asset objAsset : [SELECT Id, SerialNumber FROM Asset WHERE SerialNumber IN :SerialNumber]) {
            lstAssets.add(objAsset);
            assetNoToId.put(objAsset.SerialNumber, objAsset.Id);
          }
          Map<Id, List<Scale_Entitlement__c>> entToLinkedAsset = new Map<Id, List<Scale_Entitlement__c>>();
          List<Entitlement_Links__c> entLinksToCreate = new List<Entitlement_Links__c>();
                  List<Scale_Entitlement__c> linkedAstToUpsert = new List<Scale_Entitlement__c>();
          List<Scale_Entitlement__c> linkedAssetToDelete = new List<Scale_Entitlement__c>();
          Map<Id, ContractLineItem> cliMap = new Map<Id, ContractLineItem>();
          Map<Id, set<String>> assetSNForEnts = new Map<Id, set<String>>();
          Map<Id, Asset> assetsToUpdate = new Map<Id, Asset>();
          if (!entIdSet.isEmpty()) {
            for (Scale_Entitlement__c se : [
              SELECT Id, Type__c, Asset__c, Asset__r.SerialNumber, Renewal_Category__c, Entitlement__c, Contract_Line_Item__c
              FROM Scale_Entitlement__c
              WHERE Entitlement__c IN :entIdSet
            ]) {
              if (!entToLinkedAsset.containsKey(se.Entitlement__c)) {
                entToLinkedAsset.put(se.Entitlement__c, new List<Scale_Entitlement__c>());
              }
              entToLinkedAsset.get(se.Entitlement__c).add(se);
              assetNoToId.put(se.Asset__r.SerialNumber, se.Asset__c);
            }
            for (id entid : entIdSet) {
              if (entMapquery != null && entMapquery.containskey(entid) && entMapquery.get(entid).AssetId != null) {
                if (!assetSNForEnts.containskey(entid)) {
                  assetSNForEnts.put(entid, new Set<String>{ entMapquery.get(entid).Asset.SerialNumber });
                } else {
                  assetSNForEnts.get(entid).add(entMapquery.get(entid).Asset.SerialNumber);
                }
              }
            }
          }

            if (
              !lstEntitlement.isEmpty() &&
              ((origEntToNewOrdItems.keySet().isEmpty() && refreshOIsWrapper?.oldENTIdsByNewOI.isEmpty() && newSerialNumsByOld.values().isEmpty()) || isNewSaleEnt)
            ) {
            getFilteredEntitlements(
              duplicateEntitlementsToDelete,
              gcOfferMDQEntitlementsToCreate,
              mapAssetEntToSELst,
              lstAssets,
              lstEntitlement,
              mapRCDMEntitlement,
              setQuoteIds,
              setOrders,
              setOldCLI,
              mapOfCLItoQLI,
              SerialNumber,
              mapCLIData?.values(),
              SCToUpdate,
              mapOLIToCLIobjContractLI,
              mapQuoteToOrders,
              rcdmMdt,
              olCLIConvProdId,
              setNewEntitlements,
              gcOfferSCIdContractLinesMap,
              bypassSplitSKU,
              EntToUpdate,
              lstUpsertEntitlementLinks,
              mapUpdateScaleEnt,
              mapIdToupdateOldEntitlement,
              mapIdToUpdateOldCLI,
              mapProductToPolarisMappings
            );

            if ((!lstOfOrders.isEmpty() && emailSend) || Test.isRunningTest()) {
              sendEmailToRenewalOwner(lstEntitlement, lstOfOrders);
            }
          }

          if (!origEntToNewOrdItems.KeySet().isEmpty()) {
            ReplacementEntSplitManager.processEntSplitBasedOnReplacmentFramework(
              orderItemDetById,
              repOrderItemToEntitlements,
              origEntIdToWrapper,
              entToLinkedAsset,
              assetNoToId,
              ordNoToOIs,
              entLinksToCreate,
              linkedAstToUpsert,
              cliMap,
              linkedAssetToDelete,
              mapProductToPolarisMappings,
              assetSNForEnts,
              qliRecById,
    		      assetsToUpdate,
              inactiveEntbyId,
              errorLogs
            );
          }

                // DML for linkedAstToUpsert and entLinksToCreate must be completed prior to calling syncLinkedAssetsForRefreshAndReplacementLicenses.
                if (!linkedAstToUpsert.isEmpty()) {
                    upsert linkedAstToUpsert;
                }
                if (!entLinksToCreate.isEmpty()) {upsert entLinksToCreate;}

                if (!newSerialNumsByOld.isEmpty() && UtilityClass.hasAtLeastOneNonEmptyValue(newSerialNumsByOld) ) {
                  Set<Scale_Entitlement__c> scaleENTsToUpsert = new Set<Scale_Entitlement__c>();
                  ReplacementEntSplitManager manager = new ReplacementEntSplitManager();
                  manager.syncLinkedAssetsForRefreshAndReplacementLicenses(
                    newSerialNumsByOld,
                    replacementOrRefreshOrRenewalOIs.values(),
                    entitlementsByOIId,
                    new Map<String, Asset>(),
                    null,
                    scaleENTsToUpsert,
                    assetsToUpdate,
                    exitingLinkedAssetsKey,
                    true
                  ); 
        
                  if (!scaleENTsToUpsert.isEmpty()) {
                     upsert new List<Scale_Entitlement__c>(scaleENTsToUpsert);
                   } 
                }
                
               if (!assetsToUpdate.values().isEmpty()) {
                    update assetsToUpdate.values();
                  }
               if (!cliMap.values().isEmpty()) {update cliMap.values();}

                List<Entitlement_Links__c> refreshENTLinksInsert = new List<Entitlement_Links__c>();

                // Create Entitlement links for the Refresh OrderItem only if the Previous Transaction Reference is not blank
                if (!refreshOIsWrapper?.oldENTIdsByNewOI.isempty() && !refreshOIsWrapper?.newENTsByNewOI.isempty() && !entMapquery.isEmpty()) {
                    if (!mapProductToPolarisMappings.isEmpty()) {
                        refreshOIsWrapper.mapProductToPolarisMappings.putall(mapProductToPolarisMappings);
                    }
                    refreshOIsWrapper.allOldNewENTs.putALL(entMapquery);
                    ReplacementEntSplitManager.createEntitlementLinksForRefresh(refreshOIsWrapper);
                    if (!refreshOIsWrapper.entLinksToCreate.isEmpty()) {
                        refreshENTLinksInsert.addALL(refreshOIsWrapper.entLinksToCreate);
                    }
                    if (!refreshOIsWrapper.oldEntitlementsUpdate.isEmpty()) {
                        mapIdToupdateOldEntitlement.putAll(refreshOIsWrapper.oldEntitlementsUpdate);
                    }
                }

                //Insert the Refresh Entitlement Links
                if (!refreshENTLinksInsert.isEmpty()) {
                    insert refreshENTLinksInsert;
                }
                if(!linkedAssetToDelete.isEmpty()){delete linkedAssetToDelete;}

          //insert Linked Asset
          if (!lstUpsertEntitlementLinks.isEmpty()) {
            insert lstUpsertEntitlementLinks;
          }
          //update Old Scale Entitlements Renewal Category
          if (!mapUpdateScaleEnt.isEmpty()) {
            update mapUpdateScaleEnt.values();
          }
          //update Old Entitlement Renewal Category
          if (!mapIdToupdateOldEntitlement.isEmpty()) {
            update mapIdToupdateOldEntitlement.values();
          }
          //update OldCLI and TerminatedDate
          if (!mapIdToUpdateOldCLI.isEmpty()) {
            SBQQ.TriggerControl.disable();
            update mapIdToUpdateOldCLI.Values();
            SBQQ.TriggerControl.enable();
          }
          if (!goRefreshOrders.isEmpty()) {
            terminateOldAssets(goRefreshOrders, lstEntitlement, SCToUpdate, orderIds, mapCLIData, CLITOUpdate);
          }
          if (!updateOrdersLst.isEmpty()) {
            update updateOrdersLst;
          }
          if (mapCLIData != null && !mapCLIData?.isempty()) {
            for (Id cliId : churnLineoldCLI) {
              CLITOUpdate.put( cliId, new ContractLineItem( Id = cliId, Resync_Line__c = 'Required', SBQQSC__RenewalQuantity__c = 0.00,
                  SBQQSC__TerminatedDate__c = (mapCLIData.containskey(cliId) && mapCLIData.get(cliId)?.EndDate != null) ? mapCLIData?.get(cliId)?.EndDate : system.today()));
            }
          }
          if (!mapOfGCOrders.isEmpty()) {
            Map<Id, Id> mapOrdIdtoSCId = new Map<Id, Id>();
            for (ServiceContract sc : [SELECT id, SBQQSC__Order__c FROM ServiceContract WHERE SBQQSC__Order__c IN :mapOfGCOrders.keySet()]) {
              mapOrdIdtoSCId.put(sc.SBQQSC__Order__c, sc.id);
            }
            if (!mapOrdIdtoSCId.isEmpty()) {
              createScaleUtilityClusReg(mapOfGCOrders.values(), mapOrdIdtoSCId);
            }
          }
          if (!EntToUpdate.isEmpty()) {
            update EntToUpdate.values();
          }
          if (!SCToUpdate.isEmpty()) {
            update SCToUpdate.values();
          }
          if (!CLITOUpdate.isEmpty()) {
            SBQQ.TriggerControl.disable();
            update CLITOUpdate.values();
            SBQQ.TriggerControl.enable();
          }

          if (!mapAssetEntToSELst.isEmpty()) {
            insert mapAssetEntToSELst.Values();
          }
        }
        
        }
        Catch(Exception err){
            String orderId = (updateOrdersList.size() > 0) ? updateOrdersList[0].Id : null;
            Integer maxLengthErrorMsg = Schema.SObjectType.Error_Logs__c.fields.Error_Message__c.getLength();
            String errorMsg = err.getMessage() + '\r\n' + err.getStackTraceString();
            errorMsg = errorMsg != null ? errorMsg.left(maxLengthErrorMsg) : errorMsg;
            errorLogs.add(new Error_Logs__c(Order_ID__c = orderId, Error_Type__c = 'Contract Order Error', Error_Message__c = errorMsg, Type__c = 'SFDC'));
            if((exceptionSCOrdersList.isEmpty()) || (String.isNotBlank(orderNumbers[0]) && !exceptionSCOrdersList.isEmpty() && !exceptionSCOrdersList.contains(orderNumbers[0]))) {
          Database.rollback(sp);

          if (!updateOrdersList.isEmpty() && updateOrdersList[0] != null) {
            String currentStages = updateOrdersList[0].SC_or_Entitlement_Stage__c;
              if (String.isNotBlank(currentStages)) {
                String currentOrderStage = currentStages.contains(Constants.SC_ENT_STAGE_CREATE_SERVICE_CONTRACT)
                ? Constants.SC_ENT_STAGE_CREATE_SERVICE_CONTRACT : Constants.SC_ENT_STAGE_SC_CREATION_FAILED;
                String updatedSCorENTStage = currentStages.replace(currentOrderStage,CustomEntitlementGenerationQueueable.serviceContractEntStageMap.get(currentOrderStage).successMessage);
              update new Order(Id = updateOrdersList[0].Id, SC_or_Entitlement_Stage__c = updatedSCorENTStage);
            }
          }
        }
      }
    }
    /**
   * @description Finish method
   * @param BC
   */
    global void finish(Database.BatchableContext BC){
        try{ 
        
        if(!failedOrders.isEmpty() || Test.isRunningTest()){
          Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();
          OrgWideEmailAddress emailAddress = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'SFDC No Reply'];
          Id senderEmailId = emailAddress.Id;

          Email_Preferences__mdt mdt = [SELECT Id, Receipient__c, cc__c, Email_Subject__c FROM Email_Preferences__mdt WHERE MasterLabel = 'Orders Failed to Contract' LIMIT 1];

          String emailTextHtml = '<p>Hi Team, Following Orders failed to contract.</p><p>';
          for (Id ordId : failedOrders) {
            emailTextHtml += ordId + ', ';
          }
          emailTextHtml = emailTextHtml.removeEnd(',');
          emailTextHtml += '</p>';
          Messaging.SingleEmailMessage message = generateEmail(emailTextHtml, senderEmailId, mdt);
          messages.add(message);
            if (messages.size() > 0 && !Test.isRunningTest()) {
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
          }
        }

        Boolean isExecutepublishGovOrgSyncEvents = Boolean.valueOf(Order_control__mdt.getInstance('isExecutepublishGovOrgSyncEvents').Value__c);

        if (isExecutepublishGovOrgSyncEvents) {
          Set<Id> orderReadyTosyncwithGovOrg = new Set<Id>();
          DateTime timeNow = System.now(); // Get the time now
          DateTime X30MinutesBefore = timeNow.addMinutes(-30); // Subtract 30 minutes from it

          List<order> lstRSCGorders = [
            SELECT Id, Ready_for_Gov_Sync__c, RSC_G_Enabled__c, LastModifiedDate, Order_Status__c
            FROM Order
            WHERE Order_Status__c = 'Order Accepted' AND Ready_for_Gov_Sync__c = 'Sync Ready' AND RSC_G_Enabled__c = TRUE AND LastModifiedDate < :X30MinutesBefore
          ];
          if (!lstRSCGorders.isEmpty()) {
            for (Order objOrder : lstRSCGorders) {
              orderReadyTosyncwithGovOrg.add(objOrder.Id);
            }

            UtilityClass.publishGovOrgSyncEvents(orderReadyTosyncwithGovOrg, 'Order');
            if (!OrderHandler.lstErrorLogs.isEmpty()) {
              errorLogs.addAll(OrderHandler.lstErrorLogs);
            }
          }
        }
      } catch (Exception e) {
        errorLogs.add(new Error_Logs__c(Error_Type__c = 'Contract Order Error', Error_Message__c = e.getMessage() + '\r\n' + e.getStackTraceString(), Type__c = 'SFDC'));
      }

      try {
        ManufacturingEntitlementsDateUpdate ob = new ManufacturingEntitlementsDateUpdate();
        ob.updateDates();
        if (!setOldCliCSAT.isEmpty()) {
          UpdateCSATOnQuoteOppBatch csatUpdateBatch = new UpdateCSATOnQuoteOppBatch(setOldCliCSAT);
          Database.executeBatch(csatUpdateBatch);
        }
      } catch (Exception e) {
        errorLogs.add(new Error_Logs__c(Error_Type__c = 'Contract Order Error', Error_Message__c = e.getMessage() + '\r\n' + e.getStackTraceString(), Type__c = 'SFDC'));
      }

      try {
        String orderQuery;
        if (!getBusinessLogic().Follow_Old_ContractOrders_Process__c) {
          orderQuery = Constants.CONTRACT_ORDERS_BASE_QUERY;
          orderQuery += Constants.CONTRACT_ORDERS_FINISH_FILTERS;
        }
        List<Order> remainingOrderStagesToProcess = String.isNotBlank(orderQuery) ? Database.Query(orderQuery) : null;

        if (remainingOrderStagesToProcess != null && !remainingOrderStagesToProcess.isEmpty()) {
          for (Order ord : remainingOrderStagesToProcess) {
            this.nextJob = new CustomEntitlementGenerationQueueable(new List<Order>{ ord }, ord.SC_or_Entitlement_Stage__c, this.nextJob);
          }
        }
        /*
         * For CSU-444 we are calling Queueable Class to Split into Service Contracts Based on Global Commit Ids and Custom Entitlement creation and updation.
         */
        if (this.nextJob != null) {
          System.enqueueJob(this.nextJob);
        }
      } catch (Exception e) {
        errorLogs.add(new Error_Logs__c( Error_Type__c = 'ContractOrders: CustomEntitlementGenerationQueueable',Error_Message__c = e.getMessage() + '\r\n' + e.getStackTraceString(), Type__c = 'SFDC' ) );
      }

      try {
        Order_control__mdt disableBookingScheduler = Order_control__mdt.getInstance('Disable_Old_Booking_Scheduler');
        if (disableBookingScheduler?.Value__c != null && boolean.valueOf(disableBookingScheduler?.Value__c)) {
          Bookingbatch bb = new Bookingbatch();
          Database.executeBatch(bb, 1);
        }
      } catch (Exception e) {
        errorLogs.add(new Error_Logs__c(Error_Type__c = 'ContractOrders: BookingBatch ', Error_Message__c = e.getMessage() + '\r\n' + e.getStackTraceString(), Type__c = 'SFDC'));
      }

       if (!errorLogs.isEmpty()) {
        database.insert(errorLogs, false);
      }
    }

    private Messaging.SingleEmailMessage generateEmail(String htmlBody, Id orgWideEmailAddressId, Email_Preferences__mdt mdt) {
      Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
      message.toAddresses = new List<String>{ mdt.Receipient__c };
      message.setSubject(mdt.Email_Subject__c);
      message.setHtmlBody(htmlBody);
      message.setOrgWideEmailAddressId(orgWideEmailAddressId);
      if (String.isNotBlank(mdt.cc__c)) {
        message.setCcAddresses(new List<String>{ mdt.cc__c });
      }
      return message;
    }
    /***********SKU-49-50******************** */

    //first record - avoid duplicate
    /**
   * @description Finish method
   * @param duplicateEntitlementsToDelete
   * @param entitlementListToCreate
   * @param mapAssetEntToSELst
   * @param lstAssets
   * @param lstEntitlement
   * @param mapRCDMEntitlement
   * @param setQuoteIds
   * @param setOrders
   * @param setOldCLI
   * @param mapOfCLItoQLI
   * @param SerialNumber
   * @param lstCLIData
   * @param SCToUpdate
   * @param mapOLIToCLIobjContractLI
   * @param mapQuoteToOrders
   * @param rcdmMdt
   * @param olCLIConvProdId
   * @param setNewEntitlements
   * @param gcOfferSCIdContractLinesMap
   * @param bypassSplitSKU
   * @param EntToUpdate
   * @param lstUpsertEntitlementLinks
   * @param mapUpdateScaleEnt
   * @param mapIdToupdateOldEntitlement
   * @param mapIdToUpdateOldCLI
   * @param mapProductToPolarisMappings
   */
    public void getFilteredEntitlements(
      List<Entitlement> duplicateEntitlementsToDelete,
      List<Entitlement> entitlementListToCreate,
      Map<String, Scale_Entitlement__c> mapAssetEntToSELst,
      List<Asset> lstAssets,
      List<Entitlement> lstEntitlement,
      Map<String, Entitlement> mapRCDMEntitlement,
      Set<Id> setQuoteIds,
      Set<String> setOrders,
      Set<String> setOldCLI,
      Map<Id, SBQQ__QuoteLine__c> mapOfCLItoQLI,
      Set<String> SerialNumber,
      List<ContractLineItem> lstCLIData,
      Map<Id, ServiceContract> SCToUpdate,
      Map<String, ContractLineItem> mapOLIToCLIobjContractLI,
      Map<String, List<Order>> mapQuoteToOrders,
      Map<String, X0_RCDM_Dates__mdt> rcdmMdt,
      Map<string, Id> olCLIConvProdId,
      Set<Id> setNewEntitlements,
      Map<Id, List<ContractLineItem>> gcOfferSCIdContractLinesMap,
      String bypassSplitSKU,
      Map<Id, Entitlement> EntToUpdate,
      List<Entitlement_Links__c> lstUpsertEntitlementLinks,
      Map<Id, Scale_Entitlement__c> mapUpdateScaleEnt,
      Map<Id, Entitlement> mapIdToupdateOldEntitlement,
      Map<Id, ContractLineItem> mapIdToUpdateOldCLI,
      Map<String, Polaris_SKU_Mapping_V2__c> mapProductToPolarisMappings
    ) {
      Map<String, Entitlement> mapNewEntIdToEntitlement = new Map<String, Entitlement>(); // First Records
      List<Entitlement> lstOldEntitlement = new List<Entitlement>(); //Old Entitlement
      List<ServiceContract> lstClonedServiceContractInsert = new List<ServiceContract>(); // insert ServiceContract
      List<ContractLineItem> lstInsertContractLines = new List<ContractLineItem>(); //insert ContractLineItems
      Map<String, Id> mapSCSourceIdToNewId = new Map<String, Id>(); //add OlD vs New SC Ids
      Map<Id, Id> mapCLISourceIdToNewId = new Map<Id, Id>(); // add old vs New CLI Ids
      Map<Id, Id> mapCLIToOrderId = new Map<Id, Id>(); // add OldCLI vs OrderId
      List<Entitlement> updateLstEntitlement = new List<Entitlement>(); // update Entitlement with New CLIId
      Map<String, OrderItem> mapOrderItemUpdate = new Map<String, OrderItem>(); // update OrderItem with New CLI Ids
      Set<Id> setOldSplitSKuEntIds = new Set<Id>();
      Map<String, ContractLineItem> mapLicenseSkuToRCDM = new Map<String, ContractLineItem>(); //serviceContractOfLicenseSku
      Map<String, Map<String, List<ContractLineItem>>> mapSCIdToLineTypeToAllCLI = new Map<String, Map<String, List<ContractLineItem>>>();
      Map<String, List<ContractLineItem>> mapSCIdToCLIAll = new Map<String, List<ContractLineItem>>(); //All Contract Lines per SC
      Map<String, Entitlement> mapHWToOldSWSkusEntitlement = new Map<String, Entitlement>(); //Old SW Entitlement
      List<ContractLineItem> lstDeleteContractLines = new List<ContractLineItem>(); // deleteContractLines
      List<ServiceContract> lstDeleteServiceContract = new List<ServiceContract>(); // delete SC
      Map<String, Id> mapEntAssetToScEnt = new Map<String, Id>(); //LinkAssset
      // Set<Id> setOldProducts = new Set<Id>();
      // Set<Id> setNewProducts = new Set<Id>();
      Set<String> setOldEntitlement = new Set<String>(); //Old entitlement Id
      Map<Id, Entitlement> upgradeSKUOldToNewEnt = new Map<Id, Entitlement>();
      for (Entitlement objEntitlement : lstEntitlement) {
        if (setQuoteIds.contains(objEntitlement.Order_Service_Item__r.Order.SBQQ__Quote__c)) {
          // Skip Entitlements belonging to the Summer Release flow,
          // as they are handled separately
          if (UtilityClass.isValidSummerReleaseOrderItem(objEntitlement.Order_Service_Item__r)) {
          	continue;
          }
          if (
            objEntitlement?.Order_Service_Item__r?.product2?.Upgrade_Path__c != null &&
            objEntitlement?.Order_Service_Item__r?.Entitlement_Id__c != null &&
            setOrders.contains(objEntitlement?.Order_Service_Item__r?.OrderId)
          ) {
            lstUpsertEntitlementLinks.add(
              new Entitlement_Links__c(
                Renewed_Entitlement__c = objEntitlement.Id,
                Previous_Entitlement__c = objEntitlement?.Order_Service_Item__r?.Entitlement_Id__c?.trim(),
                Quantity__c = objEntitlement.Order_Service_Item__r.Quantity,
                Renewal_Category__c = 'Upgraded',
                Type__c = 'Upgrade'
              )
            );
          }
          if ('One per quote line'.equalsIgnoreCase(objEntitlement?.Order_Service_Item__r?.product2?.SBQQSC__EntitlementConversion__c)) {
            string serialNumberProduct = String.isNotBlank(objEntitlement.Order_Service_Item__r.SerialNumber__c)
              ? objEntitlement.Order_Service_Item__r.SerialNumber__c.trim() + '-' + objEntitlement.Order_Service_Item__c
              : objEntitlement.Order_Service_Item__c;
            Boolean isRCDM = (rcdmMdt.containsKey(objEntitlement.Order_Service_item__r.Product2.ProductCode) &&
            objEntitlement.Order_Service_Item__r.SBQQ__QuoteLine__r.Line_Type__c != 'Renewal');

            if (!mapNewEntIdToEntitlement.containskey(serialNumberProduct)) {
              if (!isRCDM)
                mapNewEntIdToEntitlement.put(serialNumberProduct.trim(), objEntitlement);
              setNewEntitlements.add(objEntitlement.Id);
            }
          } else if ('One per unit'.equalsIgnoreCase(objEntitlement?.Order_Service_Item__r?.product2?.SBQQSC__EntitlementConversion__c) /*&& objEntitlement.AssetId != null*/) {
            if (!mapNewEntIdToEntitlement.containskey(objEntitlement.AssetId + '-' + objEntitlement.Order_Service_Item__r.Product2Id)) {
              mapNewEntIdToEntitlement.put(objEntitlement.AssetId + '-' + objEntitlement.Order_Service_Item__r.Product2Id, objEntitlement);
            }
          }
        } else {
          if (
            (objEntitlement?.Product__r?.Product_Level__c == 'Support' && objEntitlement?.Product__r?.Product_Type__c == 'RCDM Support') ||
            (objEntitlement?.Product__r?.Product_Level__c == 'LOD Software' ||
            objEntitlement?.Product__r?.Product_Level__c == 'Hybrid Software' ||
            (objEntitlement?.Product__r?.Product_Level__c == 'OnPrem' &&
            (objEntitlement?.Product__r?.Product_Subtype__c == null ||
            objEntitlement?.Product__r?.Product_Subtype__c == 'OnPrem LOD Addon' ||
            objEntitlement?.Product__r?.Product_Subtype__c == 'LOD Addon') &&
            (objEntitlement?.Product__r?.Product_Type__c == 'Foundation Edition' ||
            objEntitlement?.Product__r?.Product_Type__c == 'Business Edition' ||
            objEntitlement?.Product__r?.Product_Type__c == 'Enterprise Edition')))
          ) {
            setOldEntitlement.add(objEntitlement?.Id);
          }
          String oldENTCLI = objEntitlement?.ContractLineItemId != null ? String.valueOf(objEntitlement.ContractLineItemId).trim().substring(0, 15) : null;
          if (setOldCLI.contains(objEntitlement?.ContractLineItemId) || (String.isNotBlank(oldENTCLI) && setOldCLI.contains(oldENTCLI))) {
            lstOldEntitlement.add(objEntitlement);
            if (bypassSplitSKU != null) {
              if (
                objEntitlement?.Order_Service_Item__r?.product2Id != null &&
                bypassSplitSKU.contains(objEntitlement?.Order_Service_Item__r?.product2Id) &&
                !setOldSplitSKuEntIds.contains(objEntitlement?.Id)
              ) {
                setOldSplitSKuEntIds.add(objEntitlement?.Id);
              }
            }
          } else if (
            objEntitlement?.Product__r?.Product_Type__c == 'RCDM Support' &&
            (objEntitlement?.Product__r?.Product_Level__c == null || objEntitlement?.Product__r?.Product_Level__c == 'Support') &&
            objEntitlement?.Order_Service_Item__r?.SBQQ__QuoteLine__r?.SBQQ__RequiredBy__c != null
          ) {
            mapHWToOldSWSkusEntitlement.put(objEntitlement?.Order_Service_Item__r?.SBQQ__QuoteLine__r?.SBQQ__RequiredBy__c, objEntitlement);
          }
        }
      }
      if (!duplicateEntitlementsToDelete.isEmpty()) {
        try {
          delete duplicateEntitlementsToDelete;
        } catch (exception e) {
          UtilityClass.logException(e, 'contractOrders', 'getFilteredEntitlements', 'Entitlement', null, 'SFDC', false);
        }
      }
      if (!entitlementListToCreate.isEmpty()) {
        try {
          insert entitlementListToCreate;
        } catch (exception e) {
          UtilityClass.logException(e, 'contractOrders', 'getFilteredEntitlements', 'Entitlement', null, 'SFDC', false);
        }
        Map<Id, List<Entitlement>> newGCOfferSegmentEntitlementsByProductId = new Map<Id, List<Entitlement>>();
        for (Entitlement gcOfferEntitlement : [
          SELECT
            Id,
            Name,
            EndDate,
            Product__c,
            Product__r.Scale_Utility_Product__c,
            Product__r.Product_Type__c,
            ServiceContractId,
            Product__r.Product_Subtype__c,
            Product__r.License_Category__c,
            Order_Service_Item__c,
            Order_Service_Item__r.Order.Order_Sub_Type__c
          FROM Entitlement
          WHERE
            Id IN :entitlementListToCreate
            AND Product__r.Product_Subtype__c = :Constants.PROD_SUB_TYPE_SCALE_MSP
            AND Product__r.License_Category__c = :Constants.PROD_LICENSE_CATEGORY_SAAS
          ORDER BY EndDate ASC
        ]) {
          if (!newGCOfferSegmentEntitlementsByProductId.containsKey(gcOfferEntitlement.Product__c)) {
            newGCOfferSegmentEntitlementsByProductId.put(gcOfferEntitlement.Product__c, new List<Entitlement>());
          }
          newGCOfferSegmentEntitlementsByProductId.get(gcOfferEntitlement.Product__c).add(gcOfferEntitlement);
        }

        if (newGCOfferSegmentEntitlementsByProductId != null && !newGCOfferSegmentEntitlementsByProductId.isEmpty()) {
          //call for generate ent links
          generateEntitlementLinks(newGCOfferSegmentEntitlementsByProductId);
        }
      }

      if (!lstCLIData.isEmpty()) {
        for (ContractLineItem objContractLI : lstCLIData) {
          if (mapQuoteToOrders.containskey(objContractLI.SBQQSC__QuoteLine__r.SBQQ__Quote__c)) {
    		    // Skip Clis belonging to the Summer Release flow,
                // as they are handled separately
               if (UtilityClass.isValidSummerReleaseOrderItem(objContractLI.SBQQSC__OrderProduct__r)) {
                    continue;
                }  
            if (!mapSCIdToCLIAll.containskey(objContractLI.ServiceContractId)) {
              mapSCIdToCLIAll.put(objContractLI.ServiceContractId, new List<ContractLineItem>{ objContractLI });
            } else {
              mapSCIdToCLIAll.get(objContractLI.ServiceContractId).add(objContractLI);
            }
            if (
              rcdmMdt.containsKey(objContractLI?.SBQQSC__Product__r?.ProductCode) &&
              objContractLI?.SBQQSC__OrderProduct__r?.SBQQ__RequiredBy__c != null &&
              !mapOLIToCLIobjContractLI.isEmpty() &&
              mapOLIToCLIobjContractLI.containskey(objContractLI.SBQQSC__OrderProduct__r?.SBQQ__RequiredBy__c) &&
              mapOLIToCLIobjContractLI.get(objContractLI.SBQQSC__OrderProduct__r?.SBQQ__RequiredBy__c).ServiceContractId != null /*&&
               objContractLI.ServiceContractId != mapOLIToCLIobjContractLI.get(objContractLI.SBQQSC__OrderProduct__r?.SBQQ__RequiredBy__c).ServiceContractId*/
            ) {
              mapLicenseSkuToRCDM.put(objContractLI.SBQQSC__OrderProduct__r?.SBQQ__RequiredBy__c, objContractLI);
            } else {
              if (
                !rcdmMdt.containsKey(objContractLI?.SBQQSC__Product__r?.ProductCode) &&
                (objContractLI?.ServiceContract?.SBQQSC__Order__r?.Order_Sub_Type__c == null ||
                objContractLI?.ServiceContract?.SBQQSC__Order__r?.Order_Sub_Type__c == 'Renewal')
              ) {
                if (mapSCIdToLineTypeToAllCLI.containsKey(objContractLI.ServiceContractId)) {
                  if (mapSCIdToLineTypeToAllCLI.get(objContractLI.ServiceContractId).containsKey(objContractLI?.SBQQSC__QuoteLine__r?.Line_Type__c)) {
                    mapSCIdToLineTypeToAllCLI.get(objContractLI.ServiceContractId).get(objContractLI?.SBQQSC__QuoteLine__r?.Line_Type__c).add(objContractLI);
                  } else {
                    mapSCIdToLineTypeToAllCLI.get(objContractLI.ServiceContractId)
                      .put(objContractLI?.SBQQSC__QuoteLine__r?.Line_Type__c, new List<ContractLineItem>{ objContractLI });
                  }
                } else {
                  mapSCIdToLineTypeToAllCLI.put(
                    objContractLI.ServiceContractId,
                    new Map<String, List<ContractLineItem>>{ objContractLI?.SBQQSC__QuoteLine__r?.Line_Type__c => new List<ContractLineItem>{ objContractLI } }
                  );
                }
              }
            }
          }
        }
      }

      Boolean isScaleAsset = true;
      Set<String> setServiceContractId = new Set<String>();
      Map<String, ContractLineItem> mapSCIdToOnlyNewCLI = new Map<String, ContractLineItem>();
      Map<String, ContractLineItem> mapSCIdToOnlyRenewalCLI = new Map<String, ContractLineItem>();

      if (!mapSCIdToLineTypeToAllCLI.isEmpty()) {
        for (String strSCID : mapSCIdToLineTypeToAllCLI.keySet()) {
          if (mapSCIdToLineTypeToAllCLI.containskey(strSCID) && mapSCIdToLineTypeToAllCLI.get(strSCID) != null && mapSCIdToLineTypeToAllCLI.get(strSCID).size() > 1) {
            setServiceContractId.add(strSCId);
            for (String strLineType : mapSCIdToLineTypeToAllCLI.get(strSCId).keySet()) {
              if (strLineType == 'New') {
                mapSCIdToOnlyNewCLI.put(strSCId, mapSCIdToLineTypeToAllCLI.get(strSCId).get(strLineType)[0]);
              } else if (strLineType == 'Renewal') {
                mapSCIdToOnlyRenewalCLI.put(strSCId, mapSCIdToLineTypeToAllCLI.get(strSCId).get(strLineType)[0]);
              }
            }
            isScaleAsset = false;
          }
        }
      }
      if (isScaleAsset) {
        if (!mapNewEntIdToEntitlement.isEmpty()) {
          createScaleAsset(setOldEntitlement, mapEntAssetToScEnt, mapAssetEntToSELst, setQuoteId, mapNewEntIdToEntitlement, lstAssets, mapCLISourceIdToNewId);
        }
      } else {
        lstClonedServiceContractInsert = createServiceContractRecords(lstClonedServiceContractInsert, setServiceContractId, mapSCIdToOnlyNewCLI, mapSCIdToOnlyRenewalCLI);
        if (!lstClonedServiceContractInsert.isEmpty()) {
          upsert lstClonedServiceContractInsert;
          for (ServiceContract objSC : lstClonedServiceContractInsert) {
            mapSCSourceIdToNewId.put(objSC.getCloneSourceId(), objSC.Id);
          }
        }
      }
      if ((!mapLicenseSkuToRCDM.isEmpty() && !mapOLIToCLIobjContractLI.isEmpty()) || !mapSCSourceIdToNewId.isEmpty()) {
        lstInsertContractLines = createCLIRecords(
          lstInsertContractLines,
          mapCLIToOrderId,
          mapLicenseSkuToRCDM,
          mapOLIToCLIobjContractLI,
          mapSCSourceIdToNewId,
          mapSCIdToLineTypeToAllCLI
        );
        if (!lstInsertContractLines.isEmpty()) {
          insert lstInsertContractLines;
          for (ContractLineItem objCLI : lstInsertContractLines) {
            mapCLISourceIdToNewId.put(objCLI.getCloneSourceId(), objCLI.Id);
          }
        }
      }

      if (!mapNewEntIdToEntitlement.isEmpty() && !mapCLISourceIdToNewId.isEmpty() && !isScaleAsset) {
        createScaleAsset(setOldEntitlement, mapEntAssetToScEnt, mapAssetEntToSELst, setQuoteId, mapNewEntIdToEntitlement, lstAssets, mapCLISourceIdToNewId);
      }
      if (!mapCLISourceIdToNewId.isEmpty()) {
        mapOrderItemUpdate = updateOrderItem(mapCLISourceIdToNewId, mapCLIToOrderId, mapOrderItemUpdate);
        if (!mapOrderItemUpdate.isEmpty()) {
          update mapOrderItemUpdate.Values();
        }
      }
      //Insert SU Entitllements and generate ent links
      if (!mapCLISourceIdToNewId.isEmpty()) {
        updateLstEntitlement = updateEntitlements(
          updateLstEntitlement,
          mapSCSourceIdToNewId,
          mapCLISourceIdToNewId,
          mapNewEntIdToEntitlement,
          mapOLIToCLIobjContractLI,
          mapRCDMEntitlement
        );
        if (!updateLstEntitlement.isEmpty()) {
          update updateLstEntitlement;
        }
        lstDeleteContractLines = deleteContractLines(lstDeleteContractLines, mapCLISourceIdToNewId);
        if (!lstDeleteContractLines.isEmpty()) {
          SBQQ.TriggerControl.disable();
          delete lstDeleteContractLines;
          SBQQ.TriggerControl.enable();
        }

        if (!mapSCIdToCLIAll.isEmpty()) {
          lstDeleteServiceContract = deleteServiceContract(lstDeleteServiceContract, mapCLISourceIdToNewId, mapSCIdToCLIAll, rcdmMdt, SCToUpdate);
          if (!lstDeleteServiceContract.isEmpty()) {
            SBQQ.TriggerControl.disable();
            delete lstDeleteServiceContract;
            SBQQ.TriggerControl.enable();
          }
        }
      }
      if (!mapNewEntIdToEntitlement.isEmpty() && !lstOldEntitlement.isEmpty()) {
        //Remove SU Contractlines for which entitlement links are already generated.
        for (String keyStr : mapNewEntIdToEntitlement.keyset()) {
          Entitlement entObj = mapNewEntIdToEntitlement.get(keyStr);
          if (!gcOfferSCIdContractLinesMap.isEmpty() && gcOfferSCIdContractLinesMap.containsKey(entObj.ServiceContractId)) {
            mapNewEntIdToEntitlement.remove(keyStr);
          }
        }
        createLinkEntitlement(
          setOrders,
          SerialNumber,
          mapEntAssetToScEnt,
          mapNewEntIdToEntitlement,
          lstOldEntitlement,
          olCLIConvProdId,
          setNewEntitlements,
          setOldSplitSKuEntIds,
          bypassSplitSKU,
          SCToUpdate,
          lstUpsertEntitlementLinks,
          mapUpdateScaleEnt,
          mapIdToupdateOldEntitlement,
          mapIdToUpdateOldCLI,
          mapProductToPolarisMappings
        );
      }
    }
    //LinkedEntitlements
    private void createLinkEntitlement(
      Set<String> setOrders,
      Set<String> SerialNumber,
      Map<String, Id> mapEntAssetToScEnt,
      Map<String, Entitlement> mapNewEntIdToEntitlement,
      List<Entitlement> lstOldEntitlement,
      Map<string, Id> olCLIConvProdId,
      Set<Id> setNewEntitlements,
      Set<Id> setOldSplitSKuEntIds,
      String bypassSplitSKU,
      Map<Id, ServiceContract> SCToUpdate,
      List<Entitlement_Links__c> lstUpsertEntitlementLinks,
      Map<Id, Scale_Entitlement__c> mapUpdateScaleEnt,
      Map<Id, Entitlement> mapIdToupdateOldEntitlement,
      Map<Id, ContractLineItem> mapIdToUpdateOldCLI,
      Map<String, Polaris_SKU_Mapping_V2__c> mapProductToPolarisMappings
    ) {
      //Map<String, Polaris_SKU_Mapping_V2__c> mapProductToPolarisMappings = new Map<String, Polaris_SKU_Mapping_V2__c>();
      Map<String, Decimal> mapContractLineToQuantity = new Map<String, Decimal>(); //quantity calculation for Entitlement Links
      Map<String, Decimal> mapOldCLIToQuanity = new Map<String, Decimal>(); //quantity reduction for Old CLI
      Set<Id> setExistingEntitlement = new Set<Id>();
      Set<String> setExistingAssetIds = new Set<String>();
      Map<Id, Id> mapOldCLIToAssetId = new Map<Id, Id>(); //ARY-1068
      Map<Id, Date> mapOldCLIIdToRSCPStartDate = new Map<Id, Date>();
      Boolean isRSCtoRSCP = false;
      Boolean isGOtoRSCP = false;
      if (!setNewEntitlements.isEmpty()) {
        for (Entitlement_Links__c objEntLinks : [
          SELECT
            Id,
            Previous_Entitlement__r.AssetId,
            Renewed_Entitlement__c,
            Previous_Entitlement__r.Order_Service_Item__r.Product2Id,
            Renewed_Entitlement__r.Order_Service_Item__c,
            Renewed_Entitlement__r.ContractLineItem.SBQQSC__RenewalQuantity__c,
            Previous_Entitlement__c,
            Quantity__c,
            Renewal_Category__c
          FROM Entitlement_Links__c
          WHERE Renewed_Entitlement__c IN :setNewEntitlements OR Previous_Entitlement__c IN :setOldSplitSKuEntIds
        ]) {
          if (!setExistingEntitlement.Contains(objEntLinks.Previous_Entitlement__c)) {
            setExistingEntitlement.add(objEntLinks.Previous_Entitlement__c);
          }
          if (
            objEntLinks?.Previous_Entitlement__r?.AssetId != null &&
            bypassSplitSKU.contains(objEntLinks.Previous_Entitlement__r?.Order_Service_Item__r?.Product2Id) &&
            !setExistingAssetIds.contains(objEntLinks.Previous_Entitlement__r?.Order_Service_Item__r?.Product2Id + '-' + objEntLinks.Previous_Entitlement__r.AssetId)
          ) {
            setExistingAssetIds.add(objEntLinks.Previous_Entitlement__r?.Order_Service_Item__r?.Product2Id + '-' + objEntLinks.Previous_Entitlement__r.AssetId);
          }
        }
      }
      String renewalCategory = '';
      String previousratioCLIs = '';
        Map<Id, OldEntitlementUpdateWrapper> oldEntitlementDetailsUpdate = new Map<Id, OldEntitlementUpdateWrapper>();
      Map<Id, String> mapoldEntToRenewalSubCategory = new Map<Id, String>();

      Map<Id, List<Entitlement>> mapOldCLItoOldEntitlement = new Map<Id, List<Entitlement>>();
      Map<Id, Entitlement> mapCSATOldToNewEnt = new Map<Id, Entitlement>();
      Integer counterTPHRecord = 1;
      for (Entitlement objOldEnt : lstOldEntitlement) {
        for (Entitlement objNewEnt : mapNewEntIdToEntitlement.values()) {
            Boolean refreshProgram = objNewEnt.Order_Service_Item__r.Program__c == Constants.PROGRAM_REFRESH;
            //bypass Ent Link Creation for NonAsset - Asset Based;
            Boolean nonAssetToAssetTxn = objNewEnt?.Order_Service_Item__r?.Order?.Type == 'Revenue' && objNewEnt?.Order_Service_Item__r?.Order?.Order_Sub_Type__c == null &&
                                            objNewEnt?.Order_Service_Item__r?.SBQQ__QuoteLine__r?.Replacement_Details__c != null && objNewEnt?.Order_Service_Item__r?.Program__c == null;
          if (nonAssetToAssetTxn){continue;}
          Boolean isCSAT = (objNewEnt?.Order_Service_Item__r?.Order?.Order_Sub_Type__c != null &&
            objNewEnt?.Order_Service_Item__r?.Order?.Order_Sub_Type__c == 'CSAT Extension')
            ? true : false;
          String RscgType = 'RSC to RSC-G Conv';
          if (String.isNotBlank(objNewEnt?.Order_Service_Item__r?.Order.SBQQ__Quote__r?.Manual_Fulfillment_Quote__c)) {
            isRSCtoRSCP = objNewEnt.Order_Service_Item__r.Order.SBQQ__Quote__r.Manual_Fulfillment_Quote__c.contains(Constants.MANUAL_FULFILL_Quote_RSCP_CONVERSION);
            isGOtoRSCP = objNewEnt.Order_Service_Item__r.Order.SBQQ__Quote__r.Manual_Fulfillment_Quote__c.contains(Constants.MANUAL_FULFILL_Quote_GO_RSCP_CONVERSION);
          }

          String RscgProgram = objNewEnt?.Order_Service_Item__r?.Order?.Program__c != null &&
            (objNewEnt?.Order_Service_Item__r?.Order?.Program__c.contains('$0 RSC-G Replacement') ||
            objNewEnt?.Order_Service_Item__r?.Order?.Program__c.contains('25% Premium RSC-G Replacement'))
            ? objNewEnt?.Order_Service_Item__r?.Order?.Program__c
            : null;
          if (String.isNotBlank(objNewEnt?.Order_Service_Item__r?.Previous_Contract_Line_Items__c) && setOrders.contains(objNewEnt?.Order_Service_Item__r?.OrderId)) {
            for (String previousCLI : objNewEnt?.Order_Service_Item__r?.Previous_Contract_Line_Items__c?.trim()?.split(',')) {
              Id tempPrevCLI = previousCLI.trim();
              // Updating Product Category on new CLI from Old
              if (
                String.isBlank(objNewEnt?.ContractLineItem?.Product_Category__c) &&
                objOldEnt.ContractLineItemId == tempPrevCLI &&
                objOldEnt.ContractLineItem?.Product_Category__c == 'Virtual Addon'
              ) {
                if (mapIdToUpdateOldCLI.containsKey(objNewEnt?.ContractLineItemId)) {
                  if (mapIdToUpdateOldCLI.get(objNewEnt.ContractLineItemId)?.Product_Category__c == null) {
                    mapIdToUpdateOldCLI.get(objNewEnt.ContractLineItemId).Product_Category__c = 'Virtual Addon';
                  }
                } else {
                  mapIdToUpdateOldCLI.put(objNewEnt.ContractLineItemId, new ContractLineItem(Id = objNewEnt.ContractLineItemId, Product_Category__c = 'Virtual Addon'));
                }
              }
              String previousCLI1 = previousCLI.trim().substring(0, 15);
              if (previousCLI1.equals(String.valueOf(objOldEnt.ContractLineItemId).substring(0, 15))) {
                if (String.isNotBlank(RscgProgram)) {
                  mapoldEntToRenewalSubCategory.put(objOldEnt.Id, RscgProgram);
                }
                            OldEntitlementUpdateWrapper oldENTwrapper = new OldEntitlementUpdateWrapper();                
                            if(objNewEnt?.Order_Service_Item__r?.Order?.Type == 'Revenue' &&
                  String.isBlank(objNewEnt?.Order_Service_Item__r?.Order?.Order_Sub_type__c) &&
                  String.isNotBlank(objNewEnt?.Order_Service_Item__r?.Program__c)
                ) {
                  renewalCategory = (isRSCtoRSCP || isGOtoRSCP) ? 'Replaced'
                    : Constants.mapProgramToRenewalCategory.containsKey(objNewEnt?.Order_Service_Item__r?.Program__c) &&
                        Constants.mapProgramToRenewalCategory.get(objNewEnt?.Order_Service_Item__r?.Program__c) != null
                        ? Constants.mapProgramToRenewalCategory.get(objNewEnt?.Order_Service_Item__r?.Program__c) : objNewEnt?.Order_Service_Item__r?.Program__c;
                                    oldENTwrapper.renewalCategory = renewalCategory;
                                    oldEntitlementDetailsUpdate.put(objOldEnt.Id, oldENTwrapper);
                } else {
                  if (String.isNotBlank(objNewEnt?.Order_Service_Item__r?.SBQQ__QuoteLine__r?.Disposition_Reason__c)) {
                    renewalCategory = Constants.mapProgramToRenewalCategory.containsKey(objNewEnt?.Order_Service_Item__r?.SBQQ__QuoteLine__r?.Disposition_Reason__c) &&
                      Constants.mapProgramToRenewalCategory.get(objNewEnt?.Order_Service_Item__r?.SBQQ__QuoteLine__r?.Disposition_Reason__c) != null
                      ? Constants.mapProgramToRenewalCategory.get(objNewEnt?.Order_Service_Item__r?.SBQQ__QuoteLine__r?.Disposition_Reason__c)
                      : objNewEnt?.Order_Service_Item__r?.SBQQ__QuoteLine__r?.Disposition_Reason__c != 'None'
                          ? objNewEnt?.Order_Service_Item__r?.SBQQ__QuoteLine__r?.Disposition_Reason__c : renewalCategory;
                                    oldENTwrapper.renewalCategory = renewalCategory;
                                    oldEntitlementDetailsUpdate.put(objOldEnt.Id, oldENTwrapper);
                  }
                }
                //update Linked Asset
                if (!mapEntAssetToScEnt.isEmpty() && !SerialNumber.isEmpty()) {
                  for (string strSerialNumber : SerialNumber) {
                    if (mapEntAssetToScEnt.containsKey(objOldEnt?.Id + '-' + strSerialNumber)) {
                      mapUpdateScaleEnt.put(
                        mapEntAssetToScEnt.get(objOldEnt?.Id + '-' + strSerialNumber),
                        new Scale_Entitlement__c(Id = mapEntAssetToScEnt.get(objOldEnt?.Id + '-' + strSerialNumber), Renewal_Category__c = renewalCategory)
                      );
                    }
                  }
                }
                if (
                  'One per unit'.equalsIgnoreCase(objNewEnt?.Order_Service_Item__r?.Product2?.SBQQSC__EntitlementConversion__c) &&
                  ('One per unit'.equalsIgnoreCase(objOldEnt?.Order_Service_Item__r?.Product2?.SBQQSC__EntitlementConversion__c) ||
                  ('one per quote line'.equalsIgnoreCase(objOldEnt?.Order_Service_Item__r?.Product2?.SBQQSC__EntitlementConversion__c) &&
                  objOldEnt?.Order_Service_Item__r?.Product2?.Product_Subtype__c == 'GO CNV'))
                ) {
                  if (
                    String.isNotBlank(objOldEnt.AssetId) &&
                    ((String.isNotBlank(objNewEnt.AssetId) && objNewEnt.AssetId == objOldEnt.AssetId) ||
                    (String.isNotBlank(objNewEnt?.Order_Service_Item__r?.Upgraded_From__c) &&
                    objNewEnt.Order_Service_Item__r.Upgraded_From__c.contains(objOldEnt.Asset.SerialNumber)))
                  ) {
                    if (!mapContractLineToQuantity.containsKey(objOldEnt?.ContractLineItemId)) {
                      mapContractLineToQuantity.put(objOldEnt.ContractLineItemId, 1);
                    } else {
                      mapContractLineToQuantity.put(objOldEnt.ContractLineItemId, mapContractLineToQuantity.get(objOldEnt.ContractLineItemId) + 1);
                    }
                    if (
                      isRSCtoRSCP &&
                      !mapOldCLIIdToRSCPStartDate.containsKey(objOldEnt?.ContractLineItemId) &&
                      (objOldEnt?.Order_Service_Item__r?.Quantity - objNewEnt?.Order_Service_Item__r?.Quantity) <= 0
                    ) {
                      mapOldCLIIdToRSCPStartDate.put(objOldEnt.ContractLineItemId, objNewEnt?.StartDate.addDays(-1));
                    }
                    lstUpsertEntitlementLinks.add(
                      new Entitlement_Links__c(
                        Renewed_Entitlement__c = objNewEnt.Id,
                        Previous_Entitlement__c = objOldEnt.Id,
                        Quantity__c = 1,
                        Renewal_Category__c = renewalCategory,
                        Type__c = refreshProgram ? Constants.PROGRAM_REFRESH : string.isNotBlank(RscgProgram) ? RscgType : isCSAT ? 'CSAT' : isRSCtoRSCP ? Constants.ENT_LINK_TYPE_CNV_ONPREM : 'Renewal'
                      )
                    );
                    setExistingEntitlement.add(objOldEnt.Id);
                    if (isCSAT) {
                      mapCSATOldToNewEnt.put(objOldEnt.Id, objNewEnt);
                    }
                    if (objNewEnt?.Order_Service_Item__r?.Program__c != 'Refresh') {
                      if (!setExistingAssetIds.contains(objOldEnt?.Order_Service_Item__r.Product2Id + '-' + objOldEnt.AssetId)) {
                        mapOldCLIToQuanity.put(
                          objOldEnt.ContractLineItemId,
                          (objOldEnt?.ContractLineItem?.SBQQSC__RenewalQuantity__c > 0.00)
                            ? (objOldEnt?.ContractLineItem?.SBQQSC__RenewalQuantity__c - mapContractLineToQuantity?.get(objOldEnt?.ContractLineItemId)) : 0.00
                        );
                        if (bypassSplitSKU.contains(objOldEnt?.Order_Service_Item__r.Product2Id)) {
                          setExistingAssetIds.add(objOldEnt?.Order_Service_Item__r.Product2Id + '-' + objOldEnt.AssetId);
                        }
                      }
                      if (!mapOldCLItoOldEntitlement.containsKey(objOldEnt.ContractLineItemId)) {
                        mapOldCLItoOldEntitlement.put(objOldEnt.ContractLineItemId, new List<Entitlement>{ objOldEnt });
                      } else {
                        mapOldCLItoOldEntitlement.get(objOldEnt.ContractLineItemId).add(objOldEnt);
                      }
                    }
                  } else {
                    if (String.isBlank(objOldEnt.AssetId) || (String.isBlank(objNewEnt.AssetId))) {
                      system.debug(logginglevel.DEBUG, ':::Test::');
                    }
                  }
                } else if (
                  'One per unit'.equalsIgnoreCase(objNewEnt?.Order_Service_Item__r?.Product2?.SBQQSC__EntitlementConversion__c) &&
                  'One per quote line'.equalsIgnoreCase(objOldEnt?.Order_Service_Item__r?.Product2?.SBQQSC__EntitlementConversion__c)
                ) {
                  setExistingEntitlement.add(objOldEnt.Id);
                  lstUpsertEntitlementLinks.add(
                    new Entitlement_Links__c(
                      Renewed_Entitlement__c = objNewEnt.Id,
                      Previous_Entitlement__c = objOldEnt.Id,
                      Quantity__c = objOldEnt?.Quantity__c != null ? objOldEnt?.Quantity__c : objOldEnt?.Order_Service_Item__r?.Quantity,
                      Renewal_Category__c = renewalCategory,
                      Type__c = refreshProgram ? Constants.PROGRAM_REFRESH : string.isNotBlank(RscgProgram) ? RscgType : isCSAT ? 'CSAT' : 'Renewal'
                    )
                  );
                  if (isCSAT) {
                    mapCSATOldToNewEnt.put(objOldEnt.Id, objNewEnt);
                  }
                  if (!mapOldCLIToQuanity.containsKey(objOldEnt.ContractLineItemId) && objNewEnt?.Order_Service_Item__r?.Program__c != 'Refresh') {
                    mapOldCLIToQuanity.put(objOldEnt.ContractLineItemId, 0.00);
                    if (!mapOldCLItoOldEntitlement.containsKey(objOldEnt.ContractLineItemId)) {
                      mapOldCLItoOldEntitlement.put(objOldEnt.ContractLineItemId, new List<Entitlement>{ objOldEnt });
                    } else {
                      mapOldCLItoOldEntitlement.get(objOldEnt.ContractLineItemId).add(objOldEnt);
                    }
                  }
                } else if (
                  'One per quote line'.equalsIgnoreCase(objNewEnt?.Order_Service_Item__r?.Product2?.SBQQSC__EntitlementConversion__c) &&
                  (('One per quote line'.equalsIgnoreCase(objOldEnt?.Order_Service_Item__r?.Product2?.SBQQSC__EntitlementConversion__c) &&
                  objOldEnt?.Order_Service_Item__r?.Product2?.Product_Subtype__c != 'GO CNV') || isPMCEntitlement(objOldEnt))
                ) {
                  if (!mapOldCLItoOldEntitlement.containsKey(objOldEnt.ContractLineItemId)) {
                    mapOldCLItoOldEntitlement.put(objOldEnt.ContractLineItemId, new List<Entitlement>{ objOldEnt });
                  } else {
                    mapOldCLItoOldEntitlement.get(objOldEnt.ContractLineItemId).add(objOldEnt);
                  }

                  if (
                    objOldEnt?.Order_Service_Item__c != null &&
                    ((!objNewEnt?.Order_Service_Item__r?.Order?.Is_RWD_Polaris_Quote__c && !objOldEnt?.Order_Service_Item__r?.Order?.Is_RWD_Polaris_Quote__c) ||
                    (objNewEnt?.Order_Service_Item__r?.Order?.Is_RWD_Polaris_Quote__c && objOldEnt?.Order_Service_Item__r?.Order?.Is_RWD_Polaris_Quote__c))
                  ) {
                    setExistingEntitlement.add(objOldEnt.Id);
                    Map<String, Object> jsonRCVProductMap = new Map<String, Object>();
                    Decimal entLinkQuantity = null;
                    String renCategory = null;
                    String entitlementLinkType = null;
                    Boolean isRCVProduct = false;
                    if (
                      String.isNotBlank(objOldEnt?.Order_Service_Item__r?.Product2?.Custom_Renewal_Attributes__c) &&
                      objOldEnt?.Order_Service_Item__r?.Product2?.Custom_Renewal_Attributes__c.contains('RCVProd')
                    ) {
                      jsonRCVProductMap = (Map<String, Object>) JSON.deserializeUntyped(objOldEnt?.Order_Service_Item__r?.Product2?.Custom_Renewal_Attributes__c);
                      if (jsonRCVProductMap.containsKey('RCVProd') && jsonRCVProductMap.get('RCVProd') == objNewEnt.Order_Service_Item__r.Product2Id) {
                        entLinkQuantity = objNewEnt?.Order_Service_Item__r?.Quantity / Integer.ValueOf(jsonRCVProductMap.get('RCVQuantRatio'));
                        renCategory = 'Replaced';
                        isRCVProduct = true;
                      }
                    } else if (isRSCtoRSCP) {
                      entLinkQuantity = objOldEnt?.Order_Service_Item__r?.Quantity;
                      if ((objOldEnt?.Order_Service_Item__r?.Quantity - objNewEnt?.Order_Service_Item__r?.Quantity) > 0) {
                        entitlementLinkType = Constants.ENT_LINK_TYPE_PARTIAL_CNV_ONPREM;
                      } else {
                        if (!mapOldCLIIdToRSCPStartDate.containsKey(objOldEnt?.ContractLineItemId)) {
                          mapOldCLIIdToRSCPStartDate.put(objOldEnt.ContractLineItemId, objNewEnt?.StartDate.addDays(-1));
                        }
                        entitlementLinkType = Constants.ENT_LINK_TYPE_CNV_ONPREM;
                      }
                    }

                    lstUpsertEntitlementLinks.add(
                      new Entitlement_Links__c(
                        Renewed_Entitlement__c = objNewEnt.Id,
                        Previous_Entitlement__c = objOldEnt.Id,
                        Quantity__c = entLinkQuantity != null
                          ? entLinkQuantity
                          : objNewEnt?.Quantity__c != null ? objNewEnt?.Quantity__c : objNewEnt?.Order_Service_Item__r?.Quantity,
                        Renewal_Category__c = renCategory != null ? renCategory : renewalCategory,
                        Type__c = refreshProgram ? Constants.PROGRAM_REFRESH : string.isNotBlank(RscgProgram) ? RscgType : isCSAT ? 'CSAT' : string.isNotBlank(entitlementLinkType) ? entitlementLinkType : 'Renewal'
                      )
                    );
                    if (isCSAT) {
                      mapCSATOldToNewEnt.put(objOldEnt.Id, objNewEnt);
                    }
                    if (!mapOldCLIToQuanity.containsKey(objOldEnt.ContractLineItemId) && !isRCVProduct) {
                      mapOldCLIToQuanity.put(
                        objOldEnt.ContractLineItemId,
                        (objOldEnt?.ContractLineItem?.SBQQSC__RenewalQuantity__c > 0.00)
                          ? objOldEnt?.ContractLineItem?.SBQQSC__RenewalQuantity__c - objNewEnt?.ContractLineItem?.SBQQSC__RenewalQuantity__c : 0.00
                      );
                    }
                  } else if (
                    (objNewEnt?.Order_Service_Item__r?.Order?.Is_RWD_Polaris_Quote__c &&
                    objOldEnt?.Order_Service_Item__c != null &&
                    !objOldEnt?.Order_Service_Item__r?.Order?.Is_RWD_Polaris_Quote__c) || isPMCEntitlement(objOldEnt)
                  ) {
                    previousratioCLIs = objNewEnt?.Order_Service_Item__r?.Previous_Contract_Line_Items__c;
                    Id newProdId = objNewEnt?.Order_Service_Item__r?.Program__c == 'Replaced' &&
                      previousratioCLIs != null &&
                      olCLIConvProdId.containsKey(previousratioCLIs.trim())
                      ? olCLIConvProdId.get(previousratioCLIs.trim())
                      : objNewEnt?.Order_Service_Item__r?.Product2Id;
                    if (
                      objNewEnt?.Order_Service_Item__r?.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c == 'Renewal+Expansion' &&
                      mapProductToPolarisMappings.containsKey(objOldEnt?.Order_Service_Item__r?.Product2Id + '-' + newProdId)
                    ) {
                      Decimal ratio = (objNewEnt?.Order_Service_Item__r?.Quantity /
                      mapProductToPolarisMappings.get(objOldEnt?.Order_Service_Item__r?.Product2Id + '-' + newProdId).Quantity_Ratio__c);
                      setExistingEntitlement.add(objOldEnt.Id);
                      lstUpsertEntitlementLinks.add(
                        new Entitlement_Links__c(
                          Renewed_Entitlement__c = objNewEnt.Id,
                          Previous_Entitlement__c = objOldEnt.Id,
                          Quantity__c = ratio,
                          Renewal_Category__c = renewalCategory,
                          Type__c = refreshProgram ? Constants.PROGRAM_REFRESH :  string.isNotBlank(RscgProgram) ? RscgType : isCSAT ? 'CSAT' : 'Renewal'
                        )
                      );
                      if (isCSAT) {
                        mapCSATOldToNewEnt.put(objOldEnt.Id, objNewEnt);
                      }
                      if (!mapOldCLIToQuanity.containsKey(objOldEnt.ContractLineItemId) && objNewEnt?.Order_Service_Item__r?.Program__c != 'Refresh') {
                        mapOldCLIToQuanity.put(
                          objOldEnt.ContractLineItemId,
                          objOldEnt?.ContractLineItem?.SBQQSC__RenewalQuantity__c > 0.00 ? objOldEnt?.ContractLineItem?.SBQQSC__RenewalQuantity__c - ratio : 0.00
                        );
                      }
                    } else {
                      setExistingEntitlement.add(objOldEnt.Id);
                      lstUpsertEntitlementLinks.add(
                        new Entitlement_Links__c(
                          Renewed_Entitlement__c = objNewEnt.Id,
                          Previous_Entitlement__c = objOldEnt.Id,
                          Quantity__c = objNewEnt?.Quantity__c != null ? objNewEnt?.Quantity__c : objNewEnt?.Order_Service_Item__r?.Quantity,
                          Renewal_Category__c = renewalCategory,
                          Type__c = refreshProgram ? Constants.PROGRAM_REFRESH : string.isNotBlank(RscgProgram) ? RscgType : isCSAT ? 'CSAT' : 'Renewal'
                        )
                      );
                      if (isCSAT) {
                        mapCSATOldToNewEnt.put(objOldEnt.Id, objNewEnt);
                      }
                      if (
                        !mapOldCLIToQuanity.containsKey(objOldEnt.ContractLineItemId) && (objNewEnt?.Order_Service_Item__r?.Program__c != 'Refresh' || isPMCEntitlement(objOldEnt))
                      ) {
                        mapOldCLIToQuanity.put(
                          objOldEnt.ContractLineItemId,
                          objOldEnt?.ContractLineItem?.SBQQSC__RenewalQuantity__c > 0.00
                            ? objOldEnt?.ContractLineItem?.SBQQSC__RenewalQuantity__c - objNewEnt?.ContractLineItem?.SBQQSC__RenewalQuantity__c : 0.00
                        );
                      }
                    }
                  }
                } else if (
                  'One per quote line'.equalsIgnoreCase(objNewEnt?.Order_Service_Item__r?.Product2?.SBQQSC__EntitlementConversion__c) &&
                  'One per unit'.equalsIgnoreCase(objOldEnt?.Order_Service_Item__r?.Product2?.SBQQSC__EntitlementConversion__c) ||
                  objOldEnt?.Order_Service_Item__r?.Product2?.Product_Subtype__c == 'GO CNV'
                ) {
                  String subScribedAssetNumbers = '';
                  if (!mapOldCLItoOldEntitlement.containsKey(objOldEnt.ContractLineItemId)) {
                    mapOldCLItoOldEntitlement.put(objOldEnt.ContractLineItemId, new List<Entitlement>{ objOldEnt });
                  } else {
                    mapOldCLItoOldEntitlement.get(objOldEnt.ContractLineItemId).add(objOldEnt);
                  }

                  if (String.isNotBlank(objNewEnt?.Order_Service_Item__r?.SerialNumber__c)) {
                    subScribedAssetNumbers = objNewEnt?.Order_Service_Item__r?.SerialNumber__c;
                  } else if (String.isNotBlank(objNewEnt?.ContractLineItem?.SBQQSC__QuoteLine__r?.Arroyo_Subscribed_Asset_Name__c)) {
                    subScribedAssetNumbers = objNewEnt?.ContractLineItem?.SBQQSC__QuoteLine__r?.Arroyo_Subscribed_Asset_Name__c;
                  } else if (String.isNotBlank(objNewEnt?.ContractLineItem?.SBQQSC__QuoteLine__r?.SubscribedAssetNames__c)) {
                    subScribedAssetNumbers = objNewEnt?.ContractLineItem?.SBQQSC__QuoteLine__r?.SubscribedAssetNames__c;
                  } else if (objNewEnt?.ContractLineItem?.SBQQSC__QuoteLine__r?.SBQQ__RequiredBy__c != null) {
                    if (String.isNotBlank(objNewEnt?.ContractLineItem?.SBQQSC__QuoteLine__r?.SBQQ__RequiredBy__r?.Arroyo_Subscribed_Asset_Name__c)) {
                      subScribedAssetNumbers = objNewEnt?.ContractLineItem?.SBQQSC__QuoteLine__r?.SBQQ__RequiredBy__r?.Arroyo_Subscribed_Asset_Name__c;
                    } else if (String.isNotBlank(objNewEnt?.ContractLineItem?.SBQQSC__QuoteLine__r?.SBQQ__RequiredBy__r?.SubscribedAssetNames__c)) {
                      subScribedAssetNumbers = objNewEnt?.ContractLineItem?.SBQQSC__QuoteLine__r?.SBQQ__RequiredBy__r?.SubscribedAssetNames__c;
                    }
                  }
                  if (String.isNotBlank(subScribedAssetNumbers) && String.isNotBlank(objOldEnt?.AssetId)) {
                    for (String strSubscribedAsset : subScribedAssetNumbers?.trim()?.split(',')) {
                      if (String.isNotBlank(objOldEnt?.AssetId) && strSubscribedAsset.trim() == objOldEnt?.Asset.SerialNumber.trim()) {
                        if (!mapContractLineToQuantity.containsKey(objOldEnt?.ContractLineItemId)) {
                          mapContractLineToQuantity.put(objOldEnt.ContractLineItemId, 1);
                        } else {
                          mapContractLineToQuantity.put(objOldEnt.ContractLineItemId, mapContractLineToQuantity.get(objOldEnt.ContractLineItemId) + 1);
                        }

                        lstUpsertEntitlementLinks.add(
                          new Entitlement_Links__c(
                            Renewed_Entitlement__c = objNewEnt.Id,
                            Previous_Entitlement__c = objOldEnt.Id,
                            Quantity__c = 1.00,
                            Renewal_Category__c = renewalCategory,
                            Type__c = refreshProgram ? Constants.PROGRAM_REFRESH : string.isNotBlank(RscgProgram) ? RscgType : isCSAT ? 'CSAT' : 'Renewal'
                          )
                        );
                        setExistingEntitlement.add(objOldEnt.Id);
                        if (isCSAT) {
                          mapCSATOldToNewEnt.put(objOldEnt.Id, objNewEnt);
                        }
                        if (
                          objNewEnt?.Order_Service_Item__r?.Program__c != 'Refresh' &&
                          !mapContractLineToQuantity.isEmpty() &&
                          mapContractLineToQuantity.containsKey(objOldEnt.ContractLineItemId)
                        ) {
                          if (!setExistingAssetIds.contains(objOldEnt?.Order_Service_Item__r.Product2Id + '-' + objOldEnt.AssetId)) {
                            mapOldCLIToQuanity.put(
                              objOldEnt.ContractLineItemId,
                              objOldEnt?.ContractLineItem?.SBQQSC__RenewalQuantity__c > 0.00
                                ? objOldEnt?.ContractLineItem?.SBQQSC__RenewalQuantity__c - mapContractLineToQuantity.get(objOldEnt.ContractLineItemId) : 0.00
                            );
                            if (bypassSplitSKU.contains(objOldEnt?.Order_Service_Item__r.Product2Id)) {
                              setExistingAssetIds.add(objOldEnt?.Order_Service_Item__r.Product2Id + '-' + objOldEnt.AssetId);
                            }
                          }
                        }
                      } //if End - AssetId
                    } //For loop SubscribedAsset
                  } else if (
                    (String.isBlank(subScribedAssetNumbers) && (String.isBlank(objOldEnt?.AssetId) || String.isNotBlank(objOldEnt?.AssetId))) ||
                    (String.isNotBlank(subScribedAssetNumbers) && String.isBlank(objOldEnt?.AssetId))
                  ) {
                    if (
                      objNewEnt?.Order_Service_Item__r?.Product2?.Family == 'Third Party License' ||
                      objOldEnt?.Order_Service_Item__r?.Product2?.Family == 'Third Party License' ||
                      objNewEnt?.Order_Service_Item__r?.Product2?.Product_Type__c == '3rd Party Hardware' ||
                      objOldEnt?.Order_Service_Item__r?.Product2?.Product_Type__c == '3rd Party Hardware'
                    ) {
                      if (!setExistingEntitlement.contains(objOldEnt.Id)) {
                        if (objNewEnt?.Order_Service_Item__r?.TPH_Quantity__c != null && counterTPHRecord <= Integer.valueOf(objNewEnt?.Order_Service_Item__r?.TPH_Quantity__c)) {
                          lstUpsertEntitlementLinks.add(
                            new Entitlement_Links__c(
                              Renewed_Entitlement__c = objNewEnt.Id,
                              Previous_Entitlement__c = objOldEnt.Id,
                              Quantity__c = 1,
                              Renewal_Category__c = renewalCategory,
                              Type__c = refreshProgram ? Constants.PROGRAM_REFRESH : string.isNotBlank(RscgProgram) ? RscgType : isCSAT ? 'CSAT' : 'Renewal'
                            )
                          );
                          if (isCSAT) {
                            mapCSATOldToNewEnt.put(objOldEnt.Id, objNewEnt);
                          }
                          setExistingEntitlement.add(objOldEnt.Id);

                          if (objNewEnt?.Order_Service_Item__r?.Program__c != 'Refresh') {
                            mapOldCLIToQuanity.put(
                              objOldEnt.ContractLineItemId,
                              objOldEnt?.ContractLineItem?.SBQQSC__RenewalQuantity__c > 0.00
                                ? objOldEnt?.ContractLineItem?.SBQQSC__RenewalQuantity__c - Decimal.ValueOf(objNewEnt?.Order_Service_Item__r?.TPH_Quantity__c) : 0.00
                            );
                          }
                          counterTPHRecord++;
                        }
                      }
                    } else if (
                      objOldEnt?.Order_Service_Item__r?.Product2?.Product_Level__c == 'Standalone Software Addon' ||
                      objOldEnt?.Order_Service_Item__r?.Product2?.Product_Level__c == 'SaaS Software Addon' ||
                      objOldEnt?.Order_Service_Item__r?.Product2?.License_Subtype__c == 'Add-On'
                    ) {
                      if (!mapContractLineToQuantity.containsKey(objOldEnt?.ContractLineItemId) && objNewEnt?.Order_Service_Item__r?.Program__c != 'Refresh') {
                        mapContractLineToQuantity.put(objOldEnt.ContractLineItemId, 0.00);
                        lstUpsertEntitlementLinks.add(
                          new Entitlement_Links__c(
                            Renewed_Entitlement__c = objNewEnt.Id,
                            Previous_Entitlement__c = objOldEnt.Id,
                            Quantity__c = objNewEnt?.Quantity__c != null ? objNewEnt?.Quantity__c : objNewEnt?.Order_Service_Item__r?.Quantity,
                            Renewal_Category__c = renewalCategory,
                            Type__c = refreshProgram ? Constants.PROGRAM_REFRESH :  string.isNotBlank(RscgProgram) ? RscgType : isCSAT ? 'CSAT' : 'Renewal'
                          )
                        );
                        setExistingEntitlement.add(objOldEnt.Id);
                        if (isCSAT) {
                          mapCSATOldToNewEnt.put(objOldEnt.Id, objNewEnt);
                        }
                      }
                    } else {
                      errorLogs.add( new Error_Logs__c(Error_Type__c = 'Entitlement Tagging',Error_Message__c = 'Entitlement Tagging Error with CLI' + objNewEnt?.ContractLineItemId,  Type__c = 'SFDC'));
                    }
                  }
                }
              }
            }
          }
        }
        if (!mapCSATOldToNewEnt.isEmpty() && mapCSATOldToNewEnt.containsKey(objOldEnt.Id)) {
          Entitlement objNewEnt = mapCSATOldToNewEnt.get(objOldEnt.Id);
          mapIdToupdateOldEntitlement.put(
            objOldEnt.Id,
            new Entitlement(Id = objOldEnt.Id, Has_linked_CSAT_Extension_Entitlement__c = true, New_Extended_End_Date__c = objNewEnt.EndDate, New_Extension_Term__c = objNewEnt.Subscription_Term__c));
          mapIdToUpdateOldCLI.put(
            objOldEnt.ContractLineItemId,
            new ContractLineItem(Id = objOldEnt.ContractLineItemId, New_Extended_End_Date__c = objNewEnt.EndDate, New_Extension_Term__c = objNewEnt.Subscription_Term__c)
          );
          setOldCliCSAT.add(objOldEnt.ContractLineItemId);
        } else {
                if(!oldEntitlementDetailsUpdate.isEmpty() && 
                oldEntitlementDetailsUpdate.containsKey(objOldEnt.Id) && 
                !mapIdToupdateOldEntitlement.containsKey(objOldEnt.Id) && 
                setExistingEntitlement.contains(objOldEnt.Id) && 
                objOldEnt?.Renewal_Category__c != 'Converted') {
                    
                    Entitlement entUpdate = new Entitlement(
                        Id = objOldEnt.Id,
                        Renewal_Category__c = ('One per unit'.equalsIgnoreCase(objOldEnt?.Order_Service_Item__r?.Product2?.SBQQSC__EntitlementConversion__c) ||
                        objOldEnt?.Order_Service_Item__r?.Product2?.Product_Subtype__c == 'GO CNV' ||
                        (objOldEnt.Renewal_Category__c != 'MIXEDPARTIAL' &&
                        mapOldCLIToQuanity.containsKey(objOldEnt.ContractLineItemId) &&
                        mapOldCLIToQuanity.get(objOldEnt.ContractLineItemId) <= 0.00))
                        ? oldEntitlementDetailsUpdate.get(objOldEnt.Id)?.renewalCategory
                        : 'MIXEDPARTIAL',
                        Renewal_Sub_Category__c = (oldEntitlementDetailsUpdate.get(objOldEnt.Id)?.renewalCategory == 'Replaced' && mapoldEntToRenewalSubCategory.containsKey(objOldEnt.Id))
                        ? mapoldEntToRenewalSubCategory.get(objOldEnt.Id) : null
                    );
                    mapIdToupdateOldEntitlement.put(objOldEnt.Id, entUpdate);

            if (
              mapIdToupdateOldEntitlement.containsKey(objOldEnt.Id) &&
              mapOldCLIIdToRSCPStartDate.containsKey(objOldEnt.ContractLineItemId) &&
              mapOldCLIIdToRSCPStartDate.get(objOldEnt.ContractLineItemId) != null
            ) {
              mapIdToupdateOldEntitlement.get(objOldEnt.Id).Enddate = mapOldCLIIdToRSCPStartDate.get(objOldEnt.ContractLineItemId);
            }
          }
          if (!setExistingEntitlement.contains(objOldEnt.Id) && !mapOldCLIToAssetId.containsKey(objOldEnt.ContractLineItemId) && objOldEnt.AssetId != null) {
            mapOldCLIToAssetId.put(objOldEnt.ContractLineItemId, objOldEnt.AssetId);
          }

          if (!mapOldCLIToQuanity.isEmpty() && !mapOldCLItoOldEntitlement.isEmpty()) {
            for (Id oldCLIId : mapOldCLIToQuanity.keySet()) {
              if (mapOldCLItoOldEntitlement.containsKey(oldCLIId)) {
                String serialNumberId = mapOldCLIToQuanity.get(oldCLIId) > 0.00 && mapOldCLIToAssetId.containsKey(oldCLIId)
                  ? mapOldCLIToAssetId.get(oldCLIId)
                  : mapOldCLItoOldEntitlement.get(oldCLIId)[0].ContractLineItem.SBQQSC__RequiredById__c;
                String rootId = mapOldCLIToQuanity.get(oldCLIId) > 0.00 && mapOldCLIToAssetId.containsKey(oldCLIId)
                  ? mapOldCLIToAssetId.get(oldCLIId)
                  : mapOldCLItoOldEntitlement.get(oldCLIId)[0].ContractLineItem.SBQQSC__RootId__c;
                mapIdToUpdateOldCLI.put(
                  oldCLIId,
                  new ContractLineItem(
                    Id = oldCLIId,
                    SBQQSC__RenewalQuantity__c = mapOldCLIToQuanity.get(oldCLIId) > 0.00 ? mapOldCLIToQuanity.get(oldCLIId) : 0.00,
                    SBQQSC__RootId__c = rootId,
                    Resync_Line__c = 'Required',
                    SBQQSC__RequiredById__c = serialNumberId,
                    SBQQSC__TerminatedDate__c = mapOldCLIToQuanity.get(oldCLIId) <= 0.00 ? mapOldCLItoOldEntitlement.get(oldCLIId)[0]?.ContractLineItem?.EndDate : null
                  )
                );
                if (mapOldCLIToQuanity.get(oldCLIId) < 0.00) {
                  errorLogs.add(new Error_Logs__c(Error_Type__c = 'Entitlement Tagging', Error_Message__c = 'Renewal Quantity < 0 with Old CLI ' + oldCLIId, Type__c = 'SFDC'));
                }

                if (mapIdToUpdateOldCLI.containsKey(oldCLIId) && mapOldCLIIdToRSCPStartDate.containsKey(oldCLIId) && mapOldCLIIdToRSCPStartDate.get(oldCLIId) != null) {
                  mapIdToUpdateOldCLI.get(oldCLIId).Enddate = mapOldCLIIdToRSCPStartDate.get(oldCLIId);
                }
              }
            }
          }
        }
      }
    }

    private boolean isPMCEntitlement(Entitlement oldENT) {
      return (oldENT?.Type == Constants.ENT_TYPE_PMC && 'One per quote line'.equalsIgnoreCase(oldENT?.Product__r?.SBQQSC__EntitlementConversion__c));
    }

    //createServiceContract
    private static List<ServiceContract> createServiceContractRecords(
      List<ServiceContract> lstClonedServiceContractInsert,
      Set<String> setServiceContractId,
      Map<String, ContractLineItem> mapSCIdToOnlyNewCLI,
      Map<String, ContractLineItem> mapSCIdToOnlyRenewalCLI
    ) {
      if (!setServiceContractId.isEmpty()) {
        for (ServiceContract objSC : [
          SELECT
            Id,
            Name,
            AccountId,
            Term,
            createdDate,
            LastModifiedDate,
            StartDate,
            EndDate,
            Pricebook2Id,
            SBQQSC__Opportunity__c,
            SBQQSC__Order__r.OpportunityId,
            SBQQSC__Order__c,
            SBQQSC__Order__r.Order_Sub_Type__c,
            SBQQSC__Quote__c,
            SBQQSC__Quote__r.Renewal_Opportunity__c,
            SBQQSC__RenewalQuoted__c
          FROM ServiceContract
          WHERE Id IN :setServiceContractId
          ORDER BY createdDate ASC
        ]) {
          if (
            objSC.SBQQSC__Order__r.Order_Sub_Type__c == null &&
            !mapSCIdToOnlyRenewalCLI.isEmpty() &&
            mapSCIdToOnlyRenewalCLI.containsKey(objSC.Id) &&
            mapSCIdToOnlyRenewalCLI.get(objSC.Id) != null
          ) {
            objSC.SBQQSC__Opportunity__c = mapSCIdToOnlyRenewalCLI.get(objSC.Id).SBQQSC__OrderProduct__r.Order.OpportunityId;
            objSC.SBQQSC__Order__c = mapSCIdToOnlyRenewalCLI.get(objSC.Id).SBQQSC__OrderProduct__r.OrderId;
            lstClonedServiceContractInsert.add(objSC);
          }
          ServiceContract sc = objSC.clone(false);
          if (!mapSCIdToOnlyNewCLI.isEmpty() && mapSCIdToOnlyNewCLI.containsKey(objSC.Id) && mapSCIdToOnlyNewCLI.get(objSC.Id) != null) {
            sc.SBQQSC__Opportunity__c = mapSCIdToOnlyNewCLI.get(objSC.Id).SBQQSC__OrderProduct__r.Order.OpportunityId;
            sc.SBQQSC__Order__c = mapSCIdToOnlyNewCLI.get(objSC.Id).SBQQSC__OrderProduct__r.OrderId;
          }

          lstClonedServiceContractInsert.add(sc);
        }
      }
      return lstClonedServiceContractInsert;
    }
    //insert RCDM CLI  and New CLI
    private static List<ContractLineItem> createCLIRecords(
      List<ContractLineItem> lstInsertContractLines,
      Map<Id, Id> mapCLIToOrderId,
      Map<String, ContractLineItem> mapLicenseSkuToRCDM,
      Map<String, ContractLineItem> mapOLIToCLIobjContractLI,
      Map<String, Id> mapSCSourceIdToNewId,
      Map<String, Map<String, List<ContractLineItem>>> mapSCIdToLineTypeToAllCLI
    ) {
      if (!mapLicenseSkuToRCDM.isEmpty() && !mapOLIToCLIobjContractLI.isEmpty()) {
        for (String strOLIId : mapLicenseSkuToRCDM.keySet()) {
          if (mapOLIToCLIobjContractLI.containsKey(strOLIId)) {
            ContractLineItem objCLI = mapLicenseSkuToRCDM.get(strOLIId).Clone(false);

            objCLI.ServiceContractId = (!mapSCSourceIdToNewId.isEmpty() &&
              mapSCSourceIdToNewId.containsKey(mapLicenseSkuToRCDM.get(strOLIId).ServiceContractId + '-' + mapLicenseSkuToRCDM.get(strOLIId).SBQQSC__OrderProduct__c) &&
              mapSCSourceIdToNewId.get(mapLicenseSkuToRCDM.get(strOLIId).ServiceContractId + '-' + mapLicenseSkuToRCDM.get(strOLIId).SBQQSC__OrderProduct__c) != null)
              ? mapSCSourceIdToNewId.get(mapLicenseSkuToRCDM.get(strOLIId).ServiceContractId + '-' + mapLicenseSkuToRCDM.get(strOLIId).SBQQSC__OrderProduct__c)
              : (mapSCSourceIdToNewId.containsKey(mapOLIToCLIobjContractLI.get(strOLIId).ServiceContractId) &&
                  mapSCSourceIdToNewId.get(mapOLIToCLIobjContractLI.get(strOLIId).ServiceContractId) != null)
                  ? mapSCSourceIdToNewId.get(mapOLIToCLIobjContractLI.get(strOLIId).ServiceContractId)
                  : mapOLIToCLIobjContractLI.get(strOLIId).ServiceContractId;
            //objCLI.ServiceContractId = (!mapSCSourceIdToNewId.isEmpty() && mapSCSourceIdToNewId.containsKey(mapOLIToCLIobjContractLI.get(strOLIId).ServiceContractId) && mapSCSourceIdToNewId.get(mapOLIToCLIobjContractLI.get(strOLIId).ServiceContractId) != null) ? mapSCSourceIdToNewId.get(mapOLIToCLIobjContractLI.get(strOLIId).ServiceContractId) : mapOLIToCLIobjContractLI.get(strOLIId).ServiceContractId;
            lstInsertContractLines.add(objCLI);
            mapCLIToOrderId.put(mapLicenseSkuToRCDM.get(strOLIId).Id, mapLicenseSkuToRCDM.get(strOLIId).SBQQSC__OrderProduct__c);
            if (!mapSCSourceIdToNewId.containskey(mapLicenseSkuToRCDM.get(strOLIId).ServiceContractId + '-' + mapLicenseSkuToRCDM.get(strOLIId).SBQQSC__OrderProduct__c)) {
              /*&& mapLicenseSkuToRCDM.get(strOLIId).ServiceContractId != mapOLIToCLIobjContractLI.get(strOLIId).ServiceContractId*/
              mapSCSourceIdToNewId.put(
                mapLicenseSkuToRCDM.get(strOLIId).ServiceContractId + '-' + mapLicenseSkuToRCDM.get(strOLIId).SBQQSC__OrderProduct__c,
                objCLI.ServiceContractId
              );
            }
          }
        }
      }

      if (!mapSCIdToLineTypeToAllCLI.isEmpty()) {
        for (String strSCId : mapSCIdToLineTypeToAllCLI.keySet()) {
          if (mapSCIdToLineTypeToAllCLI?.get(strSCId).containsKey('New')) {
            for (ContractLineItem objContractLI : mapSCIdToLineTypeToAllCLI.get(strSCId).get('New')) {
              if (mapSCSourceIdToNewId.containsKey(objContractLI.ServiceContractId) && mapSCSourceIdToNewId.get(objContractLI.ServiceContractId) != null) {
                ContractLineItem objCLI = objContractLI.Clone(false);
                objCLI.ServiceContractId = mapSCSourceIdToNewId.get(objContractLI.ServiceContractId);
                lstInsertContractLines.add(objCLI);
                mapCLIToOrderId.put(objContractLI.Id, objContractLI.SBQQSC__OrderProduct__c);
              }
            }
          }
        }
      }

      return lstInsertContractLines;
    }
    //update CLI on OrderProduct
    private static Map<String, OrderItem> updateOrderItem(Map<Id, Id> mapCLISourceIdToNewId, Map<Id, Id> mapCLIToOrderId, Map<String, OrderItem> mapOrderItemUpdate) {
      if (!mapCLISourceIdToNewId.isEmpty()) {
        for (Id oldCLIId : mapCLISourceIdToNewId.keySet()) {
          if (!mapCLIToOrderId.isEmpty() && mapCLIToOrderId.containsKey(oldCLIId) && !mapOrderItemUpdate.containsKey(mapCLIToOrderId.get(oldCLIId))) {
            mapOrderItemUpdate.put(
              mapCLIToOrderId.get(oldCLIId),
              new OrderItem(Id = mapCLIToOrderId.get(oldCLIId), SBQQSC__ContractLineItem__c = mapCLISourceIdToNewId.get(oldCLIId))
            );
          }
        }
      }
      return mapOrderItemUpdate;
    }
    //update Entitlement wih New CLI
    private static List<Entitlement> updateEntitlements(
      List<Entitlement> updateLstEntitlement,
      Map<String, Id> mapSCSourceIdToNewId,
      Map<Id, Id> mapCLISourceIdToNewId,
      Map<String, Entitlement> mapNewEntIdToEntitlement,
      Map<String, ContractLineItem> mapOLIToCLIobjContractLI,
      Map<String, Entitlement> mapRCDMEntitlement
    ) {
      for (Entitlement objEntitlement : mapNewEntIdToEntitlement.values()) {
        if (
          mapCLISourceIdToNewId.containsKey(objEntitlement.ContractLineItemId) &&
          !mapRCDMEntitlement.containsKey(objEntitlement.Order_Service_Item__c + '-' + objEntitlement.Product__c)
        ) {
          mapRCDMEntitlement.put(objEntitlement.Order_Service_Item__c + '-' + objEntitlement.Product__c, objEntitlement);
        }
      }
      if (!mapRCDMEntitlement.isEmpty()) {
        String strSourceSC = '';
        for (Entitlement objEntitlement : mapRCDMEntitlement.values()) {
          if (mapCLISourceIdToNewId.containsKey(objEntitlement.ContractLineItemId)) {
            if (!mapSCSourceIdToNewId.isEmpty()) {
              if (mapSCSourceIdToNewId.containskey(objEntitlement.serviceContractId + '-' + objEntitlement.Order_Service_Item__c)) {
                strSourceSC = objEntitlement.serviceContractId + '-' + objEntitlement.Order_Service_Item__c;
              } else {
                strSourceSC = objEntitlement.serviceContractId;
              }
            }
            updateLstEntitlement.add(
              new Entitlement(
                Id = objEntitlement.Id,
                serviceContractId = !mapSCSourceIdToNewId.isEmpty() && mapSCSourceIdToNewId.containsKey(strSourceSC)
                  ? mapSCSourceIdToNewId.get(strSourceSC)
                  : (!mapOLIToCLIobjContractLI.isEmpty() &&
                      mapOLIToCLIobjContractLI.containsKey(objEntitlement?.Order_Service_Item__r?.SBQQ__RequiredBy__c) &&
                      mapOLIToCLIobjContractLI.get(objEntitlement?.Order_Service_Item__r?.SBQQ__RequiredBy__c) != null)
                      ? mapOLIToCLIobjContractLI.get(objEntitlement.Order_Service_Item__r.SBQQ__RequiredBy__c).ServiceContractId
                      : (mapSCSourceIdToNewId.containsKey(mapOLIToCLIobjContractLI.get(objEntitlement.Order_Service_Item__c).ServiceContractId) &&
                          mapSCSourceIdToNewId.get(mapOLIToCLIobjContractLI.get(objEntitlement.Order_Service_Item__c).ServiceContractId) != null)
                          ? mapSCSourceIdToNewId.get(mapOLIToCLIobjContractLI.get(objEntitlement.Order_Service_Item__c).ServiceContractId)
                          : objEntitlement.ServiceContractId,
                ContractLineItemId = mapCLISourceIdToNewId.get(objEntitlement.ContractLineItemId)
              )
            );
          }
        }
      }
      return updateLstEntitlement;
    }

    /*****Insert Scale Asset -RWD97 */
    /**
     * @description create Linked Assets
     * @param setOldEntitlement
     * @param mapEntAssetToScEnt
     * @param mapAssetEntToSELst
     * @param setQuoteId
     * @param mapNewEntIdToEntitlement
     * @param lstAssets
     * @param mapOldCLItoNewCLIId
     */
    public void createScaleAsset(
      Set<String> setOldEntitlement,
      Map<String, Id> mapEntAssetToScEnt,
      Map<String, Scale_Entitlement__c> mapAssetEntToSELst,
      Set<Id> setQuoteId,
      Map<String, Entitlement> mapNewEntIdToEntitlement,
      List<Asset> lstAssets,
      Map<Id, Id> mapOldCLItoNewCLIId
    ) {
      Map<String, Entitlement> mapAssetToEntitlements = new Map<String, Entitlement>();
      Map<String, String> mapOrderLineToEntitlementId = new Map<String, String>();
      Map<String, String> mapSerialNumberToAssetId = new Map<String, string>();
      List<Scale_Entitlement__c> lstInsertScaleAsset = new List<Scale_Entitlement__c>();
      Set<String> setAssetIds = new Set<String>();
      Set<String> setCurrentEntitlements = new Set<String>();
      for (Entitlement objEntitlement : mapNewEntIdToEntitlement.values()) {
        if (
          objEntitlement.Order_Service_Item__r.Order.Is_RWD_Polaris_Quote__c == true &&
          setQuoteId.contains(objEntitlement.Order_Service_Item__r.Order.SBQQ__Quote__c) &&
          objEntitlement.Type != 'Manufacturing Entitlement' &&
          objEntitlement.Order_Service_Item__r.Order.Order_Status__c == 'Shipped'
        ) {
          if (objEntitlement?.Asset?.SerialNumber != null) {
            mapSerialNumberToAssetId.put(objEntitlement.Asset.SerialNumber, objEntitlement.AssetId);
          }
          if (!lstAssets.isEmpty()) {
            for (Asset objAsset : lstAssets) {
              if (!mapSerialNumberToAssetId.containsKey(objAsset.SerialNumber))
                mapSerialNumberToAssetId.put(objAsset.SerialNumber, objAsset.Id);
            }
          }
          if (
            /*objEntitlement?.Order_Service_Item__r?.SBQQ__RequiredBy__c == null && objEntitlement?.Order_Service_Item__r?.SBQQ__QuoteLine__r?.SBQQ__RequiredBy__c == null &&*/
            (objEntitlement?.Product__r?.Product_Level__c == 'Support' && objEntitlement?.Product__r?.Product_Type__c == 'RCDM Support') ||
            (objEntitlement?.Product__r?.Product_Level__c == 'LOD Software' ||
            objEntitlement?.Product__r?.Product_Level__c == 'Hybrid Software' ||
            (objEntitlement?.Product__r?.Product_Level__c == 'OnPrem' &&
            (objEntitlement?.Product__r?.Product_Subtype__c == null ||
            objEntitlement?.Product__r?.Product_Subtype__c == 'OnPrem LOD Addon' ||
            objEntitlement?.Product__r?.Product_Subtype__c == 'LOD Addon') &&
            (objEntitlement?.Product__r?.Product_Type__c == 'Foundation Edition' ||
            objEntitlement?.Product__r?.Product_Type__c == 'Business Edition' ||
            objEntitlement?.Product__r?.Product_Type__c == 'Enterprise Edition')))
          ) {
            mapOrderLineToEntitlementId.put(objEntitlement.Order_Service_Item__c, objEntitlement.Id);

            if (
              (objEntitlement?.Order_Service_Item__r?.Order.Order_Sub_Type__c == 'Renewal' ||
              objEntitlement?.Order_Service_Item__r.Program__c == 'Replaced' ||
              objEntitlement?.Order_Service_Item__r?.Program__c == 'Conversion') && objEntitlement?.Order_Service_Item__r?.SerialNumber__c != null
            ) {
              for (String strSerialNumber : objEntitlement.Order_Service_Item__r.SerialNumber__c.split(',')) {
                if (!mapAssetToEntitlements.containskey(strSerialNumber.trim())) {
                  mapAssetToEntitlements.put(strSerialNumber.trim() + '-' + objEntitlement.Id, objEntitlement);
                }
              }
            }
          } else if (
            objEntitlement.Order_Service_Item__r.Order.Type == 'Revenue' &&
            (objEntitlement.Order_Service_Item__r.Order.Order_Sub_Type__c == null ||
            objEntitlement.Order_Service_Item__r.Order.Order_Sub_Type__c == Constants.ORDER_SUB_TYPE_GC_OFFER) &&
            (objEntitlement.Order_Service_Item__r.Program__c == null ||
            objEntitlement.Order_Service_Item__r.Program__c == 'Refresh')
          ) {
            //if(objEntitlement.Order_Service_Item__r.Order.Order_Sub_Type__c != 'Renewal' && !isRenewalUpgradedSku && objEntitlement.Order_Service_Item__r.Program__c != 'Conversion') {
            if (objEntitlement.AssetId != null && !mapAssetToEntitlements.containskey(objEntitlement.AssetId)) {
              mapAssetToEntitlements.put(objEntitlement.AssetId + '-' + objEntitlement.Id, objEntitlement);
            }
          }
        }
      }
      if (!mapAssetToEntitlements.isEmpty()) {
        for (String serialNumberEntIdKey : mapAssetToEntitlements.keySet()) {
          if (mapAssetToEntitlements.containskey(serialNumberEntIdKey)) {
            Entitlement objEntitlement = mapAssetToEntitlements.get(serialNumberEntIdKey);
            String entiltementId = '';
            String contractLineId = '';
            String orderProduct = '';
            String assetsIds = '';
            Boolean checkIfRsp = (objEntitlement?.Product__r?.Product_Level__c == 'OnPrem' && (objEntitlement?.Product__r?.Product_Subtype__c == 'OnPrem LOD Addon' || objEntitlement?.Product__r?.Product_Subtype__c == 'LOD Addon'));

            if (
              objEntitlement.Order_Service_Item__r.Order.Type == 'Revenue' &&
              (objEntitlement.Order_Service_Item__r.Order.Order_Sub_Type__c == null ||
              objEntitlement.Order_Service_Item__r.Order.Order_Sub_Type__c == Constants.ORDER_SUB_TYPE_GC_OFFER) &&
              (objEntitlement.Order_Service_Item__r.Program__c == null ||
              objEntitlement.Order_Service_Item__r.Program__c == 'Refresh') &&
              !checkIfRsp
            ) {
              entiltementId = mapOrderLineToEntitlementId.get(objEntitlement.Order_Service_Item__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c);
              contractLineId = !mapOldCLItoNewCLIId.isEmpty() &&
                mapOldCLItoNewCLIId.containsKey(objEntitlement.Order_Service_Item__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQSC__ContractLineItem__c) &&
                mapOldCLItoNewCLIId.get(objEntitlement.Order_Service_Item__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQSC__ContractLineItem__c) != null
                ? mapOldCLItoNewCLIId.get(objEntitlement.Order_Service_Item__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQSC__ContractLineItem__c)
                : objEntitlement.Order_Service_Item__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQSC__ContractLineItem__c;
              orderProduct = objEntitlement.Order_Service_Item__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c;
              assetsIds = serialNumberEntIdKey.split('-')[0].trim();
            } else {
              if (mapSerialNumberToAssetId.containsKey(serialNumberEntIdKey.split('-')[0].trim()) && mapSerialNumberToAssetId.get(serialNumberEntIdKey.split('-')[0].trim()) != null) {
                entiltementId = mapOrderLineToEntitlementId.get(objEntitlement.Order_Service_Item__c);
                contractLineId = !mapOldCLItoNewCLIId.isEmpty() && mapOldCLItoNewCLIId.containskey(objEntitlement.ContractLineItemId)
                  ? mapOldCLItoNewCLIId.get(objEntitlement.ContractLineItemId)
                  : objEntitlement.ContractLineItemId;
                orderProduct = objEntitlement.Order_Service_Item__c;
                if (checkIfRsp) {
                  assetsIds = mapSerialNumberToAssetId.get(serialNumberEntIdKey.split('-')[0].trim());
                } else {
                  assetsIds = mapSerialNumberToAssetId.get(serialNumberEntIdKey.split('-')[0].trim());
                }
              }
            }
            if (String.isNotBlank(entiltementId) && String.isNotBlank(contractLineId) && String.isNotBlank(orderProduct) && String.isNotBlank(assetsIds)) {
              setAssetIds.add(assetsIds);
              setCurrentEntitlements.add(entiltementId);

                    //Prevent Scale ENT creation if it is already been created as part of Refresh
                    boolean scaleENTCreated = false;
                    if(serialNumberEntIdKey.contains('-') && serialNumberEntIdKey.split('-').size() > 0 && exitingLinkedAssetsKey.Contains(entiltementId + '-' + serialNumberEntIdKey.split('-')[0].trim())){
                        scaleENTCreated = true;
                    }
                    if(!scaleENTCreated){
                        mapAssetEntToSELst.put(assetsIds.trim()+'-'+entiltementId, new Scale_Entitlement__c(Asset__c = assetsIds.trim(), Type__c= 'Non-Scale',  Contract_Line_Item__c = contractLineId.trim(), Order_Product__c = orderProduct.trim(), Entitlement__c= entiltementId ));
            }
                    
            }
            //lstInsertScaleAsset.add(new Scale_Entitlement__c(Asset__c = assetsIds.trim(), Type__c= 'Non-Scale',  Contract_Line_Item__c = contractLineId.trim(), Order_Product__c = orderProduct.trim(), Entitlement__c= entiltementId ));
          }
        }
      }
      if (!setAssetIds.isEmpty()) {
        for (Scale_Entitlement__c objAssetScale : [
          SELECT Id, Asset__c, Asset__r.SerialNumber, Renewal_Category__c, Asset__r.Serial_Number__c, Entitlement__c, Contract_Line_Item__c
          FROM Scale_Entitlement__c
          WHERE Asset__c IN :setAssetIds AND (Entitlement__c IN :setOldEntitlement OR Entitlement__c IN :setCurrentEntitlements)
        ]) {
          if (String.isBlank(objAssetScale.Renewal_Category__c)) {
            mapEntAssetToScEnt.put(objAssetScale.Entitlement__c + '-' + objAssetScale?.Asset__r.SerialNumber, objAssetScale.Id);
          }
          if (objAssetScale.Id != null && mapAssetEntToSELst.containskey(objAssetScale.Asset__c + '-' + objAssetScale.Entitlement__c)) {
            if (objAssetScale.Contract_Line_Item__c == null) {
              mapAssetEntToSELst.put(objAssetScale.Asset__c + '-' + objAssetScale.Entitlement__c,
                new Scale_Entitlement__c( Id = objAssetScale.Id, Contract_Line_Item__c = mapAssetEntToSELst.get(objAssetScale.Asset__c + '-' + objAssetScale.Entitlement__c).Contract_Line_Item__c));
            } else {
              mapAssetEntToSELst.remove(objAssetScale.Asset__c + '-' + objAssetScale.Entitlement__c);
            }
          }
        }
      }
    }
    /**
     * @description terminate Old Asset for Refresh
     * @param lstOfOrders
     * @param lstEntitlement
     * @param mapSCToUpdate
     * @param orderids
     * @param mapCLIData
     * @param mapOfCLItoUpdate
     */
    public void terminateOldAssets(
      List<Order> lstOfOrders,
      List<Entitlement> lstEntitlement,
      Map<Id, ServiceContract> mapSCToUpdate,
      set<id> orderids,
      Map<Id, ContractLineItem> mapCLIData,
      Map<Id, ContractLineItem> mapOfCLItoUpdate
    ) {
      Map<string, assetInfoClass> serialNumAsset = new Map<String, assetInfoClass>();
      Map<Id, Asset> AssetToupdate = new Map<Id, Asset>();
      Map<Id, Entitlement> entToUpdate = new Map<Id, Entitlement>();
      Set<string> AssetToRefreshSN = new Set<string>();
      Map<Id, Entitlement> CLIToEntitlement = new Map<Id, Entitlement>();
      Map<Id, List<String>> CLIToValidAsset = new Map<Id, List<String>>();
      Map<Id, Set<String>> CLIToRefreshedAsset = new Map<Id, Set<String>>();
      List<Entitlement> lstOfEnt = new List<Entitlement>();
        // Flag to indicate if the transaction is part of the Summer Release flow
        Boolean isSummerReleaseTransaction = false;
      Map<Id, Id> cliMapoldToNew = new Map<Id, Id>();
      for (Order ord : lstOfOrders) {
        for (OrderItem OI : ord.orderItems) {
          if(OI.Program__c != Constants.PROGRAM_REFRESH){
                    continue;
          } 
           if (!isSummerReleaseTransaction && String.isNotBlank(OI.Previous_Transaction_Reference__c)) {
             isSummerReleaseTransaction = true;
          }          
          if (OI.SerialNumber__c != null && string.isNotBlank(OI.SerialNumber__c)) {
            for (string SN : OI.SerialNumber__c.replaceAll('\\s+', '').split(',')) {
              serialNumAsset.put(SN, new assetInfoClass(null, ord.Actual_Order_Ship_Date__c, null));
            }
            if (OI.Upgraded_From__c != null && string.isNotBlank(OI.Upgraded_From__c)) {
              for (string SN : OI.Upgraded_From__c.replaceAll('\\s+', '').split(',')) {
                serialNumAsset.put(SN, new assetInfoClass(null, ord.Actual_Order_Ship_Date__c, OI.SerialNumber__c));
                AssetToRefreshSN.add(SN);
              }
            }
          }
        }
      }

      for (Asset eachAsset : [
        SELECT id, SerialNumber, Program__c, Processed_Date__c, UsageEndDate, Upgraded_Asset__c, product2.Usable_Capacity__c
        FROM Asset
        WHERE SerialNumber IN :serialNumAsset.KeySet()
      ]) {
        serialNumAsset.get(eachAsset.serialNumber).assetRec = eachAsset;
      }
      if (lstEntitlement != null && lstEntitlement.size() > 0) {
        for (Entitlement ent : lstEntitlement) {
          if (ent.Asset.SerialNumber != null && AssetToRefreshSN.contains(ent.Asset.SerialNumber)) {
            lstOfEnt.add(ent);
          }
          if (orderids.contains(ent.Order_Service_Item__r.orderid) && ent.Order_Service_Item__r.Previous_Contract_Line_Items__c != null) {
            for (String cli : ent.Order_Service_Item__r?.Previous_Contract_Line_Items__c?.trim()?.split(',')) {
              cliMapoldToNew.put(cli.trim(), ent.ContractLineItemId);
            }
          }
        }
      }
      for (String assetSN : AssetToRefreshSN) {
        Asset refreshedAsst = new Asset(id = serialNumAsset.get(assetSN).assetRec.Id);
        if (refreshedAsst.Program__c != 'Refreshed' && !AssetToupdate.containskey(refreshedAsst.id)) {
          refreshedAsst.Program__c = 'Refreshed';
          refreshedAsst.Processed_Date__c = serialNumAsset.get(assetSN)?.ordshipDate; //ordership date need to get from inner class
          if (serialNumAsset.get(assetSN) != null) {
            if (serialNumAsset.get(assetSN)?.ordshipDate != null) {
              refreshedAsst.UsageEndDate = serialNumAsset.get(assetSN)?.ordshipDate?.addDays(60);
            }
            if (serialNumAsset.get(assetSN).newSerialNum != null) {
              refreshedAsst.Upgraded_Asset__c = serialNumAsset.get(serialNumAsset?.get(assetSN)?.newSerialNum)?.assetRec.id; // reference from inner class
            }
          }
          AssetToupdate.put(refreshedAsst.id, refreshedAsst);
        }
      }
        for(Entitlement eachEnt: lstOfEnt){
            //Skip updates on the old V1 License during summer relase process
            if (isSummerReleaseTransaction && UtilityClass.isV1LicenseProduct(eachEnt?.Product__r)){
                continue;
            } 
            if(eachEnt.asset.Program__c != 'Refreshed' && !entToUpdate.containskey(eachEnt.id)){
          Entitlement ent = new Entitlement(id = eachEnt.id);
                ent.Go_Refresh__c = true ;
          ent.Renewal_Category__c = 'Refreshed';  
          
          // FY25SR-2348: Skip all date updates for Summer Release Transactions.
          if(!isSummerReleaseTransaction){
          ent.Refresh_Grace_Period_Start_Date__c = serialNumAsset.get(eachEnt.Asset.SerialNumber).ordshipDate;
          if (eachEnt.Product__r.Gorefresh_Mark_SW_End_Date__c == true) {
            ent.SW_Support_End_Date__c = serialNumAsset.get(eachEnt.Asset.SerialNumber).ordshipDate.addDays(60);
          } else if (eachEnt.EndDate != null && eachEnt.EndDate > serialNumAsset.get(eachEnt.Asset.SerialNumber).ordshipDate.addDays(60)) {
            ent.EndDate = serialNumAsset.get(eachEnt.Asset.SerialNumber).ordshipDate.addDays(60);
          }
          }

          entToUpdate.put(ent.id, ent);

                if(eachEnt.assetId != null && AssetToRefreshSN.contains(eachEnt.Asset.SerialNumber) && eachEnt.ContractLineItemId != null){ //null check for asset related to ent

            if (CLIToRefreshedAsset.containskey(eachEnt.ContractLineItemId)) {
              CLIToRefreshedAsset.get(eachEnt.ContractLineItemId).add(eachEnt.Asset.SerialNumber);
            } else {
              CLIToRefreshedAsset.put(eachEnt.ContractLineItemId, new Set<String>{ eachEnt.Asset.SerialNumber });
            }
          }
                If(eachEnt.ContractLineItemId != null && !CLIToEntitlement.containsKey(eachEnt.ContractLineItemId)){
            CLIToEntitlement.put(eachEnt.ContractLineItemId, eachEnt);
          }
        }
      }
      if (!CLIToRefreshedAsset.isEmpty()) {
        CLIToValidAsset = getNonRefreshedAsset(CLIToRefreshedAsset.keyset(), AssetToRefreshSN);
      }
      for (Id eachCLI : CLIToRefreshedAsset.keySet()) {
        List<String> listOfAssetSN = new List<String>();
        listOfAssetSN.addAll(CLIToRefreshedAsset.get(eachCLI));
        ContractLineItem CLI = new ContractLineItem(Id = eachCLI);
        ContractLineItem newCLI;
        if (!cliMapoldToNew?.isempty() && mapCLIData != null && !mapCLIData?.isempty()) {
          newCLI = cliMapoldToNew.containskey(CLI.id) &&
            cliMapoldToNew.get(cli.id) != null &&
            mapCLIData.containskey(cliMapoldToNew.get(cli.id)) &&
            mapCLIData.get(cliMapoldToNew.get(cli.id)) != null
            ? mapCLIData.get(cliMapoldToNew.get(cli.id))
            : null;
        }

        if ((CLIToEntitlement?.get(eachCLI)?.ContractLineItem?.SBQQSC__RenewalQuantity__c - CLIToRefreshedAsset?.get(eachCLI)?.size()) <= 0) {
          CLI.SBQQSC__TerminatedDate__c = serialNumAsset?.get(listOfAssetSN[0])?.ordshipDate != null ? serialNumAsset?.get(listOfAssetSN[0])?.ordshipDate?.addDays(60) : null;
          if (
            newCLI != null &&
            newCLI?.SBQQSC__Product__r?.Product_Level__c != 'Hybrid Software' &&
            newCLI?.SBQQSC__Product__r?.Product_Level__c != 'LOD Software' &&
            newCLI?.SBQQSC__Product__r?.Product_Level__c != 'OnPrem' &&
            CLIToValidAsset?.get(eachCLI) != null
          ) {
            CLI.SBQQSC__RootId__c = CLIToValidAsset?.get(eachCLI)[0];
          }
        }
        if (
          newCLI != null &&
          newCLI?.SBQQSC__Product__r?.Product_Level__c != null &&
          ((newCLI?.SBQQSC__Product__r?.Product_Level__c == 'Hybrid Software' ||
          (newCLI?.SBQQSC__Product__r?.Product_Level__c == 'OnPrem' &&
          (newCLI?.SBQQSC__Product__r?.Product_Type__c == 'Foundation Edition' ||
          newCLI?.SBQQSC__Product__r?.Product_Type__c == 'Business Edition' ||
          newCLI?.SBQQSC__Product__r?.Product_Type__c == 'Enterprise Edition') &&
          newCLI?.SBQQSC__Product__r?.Product_Subtype__c == null) ||
          newCLI?.SBQQSC__Product__r?.Product_Level__c == 'LOD Software') && newCLI?.SBQQSC__Product__r?.Product_Subtype__c != 'RCDM')
        ) {
          Decimal totUsablecap = 0;
          for (String eachAsset : listOfAssetSN) {
            if (serialNumAsset.get(eachAsset) != null && serialNumAsset.get(eachAsset)?.assetRec?.product2?.Usable_Capacity__c != null) {
              totUsablecap = totUsablecap + serialNumAsset.get(eachAsset)?.assetRec?.product2?.Usable_Capacity__c;
            }
          }
          CLI.SBQQSC__RenewalQuantity__c = (CLIToEntitlement.get(eachCLI).ContractLineItem.SBQQSC__RenewalQuantity__c - totUsablecap) >= 0
            ? (CLIToEntitlement.get(eachCLI).ContractLineItem.SBQQSC__RenewalQuantity__c - totUsablecap) : 0;
          CLI.Resync_Line__c = 'Required';
        } else if (
          newCLI != null && newCLI?.SBQQSC__Product__r?.Product_Level__c == 'Standalone Software Addon' || newCLI?.SBQQSC__Product__r?.Product_Level__c == 'SaaS Software Addon'
        ) {
          CLI.SBQQSC__RenewalQuantity__c = 0.00;
          CLI.Resync_Line__c = 'Required';
        } else {
          CLI.SBQQSC__RenewalQuantity__c = (CLIToEntitlement.get(eachCLI).ContractLineItem.SBQQSC__RenewalQuantity__c - CLIToRefreshedAsset.get(eachCLI).size()) >= 0
            ? (CLIToEntitlement.get(eachCLI).ContractLineItem.SBQQSC__RenewalQuantity__c - CLIToRefreshedAsset.get(eachCLI).size()) : 0;
          CLI.Resync_Line__c = 'Required';
        }
        mapOfCLItoUpdate.put(CLI.id, CLI);
      }
      /*SBQQ.TriggerControl.disable();
          if(!mapOfCLItoUpdate.values().isEmpty()){
              Update mapOfCLItoUpdate.values();
          }
          SBQQ.TriggerControl.enable();*/
      /*if(!mapSCToUpdate.values().isEmpty()){

              update mapSCToUpdate.values();
          } */
      if (!entToUpdate.values().isEmpty()) {
        update entToUpdate.values();
      }
      if (!AssetToupdate.values().isEmpty()) {
        update AssetToupdate.values();
      }
    }
    private static Map<Id, List<Id>> getNonRefreshedAsset(set<Id> cliIds, set<string> AssetToRefresh) {
      List<Entitlement> lstEnt = [SELECT id, AssetId, asset.SerialNumber, ContractLineItemId FROM Entitlement WHERE ContractLineItemId IN :cliIds];
      Map<Id, List<Id>> CLIToValidAsset = new Map<Id, List<Id>>();
      for (Entitlement ent : lstEnt) {
        if (!AssetToRefresh.contains(ent.asset.SerialNumber)) {
          CLIToValidAsset.put(ent.ContractLineItemId, new List<Id>{ ent.AssetId });
        }
      }
      return CLIToValidAsset;
    }

    //delete existing contractlines of original SC.
    private static List<ContractLineItem> deleteContractLines(List<ContractLineItem> lstDeleteCLI, Map<Id, Id> mapCLISourceIdToNewId) {
      for (Id cLIId : mapCLISourceIdToNewId.keySet()) {
        lstDeleteCLI.add(new ContractLineItem(Id = cLIId));
      }
      return lstDeleteCLI;
    }

    //delete service contracts
    private static List<ServiceContract> deleteServiceContract(
      List<ServiceContract> lstDeleteServiceContract,
      Map<Id, Id> mapCLISourceIdToNewId,
      Map<String, List<ContractLineItem>> mapSCIdToCLIAll,
      Map<String, X0_RCDM_Dates__mdt> rcdmMdt,
      Map<Id, ServiceContract> SCToUpdate
    ) {
      if (!mapSCIdToCLIAll.isEmpty()) {
        for (String strSC : mapSCIdToCLIAll.keySet()) {
          for (Integer i = mapSCIdToCLIAll.get(strSC).size() - 1; i >= 0; i--) {
            if (rcdmMdt.containsKey(mapSCIdToCLIAll.get(strSC)[i].SBQQSC__Product__r.ProductCode)) {
              if (!mapCLISourceIdToNewId.isEmpty() && mapCLISourceIdToNewId.containsKey(mapSCIdToCLIAll.get(strSC)[i].Id)) {
                mapSCIdToCLIAll.get(strSC).remove(i);
              }
            }
          }
        }

        for (String strSourceId : mapSCIdToCLIAll.keySet()) {
          if (mapSCIdToCLIAll.get(strSourceId).isEmpty() || mapSCIdToCLIAll.get(strSourceId) == null) {
            lstDeleteServiceContract.add(new ServiceContract(Id = strSourceId));
            if (SCToUpdate.containsKey(strSourceId)) {
              SCToUpdate.remove(strSourceId);
            }
          }
        }
      }

      return lstDeleteServiceContract;
    }

    //send Email to Renewal Owner
    private static void sendEmailToRenewalOwner(List<Entitlement> lstEntitlement, List<Order> lstOrderlst) {
      Set<String> setConvertedAssets = new Set<String>();
      Map<String, List<Entitlement>> mapSerialNumberToCLI = new Map<String, List<Entitlement>>();
      Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();
      OrgWideEmailAddress emailAddress = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'SFDC No Reply'];
      Id senderEmailId = emailAddress.Id;
      Map<String, List<String>> mapSerialNumberToOldCLI = new Map<String, List<String>>();
      List<String> lstOldCLI = new List<String>();
      String recepient;
      String subject = 'Order' + lstOrderlst[0].OrderNumber + ' is either refreshed or converted';
      String href = URL.getSalesforceBaseUrl().toExternalForm();
      String emailTextHtml = '<p>Hello,</p>';
      emailTextHtml +=
        '<p>As part of Order <a href="' +
        href +
        '/' +
        lstOrderlst[0].Id +
        '">' +
        lstOrderlst[0].OrderNumber +
        '</a> the assets listed below were either refreshed or converted. Please review and update the entitlements as well as inflight opportunity and quotes as needed.</p>';
      emailTextHtml += '<p>Converted/Refreshed Opportunity : ' + lstOrderlst[0].Opportunity.Name + '</p>';
      emailTextHtml += '<p>Close Date:' + lstOrderlst[0].Opportunity.CloseDate + '</p>';
      emailTextHtml += '<table border="1" style="border-collapse: collapse"><tr><th>Asset</th><th>Service Contract Lines</th><th>Renewal Opportunity</th></tr>';
      for (OrderItem objOLI : lstOrderlst[0].OrderItems) {
        if (String.isNotEmpty(objOLI.Previous_Contract_Line_Items__c)) {
          for (String strOLDCLI : objOLI.Previous_Contract_Line_Items__c.trim().split(',')) {
            lstOldCLI.add(strOLDCLI.trim());
          }
        }
        if (String.isNotEmpty(objOLI.SerialNumber__c)) {
          for (String strSerialNumbers : objOLI.SerialNumber__c.trim().split(',')) {
            setConvertedAssets.add(strSerialNumbers.trim());
          }
        }
        if (String.isNotBlank(objOLI.SerialNumber__c)) {
          for (String strSerialNumbers : objOLI.SerialNumber__c.trim().split(',')) {
            setConvertedAssets.add(strSerialNumbers.trim());
          }
        }

        if (String.isNotBlank(objOLI.Upgraded_From__c)) {
          for (string strString : objOLI.Upgraded_From__c.trim().split(',')) {
            if (!setConvertedAssets.contains(strString.trim()))
              setConvertedAssets.add(strString.trim());
          }
        }
      }
      if (!lstOldCLI.isEmpty() && !setConvertedAssets.isEmpty()) {
        for (Entitlement objEnt : lstEntitlement) {
          if (objEnt.AssetId != null) {
            if (
              lstOldCLI.contains(objEnt.ContractLineItemId) && (setConvertedAssets.contains(objEnt.Asset.SerialNumber) || setConvertedAssets.contains(objEnt.Asset.Serial_Number__c))
            ) {
              string serialNumber = objEnt.Asset.SerialNumber != null ? objEnt.Asset.SerialNumber : objEnt.Asset.Serial_Number__c;
              if (serialNumber != null) {
                if (!mapSerialNumberToCLI.containskey(serialNumber))
                  mapSerialNumberToCLI.put(serialNumber, new List<Entitlement>{});
                mapSerialNumberToCLI.get(serialNumber).add(objEnt);
              }
            }
          }
        }
      }
      if (!mapSerialNumberToCLI.isEmpty()) {
        for (String strSerialNumber : mapSerialNumberToCLI.keySet()) {
          emailTextHtml += '<tr><td>' + strSerialNumber + '</td>';
          String CLINumber = '';
          String OpportunityName = '';
          for (Entitlement objEnt : mapSerialNumberToCLI.get(strSerialNumber)) {
            CLINumber += '<a href="' + href + '/' + objEnt.ContractLineItemId + '">' + objEnt.ContractLineItem.LineItemNumber + '</a>, ';
            OpportunityName +=
              '<a href="' +
              href +
              '/' +
              objEnt.ContractLineItem.SBQQSC__OrderProduct__r.Order.OpportunityId +
              '">' +
              objEnt.ContractLineItem.SBQQSC__OrderProduct__r.Order.Opportunity.Name +
              '</a>, ';
          }
          CLINumber = CLINumber.removeEnd(', ');
          OpportunityName = OpportunityName.removeEnd(', ');
          emailTextHtml += '</td>' + CLINumber + '</td><td>' + OpportunityName + '</td></tr>';
        }
        emailTextHtml += '</table>';

        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = new List<String>{ lstOrderlst[0].Opportunity.Owner.Email };
        message.setSubject(subject);
        message.setHtmlBody(emailTextHtml);
        message.setOrgWideEmailAddressId(senderEmailId);
        if (String.isNotBlank(Label.Renewal_Cc_Email)) {
          message.setCcAddresses(new List<String>{ Label.Renewal_Cc_Email });
        }
        messages.add(message);
      if (messages.size() > 0 && !Test.isRunningTest()) {
          Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        }
      }
    }

    private void createScaleUtilityClusReg(List<Order> lstOfOrder, Map<Id, Id> mapOfOrdIdToSCId) {
      try {
        List<Scale_Utility_Cluster_Registration__c> lstOfCluReg = new List<Scale_Utility_Cluster_Registration__c>();
        for (Order ord : lstOfOrder) {
          for (Orderitem oi : ord.orderitems) {
            if (
              oi.Product2.Product_Subtype__c == Constants.PROD_SUB_TYPE_SCALE_MSP &&
              oi.Product2.License_Category__c == null &&
              !oi.Product2.Bundle_Features__c?.containsIgnoreCase(Constants.PROD_BUNDLE_FEATURES_M365H)
            ) {
              Scale_Utility_Cluster_Registration__c suClusterReg = new Scale_Utility_Cluster_Registration__c();
              suClusterReg.Account_ID__c = ord.AccountId;
              suClusterReg.Service_Contract_ID__c = mapOfOrdIdToSCId.get(ord.id);
              suClusterReg.Global_Commit_ID__c = oi.Global_Commit_ID__c;
              suClusterReg.License_ID__c = oi.Product2Id;
              suClusterReg.License_Order_Product__c = oi.id;
              suClusterReg.Order_ID__C = ord.Id;
              lstOfCluReg.add(suClusterReg);
            }
          }
        }
        if (!lstOfcluReg.isEmpty()) {
          Database.insert(lstOfcluReg, false);
        }
      } catch (Exception e) {
        UtilityClass.logException(e, 'ContractOrders', 'createScaleUtilityClusReg', 'Scale_Utility_Cluster_Registration__c', null, 'SFDC', false);
      }
    }

    private class AssetInfoClass {
      asset assetRec;
      Date ordshipDate;
      String newSerialNum;
      private assetInfoClass(asset assetRec, Date ordshipDate, String newSerialNum) {
        this.assetRec = assetRec;
        this.ordshipDate = ordshipDate;
        this.newSerialNum = newSerialNum;
      }
    }

    /** 
     * @description For all the custom created entitlement for GC Offer Contract lines (Scale Utility project), there has to be a link
     * between segment/MDQ emtitlements. Example, segment 1 entitlement will be linked with segment 2 entitlement and so on
     * @param newGCOfferSegmentEntitlementsByProductId
     **/
    public static void generateEntitlementLinks(Map<Id, List<Entitlement>> newGCOfferSegmentEntitlementsByProductId) {
      List<Entitlement_Links__c> gcOfferEntitlementLinksToCreate = new List<Entitlement_Links__c>();

      if (newGCOfferSegmentEntitlementsByProductId?.size() > 0) {
        for (Id productId : newGCOfferSegmentEntitlementsByProductId.keySet()) {
          Entitlement previousEntitlement;
          for (Entitlement renewalEntitlement : newGCOfferSegmentEntitlementsByProductId.get(productId)) {
            if (
              previousEntitlement != null &&
              previousEntitlement != renewalEntitlement &&
              renewalEntitlement.ServiceContractId == previousEntitlement.ServiceContractId &&
              renewalEntitlement.Product__r.Product_Subtype__c == Constants.PROD_SUB_TYPE_SCALE_MSP &&
              renewalEntitlement.Product__r.License_Category__c == Constants.PROD_LICENSE_CATEGORY_SAAS &&
              previousEntitlement.Product__r.Product_Subtype__c == Constants.PROD_SUB_TYPE_SCALE_MSP &&
              previousEntitlement.Product__r.License_Category__c == Constants.PROD_LICENSE_CATEGORY_SAAS
            ) {
              Entitlement_Links__c entLink = new Entitlement_Links__c(
                Previous_Entitlement__c = previousEntitlement.Id,
                Renewed_Entitlement__c = renewalEntitlement.Id,
                Type__c = Constants.ORDER_SUB_TYPE_GC_OFFER,
                Quantity__c = Constants.DEFAULT_SU_ENTITLEMENT_LINK_QUANTITY
              );
              gcOfferEntitlementLinksToCreate.add(entLink);
            }
            previousEntitlement = renewalEntitlement;
          }
        }
      }

      try {
        if (!gcOfferEntitlementLinksToCreate.isEmpty()) {
          Database.SaveResult[] srList = Database.insert(gcOfferEntitlementLinksToCreate, false);
        }
      } catch (Exception e) {
        UtilityClass.logException(e, 'ContractOrders', 'generateEntitlementLinks', 'Entitlement_Links__c', null, 'SFDC', false);
      }
    }

  /**
   * Wrapper class to store details required for updating old entitlements
   */
  /**
   * @description OldEntitlementUpdateWrapper
   */
  public class OldEntitlementUpdateWrapper {
    public String renewalCategory;
  } 
  
}