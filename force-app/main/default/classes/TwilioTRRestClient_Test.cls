/********************************************************************************************************
* Name              : TwilioTRRestClient_Test 
* Purpose           : TwilioTRRestClient_Test is Used for Testing TwilioTRRestClient Class
*********************************************************************************************************/
@isTest(seeAllData = false)
public class TwilioTRRestClient_Test {
    final static String authToken = '12345678901234567890123456789012';
    
    public static testMethod void testGetWorkspaces() {
        Test.startTest();
        TwilioTRRestClient restClient= new TwilioTRRestClient('AC00000000000000000000000000000000',authToken);
        restClient.getWorkspaces();
        Test.stopTest();
    }
    
    public static testMethod void testGetWorkspace() {
        String VISION_API = 'https://api.metamind.io/v1/vision';
        String tokenEndpoint=VISION_API + '/datasets/upload';
        Test.startTest();
        TwilioTRRestClient restClient= new TwilioTRRestClient('AC00000000000000000000000000000000',authToken,tokenEndpoint);
        TwilioTRWorkspace trWorkspace= restClient.getWorkspace('WS00000000000000000000000000000000');
        Test.stopTest();
    }
}