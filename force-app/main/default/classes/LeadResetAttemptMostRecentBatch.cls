//[SAL-183] Batch job to reset Attempts Most Recent field
global class LeadResetAttemptMostRecentBatch implements Database.Batchable<sObject>,  Schedulable {
    
    global void execute(SchedulableContext SC) {
        LeadResetAttemptMostRecentBatch ldBtch = new LeadResetAttemptMostRecentBatch(); 
    }
    
    global final String query = null ;
    
    global LeadResetAttemptMostRecentBatch () {
        query = 'SELECT Id, No_Activity_for_24_Days__c FROM Lead WHERE No_Activity_for_24_Days__c > 24 ';
    }
    
    global LeadResetAttemptMostRecentBatch (String qryStr) {
        query = qryStr;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Lead> leadList) {
        
    }   
    
    global void finish(Database.BatchableContext BC) {
        // execute any post-processing operations
    }
}