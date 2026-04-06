global class CloneQuotewithQLIs implements Database.Batchable<sObject> ,Database.Stateful{
    public Set<Id> quoteIds = new Set<Id>();
    public List<SBQQ__QuoteLine__c> toBeUpdatedQLIs = new List<SBQQ__QuoteLine__c>();
    public CloneQuotewithQLIs (Set<ID> setQuoteIDs) {
        quoteIds = setQuoteIDs;
        
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // collect the batches of records or objects to be passed to execute
   
        String query = 'SELECT id from SBQQ__Quote__c where id in :quoteIds';
        return Database.getQueryLocator(query);
    }
     
    global void execute(Database.BatchableContext BC, List<SBQQ__Quote__c> quoteList) {
        Map<Id, Id> oldToNewQuoteMap = cloneQuote(quoteList);
        cloneQuoteLines(oldToNewQuoteMap);
    }   
    
    global void finish(Database.BatchableContext BC) {
        // execute any post-processing operations like sending email
        update toBeUpdatedQLIs;
    }
    
    
    public Map<Id, Id> cloneQuote(List<SBQQ__Quote__c> quoteList) {
        // Get the original quotes

        String objQuery = 'SELECT ' + String.join(getAllFields('SBQQ__Quote__c'), ',') + ' FROM SBQQ__Quote__c WHERE Id IN : quoteIds';
        system.debug('objQueryobjQuery    '+objQuery);
        List<SBQQ__Quote__c> originalQuotes = Database.query(objQuery);

        // Create a map to store the relationship between original and cloned quotes
        Map<Id, SBQQ__Quote__c> originalToClonedMap = new Map<Id, SBQQ__Quote__c>();

        // Clone each original quote
        for (SBQQ__Quote__c originalQuote : originalQuotes) {
            SBQQ__Quote__c clonedQuote = originalQuote.clone(false, false, false, false);
            clonedQuote.SBQQ__Source__c = originalQuote.Id;
            originalToClonedMap.put(originalQuote.Id, clonedQuote);
        }

        // Insert the cloned quotes
        insert originalToClonedMap.values();
        
        // Return a map of old quote IDs to new quote IDs
        Map<Id, Id> oldToNewQuoteMap = new Map<Id, Id>();
        for (SBQQ__Quote__c originalQuote : originalQuotes) {
            oldToNewQuoteMap.put(originalQuote.Id, originalToClonedMap.get(originalQuote.Id).Id);
        }
        return oldToNewQuoteMap;
    }
    
    
    public void cloneQuoteLines(Map<Id, Id> oldToNewQuoteMap) {
        // Get the original quote lines
        Set<Id> quoteIdSet = oldToNewQuoteMap.keyset();
        String objQuery = 'SELECT ' + String.join(getAllFields('SBQQ__QuoteLine__c'), ',') + ' FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN : quoteIdSet';
        system.debug('objQueryobjQuery    '+objQuery);
        List<SBQQ__QuoteLine__c> originalQuoteLines  = Database.query(objQuery);

        // Create a map to store the relationship between original and cloned quote lines
        Map<Id, SBQQ__QuoteLine__c> originalToClonedMap = new Map<Id, SBQQ__QuoteLine__c>();

        // Clone each original quote line
        for (SBQQ__QuoteLine__c originalQuoteLine : originalQuoteLines) {
            SBQQ__QuoteLine__c clonedQuoteLine = originalQuoteLine.clone(false, false, false, false);
            clonedQuoteLine.SBQQ__Quote__c = oldToNewQuoteMap.get(clonedQuoteLine.SBQQ__Quote__c);
            originalToClonedMap.put(originalQuoteLine.Id, clonedQuoteLine);
        }
        insert originalToClonedMap.values();

        // Update the SBQQ__RequiredBy__c field of each cloned quote line to maintain the hierarchy
        for (SBQQ__QuoteLine__c clonedQuoteLine : originalToClonedMap.values()) {
            if (originalToClonedMap.containsKey(clonedQuoteLine.SBQQ__RequiredBy__c)) {
                clonedQuoteLine.SBQQ__RequiredBy__c = originalToClonedMap.get(clonedQuoteLine.SBQQ__RequiredBy__c).Id;
                //clonedQuoteLine.SBQQ__Quote__c = oldToNewQuoteMap.get(clonedQuoteLine.SBQQ__Quote__c);
                toBeUpdatedQLIs.add(clonedQuoteLine);
            }
        }

        // Insert the cloned quote lines
        //update originalToClonedMap.values();
    }

    public void cloneSObject(Map<Id, Id> oldToNewQuoteMap, String objectName, String relationshipFieldName) {
        // Get the original quotes

        Set<Id> quoteIdSet = oldToNewQuoteMap.keyset();
        String objQuery = 'SELECT ' + String.join(getAllFields(objectName), ',') + ' FROM ' + objectName + ' WHERE ' + relationshipFieldName + ' IN : quoteIds';
        system.debug('objQueryobjQuery    '+objQuery);
        List<SObject> originalRecordList = Database.query(objQuery);

        // Create a map to store the relationship between original and cloned quotes
        Map<Id, SObject> originalToClonedMap = new Map<Id, SObject>();

        // Clone each original quote
        for (SObject originalRecord : originalRecordList) {
            SObject clonedQuote = originalRecord.clone(false, false, false, false);
            originalToClonedMap.put(originalRecord.Id, clonedQuote);
        }

        // Insert the cloned quotes
        insert originalToClonedMap.values();
        /*
        // Return a map of old quote IDs to new quote IDs
        Map<Id, Id> oldToNewQuoteMap = new Map<Id, Id>();
        for (SBQQ__Quote__c originalRecord : originalRecordList) {
            oldToNewQuoteMap.put(originalRecord.Id, originalToClonedMap.get(originalRecord.Id).Id);
        }*/
    }

    public static list<String>  getAllFields(String sObjectName){
        list<String> listOfFields = new list<string>();
        Map<String, Schema.SObjectType> globalDescribeIns = Schema.getGlobalDescribe();    
        Map <String, Schema.SObjectField> fieldMap = globalDescribeIns.get(sObjectName).getDescribe().fields.getMap();
        
        for(Schema.SObjectField fieldAPI : fieldMap.values())
        {  
            Schema.DescribeFieldResult fieldDetail = fieldAPI.getDescribe();
            if(fieldDetail.isCreateable()){
                listOfFields.add(fieldDetail.getName());
            }
            
        }
        return listOfFields;
    }
}