@isTest
private class AccountDataMigrationBatchTest {

    @isTest
    static void testBatchWithValidData() {
        List<Account> testAccounts = new List<Account>();

        for (Integer i = 0; i < 5; i++) {
            Account acc = new Account(
                Name = 'Test Account ' + i,
                DSCORGPKG__IT_Budget__c = 10000 + i
            );
            testAccounts.add(acc);
        }

        testAccounts.add(new Account(Name = 'Test Account No Budget'));

        insert testAccounts;

        Test.startTest();
        System.runAs([SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1][0]) {
         	AccountDataMigrationBatch batch = new AccountDataMigrationBatch();
            Database.executeBatch(batch);    
        }
        Test.stopTest();
        List<Account> updatedAccounts = [SELECT Id, IT_Budget__c, DSCORGPKG__IT_Budget__c 
                                         FROM Account 
                                         WHERE DSCORGPKG__IT_Budget__c != NULL];

        System.assertEquals(testAccounts[0].DSCORGPKG__IT_Budget__c, updatedAccounts[0].IT_Budget__c);

        
    }
}