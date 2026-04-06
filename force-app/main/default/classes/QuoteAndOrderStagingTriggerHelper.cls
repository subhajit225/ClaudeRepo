public class QuoteAndOrderStagingTriggerHelper {
  // Constant for the RCDM transaction SKU name, fetched from custom metadata
  public static String RCDMTransSkuName = X0_RCDM_Dates__mdt.getInstance('RS_BT_RCDM_T')?.Product_Name__c;
  public static Map<Id, Quote_and_Order_Staging__c> quoteAndOrderStagingRecordsToCreate = new Map<Id, Quote_and_Order_Staging__c>();
  public static List<Id> rcdmEntitlementIdswithQuantityMismatch = new List<Id>();
  public static Set<Id> accountWithNoChildRecords = new Set<Id>();
  // Main method to process the Quote and Order Staging
  public static void QuoteAndOrderStagingMethod(Map<Id, Quote_and_Order_Staging__c> accountIdToQuoteAndStageObj) {
    for (Id Acctid : accountIdToQuoteAndStageObj.keyset()) {
      // adding all the account ids for now... will keep removing as we child Q&A staging records are created against the account
      accountWithNoChildRecords.add(Acctid);
    }
    // Maps to store various types of entitlements and related data
    Map<String, Entitlement> licenseEntitlementByOrderAndQtyKey = new Map<String, Entitlement>(); // license Entitlement with Order & Qty as key
    Map<String, Entitlement> rcdmtEntitlementByOrderAndQtyKey = new Map<String, Entitlement>(); // rcdmt w/o link but Order & Qty match
    Map<String, Entitlement> rcdmtEntitlementByLicenseAndOIKey = new Map<String, Entitlement>(); // rcdmt w/ link but license OI and own OI as key
    Map<String, SBQQ__QuoteLine__c> licenseQuoteLineByQliAndQtyAsKey = new Map<String, SBQQ__QuoteLine__c>();
    // Map to get the latest revenue order for each account
    Map<Id, Id> latesRevenueOrderIdByAccountId = new Map<Id, Id>();
    // Set to store quote IDs
    Set<Id> oldQuoteIds = new Set<Id>();

    getLatesRevenueOrderIdByAccountId(accountIdToQuoteAndStageObj.keyset(), latesRevenueOrderIdByAccountId);
    preventDuplicateRecordAgainstEachAccount(accountIdToQuoteAndStageObj);
    // Process entitlements and populate maps
    processEntitlements(
      accountIdToQuoteAndStageObj,
      licenseEntitlementByOrderAndQtyKey,
      rcdmtEntitlementByOrderAndQtyKey,
      rcdmtEntitlementByLicenseAndOIKey,
      oldQuoteIds,
      latesRevenueOrderIdByAccountId
    );
    // Process quote lines and populate map
    processQuoteLines(oldQuoteIds, licenseQuoteLineByQliAndQtyAsKey);
    // Process RCDM entitlements with linkage
    processRcdmtEntitlementsWithLinkage(
      rcdmtEntitlementByLicenseAndOIKey,
      accountIdToQuoteAndStageObj,
      latesRevenueOrderIdByAccountId,
      quoteAndOrderStagingRecordsToCreate
    );

    // Process RCDM entitlements without linkage
    processRcdmtEntitlementsWithoutLinkage(
      rcdmtEntitlementByOrderAndQtyKey,
      licenseEntitlementByOrderAndQtyKey,
      licenseQuoteLineByQliAndQtyAsKey,
      accountIdToQuoteAndStageObj,
      latesRevenueOrderIdByAccountId,
      quoteAndOrderStagingRecordsToCreate
    );

    // Update Quote and Order Staging objects
    updateQuoteAndOrderStaging(accountIdToQuoteAndStageObj, quoteAndOrderStagingRecordsToCreate);
  }

  private static void getLatesRevenueOrderIdByAccountId(set<Id> accountId, Map<Id, Id> latesRevenueOrderIdByAccountId) {
    if (!accountId.isEmpty()) {
      for (order ord : [
        SELECT id, accountId
        FROM order
        WHERE accountId IN :accountId AND type = 'Revenue' AND Order_Sub_Type__c = NULL AND Order_Status__c = 'Shipped'
        ORDER BY ActivatedDate DESC
      ]) {
        if (!latesRevenueOrderIdByAccountId.containskey(ord.accountId))
          latesRevenueOrderIdByAccountId.put(ord.accountId, ord.Id);
      }
    }
  }

  private static void preventDuplicateRecordAgainstEachAccount(Map<Id, Quote_and_Order_Staging__c> QuoteAndStagingRecordsMap) {
    Set<Id> avoidDuplicateRecordsForQuoteAndStagingRecords = new Set<Id>();
    Set<Id> storeAllAccountIfDuplicateFound = new Set<Id>();

    if (!QuoteAndStagingRecordsMap.isempty()) {
      for (Quote_and_Order_Staging__c quoteAndStagingResultFromQueryObj : [
        SELECT Id, Account_OM__c
        FROM Quote_and_Order_Staging__c
        WHERE Account_OM__c IN :QuoteAndStagingRecordsMap.keyset() AND Process_Type__c = :constants.RCDMT_EXT_INITIAL_PROCESS_TYPE
      ]) {
        if (quoteAndStagingResultFromQueryObj.Account_OM__c != null)
          storeAllAccountIfDuplicateFound.add(quoteAndStagingResultFromQueryObj.Account_OM__c);
      }
    }
    if (!storeAllAccountIfDuplicateFound.isempty()) {
      for (Quote_and_Order_Staging__c quoteAndStagingIterationObj : QuoteAndStagingRecordsMap.values()) {
        if (storeAllAccountIfDuplicateFound.contains(quoteAndStagingIterationObj.Account_OM__c)) {
          quoteAndStagingIterationObj.addError(constants.RCDMT_EXT_DUPLICATE_ACCOUNT_MESSAGE);
        }
      }
    }
  }

  // Method to process entitlements and populate maps
  private static void processEntitlements(
    Map<Id, Quote_and_Order_Staging__c> accountIdToQuoteAndStageObj,
    Map<String, Entitlement> licenseEntitlementByOrderAndQtyKey,
    Map<String, Entitlement> rcdmtEntitlementByOrderAndQtyKey,
    Map<String, Entitlement> rcdmtEntitlementByLicenseAndOIKey,
    Set<Id> oldQuoteIds,
    Map<Id, Id> latesRevenueOrderIdByAccountId
  ) {
    ShGl_DisableBusinessLogic__c businessLogic = ShGl_DisableBusinessLogic__c.getInstance();
    // Query to fetch entitlements
    for (Entitlement ett : [
      SELECT
        id,
        Order_Service_Item__r.orderId,
        Order_Service_Item__r.product2.Product_Level__c,
        Order_Service_Item__r.product2.Product_Subtype__c,
        Order_Service_Item__r.product2.Product_Type__c,
        EndDate,
        Order_Quantity__c,
        Order_Service_Item__r.SBQQ__RequiredBy__r.EndDate,
        Order_Service_Item__r.SBQQ__RequiredBy__r.quantity,
        AccountId,
        name,
        Order_Service_Item__r.product2.Family,
        Order_Service_Item__r.product2.name,
        Order_Service_Item__r.SBQQ__RequiredBy__c,
        Order_Service_Item__r.order.SBQQ__Quote__c,
        Order_Service_Item__r.order.orderNumber,
        ContractLineItemId
      FROM Entitlement
      WHERE
        type = 'Phone Support'
        AND Order_Service_Item__r.order.type = 'Revenue'
        AND Order_Service_Item__r.order.Order_Status__c = 'Shipped'
        AND AccountId IN :accountIdToQuoteAndStageObj.keySet()
        AND (Order_Service_Item__r.product2.Product_Level__c = :constants.RSC_LOD_PRODUCT_LEVEL
        OR Order_Service_Item__r.product2.Product_Level__c = :constants.RSC_HYBRID_PRODUCT_LEVEL
        OR (Order_Service_Item__r.product2.Product_Level__c = :constants.RSC_ONPREM_PRODUCT_LEVEL
        AND (Order_Service_Item__r.product2.Product_Type__c = :constants.RSC_FOUNDATION_PRODUCT_TYPE
        OR Order_Service_Item__r.product2.Product_Type__c = :constants.RSC_BUSINESS_PRODUCT_TYPE
        OR Order_Service_Item__r.product2.Product_Type__c = :constants.RSC_ENTERPRISE_PRODUCT_TYPE))
        OR Order_Service_Item__r.product2.name = :RCDMTransSkuName)
      ORDER BY CREATEDDATE DESC
    ]) {
      if (
        ett.Order_Service_Item__r.product2.name == RCDMTransSkuName &&
        businessLogic.Min_EndDate_to_Consider_for_RCDM_T_Ext__c != null &&
        ett.EndDate < businessLogic.Min_EndDate_to_Consider_for_RCDM_T_Ext__c
      ) {
        System.debug('outcome11a ' + ett.id + '--' + ett.EndDate);
        continue;
      }
      // Process each entitlement
      processEntitlement(ett, licenseEntitlementByOrderAndQtyKey, rcdmtEntitlementByOrderAndQtyKey, rcdmtEntitlementByLicenseAndOIKey, oldQuoteIds);
    }
    system.debug('size for rcdmtEntitlementByOrderAndQtyKey is #####  ' + rcdmtEntitlementByOrderAndQtyKey.size());
    system.debug('rcdmtEntitlementByLicenseAndOIKeyis #####  ' + rcdmtEntitlementByLicenseAndOIKey.size());
  }

  // Method to process individual entitlement and categorize them
  private static void processEntitlement(
    Entitlement ett,
    Map<String, Entitlement> licenseEntitlementByOrderAndQtyKey,
    Map<String, Entitlement> rcdmtEntitlementByOrderAndQtyKey,
    Map<String, Entitlement> rcdmtEntitlementByLicenseAndOIKey,
    Set<Id> oldQuoteIds
  ) {
    Boolean isLicenseSKU = isLicenseSKU(ett?.Order_Service_Item__r?.product2);

    // Add quote ID to the set
    oldQuoteIds.add(ett?.Order_Service_Item__r?.order.SBQQ__Quote__c);

    if (isLicenseSKU) {
      // Store license entitlements
      String key = ett.Order_Service_Item__r.order.orderNumber + '-' + ett.Order_Quantity__c;
      licenseEntitlementByOrderAndQtyKey.put(key, ett);
    }

    if (ett.Order_Service_Item__r.SBQQ__RequiredBy__c == null && ett.Order_Service_Item__r.product2.name == RCDMTransSkuName) {
      // Store RCDM entitlements without linkage
      String rcdmKey = ett.Order_Service_Item__r.order.orderNumber + '-' + ett.Order_Quantity__c;
      rcdmtEntitlementByOrderAndQtyKey.put(rcdmKey, ett);
    } else if (ett.Order_Service_Item__r.product2.name == RCDMTransSkuName) {
      // Store RCDM entitlements with linkage
      String anotherKey = ett.Order_Service_Item__r.SBQQ__RequiredBy__c + '-' + ett.Order_Service_Item__c;
      rcdmtEntitlementByLicenseAndOIKey.put(anotherKey, ett);
    }
  }

  // Method to check if a product is a license SKU
  private static Boolean isLicenseSKU(Product2 product) {
    return (product.Product_Level__c == constants.RSC_LOD_PRODUCT_LEVEL ||
    product.Product_Level__c == constants.RSC_HYBRID_PRODUCT_LEVEL ||
    (product.Product_Level__c == constants.RSC_ONPREM_PRODUCT_LEVEL &&
    (product.Product_Type__c == constants.RSC_FOUNDATION_PRODUCT_TYPE && product.Product_Type__c == constants.RSC_BUSINESS_PRODUCT_TYPE ||
    product.Product_Type__c == constants.RSC_ENTERPRISE_PRODUCT_TYPE)));
  }

  // Method to process quote lines and populate map
  private static void processQuoteLines(Set<Id> oldQuoteIds, Map<String, SBQQ__QuoteLine__c> licenseQuoteLineByQliAndQtyAsKey) {
    // Query to fetch quote lines
    for (SBQQ__QuoteLine__c quoteLine : [
      SELECT
        id,
        SBQQ__Product__r.Name,
        SBQQ__Product__r.Product_Level__c,
        SBQQ__Product__r.Product_Subtype__c,
        SBQQ__Product__r.Product_Type__c,
        SBQQ__RequiredBy__c,
        SBQQ__Product__r.Family,
        SBQQ__Quote__c,
        SBQQ__Quantity__c,
        SBQQ__EndDate__c
      FROM SBQQ__QuoteLine__c
      WHERE
        SBQQ__Quote__c IN :oldQuoteIds
        AND (SBQQ__Product__r.Product_Level__c = :constants.RSC_LOD_PRODUCT_LEVEL
        OR SBQQ__Product__r.Product_Level__c = :constants.RSC_HYBRID_PRODUCT_LEVEL
        OR (SBQQ__Product__r.Product_Level__c = :constants.RSC_ONPREM_PRODUCT_LEVEL
        AND (SBQQ__Product__r.Product_Type__c = :constants.RSC_FOUNDATION_PRODUCT_TYPE
        OR SBQQ__Product__r.Product_Type__c = :constants.RSC_BUSINESS_PRODUCT_TYPE
        OR SBQQ__Product__r.Product_Type__c = :constants.RSC_ENTERPRISE_PRODUCT_TYPE)))
    ]) {
      Boolean isLicenseSKU = isLicenseSKU(quoteLine?.SBQQ__Product__r);
      if (isLicenseSKU) {
        // Store RSC line from quote
        String key = quoteLine.SBQQ__Quote__c + '-' + quoteLine.SBQQ__Quantity__c;
        licenseQuoteLineByQliAndQtyAsKey.put(key, quoteLine);
      }
    }
  }

  // Method to process RCDM entitlements with linkage
  private static void processRcdmtEntitlementsWithLinkage(
    Map<String, Entitlement> rcdmtEntitlementByLicenseAndOIKey,
    Map<Id, Quote_and_Order_Staging__c> accountIdToQuoteAndStageObj,
    Map<Id, Id> latesRevenueOrderIdByAccountId,
    Map<Id, Quote_and_Order_Staging__c> quoteAndOrderStagingRecordsToCreate
  ) {
    for (String rcdmtOrderAndQtyKey : rcdmtEntitlementByLicenseAndOIKey.keySet()) {
      Entitlement rcdmtEntitlement = rcdmtEntitlementByLicenseAndOIKey.get(rcdmtOrderAndQtyKey);
      Date startDateForRCDMTExtension = rcdmtEntitlement?.EndDate?.addDays(1);
      Date extendRCDMTEndDateToConsider;
      Quote_and_Order_Staging__c parentQnOStagingRecord = accountIdToQuoteAndStageObj.containsKey(rcdmtEntitlement.AccountId)
        ? accountIdToQuoteAndStageObj.get(rcdmtEntitlement.AccountId)
        : null;
      if (parentQnOStagingRecord != null && rcdmtEntitlement.EndDate != null) {
        if (rcdmtEntitlement.EndDate != null && rcdmtEntitlement.EndDate < parentQnOStagingRecord.Processing_Date__c) {
          rcdmtEntitlement.StartDate = startDateForRCDMTExtension = parentQnOStagingRecord.Processing_Date__c;
        } else {
          rcdmtEntitlement.StartDate = startDateForRCDMTExtension = rcdmtEntitlement?.EndDate?.addDays(1);
        }
      }

      if (
        rcdmtEntitlement?.Order_Service_Item__r?.SBQQ__RequiredBy__r?.EndDate != null &&
        accountIdToQuoteAndStageObj.containsKey(rcdmtEntitlement.AccountId) &&
        rcdmtEntitlement?.Order_Service_Item__r?.SBQQ__RequiredBy__r?.EndDate <
        accountIdToQuoteAndStageObj?.get(rcdmtEntitlement.AccountId)?.EOL_EndDate__c
      ) {
        extendRCDMTEndDateToConsider = rcdmtEntitlement.Order_Service_Item__r.SBQQ__RequiredBy__r.EndDate;
      } else {
        extendRCDMTEndDateToConsider = accountIdToQuoteAndStageObj?.get(rcdmtEntitlement.AccountId)?.EOL_EndDate__c;
      }

      if (extendRCDMTEndDateToConsider != null) {
        accountWithNoChildRecords.remove(rcdmtEntitlement.AccountId);
        // Populate Quote and Order Staging object map
        quoteAndOrderStagingRecordsToCreate.put(
          rcdmtEntitlement.Id,
          new Quote_and_Order_Staging__c(
            Account_OM__c = rcdmtEntitlement.AccountId,
            Entitlement__c = rcdmtEntitlement.Id,
            Process_Type__c = Constants.RCDMT_EXT_LOAD_DATA_PROCESS_TYPE,
            Line_Item_Start_Date__c = startDateForRCDMTExtension,
            quantity__c = rcdmtEntitlement.Order_Quantity__c,
            Line_Item_End_Date__c = extendRCDMTEndDateToConsider,
            RSC_OrderItem__c = rcdmtEntitlement?.Order_Service_Item__r?.SBQQ__RequiredBy__c,
            Subsumed_Old_Contract_Line_Items__c = rcdmtEntitlement.ContractLineItemId,
            RenewedContractLine__c = rcdmtEntitlement.ContractLineItemId,
            Contract_Line_Item__c = rcdmtEntitlement.ContractLineItemId,
            Order__c = latesRevenueOrderIdByAccountId.get(rcdmtEntitlement.AccountId)
          )
        );
        if (rcdmtEntitlement.Order_Quantity__c != rcdmtEntitlement?.Order_Service_Item__r?.SBQQ__RequiredBy__r.quantity)
          rcdmEntitlementIdswithQuantityMismatch.add(rcdmtEntitlement.Id);
      }
    }
  }

  // Method to process RCDM entitlements without linkage
  private static void processRcdmtEntitlementsWithoutLinkage(
    Map<String, Entitlement> rcdmtEntitlementByOrderAndQtyKey,
    Map<String, Entitlement> licenseEntitlementByOrderAndQtyKey,
    Map<String, SBQQ__QuoteLine__c> licenseQuoteLineByQliAndQtyAsKey,
    Map<Id, Quote_and_Order_Staging__c> accountIdToQuoteAndStageObj,
    Map<Id, Id> latesRevenueOrderIdByAccountId,
    Map<Id, Quote_and_Order_Staging__c> quoteAndOrderStagingRecordsToCreate
  ) {
    system.debug('control is here' + rcdmtEntitlementByOrderAndQtyKey);
    for (String key : rcdmtEntitlementByOrderAndQtyKey.keySet()) {
      Entitlement rcdmtEntitlement = rcdmtEntitlementByOrderAndQtyKey.get(key);
      Date startDateForRCDMTExtension = rcdmtEntitlement.EndDate.addDays(1);
      Entitlement licenseEntitlement = licenseEntitlementByOrderAndQtyKey?.get(key);
      Date endDateOfLicenseQLI;
      Date extendRCDMTEndDateToConsider;
      Quote_and_Order_Staging__c parentQnOStagingRecord = accountIdToQuoteAndStageObj.containsKey(rcdmtEntitlement.AccountId)
        ? accountIdToQuoteAndStageObj.get(rcdmtEntitlement.AccountId)
        : null;
      if (parentQnOStagingRecord != null && rcdmtEntitlement.EndDate != null) {
        if (rcdmtEntitlement.EndDate != null && rcdmtEntitlement.EndDate < parentQnOStagingRecord.Processing_Date__c) {
          rcdmtEntitlement.StartDate = startDateForRCDMTExtension = parentQnOStagingRecord.Processing_Date__c;
        } else {
          rcdmtEntitlement.StartDate = startDateForRCDMTExtension = rcdmtEntitlement.EndDate.addDays(1);
        }
      }
      // When We have extra RCDM With
      // No Matching Licence Based on Qty then check in Quote/QuoteLine
      //  If we there is any matching Licence
      if (rcdmtEntitlement != null) {
        String quoteLineKey = rcdmtEntitlement?.Order_Service_Item__r?.order.SBQQ__Quote__c + '-' + rcdmtEntitlement.Order_Quantity__c;
        if (licenseEntitlement == null) {
          endDateOfLicenseQLI = licenseQuoteLineByQliAndQtyAsKey.containsKey(quoteLineKey)
            ? licenseQuoteLineByQliAndQtyAsKey?.get(quoteLineKey)?.SBQQ__EndDate__c
            : null;
        } else {
          endDateOfLicenseQLI = licenseEntitlement.EndDate;
        }

        if (
          AccountIdToQuoteAndStageObj.containskey(rcdmtEntitlement.AccountId) &&
          endDateOfLicenseQLI != null &&
          endDateOfLicenseQLI < AccountIdToQuoteAndStageObj.get(rcdmtEntitlement.AccountId).EOL_EndDate__c
        ) {
          extendRCDMTEndDateToConsider = endDateOfLicenseQLI;
        } else {
          extendRCDMTEndDateToConsider = AccountIdToQuoteAndStageObj?.get(rcdmtEntitlement.AccountId)?.EOL_EndDate__c;
        }
      }

      if (extendRCDMTEndDateToConsider != null) {
        accountWithNoChildRecords.remove(rcdmtEntitlement.AccountId);
        // Populate Quote and Order Staging object map
        quoteAndOrderStagingRecordsToCreate.put(
          rcdmtEntitlement.Id,
          new Quote_and_Order_Staging__c(
            Account_OM__c = rcdmtEntitlement.AccountId,
            Entitlement__c = rcdmtEntitlement.Id,
            Process_Type__c = Constants.RCDMT_EXT_LOAD_DATA_PROCESS_TYPE,
            Line_Item_Start_Date__c = startDateForRCDMTExtension,
            quantity__c = rcdmtEntitlement.Order_Quantity__c,
            Line_Item_End_Date__c = extendRCDMTEndDateToConsider,
            Subsumed_Old_Contract_Line_Items__c = rcdmtEntitlement.ContractLineItemId,
            RenewedContractLine__c = rcdmtEntitlement.ContractLineItemId,
            Contract_Line_Item__c = rcdmtEntitlement.ContractLineItemId,
            RSC_OrderItem__c = (licenseEntitlement != null) ? licenseEntitlement.Order_Service_Item__c : null,
            Order__c = latesRevenueOrderIdByAccountId.get(rcdmtEntitlement.AccountId)
          )
        );
        //if(rcdmtEntitlement.Order_Quantity__c==licenseEntitlement.Order_Quantity__c)
        if (rcdmtEntitlement != null && licenseEntitlement != null && rcdmtEntitlement.Order_Quantity__c != licenseEntitlement.Order_Quantity__c)
          rcdmEntitlementIdswithQuantityMismatch.add(rcdmtEntitlement.Id);
      }
    }
  }

  // Method to update Quote and Order Staging objects
  private static void updateQuoteAndOrderStaging(
    Map<Id, Quote_and_Order_Staging__c> accountIdToQuoteAndStageObj,
    Map<Id, Quote_and_Order_Staging__c> quoteAndOrderStagingRecordsToCreate
  ) {
    Map<Id, Boolean> accountIdToVerificationStatus = new Map<Id, Boolean>();

    if (!quoteAndOrderStagingRecordsToCreate.isEmpty()) {
      for (Quote_and_Order_Staging__c quoteStagingObj : quoteAndOrderStagingRecordsToCreate.values()) {
        if (accountIdToQuoteAndStageObj.containsKey(quoteStagingObj.Account_OM__c)) {
          if (isCompleteStagingObject(quoteStagingObj) && !rcdmEntitlementIdswithQuantityMismatch.contains(quoteStagingObj.Entitlement__c)) {
            quoteStagingObj.Process_Status_OM__c = Constants.RCDMT_EXT_READY_PROCESS_STATUS;
          } else {
            accountIdToVerificationStatus.put(quoteStagingObj.Account_OM__c, true);
            quoteStagingObj.Process_Status_OM__c = Constants.RCDMT_EXT_VERIFICATION_PROCESS_STATUS;
          }
        }
      }
    }
    // Update parent staging objects
    if (accountIdToQuoteAndStageObj != null || accountIdToVerificationStatus != null) {
      updateParentStagingObjects(accountIdToQuoteAndStageObj, accountIdToVerificationStatus);
    }
  }

  // Method to check if a staging object is complete
  private static Boolean isCompleteStagingObject(Quote_and_Order_Staging__c quoteStagingObj) {
    return quoteStagingObj.Contract_Line_Item__c != null &&
      quoteStagingObj.Order__c != null &&
      quoteStagingObj.RSC_OrderItem__c != null &&
      quoteStagingObj.Entitlement__c != null &&
      quoteStagingObj.Line_Item_Start_Date__c != null &&
      quoteStagingObj.Line_Item_End_Date__c != null &&
      quoteStagingObj.Subsumed_Old_Contract_Line_Items__c != null &&
      quoteStagingObj.RenewedContractLine__c != null &&
      quoteStagingObj.Quantity__c != null &&
      quoteStagingObj.Line_Item_Start_Date__c < quoteStagingObj.Line_Item_End_Date__c;
  }

  // Method to update parent staging objects
  private static void updateParentStagingObjects(
    Map<Id, Quote_and_Order_Staging__c> accountIdToQuoteAndStageObj,
    Map<Id, Boolean> accountIdToVerificationStatus
  ) {
    for (Id accountId : accountIdToQuoteAndStageObj.keySet()) {
      Quote_and_Order_Staging__c parentStagingObj = accountIdToQuoteAndStageObj.get(accountId);
      system.debug('accountWithNoChildRecords is ###' + accountWithNoChildRecords);
      if (
        (!accountIdToVerificationStatus.isEmpty() &&
        accountIdToVerificationStatus.containsKey(accountId) &&
        accountIdToVerificationStatus.get(accountId)) || (!accountWithNoChildRecords.isempty() && accountWithNoChildRecords.contains(accountId))
      ) {
        parentStagingObj.Process_Status_OM__c = Constants.RCDMT_EXT_VERIFICATION_PROCESS_STATUS;
      } else {
        parentStagingObj.Process_Status_OM__c = Constants.RCDMT_EXT_READY_PROCESS_STATUS;
      }
    }
  }

  public static void loadAllQuoteAndStagingOrderAfterInsert() {
    if (!quoteAndOrderStagingRecordsToCreate.isempty()) {
      system.debug('quoteAndOrderStagingRecordsToCreate is ' + quoteAndOrderStagingRecordsToCreate);
      TriggerControl.stopQuoteAndOrderStagingTrigger = true;
      insert quoteAndOrderStagingRecordsToCreate.values();
      TriggerControl.stopQuoteAndOrderStagingTrigger = false;
    }
  }
}