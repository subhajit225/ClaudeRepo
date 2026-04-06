public class RMAFailureTriggersHandler extends TriggerHandler {
        private Boolean isDisabled = false;
        public RMAFailureTriggersHandler() {
            ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance();
            isDisabled = disabled.Disable_Failure_Triggers__c;
        
    }
    // After Update
     public override void afterUpdate() {
        if(!isDisabled) {
            RmaFailureTriggerHelper.ProcessRmaFailedRecords((List<Failure__c>)Trigger.new,(Map<Id,Failure__c>) Trigger.oldMap);
        }
        }
        
    }