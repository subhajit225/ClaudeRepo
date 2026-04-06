/*************************************************************************************************************
Description : Arroyo 2.0 Project
Developer : Shaloo
Date : 17-10-2022

Script to schedule the Batch Class:
metricCalcForArroyoBatch arroyoMetricsCalcBatch = new metricCalcForArroyoBatch();
System.schedule('Arroyo2.0Batch-Morning IST', '0 05 9 * * ?', new metricCalcForArroyoBatch());
System.schedule('Arroyo2.0Batch-Evening IST', '0 05 21 * * ?', new metricCalcForArroyoBatch()); 

Script to execute the Batch Class:
metricCalcForArroyoBatch arroyoMetricsCalcBatch = new metricCalcForArroyoBatch('a6T8C0000004eTtUAI');
Database.executebatch(arroyoMetricsCalcBatch, 1);

Script to stop jobs:
for(AsyncApexJob aJob: [SELECT Id, Status FROM AsyncApexJob WHERE 
CreatedById IN ('0056f00000AztBC') AND 
Status IN ('Processing', 'Holding','Queued',
'Preparing')])
{ 
System.AbortJob(aJob.Id); 
}
List<CronTrigger> jobsToAbort = [SELECT Id FROM CronTrigger WHERE 
CreatedById IN ('0056f00000AztBC')];
for(CronTrigger job : jobsToAbort){ 
System.abortJob(job.Id); 
}
************************************************************************************************************/

//REEN-73 removed stateful
public with sharing class metricCalcForArroyoBatch implements Database.Batchable<SObject>, Schedulable {
    /**query */
    public String query; 
    /**quoteId */
    public Set<Id> quoteId = new Set<Id>();
    /**recfound */
    public Boolean recfound = false;
    
    /*Constructor*/
    public metricCalcForArroyoBatch(){//REEN-121
        query = 'SELECT Id, Name, SBQQ__Type__c, SBQQ__Status__c, MetricsLastCalcOn__c, LastModifiedDate FROM SBQQ__Quote__c WHERE (SBQQ__Type__c = \'Renewal\' OR SBQQ__Type__c = \'Renewal+Expansion\' OR SBQQ__Type__c = \'Quote\' OR SBQQ__Type__c = \'Amendment\') AND SBQQ__Status__c != \'Approved\' AND SBQQ__Status__c != \'In Review\' AND SBQQ__Opportunity2__r.StageName != \'6 PO With Channel\' AND SBQQ__Opportunity2__r.StageName != \'7 Closed Admin\' AND SBQQ__Opportunity2__r.StageName != \'7 Closed Lost\' AND SBQQ__Opportunity2__r.StageName != \'7 Closed Won\'';    }
    
    /*Batch for one record specifically*/
    public metricCalcForArroyoBatch(Id quoteId){
        recfound = true;
        query = 'SELECT Id, Name, SBQQ__Type__c, SBQQ__Status__c, MetricsLastCalcOn__c, LastModifiedDate FROM SBQQ__Quote__c WHERE Id = \''+quoteId+'\'';
    }
    //REEN-73 added constructor
    /*Batch for  multi specifically*/
    public metricCalcForArroyoBatch(Set<Id> quoteIds){
        Set<String> qid = new Set<String>();
        
        for(Id quoteId: quoteIds){
            qid.add('\''+quoteId+'\'');   
        }
        
        List<String> qIDList = new List<String>();
        qIDList.addAll(qid);
        
        recfound = true;
        query = 'SELECT Id, Name, SBQQ__Type__c, SBQQ__Status__c, MetricsLastCalcOn__c, LastModifiedDate FROM SBQQ__Quote__c WHERE Id IN ('+String.join(qIDList,',')+')';
    }
    /**Start Method */
    public Database.QueryLocator start(Database.BatchableContext batchableContext){
        return Database.getQueryLocator(query);
    }
    
    /**Execute Method */
    public void execute(Database.BatchableContext batchableContext, List<SBQQ__Quote__c> scope){
        try{
            for(SBQQ__Quote__c quote: scope){
                if((quote.MetricsLastCalcOn__c == null) || (quote.MetricsLastCalcOn__c != null && (quote.MetricsLastCalcOn__c < quote.LastModifiedDate)) || recfound == TRUE){
                    quoteId.add(quote.Id);
                }
            }            
            if(quoteId != null && !quoteId.isEmpty()){
                //metricCalcForArroyoQueueable_v2.calculateMetrics(quoteId);
                MetricsCalculatorQueueable.calculateMetrics(quoteId);
            }
            //FY25SR-1125 Ends
        }
        catch(Exception ex){
            system.debug('Exception occured : ' + ex);
            List<Batch_Error_Log__c> belList = new List<Batch_Error_Log__c>();
            for(Id quote: quoteId){
            Batch_Error_Log__c bel = new Batch_Error_Log__c(Failure_Job_ID__c = batchableContext.getJobID(),Failure_Message__c = ex.getMessage(),Class_Name__c='metricCalcForArroyoBatch',Failure_Date__c=Date.today(),Service_Contract_Id__c=quote);
            belList.add(bel);}
            insert belList;
        }
    }
    /**Finish method */
    public void finish(Database.BatchableContext batchableContext){
        System.debug('Finish Method');
    }
    
    /**Execute method */
    public void execute(SchedulableContext schedulableContext){
        Database.executeBatch(new metricCalcForArroyoBatch(), 1);
    }
}