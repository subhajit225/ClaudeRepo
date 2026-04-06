public class KnowledgeNavigateController {

    @AuraEnabled
    public static Id knowledgeId(String kbId){
        how_to__kav kb = [SELECT Id, KnowledgeArticleId,isLatestVersion FROM How_To__kav where id =: kbId limit 1];
        if(kb.IsLatestVersion){
            return kbId;
        }
        return kb.KnowledgeArticleId;
    }
}