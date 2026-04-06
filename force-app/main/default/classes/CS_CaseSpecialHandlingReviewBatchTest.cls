@IsTest
public class CS_CaseSpecialHandlingReviewBatchTest {
    /*Test method for setup*/
    @testsetup
    private static void testSetup() {
        User usr=TestDataFactory.getUser();
        usr.email='testuser@testuser1.com';
        insert usr;
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Case_Special_Handling_Edit_Access'];
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = usr.Id;
        psa.PermissionSetId = ps.Id;
        insert psa;
        List <User> userList = new List <User> ();
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Rubrik Light Administrator' LIMIT 1].id;
        for (Integer i = 0; i < 3; i++) {
            User newUser = new User(
                LastName = 'User' + i,
                Email = 'user' + i + '@test.com.invalid',
                Username = 'user' + i + '@rubrikdevtest.com.invalid',
                Alias = 'usr' + i,
                ProfileId = profileId,
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                TimeZoneSidKey = 'America/Los_Angeles'
            );
            userList.add(newUser);
        }
        insert userList;
        List<PermissionSetAssignment> pList=new List<PermissionSetAssignment> ();
        for(user u:userList){
            PermissionSetAssignment psa2 = new PermissionSetAssignment();
            psa2.AssigneeId = u.Id;
            psa2.PermissionSetId = ps.Id;
            pList.add(psa2);
        }
        insert pList;
        user u = userList[0];
        u.ManagerId = UserList[1].Id;
        update u;
        user u2 = userList[1];
        u2.ManagerId = UserList[2].Id;
        update u2;
        System.runAs(u) {
            Account acc = new Account(name = 'test', Heads_Up_to_Support_Team__c = 'Test',Account_SAM__c= u2.id);
            insert acc;
            Account acc2 = new Account(name = 'test2', Heads_Up_to_Support_Team__c = 'Test2');
            insert acc2;
            insert new List <Case_Special_Handling__c> {
                new Case_Special_Handling__c(Account_Id__c = acc.Id, Valid_Until__c = System.today().addDays(-45), Message__c = 'Test', Category__c = 'Darksite information'),
                new Case_Special_Handling__c(Account_Id__c = acc2.Id, Valid_Until__c = System.today().addDays(-45), Message__c = 'Test', Auto_Archive__c = true, Category__c = 'Darksite information')
            };
        }
    }
    
    @isTest static void testMethodActive() {
        User u = [SELECT id, name from user where email ='testuser@testuser1.com'];
        System.runAs(u){
        Test.startTest();
        Database.executeBatch(new CS_CaseSpecialHandlingReviewBatch());
        Test.stopTest();
        Assert.isTrue([SELECT Id, Is_Archived__c FROM Case_Special_Handling__c WHERE Auto_Archive__c = true].Is_Archived__c, 'Accounts should have been archived');
        }
    }
}