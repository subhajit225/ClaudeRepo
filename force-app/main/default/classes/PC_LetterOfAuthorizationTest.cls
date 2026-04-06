@isTest
public class PC_LetterOfAuthorizationTest {
    @testSetup static void setupmethod() {
        List<Contact> contList = new List<Contact>();
        UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
        Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
        User portalAccountOwner1 = new User(
            UserRoleId = portalRole.Id,
            ProfileId = profile1.Id,
            Username = System.now().millisecond() + 'tepuser2@test.com',
            Alias = 'batman',
            Email='brucee.wayne@wayneenteprises.com',
            EmailEncodingKey='UTF-8',
            Firstname='Bruce',
            Lastname='Wayne',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Chicago'
        );
        Database.insert(portalAccountOwner1);
        System.runAs ( portalAccountOwner1 ) {
            /*Account portalAccount1 = new Account(
                Name = 'TtAccount1',
                OwnerId = portalAccountOwner1.Id,
                Contract_Status__c = 'Signed-Active'
                isPartner
            );*/
            Account portalAccount1 = ShGl_TestFactory.testMethod_PartnerAccount('Test Account');
            portalAccount1.Name = 'PARTNER_MSP ';
            portalAccount1.Website='www.test3.com';
            portalAccount1.type='Customer';
            portalAccount1.BillingCountry='United States';
            portalAccount1.type='Reseller';
            portalAccount1.IsPartner = true;
            portalAccount1.Contract_Status__c = 'Signed-Active';
            update portalAccount1;
            
            ChannelProgram cp = new ChannelProgram(
            	Name='Elite Plus');
            Database.insert(cp);
            
            ChannelProgramLevel cpl = new ChannelProgramLevel(
                Name = 'E Plus',
                ProgramId = cp.Id
            );
            Database.insert(cpl);
            
            ChannelProgramMember cpm = new ChannelProgramMember(
                PartnerId = portalAccount1.Id,
                ProgramId = cp.Id,
                LevelId = cpl.Id
            );
            Database.insert(cpm);
            
            //Create contact
            Contact contact1 = new Contact(
                FirstName = 'Test',
                Lastname = 'McTesty',
                AccountId = portalAccount1.Id,
                Email = System.now().millisecond() + 'test@test.com',
                Primary_Role__c = 'Admin'
            );
            contList.add(contact1);
            Contact contact2 = new Contact(
                FirstName = 'Test 2',
                Lastname = 'McTesty 2',
                AccountId = portalAccount1.Id,
                Email = System.now().millisecond() + 'test@test.com',
                Primary_Role__c = 'Executive'
            );
            contList.add(contact2);
            insert contList;
            
            Profile portalProfile = [SELECT Id FROM Profile Where Name='Rubrik Partner community Manager' Limit 1];
            User user1 = new User(
                Username = System.now().millisecond() + 'teuser1@test.com',
                ContactId = contact1.Id,
                ProfileId = portalProfile.Id,
                Alias = 'test123',
                Email = 'test12345@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'McTes 1',
                CommunityNickname = 'test12345',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
            );
            Database.insert(user1);
            
            User user2 = new User(
                Username = System.now().millisecond() + 'teuser3@test.com',
                ContactId = contact2.Id,
                ProfileId = portalProfile.Id,
                Alias = 'test1234',
                Email = 'test123456@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'McTes 2',
                CommunityNickname = 'test123456',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
            );
            Database.insert(user2);
        }
    }
    
    @isTest static void letterOfAuthTest(){
        User portalUser1 = [SELECT Id,Name,Contact.Account.Name,Contact.Account.ChannelProgramLevelName FROM User Where LastName ='McTes 1'];
        User portalUser2 = [SELECT Id,Contact.Account.Name,Contact.Account.ChannelProgramLevelName FROM User Where LastName ='McTes 2'];
        
        system.debug('portalUser1->'+portalUser1);
        system.debug('portalUser2->'+portalUser2);
        test.startTest();
        system.runAs(portalUser2){
            Account acc = [SELECT Id FROM Account LIMIT 1];
            PageReference pageRef = Page.PC_LOA;
            Test.setCurrentPage(pageRef);
        	pageRef.getParameters().put('id', String.valueOf(acc.Id));
            PC_LetterOfAuthorization vfHandler = new PC_LetterOfAuthorization();
            vfHandler.renderAsPDF();
        }
        System.assertEquals(portalUser1.Name,'McTes 1');
        test.stopTest();
    }
    
    @isTest static void letterOfAuthStdControllerTest(){
        User portalUser2 = [SELECT Id,Contact.Account.Name,Contact.Account.ChannelProgramLevelName FROM User Where LastName ='McTes 2'];
        PageReference pageRef = Page.PC_LOA;
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id', String.valueOf(acc.Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(acc);
        system.runAs(portalUser2){
        	PC_LetterOfAuthorization test = new PC_LetterOfAuthorization(sc);
            test.letterContent = System.Label.PC_LetterContent;
            test.currentMonth = system.now().format('MMMM');
        }
    }
}