@isTest
private class CS_CaseSpecialHandlingMigrationBatchTest {
    /*test setup method for records insertion*/
    @testSetup
    static void setupTestData() {
        User u=TestDataFactory.getUser();
        u.email='testuser@testuser1.com';
        insert u;
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Case_Special_Handling_Edit_Access'];
        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.AssigneeId = u.Id;
        psa.PermissionSetId = ps.Id;
        insert psa;
        System.runAs(u) {
        List <Account> testAccounts = new List <Account> ();
        for (Integer i = 0; i < 20; i++) {
            testAccounts.add(new Account(Name = 'Test Account ' + i, Heads_Up_to_Support_Team__c = 'Test Message'));
        }
            insert testAccounts;
        }
    }

    @isTest
    static void testBatchExecution() {
        User u = [SELECT id, name from user where email ='testuser@testuser1.com'];
        System.runAs(u){
        Test.startTest();
        Database.executeBatch(new CS_CaseSpecialHandlingMigrationBatch(), 50);
        Test.stopTest();	
        Integer recordCount = [SELECT COUNT() FROM Case_Special_Handling__c Limit 20];
        System.assertEquals(20, recordCount, 'Expected 200 records to be inserted');
        }
    }

    @isTest
    static void testBatchWithNoAccounts() {
        User u = [SELECT id, name from user where email ='testuser@testuser1.com'];
        System.runAs(u){
        delete[SELECT Id FROM Account Limit 20];
        Test.startTest();
        Database.executeBatch(new CS_CaseSpecialHandlingMigrationBatch(), 50);
        Test.stopTest();
        Integer recordCount = [SELECT COUNT() FROM Case_Special_Handling__c Limit 20];
        System.assertEquals(0, recordCount, 'No records should be inserted if there are no accounts');
    }
    }

    @isTest
    static void testBatchWithExistingRecords() {
        User u = [SELECT id, name from user where email ='testuser@testuser1.com'];
        System.runAs(u){
        List <Case_Special_Handling__c> existingRecords = new List <Case_Special_Handling__c> ();
        for (Account a: [SELECT Id FROM Account LIMIT 5]) {
            existingRecords.add(new Case_Special_Handling__c(Account_Id__c = a.Id, Category__c = 'Support contract exceptions'));
        }
        insert existingRecords;

        Test.startTest();
        Database.executeBatch(new CS_CaseSpecialHandlingMigrationBatch('SELECT Id, Heads_Up_to_Support_Team__c FROM Account WHERE Id NOT IN (SELECT Account_Id__c FROM Case_Special_Handling__c)'), 50);
        Test.stopTest();

        Integer recordCount = [SELECT COUNT() FROM Case_Special_Handling__c Limit 20];
        System.assertEquals(20, recordCount, 'No new records should be inserted if there are existing records');
    }
    }
}