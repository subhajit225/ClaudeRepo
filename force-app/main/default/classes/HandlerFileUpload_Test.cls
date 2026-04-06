/********************************************************************************************************
* Name              : HandlerFileUpload_Test
* Purpose           : HandlerFileUpload_Test is Used for Testing HandlerFileUpload Class
*********************************************************************************************************/
@isTest
public class HandlerFileUpload_Test{

    static testMethod void testBotResponseForSuccessfullFileUpload() {
        String utterance = 'Test';
        Map<String, String> session = new Map<String, String>();
        session.put('Test1Key','Test1Value');
        String fileName ='TestFileName';
        String fileContent = 'TesFileContent';

        Test.startTest();
        HandlerFileUpload handlerFileUpload = new HandlerFileUpload();
        handlerFileUpload.handle(utterance,null,session,fileName,fileContent);
        Test.stopTest();
        
    }
    
     static testMethod void testBotResponseForUnsuccessfullFileUpload() {
        String utterance = 'Test';
        Map<String, String> session = new Map<String, String>();
        session.put('Test1Key','Test1Value');
        String fileName =null;
        String fileContent = 'TesFileContent';

        Test.startTest();
        HandlerFileUpload handlerFileUpload = new HandlerFileUpload();
        //
        handlerFileUpload.handle(utterance,null,session,fileName,fileContent);
        Test.stopTest();
        
    }

}