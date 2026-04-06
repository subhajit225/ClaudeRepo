public with sharing class ScaleUtilityOverageTriggerHandler extends TriggerHandler {
  private Boolean isDisabled = false; 

  public ScaleUtilityOverageTriggerHandler() { 
    ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance();
    isDisabled = disabled.Disable_Scale_Utility_Overage_Triggers__c;
    ///// DO NOT RUN MORE THAN 2 TIME - Avoid Recursion /////
    //this.setMaxLoopCount(2);
  } 

  public override void beforeInsert() { 
  }
  public override void beforeUpdate() {  
    Map<Id, Scale_Utility_Overage__c> newSUOverageRecordsById = (Map<Id, Scale_Utility_Overage__c>) Trigger.newMap;
    Map<Id, Scale_Utility_Overage__c> oldSUOverageRecordsById = (Map<Id, Scale_Utility_Overage__c>) Trigger.oldMap;
    if (!isDisabled) {
      ScaleUtilityOverageTriggerHelper.updateScaleUtilityOverageStatus(
        newSUOverageRecordsById,
        oldSUOverageRecordsById
      );
    }
  }
  public override void beforeDelete() {
  }

  public override void afterInsert() {
  }
  public override void afterUpdate() {
    if (!isDisabled) {
      Map<Id, Id> orderIdBySUOverageId = new Map<Id, Id>(); //CSU-116
      Map<Id, Scale_Utility_Overage__c> SUOverageRecordsToReprocess = new Map<Id, Scale_Utility_Overage__c>();
      List<Id> suOveragesSyncSuccessIds = new List<Id>();
      Map<Id, Scale_Utility_Overage__c> newSUOverageRecordsById = (Map<Id, Scale_Utility_Overage__c>) Trigger.newMap;
      Map<Id, Scale_Utility_Overage__c> oldSUOverageRecordsById = (Map<Id, Scale_Utility_Overage__c>) Trigger.oldMap;
      for (Scale_Utility_Overage__c newSUOverage : newSUOverageRecordsById.values()) {
        Scale_Utility_Overage__c oldSUOverage = oldSUOverageRecordsById.get(newSUOverage.id);
        if (
          oldSUOverage.Process_Flag__c != Constants.PROCESS_FLAG_REPROCESS &&
          (newSUOverage.Process_Flag__c == Constants.PROCESS_FLAG_REPROCESS ||
          newSUOverage.Process_Flag__c == Constants.PROCESS_FLAG_STALE)
        ) {
            SUOverageRecordsToReprocess.put(newSUOverage.id, newSUOverage);
        }

        if (
          oldSUOverage.Sync_Status__c != Constants.SYNC_SUCCESS &&
          newSUOverage.Sync_Status__c == Constants.SYNC_SUCCESS
        ) {
          suOveragesSyncSuccessIds.add(newSUOverage.Id);
        }
        //CSU-116 Start
        if (
          newSUOverage.Process_Flag__c != oldSUOverage.Process_Flag__c &&
          newSUOverage.Process_Flag__c == Constants.PROCESS_FLAG_CEATE_OVERAGE_ORDER &&
          newSUOverage.Original_Order__c != null &&
          newSUOverage.Createddate.month() == System.today().month()
        ) {
          orderIdBySUOverageId.put(newSUOverage.Id, newSUOverage.Original_Order__c);
        }
        //CSU-116 End
      }
      if (!SUOverageRecordsToReprocess.values().isEmpty()) {
        ScaleUtilityOverageTriggerHelper.processSnowflakeFeedsForReProcessing(SUOverageRecordsToReprocess);
      }

      if (!suOveragesSyncSuccessIds.isEmpty()) {
        ScaleUtilityOverageTriggerHelper.syncSnowflakeFeeds(suOveragesSyncSuccessIds);
      }

      //CSU-116 Start
      if (!orderIdBySUOverageId.isEmpty()) {
        ScaleUtilityOverageTriggerHelper.createOverageOpptyAndOrder(orderIdBySUOverageId);
      }
      //CSU-116 End
    }
  }
  public override void afterDelete() {
  }

  public override void afterUndelete() {
  }
}