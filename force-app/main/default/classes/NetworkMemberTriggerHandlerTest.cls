/**
* @Author       :   Saakshi Gupta
* @CreatedDate  :   08-08-2022
* @Jira Ticket  :   CS21-1100 - Forums 2.0 Rewards Redemption/Swag Store
* @Description  :   Test class for NetworkMemberTriggerHandler.
*/
@isTest(seeAllData=false)
public class NetworkMemberTriggerHandlerTest {
    @testSetup
    public static void dataSetup() {
        insert new TriggerControl__c(Name='Entitlement');

        Account testAccount = new Account(name='Test Company Name');
        insert testAccount;

        Contact testContactDummy = new Contact();
        Contact testContact = new Contact(AccountId=testAccount.Id, FirstName='First Name',LastName='Last name',title='TITLE',Phone='123456489',Email='test@test.com');
        insert testContact;

        Profile prof = [SELECT Id FROM Profile WHERE Name = 'Rubrik Customer Community Login User' LIMIT 1];
        User u = new User(Alias = 'standt1', email='standarduser1@testorg.com',
                          EmailEncodingKey='UTF-8', LastName='Testing1', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', ProfileId = prof.Id,
                          TimeZoneSidKey='America/Los_Angeles', username='standarduser@testorg131.com', ContactId = testContact.Id);
        insert u;
    }

    @isTest static void testUpdateUserCoins() {
        Profile prof = [SELECT Id FROM Profile WHERE Name = 'Rubrik Customer Community Login User' LIMIT 1];
        NetworkMember n = [SELECT Id, ReputationPoints FROM NetworkMember WHERE Member.Email = 'standarduser1@testorg.com' AND Member.ProfileId =:  prof.Id LIMIT 1];
        n.ReputationPoints = n.ReputationPoints + 10;
        update n;
    }
}