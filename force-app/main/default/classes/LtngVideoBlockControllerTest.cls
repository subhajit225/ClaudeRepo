@isTest
public class LtngVideoBlockControllerTest {
    static testmethod void LtngVideoBlockControllerTest(){
    	How_To__kav newKav = new How_To__kav(UrlName='URL',Title='Title', Language='en_US' );
        insert newKav;
        how_to__kav articleToPublish = [select id,KnowledgeArticleId,ArticleNumber from how_to__kav where Id =: newKav.Id];
        KbManagement.PublishingService.publishArticle(articleToPublish.KnowledgeArticleId, true);
        How_To__DataCategorySelection DCS = new How_To__DataCategorySelection();
        DCS.DataCategoryGroupName = 'Article';
        DCS.DataCategoryName = 'Videos';
        DCS.ParentId = articleToPublish.Id;
        insert DCS;
        How_To__VoteStat vt = new How_To__VoteStat();
        articleToPublish = [select id,KnowledgeArticleId,PublishStatus from how_to__kav where Id =: newKav.Id];
        LtngVideoBlockController.getTopVideos();
    	
    }
    
    static testmethod void LtngVideoBlockControllerTest2(){
        LtngVideoBlockController.getTopVideos();
    }

}