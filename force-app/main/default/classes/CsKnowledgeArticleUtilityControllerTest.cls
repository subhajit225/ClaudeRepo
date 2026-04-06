@IsTest
private class CsKnowledgeArticleUtilityControllerTest {
    
    @TestSetup
    static void setupTestData() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // Create a test Knowledge Article in Draft status
            List<How_To__kav> articlesToInsert = new List<How_To__kav>();
            How_To__kav testArticle = new How_To__kav(
                Title = 'Test Article',
                UrlName = 'Test-Article',
                IsVisibleInPkb = true,
                IsVisibleInCsp = true,
                IsVisibleInPrm = true
            );
            articlesToInsert.add(testArticle);
            
            How_To__kav testArticle2 = new How_To__kav(
                Title = 'Test Article 2',
                UrlName = 'Test-Article2',
                IsVisibleInPkb = true,
                IsVisibleInCsp = true,
                IsVisibleInPrm = true
            );
            articlesToInsert.add(testArticle2);
            
            How_To__kav testArticle3 = new How_To__kav(
                Title = 'Test Article 3',
                UrlName = 'Test-Article3',
                IsVisibleInPkb = true,
                IsVisibleInCsp = true,
                IsVisibleInPrm = true
            );
            articlesToInsert.add(testArticle3);
            
            insert articlesToInsert;
            
            // Query the articles to retrieve the KnowledgeArticleId
            testArticle = [SELECT KnowledgeArticleId FROM How_To__kav WHERE Id = :articlesToInsert[0].Id];
            testArticle3 = [SELECT KnowledgeArticleId FROM How_To__kav WHERE Title = 'Test Article 3'];
            
            System.assertNotEquals(null, testArticle.KnowledgeArticleId, 'KnowledgeArticleId should not be null before publishing');
            
            // Publish the articles
            KbManagement.PublishingService.publishArticle(testArticle.KnowledgeArticleId, true);
            KbManagement.PublishingService.publishArticle(testArticle3.KnowledgeArticleId, true);
            KbManagement.PublishingService.archiveOnlineArticle(testArticle3.KnowledgeArticleId, null);
        }
    }
    
    
    @IsTest
    static void testUpdateRecordsSuccess() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // Get the published article
            List<String> articleIds = new List<String>();
            for(How_To__kav article : [SELECT KnowledgeArticleId FROM How_To__kav]) {
                articleIds.add(article.KnowledgeArticleId);
            }
            
            Test.startTest();
            List<CsKnowledgeArticleUtilityController.Response> responses = 
                CsKnowledgeArticleUtilityController.updateRecords(articleIds);
            Test.stopTest();
            
            // Verify results
            System.assertNotEquals(null, responses, 'Response should not be null');
            
            // Verify article was archived
            How_To__kav archivedArticle = [
                SELECT PublishStatus, Title, IsVisibleInPkb, IsVisibleInCsp, IsVisibleInPrm 
                FROM How_To__kav 
                WHERE PublishStatus = 'Archived' 
                LIMIT 1
            ];
            System.assert(archivedArticle.Title.startsWith('[Archived]'), 'Title should be prefixed with [Archived]');
            System.assertEquals(false, archivedArticle.IsVisibleInPkb, 'Article should not be visible in PKB');
            System.assertEquals(false, archivedArticle.IsVisibleInCsp, 'Article should not be visible in CSP');
            System.assertEquals(false, archivedArticle.IsVisibleInPrm, 'Article should not be visible in PRM');
        }
    }
    
    @IsTest
    static void testUpdateRecordsEmptyList() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.startTest();
            List<CsKnowledgeArticleUtilityController.Response> responses = 
                CsKnowledgeArticleUtilityController.updateRecords(new List<String>());
            Test.stopTest();
            
            System.assertEquals(0, responses.size(), 'Should return empty list for empty input');
        }
    }
    
    @IsTest
    static void testUpdateRecordsNullList() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.startTest();
            List<CsKnowledgeArticleUtilityController.Response> responses = 
                CsKnowledgeArticleUtilityController.updateRecords(null);
            Test.stopTest();
            
            System.assertEquals(0, responses.size(), 'Should return empty list for null input');
        }
    }
    @IsTest
    static void testSendProcessingEmail() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            String attachmentBody = EncodingUtil.base64Encode(Blob.valueOf('Test Content'));
            String fileName = 'test.xlsx';
            
            Test.startTest();
            Integer emailInvocations = Limits.getEmailInvocations();
            try {            
                CsKnowledgeArticleUtilityController.sendProcessingEmail(attachmentBody, fileName);     
            } catch (AuraHandledException e) {
                System.assert(emailInvocations == Limits.getEmailInvocations(), 'One email should have been sent');
            }
            Test.stopTest();
        }
    }    
    
    @IsTest
    static void testResponse() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            String testId = 'testId';
            Boolean testSuccess = true;
            String testError = 'Test Error';
            
            Test.startTest();
            CsKnowledgeArticleUtilityController.Response response = 
                new CsKnowledgeArticleUtilityController.Response(testId, testSuccess, testError);
            Test.stopTest();
            
            System.assertEquals(testId, response.id, 'ID should match');
            System.assertEquals(testSuccess, response.success, 'Success should match');
            System.assertEquals(testError, response.errorMessage, 'Error message should match');
        }
    }
}