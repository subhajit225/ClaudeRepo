@isTest
public class BatchRunControllerTest {
    
    public static testMethod void testProcess()
    {
        String uniqueUserName = 'BatchRunControllerTest' + DateTime.now().getTime() + '@testclass.com';           
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
            User usr=new user(alias = 'std', email='testuser@testclass.com',
            emailencodingkey='UTF-8', firstname='test', lastname='user', languagelocalekey='en_US',
            localesidkey='en_US', profileid = p.Id,
            timezonesidkey='America/Los_Angeles', username=uniqueUserName);
            
            System.runAs(usr){ 
            Test.startTest();       
            BatchRunController BRC = new BatchRunController();
            BRC.process();
            BRC.messages();
            BRC.processSync();
            BRC.messagesSync();
            Test.stopTest();
        }
    }
    
}