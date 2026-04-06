/**
 * @description        Helper class for OrderItem Trigger
 * @author             Chaitra
 * @last modified on   15-04-2025
 * @last modified by   Ravi Mali
 */
public with sharing class OrderItemTriggerHelper {
  public static final String REVENUE_TYPE = 'Revenue';
  public static Map<Id, Order> mapOfOrders;
  public static Boolean insertTransaction = false;
  public static Map<Id, OrderItem> mapOfIdtoOrderItem;
  public static Set<String> quoteIds = new Set<String>();
  public static Map<Id, Entitlement> mapOfIdToEnt;
  public static Map<Id, OrderItem> oiUpdateMap = new Map<Id, OrderItem>(); //CSU-444 Change List To Map
  public static List<String> quotePrograms;
  public static Map<String, String> orderIdToGCId = new Map<String, String>();
  public static Map<String, Asset> mapAssetNumberToAsset = new Map<String, Asset>();
  public static Boolean isRecentlyInserted = false;
  public static Map<Id, OpportunityLineItem> qliOppLIMap = new Map<Id, OpportunityLineItem>();
  public static Map<String, String> polarisSkuMapping = new Map<String, String>();
  public static Map<Id, Asset> toUpdateAssets = new Map<Id, Asset>();
  public static Map<Id, Id> pOrderItemVsOriginalOrder = new Map<Id, Id>();
  public static Map<Id, SBQQ__QuoteLine__c> quoteLineItemById = new Map<Id, SBQQ__QuoteLine__c>();
  public static Set<Id> originalOrderItemSet = new Set<Id>();
  public static string RCDMTransSkuName = X0_RCDM_Dates__mdt.getInstance('RS_BT_RCDM_T')?.Product_Name__c;
  public static Map<String, Id> settingOppLineMap = new Map<String, Id>();
  public static Map<Id, ReplacementJson> qliJsonById = new Map<Id, ReplacementJson>(); // Stores deserialized Replacement JSON by QLI Id
  public static Map<Id, Entitlement> allEntitlementsById;
  
  /**
   * @description Data collection used in entire order item trigger transaction
   * @author Prashant Kumar
   * @param setOfOrderIds
   * @param isBeforeInsert
   */
  public static void orderItemInit(set<id> setOfOrderIds, Boolean isBeforeInsert) {
    Set<String> setQuoteIds = new Set<String>();
    Set<String> AssetSNSet = new Set<String>();
    Set<Id> productIds = new Set<Id>();
    mapOfIdtoOrderItem = new Map<Id, OrderItem>();
    quotePrograms = new List<String>();
    set<Id> opptyId = new Set<Id>();
    List<Id> prevCLIItemsFromOI = new List<Id>();
    Set<Id> inactiveEntIds = new Set<Id>();
    mapOfOrders = new Map<Id, order>(
      [
        SELECT
          id,
          RecordType.Name,
          opportunityId,
          effectivedate,
          ordernumber,
          Type,
          Order_Sub_Type__c,
          opportunity.recordtypeId,
          Related_Order__c,
          HW_Order__c,
          SBQQ__Quote__c,
          SBQQ__Quote__r.Opportunity_Program__c,
          is_Amendment_Order__c,
          SBQQ__Quote__r.SBQQ__Type__c,
                   Associated_Order_Numbers__c,
          ProcessType__c
        FROM order
        WHERE Id IN :setOfOrderIds
      ]
    );
    for (Order objOrder : mapOfOrders.values()) {
      // PRDOPS25-972 including GC ondemand
      if (objOrder.Order_Sub_Type__c == 'MSP Overage' || objOrder.Order_Sub_Type__c == 'GC OnDemand')
        opptyId.add(objOrder.opportunityId);

      if (objOrder?.SBQQ__Quote__c != null) {
        quoteIds.add(objOrder.SBQQ__Quote__c);
      }
      if (String.isNotBlank(objOrder?.SBQQ__Quote__r?.Opportunity_Program__c)) {
        for (String strProg : objOrder.SBQQ__Quote__r.Opportunity_Program__c.trim().Split(',')) {
          quotePrograms.add(strProg.trim());
        }
      }
    }
    for (OrderItem OI : (List<OrderItem>) Trigger.new) {
      if (
        mapOfOrders?.get(OI.OrderId)?.RecordType.Name == 'Phantom Order' &&
        OI.Support_Start_Date__c != null &&
        OI.Previous_Transaction_Reference__c != null &&
        OI.Support_End_Date__c != null
      ) {
        PreviousTransRefWrapper.PhantomPrevLineDetail prevLine = (PreviousTransRefWrapper.PhantomPrevLineDetail) JSON.deserialize(
          OI.Previous_Transaction_Reference__c,
          PreviousTransRefWrapper.PhantomPrevLineDetail.class
        );
        pOrderItemVsOriginalOrder.put(OI.Id, prevLine.orderItemId);
        originalOrderItemSet.add(prevLine.orderItemId);
      }
    }
    if (quoteIds != null) {
      for (SBQQ__QuoteLine__c qli : [
        SELECT
          id,
          Subscribed_Asset_Name__c,
          Disposition_Reason__c,
          SBQQ__Quote__r.Opportunity_Program__c,
          SBQQ__Quote__r.SBQQ__Opportunity2__r.Sell_to_Partner__c,
          Prepayment_Credit__c,
          SBQQ__SegmentLabel__c,
          SBQQ__Quote__r.Manual_Fulfillment_Quote__c,
          Trade_Up_Serial_Number__c,
          SBQQSC__RenewedContractLine__c,
          SBQQ__Quote__r.SBQQ__Type__c,
          SubscribedAssetNames__c,
          SBQQ__Quote__r.Is_RWD_Polaris_Quote__c,
          SBQQ__StartDate__c,
          SBQQ__EndDate__c,
          Arroyo_Subscribed_Asset_Name__c,
          SBQQ__ListPrice__c,
          Special_Program__c,
          SBQQ__Product__r.Product_Level__c,
          SBQQ__Product__r.Product_Type__c,
          SBQQ__Product__r.Upgrade_Path__c,
          Account_s_Entitlement__c,
          SBQQ__RequiredBy__c,
          SBQQ__RequiredBy__r.SBQQ__Product__r.Usable_Capacity__c,
          SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,
          SBQQ__CustomerPrice__c,
          Arroyo_Subsumed_Old_Contract_Line_Items__c,
          TPH_Drive_Size__c,
          TPH_Models_Gen__c,
          TPH_OEM__c,
          TPH_Quantity__c,
          SBQQ__Quantity__c,
          Replacement_Details__c,
          SBQQ__Quote__c,
          Line_Type__c,
          SBQQ__Optional__c,
          SBQQ__Product__r.SBQQ__Optional__c,
          SBQQ__Product__r.SBQQ__ExcludeFromOpportunity__c,
          SBQQ__Existing__c,
          (SELECT id, Quantity, Replacement_Type__c, Previous_Transaction_Reference__c FROM sbqq__OrderProducts__r)
        FROM SBQQ__QuoteLine__c
        WHERE SBQQ__Quote__c IN :quoteIds
      ]) {
        quoteLineItemById.put(qli.id, qli);
        if (qli.Arroyo_Subscribed_Asset_Name__c != null) {
          AssetSNSet.addall(qli.Arroyo_Subscribed_Asset_Name__c?.deleteWhitespace().split(','));
        }
        if (qli.SubscribedAssetNames__c != null) {
          AssetSNSet.addall(qli.SubscribedAssetNames__c?.deleteWhitespace().split(','));
        }
        if (qli.Arroyo_Subsumed_Old_Contract_Line_Items__c != null) {
          prevCLIItemsFromOI.addall(qli.Arroyo_Subsumed_Old_Contract_Line_Items__c?.deleteWhitespace().split(','));
        }
      }
    }

    if (quoteLineItemById != null && qliJsonById.isEmpty()) {
      qliJsonById = deserializeQliJson(quoteLineItemById);
      
      for (Id qliId : qliJsonById.keySet()) {
        ReplacementJson qliJsonWrapper = qliJsonById.get(qliId);
        Set<Id> tempInactiveEntIds = qliJsonWrapper != null ? UtilityClass.getChildEntIdsFromQliJson(qliJsonWrapper, null) : new Set<Id>();
        inactiveEntIds.addAll(tempInactiveEntIds);
      }
    }

    if ((qliOppLIMap.isEmpty() && !quoteIds.isEmpty()) || !opptyId.isempty()) {
      for (OpportunityLineItem oppLine : [
        SELECT Id, OpportunityId, Product2.name, Quantity, SBQQ__QuoteLine__c
        FROM OpportunityLineItem
        WHERE SBQQ__QuoteLine__r.SBQQ__Quote__c IN :quoteIds OR opportunityId IN :opptyId
      ]) {
        settingOppLineMap.put(oppLine.OpportunityId + '-' + oppLine.Product2.name + '-' + oppLine.Quantity, oppLine.Id);
        if (oppLine.SBQQ__QuoteLine__c != null)
          qliOppLIMap.put(oppLine.SBQQ__QuoteLine__c, oppLine);
      }
    }
    if ((mapOfIdtoOrderItem.isEmpty() && !isBeforeInsert) || !AssetSNSet.isEmpty() || !prevCLIItemsFromOI.isEmpty()) {
      mapOfIdtoOrderItem = new Map<Id, OrderItem>(
        [
          SELECT
            Id,
            Line_Type__c,
            Replacement_Type__c,
            OrderItemNumber,
            SBQQ__QuoteLine__r.Arroyo_Subsumed_Old_Contract_Line_Items__c,
            SBQQ__QuoteLine__r.Replacement_Details__c,
            SBQQ__QuotedQuantity__c,
            Global_Commit_Split_ID__c,
            Support_Start_Date__c,
            Support_End_Date__c,
            TotalPrice,
            Previous_Transaction_Reference__c,
            SBQQ__QuoteLine__r.SBQQ__EndDate__c,
            SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQSC__UpgradedContractLine__r.SBQQSC__OrderProduct__c,
            SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQSC__UpgradedContractLine__r.SBQQSC__OrderProduct__c,
            SBQQ__QuoteLine__r.SBQQ__StartDate__c,
            SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQSC__UpgradedContractLine__r.Global_Commit_ID__c,
            SBQQ__QuoteLine__r.SBQQSC__UpgradedContractLine__r.Global_Commit_ID__c,
            SBQQ__QuoteLine__r.SBQQ__Quote__r.Amended_Renewed_Service_Contract__r.Quote_additional_month__c,
            SBQQ__QuoteLine__r.Required_By_Product_Code__c,
            SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.Required_By_Product_Code__c,
            SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQSC__UpgradedContractLine__r.Global_Commit_ID__c,
            SBQQ__RequiredBy__r.Product2.Name,
            Order.opportunity.recordtypeId,
            SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__SubscriptionTerm__c,
            Order.Order_Status__c,
            SBQQ__OrderedQuantity__c,
            SBQQ__QuoteLine__r.SBQQ__Quantity__c,
            Quantity,
            Product2.ProductCode,
            SBQQ__QuoteLine__r.SBQQ__Quote__c,
            SBQQ__QuoteLine__r.Trade_Up_Serial_Number__c,
            SBQQ__SubscriptionTerm__c,
            Order_Status__c,
            Support_Term__c,
            Order.Bill_To_Name__c,
            Order.type,
            Order.NetSuite_Order__c,
            Order.EffectiveDate,
            Order.POC_Request__r.Most_Recent_End_Date__c,
            Order.Order_Sub_Type__c,
            SBQQ__RequiredBy__c,
            SBQQ__RequiredBy__r.SBQQSC__ContractLineItem__c,
            SBQQSC__ContractLineItem__c,
            SerialNumber__c,
            Upgraded_From__c,
            Order.Is_RWD_Polaris_Quote__c,
            Order.ProcessType__c,
            Order.Sell_to_Partner__c,
            product2.Product_Level__c,
            SBQQ__QuoteLine__r.Special_Program__c,
            Product2.Name,
            SBQQ__RequiredBy__r.Product2.Product_Level__c,
            SBQQ__RequiredBy__r.SerialNumber__c,
            SBQQSC__ContractLineItem__r.SBQQSC__RequiredById__c,
            SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.Product2.Product_Level__c,
            product2.Product_Type__c,
            SBQQ__QuoteLine__c,
            product2.License_per_Qty__c,
            Licence_Type__c,
            SBQQ__QuoteLine__r.SBQQ__Quote__r.Additional_Month_added__c,
            SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Level__c,
            Product2.Bundle_Features__c,
            SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Level__c,
            Product2.License_Type__c,
            SBQQ__QuoteLine__r.Licensing_Model__c,
            SBQQ__QuoteLine__r.Subscribed_Asset_Name__c,
            Order.Has_Third_Party_Hardware_Product__c,
            SBQQ__QuoteLine__r.SubscribedAssetNames__c,
            Product2.Product_Subtype__c,
            Product2.License_Category__c,
            SBQQ__QuoteLine__r.Arroyo_Subscribed_Asset_Name__c,
            Previous_Contract_Line_Items__c,
            Program__c,
            Global_Commit_ID__c,
            Product_Name__c,
            SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c,
            SBQQSC__ContractLineItem__r.Global_Commit_ID__c,
            Order.AccountId,
            SBQQ__QuoteLine__r.SBQQ__Quote__r.Amended_Renewed_Service_Contract__c,
            SBQQ__QuoteLine__r.SBQQ__Product__r.Family,
            SBQQ__QuoteLine__r.TPH_Quantity__c,
            Product2.Entitlement_Conversion_Non_CPQ__c,
            Product2.SBQQSC__EntitlementConversion__c,
            SBQQ__QuoteLine__r.SBQQ__SubscriptionTerm__c,
            SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c,
            Order.Actual_Order_Ship_Date__c,
            EndDate,
            SBQQ__QuoteLine__r.Line_Type__c,
            SBQQ__SegmentIndex__c,
            orderId,
            SBQQ__QuoteLine__r.SBQQ__EffectiveEndDate__c,
            Order.is_Amendment_Order__c,
            SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQSC__MasterServiceContract__c,
            SBQQ__QuoteLine__r.SBQQ__Quote__r.RWD_Deal_Ops_Exception__c,
            product2.Edition__c,
            product2.SBQQ__SubscriptionPricing__c,
            Opportunity_Product__r.Renewal_Target_Amount__c,
            Opportunity_Product__r.RBOBACV__c,
            Opportunity_Product__r.PromoDiscTCV__c,
            Opportunity_Product__r.Oppty_Trade_Up_Discount__c,
            Opportunity_Product__r.Quantity,
            Product2Id,
            (SELECT Id, ContractLineItemId, Order_Service_Item__c FROM Entitlements__r)
          FROM OrderItem
          WHERE SBQQ__QuoteLine__r.SBQQ__Quote__c IN :quoteIds OR Id IN :Trigger.new OR Id IN :originalOrderItemSet
        ]
      );

      Set<String> setSerialNumber = new Set<String>();
      Set<Id> setPOCProductId = new Set<Id>();
      for (OrderItem OI : mapOfIdtoOrderItem.values()) {
        if (OI.Order.Type == 'POC') {
          setPOCProductId.add(OI.Product2Id);
        }

        if (String.isNotBlank(OI.SerialNumber__c)) {
          for (String strSerialNumber : OI.SerialNumber__c.trim().split(',')) {
            setSerialNumber.add(strSerialNumber.trim());
          }
        }
        if (OI.SBQQ__QuoteLine__c != null) {
          if (OI.SBQQ__QuoteLine__r.Arroyo_Subscribed_Asset_Name__c != null) {
            AssetSNSet.addall((OI.SBQQ__QuoteLine__r.Arroyo_Subscribed_Asset_Name__c.replaceAll('\\s+', '').split(',')));
          }
          if (OI.SBQQ__QuoteLine__r.SubscribedAssetNames__c != null) {
            AssetSNSet.addall((OI.SBQQ__QuoteLine__r.SubscribedAssetNames__c.replaceAll('\\s+', '').split(',')));
          }
        }

        //CSU-7 Start
        if (Trigger.isAfter && Trigger.isInsert) {
          if (
            Trigger.newMap?.keyset()?.contains(OI.Id) &&
            OI.Order?.Order_Sub_Type__c == Constants.ORDER_SUB_TYPE_GC_OFFER &&
            oi.product2.Product_Subtype__c == Constants.PROD_SUB_TYPE_SCALE_MSP &&
            String.isBlank(oi.Product2.License_Category__c) &&
            (OI?.SBQQ__QuoteLine__r?.SBQQ__Quote__r?.SBQQ__Type__c != Constants.AMENDMENT_QUOTE ||
            (OI?.SBQQ__QuoteLine__r?.SBQQ__Quote__r?.SBQQ__Type__c == Constants.AMENDMENT_QUOTE &&
            OI?.SBQQ__QuoteLine__r?.SBQQ__Quote__r?.SBQQSC__MasterServiceContract__c != null && OI?.SBQQ__QuoteLine__r?.SBQQ__Quote__r?.Amended_Renewed_Service_Contract__c != null && OI?.SBQQSC__ContractLineItem__c == null
            ))
          ) {
            OI.Global_Commit_ID__c = OI?.Order?.AccountId + '-' + OI.Id + '-' + OI?.Product_Name__c;
            OI.Global_Commit_Split_ID__c = OI?.Order?.AccountId + '-' + OI.Id + '-' + OI?.Product_Name__c;
            orderIdToGCId.put(OI.OrderId + '-' + OI?.Product_Name__c, OI.Global_Commit_ID__c);
            oiUpdateMap.put(OI.id, OI);
          }
        }
        //CSU-7 End
      }
      // CSU-474: Calling All Logic Of Setting Global Commit Id,Global Commit Split Id, requiredBy
      // on Amendment as well regular Scale Utility OrderLines
      for (OrderItem OI : mapOfIdtoOrderItem.values()) {
        if (Trigger.isAfter && Trigger.isInsert) {
          stampGlobalCommitIdOnOrderLinesForSU(OI);
        }
      }

      if (setSerialNumber != null || !AssetSNSet.isEmpty()) {
        for (Asset objAsset : [
          SELECT
            Id,
            name,
            SerialNumber,
            Serial_number__c,
            Product2ID,
            Quantity,
            Order_Service_Item__r.SBQQ__QuoteLine__c,
            Location__c,
            AccountId,
            Account.Name,
            Product2.Asset_Upgrade_Product__c,
            Bypass_Account_and_Product_Update__c,
            Order_Service_Item__c,
            Product_Code_Custom__c,
            Order_Service_Item__r.Order.Type,
            Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__DynamicOptionId__c,
            Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__OptionType__c,
            Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__OptionLevel__c,
            Order_Service_Item__r.SBQQ__RequiredBy__r.SBQQSC__ContractLineItem__c,
            Order_Service_Item__r.SBQQSC__ContractLineItem__c,
            Order_Service_Item__r.Order.Is_RWD_Polaris_Quote__c,
            Order_Service_Item__r.Order.Order_SubType__c,
            Product_Usable_Capacity__c
          FROM Asset
          WHERE serialNumber IN :setSerialNumber OR serialNumber IN :AssetSNSet
        ]) {
          mapAssetNumberToAsset.put(objAsset.serialNumber, objAsset);
          if (objAsset.Product2ID != null) {
            productIds.add(objAsset.Product2ID);
          }
        }
      }
      if (!productIds.isEmpty()) {
        for (Polaris_SKU_Mapping_V2__c skuMapping : [SELECT Id, New_Product__c, Old_Product__c FROM Polaris_SKU_Mapping_V2__c WHERE Old_Product__c IN :productIds]) {
          if (skuMapping.New_Product__c != null) {
            polarisSkuMapping.put(skuMapping.Old_Product__c, skuMapping.New_Product__c);
          }
        }
      }
      if (allEntitlementsById == null) {
      allEntitlementsById = new Map<Id, Entitlement>(
          [
            SELECT
              id,
              Asset.SerialNumber,
              Phantom_OrderItemID__c,
              Phantom_OrderItemID__r.Quantity,
              ContractLineItem.LinkedAssets__c,
              ContractLineItemId,
              EndDate,
              Asset.Name,
              Asset.serial_number__c,
              Product__r.Product_Type__c,
              Product__r.Name,
              Product__r.Approval_Category__c,
              product__r.Bundle_Features__c,
              Order_Service_Item__c,
              Order_Service_Item__r.Quantity,
              Product__r.Product_Level__c,
              Order_Service_Item__r.Order.OrderNumber,
              Quantity__c, 
              (SELECT Id, Asset__r.SerialNumber, Asset__r.Name, Asset__c, Contract_Line_Item__c, Entitlement__c FROM Scale_Entitlements__r)
            FROM Entitlement
            WHERE Asset.serial_number__c IN :AssetSNSet OR ContractLineItemId IN :prevCLIItemsFromOI OR Id IN :inactiveEntIds
            ORDER BY EndDate DESC
          ]
        );
      }
      if (!oiUpdateMap.isEmpty() && Trigger.isAfter && Trigger.isInsert  && !OpportunityBulkUpdateQueueable.isBulkDeal) {
        System.enqueueJob(new UpdateSupportOrderLinesDatesForCSUClass(oiUpdateMap.values()));
      }
    }
    
    if (allEntitlementsById != null && !allEntitlementsById.isEmpty() && mapOfIdToEnt == null) {
      mapOfIdToEnt = new Map<Id, Entitlement>();
      for (Entitlement ent : allEntitlementsById.Values()) {
        if (
            (ent.Asset?.serial_number__c != null && AssetSNSet.contains(ent.Asset.serial_number__c)) ||
            (ent.ContractLineItemId != null && prevCLIItemsFromOI.contains(ent.ContractLineItemId))
        ) {
            mapOfIdToEnt.put(ent.Id, ent);
        }
      }
    }
  }
  /**
   * @description For the Non-Aspen Order: Updates the SerialNumber__c field on refresh OrderItems
   * based on a mapping from old serial numbers (Upgraded_From__c)
   */
  public static void updateRefreshOrderItemSerialNumbers() {
    Map<String, Set<String>> newAssetsByOldAsset = new Map<String, Set<String>>();
    Map<Id, OrderItem> orderItemToUpdate = new Map<Id, OrderItem>();

    for (OrderItem OI : mapOfIdtoOrderItem.values()) {
      UtilityClass.getNewAssetsByOldAssetMapping(OI, newAssetsByOldAsset);
    }

    if (newAssetsByOldAsset.isEmpty()) {return;}

    for (OrderItem OI : mapOfIdtoOrderItem.values()) {
      // Update Serial # only for Refresh, Replacement Licenses, and Renewals
      if (!UtilityClass.isRefreshedLicenseOI(OI) && !(OI.Line_Type__c == Constants.ORDER_TYPE_RENEWAL && String.isNotBlank(OI.Upgraded_From__c)) && !Test.isRunningTest()) {continue;}
      
      Set<String> newSerialNumbers = new Set<String>();
      List<String> replacedFromSerialNumbers = OI.Upgraded_From__c != null ? OI.Upgraded_From__c.split(',') : new List<String>();

      for (String oldSN : replacedFromSerialNumbers) {
        String trimmedOldSN = oldSN.trim();
        if (newAssetsByOldAsset.containsKey(trimmedOldSN)) {
          newSerialNumbers.addAll(newAssetsByOldAsset.get(trimmedOldSN));
        }
      }

      if (newSerialNumbers.isEmpty()) {continue;}

      if (OI.Program__c == CONSTANTS.PROGRAM_REFRESH) {
        OI.SerialNumber__c = String.join(new List<String>(newSerialNumbers), ',');
        orderItemToUpdate.put(OI.Id, OI);
      } else if (Constants.REPLACEMENT_PROGRAMS.contains(OI.Program__c) || OI.Line_Type__c == Constants.ORDER_TYPE_RENEWAL) {
        if (String.isNotBlank(OI?.SerialNumber__c)) {
          for (String SR : OI.SerialNumber__c.split(',')) {
            String trimmedSR = SR.trim();
            if (!replacedFromSerialNumbers.contains(trimmedSR)) {
              newSerialNumbers.add(trimmedSR);
            }
          }
        }
        OI.SerialNumber__c = String.join(new List<String>(newSerialNumbers), ',');
        orderItemToUpdate.put(OI.Id, OI);
      }
    }

    if (!orderItemToUpdate.isEmpty()) {
      update orderItemToUpdate.values();
    }
  }

   /**
 * @description Updates SerialNumber__c field on License-type OrderItems by associating them 
 * with serial numbers from corresponding Hardware OrderItems based on Entitlement IDs.
 *
 * @param nonAstToAstOrdItmWithSerialNum - List of Hardware / Hw Support OrderItems for which serial numbers need to be mapped.
 * @param isAspenOrder
 * @author Naveen Selvaraj
 */
  public static void updateSerialNumOnLicenseLine(List<OrderItem> nonAstToAstOrdItmWithSerialNum, Boolean isAspenOrder) {
    if (nonAstToAstOrdItmWithSerialNum == null || nonAstToAstOrdItmWithSerialNum.isEmpty()) {return;}
        Map<Id, Set<String>> assetSerialNumsByEntId = new Map<Id, Set<String>>();
        List<OrderItem> orderItemsToUpdate = new List<OrderItem>();
        Set<Id> quoteIds = new Set<Id>();
        Set<String> newSerialNumsToQuery = new Set<String>();
        Map<String, Asset> assetBySerialNumber = new Map<String, Asset>();
    Map<Id, Entitlement> newEntsById = new Map<Id, Entitlement>();
        List<Scale_Entitlement__c> linkedAstToCreate = new List<Scale_Entitlement__c>();
        // Process input hardware OrderItems to extract entitlement-serial mappings
        for (OrderItem oi : nonAstToAstOrdItmWithSerialNum) {
            // Re-fetch OrderItem from global map if required
            oi = mapOfIdtoOrderItem.containsKey(oi.Id) ? mapOfIdtoOrderItem.get(oi.Id) : null;
      if (oi == null) {continue;}
            String skuType = UtilityClass.getTypeofSKU(oi);
            quoteIds.add(oi.SBQQ__QuoteLine__r.SBQQ__Quote__c);
            Set<String> assetSerialNums = new Set<String>();
            if (oi.SerialNumber__c != null) {
                assetSerialNums.addall(new Set<String>(oi.SerialNumber__c.replaceAll('\\s+', '').split(',')));
            }
            // Filtering HW line Item for Non-Aspen || HW Support line item for Aspen 
            if (skuType == Constants.SKU_TYPE_HARDWARE || skuType == Constants.SKU_TYPE_HW_SUPPORT) {
                Set<String> entIds = UtilityClass.getEntIdFromQliJson(oi.SBQQ__QuoteLine__r);
        if (entIds == null || entIds.isEmpty()) {continue;}
                // Prepare Serialnumbers by old EntId 
                for (String entId : entIds) {
                    if (!assetSerialNumsByEntId.containsKey(entId)) {
                        assetSerialNumsByEntId.put(entId, new Set<String>());
                    }
                    assetSerialNumsByEntId.get(entId).addAll(assetSerialNums);
                }
            }
        }
        // Process all OrderItems in the related quotes to update License OrderItems
        Map<Id, Set<String>> entIdToSerialNums = new Map<Id, Set<String>>();
        if (!quoteIds.isEmpty() && !assetSerialNumsByEntId.isEmpty()) {
            for (OrderItem oi : mapOfIdtoOrderItem.values()) {
                String skuType = UtilityClass.getTypeofSKU(oi);
                //Filtering Replaced lines  
                if (skuType == Constants.SKU_TYPE_LICENSE && (oi.Program__c == Constants.PROGRAM_CONVERSION || oi.Program__c == Constants.PROGRAM_UPGRADE)) {
                    Set<String> serialNums = new Set<String>();
                    Set<String> entIds = UtilityClass.getEntIdFromQliJson(oi.SBQQ__QuoteLine__r);
    
                    for (String entId : entIds) {
                        if (assetSerialNumsByEntId.containsKey(entId)) {
                            serialNums.addAll(assetSerialNumsByEntId.get(entId));
                        }
                    }
                    if (!serialNums.isEmpty()) {
                        if (oi.SerialNumber__c != null) {
                           Set<String> allSerials = new Set<String>();
                           allSerials.addAll(new Set<String>(oi.SerialNumber__c.replaceAll('\\s+', '').split(',')));
                           allSerials.addAll(serialNums);
                           oi.SerialNumber__c = String.join(new List<String>(allSerials), ',');
            } else {
                            oi.SerialNumber__c = String.join(new List<String>(serialNums), ',');
                        }
                        orderItemsToUpdate.add(oi);
                    }
                    if (isAspenOrder) {
                        //Prepare data for linked asset creation for aspen use case. 
                        for (Entitlement ent : oi.Entitlements__r) {
                           entIdToSerialNums.put(ent.id, serialNums);
                           newSerialNumsToQuery.addall(serialNums);
                           newEntsById.put(ent.id, ent);
                        }
                    }
                }
            }
        }
    if (!entIdToSerialNums.isEmpty() && !newSerialNumsToQuery.isEmpty()) {
           assetBySerialNumber = fetchAssetsBySerialNumbers(newSerialNumsToQuery);
      for (Id entId : entIdToSerialNums.KeySet()) {
        if (entIdToSerialNums.containskey(entId) && !entIdToSerialNums.get(entId).isEmpty()) {
                for (String serialNum : entIdToSerialNums.get(entId)) {
                    if (assetBySerialNumber.containsKey(serialNum) && assetBySerialNumber.get(serialNum) != null && newEntsById.containskey(entId)) {
                      linkedAstToCreate.add(UtilityClass.createLinkedAsset(newEntsById.get(entId), assetBySerialNumber.get(serialNum).Id, 'Non-Scale'));
                    }
                  }
                }
            }
        }
        // Perform DML to update serial numbers on License OrderItems
        if (!orderItemsToUpdate.isEmpty()) {
            update orderItemsToUpdate;
        }
        // Insert linked Assets for replaced line - aspen order 
        if (!linkedAstToCreate.isEmpty()) {
            insert linkedAstToCreate;
        }
    }
    
    /**
 * @description Creates linked Scale_Entitlement__c asset records for License OrderItems
 * which have been contracted and have serial numbers but were originally non-asset SKUs.
 *
 * @param contractedLicenseOrdItemById  - Map of OrderItem Id to OrderItem for License SKUs.
 */
  public static void createLinkedAssetForLicenseNonAssetToAsset(Map<Id, OrderItem> contractedLicenseOrdItemById) {
    if (contractedLicenseOrdItemById == null || contractedLicenseOrdItemById.isEmpty()) {return;}
      Map<Id, Set<String>> serialNumsByOrderItemId = new Map<Id, Set<String>>();
      Set<String> allSerialNumsToQuery = new Set<String>();
      Map<String, Asset> assetBySerialNum = new Map<String, Asset>();
      List<Scale_Entitlement__c> scaleEntsToCreate = new List<Scale_Entitlement__c>();
  
      // Iterate over License OrderItems
    for (OrderItem oi : contractedLicenseOrdItemById.values()) {
        oi = mapOfIdtoOrderItem.containsKey(oi.Id) ? mapOfIdtoOrderItem.get(oi.Id) : null;
        if (oi == null) {continue;}
        // Only process License SKUs
        String skuType = UtilityClass.getTypeofSKU(oi);
        if (skuType != Constants.SKU_TYPE_LICENSE){continue;}
        

        // Extract and clean serial numbers
        Set<String> assetSerialNumsForOrderItem = new Set<String>();
        if (oi.SerialNumber__c != null) {
            for (String sn : oi.SerialNumber__c.trim().split(',')) {
                sn = sn.trim();
                if (!String.isBlank(sn)) {
                    assetSerialNumsForOrderItem.add(sn);
                    allSerialNumsToQuery.add(sn);
                }
            }
        }

        if (!serialNumsByOrderItemId.containsKey(oi.Id)) {
            serialNumsByOrderItemId.put(oi.Id, new Set<String>());
        }
        serialNumsByOrderItemId.get(oi.Id).addAll(assetSerialNumsForOrderItem);
      }
  
      // Proceed only if serial numbers to query exist
      if (!allSerialNumsToQuery.isEmpty()) {
          assetBySerialNum = fetchAssetsBySerialNumbers(allSerialNumsToQuery);
          
      scaleEntsToCreate = createScaleEntOnLicenses(contractedLicenseOrdItemById.keySet(), serialNumsByOrderItemId, assetBySerialNum);
      }
  
      // DML to update/create linked asset records
      if (!scaleEntsToCreate.isEmpty()) {
          insert scaleEntsToCreate;
      }
  }

    /**
   * @description Queries all Asset records by a given set of serial numbers
   * and returns a map keyed by trimmed SerialNumber.
   *
   * @param serialNumbers Set of serial numbers to query for
   * @return Map<String, Asset> where key = trimmed SerialNumber, value = corresponding Asset record
   */
  private static Map<String, Asset> fetchAssetsBySerialNumbers(Set<String> serialNumbers) {
      Map<String, Asset> assetBySerialNum = new Map<String, Asset>();
    if (serialNumbers == null || serialNumbers.isEmpty()) {return assetBySerialNum;}
      // Query Asset records by provided serial numbers
      List<Asset> allAssets = [
          SELECT Id, SerialNumber
          FROM Asset
          WHERE SerialNumber IN :serialNumbers
      ];
      // Map each valid (non-blank) serial number to its corresponding Asset
      for (Asset asset : allAssets) {
          if (!String.isBlank(asset.SerialNumber)) {
              assetBySerialNum.put(asset.SerialNumber.trim(), asset);
          }
      }
      return assetBySerialNum;
  }

      /**
   * @description Queries Entitlements linked to the given OrderItem IDs and prepares
   * a list of Scale_Entitlement__c records for serial-number-matched Assets.
   *
   * @param licenseOrderItemIds Set of OrderItem IDs to query Entitlements for.
   * @param serialNumsByOrderItemId Map of OrderItemId to Set of serial numbers.
   * @param assetBySerialNum Map of trimmed SerialNumber to Asset record.
   * @return List of Scale_Entitlement__c records to be inserted.
   */
  public static List<Scale_Entitlement__c> createScaleEntOnLicenses(
      Set<Id> licenseOrderItemIds,
      Map<Id, Set<String>> serialNumsByOrderItemId,
      Map<String, Asset> assetBySerialNum
  ) {
      List<Scale_Entitlement__c> scaleEntsToCreate = new List<Scale_Entitlement__c>();

      // Query all Entitlements linked to the provided License OrderItems
      List<Entitlement> entsToLink = [
          SELECT Id, Order_Service_Item__c, ContractLineItemId
          FROM Entitlement
          WHERE Order_Service_Item__c IN :licenseOrderItemIds
      ];

      for (Entitlement ent : entsToLink) {
          Id orderItemId = ent.Order_Service_Item__c;
          if (orderItemId != null && serialNumsByOrderItemId.containsKey(orderItemId)) {
              Set<String> serialNums = serialNumsByOrderItemId.get(orderItemId);

              for (String serialNum : serialNums) {
                  serialNum = serialNum.trim();
                  if (assetBySerialNum.containsKey(serialNum)) {
                      Asset asset = assetBySerialNum.get(serialNum);
                      Scale_Entitlement__c linkedAsset = UtilityClass.createLinkedAsset(ent, asset.Id, 'Non-Scale');
                      scaleEntsToCreate.add(linkedAsset);
                  }
              }
          }
      }

      return scaleEntsToCreate;
  }

  //CSU-7 End

    //CSU-7 End
  /**
   * @author Prashant Kumar
   * @date 17-04-2025
   * @description delete Booking Line Item when order Product is Deleted
   * @param oldMap
   */
  public static void deleteBookingLineItems(Map<ID, OrderItem> oldMap) {
    List<Booking_Line_Item__c> bliListToDelete = [SELECT id, OrderProduct__c FROM Booking_Line_Item__c WHERE OrderProduct__c IN :oldMap.keySet()];
    if (!bliListToDelete.isEmpty()) {
      delete bliListToDelete;
    }
  }
  /**
   * @author Prashant Kumar
   * @date 17-04-2025
   * @description Reset the orderline data
   * @param newOrderItem
   * @param oldOrderItem
   */
  public static void resetValues(OrderItem newOrderItem, OrderItem oldOrderItem) {
    if (oldOrderItem == null) {
      // On Before Insert
      newOrderItem.Has_PSTask__c = false;
      // newOrderItem.ServiceDate = (newOrderItem.is_Amendment__c || newOrderItem.Is_Renewal__c) ? null : newOrderItem.ServiceDate;
    } else if (oldOrderItem != null) {
      // On Before Update
      if (newOrderItem.SBQQ__QuoteLine__c != null && oldOrderItem.Quantity != newOrderItem.Quantity) {
        newOrderItem.SBQQ__OrderedQuantity__c = newOrderItem.Quantity;
      }
      if (newOrderItem.SBQQ__SegmentIndex__c == null) {
                /*
                 * Commented by Siva Kumar to pass PMD voilation of empty if condition
                 * if( (newOrderItem.is_Amendment__c || newOrderItem.Is_Renewal__c ) && newOrderItem.Support_Start_Date__c != null){
          //newOrderItem.ServiceDate = newOrderItem.Support_Start_Date__c;
                }*/
        if (newOrderItem.EndDate != newOrderItem.Support_End_Date__c) {
          newOrderItem.EndDate = newOrderItem.Support_End_Date__c;
        }
      }
    }
  }

  /**
   * @author Prashant Kumar
   * @date 17-05-2025
   * @description populateFieldsOnInsert Method Called in Before Insert to set orderline object
   * @param newOrderItemMap
   * @param oldOrderItemMap
   */
  //Added for PRDOPS22_362
  public static void populateFieldsOnUpdate(Map<Id, OrderItem> newOrderItemMap, Map<Id, OrderItem> oldOrderItemMap) {
    Set<String> setOldCLI = new Set<String>();
    Set<String> rcdmExtensionOldCli = new Set<String>();
    Map<String, Id> rscLinkBasedOnPreviousCli = new Map<String, Id>();
    List<OrderItem> replacementNewOIs = new List<OrderItem>();
    for (orderItem oi : newOrderItemMap.values()) {
      OrderItem oldoi = OldOrderItemMap.get(oi.Id);

      OrderItem queriedOI = mapOfIdtoOrderItem.containsKey(oi.Id) ? mapOfIdtoOrderItem.get(oi.Id) : null;
      //FY25SR-1067
      if (
        oi.Quantity != null &&
        oldoi.Quantity != oi.Quantity &&
        quoteLineItemById != null &&
        quoteLineItemById.get(oi.SBQQ__QuoteLine__c) != null &&
        quoteLineItemById.get(oi.SBQQ__QuoteLine__c).Prepayment_Credit__c != null
      ) {
        oi.Credit_Amount__c = (quoteLineItemById.get(oi.SBQQ__QuoteLine__c).Prepayment_Credit__c / quoteLineItemById.get(oi.SBQQ__QuoteLine__c).SBQQ__Quantity__c) * oi.Quantity;
      }
      if (String.isBlank(oi.Previous_Transaction_Reference__c) && queriedOI != null && String.isNotBlank(queriedOI?.SBQQ__QuoteLine__r?.Replacement_Details__c)) {
        replacementNewOIs.add(oi);
      }

      Boolean compareOldAndNewCLI = (oldoi.Previous_Contract_Line_Items__c != oi.Previous_Contract_Line_Items__c && oldoi.Previous_Contract_Line_Items__c == null);
      String previousCliItems = oi.Previous_Contract_Line_Items__c;
      if ((compareOldAndNewCLI || isRecentlyInserted) && oi.RenewalModel__c != 'License Change') {
        if (previousCliItems != null) {
          List<String> previousCliList = previousCliItems.trim().split(',');
          String previousCli = previousCliList[0];
          previousCli = previousCli.trim().substring(0, 15);
          oi.Previous_Contract_Line__c = previousCli != null ? previousCli : '';
        }
      }

      if (oi.Id != null) {
        //before Update
        if (!mapOfOrders.isEmpty() && mapOfOrders.containskey(oi.OrderId) && mapOfOrders.get(oi.OrderId).Type == REVENUE_TYPE.trim() && oi.Support_Start_Date__c != null) {
          if (mapOfOrders.get(oi.OrderId).Order_Sub_Type__c == constants.ORDER_SUB_TYPE_GC_OFFER) {
            if (oi.Support_Start_Date__c > oi.ServiceDate || oi.ServiceDate == null)
              oi.ServiceDate = oi.Support_Start_Date__c;
            if (oi.Support_End_Date__c > oi.EndDate)
              oi.EndDate = oi.Support_End_Date__c;
          } else {
            oi.ServiceDate = oi.Support_Start_Date__c;
          }
        }
        if (
          mapOfOrders.get(oi.OrderId).RecordType.Name == 'Phantom Order' &&
          oldoi.Support_Start_Date__c != oi.Support_Start_Date__c ||
          oldoi.Support_End_Date__c != oi.Support_End_Date__c &&
          oi.Support_Start_Date__c != null &&
          oi.Previous_Transaction_Reference__c != null &&
          oi.Support_End_Date__c != null && pOrderItemVsOriginalOrder.containsKey(oi.Id)
        ) {
          Id orgOrderItemId = pOrderItemVsOriginalOrder.get(oi.Id);
          OrderItem orgOrderItem = mapOfIdtoOrderItem.get(orgOrderItemId);
          if (orgOrderItem != null && orgOrderItem.Support_Start_Date__c != null && orgOrderItem.Support_End_Date__c != null) {
            Integer noOfDays = orgOrderItem.Support_Start_Date__c.daysBetween(orgOrderItem.Support_End_Date__c);
            Decimal amtPerDay = (orgOrderItem.TotalPrice / noOfDays) / orgOrderItem.Quantity;
            Integer noOfDaysPO = oi.Support_Start_Date__c.daysBetween(oi.Support_End_Date__c);
            oi.Surviving_Amount__c = noOfDaysPO * amtPerDay * oi.Quantity;
          }
        }
         if (
          !mapOfOrders.isEmpty() &&
          mapOfOrders.containsKey(oi.OrderId) &&
          mapOfOrders.get(oi.OrderId).Type == REVENUE_TYPE.trim() &&
          !mapOfIdtoOrderItem.isEmpty() &&
          mapOfIdtoOrderItem.containsKey(oi.Id) &&
          oi.Opportunity_Product__c != null
        ) {
          OpportunityLineItem OLI = mapOfIdtoOrderItem.get(oi.Id)?.Opportunity_Product__r;
          Decimal qtyFactor = (oi.Quantity != null && oi.Quantity != 0.0 && OLI?.Quantity != null && OLI.Quantity != 0) ? oi.Quantity / OLI.Quantity : 1;

          oi.Renewal_Target_Amount_ACV__c = (OLI?.Renewal_Target_Amount__c != null) ? OLI.Renewal_Target_Amount__c * qtyFactor : 0.0;
          oi.RBOB_ACV__c = (OLI?.RBOBACV__c != null) ? OLI.RBOBACV__c * qtyFactor : 0.0;
          oi.PromoDiscTCV__c = (OLI?.PromoDiscTCV__c != null) ? OLI.PromoDiscTCV__c * qtyFactor : 0.0;
          oi.Oppty_Trade_Up_Discount__c = (OLI?.Oppty_Trade_Up_Discount__c != null) ? OLI.Oppty_Trade_Up_Discount__c * qtyFactor : 0.0;
        }
      }
      if (mapOfIdtoOrderItem.containsKey(oi.Id)) {
        OrderItem oiQueried = mapOfIdtoOrderItem.get(oi.Id);
        Map<Id, String> orderProgramByOrderId = new Map<Id, String>();
        if (
          oiQueried?.SBQQ__QuoteLine__r?.SBQQ__Quote__r?.RWD_Deal_Ops_Exception__c == constants.RCDMT_EXT_RWD_DEAL_OPS_EXCEPTION &&
          oiQueried.Previous_Contract_Line_Items__c != null &&
          oiQueried.product2.name == RCDMTransSkuName
        ) {
          rcdmExtensionOldCli.add(oiQueried.Previous_Contract_Line_Items__c);
        }
        Boolean checkIfSuAmendment = (oiQueried.Order?.Order_Sub_Type__c == Constants.ORDER_SUB_TYPE_GC_OFFER && oiQueried.Order.is_Amendment_Order__c);
        if (checkIfSuAmendment) {
          if (isScaleUtilityUpgradeSKU(oiQueried.Product2)) {
            oi.Program__c = Constants.PROGRAM_UPGRADE;
            oi.Sales_Price__c = oi.UnitPrice;
            if (
              !orderProgramByOrderId.containsKey(oi.OrderId) || (orderProgramByOrderId.containsKey(oi.OrderId) && orderProgramByOrderId.get(oi.OrderId) == Constants.PROGRAM_EXPANSION)
            ) {
              orderProgramByOrderId.put(oi.OrderId, Constants.PROGRAM_UPGRADE);
            }
          } else {
            oi.Program__c = Constants.PROGRAM_EXPANSION;
            if (!orderProgramByOrderId.containsKey(oi.OrderId)) {
              orderProgramByOrderId.put(oi.OrderId, Constants.PROGRAM_EXPANSION);
            }
          }
          if (
            oiQueried?.Product2?.Product_Subtype__c != null &&
            constants.SCALE_UTILITY_PRODUCT_SUBTYPES_ONDEMAND.contains(oiQueried?.Product2?.Product_Subtype__c) &&
            oiQueried?.Product2?.License_Category__c != null &&
            oiQueried?.Product2?.License_Category__c == Constants.LICENSE_CATEGORY
          ) {
            oi.Program__c = orderProgramByOrderId.get(oi.OrderId);
          }
        }
        // PRDOPS24-633 - Start
        if (
          oiQueried?.Order?.opportunity.recordtypeId == Constants.OPPORTUNITY_RECORDTYPEID_RENEWAL &&
          oiQueried.Order.Order_Sub_Type__c == Constants.ORDER_SUB_TYPE_GC_OFFER &&
          oi.Program__c != Constants.PROGRAM_MSP_TO_SU_V1_V2
        ) {
          oi.Program__c = Constants.PROGRAM_MSP_TO_SU_V1_V2;
        }
        // PRDOPS24-633 - End

        //ARY-TPHQuantity

        if (oiQueried?.SBQQ__QuoteLine__r?.SBQQ__Quantity__c == oi.Quantity && String.isNotBlank(oiQueried?.SBQQ__QuoteLine__r?.TPH_Quantity__c)) {
          oi.TPH_Quantity__c = oiQueried?.SBQQ__QuoteLine__r?.TPH_Quantity__c;
        } else if (
          oldoi.Quantity != oi.Quantity &&
          String.isNotBlank(oiQueried?.SBQQ__QuoteLine__r?.TPH_Quantity__c) &&
          oiQueried?.SBQQ__QuoteLine__r?.SBQQ__Quantity__c != null &&
          oi.Quantity != null
        ) {
          oi.TPH_Quantity__c = String.valueOf(
            Math.ceil((Integer.valueOf(oiQueried?.SBQQ__QuoteLine__r?.TPH_Quantity__c) / oiQueried?.SBQQ__QuoteLine__r?.SBQQ__Quantity__c) * oi.Quantity)
          );
        }

        //PRDOPS23-198 : Populate subscription term
        if (isSubscriptionProductForPocOrder(oiQueried)) {
          oi.SBQQ__SubscriptionTerm__c = getmonthsbetweenDates(oiQueried.Order.EffectiveDate, oiQueried.Order.POC_Request__r.Most_Recent_End_Date__c);
        }

        // Logic To By Pass Updating Support term For Licence and Last Segment Line for M365 Sku - CSU-339-Prashant
        Boolean isM365SkuCSU = (String.isNotBlank(oiQueried?.Product2?.Bundle_Features__c) && (oiQueried?.Product2?.Bundle_Features__c?.contains('M365')));

        //PRDOPS23-291 PRDOPS24-234
        if (
          oiQueried.SBQQ__QuoteLine__c != null &&
          oiQueried.SBQQ__SubscriptionTerm__c != null &&
          oiQueried.SBQQ__QuoteLine__r.SBQQ__Quote__r.Additional_Month_added__c &&
          oiQueried?.SBQQ__QuoteLine__r?.Special_Program__c != 'Conversion' &&
          oiQueried.Order.type == 'Revenue' &&
          oiQueried?.SBQQ__QuoteLine__r?.Line_Type__c == 'New' &&
          oiQueried.SBQQ__QuoteLine__r?.SBQQ__Product__r?.Family != 'CEM' &&
          oiQueried.SBQQ__QuoteLine__r?.SBQQ__Product__r?.Family != 'ASE' &&
          (String.isBlank(oiQueried.Order.Order_Sub_Type__c) ||
          (oiQueried.Order.Order_Sub_Type__c == Constants.ORDER_SUB_TYPE_GC_OFFER &&
          !isScaleUtilityUpgradeSKU(oiQueried.product2) &&
          !isM365SkuCSU &&
          (oiQueried.SBQQ__SegmentIndex__c == null || oiQueried.SBQQ__SegmentIndex__c == oiQueried.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c)))
        ) {
          oi.Support_Term__c = oiQueried.SBQQ__SubscriptionTerm__c + 1;
        }

        if (
          isGCOfferAmendmentWithAdditionalMonth(oiQueried) &&
          (oiQueried.SBQQ__SegmentIndex__c == (oiQueried.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c - 1) ||
          Constants.SCALE_UTILITY_PRODUCT_SUBTYPES_ONDEMAND.contains(oiQueried?.Product2?.Product_Subtype__c))
        ) {
          if (oiQueried.SBQQ__SegmentIndex__c == (oiQueried.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c - 1) && !isScaleUtilityUpgradeSKU(oiQueried.product2)) {
            oi.Support_Term__c = oiQueried.SBQQ__SubscriptionTerm__c + 1;
          } else if (
            oiQueried.SBQQ__SegmentIndex__c == (oiQueried.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c - 1) && isScaleUtilityUpgradeSKU(oiQueried.product2)
          ) {
            oi.Support_Term__c = 2;
          } else if (Constants.SCALE_UTILITY_PRODUCT_SUBTYPES_ONDEMAND.contains(oiQueried?.Product2?.Product_Subtype__c)) {
            oi.Support_Term__c = null;
          }
          if (!isScaleUtilityUpgradeSKU(oiQueried.product2)) {
            OI.Support_End_Date__c = oiQueried.SBQQ__QuoteLine__r.SBQQ__EffectiveEndDate__c.addMonths(1);
          }
        }

        // PRDOPS22-381 - Prashant
        if (
          mapOfIdtoOrderItem.get(oi.id).SBQQ__OrderedQuantity__c != null &&
          mapOfIdtoOrderItem.get(oi.id).Order.type == 'Revenue' &&
          mapOfIdtoOrderItem.get(oi.id).product2.License_per_Qty__c != null
        ) {
          oi.User_license_count__c = mapOfIdtoOrderItem.get(oi.id).SBQQ__OrderedQuantity__c * mapOfIdtoOrderItem.get(oi.id).product2.License_per_Qty__c;
        }

        //PRDOPS23-685
        if (oiQueried.SBQQ__QuoteLine__c != null && insertTransaction) {
          oi.Trade_Up_SerialNumber__c = oiQueried.SBQQ__QuoteLine__r.Trade_Up_Serial_Number__c;
        }

        // RWD-157 Changes
        if (oiQueried.Order_Status__c != 'Shipped' && oiQueried.Order_Status__c != 'Rejected') {
          if (
            (oiQueried.Order.Is_RWD_Polaris_Quote__c || oiQueried.Product2.ProductCode == 'RS-BT-RCDM-T') &&
            oiQueried.Order.Order_Sub_Type__c != Constants.ORDER_SUB_TYPE_GC_OFFER &&
            oiQueried.Order.Type != Constants.ORDER_TYPE_REVENUE_INTERNAL
          ) {
            if (
              (oiQueried.product2.Product_Level__c == 'Support' &&
              ((oiQueried.product2.Product_Type__c == 'RCDM Support' &&
              (oiQueried.SBQQ__QuoteLine__r?.SBQQ__RequiredBy__r?.SBQQ__Product__r.Product_Level__c == 'LOD Software' ||
              oiQueried?.SBQQ__RequiredBy__r?.product2.Product_Level__c == 'LOD Software')) ||
              (oiQueried.SBQQ__QuoteLine__r?.SBQQ__RequiredBy__r?.SBQQ__RequiredBy__r?.SBQQ__Product__r.Product_Level__c == 'LOD Software' ||
              oiQueried?.SBQQ__RequiredBy__r?.SBQQ__RequiredBy__r?.product2.Product_Level__c == 'LOD Software'))) ||
              ((oiQueried.product2.Product_Level__c == 'Hardware' && (oiQueried.product2.Product_Type__c == 'Add-On Node' || oiQueried.product2.Product_Type__c == 'Hardware')) &&
              (oiQueried.SBQQ__QuoteLine__r?.SBQQ__RequiredBy__r?.SBQQ__Product__r.Product_Level__c == 'LOD Software' ||
              oiQueried?.SBQQ__RequiredBy__r?.product2.Product_Level__c == 'LOD Software')) ||
              (oiQueried.product2.Product_Level__c == 'LOD Software')
            ) {
              OI.Licence_Type__c = 'Life of Device';
            } else if (
              (oiQueried.product2.Product_Level__c == 'Support' &&
              (oiQueried.SBQQ__QuoteLine__r?.SBQQ__RequiredBy__r?.SBQQ__RequiredBy__r?.SBQQ__Product__r.Product_Level__c == 'Hybrid Software' ||
              oiQueried?.SBQQ__RequiredBy__r?.SBQQ__RequiredBy__r?.product2.Product_Level__c == 'Hybrid Software')) ||
              ((oiQueried.product2.Product_Level__c == 'Hardware' && (oiQueried.product2.Product_Type__c == 'Add-On Node' || oiQueried.product2.Product_Type__c == 'Hardware')) &&
              (oiQueried.SBQQ__QuoteLine__r?.SBQQ__RequiredBy__r?.SBQQ__Product__r.Product_Level__c == 'Hybrid Software' ||
              oiQueried?.SBQQ__RequiredBy__r?.product2.Product_Level__c == 'Hybrid Software')) ||
              (oiQueried.product2.Product_Level__c == 'Hybrid Software')
            ) {
              OI.Licence_Type__c = 'Subscription';
            } else {
              if (oiQueried.Product2.License_Type__c != null) {
                OI.Licence_Type__c = oiQueried.Product2.License_Type__c;
              } else if (oiQueried.SBQQ__QuoteLine__r.Licensing_Model__c != null) {
                OI.Licence_Type__c = oiQueried.SBQQ__QuoteLine__r.Licensing_Model__c;
              }
            }
            // Added for PRDOPS23-524

            if (
              oiQueried.Product2.Product_Level__c == 'LOD Software' ||
              oiQueried.Product2.ProductCode == 'RS-BT-RCDM-T' || // Added for PRDOPS23-847
              (oiQueried.Product2.Product_Level__c == 'OnPrem' &&
              (oiQueried.Product2.Product_Type__c == 'Enterprise Edition' ||
              oiQueried.Product2.Product_Type__c == 'Business Edition' ||
              oiQueried.Product2.Product_Type__c == 'Foundation Edition' || oiQueried.Product2.Product_Type__c == 'PMC') &&
              oiQueried.Product2.Product_Subtype__c == null)
            ) {
              OI.Cluster_Order_Type__c = 'LOD';
            } else if (
              (oiQueried.Product2.Product_Level__c == 'Standalone Software Addon' && oiQueried.Product2.Product_Type__c == 'Cloud Edition') ||
              (oiQueried.Product2.Product_Level__c == 'SaaS Software Addon' && (Constants.IDENTITY_EDGE_PRODUCT_TYPES.contains(oiQueried.Product2.Product_Type__c) || oiQueried.Product2.Edition__c == Constants.COMPLETE_UPGRADE_EDITION)) ||//ITNPI-3211
              (oiQueried.Product2.Product_Type__c == 'RZTDP' && oiQueried.Order.Order_Sub_Type__c != 'Renewal') ||
              oiQueried.Product2.Product_Level__c == 'Hybrid Software' ||
              oiQueried.Product2.Product_Type__c == 'UCL' ||
              oiQueried.Product2.Product_Type__c == 'EDGE'
            ) {
              OI.Cluster_Order_Type__c = 'Subscription';
            } else {
              OI.Cluster_Order_Type__c = 'None';
            }

            //end PRDOPS23-524
          } else {
            if (oiQueried.SBQQ__QuoteLine__r.Licensing_Model__c != null && oiQueried.Order.Type != Constants.ORDER_TYPE_REVENUE_INTERNAL) {
              OI.Licence_Type__c = oiQueried.SBQQ__QuoteLine__r.Licensing_Model__c;
            }
            //Added PRDOPS23-524
            if (
              (String.isBlank(oiQueried.Product2.Product_Level__c) && oiQueried.Product2.Product_Type__c == 'EDGE') ||
              (String.isBlank(oiQueried.Product2.Product_Level__c) &&
              oiQueried.Product2.License_Type__c == 'Perpetual' && oiQueried.Product2.Product_Type__c == 'RCDM' && oiQueried.Order.Order_Sub_Type__c != 'Renewal') ||
              (String.isBlank(oiQueried.Product2.Product_Level__c) &&
              oiQueried.Order.Order_Sub_Type__c != 'Renewal' &&
              (oiQueried.Product2.Product_Subtype__c == 'GO' ||
              oiQueried.Product2.Product_Type__c == 'Business Edition' ||
              oiQueried.Product2.Product_Type__c == 'Complete Edition' ||
              oiQueried.Product2.Product_Type__c == 'Complete Edition Elite' ||
              oiQueried.Product2.Product_Type__c == 'Complete Edition Pro' ||
              oiQueried.Product2.Product_Type__c == 'Enterprise Edition' ||
              oiQueried.Product2.Product_Type__c == 'Foundation Edition'))
            ) {
              OI.Cluster_Order_Type__c = 'Legacy';
            } else if (oiQueried.Product2.Product_Type__c == 'UCL' 
              || oiQueried.Product2.Product_Type__c == 'Cloud Edition'
              || (oiQueried.Order.Order_Sub_Type__c == Constants.ORDER_SUB_TYPE_GC_OFFER && oiQueried.Product2.Product_Level__c == constants.RSC_HYBRID_PRODUCT_LEVEL)
              ) {
              OI.Cluster_Order_Type__c = 'Subscription';
            } else {
              OI.Cluster_Order_Type__c = 'None';
            }
            //end PRDOPS23-524
          }
        }
      }
    }

    if (!replacementNewOIs.isEmpty()) {
      getPrevTransRefJson(replacementNewOIs);
    }

    // Linking RSC and RCDM-T when linkage is not there
    // Set map based on previous old CLI Stamped on order product for RCDM-T Manual Extension- PRDOPS25-496
    if (!rcdmExtensionOldCli.isempty()) {
      for (Quote_and_Order_Staging__c quoteAndStagingOrderObj : [
        SELECT Id, QuoteLine_Id__c, Contract_Line_Item__c, RSC_OrderItem__c
        FROM Quote_and_Order_Staging__c
        WHERE Contract_Line_Item__c IN :rcdmExtensionOldCli
      ]) {
        rscLinkBasedOnPreviousCli.put(quoteAndStagingOrderObj.Contract_Line_Item__c, quoteAndStagingOrderObj.RSC_OrderItem__c);
      }
    }
    // Assigning Required to RCDM-T Extension Line
    for (orderItem oi : newOrderItemMap.values()) {
      if (
        !rscLinkBasedOnPreviousCli.isempty() &&
        rscLinkBasedOnPreviousCli.containskey(oi.Previous_Contract_Line_Items__c) &&
        mapOfIdtoOrderItem.containsKey(oi.Id) &&
        mapOfIdtoOrderItem.get(oi.Id).product2.name == RCDMTransSkuName
      ) {
        oi.SBQQ__RequiredBy__c = rscLinkBasedOnPreviousCli.get(oi.Previous_Contract_Line_Items__c);
      }
    }
  }
  /***********************************************************
   * Description : Reparenting for netapp orders(PRDOPS23-46)
   ***********************************************************/
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description Reparenting for netapp orders(PRDOPS23-46)
   * @param newMap
   */
  public static void populateValuesOnCreatedOLI(Map<Id, OrderItem> newMap) {
    Map<Id, OrderItem> mapOforderItm = new Map<Id, OrderItem>(
      [
        SELECT
          id,
          order.opportunityId,
          Previous_Contract_Line_Items__c,
          Product2.name,
          Program__c,
          Order.Bill_To_Name__c,
          SBQQ__QuoteLine__r.SBQQ__Quote__r.Opportunity_Program__c,
          Order.Sell_to_Partner__c,
          SBQQ__QuoteLine__r.SBQQ__Quote__r.RSC_G_Eligible__c,
          Order.Opportunity.Distributor_Lookup__c,
          SBQQ__RequiredBy__c,
          Order.SBQQ__Quote__c,
          SBQQ__QuoteLine__c,
          OrderId,
          Quantity,
          product2.Product_Type__c,
          product2.Product_Level__c,
          Opportunity_Product__c
        FROM orderItem
        WHERE Id IN :newMap.keyset()
      ]
    );
    Map<Id, OrderItem> mapOIToUpdate = new Map<Id, OrderItem>();
    mapOIToUpdate.putAll(getOldContractLineItem(newMap.values()));
    Map<id, Map<id, id>> qliOrdIdItemMap = new Map<id, Map<id, id>>();
    Map<String, Order> mapOfOrdNumtoOrd = new Map<string, Order>();
    Sfdc_Disti_Mapping__mdt objDistiMap = new Sfdc_Disti_Mapping__mdt();

    for (OrderItem newOrdItm : mapOforderItm.values()) {
      if (newOrdItm.SBQQ__QuoteLine__c != null && qliOppLIMap.containsKey(newOrdItm.SBQQ__QuoteLine__c)) {
        if (mapOIToUpdate.containsKey(newOrdItm.id)) {
          mapOIToUpdate.get(newOrdItm.id).Opportunity_Product__c = qliOppLIMap.get(newOrdItm.SBQQ__QuoteLine__c).Id;
        } else {
          mapOIToUpdate.put(newOrdItm.id, new OrderItem(id = newOrdItm.id, Opportunity_Product__c = qliOppLIMap.get(newOrdItm.SBQQ__QuoteLine__c).Id));
        }
      } else {
        if (!settingOppLineMap.isempty()) {
          String key = newOrdItm.order?.opportunityId + '-' + newOrdItm.Product2.name + '-' + newOrdItm.Quantity;
          if (mapOIToUpdate.containskey(newOrdItm.id)) {
            mapOIToUpdate.get(newOrdItm.id).Opportunity_Product__c = settingOppLineMap.containskey(key) ? settingOppLineMap.get(key) : null;
          } else {
            mapOIToUpdate.put(newOrdItm.id, new OrderItem(id = newOrdItm.id, Opportunity_Product__c = settingOppLineMap.containskey(key) ? settingOppLineMap.get(key) : null));
          }
        }
      }
      if (
        newOrdItm.SBQQ__QuoteLine__c != null &&
        (newOrdItm.SBQQ__QuoteLine__r?.SBQQ__Quote__r?.Opportunity_Program__c != null &&
        newOrdItm.SBQQ__QuoteLine__r.SBQQ__Quote__r.Opportunity_Program__c.containsIgnoreCase('Conversion') &&
        (newOrdItm.Program__c == 'Refresh' || String.isBlank(newOrdItm.Program__c))) ||
        (newOrdItm?.SBQQ__QuoteLine__r?.SBQQ__Quote__c != null && newOrdItm?.SBQQ__QuoteLine__r?.SBQQ__Quote__r?.RSC_G_Eligible__c) ||
        (newOrdItm.Order.Sell_to_Partner__c != null && Label.NetApp_Account_Ids.contains(string.valueof(newOrdItm.Order.Sell_to_Partner__c)) && newOrdItm.Order.Bill_To_Name__c == newOrdItm.Order.Sell_to_Partner__c)
      ) {
        if (qliOrdIdItemMap.containsKey(newOrdItm.SBQQ__QuoteLine__c)) {
          qliOrdIdItemMap.get(newOrdItm.SBQQ__QuoteLine__c).put(newOrdItm.OrderId, newOrdItm.id);
        } else {
          qliOrdIdItemMap.put(newOrdItm.SBQQ__QuoteLine__c, new Map<id, id>{ newOrdItm.OrderId => newOrdItm.id });
        }
      }
    }
    if (!mapOfOrders.isEmpty()) {
      for (Order ord : mapOfOrders.values()) {
        mapOfOrdNumtoOrd.put(ord.ordernumber, ord);
      }
    }
    if (!qliOrdIdItemMap.isEmpty()) {
      //FY25SR-1067
      // Map<ID, SBQQ__QuoteLine__c> quoteLineMap = new Map<ID, SBQQ__QuoteLine__c>([Select ID, SBQQ__Quote__r.Opportunity_Program__c, SBQQ__Quote__r.SBQQ__Opportunity2__r.Sell_to_Partner__c, SBQQ__RequiredBy__c from SBQQ__QuoteLine__c where ID IN: qliOrdIdItemMap.keySet()]);
      for (OrderItem newOrdItm : mapOforderItm.values()) {
        if (newOrdItm.Order.Opportunity.Distributor_Lookup__c != null && OrderInsertHelper.getDistributorMetadata(newOrdItm.Order.Opportunity.Distributor_Lookup__c) != null) {
          objDistiMap = OrderInsertHelper.getDistributorMetadata(newOrdItm.Order.Opportunity.Distributor_Lookup__c);
        }
        SBQQ__QuoteLine__c qli = quoteLineItemById.containskey(newOrdItm.SBQQ__QuoteLine__c) ? quoteLineItemById.get(newOrdItm.SBQQ__QuoteLine__c) : null; //FY25SR-1067
        //if(newOrdItm.SBQQ__RequiredBy__c == null && qli != null && qli.SBQQ__Quote__r.SBQQ__Opportunity2__r.Sell_to_Partner__c != null && qli.SBQQ__RequiredBy__c != null && qliOrdIdItemMap.containsKey(qli.SBQQ__RequiredBy__c)){//FCUS 42,46
        if (
          newOrdItm.SBQQ__RequiredBy__c == null && qli != null && qli.SBQQ__RequiredBy__c != null && qliOrdIdItemMap.containsKey(qli.SBQQ__RequiredBy__c) &&
          (newOrdItm.Order.Sell_to_Partner__c != null && Label.NetApp_Account_Ids.contains(string.valueof(newOrdItm.Order.Sell_to_Partner__c)) && newOrdItm.Order.Bill_To_Name__c == newOrdItm.Order.Sell_to_Partner__c) ||
          (String.isNotBlank(qli?.SBQQ__Quote__r?.Opportunity_Program__c) &&
          qli.SBQQ__Quote__r.Opportunity_Program__c.containsIgnoreCase('Conversion') &&
          (String.isBlank(objDistiMap.Po_Disti_Type__c) || (objDistiMap.Po_Disti_Type__c != null && objDistiMap.Disable_Distii__c)))
        ) {
          //FCUS 42,46

          Id parentId;
          if (
            qliOrdIdItemMap.containsKey(qli.SBQQ__RequiredBy__c) &&
            qliOrdIdItemMap.get(qli.SBQQ__RequiredBy__c).containsKey(newOrdItm.OrderId) &&
            qliOrdIdItemMap.get(qli.SBQQ__RequiredBy__c).get(newOrdItm.OrderId) != null
          ) {
            parentId = qliOrdIdItemMap.get(qli.SBQQ__RequiredBy__c).get(newOrdItm.OrderId);
          } else {
            if (
              (newOrdItm.Product2.Product_Level__c == 'Hardware' && (newOrdItm.Product2.Product_Type__c == 'Add-On Node' || newOrdItm.Product2.Product_Type__c == 'Hardware')) &&
              mapOfOrders.get(newOrdItm.orderid) != null &&
              mapOfOrders.get(newOrdItm.OrderId).Related_Order__c != null &&
              !mapOfOrders.get(newOrdItm.OrderId).Related_Order__c.contains(',')
            ) {
              parentId = qliOrdIdItemMap.get(qli.SBQQ__RequiredBy__c).get(mapOfOrdNumtoOrd.get(mapOfOrders.get(newOrdItm.orderId).Related_Order__c).id);
            } else if (
              (newOrdItm.Product2.Product_Type__c == 'HW Support' &&
              newOrdItm.Product2.Product_Level__c == 'Support') &&
              mapOfOrders.get(newOrdItm.orderid) != null &&
              mapOfOrders.get(newOrdItm.OrderId).HW_Order__c != null &&
              !mapOfOrders.get(newOrdItm.OrderId).HW_Order__c.contains(',')
            ) {
              parentId = qliOrdIdItemMap.get(qli.SBQQ__RequiredBy__c).get(mapOfOrdNumtoOrd.get(mapOfOrders.get(newOrdItm.orderId).HW_Order__c).id);
            } else {
              if (qliOrdIdItemMap.containskey(qli.SBQQ__RequiredBy__c))
                parentId = qliOrdIdItemMap.get(qli.SBQQ__RequiredBy__c).values()[0];
            }
          }
          if (parentId != null) {
            if (mapOIToUpdate.containsKey(newOrdItm.id) && mapOIToUpdate.get(newOrdItm.id) != null) {
              mapOIToUpdate.get(newOrdItm.id).SBQQ__RequiredBy__c = parentId;
            } else {
              mapOIToUpdate.put(newOrdItm.id, new OrderItem(id = newOrdItm.id, SBQQ__RequiredBy__c = parentId));
            }
          }
        }
      }
    }
    if (!mapOIToUpdate.values().isEmpty() && mapOIToUpdate.size() > 0) {
      update mapOIToUpdate.values();
    }
  }
  /**
   * @author Prashant Kumar
   * @date 17-04-2025
   * @description This method will populate EDI line Number and BuyersPartNum on Orderlines from POItems
   * @param newOrderItems
   * @param quoteLineIds
   */
  //This mthod will populate EDI line Number and BuyersPartNum on Orderlines from POItems
  public static void populateEDILInes(List<OrderItem> newOrderItems, Set<Id> quoteLineIds) {
    //FY25SR-1067
    quoteLineIds.remove(null);
    if (quoteLineItemById != null && !quoteLineItemById.values().isEmpty() && (!quoteLineIds.isEmpty() || !quoteIds.isEmpty())) {
      Map<Id, PO_Item_Stage__c> poItemsMap = new Map<Id, PO_Item_Stage__c>(
        [
          SELECT Id, Name, Quote_Line__c, EDI_Line_Number__c, Buyer_Part_Number__c
          FROM PO_Item_Stage__c
          WHERE Quote_Line__c IN :quoteLineIds AND Stage_po__r.Expected_number_of_POs__c = 1
        ]
      );
      Map<Id, Map<String, String>> orderDataMap = new Map<Id, Map<String, String>>();
      for (PO_Item_Stage__c poitemStage : poItemsMap.values()) {
        if (!orderDataMap.containsKey(poitemStage.Quote_Line__c)) {
          orderDataMap.put(
            poitemStage.Quote_Line__c,
            new Map<String, String>{ 'EDI_LINE_NUM' => poitemStage.EDI_Line_Number__c, 'BUYER_PART_NUM' => poitemStage.Buyer_Part_Number__c }
          );
        } else {
          orderDataMap.get(poitemStage.Quote_Line__c).put('EDI_LINE_NUM', orderDataMap.get(poitemStage.Quote_Line__c).get('EDI_LINE_NUM') + ';' + poitemStage.EDI_Line_Number__c);
        }
      }
      for (OrderItem oi : newOrderItems) {
        String uniqueOldCLI = null;
        Boolean checkIfGCWithRenewalOppty = (mapOfOrders.get(oi.OrderId).Order_Sub_Type__c == constants.ORDER_SUB_TYPE_GC_OFFER &&
        mapOfOrders.get(oi.OrderId).Opportunity.RecordtypeId == Constants.OPPORTUNITY_RECORDTYPEID_RENEWAL);

        // Setting the Segment Label Based On QuoteLine
        //    for OrderItem for CSU-714-Prashant
        //
        if (!quoteLineItemById.isEmpty() && oi.SBQQ__QuoteLine__c != null && quoteLineItemById.containsKey(oi.SBQQ__QuoteLine__c)) {
          SBQQ__QuoteLine__c qli = quoteLineItemById.get(oi.SBQQ__QuoteLine__c);
          if (qli.Prepayment_Credit__c != null) {
            // FY25SR-1067
            oi.Credit_Amount__c = (qli.Prepayment_Credit__c / qli.SBQQ__Quantity__c) * oi.Quantity;
          }
          if (qli.sbqq__OrderProducts__r.size() > 0) {
            //FY25SR-1361
            if (oi.Previous_Transaction_Reference__c == null) {
              oi.Previous_Transaction_Reference__c = qli.sbqq__OrderProducts__r[0].Previous_Transaction_Reference__c;
            }
            if (oi.Replacement_Type__c == null) {
              oi.Replacement_Type__c = qli.sbqq__OrderProducts__r[0].Replacement_Type__c;
            }
          }
          if (mapOfOrders?.get(oi.OrderId)?.Order_Sub_Type__c == constants.ORDER_SUB_TYPE_GC_OFFER && !mapOfOrders.isEmpty()) {
            if (qli.SBQQ__SegmentLabel__c != null && qli != null) {
              oi.Segment_Label__c = qli.SBQQ__SegmentLabel__c;
            }
          }
          if (qli.SBQQ__Product__r?.Upgrade_Path__c != null && qli.Account_s_Entitlement__c != null) {
            oi.Entitlement_Id__c = String.valueOf(qli.Account_s_Entitlement__c);
          }
        }

        if (oi.Id == null) {
          //before Insert

          oi.ServiceDate = !mapOfOrders.isEmpty() &&
            mapOfOrders.containskey(oi.OrderId) &&
            !checkIfGCWithRenewalOppty &&
            mapOfOrders.get(oi.OrderId).Type == REVENUE_TYPE.trim()
            ? null
            : oi.ServiceDate;
        }

        /**
         * this block sets the standard start and end dates (ServiceDate and EndDate) on the order Items
         * as this will be used later to set the Order's Effective Date because by default ServiceDate and Enddate on the order items starts with today's date
         * and when we were setting the Support End Date as the Effective date of the order then errors were encounetered like
         * 1. Effective Date can't be later than the Start Date of the products
         * 2. End Date can't be earlier than the start date
         */
        if (checkIfGCWithRenewalOppty && quoteLineItemById.containsKey(oi.SBQQ__QuoteLine__c)) {
          SBQQ__QuoteLine__c objQLI = quoteLineItemById.get(oi.SBQQ__QuoteLine__c);
          oi.ServiceDate = objQLI.SBQQ__StartDate__c;
          oi.EndDate = objQLI.SBQQ__EndDate__c;
        }

        if (orderDataMap.containsKey(oi.SBQQ__QuoteLine__c)) {
          oi.EDI_Line_Number__c = orderDataMap.get(oi.SBQQ__QuoteLine__c).get('EDI_LINE_NUM');
          oi.Buyer_Part_Number__c = orderDataMap.get(oi.SBQQ__QuoteLine__c).get('BUYER_PART_NUM');
        }
        if (quoteLineItemById.containsKey(oi.SBQQ__QuoteLine__c)) {
          SBQQ__QuoteLine__c objQLI = quoteLineItemById.get(oi.SBQQ__QuoteLine__c);
          Boolean isRSCOrGO = (String.isNotBlank(objQLI.SBQQ__Quote__r?.Manual_Fulfillment_Quote__c) &&
          (objQLI.SBQQ__Quote__r?.Manual_Fulfillment_Quote__c.contains(Constants.MANUAL_FULFILL_Quote_RSCP_CONVERSION) ||
          objQLI.SBQQ__Quote__r?.Manual_Fulfillment_Quote__c.contains(Constants.MANUAL_FULFILL_Quote_GO_RSCP_CONVERSION)));

          if (oi.Previous_Contract_Line_Items__c == null) {
            if (String.isNotBlank(objQLI.Arroyo_Subsumed_Old_Contract_Line_Items__c)) {
              List<String> duplicateRemoveOldCLI = new List<String>(new Set<String>(objQLI.Arroyo_Subsumed_Old_Contract_Line_Items__c.split(',')));
              uniqueOldCLI = String.join(duplicateRemoveOldCLI, ',').replaceAll('\\s+', '');
            }
            if (objQLI.SBQQ__Quote__r.SBQQ__Type__c == 'Renewal') {
              oi.Previous_Contract_Line_Items__c = uniqueOldCLI != null ? uniqueOldCLI : objQLI.SBQQSC__RenewedContractLine__c != null ? objQLI.SBQQSC__RenewedContractLine__c : oi.Previous_Contract_Line_Items__c;
            } else if (objQLI.SBQQ__Quote__r.SBQQ__Type__c == 'Renewal+Expansion') {
              oi.Previous_Contract_Line_Items__c = uniqueOldCLI;
            } else if (isRSCOrGO && uniqueOldCLI != null) {
              oi.Previous_Contract_Line_Items__c = uniqueOldCLI;
            }
          }
          //SKU-52

          oi.Program__c = objQLI.Special_Program__c != null ? objQLI.Special_Program__c : oi.Program__c;
          oi.Upgraded_From__c = objQLI.Arroyo_Subscribed_Asset_Name__c;
          if (
            objQLI != null &&
            ((String.isNotBlank(oi.Program__c) && (CONSTANTS.REPLACEMENT_PROGRAMS.contains(oi.Program__c) || oi.Program__c == CONSTANTS.PROGRAM_REFRESH)) ||
            Oi.Line_Type__c == Constants.ORDER_TYPE_RENEWAL)
          ) {
            Set<String> serialNumbers = new Set<String>();
            Map<Id, Set<String>> entIdToSerialNums = UtilityClass.getAssetSerialNumbersFromQliJson(objQLI);
            if (entIdToSerialNums != null) {
                  for (Set<String> serialNum : entIdToSerialNums.values()) {
                      serialNumbers.addAll(serialNum);
                  }
              }
            if (serialNumbers != null && !serialNumbers.isEmpty()) {
              oi.Upgraded_From__c = String.join(new List<String>(serialNumbers), ','); //FY25SR-1320
            }
          }
          oi.Actual_Sales_Price__c = objQLI.SBQQ__ListPrice__c;
          oi.Sales_Price__c = objQLI.SBQQ__CustomerPrice__c;
          //PRDOPS24 - 226
          oi.TPH_Drive_Size__c = objQLI.TPH_Drive_Size__c;
          oi.TPH_Models_Gen__c = objQLI.TPH_Models_Gen__c;
          oi.TPH_OEM__c = objQLI.TPH_OEM__c;
          if (objQLI?.SBQQ__Quantity__c == oi.Quantity && String.isNotBlank(objQLI.TPH_Quantity__c)) {
            oi.TPH_Quantity__c = objQLI?.TPH_Quantity__c;
          } else if (String.isNotBlank(objQLI.TPH_Quantity__c) && objQLI.SBQQ__Quantity__c != null && oi.Quantity != null) {
            oi.TPH_Quantity__c = String.valueOf(Math.ceil((Integer.valueOf(objQLI.TPH_Quantity__c) / objQLI.SBQQ__Quantity__c) * oi.Quantity));
          } else {
            if (objQLI.TPH_Quantity__c != null) {
              oi.TPH_Quantity__c = objQLI.TPH_Quantity__c;
            }
          }
        }
      }
    }
  }
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description This Method will return old ContractLine Item Based on OrderItem Ids.
   * @param newOrderItems
   * @return List<orderItem>
   */
  private static List<orderItem> getOldContractLineItem(List<OrderItem> newOrderItems) {
    Set<String> lstOfAssetIds = new Set<String>();
    Map<String, Entitlement> mapOfAssetToEnt = new Map<String, Entitlement>();
    List<OrderItem> lstOIToUpdate = new List<OrderItem>();
    set<id> updatedOIId = new Set<id>();
    for (OrderItem OI : newOrderItems) {
      if (mapOfIdtoOrderItem.get(OI.id) != null) {
        OrderItem tempOI = mapOfIdtoOrderItem.get(OI.id);
        if (
          (((tempOI.Product2.Product_Level__c == 'Hybrid Software' ||
          (tempOI.Product2.Product_Level__c == 'OnPrem' && (tempOI.Product2.Product_Type__c == 'Foundation Edition' || tempOI.Product2.Product_Type__c == 'Business Edition' || tempOI.Product2.Product_Type__c == 'Enterprise Edition') && tempOI?.Product2?.Product_Subtype__c == null) ||
          tempOI.Product2.Product_Level__c == 'LOD Software') && tempOI.Product2.Product_Subtype__c != 'RCDM') ||
          (tempOI.Product2.Product_Type__c == 'HW Support' &&
          tempOI.Product2.Product_Level__c == 'Support')) &&
          tempOI.SBQQ__QuoteLine__c != null &&
          tempOI.SBQQ__QuoteLine__r.SBQQ__Quote__c != null &&
          tempOI.SBQQ__QuoteLine__r.Arroyo_Subscribed_Asset_Name__c != null &&
          (tempOI.SBQQ__QuoteLine__r.Special_Program__c == 'Conversion' ||
          tempOI.SBQQ__QuoteLine__r.Special_Program__c == 'Refresh') &&
          tempOI.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c == 'Quote' &&
          tempOI.Previous_Contract_Line_Items__c == null
        ) {
          lstOfAssetIds.addall((tempOI.SBQQ__QuoteLine__r.Arroyo_Subscribed_Asset_Name__c.replaceAll('\\s+', '').split(',')));
        }
      }
    }
    if (mapOfIdToEnt != null && mapOfIdToEnt.size() > 0) {
      for (Entitlement ent : mapOfIdToEnt.values()) {
        if (ent.Asset.serial_number__c != null && lstOfAssetIds.contains(ent.Asset.serial_number__c)) {
          String key;
          if (ent.Product__r.Product_Type__c == 'RCDM Support' && ent.Product__r.Approval_Category__c == 'RCDM Support') {
            key = ent.Asset.serial_number__c + ':' + 'License';
            if (!mapOfAssetToEnt.containsKey(key)) {
              mapOfAssetToEnt.put(key, ent);
            }
          } else if (ent.Product__r.Product_Type__c == 'HW Support' && ent.Product__r.Approval_Category__c == 'Hardware Support') {
            key = ent.Asset.serial_number__c + ':' + 'Support';
            if (!mapOfAssetToEnt.containsKey(key)) {
              mapOfAssetToEnt.put(key, ent);
            }
          } else if (ent.Product__r.Product_Type__c == 'HW Support' && ent.Product__r.Approval_Category__c == 'RCDM Support') {
            List<String> tempStr = new List<String>{ 'License', 'Support' };
            for (String str : tempStr) {
              key = ent.Asset.serial_number__c + ':' + str;
              if (!mapOfAssetToEnt.containsKey(key)) {
                mapOfAssetToEnt.put(key, ent);
              }
            }
          } else if (ent.Product__r.Bundle_Features__c != null) {
            for (string str : ent.Product__r.Bundle_Features__c.split(';')) {
              if (str.contains('RCDM')) {
                key = ent.Asset.serial_number__c + ':' + 'License';
                if (!mapOfAssetToEnt.containsKey(key)) {
                  mapOfAssetToEnt.put(key, ent);
                }
              } else if (str.equals('Hardware Premium Support')) {
                key = ent.Asset.serial_number__c + ':' + 'Support';
                if (!mapOfAssetToEnt.containsKey(key)) {
                  mapOfAssetToEnt.put(key, ent);
                }
              }
            }
          }
        }
      }
    }

    if (mapOfAssetToEnt.size() > 0) {
      for (OrderItem OI : newOrderItems) {
        OrderItem tempOI = mapOfIdtoOrderItem.get(OI.id);
        if (tempOI.SBQQ__QuoteLine__r.Arroyo_Subscribed_Asset_Name__c != null) {
          for (String astStr : (tempOI.SBQQ__QuoteLine__r.Arroyo_Subscribed_Asset_Name__c.replaceAll('\\s+', '').split(','))) {
            if (
              (tempOI.Product2.Product_Level__c == 'Hybrid Software' ||
              (tempOI.Product2.Product_Level__c == 'OnPrem' && (tempOI.Product2.Product_Type__c == 'Foundation Edition' || tempOI.Product2.Product_Type__c == 'Business Edition' || tempOI.Product2.Product_Type__c == 'Enterprise Edition') && tempOI?.Product2?.Product_Subtype__c == null) ||
              tempOI.Product2.Product_Level__c == 'LOD Software') && tempOI.Product2.Product_Subtype__c != 'RCDM'
            ) {
              if (mapOfAssetToEnt.containsKey(astStr + ':' + 'License') && mapOfAssetToEnt.get(astStr + ':' + 'License') != null) {
                tempOI.Previous_Contract_Line_Items__c = tempOI.Previous_Contract_Line_Items__c != null ? tempOI.Previous_Contract_Line_Items__c + ',' + mapOfAssetToEnt.get(astStr + ':' + 'License').ContractLineItemId
                  : mapOfAssetToEnt.get(astStr + ':' + 'License').ContractLineItemId;
              }
            } else if (tempOI.Product2.Product_Type__c == 'HW Support' && tempOI.Product2.Product_Level__c == 'Support') {
              if (mapOfAssetToEnt.containsKey(astStr + ':' + 'Support') && mapOfAssetToEnt.get(astStr + ':' + 'Support') != null) {
                tempOI.Previous_Contract_Line_Items__c = tempOI.Previous_Contract_Line_Items__c != null ? tempOI.Previous_Contract_Line_Items__c + ',' + mapOfAssetToEnt.get(astStr + ':' + 'Support').ContractLineItemId
                  : mapOfAssetToEnt.get(astStr + ':' + 'Support').ContractLineItemId;
              }
            }
            if (!updatedOIId.contains(tempOI.id)) {
              lstOIToUpdate.add(tempOI);
              updatedOIId.add(tempOI.id);
            }
          }
        }
      }
    }
    return lstOIToUpdate;
  }
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description syncAssets Method is used to perform Actions when Cli Is Created and linked with orderitem and then assets are updated
   * @param newOrderItems
   * @param oldOrderMap
   */
  public static void syncAssets(List<OrderItem> newOrderItems, Map<ID, OrderItem> oldOrderMap) {
    Set<Id> ContractLineItemIds = new Set<Id>();
    Set<String> serialNumbers = new Set<String>();
    Map<Id, ContractLineItem> mapItems = new Map<Id, ContractLineItem>();
    Map<String, Asset> mapAssets = new Map<String, Asset>();
    Map<Id, Entitlement> toUpdate = new Map<Id, Entitlement>();
    Map<Id, Date> assetStartDateMap = new Map<Id, Date>(); //EL-244
    Map<Id, Date> assetEndDateMap = new Map<Id, Date>(); //EL-244
    Map<Id, ContractLineItem> toUpdateContractLineItems = new Map<Id, ContractLineItem>();

    Set<Id> orderIds = new Set<Id>();
    Set<Id> orderItemsWithCLs = new Set<Id>();
    Set<String> spareSNs = new Set<String>();

    for (OrderItem oi : newOrderItems) {
      OrderItem oiOld = oldOrderMap.get(oi.Id);

      if (oi.SBQQSC__ContractLineItem__c != oiOld.SBQQSC__ContractLineItem__c || (String.isNotBlank(oi.SerialNumber__c) && oi.SerialNumber__c != oiOld.SerialNumber__c)) {
        ContractLineItemIds.add(oi.SBQQSC__ContractLineItem__c);
        orderItemsWithCLs.add(oi.Id);
        orderIds.add(oi.OrderId);
      }
    }
    ContractLineItemIds.remove(null);

    Map<ID, List<Entitlement>> cliEntitlementMap = new Map<ID, List<Entitlement>>();
    System.debug(LoggingLevel.ERROR, '---ContractLineItemIds--' + json.serialize(ContractLineItemIds));
    Map<String, String> mapLocationByOrderItemId = new Map<String, String>();

    if (!orderIds.isEmpty()) {
      List<ContractLineItem> items = [
        SELECT
          Id,
          Quantity,
          SBQQSC__OrderProduct__c,
          SBQQSC__OrderProduct__r.Id,
          SBQQSC__OrderProduct__r.Quantity,
          SBQQSC__OrderProduct__r.Product2.SBQQSC__EntitlementConversion__c,
          SBQQSC__OrderProduct__r.Product2.Entitlement_Conversion_Non_CPQ__c,
          SBQQSC__OrderProduct__r.SerialNumber__c,
          SBQQSC__RequiredByProduct__c,
          SBQQSC__RequiredByProduct__r.Asset_Upgrade_Product__c,
          SBQQSC__OrderProduct__r.Support_End_Date__c,
          SBQQSC__OrderProduct__r.Support_Start_Date__c,
          SBQQSC__OrderProduct__r.Order.Order_Sub_Type__c,
          SBQQSC__OrderProduct__r.OrderItemNumber,
          SBQQSC__OrderProduct__r.SBQQ__RequiredBy__c,
          SBQQSC__OrderProduct__r.SBQQ__RequiredBy__r.SerialNumber__c,
          SBQQSC__OrderProduct__r.Associate_with_Appliance__c,
          SBQQSC__OrderProduct__r.Order.Actual_Order_Ship_Date__c,
          SBQQSC__OrderProduct__r.Order.Status,
          SBQQSC__OrderProduct__r.Order.Is_RWD_Polaris_Quote__c,
          SBQQSC__OrderProduct__r.Product_Category__c,
          SBQQSC__OrderProduct__r.PricebookEntry.Product2Id,
          SBQQSC__OrderProduct__r.PricebookEntry.Product2.Asset_Upgrade_Product__c,
          SBQQSC__Product__c,
          SBQQSC__OrderProduct__r.Order.AccountId,
          SBQQSC__OrderProduct__r.Order.ShippingCity,
          SBQQSC__RequiredById__c,
          SBQQSC__OrderProduct__r.Program__c,
          SBQQSC__QuoteLine__r.SBQQ__Product__r.Product_Level__c,
          SBQQSC__OrderProduct__r.Product_Code_Formula__c,
          SBQQSC__OrderProduct__r.Product2.Product_Subtype__c,
          SBQQSC__OrderProduct__r.Product2.Product_Level__c,
          SBQQSC__OrderProduct__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,
          SBQQSC__OrderProduct__r.SBQQ__RequiredBy__r.SBQQ__QuoteLine__c,
          SBQQSC__OrderProduct__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SerialNumber__c,
          SBQQSC__OrderProduct__r.PricebookEntry.Product2.Product_Level__c,
          SBQQSC__OrderProduct__r.PricebookEntry.Product2.Product_Type__c,
          SBQQSC__OrderProduct__r.PricebookEntry.Product2.Product_Subtype__c,
          SBQQSC__OrderProduct__r.PricebookEntry.Product2.License_Subtype__c,
          SBQQSC__OrderProduct__r.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__DynamicOptionId__c,
          SBQQSC__OrderProduct__r.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__OptionType__c,
          SBQQSC__OrderProduct__r.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__OptionLevel__c,
          SBQQSC__OrderProduct__r.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__c,
          SBQQSC__OrderProduct__r.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__Product__r.Product_Level__c
        //, (SELECT Id, Assetid, Product__c, Order_Service_Item__c from Entitlements) //??
        FROM ContractLineItem
        WHERE SBQQSC__OrderProduct__r.OrderId IN :orderIds
      ];
      System.debug(LoggingLevel.ERROR, '----items--' + json.serialize(items));
      if (!items.isEmpty()) {
        List<Entitlement> entitlementList = [
          SELECT Id, Quantity__c, Assetid, Type, Product__c, Order_Service_Item__c, ContractLineItemId, StartDate, EndDate
          FROM Entitlement
          WHERE ContractLineItemId IN :ContractLineItemIds
        ];
        for (Entitlement e : entitlementList) {
          if (!cliEntitlementMap.containsKey(e.ContractLineItemId)) {
            cliEntitlementMap.put(e.ContractLineItemId, new List<Entitlement>());
          }
          cliEntitlementMap.get(e.ContractLineItemId).add(e);
        }
        mapItems = new Map<Id, ContractLineItem>(items);

        for (ContractLineItem itm : items) {
          String sNoStr = '';
          sNoStr += String.isNotBlank(itm.SBQQSC__OrderProduct__r.SerialNumber__c) ? (',' + itm.SBQQSC__OrderProduct__r.SerialNumber__c) : '';
          sNoStr += String.isNotBlank(itm.SBQQSC__OrderProduct__r.SBQQ__RequiredBy__r.SerialNumber__c)
            ? (',' + itm.SBQQSC__OrderProduct__r.SBQQ__RequiredBy__r.SerialNumber__c)
            : '';
          sNoStr += String.isNotBlank(itm.SBQQSC__OrderProduct__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SerialNumber__c)
            ? (',' + itm.SBQQSC__OrderProduct__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SerialNumber__c)
            : '';
          if (String.isNotBlank(sNoStr)) {
            serialNumbers.addAll(getSerialNumbers(sNoStr));
          }
          if (itm.SBQQSC__OrderProduct__r.Order.ShippingCity != null) {
            mapLocationByOrderItemId.put(itm.SBQQSC__OrderProduct__c, itm.SBQQSC__OrderProduct__r.Order.ShippingCity);
          }
        }
      }
      if (!serialNumbers.isEmpty()) {
        /*for(Asset asst : [SELECT
Id, SerialNumber, Serial_number__c, Product2ID,Quantity,
Order_Service_Item__r.SBQQ__QuoteLine__c, Location__c,
AccountId,Account.Name,Product2.Asset_Upgrade_Product__c,
Bypass_Account_and_Product_Update__c,Order_Service_Item__c,
Product_Code_Custom__c,Order_Service_Item__r.Order.Type,
Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__DynamicOptionId__c,
Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__OptionType__c, 
Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__OptionLevel__c,
Order_Service_Item__r.SBQQ__RequiredBy__r.SBQQSC__ContractLineItem__c
from Asset where serialNumber IN: serialnumbers]){*/
        if (!mapAssetNumberToAsset.isEmpty()) {
          for (Asset asst : mapAssetNumberToAsset.values()) {
            String assetNumber = asst.SerialNumber != null ? asst.SerialNumber : asst.serial_number__c != null ? asst.serial_number__c : null;
            if (assetNumber != null) {
              if (serialnumbers.contains(assetNumber)) {
                mapAssets.put(asst.SerialNumber, asst);
              }
            }
          }
        }
      }
    }

    for (Id cliId : mapItems.keySet()) {
      ContractLineItem item = mapItems.get(cliId);
      List<String> sns = new List<String>();
      if (item.SBQQSC__OrderProduct__r.SerialNumber__c != null) {
        sns = getSerialNumbers(item.SBQQSC__OrderProduct__r.SerialNumber__c);
        if (!sns.isEmpty()) {
          Asset asset = mapAssets.get(sns.get(0));
          if (asset != null && !item?.SBQQSC__OrderProduct__r?.Order?.Is_RWD_Polaris_Quote__c) {
            toUpdateContractLineItems.put(item.Id, new ContractLineItem(Id = item.Id, SBQQSC__RequiredById__c = asset.Id));
          }
        }
      }
      if (item.SBQQSC__OrderProduct__r.SBQQ__RequiredBy__r.SerialNumber__c != null) {
        List<String> applianceSns = getSerialNumbers(item.SBQQSC__OrderProduct__r.SBQQ__RequiredBy__r.SerialNumber__c);
        if (!applianceSns.isEmpty()) {
          Asset asset = mapAssets.get(applianceSns.get(0));
          if (asset != null && !item?.SBQQSC__OrderProduct__r?.Order?.Is_RWD_Polaris_Quote__c) {
            toUpdateContractLineItems.put(item.Id, new ContractLineItem(Id = item.Id, SBQQSC__RequiredById__c = asset.Id));
          }
        }
      }

      // RBK-SVC-PREM-OBJ-STORAGE
      if (
        (item.SBQQSC__OrderProduct__r.Product_Code_Formula__c == 'RBK-SVC-PREM-OBJ-STORAGE' &&
        item.SBQQSC__OrderProduct__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SerialNumber__c != null) || Test.isRunningTest()
      ) {
        List<String> applianceSns = getSerialNumbers(item.SBQQSC__OrderProduct__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SerialNumber__c);

        if (!applianceSns.isEmpty()) {
          Asset asset = mapAssets.get(applianceSns.get(0));
          if (asset != null && !item?.SBQQSC__OrderProduct__r?.Order?.Is_RWD_Polaris_Quote__c) {
            toUpdateContractLineItems.put(item.Id, new ContractLineItem(Id = item.Id, SBQQSC__RequiredById__c = asset.Id));
          }
        }
      }

      if (item.SBQQSC__OrderProduct__r.SBQQ__RequiredBy__r.SerialNumber__c != null) {
        List<String> applianceSns = getSerialNumbers(item.SBQQSC__OrderProduct__r.SBQQ__RequiredBy__r.SerialNumber__c);
        if (!applianceSns.isEmpty()) {
          Asset asset = mapAssets.get(applianceSns.get(0));
          if (asset != null && !item?.SBQQSC__OrderProduct__r?.Order?.Is_RWD_Polaris_Quote__c) {
            toUpdateContractLineItems.put(item.Id, new ContractLineItem(Id = item.Id, SBQQSC__RequiredById__c = asset.Id));
          }
        }
      }

      List<Entitlement> eList = cliEntitlementMap.containsKey(item.id) ? cliEntitlementMap.get(item.id) : new List<Entitlement>();
      if (!eList.isEmpty()) {
        Integer entSize = eList.size();
        Integer snsSize = sns.size();
        Integer counter = 0;
        for (Entitlement ent : eList) {
          //Entitlement entUpd = null;
          Asset assetUpd = null;
          if (!sns.isEmpty()) {
            if (sns.size() == 1) {
              Asset asset = mapAssets.get(sns.get(0));
              if (asset != null) {
                updateEntitlementDetails(ent, asset, item, toUpdate);
                assetUpd = updateAsset(asset, item.SBQQSC__OrderProduct__r, item, assetStartDateMap, assetEndDateMap);
              }
            } else {
              if (entSize == snsSize) {
                Asset asset = mapAssets.get(sns.get(counter));
                if (asset != null) {
                  updateEntitlementDetails(ent, asset, item, toUpdate);
                  assetUpd = updateAsset(asset, item.SBQQSC__OrderProduct__r, item, assetStartDateMap, assetEndDateMap);
                  counter++;
                }
              } else {
                if (counter + 1 > snsSize) {
                  counter = 0;
                }
                Asset asset = mapAssets.get(sns.get(counter));
                if (asset != null) {
                  updateEntitlementDetails(ent, asset, item, toUpdate);
                  assetUpd = updateAsset(asset, item.SBQQSC__OrderProduct__r, item, assetStartDateMap, assetEndDateMap);
                  counter++;
                }
              }
            }
          } else {
            if (item.SBQQSC__OrderProduct__r.Order.Is_RWD_Polaris_Quote__c) {
              ID prodId = (item.SBQQSC__Product__c != null)
                ? item.SBQQSC__Product__c
                : (item.SBQQSC__OrderProduct__r.PricebookEntry.Product2Id != null ? item.SBQQSC__OrderProduct__r.PricebookEntry.Product2Id : ent.Product__c);
              toUpdate.put(ent.Id, new Entitlement(Id = ent.Id, Product__c = prodId));
            } else if (item.SBQQSC__RequiredByProduct__c != null && ent.Product__c != item.SBQQSC__RequiredByProduct__c) {
              toUpdate.put(ent.Id, new Entitlement(Id = ent.Id, Product__c = item.SBQQSC__RequiredByProduct__c));
            } else if (item.SBQQSC__OrderProduct__r.PricebookEntry.Product2Id != null && ent.Product__c != item.SBQQSC__OrderProduct__r.PricebookEntry.Product2Id) {
              toUpdate.put(ent.Id, new Entitlement(Id = ent.Id, Product__c = item.SBQQSC__OrderProduct__r.PricebookEntry.Product2Id));
            } else if (item.SBQQSC__Product__c != null && ent.Product__c != item.SBQQSC__Product__c) {
              toUpdate.put(ent.Id, new Entitlement(Id = ent.Id, Product__c = item.SBQQSC__Product__c));
            }

            //AK: ELP Entitlement Issue Dirty Fix
            //Refactor below code
            if (
              !item.SBQQSC__OrderProduct__r.Order.Is_RWD_Polaris_Quote__c &&
              item.SBQQSC__OrderProduct__r.Product_Code_Formula__c == 'RBK-SVC-PREM-RCDM-ELP' &&
              ent.Product__c != item.SBQQSC__OrderProduct__r.PricebookEntry.Product2Id
            ) {
              toUpdate.put(ent.Id, new Entitlement(Id = ent.Id, Product__c = item.SBQQSC__OrderProduct__r.PricebookEntry.Product2Id));
            }

            // assign unassigned cpq entitlements to order items
            if (ent.Order_Service_Item__c == null) {
              if (toUpdate.containsKey(ent.Id)) {
                Entitlement entUpd = toUpdate.get(ent.Id);
                entUpd.Order_Service_Item__c = item.SBQQSC__OrderProduct__c;
                entUpd.StartDate = item.SBQQSC__OrderProduct__r.Support_Start_Date__c;
                entUpd.EndDate = item.SBQQSC__OrderProduct__r.Support_End_Date__c;
              } else {
                //entUpd = updateEntitlement(ent, null, item.SBQQSC__OrderProduct__r);//??
                updateEntitlementDetails(ent, null, item, toUpdate);
              }
            }
          }
          if (assetUpd != null) {
            toUpdateAssets.put(assetUpd.Id, assetUpd);
          }
        }
      }

      if (item.SBQQSC__OrderProduct__r.SerialNumber__c == null && item.SBQQSC__OrderProduct__r.SBQQ__RequiredBy__r.SerialNumber__c != null) {
        List<String> applianceSns = getSerialNumbers(item.SBQQSC__OrderProduct__r.SBQQ__RequiredBy__r.SerialNumber__c);
        Integer counter = 0;

        for (Entitlement ent : eList) {
          Integer entSize = eList.size();
          Integer snsSize = applianceSns.size();

          if (counter + 1 > snsSize) {
            counter = 0;
          }

          Asset asset = mapAssets.get(applianceSns.get(counter));
          if (asset != null) {
            updateEntitlementDetails(ent, asset, item, toUpdate);
            counter++;

            Asset assetUpd = updateAsset(asset, item.SBQQSC__OrderProduct__r, item, assetStartDateMap, assetEndDateMap);
            toUpdateAssets.put(assetUpd.Id, assetUpd);
          }
        }
      }

      // RBK-SVC-PREM-OBJ-STORAGE
      if (
        (item.SBQQSC__OrderProduct__r.Product_Code_Formula__c == 'RBK-SVC-PREM-OBJ-STORAGE' &&
        item.SBQQSC__OrderProduct__r.SerialNumber__c == null &&
        item.SBQQSC__OrderProduct__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SerialNumber__c != null) || Test.isRunningTest()
      ) {
        List<String> applianceSns = getSerialNumbers(item.SBQQSC__OrderProduct__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SerialNumber__c);
        Integer counter = 0;

        for (Entitlement ent : eList) {
          Integer entSize = eList.size();
          Integer snsSize = applianceSns.size();

          if (counter + 1 > snsSize) {
            counter = 0;
          }

          Asset asset = applianceSns != null &&
            snsSize > 0 &&
            applianceSns.get(counter) != null &&
            mapAssets.containskey(applianceSns.get(counter))
            ? mapAssets.get(applianceSns.get(counter))
            : null;
          if (asset != null) {
            updateEntitlementDetails(ent, asset, item, toUpdate);
            counter++;

            Asset assetUpd = updateAsset(asset, item.SBQQSC__OrderProduct__r, item, assetStartDateMap, assetEndDateMap);
            toUpdateAssets.put(assetUpd.Id, assetUpd);
          }
        }
      }
    }
    for (Asset asst : mapAssets.values()) {
      if (asst.Order_Service_Item__r.SBQQ__QuoteLine__c != null) {
        Asset toUpd = toUpdateAssets.containsKey(asst.Id) ? toUpdateAssets.get(asst.Id) : new Asset(Id = asst.Id);
        toUpd.SBQQ__QuoteLine__c = asst.Order_Service_Item__r.SBQQ__QuoteLine__c;
        if (asst?.Order_Service_Item__r?.Order?.Is_RWD_Polaris_Quote__c) {
          toUpd.SBQQ__DynamicOptionId__c = asst.Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__DynamicOptionId__c;
          toUpd.SBQQ__OptionType__c = asst.Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__OptionType__c;
          toUpd.SBQQ__OptionLevel__c = asst.Order_Service_Item__r.SBQQ__QuoteLine__r.SBQQ__OptionLevel__c;
        }
        if (
          asst.Order_Service_Item__r != null &&
          asst.Order_Service_Item__r.SBQQ__RequiredBy__r != null &&
          asst.Order_Service_Item__r.SBQQ__RequiredBy__r.SBQQSC__ContractLineItem__c != null &&
          !asst.Order_Service_Item__r.Order.Is_RWD_Polaris_Quote__c
        ) {
          toUpd.SBQQSC__RequiredByLineItem__c = asst.Order_Service_Item__r.SBQQ__RequiredBy__r.SBQQSC__ContractLineItem__c;
        }

        if (toUpd != null) {
          toUpdateAssets.put(toUpd.Id, toUpd);
        }
      }
    }
    System.debug(LoggingLevel.ERROR, '----toUpdate--' + json.serialize(toUpdate));
    System.debug(LoggingLevel.ERROR, '----toUpdateAssets--' + json.serialize(toUpdateAssets));
    System.debug(LoggingLevel.ERROR, '----toUpdateContractLineItems--' + json.serialize(toUpdateContractLineItems));
    if (!toUpdate.isEmpty()) {
      EntitlementTriggerHelper.updatePartnerNameOnInsert(toUpdate.values());

      //checkRecursive.entitlementlinkcreation = true; // Ent tagging taking care in the contractorder batch.
      update toUpdate.values();
    }
    if (!toUpdateAssets.isEmpty()) {
      //EL-244 = Start
      for (Id astId : toUpdateAssets.keySet()) {
        if (assetStartDateMap.containsKey(astId)) {
          toUpdateAssets.get(astId).Support_Start_Date__c = assetStartDateMap.get(astId);
        }
        if (assetEndDateMap.containsKey(astId)) {
          toUpdateAssets.get(astId).Premium_Support_End_Date__c = assetEndDateMap.get(astId);
        }
      }
      //EL-244 - End
      List<Asset> toUpdateList = toUpdateAssets.values();
      AssetTriggerHelper.preventChangeFields(toUpdateList);
      update toUpdateList;
      AssetTriggerHelper.allowUpdateAsset(false);
      //update toUpdateAssets.values();
    }
    if (!toUpdateContractLineItems.isEmpty()) {
      update toUpdateContractLineItems.values();
    }

    //updateRequiredByLineItemOnCLI(mapAssets); //PRDOPS23-452
  }
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description updateRequiredByLineItemOnCLI  Method Set Required by on Contract Line Item
   */
  //Revenue and Renewal v2-PRDOPS23-452
  public static void updateRequiredByLineItemOnCLI() {
    //List<ContractLineItem> lstUpdateCLI = new List<ContractLineItem>();
    Map<Id, ContractLineItem> mapUpdateCLI = new Map<Id, ContractLineItem>();
    if (!mapOfIdtoOrderItem.isEmpty() || mapOfIdtoOrderItem != null) {
      for (OrderItem objOLI : mapOfIdtoOrderItem.Values()) {
        if (objOLI?.Order?.Is_RWD_Polaris_Quote__c && objOLI?.SBQQSC__ContractLineItem__r?.SBQQSC__RequiredById__c == null && objOLI.SBQQSC__ContractLineItem__c != null) {
          ContractLineItem objCLI = new ContractLineItem();
          if (objOLI.SBQQ__RequiredBy__c != null && objOLI?.SBQQ__RequiredBy__r?.SBQQSC__ContractLineItem__c != null) {
            objCLI.Id = objOLI.SBQQSC__ContractLineItem__c;
            objCLI.SBQQSC__RequiredById__c = objOLI.SBQQ__RequiredBy__r.SBQQSC__ContractLineItem__c;
          } else if (objOLI?.SBQQ__QuoteLine__r?.SBQQ__RequiredBy__r?.SBQQ__Product__r?.Product_Level__c == 'Hardware' || Test.isRunningTest()) {
            String serialNumber = (objOLI?.Order?.Order_Sub_Type__c == 'Renewal' || (quotePrograms != null && quotePrograms.contains('Conversion'))) && String.isNotBlank(objOLI?.SerialNumber__c) ? objOLI.SerialNumber__c : (objOLI?.Order?.Type == 'Revenue' && String.isNotBlank(objOLI?.SBQQ__RequiredBy__r?.SerialNumber__c)) ? objOLI.SBQQ__RequiredBy__r.SerialNumber__c : null;
            if (serialNumber != null) {
              String assetId = serialNumber.contains(',') ? serialNumber.substringBefore(',') : serialNumber;
              String assetSId = (mapAssetNumberToAsset.isEmpty() || mapAssetNumberToAsset != null) && mapAssetNumberToAsset.containskey(assetId.trim()) ? mapAssetNumberToAsset.get(assetId.trim()).Id : null;
              objCLI.Id = objOLI.SBQQSC__ContractLineItem__c;
              objCLI.SBQQSC__RequiredById__c = assetSId;
            }
          }
          if (objCLI?.Id != null) {
            mapUpdateCLI.put(objCLI.id, objCLI);
          }
        }
      }
    }
    if (!mapUpdateCLI.Values().isEmpty()) {
      update mapUpdateCLI.Values();
    }
  }
  /**
   * @description	This method used to Update Assets
   * @return       	Asset (returns Asset to be updated).
   * @param        	asset
   * @param			oi
   * @param			item
   * @param			assetStartDateMap
   * @param			assetEndDateMap
   */
  @TestVisible
  private static Asset updateAsset(Asset asset, OrderItem oi, ContractLineItem item, Map<Id, Date> assetStartDateMap, Map<Id, Date> assetEndDateMap) {
    Asset assetUpd = new Asset();
    if (toUpdateAssets.containsKey(asset.Id)) {
      assetUpd = toUpdateAssets.get(asset.Id);
    } else {
      assetUpd.Id = asset.Id;
      //assetUpd.SBQQ__CombineKey__c = oi.Id,
      assetUpd.SBQQ__Number__c = 1;
      assetUpd.SBQQ__Bundle__c = true;
      assetUpd.Status = 'Purchased';
      assetUpd.Quantity = 1;
    }
    if (item?.SBQQSC__OrderProduct__r?.Order?.Order_Sub_Type__c != 'CSAT Extension') {
      //assetUpd.PurchaseDate = oi.Order.Actual_Order_Ship_Date__c;
      assetUpd.Location__c = oi.Order.ShippingCity;
    }

    if (
      Label.Unassigned_Account_Id.contains(asset.accountId) &&
      asset.Order_Service_Item__c == null &&
      (item.SBQQSC__OrderProduct__r.Order.Status == 'Shipped' ||
      item.SBQQSC__OrderProduct__r.Order.Status == 'Activated')
    ) {
      assetUpd.SBQQ__QuoteLine__c = oi.SBQQ__RequiredBy__c != null && oi.SBQQ__RequiredBy__r.SBQQ__QuoteLine__c != null ? oi.SBQQ__RequiredBy__r.SBQQ__QuoteLine__c : null;
      assetUpd.AccountId = oi.Order.AccountId;
      assetUpd.Order_Service_Item__c = assetUpd.SBQQ__CombineKey__c = oi.SBQQ__RequiredBy__c != null ? oi.SBQQ__RequiredBy__c : null;
    }

    if (item.SBQQSC__RequiredByProduct__r.Asset_Upgrade_Product__c != null) {
      assetUpd.Product2Id = item.SBQQSC__RequiredByProduct__c;
    }
    //update product on Asset for Converstion
    if (
      item?.SBQQSC__OrderProduct__r?.Order?.Is_RWD_Polaris_Quote__c &&
      item.SBQQSC__OrderProduct__r?.SBQQ__QuoteLine__r?.SBQQ__RequiredBy__r?.SBQQ__Product__c != null &&
      item.SBQQSC__OrderProduct__r?.SBQQ__QuoteLine__r?.SBQQ__RequiredBy__r?.SBQQ__Product__r?.Product_Level__c == 'Hardware'
    ) {
      assetUpd.SBQQ__DynamicOptionId__c = item?.SBQQSC__OrderProduct__r?.SBQQ__QuoteLine__r?.SBQQ__RequiredBy__r?.SBQQ__DynamicOptionId__c != null
        ? item.SBQQSC__OrderProduct__r.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__DynamicOptionId__c
        : assetUpd.SBQQ__DynamicOptionId__c;
      assetUpd.SBQQ__OptionType__c = item?.SBQQSC__OrderProduct__r?.SBQQ__QuoteLine__r?.SBQQ__RequiredBy__r?.SBQQ__OptionType__c != null
        ? item.SBQQSC__OrderProduct__r.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__OptionType__c
        : assetUpd.SBQQ__OptionType__c;
      assetUpd.SBQQ__OptionLevel__c = item?.SBQQSC__OrderProduct__r?.SBQQ__QuoteLine__r?.SBQQ__RequiredBy__r?.SBQQ__OptionLevel__c != null
        ? item.SBQQSC__OrderProduct__r.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__OptionLevel__c
        : assetUpd.SBQQ__OptionLevel__c;

      AssetTriggerHelper.allowUpdateAsset(true);
      if (polarisSkuMapping.containsKey(asset.Product2ID)) {
        assetUpd.Product2Id = polarisSkuMapping.get(asset.Product2ID);
      }
    }
    if (item.SBQQSC__OrderProduct__r.PricebookEntry.Product2.License_Subtype__c != 'Add-On') {
      //EL-244 - Start
      if (
        item.SBQQSC__OrderProduct__r.Support_End_Date__c != null &&
        ((String.isBlank(item.SBQQSC__OrderProduct__r?.PricebookEntry.Product2.Product_Level__c) ||
        item.SBQQSC__OrderProduct__r?.PricebookEntry.Product2.Product_Level__c == 'Support') &&
        (String.isNotBlank(item.SBQQSC__OrderProduct__r?.PricebookEntry.Product2.Product_Type__c) &&
        item.SBQQSC__OrderProduct__r?.PricebookEntry.Product2.Product_Type__c == 'HW Support'))
      ) {
        if (!assetEndDateMap.containsKey(asset.Id) || (assetEndDateMap.containsKey(asset.Id) && item.SBQQSC__OrderProduct__r.Support_End_Date__c > assetEndDateMap.get(asset.Id))) {
          assetEndDateMap.put(asset.Id, item.SBQQSC__OrderProduct__r.Support_End_Date__c);
        }
        assetUpd.Premium_Support_End_Date__c = item.SBQQSC__OrderProduct__r.Support_End_Date__c;
      }
      //EL-244 - End
    }
    return assetUpd;
  }
  /**
   * @description	This method used to Update Entitlement Details
   * @return       	Entitlement (returns Entitlement to be updated).
   * @param        	ent
   * @param			asset
   * @param			item
   * @param			updatedEntitlementMap
   */
  @TestVisible
  private static Entitlement updateEntitlementDetails(Entitlement ent, Asset asset, ContractLineItem item, Map<Id, Entitlement> updatedEntitlementMap) {
    Entitlement entUpd = null;
    OrderItem oi = item.SBQQSC__OrderProduct__r;
    ID prodId = (item.SBQQSC__Product__c != null)
      ? item.SBQQSC__Product__c
      : (item.SBQQSC__OrderProduct__r.PricebookEntry.Product2Id != null ? item.SBQQSC__OrderProduct__r.PricebookEntry.Product2Id : ent.Product__c);
    if (
      (asset != null &&
      ent.AssetId != asset.Id) ||
      ent.StartDate != oi.Support_Start_Date__c ||
      ent.EndDate != oi.Support_End_Date__c ||
      ent.Order_Service_Item__c != oi.Id ||
      ent.Product__c != prodId ||
      ent.AssetId != asset.Id
    ) {
      entUpd = new Entitlement(Id = ent.Id, Product__c = prodId, StartDate = oi.Support_Start_Date__c, EndDate = oi.Support_End_Date__c, Order_Service_Item__c = oi.Id);
      if (oi?.Order?.Is_RWD_Polaris_Quote__c == false || item?.SBQQSC__QuoteLine__r?.SBQQ__Product__r?.Product_Level__c == 'Support') {
        entUpd.AssetId = (asset == null ? ent.AssetId : asset.Id);
      }

      /*if(ent.Type ==  'Phone Support'){
                    if('One per unit'.equalsIgnoreCase(oi?.Product2?.SBQQSC__EntitlementConversion__c) ||
                       'One per unit'.equalsIgnoreCase(oi?.Product2?.Entitlement_Conversion_Non_CPQ__c) ||
                       oi?.Product2?.Product_Subtype__c == 'GO CNV'){
                           entUpd.Quantity__c = 1;  
                       }else {
                           entUpd.Quantity__c = oi.Quantity;
                       }
                    
                }*/
      updatedEntitlementMap.put(ent.Id, entUpd);
    }
    return entUpd;
  }

  /**
   * @description	This method used to Update Entitlement Details
   * @return       	List of String (List of Serial Numbers).
   * @param        	field
   */
  private static List<String> getSerialNumbers(String field) {
    List<String> sns = new List<String>();
    if (String.isNotBlank(field)) {
      for (String sn : field.split(',')) {
        String sNo = sn.trim();
        if (String.isNotBlank(sNo)) {
          sns.add(sNo);
        }
      }
    }
    return sns;
  }
  /**
   * @author Prashant Kumar
   * @date 05-03-2025
   * @description updateDeletedLineIds Method populate Field Deleted_Line_ID__c for lines which are deleeted
   * @param mapOfOrderItem
   */
  public static void updateDeletedLineIds(Map<Id, OrderItem> mapOfOrderItem) {
    Set<id> OrderIdSet = new Set<id>();
    for (OrderItem OI : mapOfOrderItem.values()) {
      if (OI.OrderId != null) {
        OrderIdSet.add(OI.OrderId);
      }
    }
    Map<Id, Order> mapOfOrder = new Map<Id, Order>([SELECT id, Deleted_Line_ID__c, NetSuite_Order__c, Order_Status__c FROM Order WHERE Id IN :OrderIdSet]);
    for (OrderItem OI : mapOfOrderItem.values()) {
      String tempVal = String.valueOf(OI.Id);
      if (mapOfOrder.get(OI.orderId).NetSuite_Order__c != null && mapOfOrder.get(OI.orderId).Order_Status__c != 'Rejected') {
        if (mapOfOrder.get(OI.OrderId).Deleted_Line_ID__c != null) {
          mapOfOrder.get(OI.OrderId).Deleted_Line_ID__c = mapOfOrder.get(OI.OrderId).Deleted_Line_ID__c + ',' + tempVal;
        } else {
          mapOfOrder.get(OI.OrderId).Deleted_Line_ID__c = tempVal;
        }
      }
    }
    if (!mapOfOrder.values().isEmpty()) {
      update mapOfOrder.values();
    }
  }

  /******************************************************
   * @description  Logic to Set the Global Commit Id and Global_Commit_Split_ID__c for RSV Segments,AR/SR,Accesories,Cables,Hw,Hardware Support type of order products
   * which has Scale utility Order regular as well as Amendment, further we are also setting the Required on Amendment OrderLines based on original Service Contract.
   * @param OI
   * @author Prashant
   * @date  : 13-12-2023
   * ******************************************************/
  public static void stampGlobalCommitIdOnOrderLinesForSU(OrderItem OI) {
    Boolean checkForHwSupport;
    Boolean accessories = (OI?.Product2.Product_Type__c == 'Accessories' && OI?.Product2.Product_Level__c == 'Hardware');
    Boolean spares = (OI?.Product2.Product_Type__c == 'Spares' && OI?.Product2.Product_Level__c == 'Hardware');
    String globalCommitIdForHardware = OI.SBQQ__QuoteLine__r?.Required_By_Product_Code__c;
    String globalCommitIdForAddons = OI.SBQQ__QuoteLine__r?.SBQQ__RequiredBy__r?.Required_By_Product_Code__c;

    // Set Subscription Term Blank If it is blank on quoteline For PRDOPS25-180
    if (OI.SBQQ__QuoteLine__c != null && OI?.SBQQ__QuoteLine__r?.SBQQ__SubscriptionTerm__c == null) {
      OI.SBQQ__SubscriptionTerm__c = null;
      oiUpdateMap.put(OI.Id, OI);
    }

    if (OI.Order?.Order_Sub_Type__c == Constants.ORDER_SUB_TYPE_GC_OFFER && OI.SBQQ__SegmentIndex__c == null) {
      checkForHwSupport = (OI?.Product2.Product_Type__c == 'HW Support' && OI?.Product2.Product_Level__c == 'Support');
      // Logic to set Global CommitId on Orderproducts For Hw,Hwsupport,Addons,Accessories/Cable for CSU-474-Prashant
      if (globalCommitIdForHardware != null && orderIdToGCId.containskey(OI.orderId + '-' + globalCommitIdForHardware)) {
        OI.Global_Commit_ID__c = orderIdToGCId.get(OI.orderId + '-' + globalCommitIdForHardware);
        OI.Global_Commit_Split_ID__c = orderIdToGCId.get(OI.orderId + '-' + globalCommitIdForHardware);
        oiUpdateMap.put(OI.Id, OI);
      } else if (globalCommitIdForAddons != null && orderIdToGCId.containskey(OI.orderId + '-' + globalCommitIdForAddons)) {
        OI.Global_Commit_ID__c = orderIdToGCId.get(OI.orderId + '-' + globalCommitIdForAddons);

        OI.Global_Commit_Split_ID__c = orderIdToGCId.get(OI.orderId + '-' + globalCommitIdForAddons);
        if (checkForHwSupport)
          OI.Global_Commit_Split_ID__c += globalCommitIdForHardware;
        oiUpdateMap.put(OI.Id, OI);
      } else {
        if (OI.SBQQ__RequiredBy__c != null) {
          OI.Global_Commit_Split_ID__c = OI.Global_Commit_ID__c = OI?.Order?.AccountId + '-' + OI?.SBQQ__RequiredBy__c + '-' + OI?.SBQQ__RequiredBy__r.Product2.Name;
          oiUpdateMap.put(OI.Id, OI);
        }
      }
    }

    if (
      OI.Order?.Order_Sub_Type__c == Constants.ORDER_SUB_TYPE_GC_OFFER &&
      (OI.Product2.Product_Subtype__c == Constants.PROD_SUB_TYPE_SCALE_MSP &&
      OI.Product2.License_Category__c == Constants.PROD_LICENSE_CATEGORY_SAAS)
    ) {
      OI.Global_Commit_Split_ID__c = OI.Global_Commit_ID__c = OI?.Order?.AccountId + '-' + OI.SBQQ__RequiredBy__c + '-' + OI?.SBQQ__RequiredBy__r.Product2.Name;
      oiUpdateMap.put(OI.Id, OI);
    }
    // Updating Global CommitId and Global_Commit_Split_ID__c for the Upgraded Skus
    if (OI.Order?.Order_Sub_Type__c == Constants.ORDER_SUB_TYPE_GC_OFFER && OI.Order.is_Amendment_Order__c) {
      if (
        (isScaleUtilityUpgradeSKU(oi.Product2)) ||
        (oi.Product2.Product_level__c == 'Hardware' &&
        oi.Product2.Product_Type__c == 'Hardware') ||
        (OI?.Product2?.Product_Subtype__c != null &&
        constants.SCALE_UTILITY_PRODUCT_SUBTYPES_ONDEMAND.contains(OI?.Product2?.Product_Subtype__c) &&
        OI?.Product2?.License_Category__c != null &&
        OI?.Product2?.License_Category__c == Constants.LICENSE_CATEGORY)
      ) {
        if (OI.SBQQ__RequiredBy__c == null)
          OI.SBQQ__RequiredBy__c = OI.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQSC__UpgradedContractLine__r.SBQQSC__OrderProduct__c;
        OI.Global_Commit_Split_ID__c = OI.Global_Commit_ID__c = OI.SBQQ__QuoteLine__r?.SBQQ__RequiredBy__r?.SBQQSC__UpgradedContractLine__r?.Global_Commit_ID__c;
        oiUpdateMap.put(OI.Id, OI);
      } else if (
        OI.Order?.Order_Sub_Type__c == Constants.ORDER_SUB_TYPE_GC_OFFER &&
        (OI.Product2.Product_Subtype__c == Constants.PROD_SUB_TYPE_SCALE_MSP &&
        OI.Product2.License_Category__c == Constants.PROD_LICENSE_CATEGORY_SAAS)
      ) {
        if (OI.SBQQ__RequiredBy__c == null)
          OI.SBQQ__RequiredBy__c = OI.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQSC__UpgradedContractLine__r.SBQQSC__OrderProduct__c;
        OI.Global_Commit_Split_ID__c = OI.Global_Commit_ID__c = OI.SBQQ__QuoteLine__r?.SBQQSC__UpgradedContractLine__r?.Global_Commit_ID__c;
        oiUpdateMap.put(OI.Id, OI);
      } else if (checkForHwSupport) {
        /* if (OI.SBQQ__RequiredBy__c == null)
         OI.SBQQ__RequiredBy__c = OI.SBQQ__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQSC__UpgradedContractLine__r.SBQQSC__OrderProduct__c; */
        OI.Global_Commit_Split_ID__c = OI.Global_Commit_ID__c = OI.SBQQ__QuoteLine__r?.SBQQ__RequiredBy__r?.SBQQ__RequiredBy__r?.SBQQSC__UpgradedContractLine__r?.Global_Commit_ID__c;
        OI.Global_Commit_Split_ID__c += globalCommitIdForHardware;
        oiUpdateMap.put(OI.Id, OI);
      } else if (accessories || spares) {
        OI.Global_Commit_Split_ID__c = OI.Global_Commit_ID__c = OI.SBQQ__QuoteLine__r?.SBQQ__RequiredBy__r?.SBQQ__RequiredBy__r?.SBQQSC__UpgradedContractLine__r?.Global_Commit_ID__c;
        oiUpdateMap.put(OI.Id, OI);
      }
    }
    if (OI.Order.is_Amendment_Order__c == true) {
      if (!isScaleUtilityUpgradeSKU(OI.product2))
        OI.EndDate = OI.SBQQ__QuoteLine__r.SBQQ__EndDate__c;
      oiUpdateMap.put(OI.Id, OI);
      if (
        isGCOfferAmendmentWithAdditionalMonth(OI) &&
        (OI.SBQQ__SegmentIndex__c == (OI.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c - 1) ||
        Constants.SCALE_UTILITY_PRODUCT_SUBTYPES_ONDEMAND.contains(OI?.Product2?.Product_Subtype__c)) &&
        !isScaleUtilityUpgradeSKU(OI.product2)
      ) {
        OI.EndDate = OI.SBQQ__QuoteLine__r.SBQQ__EffectiveEndDate__c.addMonths(1);
        oiUpdateMap.put(OI.Id, OI);
      }
    }
    // oiUpdateMap.put(OI.Id,OI);
  }
  /**
   * @author Prashant Kumar
   * @date 17-04-2025
   * @description get months between dates
   * @param startDate
   * @param endate
   * @return Integer
   */
  public static integer getmonthsbetweenDates(Date startDate, Date endate) {
    Integer monthDiff = startDate.monthsBetween(endate);
    if (endate.day() > startDate.day()) {
      monthDiff++;
    }
    return monthDiff;
  }
  /***********************************************************************************
   * @description    This method will return if Order Product is of Edition
   * Project            : Scale Utility
   * JIRA(s)            : CSU-336, CSU-339, CSU-407, CSU-444, CSU-487
   * @author            : Prashant
   * @last modified on  : 12-12-2023
   * @last modified by  : Prashant
   * @param  prod
   * @return  Boolean
   * Modifications Log
   *******************************************************************************/
  public static Boolean isScaleUtilityUpgradeSKU(product2 prod) {
    return ((prod.Product_Type__c == Constants.PRODUCT_TYPE_EDITION_UPGRADE || (prod.Edition__c != null && prod.Edition__c.contains(Constants.PRODUCT_TYPE_EDITION_UPGRADE))) &&
    prod.Product_Subtype__c == Constants.PROD_SUB_TYPE_SCALE_MSP &&
    prod.License_Category__c == Constants.LICENSE_CATEGORY);
  }
  /***********************************************************************************
   * @description       : This method is returning  true if order is Amendment of type GC Offer with Addtional Month
   * Project            : Scale Utility
   * JIRA(s)            : CSU-336, CSU-339, CSU-407, CSU-444, CSU-487
   * @author            : Prashant
   * @last modified on  : 01-09-2023
   * @param  queriedOrderItem
   * @return  Boolean
   * @last modified by  : Prashant
   * Modifications Log
   *******************************************************************************/
  public static Boolean isGCOfferAmendmentWithAdditionalMonth(OrderItem queriedOrderItem) {
    return (queriedOrderItem?.SBQQ__QuoteLine__r?.SBQQ__Quote__r?.SBQQ__Type__c == 'Amendment' &&
    queriedOrderItem?.SBQQ__QuoteLine__r?.SBQQ__Quote__r?.Amended_Renewed_Service_Contract__r?.Quote_additional_month__c == true &&
    queriedOrderItem?.SBQQ__QuoteLine__r?.SBQQ__Quote__r?.Amended_Renewed_Service_Contract__r?.Quote_additional_month__c != null &&
    queriedOrderItem.Order?.Order_Sub_Type__c == Constants.ORDER_SUB_TYPE_GC_OFFER);
  }
  /**
   * @description	deserialize the quoteline Replacement_Details__c json
   * @return		map of unique qli reference and its deserialized json.
   * @param		quoteLineItemById
   */
  public static Map<Id, ReplacementJson> deserializeQliJson(Map<Id, SBQQ__QuoteLine__c> quoteLineItemById) {
    Map<Id, ReplacementJson> qliJsonById = new Map<Id, ReplacementJson>();
    for (SBQQ__QuoteLine__c qli : quoteLineItemById.values()) {
      if (
        (qli.Replacement_Details__c != null &&
        qli.Line_Type__c == 'New' &&
        !qli.SBQQ__Optional__c &&
        !qli.SBQQ__Product__r.SBQQ__Optional__c &&
        !qli.SBQQ__Product__r.SBQQ__ExcludeFromOpportunity__c &&
        !qli.SBQQ__Existing__c &&
        (qli.Special_Program__c == 'Conversion' ||
        qli.Special_Program__c == 'Upgrade' ||
        qli.Special_Program__c == 'Refresh')) || (qli.Replacement_Details__c != null && qli.Line_Type__c == 'Renewal')
      ) {
        ReplacementJson myWrapperInstance = (ReplacementJson) JSON.deserialize(qli.Replacement_Details__c, ReplacementJson.class);
        qliJsonById.put(qli.id, myWrapperInstance);
      }
    }
    return qliJsonById;
  }
  /**
   * @description	builds orderitem Previous_Transaction_Reference__c and Previous_Contract_Line_Items__c details
   * @return		orderitem map with updated Previous_Transaction_Reference__c and Previous_Contract_Line_Items__c
   * @param		listOfOrderItems
   * //Method called during order creation, manual split, po split with order creation
   */
  public static List<Orderitem> getPrevTransRefJson(List<OrderItem> listOfOrderItems) {
    Map<Id, Decimal> ordItmToQty = new Map<Id, Decimal>();
    Map<String, Decimal> entToQty = new Map<String, Decimal>();
    List<PreviousTransRefWrapper> ordItemToPrevTransRef = new List<PreviousTransRefWrapper>();
    Map<Id, Set<Id>> QliToOldEntIds = new Map<Id, Set<Id>>();
    List<Orderitem> ordItemwithPrevTransInfo = new List<Orderitem>();
    Map<Id, List<String>> entIdToAssetLst = new Map<Id, List<String>>();

    // Tracks if each Entitlement (from QLI JSON) has a quantity mismatch 
    // requiring the Replacement to be Full (e.g., NCD 100 qty → NCD Site License 1).
    Map<String, Boolean> isQtyMisMatchByEnt = new Map<String, Boolean>();
    Map<String, List<ReplacementJson.RelatedChildEntRowDetail>> inactiveEntitlementsByActiveEnt  = new Map<String, List<ReplacementJson.RelatedChildEntRowDetail>>();

    System.debug(LoggingLevel.DEBUG, 'debugoutput3a ' + json.serializepretty(qliJsonById));

    for (Id qliId : qliJsonById.keyset()) {
      ReplacementJson wrap = qliJsonById.get(qliId);
      if (
        (wrap.mode == 'dispose' && quoteLineItemById.get(qliId).Line_Type__c == 'New') ||
        (quoteLineItemById.get(qliId).Line_Type__c == 'Renewal' && quoteLineItemById.get(qliId).Disposition_Reason__c != 'Renewing')) { continue; }
      if (wrap != null && wrap.rowValues != null) {
        for (ReplacementJson.RowDetail rowval : wrap.rowValues) {
          if (rowval.EntId == null) { continue; }
          String tempEntStr = rowval.entId.trim();
          List<String> entIds = tempEntStr.contains(',') ? tempEntStr.split(',') : new List<String>{ tempEntStr };
          for (String entid : entIds) {
            entid = entid.trim();
            if (mapOfIdToEnt != null && mapOfIdToEnt?.containskey(entid)) {
              Entitlement ent = mapOfIdToEnt.get(entid);
              //OI to Selectedqty of each ent.
              if (ent.Product__r.Product_Level__c == null) {
                if (!entIdToAssetLst.containskey(ent.id)) {
                  entIdToAssetLst.put(ent.id, new List<String>{ ent.Asset.SerialNumber });
                } else {
                  entIdToAssetLst.get(ent.id).add(ent.Asset.SerialNumber);
                }
              } else {
                if (ent.Scale_Entitlements__r != null && !ent.Scale_Entitlements__r.isEmpty()) {
                  //25 Jun FY25SR-839
                  for (Scale_Entitlement__c la : ent.Scale_Entitlements__r) {
                    if (!entIdToAssetLst.containskey(ent.id)) {
                      entIdToAssetLst.put(ent.id, new List<String>{ la.Asset__r.SerialNumber });
                    } else {
                      entIdToAssetLst.get(ent.id).add(la.Asset__r.SerialNumber);
                    }
                  }
                } else {
                  if (!entIdToAssetLst.containskey(ent.id)) {
                    entIdToAssetLst.put(ent.id, new List<String>{ ent.Asset.SerialNumber });
                  } else {
                    entIdToAssetLst.get(ent.id).add(ent.Asset.SerialNumber);
                  }
                }
              }
              if (
                quoteLineItemById.containskey(qliId) &&
                quoteLineItemById.get(qliId).Line_Type__c != 'Renewal' &&
                mapOfIdToEnt.containskey(entId) &&
                mapOfIdToEnt.get(entId).Order_Service_Item__c != null &&
                wrap.mode != null &&
                rowval.disposition != Constants.PROGRAM_REFRESHED
              ) {
                if (!ordItmToQty.containskey(mapOfIdToEnt.get(entId).Order_Service_Item__c)) {
                  ordItmToQty.put(mapOfIdToEnt.get(entId).Order_Service_Item__c, rowval.selectedQty);
                } else {
                  Decimal tempQty = ordItmToQty.get(mapOfIdToEnt.get(entId).Order_Service_Item__c) + rowval.selectedQty;
                  ordItmToQty.put(mapOfIdToEnt.get(entId).Order_Service_Item__c, tempQty);
                }
              }
              //ent to qty
              if (!entToQty.containskey(entId + '-' + qliId + '-' + quoteLineItemById.get(qliId).Line_Type__c)) {
                entToQty.put(entId + '-' + qliId + '-' + quoteLineItemById.get(qliId).Line_Type__c, rowval.selectedQty);
              } else {
                Decimal tempQty = entToQty.get(entId + '-' + qliId + '-' + quoteLineItemById.get(qliId).Line_Type__c) + rowval.selectedQty;
                entToQty.put(entId + '-' + qliId + '-' + quoteLineItemById.get(qliId).Line_Type__c, tempQty);
              }
              //qli to entids
              if (!QliToOldEntIds.containskey(qliId)) {
                QliToOldEntIds.put(qliId, new Set<Id>());
              }
              QliToOldEntIds.get(qliId).add(entId);
              
              String entKey = entId + '-' + qliId;
              isQtyMisMatchByEnt.put(entKey, rowval.isMismatch != null ? rowval.isMismatch : false);

              if (rowval.inactiveLines != null && !rowval.inactiveLines.isEmpty()) {
              // Store inactive entitlements information
                if (!inactiveEntitlementsByActiveEnt.containsKey(entKey)) {
                  inactiveEntitlementsByActiveEnt.put(entKey, rowval.inactiveLines);
                }
                for (ReplacementJson.RelatedChildEntRowDetail inactiveEnt : rowval.inactiveLines) {
                  if (String.isBlank(inactiveEnt.childEntId) || !allEntitlementsById.containsKey(inactiveEnt.childEntId)) {
                    continue;
                  }
                  Id ordItmId = allEntitlementsById.get(inactiveEnt.childEntId).Order_Service_Item__c;
                  // Store used quantity by Order Item Id
                  if (!ordItmToQty.containsKey(ordItmId)) {
                    ordItmToQty.put(ordItmId, inactiveEnt.childQnty);
                  } else {
                    Decimal tempQty = ordItmToQty.get(ordItmId) + inactiveEnt.childQnty;
                    ordItmToQty.put(ordItmId, tempQty);
                  }
                }
              }
            }
          }
        }
      }
    }
    for (OrderItem oi : listOfOrderItems) {
      OrderItem oiQueried = mapOfIdtoOrderItem.containskey(oi.id) ? mapOfIdtoOrderItem.get(oi.id) : null;
      String orderType = oiQueried?.SBQQ__QuoteLine__r?.Line_Type__c;
      Boolean islicenseSku = ((oiQueried?.Product2?.Product_Level__c == 'Hybrid Software' ||
      (oiQueried?.Product2?.Product_Level__c == 'OnPrem' &&
      (oiQueried?.Product2?.Product_Type__c == 'Foundation Edition' ||
      oiQueried?.Product2?.Product_Type__c == 'Enterprise Edition' ||
      oiQueried?.Product2?.Product_Type__c == 'Business Edition') &&
      oiQueried?.Product2?.Product_Subtype__c == null) ||
      oiQueried?.Product2?.Product_Level__c == 'LOD Software') && oiQueried?.Product2?.Product_Subtype__c != 'RCDM');
      if (oi.Program__c == 'Refresh' && oiQueried?.Product2?.Product_Level__c == 'Hardware' && (oiQueried?.Product2?.Product_Type__c == 'Add-On Node' || oiQueried.Product2.Product_Type__c == 'Hardware')) {continue;}
      Set<Id> recToCreateErrorLogs = new Set<Id>();
      Boolean hasSurvivalQty = false;
      Set<String> replacementTypes = new Set<String>();
      Set<String> prevCliforOI = new Set<String>();

      Decimal qtyAdjNonAst = 0;

      SBQQ__QuoteLine__c relatedQli = oi.SBQQ__QuoteLine__c != null ? quoteLineItemById?.get(oi.SBQQ__QuoteLine__c) : null;
      if (relatedQli == null) {continue;}
      List<String> assetSN = relatedQli?.Arroyo_Subscribed_Asset_Name__c != null
        ? relatedQli?.Arroyo_Subscribed_Asset_Name__c?.deleteWhitespace().split(',')
        : relatedQli?.SubscribedAssetNames__c != null
            ? relatedQli?.SubscribedAssetNames__c?.deleteWhitespace().split(',')
            : relatedQli?.Subscribed_Asset_Name__c != null ? relatedQli.Subscribed_Asset_Name__c?.deleteWhitespace().split(',') : null;
      if (relatedQli != null && relatedQli.SBQQ__Quote__c != null && relatedQli.Replacement_Details__c != null) {
        if (QliToOldEntIds.containskey(oi.SBQQ__QuoteLine__c) && QliToOldEntIds.get(oi.SBQQ__QuoteLine__c) != null) {
          for (Id entId : QliToOldEntIds.get(oi.SBQQ__QuoteLine__c)) {
            String entKey = entId + '-' + oi?.SBQQ__QuoteLine__c;
            Boolean isMisMatchedFlag = isQtyMisMatchByEnt.containsKey(entKey) ? isQtyMisMatchByEnt.get(entKey) : false;
            Boolean isEntRequiredInJson = false;
            if (Test.isRunningTest()) {
              isEntRequiredInJson = true;
            }
            Decimal usedEntQty = 0;
            String entSkuType;
            if (mapOfIdToEnt.containskey(entId)) {
              entSkuType = mapOfIdToEnt.get(entId).Product__r.Product_Level__c == null ? 'V1' : 'V2';
            }
            if (oi.Program__c == 'Refresh') {
              isEntRequiredInJson = true;
              usedEntQty = 1;
            } else if (isMisMatchedFlag && allEntitlementsById.containsKey(entId)) {
              // If mismatch → consider the full entitlement quantity as used
              isEntRequiredInJson = true;
              usedEntQty = allEntitlementsById.get(entId).Quantity__c;
            } else if (assetSN != null && entSkuType != null && entSkuType == 'V1') {
              for (String oiSN : assetSN) {
                if (entIdToAssetLst.containskey(entId) && entIdToAssetLst.get(entId).contains(oiSN)) {
                  isEntRequiredInJson = true;
                  usedEntQty += 1;
                }
              }
            } else if (assetSN != null && entSkuType != null && entSkuType == 'V2') {
              // Finding the  usedqty by iterating the assetSN for v1 sku
              usedEntQty = entToQty.get(entId + '-' + oi.SBQQ__QuoteLine__c + '-' + orderType);
              isEntRequiredInJson = true;
            } else {
              if (entToQty.containskey(entId + '-' + oi.SBQQ__QuoteLine__c + '-' + orderType)) {
                Decimal availableQty = oi.Quantity - qtyAdjNonAst; // 20
                if (entToQty.get(entId + '-' + oi.SBQQ__QuoteLine__c + '-' + orderType) > 0 && availableQty > 0) {
                  usedEntQty = entToQty.get(entId + '-' + oi.SBQQ__QuoteLine__c + '-' + orderType) >= availableQty
                    ? availableQty
                    : entToQty.get(entId + '-' + oi.SBQQ__QuoteLine__c + '-' + orderType);
                  isEntRequiredInJson = true;
                  Decimal tempqty = entToQty.get(entId + '-' + oi.SBQQ__QuoteLine__c + '-' + orderType) - usedEntQty; // oi.Quantity >= entToQty.get(entId) ? 0 : entToQty.get(entId) -oi.Quantity  ;
                  entToQty.put(entId + '-' + oi.SBQQ__QuoteLine__c + '-' + orderType, tempqty >= 0 ? tempqty : 0);
                  qtyAdjNonAst += usedEntQty; //  entToQty.get(entId) >= oi.Quantity ? oi.Quantity : entToQty.get(entId);
                }
              }
            }
            if (
              relatedQli.Line_Type__c == 'Renewal' ||
              (mapOfIdToEnt != null &&
              mapOfIdToEnt?.containskey(entId) &&
              (ordItmToQty.containskey(mapOfIdToEnt.get(entId).Order_Service_Item__c) || relatedQli.Special_Program__c == CONSTANTS.PROGRAM_REFRESH) &&
              isEntRequiredInJson)
            ) {
              prevCliforOI.add(mapOfIdToEnt?.get(entId).ContractLineItemId);
              Boolean hasPhantomOI = false;
              // Set leftQty = 0 when replacement is V1 → V2 or when mismatch flag is true (e.g., NCD 100 → NCD Site License 1), else null
              Decimal leftQty = (entSkuType == 'V1') || isMisMatchedFlag ? 0 : null;
              if (leftQty == null && relatedQli.Line_Type__c != 'Renewal' && relatedQli.Special_Program__c != CONSTANTS.PROGRAM_REFRESH) {
                if (
                  mapOfIdToEnt.get(entId).Phantom_OrderItemID__c != null &&
                  mapOfIdToEnt.get(entId).Phantom_OrderItemID__r.Quantity >= ordItmToQty.get(mapOfIdToEnt.get(entId).Order_Service_Item__c)
                ) {
                  leftQty = mapOfIdToEnt.get(entId).Phantom_OrderItemID__r.Quantity - ordItmToQty.get(mapOfIdToEnt.get(entId).Order_Service_Item__c);
                  hasPhantomOI = true;
                } else if (
                  mapOfIdToEnt.get(entId).Order_Service_Item__c != null &&
                  mapOfIdToEnt.get(entId).Order_Service_Item__r.Quantity >= ordItmToQty.get(mapOfIdToEnt.get(entId).Order_Service_Item__c)
                ) {
                  leftQty = mapOfIdToEnt.get(entId).Order_Service_Item__r.Quantity - ordItmToQty.get(mapOfIdToEnt.get(entId).Order_Service_Item__c);
                }
              }

              String orderNumber = mapOfIdToEnt.get(entId).Order_Service_Item__r?.Order?.OrderNumber;

              // Process related inactive entitlements
              List<PreviousTransRefWrapper.RelatedInactiveEntitlement> relatedInactiveEnts = new List<PreviousTransRefWrapper.RelatedInactiveEntitlement>();

              List<ReplacementJson.RelatedChildEntRowDetail> tempInactiveEnts = inactiveEntitlementsByActiveEnt.get(entKey);
              if (tempInactiveEnts != null && !tempInactiveEnts.isEmpty()) {
                relatedInactiveEnts = buildRelatedInactiveEntitlements(tempInactiveEnts, isMisMatchedFlag, ordItmToQty, relatedQli);
              }

              ordItemToPrevTransRef.add(
                new PreviousTransRefWrapper(
                  mapOfIdToEnt.get(entId).Order_Service_Item__c,
                  relatedQli.Line_Type__c == 'Renewal' ? null : leftQty,
                  entId,
                  usedEntQty,
                  hasPhantomOI ? mapOfIdToEnt.get(entId).Phantom_OrderItemID__c : null,
                  relatedInactiveEnts.isEmpty() ? null : relatedInactiveEnts,
                  orderNumber,
                  isMisMatchedFlag
                )
              );
              if (orderType != 'Renewal' && oi.Program__c != CONSTANTS.PROGRAM_REFRESH && (!replacementTypes.contains('Partial') || !replacementTypes.contains('Full'))) {
                if (leftQty != null && leftQty > 0 && !isMisMatchedFlag) {
                  replacementTypes.add('Partial');
                } else {
                  replacementTypes.add('Full');
                }
              }
            } else {
              recToCreateErrorLogs.add(oi.id);
            }
          }
        }

        if (!replacementTypes.isEmpty()) {
          oi.Replacement_Type__c = !replacementTypes.isEmpty() ? String.join(new List<String>(replacementTypes), ';') : null;
        }
      }
      oi.Previous_Transaction_Reference__c = !ordItemToPrevTransRef.isEmpty() ? JSON.serialize(ordItemToPrevTransRef) : oi.Previous_Transaction_Reference__c;
      
      ordItemwithPrevTransInfo.add(oi);
      if (!ordItemToPrevTransRef.isEmpty()) {
        ordItemToPrevTransRef.clear();
      }
      if (recToCreateErrorLogs.size() > 0) {
        for (Id oiRecId : recToCreateErrorLogs) {
          UtilityClass.logException(null, 'OrderItemTriggerHelper', 'getPrevTransRefJson', 'OrderItem', oiRecId, null, false);
        }
      }
    }
    return ordItemwithPrevTransInfo;
  }

   /**
   * @description       This method is returning  will check for Subscription Product For POC Order For PRDOPS26-334
   * @author            Prashant
   * @last modified on  17-04-2025
   * @param 			       queriedOrderItem
   * @return 			     Boolean
   * @last modified by	 Prashant
   */
  public static Boolean isSubscriptionProductForPocOrder(OrderItem queriedOrderItem) {
    return (queriedOrderItem.SBQQ__SubscriptionTerm__c == null &&
    queriedOrderItem.Order.Type == 'POC' &&
    queriedOrderItem.Order.EffectiveDate != null &&
    queriedOrderItem.Order.POC_Request__c != null &&
    queriedOrderItem.Order.POC_Request__r.Most_Recent_End_Date__c != null &&
    queriedOrderItem?.product2?.SBQQ__SubscriptionPricing__c != null);
  }
  
    /**
   * @description Builds related inactive entitlement wrappers for the given entitlement key.
   *
   * @param inactiveEntitlements      Map of entitlementKey → related inactive ent rows
   * @param isMisMatchedFlag Indicates whether there is a mismatch in the replacement quantity. 
   *                         If true, the entire entitlement is considered used 
   *                         (e.g., NCD 100 qty → NCD Site License 1
   * @param ordItmToQty Stores the mapping of Order Item Id to the consumed Quantity
   * @param relatedQli Related Quoteline
   * @return List of RelatedInactiveEntitlement wrappers
   */
  public static List<PreviousTransRefWrapper.RelatedInactiveEntitlement> buildRelatedInactiveEntitlements(
    List<ReplacementJson.RelatedChildEntRowDetail> inactiveEntitlements,
    Boolean isMisMatchedFlag,
    Map<Id, Decimal> ordItmToQty,
    SBQQ__QuoteLine__c relatedQli
  ) {
    List<PreviousTransRefWrapper.RelatedInactiveEntitlement> relatedInactiveEnts = new List<PreviousTransRefWrapper.RelatedInactiveEntitlement>();

    for (ReplacementJson.RelatedChildEntRowDetail inactiveEnt : inactiveEntitlements) {
      if (String.isBlank(inactiveEnt.childEntId) || !allEntitlementsById.containsKey(inactiveEnt.childEntId)) {
        continue;
      }

      // Get the inactive child entitlement and compute used/remaining quantities
      Entitlement childInactiveEnt = allEntitlementsById.get(inactiveEnt.childEntId);
      // If mismatch, mark full entitlement as used; otherwise use provided child quantity (default 0 if null)
      Decimal childUsedQty = isMisMatchedFlag ? childInactiveEnt.Quantity__c : (inactiveEnt.childQnty == null) ? 0 : inactiveEnt.childQnty;
      // Remaining = max(Entitlement Qty − Used, 0); else 0 if mismatched, Renewal, or missing Order Item
      Decimal childRemainingQty = (!isMisMatchedFlag && relatedQli.Line_Type__c != 'Renewal' && ordItmToQty.containsKey(childInactiveEnt.Order_Service_Item__c)) &&
        childInactiveEnt.Order_Service_Item__r.Quantity >= ordItmToQty.get(childInactiveEnt.Order_Service_Item__c)
        ? Math.max(childInactiveEnt.Order_Service_Item__r.Quantity - ordItmToQty.get(childInactiveEnt.Order_Service_Item__c), 0)
        : 0;

      String orderNumber;
      if (childInactiveEnt.Order_Service_Item__r != null && childInactiveEnt.Order_Service_Item__r.Order != null) {
        orderNumber = childInactiveEnt.Order_Service_Item__r.Order.OrderNumber;
      }

      relatedInactiveEnts.add(
        new PreviousTransRefWrapper.RelatedInactiveEntitlement(childInactiveEnt.Id, childRemainingQty, childUsedQty, childInactiveEnt.Order_Service_Item__c, orderNumber)
      );
    }
    return relatedInactiveEnts;
  }
}