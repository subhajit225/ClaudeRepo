@isTest
private class PC_HelpLinkController_Test {
    public static testmethod void testController(){
        Test.startTest();
        List<ContentVersion> cv = ShGl_TestFactory.testMethod_Content(1);
        ContentVersion contentVersion_2 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :cv[0].Id LIMIT 1];
        PC_HelpLinkController.getContentversionId(contentVersion_2.ContentDocumentId);
        Test.stopTest();
    }
}