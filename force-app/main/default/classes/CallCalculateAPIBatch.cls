global class CallCalculateAPIBatch implements Database.Batchable<sObject> {
    public Set<Id> quoteIds = new Set<Id>();
    public CallCalculateAPIBatch (List<SBQQ__Quote__c> quoteId) {
        for (SBQQ__Quote__c quoteRec : quoteId) {
            quoteIds.add(quoteRec.Id);
        }
        
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // collect the batches of records or objects to be passed to execute
        String query = 'SELECT id from SBQQ__Quote__c where id in :quoteIds';
        return Database.getQueryLocator(query);
    }
     
    global void execute(Database.BatchableContext BC, List<SBQQ__Quote__c> quoteList) {
        if (!quoteList.isEmpty()) {
            for (SBQQ__Quote__c quoteRec : quoteList) {
                QuoteReader reader = new QuoteReader();
                QuoteModel quote = reader.read(quoteRec.Id);
                QuoteCalculator calculator = new QuoteCalculator();
                calculator.calculate(quote, 'MyCallback');
            }
        }
    }   
    
    global void finish(Database.BatchableContext BC) {
        // execute any post-processing operations like sending email
    }
}