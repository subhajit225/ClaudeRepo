trigger dDCaseCommentsTrigger on Deal_Desk_Comments__c (after insert) {
    
     if(trigger.isAfter && trigger.isInsert){
        dDCaseCommentsTriggerHandler.onAfterInsert(trigger.new, trigger.newMap);
    }

}