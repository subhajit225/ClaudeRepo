/**
 * Description: This schedulable batch set the Eligible for Free HW field on the Asset based on the following conditions
 *              Product_Subtype__c = 'GO' or 'GO CNV'
 *              Product_Type__c != 'HW Support'
 *              Order Type = 'Revenue'
 *              Product Name does not contains 'NODE'
 *              Subscription Term >= 36
 *              End Date does not exceeds 90 days
 *
 * Author:      Shahroz Beig
 * Date:        December 14, 2022
 */
public class AssetSetEligibleFreeHWBatch implements Database.Batchable<sObject>, Schedulable, Database.Stateful {
  static Set<Id> assetIdsAlreadyProcessed = new Set<Id>();
  Date currentDate = System.today();
  String refreshedProgram = Constants.PROGRAM_REFRESHED;
  String productFamliyR6K = Constants.PRODUCT_FAMILY_R6000;
  @testVisible
  Boolean shouldThowException = false;
  Id entitlementIdToProcess;

  Map<String, Date> disqAstSNvsExpDtMap = new Map<String, Date>(); //MS CPQ22-3092
  Set<Id> accIdsSet = new Set<Id>(); //MS CPQ22-3092

  public AssetSetEligibleFreeHWBatch() {
  }

  /**
   * Constructor overloading to run it for specific record when needed
   */
  public AssetSetEligibleFreeHWBatch(Id entitlementId) {
    entitlementIdToProcess = entitlementId;
  }

  public Database.QueryLocator start(Database.BatchableContext batchContext) {
    String query =
      'SELECT ' +
      ' Id, ' +
      ' Asset.ProductCode, ' +
      ' Name, ' +
      ' StartDate, ' +
      ' EndDate, ' +
      ' Entitlement_Status__c, ' +
      ' Subscription_Term__c, ' +
      ' AssetId, ' +
      ' Asset.Name, ' +
      ' Asset.AccountId, ' +
      ' Asset.Account.name, ' +
      ' Asset.PurchaseDate, ' +
      ' Asset.Premium_Support_End_Date__c, ' +
      ' Asset.SBQQ__OrderProduct__r.Order.OrderNumber, ' +
      ' Asset.Free_HW_Refresh_Forfeited__c, ' +
      ' Asset.Eligible_for_Free_HW__c, ' +
      ' Asset.Order_Number__c, ' +
      ' Asset.Expiration_Date__c, ' +
      ' Asset.Product2.Family, ' +
      ' Asset.Program__c, ' +
      ' Asset.Order_Service_Item__r.Order.OrderNumber, ' +
      ' Order_Service_Item__r.Order.Type, ' +
      ' Order_Service_Item__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.Product2.Product_Subtype__c, ' +
      ' Order_Service_Item__r.Order.OrderNumber, ' +
      ' Order_Service_Item__r.Product2.Product_Subtype__c, ' +
      ' Product__r.Product_Level__c, ' +
      ' Product__r.Edition__c ' +
      ' FROM Entitlement ';

    // if needed, execute it for a single record by passing the Id of the entitlement
    if (entitlementIdToProcess != null) {
      query += ' WHERE Id = :entitlementIdToProcess';
    } else {
      query +=
        ' WHERE ' +
        '  (Order_Service_Item__r.order.Type IN (\'Revenue\')' +
        '  AND Order_Service_Item__r.Product2.Product_Subtype__c IN (\'GO CNV\', \'GO\')' +
        '  AND Order_Service_Item__r.Product2.Product_Type__c != \'HW Support\'' +
        '  AND Asset.Eligible_for_Free_HW__c != \'Disqualified\'' +
        '  AND Asset.Eligible_for_Free_HW__c != \'Disqualified - Manual\'' +
        '  AND Asset.Eligible_for_Free_HW__c != \'Expired\'' +
        '  AND Asset.Eligible_for_Free_HW__c != \'Expired - Manual\'' +
        '  AND (NOT Name LIKE \'%NODE%\')) ' +
        '  OR (AssetId != null ' +
        '  AND Asset.Product2.Family = :productFamliyR6K' +
        '  AND Asset.Program__c = :refreshedProgram' +
        '  AND EndDate <= :currentDate)' +
        '  ORDER BY CreatedDate ASC';
    }
    return Database.getQueryLocator(query);
  }

  public void execute(Database.BatchableContext batchContext, List<Entitlement> entitlements) {
    Map<Id, Asset> assetsToUpdate = new Map<Id, Asset>();
    Date effAssetExpiryDt = Date.valueOf(System.Label.Effective_Asset_Expiry_Date);
    List<Id> assetIds = new List<Id>();
    Set<Id> expiredAssetIds = new Set<Id>();
    Map<Id, Id> expiredEntitlementIdToAssetId = new Map<Id, Id>();
    for (Entitlement anEntitlement : entitlements) {
      assetIds.add(anEntitlement.AssetId);
      String prodFamily = anEntitlement?.Asset?.Product2?.Family;
      if (
        anEntitlement.EndDate != null &&
        anEntitlement.EndDate <= currentDate &&
        prodFamily == Constants.PRODUCT_FAMILY_R6000 &&
        anEntitlement.Asset.Program__c == Constants.PROGRAM_REFRESHED
      ) {
        expiredAssetIds.add(anEntitlement.AssetId);
        if (isV1LicenseEntitlement(anEntitlement)) {
          expiredEntitlementIdToAssetId.put(anEntitlement.Id, anEntitlement.AssetId);
        }
      }
    }
    if (!expiredAssetIds.isEmpty()) {
      fetchDecomissionedAssets(expiredAssetIds, assetsToUpdate, expiredEntitlementIdToAssetId);
    }

    Map<Id, Id> initialEntitlementByAssetId = new Map<Id, id>(); // Stores the initial entitlement associated with the Asset
    for (Asset anAsset : [
      SELECT
        Id,
        (
          SELECT Id, EndDate
          FROM Entitlements
          WHERE
            Order_Service_Item__r.order.Type IN ('Revenue')
            AND Order_Service_Item__r.Product2.Product_Subtype__c IN ('GO CNV', 'GO')
            AND Order_Service_Item__r.Product2.Product_Type__c != 'HW Support'
            AND Asset.Eligible_for_Free_HW__c != 'Disqualified'
            AND Asset.Eligible_for_Free_HW__c != 'Disqualified - Manual'
            AND Asset.Eligible_for_Free_HW__c != 'Expired'
            AND Asset.Eligible_for_Free_HW__c != 'Expired - Manual'
            AND (NOT Name LIKE '%NODE%')
          ORDER BY Createddate ASC
          LIMIT 1
        )
      FROM Asset
      WHERE Id IN :assetIds
    ]) {
      if (!initialEntitlementByAssetId.containsKey(anAsset.Id) && anAsset.Entitlements != null && !anAsset.Entitlements.isEmpty()) {
        initialEntitlementByAssetId.put(anAsset.Id, anAsset.Entitlements[0].id);
      }
    }

    Map<Id, Entitlement> latestEntitlementByAssetId = new Map<Id, Entitlement>(); // Stores the latest entitlement associated with the Asset
    Map<Id, Scale_Entitlement__c> latestLinkedEntitlementByAssetId = new Map<Id, Scale_Entitlement__c>();
    for (Asset anAsset : [
      SELECT
        Id,
        (
          SELECT Id, EndDate
          FROM Entitlements
          WHERE
            Order_Service_Item__r.order.Type IN ('Revenue')
            AND Order_Service_Item__r.Product2.Product_Subtype__c IN ('GO CNV', 'GO')
            AND Order_Service_Item__r.Product2.Product_Type__c != 'HW Support'
            AND Asset.Eligible_for_Free_HW__c != 'Disqualified'
            AND Asset.Eligible_for_Free_HW__c != 'Disqualified - Manual'
            AND Asset.Eligible_for_Free_HW__c != 'Expired'
            AND Asset.Eligible_for_Free_HW__c != 'Expired - Manual'
            AND (NOT Name LIKE '%NODE%')
          ORDER BY Enddate DESC
          LIMIT 1
        ),
        (SELECT id, Entitlement__r.enddate, Entitlement__r.createddate FROM Scale_Assets__r ORDER BY Entitlement__r.enddate DESC LIMIT 1)
      FROM Asset
      WHERE Id IN :assetIds
    ]) {
      if (!latestEntitlementByAssetId.containsKey(anAsset.Id) && anAsset.Entitlements != null && !anAsset.Entitlements.isEmpty()) {
        latestEntitlementByAssetId.put(anAsset.Id, anAsset.Entitlements[0]);
      }
      if (!latestLinkedEntitlementByAssetId.containsKey(anAsset.Id) && anAsset.Scale_Assets__r != null && !anAsset.Scale_Assets__r.isEmpty()) {
        latestLinkedEntitlementByAssetId.put(anAsset.Id, anAsset.Scale_Assets__r[0]);
      }
    }

    for (Entitlement entitlement : entitlements) {
      if (isEligible(entitlement, assetIdsAlreadyProcessed, initialEntitlementByAssetId) && !Label.Unassigned_Account_Id.contains(entitlement.Asset.AccountId)) {
        if (
          String.isNotBlank(entitlement.AssetId) &&
          !assetIdsAlreadyProcessed.contains(entitlement.AssetId) &&
          entitlement.Asset.Expiration_Date__c != null &&
          entitlement.Asset.Expiration_Date__c <= System.today() &&
          !entitlement.Asset.Free_HW_Refresh_Forfeited__c
        ) {
          if (!assetsToUpdate.containskey(entitlement.AssetId)) {
            assetsToUpdate.put(entitlement.AssetId, new Asset(Id = entitlement.AssetId, Eligible_for_Free_HW__c = 'Expired'));
          } else {
            assetsToUpdate.get(entitlement.AssetId).Eligible_for_Free_HW__c = 'Expired';
          }

          /*********** MS CPQ22-3092 ************/
          //disqAstSNvsAccMap.put(entitlement.Asset.Name, entitlement.Asset.AccountId);
          disqAstSNvsExpDtMap.put(entitlement.Asset.Name, entitlement.Asset.Expiration_Date__c);
          accIdsSet.add(entitlement.Asset.AccountId);
          System.debug(LoggingLevel.INFO, 'MS Collecting Assets SNs for InvalidateQuoteBatch SN = ' + entitlement.Asset.Name);
          /*********** MS CPQ22-3092 ************/
        } else {
          if (
            String.isNotBlank(entitlement.AssetId) &&
            !assetIdsAlreadyProcessed.contains(entitlement.AssetId) &&
            entitlement.Asset.Expiration_Date__c != null &&
            entitlement.Asset.Expiration_Date__c <= System.today() &&
            entitlement.Asset.Free_HW_Refresh_Forfeited__c
          ) {
            /*********** MS CPQ22-3092 ************/
            disqAstSNvsExpDtMap.put(entitlement.Asset.Name, entitlement.Asset.Expiration_Date__c);
            accIdsSet.add(entitlement.Asset.AccountId);
            System.debug(LoggingLevel.INFO, 'MS Collecting Assets SNs Forfeited is true for SN = ' + entitlement.Asset.Name);
            /*********** MS CPQ22-3092 ************/
          }
          if (
            String.isNotBlank(entitlement.AssetId) &&
            !assetIdsAlreadyProcessed.contains(entitlement.AssetId) &&
            (latestEntitlementByAssetId.containsKey(entitlement.AssetId) &&
            latestEntitlementByAssetId.get(entitlement.AssetId) != null &&
            latestEntitlementByAssetId.get(entitlement.AssetId).EndDate <= Date.today() &&
            latestEntitlementByAssetId.get(entitlement.AssetId).EndDate.daysBetween(Date.today()) >= 90) &&
            (!entitlement.Asset.Free_HW_Refresh_Forfeited__c || (entitlement.Asset.Free_HW_Refresh_Forfeited__c && entitlement.Asset.Expiration_Date__c == null)) &&
            (!latestLinkedEntitlementByAssetId.containsKey(entitlement.AssetId) ||
            (latestLinkedEntitlementByAssetId.containsKey(entitlement.AssetId) &&
            latestLinkedEntitlementByAssetId.get(entitlement.AssetId) != null &&
            latestLinkedEntitlementByAssetId.get(entitlement.AssetId).Entitlement__r != null &&
            latestLinkedEntitlementByAssetId.get(entitlement.AssetId).Entitlement__r.enddate <= Date.today() &&
            latestLinkedEntitlementByAssetId.get(entitlement.AssetId).Entitlement__r.enddate.daysBetween(Date.today()) >= 90))
          ) {
            if (!assetsToUpdate.containskey(entitlement.AssetId)) {
              assetsToUpdate.put(entitlement.AssetId, new Asset(Id = entitlement.AssetId, Eligible_for_Free_HW__c = 'Disqualified'));
            } else {
              assetsToUpdate.get(entitlement.AssetId).Eligible_for_Free_HW__c = 'Disqualified';
            }
          } else if (entitlement.Asset.Eligible_for_Free_HW__c != 'True' && entitlement.Asset.Eligible_for_Free_HW__c != 'True - Manual') {
            if (!assetsToUpdate.containskey(entitlement.AssetId)) {
              assetsToUpdate.put(entitlement.AssetId, new Asset(Id = entitlement.AssetId, Eligible_for_Free_HW__c = 'True'));
            } else {
              assetsToUpdate.get(entitlement.AssetId).Eligible_for_Free_HW__c = 'True';
            }
          }
          if (
            String.isNotBlank(entitlement.AssetId) &&
            entitlement.Asset.Expiration_Date__c == null &&
            (latestEntitlementByAssetId.get(entitlement.AssetId)?.EndDate > effAssetExpiryDt ||
            latestLinkedEntitlementByAssetId.get(entitlement.AssetId)?.Entitlement__r?.enddate > effAssetExpiryDt)
          ) {
            date maxDate;
            if (latestEntitlementByAssetId.get(entitlement.AssetId)?.EndDate != null && latestLinkedEntitlementByAssetId.get(entitlement.AssetId)?.Entitlement__r?.enddate != null)
              maxDate = latestEntitlementByAssetId.get(entitlement.AssetId)?.EndDate > latestLinkedEntitlementByAssetId.get(entitlement.AssetId)?.Entitlement__r?.enddate
                ? latestEntitlementByAssetId.get(entitlement.AssetId)?.EndDate
                : latestLinkedEntitlementByAssetId.get(entitlement.AssetId)?.Entitlement__r?.enddate;
            else
              maxDate = latestEntitlementByAssetId.get(entitlement.AssetId)?.EndDate == null
                ? latestLinkedEntitlementByAssetId.get(entitlement.AssetId)?.Entitlement__r?.enddate
                : latestEntitlementByAssetId.get(entitlement.AssetId)?.EndDate;
            if (maxDate != null) {
              if (!assetsToUpdate.containskey(entitlement.AssetId)) {
                assetsToUpdate.put(entitlement.AssetId, new Asset(Id = entitlement.AssetId, Expiration_Date__c = maxDate.addDays(90)));
              } else {
                assetsToUpdate.get(entitlement.AssetId).Expiration_Date__c = maxDate.addDays(90);
              }
            }
          }
        }
        assetIdsAlreadyProcessed.add(entitlement.AssetId);
      }
    }

    try {
      if (shouldThowException == true) {
        throw new DMLException('My DML EXCEPTION');
      }
      List<Error_Logs__c> errorLogs = new List<Error_Logs__c>();
      if (!assetsToUpdate.values().isEmpty()) {
        Database.SaveResult[] assetUpdateResults = Database.update(assetsToUpdate.values(), false);
        for (Database.SaveResult assetUpdateResult : assetUpdateResults) {
          if (!assetUpdateResult.isSuccess()) {
            assetIdsAlreadyProcessed.remove(assetUpdateResult.getId());
            Database.Error err = assetUpdateResult.getErrors()[0];
            errorLogs.add(
              createErrorLog(
                'AssetSetEligibleFreeHWBatch - Error while setting Eligible for Free HW field on an Asset',
                err.getMessage() + '\r\n' + err.getFields() + '\r\n' + 'Asset ID: ' + assetUpdateResult.getId(),
                assetUpdateResult.getId()
              )
            );
          }
        }
      }

      if (!errorLogs.isEmpty()) {
        insert errorLogs;
      }
    } catch (Exception ex) {
      insert createErrorLog(
        'AssetSetEligibleFreeHWBatch - Error in the batch while setting Eligible for Free HW field',
        ex.getMessage() + '\r\n' + ex.getStackTraceString() + '\r\n' + 'Asset IDs are: ' + String.join(assetsToUpdate.values(), ','),
        null
      );
    }
  }
  /**
   * @description This method verifies if Entitlement Product is a V1 License
   * @param entRec Entitlement Record where Product details are associated and verify if that Product is V1 SKU
   * @return Boolean if Product is V1 License returns true.
   */
  public Boolean isV1LicenseEntitlement(Entitlement entRec) {
    return UtilityClass.isV1LicenseProduct(entRec.Product__r);
  }
  /**
   * @description	This method is used to find Assets with R7000 Product Family and updates related R6000
   * Assets Status as Decomissioned
   * @param expiredAssetIds AssetIds whose EndDate is Passed and Product Family as R6000
   * @param assetsToUpdate  Holds asset records whose status needs to be updated
   * @author Siva Kumar
   * @last modified on  : 28-04-2025
   */
  public void fetchDecomissionedAssets(Set<Id> expiredAssetIds, Map<Id, Asset> assetsToUpdate, Map<Id, Id> expiredEntitlementIdToAssetId) {
    Map<Id, Set<Id>> entIdToAssetIds = new Map<Id, Set<Id>>();
    Set<Id> assetIdsToDecomission = new Set<Id>();
    //For V2 SKU's check if it has old scale Entitlements
    for (Scale_Entitlement__c scaleEnt : [
      SELECT Id, Asset__c, Entitlement__c, Entitlement__r.EndDate
      FROM Scale_Entitlement__c
      WHERE
        Asset__c IN :expiredAssetIds
        AND Asset__r.Program__c = :Constants.PROGRAM_REFRESHED
        AND Renewal_Category__c = :Constants.SCALE_ENT_RENEWAL_CATEGORY_REFRESHED
        AND Asset__r.Status != :Constants.ASSET_STATUS_DECOMMISSIONED
      ORDER BY Entitlement__r.EndDate DESC
    ]) {
      // Scaled Entitlements
      if (!entIdToAssetIds.containsKey(scaleEnt.Entitlement__c)) {
        entIdToAssetIds.put(scaleEnt.Entitlement__c, new Set<Id>());
      }
      entIdToAssetIds.get(scaleEnt.Entitlement__c).add(scaleEnt.Asset__c);
    }

    for (AggregateResult aggRes : [
      SELECT Entitlement__c EntId, count(Id) recCount
      FROM Scale_Entitlement__c
      WHERE
        (Entitlement__c IN :entIdToAssetIds.keySet()
        OR Entitlement__c IN :expiredEntitlementIdToAssetId.keyset())
        AND Asset__r.Product2.Family = :Constants.PRODUCT_FAMILY_R7000
      GROUP BY Entitlement__c
    ]) {
      //Linked Assets
      Id entId = (Id) aggRes.get('EntId');
      if (entIdToAssetIds.containsKey(entId)) {
        assetIdsToDecomission.addAll(entIdToAssetIds.get(entId));
      }
      if (expiredEntitlementIdToAssetId.containsKey(entId)) {
        assetIdsToDecomission.add(expiredEntitlementIdToAssetId.get(entId));
      }
    }
    //Remove AssetId from assetIdsToDecomission if AssetId in set has atleast one active EntitlementAdd commentMore actions
    for (AggregateResult aggRes : [
      SELECT count(Id), AssetId assetId
      FROM Entitlement
      WHERE Status = :Constants.ENT_STATUS_ACTIVE AND AssetId IN :assetIdsToDecomission
      GROUP BY AssetId
    ]) {
      Id activeAssetId = (Id) aggRes.get('assetId');
      if (assetIdsToDecomission.contains(activeAssetId)) {
        assetIdsToDecomission.remove(activeAssetId);
      }
    }
    for (Id assetRecId : assetIdsToDecomission) {
      assetsToUpdate.put(assetRecId, new Asset(Id = assetRecId, Status = Constants.ASSET_STATUS_DECOMMISSIONED));
    }
  }
  public void finish(Database.BatchableContext batchContext) {
    System.debug(LoggingLevel.INFO, 'AssetSetEligibleFreeHWBatch () , Completed.');

    /************** MS CPQ22-3092 **************/

    InvalidateQuoteBatch invlQtBatch = new InvalidateQuoteBatch(disqAstSNvsExpDtMap, accIdsSet);
    Database.executeBatch(invlQtBatch);
    System.debug(LoggingLevel.INFO, 'InvalidateQuoteBatch () , Executed from AssetSetEligibleFreeHWBatch.');

    /************** MS CPQ22-3092 **************/
  }

  public void execute(SchedulableContext scheduledContext) {
    AssetSetEligibleFreeHWBatch setEligibleForFreeHwFlagBatch = new AssetSetEligibleFreeHWBatch();
    Database.executeBatch(setEligibleForFreeHwFlagBatch, 20);
  }

  /**
   * This method checks the condition whether an asset is eligible for updating the Eligible For Free HW field
   * If it returns true then other conditions are checked whether the End Date has 90 days or not.
   * If it return false then the record are skipped from the updates
   */
  private static Boolean isEligible(Entitlement entitlement, Set<Id> assetIdsAlreadyProcessed, Map<Id, Id> initialEntitlementByAssetId) {
    if (
      (entitlement.StartDate.daysBetween(entitlement.EndDate) >= 1095 ||
      entitlement.Subscription_Term__c >= 36) &&
      initialEntitlementByAssetId.get(entitlement.AssetId) == entitlement.id &&
      String.isNotBlank(entitlement.AssetId) &&
      !assetIdsAlreadyProcessed.contains(entitlement.AssetId) &&
      (entitlement.Order_Service_Item__r.Product2.Product_Subtype__c == 'GO' ||
      entitlement.Order_Service_Item__r.Product2.Product_Subtype__c == 'GO CNV')
    ) {
      return true;
    }
    return false;
  }

  private static Error_Logs__c createErrorLog(String errorType, String message, String recordId) {
    return new Error_Logs__c(Error_Type__c = errorType, Error_Message__c = message, Type__c = 'SFDC', Object__c = 'Asset', RecordId__c = recordId);
  }
}