trigger CreateCaseArticle on How_To__kav (after insert,after update) {
    if(trigger.isInsert){
        for(How_To__kav kcs : trigger.new)
        {
            If(kcs.Status__c == 'Draft' && kcs.Case__c != null)
            {
                CaseArticle ca = new CaseArticle();
                ca.CaseId = kcs.Case__c;
                ca.KnowledgeArticleId = kcs.KnowledgeArticleId;
                insert ca;
            }
        }
    }
    if(trigger.isUpdate){
        CreateCaseArticleHandler.afterUpdate(trigger.newMap);
    }
}