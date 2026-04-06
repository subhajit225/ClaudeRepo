/********************************************************************************************************
* Name              : TwilioParser_Test 
* Purpose           : TwilioParser_Test is Used for Testing TwilioParser Class
*********************************************************************************************************/
@isTest
public class TwilioParser_Test{
    static testMethod void testJsonToMap(){
        String accountJsonResponseBody ='{"Account":[{"Name":"TestAccountName","Country":"India"}]}';
        Test.startTest();
        TwilioParser.jsonToMap(accountJsonResponseBody);
        Test.stopTest();
    }
    
    static testMethod void testJsonToList(){
        String accountJsonResponseBody ='[{"Name":"TestAccountName","Country":"India"}]';
        Test.startTest();
        TwilioParser.jsonToList(accountJsonResponseBody);
        Test.stopTest();
    }
    
    static testMethod void testParseDatetime(){
        Test.startTest();
        String todayDatetime= String.valueOf('2013 11 Dec 2013 09:08:07 06');
        TwilioParser.parseDatetime(todayDatetime);
        Test.stopTest();
    }
    
    static testMethod void testParseDatetimeForNull(){
        Test.startTest();
        String todayDatetime;
        TwilioParser.parseDatetime(todayDatetime);
        Test.stopTest();
    }
    
    static testMethod void testFormatDatetime(){
        Test.startTest();
        TwilioParser.formatDatetime(DateTime.newInstanceGMT(2013, 11, 12, 3, 3, 3));
        Test.stopTest();
    }
    
    static testMethod void testFormatFilterDatetime(){
        Test.startTest();
        TwilioParser.formatFilterDatetime(2013, 11, 12);
        Test.stopTest();
    }
}