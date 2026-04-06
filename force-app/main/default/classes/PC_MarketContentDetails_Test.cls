@isTest
private class PC_MarketContentDetails_Test {
    public static testmethod void testfetchContentDetails(){
        Test.startTest();
        List<ContentVersion> cv = ShGl_TestFactory.testMethod_Content(1);
        PC_MarketContentDetails.fetchContentDetails();
        Test.stopTest();
    }
    public static testmethod void testPreviewContentDetails(){
        Test.startTest();
        List<ContentVersion> cv = ShGl_TestFactory.testMethod_Content(1);
        PC_MarketContentDetails.PreviewContentDetails(cv[0].id);
        Test.stopTest();
    }
}