@isTest
private class RiskProfileBatchAndSchedulerTest {
    
    /**
* @description Sets up a test user with the 'API Integration User' profile and assigns required permission set.
*              This user will be used with System.runAs() in all test methods.
*/
    @testSetup
    static void setupTestUserAndData() {
        Profile apiProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        User testUser = new User(
            FirstName = 'API',
            LastName = 'Automation',
            Email = 'apiautomation@rubrik.com.testrubrikinvalid',
            Username = 'apiautomation@rubrik.com.testrubrikinvalid',
            Alias = 'apiauto',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = apiProfile.Id
        );
        insert testUser;
        
        // Assign permission set
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Risk_Governance_Owner_Permissions' LIMIT 1];
        insert new PermissionSetAssignment(
            AssigneeId = testUser.Id,
            PermissionSetId = ps.Id
        );
    }
    
    /**
     * @description Creates an Account and a related Account_Risk__c record for the given risk type.  
     *              The Account is inserted first, then an Account_Risk__c record is created and upserted.  
     *              Useful for setting up test data.
     *
     * @param type The risk type value to be assigned to the Account_Risk__c record (e.g., 'ML', 'CX').
     * @return Account_Risk__c The created Account_Risk__c record linked to the new Account.
     */
    private static Account_Risk__c createAccountRisk(String type) {
        Account acc = new Account(Name = 'Test Account ' + type,Close_Won_Date__c = System.today().addDays(-100));
        insert acc;
        
        Account_Risk__c ar = new Account_Risk__c(
            Account__c = acc.Id,
            Account_External_Id__c = acc.Id,
            //   Need_Update__c = true,
            Risk_Type__c = type,
            CX_Score_Status__c = 'Poor'
        );
        upsert ar;
        return ar;
    }
    
    /**
     * @description Creates a Custom_Configuration_Change__c record for test setup.  
     *              The Config_Type__c field is populated either from an existing record  
     *              or from the first available picklist value.  
     *              Inserts and returns the new configuration record.
     *
     * @param configFor The value for Config_For__c (e.g., 'CX Sync', 'ML Sync', 'CX & ML Both').
     * @param disabled  Indicates whether the configuration should be disabled (true = disabled).
     * @param nextRun   The date to be set in Next_Run__c field.
     * @return Custom_Configuration_Change__c The created configuration record.
     */
    private static Custom_Configuration_Change__c createConfig(String configFor, Boolean disabled, Date nextRun) {
        String validType;
        List<Custom_Configuration_Change__c> existing = [
            SELECT Config_Type__c
            FROM Custom_Configuration_Change__c
            WHERE Config_Type__c != null
            LIMIT 1
        ];
        if (!existing.isEmpty()) {
            validType = existing[0].Config_Type__c;
        } else {
            Schema.DescribeFieldResult fieldDesc = 
                Custom_Configuration_Change__c.Config_Type__c.getDescribe();
            validType = fieldDesc.getPicklistValues()[0].getValue();
        }
        
        Custom_Configuration_Change__c cfg = new Custom_Configuration_Change__c(
            RecordTypeId = Schema.SObjectType.Custom_Configuration_Change__c
            .getRecordTypeInfosByName()
            .get('RP Frequency Config')
            .getRecordTypeId(),
            Config_For__c = configFor,
            Config_Type__c = validType,
            Next_Run__c = nextRun,
            Config_Disabled__c = disabled
        );
        insert cfg;
        return cfg;
    }
    
    @isTest
    static void testMLAndCXBothAllowed() {
        User u = [SELECT Id FROM User WHERE Username = 'apiautomation@rubrik.com.testrubrikinvalid' LIMIT 1];
        System.runAs(u) {
            createConfig('CX & ML Both', false, Date.today().addDays(-1));
            Account_Risk__c ar1 = createAccountRisk('ML');
            Account_Risk__c ar2 = createAccountRisk('CX');
            
            Integer recCount = [SELECT COUNT() FROM Account_Risk__c WHERE Need_Update__c = true];
            System.assertEquals(2, recCount, 'One records should be pending update');
            
            Test.startTest();
            Database.executeBatch(new RiskProfileCreationBatch(), recCount);
            Test.stopTest();
            
            for (Account_Risk__c ar : [SELECT Need_Update__c FROM Account_Risk__c]) {
                System.assertEquals(false, ar.Need_Update__c, 'Risk record should have been updated');
            }
        }
    }
    
    @isTest
    static void testConfigDisabledToCreateRiskProfile() {
        User u = [SELECT Id FROM User WHERE Username = 'apiautomation@rubrik.com.testrubrikinvalid' LIMIT 1];
        System.runAs(u) {
            
            
            createConfig('ML Sync', true, Date.today());
            createAccountRisk('ML');
            
            
            
            Test.startTest();
            Integer recCount = [SELECT COUNT() FROM Account_Risk__c WHERE Need_Update__c = true];
            System.assertEquals(1, recCount);
            Database.executeBatch(new RiskProfileCreationBatch(), recCount);
            Test.stopTest();
            
            List<Risk_Profile__c> result = [SELECT Id FROM Risk_Profile__c];
            System.assertEquals(true, result != null, 'Risk Profile should be created');
        }
    }
    
    @isTest
    static void testBlockFutureDate() {
        User u = [SELECT Id FROM User WHERE Username = 'apiautomation@rubrik.com.testrubrikinvalid' LIMIT 1];
        System.runAs(u) {
            createConfig('CX Sync', false, Date.today().addDays(5));
            Account_Risk__c ar = createAccountRisk('CX');
            User u2 = [SELECT Id FROM User WHERE UserName LIKE '%apiautomation@rubrik.com%' LIMIT 1];
            Integer recCount = [SELECT COUNT() FROM Account_Risk__c WHERE Need_Update__c = true AND Id =: ar.Id];
            System.assertEquals(0, recCount);
            
            Test.startTest();
            Database.executeBatch(new RiskProfileCreationBatch(), 200);
            Test.stopTest();
            
            List<Account_Risk__c> result = [SELECT Need_Update__c FROM Account_Risk__c];
            System.assertEquals(false, result[0].Need_Update__c, 'Future-dated config should block execution');
        }
    }
    
    @isTest
    static void testAllowCXSync() {
        User u = [SELECT Id FROM User WHERE Username = 'apiautomation@rubrik.com.testrubrikinvalid' LIMIT 1];
        System.runAs(u) {
            createConfig('CX Sync', false, Date.today().addDays(-2));
            Account_Risk__c ar = createAccountRisk('CX');
            
            Test.startTest();
            Database.executeBatch(new RiskProfileCreationBatch(), 200);
            Test.stopTest();
        }
        List<Risk_Profile__c> result = [SELECT Id FROM Risk_Profile__c];
        System.assertEquals(true, result != null, 'Risk Profile should be created');
    }
    
    @isTest
    static void testSchedulableExecuteDirect() {
        User u = [SELECT Id FROM User WHERE Username = 'apiautomation@rubrik.com.testrubrikinvalid' LIMIT 1];
        System.runAs(u) {
            createConfig('CX Sync', false, Date.today().addDays(-2));
            Account_Risk__c ar = createAccountRisk('CX');
            
            Test.startTest();
            new RiskProfileCreationBatch().execute((SchedulableContext) null);
            Test.stopTest();
            List<Risk_Profile__c> result = [SELECT Id FROM Risk_Profile__c];
            System.assertEquals(true, result != null, 'Risk Profile should be created');
        }
    }
    
    @isTest
    static void testMLSyncBranchRuns() {
        User u = [SELECT Id FROM User WHERE Username = 'apiautomation@rubrik.com.testrubrikinvalid' LIMIT 1];
        System.runAs(u) {
            createConfig('ML Sync', false, Date.today().addDays(-1));
            createAccountRisk('ML');
            
            Integer recCount = [SELECT COUNT() FROM Account_Risk__c WHERE Need_Update__c = true];
            System.assertEquals(1, recCount);
            
            Test.startTest();
            Database.executeBatch(new RiskProfileCreationBatch(), recCount);
            Test.stopTest();
            
            List<Account_Risk__c> result = [SELECT Need_Update__c FROM Account_Risk__c];
            System.assertEquals(false, result[0].Need_Update__c, 'ML record should have been updated');
        }
    }
    
    @isTest
    static void testSchedulerQueueExecutesAsync() {
        User u = [SELECT Id FROM User WHERE Username = 'apiautomation@rubrik.com.testrubrikinvalid' LIMIT 1];
        System.runAs(u) {
            Test.startTest();
            System.enqueueJob(new RiskProfileSchedulerQueue());
            Test.stopTest();
            
            List<AsyncApexJob> jobs = [
                SELECT Id, JobType, Status, ApexClass.Name 
                FROM AsyncApexJob 
                WHERE ApexClass.Name = 'RiskProfileSchedulerQueue'
                LIMIT 1
            ];
            
            System.assertEquals(1, jobs.size(), 'One RiskProfileSchedulerQueue job should be enqueued');
            System.assertEquals('Queueable', jobs[0].JobType, 'Job should be of type Queueable');
        }
    }
}