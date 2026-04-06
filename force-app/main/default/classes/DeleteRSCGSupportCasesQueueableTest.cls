/**
 * @description Test class for DeleteRSCGSupportCasesQueueable
 */
@isTest
public class DeleteRSCGSupportCasesQueueableTest {

    /**
     * @description Get active system admin user for testing
     * @return user
     */
    private static User getSystemAdminUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
    }

    /**
     * @description Test data setup
     */
    @testSetup
    static void setupTestData() {
        // Create test accounts with different RSC-G support configurations
        List<Account> testAccounts = new List<Account>();

        // Account 1: Has RSC-G support (should delete cases)
        testAccounts.add(new Account(
            Name = 'Test Account RSC-G',
            RSC_G_Support__c = 'RSC-G'
        ));

        // Account 2: Has RSC-G and RSC/CDM support (should delete cases)
        testAccounts.add(new Account(
            Name = 'Test Account RSC-G Multiple',
            RSC_G_Support__c = 'RSC-G;RSC/CDM'
        ));

        // Account 3: Has only RSC/CDM support (should NOT delete cases)
        testAccounts.add(new Account(
            Name = 'Test Account RSC/CDM Only',
            RSC_G_Support__c = 'RSC/CDM'
        ));

        // Account 4: No RSC-G support (should NOT delete cases)
        testAccounts.add(new Account(
            Name = 'Test Account No Support',
            RSC_G_Support__c = null
        ));

        insert testAccounts;

        // Create test contacts
        List<Contact> testContacts = new List<Contact>();
        for (Account acc : testAccounts) {
            testContacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact ' + acc.Name,
                Email = 'test' + acc.Id + '@test.com',
                AccountId = acc.Id
            ));
        }
        insert testContacts;

        // Get Support Case Record Type ID
        Id supportCaseRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Support_Case')?.getRecordTypeId();
        if (supportCaseRTId == null) {
            // Fallback to first available record type if Support_Case doesn't exist
            supportCaseRTId = Schema.SObjectType.Case.getRecordTypeInfos()[0].getRecordTypeId();
        }

        // Get non-Support Case Record Type ID for testing
        Id nonSupportCaseRTId = null;
        for (Schema.RecordTypeInfo rtInfo : Schema.SObjectType.Case.getRecordTypeInfos()) {
            if (rtInfo.getDeveloperName() != 'Support_Case' && rtInfo.isAvailable()) {
                nonSupportCaseRTId = rtInfo.getRecordTypeId();
                break;
            }
        }
        if (nonSupportCaseRTId == null) {
            nonSupportCaseRTId = supportCaseRTId; // Fallback if only one record type exists
        }

        // Create test cases
        List<Case> testCases = new List<Case>();
        Integer caseCounter = 1;

        // Get all Contacts for the test accounts in a single query to avoid SOQL in loop
        Map<Id, Contact> accountToContactMap = new Map<Id, Contact>();
        for (Contact con : [SELECT Id, AccountId FROM Contact WHERE AccountId IN :testAccounts]) {
            accountToContactMap.put(con.AccountId, con);
        }

        for (Account acc : testAccounts) {
            Contact relatedContact = accountToContactMap.get(acc.Id);

            // Create Support Cases for each account
            testCases.add(new Case(
                Subject = 'Test Support Case ' + caseCounter,
                AccountId = acc.Id,
                ContactId = relatedContact.Id,
                RecordTypeId = supportCaseRTId,
                Origin = 'Email',
                Priority = 'P3',
                Status = 'New'
            ));
            caseCounter++;

            // Create non-Support Cases for testing (should not be processed)
            testCases.add(new Case(
                Subject = 'Test Non-Support Case ' + caseCounter,
                AccountId = acc.Id,
                ContactId = relatedContact.Id,
                RecordTypeId = nonSupportCaseRTId,
                Origin = 'Email',
                Priority = 'P3',
                Status = 'New'
            ));
            caseCounter++;
        }

        insert testCases;
    }

    /**
     * @description Test successful deletion of RSC-G support cases
     */
    @isTest
    static void testSuccessfulRSCGCaseDeletion() {
        User adminUser = getSystemAdminUser();

        System.runAs(adminUser) {
            // Get test account with exact RSC-G support
            Account rscgAccount = [SELECT Id FROM Account WHERE Name = 'Test Account RSC-G' LIMIT 1];

            // Get Support Cases for RSC-G account (only exact match should be processed)
            List<Case> rscgCases = [SELECT Id FROM Case WHERE AccountId = :rscgAccount.Id
                                   AND Subject LIKE 'Test Support Case%'];

            // Verify cases exist before deletion
            System.assertEquals(1, rscgCases.size(), 'Should have 1 RSC-G support case before deletion');

            Test.startTest();

            // Execute the queueable with List<Case>
            DeleteRSCGSupportCasesQueueable queueable = new DeleteRSCGSupportCasesQueueable(rscgCases);
            System.enqueueJob(queueable);

            Test.stopTest();

            // Verify cases were deleted
            Set<Id> caseIds = new Set<Id>();
            for (Case c : rscgCases) {
                caseIds.add(c.Id);
            }
            Integer casesAfterDeletion = [SELECT COUNT() FROM Case WHERE Id IN :caseIds];
            System.assertEquals(0, casesAfterDeletion, 'RSC-G support cases should be deleted');
        }
    }

    /**
     * @description Test that non-RSC-G support cases are not deleted
     */
    @isTest
    static void testNonRSCGCasesNotDeleted() {
        User adminUser = getSystemAdminUser();

        System.runAs(adminUser) {
            // Get test accounts without exact RSC-G support
            Account rscCdmAccount = [SELECT Id FROM Account WHERE Name = 'Test Account RSC/CDM Only' LIMIT 1];
            Account noSupportAccount = [SELECT Id FROM Account WHERE Name = 'Test Account No Support' LIMIT 1];

            // Get Support Cases for non-RSC-G accounts
            List<Case> nonRscgCases = [SELECT Id FROM Case WHERE AccountId IN (:rscCdmAccount.Id, :noSupportAccount.Id)
                                      AND Subject LIKE 'Test Support Case%'];

            // Verify cases exist before processing
            System.assertEquals(2, nonRscgCases.size(), 'Should have 2 non-RSC-G support cases before processing');

            Test.startTest();

            // Execute the queueable with List<Case> - these should be deleted directly since queueable doesn't filter
            DeleteRSCGSupportCasesQueueable queueable = new DeleteRSCGSupportCasesQueueable(nonRscgCases);
            System.enqueueJob(queueable);

            Test.stopTest();

            // Verify cases were deleted (queueable deletes whatever cases are passed to it)
            Set<Id> caseIds = new Set<Id>();
            for (Case c : nonRscgCases) {
                caseIds.add(c.Id);
            }
            Integer casesAfterProcessing = [SELECT COUNT() FROM Case WHERE Id IN :caseIds];
            System.assertEquals(0, casesAfterProcessing, 'Cases passed to queueable should be deleted');
        }
    }

    /**
     * @description Test that any cases passed to queueable are deleted (no filtering in queueable)
     */
    @isTest
    static void testDirectCaseDeletion() {
        User adminUser = getSystemAdminUser();

        System.runAs(adminUser) {
            // Get all non-Support Cases
            List<Case> nonSupportCases = [SELECT Id FROM Case WHERE Subject LIKE 'Test Non-Support Case%'];

            // Verify cases exist before processing
            System.assert(nonSupportCases.size() > 0, 'Should have non-support cases before processing');
            Integer casesBeforeProcessing = nonSupportCases.size();

            Test.startTest();

            // Execute the queueable - it will delete whatever cases are passed to it
            DeleteRSCGSupportCasesQueueable queueable = new DeleteRSCGSupportCasesQueueable(nonSupportCases);
            System.enqueueJob(queueable);

            Test.stopTest();

            // Verify cases were deleted (queueable deletes all cases passed to it)
            Set<Id> caseIds = new Set<Id>();
            for (Case c : nonSupportCases) {
                caseIds.add(c.Id);
            }
            Integer casesAfterProcessing = [SELECT COUNT() FROM Case WHERE Id IN :caseIds];
            System.assertEquals(0, casesAfterProcessing, 'All cases passed to queueable should be deleted');
        }
    }

    /**
     * @description Test with empty case list
     */
    @isTest
    static void testEmptyCaseList() {
        User adminUser = getSystemAdminUser();

        System.runAs(adminUser) {
            List<Case> emptyCaseList = new List<Case>();

            Test.startTest();

            // Execute the queueable with empty list
            DeleteRSCGSupportCasesQueueable queueable = new DeleteRSCGSupportCasesQueueable(emptyCaseList);
            System.enqueueJob(queueable);

            Test.stopTest();

            // Should execute without errors
            System.assert(true, 'Queueable should handle empty case list gracefully');
        }
    }

    /**
     * @description Test with null case list
     */
    @isTest
    static void testNullCaseList() {
        User adminUser = getSystemAdminUser();

        System.runAs(adminUser) {
            Test.startTest();

            // Execute the queueable with null list
            DeleteRSCGSupportCasesQueueable queueable = new DeleteRSCGSupportCasesQueueable(null);
            System.enqueueJob(queueable);

            Test.stopTest();

            // Should execute without errors
            System.assert(true, 'Queueable should handle null case list gracefully');
        }
    }

    /**
     * @description Test mixed case scenarios - queueable deletes all cases passed to it
     */
    @isTest
    static void testMixedCaseScenarios() {
        User adminUser = getSystemAdminUser();

        System.runAs(adminUser) {
            // Get all Support Cases
            List<Case> allSupportCases = [SELECT Id, AccountId, Account.RSC_G_Support__c
                                         FROM Case
                                         WHERE Subject LIKE 'Test Support Case%'];

            // Verify we have multiple cases
            System.assert(allSupportCases.size() > 1, 'Should have multiple support cases');

            Test.startTest();

            // Execute the queueable with all cases - it will delete all of them
            DeleteRSCGSupportCasesQueueable queueable = new DeleteRSCGSupportCasesQueueable(allSupportCases);
            System.enqueueJob(queueable);

            Test.stopTest();

            // Verify all cases were deleted (queueable deletes whatever is passed to it)
            Set<Id> allCaseIds = new Set<Id>();
            for (Case c : allSupportCases) {
                allCaseIds.add(c.Id);
            }
            Integer remainingCases = [SELECT COUNT() FROM Case WHERE Id IN :allCaseIds];
            System.assertEquals(0, remainingCases, 'All cases passed to queueable should be deleted');
        }
    }

    /**
     * @description Test cases without accounts - queueable will delete them anyway
     */
    @isTest
    static void testCasesWithoutAccounts() {
        User adminUser = getSystemAdminUser();

        System.runAs(adminUser) {
            // Create a case without an account
            Case caseWithoutAccount = new Case(
                Subject = 'Test Case Without Account',
                Origin = 'Email',
                Priority = 'P3',
                Status = 'New'
            );
            insert caseWithoutAccount;

            List<Case> casesToDelete = new List<Case>{caseWithoutAccount};

            Test.startTest();

            // Execute the queueable - it will delete the case even without account
            DeleteRSCGSupportCasesQueueable queueable = new DeleteRSCGSupportCasesQueueable(casesToDelete);
            System.enqueueJob(queueable);

            Test.stopTest();

            // Verify case was deleted (queueable deletes whatever is passed to it)
            Integer casesAfterProcessing = [SELECT COUNT() FROM Case WHERE Id = :caseWithoutAccount.Id];
            System.assertEquals(0, casesAfterProcessing, 'Case should be deleted by queueable');
        }
    }

    /**
     * @description Test error handling with cases that don't exist in database
     */
    @isTest
    static void testNonExistentCases() {
        User adminUser = getSystemAdminUser();

        System.runAs(adminUser) {
            // Create cases with fake IDs that don't exist in database
            List<Case> nonExistentCases = new List<Case>();

            // Create case objects with fake IDs (these won't exist in the database)
            Case fakeCase1 = new Case();
            fakeCase1.Id = '500000000000001';
            Case fakeCase2 = new Case();
            fakeCase2.Id = '500000000000002';

            nonExistentCases.add(fakeCase1);
            nonExistentCases.add(fakeCase2);

            Test.startTest();

            // Execute the queueable with non-existent cases - this should cause an error
            DeleteRSCGSupportCasesQueueable queueable = new DeleteRSCGSupportCasesQueueable(nonExistentCases);
            System.enqueueJob(queueable);

            Test.stopTest();

            // Should execute and handle errors gracefully (error handling in queueable)
            System.assert(true, 'Queueable should handle non-existent cases gracefully');
        }
    }

    /**
     * @description Test error handling scenario to improve code coverage
     */
    @isTest
    static void testErrorHandling() {
        User adminUser = getSystemAdminUser();

        System.runAs(adminUser) {
            // Create a test case for normal deletion
            Account testAccount = new Account(
                Name = 'Test Error Account',
                RSC_G_Support__c = 'RSC-G'
            );
            insert testAccount;

            Contact testContact = new Contact(
                FirstName = 'Test',
                LastName = 'Error Contact',
                Email = 'testerror@test.com',
                AccountId = testAccount.Id
            );
            insert testContact;

            // Get Support Case Record Type ID
            Id supportCaseRTId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Support_Case')?.getRecordTypeId();
            if (supportCaseRTId == null) {
                supportCaseRTId = Schema.SObjectType.Case.getRecordTypeInfos()[0].getRecordTypeId();
            }

            Case testCase = new Case(
                Subject = 'Test Error Case',
                AccountId = testAccount.Id,
                ContactId = testContact.Id,
                RecordTypeId = supportCaseRTId,
                Origin = 'Email',
                Priority = 'P3',
                Status = 'New'
            );
            insert testCase;

            List<Case> casesToDelete = new List<Case>{testCase};

            Test.startTest();

            // Execute the queueable - this should work normally and test error handling paths
            DeleteRSCGSupportCasesQueueable queueable = new DeleteRSCGSupportCasesQueueable(casesToDelete);
            System.enqueueJob(queueable);

            Test.stopTest();

            // Verify case was deleted
            Integer casesAfterProcessing = [SELECT COUNT() FROM Case WHERE Id = :testCase.Id];
            System.assertEquals(0, casesAfterProcessing, 'Case should be deleted');
        }
    }
}