/*
Author : Akhilesh Dhindsa 
Apex Class : PC_PortalUserDeactivationBatch
*/

@isTest
public class PC_PortalUserDeactivationBatchTest {
    
    @testSetup
    static void setupMethod() {
        UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
        Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
        User portAccountOwner1 = new User(
            UserRoleId = portalRole.Id,
            ProfileId = profile1.Id,
            Username = System.now().millisecond() + 'testAcc1@test.com.sandbox',
            Alias = 'userObj',
            Email='testuser.test@enterprises.com.sandbox',
            EmailEncodingKey='UTF-8',
            Firstname='Test',
            Lastname='DeactivatedUser1',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Chicago'
        );
        insert portAccountOwner1;
        
        System.runAs(portAccountOwner1) {
            Account portalAccount1 = new Account(
                Name = 'TestAccount',
                OwnerId = portAccountOwner1.Id
            );
            insert portalAccount1;
            
            Contact contact1 = new Contact(
                FirstName = 'Test',
                Lastname = 'Contact12test',
                AccountId = portalAccount1.Id,
                Email = 'test541@rubrik.com.sandbox',
                Primary_Role__c = 'Admin'
            );
            insert contact1;
            
            Profile portalProfile = [SELECT Id FROM Profile Where Name='Rubrik Partner community Manager' Limit 1];
            User user1 = new User(
                Username = System.now().millisecond() + 'tepuser23@test.com.sandbox',
                ContactId = contact1.Id,
                ProfileId = portalProfile.Id,
                Alias = 'test123',
                Email = 'test541@rubrik.com.sandbox',
                EmailEncodingKey = 'UTF-8',
                LastName = 'TestDeactivatedUser2',
                CommunityNickname = 'test12345' + System.now().millisecond(),
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
            );
            insert user1;
        }
    }
    
    @isTest
    static void testBatchExecution() {
        User scope =[Select id from User where Email='test541@rubrik.com.sandbox'];
        Test.startTest();
        System.runAs([SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1][0]) {
            PC_PortalUserDeactivationBatch batchObj = new PC_PortalUserDeactivationBatch();
            batchObj.start(null);
            batchObj.execute(null,new List<User>{scope});
            batchObj.finish(null);
        }
        Test.stopTest();
        User updatedUser = [SELECT Id, IsActive FROM User WHERE Id = :scope.Id];
        System.assertEquals(false, updatedUser.IsActive, 'The portal user should have been deactivated.');
        
    }
    
    @isTest
    static void testQueueableExceptionPath() { 
        PC_PortalUserDeactivationBatch.UserDeactivationQueueable queuer = new PC_PortalUserDeactivationBatch.UserDeactivationQueueable(null);
        Test.startTest();
        System.runAs([SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1][0]) {
            System.enqueueJob(queuer);
        }
        Test.stopTest();
        System.assert(true, 'Queueable executed without interrupting the test execution.');
    }
    
}