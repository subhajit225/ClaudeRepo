/***************************************************************************** 
* @description       : This is a Test class for SyncBookingTrigger for Sync_Booking__e
* @author            : 
* @last modified on  : 10-06-2025
* @last modified by  : Shrutika Kesarkar
* Modifications Log
* Ver   Date          Author               Modification
* 1.0   10-06-2025    Shrutika Kesarkar    Initial Version
******************************************************************************/
@istest
public class SyncBookingTriggerTest {
    static testMethod void testSyncBookingTrigger() {
        String uniqueUserName = 'PolarisFulfilmentAPITest@rbk.com';
        Profile pf = [SELECT Id FROM Profile WHERE Name = 'API Integration User'];
        User usr2 = new user(
        Username = 'api.integration.user@example.com',
        firstname = 'test123',
        lastname = 'user123',
        Email = 'api.integration.user@example.com',
        Alias = 'apiuser',
        TimeZoneSidKey = 'America/New_York',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        profileid = pf.Id
        );
        insert usr2;
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User usr = new user(
        alias = 'std',
        email = 'testuser@testclass.com',
        emailencodingkey = 'UTF-8',
        firstname = 'test',
        lastname = 'user',
        languagelocalekey = 'en_US',
        localesidkey = 'en_US',
        profileid = p.Id,
        timezonesidkey = 'America/Los_Angeles',
        username = uniqueUserName
        );
        System.runAs(usr) {
            Sync_Booking__e syncOppty = new Sync_Booking__e(Record_Id__c = 'oppty.Id');
            Test.startTest();
            EventBus.publish(syncOppty);
            Test.stopTest();
            List<CronTrigger> currentRunningApex = [
                SELECT CronJobDetailId, CronJobDetail.Name
                FROM CronTrigger
                WHERE CronJobDetail.Name = 'SyncBookingBatchSchedularFromTrigger'
            ];
            system.assert(currentRunningApex.size() > 0);
        }
    }
}