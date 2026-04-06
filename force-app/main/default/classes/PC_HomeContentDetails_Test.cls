/** Created By :Annappa
* Purpose : Test class of  PC_HomeContentDetails
**/
@isTest
private class PC_HomeContentDetails_Test {
    public static testmethod void testPopularDetails(){
        Test.startTest(); 
        List<ContentVersion> cv = ShGl_TestFactory.testMethod_Content(1);
        PC_HomeContentDetails.fetchContentDetails('Popular');
        PC_HomeContentDetails.PreviewContentDetails(cv[0].Id);
        Test.stopTest(); 
    }
    public static testmethod void testWhatsNewDetails(){
        Test.startTest();
        List<ContentVersion> cv = ShGl_TestFactory.testMethod_Content(1);
        PC_HomeContentDetails.fetchContentDetails('Whats New');
        Test.stopTest();
    }
    public static testmethod void testMyPins(){
        Test.startTest();
        List<ContentVersion> cv = ShGl_TestFactory.testMethod_Content(1);
        PC_HomeContentDetails.fetchContentDetails('Whats New');
        ContentVersion contentVersionSelect = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :cv[0].Id LIMIT 1];
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        ShGl_TestFactory.testMethod_EntitySubscription(documents[0].ID,UserInfo.getUserId());
        PC_HomeContentDetails.fetchContentDetails('My Pins');
        Test.stopTest();
    }
}