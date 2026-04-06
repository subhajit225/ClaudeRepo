@isTest
public class KnowledgeFeedbackControllerTest {
    public static  testMethod void testKB(){
        How_To__kav newKav = new How_To__kav(UrlName='URL',Title='Title', Language='en_US',Rank__c=1 );
        insert newKav;
        KnowledgeFeedbackController.saveFeedback(String.valueOf(newKav.Id),'test','Test');
        KnowledgeFeedbackController.getRelatedAttachment(newKav.Id);
   }
}