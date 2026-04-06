/******************************************************************************
 * @description       : This Class is used to generate CS (Customer Support) related test data using the defaults
 * @author            : 
 * @last modified on  : 11-13-2025
 * @last modified by  : 
 * Modifications Log
 * Ver   Date          Author        Modification
 * 
 ******************************************************************************/
public with sharing class CS_TestDataFactoryUtility {
    
    private Map<String, List<SObject>> createdRecords = new Map<String, List<SObject>>();
    private Map<String, Integer> recordCounts = new Map<String, Integer>();
    private Map<String, Map<String, Object>> commonFields = new Map<String, Map<String, Object>>();
    private Map<String, Map<String, List<Object>>> indexedFields = new Map<String, Map<String, List<Object>>>();

    /**
     * @description Set the number of records to create for a specific sObject type
     * @param sObjectType The API name of the sObject
     * @param count Number of records to create
     * @return CS_TestDataFactoryUtility Current instance for method chaining
     */
    public CS_TestDataFactoryUtility withRecordCount(String sObjectType, Integer count) {
        recordCounts.put(sObjectType, count);
        return this;
    }

    /**
     * @description Set common field values for all records of a specific sObject type
     * @param sObjectType The API name of the sObject
     * @param fieldName The field API name
     * @param value The value to set
     * @return CS_TestDataFactoryUtility Current instance for method chaining
     */
    public CS_TestDataFactoryUtility withCommonField(String sObjectType, String fieldName, Object value) {
        if (!commonFields.containsKey(sObjectType)) {
            commonFields.put(sObjectType, new Map<String, Object>());
        }
        commonFields.get(sObjectType).put(fieldName, value);
        return this;
    }

    /**
     * @description Set indexed field values for records of a specific sObject type
     * @param sObjectType The API name of the sObject
     * @param fieldName The field API name
     * @param values List of values to set for each record
     * @return CS_TestDataFactoryUtility Current instance for method chaining
     */
    public CS_TestDataFactoryUtility withIndexedField(String sObjectType, String fieldName, List<Object> values) {
        if (!indexedFields.containsKey(sObjectType)) {
            indexedFields.put(sObjectType, new Map<String, List<Object>>());
        }
        indexedFields.get(sObjectType).put(fieldName, values);
        return this;
    }

    /**
     * @description Get created records for a specific sObject type
     * @param sObjectType The API name of the sObject
     * @return List<SObject> List of created records
     */
    public List<SObject> getCreatedRecords(String sObjectType) {
        return createdRecords.get(sObjectType);
    }

    /**
     * @description This method is used to generate Accounts (prerequisite for many CS objects)
     * @return CS_TestDataFactoryUtility Current instance for method chaining
     */
    public CS_TestDataFactoryUtility generateAccounts() {
        Integer count = recordCounts.get('Account') == null ? 1 : recordCounts.get('Account');
        List<Account> accs = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            Account acc = new Account(Name = 'CS Test Account ' + i);
            applyCustomFields(acc, 'Account', i);
            accs.add(acc);
        }
        insert accs;
        createdRecords.put('Account', accs);
        return this;
    }

    /**
     * @description This method is used to generate Contacts (prerequisite for many CS objects)
     * @return CS_TestDataFactoryUtility Current instance for method chaining
     */
    public CS_TestDataFactoryUtility generateContacts() {
        if (!createdRecords.containsKey('Account')) generateAccounts();
        Integer count = recordCounts.get('Contact') == null ? 1 : recordCounts.get('Contact');
        
        List<Account> accs = (List<Account>) createdRecords.get('Account');
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < count; i++) {
            Contact con = new Contact(
                FirstName = 'CS Test',
                LastName = 'Contact ' + i,
                Email = 'cstest' + i + '@example.com',
                AccountId = accs[0].Id
            );
            applyCustomFields(con, 'Contact', i);
            contacts.add(con);
        }
        insert contacts;
        createdRecords.put('Contact', contacts);
        return this;
    }

    /**
     * @description This method is used to generate Users (prerequisite for many CS objects)
     * @return CS_TestDataFactoryUtility Current instance for method chaining
     */
    public CS_TestDataFactoryUtility generateUsers() {
        Integer count = recordCounts.get('User') == null ? 1 : recordCounts.get('User');
        
        // Get a standard profile for test users
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        // Clean up any existing test users to avoid duplicates
        try {
            List<User> existingUsers = [SELECT Id FROM User WHERE Username LIKE 'cstestuser%@example.com.%' AND IsActive = true LIMIT 100];
            if (!existingUsers.isEmpty()) {
                for (User existingUser : existingUsers) {
                    existingUser.IsActive = false;
                }
                update existingUsers;
            }
        } catch (Exception e) {
            // Ignore if we can't deactivate existing users
            System.debug(LoggingLevel.INFO,'Could not deactivate existing test users: ' + e.getMessage());
        }

        List<User> users = new List<User>();
        for (Integer i = 0; i < count; i++) {
            // Generate unique identifier using crypto random
            Blob randomBlob = Crypto.generateAesKey(128);
            String uniqueId = EncodingUtil.convertToHex(randomBlob).substring(0, 10);
            User u = new User(
                FirstName = 'CS Test',
                LastName = 'User ' + i,
                Email = 'cstestuser' + i + uniqueId + '@example.com',
                Username = 'cstestuser' + i + uniqueId + '@example.com.' + System.currentTimeMillis(),
                Alias = 'cstu' + i,
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = standardProfile.Id,
                IsActive = true
            );
            applyCustomFields(u, 'User', i);
            users.add(u);
        }
        insert users;
        createdRecords.put('User', users);
        return this;
    }

    /**
     * @description This method is used to generate Cases
     * @return CS_TestDataFactoryUtility Current instance for method chaining
     */
    public CS_TestDataFactoryUtility generateCases() {
        if (!createdRecords.containsKey('Account')) generateAccounts();
        if (!createdRecords.containsKey('Contact')) generateContacts();

        Integer count = recordCounts.get('Case') == null ? 1 : recordCounts.get('Case');
        List<Account> accs = (List<Account>) createdRecords.get('Account');
        List<Contact> cons = (List<Contact>) createdRecords.get('Contact');

        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < count; i++) {
            Case c = new Case(
                Subject = 'CS Test Case ' + i,
                AccountId = accs[0].Id,
                ContactId = cons[0].Id,
                Status = 'New',
                Priority = 'Medium',
                Origin = 'Internal'
            );
            applyCustomFields(c, 'Case', i);
            cases.add(c);
        }
        insert cases;
        createdRecords.put('Case', cases);
        return this;
    }

    /**
     * @description This method is used to generate Aha_Ideas__c
     * @return CS_TestDataFactoryUtility Current instance for method chaining
     */
    public CS_TestDataFactoryUtility generateAhaIdeas() {
        Integer count = recordCounts.get('Aha_Ideas__c') == null ? 1 : recordCounts.get('Aha_Ideas__c');

        List<Aha_Ideas__c> ahaIdeas = new List<Aha_Ideas__c>();
        for (Integer i = 0; i < count; i++) {
            Aha_Ideas__c idea = new Aha_Ideas__c(
                Name = 'CS Test Aha Idea ' + i
            );
            applyCustomFields(idea, 'Aha_Ideas__c', i);
            ahaIdeas.add(idea);
        }
        insert ahaIdeas;
        createdRecords.put('Aha_Ideas__c', ahaIdeas);
        return this;
    }

    /**
     * @description This method is used to generate Aha_Idea_Link__c
     * @return CS_TestDataFactoryUtility Current instance for method chaining
     */
    public CS_TestDataFactoryUtility generateAhaIdeaLinks() {
        if (!createdRecords.containsKey('Aha_Ideas__c')) generateAhaIdeas();
        
        Integer count = recordCounts.get('Aha_Idea_Link__c') == null ? 1 : recordCounts.get('Aha_Idea_Link__c');
        List<Aha_Ideas__c> ahaIdeas = (List<Aha_Ideas__c>) createdRecords.get('Aha_Ideas__c');

        List<Aha_Idea_Link__c> ahaIdeaLinks = new List<Aha_Idea_Link__c>();
        for (Integer i = 0; i < count; i++) {
            Aha_Idea_Link__c link = new Aha_Idea_Link__c(
                Aha_Ideas__c = ahaIdeas[0].Id
            );
            applyCustomFields(link, 'Aha_Idea_Link__c', i);
            ahaIdeaLinks.add(link);
        }
        insert ahaIdeaLinks;
        createdRecords.put('Aha_Idea_Link__c', ahaIdeaLinks);
        return this;
    }

    /**
     * @description This method is used to generate Cluster__c
     * @return CS_TestDataFactoryUtility Current instance for method chaining
     */
    public CS_TestDataFactoryUtility generateClusters() {
        Integer count = recordCounts.get('Cluster__c') == null ? 1 : recordCounts.get('Cluster__c');

        // Clean up any existing test clusters to avoid duplicates
        try {
            List<Cluster__c> existingClusters = [SELECT Id FROM Cluster__c WHERE Name LIKE 'CS Test Cluster%' LIMIT 100];
            if (!existingClusters.isEmpty()) {
                delete existingClusters;
            }
        } catch (Exception e) {
            // Ignore if we can't delete existing records
            System.debug(LoggingLevel.INFO,'Could not delete existing test clusters: ' + e.getMessage());
        }

        List<Cluster__c> clusters = new List<Cluster__c>();
        for (Integer i = 0; i < count; i++) {
            // Generate a unique UUID for each cluster using crypto random
            Blob randomBlob = Crypto.generateAesKey(128);
            String uniqueId = EncodingUtil.convertToHex(randomBlob).substring(0, 12) + i + System.currentTimeMillis();
            Cluster__c cluster = new Cluster__c(
                UUID__c = uniqueId,
                Name = 'CS Test Cluster ' + i + ' ' + uniqueId.substring(0, 8)
            );
            applyCustomFields(cluster, 'Cluster__c', i);
            clusters.add(cluster);
        }
        insert clusters;
        createdRecords.put('Cluster__c', clusters);
        return this;
    }

    /**
     * @description This method is used to generate Escalation__c
     * @return CS_TestDataFactoryUtility Current instance for method chaining
     */
    public CS_TestDataFactoryUtility generateEscalations() {
        if (!createdRecords.containsKey('Case')) generateCases();

        Integer count = recordCounts.get('Escalation__c') == null ? 1 : recordCounts.get('Escalation__c');
        List<Case> cases = (List<Case>) createdRecords.get('Case');

        List<Escalation__c> escalations = new List<Escalation__c>();
        for (Integer i = 0; i < count; i++) {
            Escalation__c esc = new Escalation__c(
                Case__c = cases[0].Id
            );
            applyCustomFields(esc, 'Escalation__c', i);
            escalations.add(esc);
        }
        insert escalations;
        createdRecords.put('Escalation__c', escalations);
        return this;
    }

    /**
     * @description This method is used to generate AccountAuditLog__c
     * @return CS_TestDataFactoryUtility Current instance for method chaining
     */
    public CS_TestDataFactoryUtility generateAccountAuditLogs() {
        if (!createdRecords.containsKey('User')) generateUsers();
        if (!createdRecords.containsKey('Account')) generateAccounts();

        Integer count = recordCounts.get('AccountAuditLog__c') == null ? 1 : recordCounts.get('AccountAuditLog__c');
        List<User> users = (List<User>) createdRecords.get('User');
        List<Account> accounts = (List<Account>) createdRecords.get('Account');

        List<AccountAuditLog__c> auditLogs = new List<AccountAuditLog__c>();
        for (Integer i = 0; i < count; i++) {
            AccountAuditLog__c log = new AccountAuditLog__c();
            // Set User__c if it exists in the object
            if (users != null && !users.isEmpty()) {
                try {
                    log.put('User__c', users[0].Id);
                } catch (Exception e) {
                    System.debug(LoggingLevel.INFO,'Skipping User__c field for AccountAuditLog__c: ' + e.getMessage());
                }
            }
            // Set Account__c if it exists in the object
            if (accounts != null && !accounts.isEmpty()) {
                try {
                    log.put('Account__c', accounts[0].Id);
                } catch (Exception e) {
                    System.debug(LoggingLevel.INFO,'Skipping Account__c field for AccountAuditLog__c: ' + e.getMessage());
                }
            }
            applyCustomFields(log, 'AccountAuditLog__c', i);
            auditLogs.add(log);
        }
        insert auditLogs;
        createdRecords.put('AccountAuditLog__c', auditLogs);
        return this;
    }

    /**
     * @description This method is used to generate Case_Audit__c
     * @return CS_TestDataFactoryUtility Current instance for method chaining
     */
    public CS_TestDataFactoryUtility generateCaseAudits() {
        if (!createdRecords.containsKey('Case')) generateCases();

        Integer count = recordCounts.get('Case_Audit__c') == null ? 1 : recordCounts.get('Case_Audit__c');
        List<Case> cases = (List<Case>) createdRecords.get('Case');

        List<Case_Audit__c> caseAudits = new List<Case_Audit__c>();
        for (Integer i = 0; i < count; i++) {
            Case_Audit__c audit = new Case_Audit__c();
            if (cases != null && !cases.isEmpty()) {
                try {
                    audit.put('Case__c', cases[0].Id);
                } catch (Exception e) {
                    System.debug(LoggingLevel.INFO,'Skipping Case__c field for Case_Audit__c: ' + e.getMessage());
                }
            }
            applyCustomFields(audit, 'Case_Audit__c', i);
            caseAudits.add(audit);
        }
        insert caseAudits;
        createdRecords.put('Case_Audit__c', caseAudits);
        return this;
    }

    /**
     * @description This method is used to generate Community_Feed__c
     * @return CS_TestDataFactoryUtility Current instance for method chaining
     */
    public CS_TestDataFactoryUtility generateCommunityFeeds() {
        if (!createdRecords.containsKey('User')) generateUsers();

        Integer count = recordCounts.get('Community_Feed__c') == null ? 1 : recordCounts.get('Community_Feed__c');
        List<User> users = (List<User>) createdRecords.get('User');

        List<Community_Feed__c> feeds = new List<Community_Feed__c>();
        for (Integer i = 0; i < count; i++) {
            Community_Feed__c feed = new Community_Feed__c();
            if (users != null && !users.isEmpty()) {
                try {
                    feed.put('Author__c', users[0].Id);
                } catch (Exception e) {
                    System.debug(LoggingLevel.INFO,'Skipping Author__c field for Community_Feed__c: ' + e.getMessage());
                }
            }
            applyCustomFields(feed, 'Community_Feed__c', i);
            feeds.add(feed);
        }
        insert feeds;
        createdRecords.put('Community_Feed__c', feeds);
        return this;
    }

    /**
     * @description This method is used to generate Customer_Subscription__c
     * @return CS_TestDataFactoryUtility Current instance for method chaining
     */
    public CS_TestDataFactoryUtility generateCustomerSubscriptions() {
        if (!createdRecords.containsKey('Account')) generateAccounts();

        Integer count = recordCounts.get('Customer_Subscription__c') == null ? 1 : recordCounts.get('Customer_Subscription__c');
        List<Account> accs = (List<Account>) createdRecords.get('Account');

        List<Customer_Subscription__c> subscriptions = new List<Customer_Subscription__c>();
        for (Integer i = 0; i < count; i++) {
            Customer_Subscription__c sub = new Customer_Subscription__c();
            if (accs != null && !accs.isEmpty()) {
                try {
                    sub.put('Account__c', accs[0].Id);
                } catch (Exception e) {
                    System.debug(LoggingLevel.INFO,'Skipping Account__c field for Customer_Subscription__c: ' + e.getMessage());
                }
            }
            applyCustomFields(sub, 'Customer_Subscription__c', i);
            subscriptions.add(sub);
        }
        insert subscriptions;
        createdRecords.put('Customer_Subscription__c', subscriptions);
        return this;
    }

    /**
     * @description This method is used to generate Playbook__c
     * @return CS_TestDataFactoryUtility Current instance for method chaining
     */
    public CS_TestDataFactoryUtility generatePlaybooks() {
        if (!createdRecords.containsKey('Account')) generateAccounts();

        Integer count = recordCounts.get('Playbook__c') == null ? 1 : recordCounts.get('Playbook__c');
        List<Account> accounts = (List<Account>) createdRecords.get('Account');

        List<Playbook__c> playbooks = new List<Playbook__c>();
        for (Integer i = 0; i < count; i++) {
            Playbook__c playbook = new Playbook__c(
                Name = 'CS Test Playbook ' + i
            );
            // Set Account__c if it exists in the object
            if (accounts != null && !accounts.isEmpty()) {
                try {
                    playbook.put('Account__c', accounts[0].Id);
                } catch (Exception e) {
                    System.debug(LoggingLevel.INFO,'Skipping Account__c field for Playbook__c: ' + e.getMessage());
                }
            }
            applyCustomFields(playbook, 'Playbook__c', i);
            playbooks.add(playbook);
        }
        insert playbooks;
        createdRecords.put('Playbook__c', playbooks);
        return this;
    }

    /**
     * @description This method is used to generate Success_Plan__c
     * @return CS_TestDataFactoryUtility Current instance for method chaining
     */
    public CS_TestDataFactoryUtility generateSuccessPlans() {
        if (!createdRecords.containsKey('Account')) generateAccounts();

        Integer count = recordCounts.get('Success_Plan__c') == null ? 1 : recordCounts.get('Success_Plan__c');
        List<Account> accs = (List<Account>) createdRecords.get('Account');

        List<Success_Plan__c> successPlans = new List<Success_Plan__c>();
        for (Integer i = 0; i < count; i++) {
            Success_Plan__c plan = new Success_Plan__c(
                Name = 'CS Test Success Plan ' + i
            );
            if (accs != null && !accs.isEmpty()) {
                try {
                    plan.put('Account__c', accs[0].Id);
                } catch (Exception e) {
                    System.debug(LoggingLevel.INFO,'Skipping Account__c field for Success_Plan__c: ' + e.getMessage());
                }
            }
            applyCustomFields(plan, 'Success_Plan__c', i);
            successPlans.add(plan);
        }
        insert successPlans;
        createdRecords.put('Success_Plan__c', successPlans);
        return this;
    }

    /**
     * @description This method is used to generate Tasks__c
     * @return CS_TestDataFactoryUtility Current instance for method chaining
     */
    public CS_TestDataFactoryUtility generateTasks() {
        Integer count = recordCounts.get('Tasks__c') == null ? 1 : recordCounts.get('Tasks__c');

        List<Tasks__c> tasks = new List<Tasks__c>();
        for (Integer i = 0; i < count; i++) {
            Tasks__c task = new Tasks__c();
            applyCustomFields(task, 'Tasks__c', i);
            tasks.add(task);
        }
        insert tasks;
        createdRecords.put('Tasks__c', tasks);
        return this;
    }

    /**
     * @description This method is used to generate Release_Version__c
     * @return CS_TestDataFactoryUtility Current instance for method chaining
     */
    public CS_TestDataFactoryUtility generateReleaseVersions() {
        Integer count = recordCounts.get('Release_Version__c') == null ? 1 : recordCounts.get('Release_Version__c');

        List<Release_Version__c> versions = new List<Release_Version__c>();
        for (Integer i = 0; i < count; i++) {
            Release_Version__c version = new Release_Version__c(
                Name = 'CS Test Release Version ' + i
            );
            applyCustomFields(version, 'Release_Version__c', i);
            versions.add(version);
        }
        insert versions;
        createdRecords.put('Release_Version__c', versions);
        return this;
    }

    /**
     * @description This method is used to generate Catalog__c
     * @return CS_TestDataFactoryUtility Current instance for method chaining
     */
    public CS_TestDataFactoryUtility generateCatalogs() {
        Integer count = recordCounts.get('Catalog__c') == null ? 1 : recordCounts.get('Catalog__c');

        List<Catalog__c> catalogs = new List<Catalog__c>();
        for (Integer i = 0; i < count; i++) {
            Catalog__c catalog = new Catalog__c();
            applyCustomFields(catalog, 'Catalog__c', i);
            catalogs.add(catalog);
        }
        insert catalogs;
        createdRecords.put('Catalog__c', catalogs);
        return this;
    }

    /**
     * @description Generate base CS data (Account, Contact, User, Case)
     * @return CS_TestDataFactoryUtility Current instance for method chaining
     */
    public CS_TestDataFactoryUtility generateBaseCSData() {
        return generateAccounts()
            .generateContacts()
            .generateUsers()
            .generateCases();
    }

    /**
     * @description Generate comprehensive CS test data
     * @return CS_TestDataFactoryUtility Current instance for method chaining
     */
    public CS_TestDataFactoryUtility generateComprehensiveCSData() {
        return generateBaseCSData()
            .generateAhaIdeas()
            .generateAhaIdeaLinks()
            .generateClusters()
            .generateEscalations()
            .generateAccountAuditLogs()
            .generateCaseAudits()
            .generateCommunityFeeds()
            .generateCustomerSubscriptions()
            .generatePlaybooks()
            .generateSuccessPlans()
            .generateTasks()
            .generateReleaseVersions()
            .generateCatalogs();
    }

    // --- Helper ---
    private void applyCustomFields(SObject record, String sObjectType, Integer index) {

        Map<String, Object> defaultFields = CS_TestDataFactoryDefaults.getDefaultFields(sObjectType);

        if (commonFields != null && commonFields.containsKey(sObjectType)) {
            defaultFields.putAll(commonFields.get(sObjectType));
        }

        // Get list of fields that have indexed values defined
        Set<String> indexedFieldNames = new Set<String>();
        if (indexedFields.containsKey(sObjectType)) {
            indexedFieldNames.addAll(indexedFields.get(sObjectType).keySet());
        }

        // Apply default fields, but skip fields that have indexed values defined
        for (String fieldName : defaultFields.keySet()) {
            if (!indexedFieldNames.contains(fieldName)) {
                try {
                    Object fieldValue = defaultFields.get(fieldName);
                    if (fieldValue != null) {
                        record.put(fieldName, fieldValue);
                    }
                } catch (Exception e) {
                    // Field doesn't exist or is not editable - skip it
                    System.debug(LoggingLevel.INFO,'Skipping field ' + fieldName + ' for ' + sObjectType + ': ' + e.getMessage());
                }
            }
        }

        // Apply indexed fields only when values are available
        if (indexedFields.containsKey(sObjectType)) {
            for (String f : indexedFields.get(sObjectType).keySet()) {
                List<Object> vals = indexedFields.get(sObjectType).get(f);
                if (index < vals.size()) {
                    try {
                        record.put(f, vals[index]);
                    } catch (Exception e) {
                        // Field doesn't exist or is not editable - skip it
                        System.debug(LoggingLevel.INFO,'Skipping indexed field ' + f + ' for ' + sObjectType + ': ' + e.getMessage());
                    }
                }
                // If index >= vals.size(), field remains null (no default applied)
            }
        }
    }
}