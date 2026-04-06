@isTest
public class ScheduleKbSubscribeBatchTest {

    public static testMethod void testKnowledgeSubscriptionBatch(){
        How_To__kav newArticle = new How_To__kav(Title='test',summary='xyz',urlname='xyz',isVisibleInPkb = true);
        insert newArticle;
        How_To__DataCategorySelection newArtDC = new How_To__DataCategorySelection();
        newArtDC.DataCategoryGroupName = 'Article';
        newArtDC.DataCategoryName = 'API';
        newArtDC.ParentId = newArticle.id;
        insert newArtDC;
        How_To__kav obj1 = [SELECT Id,Title,KnowledgeArticleId FROM How_To__kav WHERE id =: newArticle.Id];
        KbManagement.PublishingService.publishArticle(obj1.KnowledgeArticleId, true);
        List<Customer_Subscription__c> csList = new List<Customer_Subscription__c>();
        csList.add(new Customer_Subscription__c(type__c='Category' ,Category_Name__c ='API', User__c = UserInfo.getUserId()));
        csList.add(new Customer_Subscription__c(type__c='Article' ,Category_Name__c ='API' , User__c = UserInfo.getUserId() , KB_ID__c = obj1.KnowledgeArticleId ));
        insert csList;
        Test.StartTest();
        scheduleKbSubscribeBatch sh1 = new scheduleKbSubscribeBatch();      
        String sch = '0 0 23 * * ?';
        system.schedule('Test check', sch, sh1);
        Test.stopTest();
    }
}