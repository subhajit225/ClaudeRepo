/**
 * @description
 *   Test class for NewIdeaController, covering Idea creation functionality.
 *   It inserts necessary test data including Account, Contact, User, and AccountTeamMember
 *   to enable testing of idea creation in a community context.
 * @author Grazitti
 * @date 2016-04-16
 * @test
 */
@isTest
public class NewIdeaControllerTest {

    /**
     * @description
     *   Inserts test data required for executing NewIdeaController tests.
     *   This includes TriggerControl records, Account, Contact, User and AccountTeamMember.
     */
    @TestSetup
    public static void dataSetup() {
        insert new TriggerControl__c(Name='Case');
        insert new TriggerControl__c(Name='Entitlement');
        
        Account acc = new Account(name='testAcc');
        acc.OwnerId=UserInfo.getUserId();
        insert acc;
        
        Contact cont = new Contact(lastName='testCont');
        cont.Notify_For_case_creation__c = true;
        cont.Email='testcontact@test.com';
        cont.AccountId = acc.Id;
        insert cont;
        
        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'Rubrik Community Super User'].Id;
        
        User u = new User(
            ProfileId = profileId,
            ContactId = cont.Id,
            FirstName = 'Test Contact',
            LastName = 'User',
            Email = 'testcontactuser@test.com',
            Username = System.now().millisecond() + 'testcontactuser@test.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = String.valueOf(UserInfo.getTimeZone()),
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            IsActive = true);
        
        insert u;
        
        AccountTeamMember teamMember = new AccountTeamMember();
        teamMember.AccountId = acc.Id;
        teamMember.UserId = UserInfo.getUserId();
        teamMember.TeamMemberRole = 'Sales Engineer';
        insert teamMember;
    }

    /**
     * @description
     *   Tests the creation of an Idea record using NewIdeaController.
     *   Verifies that a new Idea Id is returned after creation.
     */
    public static testMethod void createIdeaTest() {
        User us = [SELECT Id FROM User WHERE Email = 'testcontactuser@test.com' LIMIT 1];
        System.runAs(us) {
            String networkId = System.Label.CommNetworkId;
            NewIdeaController.getPiklistValues();    
            String ideaId = NewIdeaController.createIdea('test', 'testBody', new List<String>{'Other'}, networkId);
            System.assertEquals(true, ideaId != null, 'Idea Id should not be null after creation');
        }
    }
}