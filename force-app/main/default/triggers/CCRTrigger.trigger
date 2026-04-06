trigger CCRTrigger on CCR__c (before insert, before update, after insert, after update) {
      new CCRTriggerHandler().run(); 
}