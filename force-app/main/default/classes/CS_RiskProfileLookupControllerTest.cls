/**
* @description Test class for CS_RiskProfileLookupController functionality.
* @test
* @author Raveesh Layal
* @date 2025-08-01
*/
@IsTest
public class CS_RiskProfileLookupControllerTest {
    
    /**
* @description Setup common test data such as settings, account, and entitlement.
*/
    @testsetup static void setup(){
        ShGl_DisableBusinessLogic__c customSetting = ShGl_DisableBusinessLogic__c.getOrgDefaults();
        customSetting.Disable_Entitlement_Validation_Rules__c = true;
        upsert customSetting ShGl_DisableBusinessLogic__c.Id;
        
        TriggerControl__c entitlementTriggerControl = TriggerControl__c.getInstance('Entitlement');        
        if (entitlementTriggerControl == null) {
            entitlementTriggerControl = new TriggerControl__c(
                Name = 'Entitlement',
                DisableTrigger__c = true
            );
            insert entitlementTriggerControl;
        } else {
            entitlementTriggerControl.DisableTrigger__c = true;
            update entitlementTriggerControl;
        }
        Account act = new Account(
            Name = 'Customer',
            Phone = '123-456-7890',
            AccountNumber = 'Test',
            BillingStreet = '123 street',
            BillingCity = 'Santa Clara', 
            BillingState = 'California',
            BillingPostalCode = '95050',
            BillingCountry = 'United States',
            ShippingStreet = '123 street',
            ShippingCity = 'Santa Clara',
            ShippingState = 'California',
            ShippingPostalCode = '95050',
            ShippingCountry = 'United States'
        );
        insert act;
        Entitlement secondEnt = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        secondEnt.AccountId = act.Id;
        secondEnt.StartDate = Date.today().addDays(-365);
        secondEnt.EndDate = Date.today().addDays(365);
        secondEnt.Renewable__c = true;
        secondEnt.Type = 'Phone Support';
        secondEnt.Name = 'CS_RiskTest';
        insert secondEnt;
    }
    
    /**
* @description Helper method to create a JSON string for lookup component testing.
*
* @param lookupFx The lookup function name.
* @param searchTerm The term to search for.
* @param sObjectName The API name of the sObject to search.
* @param field The main field to display in the lookup results.
* @param subField A secondary field to display alongside the main field.
* @param SortBy The field by which results should be sorted.
* @param SearchBy The field to use for searching.
* @param maxResults Maximum number of results to return.
* @param selectedIds A list of already selected record IDs to be included.
* @param additionalParams A map of additional parameters to customize the lookup behavior.
* @return String A JSON-formatted string representing the lookup data.
*/
    private static String createTestLookupJSON(String lookupFx, String searchTerm, String sObjectName, String field, String subField,String SortBy,String SearchBy, Integer maxResults, List<String> selectedIds, Map<String, List<String>> additionalParams) {
        CS_RiskProfileLookupController.Lookup lookup = new CS_RiskProfileLookupController.Lookup();
        lookup.lookupFx = lookupFx;
        
        CS_RiskProfileLookupController.LookupFxParam lookupFxParam = new CS_RiskProfileLookupController.LookupFxParam();
        lookupFxParam.searchTerm = searchTerm != null ? searchTerm : '';
        lookupFxParam.sObjectName = sObjectName != null ? sObjectName : 'Account';
        lookupFxParam.field = field != null ? field : 'Name';
        lookupFxParam.subField = subField;
        lookupFxParam.sortBy = SortBy;
        lookupFxParam.searchBy = SearchBy;
        lookupFxParam.maxResults = maxResults != null ? maxResults : 10;
        lookupFxParam.selectedIds = selectedIds != null ? selectedIds : new List<String>();
        lookupFxParam.additional = additionalParams != null ? additionalParams : new Map<String, List<String>>();
        
        lookup.lookupFxParam = lookupFxParam;
        
        return JSON.serialize(lookup);
    }
    
    /**
* @description Tests lookup with Account entitlements.
*/
    @IsTest
    static void testSearchLookupRecordsWithAccountEntitlements() {
        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'System Administrator'].Id;
        
        User u = new User(
            ProfileId = profileId,
            FirstName = 'Test User',
            LastName = 'last',
            Email = 'testuser@test.com',
            Username = System.now().millisecond() + 'testuser@test.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = String.valueOf(UserInfo.getTimeZone()),
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            IsActive = true);
        insert u;
        
        Test.startTest();
        System.runAs(u){
            Map<String, List<String>> additionalParams = new Map<String, List<String>>{
                'accountId' => new List<String>{'someAccountId'}
            };
                String lookupJSON = createTestLookupJSON('accountEntitlements', '', 'Entitlement', 'Name', 'SubType__c','AssetId','Type', 10, new List<String>{'testOpp'}, additionalParams);
            List<CS_RiskProfileLookupController.LookupSearchResult> results = CS_RiskProfileLookupController.searchLookupRecords(lookupJSON);
            Test.stopTest();
            System.assertNotEquals(null, results, 'Results should not be null');
            System.assert(results.size() <= 5, 'Results should respect maxResults limit');
        }
    }
    
    /**
* @description Tests lookup with risk profile product features.
*/
    @IsTest
    static void testSearchLookupRecordsWithRiskProfilePDMs() {
        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'System Administrator'].Id;
        
        User u = new User(
            ProfileId = profileId,
            FirstName = 'Test User',
            LastName = 'last',
            Email = 'testuser@test.com',
            Username = System.now().millisecond() + 'testuser@test.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = String.valueOf(UserInfo.getTimeZone()),
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            IsActive = true);
        insert u;
        
        System.runAs(u){
            Map<String, List<String>> additionalParams = new Map<String, List<String>>{
                'Entitlement__c' => new List<String>{'someEntitlementId'}
            };
                String lookupJSON = createTestLookupJSON('riskProfilePDMs', 'Sample', 'Product_Feature__c', 'Name','Feature__c','Marketing__c','Feature_Type__c',3, new List<String>(), additionalParams);
            
            Test.startTest();
            List<CS_RiskProfileLookupController.LookupSearchResult> results = CS_RiskProfileLookupController.searchLookupRecords(lookupJSON);
            Test.stopTest();
            
            System.assertNotEquals(null, results, 'Results should not be null');
            System.assert(results.size() <= 3, 'Results should respect maxResults limit');
        }
    }
    
    /**
* @description Tests lookup with opportunity product features.
*/
    @IsTest
    static void testSearchLookupRecordsWithOpportunityPDMs() {
        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'System Administrator'].Id;
        
        User u = new User(
            ProfileId = profileId,
            FirstName = 'Test User',
            LastName = 'last',
            Email = 'testuser@test.com',
            Username = System.now().millisecond() + 'testuser@test.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = String.valueOf(UserInfo.getTimeZone()),
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            IsActive = true);
        insert u;
        
        System.runAs(u){
            Entitlement ent = [SELECT Id,AccountId FROM Entitlement LIMIT 1];
            Map<String, List<String>> additionalParams = new Map<String, List<String>>{
                'Entitlement__c' => new List<String>{ent.Id},
                    'accountId' => new List<String>{ent.AccountId}
            };
                String lookupJSON = createTestLookupJSON('opportunityPDMs', 'Sample', 'Product_Feature__c', 'Name','Feature__c','Marketing__c','Feature_Type__c',3, new List<String>(), additionalParams);
            
            Test.startTest();
            List<CS_RiskProfileLookupController.LookupSearchResult> results = CS_RiskProfileLookupController.searchLookupRecords(lookupJSON);
            Test.stopTest();
            
            System.assertNotEquals(null, results, 'Results should not be null');
            System.assert(results.size() <= 3, 'Results should respect maxResults limit');
        }
    }
    
    /**
* @description Tests lookup with entitlement records.
*/
    @IsTest
    static void testSearchLookupRecordsWithEntitlement() {
        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'System Administrator'].Id;
        
        User u = new User(
            ProfileId = profileId,
            FirstName = 'Test User',
            LastName = 'last',
            Email = 'testuser@test.com',
            Username = System.now().millisecond() + 'testuser@test.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = String.valueOf(UserInfo.getTimeZone()),
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            IsActive = true);
        insert u;
        
        System.runAs(u){
            Account acc = [SELECT Id FROM Account WHERE Name = 'Customer' LIMIT 1];
            Map<String, List<String>> additionalParams = new Map<String, List<String>>{
                'accountId' => new List<String>{acc.Id}
            };
                String lookupJSON = createTestLookupJSON('entitlement', '', 'Entitlement', 'Name', 'SubType__c','AssetId','Type', 10, new List<String>{'testOpp'}, additionalParams);
            Test.startTest();
            List<CS_RiskProfileLookupController.LookupSearchResult> results = CS_RiskProfileLookupController.searchLookupRecords(lookupJSON);
            Test.stopTest();
            
            System.assertNotEquals(null, results, 'Results should not be null');
            System.assert(results.size() <= 5, 'Results should respect maxResults limit');
        }
    }
    
    /**
* @description Tests lookup with account product features.
*/
    @IsTest
    static void testSearchLookupRecordsWithAccountPDMs() {
        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'System Administrator'].Id;
        
        User u = new User(
            ProfileId = profileId,
            FirstName = 'Test User',
            LastName = 'last',
            Email = 'testuser@test.com',
            Username = System.now().millisecond() + 'testuser@test.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = String.valueOf(UserInfo.getTimeZone()),
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            IsActive = true);
        insert u;
        
        System.runAs(u){
            Map<String, List<String>> additionalParams = new Map<String, List<String>>{
                'accountId' => new List<String>{'someAccountId'},
                    'Entitlement__c' => new List<String>{'someEntitlementId'}
            };
                String lookupJSON = createTestLookupJSON('accountPDMs', 'Sample', 'Product_Feature__c', 'Name','Feature__c','Marketing__c','Feature_Type__c',3, new List<String>{'testOpp'}, additionalParams);
            
            Test.startTest();
            List<CS_RiskProfileLookupController.LookupSearchResult> results = CS_RiskProfileLookupController.searchLookupRecords(lookupJSON);
            Test.stopTest();
            
            System.assertNotEquals(null, results, 'Results should not be null');
            System.assert(results.size() <= 5, 'Results should respect maxResults limit');
        }
    }
    
    /**
* @description Tests lookup with opportunity entitlements.
*/
    @IsTest
    static void testSearchLookupRecordsWithOpportunityEntitlements() {
        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'System Administrator'].Id;
        
        User u = new User(
            ProfileId = profileId,
            FirstName = 'Test User',
            LastName = 'last',
            Email = 'testuser@test.com',
            Username = System.now().millisecond() + 'testuser@test.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = String.valueOf(UserInfo.getTimeZone()),
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            IsActive = true);
        insert u;
        
        System.runAs(u){
            Map<String, List<String>> additionalParams = new Map<String, List<String>>{
                'Opportunity__c' => new List<String>{'someOpportunityId'},
                    'accountId' => new List<String>{'someAccountId'}
            };
                String lookupJSON = createTestLookupJSON('opportunityEntitlements', 'Sample', 'Entitlement', 'Name', 'SubType__c','AssetId','Type', 10, new List<String>{'testOpp'}, additionalParams);
            
            Test.startTest();
            List<CS_RiskProfileLookupController.LookupSearchResult> results = CS_RiskProfileLookupController.searchLookupRecords(lookupJSON);
            Test.stopTest();
            
            System.assertNotEquals(null, results, 'Results should not be null');
            System.assert(results.size() <= 10, 'Results should respect maxResults limit');
        }
    }
    
    /**
* @description Tests watchers lookup functionality.
*/
    @IsTest
    static void testWatchersMethod() {
        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'System Administrator'].Id;
        
        User u = new User(
            ProfileId = profileId,
            FirstName = 'Test User',
            LastName = 'last',
            Email = 'testuser@test.com',
            Username = System.now().millisecond() + 'testuser@test.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = String.valueOf(UserInfo.getTimeZone()),
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            IsActive = true);
        insert u;
        
        System.runAs(u){
            Map<String, List<String>> additionalParams = new Map<String, List<String>>();
            String lookupJSON = createTestLookupJSON('riskProfileWatcher', '', 'User', 'Name', 'Email','Name','', 10, new List<String>{u.Id}, additionalParams);
            
            Test.startTest();
            List<CS_RiskProfileLookupController.LookupSearchResult> results = CS_RiskProfileLookupController.searchLookupRecords(lookupJSON);
            Test.stopTest();
            
            System.assertNotEquals(null, results, 'Results should not be null');
        }
    }
    
    /**
* @description Tests retrieval of a recently created record.
*/
    @IsTest
    static void testGetRecentlyCreatedRecord() {
        // Create a test Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        testAccount.Type = 'MSP';
        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'System Administrator'].Id;
        
        User u = new User(
            ProfileId = profileId,
            FirstName = 'Test User',
            LastName = 'last',
            Email = 'testuser@test.com',
            Username = System.now().millisecond() + 'testuser@test.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = String.valueOf(UserInfo.getTimeZone()),
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            IsActive = true);
        insert u;
        
        System.runAs(u){
            Test.startTest();
            update testAccount;
            CS_RiskProfileLookupController.LookupSearchResult result = CS_RiskProfileLookupController.getRecentlyCreatedRecord('Account', testAccount.Id, 'Name', null);
            Test.stopTest();
            
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assertEquals(testAccount.Id, result.Id, 'Result ID should match test Account ID');
            System.assertEquals('Test Account', result.title, 'Result title should match test Account name');
        }
    }
    
    /**
* @description Tests retrieval of a recently created record with sub-field.
*/
    @IsTest
    static void testGetRecentlyCreatedRecordWithSubField() {
        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'System Administrator'].Id;
        
        User u = new User(
            ProfileId = profileId,
            FirstName = 'Test User',
            LastName = 'last',
            Email = 'testuser@test.com',
            Username = System.now().millisecond() + 'testuser@test.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = String.valueOf(UserInfo.getTimeZone()),
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            IsActive = true);
        insert u;
        
        System.runAs(u){
            // Create a test Contact
            Contact testContact = new Contact(FirstName = 'John', LastName = 'Doe', AccountId = null);
            insert testContact;
            
            Test.startTest();
            CS_RiskProfileLookupController.LookupSearchResult result = CS_RiskProfileLookupController.getRecentlyCreatedRecord('Contact', testContact.Id, 'LastName', 'FirstName');
            Test.stopTest();
            
            System.assertNotEquals(null, result, 'Result should not be null');
            System.assertEquals(testContact.Id, result.Id, 'Result ID should match test Contact ID');
            System.assertEquals('Doe', result.title, 'Result title should match test Contact LastName');
            System.assertEquals('John', result.subtitle, 'Result subtitle should match test Contact FirstName');
        }
    }
    
    /**
* @description Tests governance owners retrieval utility.
*/
    @isTest
    static void testGetGovernanceOwners() {
        Test.startTest();
        
        // Create a group to simulate the governance queue
        Group governanceGroup = new Group(
            Name = 'Risk Profile Governance Group',
            DeveloperName = 'Risk_Profile_Governance_Queue',
            Type = 'Queue'
        );
        insert governanceGroup;
        
        // Create users to be added to the group
        User user1 = new User(
            Username = 'userxyz@test.com',
            Email = 'userabc@test.com',
            Alias = 'u1',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LastName = 'User1',
            IsActive = true
        );
        insert user1;
        
        User user2 = new User(
            Username = 'userasdf@test.com',
            Email = 'user234@test.com',
            Alias = 'u2',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LastName = 'User2',
            IsActive = true
        );
        insert user2;
        
        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'System Administrator'].Id;
        
        User u = new User(
            ProfileId = profileId,
            FirstName = 'Test User',
            LastName = 'last',
            Email = 'testuser@test.com',
            Username = System.now().millisecond() + 'testuser@test.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = String.valueOf(UserInfo.getTimeZone()),
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            IsActive = true);
        insert u;
        
        System.runAs(u){
            // Add users to the governance group
            GroupMember groupMember1 = new GroupMember(GroupId = governanceGroup.Id, UserOrGroupId = user1.Id);
            GroupMember groupMember2 = new GroupMember(GroupId = governanceGroup.Id, UserOrGroupId = user2.Id);
            insert new List<GroupMember>{groupMember1, groupMember2};
                
                // Call the method to test
                List<Id> ownerIds = CS_RiskMitigationUtility.getGovernanceOwners();
            
            Test.stopTest();
            System.assertNotEquals(null, ownerIds, 'Owner IDs list should not be null');
        }
    }
    
    /**
* @description Tests retrieval of watchers for risk profiles.
*/
    @IsTest
    static void testGetWatchers() {
        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'System Administrator'].Id;
        
        User u = new User(
            ProfileId = profileId,
            FirstName = 'Test User',
            LastName = 'last',
            Email = 'testuser@test.com',
            Username = System.now().millisecond() + 'testuser@test.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = String.valueOf(UserInfo.getTimeZone()),
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            IsActive = true);
        insert u;
        
        Test.startTest();
        System.runAs(u){
            // Create an empty list of Risk_Profile__c records
            List<Risk_Profile__c> riskProfiles = new List<Risk_Profile__c>();
            
            // Call the getWatchers method with the empty list
            Map<Id, Set<Id>> result = CS_RiskMitigationUtility.getWatchers(riskProfiles);
            
            // Assert that the result is an empty map
            System.assertEquals(0, result.size(), 'Expected no watchers as input list is empty');
        }
        Test.stopTest();
    }
    
    /**
* @description Tests Account triggers logic handling.
*/
    @IsTest
    static void testAccountTriggersHandler() {
        // Create a test Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Update fields to trigger the logic
        testAccount.Type = 'MSP';
        testAccount.Contract_Negotiation__c = true;
        testAccount.EULA_revision_Required__c = true;
        testAccount.CX_Score_Status__c = 'Fragile';
        
        Test.startTest();
        update testAccount;
        
        // Update again to test further changes
        testAccount.Type = 'Prospect';
        testAccount.EULA_revision_Required__c = false;
        update testAccount;
        
        
        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'System Administrator'].Id;
        
        User u = new User(
            ProfileId = profileId,
            FirstName = 'Test User',
            LastName = 'last',
            Email = 'testuser@test.com',
            Username = System.now().millisecond() + 'testuser@test.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = String.valueOf(UserInfo.getTimeZone()),
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            IsActive = true);
        insert u;
        
        System.runAs(u){
            
            // Query the updated account to verify changes
            Account result = [SELECT Id, Name, Type, Contract_Negotiation__c, EULA_revision_Required__c, CX_Score_Status__c 
                              FROM Account 
                              WHERE Id = :testAccount.Id];
            
            // Assertions
            System.assertEquals('Test Account', result.Name, 'Account Name should be "Test Account"');
            System.assertEquals('Prospect', result.Type, 'Account Type should be "Prospect"');
            System.assertEquals(false, result.EULA_revision_Required__c, 'EULA Revision Required should be false');
            System.assertEquals(true, result.Contract_Negotiation__c, 'Contract Negotiation should remain true');
            System.assertEquals('Fragile', result.CX_Score_Status__c, 'CX Score Status should remain "Fragile"');
            Test.stopTest();
        }
    }
    /**
* @description Tests setting and getting the relatedRecordId property 
*              in the LookupSearchResult inner class of CS_RiskProfileLookupController.
*/
    @isTest
    static void testLookupSearchResultPropertyCoverage() {
        // Instantiate the inner class
        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'System Administrator'].Id;
        
        User u = new User(
            ProfileId = profileId,
            FirstName = 'Test User',
            LastName = 'last',
            Email = 'testuser@test.com',
            Username = System.now().millisecond() + 'testuser@test.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = String.valueOf(UserInfo.getTimeZone()),
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            IsActive = true);
        insert u;
        
        Test.startTest();
        System.runAs(u){
            CS_RiskProfileLookupController.LookupSearchResult result = 
                new CS_RiskProfileLookupController.LookupSearchResult();
            result.relatedRecordId = 'TestingRelatedID';
            System.assertEquals('TestingRelatedID', result.relatedRecordId);
        }
    }
    /**
* @description Tests setting and getting the recordId property along with 
*              other parameters in the LookupFxParam inner class of CS_RiskProfileLookupController.
*/
    @isTest
    static void testLookupFxParamRecordIdPropertyCoverage() {
        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'System Administrator'].Id;
        
        User u = new User(
            ProfileId = profileId,
            FirstName = 'Test User',
            LastName = 'last',
            Email = 'testuser@test.com',
            Username = System.now().millisecond() + 'testuser@test.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = String.valueOf(UserInfo.getTimeZone()),
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            IsActive = true);
        insert u;
        
        Test.startTest();
        System.runAs(u){
            CS_RiskProfileLookupController.LookupFxParam param = new CS_RiskProfileLookupController.LookupFxParam();
            param.recordId = 'TestingRelatedID'; 
            System.assertEquals('TestingRelatedID', param.recordId);
        }
    }
    
}