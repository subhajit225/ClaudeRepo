trigger specialistRequestTrigger on Specialist_Request__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
    new specialistRequestTriggerHandler().run();
}