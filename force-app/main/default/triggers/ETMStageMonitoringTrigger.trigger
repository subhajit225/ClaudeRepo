trigger ETMStageMonitoringTrigger on ETMStage_Monitoring__c (before insert, before update) {
    ShGl_DisableBusinessLogic__c disableBusinessLogicCS = ShGl_DisableBusinessLogic__c.getInstance(UserInfo.getUserId());
    if(!disableBusinessLogicCS.Disable_ETMStageMonitoring_Triggers__c){
        TriggerManager.invokeHandler(new ETMStageMonitoringTriggerHandler());
    }
}