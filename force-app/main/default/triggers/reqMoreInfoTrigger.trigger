trigger reqMoreInfoTrigger on Request_More_Information_Notes__c (before insert, after insert, before update, after update) {
    
     if(trigger.isBefore && trigger.isInsert){
        reqMoreInfoTriggerHandler.onBeforeInsert(trigger.new);
    }
    
    if(trigger.isAfter && trigger.isInsert){
        reqMoreInfoTriggerHandler.onAfterInsert(trigger.new, trigger.newMap);
        
    }
    if(trigger.isBefore && trigger.isUpdate){
        reqMoreInfoTriggerHandler.onBeforeUpdate(trigger.new, trigger.oldMap);
        
    }
    if(trigger.isAfter && trigger.isUpdate){
        reqMoreInfoTriggerHandler.onAfterUpdate(trigger.new, trigger.oldMap);
        
    }

}