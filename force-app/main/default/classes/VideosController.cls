public class VideosController{
    
    public VideosController(){}
    
    public List<How_To__kav> getTopVideos(){
       Map<id,How_To__kav> kavMap = new Map<Id,How_To__kav>();
       List<How_To__kav> kavList = [SELECT Id, CreatedDate, LastModifiedDate, ArticleNumber, KnowledgeArticleId, Summary, Summary__c,Video_URL__c,Title, Rank__c, LastPublishedDate, UrlName,createdby.name 
                               FROM How_To__kav where PublishStatus='Online' AND Language='en_US' WITH DATA CATEGORY ARTICLE__c BELOW Videos__c 
                                ORDER BY RANK__c, LastPublishedDate
                               DESC nulls last];
       for(How_To__kav each : kavList){
           kavMap.put(each.KnowledgeArticleId,each);
       }
       List<KnowledgeArticleVoteStat> kavPList = [SELECT Id, ParentId, NormalizedScore, Parent.ArticleNumber
                                FROM KnowledgeArticleVoteStat
                                WHERE NormalizedScore>0 AND parentid in :kavMap.keySet() 
                                order BY NormalizedScore,parent.LastPublishedDate DESC
                               LIMIT 6];
       Map<id,How_To__kav> topVideos = new Map<id,How_To__kav>();
       if(kavPList != null && !kavPList.isEmpty()){
           for(KnowledgeArticleVoteStat each : kavPList){
               if(kavMap != null && !kavMap.isEmpty() && kavMap.containsKey(each.parentId)){
                   topVideos.put(each.parentid,kavMap.get(each.parentId));
               }
           }
       }else{
           for(integer i=0;i<kavList.size();i++){
               if(i<=5){
                   topVideos.put(kavList[i].knowledgeArticleid,kavList[i]);
               }else{break;}
           }
       }
       
       if(topVideos != null && !topVideos.isEmpty() && topVideos.size() < 6){
           for(How_To__kav each : kavList){
               if(!topVideos.ContainsKey(each.knowledgeArticleid) && topVideos.size() < 6){
                   topVideos.put(each.knowledgeArticleid,each);
               }
           }
       }
       return topVideos.values();
    }
}