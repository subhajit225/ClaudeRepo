/**
 * @test
 * @class       Workday_UserOnTimeOffTest
 * @author      Saakshi Gupta
 * @created     2020-05-29
 * @description Test class for the Workday_UserOnTimeOff batch class.
 *              Validates that user time-off statuses are correctly updated
 *              based on the batch execution logic.
 * @date 2025-08-01
 * 
 */

@isTest(SeeAllData = false)
public class Workday_UserOnTimeOffTest {
    /**
     * @description test data
     */
    @testSetup
    private static void setup(){
        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'Rubrik Customer Support User'].Id;
        List<User> userList = new List<User>();
        User u = new User(
            ProfileId = profileId,
            LastName = 'last',
            Email = 'testuser@test.com',
            Username = System.now().millisecond() + 'testuser@test.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Employee_Time_Off__c = true);
        userList.add(u);
        User u2 = new User(
            ProfileId = profileId,
            LastName = 'last',
            Email = 'testuser2@test.com',
            Username = System.now().millisecond() + 'testuser2@test.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias2',
            TimeZoneSidKey = String.valueOf(UserInfo.getTimeZone()),
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Time_Off_Dates__c = String.valueOf(System.today()));
        userList.add(u2);
        insert userList;
        
    }
    
    
    /**
     * @description Tests the Workday_UserOnTimeOff batch class functionality to validate user time-off status updates
     */
    @isTest
    public static void testWorkdayUserOnTimeOff(){
        
        User user3 = [SELECT Id, Employee_Time_Off__c FROM User WHERE Email = 'testuser@test.com'];
        System.runAs(user3){
        Test.startTest();
        Database.executeBatch(new Workday_UserOnTimeOff(), 200);
        Test.stopTest();
        
        User user1 = [SELECT Id, Employee_Time_Off__c FROM User WHERE Email = 'testuser@test.com'];
        System.assert(!user1.Employee_Time_Off__c);
        User user2 = [SELECT Id, Employee_Time_Off__c FROM User WHERE Email = 'testuser2@test.com'];
        System.assert(user2.Employee_Time_Off__c);
        }
    }
}