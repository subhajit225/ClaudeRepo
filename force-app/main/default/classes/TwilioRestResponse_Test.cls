/********************************************************************************************************
* Name              : TwilioRestResponse_Test
* Purpose           : TwilioRestResponse_Test is Used for Testing TwilioRestResponse Class
*********************************************************************************************************/
@istest
public Class TwilioRestResponse_Test{
    
    static testmethod void testResponseBody(){
        Test.startTest();
        TwilioRestResponse restResponse = new TwilioRestResponse('{"name":"TestName", "age":31, "city":"New York"}',200);
        String resBody = restResponse.responseBody;
        Test.stopTest();
    }
    
    static testmethod void testSetResponseText(){
        Test.startTest();
        TwilioRestResponse restResponse = new TwilioRestResponse('{"name":"TestName", "age":31, "city":"New York"}',200);
        restResponse.setResponseText('Response Text');
        Test.stopTest();
    }
    
    static testmethod void testGetAndSetHttpStatus(){
        Test.startTest();
        TwilioRestResponse restResponse = new TwilioRestResponse('{"name":"TestName", "age":31, "city":"New York"}',200);
        restResponse.setHttpStatus(200);
        Integer respStatus = restResponse.getHttpStatus();
        Test.stopTest();
    }
    
    static testmethod void testGetAndSetUrl(){
        Test.startTest();
        TwilioRestResponse restResponse = new TwilioRestResponse('{"name":"TestName", "age":31, "city":"New York"}',200);
        restResponse.setUrl('www.test.com');
        String returnedUrl = restResponse.getUrl();
        Test.stopTest();
    }
    
    static testmethod void testGetAndSetQueryString(){
        Test.startTest();
        TwilioRestResponse restResponse = new TwilioRestResponse('{"name":"TestName", "age":31, "city":"New York"}',200);
        restResponse.setQueryString('testQueryString');
        String queryString = restResponse.getQueryString();
        Test.stopTest();
    }
    
    static testmethod void testGetAndSetError(){
        Test.startTest();
        TwilioRestResponse restResponse = new TwilioRestResponse('{"name":"TestName", "age":31, "city":"New York"}',200);
        restResponse.setError(false);
        Boolean isError = restResponse.isError();
        Test.stopTest();
    }
    
    static testmethod void testClientError(){
        Test.startTest();
        TwilioRestResponse restResponse = new TwilioRestResponse('{"name":"TestName", "age":31, "city":"New York"}',200);
        restResponse.setHttpStatus(200);
        Boolean isClientError = restResponse.isClientError();
        Test.stopTest();
    }
    
    static testmethod void testServerError(){
        Test.startTest();
        TwilioRestResponse restResponse = new TwilioRestResponse('{"name":"TestName", "age":31, "city":"New York"}',200);
        restResponse.setHttpStatus(200);
        Boolean isServerError = restResponse.isServerError();
        Test.stopTest();
    }
    
    static testmethod void testSetContentType(){
        Test.startTest();
        TwilioRestResponse restResponse = new TwilioRestResponse('{"name":"TestName", "age":31, "city":"New York"}',200);
        restResponse.setContentType('TestContentType');
        Test.stopTest();
    }
    
    static testmethod void testIsJson(){
        Test.startTest();
        TwilioRestResponse restResponse = new TwilioRestResponse('www.test.com','{"name":"TestName", "age":31, "city":"New York"}',200);
        restResponse.setContentType('application/json');
        restResponse.isJson();
        Test.stopTest();
    }
    
    static testmethod void testIsXml(){
        Test.startTest();
        TwilioRestResponse restResponse = new TwilioRestResponse('{"name":"TestName", "age":31, "city":"New York"}',200);
        restResponse.setContentType('application/xml');
        restResponse.isXml();
        Test.stopTest();
    }
    
    static testmethod void testToMap(){
        Test.startTest();
        TwilioRestResponse restResponse = new TwilioRestResponse('{"name":"TestName", "age":31, "city":"New York"}',200);
        restResponse.setContentType('application/json');
        restResponse.toMap();
        Test.stopTest();
    }
    
    static testmethod void testToMapForException(){
        Test.startTest();
        TwilioRestResponse restResponse = new TwilioRestResponse('{"name":"TestName", "age":31, "city":"New York"}',200);
        restResponse.setContentType('application/xml');
        try{
            restResponse.toMap();
        }catch(Exception exp){
            System.debug('Exception : '+exp);
        }
        Test.stopTest();
    }
}