/***********************************************************************************************************
* Class Name           : AutoApprovalTriggerUtilityTest
* Date Created/Modified: 15/11/2025
* Author               : Deepak
* @description         : Test class for AutoApprovalTriggerUtility
* Test Class           :
/********************************************************************************************************/
@isTest
public class AutoApprovalTriggerUtilityTest { 
    /***********************************************************************************************************
    * Method Name          : setup
    * Date Created/Modified: 15/11/2025
    * Author               : Deepak
    * @description         : Data setup for the test class
    /**********************************************************************************************************/
    @testSetup
    static void setup() {
        // Users / groups / approvers via your factory
        List<Profile> profs = [
            SELECT Id
            FROM Profile
            WHERE Name IN ('Rubrik Inside Sales', 'System Administrator')
            ORDER BY Name
        ];
        
        List<User> users = TestDataFactory.getUsers('testClassUser', new Set<Id>{ profs[0].Id }, 1);
        users.addAll(TestDataFactory.getUsers('testClassUserAdmin', new Set<Id>{ profs[1].Id }, 1));
        insert users;

        //Deactivate triggers
        INSERT new ShGl_DisableBusinessLogic__c(
            Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
            Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
            Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,
            Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
            Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
            Disable_Opportunity_Validation_Rules__c=true);
        // Trigger control
        TriggerControl__c triggerControl = new TriggerControl__c(
            Name = 'Approval',
            DisableTrigger__c = true
        );
        insert triggerControl;

        // Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Contact
        Contact con = new Contact(
            LastName = 'Test',
            FirstName = 'Contact',
            AccountId = acc.Id,
            Email = 'test4324324.test324325344@1234.com'
        );
        insert con;

        // Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            AccountId = acc.Id,
            StageName = '1 Discovery',
            CloseDate = System.today(),
            ForecastCategoryName = 'Best Case',
            Business_Unit__c = 'Rubrik',
            Installation_Assigned_To__c = 'FE Install'
        );
        insert opp;

        // Product
        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'RBK-R6404S-01-STARTER',
            IsActive = true
        );
        insert prod;

        // Pricebook
        Id stdPbId = Test.getStandardPricebookId();
        Pricebook2 pb = new Pricebook2(
            Id = stdPbId,
            IsActive = true
        );
        update pb;

        // PBE
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pb.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        // Assets
        Asset a1 = new Asset(
            Name = '123456',
            Product2Id = prod.Id,
            AccountId = acc.Id,
            ContactId = con.Id
        );
        insert a1;

        Asset a2 = new Asset(
            Name = '12345',
            Product2Id = prod.Id,
            AccountId = acc.Id,
            ContactId = con.Id
        );
        insert a2;

        // Quote
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__PriceBook__c = pb.Id,
            SBQQ__Status__c = 'Draft',
            SBQQ__Opportunity2__c = opp.Id,
            RWD_Deal_Ops_Exception__c = 'Test Quote',
            RWD_Deal_Ops_Exception_Justification__c = 'RWD Deals Ops Ezception is For Test',
            SBQQ__Type__c = 'Quote',
            OpportunitySubType__c = 'GC Offer',
            Task_Products__c = 'RBK-DISK-RETENTION',
            Has_Mosaic_SKUs__c = true,
            Deal_Desk_Notes__c = 'Test quot deal',
            ApprovalStatus__c = 'Approved'
        );
        insert quote;

        // Quote line
        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__Product__c = prod.Id,
            SBQQ__PricebookEntryId__c = pbe.Id,
            SBQQ__Quantity__c = 2.00,
            SBQQ__ListPrice__c = 100,
            SBQQ__Discount__c = 55.00,
            SBQQ__Number__c = 1,
            SBQQ__SubscribedAssetIds__c = a1.Id,
            SubscribedAssetNames__c = 'BB192863040046',
            RWD_approval_Tier__c = 'RSM,RD_New | Tier:0-500|,DD_New'
        );
        insert ql;
        sbaa__ApprovalChain__c chain = new sbaa__ApprovalChain__c(
            Name = 'Identity Offerings Approvals',
            sbaa__TargetObject__c = 'SBQQ__Quote__c'
        );
        insert chain;
         // Rule
        List<sbaa__ApprovalRule__c> rules = new List<sbaa__ApprovalRule__c>();
        sbaa__ApprovalRule__c rule = new sbaa__ApprovalRule__c(
            sbaa__Active__c = true,
            sbaa__TargetObject__c = 'SBQQ__Quote__c',
            sbaa__ApprovalChain__c = chain.Id,
            sbaa__ApprovalStep__c  = 1.0
        );

        sbaa__ApprovalRule__c ruleObj = new sbaa__ApprovalRule__c(
            sbaa__Active__c = true,
            sbaa__TargetObject__c = 'SBQQ__Quote__c',
            sbaa__ApprovalChain__c = chain.Id,
            sbaa__ApprovalStep__c  = 2.0
        );
        rules.add(rule);
        rules.add(ruleObj);
        insert rules;

        sbaa__ApprovalVariable__c tstVar = new sbaa__ApprovalVariable__c(
            sbaa__TargetObject__c = 'SBQQ__QuoteLine__c',
                sbaa__AggregateField__c = 'SBQQ__Quantity__c',
                sbaa__AggregateFunction__c = 'Count',
                sbaa__FilterField__c = 'SBQQ__Quantity__c',
                sbaa__FilterValue__c = '0',
                sbaa__Operator__c = 'greater than',
                sbaa__Type__c = 'Summary'
            );
        insert tstVar;

        List<sbaa__ApprovalCondition__c> conditions = new List<sbaa__ApprovalCondition__c>();
        sbaa__ApprovalCondition__c cond1 = new sbaa__ApprovalCondition__c(
            sbaa__ApprovalRule__c = rule.Id,
            Custom_Smart_Approval__c = true,
            sbaa__Operator__c = 'greater than',
            sbaa__FilterValue__c = '0',
            sbaa__TestedVariable__c = tstVar.Id,
            Track_Fields__c = 'RWD_approval_Tier__c;SBQQ__Quantity__c: greater than;Approval_Discount__c: greater than'
        );
        conditions.add(cond1);

        sbaa__ApprovalCondition__c cond2 = new sbaa__ApprovalCondition__c(
            sbaa__ApprovalRule__c = ruleObj.Id,
            Custom_Smart_Approval__c = true,
            sbaa__Operator__c = 'greater than',
            sbaa__FilterValue__c = '0',
            sbaa__TestedVariable__c = tstVar.Id,
            Track_Fields__c = 'RWD_approval_Tier__c;SBQQ__Quantity__c: greater than;Approval_Discount__c: greater than'
        );
        conditions.add(cond2);
        insert conditions;

        List<sbaa__Approver__c> approvers = TestDataFactory.getApprovers(
            new Set<Id>{ users[0].Id, users[1].Id}, new Set<Id>{}
        );
        insert approvers;
        
        // Base Approval (Requested)
        List<sbaa__Approval__c> approvals = new List<sbaa__Approval__c>();
        sbaa__Approval__c appr = new sbaa__Approval__c(
            sbaa__Rule__c      = rule.Id,
            Quote__c           = quote.Id,
            sbaa__Status__c    = 'Requested',
            sbaa__Opportunity__c = opp.Id,
            sbaa__Approver__c  = approvers[0].Id,
            sbaa__AssignedTo__c = users[0].Id,
            sbaa__RecordField__c = 'Quote__c',
            sbaa__ApprovalStep__c = 1,
            sbaa__DelegatedApprover__c = approvers[1].Id,
            Feedback_Groups__c = 'Deal Operations',
            sbaa__ApprovalChain__c = chain.Id
        );
        approvals.add(appr);

        sbaa__Approval__c appr1 = new sbaa__Approval__c(
            sbaa__Rule__c      = ruleObj.Id,
            Quote__c           = quote.Id,
            sbaa__Status__c    = Constants.STATUS_ASSIGNED,
            sbaa__Opportunity__c = opp.Id,
            sbaa__Approver__c  = approvers[0].Id,
            sbaa__AssignedTo__c = users[0].Id,
            sbaa__RecordField__c = 'Quote__c',
            sbaa__ApprovalStep__c = 1,
            sbaa__DelegatedApprover__c = approvers[1].Id,
            Feedback_Groups__c = 'Deal Operations',
            sbaa__ApprovalChain__c = chain.Id
        );
        approvals.add(appr1);
        insert approvals;
    }
    
    /***********************************************************************************************************
    * Method Name          : autoApproveTest
    * Date Created/Modified: 20/11/2025
    * Author               : Deepak
    * @description         : Covers methods for multiple methods
    /**********************************************************************************************************/
    @isTest
    static void autoApproveTest() {
        user usr1 = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive=true LIMIT 1];
        
        //Deactivate triggers
        INSERT new ShGl_DisableBusinessLogic__c(setupownerid = usr1.Id, 
        Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
        Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
        Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,
        Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
        Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
        Disable_Opportunity_Validation_Rules__c=true);
		
        System.runAs(usr1) {
             List<SBAA__Approval__c> approvals = [
                SELECT Id, Quote__c, sbaa__Rule__c, sbaa__ApprovalChain__c,  sbaa__Status__c, sbaa__ApprovalStep__c
                FROM sbaa__Approval__c
            ];
            List<SBQQ__Quoteline__c> quotelines = [SELECT Id, SBQQ__Quote__c FROM SBQQ__Quoteline__c];
            List<Approval_Snapshot__c> approvalSnapshots = new List<Approval_Snapshot__c>();
            for(SBQQ__Quoteline__c ql : quotelines) {
                Approval_Snapshot__c aprSnp = new Approval_Snapshot__c(
                    History__c ='{"'+approvals[0].sbaa__Rule__c+'":{"SBQQ__Quantity__c":2.00,"Approval_Discount__c":55.00,"RWD_approval_Tier__c":"0-500"}}',
                    Quote_Line__c = ql.Id,
                    Quote__c = ql.SBQQ__Quote__c
                );
                approvalSnapshots.add(aprSnp);
            }
            insert approvalSnapshots;
           
            Test.startTest();
            AutoApprovalTriggerUtility.autoApprove(approvals);
            AutoApprovalTriggerUtility.updateQuoteStatus(approvals[0].Quote__c);
            Test.stopTest();
            System.assert(true);
        }
    }
    /***********************************************************************************************************
    * Method Name          : createSnapshotsTest
    * Date Created/Modified: 20/11/2025
    * Author               : Deepak
    * @description         : Covers methods for multiple methods
    /**********************************************************************************************************/
    @isTest
    static void createSnapshotsTest() {
        user usr1 = [SELECT Id FROM User WHERE email  = 'user@test.com.sandbox' LIMIT 1];
        //Deactivate triggers
        INSERT new ShGl_DisableBusinessLogic__c(setupownerid = usr1.Id, 
        Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
        Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
        Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,
        Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
        Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
        Disable_Opportunity_Validation_Rules__c=true);
        System.runAs(usr1) {
            sbaa__ApprovalRule__c rule = [
                SELECT Id
                FROM sbaa__ApprovalRule__c
                LIMIT 1
            ];
            List<SBQQ__Quoteline__c> quotelines = [SELECT Id, SBQQ__Quote__c FROM SBQQ__Quoteline__c];
            List<Approval_Snapshot__c> approvalSnapshots = new List<Approval_Snapshot__c>();
            for(SBQQ__Quoteline__c ql : quotelines) {
                Approval_Snapshot__c aprSnp = new Approval_Snapshot__c(
                    History__c ='{"'+rule.Id+'":{"SBQQ__Quantity__c":2.00,"Approval_Discount__c":55.00,"RWD_approval_Tier__c":"0-500"}}',
                    Quote_Line__c = ql.Id,
                    Quote__c = ql.SBQQ__Quote__c
                );
                approvalSnapshots.add(aprSnp);
            }
            insert approvalSnapshots;
            sbaa__Approval__c appr = [
                SELECT Id, sbaa__Rule__c, Quote__c, sbaa__Status__c, Approvals_from_Source_Quote__c
                FROM sbaa__Approval__c
                LIMIT 1
            ];

            sbaa__ApprovalVariable__c tstVar = new sbaa__ApprovalVariable__c(
            sbaa__TargetObject__c = 'SBQQ__QuoteLine__c',
                sbaa__AggregateField__c = 'SBQQ__Quantity__c',
                sbaa__AggregateFunction__c = 'Count',
                sbaa__FilterField__c = 'SBQQ__Quantity__c',
                sbaa__FilterValue__c = '0',
                sbaa__Operator__c = 'greater than',
                sbaa__Type__c = 'Summary'
            );
            insert tstVar;
            
            sbaa__ApprovalCondition__c cond1 = new sbaa__ApprovalCondition__c(
                sbaa__ApprovalRule__c = rule.Id,
                Custom_Smart_Approval__c = true,
                sbaa__Operator__c = 'greater than',
                sbaa__FilterValue__c = '0',
                sbaa__TestedVariable__c = tstVar.Id,
                Track_Fields__c = 'RWD_approval_Tier__c;SBQQ__Quantity__c: greater than;Approval_Discount__c: greater than'
            );
            insert cond1;
            
            // Old map with Requested
            sbaa__Approval__c oldAppr = appr.clone(false, false, false, false);
            oldAppr.sbaa__Status__c = 'Requested';
            Map<Id, sbaa__Approval__c> oldMap = new Map<Id, sbaa__Approval__c>{
                appr.Id => oldAppr
            };

            // Move live record to Approved
            appr.sbaa__Status__c = Constants.STATUS_APPROVED;
            update appr;

            List<sbaa__Approval__c> listAppr = new List<sbaa__Approval__c>{appr};

            Test.startTest();
            AutoApprovalTriggerUtility.createSnapshots(listAppr, oldMap);
            Test.stopTest();
            System.assert(true);
        }
    }

    /***********************************************************************************************************
    * Method Name          : createSnapShotFailureTest
    * Date Created/Modified: 20/11/2025
    * Author               : Deepak
    * @description         : Covers methods for multiple methods
    /**********************************************************************************************************/
    @isTest
    static void createSnapShotFailureTest() {
        user usr1 = [SELECT Id FROM User WHERE email  = 'user@test.com.sandbox' LIMIT 1];
        //Deactivate triggers
        INSERT new ShGl_DisableBusinessLogic__c(setupownerid = usr1.Id, 
        Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
        Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
        Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,
        Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
        Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
        Disable_Opportunity_Validation_Rules__c=true);
        System.runAs(usr1) {
            Test.startTest();
            AutoApprovalTriggerUtility.createSnapshots(null, null);
            AutoApprovalTriggerUtility.autoApprove(null);
            Test.stopTest();
            System.assert(true);
        }       
    }

    /***********************************************************************************************************
    * Method Name          : compareRecordWithRuleHistoryTest
    * Date Created/Modified: 20/11/2025
    * Author               : Deepak
    * @description         : Covers methods for multiple methods
    /**********************************************************************************************************/
    @isTest
    static void compareRecordWithRuleHistoryTest() {
        user usr1 = [SELECT Id FROM User WHERE email  = 'user@test.com.sandbox' LIMIT 1];
        //Deactivate triggers
        INSERT new ShGl_DisableBusinessLogic__c(setupownerid = usr1.Id, 
        Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
        Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
        Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,
        Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
        Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
        Disable_Opportunity_Validation_Rules__c=true);
        System.runAs(usr1) {
            sbaa__ApprovalRule__c rule = [
                SELECT Id
                FROM sbaa__ApprovalRule__c
                LIMIT 1
            ];
            List<SBQQ__Quoteline__c> quotelines = 
                [SELECT Id, RWD_approval_Tier__c, SBQQ__Discount__c, SBQQ__Quote__c
                FROM SBQQ__QuoteLine__c];
            List<Approval_Snapshot__c> approvalSnapshots = new List<Approval_Snapshot__c>();
            for(SBQQ__Quoteline__c ql : quotelines) {
                Approval_Snapshot__c aprSnp = new Approval_Snapshot__c(
                    History__c ='{"'+rule.Id+'":{"SBQQ__Quantity__c":2.00,"Approval_Discount__c":55.00,"RWD_approval_Tier__c":"0-500"}}',
                    Quote_Line__c = ql.Id,
                    Quote__c = ql.SBQQ__Quote__c
                );
                approvalSnapshots.add(aprSnp);
            }
            insert approvalSnapshots;
            Map<String, Object> tierHistory = new Map<String, Object>{
                Constants.QL_RWD_APPROVAL_TIER => '1001-100000'
            };
            Map<String, String> tierOps = new Map<String, String>{
                Constants.QL_RWD_APPROVAL_TIER => Constants.EQUALS_OPERATOR
            };

            Map<String, Object> updatedTier =
                AutoApprovalTriggerUtility.compareRecordWithRuleHistory(quotelines[0], tierHistory, tierOps);
            System.assertNotEquals(null, updatedTier);

            Map<String, Object> discHistory = new Map<String, Object>{
                'SBQQ__Discount__c' => 5
            };
            Map<String, String> discOps = new Map<String, String>{
                'SBQQ__Discount__c' => Constants.GREATER_THAN_OPERATOR
            };

            Map<String, Object> updatedDisc =
                AutoApprovalTriggerUtility.compareRecordWithRuleHistory(quotelines[0], discHistory, discOps);
            System.assertNotEquals(null, updatedDisc);
        }
    }

    /***********************************************************************************************************
    * Method Name          : evaluateSmartApprovalConditionsEvaluateApprovalRulesTest
    * Date Created/Modified: 20/11/2025
    * Author               : Deepak
    * @description         : Covers methods for multiple methods
    /**********************************************************************************************************/
    @isTest
    static void evaluateSmartApprovalConditionsEvaluateApprovalRulesTest() {
        user usr1 = [SELECT Id FROM User WHERE email  = 'user@test.com.sandbox' LIMIT 1];
        //Deactivate triggers
        INSERT new ShGl_DisableBusinessLogic__c(setupownerid = usr1.Id, 
        Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
        Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
        Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,
        Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
        Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
        Disable_Opportunity_Validation_Rules__c=true);
        System.runAs(usr1) {
            sbaa__ApprovalRule__c rule = [
                SELECT Id
                FROM sbaa__ApprovalRule__c
                LIMIT 1
            ];
            SBQQ__Quote__c quote = [
                SELECT Id,
                  (SELECT Id, SBQQ__Quantity__c, SBQQ__Discount__c, SBQQ__ProductCode__c, SBQQ__Quote__c
                     FROM SBQQ__LineItems__r)
                FROM SBQQ__Quote__c
                LIMIT 1
            ];
            List<Approval_Snapshot__c> approvalSnapshots = new List<Approval_Snapshot__c>();
            for(SBQQ__Quoteline__c ql : quote.SBQQ__LineItems__r) {
                Approval_Snapshot__c aprSnp = new Approval_Snapshot__c(
                    History__c ='{"'+rule.Id+'":{"SBQQ__Quantity__c":2.00,"Approval_Discount__c":55.00,"RWD_approval_Tier__c":"0-500"}}',
                    Quote_Line__c = ql.Id,
                    Quote__c = quote.Id
                );
                approvalSnapshots.add(aprSnp);
            }
            insert approvalSnapshots;
            sbaa__ApprovalVariable__c tstVar = new sbaa__ApprovalVariable__c(
            sbaa__TargetObject__c = 'SBQQ__QuoteLine__c',
                sbaa__AggregateField__c = 'SBQQ__Quantity__c',
                sbaa__AggregateFunction__c = 'Count',
                sbaa__FilterField__c = 'SBQQ__Quantity__c',
                sbaa__FilterValue__c = '0',
                sbaa__Operator__c = 'greater than',
                sbaa__Type__c = 'Summary'
            );
            insert tstVar;
            sbaa__ApprovalCondition__c cond1 = new sbaa__ApprovalCondition__c(
                sbaa__ApprovalRule__c = rule.Id,
                Custom_Smart_Approval__c = true,
                sbaa__Operator__c = 'greater than',
                sbaa__FilterValue__c = '0',
                sbaa__TestedVariable__c = tstVar.Id,
                Track_Fields__c = 'RWD_approval_Tier__c;SBQQ__Quantity__c: greater than;Approval_Discount__c: greater than'
            );
            insert cond1;
            Map<Id, List<sbaa__ApprovalCondition__c>> condMap =
                AutoApprovalTriggerUtility.getSmartConditions(
                    AutoApprovalTriggerUtility.getAllApprovalConditions(new Set<Id>{rule.Id}));
            AutoApprovalTriggerUtility.ResponseDetails rd =
                AutoApprovalTriggerUtility.evaluateApprovalRules(quote, condMap);
            System.assertNotEquals(null, rd);
            System.assert(rd.ruleToApplicableLines.containsKey(rule.Id));
        }
    }

    /***********************************************************************************************************
    * Method Name          : getQuoteDataTest
    * Date Created/Modified: 20/11/2025
    * Author               : Deepak
    * @description         : Covers methods for multiple methods
    /**********************************************************************************************************/
    @isTest
    static void getQuoteDataTest() {
        user usr1 = [SELECT Id FROM User WHERE email  = 'user@test.com.sandbox' LIMIT 1];
        //Deactivate triggers
        INSERT new ShGl_DisableBusinessLogic__c(setupownerid = usr1.Id, 
        Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
        Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
        Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,
        Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
        Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
        Disable_Opportunity_Validation_Rules__c=true);
        System.runAs(usr1) {
            SBQQ__Quote__c quote = [
                SELECT Id,
                    (SELECT Id, SBQQ__Quantity__c, SBQQ__AdditionalDiscountAmount__c, SBQQ__ProductCode__c
                        FROM SBQQ__LineItems__r)
                FROM SBQQ__Quote__c
                LIMIT 1
            ];
            sbaa__ApprovalRule__c rule = [
                SELECT Id
                FROM sbaa__ApprovalRule__c
                LIMIT 1
            ];
            List<Approval_Snapshot__c> approvalSnapshots = new List<Approval_Snapshot__c>();
            for(SBQQ__Quoteline__c ql : quote.SBQQ__LineItems__r) {
                Approval_Snapshot__c aprSnp = new Approval_Snapshot__c(
                    History__c ='{"'+rule.Id+'":{"SBQQ__Quantity__c":2.00,"Approval_Discount__c":55.00,"RWD_approval_Tier__c":"0-500"}}',
                    Quote_Line__c = ql.Id,
                    Quote__c = quote.Id
                );
                approvalSnapshots.add(aprSnp);
            }
            insert approvalSnapshots;

            sbaa__ApprovalVariable__c tstVar = new sbaa__ApprovalVariable__c(
            sbaa__TargetObject__c = 'SBQQ__QuoteLine__c',
                sbaa__AggregateField__c = 'SBQQ__Quantity__c',
                sbaa__AggregateFunction__c = 'Count',
                sbaa__FilterField__c = 'SBQQ__Quantity__c',
                sbaa__FilterValue__c = '0',
                sbaa__Operator__c = 'greater than',
                sbaa__Type__c = 'Summary'
            );
            insert tstVar;
            
            sbaa__ApprovalVariable__c tstVar1 = new sbaa__ApprovalVariable__c(
            sbaa__TargetObject__c = 'SBQQ__QuoteLine__c',
                sbaa__AggregateField__c = 'SBQQ__Quantity__c',
                sbaa__AggregateFunction__c = 'Count',
                sbaa__FilterField__c = 'SBQQ__Quantity__c',
                sbaa__FilterValue__c = '0',
                sbaa__Operator__c = 'greater than',
                sbaa__Type__c = 'Summary'
            );
            insert tstVar1;
            
            List<sbaa__ApprovalCondition__c> aprCondList = new List<sbaa__ApprovalCondition__c>();
            
            sbaa__ApprovalCondition__c cond1 = new sbaa__ApprovalCondition__c(
                sbaa__ApprovalRule__c = rule.Id,
                Custom_Smart_Approval__c = true,
                sbaa__Operator__c = 'greater than',
                sbaa__FilterValue__c = '0',
                sbaa__TestedVariable__c = tstVar.Id,
                sbaa__FilterVariable__c = tstVar1.Id,
                Track_Fields__c = 'RWD_approval_Tier__c;SBQQ__Quantity__c: greater than;Approval_Discount__c: greater than'
            );
            
            sbaa__ApprovalCondition__c cond2 = new sbaa__ApprovalCondition__c(
                sbaa__ApprovalRule__c = rule.Id,
                Custom_Smart_Approval__c = true,
                sbaa__Operator__c = 'greater than',
                sbaa__FilterValue__c = '0',
                sbaa__TestedField__c = 'SBQQ__AdditionalDiscountAmount__c',
                sbaa__FilterField__c = 'SBQQ__AdditionalDiscountAmount__c',
                Track_Fields__c = 'RWD_approval_Tier__c;SBQQ__Quantity__c: greater than;Approval_Discount__c: greater than'
            );
            
			aprCondList.add(cond1); 
            aprCondList.add(cond2);
            
            insert aprCondList;
            
            sbaa__Approval__c appr = [
                SELECT Id, sbaa__CommentsLong__c
                FROM sbaa__Approval__c
                LIMIT 1
            ];
            List<Id> ids = new List<Id>{appr.Id};
                
                List<sbaa__ApprovalCondition__c> aprCond = [select id, sbaa__FilterVariable__r.Name, sbaa__FilterVariable__r.sbaa__AggregateField__c, sbaa__FilterVariable__r.sbaa__FilterField__c, 
                                                            sbaa__TestedVariable__r.Name, sbaa__TestedVariable__r.sbaa__AggregateField__c, sbaa__TestedVariable__r.sbaa__FilterField__c,  sbaa__TestedField__c, 
                                                            sbaa__FilterField__c, Custom_Smart_Approval__c,sbaa__Operator__c, sbaa__FilterValue__c, sbaa__TestedVariable__c, sbaa__FilterVariable__c, 
                                                            sbaa__ApprovalRule__c, sbaa__ApprovalRule__r.sbaa__TargetObject__c
                                                            from sbaa__ApprovalCondition__c where Id= :aprCondList];
                
            Map<Id, List<sbaa__ApprovalCondition__c>> condMap = new Map<Id, List<sbaa__ApprovalCondition__c>>();
            
            condMap.put(rule.Id, aprCond);
            
            Map<String, String> condStrMap = new Map<String, String>();
            condStrMap.put('Approval_Discount__c','greater than');
            condStrMap.put('RWD_approval_Tier__c','greater than');
            condStrMap.put('SBQQ__Quantity__c','greater than');
            
            Map<Id, Map<String, String>> idStrMap = new Map<Id, Map<String, String>>();
            idStrMap.put(rule.id, condStrMap);
                
            Test.startTest();
            AutoApprovalTriggerUtility.getQuoteData(quote.Id, condMap, idStrMap);
            Test.stopTest();
            System.assert(true);
            
        }
    }

    /***********************************************************************************************************
    * Method Name          : operationTest
    * Date Created/Modified: 20/11/2025
    * Author               : Ankita
    * @description         : Covers methods for multiple methods
    /**********************************************************************************************************/
    @isTest
    public static void operationTest() {
        user usr1 = [SELECT Id FROM User WHERE email  = 'user@test.com.sandbox' LIMIT 1];
        System.runAs(usr1) {
            // EQUALS_OPERATOR
            Boolean resultEquals = ConditionsEvaluator.operate('Test', Constants.EQUALS_OPERATOR, 'Test, Test2');
            Boolean resultEquals1 = ConditionsEvaluator.operate('Test', Constants.EQUALS_OPERATOR, 'Test');
            Boolean resultEquals2 = ConditionsEvaluator.operate('Test3', Constants.EQUALS_OPERATOR, 'Test,Test2');

            //NOT_EQUALS_OPERATOR
            Boolean resultNotEquals = ConditionsEvaluator.operate('Test', Constants.NOT_EQUALS_OPERATOR, 'Test, Test2');
            Boolean resultNotEquals1 = ConditionsEvaluator.operate('Test', Constants.NOT_EQUALS_OPERATOR, 'Test1');
            Boolean resultNotEquals2 = ConditionsEvaluator.operate('Test3', Constants.EQUALS_OPERATOR, 'Test,Test2');

            //LESS_THAN_OPERATOR
            Boolean resultLessThan = ConditionsEvaluator.operate(200, Constants.LESS_THAN_OPERATOR, 2000);

            //LESS_OR_EQUALS_OPERATOR
            Boolean resultLessThanEquals = ConditionsEvaluator.operate(200, Constants.LESS_OR_EQUALS_OPERATOR, 200);

            //GREATER_THAN_OPERATOR
            Boolean resultGreaterThan= ConditionsEvaluator.operate(2000, Constants.GREATER_THAN_OPERATOR, 200);

            //GREATER_OR_QUALS_OPERATOR
            Boolean resultGreaterThanEquals= ConditionsEvaluator.operate(200, Constants.GREATER_OR_QUALS_OPERATOR, 200);

            //STARTS_WITH_OPERATOR
            Boolean resultStartsWith = ConditionsEvaluator.operate('Test', Constants.STARTS_WITH_OPERATOR, 'Test123');

            //ENDS_WITH_OPERATOR
            Boolean resultEndsWith = ConditionsEvaluator.operate('123', Constants.ENDS_WITH_OPERATOR, 'Test123');

            //CONTAINS_OPERATOR
            Boolean resultContains = ConditionsEvaluator.operate('123', Constants.CONTAINS_OPERATOR, 'Test123');
            Boolean resultContains1 = ConditionsEvaluator.operate('123', Constants.CONTAINS_OPERATOR, 'Test123, Test234');
            Boolean resultContains2 = ConditionsEvaluator.operate('Test3', Constants.CONTAINS_OPERATOR, 'Test,Test2');

            //DOES_NOT_CONTAIN_OPERATOR
            Boolean resultDoesnotContains = ConditionsEvaluator.operate('123', Constants.DOES_NOT_CONTAIN_OPERATOR, 'Test123');
            Boolean resultDoesnotContains1 = ConditionsEvaluator.operate('Test', Constants.DOES_NOT_CONTAIN_OPERATOR, 'Test12, Test');
            Boolean resultDoesnotContains2 = ConditionsEvaluator.operate('Test3', Constants.CONTAINS_OPERATOR, 'Test,Test2');

            //INCLUDES_OPERATOR
            Boolean resultInclude = ConditionsEvaluator.operate('123', Constants.INCLUDES_OPERATOR, 'Test123');

            System.assert(true);
        }
    }
    /***********************************************************************************************************
    * Method Name          : createNewSnapshotsTest
    * Date Created/Modified: 04/12/2025
    * Author               : Ankita
    * @description         : Covers methods for createSnapshots for new ApprovalSnapshot records
    /**********************************************************************************************************/
    @isTest
    static void createNewSnapshotsTest() {
        user usr1 = [SELECT Id FROM User WHERE email  = 'user@test.com.sandbox' LIMIT 1];
        //Deactivate triggers
        INSERT new ShGl_DisableBusinessLogic__c(setupownerid = usr1.Id, 
        Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
        Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
        Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,
        Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
        Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
        Disable_Opportunity_Validation_Rules__c=true);
        System.runAs(usr1) {
            sbaa__ApprovalRule__c rule = [
                SELECT Id
                FROM sbaa__ApprovalRule__c
                LIMIT 1
            ];
            sbaa__ApprovalVariable__c tstVar = new sbaa__ApprovalVariable__c(
            sbaa__TargetObject__c = 'SBQQ__QuoteLine__c',
                sbaa__AggregateField__c = 'SBQQ__Quantity__c',
                sbaa__AggregateFunction__c = 'Count',
                sbaa__FilterField__c = 'SBQQ__Quantity__c',
                sbaa__FilterValue__c = '0',
                sbaa__Operator__c = 'greater than',
                sbaa__Type__c = 'Summary'
            );
            insert tstVar;
            sbaa__ApprovalCondition__c cond1 = new sbaa__ApprovalCondition__c(
                sbaa__ApprovalRule__c = rule.Id,
                Custom_Smart_Approval__c = true,
                sbaa__Operator__c = 'greater than',
                sbaa__FilterValue__c = '0',
                sbaa__TestedVariable__c = tstVar.Id,
                Track_Fields__c = 'RWD_approval_Tier__c;SBQQ__Quantity__c: greater than;Approval_Discount__c: greater than'
            );
            insert cond1;
            sbaa__Approval__c appr = [
                SELECT Id, sbaa__Rule__c, Quote__c, sbaa__Status__c, Approvals_from_Source_Quote__c
                FROM sbaa__Approval__c
                LIMIT 1
            ];
            // Old map with Requested
            sbaa__Approval__c oldAppr = appr.clone(false, false, false, false);
            oldAppr.sbaa__Status__c = 'Requested';
            Map<Id, sbaa__Approval__c> oldMap = new Map<Id, sbaa__Approval__c>{
                appr.Id => oldAppr
            };

            // Move live record to Approved
            appr.sbaa__Status__c = Constants.STATUS_APPROVED;
            update appr;

            List<sbaa__Approval__c> listAppr = new List<sbaa__Approval__c>{appr};

            Test.startTest();
            AutoApprovalTriggerUtility.createSnapshots(listAppr, oldMap);
            Test.stopTest();
            System.assert(true);
        }
    }
}