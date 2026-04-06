trigger LeadTrigger on Lead (before insert, before update, after insert, after update) {
    if(UserInfo.getUserId() == Label.DisableTriggerUser) return;
    // Control trigger execution
    if(Trigger.isBefore && Trigger.isUpdate) {
        new LeadTriggerHelper().populateWinningL2AAccount((List<Lead>) Trigger.new, (Map<Id, Lead>) Trigger.oldMap);
    }
    if(!ShGl_DisableBusinessLogic__c.getInstance().Disable_Lead_Triggers__c && flowControll.LeadTriggerHandler) {
        system.debug('Trigger execution');
        //TriggerFactory.createHandler(Lead.sObjectType);
        TriggerManager.invokeHandler(new LeadTriggerHandler());
    }
    if(Trigger.isBefore && Trigger.isUpdate) {
        new LeadTriggerHelper().populateWinningL2AAccount((List<Lead>) Trigger.new, (Map<Id, Lead>) Trigger.oldMap);
        new LeadTriggerHelper().uncheckL2AStatus((List<Lead>) Trigger.new, (Map<Id, Lead>) Trigger.oldMap);
    }
    
}