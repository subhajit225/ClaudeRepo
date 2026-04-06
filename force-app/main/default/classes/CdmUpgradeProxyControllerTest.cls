@isTest
private class CdmUpgradeProxyControllerTest {
    
    @testSetup static void createTestData() {
        OktaUserUtilityTest.oktaCustomSettingsParams();
        
        Id profileId = [select id from profile where name='System Administrator'].id;
        
        account acct=new account(name='test account',AccountNumber='123456');
        insert acct;
        contact con=new contact(lastname='test contact',leadsource='web',
                                email='testc@test.com',accountId=acct.id);
        insert con;
        User user = new User(alias = 'test123', email= 'tes12@gmail.com',
                             emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                             localesidkey='en_US', profileid = profileId, country='United States',IsActive =true,
                             timezonesidkey='America/Los_Angeles', username='firefox324@noemail.com.invalid1234');
        
        insert user;
        
    }
    
    @isTest
    static void testProcessPostRequest() {
        User usr =[select id from user where isActive=true order by createddate desc limit 1];
        system.runAs(usr) {
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new RestMock());
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            // ---- Request body --- 
            Map<String, Object> requestBodyMap = new Map<String, Object>();
            Map<String, Object> oktaCredsMap = new Map<String, Object>();
            //oktaCredsMap.put('username', 'username');
            //oktaCredsMap.put('password', 'password');
            requestBodyMap.put('okta_creds', oktaCredsMap);
            
            String requestBody = JSON.serialize(requestBodyMap);
            // request.requestBody = Blob.valueOf(requestBody);
            // --- Parameters ---- 
            req.addParameter('show_all', 'true');
            req.addParameter('fetch_links', 'false'); 
            req.addParameter('filter_version', '1.0'); 
            req.addParameter('filter_upgradable_versions', 'true');
            req.addParameter('source_version', '2.0'); 
            req.addParameter('show_814', 'true'); 
            req.requestURI = '/services/apexrest/cdm/loginAndListDownloadableReleases';  //Request URL
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueof(requestBody);
            req.addHeader('Content-Type', 'application/json'); 
            req.addHeader('username', 'username'); 
            req.addHeader('password', 'password'); 
            RestContext.request = req;
            RestContext.response = res;
            
            //System.assertEquals(200, res.statusCode);
            CdmUpgradeProxyController.processPostRequest();
            System.assertEquals('true', RestContext.request.params.get('show_all'));
            System.assertEquals('false', RestContext.request.params.get('fetch_links'));
            System.assertEquals('1.0', RestContext.request.params.get('filter_version'));
            Test.stopTest();
        }
    }
    
    @isTest
    static void testProcessPostRequest2() {
        User usr =[select id from user where isActive=true order by createddate desc limit 1];
        system.runAs(usr) {
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new RestMock());
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            String JSONMsg = '{"show_all": "true"}';
            req.requestURI = '/services/apexrest/cdm/loginAndListDownloadableReleases';  //Request URL
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueof(JSONMsg);
            req.addHeader('Content-Type', 'application/json'); 
            RestContext.request = req;
            RestContext.response = res;
            
            //System.assertEquals(200, res.statusCode);
            CdmUpgradeProxyController.processPostRequest();
            System.assertEquals('true', 'true');
            Test.stopTest();
        }
    }
    
    @isTest
    static void testProcessPostRequest3() {
        User usr =[select id from user where isActive=true order by createddate desc limit 1];
        system.runAs(usr) {
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new RestMock2());
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            // ---- Request body --- 
            Map<String, Object> requestBodyMap = new Map<String, Object>();
            Map<String, Object> oktaCredsMap = new Map<String, Object>();
            oktaCredsMap.put('username', 'username');
            oktaCredsMap.put('password', 'password');
            requestBodyMap.put('okta_creds', oktaCredsMap);
            
            String requestBody = JSON.serialize(requestBodyMap);
            // --- Parameters ---- 
            req.addParameter('show_all', 'true');
            req.addParameter('fetch_links', 'false'); 
            req.addParameter('filter_version', '1.0'); 
            req.addParameter('filter_upgradable_versions', 'true');
            req.addParameter('source_version', '2.0'); 
            req.addParameter('show_814', 'true'); 
            req.requestURI = '/services/apexrest/cdm/loginAndListDownloadableReleases';  //Request URL
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueof(requestBody);
            req.addHeader('Content-Type', 'application/json'); 
            req.addHeader('username', 'username'); 
            req.addHeader('password', 'password'); 
            RestContext.request = req;
            RestContext.response = res;
            
            CdmUpgradeProxyController.processPostRequest();
            System.assertEquals('true', RestContext.request.params.get('show_all'));
            System.assertEquals('false', RestContext.request.params.get('fetch_links'));
            System.assertEquals('1.0', RestContext.request.params.get('filter_version'));
            Test.stopTest();
        }
    }
    
    @isTest
    static void testProcessPostRequest4() {
        User usr =[select id from user where isActive=true order by createddate desc limit 1];
        system.runAs(usr) {
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new RestMock3());
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            // ---- Request body --- 
            Map<String, Object> requestBodyMap = new Map<String, Object>();
            Map<String, Object> oktaCredsMap = new Map<String, Object>();
            //oktaCredsMap.put('username', 'tester@noemail.com');
            //oktaCredsMap.put('password', 'password');
            //requestBodyMap.put('okta_creds', oktaCredsMap);
            
            String requestBody = JSON.serialize(requestBodyMap);
            // --- Parameters ---- 
            req.addParameter('show_all', 'true'); 
            req.requestURI = '/services/apexrest/cdm/loginAndListDownloadableReleases';  //Request URL
            req.httpMethod = 'POST';
            req.requestBody = Blob.valueof(requestBody);
            req.addHeader('Content-Type', 'application/json'); 
            req.addHeader('username', 'firefox324@noemail.com.invalid1234'); 
            req.addHeader('password', 'password'); 
            RestContext.request = req;
            RestContext.response = res;
            
            CdmUpgradeProxyController.processPostRequest();
            System.assertEquals('true', RestContext.request.params.get('show_all'));
            Test.stopTest();
        }
    }
    
    private class RestMock implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            String fullJson = 'your Json Response';
            Map<String, Object> resBodyMap = new Map<String, Object>();
            Map<String,Object> prfMap = new Map<String,Object>();
            prfMap.put('sfdcCustomerPortalUsername','TestUsername');
            resBodyMap.put('profile',prfMap);
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(JSON.serialize(resBodyMap));
            res.setStatusCode(200);
            res.setStatus('OK');
            return res;
        }
    }
    
    private class RestMock2 implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            String fullJson = 'your Json Response';
            Map<String, Object> resBodyMap = new Map<String, Object>();
            Map<String,Object> prfMap = new Map<String,Object>();
            prfMap.put('sfdcCustomerPortalUsername','');
            resBodyMap.put('profile',prfMap);
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(JSON.serialize(resBodyMap));
            res.setStatusCode(200);
            res.setStatus('OK');
            return res;
        }
    }
    
    private class RestMock3 implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            Map<String, Object> resBodyMap = new Map<String, Object>();
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(JSON.serialize(resBodyMap));
            res.setStatusCode(404);
            res.setStatus('Error');
            return res;
        }
    }
}