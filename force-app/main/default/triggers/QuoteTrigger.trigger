trigger QuoteTrigger on SBQQ__Quote__c (before insert,after insert, before update, after update, after delete, after undelete) {
    if(!TriggerControls.disableQuoteTrigger)
        new QuoteTriggerHandler().run();   
    //CPQ22-5393 starts
     if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)){
        /* Calling trackFieldsHistory method of CustomHistoryTracker class to track the hitsory of fields defined in the Field Set */
        String disabledHistorytracking = System.label.Disable_Quote_History_Tracking;
        if(disabledHistorytracking == 'No' || disabledHistorytracking == 'no'){ 
            CustomHistoryTracker.trackFieldsHistory(trigger.new, Trigger.oldMap, 'Quote__c'); //CPQ22-5393
        }
    } //CPQ22-5393 ends
}