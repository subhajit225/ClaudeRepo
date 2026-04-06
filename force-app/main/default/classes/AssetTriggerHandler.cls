public class AssetTriggerHandler extends TriggerHandler {

    private Boolean isDisabled = false;
    public static Boolean disableHistoryTracking = false;


    public AssetTriggerHandler() {
        ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance();
        isDisabled = disabled.Disable_Asset_Triggers__c;

        ///// DO NOT RUN MORE THAN 2 TIME - Avoid Recursion /////
        Integer mxloopCount = Integer.valueOf(disabled.TriggerMaxLoopCount__c);
        this.setMaxLoopCount(mxloopCount);
    }

    public override void beforeInsert() {
        if(!isDisabled) {
          disableHistoryTracking = true;
            AssetTriggerHelper.setFieldsOnAssetInsert((List<Asset>)Trigger.new);
            //GANg-8
            AssetTriggerHelper.populatePOC((List<Asset>)Trigger.new, (Map<Id, Asset>)Trigger.oldMap);
        }
    }
    public override void beforeUpdate() {
        if(!isDisabled) {
            AssetTriggerHelper.setFieldsOnAssetUpdate((List<Asset>)Trigger.new, (Map<Id, Asset>)Trigger.oldMap);
            //GANG-8
            AssetTriggerHelper.populatePOC((List<Asset>)Trigger.new, (Map<Id, Asset>)Trigger.oldMap);
        }
    }

    //PRDOPS25-734
    public override void beforeDelete() {
      if(!isDisabled) {
        Map<Id, Asset>  oldassetMap = (Map<Id, Asset>)Trigger.oldMap;  
        AssetTriggerHelper.customValidationOnDeleteAsset(oldassetMap);
    }
    }

    public override void afterInsert() {}

     public override void afterUpdate() {
        if(!isDisabled) {
          Order_control__mdt DisableCustomHistoryTracker = Order_control__mdt.getInstance('Disable_Asset_Custom_History_Tracker');
          if(!CustomHistoryTracker.recurssionHandlerSobjectSet.contains('Asset') &&
             DisableCustomHistoryTracker?.Value__c != null  &&
             !boolean.valueOf(DisableCustomHistoryTracker?.Value__c) && !disableHistoryTracking){
                 system.debug('calling CustomHistoryTracker');
                 CustomHistoryTracker.trackFieldsHistory(trigger.new, Trigger.oldMap,'Asset__c');
             }
           // AssetTriggerHelper.DiscardCLIsOnRefresh((List<Asset>)Trigger.new, (Map<Id, Asset>)Trigger.oldMap);   
            
        }
    }

    public override void afterDelete() {}

    public override void afterUndelete() {}  

    public void explicitMethodHandler(List<Asset> newAssets, Map<Id, Asset> oldAssetById, System.TriggerOperation triggerEvent) {
      if (!isDisabled) {
        switch on triggerEvent {
          when BEFORE_UPDATE {
            AssetTriggerHelper.preventChangeFields(newAssets, oldAssetById, null, null);
          }
        }
      } 
    }
}