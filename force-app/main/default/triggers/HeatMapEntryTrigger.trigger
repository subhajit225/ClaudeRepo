trigger HeatMapEntryTrigger on HeatMap_Entry__c (before insert, before update) {
    if(!ShGl_DisableBusinessLogic__c.getInstance().Disable_Heat_Map_Entry_Triggers__c){
        TriggerManager.invokeHandler(new HeatMapEntryTriggerHandler());
    }
}