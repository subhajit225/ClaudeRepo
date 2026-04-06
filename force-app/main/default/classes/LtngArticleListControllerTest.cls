@isTest
public class LtngArticleListControllerTest {
    static testmethod void LtngArticleListControllerTest(){
        /* KAV*/
        How_To__kav kav = new How_To__kav(UrlName='URL',Title='Title');
        insert kav;
        How_To__DataCategorySelection dcs = new How_To__DataCategorySelection(ParentId = kav.Id,DataCategoryGroupName='Article',DataCategoryName='Documentation');
        insert dcs;
        how_to__kav articleToPublish = [select id,KnowledgeArticleId from how_to__kav where Id =: kav.Id];
        KbManagement.PublishingService.publishArticle(articleToPublish.KnowledgeArticleId, true);
        LtngArticleListController.getSubscription(kav.Id);    
        LtngArticleListController.deleteSubscription(kav.Id,true);    
        LtngArticleListController.deleteSubscription(kav.Id,false);    
        /*Customer Sub**/
        Customer_Subscription__c custSub = new Customer_Subscription__c(Article_Number__c ='TestAccount',Title__c='Title',user__c = UserInfo.getUserId(),Category_Label__c='label',KB_ID__c='kA01W0000000Y7nSAE',Type__c = 'Article');
        
        
        LtngArticleListController.checkIfSubscribed('Test');  
        LtngArticleListController.checkIfSubscribed('All');  
        LtngArticleListController.editSubscription('All',true);
        LtngArticleListController.editSubscription('All',false);
        
        LtngArticleListController.editSubscription('Polaris',false);
        LtngArticleListController.createKbSubscription();    
        LtngArticleListController.getArticleList('1','1','Polaris');
        
    }
}