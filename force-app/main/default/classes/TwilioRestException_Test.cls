/********************************************************************************************************
* Name              : TwilioRestException_Test
* Purpose           : TwilioRestException_Test is Used for Testing TwilioRestException Class
*********************************************************************************************************/
@isTest
public class TwilioRestException_Test{ 
    
    static testMethod void testGetMessage(){
        TwilioRestException restExp = new TwilioRestException('ErrorMsg',404);
        Test.startTest();
        restExp.getMessage();
        Test.stopTest();
    }
    
    static testMethod void testGetMoreInfo(){
        TwilioRestException restExp = new TwilioRestException('ErrorMsg',404,'MoreInfo');
        Test.startTest();
        restExp.getMoreInfo();
        Test.stopTest();
    }
    
    static testMethod void testGetErrorCodeForJSON(){
        TwilioRestResponse restResponse = new TwilioRestResponse('{"name":"TestName", "code":"200", "more_info":"Testmore_info","status":"200"}',404);
        restResponse.setContentType('application/json');
        //restResponse.setHttpStatus(404);
        TwilioRestException restExp = new TwilioRestException(restResponse);
        Test.startTest();
        restExp.getErrorCode();
        Test.stopTest();
    }
    
}