global class DisableTrialUserBatch implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Date dt = System.today();
        String query = 'Select id from contact where  trial_Edge_End_Date__c =: dt AND Agreed_to_Edge_Trial_Agreement__c = true';
        return Database.getQueryLocator(query);
        // collect the batches of records or objects to be passed to execute
    }
    global void execute(Database.BatchableContext bc, List<Contact> records){
        Set<Id> contactIds = new Set<Id>();
        for(Contact con : records){
            contactIds.add(con.id);
        }
        List<User> userList = [SELECT id,isActive from user where contactId IN: contactIds AND Profile.Id =: Label.Trial_Edge_Profile];
        for(User u : userList){
            u.isActive = false;
        }
        update userList;
        // process each batch of records
    }    
    global void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }    
}