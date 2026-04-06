/************************************************************
* @description       : QuoteAndOrderStagingTrigger is writtent to Automate the Data loading of Old RCDM-T Line 
						on Quote and Staging Object
* @author            : Prashant
* Modifications Log  
* Ver   Date          Author        Modification
**************************************************************/

trigger QuoteAndOrderStagingTrigger on Quote_and_Order_Staging__c(
    before insert,
    before update,
    before delete,
    after insert,
    after update,
    after delete,
    after undelete
) {
    ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance();
    if(triggerControl.stopQuoteAndOrderStagingTrigger){ 
        return;    
    }
    if (!disabled.Disable_QuoteAndStaging_Trigger__c) { 
        new QuoteAndOrderStagingTriggerHandler().run();
    } 
}