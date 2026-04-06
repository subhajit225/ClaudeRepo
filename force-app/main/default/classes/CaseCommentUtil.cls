/**
* @description Util class to update Case Comment Counts and Last Case Comment Created Dates
* on Cases - JIRA - CS21-574/CS21-689
*
* @CreatedDate 13th Aug 2021
* @Created By Veera Gandi
* 
* @Test Class CaseCommentUtilTest
*/
public without sharing class CaseCommentUtil {
    
    /**
    * @description Method to re-calculate case comment counts on the case - CS21-574/CS21-689
    * @param newlist - trigger context variable
    * @param oldmap - trigger context variable
    * @return void 
    */
    public static void rollupCaseCommentSummary(List<CaseComment> newList, Map<Id, CaseComment> oldMap) {
        
        Map<Id, Case> cases = new Map<Id, Case>();
        
        //check and collect caseIds for which case comment need to be re-calculated
        //initiate case object and reset casecomment counts to 0 
        for (CaseComment eachComment : newList) {
            if (trigger.isInsert 
                || trigger.isDelete 
                || (eachComment.IsPublished != oldMap.get(eachComment.Id).IsPublished)) 
            {
                //resetting case rollup fields for recalculation 
                Case currentCase = new Case();
                currentCase.Id=eachComment.ParentId;
                currentCase.CaseCommentsPublic__c = 0;
                currentCase.LastPublicCommentCreatedDate__c = null;
                
                //community users will not have access to private comments
                //bypassing private comment rollups for community users
                //reference : https://help.salesforce.com/s/articleView?id=000312705&type=1
                if (userInfo.getUserType() == 'Standard') {
                    currentCase.CaseCommentsPrivate__c = 0;
                    currentCase.LastPrivateCommentCreatedDate__c = null;
                }
                
                cases.put(eachComment.ParentId, currentCase);
            }
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

}