@isTest
public class ControllerCommunityHomeTest {
    static testmethod void ControllerCommunityHomeTest(){
        /* Article Publishh */
        How_To__kav newKav = new How_To__kav(UrlName='URL',Title='Title', Language='en_US',Rank__c=1 );
        insert newKav;
        how_to__kav articleToPublish = [select id,KnowledgeArticleId,ArticleNumber from how_to__kav where Id =: newKav.Id];
        KbManagement.PublishingService.publishArticle(articleToPublish.KnowledgeArticleId, true);
        articleToPublish = [select id,KnowledgeArticleId,PublishStatus from how_to__kav where Id =: newKav.Id];

        /*Article */
        
        How_To__DataCategorySelection DCS = new How_To__DataCategorySelection();
        DCS.DataCategoryGroupName = 'Article';
        DCS.DataCategoryName = 'Videos';
        DCS.ParentId = articleToPublish.Id;
        insert DCS;
        //How_To__VoteStat vt = new How_To__VoteStat();
        articleToPublish = [select id,KnowledgeArticleId,PublishStatus from how_to__kav where Id =: newKav.Id];
         
         
        
        ControllerCommunityHome.getNewArticles();
        //ControllerCommunityHome.getTopSolutions(2);
        Portal_News__c portalNews = new Portal_News__c(Name='test',Audience__c ='All',Alert__c=False,Publish_Date__c=system.today(),Expiration_Date__c=system.today().addDays(20));
        insert portalNews;
        
        Portal_News__c portalNewsInfo = [select id,Publish_Date__c,expiration_date__c from Portal_News__c where Id =: portalNews.Id];
        ControllerCommunityHome.getPortalDetailNews(portalNewsInfo.Id);
        ControllerCommunityHome.getPortalNews(portalNewsInfo.Id,'test');
        ControllerCommunityHome.getRankedSolutions();
        
        
    }
}