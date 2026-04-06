trigger POSReportTrigger on POS_Report__c (before insert, before update, before delete, after insert, after update, after delete) {
    ShGl_DisableBusinessLogic__c disableBusinessLogicCS = ShGl_DisableBusinessLogic__c.getInstance(UserInfo.getUserId());
    if(!disableBusinessLogicCS.Disable_POS_Report_Triggers__c){
        if(FlowControll.POSReportTrigger && TriggerManager.isTriggerExecutionAllowed('POS_Report__c')){
            TriggerManager.invokeHandler(new POSReportTriggerHandler());
        }
    }
}