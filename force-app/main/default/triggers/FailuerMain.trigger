/* This FailuerMain trigger is created for PRDOPS21-102 */
trigger FailuerMain on Failure__c (before insert, before update, before delete, after insert, after update, after delete) { 
  new RMAFailureTriggersHandler().run();  
    
}