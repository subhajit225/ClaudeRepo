trigger POCRequestTrigger on POC__C (before insert, before update, before delete, after insert, after update, after delete) {
/*    
    if(flowControll.POCRequestTriggerHandler) {
        TriggerFactory.createHandler(POC__C.sObjectType);
    }
*/

    ShGl_DisableBusinessLogic__c disableBusinessLogicCS = ShGl_DisableBusinessLogic__c.getInstance(UserInfo.getUserId());
    if(!disableBusinessLogicCS.Disable_POC_Trigger__c && FlowControll.POCRequestTriggerHandler){
        TriggerManager.invokeHandler(new PocTriggerHandler());
    }

}