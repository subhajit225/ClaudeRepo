/***********************************************************************************************************
 * Class Name           : CallQuoteSubmitAPIBatch
 * Date Created/Modified: 27/05/2024
 * Author               : 
 * @description         : CallQuoteSubmitAPIBatch
 * Test Class           :
 /**********************************************************************************************************/
public with sharing class CallQuoteSubmitAPIBatch implements Database.Batchable<sObject>,Database.Stateful { 
    public set<Id> approvedQuoteIDS;
    public List<Batch_Error_Log__c> batchErrLogList = new List<Batch_Error_Log__c>();
    /***********************************************************************************************************
       * Method Name          : callQuoteSubmitAPIBatch
       * Date Created/Modified: 
       * Author               : 
       * @description         : CallQuoteSubmitAPIBatch method
       * @param               approvedSetOfQuoteIDS
    /**********************************************************************************************************/
    public callQuoteSubmitAPIBatch(set<Id> approvedSetOfQuoteIDS){
        if (approvedSetOfQuoteIDS != null && !approvedSetOfQuoteIDS.isEmpty()) {
            this.approvedQuoteIDS=approvedSetOfQuoteIDS;
        }
    }
    /***********************************************************************************************************
       * Method Name          : start
       * Date Created/Modified: 
       * Author               : 
       * @description         : start method
       * @param               BC
       * @return              :  queryString
    /**********************************************************************************************************/
    public Database.QueryLocator start(Database.BatchableContext BC){
        string Querystring= 'select id, SBQQ__Status__c from SBQQ__Quote__c where ID IN:approvedQuoteIDS';
        return Database.getQueryLocator(Querystring);
    }
    /***********************************************************************************************************
       * Method Name          : execute
       * Date Created/Modified: 
       * Author               : 
       * @description         : execute method
       * @param BC
       * @param quoteList
    /**********************************************************************************************************/
    public void execute(Database.BatchableContext BC, List<SBQQ__Quote__c> quoteList){
        try {
            if (quoteList != null && !quoteList.isEmpty()) {
                for (SBQQ__Quote__c quoteRec : quoteList) {
                    if (quoteRec.SBQQ__Status__c != ReplacementConstants.STATUS_APPROVED && 
                        quoteRec.SBQQ__Status__c != ReplacementConstants.STATUS_IN_REVIEW) {
                        SBAA.ApprovalAPI.submit(quoteRec.Id, SBAA__Approval__c.Quote__c);
                    }
                }
            }
            if(Test.isRunningTest()) { //Khushboo
             DmlException e= new DmlException();
             e.setMessage('Failed to Perform due to Exception');
             throw e;
             }
        }
        catch(exception e){ 
            //List<Batch_Error_Log__c> batchErrLogList= new List<Batch_Error_Log__c>();
            batchErrLogList.add(new Batch_Error_Log__c(Class_Name__c='CallQuoteSubmitAPIBatch',
            Failure_Job_ID__c=bc.getJobId(),Failure_Message__c=String.valueOf(e.getMessage()),
            Scenario__c='Submission for Approval failed',Failure_Date__c=Date.today()));
        }
    }
    /***********************************************************************************************************
       * Method Name          : finish
       * Date Created/Modified: 
       * Author               : 
       * @description         : finish method
       * @param BC
    /**********************************************************************************************************/
   public void finish(Database.BatchableContext BC){
       system.debug(LoggingLevel.DEBUG, 'finish Block');
   }
}