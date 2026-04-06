trigger AccountScreeningTrigger on Account_Screening__c (before insert, before update, before delete, after insert, after update, after delete) {
  AccountScreeningTriggerHandler handler = new AccountScreeningTriggerHandler();
  handler.run(); 
}