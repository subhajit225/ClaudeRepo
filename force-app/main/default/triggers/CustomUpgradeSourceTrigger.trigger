trigger CustomUpgradeSourceTrigger on Custom_Upgrade_Source__c(after update,after insert,after delete, before update,before insert, before delete) {


 if(!ShGl_DisableBusinessLogic__c.getInstance().Disable_UpgradeSource_Trigger__c){
        TriggerFactory.createHandler(Custom_Upgrade_Source__c.sObjectType);
    } 
}