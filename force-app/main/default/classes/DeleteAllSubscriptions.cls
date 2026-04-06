global class DeleteAllSubscriptions implements Database.Batchable<sObject>{
    public String callFrom;
    global DeleteAllSubscriptions(String callFrom){
        this.callFrom = callFrom;
    }
    global Database.QueryLocator start(Database.BatchableContext BC) {
        Id curentUser15DigitId = Id.valueOf(Userinfo.getUserId()).to15(); 
        if(callFrom == 'Forum'){
            
            String query = 'Select Id,KB_ID__c,User__c From Customer_Subscription__c where KB_ID__c!=null AND Type__c=\'FeedItem\' AND User__c=\''+curentUser15DigitId+'\'';
            return Database.getQueryLocator(query);
            
        }
        /*if(callFrom == 'Kb'){
            
            String query = 'Select Id,KB_ID__c,User__c From Customer_Subscription__c where KB_ID__c!=null AND Type__c=\'Article\' AND User__c=\''+curentUser15DigitId+'\'';
            return Database.getQueryLocator(query);
            
        }*/
        return null;
    }
    
    global void execute(Database.BatchableContext BC, List<Customer_Subscription__c> csList) {
        
        try {
            if(!csList.isEmpty()){
                if(callFrom == 'Forum'){
                    for(Customer_Subscription__c cs : csList){                
                        ConnectApi.ChatterFeeds.updateFeedElementBookmarks(system.label.networkScope, cs.KB_ID__c, false); 
                    }
                    DELETE csList;
                }
                else{
                    DELETE csList;
                }
            }
            
        } catch(Exception e) {
            System.debug(e);
        }
        
    }   
    
    global void finish(Database.BatchableContext BC) {
        // execute any post-processing operations like sending email
    }
}