@isTest
public class PC_PartnerOppPipelineApexControllerTest 
{
    @testSetup static void createTestData()
    {
        UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
        Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
        User portAccountOwner1 = new User(
            UserRoleId = portalRole.Id,
            ProfileId = profile1.Id,
            Username = System.now().millisecond() + 'testpAcc1@test.com',
            Alias = 'batman',
            Email='bruce.wayne@wayneenterprises.com',
            EmailEncodingKey='UTF-8',
            Firstname='Bruce',
            Lastname='Wayne',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Chicago'
        );
        Database.insert(portAccountOwner1);
        System.runAs(portAccountOwner1){
            Account portalAccount1 = new Account(
                Name = 'TestAccount',
                OwnerId = portAccountOwner1.Id
                //Focused_Partner__c = true
            );
            Database.insert(portalAccount1);
            
            Contact contact1 = new Contact(
                FirstName = 'Test',
                Lastname = 'McTesty',
                AccountId = portalAccount1.Id,
                Email = System.now().millisecond() + 'test@test.com',
                Primary_Role__c = 'Admin'
            );
            insert contact1;
            
            Profile portalProfile = [SELECT Id FROM Profile Where Name='Rubrik Partner community Manager' Limit 1];
            User user1 = new User(
                Username = System.now().millisecond() + 'tepuser22@test.com',
                ContactId = contact1.Id,
                ProfileId = portalProfile.Id,
                Alias = 'test123',
                Email = 'test12345@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'McTesty',
                CommunityNickname = 'test12345',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
            );
            Database.insert(user1);
        }
    }
    
    @isTest static void testgetPartnerOppPipeline(){
        Account acc = [SELECT Id from Account Limit 1];
        User u = [SELECT Id FROM User WHERE LastName='McTesty'];
        test.startTest();
        System.runAs(u){
            PC_PartnerOppPipelineApexController.getPartnerOppPipeline(String.valueOf(u.Id), String.valueOf(system.today()), String.valueOf(system.today() + 1), 'test',new List<String>{acc.Id}, new List<String>{'Partner Sourced New Logo (PSNL)'});
            PC_PartnerOppPipelineApexController.getOpportunityData();
        } 
        test.stopTest();
    }
}