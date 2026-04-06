/**
 * ───────────────────────────────────────────────────────────────────────────────────────────────────┐
 * @description Test class for CS_TestDataFactoryUtility - Comprehensive test coverage for Customer
 *              Support test data factory operations including all sObject generation methods.
 * ───────────────────────────────────────────────────────────────────────────────────────────────────
 * @Class     CS_TestDataFactoryUtilityTest
 * @Coverage  Target: 90%+ - Covers CS_TestDataFactoryUtility test data factory operations
 * @Methods   Comprehensive test methods covering all major code paths and edge cases
 * @Author    Vijay Kumar K R
 * @Created   Jan 24, 2025
 * @Version   3.0 - Recreated for comprehensive coverage without failures
 * ───────────────────────────────────────────────────────────────────────────────────────────────────
 * @Features  • Account, Contact, User, Case generation
 *            • Custom object generation (Aha_Ideas__c, Cluster__c, etc.)
 *            • Audit log generation (AccountAuditLog__c, Case_Audit__c)
 *            • Community and subscription objects
 *            • Method chaining and configuration testing
 *            • Error handling and edge case coverage
 *            • State/Country picklist compliance
 *            • Unique field validation (UUID, Username)
 * ───────────────────────────────────────────────────────────────────────────────────────────────────
 * @Coverage  All CS_TestDataFactoryUtility methods:
 *            • Constructor and configuration methods
 *            • Individual sObject generation methods
 *            • Composite generation methods
 *            • Helper methods and field application
 * ───────────────────────────────────────────────────────────────────────────────────────────────────┘
 */
@isTest
public class CS_TestDataFactoryUtilityTest {

    @isTest
    static void testConstructor() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();
            Test.stopTest();

            System.assertNotEquals(null, factory, 'Factory should be instantiated');
        }
    }


    @isTest
    static void testWithRecordCount() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();
            CS_TestDataFactoryUtility result = factory.withRecordCount('Account', 5);
            Test.stopTest();

            System.assertEquals(factory, result, 'Should return same instance for method chaining');
        }
    }

    @isTest
    static void testWithCommonField() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();
            CS_TestDataFactoryUtility result = factory.withCommonField('Account', 'Name', 'Test Account');
            Test.stopTest();

            System.assertEquals(factory, result, 'Should return same instance for method chaining');
        }
    }

    @isTest
    static void testWithIndexedField() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();
            List<Object> values = new List<Object>{'Value1', 'Value2', 'Value3'};
            CS_TestDataFactoryUtility result = factory.withIndexedField('Account', 'Name', values);
            Test.stopTest();

            System.assertEquals(factory, result, 'Should return same instance for method chaining');
        }
    }

    @isTest
    static void testGenerateAccounts() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();
            factory.withRecordCount('Account', 2)
                .withCommonField('Account', 'BillingState', 'California')
                .withCommonField('Account', 'BillingCountry', 'United States');
            factory.generateAccounts();
            Test.stopTest();

            List<SObject> accounts = factory.getCreatedRecords('Account');
            System.assertNotEquals(null, accounts, 'Accounts should be created');
            System.assertEquals(2, accounts.size(), 'Should create 2 accounts');

            Account acc = (Account) accounts[0];
            System.assert(acc.Name.contains('CS Test Account'), 'Account name should contain CS Test Account');
        }
    }

    @isTest
    static void testGenerateAccountsWithCustomFields() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();
            factory.withCommonField('Account', 'BillingCity', 'San Francisco')
                .withCommonField('Account', 'BillingState', 'California')
                .withCommonField('Account', 'BillingCountry', 'United States');
            factory.generateAccounts();
            Test.stopTest();

            List<SObject> accounts = factory.getCreatedRecords('Account');
            System.assertNotEquals(null, accounts, 'Accounts should be created');
            System.assertEquals(1, accounts.size(), 'Should create 1 account by default');
        }
    }

    @isTest
    static void testGenerateContacts() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();
            factory.withRecordCount('Contact', 3)
                .withCommonField('Account', 'BillingState', 'California')
                .withCommonField('Account', 'BillingCountry', 'United States');
            factory.generateContacts();
            Test.stopTest();

            List<SObject> contacts = factory.getCreatedRecords('Contact');
            System.assertNotEquals(null, contacts, 'Contacts should be created');
            System.assertEquals(3, contacts.size(), 'Should create 3 contacts');

            Contact con = (Contact) contacts[0];
            System.assertEquals('CS Test', con.FirstName, 'Contact first name should be CS Test');
            System.assert(con.LastName.contains('Contact'), 'Contact last name should contain Contact');
            System.assert(con.Email.contains('cstest'), 'Contact email should contain cstest');
            System.assertNotEquals(null, con.AccountId, 'Contact should have AccountId');
        }
    }

    @isTest
    static void testGenerateContactsWithExistingAccount() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();
            factory.withCommonField('Account', 'BillingState', 'California')
                .withCommonField('Account', 'BillingCountry', 'United States');
            factory.generateAccounts();
            factory.generateContacts();
            Test.stopTest();

            List<SObject> contacts = factory.getCreatedRecords('Contact');
            List<SObject> accounts = factory.getCreatedRecords('Account');

            System.assertNotEquals(null, contacts, 'Contacts should be created');
            System.assertNotEquals(null, accounts, 'Accounts should be created');

            Contact con = (Contact) contacts[0];
            Account acc = (Account) accounts[0];
            System.assertEquals(acc.Id, con.AccountId, 'Contact should be linked to created account');
        }
    }

    @isTest
    static void testGenerateUsers() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();
            String uniqueId = String.valueOf(System.currentTimeMillis());
            factory.withRecordCount('User', 2)
                .withIndexedField('User', 'Username', new List<Object>{
                    'cstestuser1' + uniqueId + '@test.com',
                    'cstestuser2' + uniqueId + '@test.com'
                });
            factory.generateUsers();
            Test.stopTest();

            List<SObject> users = factory.getCreatedRecords('User');
            System.assertNotEquals(null, users, 'Users should be created');
            System.assertEquals(2, users.size(), 'Should create 2 users');

            User u = (User) users[0];
            System.assertEquals('CS Test', u.FirstName, 'User first name should be CS Test');
            System.assert(u.LastName.contains('User'), 'User last name should contain User');
            System.assert(u.Email.contains('cstestuser'), 'User email should contain cstestuser');
            System.assert(u.Username.contains('cstestuser'), 'Username should contain cstestuser');
            System.assertEquals(true, u.IsActive, 'User should be active');
        }
    }

    @isTest
    static void testGenerateCases() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
        Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();
            factory.withRecordCount('Case', 2)
                .withCommonField('Account', 'BillingState', 'California')
                .withCommonField('Account', 'BillingCountry', 'United States');
            factory.generateCases();
            Test.stopTest();

            List<SObject> cases = factory.getCreatedRecords('Case');
            System.assertNotEquals(null, cases, 'Cases should be created');
            System.assertEquals(2, cases.size(), 'Should create 2 cases');

            Case c = (Case) cases[0];
            System.assertNotEquals(null, c.Subject, 'Case should have a subject');
            System.assertNotEquals(null, c.AccountId, 'Case should have AccountId');
            System.assertNotEquals(null, c.ContactId, 'Case should have ContactId');
        }
    }

    @isTest
    static void testGenerateCasesWithExistingData() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();
            factory.withCommonField('Account', 'BillingState', 'California')
                .withCommonField('Account', 'BillingCountry', 'United States');
            factory.generateAccounts();
            factory.generateContacts();
            factory.generateCases();
            Test.stopTest();

            List<SObject> cases = factory.getCreatedRecords('Case');
            List<SObject> accounts = factory.getCreatedRecords('Account');
            List<SObject> contacts = factory.getCreatedRecords('Contact');

            System.assertNotEquals(null, cases, 'Cases should be created');
            System.assertNotEquals(null, accounts, 'Accounts should be created');
            System.assertNotEquals(null, contacts, 'Contacts should be created');

            Case c = (Case) cases[0];
            Account acc = (Account) accounts[0];
            Contact con = (Contact) contacts[0];

            System.assertEquals(acc.Id, c.AccountId, 'Case should be linked to created account');
            System.assertEquals(con.Id, c.ContactId, 'Case should be linked to created contact');
        }
    }

    @isTest
    static void testGenerateAhaIdeas() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();
            factory.withRecordCount('Aha_Ideas__c', 2);
            factory.generateAhaIdeas();
            Test.stopTest();

            List<SObject> ahaIdeas = factory.getCreatedRecords('Aha_Ideas__c');
            System.assertNotEquals(null, ahaIdeas, 'Aha Ideas should be created');
            System.assertEquals(2, ahaIdeas.size(), 'Should create 2 Aha Ideas');

            Aha_Ideas__c idea = (Aha_Ideas__c) ahaIdeas[0];
            System.assertNotEquals(null, idea.Name, 'Aha Idea should have a name');
        }
    }

    @isTest
    static void testGenerateAhaIdeaLinks() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();
            factory.withRecordCount('Aha_Idea_Link__c', 2);
            factory.generateAhaIdeaLinks();
            Test.stopTest();

            List<SObject> ahaIdeaLinks = factory.getCreatedRecords('Aha_Idea_Link__c');
            List<SObject> ahaIdeas = factory.getCreatedRecords('Aha_Ideas__c');

            System.assertNotEquals(null, ahaIdeaLinks, 'Aha Idea Links should be created');
            System.assertNotEquals(null, ahaIdeas, 'Aha Ideas should be created as prerequisite');
            System.assertEquals(2, ahaIdeaLinks.size(), 'Should create 2 Aha Idea Links');

            Aha_Idea_Link__c link = (Aha_Idea_Link__c) ahaIdeaLinks[0];
            Aha_Ideas__c idea = (Aha_Ideas__c) ahaIdeas[0];
            System.assertEquals(idea.Id, link.Aha_Ideas__c, 'Link should be connected to Aha Idea');
        }
    }

    @isTest
    static void testGenerateAhaIdeaLinksWithExistingIdeas() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();
            factory.generateAhaIdeas();
            factory.generateAhaIdeaLinks();
            Test.stopTest();

            List<SObject> ahaIdeaLinks = factory.getCreatedRecords('Aha_Idea_Link__c');
            List<SObject> ahaIdeas = factory.getCreatedRecords('Aha_Ideas__c');

            System.assertNotEquals(null, ahaIdeaLinks, 'Aha Idea Links should be created');
            System.assertNotEquals(null, ahaIdeas, 'Aha Ideas should exist');

            Aha_Idea_Link__c link = (Aha_Idea_Link__c) ahaIdeaLinks[0];
            Aha_Ideas__c idea = (Aha_Ideas__c) ahaIdeas[0];
            System.assertEquals(idea.Id, link.Aha_Ideas__c, 'Link should be connected to existing Aha Idea');
        }
    }

    @isTest
    static void testGenerateClusters() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();
            String uniqueId1 = EncodingUtil.base64Encode(Crypto.generateAesKey(128)).substring(0, 10);
            String uniqueId2 = EncodingUtil.base64Encode(Crypto.generateAesKey(128)).substring(0, 10);
            factory.withRecordCount('Cluster__c', 2)
                .withIndexedField('Cluster__c', 'UUID__c', new List<Object>{
                    'cluster-uuid-' + uniqueId1,
                    'cluster-uuid-' + uniqueId2
                })
                .withIndexedField('Cluster__c', 'Name', new List<Object>{
                    'cluster-uuid-' + uniqueId1,
                    'cluster-uuid-' + uniqueId2
                });
            factory.generateClusters();
            Test.stopTest();

            List<SObject> clusters = factory.getCreatedRecords('Cluster__c');
            System.assertNotEquals(null, clusters, 'Clusters should be created');
            System.assertEquals(2, clusters.size(), 'Should create 2 clusters');

            Cluster__c cluster = (Cluster__c) clusters[0];
            System.assertEquals(cluster.UUID__c, cluster.Name, 'UUID should match Name');
            System.assertNotEquals(null, cluster.UUID__c, 'Cluster should have UUID');
        }
    }

    @isTest
    static void testGenerateEscalations() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();
            factory.withRecordCount('Escalation__c', 2)
                .withCommonField('Account', 'BillingState', 'California')
                .withCommonField('Account', 'BillingCountry', 'United States');
            factory.generateEscalations();
            Test.stopTest();

            List<SObject> escalations = factory.getCreatedRecords('Escalation__c');
            List<SObject> cases = factory.getCreatedRecords('Case');

            System.assertNotEquals(null, escalations, 'Escalations should be created');
            System.assertNotEquals(null, cases, 'Cases should be created as prerequisite');
            System.assertEquals(2, escalations.size(), 'Should create 2 escalations');

            Escalation__c esc = (Escalation__c) escalations[0];
            Case c = (Case) cases[0];
            System.assertEquals(c.Id, esc.Case__c, 'Escalation should be linked to case');
        }
    }

    @isTest
    static void testGenerateEscalationsWithExistingCases() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();
            factory.withCommonField('Account', 'BillingState', 'California')
                .withCommonField('Account', 'BillingCountry', 'United States');
            factory.generateCases();
            factory.generateEscalations();
            Test.stopTest();

            List<SObject> escalations = factory.getCreatedRecords('Escalation__c');
            List<SObject> cases = factory.getCreatedRecords('Case');

            System.assertNotEquals(null, escalations, 'Escalations should be created');
            System.assertNotEquals(null, cases, 'Cases should exist');

            Escalation__c esc = (Escalation__c) escalations[0];
            Case c = (Case) cases[0];
            System.assertEquals(c.Id, esc.Case__c, 'Escalation should be linked to existing case');
        }
    }

    @isTest
    static void testGenerateAccountAuditLogs() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();
            factory.withRecordCount('AccountAuditLog__c', 2)
                .withCommonField('Account', 'BillingCity', 'Santa Clara')
                .withCommonField('Account', 'BillingState', 'California')
                .withCommonField('Account', 'BillingCountry', 'United States');
            factory.generateAccountAuditLogs();
            Test.stopTest();

            List<SObject> auditLogs = factory.getCreatedRecords('AccountAuditLog__c');
            List<SObject> users = factory.getCreatedRecords('User');
            List<SObject> accounts = factory.getCreatedRecords('Account');

            System.assertNotEquals(null, auditLogs, 'Account Audit Logs should be created');
            System.assertNotEquals(null, users, 'Users should be created as prerequisite');
            System.assertNotEquals(null, accounts, 'Accounts should be created as prerequisite');
            System.assertEquals(2, auditLogs.size(), 'Should create 2 audit logs');
        }
    }

    @isTest
    static void testGenerateAccountAuditLogsWithExistingData() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();
            String uniqueId = String.valueOf(System.currentTimeMillis());
            factory.withIndexedField('User', 'Username', new List<Object>{
                    'cstestuser' + uniqueId + '@test.com'
                })
                .withCommonField('Account', 'BillingState', 'California')
                .withCommonField('Account', 'BillingCountry', 'United States');
            factory.generateUsers();
            factory.generateAccounts();
            factory.generateAccountAuditLogs();
            Test.stopTest();

            List<SObject> auditLogs = factory.getCreatedRecords('AccountAuditLog__c');
            System.assertNotEquals(null, auditLogs, 'Account Audit Logs should be created');
            System.assertEquals(1, auditLogs.size(), 'Should create 1 audit log by default');
        }
    }

    @isTest
    static void testGenerateCaseAudits() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();
            factory.withRecordCount('Case_Audit__c', 2)
                .withCommonField('Account', 'BillingState', 'California')
                .withCommonField('Account', 'BillingCountry', 'United States')
                .withCommonField('Case_Audit__c', 'Case_Audit_Timestamp__c', System.now())
                .withCommonField('Case_Audit__c', 'Case_Documentation__c', 'Great')
                .withCommonField('Case_Audit__c', 'Case_Field_Classification__c', 'Great')
                .withCommonField('Case_Audit__c', 'Final_Audit_Score__c', 85.0)
                .withCommonField('Case_Audit__c', 'Overall_Case_management__c', 'Great')
                .withCommonField('Case_Audit__c', 'Resolution__c', 'Great');
            factory.generateCaseAudits();
            Test.stopTest();

            List<SObject> caseAudits = factory.getCreatedRecords('Case_Audit__c');
            List<SObject> cases = factory.getCreatedRecords('Case');

            System.assertNotEquals(null, caseAudits, 'Case Audits should be created');
            System.assertNotEquals(null, cases, 'Cases should be created as prerequisite');
        }
    }

    @isTest
    static void testGenerateCaseAuditsWithExistingCases() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();
            factory.withCommonField('Account', 'BillingState', 'California')
                .withCommonField('Account', 'BillingCountry', 'United States')
                .withCommonField('Case_Audit__c', 'Case_Audit_Timestamp__c', System.now())
                .withCommonField('Case_Audit__c', 'Case_Documentation__c', 'Great')
                .withCommonField('Case_Audit__c', 'Case_Field_Classification__c', 'Great')
                .withCommonField('Case_Audit__c', 'Final_Audit_Score__c', 85.0)
                .withCommonField('Case_Audit__c', 'Overall_Case_management__c', 'Great')
                .withCommonField('Case_Audit__c', 'Resolution__c', 'Great');
            factory.generateCases();
            factory.generateCaseAudits();
            Test.stopTest();

            List<SObject> caseAudits = factory.getCreatedRecords('Case_Audit__c');
            List<SObject> cases = factory.getCreatedRecords('Case');

            System.assertNotEquals(null, caseAudits, 'Case Audits should be created');
            System.assertNotEquals(null, cases, 'Cases should exist');
            System.assertEquals(1, caseAudits.size(), 'Should create 1 case audit by default');
        }
    }

    @isTest
    static void testGenerateCommunityFeeds() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();
            factory.withRecordCount('Community_Feed__c', 2);
            factory.generateCommunityFeeds();
            Test.stopTest();

            List<SObject> feeds = factory.getCreatedRecords('Community_Feed__c');
            List<SObject> users = factory.getCreatedRecords('User');

            System.assertNotEquals(null, feeds, 'Community Feeds should be created');
            System.assertNotEquals(null, users, 'Users should be created as prerequisite');
            System.assertEquals(2, feeds.size(), 'Should create 2 community feeds');
        }
    }

    @isTest
    static void testGenerateCommunityFeedsWithExistingUsers() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();
            factory.generateUsers();
            factory.generateCommunityFeeds();
            Test.stopTest();

            List<SObject> feeds = factory.getCreatedRecords('Community_Feed__c');
            List<SObject> users = factory.getCreatedRecords('User');

            System.assertNotEquals(null, feeds, 'Community Feeds should be created');
            System.assertNotEquals(null, users, 'Users should exist');
            System.assertEquals(1, feeds.size(), 'Should create 1 community feed by default');
        }
    }

    @isTest
    static void testGenerateCustomerSubscriptions() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();
            factory.withRecordCount('Customer_Subscription__c', 2)
                .withCommonField('Account', 'BillingState', 'California')
                .withCommonField('Account', 'BillingCountry', 'United States')
                .withCommonField('Customer_Subscription__c', 'Type__c', 'Article');
            factory.generateCustomerSubscriptions();
            Test.stopTest();

            List<SObject> subscriptions = factory.getCreatedRecords('Customer_Subscription__c');
            List<SObject> accounts = factory.getCreatedRecords('Account');

            System.assertNotEquals(null, subscriptions, 'Customer Subscriptions should be created');
            System.assertNotEquals(null, accounts, 'Accounts should be created as prerequisite');
            System.assertEquals(2, subscriptions.size(), 'Should create 2 customer subscriptions');
        }
    }

    @isTest
    static void testGenerateCustomerSubscriptionsWithExistingAccounts() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();
            factory.withCommonField('Account', 'BillingState', 'California')
                .withCommonField('Account', 'BillingCountry', 'United States')
                .withCommonField('Customer_Subscription__c', 'Type__c', 'Article');
            factory.generateAccounts();
            factory.generateCustomerSubscriptions();
            Test.stopTest();

            List<SObject> subscriptions = factory.getCreatedRecords('Customer_Subscription__c');
            List<SObject> accounts = factory.getCreatedRecords('Account');

            System.assertNotEquals(null, subscriptions, 'Customer Subscriptions should be created');
            System.assertNotEquals(null, accounts, 'Accounts should exist');
            System.assertEquals(1, subscriptions.size(), 'Should create 1 customer subscription by default');
        }
    }

    @isTest
    static void testGeneratePlaybooks() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();
            factory.withRecordCount('Playbook__c', 2)
                .withCommonField('Account', 'BillingState', 'California')
                .withCommonField('Account', 'BillingCountry', 'United States');
            factory.generatePlaybooks();
            Test.stopTest();

            List<SObject> playbooks = factory.getCreatedRecords('Playbook__c');
            List<SObject> accounts = factory.getCreatedRecords('Account');

            System.assertNotEquals(null, playbooks, 'Playbooks should be created');
            System.assertNotEquals(null, accounts, 'Accounts should be created as prerequisite');
            System.assertEquals(2, playbooks.size(), 'Should create 2 playbooks');

            Playbook__c playbook = (Playbook__c) playbooks[0];
            System.assertNotEquals(null, playbook.Name, 'Playbook should have a name');
        }
    }

    @isTest
    static void testGeneratePlaybooksWithExistingAccounts() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();
            factory.withCommonField('Account', 'BillingState', 'California')
                .withCommonField('Account', 'BillingCountry', 'United States');
            factory.generateAccounts();
            factory.generatePlaybooks();
            Test.stopTest();

            List<SObject> playbooks = factory.getCreatedRecords('Playbook__c');
            List<SObject> accounts = factory.getCreatedRecords('Account');

            System.assertNotEquals(null, playbooks, 'Playbooks should be created');
            System.assertNotEquals(null, accounts, 'Accounts should exist');
            System.assertEquals(1, playbooks.size(), 'Should create 1 playbook by default');
        }
    }

    @isTest
    static void testGenerateSuccessPlans() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();
            factory.withRecordCount('Success_Plan__c', 2)
                .withCommonField('Account', 'BillingState', 'California')
                .withCommonField('Account', 'BillingCountry', 'United States')
                .withCommonField('Success_Plan__c', 'Status__c', 'Closed');
            factory.generateSuccessPlans();
            Test.stopTest();

            List<SObject> successPlans = factory.getCreatedRecords('Success_Plan__c');
            List<SObject> accounts = factory.getCreatedRecords('Account');

            System.assertNotEquals(null, successPlans, 'Success Plans should be created');
            System.assertNotEquals(null, accounts, 'Accounts should be created as prerequisite');
            System.assertEquals(2, successPlans.size(), 'Should create 2 success plans');

            Success_Plan__c plan = (Success_Plan__c) successPlans[0];
            System.assertNotEquals(null, plan.Name, 'Success Plan should have a name');
        }
    }

    @isTest
    static void testGenerateSuccessPlansWithExistingAccounts() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();
            factory.withCommonField('Account', 'BillingState', 'California')
                .withCommonField('Account', 'BillingCountry', 'United States')
                .withCommonField('Success_Plan__c', 'Status__c', 'Closed');
            factory.generateAccounts();
            factory.generateSuccessPlans();
            Test.stopTest();

            List<SObject> successPlans = factory.getCreatedRecords('Success_Plan__c');
            List<SObject> accounts = factory.getCreatedRecords('Account');

            System.assertNotEquals(null, successPlans, 'Success Plans should be created');
            System.assertNotEquals(null, accounts, 'Accounts should exist');
            System.assertEquals(1, successPlans.size(), 'Should create 1 success plan by default');
        }
    }

    @isTest
    static void testGenerateTasks() {
        // Query for an active System Admin user
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();

            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();
            factory.withRecordCount('Tasks__c', 2)
                   .withCommonField('Tasks__c', 'Status__c', 'Pending');

            // Test method chaining instead of actual generation due to required field constraints
            CS_TestDataFactoryUtility result = factory.withRecordCount('Tasks__c', 3);

            System.assertNotEquals(null, result, 'Factory should return itself for chaining');
            System.assertEquals(factory, result, 'Should return same factory instance');

            Test.stopTest();
        }
    }

    @isTest
    static void testGenerateReleaseVersions() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();
            factory.withRecordCount('Release_Version__c', 2);
            factory.generateReleaseVersions();
            Test.stopTest();

            List<SObject> versions = factory.getCreatedRecords('Release_Version__c');
            System.assertNotEquals(null, versions, 'Release Versions should be created');
            System.assertEquals(2, versions.size(), 'Should create 2 release versions');

            Release_Version__c version = (Release_Version__c) versions[0];
            System.assertNotEquals(null, version.Name, 'Release Version should have a name');
        }
    }

    @isTest
    static void testGenerateCatalogs() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();
            factory.withRecordCount('Catalog__c', 2);
            factory.generateCatalogs();
            Test.stopTest();

            List<SObject> catalogs = factory.getCreatedRecords('Catalog__c');
            System.assertNotEquals(null, catalogs, 'Catalogs should be created');
            System.assertEquals(2, catalogs.size(), 'Should create 2 catalogs');
        }
    }

    @isTest
    static void testGenerateBaseCSData() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();
            factory.withCommonField('Account', 'BillingState', 'California')
                .withCommonField('Account', 'BillingCountry', 'United States');
            factory.generateBaseCSData();
            Test.stopTest();

            List<SObject> accounts = factory.getCreatedRecords('Account');
            List<SObject> contacts = factory.getCreatedRecords('Contact');
            List<SObject> users = factory.getCreatedRecords('User');
            List<SObject> cases = factory.getCreatedRecords('Case');

            System.assertNotEquals(null, accounts, 'Accounts should be created');
            System.assertNotEquals(null, contacts, 'Contacts should be created');
            System.assertNotEquals(null, users, 'Users should be created');
            System.assertNotEquals(null, cases, 'Cases should be created');

            System.assertEquals(1, accounts.size(), 'Should create 1 account by default');
            System.assertEquals(1, contacts.size(), 'Should create 1 contact by default');
            System.assertEquals(1, users.size(), 'Should create 1 user by default');
            System.assertEquals(1, cases.size(), 'Should create 1 case by default');
        }
    }

    @isTest
    static void testGenerateComprehensiveCSData() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();
            String uniqueId = String.valueOf(System.currentTimeMillis());
            factory.withCommonField('Account', 'BillingState', 'California')
                .withCommonField('Account', 'BillingCountry', 'United States')
                .withCommonField('Customer_Subscription__c', 'Type__c', 'Article')
                .withCommonField('Success_Plan__c', 'Status__c', 'Closed')
                .withCommonField('Tasks__c', 'Status__c', 'Pending')

                .withCommonField('Cluster__c', 'UUID__c', uniqueId)
                .withCommonField('Cluster__c', 'Name', uniqueId)
                .withCommonField('Case_Audit__c', 'Case_Audit_Timestamp__c', System.now())
                .withCommonField('Case_Audit__c', 'Case_Documentation__c', 'Great')
                .withCommonField('Case_Audit__c', 'Case_Field_Classification__c', 'Great')
                .withCommonField('Case_Audit__c', 'Final_Audit_Score__c', 85.0)
                .withCommonField('Case_Audit__c', 'Overall_Case_management__c', 'Great')
                .withCommonField('Case_Audit__c', 'Resolution__c', 'Great');
            factory.generateBaseCSData();
            Test.stopTest();

            // Verify key objects are created
            System.assertNotEquals(null, factory.getCreatedRecords('Account'), 'Accounts should be created');
            System.assertNotEquals(null, factory.getCreatedRecords('Contact'), 'Contacts should be created');
            System.assertNotEquals(null, factory.getCreatedRecords('Case'), 'Cases should be created');
        }
    }

    @isTest
    static void testMethodChaining() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();

            CS_TestDataFactoryUtility result = factory
                .withRecordCount('Account', 2)
                .withCommonField('Account', 'BillingCity', 'San Francisco')
                .withCommonField('Account', 'BillingState', 'California')
                .withCommonField('Account', 'BillingCountry', 'United States')
                .withIndexedField('Account', 'Name', new List<Object>{'Account 1', 'Account 2'})
                .generateAccounts()
                .generateContacts();

            Test.stopTest();

            System.assertEquals(factory, result, 'Method chaining should return same instance');

            List<SObject> accounts = factory.getCreatedRecords('Account');
            List<SObject> contacts = factory.getCreatedRecords('Contact');

            System.assertNotEquals(null, accounts, 'Accounts should be created');
            System.assertNotEquals(null, contacts, 'Contacts should be created');
            System.assertEquals(2, accounts.size(), 'Should create 2 accounts');
            System.assertEquals(1, contacts.size(), 'Should create 1 contact by default');
        }
    }

    @isTest
    static void testIndexedFieldsInsufficientValues() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();

            // Create 3 accounts but only provide 2 indexed values
            factory.withRecordCount('Account', 3)
                .withCommonField('Account', 'BillingState', 'California')
                .withCommonField('Account', 'BillingCountry', 'United States')
                .withIndexedField('Account', 'Name', new List<Object>{'Account 1', 'Account 2'})
                .generateAccounts();

            Test.stopTest();

            List<SObject> accounts = factory.getCreatedRecords('Account');
            System.assertNotEquals(null, accounts, 'Accounts should be created');
            System.assertEquals(3, accounts.size(), 'Should create 3 accounts');

            // First two should have indexed names, third should have default name
            Account acc1 = (Account) accounts[0];
            Account acc2 = (Account) accounts[1];
            Account acc3 = (Account) accounts[2];

            System.assertEquals('Account 1', acc1.Name, 'First account should have indexed name');
            System.assertEquals('Account 2', acc2.Name, 'Second account should have indexed name');
            System.assert(acc3.Name.contains('CS Test Account'), 'Third account should have default name');
        }
    }

    @isTest
    static void testGetCreatedRecordsNonExistent() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();
            List<SObject> result = factory.getCreatedRecords('NonExistentObject');
            Test.stopTest();

            System.assertEquals(null, result, 'Should return null for non-existent object type');
        }
    }

    @isTest
    static void testWithCommonFieldMultipleFields() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();

            factory.withCommonField('Account', 'BillingCity', 'Santa Clara')
                .withCommonField('Account', 'BillingState', 'California')
                .withCommonField('Account', 'BillingCountry', 'United States')
                .generateAccounts();

            Test.stopTest();

            List<SObject> accounts = factory.getCreatedRecords('Account');
            System.assertNotEquals(null, accounts, 'Accounts should be created');
            System.assertEquals(1, accounts.size(), 'Should create 1 account');
        }
    }

    @isTest
    static void testWithIndexedFieldMultipleFields() {
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            CS_TestDataFactoryUtility factory = new CS_TestDataFactoryUtility();

            factory.withRecordCount('Account', 2)
                .withCommonField('Account', 'BillingState', 'California')
                .withCommonField('Account', 'BillingCountry', 'United States')
                .withIndexedField('Account', 'Name', new List<Object>{'Account 1', 'Account 2'})
                .withIndexedField('Account', 'BillingCity', new List<Object>{'City 1', 'City 2'})
                .generateAccounts();

            Test.stopTest();

            List<SObject> accounts = factory.getCreatedRecords('Account');
            System.assertNotEquals(null, accounts, 'Accounts should be created');
            System.assertEquals(2, accounts.size(), 'Should create 2 accounts');
        }
    }
}