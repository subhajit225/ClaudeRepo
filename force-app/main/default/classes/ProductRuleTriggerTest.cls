@IsTest
private class ProductRuleTriggerTest {

    private static SBQQ__ProductRule__c buildRule(Boolean generate, String name, String type) {
        SBQQ__ProductRule__c rule = new SBQQ__ProductRule__c(
            Name = name,
            SBQQ__EvaluationEvent__c = 'Load',         
            SBQQ__ConditionsMet__c = 'Any',        
            SBQQ__Type__c = type,              
            SBQQ__Scope__c = 'Product',                
            RBRK_GenerateJSON__c = generate,
            SBQQ__ErrorMessage__c = 'Test Message',
            SBQQ__AdvancedCondition__c = '',
            ExceptionForBypass__c = ''
        );
        return rule;
    }

    @IsTest
    static void testFullFlow() {
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        update listUser[0];

        system.runAs(listUser[0]){

            RBRKRuleCondition__c existingRuleCondition = new RBRKRuleCondition__c(
                RBRKRuleName__c = 'Existing Rule',
                Name = 'Existing Rule',
                RuleJSON__c = '{}',
                RuleSVJSON__c = '{}'
            );
            insert existingRuleCondition;

            SBQQ__ProductRule__c ruleVar = buildRule(false, 'Automation Test Rule Variable', 'Validation');
            insert ruleVar;
            SBQQ__ProductRule__c ruleVar2 = buildRule(false, 'Existing Rule', 'Validation');
            insert ruleVar2;

            SBQQ__SummaryVariable__c sv = new SBQQ__SummaryVariable__c(
                Name = 'SV_Test',
                SBQQ__AggregateField__c = 'SBQQ__NetPrice__c',
                SBQQ__AggregateFunction__c = 'SUM',
                SBQQ__Scope__c = 'Quote',
                SBQQ__TargetObject__c = 'SBQQ__QuoteLine__c'
            );
            insert sv;

            SBQQ__ErrorCondition__c ecVar = new SBQQ__ErrorCondition__c(
                SBQQ__Rule__c = ruleVar.Id,
                SBQQ__Index__c = 1,
                SBQQ__TestedObject__c = 'SBQQ__QuoteLine__c',
                SBQQ__FilterType__c = 'Variable',
                SBQQ__Operator__c = '=',
                SBQQ__TestedVariable__c = sv.Id,
                SBQQ__FilterVariable__c = sv.Id
            );
            insert ecVar;

            SBQQ__ErrorCondition__c ecField = new SBQQ__ErrorCondition__c(
                SBQQ__Rule__c = ruleVar.Id,
                SBQQ__Index__c = 2,
                SBQQ__TestedObject__c = 'SBQQ__QuoteLine__c',
                SBQQ__FilterType__c = 'Value',
                SBQQ__Operator__c = '=',
                SBQQ__TestedField__c = 'SBQQ__NetPrice__c',
				SBQQ__FilterValue__c = '10'
            );
            insert ecField;

            Test.startTest();
            
            ruleVar.RBRK_GenerateJSON__c = true;
            update ruleVar;

            Test.stopTest();

            List<RBRKRuleCondition__c> jsonResult = [
                SELECT Id, RuleJSON__c, RuleSVJSON__c, RBRKRuleName__c
                FROM RBRKRuleCondition__c
                WHERE RBRKRuleName__c IN ('Automation Test Rule Variable','Existing Rule')
            ];

            System.assertEquals(2, jsonResult.size(), 'All two RBRKRuleCondition__c records must exist');

        }
    }
}