@isTest
public class  ScheduleBookingBatchTest{
    public static testmethod void schedBatch(){ 
        String uniqueUserName = 'ScheduleBookingBatchTest' + DateTime.now().getTime() + '@testclass.com';           
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User usr=new user(alias = 'std', email='testuser@testclass.com',
        emailencodingkey='UTF-8', firstname='test', lastname='user', languagelocalekey='en_US',
        localesidkey='en_US', profileid = p.Id,
        timezonesidkey='America/Los_Angeles', username=uniqueUserName);
        
        System.runAs(usr){ 
        test.startTest();   
        BookingbatchController.method();
        test.stopTest(); 
        }
            
 }   

    @isTest
    public static void testSetup(){ 
        test.startTest();   
        ScheduleBookingBatch.setup();
        test.stopTest(); 
    }   
    @isTest
    public static void testSchedule(){ 
        test.startTest();   
        Datetime dt = Datetime.now().addMinutes(1);
        String jobID = System.Schedule('Booking Batchs Test @ 00 min.', dt.format('s m H d M \'?\' yyyy'), new ScheduleBookingBatch());
        test.stopTest(); 
    }   
}