/**
* @description Batch Job to update Case Comment counts on Cases.
* This is a one time job to update CaseCommentsPublic__c, CaseCommentsPrivate__c 
* on Cases - JIRA - CS21-574
*
* @CreatedDate 13th Aug 2021
* @Created By Veera Gandi
* 
* @Test Class RollupCaseCommentsCountOnCaseBatchTest
*/
public class RollupCaseCommentsCountOnCaseBatch implements Database.Batchable<sObject> {
    public String query;
    
    /**
    * @description Constructor to get batch job query to be executed in start method.
    * query eg: SELECT Id, CreatedDate FROM Case WHERE CreatedDate > 2021-06-01T00:00:00.000+0000
    */
    public RollupCaseCommentsCountOnCaseBatch(string query){       
        this.query = query;
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
    public void execute(Database.BatchableContext batchableContext, List<Case> caseList){
        Map<Id, Case> cases = new Map<Id, Case>();
        
        //cases for which case comment need to be re-calculated
        //initiate case object and reset casecomment counts to 0 
        for (Case eachCase : caseList) {
            eachCase.CaseCommentsPublic__c = 0; 
            eachCase.CaseCommentsPrivate__c  = 0;
            eachCase.LastPrivateCommentCreatedDate__c = null; 
            eachCase.LastPublicCommentCreatedDate__c  = null;
            cases.put(eachCase.Id, eachCase);
        }
        
        if (!cases.isEmpty()) {
            //aggegate query to get public and private case counts
            for (AggregateResult result : [SELECT Count(Id) total, ParentId caseId, IsPublished isPublic, 
                                           Max(CreatedDate) lastCommentCreatedDate 
                                           FROM CaseComment 
                                           WHERE ParentId IN : cases.KeySet()
                                           GROUP BY ParentId, IsPublished]) {
                Integer commentsCount = (Integer) result.get('total');
                Boolean isPublicComment = (Boolean) result.get('isPublic');
                Id currentCaseId = (Id) result.get('caseId');
                DateTime lastCommentCreatedDate = (DateTime) result.get('lastCommentCreatedDate');
                
                if (isPublicComment) {
                    cases.get(currentCaseId).CaseCommentsPublic__c = commentsCount;
                    cases.get(currentCaseId).LastPublicCommentCreatedDate__c = lastCommentCreatedDate;
                } else {
                    cases.get(currentCaseId).CaseCommentsPrivate__c = commentsCount;
                    cases.get(currentCaseId).LastPrivateCommentCreatedDate__c = lastCommentCreatedDate;
                }
            }
        }
        
        //update recalculated case counts
        if (!cases.isEmpty()) {
            List<Database.SaveResult> saveResults = Database.Update(cases.values(), false);
            
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
		System.debug(LoggingLevel.DEBUG, 'Case Comment Summary Job completed successfully.');
    }
}