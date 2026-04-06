trigger ProductTrigger on Product2 (before insert,before update){
    if(!ShGl_DisableBusinessLogic__c.getInstance().Disable_Product2_Trigger__c){
        TriggerFactory.createHandler(Product2.sObjectType);
    }
}