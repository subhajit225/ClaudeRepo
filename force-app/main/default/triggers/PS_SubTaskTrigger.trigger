trigger PS_SubTaskTrigger on PS_SubTask__c (after insert, after update) {
    if(PS_SubTaskTriggerHandler.noRecurssion){
        return;
    }
	if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate) ) {
        PS_SubTaskTriggerHandler.updateBillable(Trigger.new);
    }
}