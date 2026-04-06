public class Territory2TriggersHandler extends TriggerHandler {
    
    private Boolean isDisabled = false;

    public Territory2TriggersHandler() {
        ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance();
        isDisabled = disabled.Disable_Territory_Triggers__c;
    }

 /*   public override void beforeInsert() {
    }
*/
     //Pooled SE
    public override void beforeUpdate() {
         if(!isDisabled) {
           Territory2TriggerHelper.sePoolCheckforRegion((List<territory2>) trigger.new);
             Territory2TriggerHelper.sePoolingCheck((List<territory2>)trigger.new,(Map<Id,Territory2>)Trigger.oldMap);
          }
    }


   // public override void beforeDelete() {}

    public override void afterInsert() {
        if(!isDisabled) {
            Territory2TriggerHelper.filterTerritoryToCreateAssignmentRule((Map<Id,Territory2>)Trigger.newMap, (Map<Id,Territory2>)Trigger.oldMap, true);
        }
    }

    public override void afterUpdate() {
        if(!isDisabled) {
            Territory2TriggerHelper.filterTerritoryToCreateAssignmentRule((Map<Id,Territory2>)Trigger.newMap, (Map<Id,Territory2>)Trigger.oldMap, false);
            Territory2TriggerHelper.getOwnerAssignmentImpactedTerr((List<territory2>)trigger.new,(Map<Id,Territory2>)Trigger.oldMap);
        }

    }

/*    public override void afterDelete() {}

    public override void afterUndelete() {} */
    
}