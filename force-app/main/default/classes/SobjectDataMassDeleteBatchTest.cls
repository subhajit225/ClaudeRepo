/**
 * @description Test class for SobjectDataMassDeleteBatch. Verifies constructor validations,
 *              batch start/execute behavior, and deletion outcomes across supported sObjects.
 * @isTest
 * @see SobjectDataMassDeleteBatch
 */
@IsTest
private class SobjectDataMassDeleteBatchTest {

    @TestSetup
    static void setupData(){
        // Create a System Administrator user and run the batch as that user.
        Profile sysAdminProfile = [
            SELECT Id, Name
            FROM Profile
            WHERE Name = 'System Administrator'
            LIMIT 1
        ];

        User adminUser = new User(
            Alias = 'tadmin',
            Email = 'sys.admin@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Admin',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'sys.admin.cp@example.com',
            ProfileId = sysAdminProfile.Id
        );
        insert adminUser;
    }

    /**
     * @description Utility method to create Account test data, and backdate CreatedDate
     *              to be before the provided cutoff date using Test.setCreatedDate.
     * @param count Number of Account records to create.
     * @param cutoff Cutoff date; created dates will be set to 2 days before this date.
     * @return List of inserted Account records.
     */
    private static List<Account> createTestAccounts(Integer count, Date cutoff) {
        List<Account> accts = new List<Account>();
        for(Integer i=0; i<count; i++) {
            accts.add(new Account(Name = 'TestAccount' + i));
        }
        insert accts;

        for(Account acc : accts) {
            Test.setCreatedDate(acc.Id, cutoff.addDays(-2));
        }
        return accts;
    }

    /**
     * @description Utility method to create Error_Logs__c test data, and backdate CreatedDate
     *              to be before the provided cutoff date using Test.setCreatedDate.
     * @param count Number of Error_Logs__c records to create.
     * @param cutoff Cutoff date; created dates will be set to 2 days before this date.
     * @return List of inserted Error_Logs__c records.
     */
    private static List<Error_Logs__c> createTestIntegrationLogs(Integer count, Date cutoff) {
        List<Error_Logs__c> errorLogs = new List<Error_Logs__c>();
        for(Integer i=0; i<count; i++) {
            errorLogs.add(new Error_Logs__c());
        }
        insert errorLogs;

        for(Error_Logs__c acc : errorLogs) {
            Test.setCreatedDate(acc.Id, cutoff.addDays(-2));
        }
        return errorLogs;
    }

    /**
     * @description Verifies constructor input validation for SobjectDataMassDeleteBatch,
     *              asserting exceptions on null/blank/invalid parameters and success on valid input.
     * @testMethod
     * @see SobjectDataMassDeleteBatch
     */
    @IsTest
    static void testConstructorValidations() {
        Date cutoff = Date.today();

        User adminUser = [SELECT ID FROM User WHERE Username = 'sys.admin.cp@example.com'];

        System.runAs(adminUser) {
            
            try {
                new SobjectDataMassDeleteBatch(null, cutoff);
                System.assert(false, 'Expected exception on null objectApiName');
            } catch (SobjectDataMassDeleteBatch.InvalidParameterException e) {
                System.assert(true);
            }
    
            try {
                new SobjectDataMassDeleteBatch('   ', cutoff);
                System.assert(false, 'Expected exception on blank objectApiName');
            } catch (SobjectDataMassDeleteBatch.InvalidParameterException e) {
                System.assert(true);
            }
    
            try {
                new SobjectDataMassDeleteBatch('Account', null);
                System.assert(false, 'Expected exception on null cutoffDate');
            } catch (SobjectDataMassDeleteBatch.InvalidParameterException e) {
                System.assert(true);
            }
    
            try {
                new SobjectDataMassDeleteBatch('Account', cutoff, null);
                System.assert(false, 'Expected exception on null emailRecipients');
            } catch (SobjectDataMassDeleteBatch.InvalidParameterException e) {
                System.assert(true);
            }
    
            try {
                new SobjectDataMassDeleteBatch('Account', cutoff, new List<String>());
                System.assert(false, 'Expected exception on empty emailRecipients');
            } catch (SobjectDataMassDeleteBatch.InvalidParameterException e) {
                System.assert(true);
            }
    
            try {
                new SobjectDataMassDeleteBatch('NonExistent__c', cutoff);
                System.assert(false, 'Expected exception on invalid objectApiName');
            } catch (SobjectDataMassDeleteBatch.InvalidParameterException e) {
                System.assert(true);
            }
        }
        // Valid constructor with default emailRecipients
        SobjectDataMassDeleteBatch batch = new SobjectDataMassDeleteBatch('Account', cutoff);
        System.assertNotEquals(null, batch, 'Batch should not be null');

    }

    /**
     * @description Ensures execute method deletes records older than cutoff for supported sObject
     *              (Error_Logs__c) and that failedRecordsCsvMap remains empty.
     * @testMethod
     * @see SobjectDataMassDeleteBatch#execute(Database.BatchableContext, List<sObject>)
     */
    @IsTest
    static void testBatchExecuteSuccessfullyDeletesData() {
        Date cutoff = Date.today();
        List<Error_Logs__c> errorLogs = createTestIntegrationLogs(4, cutoff);
        SobjectDataMassDeleteBatch batch;

        User adminUser = [SELECT ID FROM User WHERE Username = 'sys.admin.cp@example.com'];

        System.runAs(adminUser) {
            Test.startTest();
            batch = new SobjectDataMassDeleteBatch('Error_Logs__c', cutoff);
            Database.executeBatch(batch, 200);
            Test.stopTest();
        }


        Integer remaining = [SELECT COUNT() FROM Error_Logs__c WHERE Id IN :errorLogs];
        System.assertEquals(0, remaining, 'All Integration log record must be deleted');

        // failedRecordsCsvMap should be empty
        System.assertEquals(0, batch.failedRecordsCsvMap.size(), 'Failed record map size should be 0');
    }

    /**
     * @description Validates scenario where deletions are not permitted/expected for Account,
     *              confirming records remain and that count is greater than zero post batch run.
     * @testMethod
     * @see SobjectDataMassDeleteBatch#execute(Database.BatchableContext, List<sObject>)
     */
    @IsTest
    static void testBatchExecuteFailures() {
        Date cutoff = Date.today();
        List<Account> accounts = createTestAccounts(4, cutoff);

        User adminUser = [SELECT ID FROM User WHERE Username = 'sys.admin.cp@example.com'];

        System.runAs(adminUser) {
            Test.startTest();
            SobjectDataMassDeleteBatch batch = new SobjectDataMassDeleteBatch('Account', cutoff);
            Database.executeBatch(batch, 200);
             // failedRecordsCsvMap should be empty
            Test.stopTest();
        }

        Integer accountCount = [SELECT COUNT() FROM Account WHERE Id IN :accounts];

        // failedRecordsCsvMap should NOT be empty
        System.assertNotEquals(0, accountCount, 'Account count should be more than 0');
    }

    /**
     * @description Verifies the start method returns a non-null Database.QueryLocator for a valid
     *              configuration to ensure batchable query assembly is correct.
     * @testMethod
     * @see SobjectDataMassDeleteBatch#start(Database.BatchableContext)
     */
    @IsTest
    static void testStartReturnsQueryLocator() {
        Date cutoff = Date.today();
        SobjectDataMassDeleteBatch batch = new SobjectDataMassDeleteBatch('Account', cutoff);
        Database.QueryLocator locator;

        User adminUser = [SELECT ID FROM User WHERE Username = 'sys.admin.cp@example.com'];

        System.runAs(adminUser) {
            Test.startTest();
            locator = batch.start(null);
            Test.stopTest();
        }


        System.assert(locator != null);
    }
}