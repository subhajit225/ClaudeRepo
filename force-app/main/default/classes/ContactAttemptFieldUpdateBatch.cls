global class ContactAttemptFieldUpdateBatch  implements Database.Batchable<sObject> {  
       
    global Database.QueryLocator start(Database.BatchableContext BC) {
     string query = 'SELECT Id, Attempts_All_Time__c, Most_Recent_Activity_Date__c, Touches_since_MQL__c, Last_MQL_Date__c,(SELECT Id, CreatedDate FROM Tasks ORDER BY CreatedDate DESC) FROM Contact WHERE (LastModifiedDate = LAST_N_MONTHS:6 OR LastModifiedDate = This_Month) AND Contact_Status__c!= \'Non-Qualified\'';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Contact> conList) {
        List<Contact> conToBeUpdated = new List<Contact> ();
        
        for(Contact con : conList){
            if(!con.Tasks.IsEmpty()) {          
                integer touchesAfterMql = 0;
                integer touchesAlltime = 0;
                for(Task ts : con.Tasks){
                    if(con.Last_MQL_Date__c != null && Date.valueOf(ts.CreatedDate) >= con.Last_MQL_Date__c){
                        touchesAfterMql += 1;
                    }
                    if(ts.CreatedDate > System.Today().addDays(-60)){
                        touchesAlltime += 1;
                    }
                }
                con.Attempts_All_Time__c = touchesAlltime;
                con.Touches_since_MQL__c = touchesAfterMql;
                conToBeUpdated.add(con);
            }else if (con.Attempts_All_Time__c != 0){
                con.Attempts_All_Time__c = 0;
                conToBeUpdated.add(con);
            }
        }
        if(!conToBeUpdated.IsEmpty()){
            Database.SaveResult[] srList = Database.update(conToBeUpdated, false);
            List<Batch_Log__c> bList = new List<Batch_Log__c> ();
            
            // Iterate through each returned result
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully Updated Contact : ' + sr.getId());
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Contact fields that affected this error: ' + err.getFields());
                        
                        bList.add(new Batch_Log__c(Source_Component__c = 'ContactAttemptFieldUpdateBatch',Related_Object__c = 'Contact', Related_Record_ID__c = sr.getId(), Description__c = err.getStatusCode() + ' : ' + err.getMessage() +' : ' + err.getFields()));
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