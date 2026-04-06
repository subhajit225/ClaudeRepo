/* Apex Trigger on Quote Document object */
trigger QuoteDocumentTrigger on SBQQ__QuoteDocument__c (before insert, after insert, before update, after update, after delete, after undelete)
{
    new QuoteDocumentTriggerHandler().run();
}