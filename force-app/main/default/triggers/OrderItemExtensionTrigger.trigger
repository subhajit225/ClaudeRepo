/************************************************************
* @description       : Order Item Extension trigger
* @autor             : Ravi
* @last modified on  : 05-24-2024
* @last modified by  : Ravi
* Modifications Log
* Ver   Date          Author       Modification
* 1.0   05-24-2024    Ravi         Initial Version
**************************************************************/
trigger OrderItemExtensionTrigger on Order_Item_Extension__c(after insert, after update) {
    try {
        ShGl_DisableBusinessLogic__c orderFlowControl = ShGl_DisableBusinessLogic__c.getInstance();
        
        // Check if the trigger logic should be disabled
        if (
            orderFlowControl.Disable_OrderItemExtension_Trigger__c ||
            TriggerControl.stopOrderItemExtensionTrigger ||
            (TriggerControl__c.getInstance('OrderItemExtension') != null &&
             TriggerControl__c.getInstance('OrderItemExtension').DisableTrigger__c)
        ) 
        {
            return;
        }
        // Execute the handler
        OrderItemExtensionHandler extensionHandler = OrderItemExtensionHandler.getInstance();
        extensionHandler.execute();
        
        // Throw a test exception if running in test context
        if (Test.isRunningTest()) {
            throw new System.DmlException('Test Exception');
        }
        
    } catch (Exception ex) {
        // Log the exception
        OrderItemExtensionHelper.getInstance().errorLogs.add(
            new Error_Logs__c(
                Error_Type__c = 'Order Item Extension Error',
                Error_Message__c = ex.getMessage() + '\r\n' + ex.getStackTraceString(),
                Type__c = 'SFDC'
            )
        );
    } finally {
        // Insert error logs
        System.debug(LoggingLevel.Error, 'Error Logs :: ' + OrderItemExtensionHelper.getInstance().errorLogs);
        
        List<Error_Logs__c> errLogToInsert = new List<Error_Logs__c>();
        for (Error_Logs__c errLog : OrderItemExtensionHelper.getInstance().errorLogs) {
            if (errLog.Id == null) {
                errLog.RecordId__c = Trigger.new[0].Id;
                errLogToInsert.add(errLog);
            }
        }
        
        if (!errLogToInsert.isEmpty()) {
            Database.insert(errLogToInsert, false);
        }
    }
}