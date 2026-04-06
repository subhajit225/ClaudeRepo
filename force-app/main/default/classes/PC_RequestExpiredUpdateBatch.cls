/*** Batch class run daily to update expired checkbox on  Partner request submitter if no claim is submitted and it is more than 30 days of the activity end date
 **/ 
global class PC_RequestExpiredUpdateBatch implements Database.Batchable<SObject>, Database.Stateful {

      List<String> updateFailedResultList = new List<String>();
    // Query to fetch accounts where Custom_Date__c is 30 days before today
    global Database.QueryLocator start(Database.BatchableContext BC) {
        Date dayBefore31Days = Date.today().addDays(-31);
        Date startOf2025 = Date.newinstance(2025, 1, 1);
        String query = 'SELECT Id, Activity_End_Date__c, Status, Is_Expired__c, (SELECT Id FROM PartnerFundClaims) ' +
                       'FROM PartnerFundRequest ' +
                       'WHERE Status = \'Approved\' AND Activity_End_Date__c >= :startOf2025 AND Activity_End_Date__c <= :dayBefore31Days AND Is_Expired__c = false';
        return Database.getQueryLocator(query);
    }
    
    // Execute method to process each batch of Account records
    global void execute(Database.BatchableContext BC, List<PartnerFundRequest> requestList) {
        
        // Process each partner request record
        for (PartnerFundRequest requestRec : requestList) {
            if(requestRec.PartnerFundClaims.size() == 0){
               requestRec.Is_Expired__c = true;
           }
         }
        
         // Use Database.update with allOrNone set to false for partial success
        Database.SaveResult[] updateResults = Database.update(requestList, True);
     
    }
    
    // Finish method for post-processing (optional)
    global void finish(Database.BatchableContext BC) {
        System.debug(Logginglevel.INFO, 'Inside finish method');
    }
}