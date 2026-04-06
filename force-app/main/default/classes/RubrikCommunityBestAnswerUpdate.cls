/**
* @description Batch job to update best on count on respective User record - CS21-804
*
* @CreatedDate 9th Dec 2021
* @Created By Veera Gandi
* 
* @Test Class RubrikCommunityBestAnswerCalculationTest
*/
public class RubrikCommunityBestAnswerUpdate implements Database.Batchable<sObject>, Database.stateful {
    public String query;
    public Map<String, Integer> bestAnswersSummary;
    public Set<String> userIds;
    
    /**
    * @description Constructor to get batch job query to be executed in start method.
    */
    public RubrikCommunityBestAnswerUpdate(Map<String, Integer> bestAnswersSummary){
        this.bestAnswersSummary = bestAnswersSummary;
        this.userIds = bestAnswersSummary.KeySet();
        this.query = 'SELECT Id, BestAnswerCount__c FROM User WHERE Id IN :userIds';
        
    }

    /**
    * @description start method runs at the beginning of a batch Apex job which collects the records or objects to pass to the execute method. 
    * @param  BatchableContext - Database.BatchableContext
    * @return Database.QueryLocator - List of Accounts
    */
    public Database.QueryLocator start(Database.BatchableContext batchableContext){
        return Database.getQueryLocator(query);
    }
    
    /**
    * @description execute method is called for each batch of records that you pass to it
    * @param  BatchableContext - Database.BatchableContext
    * @param  accounts - List of Accounts
    * @return void
    */
    public void execute(Database.BatchableContext batchableContext, List<User> users){
        List<User> usersToUpdate = new List<User>();
        
        for (User eachUser : users) {
            if (bestAnswersSummary.containsKey(eachUser.Id) && eachUser.BestAnswerCount__c != bestAnswersSummary.get(eachUser.Id)) {
                eachUser.BestAnswerCount__c = bestAnswersSummary.get(eachUser.Id);
                usersToUpdate.add(eachUser);
            }
        }
        
        if (!usersToUpdate.isEmpty()) {
            List<Database.SaveResult> saveResults = Database.Update(usersToUpdate, false);
            
            for (Database.SaveResult result : saveResults) {
                if (!result.isSuccess()) {
                    System.debug('Error Occured ::' + JSON.serialize(result.getErrors()));
                }
            }
        }
    }
    
    /**
    * @description finish is to execute post-processing operations
    * @param  batchableContext - Database.BatchableContext
    * @return void
    */
    public void finish(Database.BatchableContext batchableContext){
		
    }
}