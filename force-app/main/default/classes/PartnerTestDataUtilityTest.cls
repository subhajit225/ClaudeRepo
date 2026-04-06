/******************************************************************************
* @description       : Comprehensive test class for TestDataFactoryDefaults and PartnerTestDataUtility
* @author            : Ankit Gupta
* @last modified on  : 02-26-2026
* @last modified by  : Harshit Garg
* Modifications Log
* Ver   Date          Author           Modification
* 1.0   11-21-2025    Ankit Gupta      Initial Version
******************************************************************************/
@isTest
public class PartnerTestDataUtilityTest {
    
    @testSetup
    static void setupTestData() {
        // Create basic test data needed for relationships
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account testAccount = new Account(Name = 'Test Partner Account', Type = 'Partner',recordtypeId=devRecordTypeId);
        insert testAccount;
        
        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = testAccount.Id, Email = 'test@test.com.sandbox');
        insert testContact;
        
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = '1 Discovery',
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert testOpp;
        
    }
    
    
    // Test TestDataFactoryDefaults.generateSObjects with common fields only
    @isTest
    static void testGenerateSObjectsWithCommonFields() {
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            
            Map<String, Object> commonFields = new Map<String, Object>{
                'Name' => 'Test Account Generated',
                    'Type' => 'Partner'
                    };
                        
                        List<SObject> accounts = TestDataFactoryDefaults.generateSObjects(3, 'Account', commonFields, null);
            
            Test.stopTest();
            
            Assert.areEqual(3, accounts.size(), 'Should generate 3 accounts');
            Assert.areEqual('Test Account Generated', accounts[0].get('Name'), 'Name should match');
            Assert.areEqual('Partner', accounts[0].get('Type'), 'Type should match');
        }
    }
    
    // Test TestDataFactoryDefaults.generateSObjects with indexed fields
    @isTest
    static void testGenerateSObjectsWithIndexedFields() {
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            
            Map<String, Object> commonFields = new Map<String, Object>{
                'Type' => 'Partner'
                    };
                        
                        Map<String, List<Object>> indexedFields = new Map<String, List<Object>>{
                            'Name' => new List<Object>{'Account 1', 'Account 2', 'Account 3'}
                        };
                            
                            List<SObject> accounts = TestDataFactoryDefaults.generateSObjects(3, 'Account', commonFields, indexedFields);
            
            Test.stopTest();
            
            Assert.areEqual(3, accounts.size(), 'Should generate 3 accounts');
            Assert.areEqual('Account 1', accounts[0].get('Name'), 'First account name should match');
            Assert.areEqual('Account 2', accounts[1].get('Name'), 'Second account name should match');
            Assert.areEqual('Account 3', accounts[2].get('Name'), 'Third account name should match');
        }
    }
    
    // Test createDealRegistrations
    @isTest
    static void testCreateDealRegistrations() {
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            Map<String, Object> additionalFields = new Map<String, Object>{
                'Company__c' => 'Test Company Override'
                    };
                        
                        List<Deal_Registration__c> dealRegs = PartnerTestDataUtility.createDealRegistrations(
                            2, 'Reseller', 'Submitted', additionalFields
                        );
            Test.stopTest();
            Assert.areEqual(2, dealRegs.size(), 'Should create 2 deal registrations');
            Assert.areEqual('Submitted', dealRegs[0].Deal_Registration_Status__c, 'Status should match');
        }
    }
    
    
    // Test createAccounts with record type
    @isTest
    static void testCreateAccountsWithRecordType() {
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            Map<String, Object> additionalFields = new Map<String, Object>{'BillingCity' => 'San Francisco'};
                
                List<Account> accounts = PartnerTestDataUtility.createAccounts(
                    3, 'Partner', 'Partner/Distributor', additionalFields
                );
            Test.stopTest();
            
            Assert.areEqual(3, accounts.size(), 'Should create 3 accounts');
            Assert.areEqual('Partner', accounts[0].Type, 'Type should match');
            Assert.areEqual('San Francisco', accounts[0].BillingCity, 'Additional field should be set');
        }
    }
    
    
    // Test createAccounts without record type
    @isTest
    static void testCreateAccountsWithoutRecordType() {
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            List<Account> accounts = PartnerTestDataUtility.createAccounts(
                2, 'Customer', null, null
            );
            Test.stopTest();
            Assert.areEqual(2, accounts.size(), 'Should create 2 accounts');
            Assert.areEqual('Customer', accounts[0].Type, 'Type should match');
        }
    }
    
    
    // Test createOpportunities
    @isTest
    static void testCreateOpportunities() {
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Account acc = [SELECT Id FROM Account LIMIT 1];
            
            Test.startTest();
            Map<String, Object> additionalFields = new Map<String, Object>{
                'Amount' => 50000
                    };
                        List<Opportunity> opps = PartnerTestDataUtility.createOpportunities(
                            2, '2 Consensus', acc.Id, additionalFields
                        );
            Test.stopTest();
            
            Assert.areEqual(2, opps.size(), 'Should create 2 opportunities');
            Assert.areEqual('2 Consensus', opps[0].StageName, 'Stage should match');
        }
    }
    
    
    // Test createPatchManagers
    @isTest
    static void testCreatePatchManagers() {
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            Map<String, Object> additionalFields = new Map<String, Object>{
                'City__c' => 'City'
                    };
                        List<PatchManager__c> patches = PartnerTestDataUtility.createPatchManagers(
                            2, 'Geographic', UserInfo.getUserId(), additionalFields
                        );
            Test.stopTest();
            Assert.areEqual(2, patches.size(), 'Should create 2 patch managers');
        }
    }
    
    
    // Test createContacts
    @isTest
    static void testCreateContacts() {
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Account acc = [SELECT Id FROM Account LIMIT 1];
            Test.startTest();
            Map<String, Object> additionalFields = new Map<String, Object>{'Title' => 'VP of Sales'};
                List<Contact> contacts = PartnerTestDataUtility.createContacts(
                    3, acc.Id, additionalFields
                );
            Test.stopTest();
            Assert.areEqual(3, contacts.size(), 'Should create 3 contacts');
        }
    }
    
    // Test createLeads
    @isTest
    static void testCreateLeads() {
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            Map<String, Object> additionalFields = new Map<String, Object>{'Industry' => 'Technology'};
                List<Lead> leads = PartnerTestDataUtility.createLeads(
                    2, 'Open', additionalFields
                );
            Test.stopTest();
            
            Assert.areEqual(2, leads.size(), 'Should create 2 leads');
            Assert.areEqual('Open', leads[0].Status, 'Status should match');
        }
    }
    
    
    // Test createUsers
    @isTest
    static void testCreateUsers() {
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            Map<String, Object> additionalFields = new Map<String, Object>{ 'Department' => 'Sales' };
                List<User> users1 = PartnerTestDataUtility.createUsers( 2, 'System Administrator', additionalFields );
            Test.stopTest();
            
            Assert.areEqual(2, users1.size(), 'Should create 2 users');
            Assert.areEqual('Test', users1[0].FirstName, 'FirstName should match');
        }
    }
    
    
    // Test createPartnerRelations
    @isTest
    static void testCreatePartnerRelations() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Map<String, Object> additionalFields = new Map<String, Object>{ 'Involvement_Type__c' => 'Transacting Partner' };
            List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            List<Partner_Relation__c> partnerRelations = PartnerTestDataUtility.createPartnerRelations(
                2, 'Transacting Partner', acc.Id, opp.Id, additionalFields
            );
            Test.stopTest();
            
            Assert.areEqual(2, partnerRelations.size(), 'Should create 2 partner relations');
            Assert.areEqual('Transacting Partner', partnerRelations[0].Involvement_Type__c, 'Involvement type should match');
        }
    }
    
    
    // Test createDRPSEscalations
    @isTest
    static void testCreateDRPSEscalations() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Deal_Registration__c dealReg = new Deal_Registration__c(
            FirstName__c = 'Test',
            LastName__c = 'Deal',
            Email__c = 'test@deal.com.sandbox',
            Company__c = 'Test Company',
            Partner_Lookup__c = acc.Id,
            Opportunity__c = opp.Id,
            RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Reseller')?.getRecordTypeId()
        );
        insert dealReg;
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Map<String, Object> additionalFields = new Map<String, Object>{
                'Status__c' => 'Submitted'
                    };
                        Test.startTest();
            List<DR_PS_Escalation__c> escalations = PartnerTestDataUtility.createDRPSEscalations(
                2, 'Submitted', 'Federal', 'New Deal', dealReg, additionalFields
            );
            Test.stopTest();
            
            Assert.areEqual(2, escalations.size(), 'Should create 2 escalations');
            Assert.areEqual('Submitted', escalations[0].Status__c, 'Status should match');
        }
    }
    
    
    // Test createPartnerPageConfigurations
    @isTest
    static void testCreatePartnerPageConfigurations() {
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            Map<String, Object> additionalFields = new Map<String, Object>{
                'Menu_Group__c' => 'Home'
                    };
                        List<Partner_Page_Configuration__c> configs = PartnerTestDataUtility.createPartnerPageConfigurations(
                            2, 'Menu', 'https://test.com', additionalFields
                        );
            Test.stopTest();
            
            Assert.areEqual(2, configs.size(), 'Should create 2 configurations');
        }
    }
    
    
    // Test createIncentives
    @isTest
    static void testCreateIncentives() {
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Account acc = [SELECT Id FROM Account LIMIT 1];
            Map<String, Object> additionalFields = new Map<String, Object>{
                'Status__c' => 'Approved'
                    };
                        Test.startTest();
            List<Incentives__c> incentives = PartnerTestDataUtility.createIncentives(
                2, 'Transform Accelerator Claim', 'Approved', acc.Id, additionalFields
            );
            Test.stopTest();
            Assert.areEqual(2, incentives.size(), 'Should create 2 incentives');
            Assert.areEqual('Approved', incentives[0].Status__c, 'Status should match');
        }
    }
    
    
    // Test createCountryWithCode
    @isTest
    static void testCreateCountryWithCode() {
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Map<String, Object> additionalFields = new Map<String, Object>{ 'Code__c' => 'US' };
                Test.startTest();
            List<CountryWithCode__c> countries = PartnerTestDataUtility.createCountryWithCode(
                2, 'US', 'United States', additionalFields
            );
            Test.stopTest();
            Assert.areEqual(2, countries.size(), 'Should create 2 country records');
            Assert.areEqual('US', countries[0].Code__c, 'Code should match');
        }
    }
    
    
    // Test createCodeWithCountry
    @isTest
    static void testCreateCodeWithCountry() {
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Map<String, Object> additionalFields = new Map<String, Object>{ 'Country__c' => 'United States' };
                Test.startTest();
            List<CodeWithCountry__c> codes = PartnerTestDataUtility.createCodeWithCountry(
                2, 'CA', 'United States', additionalFields
            );
            Test.stopTest();
            
            Assert.areEqual(2, codes.size(), 'Should create 2 code records');
            Assert.areEqual('United States', codes[0].Country__c, 'Country should match');
        }
    }
    
    
    // Test createStateCodeWithName
    @isTest
    static void testCreateStateCodeWithName() {
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Map<String, Object> additionalFields = new Map<String, Object>{ 'State_Name__c' => 'California' };
                Test.startTest();
            List<statecodename__c> states = PartnerTestDataUtility.createStateCodeWithName(
                2, 'CA', 'California', additionalFields
            );
            Test.stopTest();
            Assert.areEqual(2, states.size(), 'Should create 2 state records');
            Assert.areEqual('California', states[0].State_Name__c, 'State name should match');
        }
    }
    
    
    // Test createPartnerFundRequest
    @isTest
    static void testCreatePartnerFundRequest() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Map<String, Object> additionalFields = new Map<String, Object>{ 'Status' => 'Approved' };
            List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            List<PartnerFundRequest> requests = PartnerTestDataUtility.createPartnerFundRequest(
                2, 'Approved', acc.Id, additionalFields
            );
            Test.stopTest();
            Assert.areEqual(2, requests.size(), 'Should create 2 fund requests');
            Assert.areEqual('Approved', requests[0].Status, 'Status should match');
        }
    }
    
    // Test createPartnerFundClaim
    @isTest
    static void testCreatePartnerFundClaim() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
			List<PartnerFundClaim> claims = PartnerTestDataUtility.createPartnerFundClaim(
                1, 'Draft', null, null
            );
            Test.stopTest();
            Assert.areEqual(1, claims.size(), 'Should create 1 claim request');
            Assert.areEqual('Draft', claims[0].Status, 'Status should match');
        }
    }
    
    
    // Test createTerritories
    @isTest
    static void testCreateTerritories() {
        Territory2Model tm = [SELECT Id FROM Territory2Model LIMIT 1];
        Territory2Type tt = [SELECT Id FROM Territory2Type LIMIT 1];
        Map<String, Object> additionalFields = new Map<String, Object>{ 'Adaptive_Territory_Id__c' => '999999' };
            List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            List<Territory2> territories = PartnerTestDataUtility.createTerritories(
                1, tm.Id, tt.Id, additionalFields
            );
            Test.stopTest();
            Assert.areEqual(1, territories.size(), 'Should create 3 territories');
            Assert.areEqual('CDM_1', territories[0].DeveloperName, 'First territory name should match');
        }
    }
    
    
    // Test createUserTerritoryAssociations
    @isTest
    static void testCreateUserTerritoryAssociations() {
        List<Territory2Model> TModel = [Select id,Name from territory2model where State ='Active'];
        List<Territory2Type> terrType = [Select Id, DeveloperName from Territory2Type where DeveloperName = 'Territory'];
        
        Territory2 terr = new Territory2(
            Name = 'Test Territory',
            DeveloperName = 'TestTerritory',
            Territory2ModelId = TModel[0].Id,
            Territory2TypeId = terrType[0].Id,
            Adaptive_Territory_Id__c = '999999'
        );
        insert terr;
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Map<String, Object> additionalFields = new Map<String, Object>{ 'RoleInTerritory2' => 'Account Executive' };
                Test.startTest();
            List<UserTerritory2Association> associations = PartnerTestDataUtility.createUserTerritoryAssociations(
                2, 'Account Executive', terr.Id, UserInfo.getUserId(), additionalFields
            );
            Test.stopTest();
            Assert.areEqual(2, associations.size(), 'Should create 2 associations');
            Assert.areEqual('Account Executive', associations[0].RoleInTerritory2, 'Role should match');
        }
    }
    
    
    // Test createDealPartnerEmail
    @isTest
    static void testCreateDealPartnerEmail() {
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            Map<String, Object> additionalFields = new Map<String, Object>{ 'Type__c' => 'Primary' };
                List<DealPartnerEmail__c> emails = PartnerTestDataUtility.createDealPartnerEmail(
                    2, 'Test Email', 'Primary', additionalFields
                );
            Test.stopTest();
            Assert.areEqual(2, emails.size(), 'Should create 2 email records');
            Assert.areEqual('Primary', emails[0].Type__c, 'Type should match');
        }
    }
    
    
    // Test createPartnerOnBoardingRequest
    @isTest
    static void testCreatePartnerOnBoardingRequest() {
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Map<String, Object> additionalFields = new Map<String, Object>{ 'Partner_Onboarding_Status__c' => 'Submitted' };
                Test.startTest();
            List<Partner_Onboarding_Request__c> requests = PartnerTestDataUtility.createPartnerOnBoardingRequest(
                2, 'Partner_Onboarding_Request__c', 'Submitted', additionalFields
            );
            Test.stopTest();
            Assert.areEqual(2, requests.size(), 'Should create 2 onboarding requests');
        }
    }
    
    
    // Test createMIPContract
    @isTest
    static void testCreateMIPContract() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Map<String, Object> additionalFields = new Map<String, Object>{ 'Status__c' => 'Active' };
            List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            List<MIP_Contract__c> contracts = PartnerTestDataUtility.createMIPContract(
                2, acc.Id, con.Id, UserInfo.getUserId(), 'Active', additionalFields
            );
            Test.stopTest();
            
            Assert.areEqual(2, contracts.size(), 'Should create 2 MIP contracts');
            Assert.areEqual('Active', contracts[0].Status__c, 'Status should match');
        }
    }
    
    
    // Test createMIPAccountContribution
    @isTest
    static void testCreateMIPAccountContribution() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        MIP_Contract__c contract = new MIP_Contract__c(
            Partner_Account__c = acc.Id,
            Partner_Contact_of_Signature__c = con.Id,
            CDM__c = UserInfo.getUserId(),
            Status__c = 'Draft',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(365)
        );
        insert contract;
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            List<MIP_Account_Contribution__c> contributions = PartnerTestDataUtility.createMIPAccountContribution(
                2, acc.Id, contract.Id, null
            );
            Test.stopTest();
            Assert.areEqual(2, contributions.size(), 'Should create 2 contributions');
        }
    }
    
    
    // Test createMIPElement
    @isTest
    static void testCreateMIPElement() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        MIP_Contract__c contract = new MIP_Contract__c(
            Partner_Account__c = acc.Id,
            Partner_Contact_of_Signature__c = con.Id,
            CDM__c = UserInfo.getUserId(),
            Status__c = 'Draft',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(365)
        );
        insert contract;
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Map<String, Object> additionalFields = new Map<String, Object>{ 'Element_Type__c' => 'Rebate' };
                Test.startTest();
            List<MIP_Element__c> elements = PartnerTestDataUtility.createMIPElement(
                2, 'MIP_Element__c', contract.Id, 'Rebate', additionalFields
            );
            Test.stopTest();
            Assert.areEqual(2, elements.size(), 'Should create 2 MIP elements');
            Assert.areEqual('Rebate', elements[0].Element_Type__c, 'Element type should match');
        }
    }
    
    
    // Test createPartnerMarketingBudget
    @isTest
    static void testCreatePartnerMarketingBudget() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            List<PartnerMarketingBudget> budgets = PartnerTestDataUtility.createPartnerMarketingBudget(
                2, acc.Id, null
            );
            Test.stopTest();
            Assert.areEqual(2, budgets.size(), 'Should create 2 marketing budgets');
            Assert.areEqual(acc.Id, budgets[0].ChannelPartnerId, 'Account should match');
        }
    }
    
    
    // Test createPartnerFundAllocation
    @isTest
    static void testCreatePartnerFundAllocation() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            List<PartnerFundAllocation> allocations = PartnerTestDataUtility.createPartnerFundAllocation(
                2, acc.Id, null, null
            );
            Test.stopTest();
            
            Assert.areEqual(2, allocations.size(), 'Should create 2 fund allocations');
            Assert.areEqual(acc.Id, allocations[0].ChannelPartnerId, 'Account should match');
        }
    }
    
    
    // Test createPartnerRegistrationRequest
    @isTest
    static void testCreatePartnerRegistrationRequest() {
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            List<Partner_Registration_Request__c> requests = PartnerTestDataUtility.createPartnerRegistrationRequest(
                2, null
            );
            Test.stopTest();
            Assert.areEqual(2, requests.size(), 'Should create 2 registration requests');
        }
    }
    
    // Test createWorkflowTriggerBypass
    @isTest
    static void testCreateWorkflowTriggerBypass() {
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            List<WorkflowTriggerBypass__c> bypasses = PartnerTestDataUtility.createWorkflowTriggerBypass(
                2, 'TestBypass', true, null
            );
            Test.stopTest();
            
            Assert.areEqual(2, bypasses.size(), 'Should create 2 bypass records');
            Assert.areEqual('TestBypass', bypasses[0].Name, 'Name should match');
            Assert.areEqual(true, bypasses[0].ByPassTrigger__c, 'Bypass flag should be true');
        }
    }
    
    
    // Test createCases
    @isTest
    static void testCreateCases() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            List<Case> cases = PartnerTestDataUtility.createCases(
                2, 'Case', acc.Id, con.Id, null
            );
            Test.stopTest();
            Assert.areEqual(2, cases.size(), 'Should create 2 cases');
            Assert.areEqual(acc.Id, cases[0].AccountId, 'Account should match');
            Assert.areEqual(con.Id, cases[0].ContactId, 'Contact should match');
        }
    }
    
    
    // Test createContentVersion
    @isTest
    static void testCreateContentVersion() {
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            List<ContentVersion> contentVersions = PartnerTestDataUtility.createContentVersion(
                2, 'test.pdf', null
            );
            Test.stopTest();
            
            Assert.areEqual(2, contentVersions.size(), 'Should create 2 content versions');
            Assert.areEqual('test.pdf', contentVersions[0].PathOnClient, 'Path should match');
        }
    }
    
    
    // Test createPermissionSetAssignment
    @isTest
    static void testCreatePermissionSetAssignment() {
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        // Create a test permission set
        PermissionSet ps = new PermissionSet(
            Name = 'TestPermissionSet',
            Label = 'Test Permission Set testing'
        );
        insert ps;
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            List<PermissionSetAssignment> assignments = PartnerTestDataUtility.createPermissionSetAssignment(
                1, 'TestPermissionSet', testUser.Id, null
            );
            Test.stopTest();
            Assert.areEqual(1, assignments.size(), 'Should create 1 permission set assignment');
            Assert.areEqual(ps.Id, assignments[0].PermissionSetId, 'Permission set should match');
            Assert.areEqual(testUser.Id, assignments[0].AssigneeId, 'User should match');
        }
    }
    
    
    // Test createCampaignMember
    @isTest
    static void testCreateCampaignMember() {
        
        Campaign testCampaign = new Campaign(
            Name = 'Partner Portal Deal Registration',
            Status = 'Planned',
            Type = 'Email',
            IsActive = true,
            StartDate = Date.today(),
            EndDate = Date.today().addDays(10),
            Campaign_Sales_Area__c ='AMER',
            Executed_By__c = 'Partner Marketing',
            Alliance_Partner__c = 'Amazon Web Services',
            Campaign_Sales_Region__c = 'AMER',
            Campaign_Theme__c = 'General',
            Campaign_Sales_Theatre__c = 'AMER',
            GTM_Play__c = 'General',
            Involvement_by_Customer_Marketing__c = 'No'
        );
        insert testCampaign;
        Map<String, Object> additionalFields = new Map<String, Object>{ 'Industry' => 'Technology' };
            
            List<Lead> leads = PartnerTestDataUtility.createLeads( 1, 'Open', additionalFields );
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            List<CampaignMember> members = PartnerTestDataUtility.createCampaignMember(
                2, leads[0].Id, testCampaign.Id, 'Sent', null
            );
            Test.stopTest();
            
            Assert.areEqual(2, members.size(), 'Should create 2 campaign members');
            Assert.areEqual('Sent', members[0].Status, 'Status should match');
        }
    }

    // Test createContentDocumentLinks
    @isTest
    static void testCreateContentDocumentLinks() {
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            List<ContentVersion> contentVersions = PartnerTestDataUtility.createContentVersion(
                2, 'test.pdf', null
            );
            insert contentVersions;

            Id accId = [SELECT Id FROM Account LIMIT 1].Id;

            Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersions[0].Id].ContentDocumentId;
			
			List<ContentDocumentLink> links = PartnerTestDataUtility.createContentDocumentLinks(1,accId,conDocId,null);
            Test.stopTest();
            
            Assert.areEqual(1, links.size(), 'Should create 1 content document link');
        }
    }
}