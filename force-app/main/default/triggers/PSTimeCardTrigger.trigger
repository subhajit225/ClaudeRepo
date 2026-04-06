/**
* @Author      : Sai Kishore
*/
trigger PSTimeCardTrigger on PS_Time_Card__c (before update) {
   		system.debug('Trigger execution');
        TriggerManager.invokeHandler(new PSTimeCardTriggerHandler()); 
}