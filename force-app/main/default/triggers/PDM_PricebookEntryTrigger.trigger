trigger PDM_PricebookEntryTrigger on PDM_PricebookEntry_Dump__c (before insert,before update,after insert,after update) {
  TriggerManager.invokeHandler(new PDM_PricebookEntryDumpTriggerHandler());
}