public class RMAOrderTriggerHandler  extends TriggerHandler {
private Boolean isDisabled = false;
    
	public RMAOrderTriggerHandler() {
        ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance();
        isDisabled = disabled.Disable_RMA_Trigger__c;
    }
	
    public override void beforeInsert() {
	if(!isDisabled)
        	RMAOrderTriggerHelper.populateSmartHandsProvider((List<RMA_Order__c>) Trigger.New);
	}

    public override void beforeUpdate() {
        if(!isDisabled)
        	RMAOrderTriggerHelper.checkEmailRegex((Map<Id, RMA_Order__c>) Trigger.OldMap,(List<RMA_Order__c>) Trigger.New);
    }
    
    public override void beforeDelete() {}
    
    public override void afterInsert() {
        if(!isDisabled)
        	RMAOrderTriggerHelper.checkRecordApprovedOnInsert((List<RMA_Order__c>) Trigger.New);
    }
    
    public override void afterUpdate() {
        if(!isDisabled)
        	RMAOrderTriggerHelper.checkRecordApprovedOnUpdate((Map<Id, RMA_Order__c>) Trigger.OldMap,(List<RMA_Order__c>) Trigger.New);
    }
    
    public override void afterDelete() {}
        
	public override void afterUndelete() {}        
}