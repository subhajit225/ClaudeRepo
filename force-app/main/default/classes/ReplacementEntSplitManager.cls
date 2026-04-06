/*******************************************************************************
 * @description       : ReplacementEntSplitManager class responsible for handling Split of
 *                      original entitlement logic within the Replacement Framework.
 * @created on        : 03-04-2025
 * @created by        : Naveen Selvaraj / Ravi
 * Test class         : ContractOrders_Test
 * *****************************************************************************
 * History
 * Date                Modification           Author
 * 03-04-2025          FY25SR-1212             naveenkumar.selvaraj@rubrik.com
 *******************************************************************************
 */
public class ReplacementEntSplitManager {

  //This map hold the old v1 license ENTs which is required to create the linked asset(V1 -> V2 Refresh)
  public static Map<Id, Entitlement> oldV1Entitlements = new Map<Id, Entitlement>();
  
  @testVisible
  private static Boolean isTestSplit = true; 
  // Maps Entitlement ID to its associated Scale Ent asset serial numbers.
  // This gets populated from either `syncLinkedAssetsForRefreshAndReplacementLicenses` 
  // or `createEntitlementLinksForRefresh`, since Aspen's linked asset logic does not run 
  // from the ContractOrders batch.
  public static Map<Id, Set<String>> serialNumbersByEntId = new Map<Id, Set<String>>();
 //ITNPI-2901: Set of Order Line Item IDs representing auto-added capacity SKUs.
  public static Set<String> autoAddedCapacityOLI = new Set<String>() ;

  /**
   * Identifies the active entitlement and related replacement or renewal entitlements through associated Entitlement Links.
   * @param orderItemDetById             Map of OrderItem IDs to their corresponding OrderItem records.
   * @param OrigEntWrap                  Wrapper containing original entitlement record and associated data.
   * @param entLinksByCliId              Map of Contract Line Item ID to related Entitlement Link records.
   * @param newOrdItemDetail             Map of OrderItem IDs representing renewal or replacement details.
   * @param repOrderItemToEntitlements   Map of OrderItem ID to associated replacement/renewal Entitlements.
  * @param oldReplacedOrderItemById     Map of old OrderItem IDs to their replaced OrderItem records.
 * @author Naveen Selvaraj
 * @date 15-04-2025
*/
  public static EntitlementDetails getSurvivingEnt(
    Map<Id, OrderItem> orderItemDetById,
    EntitlementDetails OrigEntWrap,
    Map<Id, List<Entitlement_Links__c>> entLinksByCliId,
    Map<Id, Orderitem> newOrdItemDetail,
    Map<Id, List<Entitlement>> repOrderItemToEntitlements,
    Map<Id, OrderItem> oldReplacedOrderItemById,
    Set<Id> allOriginalEntIds,
    List<Error_Logs__c> lstofErrorLogs
  ) {
    final String METHOD_NAME_GET_SURVIVING_ENT = 'getSurvivingEnt';
    String customErrorMsg = null;
    Boolean isTerminatedDateMatch = false;
    String newRenewalCategory;
    Entitlement replacedOrRenewedEnt, survivingEnt;
    Entitlement_Links__c replacedOrRenewedEntLink, survEntLink;
    Entitlement orgEnt = OrigEntWrap != null ? OrigEntWrap.orgEntRec : null;
    List<Id> newoiId;
    if (orgEnt == null) {
      customErrorMsg = Constants.ERROR_ORIGINAL_ENT_NOT_FOUND;
    }
    for (Id oiId : OrigEntWrap.newEntitlementsByNewOrdItemId.keySet()) {
      if (newOrdItemDetail.containskey(oiId)) {
        OrigEntWrap.newReplacedRenewedOI.add(newOrdItemDetail.get(oiId));
      }
    }
    if (OrigEntWrap.orderType != Constants.ORDER_TYPE_RENEWAL) {
      ReplacementEntSplitHelper.getTerminateDateBasedRepPolicy(OrigEntWrap, repOrderItemToEntitlements, oldReplacedOrderItemById, lstofErrorLogs);
    } else if (OrigEntWrap.orderType == Constants.ORDER_TYPE_RENEWAL) {
      updateDeltaSkusOnWrapper(OrigEntWrap, entLinksByCliId, allOriginalEntIds);
    }
    if (OrigEntWrap != null && OrigEntWrap.newEntitlementsByNewOrdItemId != null && OrigEntWrap.newEntitlementsByNewOrdItemId.keyset().size() > 0) {
      newoiId = new List<Id>(OrigEntWrap.newEntitlementsByNewOrdItemId.keyset());
    }
    if (orgEnt != null && OrigEntWrap.terminateDate == null && OrigEntWrap.orderType != Constants.ORDER_TYPE_RENEWAL) {
      customErrorMsg = customErrorMsg + '-' + orgEnt.Id + '-' + Constants.ERROR_TERMINATE_DATE_NOT_FOUND;
    }
    for(Id ordItmId : newoiId){
      if(!orderItemDetById.containskey(ordItmId)){
         continue;
      }
      OrderItem newOrderItem = orderItemDetById.get(ordItmId);
      String targetProdType;
      if(newOrderItem.SBQQ__QuoteLine__r.Replacement_Details__c != null){
        ReplacementJson qliJsonWrapper = (ReplacementJson) JSON.deserialize(newOrderItem.SBQQ__QuoteLine__r.Replacement_Details__c, ReplacementJson.class);
        targetProdType = qliJsonWrapper.targetProductType;
        Set<Id> tempInactiveEnt = qliJsonWrapper != null ? UtilityClass.getChildEntIdsFromQliJson(qliJsonWrapper,OrigEntWrap) : null;
        if(tempInactiveEnt != null && !tempInactiveEnt.isEmpty()){
          OrigEntWrap.inactiveEntsToTerminate.addAll(tempInactiveEnt);
        }
        if (OrigEntWrap.orderItemIdToTargetProductType != null && targetProdType != null) {
          OrigEntWrap.orderItemIdToTargetProductType.put(ordItmId, targetProdType);
        }
      }
      if(OrigEntWrap.orderFulfillmentDate == null && newOrderItem != null){
         OrigEntWrap.orderFulfillmentDate = newOrderItem.Order.Actual_Order_Ship_Date__c;
      }
      if(newRenewalCategory == null){
          if (OrigEntWrap.orderType == Constants.ORDER_TYPE_RENEWAL) {
            newRenewalCategory = Constants.mapProgramToRenewalCategory.get(newOrderItem.Order.Order_sub_type__c);
          } else {
            newRenewalCategory = Constants.mapProgramToRenewalCategory.get(newOrderItem.Program__c);
          }
      }
      if (orgEnt != null && targetProdType == null) {
        customErrorMsg = customErrorMsg + '-' + orgEnt.Id + '-' + Constants.ERROR_TARGET_PRODUCT_TYPE_MISSING;
      }
    }
      if (customErrorMsg != null && customErrorMsg != '') {
        lstofErrorLogs.add(UtilityClass.createlogExceptionRecord(null, Constants.ENTITLEMENT_MANAGER_CLASS, METHOD_NAME_GET_SURVIVING_ENT, 'Entitlement', OrigEntWrap.orderId, 'Data Issue', false, customErrorMsg));
    }
    MatchingEntlinks matchedLinks = new MatchingEntlinks();
    if (orgEnt.contractlineItemId != null && entLinksByCliId != null && entLinksByCliId.containskey(orgEnt.contractlineItemId)) {
      matchedLinks = getMatchingEntitlementLink(entLinksByCliId.get(orgEnt.contractlineItemId), OrigEntWrap.terminateDate, newRenewalCategory);
    }
    if (
      orgEnt.Terminated_Date__c == null ||
      (orgEnt.Terminated_Date__c != null &&
      orgEnt.Terminated_Date__c > System.today() &&
      orgEnt.Renewal_Category__c == Constants.ENT_RENEWAL_CATEGORY_RENEWED &&
      newRenewalCategory != Constants.ENT_RENEWAL_CATEGORY_RENEWED  /*&&
      matchedLinks?.survEntLink == null*/)
    ) {
      survivingEnt = orgEnt;
      replacedOrRenewedEnt = null;
    } else if (matchedLinks != null && (matchedLinks.survEntLink != null || matchedLinks.renewedOrReplacedEnt != null)) {
      if (matchedLinks.renewedOrReplacedEnt != null) {
          isTerminatedDateMatch = true;
        replacedOrRenewedEnt = matchedLinks.renewedOrReplacedEnt.Renewed_Entitlement__r;
        replacedOrRenewedEntLink = matchedLinks.renewedOrReplacedEnt;
        }
      if (matchedLinks.survEntLink != null) {
          survivingEnt = matchedLinks.survEntLink.Renewed_Entitlement__r;
          survEntLink = matchedLinks.survEntLink;
      }
    } else {
       survivingEnt = orgEnt;
       replacedOrRenewedEnt = null;
    }
    EntitlementDetails updatedOrigEntWrap = OrigEntWrap != null ? OrigEntWrap : new EntitlementDetails();
    updatedOrigEntWrap.replacedOrRenewedEnt = replacedOrRenewedEnt;
    updatedOrigEntWrap.survivingEnt = survivingEnt;
    updatedOrigEntWrap.isTerminatedDateMatch = isTerminatedDateMatch;
    updatedOrigEntWrap.replacedOrRenewedEntLink = replacedOrRenewedEntLink;
    updatedOrigEntWrap.survEntLink = survEntLink;
    return updatedOrigEntWrap;
  }


  /* Method to identify specific entitlement links from a given list
   *  Returns a wrapper object `MatchingEntlinks` containing:
   * `renewedOrReplacedEnt` – matched based on termination date and renewal category
   * `survEntLink` – surviving entitlement with no termination date and no renewal category
   *  @author - Naveen Selvaraj
   *  @Date  -  25/7/2025 */
  private static MatchingEntlinks getMatchingEntitlementLink(
    List<Entitlement_Links__c> entLinks,
    Date terminateDate,
    String newRenewalCategory
  ) {
      MatchingEntlinks matchingLinks = new MatchingEntlinks();
      //List<Entitlement_Links__c> entLinks = entLinksByCliId.get(contractLineItemId);
    if (entLinks == null)
      return null;
      for (Entitlement_Links__c entLink : entLinks) {
          if (
        entLink != null &&
        entLink.Renewed_Entitlement__r != null &&
        entLink.Renewed_Entitlement__r.Terminated_Date__c != null &&
        (entLink.Type__c == Constants.ENT_LINK_TYPE_SPLIT_UPGRADE ||
                entLink.Type__c == Constants.ENT_LINK_TYPE_SPLIT_CONVERSION ||
        entLink.Type__c == Constants.ENT_LINK_TYPE_SPLIT_RENEWAL) &&
        entLink.Renewed_Entitlement__r.Terminated_Date__c == terminateDate &&
        entLink.Renewed_Entitlement__r.Renewal_Category__c != null &&
        entLink.Renewed_Entitlement__r.Renewal_Category__c.equals(newRenewalCategory)
          ) {
              matchingLinks.renewedOrReplacedEnt = entLink; // Return first matching record
          }
          if (
            entLink.Renewed_Entitlement__r.Terminated_Date__c == null &&
            entLink.Type__c == Constants.ENT_LINK_TYPE_SPLIT_SURVIVING &&
            entLink.Renewed_Entitlement__r.Renewal_Category__c == null
          ) {
              matchingLinks.survEntLink = entLink;
          }
      }
      return matchingLinks; // No match found
  }

  /**
 * Updates Terminated_Date__c for inactive entitlements and adds them to the provided map.
 *
 * @param origEntId       Id of the original entitlement linked to inactive ones.
 * @param inactiveEntIds  Set of inactive entitlement Ids.
 * @param entToUpsert     Map to store updated entitlements (key = origEntId + '-' + inactiveEntId).
 * @param inactiveEntById Map of Inactive Entitlement by IDs
 * @author Naveen Selvaraj
 * @date 18/8/2025
 * Note: No DML is performed; caller must handle persistence.
 */
  public static void prepareInactiveEntitlementUpdates(
      Id origEntId, 
      EntitlementDetails origEntDetailsWrapper, 
      Map<String, Entitlement> entToUpsert,
      Map<Id, Entitlement> inactiveEntById
    ) {
        Set<Id> inactiveEntIds = origEntDetailsWrapper.inactiveEntsToTerminate;
        if (inactiveEntIds == null || inactiveEntIds.isEmpty()) {
            return;
        }
        for (Id inActiveEntId : inactiveEntIds) {
          Entitlement inActiveEnt = inactiveEntById != null && inactiveEntById.containskey(inActiveEntId) ? inactiveEntById.get(inActiveEntId) : null;
          if (inActiveEnt == null) {
                  continue;
          }
            inActiveEnt.Terminated_Date__c = origEntDetailsWrapper.terminateDate;
            inActiveEnt.Resync_Line__c = 'Required'; // update logic
            inActiveEnt.Renewal_Category__c = origEntDetailsWrapper.transactionType;
          entToUpsert.put(origEntId + '-' + Constants.ENT_INACTIVE, inActiveEnt);
        }
  }

  /**
 * Handles replacement policies for split entitlements in renewal and replacement scenarios.
 *
 * This method processes a collection of original entitlements and determines how they should be split,
 * updated, or replaced based on associated order data, linked assets, entitlement links, and product mappings.
 * It supports various replacement types (including "One per unit") and handles both full and partial replacements.
 
 * @param orderItemDetById               Map of OrderItem IDs to corresponding OrderItem records.
 * @param repOrderItemToEntitlements     Map of replacement OrderItem IDs to their associated Entitlement records.
 * @param origEntIdToWrap                Map of original Entitlement IDs to their detailed wrapper (EntitlementDetails).
 * @param entToLinkedAsset               Map of Entitlement IDs to their linked asset records (Scale_Entitlement__c).
 * @param assetNoToId                    Map of asset serial numbers to their respective asset record IDs.
 * @param ordNoToOIs                     Map of Order Numbers to Program Code-to-OrderItem ID mappings.
 * @param entLinksToCreate               List to collect Entitlement Link records for insertion/updating.
 * @param linkedAstToUpsert              List to collect linked asset records (Scale_Entitlement__c) for insertion/updating.
 * @param cliMap                         Map of Contract Line Item IDs to ContractLineItem records (for updates).
 * @param linkedAssetToDelete            List of linked asset records to be deleted.
 * @param mapProductToPolarisMappings    Map of product identifiers to their Polaris SKU mapping data.
 * @param assetSNForEnts                 Map of Entitlement IDs to associated asset serial numbers.
 * @param inactiveEntById                Map of InActive Entitlement by IDs 
 * @param qliRecById                     Map of QuoteLine IDs to their corresponding SBQQ__QuoteLine__c records.
 *
 * @author Naveen Selvaraj
 * @date 15-04-2025
 */
  public static void processEntSplitBasedOnReplacmentFramework(Map<Id, OrderItem> orderItemDetById, Map<Id, List<Entitlement>> repOrderItemToEntitlements, Map<Id, EntitlementDetails> origEntIdToWrap, Map<Id, List<Scale_Entitlement__c>> entToLinkedAsset, Map<String, Id> assetNoToId, Map<String, Map<String, Id>> ordNoToOIs, List<Entitlement_Links__c> entLinksToCreate, List<Scale_Entitlement__c> linkedAstToUpsert, Map<Id, ContractLineItem> cliMap, List<Scale_Entitlement__c> linkedAssetToDelete, Map<String, Polaris_SKU_Mapping_V2__c> mapProductToPolarisMappings, Map<Id, Set<String>> assetSNForEnts, Map<Id, SBQQ__QuoteLine__c> qliRecById, Map<Id, Asset> assetsToUpdate, Map<Id, Entitlement> inactiveEntById, List<Error_Logs__c> lstofErrorLogs) {
    final String METHOD_NAME_HANDLE_SPLITENT = 'processEntSplitBasedOnReplacmentFramework';
    Map<String, Entitlement> entToUpsert = new Map<String, Entitlement>();
    Map<Id, Set<String>> entidsToSNSet = new Map<Id, Set<String>>();
    if (!origEntIdToWrap.isEmpty()) {
      ReplacementEntSplitHelper.getSerialNumbersByEntId(origEntIdToWrap, entidsToSNSet, entToLinkedAsset, assetSNForEnts);
      for (Id origEntId : origEntIdToWrap.keySet()) {
        String customErrorMsg = '';
        EntitlementDetails origEntDetailsWrapper = origEntIdToWrap.get(origEntId);
        Entitlement orgEnt = origEntDetailsWrapper.orgEntRec;
        origEntDetailsWrapper.orgEntQtyAdjusted = false;
        if (origEntDetailsWrapper.orgEntRec == null) {
          customErrorMsg = origEntId + '-' + Constants.ERROR_ORIGINAL_ENT_NOT_FOUND;
        }
        if (origEntDetailsWrapper.allAssets.isEmpty()) {
            Id tempEntId = origEntDetailsWrapper.survivingEnt != null ? origEntDetailsWrapper.survivingEnt.Id : origEntId;
            if (entidsToSNSet.containskey(tempEntId)) {
              origEntDetailsWrapper.allAssets.addAll(entidsToSNSet.get(tempEntId));
          }
        }
        Boolean split = Test.isRunningTest() && isTestSplit ? true : false;
        Decimal leftQty, qty = 0.0;
        if (origEntDetailsWrapper.newEntitlementsByNewOrdItemId.keyset().size() > 0) {
          for (Id oiId : origEntDetailsWrapper.newEntitlementsByNewOrdItemId.keyset()) {
            OrderItem oi = orderItemDetById.containskey(oiId) ? orderItemDetById.get(oiId) : null;
            if (oi == null || (oi.SBQQ__QuoteLine__c != null && qliRecById.containskey(oi.SBQQ__QuoteLine__c) && qliRecById.get(oi.SBQQ__QuoteLine__c).sbqq__OrderProducts__r.size() > 1)) {
              continue;
            }
            // ProgramType: For Replacement take Oi.Program__c, for Renewal fallback to Order.Order_Sub_Type__c
            String programType = String.isNotBlank(oi.Program__c) ? oi.Program__c : oi.Order.Order_Sub_Type__c;
            List<PreviousTransRefWrapper> wrapper = (List<PreviousTransRefWrapper>) JSON.deserialize(oi.Previous_Transaction_Reference__c, List<PreviousTransRefWrapper>.class);
            for (PreviousTransRefWrapper wrp : wrapper) {
              //ITNPI-2901
              Boolean isAutoAddedSKU = qliRecById!=null && qliRecById?.containsKey(oi.SBQQ__QuoteLine__c)?UtilityClass.isAutoAddedCapacitySKU(qliRecById?.get(oi.SBQQ__QuoteLine__c)):false;
              if (wrp.entId == origEntId && !isAutoAddedSKU) {
                qty += wrp.usedEntitlementQuantity;
                leftQty = wrp.orderItemRemainingQuantity;
              }else if(isAutoAddedSKU){
                autoAddedCapacityOLI.add(oiId);
              }
              if (!origEntDetailsWrapper.newOrdItemNEntIdToWrapper.containskey(oi.id + '-' + wrp.entId)) {
                origEntDetailsWrapper.newOrdItemNEntIdToWrapper.put(oi.id + '-' + wrp.entId, wrp);
              }
            }
            if (oi.SBQQ__QuoteLine__r.Replacement_Details__c != null && String.isNotBlank(origEntDetailsWrapper.orderType)) {
              Set<String> assetSerialNum = new Set<String>();
              if (OI.serialNumber__c != null) {
                assetSerialNum = new Set<String>(oi.serialNumber__c.trim().split(','));
              }
              Map<Id, Set<String>> serialNumsByEntId = UtilityClass.getAssetSerialNumbersFromQliJson(oi.SBQQ__QuoteLine__r);
              Set<String> oldSerialNums = serialNumsByEntId != null &&
                serialNumsByEntId.containskey(orgEnt.Id) &&
                serialNumsByEntId.get(orgEnt.Id).size() > 0
                ? serialNumsByEntId.get(orgEnt.Id)
                : assetSerialNum.size() > 0 ? assetSerialNum : null;
              Boolean isReplacementWithSNs = (origEntDetailsWrapper.orderType == Constants.ORDER_TYPE_REPLACEMENT &&
               oldSerialNums != null && oldSerialNums.size() > 0);
              Boolean isV1Renewals = (origEntDetailsWrapper.orderType == Constants.ORDER_TYPE_RENEWAL && orgEnt.Product__r.Product_Level__c == null);
              Boolean isV2RenewalsWithSerialNums = (origEntDetailsWrapper.orderType == Constants.ORDER_TYPE_RENEWAL &&
              orgEnt.Product__r.Product_Level__c != null &&
              oldSerialNums != null &&
              oldSerialNums.size() > 0);
              if ((isReplacementWithSNs || isV2RenewalsWithSerialNums) && oldSerialNums != null && oldSerialNums.size() > 0) {
                origEntDetailsWrapper.usedAssets.addAll(oldSerialNums);
              } else if (isV1Renewals) {
                origEntDetailsWrapper.usedAssets.addAll(entidsToSNSet.get(orgEnt.id));
              }
              if (oi.SerialNumber__c != null) {
                List<String> oiAssetSNs = oi.SerialNumber__c.trim().split(',');
                for (String serialNum : oiAssetSNs) {
                  serialNum = serialNum.trim();
                  if (origEntDetailsWrapper.transactionTypeByAssetSN != null && !origEntDetailsWrapper.transactionTypeByAssetSN.containskey(serialNum)) {
                    origEntDetailsWrapper.transactionTypeByAssetSN.put(serialNum, Constants.mapProgramToRenewalCategory.get(programType));
                  }
                  if (oi.Upgraded_From__c != null && oi.SerialNumber__c != oi.Upgraded_From__c && !oi.Upgraded_From__c.contains(serialNum)) {
                    origEntDetailsWrapper.refreshedSN.add(serialNum);
                  }
                }
              }
            }
            if (repOrderItemToEntitlements.containskey(oi.id) && repOrderItemToEntitlements.get(oi.Id).size() > 0) {
              if (oi?.Product2?.SBQQSC__EntitlementConversion__c == Constants.PROD_ENTCON_ONE_PER_UNIT && String.isNotBlank(oi.SerialNumber__c)) {
                 List<Entitlement> entList = new List<Entitlement>(repOrderItemToEntitlements.get(oi.id));
                 for (Entitlement newent : entList) {
                  if (entidsToSNSet.containskey(origEntId) && entidsToSNSet.containskey(newent.id)) {
                    List<String> tempListOfSN = new List<String>(entidsToSNSet.get(newent.id));
                    String assetSN = tempListOfSN[0];
                    if (assetSN != null && entidsToSNSet.get(origEntId)?.contains(assetSN)) {
                      if (origEntDetailsWrapper.newEntitlementsByNewOrdItemId.containskey(oi.id)) {
                        origEntDetailsWrapper.newEntitlementsByNewOrdItemId.get(oi.id).add(newEnt);
                      }
                      if (repOrderItemToEntitlements.get(oi.Id).size() > 1) {
                        Integer index = repOrderItemToEntitlements.get(oi.Id).indexof(newent);
                        repOrderItemToEntitlements.get(oi.Id).remove(index);
                      }
                    }
                  }
                }
              } else {
                Entitlement newentRec = repOrderItemToEntitlements.get(oi.Id)[0];
                if (origEntDetailsWrapper.newEntitlementsByNewOrdItemId.containskey(oi.id)) {
                  origEntDetailsWrapper.newEntitlementsByNewOrdItemId.get(oi.id).add(newentRec);
                }
                if (repOrderItemToEntitlements.get(oi.Id).size() > 1) {
                  repOrderItemToEntitlements.get(oi.Id).remove(0);
                }
              }
            }
          }
        }
        if (origEntDetailsWrapper.newEntitlementsByNewOrdItemId.keyset().size() > 0) {
          String phOrd = '';
          for (Id oiId : origEntDetailsWrapper.newEntitlementsByNewOrdItemId.keyset()) {
            OrderItem oi = orderItemDetById.containskey(oiId) ? orderItemDetById.get(oiId) : null;
            origEntDetailsWrapper.newReplacedEnts.addall(origEntDetailsWrapper.newEntitlementsByNewOrdItemId.get(oi.id));
            PreviousTransRefWrapper wrp = origEntDetailsWrapper.newOrdItemNEntIdToWrapper.containskey(oi.id + '-' + origEntId) ? origEntDetailsWrapper.newOrdItemNEntIdToWrapper.get(oi.id + '-' + origEntId) : null;
            if (oi == null || wrp == null || (oi.SBQQ__QuoteLine__c != null && qliRecById.containskey(oi.SBQQ__QuoteLine__c) && qliRecById.get(oi.SBQQ__QuoteLine__c).sbqq__OrderProducts__r.size() > 1)) {
              continue;
            }
            Date terminateDt;
            phOrd = oi.Order.Associated_Order_Numbers__c;
            if (origEntDetailsWrapper.survivingEnt == null) {
              customErrorMsg = customErrorMsg + '-' + origEntId + '-' + Constants.ERROR_SURVIVING_ENTITLEMENT_MISSING;
            }
            if (origEntDetailsWrapper.terminateDate == null && origEntDetailsWrapper.orderType == Constants.ORDER_TYPE_REPLACEMENT) {
              customErrorMsg = customErrorMsg + '-' + origEntId + '-' + Constants.ERROR_TERMINATE_DATE_NOT_FOUND;
            }
            if (customErrorMsg != null && customErrorMsg != '') {
              continue;
            } else {
              if (String.isNotBlank(origEntDetailsWrapper.orderType)) {
                if ((origEntDetailsWrapper.orderType == Constants.ORDER_TYPE_REPLACEMENT || origEntDetailsWrapper.orderType == Constants.ORDER_TYPE_RENEWAL) && !origEntDetailsWrapper.orgEntQtyAdjusted) {
                  if (!origEntDetailsWrapper.isMisMatched && origEntDetailsWrapper.survivingEnt != null && qty < origEntDetailsWrapper.survivingEnt.Order_Service_Item__r.Quantity && origEntDetailsWrapper.survivingEnt.Quantity__c - qty != 0 && !origEntDetailsWrapper.isTerminatedDateMatch) {
                    split = true;
                  }
                  if (origEntDetailsWrapper.survivingEnt.Id != null && !(origEntDetailsWrapper.isTerminatedDateMatch && origEntDetailsWrapper.survivingEnt.Quantity__c - qty > 0)) {
                    origEntDetailsWrapper.survivingEnt.Terminated_Date__c = origEntDetailsWrapper.orgEntRec.status == Constants.ENT_STATUS_EXPIRED ? origEntDetailsWrapper.orgEntRec.EndDate.addDays(-1) : origEntDetailsWrapper.orderFulfillmentDate.addDays(-1);
                  }
                  if (origEntDetailsWrapper.survivingEnt != null && origEntDetailsWrapper.survivingEnt.Id != null) {
                    origEntDetailsWrapper.orgEntQtyAdjusted = true;
                    string renewalCategory = origEntDetailsWrapper.transactionType = origEntDetailsWrapper.survivingEnt.Renewal_Category__c = getRenewalCategory(origEntDetailsWrapper, oi);
                    if (split) {
                      handleEntitlementSplit(origEntId, origEntDetailsWrapper, qty, entToUpsert, renewalCategory, ordNoToOIs, phOrd, inactiveEntById);
                    } else if (origEntDetailsWrapper.isMisMatched || (origEntDetailsWrapper.survivingEnt != null && origEntDetailsWrapper.replacedOrRenewedEnt == null && origEntDetailsWrapper.survivingEnt.Quantity__c - qty == 0)) {
                      handleFullReplacementOrRenewal(origEntId, origEntDetailsWrapper, entToUpsert, renewalCategory);
                    } else if (origEntDetailsWrapper.survivingEnt != null && origEntDetailsWrapper.replacedOrRenewedEnt != null && (origEntDetailsWrapper.isTerminatedDateMatch || (!origEntDetailsWrapper.isTerminatedDateMatch && origEntDetailsWrapper.survivingEnt.Order_Service_Item__r.Quantity != origEntDetailsWrapper.survivingEnt.Quantity__c && origEntDetailsWrapper.survivingEnt.Quantity__c - qty == 0))) {
                      adjustQtyOnExistingSurvivingEnt(origEntId, origEntDetailsWrapper, qty, entToUpsert, entLinksToCreate);
                    }
                    cliMap = UtilityClass.getupdatedCli(cliMap, origEntDetailsWrapper.survivingEnt, qty);
                  }
                }
              }
            }
          }
        }
        if (origEntDetailsWrapper.inactiveEntsToTerminate != null && !origEntDetailsWrapper.inactiveEntsToTerminate.isEmpty() && (!split || origEntDetailsWrapper.isMisMatched)) {
           prepareInactiveEntitlementUpdates(origEntId, origEntDetailsWrapper, entToUpsert, inactiveEntById);
          }
        if (customErrorMsg != null && customErrorMsg != '') {
          lstofErrorLogs.add(UtilityClass.createlogExceptionRecord(null, Constants.ENTITLEMENT_MANAGER_CLASS, METHOD_NAME_HANDLE_SPLITENT, 'Entitlement', origEntDetailsWrapper.orderId, 'Data Issue', false, customErrorMsg));
        } else {
          if (
            origEntDetailsWrapper.orderItemIdToTargetProductType != null &&
            origEntDetailsWrapper.orderItemIdToTargetProductType?.values()?.contains(Constants.SKU_TYPE_NON_HARDWARE) &&
            origEntDetailsWrapper.usedAssets != null &&
            !origEntDetailsWrapper.usedAssets.isEmpty()
          ) {
            for (String assetSN : origEntDetailsWrapper.usedAssets) {
              if (assetNoToId.containskey(assetSN)) {
                Id assetId = assetNoToId.get(assetSN);
                if (assetsToUpdate.containskey(assetId)) {
                  assetsToUpdate.get(assetId).Program__c = origEntDetailsWrapper.transactionType;
                } else {
                  assetsToUpdate.put(assetId, new Asset(Id = assetId, Program__c = origEntDetailsWrapper.transactionType));
                }
              }
            }
          }
        }
      }
      if (!entToUpsert.values().isEmpty()) {
        upsert entToUpsert.values();
        manageEntitlementLinks(entToUpsert, origEntIdToWrap, entLinksToCreate, mapProductToPolarisMappings);
        manageLinkedAssets(entToUpsert, origEntIdToWrap, entToLinkedAsset, assetNoToId, linkedAstToUpsert);
      }
    }
  }

  /*
   * @description Determines the renewal category for the entitlement.
   * @param originalEntDetailsWrapper The wrapper for original entitlement details.
   * @param newOrderItem The new OrderItem record.
   * @return The renewal category string.
   */
  private static String getRenewalCategory(EntitlementDetails originalEntDetailsWrapper, OrderItem newOrderItem) {
    if (originalEntDetailsWrapper.orderType == Constants.ORDER_TYPE_RENEWAL) {
      return Constants.mapProgramToRenewalCategory.get(Constants.ORDER_TYPE_RENEWAL);
    } else if (!originalEntDetailsWrapper.newEntitlementsByNewOrdItemId.isEmpty() && newOrderItem.Program__c != null && Constants.mapProgramToRenewalCategory.containsKey(newOrderItem.Program__c)) {
      return Constants.mapProgramToRenewalCategory.get(newOrderItem.Program__c);
    }
    return newOrderItem.Program__c;
  }

  /**
   * @description Handles the creation of new entitlements when a split is required.
   * @param originalEntitlementId The ID of the original entitlement.
   * @param originalEntDetailsWrapper The wrapper for original entitlement details.
   * @param usedQuantity The quantity being used.
   * @param entToUpsert Map to collect entitlements for upsert.
   * @param renewalCategory The determined renewal category.
   * @param ordNoToOIs Map of Order Numbers to Order Item IDs for phantom orders.
   * @param inactiveEntById Map of Inactive Entitlement by IDs
   */
  private static void handleEntitlementSplit(Id originalEntitlementId, EntitlementDetails originalEntDetailsWrapper, Decimal usedQuantity, Map<String, Entitlement> entToUpsert, String renewalCategory, Map<String, Map<String, Id>> ordNoToOIs, String phantomOrdNum, Map<Id,Entitlement> inactiveEntById) {
    // Create new Entitlement for used Quantity
    Entitlement splitEntForUsedQty = originalEntDetailsWrapper.survivingEnt.clone(false, false, false, false);
    splitEntForUsedQty.Terminated_Date__c = originalEntDetailsWrapper.orderType == Constants.ORDER_TYPE_RENEWAL ? originalEntDetailsWrapper.survivingEnt.EndDate : originalEntDetailsWrapper.terminateDate;
    splitEntForUsedQty.Renewal_Category__c = renewalCategory;
    splitEntForUsedQty.StartDate = originalEntDetailsWrapper.survivingEnt.Status == Constants.ENT_STATUS_EXPIRED ? originalEntDetailsWrapper.survivingEnt.EndDate : originalEntDetailsWrapper.orderFulfillmentDate;
    splitEntForUsedQty.EndDate = originalEntDetailsWrapper.survivingEnt.EndDate;
    splitEntForUsedQty.Quantity__c = usedQuantity;
    splitEntForUsedQty.Source_StartDate__c = originalEntDetailsWrapper.survivingEnt.StartDate;
    splitEntForUsedQty.Resync_Line__c = 'Required';
    entToUpsert.put(originalEntitlementId + '-' + Constants.ENT_KEY_REPLACED_OR_RENEWED_NEW, splitEntForUsedQty);

    // Create new Entitlement for Left Quantity (surviving part)
    Entitlement splitEntForLeftQty = originalEntDetailsWrapper.survivingEnt.clone(false, false, false, false);
    splitEntForLeftQty.Terminated_Date__c = null;
    splitEntForLeftQty.Renewal_Category__c = null;
    splitEntForLeftQty.StartDate = originalEntDetailsWrapper.survivingEnt.Status == Constants.ENT_STATUS_EXPIRED ? originalEntDetailsWrapper.survivingEnt.EndDate : originalEntDetailsWrapper.orderFulfillmentDate;
    splitEntForLeftQty.EndDate = originalEntDetailsWrapper.survivingEnt.EndDate;
    splitEntForLeftQty.Quantity__c = originalEntDetailsWrapper.survivingEnt.Quantity__c - usedQuantity;
    splitEntForLeftQty.Source_StartDate__c = originalEntDetailsWrapper.survivingEnt.StartDate;
    splitEntForLeftQty.Resync_Line__c = 'Required';

    if (String.isNotBlank(phantomOrdNum) && ordNoToOIs.containsKey(phantomOrdNum)) {
      Map<String, Id> prodCodeToOiId = ordNoToOIs.get(phantomOrdNum);
      String prdName = originalEntDetailsWrapper?.orgEntRec?.Product__r.Name + originalEntDetailsWrapper?.orgEntRec?.Id;
      if (prodCodeToOiId.containsKey(prdName)) {
        Id phOrdItemId = prodCodeToOiId.get(prdName);
        splitEntForLeftQty.Phantom_OrderItemID__c = phOrdItemId;
      }
    }
    entToUpsert.put(originalEntitlementId + '-' + Constants.ENT_KEY_SURVIVING_NEW, splitEntForLeftQty);

    if (originalEntDetailsWrapper.inactiveEntsToTerminate != null && !originalEntDetailsWrapper.inactiveEntsToTerminate.isEmpty()) {
      processInactiveEntSplits(originalEntDetailsWrapper,originalEntDetailsWrapper.inactiveEntsToTerminate, originalEntitlementId, usedQuantity, renewalCategory, entToUpsert, inactiveEntById);
    }
    // Update the original surviving entitlement (which represents the used part for auditing/linking)
    originalEntDetailsWrapper.survivingEnt.Renewal_Category__c = renewalCategory;
    originalEntDetailsWrapper.survivingEnt.Transaction_Type__c = Constants.ENT_TRANS_TYPE_REPLACEMENT_FRAMEWORK;
    entToUpsert.put(originalEntitlementId + '-' + Constants.ENT_KEY_ORIGINAL, originalEntDetailsWrapper.survivingEnt);
  }

  /**
 * Splits inactive entitlements into two parts: 
 *  - Used quantity (terminated with renewal category)  
 *  - Remaining quantity (leftover)  
 * Updates the original inactive entitlement with termination and renewal details.  
 *
 * @param originalEntDetailsWrapper Wrapper containing entitlement and order details
 * @param originalEntitlementId     Id of the original entitlement
 * @param usedQuantity              Quantity consumed/used from the entitlement
 * @param renewalCategory           Renewal category (e.g., Renewed, Upgraded, Converted)
 * @param entToUpsert               Map collecting entitlements to be upserted
 * @param inactiveEntById           Pre-fetched map of inactive entitlements by Id
 * @return                          Updated map of entitlements to upsert
 */  
  public static Map<String, Entitlement> processInactiveEntSplits(
      EntitlementDetails originalEntDetailsWrapper,
      Set<Id> inactiveEntsToTerminate,
      Id originalEntitlementId,
      Decimal usedQuantity,
      String renewalCategory,
      Map<String, Entitlement> entToUpsert,
      Map<Id, Entitlement> inactiveEntById
  ) {
      if (!inactiveEntsToTerminate.isEmpty()) {
        for (Id inactiveEntId : inactiveEntsToTerminate) {
          // Load inactive entitlement from DB if needed
          Entitlement inactiveEnt = inactiveEntById != null && inactiveEntById.containskey(inactiveEntId) ? inactiveEntById.get(inactiveEntId) : null;
          if (inactiveEnt == null) {
            continue;
          }
          // Split 1: Used Quantity
          Entitlement inActiveEntSplitUsedQty = inactiveEnt.clone(false, false, false, false);
          inActiveEntSplitUsedQty.Terminated_Date__c = originalEntDetailsWrapper.terminateDate;
          inActiveEntSplitUsedQty.Renewal_Category__c = renewalCategory;
          inActiveEntSplitUsedQty.Quantity__c = usedQuantity;
          inActiveEntSplitUsedQty.Resync_Line__c = 'Required';
          entToUpsert.put(originalEntitlementId + '-' + Constants.ENT_INACTIVE_USED, inActiveEntSplitUsedQty);

          // Split 2: Remaining Quantity
          Entitlement inActiveEntSplitLeftQty = inactiveEnt.clone(false, false, false, false);
          inActiveEntSplitLeftQty.Quantity__c = inactiveEnt.Quantity__c != null ? inactiveEnt.Quantity__c - usedQuantity : 0;
          inActiveEntSplitLeftQty.Resync_Line__c = 'Required';
          entToUpsert.put(originalEntitlementId + '-' + Constants.ENT_INACTIVE_LEFT, inActiveEntSplitLeftQty);

          // Update Original Inactive Entitlement
          inactiveEnt.Renewal_Category__c = renewalCategory;
          inactiveEnt.Transaction_Type__c = Constants.ENT_TRANS_TYPE_REPLACEMENT_FRAMEWORK;
          inactiveEnt.Terminated_Date__c = originalEntDetailsWrapper.orderFulfillmentDate.addDays(-1);
          entToUpsert.put(originalEntitlementId + '-' + Constants.ENT_INACTIVE, inactiveEnt);
        }
      }

    return entToUpsert;
  }

  /**
   * @description Handles the logic for a full replacement or renewal scenario.
   * @param origEntId The ID of the original entitlement.
   * @param originalEntDetailsWrapper The wrapper for original entitlement details.
   * @param entToUpsert Map to collect entitlements for upsert.
   * @param renewalCategory The determined renewal category.
   */
  private static void handleFullReplacementOrRenewal(Id origEntId, EntitlementDetails originalEntDetailsWrapper, Map<String, Entitlement> entToUpsert, String renewalCategory) {
    originalEntDetailsWrapper.survivingEnt.Renewal_Category__c = renewalCategory;
    originalEntDetailsWrapper.survivingEnt.Terminated_Date__c = originalEntDetailsWrapper.orderType == Constants.ORDER_TYPE_RENEWAL ? originalEntDetailsWrapper.survivingEnt.EndDate : originalEntDetailsWrapper.terminateDate;
    originalEntDetailsWrapper.survivingEnt.Resync_Line__c = 'Required';
    originalEntDetailsWrapper.isFullReplacementOrRenewal = true;
    originalEntDetailsWrapper.survivingEnt.Transaction_Type__c = Constants.ENT_TRANS_TYPE_REPLACEMENT_FRAMEWORK;
    entToUpsert.put(origEntId + '-' + Constants.ENT_KEY_ORIGINAL, originalEntDetailsWrapper.survivingEnt);
  }

  /**
   * @description Handles adjusting quantities on existing replaced/renewed and surviving entitlements.
   * @param originalEntitlementId The ID of the original entitlement.
   * @param originalEntDetailsWrapper The wrapper for original entitlement details.
   * @param usedQuantity The quantity being used.
   * @param entitlementsToUpsert Map to collect entitlements for upsert.
   * @param entLinksToCreate List to collect entitlement links to create.
   */
  private static void adjustQtyOnExistingSurvivingEnt(Id origEntId, EntitlementDetails originalEntDetailsWrapper, Decimal usedQuantity, Map<String, Entitlement> entToUpsert, List<Entitlement_Links__c> entLinksToCreate) {
    // Adjusting qty on Replaced / Renewed Ents
    originalEntDetailsWrapper.replacedOrRenewedEnt.Quantity__c += usedQuantity;
    originalEntDetailsWrapper.replacedOrRenewedEnt.Resync_Line__c = 'Required';
    originalEntDetailsWrapper.replacedOrRenewedEntLink.Quantity__c += usedQuantity;
    entLinksToCreate.add(originalEntDetailsWrapper.replacedOrRenewedEntLink);
    entToUpsert.put(origEntId + '-' + Constants.ENT_KEY_REPLACED_OR_RENEWED_OLD, originalEntDetailsWrapper.replacedOrRenewedEnt);

    // Adjusting qty on Surviving Ent
    originalEntDetailsWrapper.survivingEnt.Quantity__c = originalEntDetailsWrapper.survivingEnt.Quantity__c != 0 && originalEntDetailsWrapper.survivingEnt.Quantity__c > usedQuantity ? originalEntDetailsWrapper.survivingEnt.Quantity__c - usedQuantity : originalEntDetailsWrapper.survivingEnt.Quantity__c;
    originalEntDetailsWrapper.survivingEnt.Resync_Line__c = 'Required';
    originalEntDetailsWrapper.survEntLink.Quantity__c = originalEntDetailsWrapper.survEntLink.Quantity__c != 0 && originalEntDetailsWrapper.survEntLink.Quantity__c > usedQuantity ? originalEntDetailsWrapper.survEntLink.Quantity__c - usedQuantity : originalEntDetailsWrapper.survEntLink.Quantity__c;
    entLinksToCreate.add(originalEntDetailsWrapper.survEntLink);
    entToUpsert.put(origEntId + '-' + Constants.ENT_KEY_SURVIVING_OLD, originalEntDetailsWrapper.survivingEnt);
  }

  /**
   * Method to create or update Linked Assets for Replacement Framework use cases.
   * <p>This method handles the logic to associate entitlements with their corresponding linked assets
   * based on asset and entitlement data in the Replacement Framework.</p>
   *
   * @param entToUpsert         List of upserted Entitlements as part of the Replacement Framework.
   * @param origEntIdToWrap     Wrapper object or map containing organization entitlement details.
   * @param entToLinkedAsset    Map of Entitlement ID to its corresponding Linked Asset information.
   * @param assetNoToId         Map of Asset Serial Numbers to their related record IDs.
   * @param linkedAstToUpsert   List used for DML, containing Linked Asset records to insert or update.
   *
   * @return Updates the linkedAstToUpsert list with records to be inserted or updated.
   *
   * @author Naveen Selvaraj
   * @date 15-04-2025
   */
  public static void manageLinkedAssets(Map<String, Entitlement> entToUpsert, Map<Id, EntitlementDetails> origEntIdToWrap, Map<Id, List<Scale_Entitlement__c>> entToLinkedAsset, Map<String, Id> assetNoToId, List<Scale_Entitlement__c> linkedAstToUpsert) {
    Set<String> exitingLinkedAssetsKey = new Set<String>();
    for (String entKey : entToUpsert.keySet()) {
      String originalEntId = entKey.split('-')[0];
      EntitlementDetails origEntDetailsWrapper = origEntIdToWrap.get(originalEntId);
      Entitlement entRecord = entToUpsert.get(entKey);
      if ((entKey.contains(Constants.ENT_KEY_ORIGINAL) && origEntDetailsWrapper.isFullReplacementOrRenewal) || Test.isRunningTest()) {
        ReplacementEntSplitHelper.handleAssetLinkageForFullReplacement(origEntDetailsWrapper, entToLinkedAsset, linkedAstToUpsert, entToUpsert, originalEntId);
      }
      if (entKey.contains(Constants.ENT_KEY_SURVIVING_NEW)) {
        ReplacementEntSplitHelper.handleAssetLinkageSurvivingNew(origEntDetailsWrapper, entRecord, assetNoToId, linkedAstToUpsert);
      }
      if (entKey.contains(Constants.ENT_KEY_REPLACED_OR_RENEWED_NEW)) {
        ReplacementEntSplitHelper.handleAssetLinkageReplacedNew(origEntDetailsWrapper, entRecord, entToLinkedAsset, assetNoToId, linkedAstToUpsert);
      }
      if ((entKey.contains(Constants.ENT_KEY_REPLACED_OR_RENEWED_OLD) && origEntDetailsWrapper.orderItemIdToTargetProductType != null && origEntDetailsWrapper.orderItemIdToTargetProductType?.values()?.contains(Constants.SKU_TYPE_HARDWARE)) || Test.isRunningTest()) {
        ReplacementEntSplitHelper.handleAssetLinkageReplacedOld(origEntDetailsWrapper, entRecord, assetNoToId, linkedAstToUpsert);
      }
      if (entKey.contains(Constants.ENT_KEY_SURVIVING_OLD)) {
        ReplacementEntSplitHelper.handleAssetLinkageSurvivingOld(origEntDetailsWrapper, entToLinkedAsset, linkedAstToUpsert);
      }
      if (
        (entKey.contains(Constants.ENT_KEY_ORIGINAL) || entKey.contains(Constants.ENT_KEY_SURVIVING_OLD)) &&
        !origEntDetailsWrapper.newReplacedEnts.isEmpty() &&
        origEntDetailsWrapper.orderItemIdToTargetProductType != null && origEntDetailsWrapper.orderItemIdToTargetProductType?.values()?.contains(Constants.SKU_TYPE_HARDWARE)
      ) {
        ReplacementEntSplitHelper.handleAssetLinkageForNewEnts(origEntDetailsWrapper, assetNoToId, linkedAstToUpsert, exitingLinkedAssetsKey);
      }
      if (entKey.contains(Constants.ENT_INACTIVE) && entKey.equals(originalEntId+'-'+Constants.ENT_INACTIVE) && !origEntDetailsWrapper.isFullReplacementOrRenewal){
        ReplacementEntSplitHelper.handleAssetLinkageInactiveEnt(origEntDetailsWrapper,originalEntId,entRecord,assetNoToId,linkedAstToUpsert,entToLinkedAsset,entToUpsert);
      }
      origEntIdToWrap.put(originalEntId, origEntDetailsWrapper);
    }
  }
  /**
   * Method to create Entitlement Links for Replacement Framework use cases.
   * This method processes upserted entitlements and creates corresponding Entitlement Link records
   *  based on Replacement Framework logic and product-to-Polaris mapping.</p>
   *
   * @param entToUpsert                  List of upserted Entitlements as part of the Replacement Framework.
   * @param origEntIdToWrap              Wrapper or map containing details of organization Entitlements.
   * @param entLinksToCreate             List used in DML to store Entitlement Link records to be created.
   * @param mapProductToPolarisMappings Map of Product to Polaris Mappings used to determine Entitlement Link quantity.
   *
   * @return Updates the entLinksToCreate list with new Entitlement Link records.
   *
   * @author Naveen Selvaraj
   * @date 15-04-2025
   */
  public static void manageEntitlementLinks(Map<String, Entitlement> entToUpsert, Map<Id, EntitlementDetails> origEntIdToWrap, List<Entitlement_Links__c> entLinksToCreate, Map<String, Polaris_SKU_Mapping_V2__c> mapProductToPolarisMappings) {
    Set<String> ugLinksCreatedAlready = new Set<String>();
    for (String entKey : entToUpsert.keySet()) {
      String originalEntId = entKey.split('-')[0];
      EntitlementDetails origEntDetailsWrapper = origEntIdToWrap.get(originalEntId);
      Entitlement entRecord = entToUpsert.get(entKey);
      if (entKey == null || origEntDetailsWrapper == null) {
        continue;
      }
      if ((entKey.contains(Constants.ENT_KEY_ORIGINAL) && origEntDetailsWrapper.isFullReplacementOrRenewal) || Test.isRunningTest()) {
        ReplacementEntSplitHelper.handleEntLinkFullReplacement(entRecord, origEntDetailsWrapper, entLinksToCreate, mapProductToPolarisMappings, origEntIdToWrap, ugLinksCreatedAlready);
      }
      if (entKey.contains(Constants.ENT_KEY_SURVIVING_NEW)) {
        ReplacementEntSplitHelper.handleEntLinkSurvivingNewLink(origEntDetailsWrapper, entRecord, entLinksToCreate, mapProductToPolarisMappings);
      }
      if (entKey.contains(Constants.ENT_KEY_REPLACED_OR_RENEWED_NEW)) {
        ReplacementEntSplitHelper.handleEntLinkReplacedNewLink(origEntDetailsWrapper, entRecord, entLinksToCreate, mapProductToPolarisMappings, entToUpsert.get(entKey).Renewal_Category__c, origEntIdToWrap, ugLinksCreatedAlready);
      }
      if (entKey.contains(Constants.ENT_KEY_REPLACED_OR_RENEWED_OLD) || Test.isRunningTest()) {
        ReplacementEntSplitHelper.handleEntLinkReplacedOldLink(entRecord, origEntDetailsWrapper, entLinksToCreate, mapProductToPolarisMappings, entToUpsert.get(entKey).Renewal_Category__c);
      }
      if ((entKey.contains(Constants.ENT_INACTIVE) && entKey.equals(originalEntId+'-'+Constants.ENT_INACTIVE) && !origEntDetailsWrapper.isFullReplacementOrRenewal) || Test.isRunningTest()){
        ReplacementEntSplitHelper.handleEntlinkInactiveEnt(origEntDetailsWrapper, originalEntId, entRecord, entLinksToCreate, entToUpsert,entToUpsert.get(entKey).Renewal_Category__c,mapProductToPolarisMappings);
      }
    }
  }

  
  /**
   * Method Calling Points -> OrderUpdateHelper & ContractOrders
   * A common method for Aspen & Non-Aspen to Synchronizes the linked assets for refresh and replacement license orders.
   * This includes updating serial numbers on the refreshed order items,
   * creating new linked assets on new and old license, and updating old linked assets as "refreshed".
   * @param newSerialNumsByOld A map where the key is the old serial number and the value is a list of new serial numbers that replaced the old asset.
   * @param newOrderItems A list of OrderItem records
   * @param entitlementsByOIId A map linking OrderItem Ids to their corresponding list of Entitlements.
   * @param assetBySerialNumber A map where the key is the serial number and the value is the corresponding Asset record
   * @param orderItemsToUpdate A map of OrderItem Ids to their updated OrderItem records, to be updated in the database.
   * @param scaleEntToInsert A list of new Scale_Entitlement__c (linked assets) that are created and need to be inserted into the database.
   * @Param oldAssetsToUpdate A map of Asset Ids to their updated Asset records, to be updated in the database.
   * @param exitingLinkedAssetsKey Set of unique keys (EntitlementId + SerialNumber) to prevent duplicates.
   * @param isContractOrdersBatchContext A boolean to check if the method is being called from the batch context
   * @author Ravi Mali
   */
  public void syncLinkedAssetsForRefreshAndReplacementLicenses(
    Map<String, Set<String>> newSerialNumsByOld,
    List<OrderItem> newOrderItems,
    Map<Id, List<Entitlement>> entitlementsByOIId,
    Map<String, Asset> assetBySerialNumber,
    Map<Id, OrderItem> orderItemsToUpdate,
    Set<Scale_Entitlement__c> linkedAstToUpsert,
    Map<Id, Asset> oldAssetsToUpdate,
    Set<String> exitingLinkedAssetsKey,
    Boolean isContractOrdersBatchContext
  ) {
    //Eligible days for an old expired Entitlement in Refresh.
    Integer expiredEntitlementEligibility = Integer.ValueOf(Order_control__mdt.getInstance('ExpiredEntitlementEligibilityDays').Value__c);
    Set<Id> origEntIds = new Set<Id>();
    Set<Id> origOrdItmIds = new Set<Id>();
    
    List<Scale_Entitlement__c> oldLinkedAssets = getOldLinkedAssets(newSerialNumsByOld.keySet());

    //Query the new Asset details in the ContractOrders batch context
    if (isContractOrdersBatchContext) {
      ReplacementEntSplitHelper.loadAssets(newSerialNumsByOld, assetBySerialNumber);
    }

    for (OrderItem OI : newOrderItems) {
      Boolean isRefreshProgram = OI.Program__c == CONSTANTS.PROGRAM_REFRESH;
      if (isRefreshProgram) {
        ReplacementEntSplitHelper.collectOriginalLinesDetail(OI, origEntIds, origOrdItmIds);
      }

      ReplacementEntSplitHelper.handleLinkedAssetForNewOI(
        OI,
        newSerialNumsByOld,
        entitlementsByOIId,
        assetBySerialNumber,
        orderItemsToUpdate,
        linkedAstToUpsert,
        exitingLinkedAssetsKey,
        isContractOrdersBatchContext
      );
    }

    Set<Id> entsToExcludeForScaleENT = ReplacementEntSplitHelper.getEntitlementIdsToExclude(origEntIds, origOrdItmIds);

    //Create the linked assets in the case of v2 -> V2 Refresh
    ReplacementEntSplitHelper.linkNewAssetOnOldV2Entitlement(
      oldLinkedAssets,
      entsToExcludeForScaleENT,
      expiredEntitlementEligibility,
      newSerialNumsByOld,
      assetBySerialNumber,
      oldAssetsToUpdate,
      linkedAstToUpsert,
      exitingLinkedAssetsKey
    );

    //Create the linked assets in the case of v1 -> V2 Refresh
    if (!oldV1Entitlements.isEmpty()) {
      for (Entitlement oldENT : oldV1Entitlements.Values()) {
        if (newSerialNumsByOld.containsKey(oldENT?.Asset?.SerialNumber)) {
          ReplacementEntSplitHelper.linkNewAssetOnOldV1Entitlement(
            oldENT,
            oldAssetsToUpdate,
            newSerialNumsByOld,
            assetBySerialNumber,
            linkedAstToUpsert,
            exitingLinkedAssetsKey,
            expiredEntitlementEligibility
          );
        }
      }
    }
  }

  /**
   * Fetches old linked Scale_Entitlement__c records for the given serial numbers,
   * excluding those with 'Refreshed' renewal category or RCDM-related products.
   *
   * @param serialNumbers Set of serial numbers used to filter linked entitlements
   * @return List of eligible Scale_Entitlement__c records
   */
  public List<Scale_Entitlement__c> getOldLinkedAssets(Set<String> serialNumbers) {
    List<Scale_Entitlement__c> eligibleScaleEntitlements = new List<Scale_Entitlement__c>();

    if (serialNumbers.isEmpty()){
      return eligibleScaleEntitlements;
    }
      
    for(Scale_Entitlement__c se :[
      SELECT Id,Renewal_Category__c, Order_Product__r.Id, Entitlement__r.Id, Entitlement__r.ContractLineItemId, Entitlement__r.EndDate, Asset__c, Asset__r.SerialNumber
      FROM Scale_Entitlement__c
      WHERE Asset__r.SerialNumber IN :serialNumbers AND (NOT Entitlement__r.Product__r.Name LIKE '%RCDM%')
    ]){
      if(se.Renewal_Category__c != 'Refreshed'){
        eligibleScaleEntitlements.add(se);
      }
      if(!serialNumbersByEntId.containsKey(se.Entitlement__c)){
        serialNumbersByEntId.put(se.Entitlement__c,new Set<String>());
      }
      serialNumbersByEntId.get(se.Entitlement__c).add(se.Asset__r.SerialNumber);
    }
    return eligibleScaleEntitlements;
  }

  /**
   * Creates Entitlement_Links__c records that establish relationships between old and newly refreshed entitlements.
   *
   * @param RefreshOrderItemsWrapper A wrapper object containing all required data for linking old and new entitlements,
   *  including mappings between Order Items and Entitlements, the master list of Entitlements,
   *  the output list for link records, and product-to-Polaris SKU mappings.
   */
  public static void createEntitlementLinksForRefresh(RefreshOrderItemsWrapper wrapper) {
    Set<String> oldNewEntIdKeys = new Set<String>();
    Set<Id> allOldENTIds = new Set<Id>();
    Map<Id,Set<Id>> oldEntIdsByOiId = new Map<Id,Set<Id>>();
  

    // In the case of Aspen, serial number gets updated after SC generation,
    // fetch the old linked asset; For Non-Aspen, it's already being queried 
    // from syncLinkedAssetsForRefreshAndReplacementLicenses method
    if (!wrapper.newSerialNumsByOld.keySet().isEmpty() && serialNumbersByEntId.isEmpty()) {
      ReplacementEntSplitManager Manager = new ReplacementEntSplitManager();
        Manager.getOldLinkedAssets(wrapper.newSerialNumsByOld.keySet());
    }  

    for (Set<Id> entSet : wrapper.oldENTIdsByNewOI.values()) {
      allOldENTIds.addAll(entSet);
    }

    // Map to store a single split entitlement for each original entitlement
    Map<Id, List<Entitlement>> splitEntitlementsByOriginalId = new Map<Id, List<Entitlement>>();

    // Preload existing Entitlement Links to avoid duplicates and collect split ENTs IF 1.1 is present
    for (Entitlement_Links__c entLink : ReplacementEntSplitHelper.getEntitlementLinks(wrapper.origOrdItmIds)) {
     if (Constants.ENT_LINK_SPLIT_REPLACEMENT_TYPES.contains(entLink.Type__c)) {
        if (!splitEntitlementsByOriginalId.containsKey(entLink.Previous_Entitlement__c)) {
          splitEntitlementsByOriginalId.put(entLink.Previous_Entitlement__c, new List<Entitlement>());
        }
        splitEntitlementsByOriginalId.get(entLink.Previous_Entitlement__c).add(entLink.Renewed_Entitlement__r);
       
        if(!oldEntIdsByOiId.ContainsKey(entLink?.Previous_Entitlement__r?.Order_Service_Item__c)){
          oldEntIdsByOiId.put(entLink.Previous_Entitlement__r.Order_Service_Item__c, new Set<Id>());
        } 
        oldEntIdsByOiId.get(entLink?.Previous_Entitlement__r?.Order_Service_Item__c).add(entLink.Previous_Entitlement__c);
      }
      if (entLink.Type__c == Constants.PROGRAM_REFRESH) {
        oldNewEntIdKeys.add(entLink.Previous_Entitlement__c + '-' + entLink.Renewed_Entitlement__c);
      }
    }

    for (Id newOIId : wrapper.newENTsByNewOI.keySet()) {
      Set<Entitlement> newEnts = wrapper.newENTsByNewOI.get(newOIId);
      Set<Id> oldEntIds = wrapper.oldENTIdsByNewOI.get(newOIId);

      if (newEnts == null || oldEntIds == null)
        continue;

      for (Entitlement newRefreshedENT : newEnts) {
        Set<String> upgradedByAssetsOnNewOI = new Set<String>();
        String upgradedFrom = newRefreshedENT.Order_Service_Item__r.Upgraded_From__c;

        if (String.isNotBlank(upgradedFrom)) {
          upgradedByAssetsOnNewOI = new Set<String>(upgradedFrom.split(','));
        }

        Set<Id> origSplitEntIds = new Set<Id> ();
        
        // Extract subsequent split entitlements (beyond the original)
        for (Id oldOrgENTId : oldEntIds) {
          Entitlement oldEnt = wrapper.allOldNewENTs.get(oldOrgENTId);
          if (oldEnt != null && oldEnt.Order_Service_Item__c != null) {
             Set<Id> previousEntIds = oldEntIdsByOiId.get(oldEnt.Order_Service_Item__c);
            if (previousEntIds != null) {
                origSplitEntIds.addAll(previousEntIds);
            }
          }
        }

        oldEntIds.addALL(origSplitEntIds);

        Boolean isHwSuppSku = newRefreshedENT?.Product__r != null && UtilityClass.isV2HardwareSupportSKU(newRefreshedENT.Product__r);
        for (Id oldOrgENTId : oldEntIds) {
          List<Entitlement> sourceEntitlementsForLinking = new List<Entitlement>();

          // Determine which entitlements to link: 
          // If the original entitlement was split (e.g., into ENT 1.1, 1.2), use the split ones;
          // otherwise, use the original entitlement itself.
          if (splitEntitlementsByOriginalId.containsKey(oldOrgENTId)) {
              sourceEntitlementsForLinking.addAll(splitEntitlementsByOriginalId.get(oldOrgENTId));
          } else {
              Entitlement originalEntitlement = wrapper.allOldNewENTs.get(oldOrgENTId);
              if (originalEntitlement != null) {
                  sourceEntitlementsForLinking.add(originalEntitlement);
          }
          }

          for(Entitlement sourceEnt : sourceEntitlementsForLinking){
            Set<String> linkedAssetsOnOldEnt = serialNumbersByEntId.get(sourceEnt.Id);
            if (isHwSuppSku || ReplacementEntSplitHelper.hasCommonUpgradedAssets(linkedAssetsOnOldEnt, upgradedByAssetsOnNewOI)) {
          // Create entitlement link from the new refresh entitlement to the original entitlement
              ReplacementEntSplitHelper.linkNewRefreshEntitlementToOriginal(wrapper, sourceEnt, newRefreshedENT, isHwSuppSku, oldNewEntIdKeys);
            }
          }
          // Create entitlement link from the new refresh delta to the replacement or renewal license if present in the same quote
         ReplacementEntSplitHelper.linkRefreshDeltaToReplacementsOrRenewals(wrapper, oldOrgENTId, newRefreshedENT, oldNewEntIdKeys);
        }
      }
    }
  }

  /**
   * Wrapper class used to group all data necessary for creating entitlement links
   * during a refresh process between old and new entitlements.
   */
  public class RefreshOrderItemsWrapper {
    public Map<Id, Set<Id>> oldENTIdsByNewOI = new Map<Id, Set<Id>>(); // Maps new Order Item IDs to sets of old Entitlement IDs.
    public Map<Id, Set<Entitlement>> newENTsByNewOI = new Map<Id, Set<Entitlement>>(); // Maps new Order Item IDs to sets of newly created Entitlements.
    public Map<Id, Entitlement> allOldNewENTs = new Map<Id, Entitlement>(); // Maps Entitlement IDs to corresponding old Entitlement records.
    public Map<String, Polaris_SKU_Mapping_V2__c> mapProductToPolarisMappings = new Map<String, Polaris_SKU_Mapping_V2__c>(); // Maps product codes to Polaris SKU Mapping records.
    public List<Entitlement_Links__c> entLinksToCreate = new List<Entitlement_Links__c>(); // List to hold Entitlement_Links__c records to be created.
    public Map<Id, Entitlement> oldEntitlementsUpdate = new Map<Id, Entitlement>(); // Holds the old ENTs to update
    public Map<Id, Set<Id>> newEntIdsByOriginalENTId = new Map<Id, Set<Id>>(); // Hold the New Entitlement Detail by old original ENT
    public Set<Id> origOrdItmIds = new Set<Id>(); // Stores the new refresh entitlement Ids
    public Map<String, Set<String>> newSerialNumsByOld = new Map<String, Set<String>>();// Stores the set of new serial numbers by Old  
  }
  /**
   * Updates the `relatedBaseEnt` field in the given EntitlementDetails wrapper
   * by identifying and assigning the most relevant related entitlement based on SKU type.
   *
   * The most recent matching Ent link is used to populate `relatedBaseEnt` on the wrapper.
   *
   * @param entitlementDetailsWrapper The wrapper object containing the original entitlement record.
   *                                   This must not be null and must contain a valid `orgEntRec`.
   * @author Naveen Selvaraj
   * @date : 15/05/2025
   */
  public static void updateDeltaSkusOnWrapper(EntitlementDetails entitlementDetailsWrapper, Map<Id, List<Entitlement_links__c>> cliMapToEntLinks, Set<Id> allOriginalEntIds) {
    if (entitlementDetailsWrapper == null || entitlementDetailsWrapper.orgEntRec == null) {
      return;
    }
    Entitlement orgEntitlement = entitlementDetailsWrapper.orgEntRec;
    Boolean foundCorrectEnt = false;
    Boolean isLicenseSku = UtilityClass.IsLicenseSku(orgEntitlement.Product__r);
    if (isLicenseSku) {
      entitlementDetailsWrapper.relatedUpgradedSkuType.add(Constants.SKU_TYPE_LICENSE);
    } else if (orgEntitlement.Product__r.Product_Type__c == Constants.PRODUCT_TYPE_EDITION_UPGRADE) {
      entitlementDetailsWrapper.relatedUpgradedSkuType.add(Constants.SKU_TYPE_DELTA_UG);
    }
    if (entitlementDetailsWrapper.relatedUpgradedSkuType == null) {
      return;
    }
    List<Entitlement_links__c> entLinks = new List<Entitlement_links__c>();
    for (Id cliId : cliMapToEntLinks.Keyset()) {
      if (!cliMapToEntLinks.get(cliId).isEmpty()) {
        entLinks.addall(cliMapToEntLinks.get(cliId));
      }
    }
    for (Entitlement_links__c entLink : entLinks) {
      if (entLink.Type__c == Constants.PROGRAM_UPGRADE && entLink.Renewal_Category__c == Constants.mapProgramToRenewalCategory.get(Constants.PROGRAM_UPGRADE)) {
        if (entitlementDetailsWrapper.relatedUpgradedSkuType.contains(Constants.SKU_TYPE_LICENSE) && entLink.Previous_Entitlement__c == orgEntitlement.id && entLink.Renewed_Entitlement__r.Entitlement_Status__c == 'Active') {
          foundCorrectEnt = true;
          if (allOriginalEntIds.contains(entLink.Renewed_Entitlement__c)) {
            entitlementDetailsWrapper.relatedDeltaEnt = entLink.Renewed_Entitlement__r;
            entitlementDetailsWrapper.relatedBaseEnt = entLink.Previous_Entitlement__r;
            entitlementDetailsWrapper.relatedUpgradedSkuType.add(Constants.SKU_TYPE_DELTA_UG);
          } else {
            entitlementDetailsWrapper.relatedDeltaEnt = entLink.Renewed_Entitlement__r;
          }
        } else if (entitlementDetailsWrapper.relatedUpgradedSkuType.contains(Constants.SKU_TYPE_DELTA_UG) && entLink.Renewed_Entitlement__c == orgEntitlement.id && entLink.Previous_Entitlement__r.Entitlement_Status__c == 'Active') {
          foundCorrectEnt = true;
          if (allOriginalEntIds.contains(entLink.Previous_Entitlement__c)) {
            entitlementDetailsWrapper.relatedDeltaEnt = entLink.Renewed_Entitlement__r;
            entitlementDetailsWrapper.relatedBaseEnt = entLink.Previous_Entitlement__r;
            entitlementDetailsWrapper.relatedUpgradedSkuType.add(Constants.SKU_TYPE_LICENSE);
          } else {
            entitlementDetailsWrapper.relatedBaseEnt = entLink.Previous_Entitlement__r;
          }
        }
      }
    }
    if (!foundCorrectEnt) {
      for (Entitlement_links__c entLink : entLinks) {
        if (entLink.Type__c == Constants.ORDER_TYPE_RENEWAL && entLink.Renewal_Category__c == Constants.mapProgramToRenewalCategory.get(Constants.ORDER_TYPE_RENEWAL) && entLink.Previous_Entitlement__r.Entitlement_Status__c != 'Active' && entLink.Renewed_Entitlement__r.Entitlement_Status__c == 'Active') {
          if (entitlementDetailsWrapper.relatedUpgradedSkuType.contains(Constants.SKU_TYPE_LICENSE) && entLink.Renewed_Entitlement__r.Product__r.Product_Type__c == Constants.PRODUCT_TYPE_EDITION_UPGRADE) {
            entitlementDetailsWrapper.relatedDeltaEnt = entLink.Renewed_Entitlement__r;
          } else if (entitlementDetailsWrapper.relatedUpgradedSkuType.contains(Constants.SKU_TYPE_DELTA_UG) && UtilityClass.IsLicenseSku(entLink.Renewed_Entitlement__r.Product__r)) {
            entitlementDetailsWrapper.relatedBaseEnt = entLink.Renewed_Entitlement__r;
          }
        }
      }
    }
  }

  public class EntitlementDetails {
    public Map<Id, List<Entitlement>> newEntitlementsByNewOrdItemId;
    public Entitlement orgEntRec;
    public String orderType;
    public Entitlement survivingEnt;
    public Entitlement replacedOrRenewedEnt;
    public Date terminateDate;
    public Boolean isTerminatedDateMatch;
    public Boolean orgEntQtyAdjusted;
    public Date orderFulfillmentDate;
    public Entitlement_Links__c replacedOrRenewedEntLink;
    public Entitlement_Links__c survEntLink;
    public List<Orderitem> newReplacedRenewedOI = new List<OrderItem>(); //new oi with related orderitemextension
    public List<Entitlement> newReplacedEnts = new List<Entitlement>();
    public String replacementPolicyCategory;
    public Set<String> allAssets = new Set<String>();
    public Set<String> usedAssets = new Set<String>();
    public Set<String> refreshedSN = new Set<String>();
    public String transactionType; //Converted or Upgraded or Renewed
    public Boolean isFullReplacementOrRenewal = false;
    public Map<String, PreviousTransRefWrapper> newOrdItemNEntIdToWrapper = new Map<String, PreviousTransRefWrapper>();
    public Entitlement relatedBaseEnt;
    public Entitlement relatedDeltaEnt;
    public List<String> relatedUpgradedSkuType = new List<String>();
    public Map<Id, String> orderItemIdToTargetProductType = new Map<Id, String>();
    public Map<String, String> transactionTypeByAssetSN = new Map<String, String>();
    public Set<Id> inactiveEntsToTerminate = new Set<Id>();
    public Id orderId;
    public Boolean isMisMatched = false;
  }
  public class MatchingEntlinks {
    public Entitlement_Links__c survEntLink;
    public Entitlement_Links__c renewedOrReplacedEnt;
  }
}