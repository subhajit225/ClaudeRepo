trigger DealUpdateTrigger on Deal_Update__c (after insert) {
    
    if(trigger.isAfter){
        if(trigger.isInsert){
            DealTriggerHandler.dealUpdatesonParent(trigger.new,trigger.newMap);
        }
    }
}