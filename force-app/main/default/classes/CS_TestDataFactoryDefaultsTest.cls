/**
 * ───────────────────────────────────────────────────────────────────────────────────────────────────┐
 * @description Test class for CS_TestDataFactoryDefaults - Comprehensive test coverage for Customer
 *              Support test data factory default field values and sObject mapping operations.
 * ───────────────────────────────────────────────────────────────────────────────────────────────────
 * @Class     CS_TestDataFactoryDefaultsTest
 * @Coverage  Target: 90%+ - Covers CS_TestDataFactoryDefaults default field mapping operations
 * @Methods   Comprehensive test methods covering all sObject types and edge cases
 * @Author    Vijay Kumar K R
 * @Created   Jan 24, 2025
 * @Version   2.0 - Recreated for comprehensive coverage with PMD compliance
 * ───────────────────────────────────────────────────────────────────────────────────────────────────
 * @Features  • All sObject default field mapping validation
 *            • Case sensitivity testing for sObject names
 *            • Invalid input handling (null, empty, blank strings)
 *            • Static field map initialization verification
 *            • Big Object and Knowledge Article support
 *            • Standard Salesforce object coverage
 *            • Custom object comprehensive testing
 *            • Edge case and error condition coverage
 * ───────────────────────────────────────────────────────────────────────────────────────────────────
 * @Coverage  All CS_TestDataFactoryDefaults functionality:
 *            • getDefaultFields() method with all sObject types
 *            • Static field map initialization and access
 *            • Case-insensitive sObject name handling
 *            • Invalid input validation and error handling
 * ───────────────────────────────────────────────────────────────────────────────────────────────────┘
 */
@isTest
public class CS_TestDataFactoryDefaultsTest {
    
    /**
     * @description Test getDefaultFields method with Account and Contact related objects
     */
    @isTest
    static void testGetDefaultFieldsAccountObjects() {
        // Query for an active System Admin user
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        
        System.runAs(adminUser) {
            Test.startTest();
            
            // Test Account Historical View Big Object
            Map<String, Object> accountHistoricalFields = CS_TestDataFactoryDefaults.getDefaultFields('account_historical_view__b');
            System.assertNotEquals(null, accountHistoricalFields, 'Account Historical View fields should not be null');
            System.assert(accountHistoricalFields.containsKey('FISCAL_YEAR__c'), 'Should contain FISCAL_YEAR__c field');
            System.assertEquals('2025', accountHistoricalFields.get('FISCAL_YEAR__c'), 'Should have correct fiscal year');
            
            // Test Account Score Big Object
            Map<String, Object> accountScoreFields = CS_TestDataFactoryDefaults.getDefaultFields('account_score__b');
            System.assertNotEquals(null, accountScoreFields, 'Account Score fields should not be null');
            System.assert(accountScoreFields.containsKey('CX_Score__c'), 'Should contain CX_Score__c field');
            System.assertEquals(85.5, accountScoreFields.get('CX_Score__c'), 'Should have correct CX score');
            
            // Test Account Audit Log
            Map<String, Object> accountAuditFields = CS_TestDataFactoryDefaults.getDefaultFields('accountauditlog__c');
            System.assertNotEquals(null, accountAuditFields, 'Account Audit Log fields should not be null');
            System.assertEquals('Enforce Admin Panel', accountAuditFields.get('EditedField__c'), 'Should have correct edited field');
            System.assertEquals(true, accountAuditFields.get('NewValue__c'), 'Should have correct new value');
            
            Test.stopTest();
        }
    }

    /**
     * @description Test getDefaultFields method with Case related objects
     */
    @isTest
    static void testGetDefaultFieldsCaseObjects() {
        // Query for an active System Admin user
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();

            // Test Case standard object
            Map<String, Object> caseFields = CS_TestDataFactoryDefaults.getDefaultFields('case');
            System.assertNotEquals(null, caseFields, 'Case fields should not be null');
            System.assertEquals('Test Case Subject', caseFields.get('Subject'), 'Should have correct default subject');
            System.assertEquals('New', caseFields.get('Status'), 'Should have correct default status');
            System.assertEquals('Medium', caseFields.get('Priority'), 'Should have correct default priority');
            System.assertEquals('Internal', caseFields.get('Origin'), 'Should have correct default origin');

            // Test Case Audit
            Map<String, Object> caseAuditFields = CS_TestDataFactoryDefaults.getDefaultFields('case_audit__c');
            System.assertNotEquals(null, caseAuditFields, 'Case Audit fields should not be null');
            System.assertEquals('Case Created', caseAuditFields.get('Action_Taken__c'), 'Should have correct default action');

            // Test Case History Tracking
            Map<String, Object> caseHistoryFields = CS_TestDataFactoryDefaults.getDefaultFields('case_history_tracking__c');
            System.assertNotEquals(null, caseHistoryFields, 'Case History Tracking fields should not be null');
            System.assertEquals('Status', caseHistoryFields.get('Field_Changed__c'), 'Should have correct field changed');
            System.assertEquals('New', caseHistoryFields.get('Old_Value__c'), 'Should have correct old value');
            System.assertEquals('In Progress', caseHistoryFields.get('New_Value__c'), 'Should have correct new value');

            // Test Case Notification Preference
            Map<String, Object> caseNotificationFields = CS_TestDataFactoryDefaults.getDefaultFields('case_notification_preference__c');
            System.assertNotEquals(null, caseNotificationFields, 'Case Notification Preference fields should not be null');
            System.assertEquals(true, caseNotificationFields.get('Email_Notifications__c'), 'Should have correct email notification setting');
            System.assertEquals(false, caseNotificationFields.get('SMS_Notifications__c'), 'Should have correct SMS notification setting');

            // Test Case Special Handling
            Map<String, Object> caseSpecialHandlingFields = CS_TestDataFactoryDefaults.getDefaultFields('case_special_handling__c');
            System.assertNotEquals(null, caseSpecialHandlingFields, 'Case Special Handling fields should not be null');
            System.assertEquals('Handle with priority', caseSpecialHandlingFields.get('Special_Instructions__c'), 'Should have correct special instructions');
            System.assertEquals('Escalated', caseSpecialHandlingFields.get('Handling_Type__c'), 'Should have correct handling type');

            Test.stopTest();
        }
    }

    /**
     * @description Test getDefaultFields method with Aha Ideas related objects
     */
    @isTest
    static void testGetDefaultFieldsAhaObjects() {
        // Query for an active System Admin user
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();

            // Test Aha Ideas
            Map<String, Object> ahaIdeasFields = CS_TestDataFactoryDefaults.getDefaultFields('aha_ideas__c');
            System.assertNotEquals(null, ahaIdeasFields, 'Aha Ideas fields should not be null');
            System.assertEquals('Test Aha Idea', ahaIdeasFields.get('Name'), 'Should have correct default name');
            System.assertEquals('AHA-TEST-001', ahaIdeasFields.get('Aha_Unique_ID__c'), 'Should have correct unique ID');
            System.assertEquals('IDEA-001', ahaIdeasFields.get('Aha_Idea_Number__c'), 'Should have correct idea number');
            System.assertEquals('Test idea description for automated testing', ahaIdeasFields.get('Idea_Description__c'), 'Should have correct description');

            // Test Aha Idea Link
            Map<String, Object> ahaIdeaLinkFields = CS_TestDataFactoryDefaults.getDefaultFields('aha_idea_link__c');
            System.assertNotEquals(null, ahaIdeaLinkFields, 'Aha Idea Link fields should not be null');
            System.assert(ahaIdeaLinkFields.containsKey('Aha_Ideas__c'), 'Should contain Aha_Ideas__c field');
            System.assert(ahaIdeaLinkFields.containsKey('Case_Number__c'), 'Should contain Case_Number__c field');
            System.assert(ahaIdeaLinkFields.containsKey('Opportunity_Name__c'), 'Should contain Opportunity_Name__c field');

            Test.stopTest();
        }
    }

    /**
     * @description Test getDefaultFields method with Cluster related objects
     */
    @isTest
    static void testGetDefaultFieldsClusterObjects() {
        // Query for an active System Admin user
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();

            // Test Cluster
            Map<String, Object> clusterFields = CS_TestDataFactoryDefaults.getDefaultFields('cluster__c');
            System.assertNotEquals(null, clusterFields, 'Cluster fields should not be null');
            System.assertEquals('Test Cluster', clusterFields.get('Name'), 'Should have correct default name');
            System.assertEquals('CLUSTER-001', clusterFields.get('Cluster_ID__c'), 'Should have correct default cluster ID');
            System.assertEquals('Active', clusterFields.get('Status__c'), 'Should have correct default status');
            System.assertEquals('1.0.0', clusterFields.get('Version__c'), 'Should have correct default version');

            // Test Cluster Issue
            Map<String, Object> clusterIssueFields = CS_TestDataFactoryDefaults.getDefaultFields('cluster_issue__c');
            System.assertNotEquals(null, clusterIssueFields, 'Cluster Issue fields should not be null');
            System.assertEquals('Performance', clusterIssueFields.get('Issue_Type__c'), 'Should have correct default issue type');
            System.assertEquals('Medium', clusterIssueFields.get('Severity__c'), 'Should have correct default severity');
            System.assertEquals('Open', clusterIssueFields.get('Status__c'), 'Should have correct default status');

            // Test Cluster Registration
            Map<String, Object> clusterRegistrationFields = CS_TestDataFactoryDefaults.getDefaultFields('cluster_registration__c');
            System.assertNotEquals(null, clusterRegistrationFields, 'Cluster Registration fields should not be null');
            System.assertEquals(System.today(), clusterRegistrationFields.get('Registration_Date__c'), 'Should have correct registration date');
            System.assertEquals('Registered', clusterRegistrationFields.get('Status__c'), 'Should have correct status');

            // Test ClusterAttribute Big Object
            Map<String, Object> clusterAttributeFields = CS_TestDataFactoryDefaults.getDefaultFields('clusterattribute__b');
            System.assertNotEquals(null, clusterAttributeFields, 'Cluster Attribute fields should not be null');
            System.assertEquals('CLUSTER-001', clusterAttributeFields.get('Cluster_ID__c'), 'Should have correct cluster ID');
            System.assertEquals('CPU_Usage', clusterAttributeFields.get('Attribute_Name__c'), 'Should have correct attribute name');
            System.assertEquals('75.5', clusterAttributeFields.get('Attribute_Value__c'), 'Should have correct attribute value');

            Test.stopTest();
        }
    }

    /**
     * @description Test getDefaultFields method with Escalation related objects
     */
    @isTest
    static void testGetDefaultFieldsEscalationObjects() {
        // Query for an active System Admin user
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();

            // Test Escalation
            Map<String, Object> escalationFields = CS_TestDataFactoryDefaults.getDefaultFields('escalation__c');
            System.assertNotEquals(null, escalationFields, 'Escalation fields should not be null');
            System.assertEquals(null, escalationFields.get('Case__c'), 'Should have null Case__c (set dynamically)');
            System.assertEquals('High', escalationFields.get('Priority__c'), 'Should have correct default priority');
            System.assertEquals('Open', escalationFields.get('Status__c'), 'Should have correct default status');
            System.assertEquals('Customer Request', escalationFields.get('Escalation_Reason__c'), 'Should have correct escalation reason');

            // Test Escalation Communication
            Map<String, Object> escalationCommFields = CS_TestDataFactoryDefaults.getDefaultFields('escalation_communication__c');
            System.assertNotEquals(null, escalationCommFields, 'Escalation Communication fields should not be null');
            System.assertEquals('Email', escalationCommFields.get('Communication_Type__c'), 'Should have correct communication type');
            System.assertEquals('Escalation Update', escalationCommFields.get('Subject__c'), 'Should have correct subject');
            System.assertEquals('Test escalation communication', escalationCommFields.get('Body__c'), 'Should have correct body');

            // Test Escalation Contact
            Map<String, Object> escalationContactFields = CS_TestDataFactoryDefaults.getDefaultFields('escalation_contact__c');
            System.assertNotEquals(null, escalationContactFields, 'Escalation Contact fields should not be null');
            System.assertEquals(null, escalationContactFields.get('Escalation__c'), 'Should have null escalation reference');
            System.assertEquals(null, escalationContactFields.get('Contact__c'), 'Should have null contact reference');
            System.assertEquals('Primary Contact', escalationContactFields.get('Role__c'), 'Should have correct role');

            // Test Escalation Management
            Map<String, Object> escalationMgmtFields = CS_TestDataFactoryDefaults.getDefaultFields('escalation_management__c');
            System.assertNotEquals(null, escalationMgmtFields, 'Escalation Management fields should not be null');



            // Test Escalation Request
            Map<String, Object> escalationRequestFields = CS_TestDataFactoryDefaults.getDefaultFields('escalation_request__c');
            System.assertNotEquals(null, escalationRequestFields, 'Escalation Request fields should not be null');



            Test.stopTest();
        }
    }

    /**
     * @description Test getDefaultFields method with Playbook related objects
     */
    @isTest
    static void testGetDefaultFieldsPlaybookObjects() {
        // Query for an active System Admin user
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();

            // Test Playbook
            Map<String, Object> playbookFields = CS_TestDataFactoryDefaults.getDefaultFields('playbook__c');
            System.assertNotEquals(null, playbookFields, 'Playbook fields should not be null');
            System.assertEquals('Test Playbook', playbookFields.get('Name'), 'Should have correct default name');
            System.assertEquals('Active', playbookFields.get('Status__c'), 'Should have correct default status');
            System.assertEquals('Test playbook for automated testing', playbookFields.get('Description__c'), 'Should have correct description');

            // Test Playbook Checklist
            Map<String, Object> playbookChecklistFields = CS_TestDataFactoryDefaults.getDefaultFields('playbook_checklist__c');
            System.assertNotEquals(null, playbookChecklistFields, 'Playbook Checklist fields should not be null');
            System.assertEquals('Test Checklist Item', playbookChecklistFields.get('Task_Name__c'), 'Should have correct task name');
            System.assertEquals('Pending', playbookChecklistFields.get('Status__c'), 'Should have correct status');


            // Test Playbook Sub Task
            Map<String, Object> playbookSubTaskFields = CS_TestDataFactoryDefaults.getDefaultFields('playbook_sub_task__c');
            System.assertNotEquals(null, playbookSubTaskFields, 'Playbook Sub Task fields should not be null');
            System.assertEquals(null, playbookSubTaskFields.get('Playbook__c'), 'Should have null playbook reference');
            System.assertEquals('Test Sub Task', playbookSubTaskFields.get('Task_Name__c'), 'Should have correct task name');
            System.assertEquals('Not Started', playbookSubTaskFields.get('Status__c'), 'Should have correct status');

            // Test Playbook Template
            Map<String, Object> playbookTemplateFields = CS_TestDataFactoryDefaults.getDefaultFields('playbook_template__c');
            System.assertNotEquals(null, playbookTemplateFields, 'Playbook Template fields should not be null');
            System.assertEquals('Test Playbook Template', playbookTemplateFields.get('Name'), 'Should have correct default name');



            Test.stopTest();
        }
    }

    /**
     * @description Test getDefaultFields method with Release related objects
     */
    @isTest
    static void testGetDefaultFieldsReleaseObjects() {
        // Query for an active System Admin user
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();

            // Test Release Software
            Map<String, Object> releaseSoftwareFields = CS_TestDataFactoryDefaults.getDefaultFields('release_software__c');
            System.assertNotEquals(null, releaseSoftwareFields, 'Release Software fields should not be null');
            System.assertEquals('Test Release Software', releaseSoftwareFields.get('Name'), 'Should have correct default name');
            System.assertEquals('1.0.0', releaseSoftwareFields.get('Version__c'), 'Should have correct default version');
            System.assertEquals('Released', releaseSoftwareFields.get('Status__c'), 'Should have correct default status');
            System.assertEquals(System.today(), releaseSoftwareFields.get('Release_Date__c'), 'Should have correct release date');

            // Test Release Version
            Map<String, Object> releaseVersionFields = CS_TestDataFactoryDefaults.getDefaultFields('release_version__c');
            System.assertNotEquals(null, releaseVersionFields, 'Release Version fields should not be null');
            System.assertEquals('1.0.0', releaseVersionFields.get('Version_Number__c'), 'Should have correct version number');
            System.assertEquals('Test Release Version', releaseVersionFields.get('Name'), 'Should have correct name');
            System.assertEquals(System.today(), releaseVersionFields.get('Release_Date__c'), 'Should have correct release date');
            System.assertEquals('Active', releaseVersionFields.get('Status__c'), 'Should have correct status');

            // Test Releases
            Map<String, Object> releasesFields = CS_TestDataFactoryDefaults.getDefaultFields('releases__c');
            System.assertNotEquals(null, releasesFields, 'Releases fields should not be null');
            System.assertEquals('Test Release', releasesFields.get('Name'), 'Should have correct default name');
            System.assertEquals('1.0.0', releasesFields.get('Version__c'), 'Should have correct version');


            Test.stopTest();
        }
    }

    /**
     * @description Test getDefaultFields method with Risk Profile related objects
     */
    @isTest
    static void testGetDefaultFieldsRiskProfileObjects() {
        // Query for an active System Admin user
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();

            // Test Risk Profile
            Map<String, Object> riskProfileFields = CS_TestDataFactoryDefaults.getDefaultFields('risk_profile__c');
            System.assertNotEquals(null, riskProfileFields, 'Risk Profile fields should not be null');
            System.assertEquals('Test Risk Profile', riskProfileFields.get('Name'), 'Should have correct default name');
            System.assertEquals('Medium', riskProfileFields.get('Risk_Level__c'), 'Should have correct default risk level');
            System.assertEquals(null, riskProfileFields.get('Account__c'), 'Should have null Account__c (set dynamically)');
            System.assertEquals(System.today(), riskProfileFields.get('Assessment_Date__c'), 'Should have correct assessment date');

            // Test Risk Profile PDM Feature
            Map<String, Object> riskProfilePdmFields = CS_TestDataFactoryDefaults.getDefaultFields('risk_profile_pdm_feature__c');
            System.assertNotEquals(null, riskProfilePdmFields, 'Risk Profile PDM Feature fields should not be null');
            System.assertEquals('Test PDM Feature', riskProfilePdmFields.get('Feature_Name__c'), 'Should have correct feature name');
            System.assertEquals('Active', riskProfilePdmFields.get('Status__c'), 'Should have correct status');

            // Test Risk Profile Watcher
            Map<String, Object> riskProfileWatcherFields = CS_TestDataFactoryDefaults.getDefaultFields('risk_profile_watcher__c');
            System.assertNotEquals(null, riskProfileWatcherFields, 'Risk Profile Watcher fields should not be null');
            System.assertEquals(null, riskProfileWatcherFields.get('Risk_Profile__c'), 'Should have null risk profile reference');
            System.assertEquals(null, riskProfileWatcherFields.get('User__c'), 'Should have null user reference');
            System.assertEquals(System.today(), riskProfileWatcherFields.get('Watch_Date__c'), 'Should have correct watch date');

            Test.stopTest();
        }
    }

    /**
     * @description Test getDefaultFields method with Knowledge and Standard objects
     */
    @isTest
    static void testGetDefaultFieldsKnowledgeObjects() {
        // Query for an active System Admin user
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();

            // Test How To Knowledge Article
            Map<String, Object> howToFields = CS_TestDataFactoryDefaults.getDefaultFields('how_to__kav');
            System.assertNotEquals(null, howToFields, 'How To fields should not be null');
            System.assertEquals('Test How-To Article', howToFields.get('Title'), 'Should have correct default title');
            System.assert(((String)howToFields.get('UrlName')).startsWith('Test-How-To-Article-'), 'Should have correct URL name pattern');
            System.assertEquals('Test how-to article summary', howToFields.get('Summary'), 'Should have correct summary');
            System.assertEquals('en_US', howToFields.get('Language'), 'Should have correct language');

            // Test Idea standard object
            Map<String, Object> ideaFields = CS_TestDataFactoryDefaults.getDefaultFields('idea');
            System.assertNotEquals(null, ideaFields, 'Idea fields should not be null');
            System.assertEquals('Test Idea', ideaFields.get('Title'), 'Should have correct default title');
            System.assertEquals('Test idea description for automated testing', ideaFields.get('Body'), 'Should have correct body');
            System.assertEquals('New', ideaFields.get('Status'), 'Should have correct status');

            // Test Solution standard object
            Map<String, Object> solutionFields = CS_TestDataFactoryDefaults.getDefaultFields('solution');
            System.assertNotEquals(null, solutionFields, 'Solution fields should not be null');
            System.assertEquals('Test Solution', solutionFields.get('SolutionName'), 'Should have correct solution name');
            System.assertEquals('Test solution description for automated testing', solutionFields.get('SolutionNote'), 'Should have correct solution note');
            System.assertEquals('Draft', solutionFields.get('Status'), 'Should have correct status');
            System.assertEquals('Draft', solutionFields.get('Status'), 'Should have correct status');

            // Test LinkedArticle standard object
            Map<String, Object> linkedArticleFields = CS_TestDataFactoryDefaults.getDefaultFields('linkedarticle');
            System.assertNotEquals(null, linkedArticleFields, 'LinkedArticle fields should not be null');

            Test.stopTest();
        }
    }

    /**
     * @description Test getDefaultFields method with invalid inputs
     */
    @isTest
    static void testGetDefaultFieldsInvalidInputs() {
        // Query for an active System Admin user
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();

            // Test null input
            Map<String, Object> nullResult = CS_TestDataFactoryDefaults.getDefaultFields(null);
            System.assertNotEquals(null, nullResult, 'Result should not be null');
            System.assertEquals(0, nullResult.size(), 'Should return empty map for null input');

            // Test empty string input
            Map<String, Object> emptyResult = CS_TestDataFactoryDefaults.getDefaultFields('');
            System.assertNotEquals(null, emptyResult, 'Result should not be null');
            System.assertEquals(0, emptyResult.size(), 'Should return empty map for empty string input');

            // Test blank string input
            Map<String, Object> blankResult = CS_TestDataFactoryDefaults.getDefaultFields('   ');
            System.assertNotEquals(null, blankResult, 'Result should not be null');
            System.assertEquals(0, blankResult.size(), 'Should return empty map for blank string input');

            // Test invalid sObject type
            Map<String, Object> invalidResult = CS_TestDataFactoryDefaults.getDefaultFields('invalid_sobject_type__c');
            System.assertNotEquals(null, invalidResult, 'Result should not be null');
            System.assertEquals(0, invalidResult.size(), 'Should return empty map for invalid sObject type');

            // Test non-existent sObject type
            Map<String, Object> nonExistentResult = CS_TestDataFactoryDefaults.getDefaultFields('non_existent_object__c');
            System.assertNotEquals(null, nonExistentResult, 'Result should not be null');
            System.assertEquals(0, nonExistentResult.size(), 'Should return empty map for non-existent sObject type');

            Test.stopTest();
        }
    }

    /**
     * @description Test getDefaultFields method with case sensitivity
     */
    @isTest
    static void testGetDefaultFieldsCaseSensitivity() {
        // Query for an active System Admin user
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();

            // Test lowercase
            Map<String, Object> lowercaseResult = CS_TestDataFactoryDefaults.getDefaultFields('case');
            System.assertNotEquals(null, lowercaseResult, 'Lowercase result should not be null');
            System.assert(lowercaseResult.size() > 0, 'Should return fields for lowercase input');

            // Test uppercase
            Map<String, Object> uppercaseResult = CS_TestDataFactoryDefaults.getDefaultFields('CASE');
            System.assertNotEquals(null, uppercaseResult, 'Uppercase result should not be null');
            System.assert(uppercaseResult.size() > 0, 'Should return fields for uppercase input');

            // Test mixed case
            Map<String, Object> mixedCaseResult = CS_TestDataFactoryDefaults.getDefaultFields('CaSe');
            System.assertNotEquals(null, mixedCaseResult, 'Mixed case result should not be null');
            System.assert(mixedCaseResult.size() > 0, 'Should return fields for mixed case input');

            // Verify all results are the same (case-insensitive)
            System.assertEquals(lowercaseResult.size(), uppercaseResult.size(), 'Lowercase and uppercase should return same number of fields');
            System.assertEquals(lowercaseResult.size(), mixedCaseResult.size(), 'Lowercase and mixed case should return same number of fields');
            System.assertEquals(lowercaseResult.get('Subject'), uppercaseResult.get('Subject'), 'Should have same Subject value');
            System.assertEquals(lowercaseResult.get('Status'), mixedCaseResult.get('Status'), 'Should have same Status value');

            Test.stopTest();
        }
    }

    /**
     * @description Test getDefaultFields method with additional sObject types for comprehensive coverage
     */
    @isTest
    static void testGetDefaultFieldsAdditionalObjects() {
        // Query for an active System Admin user
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();

            // Test Success Plan
            Map<String, Object> successPlanFields = CS_TestDataFactoryDefaults.getDefaultFields('success_plan__c');
            System.assertNotEquals(null, successPlanFields, 'Success Plan fields should not be null');
            System.assertEquals('Test Success Plan', successPlanFields.get('Name'), 'Should have correct default name');
            System.assertEquals('Active', successPlanFields.get('Status__c'), 'Should have correct default status');

            // Test Tasks
            Map<String, Object> tasksFields = CS_TestDataFactoryDefaults.getDefaultFields('tasks__c');
            System.assertNotEquals(null, tasksFields, 'Tasks fields should not be null');
            System.assertEquals('Test task description', tasksFields.get('Description__c'), 'Should have correct default description');
            System.assertEquals('Not Started', tasksFields.get('Status__c'), 'Should have correct default status');
            System.assertEquals('Medium', tasksFields.get('Priority__c'), 'Should have correct default priority');
            System.assertEquals(System.today().addDays(7), tasksFields.get('Due_Date__c'), 'Should have correct due date');

            // Test Customer Subscription
            Map<String, Object> customerSubscriptionFields = CS_TestDataFactoryDefaults.getDefaultFields('customer_subscription__c');
            System.assertNotEquals(null, customerSubscriptionFields, 'Customer Subscription fields should not be null');
            System.assertEquals(null, customerSubscriptionFields.get('Account__c'), 'Should have null account reference');
            System.assertEquals(System.today(), customerSubscriptionFields.get('Start_Date__c'), 'Should have correct start date');
            System.assertEquals(System.today().addDays(365), customerSubscriptionFields.get('End_Date__c'), 'Should have correct end date');
            System.assertEquals('Active', customerSubscriptionFields.get('Status__c'), 'Should have correct default status');

            // Test Jira Issue
            Map<String, Object> jiraIssueFields = CS_TestDataFactoryDefaults.getDefaultFields('jira_issue__c');
            System.assertNotEquals(null, jiraIssueFields, 'Jira Issue fields should not be null');
            System.assertEquals('TEST-001', jiraIssueFields.get('JIRA_Key__c'), 'Should have correct JIRA key');
            System.assertEquals('Bug', jiraIssueFields.get('Issue_Type__c'), 'Should have correct issue type');
            System.assertEquals('Open', jiraIssueFields.get('Status__c'), 'Should have correct status');
            System.assertEquals('Medium', jiraIssueFields.get('Priority__c'), 'Should have correct priority');
            System.assertEquals('Bug', jiraIssueFields.get('Issue_Type__c'), 'Should have correct issue type');

            // Test Metadata Request
            Map<String, Object> metadataRequestFields = CS_TestDataFactoryDefaults.getDefaultFields('metadata_request__c');
            System.assertNotEquals(null, metadataRequestFields, 'Metadata Request fields should not be null');


            // Test PushTopic standard object
            Map<String, Object> pushTopicFields = CS_TestDataFactoryDefaults.getDefaultFields('pushtopic');
            System.assertNotEquals(null, pushTopicFields, 'PushTopic fields should not be null');
            System.assertEquals('TestPushTopic', pushTopicFields.get('Name'), 'Should have correct default name');



            // Test WL Domain
            Map<String, Object> wlDomainFields = CS_TestDataFactoryDefaults.getDefaultFields('wl_domain__c');
            System.assertNotEquals(null, wlDomainFields, 'WL Domain fields should not be null');

            System.assertEquals('Active', wlDomainFields.get('Status__c'), 'Should have correct status');

            // Test User History
            Map<String, Object> userHistoryFields = CS_TestDataFactoryDefaults.getDefaultFields('user_history__c');
            System.assertNotEquals(null, userHistoryFields, 'User History fields should not be null');
            System.assertEquals('Login', userHistoryFields.get('Action__c'), 'Should have correct action');


            // Test Status Tracking
            Map<String, Object> statusTrackingFields = CS_TestDataFactoryDefaults.getDefaultFields('status_tracking__c');
            System.assertNotEquals(null, statusTrackingFields, 'Status Tracking fields should not be null');



            Test.stopTest();
        }
    }

    /**
     * @description Test static field maps initialization
     */
    @isTest
    static void testStaticFieldMapsInitialization() {
        // Query for an active System Admin user
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();

            // Verify that static field maps are properly initialized and accessible
            // This tests the static initialization of the field maps

            // Test that we can access different types of field maps
            Map<String, Object> accountHistoricalFields = CS_TestDataFactoryDefaults.getDefaultFields('account_historical_view__b');
            Map<String, Object> caseFields = CS_TestDataFactoryDefaults.getDefaultFields('case');
            Map<String, Object> clusterFields = CS_TestDataFactoryDefaults.getDefaultFields('cluster__c');
            Map<String, Object> escalationFields = CS_TestDataFactoryDefaults.getDefaultFields('escalation__c');
            Map<String, Object> playbookFields = CS_TestDataFactoryDefaults.getDefaultFields('playbook__c');
            Map<String, Object> releaseFields = CS_TestDataFactoryDefaults.getDefaultFields('releases__c');
            Map<String, Object> riskProfileFields = CS_TestDataFactoryDefaults.getDefaultFields('risk_profile__c');
            Map<String, Object> howToFields = CS_TestDataFactoryDefaults.getDefaultFields('how_to__kav');
            Map<String, Object> successPlanFields = CS_TestDataFactoryDefaults.getDefaultFields('success_plan__c');
            Map<String, Object> tasksFields = CS_TestDataFactoryDefaults.getDefaultFields('tasks__c');

            // Verify all field maps are not null and contain data
            System.assertNotEquals(null, accountHistoricalFields, 'Account Historical View map should be initialized');
            System.assertNotEquals(null, caseFields, 'Case map should be initialized');
            System.assertNotEquals(null, clusterFields, 'Cluster map should be initialized');
            System.assertNotEquals(null, escalationFields, 'Escalation map should be initialized');
            System.assertNotEquals(null, playbookFields, 'Playbook map should be initialized');
            System.assertNotEquals(null, releaseFields, 'Release map should be initialized');
            System.assertNotEquals(null, riskProfileFields, 'Risk Profile map should be initialized');
            System.assertNotEquals(null, howToFields, 'How To map should be initialized');
            System.assertNotEquals(null, successPlanFields, 'Success Plan map should be initialized');
            System.assertNotEquals(null, tasksFields, 'Tasks map should be initialized');

            // Verify maps contain expected number of fields (greater than 0)
            System.assert(accountHistoricalFields.size() > 0, 'Account Historical View map should contain fields');
            System.assert(caseFields.size() > 0, 'Case map should contain fields');
            System.assert(clusterFields.size() > 0, 'Cluster map should contain fields');
            System.assert(escalationFields.size() > 0, 'Escalation map should contain fields');
            System.assert(playbookFields.size() > 0, 'Playbook map should contain fields');
            System.assert(releaseFields.size() > 0, 'Release map should contain fields');
            System.assert(riskProfileFields.size() > 0, 'Risk Profile map should contain fields');
            System.assert(howToFields.size() > 0, 'How To map should contain fields');
            System.assert(successPlanFields.size() > 0, 'Success Plan map should contain fields');
            System.assert(tasksFields.size() > 0, 'Tasks map should contain fields');

            Test.stopTest();
        }
    }
}