public without sharing class  attachArticleToCase{
    
    @AuraEnabled
    public static List<How_To__kav> searchArticle(string articleNumber,string caseId){
        //List<List <sObject>> articleListWithDraftStatus = new List<List <sObject>>();
        string tempInput = '*' + articleNumber.trim() + '*';
        string str= 'Online';
        String str1 = 'en_US';
        String queryString = '';
        String queryStringWithDraftStatus = '';
        set<string> articleNumberset = new set<String>();
        for(caseArticle ca :[select id,knowledgearticle.articlenumber from casearticle where caseId =: caseId]){
            articleNumberset .add(ca.knowledgearticle.articlenumber);
        }
        List<How_to__kav> returnList = new List<How_to__kav>();
        List<How_to__kav> returnList1 = new List<How_to__kav>();
        List<How_to__kav> returnList2 = new List<How_to__kav>();
        if(test.isRunningTest()){
            queryString= 'FIND\'' + String.escapeSingleQuotes(tempInput) + '\' IN ALL FIELDS RETURNING How_To__kav (id,ArticleNumber,KnowledgeArticleId,title,URLName,LastModifiedDate,CreatedBy.Name,publishStatus,CreatedDate,Summary WHERE ArticleNumber NOT IN : articleNumberset  AND PublishStatus = \'' + String.escapeSingleQuotes(str) + '\' AND Language = \'en_US\')';
        }
        else{
            queryString= 'FIND\'' + String.escapeSingleQuotes(tempInput) + '\' IN ALL FIELDS RETURNING How_To__kav (id,ArticleNumber,KnowledgeArticleId,title,URLName,LastModifiedDate,CreatedBy.Name,publishStatus,CreatedDate,Summary WHERE ArticleNumber NOT IN : articleNumberset AND PublishStatus = \'' + String.escapeSingleQuotes(str) + '\')';
        }
        List<List <sObject>> searchList = search.query(queryString);
        returnList1 = searchList[0];
        returnList.addAll(returnList1);
        /*if(test.isRunningTest()){
queryStringWithDraftStatus= 'FIND\'' + tempInput + '\' IN ALL FIELDS RETURNING How_To__kav (id,ArticleNumber,KnowledgeArticleId,title,URLName,LastModifiedDate,CreatedBy.Name,publishStatus,CreatedDate,Summary WHERE ArticleNumber NOT IN : articleNumberset AND PublishStatus = \'' + str + '\' AND Language = \'en_US\')';
}
else{
queryStringWithDraftStatus= 'FIND\'' + tempInput + '\' IN ALL FIELDS RETURNING How_To__kav (id,ArticleNumber,KnowledgeArticleId,title,URLName,LastModifiedDate,CreatedBy.Name,publishStatus,CreatedDate,Summary WHERE ArticleNumber NOT IN : articleNumberset AND PublishStatus = \'' + str + '\')';
}
system.debug('queryStringWithDraftStatus--->'+queryStringWithDraftStatus);
List<List <sObject>> searchListForDraftStatus = search.query(queryStringWithDraftStatus);
returnList2 = searchListForDraftStatus[0];
returnList.addAll(returnList2);*/
        /*if(searchList != null && !searchList.isEmpty()) articleListWithDraftStatus.addAll(searchList);
if(searchListForDraftStatus != null && !searchListForDraftStatus.isEmpty()) articleListWithDraftStatus.addAll(searchListForDraftStatus);
system.debug('searchListForDraftStatus-->'+searchListForDraftStatus);
system.debug('articleListWithDraftStatus-->'+articleListWithDraftStatus);*/
        return returnList;
        
        //return [FIND]
        //return [select id,ArticleNumber,KnowledgeArticleId,title,URLName,LastModifiedDate,CreatedBy.Name,publishStatus,CreatedDate,Summary from How_To__kav where (ArticleNumber like : tempInput OR title LIKE : tempInput) AND  ArticleNumber NOT IN : articleNumberset ORDER BY LastModifiedDate DESC];
        
        
    }
    @AuraEnabled
    public static List<How_To__kav> getArticlesApex(string caseId){       
        
        List<How_To__kav> articleList = new List<How_To__kav>();
        set<Id> articleIds = new set<Id>();
        for(CaseArticle ca : [select id,knowledgearticleId from casearticle where caseId=:caseId]){
            articleIds.add(ca.knowledgearticleId);        
        }
        if(articleIds!=null && !articleIds .isEmpty()){
            List<How_To__kav> publishedArticles = [select id,ArticleNumber,KnowledgeArticleId,title,URLName,LastModifiedDate,CreatedBy.Name,publishStatus,ValidationStatus,CreatedDate,Summary from How_To__kav where (KnowledgeArticleId IN : articleIds or ID IN : articleIds) AND publishStatus = 'online'];
            //List<How_To__kav> draftArticles = [select id,ArticleNumber,KnowledgeArticleId,title,URLName,LastModifiedDate,CreatedBy.Name,publishStatus,ValidationStatus,CreatedDate,Summary from How_To__kav where (KnowledgeArticleId IN : articleIds or ID IN : articleIds) AND publishStatus = 'draft'];
            if(publishedArticles != NULL) articleList.addAll(publishedArticles);
            //if(draftArticles != NULL ) articleList.addAll(draftArticles);
            return articleList;        
        }else{
            return articleList;
        }
        
    }
    
    @AuraEnabled
    public static String attachToCase1(List<string> articleIds, string caseId){
        try{
            List<CaseArticle> caseArticles = new List<CaseArticle>();
            for(String kbId : articleIds){
                caseArticles.add(new CaseArticle(caseId = caseid,KnowledgeArticleId = kbId));
            }
            insert caseArticles;
            
            Case caseRecord = [SELECT Id, KCS_Article_Candidate__c, Supportability_Improvement_Requested__c	
                               FROM Case	
                               WHERE Id =: caseId];	
            if(caseRecord.KCS_Article_Candidate__c != 'Article Linked'	
               || caseRecord.Supportability_Improvement_Requested__c != 'No - Supportability improvement not requested'){	
                   caseRecord.KCS_Article_Candidate__c = 'Article Linked';	
                   caseRecord.Supportability_Improvement_Requested__c = 'No - Supportability improvement not requested';	
                   update caseRecord;	
               }
            
            return 'success';
        }catch(exception e){
            system.debug('####'+ e);
            return 'error';
        }
        
    }
    @AuraEnabled
    public static String removeFromCase1(string articleId, string caseId){
        
        try{
            delete [Select Id from CaseArticle where caseId =:caseId and knowledgeArticleId=:articleId];
            //Dummy case update to initiate Case update execution to update article count and KCS fields
            Case caseRecord = new Case(Id = caseId);
            update caseRecord;
            return 'success';
        }catch(exception e){
            system.debug('####'+ e);
            return 'error';
        }
        
    }
    
}