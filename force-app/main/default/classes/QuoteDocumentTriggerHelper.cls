/* Helper class for QuoteDocumentTrigger trigger */
public class QuoteDocumentTriggerHelper{
    public static Map<Id, SBQQ__Quote__c> allQuoteDocMap;
    public static List<SBQQ__Quote__c> quoteToUpdate = new List<SBQQ__Quote__c>();
    
    /**checkDocIsApproved */
    public static void checkDocIsApproved(List<SBQQ__QuoteDocument__c> newCCLRecords){
        system.debug('**checkDocIsApproved Method is called**');
        
        Set<Id> quoteIDs = new Set<Id>();
        
        if(((List<SBQQ__QuoteDocument__c>)Trigger.new) != null  && !((List<SBQQ__QuoteDocument__c>)Trigger.new).IsEmpty())
        {
            for(SBQQ__QuoteDocument__c qDoc: (List<SBQQ__QuoteDocument__c>)Trigger.new){
                system.debug('Quote Id: ' + qDoc.SBQQ__Quote__c);
                quoteIDs.add(qDoc.SBQQ__Quote__c);
            }
        }
        
        System.debug('quoteIDs: ' + quoteIDs);  
        if(!quoteIDs.isEmpty() && allQuoteDocMap == null){
            allQuoteDocMap = new Map<Id, SBQQ__Quote__c>([SELECT Id, Name, SBQQ__Status__c, Generate_Document__c FROM SBQQ__Quote__c WHERE Id IN :quoteIDs]);
        }
        
        if(((List<SBQQ__QuoteDocument__c>)Trigger.new) != null  && !((List<SBQQ__QuoteDocument__c>)Trigger.new).IsEmpty())
        {
            for(SBQQ__QuoteDocument__c qDoc: (List<SBQQ__QuoteDocument__c>)Trigger.new)
            {
                System.debug('allQuoteDocMap: ' + allQuoteDocMap);
                
                if(allQuoteDocMap != null && !allQuoteDocMap.isEmpty())
                {
                    if(allQuoteDocMap.containsKey(qDoc.SBQQ__Quote__c))
                    {
                        for(SBQQ__Quote__c existingQuoteDoc : allQuoteDocMap.values())
                        {
                            system.debug('Quote Status: ' + existingQuoteDoc.SBQQ__Status__c);
                            if(existingQuoteDoc.SBQQ__Status__c == 'Approved')
                            {
                                existingQuoteDoc.Generate_Document__c = TRUE;
                                quoteToUpdate.add(existingQuoteDoc);
                                System.debug('IsDocApproved: ' + existingQuoteDoc.Generate_Document__c);
                            }
                        }
                    }
                }
            }
        }
        
        if(quoteToUpdate != null && !quoteToUpdate.isEmpty())
        {
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true;
            SBQQ.TriggerControl.disable();
            
            update quoteToUpdate;
            
            TriggerControls.disableQuoteTrigger = false;
            TriggerControls.disableQuoteLineTrigger = false;
            SBQQ.TriggerControl.enable();
        }
    }
    
    //CPQ22-4425 new method
    public static void populateFields(List<SBQQ__QuoteDocument__c> docs){
        for (SBQQ__QuoteDocument__c doc : docs){
            doc.SBQQ__Opportunity__c = null;
        }
    }
    
    //CPQ22-4425 update key in case of multiple generate requests
    public static void handleDuplicateKey(List<SBQQ__QuoteDocument__c> docs){
        
        Map<String, SBQQ__QuoteDocument__c> newKeyMap = new Map<String, SBQQ__QuoteDocument__c>();
        Set<Id> quoteIds = new Set<Id>();
        for (SBQQ__QuoteDocument__c doc : docs){
            newKeyMap.put(doc.SBQQ__Key__c, doc);
            quoteIds.add(doc.SBQQ__Quote__c);
        }
        system.debug('newKeyMap '+newKeyMap);
        
        for (SBQQ__QuoteDocument__c doc : [SELECT Id, SBQQ__Key__c FROM SBQQ__QuoteDocument__c WHERE SBQQ__Quote__c IN :quoteIds AND SBQQ__Key__c IN :newKeyMap.keySet()]){
            system.debug('duplicate key '+doc.SBQQ__Key__c);
            SBQQ__QuoteDocument__c newDoc = newKeyMap.get(doc.SBQQ__Key__c);
            newDoc.SBQQ__Version__c += 1;
            newDoc.SBQQ__Key__c = newDoc.SBQQ__Quote__c + '_' + newDoc.SBQQ__Version__c;
        }
    }
    
}