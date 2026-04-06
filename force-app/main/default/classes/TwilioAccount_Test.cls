/********************************************************************************************************
* Name              : TwilioAccount_Test 
* Purpose           : TwilioAccount_Test is Used for Testing TwilioAccount Class
*********************************************************************************************************/
@isTest
public class TwilioAccount_Test{
    final static String authToken = '12345678901234567890123456789012';
    public static testMethod void testTwilioAccountMethods(){
        
         String accountJsonResponseBody =
      '{"accounts":[{"sid": "ACba8bc05eacf94afdae398e642c9cc32d",'
          +'"owner_account_sid": "ACba8bc05eacf94afdae398e642c9cc32d",'
      +'"friendly_name": "Do you like my friendly name?",'
      +'"type": "Full",'
      +'"status": "active",'
      +'"date_created": "Wed, 04 Aug 2010 21:37:41 +0000",'
      +'"date_updated": "Fri, 06 Aug 2010 01:15:02 +0000",'
      +'"auth_token": "redacted",'
      +'"uri": "/2010-04-01/Accounts/ACba8bc05eacf94afdae398e642c9cc32d.json",'
      +'"subresource_uris": {'
        +'"authorized_connect_apps": "/2010-04-01/Accounts/ACba8bc05eacf94afdae398e642c9cc32d/AuthorizedConnectApps.json",'
        +'"available_phone_numbers": "/2010-04-01/Accounts/ACba8bc05eacf94afdae398e642c9cc32d/AvailablePhoneNumbers.json",'
            +'"calls": "/2010-04-01/Accounts/ACba8bc05eacf94afdae398e642c9cc32d/Calls.json",'
            +'"conferences": "/2010-04-01/Accounts/ACba8bc05eacf94afdae398e642c9cc32d/Conferences.json",'
            +'"incoming_phone_numbers": "/2010-04-01/Accounts/ACba8bc05eacf94afdae398e642c9cc32d/IncomingPhoneNumbers.json",'
            +'"notifications": "/2010-04-01/Accounts/ACba8bc05eacf94afdae398e642c9cc32d/Notifications.json",'
            +'"outgoing_caller_ids": "/2010-04-01/Accounts/ACba8bc05eacf94afdae398e642c9cc32d/OutgoingCallerIds.json",'
            +'"recordings": "/2010-04-01/Accounts/ACba8bc05eacf94afdae398e642c9cc32d/Recordings.json",'
            +'"sandbox": "/2010-04-01/Accounts/ACba8bc05eacf94afdae398e642c9cc32d/Sandbox.json",'
            +'"sms_messages": "/2010-04-01/Accounts/ACba8bc05eacf94afdae398e642c9cc32d/SMS/Messages.json",'
            +'"transcriptions": "/2010-04-01/Accounts/ACba8bc05eacf94afdae398e642c9cc32d/Transcriptions.json"'
        +'}},{"sid": "ACba8bc05eacf94afdae398e642c9cc32e",'
      +'"connect_app_sid": "CN8ff53fc8e48dfed305a8742c913b68a1",'
          +'"owner_account_sid": "ACba8bc05eacf94afdae398e642c9cc32d",'
          +'"friendly_name": "Subaccount for ConnectApp: Test",'
      +'"type": "Full",'
      +'"status": "active",'
      +'"date_created": "Wed, 04 Aug 2010 21:37:41 +0000",'
      +'"date_updated": "Fri, 06 Aug 2010 01:15:02 +0000",'
      +'"auth_token": "redacted",'
      +'"uri": "/2010-04-01/Accounts/ACba8bc05eacf94afdae398e642c9cc32e.json",'
      +'"subresource_uris": {'
        +'"authorized_connect_apps": "/2010-04-01/Accounts/ACba8bc05eacf94afdae398e642c9cc32e/AuthorizedConnectApps.json",'
        +'"available_phone_numbers": "/2010-04-01/Accounts/ACba8bc05eacf94afdae398e642c9cc32e/AvailablePhoneNumbers.json",'
            +'"calls": "/2010-04-01/Accounts/ACba8bc05eacf94afdae398e642c9cc32e/Calls.json",'
            +'"conferences": "/2010-04-01/Accounts/ACba8bc05eacf94afdae398e642c9cc32e/Conferences.json",'
            +'"incoming_phone_numbers": "/2010-04-01/Accounts/ACba8bc05eacf94afdae398e642c9cc32e/IncomingPhoneNumbers.json",'
            +'"notifications": "/2010-04-01/Accounts/ACba8bc05eacf94afdae398e642c9cc32e/Notifications.json",'
            +'"outgoing_caller_ids": "/2010-04-01/Accounts/ACba8bc05eacf94afdae398e642c9cc32e/OutgoingCallerIds.json",'
            +'"recordings": "/2010-04-01/Accounts/ACba8bc05eacf94afdae398e642c9cc32e/Recordings.json",'
            +'"sandbox": "/2010-04-01/Accounts/ACba8bc05eacf94afdae398e642c9cc32e/Sandbox.json",'
            +'"sms_messages": "/2010-04-01/Accounts/ACba8bc05eacf94afdae398e642c9cc32e/SMS/Messages.json",'
            +'"transcriptions": "/2010-04-01/Accounts/ACba8bc05eacf94afdae398e642c9cc32e/Transcriptions.json"'
        +'}}],"page":0,"total":2}';
        
        Twilio_TestHTTPMock.getInstance().putResponse(
          'POST',
          'https://api.twilio.com/2010-04-01/Accounts.json',
          new Twilio_TestHTTPMock.Response(accountJsonResponseBody,200)
      );
      
         Map<String, Object> properties = new Map<String, Object>();
         properties.put('connect_app_sid','CN8ff53fc8e48dfed305a8742c913b68a1');
         
        
        TwilioRestClient client = new TwilioRestClient('ACba8bc05eacf94afdae398e642c9cc32d', authToken);
        TwilioAccount twilioAct = new TwilioAccount(client,properties);
        Test.startTest();
        twilioAct.setSid('ACba8bc05eacf94afdae398e642c9cc32d');
        twilioAct.getSid();
        twilioAct.getConnectAppSid();
        twilioAct.getOwnerAccountSid();
        twilioAct.setAuthToken(authToken);
        twilioAct.getAuthToken();
        twilioAct.getFriendlyName();
        twilioAct.getStatus();
        twilioAct.getDateCreated();
        twilioAct.getDateUpdated();
        twilioAct.getType();
        twilioAct.getUri();
        //twilioAct.getSubresourceUris();
        twilioAct.getResourceLocation();
        twilioAct.getCalls();
        twilioAct.getCall('ACba8bc05eacf94afdae398e642c9cc32d');
        twilioAct.getSms('ACba8bc05eacf94afdae398e642c9cc32d');
        twilioAct.getMessage('ACba8bc05eacf94afdae398e642c9cc32d');
        twilioAct.getQueue('AC03c2fcd60e144e7cbeed179fcbf812a3');
        twilioAct.getApplication('AC03c2fcd60e144e7cbeed179fcbf812a3');
        twilioAct.getConference('AC03c2fcd60e144e7cbeed179fcbf812a3');
        twilioAct.getParticipants('AC03c2fcd60e144e7cbeed179fcbf812a3');
        twilioAct.getIncomingPhoneNumber('AC03c2fcd60e144e7cbeed179fcbf812a3');
        twilioAct.getShortCode('AC03c2fcd60e144e7cbeed179fcbf812a3');
        twilioAct.getNotification('AC03c2fcd60e144e7cbeed179fcbf812a3');
        twilioAct.getOutgoingCallerId('AC03c2fcd60e144e7cbeed179fcbf812a3');
        twilioAct.getRecording('AC03c2fcd60e144e7cbeed179fcbf812a3');
        twilioAct.getTranscription('AC03c2fcd60e144e7cbeed179fcbf812a3');
        twilioAct.getConnectApp('AC03c2fcd60e144e7cbeed179fcbf812a3');
        twilioAct.getAuthorizedConnectApp('AC03c2fcd60e144e7cbeed179fcbf812a3');
        twilioAct.getParticipant('AC03c2fcd60e144e7cbeed179fcbf812a3','AC03c2fcd60e144e7cbeed179fcbf812a3');
        twilioAct.getSmsMessages();
        twilioAct.getMessages();
        twilioAct.getQueues();
        //twilioAct.suspend();
        //twilioAct.activate();
        //twilioAct.close();
        twilioAct.getApplications();
        twilioAct.getAvailablePhoneNumbers();
        twilioAct.getConferences();
        twilioAct.getIncomingPhoneNumbers();
        twilioAct.getShortCodes();
        twilioAct.getNotifications();
        twilioAct.getOutgoingCallerIds();
        twilioAct.getRecordings();
        twilioAct.getTranscriptions();
        twilioAct.getSandbox();
        
        TwilioAccount twilioAct1 = new TwilioAccount(client);
        try{
            twilioAct1.suspend();
        }catch(Exception exp){
            System.debug('Exception : '+exp);
        }
        try{
            twilioAct1.activate();
        }catch(Exception exp){
            System.debug('Exception : '+exp);
        }
        try{
            twilioAct1.close();
        }catch(Exception exp){
            System.debug('Exception : '+exp);
        }
        Map<String, String> filters = new Map<String, String>();
        filters.put('Key','Value');
        try{
            twilioAct1.getAvailablePhoneNumbers(filters, 'India', 'Type');
        }catch(Exception exp){
            System.debug('Exception : '+exp);
        }
        try{
            twilioAct1.getConnectApps(filters);
        }catch(Exception exp){
            System.debug('Exception : '+exp);
        }
        try{
            twilioAct1.getAuthorizedConnectApps(filters);
        }catch(Exception exp){
            System.debug('Exception : '+exp);
        }
        try{
            twilioAct1.getSubresourceUris();
        }catch(Exception exp){
            System.debug('Exception : '+exp);
        }
        Test.stopTest();
    } 
        
}