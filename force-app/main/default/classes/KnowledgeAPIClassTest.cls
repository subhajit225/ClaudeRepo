@isTest
public class KnowledgeAPIClassTest {
    @testSetup static void setup(){
        How_To__kav article = new How_To__kav(
                    Title = 'Test',
                    IsVisibleInPkb = true,
                    IsVisibleInCsp = true,
                    IsVisibleInPrm = true,
                    Error_Code__c = 'ART-11',
                    UrlName= 'ART-11',
                    Cause__c = 'Test',
                    Summary__c = 'Test Summary',
                    Resolution__c = 'Test'
                );
        insert article;
    }
    
    @isTest
    public static void testGetMethod(){
        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/knowledgeapi';
        req.addParameter('url_code', 'ART-11');

        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;

        KnowledgeAPIClass.getArticle();
        Test.stopTest();
    }
    
    @isTest
    public static void testPostMethod(){
        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/knowledgeapi';

        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
		List<KnowledgeAPIClass.KnowledgeError> errors = new List<KnowledgeAPIClass.KnowledgeError>();
		KnowledgeAPIClass.KnowledgeError err = new KnowledgeAPIClass.KnowledgeError(); 
        err.name = 'Test';
        err.Category = 'Security';
        err.Cause = 'Rubrik test';
        err.Resolution = 'Test';
        err.Summary = 'Test Summary';
        err.error_code = 'Test-11';
        errors.add(err);
        KnowledgeAPIClass.KnowledgeError err1 = new KnowledgeAPIClass.KnowledgeError(); 
        err1.name = 'Test';
        err1.Category = 'Security';
        err1.Cause = 'Rubrik test';
        err1.Resolution = 'Test';
        err1.Summary = 'Test Summary';
        err1.error_code = 'ART-11';
        err1.status = 'Online';
        errors.add(err1);
        KnowledgeAPIClass.createRecord(errors);
        Test.stopTest();
    }
    
    @isTest
    public static void testPutMethod(){
        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/knowledgeapi';

        req.httpMethod = 'PUT';
        RestContext.request = req;
        RestContext.response = res;
		List<KnowledgeAPIClass.KnowledgeError> errors = new List<KnowledgeAPIClass.KnowledgeError>();
        KnowledgeAPIClass.KnowledgeError err1 = new KnowledgeAPIClass.KnowledgeError(); 
        err1.name = 'Test';
        err1.Category = 'Security';
        err1.Cause = 'Rubrik test';
        err1.Resolution = 'Test';
        err1.Summary = 'Test Summary';
        err1.error_code = 'ART-11';
        err1.status = 'Online';
        errors.add(err1);
        KnowledgeAPIClass.draftRecord(errors);
        Test.stopTest();
    }
}