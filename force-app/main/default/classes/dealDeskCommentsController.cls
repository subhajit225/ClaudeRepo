/**
* Date :26-October-2023
* Author : Rajat Jain
* JIRA : Deal Desk Case
* Test Class : dealDeskComments_Test
**/
public with sharing class dealDeskCommentsController {
    @AuraEnabled(cacheable=true)
    public static List<Deal_Desk_Comments__c> getddCommentsList(String parentId) {
        return [
            SELECT
                Id,
                ParentId__c,
                Body__c,
                Recipient_Names__c,
                Recipient_Ids__c,
                CreatedBy.Id,
                CreatedBy.Name,
                CreatedBy.SmallPhotoUrl,
                CreatedDate
            FROM Deal_Desk_Comments__c
            WHERE ParentId__c = :parentId 
            ORDER BY CreatedDate DESC
        ];
    }

    @AuraEnabled
    public static Deal_Desk_Comments__c createDDCommentsRec(Deal_Desk_Comments__c ddCommentRec){
        try {
            if(ddCommentRec.Body__c!=''){
                insert ddCommentRec;
                return ddCommentRec;
            }
            else{
                throw new AuraHandledException('Comment cannot be empty');
            } 
        } catch (Exception e) {throw new AuraHandledException(e.getMessage());}  
    }

}