/********************************************************************************************************
* Name              : BotResponse_Test
* Purpose           : BotResponse_Test is Used for Testing BotResponse Class
*********************************************************************************************************/
@isTest
public class BotResponse_Test{
    
    static testMethod void testBotResponse(){
        Test.startTest();
        BotResponse response0 = new BotResponse();
        
        
        BotMessage[] botMessage= new BotMessage[1];
        botMessage.add(new BotMessage());
        BotResponse response1 = new BotResponse(botMessage);
        
        List<BotMessage> messages = new List<BotMessage>{new BotMessage()};
        Map<String, String> session = new Map<String, String>();
        session.put('TestKey','TestValue');
        BotResponse response2 = new BotResponse(messages,session);
        
        BotResponse response3 = new BotResponse(new BotMessage());
        
        BotResponse response4 = new BotResponse(new BotMessage(),session);
        Test.stopTest();
    }
    
}