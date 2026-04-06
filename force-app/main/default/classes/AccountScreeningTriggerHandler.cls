public class AccountScreeningTriggerHandler extends TriggerHandler {
    
    private static Boolean isDisabled = false; 
    public AccountScreeningTriggerHandler() {
       ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance();
        isDisabled = disabled.Disable_Account_Screening_Trigger__c;
        ///// DO NOT RUN MORE THAN 2 TIME - Avoid Recursion /////
        Integer mxloopCount = Integer.valueOf(disabled.TriggerMaxLoopCount__c);
        this.setMaxLoopCount(mxloopCount);
    }
    
    public override void beforeUpdate() {
        if(isDisabled) {
            return;
        }
    }
    public override void afterUpdate() {
        if(isDisabled) {
            return;
        }
        AccountScreeningTriggerHelper.doCalloutIfGTCPassedForFreeTrial((List<Account_Screening__c>)Trigger.new,(Map<Id, Account_Screening__c>)Trigger.oldMap);
        AccountScreeningTriggerHelper.updateRelatedOpportunities((List<Account_Screening__c>)Trigger.new,(Map<Id, Account_Screening__c>)Trigger.oldMap);
        
    }
    
    
    
}