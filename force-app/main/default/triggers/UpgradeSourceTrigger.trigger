trigger UpgradeSourceTrigger on SBQQ__UpgradeSource__c  (after update,after insert,after delete, before update,before insert, before delete){
    
	
	/*if(!ShGl_DisableBusinessLogic__c.getInstance().Disable_UpgradeSource_Trigger__c){
        TriggerFactory.createHandler(SBQQ__UpgradeSource__c.sObjectType);
    }*/
    
}