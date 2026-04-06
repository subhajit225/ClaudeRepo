@isTest
public class  ScheduleBookingSyncBatchTest{
    public static testmethod void schedBatch(){ 
            String uniqueUserName = 'ScheduleBookingBatchTest' + DateTime.now().getTime() + '@testclass.com';           
            Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
            User usr=new user(alias = 'std', email='testuser@testclass.com',
            emailencodingkey='UTF-8', firstname='test', lastname='user', languagelocalekey='en_US',
            localesidkey='en_US', profileid = p.Id,
            timezonesidkey='America/Los_Angeles', username=uniqueUserName);
            
            System.runAs(usr){ 
            test.startTest();   
             ScheduleBookingSyncBatch.setup();
            test.stopTest(); 
            }
                
     }   
}