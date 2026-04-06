@isTest
public class KnowledgeDetailControllerTest {
    static testmethod void test1(){
        How_To__kav newKav = new How_To__kav(UrlName='URL',Title='Title', Language='en_US',Rank__c=1 );
        newKav.Resolution__c = 'src="';
        newKav.Summary__c = 'src="';
        newKav.Version__c = 'src="';
        newKav.Resolution__c = 'src="';
        newKav.Cause__c = 'src="';
        newKav.Environment__c = 'src="';
        insert newKav;
        KnowledgeNavigateController.knowledgeId(newKav.Id);
        How_To__kav obj1 = [SELECT Id,Title,KnowledgeArticleId FROM How_To__kav WHERE id =: newKav.Id];
        KbManagement.PublishingService.publishArticle(obj1.KnowledgeArticleId, true);
        List<How_To__kav> newKav1 = [select id,KnowledgeArticleId from How_To__kav LIMIT 1];
        KnowledgeDetailController uc = new KnowledgeDetailController();
        uc.kbRecordId = newKav.Id;
        uc.getknowRecords();
    }
}