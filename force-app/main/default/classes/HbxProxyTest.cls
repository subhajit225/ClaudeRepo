@istest
public class HbxProxyTest {
    
     @testSetup static void createTestData() {
        Id profileId = [select id from profile where name='Rubrik Community Super User'].id;
       
       account acct=new account(name='test account',AccountNumber='123456');
       insert acct;
       contact con=new contact(lastname='test contact',leadsource='web',
                                  email='testc@test.com',accountId=acct.id);
       insert con;
                  
        User user = new User(alias = 'test123', email= 'tes12@gmail.com',
                emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                localesidkey='en_US', profileid = profileId, country='United States',IsActive =true,
                ContactId = con.Id,
                timezonesidkey='America/Los_Angeles', username='tester@noemail.com');
       
        insert user;
     
     }
    
    @isTest
    static void  processPostRequestTest() {

       User usr =[select id from user where ContactId!=null and isActive=true order by createddate desc limit 1];
        system.runAs(usr) {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new RestMock());
          RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        String JSONMsg = '{"testData:allset"}';
        req.requestURI = '/services/apexrest/hbxproxy';  //Request URL
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(JSONMsg);
        req.addHeader('Content-Type', 'application/json'); 
        RestContext.request = req;
        RestContext.response = res;
        
        system.debug('testcp');
        HbxProxy.processPostRequest();
        Test.stopTest();
        }
     } 


    private class RestMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            String fullJson = 'your Json Response';

            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullJson);
            res.setStatusCode(200);
            return res;
        }
    }
   
}