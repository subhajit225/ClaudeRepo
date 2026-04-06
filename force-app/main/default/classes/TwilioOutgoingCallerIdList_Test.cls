/********************************************************************************************************
* Name              : TwilioOutgoingCallerIdList_Test 
* Purpose           : TwilioOutgoingCallerIdList_Test is Used for Testing TwilioOutgoingCallerIdList Class
*********************************************************************************************************/
@isTest
public class TwilioOutgoingCallerIdList_Test{
    final static String authToken = '12345678901234567890123456789012';
    
    static testMethod void testGetResourceLocation(){
        String accountJsonResponseBody ='{"recordings":[{"sid":"RE4e03662f6b8c01856fbd8f3769c2351a",'
        +'"account_sid":"AC03c2fcd60e144e7cbeed179fcbf812a3",'
        +'"call_sid":"CAfd61c7aff9ee4da8a053d49a35a5ff7f",'
        +'"duration":"7",'
        +'"date_created":"Fri, 1 Feb 2012 10:49:17 +0000",'
        +'"api_version":"2010-04-01",'
        +'"date_updated":"Fri, 1 Feb 2012 10:49:17 +0000",'
        +'"uri":"/2010-04-01/Accounts/AC03c2fcd60e144e7cbeed179fcbf812a3/Recordings/RE4e03662f6b8c01856fbd8f3769c2351a.json"}],'
        +'"page":0,"num_pages":1,"page_size":50,"total":2,"start":0,"end":1,"uri":'
        +'"/2010-04-01/Accounts/AC03c2fcd60e144e7cbeed179fcbf812a3/Applications.json",'
        +'"first_page_uri":"/2010-04-01/Accounts/AC03c2fcd60e144e7cbeed179fcbf812a3/Applications.json?Page=0&PageSize=50",'+
        +'"previous_page_uri":null,"next_page_uri":null,"last_page_uri":"/2010-04-01/Accounts/AC03c2fcd60e144e7cbeed179fcbf812a3/Applications.json?Page=0&PageSize=50"}';
        // register a mock Response with the Twilio_TestHTTPMock singleton service
        // for the HTTP GET method and at the Twilio Account instance URI.
        Twilio_TestHTTPMock.getInstance().putResponse(
            'GET',
            'https://api.twilio.com/2010-04-01/Accounts/AC03c2fcd60e144e7cbeed179fcbf812a3/Recordings.json',
            new Twilio_TestHTTPMock.Response(accountJsonResponseBody,200)
        );
        
        
        TwilioRestClient client = new TwilioRestClient('AC03c2fcd60e144e7cbeed179fcbf812a3', authToken);
        Test.startTest();
        TwilioOutgoingCallerIdList  callerIdList = new TwilioOutgoingCallerIdList(client);
        callerIdList.getResourceLocation();
        callerIdList.getListKey();
        Test.stopTest();
    }
    
    static testMethod void testGetPageData(){
        TwilioRestClient client = new TwilioRestClient('AC03c2fcd60e144e7cbeed179fcbf812a3', authToken);
        Test.startTest();
        TwilioOutgoingCallerIdList  callerIdList = new TwilioOutgoingCallerIdList(client);
        try{
            callerIdList.getPageData();
        }catch(Exception exp){
            System.debug('Exception :'+exp);
        }
        
        Test.stopTest();
    }
    
    static testMethod void testIterator(){
        TwilioRestClient client = new TwilioRestClient('AC03c2fcd60e144e7cbeed179fcbf812a3', authToken);
        Test.startTest();
        TwilioOutgoingCallerIdList  callerIdList = new TwilioOutgoingCallerIdList(client);
        try{
            callerIdList.iterator();
        }catch(Exception exp){
            System.debug('Exception :'+exp);
        }
        Test.stopTest();
    }
    
    static testMethod void testValidate(){
        TwilioRestClient client = new TwilioRestClient('AC03c2fcd60e144e7cbeed179fcbf812a3', authToken);
        Test.startTest();
        TwilioOutgoingCallerIdList  callerIdList = new TwilioOutgoingCallerIdList(client);
        try{
            callerIdList.validate('123456789');
        }catch(Exception exp){
            System.debug('Exception :'+exp);
        }
        Test.stopTest();
    }
    
    static testMethod void testMakeNew(){
        TwilioRestClient client = new TwilioRestClient('AC03c2fcd60e144e7cbeed179fcbf812a3', authToken);
        Test.startTest();
        Map<String, String> filters = new Map<String, String>();
        filters.put('TestKey','TestValue');
        TwilioOutgoingCallerIdList  callerIdList = new TwilioOutgoingCallerIdList(client,filters);
        try{
            callerIdList.makeNew(client,filters);
        }catch(Exception exp){
            System.debug('Exception :'+exp);
        }
        Test.stopTest();
    }
}