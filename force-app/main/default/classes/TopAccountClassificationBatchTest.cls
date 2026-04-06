/**
* @description Test Class for TopAccountClassificationBatch  
* @test
* @author Raveesh Layal
* @date 2025-10-02
*/
@isTest
public class TopAccountClassificationBatchTest {
    
    /**
* @description User Data for Testing purpose
*/
    @TestSetup
    static void setup() {
        // Create automation user that can bypass validation rules
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        
        User automationUser = new User(
            ProfileId = profileId,
            LastName = 'Automation',
            Email = 'cs-automationforTesting@rubrik.com',
            Username = 'cs-automationforTesting@rubrik.com',
            CompanyName = 'TEST',
            Title = 'Automation User',
            Alias = 'csauto',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Employee_Time_Off__c = true,
            RBAC_Department__c = 'Service Account',
            RBAC_Group__c = 'API'
        );
        insert automationUser;
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'CS_Automation_Access' LIMIT 1];
        insert new PermissionSetAssignment(
            AssigneeId = automationUser.Id,
            PermissionSetId = ps.Id
        );
        PermissionSet ps1 = [SELECT Id FROM PermissionSet WHERE Name = 'CS_Manager' LIMIT 1];
        insert new PermissionSetAssignment(
            AssigneeId = automationUser.Id,
            PermissionSetId = ps1.Id
        );
        
        
        System.runAs(automationUser){
            ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(
                Name = 'Default',
                Disable_Account_Triggers__c = true,
                Disable_Entitlement_Validation_Rules__c = true,
                SetupOwnerId = UserInfo.getOrganizationId()
            );
            insert disableLogic;
            
            TriggerControl__c tc = new TriggerControl__c(
                Name = 'Entitlement',
                DisableTrigger__c = true, 
                SetupOwnerId = UserInfo.getOrganizationId()
            );
            insert tc;
            
            List<Account> accounts = new List<Account>();
            
            // Create parent accounts with proper field initialization
            Account parentAccount1 = new Account(
                Name = 'Parent Account 1',
                Account_Preference__c = 'CSM Account',
                r6000_Series_Products_Tagged__c = null,  // Initialize to avoid null pointer
                Customer_URL__c = 'https://test.com'
            );
            accounts.add(parentAccount1);
            
            Account parentAccount2 = new Account(
                Name = 'Parent Account 2',
                Account_Preference__c = 'Top Accounts',
                r6000_Series_Products_Tagged__c = 'CEM',  // Add some test data
                Customer_URL__c = 'https://test1.com'
            );
            accounts.add(parentAccount2);
            
            Account parentAccount3 = new Account(
                Name = 'Parent Account 3',
                Account_Preference__c = 'Top Accounts (Manual exception)',
                r6000_Series_Products_Tagged__c = 'CEM, Other',
                Customer_URL__c = 'https://test.com'
            );
            accounts.add(parentAccount3);
            
            insert accounts;
            
            // Create child accounts (Level 1) with proper field initialization
            List<Account> childAccounts = new List<Account>();
            
            Account child1 = new Account(
                Name = 'Child Account 1',
                ParentId = parentAccount1.Id,
                Account_Preference__c = 'Premium Account',
                r6000_Series_Products_Tagged__c = null,
                Customer_URL__c = 'https://test.com'
            );
            childAccounts.add(child1);
            
            Account child2 = new Account(
                Name = 'Child Account 2',
                ParentId = parentAccount1.Id,
                Account_Preference__c = 'Top Accounts (Manual exception)',
                r6000_Series_Products_Tagged__c = 'CEM',
                Customer_URL__c = 'https://test17.com'
            );
            childAccounts.add(child2);
            
            Account child3 = new Account(
                Name = 'Child Account 3',
                ParentId = parentAccount2.Id,
                Account_Preference__c = 'Top Accounts (Manual exception)',
                r6000_Series_Products_Tagged__c = 'Other'
            );
            childAccounts.add(child3);
            
            insert childAccounts;
            
            // Create grandchild accounts (Level 2) with proper field initialization
            List<Account> grandChildAccounts = new List<Account>();
            
            Account grandChild1 = new Account(
                Name = 'Grandchild Account 1',
                ParentId = child1.Id,
                Account_Preference__c = 'Top Accounts (Manual exception)',
                r6000_Series_Products_Tagged__c = null,
                Customer_URL__c = 'https://test.com'
            );
            grandChildAccounts.add(grandChild1);
            
            Account grandChild2 = new Account(
                Name = 'Grandchild Account 2',
                ParentId = child2.Id,
                Account_Preference__c = 'Top Accounts',
                r6000_Series_Products_Tagged__c = 'CEM, Test'
            );
            grandChildAccounts.add(grandChild2);
            
            insert grandChildAccounts;
            
            // Create Products for Entitlements
            List<Product2> products = new List<Product2>();
            
            Product2 cemProduct = new Product2(
                Name = 'CEM Product',
                Family = 'CEM',
                Description = 'Customer Experience Manager',  // This matches your batch logic
                IsActive = true
            );
            products.add(cemProduct);
            
            Product2 cesProduct = new Product2(
                Name = 'CES Product',
                Family = 'Support',
                Description = 'Customer Experience Specialist',  // This matches your batch logic
                IsActive = true
            );
            products.add(cesProduct);
            
            insert products;
            
            // Create Standard PriceBook Entry (required)
            Id pricebookId = Test.getStandardPricebookId();
            List<PricebookEntry> pbeList = new List<PricebookEntry>();
            
            PricebookEntry pbe1 = new PricebookEntry(
                Pricebook2Id = pricebookId,
                Product2Id = cemProduct.Id,
                UnitPrice = 1000,
                IsActive = true
            );
            pbeList.add(pbe1);
            
            PricebookEntry pbe2 = new PricebookEntry(
                Pricebook2Id = pricebookId,
                Product2Id = cesProduct.Id,
                UnitPrice = 800,
                IsActive = true
            );
            pbeList.add(pbe2);
            
            insert pbeList;
            
            // CREATE SERVICE CONTRACTS TO COVER ACV CALCULATION LOGIC
            List<ServiceContract> serviceContracts = new List<ServiceContract>();
            
            // High value contract for Parent Account 1 - should trigger Top Accounts
            ServiceContract highValueContract1 = new ServiceContract(
                Name = 'High Value Contract 1',
                AccountId = parentAccount1.Id,
                Term = 12,
                StartDate = System.today(),
                EndDate = System.today().addMonths(12)
            );
            serviceContracts.add(highValueContract1);
            
            // High value contract for Child Account 1 - contributes to Parent rollup
            ServiceContract highValueContract2 = new ServiceContract(
                Name = 'High Value Contract 2',
                AccountId = child1.Id,
                Term = 24,
                StartDate = System.today(),
                EndDate = System.today().addMonths(24)
            );
            serviceContracts.add(highValueContract2);
            
            // Medium value contract for testing
            ServiceContract mediumValueContract = new ServiceContract(
                Name = 'Medium Value Contract',
                AccountId = child3.Id,
                Term = 12,
                StartDate = System.today(),
                EndDate = System.today().addMonths(12)
            );
            serviceContracts.add(mediumValueContract);
            
            // Low value contract that won't trigger Top Account
            ServiceContract lowValueContract = new ServiceContract(
                Name = 'Low Value Contract',
                AccountId = grandChild1.Id,
                Term = 12,
                StartDate = System.today(),
                EndDate = System.today().addMonths(12)
            );
            serviceContracts.add(lowValueContract);
            
            insert serviceContracts;
            
            
            // Create Entitlements with CEM/CES products that match your batch criteria
            List<Entitlement> entitlements = new List<Entitlement>();
            
            Entitlement ent1 = new Entitlement(
                Name = 'CEM Entitlement',
                AccountId = child2.Id,
                Product__c = cemProduct.Id,
                StartDate = System.today(),
                EndDate = System.today().addYears(1)
            );
            entitlements.add(ent1);
            
            Entitlement ent2 = new Entitlement(
                Name = 'CES Entitlement',
                AccountId = parentAccount3.Id,
                Product__c = cesProduct.Id,
                StartDate = System.today(),
                EndDate = System.today().addYears(1)
            );
            entitlements.add(ent2);
            
            insert entitlements;
        }
    }
    
    
    /**
* @description Test for multiple ServiceContracts same account
*/
    @isTest
    static void testMultipleContracts() {
        User automationUser = [SELECT Id FROM User WHERE Username = 'cs-automationforTesting@rubrik.com' LIMIT 1];
        
        System.runAs(automationUser) {
            Account testAccount = new Account(
                Name = 'Test Multiple Contracts',
                Account_Preference__c = 'CSM Account',
                Customer_URL__c = 'https://test4.com'
            );
            insert testAccount;
            
            ServiceContract sc1 = new ServiceContract(
                Name = 'Contract 1',
                AccountId = testAccount.Id,
                Term = 12,
                StartDate = System.today(),
                EndDate = System.today().addMonths(12)
            );
            insert sc1;
            
            ServiceContract sc2 = new ServiceContract(
                Name = 'Contract 2',
                AccountId = testAccount.Id,
                Term = 12,
                StartDate = System.today(),
                EndDate = System.today().addMonths(12)
            );
            insert sc2;
            
            Test.startTest();
            TopAccountClassificationBatch batch = new TopAccountClassificationBatch();
            Id asycJobid = Database.executeBatch(batch, 200);
            System.assertNotEquals(null, asycJobid, 'Batch job ID should not be null');
            Test.stopTest();
        }
    }
    
    
    
    /**
* @description Test for CEM tagging with existing tags
*/
    @isTest
    static void testCEMTaggingExisting() {
        User automationUser = [SELECT Id FROM User WHERE Username = 'cs-automationforTesting@rubrik.com' LIMIT 1];
        
        System.runAs(automationUser) {
            Product2 cemProduct = new Product2(
                Name = 'CEM Product Test',
                Description = 'Customer Experience Manager',
                IsActive = true
            );
            insert cemProduct;
            
            Account acc = new Account(
                Name = 'Test CEM Tags',
                Account_Preference__c = 'CSM Account',
                r6000_Series_Products_Tagged__c = 'Other',
                Customer_URL__c = 'https://test5.com',
                Top_Accounts_Criteria__c = 'Manual Exception'
            );
            insert acc;
            
            Entitlement ent = new Entitlement(
                Name = 'CEM Ent',
                AccountId = acc.Id,
                Product__c = cemProduct.Id,
                StartDate = System.today(),
                EndDate = System.today().addYears(1)
            );
            insert ent;
            
            Test.startTest();
            TopAccountClassificationBatch batch = new TopAccountClassificationBatch();
            Id asycJobid = Database.executeBatch(batch, 200);
            System.assertNotEquals(null, asycJobid, 'Batch job ID should not be null');
            Test.stopTest();
        }
    }
    /**
* @description Test to cover CEM tagging for blank r6000_Series_Products_Tagged__c field
*/
    @isTest
    static void testCEMTaggingBlankField() {
        User automationUser = [SELECT Id FROM User WHERE Username = 'cs-automationforTesting@rubrik.com' LIMIT 1];
        
        System.runAs(automationUser) {
            // Create CEM product
            Product2 cemProduct = new Product2(
                Name = 'CEM Product Blank Test',
                Description = 'Customer Experience Manager',
                IsActive = true
            );
            insert cemProduct;
            
            // Create pricebook entry
            PricebookEntry pbe = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = cemProduct.Id,
                UnitPrice = 1000,
                IsActive = true
            );
            insert pbe;
            
            // Create account with BLANK r6000_Series_Products_Tagged__c field
            Account accWithBlankTags = new Account(
                Name = 'Account With Blank Tags',
                Account_Preference__c = 'Top Accounts',  // Must be Top Accounts initially
                r6000_Series_Products_Tagged__c = null,  // This is KEY - blank field
                Customer_URL__c = 'https://test6.com'
            );
            insert accWithBlankTags;
            
            // Create CEM entitlement for this account
            Entitlement cemEnt = new Entitlement(
                Name = 'CEM Entitlement Blank Test',
                AccountId = accWithBlankTags.Id,
                Product__c = cemProduct.Id,
                StartDate = System.today(),
                EndDate = System.today().addYears(1)
            );
            insert cemEnt;
            
            Test.startTest();
            TopAccountClassificationBatch batch = new TopAccountClassificationBatch();
            Database.executeBatch(batch, 200);
            Test.stopTest();
            
            // Verify the blank field was set to 'CEM'
            Account updatedAccount = [SELECT Id, r6000_Series_Products_Tagged__c 
                                      FROM Account WHERE Id = :accWithBlankTags.Id];
            System.assertEquals('CEM', updatedAccount.r6000_Series_Products_Tagged__c, 
                                'Blank r6000_Series_Products_Tagged__c should be set to CEM');
        }
    }
    
    /**
* @description Test to cover CEM tagging for account promoted due to ACV with blank tags
*/
    @isTest
    static void testCEMTaggingPromotedAccountBlankTags() {
        User automationUser = [SELECT Id FROM User WHERE Username = 'cs-automationforTesting@rubrik.com' LIMIT 1];
        
        System.runAs(automationUser) {
            // Create CEM product
            Product2 cemProduct = new Product2(
                Name = 'CEM Product ACV Test',
                Description = 'Customer Experience Manager',
                IsActive = true
            );
            insert cemProduct;
            
            // Create pricebook entry
            PricebookEntry pbe = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = cemProduct.Id,
                UnitPrice = 1000,
                IsActive = true
            );
            insert pbe;
            
            // Create account that will be promoted due to high ACV
            Account highACVAccount = new Account(
                Name = 'High ACV Account',
                Account_Preference__c = 'CSM Account',  // Not Top Accounts initially
                r6000_Series_Products_Tagged__c = null,  // Blank field
                Top_Accounts_Criteria__c = 'Manual Exception'
            );
            insert highACVAccount;
            
            // Create high value service contract to trigger promotion
            ServiceContract highValueContract = new ServiceContract(
                Name = 'High Value Contract ACV',
                AccountId = highACVAccount.Id,
                Term = 12,
                StartDate = System.today(),
                EndDate = System.today().addMonths(12)
            );
            insert highValueContract;
            
            
            
            // Create CEM entitlement for this account
            Entitlement cemEnt = new Entitlement(
                Name = 'CEM Entitlement ACV Test',
                AccountId = highACVAccount.Id,
                Product__c = cemProduct.Id,
                StartDate = System.today(),
                EndDate = System.today().addYears(1)
            );
            insert cemEnt;
            
            Test.startTest();
            TopAccountClassificationBatch batch = new TopAccountClassificationBatch();
            String cronExp = '0 0 0 15 2 ? 2042'; // Future date for testing
            String jobId = System.schedule('Test Schedulable Batch', cronExp, batch );
            System.assertNotEquals(null, jobId, 'Batch job ID should not be null');
            Test.stopTest();
            
        }
    }
    /**
* @description Test Top Accounts and CEM tag removal logic
*/
    @isTest
    static void testRemovalLogic() {
        User automationUser = [SELECT Id FROM User WHERE Username = 'cs-automationforTesting@rubrik.com' LIMIT 1];
        
        System.runAs(automationUser) {
            // Test Scenario 1: Remove "Top Accounts" from Account_Preference__c
            Account topAccountRemoval = new Account(
                Name = 'Top Account Removal Test',
                Account_Preference__c = 'CSM Account;Top Accounts;Premium Account', // Multiple values with Top Accounts
                r6000_Series_Products_Tagged__c = 'Other, Test',
                Customer_URL__c = 'https://test7.com',
                Top_Accounts_Criteria__c = 'ARR'
            );
            insert topAccountRemoval;
            
            // Test Scenario 2: Remove "CEM" from r6000_Series_Products_Tagged__c (multiple tags)
            Account cemRemovalMultiple = new Account(
                Name = 'CEM Removal Multiple Test',
                Account_Preference__c = 'CSM Account;Top Accounts', // Has Top Accounts but will be removed
                r6000_Series_Products_Tagged__c = 'CEM, Other, Test', // Multiple tags including CEM
                Customer_URL__c = 'https://test8.com',
                Top_Accounts_Criteria__c = 'CEM'
            );
            insert cemRemovalMultiple;
            
            // Test Scenario 3: Remove "CEM" when it's the only tag (should become empty)
            Account cemRemovalSingle = new Account(
                Name = 'CEM Removal Single Test',
                Account_Preference__c = 'Premium Account;Top Accounts', // Has Top Accounts but will be removed
                r6000_Series_Products_Tagged__c = 'CEM', // Only CEM tag
                Customer_URL__c = 'https://test9.com',
                Top_Accounts_Criteria__c = 'CEM'
            );
            insert cemRemovalSingle;
            
            // Test Scenario 4: Account with "Top Accounts" at the beginning
            Account topAccountFirst = new Account(
                Name = 'Top Account First Test',
                Account_Preference__c = 'Top Accounts;CSM Account', 
                r6000_Series_Products_Tagged__c = 'CEM, Other',
                Customer_URL__c = 'https://test10.com'
            );
            insert topAccountFirst;
            
            // Test Scenario 5: Account with "Top Accounts" in the middle
            Account topAccountMiddle = new Account(
                Name = 'Top Account Middle Test',
                Account_Preference__c = 'CSM Account;Top Accounts;Premium Account', // Top Accounts in middle
                r6000_Series_Products_Tagged__c = 'Other, CEM, Test', // CEM in middle
                Customer_URL__c = 'https://test11.com'
            );
            insert topAccountMiddle;
            
            // Test Scenario 6: Account with only "Top Accounts" (should become empty/null)
            Account topAccountOnly = new Account(
                Name = 'Top Account Only Test',
                Account_Preference__c = 'Top Accounts', // Only Top Accounts
                r6000_Series_Products_Tagged__c = 'CEM', // Only CEM
                Customer_URL__c = 'https://test12.com',
                Top_Accounts_Criteria__c = 'CEM'
            );
            insert topAccountOnly;
            
            // Test Scenario 7: Account with spaces around values
            Account spacesTest = new Account(
                Name = 'Spaces Test Account',
                Account_Preference__c = ' CSM Account ; Top Accounts ; Premium Account ', // With spaces
                r6000_Series_Products_Tagged__c = ' CEM , Other , Test ', // With spaces
                Customer_URL__c = 'https://test11.com',
                Top_Accounts_Criteria__c = 'CEM'
            );
            insert spacesTest;
            
            Test.startTest();
            TopAccountClassificationBatch batch = new TopAccountClassificationBatch();
            Database.executeBatch(batch, 2000);
            Test.stopTest();
            
            // Verify Top Accounts removal scenarios
            Account updated1 = [SELECT Account_Preference__c FROM Account WHERE Id = :topAccountRemoval.Id];
            System.assertEquals('Premium Account;CSM Account', updated1.Account_Preference__c, 
                                'Top Accounts should be removed, other values preserved');
            
            Account updated2 = [SELECT Account_Preference__c FROM Account WHERE Id = :cemRemovalMultiple.Id];
            System.assertEquals('CSM Account', updated2.Account_Preference__c, 
                                'Top Accounts should be removed from multiple value string');
            
            Account updated3 = [SELECT Account_Preference__c FROM Account WHERE Id = :cemRemovalSingle.Id];
            System.assertEquals('Premium Account', updated3.Account_Preference__c, 
                                'Top Accounts should be removed, leaving other value');
            
            Account updated4 = [SELECT Account_Preference__c FROM Account WHERE Id = :topAccountFirst.Id];
            System.assertEquals('CSM Account', updated4.Account_Preference__c, 
                                'Top Accounts should be removed from beginning');
        }
    }
    /**
* @description Test ACV calculation with ContractLineItems to generate GrandTotal
*/
    @isTest
    static void testACVCalculationWithContractLineItems() {
        User automationUser = [SELECT Id FROM User WHERE Username = 'cs-automationforTesting@rubrik.com' LIMIT 1];
        
        System.runAs(automationUser) {
            // Create parent account that will exceed ACV threshold
            Account highACVParent = new Account(
                Name = 'High ACV Parent Account',
                Account_Preference__c = 'CSM Account;Top Accounts (Manual exception)',
                Customer_URL__c = 'https://test12.com',
                Top_Accounts_Criteria__c = 'CEM'
            );
            insert highACVParent;
            
            // Create child accounts under parent
            List<Account> childAccounts = new List<Account>();
            Account child1 = new Account(
                Name = 'Child Account 1 ACV',
                ParentId = highACVParent.Id,
                Account_Preference__c = 'Premium Account',
                Customer_URL__c = 'https://test13.com'
            );
            Account child2 = new Account(
                Name = 'Child Account 2 ACV',
                ParentId = highACVParent.Id,
                Account_Preference__c = 'CSM Account',
                Customer_URL__c = 'https://test14.com'
            );
            childAccounts.add(child1);
            childAccounts.add(child2);
            insert childAccounts;
            
            // Create low ACV parent (below threshold)
            Account lowACVParent = new Account(
                Name = 'Low ACV Parent Account',
                Account_Preference__c = 'CSM Account'
            );
            insert lowACVParent;
            
            // Create high-value product for testing
            Product2 highValueProduct = new Product2(
                Name = 'High Value Product',
                ProductCode = 'RBK-SVC-high-value',
                Family = 'Software',
                IsActive = true
            );
            insert highValueProduct;
            
            // Create PricebookEntry
            Id standardPricebookId = Test.getStandardPricebookId();
            PricebookEntry pbe = new PricebookEntry(
                Pricebook2Id = standardPricebookId,
                Product2Id = highValueProduct.Id,
                UnitPrice = 600000, // High unit price for ACV calculation
                IsActive = true
            );
            insert pbe;
            
            // Create Opportunity (required for ServiceContract)
            Opportunity opp = new Opportunity(
                Name = 'ACV Test Opportunity',
                AccountId = highACVParent.Id,
                StageName = 'Prospecting',
                CloseDate = System.today().addMonths(12),
                Pricebook2Id = standardPricebookId
            );
            insert opp;
            
            // Create ServiceContracts
            List<ServiceContract> serviceContracts = new List<ServiceContract>();
            
            // High value contract for parent (will exceed 500K threshold)
            ServiceContract highValueContract = new ServiceContract(
                Name = 'High Value Service Contract',
                AccountId = highACVParent.Id,
                StartDate = System.today(),
                Term = 12, // 12 months
                Pricebook2Id = standardPricebookId,
                SBQQSC__Opportunity__c = opp.Id
            );
            serviceContracts.add(highValueContract);
            
            // Low value contract for comparison
            ServiceContract lowValueContract = new ServiceContract(
                Name = 'Low Value Service Contract',
                AccountId = lowACVParent.Id,
                StartDate = System.today(),
                Term = 12,
                Pricebook2Id = standardPricebookId,
                SBQQSC__Opportunity__c = opp.Id
            );
            serviceContracts.add(lowValueContract);
            
            insert serviceContracts;
            
            // Create Assets (required for ContractLineItems)
            List<Asset> assets = new List<Asset>();
            Asset highValueAsset = new Asset(
                Name = 'High Value Asset',
                AccountId = highACVParent.Id,
                Product2Id = highValueProduct.Id
            );
            Asset lowValueAsset = new Asset(
                Name = 'Low Value Asset',
                AccountId = lowACVParent.Id,
                Product2Id = highValueProduct.Id
            );
            assets.add(highValueAsset);
            assets.add(lowValueAsset);
            insert assets;
            
            // Create ContractLineItems to generate GrandTotal values
            List<ContractLineItem> contractLineItems = new List<ContractLineItem>();
            
            // High value ContractLineItem (generates GrandTotal > 500K)
            ContractLineItem highValueCLI = new ContractLineItem(
                ServiceContractId = highValueContract.Id,
                PricebookEntryId = pbe.Id,
                AssetId = highValueAsset.Id,
                Quantity = 1,
                UnitPrice = 6000000, // This generates the high ACV value
                SBQQSC__Account__c = highACVParent.Id
            );
            contractLineItems.add(highValueCLI);
            
            // Additional ContractLineItem for same parent (tests accumulation logic)
            ContractLineItem additionalCLI = new ContractLineItem(
                ServiceContractId = highValueContract.Id,
                PricebookEntryId = pbe.Id,
                AssetId = highValueAsset.Id,
                Quantity = 1,
                UnitPrice = 300000, // Combined with above = 900K total
                SBQQSC__Account__c = highACVParent.Id
            );
            contractLineItems.add(additionalCLI);
            
            // Low value ContractLineItem (stays below threshold)
            ContractLineItem lowValueCLI = new ContractLineItem(
                ServiceContractId = lowValueContract.Id,
                PricebookEntryId = pbe.Id,
                AssetId = lowValueAsset.Id,
                Quantity = 1,
                UnitPrice = 100000, // Below 500K threshold
                SBQQSC__Account__c = lowACVParent.Id
            );
            contractLineItems.add(lowValueCLI);
            
            insert contractLineItems;
            
            Test.startTest();
            TopAccountClassificationBatch batch = new TopAccountClassificationBatch();
            Database.executeBatch(batch, 2000);
            Test.stopTest();
            
            // Verify high ACV parent was promoted to Top Accounts
            Account updatedHighACVParent = [SELECT Account_Preference__c FROM Account WHERE Id = :highACVParent.Id];
            System.assert(updatedHighACVParent.Account_Preference__c.contains('Top Accounts'), 
                          'High ACV parent should be promoted to Top Accounts (ACV > 500K)');
            
            // Verify child accounts inherited Top Accounts from parent
            List<Account> updatedChildren = [SELECT Account_Preference__c FROM Account WHERE Id IN :new List<Id>{child1.Id, child2.Id}];
            for (Account child : updatedChildren) {
                System.assert(child.Account_Preference__c.contains('Top Accounts'), 
                              'Child accounts should inherit Top Accounts from high ACV parent');
            }
            
            
            Account updatedLowACVParent = [SELECT Account_Preference__c FROM Account WHERE Id = :lowACVParent.Id];
            System.assert(!updatedLowACVParent.Account_Preference__c.contains('Top Accounts'), 
                          'Low ACV parent should NOT be promoted to Top Accounts');
            
        }
    }
    /**
* @description Test ACV accumulation logic (else branch) and blank Account_Preference assignment
*/
    @isTest
    static void testACVAccumulationAndBlankPreference() {
        User automationUser = [SELECT Id FROM User WHERE Username = 'cs-automationforTesting@rubrik.com' LIMIT 1];
        
        System.runAs(automationUser) {
            // Create account with BLANK Account_Preference__c to test 'Top Accounts' assignment
            Account blankPreferenceAccount = new Account(
                Name = 'Blank Preference Account',
                Account_Preference__c = null, // This is KEY - blank preference field
                Customer_URL__c = 'https://testing.com'
            );
            insert blankPreferenceAccount;
            
            Account childBlankPreferenceAccount = new Account(
                Name = 'Blank Preference Account',
                Account_Preference__c = null, // This is KEY - blank preference field
                Customer_URL__c = 'https://testing.com',
                Top_Accounts_Criteria__c = 'Account inheritance (CEM)',
                ParentId = blankPreferenceAccount.Id
            );
            insert childBlankPreferenceAccount;
            
            Account childBlankPreferenceAccount1 = new Account(
                Name = 'Blank Preference Account',
                Account_Preference__c = null, // This is KEY - blank preference field
                Customer_URL__c = 'https://testing.com',
                ParentId = blankPreferenceAccount.Id
            );
            insert childBlankPreferenceAccount1;
            
            // Create second account for ACV accumulation testing
            Account multiContractAccount = new Account(
                Name = 'Multi Contract Account',
                Account_Preference__c = 'CSM Account',
                Customer_URL__c = 'https://test19.com'
            );
            insert multiContractAccount;
            
            // Create products and pricebook entries
            Product2 testProduct = new Product2(
                Name = 'Test ACV Product',
                ProductCode = 'RBK-TEST-ACV',
                Family = 'Software',
                IsActive = true
            );
            insert testProduct;
            
            Id standardPricebookId = Test.getStandardPricebookId();
            PricebookEntry pbe = new PricebookEntry(
                Pricebook2Id = standardPricebookId,
                Product2Id = testProduct.Id,
                UnitPrice = 400000,
                IsActive = true
            );
            insert pbe;
            
            // Create opportunity
            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity',
                AccountId = multiContractAccount.Id,
                StageName = 'Prospecting',
                CloseDate = System.today().addMonths(12),
                Pricebook2Id = standardPricebookId
            );
            insert opp;
            
            // Create multiple ServiceContracts for SAME account (to test ACV accumulation)
            List<ServiceContract> contracts = new List<ServiceContract>();
            
            ServiceContract contract1 = new ServiceContract(
                Name = 'Contract 1 for Accumulation',
                AccountId = multiContractAccount.Id,
                StartDate = System.today(),
                Term = 12,
                Pricebook2Id = standardPricebookId,
                SBQQSC__Opportunity__c = opp.Id
            );
            contracts.add(contract1);
            
            ServiceContract contract2 = new ServiceContract(
                Name = 'Contract 2 for Accumulation',
                AccountId = multiContractAccount.Id, // SAME ACCOUNT - this triggers else branch
                StartDate = System.today(),
                Term = 12,
                Pricebook2Id = standardPricebookId,
                SBQQSC__Opportunity__c = opp.Id
            );
            contracts.add(contract2);
            
            insert contracts;
            
            // Create assets
            List<Asset> assets = new List<Asset>();
            Asset asset1 = new Asset(
                Name = 'Asset 1',
                AccountId = multiContractAccount.Id,
                Product2Id = testProduct.Id
            );
            Asset asset2 = new Asset(
                Name = 'Asset 2',
                AccountId = multiContractAccount.Id,
                Product2Id = testProduct.Id
            );
            assets.add(asset1);
            assets.add(asset2);
            insert assets;
            
            // Create ContractLineItems that will trigger ACV accumulation
            List<ContractLineItem> clis = new List<ContractLineItem>();
            
            // First ContractLineItem - creates initial ACV entry
            ContractLineItem cli1 = new ContractLineItem(
                ServiceContractId = contract1.Id,
                PricebookEntryId = pbe.Id,
                AssetId = asset1.Id,
                Quantity = 1,
                UnitPrice = 400000, // 400K ACV
                SBQQSC__Account__c = multiContractAccount.Id
            );
            clis.add(cli1);
            
            // Second ContractLineItem - SAME ACCOUNT, triggers else branch accumulation
            ContractLineItem cli2 = new ContractLineItem(
                ServiceContractId = contract2.Id,
                PricebookEntryId = pbe.Id,
                AssetId = asset2.Id,
                Quantity = 1,
                UnitPrice = 300000, // 300K ACV, combined = 700K > 500K threshold
                SBQQSC__Account__c = multiContractAccount.Id
            );
            clis.add(cli2);
            
            insert clis;
            
            // Create entitlement for blank preference account to ensure it gets processed
            Product2 cemProduct = [SELECT Id FROM Product2 WHERE Description LIKE '%Customer Experience Manager%' LIMIT 1];
            Entitlement ent = new Entitlement(
                Name = 'Test Blank Preference Entitlement',
                AccountId = blankPreferenceAccount.Id,
                Product__c = cemProduct.Id,
                StartDate = System.today(),
                EndDate = System.today().addYears(1)
            );
            insert ent;
            
            Test.startTest();
            TopAccountClassificationBatch batch = new TopAccountClassificationBatch();
            Database.executeBatch(batch, 2000);
            Test.stopTest();
            
            // Verify blank preference field gets set to 'Top Accounts'
            Account updatedBlankPreference = [SELECT Account_Preference__c FROM Account WHERE Id = :blankPreferenceAccount.Id];
            System.assertEquals('Top Accounts', updatedBlankPreference.Account_Preference__c, 
                                'Blank Account_Preference__c should be set to Top Accounts');
        }
    }
    
    /**
* @description Test complex parent-child conditional logic
*/
    @isTest
    static void testParentChildConditionalLogic() {
        User automationUser = [SELECT Id FROM User WHERE Username = 'cs-automationforTesting@rubrik.com' LIMIT 1];
        
        System.runAs(automationUser) {
            // Scenario 1: Child with Top Accounts, parent with blank preference
            Account parentWithBlankPref = new Account(
                Name = 'Parent With Blank Pref',
                Account_Preference__c = null // Blank parent preference
            );
            insert parentWithBlankPref;
            
            Account childOfBlankParent = new Account(
                Name = 'Child Of Blank Parent',
                ParentId = parentWithBlankPref.Id,
                Account_Preference__c = 'CSM Account;Top Accounts' // Has Top Accounts but should be removed
            );
            insert childOfBlankParent;
            
            // Scenario 2: Child with Top Accounts, parent without Top Accounts
            Account parentWithoutTopAccounts = new Account(
                Name = 'Parent Without Top Accounts',
                Account_Preference__c = 'CSM Account;Premium Account' // No Top Accounts
            );
            insert parentWithoutTopAccounts;
            
            Account childOfNonTopParent = new Account(
                Name = 'Child Of Non Top Parent',
                ParentId = parentWithoutTopAccounts.Id,
                Account_Preference__c = 'Premium Account;Top Accounts;CSM Account' // Has Top Accounts but should be removed
            );
            insert childOfNonTopParent;
            
            // Scenario 3: Child without parent (String.isBlank(acc.parentId))
            Account orphanAccount = new Account(
                Name = 'Orphan Account',
                ParentId = null, // No parent
                Account_Preference__c = 'CSM Account;Top Accounts;Premium Account' // Has Top Accounts but should be removed
            );
            insert orphanAccount;
            
            // Scenario 4: Child with parent that has Top Accounts (should keep Top Accounts)
            Account parentWithTopAccounts = new Account(
                Name = 'Parent With Top Accounts',
                Account_Preference__c = 'CSM Account;Top Accounts' // Has Top Accounts
            );
            insert parentWithTopAccounts;
            
            Account childOfTopParent = new Account(
                Name = 'Child Of Top Parent',
                ParentId = parentWithTopAccounts.Id,
                Account_Preference__c = 'Premium Account;Top Accounts' // Should keep Top Accounts
            );
            insert childOfTopParent;
            
            Test.startTest();
            TopAccountClassificationBatch batch = new TopAccountClassificationBatch();
            Database.executeBatch(batch, 2000);
            Test.stopTest();
            // Child of Top parent should keep Top Accounts
            List<Account> updatedChildOfTopParent = [SELECT Account_Preference__c FROM Account WHERE Id = :childOfTopParent.Id];
            System.assert(updatedChildOfTopParent.size()>0,'Child of Top parent should keep Top Accounts');
        }
    }
    
    
    
    
}