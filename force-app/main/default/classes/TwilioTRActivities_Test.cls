/********************************************************************************************************
* Name              : TwilioTRActivities_Test 
* Purpose           : TwilioTRActivities_Test is Used for Testing TwilioTRActivities Class
*********************************************************************************************************/
@isTest
public class TwilioTRActivities_Test{
    final static String authToken = '12345678901234567890123456789012';
    static testMethod void testGetResourceLocation(){
        TwilioTRRestClient restClient= new TwilioTRRestClient('AC00000000000000000000000000000000',authToken);
        Test.startTest();
        TwilioTRActivities trActivities = new TwilioTRActivities(restClient,'WS00000000000000000000000000000000','WS00000000000000000000000000000000');
        trActivities.getResourceLocation();
        Test.stopTest();
    }
    
    static testMethod void testGetWorkspaceSid(){
        TwilioTRRestClient restClient= new TwilioTRRestClient('AC00000000000000000000000000000000',authToken);
        Test.startTest();
        TwilioTRActivities trActivities = new TwilioTRActivities(restClient,'WS00000000000000000000000000000000','WS00000000000000000000000000000000');
        trActivities.getWorkspaceSid();
        Test.stopTest();
    }
    
    static testMethod void testGetFriendlyName(){
        TwilioTRRestClient restClient= new TwilioTRRestClient('AC00000000000000000000000000000000',authToken);
        Test.startTest();
        Map<String, Object> properties = new Map<String, Object>();
        properties.put('friendly_name','TestName');
        TwilioTRActivities trActivities = new TwilioTRActivities(restClient,properties);
        trActivities.getFriendlyName();
        Test.stopTest();
    }
    
    static testMethod void testGetSid(){
        TwilioTRRestClient restClient= new TwilioTRRestClient('AC00000000000000000000000000000000',authToken);
        Test.startTest();
        TwilioTRActivities trActivities = new TwilioTRActivities(restClient,'WS00000000000000000000000000000000','WS00000000000000000000000000000000');
        trActivities.getSid();
        Test.stopTest();
    }
    
    static testMethod void testGetAvailable(){
        TwilioTRRestClient restClient= new TwilioTRRestClient('AC00000000000000000000000000000000',authToken);
        Test.startTest();
        Map<String, Object> properties = new Map<String, Object>();
        properties.put('available','true');
        TwilioTRActivities trActivities = new TwilioTRActivities(restClient,properties);
        trActivities.getAvailable();
        Test.stopTest();
    }
    
    static testMethod void testGetAccountSid(){
        TwilioTRRestClient restClient= new TwilioTRRestClient('AC00000000000000000000000000000000',authToken);
        Test.startTest();
        Map<String, Object> properties = new Map<String, Object>();
        properties.put('account_sid','AC00000000000000000000000000000000');
        TwilioTRActivities trActivities = new TwilioTRActivities(restClient,properties);
        trActivities.getAccountSid();
        Test.stopTest();
    }
    
    static testMethod void testGetDateCreated(){
        TwilioTRRestClient restClient= new TwilioTRRestClient('AC00000000000000000000000000000000',authToken);
        Test.startTest();
        Map<String, Object> properties = new Map<String, Object>();
        String str = JSON.serialize(DateTime.newInstance(2013, 11, 12));
        properties.put('date_created',str);
        TwilioTRActivities trActivities = new TwilioTRActivities(restClient,properties);
        try{
            trActivities.getDateCreated();
        }catch(Exception exp){
            System.debug('Exception :'+exp);
        }
        Test.stopTest();
    }
    
    static testMethod void testGetDateUpdated(){
        TwilioTRRestClient restClient= new TwilioTRRestClient('AC00000000000000000000000000000000',authToken);
        Test.startTest();
        Map<String, Object> properties = new Map<String, Object>();
        String str = JSON.serialize(DateTime.newInstance(2013, 11, 12));
        properties.put('date_updated',str);
        TwilioTRActivities trActivities = new TwilioTRActivities(restClient,properties);
        try{
            trActivities.getDateUpdated();
        }catch(Exception exp){
            System.debug('Exception :'+exp);
        }
        Test.stopTest();
    }
    
    static testMethod void testGetSubresourceUris(){
        TwilioTRRestClient restClient= new TwilioTRRestClient('AC00000000000000000000000000000000',authToken);
        Test.startTest();
        Map<String, Object> properties = new Map<String, Object>();
        properties.put('links','testLink');
        TwilioTRActivities trActivities1 = new TwilioTRActivities(restClient);
        TwilioTRActivities trActivities = new TwilioTRActivities(restClient,properties);
        try{
            trActivities.getSubresourceUris();
        }catch(Exception exp){
            System.debug('Exception :'+exp);
        }
        Test.stopTest();
    }
    
    static testMethod void testGetUrl(){
        TwilioTRRestClient restClient= new TwilioTRRestClient('AC00000000000000000000000000000000',authToken);
        Test.startTest();
        Map<String, Object> properties = new Map<String, Object>();
        properties.put('url','www.test.com');
        TwilioTRActivities trActivities = new TwilioTRActivities(restClient,properties);
        trActivities.getUrl();
        Test.stopTest();
    }
}