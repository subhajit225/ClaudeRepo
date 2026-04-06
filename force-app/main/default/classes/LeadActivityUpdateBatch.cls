global class LeadActivityUpdateBatch implements Database.Batchable<sObject> {
    
    global final String query;
    
    global LeadActivityUpdateBatch () {
        query = 'SELECT Id, Name, Attempts_All_Time__c, Most_Recent_Activity_Date__c, LastModifiedDate,Last_MQL_Date__c,Touches_since_MQL__c,(SELECT Id, CreatedDate FROM Tasks ORDER BY CreatedDate DESC) FROM Lead WHERE LastModifiedDate = LAST_N_DAYS:2';
    }
    
    global LeadActivityUpdateBatch (String qryStr) {
        query = qryStr;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Lead> ldList) {
        
        List<Lead> ldToBeUpdated = new List<Lead> ();
        
        for(Lead ld : ldList) {
            if(!ld.Tasks.IsEmpty()) { 
                Date mostRecentDate ;
                integer touchesAfterMql = 0; 
                integer touchesAlltime = 0; 
                for(Task ts : ld.Tasks){
                    if(ld.Last_MQL_Date__c != null && Date.valueOf(ts.CreatedDate) >= ld.Last_MQL_Date__c){
                        touchesAfterMql += 1;
                    }
                    if(ts.CreatedDate > System.Today().addDays(-60)){
                        touchesAlltime += 1;
                    }
                }
                ld.Attempts_All_Time__c = touchesAlltime;
                ld.Touches_since_MQL__c = touchesAfterMql;
                //attemptsMostRecent = mrTasklst != null ? mrTasklst.size() : 0;
                                
                mostRecentDate = ld.Tasks[0].createdDate.date();
                if(mostRecentDate != null) {
                    if(ld.Most_Recent_Activity_Date__c != mostRecentDate) {
                      ld.Most_Recent_Activity_Date__c = mostRecentDate;
                    }
                }
                  ldToBeUpdated.add(ld);
                  system.debug('Inside LeadActivityUpdateBatch : ldToBeUpdated :: '+ ldToBeUpdated);
            }else if(ld.Attempts_All_Time__c != 0){
                ld.Attempts_All_Time__c = 0;
                ldToBeUpdated.add(ld);
            }
        }  
        
        if(ldToBeUpdated.size() > 0) {
            system.debug(ldToBeUpdated);
            //update ldToBeUpdated;
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
                        
                        bList.add(new Batch_Log__c(Related_Object__c = 'Lead', Related_Record_ID__c = sr.getId(), Description__c = err.getStatusCode() + ' : ' + err.getMessage() +' : ' + err.getFields()));
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