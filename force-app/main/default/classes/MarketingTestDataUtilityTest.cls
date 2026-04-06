/******************************************************************************
* @description       : Test class for MarketingTestDataUtility
* @author            : Ankit Gupta
* @last modified on  : 11-24-2025
* @last modified by  : Ankit Gupta
* Modifications Log
* Ver   Date          Author           Modification
* 1.0   11-24-2025    Ankit Gupta      Initial Version
******************************************************************************/
@isTest
public class MarketingTestDataUtilityTest {
    
    @testSetup
    static void setupTestData() {
        // Create basic test data that will be used across multiple test methods
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc.Id);
        insert con;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = '1 Discovery',
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert opp;
        
        // Create Product for PricebookEntry tests
        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'TEST-PROD',
            IsActive = true
        );
        insert prod;
    }
    
    // Test createAccounts with record type
    @isTest
    static void testCreateAccountsWithRecordType() {
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            List<Account> accounts = MarketingTestDataUtility.createAccounts(
                3, 'Partner', 'Partner/Distributor', null
            );
            Test.stopTest();
            Assert.areEqual(3, accounts.size(), 'Should create 3 accounts');
            Assert.areEqual('Partner', accounts[0].Type, 'Account type should match');
        }
        
    }
    
    // Test createAccounts without record type
    @isTest
    static void testCreateAccountsWithoutRecordType() {
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            Map<String, Object> additionalFields = new Map<String, Object>{'Industry' => 'Technology'};
                List<Account> accounts = MarketingTestDataUtility.createAccounts(
                    2, 'Customer', null, additionalFields
                );
            
            Test.stopTest();
            Assert.areEqual(2, accounts.size(), 'Should create 2 accounts');
            Assert.areEqual('Customer', accounts[0].Type, 'Account type should match');
        }
    }
    
    // Test createOpportunities
    @isTest
    static void testCreateOpportunities() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            List<Opportunity> opps = MarketingTestDataUtility.createOpportunities(
                3, '2 Consensus', acc.Id, null
            );
            Test.stopTest();
            Assert.areEqual(3, opps.size(), 'Should create 3 opportunities');
            Assert.areEqual('2 Consensus', opps[0].StageName, 'Stage should match');
        }
    }
    
    // Test createContacts
    @isTest
    static void testCreateContacts() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            List<Contact> contacts = MarketingTestDataUtility.createContacts(
                3, acc.Id, null
            );
            Test.stopTest();
            
            Assert.areEqual(3, contacts.size(), 'Should create 3 contacts');
            Assert.areEqual(acc.Id, contacts[0].AccountId, 'Account should match');
        }
    }
    
    // Test createLeads
    @isTest
    static void testCreateLeads() {
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            List<Lead> leads = MarketingTestDataUtility.createLeads(
                3, 'Open', null
            );
            Test.stopTest();
            
            Assert.areEqual(3, leads.size(), 'Should create 3 leads');
            Assert.areEqual('Open', leads[0].Status, 'Status should match');
        }
    }
    
    // Test createUsers with profile
    @isTest
    static void testCreateUsersWithProfile() {
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            List<User> users1 = MarketingTestDataUtility.createUsers(
                2, null, new Map<String, Object>{'IsActive' => true}
            );
            Test.stopTest();
            
            Assert.areEqual(2, users1.size(), 'Should create 2 users');
            Assert.areEqual('Test', users1[0].FirstName, 'First name should match');
        }
    }
    
    
    // Test createUsers without profile (defaults to System Administrator)
    @isTest
    static void testCreateUsersWithoutProfile() {
        Test.startTest();
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Assert.areEqual(1, users.size(), 'Should create 1 user');
            Assert.isNotNull(users[0].ProfileId, 'Profile should be set');
        }
        Test.stopTest();
    }
    
    
    // Test createOpportunitySplitMappings
    @isTest
    static void testCreateOpportunitySplitMappings() {
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            List<OpportunitySplitMapping__c> mappings = MarketingTestDataUtility.createOpportunitySplitMappings(
                2, 'Test_Field__c', new Map<String, Object>{'Field__c' => 'Test_Field__c'}
            );
            Test.stopTest();
            
            Assert.areEqual(2, mappings.size(), 'Should create 2 mappings');
            Assert.areEqual('Test_Field__c', mappings[0].Field__c, 'Field should match');
        }
    }
    
    
    // Test createOpportunityContactRoles
    @isTest
    static void testCreateOpportunityContactRoles() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            List<OpportunityContactRole> roles = MarketingTestDataUtility.createOpportunityContactRoles(
                2, opp.Id, con.Id, 'Decision Maker', new Map<String, Object>{'Role' => 'Decision Maker'}
            );
            Test.stopTest();
            
            Assert.areEqual(2, roles.size(), 'Should create 2 roles');
            Assert.areEqual('Decision Maker', roles[0].Role, 'Role should match');
        }
    }
    
    
    // Test createAfterActionReviews
    @isTest
    static void testCreateAfterActionReviews() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            List<After_Action_Review__c> reviews = MarketingTestDataUtility.createAfterActionReviews(
                2, opp.Id, Date.today(), new Map<String, Object>{'Opportunity_ClosedDate__c' => Date.today()}
            );
            Test.stopTest();
            
            Assert.areEqual(2, reviews.size(), 'Should create 2 reviews');
            Assert.areEqual(Date.today(), reviews[0].Opportunity_ClosedDate__c, 'Closed date should match');
        }
    }
    
    
    // Test createOrders
    @isTest
    static void testCreateOrders() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            List<Order> orders = MarketingTestDataUtility.createOrders(
                2, acc.Id, null, new Map<String, Object>{'AccountId' => acc.Id}
            );
            Test.stopTest();
            
            Assert.areEqual(2, orders.size(), 'Should create 2 orders');
            Assert.areEqual(acc.Id, orders[0].AccountId, 'Account should match');
        }
    }
    
    
    // Test createOpportunityLineItems
    @isTest
    static void testCreateOpportunityLineItems() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        
        // Create standard pricebook entry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            
            List<OpportunityLineItem> lineItems = MarketingTestDataUtility.createOpportunityLineItems(
                2, opp.Id, pbe.Id, new Map<String, Object>{'OpportunityId' => opp.Id}
            );
            Test.stopTest();
            
            Assert.areEqual(2, lineItems.size(), 'Should create 2 line items');
            Assert.areEqual(opp.Id, lineItems[0].OpportunityId, 'Opportunity should match');
            Assert.areEqual(pbe.Id, lineItems[0].PricebookEntryId, 'Pricebook entry should match');
        }
    }
    
    
    // Test createPricebooks
    @isTest
    static void testCreatePricebooks() {
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            List<Pricebook2> pricebooks = MarketingTestDataUtility.createPricebooks(
                2, null
            );
            Test.stopTest();
            Assert.areEqual(2, pricebooks.size(), 'Should create 2 pricebooks');
        }
    }
    
    
    // Test createSBQQQuotes
    @isTest
    static void testCreateSBQQQuotes() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            List<SBQQ__Quote__c> quotes = MarketingTestDataUtility.createSBQQQuotes(
                2, opp.Id, opp.AccountId, new Map<String, Object>{'SBQQ__Opportunity2__c' => opp.Id}
            );
            Test.stopTest();
            
            Assert.areEqual(2, quotes.size(), 'Should create 2 quotes');
        }
    }
    
    
    // Test createServiceContracts
    @isTest
    static void testCreateServiceContracts() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        
        Order ord = new Order(
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert ord;
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            List<ServiceContract> contracts = MarketingTestDataUtility.createServiceContracts(
                2, opp.Id, ord.Id, new Map<String, Object>{'SBQQSC__Opportunity__c' => opp.Id}
            );
            Test.stopTest();
            
            Assert.areEqual(2, contracts.size(), 'Should create 2 service contracts');
            Assert.areEqual(opp.Id, contracts[0].SBQQSC__Opportunity__c, 'Opportunity should match');   
        }
    }
    
    // Test createBookings
    @isTest
    static void testCreateBookings() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            List<Booking__c> bookings = MarketingTestDataUtility.createBookings(
                2, opp.Id, acc.Id, 'Approved', 'Booking', new Map<String, Object>{'Status__c' => 'Approved'}
            );
            Test.stopTest();
            
            Assert.areEqual(2, bookings.size(), 'Should create 2 bookings');
            Assert.areEqual('Approved', bookings[0].status__c, 'Status should match');
        }
    }
    
    
    // Test createCCRs
    @isTest
    static void testCreateCCRs() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            List<CCR__c> ccrs = MarketingTestDataUtility.createCCRs(
                2, opp.Id, acc.Id, 'Internal CCR', new Map<String, Object>{'Opportunity__c' => opp.Id}
            );
            Test.stopTest();
            
            Assert.areEqual(2, ccrs.size(), 'Should create 2 CCRs');
            Assert.areEqual(opp.Id, ccrs[0].Opportunity__c, 'Opportunity should match');
        }
    }
    
    
    // Test createSOXObjectsDeleteAccess
    @isTest
    static void testCreateSOXObjectsDeleteAccess() {
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            List<SOX_Objects_Delete_Access__c> soxRecords = MarketingTestDataUtility.createSOXObjectsDeleteAccess(
                2, UserInfo.getUserId(), true, new Map<String, Object>{'Allow_Opportunity_Delete__c' => true}
            );
            Test.stopTest();
            
            Assert.areEqual(2, soxRecords.size(), 'Should create 2 SOX records');
            Assert.areEqual(true, soxRecords[0].Allow_Opportunity_Delete__c, 'Allow delete should be true');
        }
    }
    
    
    // Test createTerritories
    @isTest
    static void testCreateTerritories() {
        Territory2Model tm = [SELECT Id FROM Territory2Model LIMIT 1];
        Territory2Type tt = [SELECT Id FROM Territory2Type LIMIT 1];
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            List<Territory2> territories = MarketingTestDataUtility.createTerritories(
                3, tm.Id, tt.Id, new Map<String, Object>{'Territory2ModelId' => tm.Id}
            );
            Test.stopTest();
            
            Assert.areEqual(3, territories.size(), 'Should create 3 territories');
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
            Territory2TypeId = terrType[0].Id
        );
        insert terr;
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            List<UserTerritory2Association> associations = MarketingTestDataUtility.createUserTerritoryAssociations(
                2, 'Account Executive', terr.Id, UserInfo.getUserId(), new Map<String, Object>{'Territory2Id' => terr.Id}
            );
            Test.stopTest();
            
            Assert.areEqual(2, associations.size(), 'Should create 2 associations');
            Assert.areEqual('Account Executive', associations[0].RoleInTerritory2, 'Role should match');
        }
    }
    
    
    // Test createPricebookEntries
    @isTest
    static void testCreatePricebookEntries() {
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        Id pricebookId = Test.getStandardPricebookId();
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            List<PricebookEntry> entries = MarketingTestDataUtility.createPricebookEntries(
                2, pricebookId, prod.Id, null
            );
            Test.stopTest();
            
            Assert.areEqual(2, entries.size(), 'Should create 2 pricebook entries');
            Assert.areEqual(pricebookId, entries[0].Pricebook2Id, 'Pricebook should match');
            Assert.areEqual(prod.Id, entries[0].Product2Id, 'Product should match');
        }
    }
    
    
    // Test createProducts
    @isTest
    static void testCreateProducts() {
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            Map<String, Object> additionalFields = new Map<String, Object>{
                'ProductCode' => 'TEST-CODE'
                    };
                        List<Product2> products = MarketingTestDataUtility.createProducts(
                            3, additionalFields
                        );
            Test.stopTest();
            
            Assert.areEqual(3, products.size(), 'Should create 3 products');
            Assert.areEqual('TEST-CODE', products[0].ProductCode, 'Product code should match');
        }
    }
    
    
    // Test createObjectTerritory2Associations
    @isTest
    static void testCreateObjectTerritory2Associations() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Territory2Model> TModel = [Select id,Name from territory2model where State ='Active'];
        List<Territory2Type> terrType = [Select Id, DeveloperName from Territory2Type where DeveloperName = 'Territory'];
        
        Territory2 terr = new Territory2(
            Name = 'Test Territory',
            DeveloperName = 'TestTerritory',
            Territory2ModelId = TModel[0].Id,
            Territory2TypeId = terrType[0].Id
        );
        insert terr;
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            List<ObjectTerritory2Association> associations = MarketingTestDataUtility.createObjectTerritory2Associations(
                2, acc.Id, terr.Id, null
            );
            Test.stopTest();
            
            Assert.areEqual(2, associations.size(), 'Should create 2 associations');
            Assert.areEqual(acc.Id, associations[0].ObjectId, 'Object should match');
            Assert.areEqual(terr.Id, associations[0].Territory2Id, 'Territory should match');
        }
    }
    
    
    // Test createContractLineItems
    @isTest
    static void testCreateContractLineItems() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        
        ServiceContract sc = new ServiceContract(
            Name = 'Test Contract',
            AccountId = acc.Id,
            StartDate = Date.today(),
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert sc;
        
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            List<ContractLineItem> lineItems = MarketingTestDataUtility.createContractLineItems(
                2, sc.Id, pbe.Id, null
            );
            Test.stopTest();
            
            Assert.areEqual(2, lineItems.size(), 'Should create 2 contract line items');
            Assert.areEqual(sc.Id, lineItems[0].ServiceContractId, 'Service contract should match');
            Assert.areEqual(pbe.Id, lineItems[0].PricebookEntryId, 'Pricebook entry should match');
        }
    }
    
    
    // Test createAssets with product
    @isTest
    static void testCreateAssetsWithProduct() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            List<Asset> assets = MarketingTestDataUtility.createAssets(
                3, acc.Id, prod.Id, null
            );
            Test.stopTest();
            
            Assert.areEqual(3, assets.size(), 'Should create 3 assets');
            Assert.areEqual(acc.Id, assets[0].AccountId, 'Account should match');
        }
    }
    
    
    // Test createAssets without product
    @isTest
    static void testCreateAssetsWithoutProduct() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            List<Asset> assets = MarketingTestDataUtility.createAssets(
                2, acc.Id, null, null
            );
            Test.stopTest();
            
            Assert.areEqual(2, assets.size(), 'Should create 2 assets');
            Assert.areEqual(acc.Id, assets[0].AccountId, 'Account should match');
        }
    }
    
    
    // Test createOpportunities with additional fields
    @isTest
    static void testCreateOpportunitiesWithAdditionalFields() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            Map<String, Object> additionalFields = new Map<String, Object>{'Amount' => 50000,'Probability' => 75};
                List<Opportunity> opps = MarketingTestDataUtility.createOpportunities(
                    2, '5 Negotiate & Close', acc.Id, additionalFields
                );
            Test.stopTest();
            
            Assert.areEqual(2, opps.size(), 'Should create 2 opportunities');
            Assert.areEqual(50000, opps[0].Amount, 'Amount should match');
        }
    }
    
    
    // Test createLeads with additional fields
    @isTest
    static void testCreateLeadsWithAdditionalFields() {
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            
            Map<String, Object> additionalFields = new Map<String, Object>{'Rating' => 'Hot','Industry' => 'Technology'};
                List<Lead> leads = MarketingTestDataUtility.createLeads(
                    2, 'Qualified', additionalFields
                );
            Test.stopTest();
            
            Assert.areEqual(2, leads.size(), 'Should create 2 leads');
            Assert.areEqual('Qualified', leads[0].Status, 'Status should match');
        }
    }
    
    
    // Test createContacts with additional fields
    @isTest
    static void testCreateContactsWithAdditionalFields() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<User> users = MarketingTestDataUtility.createUsers(1, 'System Administrator', new Map<String, Object>{'IsActive' => true});
        insert users;
        System.runAs(users[0]){
            Test.startTest();
            Map<String, Object> additionalFields = new Map<String, Object>{'Title' => 'VP of Sales','Department' => 'Sales'};
                
                List<Contact> contacts = MarketingTestDataUtility.createContacts(
                    2, acc.Id, additionalFields
                );
            Test.stopTest();
            
            Assert.areEqual(2, contacts.size(), 'Should create 2 contacts');
            Assert.areEqual('Sales', contacts[0].Department, 'Department should match');
        }
    }
}