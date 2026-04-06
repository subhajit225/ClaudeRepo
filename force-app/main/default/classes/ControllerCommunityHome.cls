public without sharing class ControllerCommunityHome {
    
    @AuraEnabled public integer rankedSize {get; set;}
    public static Set<Id> KAV1 = new set<Id>();
    public static Set<Id> KAV2 = new set<Id>();
    @AuraEnabled public static string anntype {get; set;}
    
    // Forced Articles
    @AuraEnabled
    public static List<toparticleWrapper> getRankedSolutions() {
        List<How_To__kav> kavList1 = [select Id, CreatedDate, ArticleTotalViewCount,LastModifiedDate, ArticleNumber, KnowledgeArticleId, Summary, Summary__c, Title, Rank__c, FirstPublishedDate, LastPublishedDate, UrlName,createdby.name FROM How_To__kav where PublishStatus='Online' and Language='en_US' and Rank__c!=null ORDER BY LastPublishedDate desc limit 3];
        List<How_To__kav> nonRankedKavList = [select Id,ArticleTotalViewCount, CreatedDate, LastModifiedDate, ArticleNumber, KnowledgeArticleId, Summary, Summary__c, Title, Rank__c, FirstPublishedDate, LastPublishedDate, UrlName,createdby.name FROM How_To__kav where PublishStatus='Online' and Language='en_US' and RANK__c=NULL ORDER BY LastPublishedDate desc limit 3];
        if(kavList1.size()<3 && !kavList1.isEmpty() && !nonRankedKavList.isEmpty()){            
            
            for(integer i = 0; i < =3-kavList1.size();i++){
                if(i<nonRankedKavList.size())
                    kavList1.add(nonRankedKavList.get(i));
           }
        }else{
            kavList1.addAll(nonRankedKavList);
        }
        
        List<toparticleWrapper> articleList = new List<toparticleWrapper>();
        system.debug('##$$$'+kavList1);
        for(How_To__kav k : kavList1){
            system.debug('##$$$'+k);    
            toparticleWrapper ac = new toparticleWrapper();
            ac.kV = k;
            ac.viewCount = k.ArticleTotalViewCount;
            articleList.add(ac);
        }
        system.debug('@@###'+articleList);
        
        return articleList ;

    }
    // Top Articles
    /*public static List<How_To__kav> getTopSolutions(Integer rankedSize) {
        
        integer qlimit = 0;
        qlimit = Test.isRunningTest() ? 1 : 3 - rankedSize;
        
        //Find all the articles that have a Vote Score
        List<KnowledgeArticleVoteStat> kavPList2 = [
            select id, ParentId, NormalizedScore, Parent.ArticleNumber
            FROM KnowledgeArticleVoteStat
            where NormalizedScore>0
            order by NormalizedScore desc
            limit 100];
        
        for(KnowledgeArticleVoteStat kv : kavPList2) {
            if(kv.NormalizedScore>0)
            {
                
                KAV1.add(kv.ParentId);
            }
            system.debug('### KAV1 '+ KAV1);
        }
        
        //get all of the Ranked Articles
        List<How_To__kav> kavList = [select Id, CreatedDate,FirstPublishedDate, LastModifiedDate, ArticleNumber, KnowledgeArticleId, Summary, Title, Rank__c, LastPublishedDate, UrlName,createdby.name 
                                      FROM How_To__kav where PublishStatus='Online' and Language='en_US' and Rank__c!=null
                                      ORDER BY RANK__c
                                      asc nulls last limit 100];
        
        system.debug('### kavList in getTopSolutions '+ kavList.size());
        
        //get the rest of the articles that are not ranked
        List<How_To__kav> kav2List = [select Id, CreatedDate,FirstPublishedDate,ArticleNumber, LastModifiedDate, KnowledgeArticleId, Summary, Title, Rank__c, LastPublishedDate, UrlName,createdby.name 
                                      FROM How_To__kav
                                      where PublishStatus='Online' and Language='en_US'
                                      and Id NOT in: kavList and KnowledgeArticleId In: KAV1
                                      limit :qlimit];
        
        system.debug('### kav2List in getTopSolutions '+ kav2List.size());
        
        for(How_To__kav kv1 : kav2List) {
            KAV2.add(kv1.Id);
        }
        system.debug('### KAV2 '+ KAV2);
        
        if (kav2List.isEmpty()) {
           return Test.isRunningTest() ? new List<How_To__kav>() :  null;
        }
        
        system.debug('### kav2List in getTopSolutions2 '+ kav2List.size());
        return kav2List;
    }*/
    // Portal News
    @AuraEnabled
    public static List<Portal_News__c> getPortalNews(String recordId, String Name) {
        system.debug('recordIdName-------------- >>>'+Name);
        system.debug('recordIdName-------------- >>>'+Name);
        anntype = Util.UserType;
        system.debug('anntype >>>'+anntype);
        
        String qstring = 'SELECT Id, Alert__c, Audience__c, Content__c, CreatedById, CreatedBy.Name, CreatedDate, LastModifiedDate, Expiration_Date__c, Created__c, Last_Modified__c, ';
        qString +=' Name, OwnerId, Publish_Date__c, SystemModStamp, Summary__c';
        if(anntype=='customer' || test.isRunningTest()) qString += ' FROM Portal_News__c WHERE (Audience__c = \'All\' OR Audience__c = \'Customer\')';
        if(anntype=='partner') qString += ' FROM Portal_News__c WHERE (Audience__c = \'All\' OR Audience__c = \'Partner\')';
        if(anntype == 'Trial') qString += ' FROM Portal_News__c WHERE Audience__c = \'Edge Trial\'';
        if(anntype =='internal') qString += ' FROM Portal_News__c WHERE (Audience__c = \'All\' OR Audience__c = \'Customer\') ';
        
        
        qString += ' AND Publish_Date__c <= TODAY AND (Expiration_Date__c = null OR Expiration_Date__c >= TODAY)';
        if (Name != 'Announcements'){
            qstring += ' AND Type__c =\'' + Name + '\'';
        } else {
            qstring += 'AND Type__c !=\'Getting Started\'';
        }
        
        qString += ' AND Recordtype.Name =\'Announcements\''; 
        qString += ' ORDER BY Publish_Date__c DESC LIMIT ' + Label.Announcements_Limit;
        
        List<Portal_News__c> newsList = database.query(qString);

        /*[SELECT Alert__c,Audience__c,Content__c,CreatedById,CreatedDate,Expiration_Date__c,Id,
        Name,OwnerId,Publish_Date__c,SystemModstamp
        ,
        Summary__c
        FROM Portal_News__c where (Audience__c = 'All' or Audience__c = 'Customer')
        and Publish_Date__c<=TODAY and (Expiration_Date__c=null OR Expiration_Date__c>=TODAY)
        order by Publish_Date__c desc limit 5];*/
        if (newsList.isEmpty()) {
            return null;
        }
        return newsList;
    }
    
    @AuraEnabled
    public static Portal_News__c getPortalDetailNews(String recordId) {
        
        anntype = Util.UserType;
        system.debug('anntype >>>'+anntype);
        
        String qstring1 = 'SELECT Id, Alert__c, Audience__c, Content__c, CreatedById, CreatedBy.Name, CreatedDate, LastModifiedDate, Expiration_Date__c, Created__c, Last_Modified__c, ';
        qstring1 += ' Name, OwnerId, Publish_Date__c, SystemModstamp, Summary__c, RecordType.Name';
        if(anntype=='customer' || test.isRunningTest() ) qstring1 += ' FROM Portal_News__c WHERE (Audience__c = \'All\' OR Audience__c = \'Customer\')';
        if(anntype=='partner') qstring1 +=' FROM Portal_News__c WHERE (Audience__c = \'All\' OR Audience__c = \'Partner\')';
        if(anntype == 'Trial') qstring1 +=' FROM Portal_News__c WHERE Audience__c = \'Edge Trial\'';
        if(anntype =='internal') qstring1 +=' FROM Portal_News__c WHERE (Audience__c = \'All\' OR Audience__c = \'Customer\') ';
        
        qstring1 += ' AND Id = :recordId AND Publish_Date__c <= TODAY AND (Expiration_Date__c = null OR Expiration_Date__c >= TODAY) ORDER BY Publish_Date__c DESC LIMIT 1';
        Portal_News__c test = Database.query(qstring1);
        system.debug('test------------- >>>'+test);
        return test;
    }
    // New Articles
    @AuraEnabled  
    public static List<articleWrapper> getNewArticles() {
        List<articleWrapper> articleList = new List<articleWrapper>();
        List<How_To__kav> kavList = [select Id, CreatedDate, PublishStatus,FirstPublishedDate, LastModifiedDate, ArticleNumber, KnowledgeArticleID, Summary, Summary__c, Title, LastPublishedDate, UrlName,createdby.name 
                                                 FROM How_To__kav where PublishStatus='Online' and Language='en_US' ORDER BY LastPublishedDate
                                                 desc limit 3];
        if (kavList.isEmpty()) {
            return null;
        }
        Map<id,How_To__kav> kbMap = new Map<id,How_To__kav>();
        for(How_To__kav k : kavList){
            kbMap.put(k.KnowledgeArticleID,k);
        }
        for(How_To__ViewStat views : [SELECT Id,parentId, ViewCount FROM How_To__ViewStat where ParentId IN: kbMap.keySet() and channel = 'AllChannels']){
            articleWrapper ac = new articleWrapper();
            ac.kV = kbMap.get(views.parentId);
            ac.viewCount = views.ViewCount;
            articleList.add(ac);
        }
        return articleList ;
    }
    
    public class articleWrapper{
        @AuraEnabled public How_To__kav kV;
        @AuraEnabled public Integer viewCount;
    }
     public class toparticleWrapper{
        @AuraEnabled public How_To__kav kV;
        @AuraEnabled public Integer viewCount;
    }
}