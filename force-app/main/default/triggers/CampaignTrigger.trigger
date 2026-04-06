trigger CampaignTrigger on Campaign (before insert,after insert,before update) {
    private Boolean isDisabled = false;
    ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance();
    isDisabled = disabled.Disable_Campaign_Trigger__C; //Custom setting to by-pass trigger
    if(!isDisabled && flowControll.CampaignTrigger){
        if(Trigger.isAfter && Trigger.isInsert){
            CampaignTriggerHandler.createMemberStatus(Trigger.NewMap);
        }
        if(Trigger.isBefore) {
            if(Trigger.isUpdate){
                CampaignTriggerHandler.populateActualCost((List<Campaign>)Trigger.new,(Map<Id,Campaign>)Trigger.oldMap);
                CampaignTriggerHandler.populateCDM((List<Campaign>)Trigger.new, (Map<Id,Campaign>)Trigger.oldMap);
            }
            if(Trigger.isInsert){
                CampaignTriggerHandler.checkActive((List<Campaign>)Trigger.new);
                CampaignTriggerHandler.populateCDM((List<Campaign>)Trigger.new, null);
            }
        }
    }
}