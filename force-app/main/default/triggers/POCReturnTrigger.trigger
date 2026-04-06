trigger POCReturnTrigger on POC_Return__c (before insert,
                                                                 before update,
                                                                 before delete,
                                                                 after insert,
                                                                 after update,
                                                                 after delete) {
 	TriggerManager.invokeHandler(new POCReturnTriggerHandler());  
}