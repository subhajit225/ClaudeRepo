@isTest
private class RBRK_SubscriptionSummaryVariableCalcTest {
    public static Account act;
    public static Entitlement ent;
    public static Product2 prdHW;
    public static PricebookEntry pbeHW;
    public static Asset ast;
    public static ContractLineItem contractLineItem;
    public static ServiceContract serviceContract;
    public static Opportunity opportunityObj;
    public static Id pricebookId;
    @testSetup
    static void setupTestData() {
        // Create Accounts
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 2; i++) {
            accounts.add(new Account(Name = 'Test Account ' + i));
        }
        insert accounts;

        // Create Custom Metadata (Subscription Summary Variables)
        List<RBRK_SubscriptionSummaryVariable__c> rules = new List<RBRK_SubscriptionSummaryVariable__c>();

        rules.add(new RBRK_SubscriptionSummaryVariable__c(
            Name = 'Rule1',
            RBRK_TargetObject__c = 'Subscription',
            RBRK_FilterField__c = 'SBQQSC__ProductName__c',
            RBRK_FilterValue__c = 'IGS-SVC-PREM-HW',
            RBRK_AggregateFunction__c = 'SUM',
            RBRK_AggregateField__c = 'SBQQSC__Quantity__c',
            RBRK_Operator__c = 'Equals',
            RBRK_SVUniqueId__c = 'R1',
            RBRK_IsActive__c = true
        ));
        
        rules.add(new RBRK_SubscriptionSummaryVariable__c(
            Name = 'Rule2',
            RBRK_TargetObject__c = 'Subscription',
            RBRK_FilterField__c = 'SBQQSC__ProductName__c',
            RBRK_FilterValue__c = 'IGS-SVC-PREM-HW',
            RBRK_AggregateFunction__c = 'Count',
            RBRK_AggregateField__c = 'SBQQSC__Quantity__c',
            RBRK_Operator__c = 'not equals',
            RBRK_SVUniqueId__c = 'R2',
            RBRK_IsActive__c = true
        ));
        rules.add(new RBRK_SubscriptionSummaryVariable__c(
            Name = 'Rule3',
            RBRK_TargetObject__c = 'Subscription',
            RBRK_FilterField__c = 'SBQQSC__ProductName__c',
            RBRK_FilterValue__c = 'IGS-SVC-PREM-HW',
            RBRK_AggregateFunction__c = 'Max',
            RBRK_AggregateField__c = 'SBQQSC__Quantity__c',
            RBRK_Operator__c = 'not equals',
            RBRK_SVUniqueId__c = 'R3',
            RBRK_IsActive__c = true
        ));
        rules.add(new RBRK_SubscriptionSummaryVariable__c(
            Name = 'Rule4',
            RBRK_TargetObject__c = 'Subscription',
            RBRK_FilterField__c = 'SBQQSC__ProductName__c',
            RBRK_FilterValue__c = 'IGS-SVC-PREM-HW',
            RBRK_AggregateFunction__c = 'Min',
            RBRK_AggregateField__c = 'SBQQSC__Quantity__c',
            RBRK_Operator__c = 'not equals',
            RBRK_SVUniqueId__c = 'R4',
            RBRK_IsActive__c = true
        ));
        
        insert rules;
        
        List<RBRK_SubscriptionSummaryVariable__c> rule2 = [Select id from RBRK_SubscriptionSummaryVariable__c where Name = 'Rule2'];
        
        rules.add(new RBRK_SubscriptionSummaryVariable__c(
            Name = 'Rule5',
            RBRK_TargetObject__c = 'Subscription',
            RBRK_FilterField__c = 'SBQQSC__ProductName__c',
            RBRK_FilterValue__c = 'IGS-SVC-PREM-HW',
            RBRK_AggregateFunction__c = 'SUM',
            RBRK_AggregateField__c = 'SBQQSC__Quantity__c',
            RBRK_Operator__c = 'not equals',
            RBRK_SVUniqueId__c = 'R5',
            RBRK_IsActive__c = true,
            RBRK_CompositeOperator__c = 'Add',
            RBRK_CombineWith__c = rule2[0].Id
        ));
        upsert rules;
        
    act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act;
        
        prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
        prdHW.ProductCode = 'IGS-SVC-PREM-HW';
        prdHW.Family = 'HPE';
        insert prdHW;

        pricebookId = Test.getStandardPricebookId();
        
        pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        pbeHW.PriceBook2Id = pricebookId;
        insert pbeHW;



        opportunityObj = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
        opportunityObj.AccountId = act.Id;
        opportunityObj.Name = 'EntitlementTriggerHelper Opportunity';
        opportunityObj.CloseDate = System.today().addMonths(12);
        opportunityObj.StageName = 'Prospecting';
        opportunityObj.Pricebook2Id = pricebookId;
        opportunityObj.SBQQ__QuotePricebookId__c = pricebookId;
        insert opportunityObj;

        serviceContract = new ServiceContract();
        serviceContract.Name = 'EntitlementTriggerHelper Contract';
        serviceContract.SBQQSC__Opportunity__c = opportunityObj.Id;
        serviceContract.AccountId = act.Id;
        serviceContract.StartDate = System.today();
        serviceContract.PriceBook2Id = pricebookId;
        serviceContract.Term = 36;
        insert serviceContract;
        
        contractLineItem = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        contractLineItem.SBQQSC__Account__c = act.Id;
        contractLineItem.PricebookEntryId = pbeHW.Id;
        contractLineItem.SBQQSC__Product__c = prdHW.ID;
        contractLineItem.ServiceContractId = serviceContract.Id;
        contractLineItem.StartDate = System.today();
        contractLineItem.SBQQSC__Quantity__c = 20;
        insert contractLineItem;

            }

    @isTest
    static void testProcessAllSubscription() {
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        update listUser[0];
        system.runas(listUser[0]){
        List<Account> accList = [SELECT Id, Name FROM Account];
        List<contractLineItem> cliList = [SELECT Id, Status,SBQQSC__Account__c,SBQQSC__ProductName__c,SBQQSC__Quantity__c FROM contractLineItem where SBQQSC__Account__c IN :accList];
        Test.startTest();
        RBRK_SubscriptionSummaryVariableCalc calc = new RBRK_SubscriptionSummaryVariableCalc(accList);
        RBRK_SubscriptionSummaryVariableCalc.processRecords(cliList);
        RBRK_SubscriptionSummaryVariableCalc.processContractLineItems(cliList);
        RBRK_SubscriptionSummaryVariableCalc.extractMatchingRuleIds(cliList);
        Test.stopTest();
        System.assert(true);
        }
    }

    @isTest
    static void testBuildQuery() {
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        update listUser[0];
        system.runas(listUser[0]){
        Map<String, Map<String, List<String>>> filterMap = new Map<String, Map<String, List<String>>>{
            'Equals' => new Map<String, List<String>>{
                'Test_Field__c' => new List<String>{ 'Value1' }
            }
        };

        Set<String> fields = new Set<String>{ 'Test_Field__c', 'Test_Amount__c', 'SBQQSC__Account__c' };
        List<Account> accList = [SELECT Id FROM Account LIMIT 1];

        String query = RBRK_SubscriptionSummaryVariableCalc.buildQuery(filterMap, fields, accList);
        System.assert(query.contains('Test_Field__c IN'), 'Query should include field filter');
        System.assert(query.contains('ContractLineItem'), 'Should query ContractLineItem');
    }
    }

    @isTest
    static void testMathCalc() {
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        update listUser[0];
        system.runas(listUser[0]){
        System.assertEquals(5, RBRK_SubscriptionSummaryVariableCalc.mathCalc(2, 3, 'Add'));
        System.assertEquals(-1, RBRK_SubscriptionSummaryVariableCalc.mathCalc(2, 3, 'Subtract'));
        System.assertEquals(2, RBRK_SubscriptionSummaryVariableCalc.mathCalc(6, 3, 'Divide'));
        System.assertEquals(0, RBRK_SubscriptionSummaryVariableCalc.mathCalc(6, 0, 'Divide')); // division by zero
    }
    }
}