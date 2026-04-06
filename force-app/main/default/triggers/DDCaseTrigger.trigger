trigger DDCaseTrigger on Deal_Desk_Case__c (before insert, after insert, before update, after update, before delete) {
    if(trigger.isBefore && trigger.isInsert){
        DDCaseTriggerHandler.onBeforeInsert(trigger.new);
    }
    if(trigger.isBefore && trigger.isDelete){
        DDCaseTriggerHandler.onBeforeDelete(trigger.old);
    }
    if(trigger.isAfter && trigger.isInsert){
        DDCaseTriggerHandler.onAfterInsert(trigger.new, trigger.newMap);
        
    }
    if(trigger.isBefore && trigger.isUpdate){
        DDCaseTriggerHandler.onBeforeUpdate(trigger.new, trigger.oldMap);
        
    }
    if(trigger.isAfter && trigger.isUpdate){
        DDCaseTriggerHandler.onAfterUpdate(trigger.new, trigger.oldMap);
        
    }
}