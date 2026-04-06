global class LeadAttemptFieldUpdateBatch implements Database.Batchable<sObject> {  
     
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id FROM Lead WHERE (LastModifiedDate = LAST_N_MONTHS:6 OR LastModifiedDate = This_Month) AND Status != \'Non-Qualified\'';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Lead> ldIdList) {
        List<Lead> ldToBeUpdated = new List<Lead> ();
        
        for(Lead ld : [SELECT Id, Attempts_All_Time__c, Most_Recent_Activity_Date__c, Touches_since_MQL__c, Last_MQL_Date__c,
                                 (SELECT Id, CreatedDate FROM Tasks ORDER BY CreatedDate DESC) 
                                 FROM Lead WHERE Id IN :ldIdList]){
            if(!ld.Tasks.IsEmpty()) {          
                integer touchesAfterMql = 0; 
                for(Task ts : ld.Tasks){
                    if(ld.Last_MQL_Date__c != null && Date.valueOf(ts.CreatedDate) >= ld.Last_MQL_Date__c){
                        touchesAfterMql += 1;
                    }
                }
                ld.Attempts_All_Time__c = ld.Tasks.size();
                ld.Touches_since_MQL__c = touchesAfterMql;
                
                ldToBeUpdated.add(ld);
            }
        }
        if(!ldToBeUpdated.IsEmpty()){
            Database.SaveResult[] srList = Database.update(ldToBeUpdated, false);
            List<Batch_Log__c> bList = new List<Batch_Log__c> ();
            
            // Iterate through each returned result
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully Updated Lead : ' + sr.getId());
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Lead fields that affected this error: ' + err.getFields());
                        
                        bList.add(new Batch_Log__c(Source_Component__c = 'LeadAttemptFieldUpdateBatch', Related_Object__c = 'Lead', Related_Record_ID__c = sr.getId(), Description__c = err.getStatusCode() + ' : ' + err.getMessage() +' : ' + err.getFields()));
                    }
                }
            }
            
            Database.SaveResult[] bSRList = Database.update(bList, false);
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        // execute any post-processing operations
    }
    
}