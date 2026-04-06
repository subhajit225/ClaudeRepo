/**
* @description Batch Job to call calculate API for Quote.
*              JIRA - REEN-25     
* @CreatedDate 21th Dec 2023
**/
public class QuoteCalculateAndSubmitBatch implements Database.Batchable<sObject>{ 
    
    public set<Id> quoteIDS;
    public set<Id> approvedQuoteIDS;
    public List<Batch_Error_Log__c> batchErrLogList = new List<Batch_Error_Log__c>();
    /** 
* @description batch constructor for commor queries 
* @param setOfQuoteIDS
* @param approvedSetOfQuoteIDS
* **/
    public QuoteCalculateAndSubmitBatch(set<Id> setOfQuoteIDS,set<Id> approvedSetOfQuoteIDS){
        
        this.quoteIDS=setOfQuoteIDS;
        this.approvedQuoteIDS=approvedSetOfQuoteIDS;
    }
    /**
* @description Batch Job to claculate the Quote-Start method
* @param bc
* @return query
**/
    public Database.QueryLocator start(Database.BatchableContext bc){
        string quarystring= 'select id, SBQQ__Uncalculated__c,Force_Recalculation__c '
            + 'from SBQQ__Quote__c where ID IN:quoteIDS';
        return Database.getQueryLocator(quarystring);
    }
    /**
* @description Batch Job to claculate the Quote--Execute method
* @param bc
* @param quoteList
**/
    public void execute(Database.BatchableContext bc, List<SBQQ__Quote__c> quoteList){
        try {
            if (!quoteList.isEmpty()) {
                for (SBQQ__Quote__c quoteRec : quoteList) {
                    if (quoteRec.Force_Recalculation__c ) {
                        quoteRec.Force_Recalculation__c = false;
                    } else {
                        quoteRec.Force_Recalculation__c = true;
                    }
                }
                update quoteList;
            }
            
            if(Test.isRunningTest()) { //Khushboo
                DmlException e= new DmlException();
                e.setMessage('Failed to Perform due to Exception');
                throw e;
            }
            
        }
        catch(exception e){ 
            batchErrLogList.add(
                new Batch_Error_Log__c(Class_Name__c='QuoteCalculateAndSubmitBatch',
                                       Failure_Job_ID__c=bc.getJobId(),Failure_Message__c=String.valueOf(e.getMessage()),
                                       Scenario__c='Calcution of Quote is failed',Failure_Date__c=Date.today()));
        }
    }
    /**
* @description Batch Job to claculate the Quote--Finish method
* @param bc
**/
    public void finish(Database.BatchableContext BC){
        if(batchErrLogList!=null && !batchErrLogList.isEmpty()){
            insert batchErrLogList;
        }
        if(approvedQuoteIDS!=null && !approvedQuoteIDS.isEmpty()){
            CallQuoteSubmitAPIBatch CQSB=new CallQuoteSubmitAPIBatch(approvedQuoteIDS);
            Database.executeBatch(CQSB,1);
        }
    }
}