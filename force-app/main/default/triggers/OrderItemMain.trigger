trigger OrderItemMain on OrderItem(before insert, after update, after insert, before update, before delete, after delete) {
  ShGl_DisableBusinessLogic__c csDisableBusinessLogic = ShGl_DisableBusinessLogic__c.getInstance(UserInfo.getUserId());
  if (triggerControl.stopOrderItemTrigger || PS_TaskTriggerHelper.stopOItemTgrPS_TaskTriggerHandler) {
    //ITMKT21-4     // HG to check if only one can be used
    return;
  }
  //TODO: Block Trigger with Order CS.
  if (!csDisableBusinessLogic.Disable_OrderItem_Trigger__c) {
    TriggerManager.invokeHandlerWithoutException(new OrderItemTriggerHandler());
  }
}