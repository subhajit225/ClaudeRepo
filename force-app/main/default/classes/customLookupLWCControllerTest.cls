@isTest
public class customLookupLWCControllerTest {
    @isTest static void test_method_one() {
        String uniqueUserName = 'AdminUser' + DateTime.now().getTime() + '@rubrik.com';
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User user1 = new User(
            Alias = 'adminU', Email='AdminUser@rubrik.com.sandbox',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles',
            UserName=uniqueUserName
        );
        insert user1;
        Test.startTest();
        customLookupLWCController.getRecordsByName('Account','Test','Partner/Distributor','','',false,null,new List<String>{'Reseller'});
        customLookupLWCController.getRecordsByName('Account','Test','Customer/Prospect','','',true,null,new List<String>());
        customLookupLWCController.getRecordsByName('User','AdminUser','Partner/Distributor','','',null,null,new List<String>());
        customLookupLWCController.getRecordsByName('Contact','AdminUser','','','',null,null,new List<String>());
        customLookupLWCController.fetchDefaultRecord(user1.Id,'User');
        customLookupLWCController.fetchDetailedRecords(null, 'test', 'United States', 'Account','Customer/Prospect', 'Id, Name');
        Test.stopTest();
    }
}