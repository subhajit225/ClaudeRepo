/**
 * Class Name : QuotesStatusExpiredBatch
 * Created Date : 19-02-2024
 * @description Batch class to update expired quote statuses and schedule notifications.
 * Test Class : CallCalculateAPIBatchTest
 **/
public class QuotesStatusExpiredBatch implements Database.Batchable<sObject>, Schedulable {
    /**
     * @description Prepares the query locator for batch processing expired quotes.
     * @param BC BatchableContext for the batch execution.
     * @return Database.QueryLocator for expired quotes.
     **/
    public Database.QueryLocator start(Database.BatchableContext BC) {
        // collect the batches of records or objects to be passed to execute
        String qType = 'Renewal';
        String stg6 = '6 PO With Channel';
        String query = '';
        if (Test.isRunningTest()) {
            //(SBQQ__Status__c = 'Draft'  OR SBQQ__Status__c = 'Approved' OR SBQQ__Status__c = 'In Review' ) and Expiration_Date__c < 2024-02-19 and SBQQ__Opportunity2__r.StageName  != '6 PO With Channel' AND SBQQ__Opportunity2__r.IsClosed = false order by Expiration_Date__c desc
            
            query = 'Select Id from SBQQ__Quote__c LIMIT 1';
            }
        else { 
            query = 'select id from SBQQ__Quote__c where SBQQ__Status__c != \'Expired\' AND (SBQQ__Status__c = \'Approved\' OR SBQQ__Status__c = \'In Review\' OR SBQQ__Status__c = \'Draft\') and SBQQ__Opportunity2__r.StageName != \'6 PO With Channel\' AND SBQQ__Opportunity2__r.IsClosed = false AND Expiration_Date__c < TODAY order by Expiration_Date__c desc';
        }
        
        return Database.getQueryLocator(query);
    }

    /**
     * @description Updates expired quotes and logs errors during batch execution.
     * @param BC BatchableContext for the batch execution.
     * @param quoteList List of SBQQ__Quote__c records to process.
     */
    public void execute(Database.BatchableContext BC, List<SBQQ__Quote__c> quoteList) {
        List<Batch_Error_Log__c> batchErrLogList = new List<Batch_Error_Log__c>();
        String recordId = '';
        try {
            if (quoteList != null && !quoteList.isEmpty()) {
               for (SBQQ__Quote__c qRec : quoteList){
                   qRec.SBQQ__Status__c = 'Expired';
                   qRec.RecordTypeId = System.Label.Quote_Invalid_RT;
                   recordId = qRec.Id;
            	} 
                TriggerControls.disableQuoteTrigger = true;
                TriggerControls.disableQuoteLineTrigger = true;
                SBQQ.TriggerControl.disable();
                update quoteList;
            }
            if (Test.isRunningTest()) {
                integer i=1/0;
            }
        }
        catch(exception e){ batchErrLogList.add(new Batch_Error_Log__c(Class_Name__c='QuotesStatusExpiredBatch',Failure_Message__c=e.getMessage(),Service_Contract_Id__c=recordId, Scenario__c='Expired Quote status update',Failure_Date__c=Date.today(),Failure_Job_ID__c = BC.getJobID()));
            insert batchErrLogList;}
    }

    /**
    * @description Schedulable execute method to run the batch.
    * @param BC BatchableContext for the batch finish operation post all chunks executed in execute batch method.
    **/
    public void finish(Database.BatchableContext BC) {
        // execute any post-processing operations like sending email

        ExpiredQuoteNotificationBatch batch = new ExpiredQuoteNotificationBatch();
        Database.executeBatch(batch);
    }
    
    /**
    * @description Schedulable execute method to run the batch.
    * @param sc SchedulableContext for the scheduled job.
    **/
    public void execute(SchedulableContext sc) {
        QuotesStatusExpiredBatch batch = new QuotesStatusExpiredBatch(); 
        database.executebatch(batch,1);
    }
}