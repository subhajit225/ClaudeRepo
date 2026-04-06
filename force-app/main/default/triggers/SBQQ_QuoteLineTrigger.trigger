trigger SBQQ_QuoteLineTrigger on SBQQ__QuoteLine__c (before insert,after insert, before update, after update, after delete, after undelete,before delete) {
    if(!TriggerControls.disableQuoteLineTrigger)
    new SBQQ_QuoteLineTriggerHandler().run();   
}