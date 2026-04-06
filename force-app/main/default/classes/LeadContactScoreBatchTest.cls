@isTest
public class LeadContactScoreBatchTest {
    @isTest
    static void testContactBatch() {
        Profile p = [Select Id From Profile Where Name = 'System Administrator' LIMIT 1];
        User testUser = new User(
            Alias = 'stduser',
            Email = 'standarduser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'TestUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com'
        );
        insert testUser;

        System.runAs(testUser) {
            Account acc = new Account(Name = 'Test Account');
            insert acc;
            Contact contact1 = new Contact(LastName = 'Test Contact', AccountId = acc.Id);
            insert contact1;
            Set<Id> accountIds = new Set<Id>{acc.Id};
            Test.startTest();
            LeadContactScoreBatch batch = new LeadContactScoreBatch(accountIds, 'Contact');
            Database.executeBatch(batch, 1);
            Test.stopTest();
            Contact updatedContact = [SELECT Id, Update_Lead_Score__c FROM Contact WHERE Id = :contact1.Id LIMIT 1];

            System.assertNotEquals(null, updatedContact, 'Contact should not be null');
        }
    }
}