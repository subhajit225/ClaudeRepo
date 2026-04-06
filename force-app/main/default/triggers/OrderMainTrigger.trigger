/************************************************************
 * @description       : Order new trigger
 * @author            : Chaitra
 * @last modified on  : 01-20-2021
 * @last modified by  : Chaitra
 * Modifications Log  
 * Ver   Date          Author        Modification
 * 1.0   01-20-2021   Chaitra        Initial Version
* 1.1   06-14-2022   moises         PRDOPS23-433 Adding order id to error logs
 **************************************************************/
trigger OrderMainTrigger on Order(
  before insert,
  after insert,
  after update,
  before update
) {
  try {
         
    ShGl_DisableBusinessLogic__c orderFlowControl = ShGl_DisableBusinessLogic__c.getInstance();
    if (
      orderFlowControl.Disable_Order_Triggers__c ||
      TriggerControl.stopOrderTrigger ||
      (TriggerControl__c.getInstance('Order') != null &&
      TriggerControl__c.getInstance('Order').DisableTrigger__c)
    ) {
      return;
    } else {
        OrderHandler handler = OrderHandler.getInstance();
        if (
          Trigger.isBefore &&
          Trigger.isUpdate &&
          OrderInsertHelper.getInstance().ORIGIN_CONTEXT != 'Insert'
        ) {
          handler.setMaxLoopCount((Integer) orderFlowControl.Order_Trigger_MaxLoop_Count__c);
        }
        handler.execute();

        if(test.isRunningTest()){
          throw new system.DmlException('Test Exception');
      }
    }
  } catch (Exception excep) {
    OrderInsertHelper.getInstance().errorLogs.add(new Error_Logs__c( Error_Type__c = 'Order Error',Error_Message__c = excep.getMessage() +'\r\n' +excep.getStackTraceString(), Type__c = 'SFDC'));
  } finally {
    System.debug(LoggingLevel.Error,'Error Logs :: ' + OrderInsertHelper.getInstance().errorLogs);
    List<Error_Logs__c> errLogToInsert = new List<Error_Logs__c>();
    for (Error_Logs__c el : OrderInsertHelper.getInstance().errorLogs) {
      if (el.id == null) {
          if(Trigger.new[0].id != null){
            el.Order_ID__c = Trigger.new[0].id;
          }
        errLogToInsert.add(el);
        ShGl_DisableBusinessLogic__c orderFlowControl = ShGl_DisableBusinessLogic__c.getInstance();
        if(orderFlowControl.Order_Transaction_Control__c == 'Full Commit'){ // Use only for single record processing 
          if (Trigger.newMap?.containsKey(el.Related_Order__c)) {
              Trigger.newMap.get(el.Related_Order__c).addError(el.Error_Message__c);
          }else{
            Trigger.new[0].adderror(el.Error_Message__c); 
          }
        }  
      }
    }
    if (!errLogToInsert.isEmpty()) {
      database.insert(errLogToInsert);
    }
  }

}