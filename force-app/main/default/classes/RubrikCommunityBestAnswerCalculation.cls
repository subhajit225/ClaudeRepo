/**
* @description Batch Job to consolidate and calculate the best answers count per user - CS21-804
*
* @CreatedDate 9th Dec 2021
* @Created By Veera Gandi
* 
* @Test Class RubrikCommunityBestAnswerCalculationTest
*/
public class RubrikCommunityBestAnswerCalculation implements Database.Batchable<sObject>, Database.stateful, Schedulable  {
    public String query;
    public Map<String, Integer> bestAnswersSummary;
    
    /**
    * @description Constructor to get batch job query to be executed in start method.
    * Constructor used to calculate best answers for all the records feedItems in the Org
    * We cannot execute this job incrementally as removing best answer doesn't update feeditem
    */
    public RubrikCommunityBestAnswerCalculation(){       
        this.query = 'SELECT Id, BestComment.CreatedById FROM FeedItem WHERE BestCommentId IN';
        this.query += ' (SELECT Id FROM FeedComment)';
        
        if (Test.isRunningTest()) {
            this.query += ' LIMIT 1';
        }
        
        this.bestAnswersSummary = new Map<String, Integer>();
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
    public void execute(Database.BatchableContext batchableContext, List<FeedItem> feedItems){
        for (FeedItem eachItem : feedItems) {
            integer bestAnswerCount = bestAnswersSummary.containsKey(eachItem.BestComment.CreatedById) ? bestAnswersSummary.get(eachItem.BestComment.CreatedById) + 1 : 1;
            bestAnswersSummary.put(eachItem.BestComment.CreatedById, bestAnswerCount);
        }
    }
    
    /**
    * @description finish is to execute post-processing operations
    * @param  batchableContext - Database.BatchableContext
    * @return void
    */
    public void finish(Database.BatchableContext batchableContext){
        if (!bestAnswersSummary.isEmpty()) {
            RubrikCommunityBestAnswerUpdate updateBestAnswerCountOnForumUser = new RubrikCommunityBestAnswerUpdate(bestAnswersSummary);
            Database.executeBatch(updateBestAnswerCountOnForumUser, 200);
        }
    }
    
    /**
    * @description execute method to schedule the batch job
    * @param  SchedulableContext
    * @return void
    */
    public void execute(SchedulableContext sc) {
        RubrikCommunityBestAnswerCalculation rubrikBestAnswerCalculation = new RubrikCommunityBestAnswerCalculation();
        Database.executeBatch(rubrikBestAnswerCalculation, 200);
    }
}