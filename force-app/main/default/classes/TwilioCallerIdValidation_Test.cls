/********************************************************************************************************
* Name              : TwilioCallerIdValidation_Test
* Purpose           : TwilioCallerIdValidation_Test is Used for Testing TwilioCallerIdValidation Class
*********************************************************************************************************/
@isTest
public class TwilioCallerIdValidation_Test{ 
    
    static testMethod void testGetAccountSidForJSON(){
        
        TwilioRestResponse restResponse = new TwilioRestResponse('https://test.com','{"status": 400,"AccountSid":"TestAccountSID","account_sid":"TestSID", "message": "No to number is specified", "code": 21201, "more_info": "http://www.twilio.com/docs/errors/21201","ice_servers":["Account","Opportunity"]}',400);
        restResponse.setContentType('application/json');
        Test.startTest();
        TwilioCallerIdValidation idValidation = new TwilioCallerIdValidation(restResponse);
        idValidation.getAccountSid();
        Test.stopTest();
        
    }
    
    static testMethod void testGetValidationCode(){
        
        TwilioRestResponse restResponse = new TwilioRestResponse('https://test.com','{"status": 400,"validation_code":"TestValidation_code","account_sid":"TestSID", "message": "No to number is specified", "code": 21201, "more_info": "http://www.twilio.com/docs/errors/21201","ice_servers":["Account","Opportunity"]}',400);
        restResponse.setContentType('application/json');
        Test.startTest();
        TwilioCallerIdValidation idValidation = new TwilioCallerIdValidation(restResponse);
        idValidation.getValidationCode();
        Test.stopTest();
        
    }
    
    static testMethod void testGetPhoneNumber(){
        
        TwilioRestResponse restResponse = new TwilioRestResponse('https://test.com','{"status": 400,"phone_number":"1234567890","account_sid":"TestSID", "message": "No to number is specified", "code": 21201, "more_info": "http://www.twilio.com/docs/errors/21201","ice_servers":["Account","Opportunity"]}',400);
        restResponse.setContentType('application/json');
        Test.startTest();
        TwilioCallerIdValidation idValidation = new TwilioCallerIdValidation(restResponse);
        idValidation.getPhoneNumber();
        Test.stopTest();
        
    }
    
    static testMethod void testGetFriendlyName(){
        
        TwilioRestResponse restResponse = new TwilioRestResponse('https://test.com','{"status": 400,"friendly_name":"TestFriendly_name","account_sid":"TestSID", "message": "No to number is specified", "code": 21201, "more_info": "http://www.twilio.com/docs/errors/21201","ice_servers":["Account","Opportunity"]}',400);
        restResponse.setContentType('application/json');
        Test.startTest();
        TwilioCallerIdValidation idValidation = new TwilioCallerIdValidation(restResponse);
        idValidation.getFriendlyName();
        Test.stopTest();
        
    }
    
    static testMethod void testGetPropertyForException(){
        
        TwilioRestResponse restResponse = new TwilioRestResponse('https://test.com','{"status": 400,"friendly_name":"TestFriendly_name","account_sid":"TestSID", "message": "No to number is specified", "code": 21201, "more_info": "http://www.twilio.com/docs/errors/21201","ice_servers":["Account","Opportunity"]}',400);
        restResponse.setContentType('application/json');
        Test.startTest();
        TwilioCallerIdValidation idValidation = new TwilioCallerIdValidation(restResponse);
        try{
            idValidation.getProperty('Test_Prop');
        }catch(Exception exp){
            System.debug('Exception = '+exp);
        }
        
        Test.stopTest();
        
    }
    
    static testMethod void testGetPropertyForInvalidProperty(){
        
        TwilioRestResponse restResponse = new TwilioRestResponse('https://test.com','{"status": 400,"Account":{"Name":"TestName"},"account_sid":"TestSID", "message": "No to number is specified", "code": 21201, "more_info": "http://www.twilio.com/docs/errors/21201","ice_servers":["Account","Opportunity"]}',400);
        restResponse.setContentType('application/json');
        Test.startTest();
        TwilioCallerIdValidation idValidation = new TwilioCallerIdValidation(restResponse);
        try{
            idValidation.getProperty('Account');
        }catch(Exception exp){
            System.debug('Exception = '+exp);
        }
        
        Test.stopTest();
        
    }
}