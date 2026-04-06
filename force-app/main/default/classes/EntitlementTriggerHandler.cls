/**************************************************************************************************
 * @description       : Entitlement trigger Handler
 * @author            : Chaitra
 * @last modified on  : 11-20-2025
 * @last modified by  : Shrutika
 * Modifications Log
 * Ver   Date          Author        Modification
 * 1.0   11-20-2025   Shrutika       PRDOPS-1171 
 ******************************************************************************/
public without sharing class EntitlementTriggerHandler implements ITrigger {
  Set<Id> assetIds = new Set<Id>();
  Set<Id> AccountIds = new Set<Id>();
  Map<id, Boolean> mapAssetEntlStatus = new Map<Id, Boolean>();
  List<Asset> assetwithEntitlementList = new List<Asset>();
  List<Account> accountwithEntitlementList = new List<Account>();
  List<Entitlement> entitlementsToBeUpdatedList = new List<Entitlement>();
  Set<Id> nonAssetEntilementIdSet = new Set<Id>(); //CPQ22-596
  private Boolean isDisabledBatchApex = false; //CPQ22-587
  private Boolean isDisabledTrigger = false;
  public static Boolean isDisabledEntitlementTracking = false;
  public static Boolean isDisabledSuccessPlanQueue = false;
  public static Boolean bypassRecordEditValidation = false;
  public static List<Asset> assetList = new List<Asset>();  
  public static List<account> acclist = new List<account>();
  
  /**
   * @description This is a constructor
   */
  public EntitlementTriggerHandler() {
    ShGl_DisableBusinessLogic__c disabledTrigger = ShGl_DisableBusinessLogic__c.getInstance();
    isDisabledTrigger = disabledTrigger.Disable_Entitlement_Trigger__c;
    isDisabledBatchApex = disabledTrigger.Disable_Batch_Apex__c;
    if (!isDisabledTrigger && Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
      EntitlementTriggerHelper.entitlementTriggerHelperInit();
    }
  } //CPQ22-596 ends

  /**
   * bulkBefore
   *
   * @description This method is called prior to execution of a BEFORE trigger. Use this to cache
   * any data required into maps prior execution of the trigger.
   */
  public void bulkBefore() {
    if (!isDisabledTrigger) {
      EntitlementTriggerHelper.updatePartnerNameOnChange((List<Entitlement>) Trigger.new, (Map<Id, Entitlement>) Trigger.oldMap);
      EntitlementTriggerHelper.updateAssetId((List<Entitlement>) Trigger.new);
    }
    if (Trigger.isUpdate) {
      system.debug(LoggingLevel.DEBUG, 'Before Update');
    }
    if (Trigger.isInsert) {
      isDisabledEntitlementTracking = true;
    }
    if (!isDisabledTrigger && (Trigger.isInsert || Trigger.isUpdate)) {
      EntitlementTriggerHelper.populateFieldsOnUpsert();
      if (Trigger.isInsert) {
        EntitlementTriggerHelper.populateStorageRegionBundleOnInsert();
      }
    }
  }

  /**
   * bulkAfter
   *
   * @description This method is called prior to execution of an AFTER trigger. Use this to cache
   * any data required into maps prior execution of the trigger.
   */
  public void bulkAfter() {
    if (!isDisabledTrigger) {
      ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance();
      //CS21-3139
      Set<Entitlement> activeEntitlements = new Set<Entitlement>();
      for (Sobject so : Trigger.isDelete ? Trigger.old : Trigger.new) {
        Entitlement entl = (Entitlement) so;
        if (entl.AssetId != null)
          assetIds.add(entl.AssetId);
      }

      assetIds.remove(null);
      Map<Id, Set<Id>> mapAssetProductonEntitlement = new Map<Id, Set<Id>>();
      Map<Id, Set<Entitlement>> mapAccountEntitlement_RBKEDGE = new Map<Id, Set<Entitlement>>();
      Map<Id, Set<Entitlement>> mapAccountEntitlement_RBKARCDM = new Map<Id, Set<Entitlement>>();

      for (Sobject so : Trigger.isDelete ? Trigger.old : Trigger.new) {
        Entitlement entl = (Entitlement) so;
        if (entl.AssetId == null && Entl.AccountID != null)
          accountIds.add(entl.AccountID);
      }

      Set<Id> productIdSet = new Set<Id>();
      Set<String> productCodeSet = new Set<String>();
      Set<String> productCodeSetNonAsset = new Set<String>();
      Set<Entitlement> EntitlementSet = new Set<Entitlement>();
      Set<Id> EntitlementIdSet = new Set<id>();
      if(assetList.isEmpty() && !assetIds.isEmpty()){
        assetList = [
          SELECT id, name, 
          (SELECT id, name, AssetId, StartDate, EndDate, Product__C, Product__r.ProductCode FROM Entitlements LIMIT 2000) 
          FROM Asset 
          WHERE id IN :assetIds
        ];
      }
      for (Asset asset : assetList) {
        for (Entitlement entl : asset.entitlements) {
          if (entl.assetId != null && entl.product__c != null) {
            EntitlementSet.add(entl);
          }
        }
        productIdSet.remove(null);
      }
      if(acclist.isEmpty() && !accountIds.isEmpty()){
        acclist = [
          SELECT id, name, (SELECT id, name, StartDate, AccountId, AssetId, EndDate, Product__C, Product__r.ProductCode FROM Entitlements WHERE AssetId = NULL ORDER BY EndDate ASC)
          FROM Account
          WHERE id IN :accountIds
        ];
      }

      for (Account acc : acclist) {
        Set<Entitlement> RBKCLOUTEntlIdSet = new Set<Entitlement>();
        Set<Entitlement> RBKRCDMEntlIdSet = new Set<Entitlement>();
        for (Entitlement entl : acc.entitlements) {
          if (entl.assetId == null && entl.product__c != null && entl.Product__r.ProductCode.contains('-')) {
            String strProdCode = entl.Product__r.ProductCode.substring(0, entl.Product__r.ProductCode.lastIndexOf('-'));
            productCodeSetNonAsset.add(strProdCode);
            if (strProdCode == 'RBK-EDGE-10') {
              system.debug(LoggingLevel.DEBUG, 'Bulk after');
            } else if (strProdCode == 'RBK-RCDM-AWS') {
              system.debug(LoggingLevel.DEBUG, 'Bulk after');
            } else {
              nonAssetEntilementIdSet.add(entl.id);
            }
          }
        }
        if (RBKCLOUTEntlIdSet.size() > 0)
          mapAccountEntitlement_RBKEDGE.put(acc.Id, RBKCLOUTEntlIdSet);
        if (RBKRCDMEntlIdSet.size() > 0)
          mapAccountEntitlement_RBKARCDM.put(acc.Id, RBKRCDMEntlIdSet);
      }
      for (Asset asset : assetList) {
        assetwithEntitlementList.add(asset);
      }
      for (Account account : acclist) {
        accountwithEntitlementList.add(account);
      }

      if (Trigger.isInsert) {
        /* 1. RWD-385 : Identify Free HW Eligible Lines */
        List<Entitlement> newEntitlementList = new List<Entitlement>();

        for (Entitlement entitlementObj : (List<Entitlement>) Trigger.new) {
          //CS21-3139
          if(checkEntitlementProductNamesForCemSp(entitlementObj)) {
            activeEntitlements.add(entitlementObj);
          }
          Entitlement newEntitlementObj = entitlementObj;
          if (newEntitlementObj.AssetId != null) {
            /* RWD-385: Insert Entitlement Links and Set Eligible for Free HW, Inside the insertEntitlementLinks, another method is called to Set the Eligible for Free HW*/
            newEntitlementList.add(entitlementObj);
          }
        }
        if (!newEntitlementList.isEmpty()) {
          system.debug(LoggingLevel.DEBUG, 'newEntitlementList not is empty');
        }
      }

      if (Trigger.isUpdate) {
        if (checkRecursive.entitlementlinkcreation) {
          List<Entitlement> newEntitlementList = new List<Entitlement>();
          for (Entitlement entitlementObj : (List<Entitlement>) Trigger.new) {
            Entitlement newEntitlementObj = entitlementObj;
            //CS21-3139
            if(checkEntitlementProductNamesForCemSp(entitlementObj)) {
              activeEntitlements.add(entitlementObj);
            }
            if (newEntitlementObj.AssetId != null) {
              /*RWD-385: Insert Entitlement Links and Set Eligible for Free HW, Inside the insertEntitlementLinks, another method is called to Set the Eligible for Free HW*/
              newEntitlementList.add(entitlementObj);
            }
          }
          if (!newEntitlementList.isEmpty()) {
            AssetAndEntitlementLinkUtility.insertEntLinksAndUpdateEligForFreeHW(newEntitlementList);
            checkRecursive.entitlementlinkcreation = false;
          }
        }
        Order_control__mdt DisableCustomHistoryTracker = Order_control__mdt.getInstance('Disable_Ent_Custom_History_Tracker');
        if (
          !CustomHistoryTracker.recurssionHandlerSobjectSet.contains('Entitlement') &&
          DisableCustomHistoryTracker?.Value__c != null &&
          !boolean.valueOf(DisableCustomHistoryTracker?.Value__c) &&
          !isDisabledEntitlementTracking
        ) {
          CustomHistoryTracker.trackFieldsHistory(Trigger.new, Trigger.oldMap, 'Entitlement__c');
        }
      }

      if (Trigger.isDelete) {
        system.debug(LoggingLevel.DEBUG, 'is Delete');
      }
      Order_control__mdt DisableSuccessPlanQueueableCls = Order_control__mdt.getInstance('DisableSuccessPlanQueueableCls');
      //CS21-3139
      if(!activeEntitlements.isEmpty() && DisableSuccessPlanQueueableCls?.Value__c != null && !boolean.valueOf(DisableSuccessPlanQueueableCls?.Value__c) && !isDisabledSuccessPlanQueue){
          enqueueCreateSuccessPlansQueueable(activeEntitlements);
    }
  }
  }

    /**
     * @description  : CS21-3139: CEM Success Plan Enhancements: check Entitlement Product Names For Cem Success Plan
     * @param objEnt
     * @return boolean
     */
    public static Boolean checkEntitlementProductNamesForCemSp(Entitlement objEnt) {
        
        Set<String> entitlementNames = new Set<String>{'RA-CEM-PA', 'RA-CEM-PP', 'RA-CES-PA', 'RA-CES-PP', 'RA-PAC-PA', 'RA-PAC-PP'};
        Entitlement oldEnt = Trigger.oldMap != null ? (Entitlement) Trigger.oldMap.get(objEnt.Id) : null;
        Boolean isStatusChangedToActive = (oldEnt == null || oldEnt.Status == 'InActive') && objEnt.Status == 'Active';
        
        if(isStatusChangedToActive 
            && objEnt.AccountId != null 
            && objEnt.StartDate != null 
            && objEnt.EndDate != null
            && entitlementNames.contains(objEnt.Name)){
                return true;
        }else{
            return false;
        }
    }

    /**
     * @description  : CS21-3139: CEM Success Plan Enhancements
     * @param activeEntitlements
     */
    public static void enqueueCreateSuccessPlansQueueable(Set<Entitlement> activeEntitlements) {
        try {
            isDisabledSuccessPlanQueue = true;
            CreateSuccessPlansForEntitlements.processEntitlementIdsForSucessPlan(activeEntitlements);
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error enqueuing CreateSuccessPlansQueueable: ' + ex.getMessage());
            UtilityClass.logException(ex, 'EntitlementTriggerHandler', 'enqueueCreateSuccessPlansQueueable', 'Success Plan');
        }
    }
    
  /**
   * beforeInsert
   *
   * @description This method is called iteratively for each record to be inserted during a BEFORE
   * trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
   * @param so
   */
  public void beforeInsert(SObject so) {
    system.debug(LoggingLevel.DEBUG, 'is Before Insert');
  }
  /**
   * beforeUpdate
   *
   * @description This method is called iteratively for each record to be updated during a BEFORE
   * trigger.
   * @param oldSo
   * @param so
   */
  public void beforeUpdate(SObject oldSo, SObject so) {
    //PRDOPS-1171
    Entitlement ent = (Entitlement)so;
    Boolean isValidationDisabled = ShGl_DisableBusinessLogic__c.getInstance().Disable_Entitlement_Validation_Rules__c;
    
    Boolean hasProdOpsAccess = FeatureManagement.checkPermission('Entitlement_ProdOps_Create_Edit_Access');
    Boolean hasCSAdminAccess = FeatureManagement.checkPermission('CS_Admin_Entitlement_Create_Edit');
    
    Id csAdminRecordTypeId = Label.Entitlement_CS_Admin_RecordTypeId;
    
    if (!isValidationDisabled && !hasProdOpsAccess && !bypassRecordEditValidation) {
        if ((!hasCSAdminAccess && ent.RecordTypeId == csAdminRecordTypeId) ||
            ent.Type == 'Phone Support' || ent.Type == 'Evaluation' || ent.Type == 'Admin' || (ent.Type == 'Manufacturing Entitlement' && ent.RecordTypeId != csAdminRecordTypeId) && !Test.isRunningTest()) {
                ent.addError('You are not authorized to edit this Entitlement, hence please create support ticket with ProdOps Support or email "ProdOpsapps@rubrik.com" with details.');
            }
    }
  }
  /**
   * beforeDelete
   *
   * @description This method is called iteratively for each record to be deleted during a BEFORE
   * trigger.
   * @param so
   */
  public void beforeDelete(SObject so) {
    system.debug(LoggingLevel.DEBUG, 'is Before Delete');
  }
  /**
   * afterInsert
   *
   * @description This method is called iteratively for each record inserted during an AFTER
   * trigger. Always put field validation in the 'After' methods in case another trigger
   * has modified any values. The record is 'read only' by this point.
   * @param so
   */
  public void afterInsert(SObject so) {
    if (!isDisabledTrigger) {
      List<id> EntIDList = new List<Id>();
      for (Entitlement et : (List<Entitlement>) Trigger.new) {
        EntIDList.add(et.Id);
      }
      //CPQ22-596
      if (!isDisabledBatchApex) {
        if (Limits.getQueueableJobs() == 0) {
          //ARY-596 - as part of this ticket. it should be commented.
          //System.enqueueJob(new EntitlementQueueableHelper(EntIDList));
          system.debug(LoggingLevel.DEBUG, 'is After Insert');
        }
      } //CPQ22-596 ends
    }
  }
  /**
   * afterUpdate
   *
   * @description  This method is called iteratively for each record updated during an AFTER trigger.
   * @param oldSo
   * @param so
   */
  public void afterUpdate(SObject oldSo, SObject so) {
    system.debug(LoggingLevel.DEBUG, 'is After Update');
  }
  /**
   * afterDelete
   *
   * @description  This method is called iteratively for each record deleted during an AFTER
   * trigger.
   * @param so
   */
  public void afterDelete(SObject so) {
    system.debug(LoggingLevel.DEBUG, 'is After Delete');
  }
  /**
   * andFinally
   *
   * @description This method is called once all records have been processed by the trigger. Use this
   * method to accomplish any final operations such as creation or updates of other records.
   */
  public void andFinally() {
    system.debug(LoggingLevel.DEBUG, 'is Finally');
  }
}