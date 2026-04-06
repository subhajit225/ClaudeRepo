/********************************************************************************************************
* Name              : TwilioNTSToken_Test
* Purpose           : TwilioNTSToken_Test is Used for Testing TwilioNTSToken Class
*********************************************************************************************************/
@isTest
public class TwilioNTSToken_Test{
    
    static testMethod void testGetProperty(){
        TwilioRestResponse restResponse = new TwilioRestResponse('https://test.com','{"status": 400, "message": "No to number is specified", "code": 21201, "more_info": "http://www.twilio.com/docs/errors/21201","ice_servers":["Account","Opportunity"]}',400);
        restResponse.setContentType('application/json');
        TwilioNTSToken nTSToken = new TwilioNTSToken(restResponse);
        
        Test.startTest();
        nTSToken.getProperty('TestString');
        Test.stopTest();
    }
    
    static testMethod void testGetPropertyForException(){
        TwilioRestResponse restResponse = new TwilioRestResponse('https://test.com','{"status": 400, "message": "No to number is specified", "code": 21201, "more_info": "http://www.twilio.com/docs/errors/21201"}',400);
        restResponse.setContentType('application/json');
        Test.startTest();
        try{
            TwilioNTSToken nTSToken = new TwilioNTSToken(restResponse);
            nTSToken.getProperty('TestString');
        }catch(Exception exp){
            System.debug('Exception in getProperty = '+ exp);
        }
        Test.stopTest();
    }
    
    static testMethod void testGetUserName(){
        TwilioRestResponse restResponse = new TwilioRestResponse('https://test.com','{"status": 400, "message": "No to number is specified", "code": 21201, "more_info": "http://www.twilio.com/docs/errors/21201","ice_servers":["Account","Opportunity"]}',400);
        restResponse.setContentType('application/json');
        TwilioNTSToken nTSToken = new TwilioNTSToken(restResponse);
        
        Test.startTest();
        nTSToken.getUserName();
        Test.stopTest();
    }
    
    static testMethod void testGetPassword(){
        TwilioRestResponse restResponse = new TwilioRestResponse('https://test.com','{"status": 400, "message": "No to number is specified", "code": 21201, "more_info": "http://www.twilio.com/docs/errors/21201","ice_servers":["Account","Opportunity"]}',400);
        restResponse.setContentType('application/json');
        TwilioNTSToken nTSToken = new TwilioNTSToken(restResponse);
        
        Test.startTest();
        nTSToken.getPassword();
        Test.stopTest();
    }
    
    static testMethod void testGetTTL(){
        TwilioRestResponse restResponse = new TwilioRestResponse('https://test.com','{"status": 400, "message": "No to number is specified", "code": 21201, "more_info": "http://www.twilio.com/docs/errors/21201","ice_servers":["Account","Opportunity"]}',400);
        restResponse.setContentType('application/json');
        TwilioNTSToken nTSToken = new TwilioNTSToken(restResponse);
        
        Test.startTest();
        nTSToken.getTTL();
        Test.stopTest();
    }
    
    static testMethod void testGetAccountSid(){
        TwilioRestResponse restResponse = new TwilioRestResponse('https://test.com','{"status": 400, "message": "No to number is specified", "code": 21201, "more_info": "http://www.twilio.com/docs/errors/21201","ice_servers":["Account","Opportunity"]}',400);
        restResponse.setContentType('application/json');
        TwilioNTSToken nTSToken = new TwilioNTSToken(restResponse);
        
        Test.startTest();
        nTSToken.getAccountSid();
        Test.stopTest();
    }
}