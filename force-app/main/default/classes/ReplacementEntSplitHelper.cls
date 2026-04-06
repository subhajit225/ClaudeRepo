/*******************************************************************************
 * @description       : Helper class for handling asset and entitlement linkage logic
 *                      used in ReplacementEntSplitManager during entitlement splits
 *                      and replacements in the Replacement Framework.
 * @created on        : 15-04-2025
 * @created by        : Naveen Selvaraj
 * Test class         : ContractOrders_Test
 * *****************************************************************************
 * History
 * Date                Modification           Author
 * 15-04-2025          FY25SR-1212             naveenkumar.selvaraj@rubrik.com
 *******************************************************************************
 */
public class ReplacementEntSplitHelper { 

  // Flags to determine the order booking and fulfillment scenario
  public static Boolean isOrderBookedAndFulfilledOnFirst { get; private set; }
  public static Boolean isOrderBookedAndFulfilledAfterFirst { get; private set; }
  public static Boolean isOrderBookedAndFulfilledInDifferentMonth { get; private set; }

  /**
   * Handles updating the Renewal Category on existing linked assets
   * for original entitlements that were fully replaced.
   *
   * @param orgEntDetailsWrapper    EntitlementDetails object containing original entitlement and metadata.
   * @param entToLinkedAssets       Map of entitlement IDs to their existing linked assets.
   * @param linkedAssetsToUpsert    List of linked assets to update or insert.
   */
  public static void handleAssetLinkageForFullReplacement(
    ReplacementEntSplitManager.EntitlementDetails orgEntDetailsWrapper,
    Map<Id, List<Scale_Entitlement__c>> entToLinkedAssets,
    List<Scale_Entitlement__c> linkedAssetsToUpsert,
    Map<String, Entitlement> entToUpsert,
    String originalEntId
  ) {
    Entitlement inactiveEnt = entToUpsert.containsKey(originalEntId+'-'+Constants.ENT_INACTIVE) ? entToUpsert.get(originalEntId+'-'+Constants.ENT_INACTIVE) : null;
    List<Scale_Entitlement__c> linkedAssetsToProcess = new List<Scale_Entitlement__c>();
    if(orgEntDetailsWrapper.orgEntRec != null && entToLinkedAssets.containsKey(orgEntDetailsWrapper.orgEntRec.Id)){
      linkedAssetsToProcess.addall(entToLinkedAssets.get(orgEntDetailsWrapper.orgEntRec.Id));
    }
    if(inactiveEnt != null && entToLinkedAssets.containsKey(inactiveEnt.Id)){
      linkedAssetsToProcess.addall(entToLinkedAssets.get(inactiveEnt.Id));
    }
    if (linkedAssetsToProcess != null && !linkedAssetsToProcess.isEmpty()){
      for (Scale_Entitlement__c linkAsset : linkedAssetsToProcess) {
        linkedAssetsToUpsert.add(
          new Scale_Entitlement__c(
            Id = linkAsset.Id,
            Renewal_Category__c = (orgEntDetailsWrapper.transactionTypeByAssetSN != null &&
              orgEntDetailsWrapper.transactionTypeByAssetSN.containskey(linkAsset.Asset__r.SerialNumber))
              ? orgEntDetailsWrapper.transactionTypeByAssetSN.get(linkAsset.Asset__r.SerialNumber)
              : orgEntDetailsWrapper.transactionType
          )
        );
      }
    }
  }

  /**
 * Links new entitlement records to assets based on a provided mapping from asset serial numbers to asset IDs.
 * Creates linkage records of type 'Non-Scale' and adds them to the provided list for later upsert.
 *
 * @param orgEntDetailsWrapper  Wrapper containing new entitlements and the list of used asset serial numbers.
 * @param assetNoToId           Map of asset serial numbers to corresponding Salesforce asset record IDs.
 * @param linkedAssetsToUpsert  Output list where newly created entitlement-to-asset linkage records will be added.
 */
  public static void handleAssetLinkageForNewEnts(
    ReplacementEntSplitManager.EntitlementDetails orgEntDetailsWrapper,
    Map<String, Id> assetNoToId,
    List<Scale_Entitlement__c> linkedAssetsToUpsert,
    Set<String> exitingLinkedAssetsKey
  ) {
      Map<String, String> previousScaleENTTypeByAsset = new Map<String, String>();
      List<Scale_Entitlement__c> scaleEntitlements = orgEntDetailsWrapper?.orgEntRec?.Scale_Entitlements__r;
      if (scaleEntitlements != null && !scaleEntitlements.isEmpty()) {
        for (Scale_Entitlement__c se : scaleEntitlements) {
            String serial = se?.Asset__r?.SerialNumber;
            if (serial != null) {
                previousScaleENTTypeByAsset.put(serial, se.Type__c);
            }
        }
      }
    
      for (Entitlement newReplacedEnt : orgEntDetailsWrapper.newReplacedEnts) {
         
      String targetProductType = orgEntDetailsWrapper.orderItemIdToTargetProductType != null && orgEntDetailsWrapper.orderItemIdToTargetProductType.containskey(newReplacedEnt.Order_Service_Item__c) ?
                                 orgEntDetailsWrapper.orderItemIdToTargetProductType.get(newReplacedEnt.Order_Service_Item__c)  : null;

      if(targetProductType != Constants.SKU_TYPE_HARDWARE){
         continue;
      }
      Boolean isRenewalOrder =
        newReplacedEnt.Order_Service_Item__r.Order.Type == Constants.ORDER_TYPE &&
        newReplacedEnt.Order_Service_Item__r.Order.Order_Sub_Type__c == Constants.ORDER_SUBTYPE_RENEWAL;
        if (newReplacedEnt.Product__r.SBQQSC__EntitlementConversion__c == Constants.PROD_ENTCON_ONE_PER_UNIT) {
            // bypass
             continue;
          }
          for (String assetSN : orgEntDetailsWrapper.usedAssets) {
              // In the case of a Renewal of Refresh or a Renewal of Renewal,
              // update the new Scale Entitlement's Type based on the previously linked Asset's Type  
              String scaleType = isRenewalOrder && previousScaleENTTypeByAsset.containsKey(assetSN) ? previousScaleENTTypeByAsset.get(assetSN) : 'Non-Scale';
              if (
                !exitingLinkedAssetsKey.contains(newReplacedEnt.id + '-' + assetSN) && 
                 ((newReplacedEnt.Order_Service_Item__r?.SerialNumber__c != null && newReplacedEnt.Order_Service_Item__r?.SerialNumber__c?.Contains(assetSN)) || 
                 (newReplacedEnt.Order_Service_Item__r?.Upgraded_From__c != null && newReplacedEnt.Order_Service_Item__r?.Upgraded_From__c?.Contains(assetSN)) ||
                  newReplacedEnt.Order_Service_Item__r?.SerialNumber__c == null)
                  ) {
          linkedAssetsToUpsert.add(UtilityClass.createLinkedAsset(newReplacedEnt, assetNoToId.get(assetSN), scaleType));
                  exitingLinkedAssetsKey.add(newReplacedEnt.id + '-' + assetSN);
              }
          }
      }
  }

  /**
   * Creates new linked assets for the surviving entitlement using the unused asset serial numbers.
   *
   * @param orgEntDetailsWrapper  EntitlementDetails object with asset info.
   * @param entRecord             Surviving entitlement record.
   * @param assetNoToId           Map of asset serial numbers to Asset IDs.
   * @param linkedAssetsToUpsert  List of linked assets to be inserted.
   */
  public static void handleAssetLinkageSurvivingNew(
    ReplacementEntSplitManager.EntitlementDetails orgEntDetailsWrapper,
    Entitlement entRecord,
    Map<String, Id> assetNoToId,
    List<Scale_Entitlement__c> linkedAssetsToUpsert
  ) {
    for (String assetSN : orgEntDetailsWrapper.allAssets) {
      if (!orgEntDetailsWrapper.usedAssets.contains(assetSN) && !orgEntDetailsWrapper.refreshedSN.contains(assetSN)) {
        linkedAssetsToUpsert.add(UtilityClass.createLinkedAsset(entRecord, assetNoToId.get(assetSN), 'Non-Scale'));
      }
    }
  }

  /**
   * Handles linked asset updates and creations for a newly created replacement entitlement.
   * Updates existing linked assets and creates new ones for used assets.
   *
   * @param orgEntDetailsWrapper  EntitlementDetails object containing original and used asset data.
   * @param entRecord             The new replacement entitlement record.
   * @param entToLinkedAssets      Map of entitlement ID to existing linked assets.
   * @param assetNoToId           Map of asset serial numbers to Asset IDs.
   * @param linkedAssetsToUpsert  List of linked assets to be updated/inserted.
   */    
  public static void handleAssetLinkageReplacedNew(
    ReplacementEntSplitManager.EntitlementDetails orgEntDetailsWrapper,
    Entitlement entRecord,
    Map<Id, List<Scale_Entitlement__c>> entToLinkedAssets,
    Map<String, Id> assetNoToId,
    List<Scale_Entitlement__c> linkedAssetsToUpsert
  ) {
    if (orgEntDetailsWrapper.orgEntRec != null && entToLinkedAssets.containsKey(orgEntDetailsWrapper.orgEntRec.Id)) {
      for (Scale_Entitlement__c linkAsset : entToLinkedAssets.get(orgEntDetailsWrapper.orgEntRec.Id)) {
        linkedAssetsToUpsert.add(
          new Scale_Entitlement__c(
            Id = linkAsset.Id,
            Renewal_Category__c = (orgEntDetailsWrapper.transactionTypeByAssetSN != null &&
              orgEntDetailsWrapper.transactionTypeByAssetSN.containskey(linkAsset.Asset__r.SerialNumber))
              ? orgEntDetailsWrapper.transactionTypeByAssetSN.get(linkAsset.Asset__r.SerialNumber)
              : orgEntDetailsWrapper.transactionType
          )
        );
      }
    }
    if (orgEntDetailsWrapper.orderItemIdToTargetProductType != null && orgEntDetailsWrapper.orderItemIdToTargetProductType?.values()?.contains(Constants.SKU_TYPE_HARDWARE)) {
    for (String assetSN : orgEntDetailsWrapper.usedAssets) {
      linkedAssetsToUpsert.add(UtilityClass.createLinkedAsset(entRecord, assetNoToId.get(assetSN), 'Non-Scale'));
    }
  }
  }

  /**
   * Creates new linked assets for the old entitlement (Ent 1.1) when quantity is adjusted.
   *
   * @param orgEntDetailsWrapper EntitlementDetails containing used asset serials.
   * @param entRecord            The entitlement being adjusted.
   * @param assetNoToId          Map of asset serial numbers to Asset IDs.
   * @param linkedAssetsToUpsert List of linked assets to be inserted.
   */
  public static void handleAssetLinkageReplacedOld(
    ReplacementEntSplitManager.EntitlementDetails orgEntDetailsWrapper,
    Entitlement entRecord,
    Map<String, Id> assetNoToId,
    List<Scale_Entitlement__c> linkedAssetsToUpsert
  ) {
    for (String assetSN : orgEntDetailsWrapper.usedAssets) {
      linkedAssetsToUpsert.add(UtilityClass.createLinkedAsset(entRecord, assetNoToId.get(assetSN), 'Non-Scale'));
    }
  }

  /**
   * Updates linked assets that need to be removed from the surviving entitlement
   * by marking them with the new renewal category.
   *
   * @param orgEntDetailsWrapper  EntitlementDetails object with surviving entitlement info.
   * @param entToLinkedAssets     Map of entitlements to their linked assets.
   * @param linkedAssetsToUpsert  List of linked assets to update.
   */
  public static void handleAssetLinkageSurvivingOld(
    ReplacementEntSplitManager.EntitlementDetails orgEntDetailsWrapper,
    Map<Id, List<Scale_Entitlement__c>> entToLinkedAssets,
    List<Scale_Entitlement__c> linkedAssetsToUpsert
  ) {
    if (orgEntDetailsWrapper.survivingEnt != null && entToLinkedAssets.containsKey(orgEntDetailsWrapper.survivingEnt.Id)) {
      for (Scale_Entitlement__c linkAsset : entToLinkedAssets.get(orgEntDetailsWrapper.survivingEnt.Id)) {
        if (orgEntDetailsWrapper.usedAssets.contains(linkAsset.Asset__r.SerialNumber)) {
          linkedAssetsToUpsert.add(
            new Scale_Entitlement__c(
              Id = linkAsset.Id,
              Renewal_Category__c = (orgEntDetailsWrapper.transactionTypeByAssetSN != null &&
                orgEntDetailsWrapper.transactionTypeByAssetSN.containskey(linkAsset.Asset__r.SerialNumber))
                ? orgEntDetailsWrapper.transactionTypeByAssetSN.get(linkAsset.Asset__r.SerialNumber)
                : orgEntDetailsWrapper.transactionType,
              Type__c = 'Non-Scale'
            )
          );
        }
      }
    }
  }
    
  /**
   * Handles entitlement linking for full replacements.
   * Creates links from the original entitlement to each newly replaced entitlement.
   *
   * @param entRecord                 The original entitlement record.
   * @param orgEntDetailsWrapper      Wrapper containing all original entitlement details.
   * @param entLinksToCreate          List to append newly created entitlement link records.
   * @param mapProductToPolarisMappings  Mapping between product names and Polaris mappings.
   * @param orgEntIdToWrap            all oldEnt with its related wrapper 
   * @param ugLinksCreatedAlready     links b/w Ent A and B to avoid duplicate check 
   */
  public static void handleEntLinkFullReplacement(
    Entitlement entRecord,
    ReplacementEntSplitManager.EntitlementDetails orgEntDetailsWrapper,
    List<Entitlement_Links__c> entLinksToCreate,
    Map<String, Polaris_SKU_Mapping_V2__c> mapProductToPolarisMappings,
    Map<Id, ReplacementEntSplitManager.EntitlementDetails> orgEntIdToWrap,
    Set<String> ugLinksCreatedAlready
  ) {
    for (Entitlement newReplacedEnt : orgEntDetailsWrapper.newReplacedEnts) {
      String replacedLinkType = orgEntDetailsWrapper.orderType == Constants.ORDER_TYPE_RENEWAL ? Constants.ORDER_TYPE_RENEWAL : newReplacedEnt.Order_Service_Item__r.Program__c;
      String renewalCategory =  replacedLinkType == Constants.ORDER_TYPE_RENEWAL ? Constants.ENT_RENEWAL_CATEGORY_RENEWED  : replacedLinkType == Constants.PROGRAM_UPGRADE ? 'Upgraded' : replacedLinkType == Constants.PROGRAM_CONVERSION ? 'Converted' : null;
      entLinksToCreate.add(
        UtilityClass.createEntitlementLink(
          entRecord,
          newReplacedEnt,
          renewalCategory, 
          replacedLinkType, 
          mapProductToPolarisMappings,
          orgEntDetailsWrapper.newOrdItemNEntIdToWrapper,
          orgEntDetailsWrapper.orgEntRec.Id,
          new OrderItem(Id = newReplacedEnt.Order_Service_Item__c)
        )
      );
      if (orgEntDetailsWrapper.relatedUpgradedSkuType != null && orgEntDetailsWrapper.relatedUpgradedSkuType.size() > 0) {
        createLinkageforUpgradeSkus(
          orgEntDetailsWrapper,
          entLinksToCreate,
          mapProductToPolarisMappings,
          newReplacedEnt,
          renewalCategory,
          replacedLinkType,
          orgEntIdToWrap,
          ugLinksCreatedAlready
        );
      }
    }
  }

  /**
   * Handles linking of newly created split surviving entitlement back to the original or surviving entitlement.
   *
   * @param orgEntDetailsWrapper      Wrapper containing entitlement details, including survivingEnt.
   * @param entRecord                 The new surviving entitlement being processed.
   * @param entLinksToCreate          List to append newly created entitlement link records.
   * @param mapProductToPolarisMappings  Mapping between product names and Polaris mappings.
   */
  public static void handleEntLinkSurvivingNewLink(
    ReplacementEntSplitManager.EntitlementDetails orgEntDetailsWrapper,
    Entitlement entRecord,
    List<Entitlement_Links__c> entLinksToCreate,
    Map<String, Polaris_SKU_Mapping_V2__c> mapProductToPolarisMappings
  ) {
    Entitlement sourceEnt = orgEntDetailsWrapper.survivingEnt != null ? orgEntDetailsWrapper.survivingEnt : orgEntDetailsWrapper.orgEntRec;
    if (sourceEnt != null && sourceEnt.Id != null) {
      entLinksToCreate.add(UtilityClass.createEntitlementLink(sourceEnt, entRecord, null, 'Split-Surviving', mapProductToPolarisMappings, null, null, null));
    }
  }
  /**
 * Creates entitlement links for inactive entitlements during split/renewal/upgrade/conversion.
 *
 * Links are created between:
 * - Inactive entitlement → Used/Leftover entitlements
 * - New surviving/replaced entitlements → Used/Leftover entitlements (if applicable)
 *
 * @param originalEntDetailsWrapper  Wrapper with original entitlement/order details
 * @param originalEntId              Id of the original entitlement
 * @param inactiveEnt                Inactive entitlement being processed
 * @param entLinksToCreate           Collector list for Entitlement_Links__c to insert
 * @param entToUpsert                Map of entitlements keyed by originalEntId + constant
 * @param renewalCategory            Renewal category (Renewed/Upgraded/Converted)
 * @param mapProductToPolarisMappings Product to Polaris SKU mappings
 */
  public static void handleEntlinkInactiveEnt(
    ReplacementEntSplitManager.EntitlementDetails originalEntDetailsWrapper,
    Id originalEntId,
    Entitlement inactiveEnt,
    List<Entitlement_Links__c> entLinksToCreate,
    Map<String, Entitlement> entToUpsert,
    String renewalCategory,
    Map<String, Polaris_SKU_Mapping_V2__c> mapProductToPolarisMappings
  ) {
    Entitlement usedInactiveEnt = entToUpsert.get(originalEntId + '-' + Constants.ENT_INACTIVE_USED);
    Entitlement leftInactiveEnt = entToUpsert.get(originalEntId + '-' + Constants.ENT_INACTIVE_LEFT);
    Entitlement newReplacedOrRenewedEnt = entToUpsert.get(originalEntId + '-' + Constants.ENT_KEY_REPLACED_OR_RENEWED_NEW);
    Entitlement newSurvivingEnt = entToUpsert.get(originalEntId + '-' + Constants.ENT_KEY_SURVIVING_NEW);

    // Map renewalCategory to link type
    //
    Entitlement newReplacedEnt = originalEntDetailsWrapper.newReplacedEnts != null && !originalEntDetailsWrapper.newReplacedEnts.isEmpty()
      ? originalEntDetailsWrapper.newReplacedEnts[0]
      : null;
    String linkType = renewalCategory == Constants.ENT_RENEWAL_CATEGORY_RENEWED
      ? Constants.ENT_LINK_TYPE_SPLIT_RENEWAL
      : renewalCategory == Constants.UPGRADED_STATUS
          ? Constants.ENT_LINK_TYPE_SPLIT_UPGRADE
          : renewalCategory == Constants.CONVERTED_STATUS ? Constants.ENT_LINK_TYPE_SPLIT_CONVERSION : null;
    String replacedLinkType = originalEntDetailsWrapper.orderType == Constants.ORDER_TYPE_RENEWAL
      ? Constants.ORDER_TYPE_RENEWAL
      : newReplacedEnt != null ? newReplacedEnt.Order_Service_Item__r.Program__c : null;
    if (inactiveEnt == null)
      return;

    // Handle Used Entitlement
    if (usedInactiveEnt != null) {
      entLinksToCreate.add(UtilityClass.createEntitlementLink(inactiveEnt, usedInactiveEnt, renewalCategory, linkType, mapProductToPolarisMappings, null, null, null));
      if (newSurvivingEnt != null && newReplacedOrRenewedEnt != null) {
        entLinksToCreate.add(
          UtilityClass.createEntitlementLink(newReplacedOrRenewedEnt, usedInactiveEnt, Constants.ENT_RENEWAL_CATEGORY_RENEWED, Constants.ORDER_SUBTYPE_RENEWAL, mapProductToPolarisMappings, null, null, null)
        );
      }
    }
    // Handle Leftover Entitlement
    if (leftInactiveEnt != null) {
      entLinksToCreate.add(
        UtilityClass.createEntitlementLink(inactiveEnt, leftInactiveEnt, null, Constants.ENT_LINK_TYPE_SPLIT_SURVIVING, mapProductToPolarisMappings, null, null, null)
      );
      if (newSurvivingEnt != null) {
        entLinksToCreate.add(
          UtilityClass.createEntitlementLink(newSurvivingEnt, leftInactiveEnt, Constants.ENT_RENEWAL_CATEGORY_RENEWED, Constants.ORDER_SUBTYPE_RENEWAL, mapProductToPolarisMappings, null, null, null)
        );
      }
    }
  }

  /**
   * Handles links from surviving entitlement to the split (replaced) entitlement,
   * and from the split entitlement to its new target entitlement(s).
   *
   * @param orgEntDetailsWrapper      Wrapper containing entitlement context and new replaced entitlements.
   * @param entRecord                 The new split entitlement (e.g., Ent 1.1).
   * @param entLinksToCreate          List to append newly created entitlement link records.
   * @param mapProductToPolarisMappings  Mapping between product names and Polaris mappings.
   * @param renewalCategory           The renewal category ('Converted', 'Upgraded', etc.).
   * @param orgEntIdToWrap            all oldEnt with its related wrapper 
   * @param ugLinksCreatedAlready     links b/w Ent A and B to avoid duplicate check 
   */
  public static void handleEntLinkReplacedNewLink(
    ReplacementEntSplitManager.EntitlementDetails orgEntDetailsWrapper,
    Entitlement entRecord,
    List<Entitlement_Links__c> entLinksToCreate,
    Map<String, Polaris_SKU_Mapping_V2__c> mapProductToPolarisMappings,
    String renewalCategory,
    Map<Id, ReplacementEntSplitManager.EntitlementDetails> orgEntIdToWrap,
    Set<String> ugLinksCreatedAlready
  ) {
    // Link from surviving entitlement to split replacement
    String linkType = renewalCategory == 'Renewed' ? 'Split-Renewal' : renewalCategory == 'Upgraded' ? 'Split-Upgrade' : renewalCategory == 'Converted' ? 'Split-Conversion' : null;

    entLinksToCreate.add(UtilityClass.createEntitlementLink(orgEntDetailsWrapper.survivingEnt, entRecord, null, linkType, mapProductToPolarisMappings, null, null, null));

    // Links from split entitlement to replacement targets (e.g., Ent 1.1 → Ent A)
    for (Entitlement newReplacedEnt : orgEntDetailsWrapper.newReplacedEnts) {
      String replacedLinkType = orgEntDetailsWrapper.orderType == Constants.ORDER_TYPE_RENEWAL ? Constants.ORDER_TYPE_RENEWAL : newReplacedEnt.Order_Service_Item__r.Program__c;
      renewalCategory =  replacedLinkType == Constants.ORDER_TYPE_RENEWAL ? Constants.ENT_RENEWAL_CATEGORY_RENEWED  : replacedLinkType == Constants.PROGRAM_UPGRADE ? 'Upgraded' : replacedLinkType == Constants.PROGRAM_CONVERSION ? 'Converted' : null;
      entLinksToCreate.add(
        UtilityClass.createEntitlementLink(
          entRecord,
          newReplacedEnt,
          renewalCategory,
          replacedLinkType,
          mapProductToPolarisMappings,
          orgEntDetailsWrapper.newOrdItemNEntIdToWrapper,
          orgEntDetailsWrapper.orgEntRec.Id,
          new OrderItem(Id = newReplacedEnt.Order_Service_Item__c)
        )
      );
      if (orgEntDetailsWrapper.relatedUpgradedSkuType != null && orgEntDetailsWrapper.relatedUpgradedSkuType.size() > 0) {
        createLinkageforUpgradeSkus(
          orgEntDetailsWrapper,
          entLinksToCreate,
          mapProductToPolarisMappings,
          newReplacedEnt,
          renewalCategory,
          replacedLinkType,
          orgEntIdToWrap,
          ugLinksCreatedAlready
        );
      }
    }
  }

  /**
   * Handles linking from an older replaced entitlement (adjusted) to the new replacement entitlement(s).
   * This supports updates in legacy or test-based scenarios.
   *
   * @param entRecord                 The old entitlement record that has been adjusted.
   * @param orgEntDetailsWrapper      Wrapper containing new replacement entitlements.
   * @param entLinksToCreate          List to append newly created entitlement link records.
   * @param mapProductToPolarisMappings  Mapping between product names and Polaris mappings.
   * @param renewalCategory           The renewal category ('Converted', 'Upgraded', etc.).
   */
  public static void handleEntLinkReplacedOldLink(
    Entitlement entRecord,
    ReplacementEntSplitManager.EntitlementDetails orgEntDetailsWrapper,
    List<Entitlement_Links__c> entLinksToCreate,
    Map<String, Polaris_SKU_Mapping_V2__c> mapProductToPolarisMappings,
    String renewalCategory
  ) {
    for (Entitlement newReplacedEnt : orgEntDetailsWrapper.newReplacedEnts) {
      String replacedLinkType = renewalCategory == 'Renewed' ? 'Renewal' : renewalCategory == 'Upgraded' ? 'Upgrade' : renewalCategory == 'Converted' ? 'Conversion' : null;
      entLinksToCreate.add(UtilityClass.createEntitlementLink(entRecord, newReplacedEnt, renewalCategory, replacedLinkType, mapProductToPolarisMappings, orgEntDetailsWrapper.newOrdItemNEntIdToWrapper, orgEntDetailsWrapper.orgEntRec.Id, new OrderItem(Id = newReplacedEnt.Order_Service_Item__c)));
    }
  }
    
  /**
   * Method to populate {entidsToSNSet} with Asset Serial Numbers corresponding to old Entitlements.
   *
   * <p>This method processes entitlement and linked asset data to map original entitlement IDs
   * to their associated Asset Serial Numbers.</p>
   *
   * @param orgEntIdToWrap     Map or wrapper containing original entitlement details and related asset information.
   * @param entidsToSNSet      Map or set structure used to capture Asset Serial Numbers by old entitlement ID.
   * @param entToLinkedAssets   Map of Entitlement IDs to their corresponding Linked Asset information.
   * @param assetSNForEnts     Map of old Entitlement IDs to associated Asset Serial Numbers.
   *
   * @return Updates {entidsToSNSet} with Asset Serial Numbers corresponding to each old entitlement.
   *
   * @author Naveen Selvaraj
   * @date 15-04-2025
   */
  public static void getSerialNumbersByEntId(
    Map<Id, ReplacementEntSplitManager.EntitlementDetails> origEntIdToWrap,
    Map<Id, Set<String>> entidsToSNSet,
    Map<Id, List<Scale_Entitlement__c>> entToLinkedAssets,
    Map<Id, Set<String>> assetSNForEnts
  ) {
      for (Id orgEntId : origEntIdToWrap.KeySet()) {
        Entitlement orgEnt = origEntIdToWrap.get(orgEntId).OrgEntRec;
      if (orgEnt.Product__r.Product_Level__c == null) {
        // Collect SN's for V1 sku's
        if (!entidsToSNSet.containskey(orgEnt.id)) {
          entidsToSNSet.put(orgEnt.id, new Set<String>{ orgEnt.Asset.SerialNumber });
        }
      }
      }
      if (!entToLinkedAssets.values().isEmpty()) {
        for (Id entId : entToLinkedAssets.keyset()) {
          Set<String> refreshSN = new Set<String>();
          for (Scale_Entitlement__c la : entToLinkedAssets.get(entId)) {
            // Collect SN's for V2 sku's through Linked Asset
            if (!entidsToSNSet.containskey(entId)) {
              entidsToSNSet.put(entId, new Set<String>());
            }
            entidsToSNSet.get(entId).add(la.Asset__r.SerialNumber);

            //Collecing the Refresh SN from Original Ent
            if(la.Type__c == Constants.SCALE_ENT_TYPE_REFRESHED_BASE_LICENSE){
               refreshSN.add(la.Asset__r.SerialNumber);
            }      
          }
          if(origEntIdToWrap.containskey(entId)){
            origEntIdToWrap.get(entId).refreshedSN = refreshSN;  
          }
        }
      }
      if (assetSNForEnts.keyset().size() > 0) {
        for (Id entId : assetSNForEnts.keyset()) {
          if (!entidsToSNSet.containskey(entId)) {
            entidsToSNSet.put(entId, new Set<String>());
          }
          entidsToSNSet.get(entId).addall(assetSNForEnts.get(entId));
        }
      }
    }
  /**
   * Creates entitlement linkage records for upgraded SKUs during a renewal process.
   *
   * @param orgEntDetailsWrapper               Wrapper object containing details about the original entitlements,
   *                                           including related upgrade types and associated records.
   * @param entLinksToCreate                   A list to which the newly created Entitlement_Links__c records will be added.
   * @param mapProductToPolarisMappings        A map of product codes to Polaris SKU mappings, used for metadata or categorization during linking.
   * @param newReplacedEnt                     The new entitlement object that is replacing or renewing the original entitlement.
   * @param orgEntIdToWrap                     all oldEnt with its related wrapper 
   * @param ugLinksCreatedAlready              links b/w Ent A and B to avoid duplicate check 
   * @author NaveenSelvaraj
   * @date 19/05/2025
   */
  public static void createLinkageforUpgradeSkus(
    ReplacementEntSplitManager.EntitlementDetails origEntDetailsWrapper,
    List<Entitlement_Links__c> entLinksToCreate,
    Map<String, Polaris_SKU_Mapping_V2__c> mapProductToPolarisMappings,
    Entitlement newReplacedEnt,
    String RenewalCategory,
    String entLinkType,
    Map<Id, ReplacementEntSplitManager.EntitlementDetails> orgEntIdToWrap,
    Set<String> ugLinksCreatedAlready
  ) {
    if (origEntDetailsWrapper.relatedUpgradedSkuType.size() <= 1) {
      Entitlement sourceEnt = origEntDetailsWrapper.relatedUpgradedSkuType.contains(Constants.SKU_TYPE_LICENSE)
        ? origEntDetailsWrapper.relatedDeltaEnt
        : origEntDetailsWrapper.relatedUpgradedSkuType.contains(Constants.SKU_TYPE_DELTA_UG) ? origEntDetailsWrapper.relatedBaseEnt : null;
      if (sourceEnt != null) {
        entLinksToCreate.add(
          UtilityClass.createEntitlementLink(
            sourceEnt,
            newReplacedEnt,
            RenewalCategory,
            entLinkType,
            mapProductToPolarisMappings,
            origEntDetailsWrapper.newOrdItemNEntIdToWrapper,
            origEntDetailsWrapper.orgEntRec.Id,
            new OrderItem(Id = newReplacedEnt.Order_Service_Item__c)
          )
        );
      }
    } else {
        if (!ugLinksCreatedAlready.contains(origEntDetailsWrapper.relatedBaseEnt.Id + '-' + origEntDetailsWrapper.relatedDeltaEnt.Id)) {
        Entitlement sourceEnt = orgEntIdToWrap.containskey(origEntDetailsWrapper.relatedBaseEnt.Id) &&
          !orgEntIdToWrap.get(origEntDetailsWrapper.relatedBaseEnt.Id).newReplacedEnts.isEmpty()
          ? orgEntIdToWrap.get(origEntDetailsWrapper.relatedBaseEnt.Id).newReplacedEnts[0]
          : null;
        Entitlement targetEnt = orgEntIdToWrap.containskey(origEntDetailsWrapper.relatedDeltaEnt.Id) &&
          !orgEntIdToWrap.get(origEntDetailsWrapper.relatedDeltaEnt.Id).newReplacedEnts.isEmpty()
          ? orgEntIdToWrap.get(origEntDetailsWrapper.relatedDeltaEnt.Id).newReplacedEnts[0]
          : null;
        entLinksToCreate.add(
          UtilityClass.createEntitlementLink(
            sourceEnt,
            targetEnt,
            Constants.mapProgramToRenewalCategory.get(Constants.PROGRAM_UPGRADE),
            Constants.PROGRAM_UPGRADE,
            mapProductToPolarisMappings,
            origEntDetailsWrapper.newOrdItemNEntIdToWrapper,
            origEntDetailsWrapper.orgEntRec.Id,
            new OrderItem(Id = newReplacedEnt.Order_Service_Item__c)
          )
        );
        ugLinksCreatedAlready.add(origEntDetailsWrapper.relatedBaseEnt.Id + '-' + origEntDetailsWrapper.relatedDeltaEnt.Id);
      }
    }
  }

  /**
   * Constructs an instance of getTerminateDateBasedRepPolicy to evaluate the replacement policy category
   * and termination date based on entitlement details and associated order information.
   * Ensures accurate classification of replacement scenarios using predefined mappings.
   * @author Ravi Mali
   * @param entWrap EntitlementDetails - Wrapper containing entitlement data, including order items and extensions.
   * @return void
   */
  public static void getTerminateDateBasedRepPolicy(
    ReplacementEntSplitManager.EntitlementDetails entWrap,
    Map<Id, List<Entitlement>> repOrderItemToEntitlements,
    Map<Id, OrderItem> oldReplacedOrderItemById,
    List<Error_Logs__c> lstofErrorLogs
  ) {
    final String METHOD_GET_TERMINATE_DATE_BASED_REP_POLICY = 'getTerminateDateBasedRepPolicy';

    if (entWrap == null || entWrap.newReplacedRenewedOI.isEmpty()) {
      lstofErrorLogs.add(
        UtilityClass.createlogExceptionRecord(
          null,
          Constants.ENTITLEMENT_MANAGER_CLASS,
          METHOD_GET_TERMINATE_DATE_BASED_REP_POLICY,
          'Entitlement',
          entWrap.orderId,
          'Data Issue',
          false,
          Constants.ERROR_INVALID_ENT_DETAILS_WRAPPER
        )
      );
      return;
    }

    OrderItem newReplacedOI = entWrap.newReplacedRenewedOI[0];
    Entitlement oldENT = entWrap?.orgEntRec;
    if (oldEnt != null && oldEnt.Status == Constants.ENT_STATUS_EXPIRED) {
      entWrap.terminateDate = oldEnt.Enddate;
      return;
    }

    if (newReplacedOI?.Order?.Order_Accepted_Timestamp__c == null || newReplacedOI?.Order?.Actual_Order_Ship_Date__c == null) {
      lstofErrorLogs.add(UtilityClass.createlogExceptionRecord(null, Constants.ENTITLEMENT_MANAGER_CLASS, METHOD_GET_TERMINATE_DATE_BASED_REP_POLICY, 'Order',entWrap.orderId,'Data Issue',false,Constants.ERROR_ORDER_ACCEPTED_SHIP_DATES_MISSING));
    }
    // Evaluate booking and fulfillment scenario
    evaluateBookingAndFulfillmentScenario(newReplacedOI?.Order?.Order_Accepted_Timestamp__c.date(), newReplacedOI?.Order?.Actual_Order_Ship_Date__c);

    Entitlement newReplacedEnt = repOrderItemToEntitlements.containsKey(newReplacedOI.Id) && repOrderItemToEntitlements.get(newReplacedOI.Id).size() > 0
      ? repOrderItemToEntitlements.get(newReplacedOI.Id)[0]
      : null;
    if (newReplacedEnt == null) {
      lstofErrorLogs.add(
        UtilityClass.createlogExceptionRecord(
          null,
          Constants.ENTITLEMENT_MANAGER_CLASS,
          METHOD_GET_TERMINATE_DATE_BASED_REP_POLICY,
          'Entitlement',
          entWrap.orderId,
          'Data Issue',
          false,
          Constants.ERROR_REPLACEMENT_ENT_NOT_FOUND
        )
      );
    }

    Order_Item_Extension__c oiExtension;
    if (
      oldENT?.Order_Service_item__c != null &&
      oldReplacedOrderItemById.containsKey(oldENT.Order_Service_item__c) &&
      oldReplacedOrderItemById.get(oldENT.Order_Service_item__c) != null
    ) {
      OrderItem oldOI = oldReplacedOrderItemById.get(oldENT.Order_Service_item__c);
      oiExtension = (oldOI?.Order_Item_Extensions__r != null && oldOI?.Order_Item_Extensions__r.size() > 0) ? oldOI?.Order_Item_Extensions__r[0] : null;
    }

    if (oiExtension == null) {
      lstofErrorLogs.add(
        UtilityClass.createlogExceptionRecord(
          null,
          Constants.ENTITLEMENT_MANAGER_CLASS,
          METHOD_GET_TERMINATE_DATE_BASED_REP_POLICY,
          'Entitlement',
          entWrap.orderId,
          'Data Issue',
          false,
          Constants.ERROR_OI_EXTENSION_NOT_FOUND
        )
      );
      return;
    }

    Boolean isUpgrade = newReplacedOI.Program__c == Constants.PROGRAM_UPGRADE;
    Boolean isConversion = newReplacedOI.Program__c == Constants.PROGRAM_CONVERSION;
    Boolean standardPrepay = oiExtension.Payment_Schedule__c?.equalsIgnoreCase('Standard Prepay');
    Boolean withCredits = newReplacedOI.Credit_Amount__c != null && newReplacedOI.Credit_Amount__c > 0;

    Map<String, Map<String, String>> replacementPolicyMapping = new Map<String, Map<String, String>>{
      'upgrade' => new Map<String, String>{ 'withCredits' => '1A', 'prepayWithoutCredit' => '1B', 'payAnnualWithoutCredit' => '1D' },
      'conversion' => new Map<String, String>{ 'withCredits' => '2A', 'prepayWithoutCredit' => '2B', 'payAnnualWithoutCredit' => '2D' }
    };

    String categoryKey = isUpgrade ? 'upgrade' : 'conversion';
    String policyCategory = isOrderBookedAndFulfilledOnFirst
      ? 'Order Booked and Fulfilled on First: '
      : isOrderBookedAndFulfilledAfterFirst ? 'Order Booked and Fulfilled after First: ' : 'Order Booked in Different Month and Fulfilled Later: ';

    if ((isUpgrade || isConversion) && (isOrderBookedAndFulfilledOnFirst || isOrderBookedAndFulfilledAfterFirst || isOrderBookedAndFulfilledInDifferentMonth)) {
      if ((standardPrepay || !standardPrepay) && withCredits) {
        entWrap.terminateDate = isOrderBookedAndFulfilledAfterFirst ? newReplacedEnt.StartDate - 1 : newReplacedOI.Order.Actual_Order_Ship_Date__c;
        policyCategory += replacementPolicyMapping.get(categoryKey).get('withCredits');
      } else if (standardPrepay && !withCredits) {
        entWrap.terminateDate = entWrap.orgEntRec.Enddate;
        policyCategory += replacementPolicyMapping.get(categoryKey).get('prepayWithoutCredit');
      } else if (!standardPrepay && !withCredits) {
        entWrap.terminateDate = newReplacedEnt.StartDate - 1; // FY25SR-2323
        policyCategory += replacementPolicyMapping.get(categoryKey).get('payAnnualWithoutCredit');
      }

      // Populate the default Terminate Date using the original entitlement's End Date
      // if it hasn't already been set by the earlier category logic
      if (entWrap.terminateDate == null) {
        entWrap.terminateDate = entWrap.orgEntRec.EndDate;
      }
      entWrap.replacementPolicyCategory = policyCategory;
    }
  }

  /**
   * Evaluates the order booking and fulfillment scenario based on provided dates.
   * Sets scenario flags to accurately reflect booking and fulfillment conditions.
   *
   * @param orderAcceptedDate Date - The date when the order was accepted.
   * @param orderShippedDate Date - The date when the order was shipped.
   */
    private static void evaluateBookingAndFulfillmentScenario(Date orderAcceptedDate, Date orderShippedDate) {
    isOrderBookedAndFulfilledOnFirst = false;
    isOrderBookedAndFulfilledAfterFirst = false;
    isOrderBookedAndFulfilledInDifferentMonth = false;

    if (orderAcceptedDate != null && orderShippedDate != null) {
      if (orderAcceptedDate == orderShippedDate && orderAcceptedDate.day() == 1) {
        isOrderBookedAndFulfilledOnFirst = true;
      } else if (orderAcceptedDate.month() == orderShippedDate.month() && orderAcceptedDate.year() == orderShippedDate.year() && orderAcceptedDate.day() > 1) {
        isOrderBookedAndFulfilledAfterFirst = true;
      } else if (orderAcceptedDate.month() != orderShippedDate.month() || orderAcceptedDate.year() != orderShippedDate.year()) {
        isOrderBookedAndFulfilledInDifferentMonth = true;
      }
    }
  }

    /**
   * Creates an entitlement link between a newly refreshed entitlement and the original entitlement
   *
   * @param wrapper          Wrapper containing new refresh OrderItem details
   * @param oldENT           The original entitlement being linked from.
   * @param newRefreshedENT  The newly created refreshed entitlement.
   * @param isHwSuppSku      Flag indicating if the entitlement is for a HW support SKU.
   * @param oldNewEntIdKeys  Set tracking existing links to avoid duplicates.
   */
  public static void linkNewRefreshEntitlementToOriginal(
    ReplacementEntSplitManager.RefreshOrderItemsWrapper wrapper,
    Entitlement oldENT,
    Entitlement newRefreshedENT,
    Boolean isHwSuppSku,
    Set<String> oldNewEntIdKeys
  ) {
    String oldNewEntKey = oldENT.Id + '-' + newRefreshedENT.Id;
    if (!oldNewEntIdKeys.contains(oldNewEntKey)) {
      Entitlement entUpdate = new Entitlement(Id = oldENt.Id, Resync_Line__c = 'Required', Transaction_Type__c = Constants.ENT_TRANS_TYPE_REPLACEMENT_FRAMEWORK);
      if (isHwSuppSku) {
        entUpdate.Renewal_Category__c = Constants.ENT_RENEWAL_CATEGORY_REFRESHED;
      }
      wrapper.oldEntitlementsUpdate.put(oldENT.Id, entUpdate);

      wrapper.entLinksToCreate.add(
        UtilityClass.createEntitlementLink(
          oldENT,
          newRefreshedENT,
          Constants.ENT_RENEWAL_CATEGORY_REFRESHED,
          Constants.PROGRAM_REFRESH,
          wrapper.mapProductToPolarisMappings,
          null,
          null,
          null
        )
      );
      oldNewEntIdKeys.add(oldNewEntKey);
    }
  }

  /**
   * Links a refreshed delta entitlement to a new replacement or renewal license entitlement
   * when they appear together in the same quote. Ensures proper linkage during combined
   * refresh and replacement/renewal flows.
   *
   * @param wrapper             The wrapper containing refreh OrderItem details
   * @param oldOrgENTId         The original entitlement ID before the refresh.
   * @param newRefreshedENT     The delta entitlement generated from the refresh process.
   * @param oldNewEntIdKeys     A set used to track existing links and avoid duplication.
   */
  public static void linkRefreshDeltaToReplacementsOrRenewals(ReplacementEntSplitManager.RefreshOrderItemsWrapper wrapper, Id oldOrgENTId, Entitlement newRefreshedENT, Set<String> oldNewEntIdKeys) {
    if (UtilityClass.isLicenseSku(newRefreshedENT.Product__r) && wrapper.newEntIdsByOriginalENTId.containsKey(oldOrgENTId)) {
      for (Id newENTId : wrapper.newEntIdsByOriginalENTId.get(oldOrgENTId)) {
        Entitlement newReplacedENT = wrapper.allOldNewENTs.get(newENTId);

        if (oldNewEntIdKeys.contains(newReplacedENT.Id + '-' + newRefreshedENT.Id) || !isValidRefreshForReplacement(newRefreshedENT, newReplacedENT)) {
          continue; // Create links only if refresh & replacement upgraded by the same asset
        }

        wrapper.entLinksToCreate.add(
          UtilityClass.createEntitlementLink(
            newReplacedENT,
            newRefreshedENT,
            Constants.ENT_RENEWAL_CATEGORY_REFRESHED,
            Constants.PROGRAM_REFRESH,
            wrapper.mapProductToPolarisMappings,
            null,
            null,
            null
          )
        );
        oldNewEntIdKeys.add(newReplacedENT.Id + '-' + newRefreshedENT.Id);
      }
    }
  }

  /**
   * Checks whether there is any common (intersecting) asset serial number
   * between the provided old entitlement Scale assets and the upgraded assets
   * associated with a new Order Item.
   *
   * @param oldAssetSerials         Set of serial numbers linked to the old entitlement by Scale Ent
   * @param upgradedSerialsOnNew    Set of serial numbers from the new Order Item's Upgraded_From__c
   * @return true if there is at least one common asset serial number; false otherwise
   */
  public static Boolean hasCommonUpgradedAssets(Set<String> oldAssetSerials, Set<String> upgradedSerialsOnNew) {
    if (oldAssetSerials == null || upgradedSerialsOnNew == null)
      return false;
    Set<String> intersection = new Set<String>(oldAssetSerials);
    intersection.retainAll(upgradedSerialsOnNew);
    return !intersection.isEmpty();
  }
    /**
   * Checks whether any serial number from the Refreshed Entitlement's Upgraded_From__c
   * field is present in the Replaced Entitlement's Upgraded_From__c field.
   * Useful to determine if a basic match exists for linking Refresh and Replacement entitlements.
   *
   * @param newRefreshedENT The refreshed entitlement record containing serials to match.
   * @param newReplacedENT The replaced entitlement record to search for matching serials.
   * @return Boolean indicating whether any serial from the refreshed entitlement is found in the replaced entitlement.
   * @author Ravi Mali
   * @date 01/07/2025
   */
  public static Boolean isValidRefreshForReplacement(Entitlement newRefreshedENT, Entitlement newReplacedENT) {
    if (newRefreshedENT?.Order_Service_Item__r?.Upgraded_From__c == null || newReplacedENT?.Order_Service_Item__r?.Upgraded_From__c == null) {
      return false;
    }

    String refreshedUpgraded = newRefreshedENT.Order_Service_Item__r.Upgraded_From__c;
    String replacedUpgraded = newReplacedENT.Order_Service_Item__r.Upgraded_From__c;

    for (String serial : refreshedUpgraded.split(',')) {
      if (replacedUpgraded.contains(serial.trim())) {
        return true; // At least one match found
      }
    }

    return false; // No matches
  }

    /**
   * Retrieves Entitlement_Links__c records where the Previous_Entitlement__c matches
   * any of the provided old OrderItem IDs
   *
   * @param oldEntIds A set of entitlement IDs used to filter the Previous_Entitlement__c field.
   * @return A list of matching Entitlement_Links__c records with related fields populated.
   * @author Ravi Mali
   * @date 01/07/2025
   */
  public static List<Entitlement_Links__c> getEntitlementLinks(Set<Id> origOrdItmIds) {
    if (origOrdItmIds == null || origOrdItmIds.isEmpty()) {
      return new List<Entitlement_Links__c>();
    }

    return [
      SELECT
        Id,
        Type__c,
        Previous_Entitlement__c,
        Previous_Entitlement__r.Order_Service_Item__c,
        Renewed_Entitlement__r.Order_Service_Item__c,
        Renewed_Entitlement__r.Renewal_Category__c,
        Renewed_Entitlement__r.Product__r.Product_Level__c,
        Renewed_Entitlement__r.Id,
        Renewed_Entitlement__r.Product__c,
        Renewed_Entitlement__r.Quantity__c
      FROM Entitlement_Links__c
      WHERE Previous_Entitlement__r.Order_Service_Item__c IN :origOrdItmIds
    ];
  }

    /**
   * Handles linked asset creation logic for a single OrderItem during refresh or replacement/renewal license processing.
   * Also updates the new Serial # on the eligible license present on the quote based on the Upgraded By.
   */
  public static void handleLinkedAssetForNewOI(
    OrderItem OI,
    Map<String, Set<String>> newSerialNumsByOld,
    Map<Id, List<Entitlement>> entitlementsByOIId,
    Map<String, Asset> assetBySerialNumber,
    Map<Id, OrderItem> orderItemsToUpdate,
    Set<Scale_Entitlement__c> linkedAstToUpsert,
    Set<String> exitingLinkedAssetsKey,
    Boolean isContractOrdersBatchContext
  ) {
    Boolean isRefreshProgram = OI.Program__c == CONSTANTS.PROGRAM_REFRESH;
    //Checks if the Replacement/Refresh License or Renewal OI is refreshed(by Upgraded From)
    if ((UtilityClass.isRefreshedLicenseOI(OI) || OI.Line_Type__c == Constants.ORDER_TYPE_RENEWAL) && String.isNotBlank(OI.Upgraded_From__c)) {
      Set<String> newSerialNumbers = new Set<String>();
      List<String> replacedFromSerialNumbers = OI.Upgraded_From__c.split(',');

      for (String oldSN : replacedFromSerialNumbers) {
        oldSN = oldSN.trim();
        if (newSerialNumsByOld.containsKey(oldSN)) {
          newSerialNumbers.addAll(newSerialNumsByOld.get(oldSN));
        }
      }

      if (newSerialNumbers.isEmpty())
        return;

      //Aspen Order: Update serial numbers on the refreshed/replaced/Renewal OrderItem if it is being called from Order trigger
      if (!isContractOrdersBatchContext) {
        if (isRefreshProgram) {
          OI.SerialNumber__c = String.join(new List<String>(newSerialNumbers), ',');
          orderItemsToUpdate.put(OI.id, OI);
        } else if (Constants.REPLACEMENT_PROGRAMS.contains(OI.Program__c) || OI.Line_Type__c == Constants.ORDER_TYPE_RENEWAL) {
          // If replacement or/and Renewals occurs with the Refresh, remove the old SR and retain only the new SRs
          if (String.isNotBlank(OI?.SerialNumber__c)) {
            for (String SR : OI.SerialNumber__c.split(',')) {
              String trimmedSR = SR.trim();
              if (!replacedFromSerialNumbers.contains(trimmedSR)) {
                newSerialNumbers.add(trimmedSR);
              }
            }
          }
          OI.SerialNumber__c = String.join(new List<String>(newSerialNumbers), ',');
          orderItemsToUpdate.put(OI.Id, OI);
        }
      }

      //Find current License OI's corresponding ENT for the linked asset creation
      Entitlement OIENT = null;
      if (UtilityClass.isLicenseOrderItem(OI) && !entitlementsByOIId.isEmpty() && entitlementsByOIId.containsKey(OI.Id)) {
        for (Entitlement ENT : entitlementsByOIId.get(OI.Id)) {
          if (String.isNotBlank(ENT.Type) && ENT.Type == Constants.ENT_TYPE_PHONE_SUPPORT) {
            OIENT = ENT;
            break;
          }
        }
      }

      // Create a new linked asset for the refresh or replacement or renewal license line if all are upgraded from a common source Asset
      if (OIENT != null && String.isNotBlank(OIENT?.Id)) {
        String scaleEntType = isRefreshProgram ? Constants.SCALE_ENT_TYPE_REFRESHED_DELTA_LICENSE : Constants.SCALE_ENT_TYPE_REFRESHED_BASE_LICENSE;
        for (String newSN : newSerialNumbers) {
          if (assetBySerialNumber.containsKey(newSN) && assetBySerialNumber.get(newSN) != null && !exitingLinkedAssetsKey.contains(OIENT?.Id + '-' + newSN)) {
            linkedAstToUpsert.add(createScaleEntitlement(assetBySerialNumber.get(newSN).Id, OIENT.ContractLineItemId, OI.Id, OIENT.Id, scaleEntType));
            exitingLinkedAssetsKey.add(OIENT.Id + '-' + newSN);
          }
        }
      }
    }
  }

  /**
   * Handles linked asset creation and updates for old entitlements in V2 → V2 refresh scenarios.
  */
  public static void linkNewAssetOnOldV2Entitlement(
    List<Scale_Entitlement__c> oldLinkedAssets,
    Set<Id> entsToExcludeForScaleENT,
    Integer expiredEntitlementEligibility,
    Map<String, Set<String>> newSerialNumsByOld,
    Map<String, Asset> assetBySerialNumber,
    Map<Id, Asset> oldAssetsToUpdate,
    Set<Scale_Entitlement__c> linkedAstToUpsert,
    Set<String> exitingLinkedAssetsKey
  ) {
    for (Scale_Entitlement__c oldScaleENT : oldLinkedAssets) {
      Id oldENTId = oldScaleENT?.Entitlement__r.Id;
      Id oldCLIId = oldScaleENT?.Entitlement__r?.ContractLineItemId;
      Id oldOIId = oldScaleENT?.Order_Product__r.Id;

      //Update old Asset as a refreshed
      if (!oldAssetsToUpdate.containsKey(oldScaleENT?.Asset__c)) {
        oldAssetsToUpdate.put(oldScaleENT.Asset__c, new Asset(Id = oldScaleENT.Asset__c, Program__c = 'Refreshed'));
      }

      // Exclude the Original & Surviving ENT if replacement was partial and its end date is older than expiredEntitlementEligibility days
      if (entsToExcludeForScaleENT.contains(oldENTId) || oldScaleENT.Entitlement__r.EndDate < Date.today().addDays(-expiredEntitlementEligibility))
        continue;

      oldScaleENT.Renewal_Category__c = CONSTANTS.SCALE_ENT_RENEWAL_CATEGORY_REFRESHED; //Updating Old Linked asset as a Refreshed
      linkedAstToUpsert.add(oldScaleENT);

      //Create New R7K linked asset on the old license ENT
      Set<String> newSerialNumbers = new Set<String>();
      if (newSerialNumsByOld.containsKey(oldScaleENT.Asset__r.SerialNumber)) {
        newSerialNumbers.addAll(newSerialNumsByOld.get(oldScaleENT.Asset__r.SerialNumber));
      }
      for (String newSN : newSerialNumbers) {
        if (!exitingLinkedAssetsKey.contains(oldENTId + '-' + newSN) && assetBySerialNumber.containsKey(newSN) && assetBySerialNumber.get(newSN) != null) {
          linkedAstToUpsert.add(createScaleEntitlement(assetBySerialNumber.get(newSN).Id, oldCLIId, oldOIId, oldENTId, Constants.SCALE_ENT_TYPE_REFRESHED_BASE_LICENSE));
          exitingLinkedAssetsKey.add(oldENTId + '-' + newSN);
        }
      }
    }
  }

    /*
   * @param oldENT A map where the key is the old serial number and the value is a list of new serial numbers that replaced the old asset.
   * @param oldAssetsToUpdate A map of Asset Ids to their updated Asset records, to be updated in the database.
   * @param newSerialNumsByOld A new assets mapping by Old Asset
   * @param assetBySerialNumber A map where the key is the serial number and the value is the corresponding Asset record
   * @param linkedAstToUpsert A list of new Scale_Entitlement__c (linked assets) that are created and need to be inserted into the database.
   * @param exitingLinkedAssetsKey Set of unique keys (EntitlementId + SerialNumber) to prevent duplicates.
   * @param expiredEntitlementEligibility This stores the Eligible days for an old expired Entitlement in Refresh.
   * @author Ravi Mali
   */
  public static void linkNewAssetOnOldV1Entitlement(
    Entitlement oldENT,
    Map<Id, Asset> oldAssetsToUpdate,
    Map<String, Set<String>> newSerialNumsByOld,
    Map<String, Asset> assetBySerialNumber,
    Set<Scale_Entitlement__c> linkedAstToUpsert,
    Set<String> exitingLinkedAssetsKey,
    Integer expiredEntitlementEligibility
  ) {
    // To avoid duplicate Linked Asset creation (existingLinkedAssetsKey is already populated from the batch context)
    if (!System.isBatch() && oldENT.Scale_Entitlements__r != null && oldENT.Scale_Entitlements__r.size() > 0) {
      for (Scale_Entitlement__c scaleEnt : oldENT.Scale_Entitlements__r) {
        if (scaleEnt.Asset__r != null && scaleEnt.Asset__r?.SerialNumber != null) {
          String entAssetKey = oldENT.Id + '-' + scaleEnt.Asset__r?.SerialNumber;
          exitingLinkedAssetsKey.add(entAssetKey); //This is to hold the existing linked assets key to avoid duplicates
        }
      }
    }

    //Update old Asset as a refreshed
    if (!oldAssetsToUpdate.containsKey(oldENT.AssetId)) {
      oldAssetsToUpdate.put(oldENT.AssetId, new Asset(Id = oldENT.AssetId, Program__c = 'Refreshed'));
    }

    if (oldENT.EndDate < Date.today().addDays(-expiredEntitlementEligibility))
      return;

    //Create New R7K linked asset on the old license ENT
    Set<String> newSerialNumbers = new Set<String>();
    if (newSerialNumsByOld.containsKey(oldENT.Asset.SerialNumber)) {
      newSerialNumbers.addAll(newSerialNumsByOld.get(oldENT.Asset.SerialNumber));
    }
    for (String newSN : newSerialNumbers) {
      if (!exitingLinkedAssetsKey.contains(oldENT.Id + '-' + newSN) && assetBySerialNumber.containsKey(newSN) && assetBySerialNumber.get(newSN) != null) {
        linkedAstToUpsert.add(
          createScaleEntitlement(
            assetBySerialNumber.get(newSN).Id,
            oldENT?.ContractLineItemId,
            oldENT.Order_Service_Item__c,
            oldENT.Id,
            Constants.SCALE_ENT_TYPE_REFRESHED_BASE_LICENSE
          )
        );
        exitingLinkedAssetsKey.add(oldENT.Id + '-' + newSN);
      }
    }
  }

  /**
   * Creates and returns a Scale_Entitlement__c record.
   *
   * @param assetId             Id of the associated Asset.
   * @param contractLineItemId Id of the Contract Line Item.
   * @param orderProductId     Id of the Order Product (OI).
   * @param entitlementId      Id of the Entitlement.
   * @param type               Type of entitlement (e.g., 'Non-Scale').
   * @return                   Scale_Entitlement__c record ready for insert.
   */
  public static Scale_Entitlement__c createScaleEntitlement(Id assetId, Id contractLineItemId, Id orderProductId, Id entitlementId, String type) {
    return new Scale_Entitlement__c(
      Asset__c = assetId,
      Type__c = type,
      Contract_Line_Item__c = contractLineItemId,
      Order_Product__c = orderProductId,
      Entitlement__c = entitlementId
    );
  }
    /**
   * Returns a set of Entitlement Ids to exclude from linked asset creation,
   * based on entitlement link types (Surviving or Partial Replacements).
   */
  public static Set<Id> getEntitlementIdsToExclude(Set<Id> origEntIds, Set<Id> origOrdItmIds) {
    Set<Id> entsToExclude = new Set<Id>();
    for (Entitlement_Links__c entLink : ReplacementEntSplitHelper.getEntitlementLinks(origOrdItmIds)) {
      String entLinkType = entLink.Type__c;
      // Exclude only the initial Original Entitlement if it has been split
      if (entLink.Previous_Entitlement__c != null && origEntIds.contains(entLink.Previous_Entitlement__c) && Constants.ENT_LINK_SPLIT_REPLACEMENT_TYPES.contains(entLinkType)) {
        entsToExclude.add(entLink.Previous_Entitlement__c);
      }
    }
    return entsToExclude;
  }

  /**
   * Loads Asset records based on the serial numbers mappe  d in newSerialNumsByOld and populates the provided assetBySerialNumber map.
   *
   * @param newSerialNumsByOld Map of old serial numbers to new serial numbers (e.g., <OldSN, Set<NewSN>>)
   * @param assetBySerialNumber Map to populate with Asset records, keyed by serial number
   */
  public static void loadAssets(Map<String, Set<String>> newSerialNumsByOld, Map<String, Asset> assetBySerialNumber) {
    Set<String> allSerials = new Set<String>();
    for (Set<String> serialSet : newSerialNumsByOld.values()) {
      allSerials.addAll(serialSet);
    }
    for (Asset asset : [SELECT Id, SerialNumber FROM Asset WHERE SerialNumber IN :allSerials]) {
      assetBySerialNumber.put(asset.SerialNumber, asset);
    }
  }
  
  /**
   * Collects original entitlement & Order Item Ids from the previous line details of the given OrderItem.
   *
   * @param oi The OrderItem to extract previous entitlement IDs from.
   * @param origEntIds The old Original Ent Ids will be added
   * @param origOrdItmIds The old Original Order Item Ids will be added
   */
  public static void collectOriginalLinesDetail(OrderItem oi, Set<Id> origEntIds, Set<Id> origOrdItmIds) {
    List<PreviousTransRefWrapper> wrapper = UtilityClass.getPreviousLineDetails(oi);
    for (PreviousTransRefWrapper wrp : wrapper) {
      if (String.isNotBlank(wrp.entId)) {
        origEntIds.add(wrp.entId);
        origOrdItmIds.add(wrp.orderItemId);
      }
    }
  }

  /**
 * Handles linked asset creation and updates for inactive entitlements during a replacement/split process.
 *
 * Logic covered:
 *  - For assets not used or refreshed → create new linked assets under the "left" inactive entitlement.
 *  - For used assets (when target product type is Hardware) → create linked assets under the "used" inactive entitlement.
 *  - For the original inactive entitlement's existing linked assets → update the Renewal Category field
 *    based on the transaction type mapping or fallback transaction type.
 *
 * @param orgEntDetailsWrapper  Wrapper containing entitlement, asset, and transaction type details.
 * @param originalEntId         Id of the original entitlement being processed.
 * @param inactiveEnt           The inactive entitlement record to update existing linked assets for.
 * @param assetNoToId           Map of asset serial number → Asset Id.
 * @param linkedAssetsToUpsert  Collector list of Scale_Entitlement__c records to insert/update.
 * @param entToLinkedAssets     Map of entitlement Id → list of currently linked Scale_Entitlement__c records.
 * @param entToUpsert           Map containing entitlement split records keyed with suffixes (-inactiveUsedEnt / -inactiveLeftEnt).
 */
  public static void handleAssetLinkageInactiveEnt(
    ReplacementEntSplitManager.EntitlementDetails orgEntDetailsWrapper,
    Id originalEntId,
    Entitlement inactiveEnt,
    Map<String, Id> assetNoToId,
    List<Scale_Entitlement__c> linkedAssetsToUpsert,
    Map<Id, List<Scale_Entitlement__c>> entToLinkedAssets,
    Map<String, Entitlement> entToUpsert
  ) {
    Entitlement usedInactiveEnt = entToUpsert.get(originalEntId + '-inactiveUsedEnt'); //Ent 1.1
    Entitlement leftInactiveEnt = entToUpsert.get(originalEntId + '-inactiveLeftEnt'); //Ent 1.2
    Boolean isAssetBased = orgEntDetailsWrapper.orderItemIdToTargetProductType != null && orgEntDetailsWrapper.orderItemIdToTargetProductType?.values()?.contains(Constants.SKU_TYPE_HARDWARE);
    for (String assetSN : orgEntDetailsWrapper.allAssets) {
      if (!orgEntDetailsWrapper.usedAssets.contains(assetSN) && isAssetBased) {
        linkedAssetsToUpsert.add(UtilityClass.createLinkedAsset(leftInactiveEnt, assetNoToId.get(assetSN), 'Non-Scale'));
      }
    }
    if (isAssetBased) {
      for (String assetSN : orgEntDetailsWrapper.usedAssets) {
        linkedAssetsToUpsert.add(UtilityClass.createLinkedAsset(usedInactiveEnt, assetNoToId.get(assetSN), 'Non-Scale'));
      }
    }
    if (inactiveEnt != null && entToLinkedAssets.containsKey(inactiveEnt.Id)) {
      for (Scale_Entitlement__c linkAsset : entToLinkedAssets.get(inactiveEnt.Id)) {
        linkedAssetsToUpsert.add(
          new Scale_Entitlement__c(
            Id = linkAsset.Id,
            Renewal_Category__c = (orgEntDetailsWrapper.transactionTypeByAssetSN != null &&
              orgEntDetailsWrapper.transactionTypeByAssetSN.containskey(linkAsset.Asset__r.SerialNumber))
              ? orgEntDetailsWrapper.transactionTypeByAssetSN.get(linkAsset.Asset__r.SerialNumber)
              : orgEntDetailsWrapper.transactionType
          )
        );
      }
    }
  }
}