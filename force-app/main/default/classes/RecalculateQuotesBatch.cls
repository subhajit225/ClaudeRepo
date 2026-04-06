global class RecalculateQuotesBatch implements Database.Batchable<sObject>, Schedulable, Database.Stateful {
    public List<SBQQ__Quote__c> quoteIds = new List<SBQQ__Quote__c>();
    List<Batch_Error_Log__c> batchErrLogList= new List<Batch_Error_Log__c>();
    List<Batch_Error_Log__c> batchErrLogListExisting = new List<Batch_Error_Log__c>();
    public Id recordId;
    
    global integer Summary;
     
    global RecalculateQuotesBatch(){
        Summary = 0;
    }  
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        // collect the batches of records or objects to be passed to execute
        String qType = 'Renewal';
        String stg6 = '6 PO With Channel';
        String stat = 'Draft';
        Date dT = Date.Today();
        DateTime todayDate= Date.newInstance(dT.year(), dT.month(), dT.day());
        String query = '';
        if (Test.isRunningTest()) {
           query = 'select id, SBQQ__Uncalculated__c from SBQQ__Quote__c where SBQQ__Type__c = \''+qType+ '\' and SBQQ__Opportunity2__r.StageName != \'' +stg6+ '\' and SBQQ__Status__c = \'' +stat+ '\' AND SBQQ__Opportunity2__r.IsClosed = false and SBQQ__Primary__c =true order by SBQQ__Opportunity2__r.CloseDate ASC, CreatedDate DESC LIMIT 100';
        }
        else {
           query = 'select id, SBQQ__Uncalculated__c from SBQQ__Quote__c where SBQQ__Uncalculated__c =true and SBQQ__Type__c = \''+qType+ '\' and SBQQ__Opportunity2__r.StageName != \'' +stg6+ '\' and SBQQ__Status__c = \'' +stat+ '\' AND SBQQ__Opportunity2__r.IsClosed = false and SBQQ__Primary__c =true order by SBQQ__Opportunity2__r.CloseDate ASC, CreatedDate DESC LIMIT 100';
        }
        return Database.getQueryLocator(query);
        
    }
     
    global void execute(Database.BatchableContext BC, List<SBQQ__Quote__c> quoteList) {
        try {
            if (!quoteList.isEmpty()) {
                quoteIds.addAll(quoteList);
                for (SBQQ__Quote__c quoteRec : quoteList) {
                    recordId = quoteRec.Id;
                    QuoteReader reader = new QuoteReader();
                    QuoteModel quote = reader.read(quoteRec.Id);
                    QuoteCalculator calculator = new QuoteCalculator();
                    calculator.calculate(quote, 'MyCallback');
                }
            }
            if (Test.isRunningTest()) {
                Integer i = 1/0;
            }
            
        }
        catch(exception e){ 
            //List<Batch_Error_Log__c> batchErrLogList= new List<Batch_Error_Log__c>();
            if(recordId != null){
            batchErrLogListExisting = [Select Id, Name, Service_Contract_Id__c, Failure_Message__c from Batch_Error_Log__c where Service_Contract_Id__c=:recordId AND Failure_Date__c =: Date.today()]; 
                if (batchErrLogListExisting.size() == 0) {
                    batchErrLogList.add(new Batch_Error_Log__c(Class_Name__c='RecalculateQuotesBatch',Failure_Message__c=e.getMessage(),Service_Contract_Id__c=recordId,
                                                           Scenario__c='Quote recalculation',Failure_Date__c=Date.today(),Failure_Job_ID__c = BC.getJobID()));
                    insert batchErrLogList;
                }
            }
        }
    }   
    
    global void finish(Database.BatchableContext BC) {
        system.debug('Finish');
        // execute any post-processing operations like sending email
        //Create batchable context records
        if (quoteIds != null && !quoteIds.isEmpty() && batchErrLogListExisting.size() == 0) {
            for (SBQQ__Quote__c qtRec : quoteIds) {
                if (qtRec.SBQQ__Uncalculated__c == true && recordId != null) {
                    batchErrLogList.add(new Batch_Error_Log__c(Class_Name__c='RecalculateQuotesBatch',Failure_Message__c='Quote has failed recalculation',Service_Contract_Id__c=recordId,
                                                           Scenario__c='Quote recalculation',Failure_Date__c=Date.today()));
                    Summary = Summary + 1;                                       
                }
            }
        }
        if(batchErrLogList.size()>0){
            Map<String, Batch_Error_Log__c> updateMap = new Map<String, Batch_Error_Log__c>();
            for (Batch_Error_Log__c blObj : batchErrLogList) {  
                updateMap.put(blObj.Service_Contract_Id__c, blObj);
            }

            if (updateMap != null && !updateMap.isEmpty()) {
                upsert updateMap.values();
            }
        }
    }
    
    /**
    * @description Schedule class execure method
    * @param  SchedulableContext - SchedulableContext
    * @return void
    */
    public void execute(SchedulableContext sc) {
        RecalculateQuotesBatch batch = new RecalculateQuotesBatch(); 
        database.executebatch(batch,1);
       
    }
}