@isTest
/** Created By : Sidhant 
* Purpose : Test class of PC_UserManagementApexController
**/
public class PC_UserManagementApexControllerTest {
    @testSetup static void createData(){
        UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
        Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
        User portAccountOwner1 = new User(
            UserRoleId = portalRole.Id,
            ProfileId = profile1.Id,
            Username = System.now().millisecond() + 'testpAcc1@test.com.sandbox',
            Alias = 'batman',
            Email='bruce.wayne@wayneenterprises.com.sandbox',
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
                Email = 'test541@rubrik.com.sandbox',
                Primary_Role__c = 'Admin'
            );
            insert contact1;
            
            Contact contact2 = new Contact(
                FirstName = 'Test2',
                Lastname = 'McTesty2',
                AccountId = portalAccount1.Id,
                Email = 'test542@rubrik.com.sandbox',
                Primary_Role__c = 'Admin'
            );
            insert contact2;
            
            Profile portalProfile = [SELECT Id FROM Profile Where Name='Rubrik Partner community Manager' Limit 1];
            User user1 = new User(
                Username = System.now().millisecond() + 'tepuser23@test.com.sandbox',
                ContactId = contact1.Id,
                ProfileId = portalProfile.Id,
                Alias = 'test123',
                //Email = 'test12345@test.com.sandbox',
                Email = 'test541@rubrik.com.sandbox',
                EmailEncodingKey = 'UTF-8',
                LastName = 'McTesty',
                CommunityNickname = 'test12345',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
            );
            Database.insert(user1);
            
            Profile portalProfile2 = [SELECT Id FROM Profile Where Name='Rubrik Customer Community Login User' LIMIT 1];
            User user2 = new User(
                Username = System.now().millisecond() + 'tepuer44@test.com.sandbox',
                ContactId = contact2.Id,
                ProfileId = portalProfile2.Id,
                Alias = 'tst1239',
                Email = 'tet12con@test.com.sandbox',
                EmailEncodingKey = 'UTF-8',
                LastName = 'McTesty 22',
                CommunityNickname = 'tstu2349',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
            );
            Database.insert(user2);
        }
    }
    @isTest static void testcreateNewUser()
    {
        User u = [SELECT Id FROM User WHERE LastName='McTesty'];
        User u1 = [SELECT Id FROM User WHERE LastName='McTesty 22'];
        Contact con= [SELECT Id FROM Contact WHERE LastName='McTesty'];
        test.startTest();
        System.runAs(u){
            Contact c = new Contact();
            c.Email ='test541@rubrik.com.sandbox';
            c.FirstName = 'test541';
            c.LastName = 'user1';
            c.Title = 'IT';
            c.Phone = '1234567890';
            String result = PC_UserManagementApexcontroller.createNewUser(c,true);
            Contact c1 = new Contact();
            c1.Email ='test542@rubrik.com.sandbox';
            c1.FirstName = 'test542';
            c1.LastName = 'user1';
            c1.Title = 'IT';
            c1.Phone = '1234567890';
            String result2 = PC_UserManagementApexcontroller.createNewUser(c1,true);
			Contact c3 = new Contact();
            c3.Email ='test541@rubrik.com.sandbox';
            c3.FirstName = 'test541';
            c3.LastName = 'user1';
            c3.Title = 'IT';
            c3.Phone = '1234567890';
            String result3 = PC_UserManagementApexcontroller.createNewUser(c3,true);
        }
        con.No_Longer_Employed_Here__c = true;
        update con;
        System.runAs(u){
            Contact c = new Contact();
            c.Email ='test541@rubrik.com.sandbox';
            c.FirstName = 'test541';
            c.LastName = 'user1';
            c.Title = 'IT';
            c.Phone = '1234567890';
            String result2 = PC_UserManagementApexcontroller.createNewUser(c,false);
        }
        
        System.runAs(u1){
            Contact c = new Contact();
            c.Email ='test541@rubrik.com.sandbox';
            c.FirstName = 'test541';
            c.LastName = 'user1';
            c.Title = 'IT';
            c.Phone = '1234567890';
            String result3 = PC_UserManagementApexcontroller.createNewUser(c,false);
            String result4 = PC_UserManagementApexcontroller.createNewUser(c,true);
        }
        test.stopTest();
    }
    
    @isTest static void testdeactivateUser()
    {
        Contact con = [SELECT Id FROM Contact WHERE LastName='McTesty'];
        test.startTest();
        PC_UserManagementApexcontroller.deactivateUser(con.Id, true);
        PC_UserManagementApexcontroller.updateUser(con.Id);
        PC_UserManagementApexcontroller.userActivation(con.Id);
        test.stopTest();
    }
    
    @isTest static void testupdateUser(){
        Contact con = [SELECT Id FROM Contact WHERE LastName='McTesty'];
        List<STring> ids = new List<String>();
        ids.add(con.Id);
        test.startTest();
        //PC_UserManagementApexcontroller.updateUser(ids);
        PC_UserManagementApexcontroller.updateUserActive(ids);
        test.stopTest();
    }
    
    @isTest static void testgetContactList(){
        User u = [SELECT Id FROM User WHERE LastName='McTesty'];
        test.startTest();
        System.runAs(u){
            PC_UserManagementApexcontroller.getContactList(10, 1, 'McT');
            PC_UserManagementApexcontroller.getContactList(10, 1, 'test541@r');
        }
        test.stopTest();
    }
    @isTest static void testupdateContact(){
        Contact con = [SELECT Id,Email,FirstName,LastName,Title,Phone FROM Contact WHERE LastName='McTesty'];
        test.startTest();
        PC_UserManagementApexcontroller.updateContact(con, true, true);
        PC_UserManagementApexcontroller.updateContact(con, true, false);
        test.stopTest();
    }
}