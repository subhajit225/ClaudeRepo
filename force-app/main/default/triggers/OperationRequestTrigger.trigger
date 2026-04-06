trigger OperationRequestTrigger on Operations_Request__c ( after insert, after update,before insert, before update, after delete,before delete) {
    ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance();
    if(!disabled.Disable_Operation_Request_Triggers__c && FlowControll.operationRequestTrigger){
        TriggerManager.invokeHandler(new OperationRequestTriggerHandler());
    }
}