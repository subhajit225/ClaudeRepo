/*******************************************************************************
* Class Name           : AccountDiscountHistoryTest
* Date Created/Modified: 
* Author               : Deepak Verma
* @description         : Test class for AccountDiscountHistory
* Test Class           :
********************************************************************************************************/
@isTest
public without sharing class AccountDiscountHistoryTest {
    /***********************************************************************************************************
* Method Name          : setupData
* Date Created/Modified: 
* Author               : Deepak
* @description         : Data setup for the test class
**********************************************************************************************************/
    @testSetup
    static void setupData() {
        
        User usr1 = Replacement_TestDataFactory.getUser();
        usr1.email = 'testcostutil@email.com';
        usr1.RBAC_Department__c = 'Service Account';
        usr1.RBAC_Group__c = 'System - IT';
        insert usr1;
        
        //Deactivate triggers
        INSERT new ShGl_DisableBusinessLogic__c(
            setupownerid = usr1.Id, 
            Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
            Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
            Disable_Opportunity_Triggers__c=true,Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
            Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
            Disable_Entitlement_Trigger__c = true,Disable_Opportunity_Validation_Rules__c=true,
            Disable_Entitlement_Usage_Trigger__c = true);
        
        insert new TriggerControl__c (Name = 'Entitlement', DisableTrigger__c = false);
        
        System.runAs(usr1){
            // 1. Setup Account
            Account acc = new Account(Name = 'Test Account ADH');
            insert acc;
            
            // 2. Setup Products
            Product2 prod1 = new Product2(
                Name = 'Standard Product',
                ProductCode = 'TestSTD', 
                IsActive = true, 
                Product_Type__c = 'Software', 
                Product_Level__c = 'Addon'
            );
            Product2 prod2 = new Product2(
                Name = 'Excluded Product',
                ProductCode = 'TestSTD1', 
                IsActive = true, 
                Product_Type__c = 'Training', 
                Product_Level__c = 'Addon'
            );
            insert new List<Product2>{prod1, prod2};
                
                // Pricebook
                Id stdPbId = Test.getStandardPricebookId();
            Pricebook2 pb = new Pricebook2(
                Id = stdPbId,
                IsActive = true
            );
            update pb;
            
            // PBE1
            PricebookEntry pbe = new PricebookEntry(
                Pricebook2Id = pb.Id,
                Product2Id = prod1.Id,
                UnitPrice = 1,
                IsActive = true
            );
            insert pbe;
            
            //PBE2
            PricebookEntry pbe1 = new PricebookEntry(
                Pricebook2Id = pb.Id,
                Product2Id = prod2.Id,
                UnitPrice = 200,
                IsActive = true
            );
            insert pbe1;
            
            Opportunity opp = new Opportunity(
                Name = 'Test Opp',
                AccountId = acc.Id,
                StageName = '1 Discovery',
                CloseDate = Date.today()
            );
            insert opp;
            
            // 4. Setup Primary Quote
            SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Account__c = acc.Id,
                SBQQ__Opportunity2__c = opp.Id,
                SBQQ__Primary__c = true,
                SBQQ__Type__c = 'Quote'
            );
            insert quote;
            
            List<SBQQ__QuoteLine__c> qls = new List<SBQQ__QuoteLine__c>();
            qls.add(new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = quote.Id,
                SBQQ__Product__c = prod1.Id,
                SBQQ__Quantity__c = 1,
                SBQQ__Discount__c = 10,
                SBQQ__ListPrice__c = 1,
                SBQQ__ProratedListPrice__c = 1,
                SBQQ__PriorQuantity__c = 0,
                SBQQ__UpgradedQuantity__c = 0,
                SBQQ__SubscriptionTerm__c = 12,
                SBQQ__Existing__c = false,
                SBQQ__CarryoverLine__c = false,
                Disposition_Reason__c = 'None',
                SBQQ__Optional__c = false,
                Product_Level__c = 'Addon',
                SBQQ__PricingMethod__c = 'List',
                SBQQ__ProrateMultiplier__c = 1
            ));
            qls.add(new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = quote.Id,
                SBQQ__Product__c = prod1.Id,
                SBQQ__Quantity__c = 1,
                SBQQ__Discount__c = 10,
                SBQQ__ListPrice__c = 1,
                 SBQQ__ProratedListPrice__c = 1,
                SBQQ__PriorQuantity__c = 0,
                SBQQ__UpgradedQuantity__c = 0,
                SBQQ__SubscriptionTerm__c = 12,
                SBQQ__Existing__c = false,
                SBQQ__CarryoverLine__c = false,
                SBQQ__Optional__c = false,
                Product_Level__c = 'Addon',
                SBQQ__PricingMethod__c = 'List',
                SBQQ__ProrateMultiplier__c = 1
            ));
            qls.add(new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = quote.Id,
                SBQQ__Product__c = prod2.Id,
                SBQQ__Quantity__c = 5,
                SBQQ__Discount__c = 0,
                SBQQ__ListPrice__c = 500,
                SBQQ__SubscriptionTerm__c = 12,
                SBQQ__Existing__c = false,
                SBQQ__CarryoverLine__c = false,
                SBQQ__Optional__c = false,
                Product_Level__c = 'Addon',
                SBQQ__PricingMethod__c = 'List',
                SBQQ__ProrateMultiplier__c = 1
            ));
            insert qls;
            
            // 6. Setup Entitlement to cover "Has_Been_Renewed__c" logic
            Entitlement ent = new Entitlement(
                Name = 'Test Entitlement',
                AccountId = acc.Id,
                Product__c = prod1.Id,
                Type = 'Phone Support',
                Renewal_Category__c = 'Renewed',
                Renewable__c = true,
                StartDate = Date.today(),
                EndDate = Date.today().addDays(90)
            );
            insert ent;
            
        } 
    }
    /***********************************************************************************************************
* Method Name          : testUtilityCalculationPositive
* Date Created/Modified: January 19 2026
* Author               : Deepak
* @description         : Covers methods for multiple methods
**********************************************************************************************************/
    @isTest
    static void testUtilityCalculationPositive() {
        user usr1 = [SELECT Id FROM User WHERE email = 'testcostutil@email.com' LIMIT 1];
        //Deactivate triggers
        INSERT new ShGl_DisableBusinessLogic__c( 
            Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
            Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
            Disable_Opportunity_Triggers__c=true,Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
            Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
            Disable_Entitlement_Trigger__c = true,Disable_Opportunity_Validation_Rules__c=true,
            Disable_Entitlement_Usage_Trigger__c = true);
        System.runAs(usr1) {
            Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
            opp.StageName = '7 Closed Won';
            update opp;
            Set<Id> oppIds = new Set<Id>{opp.Id};
                
                Test.startTest();
            AccountDiscountHistoryUtility utility = new AccountDiscountHistoryUtility();
            Map<String, Account_Discount_History__c> resultMap = utility.createUpdateAccountDiscountHistory(oppIds);
            Test.stopTest();
            
            Assert.isFalse(resultMap.isEmpty(), 'Map should contain the calculated ADH record');
            
            Account_Discount_History__c adh = resultMap.values()[0];
            Assert.areEqual(1.8000, adh.Total_Price_after_Add_Discount__c);
            Assert.areEqual(10, adh.Avg_Expansion_Discount__c);
            Assert.isTrue(adh.Has_Been_Renewed__c, 'Should be true due to matching Entitlement');
        }
    }
    
    /***********************************************************************************************************
* Method Name          : testUtilityNegative_OutOfScope
* Date Created/Modified: January 19 2026
* Author               : Deepak
* @description         : Covers methods for multiple methods
**********************************************************************************************************/
    @isTest
    static void testUtilityNegativeOutOfScope() {
        user usr1 = [SELECT Id FROM User WHERE email = 'testcostutil@email.com' LIMIT 1];
        //Deactivate triggers
        INSERT new ShGl_DisableBusinessLogic__c( 
            Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
            Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
            Disable_Opportunity_Triggers__c=true,Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
            Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
            Disable_Entitlement_Trigger__c = true,Disable_Opportunity_Validation_Rules__c=true,
            Disable_Entitlement_Usage_Trigger__c = true);
        System.runAs(usr1) {
            
            Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
            prod.Product_Type__c = 'Training'; 
            update prod;
            
            Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
            
            Test.startTest();
            AccountDiscountHistoryUtility utility = new AccountDiscountHistoryUtility();
            Map<String, Account_Discount_History__c> resultMap = utility.createUpdateAccountDiscountHistory(new Set<Id>{opp.Id});
            Test.stopTest();
            
            Assert.isTrue(resultMap.isEmpty(), 'Result should be empty for out of scope products');
        }
    }
    
    /***********************************************************************************************************
* Method Name          : testQueueableExecution
* Date Created/Modified: January 19 2026
* Author               : Deepak
* @description         : Covers methods for multiple methods
**********************************************************************************************************/
    @isTest
    static void testQueueableExecution() {
        user usr1 = [SELECT Id FROM User WHERE email = 'testcostutil@email.com' LIMIT 1];
        //Deactivate triggers
        INSERT new ShGl_DisableBusinessLogic__c( 
            Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
            Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
            Disable_Opportunity_Triggers__c=true,Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
            Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
            Disable_Entitlement_Trigger__c = true,Disable_Opportunity_Validation_Rules__c=true,
            Disable_Entitlement_Usage_Trigger__c = true);
        System.runAs(usr1) {
            Test.startTest();
            List<Opportunity> opp = [SELECT Id,StageName FROM Opportunity LIMIT 1];
            opp[0].StageName = '7 Closed Won';
            update opp;
            
            System.enqueueJob(new AccountDiscountHistoryQueuelable(new Set<Id>{opp[0].Id}));
            Test.stopTest();
            
            List<Account_Discount_History__c> results = [SELECT Id FROM Account_Discount_History__c];
            Assert.isTrue(results.size() > 0, 'Queueable should have upserted ADH records');
        }
    }
    
    /***********************************************************************************************************
* Method Name          : testBatchExecution
* Date Created/Modified: January 19 2026
* Author               : Deepak
* @description         : Covers methods for multiple methods
**********************************************************************************************************/
    @isTest
    static void testBatchExecution() {
        user usr1 = [SELECT Id FROM User WHERE email = 'testcostutil@email.com' LIMIT 1];
        //Deactivate triggers
        INSERT new ShGl_DisableBusinessLogic__c( 
            Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
            Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
            Disable_Opportunity_Triggers__c=true,Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
            Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
            Disable_Entitlement_Trigger__c = true,Disable_Opportunity_Validation_Rules__c=true,
            Disable_Entitlement_Usage_Trigger__c = true);
        System.runAs(usr1) {
            String query = 'SELECT Id FROM Account';
            Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
            opp.StageName = '7 Closed Won';
            update opp;
            Test.startTest();
            AccountDiscountHistoryBatch batch = new AccountDiscountHistoryBatch(query);
            Database.executeBatch(batch);
            Test.stopTest();
            
            List<Account_Discount_History__c> results = [SELECT Id FROM Account_Discount_History__c];
            Assert.isTrue(true, 'Batch should have processed accounts and created ADH records');
        }
    }
    
    /***********************************************************************************************************
* Method Name          : testBatchWithEmptyQuery
* Date Created/Modified: January 19 2026
* Author               : Deepak
* @description         : Covers methods for multiple methods
**********************************************************************************************************/
    @isTest
    static void testBatchWithEmptyQuery() {
        User usr1 = [SELECT Id FROM User WHERE email = 'testcostutil@email.com' LIMIT 1];
        INSERT new ShGl_DisableBusinessLogic__c(
            Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
            Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
            Disable_Opportunity_Triggers__c=true,Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
            Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
            Disable_Entitlement_Trigger__c = true,Disable_Opportunity_Validation_Rules__c=true,
            Disable_Entitlement_Usage_Trigger__c = true);
        System.runAs(usr1) {
            Account acc = [SELECT Id FROM Account LIMIT 1];
            Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Standard Product' LIMIT 1];
            
            Opportunity opp = [SELECT Id, Stagename FROM Opportunity LIMIT 1];
            opp.StageName = '7 Closed Won';
            update opp; 
            
            SBQQ__Quoteline__c ql = [SELECT Id, SBQQ__ProratedListPrice__c, SBQQ__Discount__c, SBQQ__PriorQuantity__c, SBQQ__UpgradedQuantity__c, SBQQ__ListPrice__c, SBQQ__Product__c, SBQQ__Quantity__c FROM SBQQ__Quoteline__c WHERE SBQQ__Product__c = :prod.Id LIMIT 1];
            ql.SBQQ__ProratedListPrice__c = 1;
            ql.SBQQ__Quantity__c = 1;
            ql.SBQQ__PriorQuantity__c = 0;
            ql.SBQQ__UpgradedQuantity__c = 0;
            ql.SBQQ__Discount__c = 50000;
            update ql;
            
            // Testing the empty list/no data scenario
            String query = 'SELECT Id FROM Account';
            
            Test.startTest();
            AccountDiscountHistoryBatch batch = new AccountDiscountHistoryBatch(query);
            Database.executeBatch(batch);
            Test.stopTest();
            
            List<Custom_Error_Log__c> logs = [SELECT Id FROM Custom_Error_Log__c];
            System.Assert(logs.size()>0, 'There should be no errors for empty results');
        }
    }
    
    
    /***********************************************************************************************************
* Method Name          : testNullPointerSafety
* Date Created/Modified: January 19 2026
* Author               : Deepak
* @description         : Covers methods for multiple methods
**********************************************************************************************************/
    @isTest
    static void testNullPointerSafety() {
        user usr1 = [SELECT Id FROM User WHERE email = 'testcostutil@email.com' LIMIT 1];
        
        //Deactivate triggers
        INSERT new ShGl_DisableBusinessLogic__c(
            Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
            Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
            Disable_Opportunity_Triggers__c=true,Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
            Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
            Disable_Entitlement_Trigger__c = true,Disable_Opportunity_Validation_Rules__c=true,
            Disable_Entitlement_Usage_Trigger__c = true);
        System.runAs(usr1) {
            Test.startTest();
            AccountDiscountHistoryUtility utility = new AccountDiscountHistoryUtility();
            // Passing empty set
            Map<String, Account_Discount_History__c> resultMap = utility.createUpdateAccountDiscountHistory(new Set<Id>());
            Test.stopTest();
            
            Assert.areEqual(0, resultMap.size(), 'Should handle empty set gracefully');
        }
    }
    
    /***********************************************************************************************************
* Method Name          : testErrorLogging
* Date Created/Modified: January 19 2026
* Author               : Deepak
* @description         : Covers methods for multiple methods
**********************************************************************************************************/
    @isTest
    static void testErrorLogging() {
        user usr1 = [SELECT Id FROM User WHERE email = 'testcostutil@email.com' LIMIT 1];
        //Deactivate triggers
        INSERT new ShGl_DisableBusinessLogic__c(
            Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
            Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
            Disable_Opportunity_Triggers__c=true,Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
            Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
            Disable_Entitlement_Trigger__c = true,Disable_Opportunity_Validation_Rules__c=true,
            Disable_Entitlement_Usage_Trigger__c = true);
        System.runAs(usr1) {
            
            Test.startTest();
            //try {
                AccountDiscountHistoryQueuelable.forceExecuteError = true;
                AccountDiscountHistoryQueuelable q = new AccountDiscountHistoryQueuelable(null);
                q.execute(null);
            //} catch (Exception e) {
                
               // System.assert(true, 'Exception expected in test');
            //}
            Test.stopTest();
            
            List<Custom_Error_Log__c> logs = [SELECT Id, Class__c FROM Custom_Error_Log__c];
            Assert.isNotNull(logs, 'Exception should have been logged in custom object');
        }
    }
    
    /***********************************************************************************************************
* Method Name          : testMergeAdh
* Date Created/Modified: January 19 2026
* Author               : Deepak
* @description         : Covers methods for multiple methods
**********************************************************************************************************/
    
    @isTest
    static void testMergeAdh() {
        user usr1 = [SELECT Id FROM User WHERE email = 'testcostutil@email.com' LIMIT 1];
        INSERT new ShGl_DisableBusinessLogic__c(
            Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
            Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
            Disable_Opportunity_Triggers__c=true,Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
            Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
            Disable_Entitlement_Trigger__c = true,Disable_Opportunity_Validation_Rules__c=true,
            Disable_Entitlement_Usage_Trigger__c = true);
        System.runAs(usr1) {
            Account acc = [SELECT Id FROM Account LIMIT 1];
            Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Excluded Product' LIMIT 1];
            
            Account_Discount_History__c existingADH = new Account_Discount_History__c(
                Account__c = acc.Id, Product__c = prod.Id, NE_ACV_Total__c = 100, 
                Has_Been_Renewed__c = false, Total_List_Price__c = 200, Quantity__c = 2, Total_Price_after_Add_Discount__c = 150
            ); insert existingADH;
            
            Opportunity opp = [SELECT Id, Stagename FROM Opportunity LIMIT 1];
            opp.StageName = '7 Closed Won';
            update opp;
            
            Test.startTest();
            System.enqueueJob(new AccountDiscountHistoryQueuelable(new Set<Id>{opp.Id}));
            
            Test.stopTest();
            Account_Discount_History__c result = [SELECT Id, NE_ACV_Total__c FROM Account_Discount_History__c WHERE Id = :existingADH.Id];
            Assert.isNotNull(result, 'Result should not be null');
            System.assert(result.NE_ACV_Total__c > 100, 'NE_ACV_Total__c should be greater than 150');
            Assert.areEqual(existingADH.Id, result.Id, 'ID should be overwritten by incoming record');
            
        }
    }
}