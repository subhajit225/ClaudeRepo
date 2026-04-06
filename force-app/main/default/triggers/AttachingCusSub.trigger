trigger AttachingCusSub on Community_Feed__c (before insert, after insert) {
    if(Trigger.isBefore && Trigger.isinsert){
        AttachingCusSubHelper.beforeInsert(Trigger.new);
    }
    if(Trigger.isafter && Trigger.isinsert){
        AttachingCusSubHelper.afterInsert(Trigger.new, Trigger.newMap);
    }
}