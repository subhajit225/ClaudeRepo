public class IntegrationLogMainTriggerHandler extends TriggerHandler {
    
    private Boolean isDisabled = false;
    
    public IntegrationLogMainTriggerHandler() {
        
        ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance();
        isDisabled = disabled.Disable_Integration_Error_Log_Trigger__c;
        
        ///// DO NOT RUN MORE THAN 2 TIME - Avoid Recursion /////
        Integer mxloopCount = Integer.valueOf(disabled.TriggerMaxLoopCount__c);
        this.setMaxLoopCount(mxloopCount);
        
        /* Add OnOff Switch and mxloopCount */
    }
    public override void beforeInsert() {}
    
    public override void beforeUpdate() {}
    
    public override void beforeDelete() {}
    
    public override void afterInsert() {
        if(!isDisabled){
            IntegrationLogMainTriggerHelper.updateFieldsOnInsert ((List<Error_Logs__c>) Trigger.new);
        }
    }
    
    public override void afterUpdate() {}
    
    public override void afterDelete() {}
    
    public override void afterUndelete() {}
}