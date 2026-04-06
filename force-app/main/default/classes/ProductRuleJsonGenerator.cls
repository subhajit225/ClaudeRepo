/**
 * @description Handler class for SBQQ__ProductRule__c trigger events.
 *              Generates JSON for Product Rules when RBRK_GenerateJSON__c is true.
 * 
 * @author      
 * @date        
 * @maintainer  
 */
public class ProductRuleJsonGenerator extends TriggerManager.GenericTriggerHandler{

    /**
     * @description After Insert Trigger Handler.
     *              Processes rules where RBRK_GenerateJSON__c = true.
     * 
     * @param newRecordsMap Map<Id, SObject> — records inserted in the transaction.
     */
    public override void onAfterInsert(Map<ID, sObject> newRecordsMap) {
        Set<Id> rulesToProcess = new Set<Id>(); 
        for (SBQQ__ProductRule__c rule : (List<SBQQ__ProductRule__c>) newRecordsMap.values()) { 
            if (rule.RBRK_GenerateJSON__c == true) {
                rulesToProcess.add(rule.Id);
            }
        }
        ProductRuleJsonGenerator.processRules(rulesToProcess);
    }

    /**
     * @description After Update Trigger Handler.
     *              Processes rules where RBRK_GenerateJSON__c changed 
     *              from false → true.
     * 
     * @param oldRecordsMap Map<Id, SObject> — records before update.
     * @param newRecordsMap Map<Id, SObject> — records after update.
     */
    public override void onAfterUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap) { 
        Set<Id> rulesToProcess = new Set<Id>();         
        for (SBQQ__ProductRule__c rule : (List<SBQQ__ProductRule__c>) newRecordsMap.values()) { 
            SBQQ__ProductRule__c oldRule = (SBQQ__ProductRule__c) oldRecordsMap.get(rule.Id);

            if (rule.RBRK_GenerateJSON__c == true && oldRule.RBRK_GenerateJSON__c != true) { 
                rulesToProcess.add(rule.Id); 
            } 
        }

        ProductRuleJsonGenerator.processRules(rulesToProcess);
    }

    /**
     * @description Core processor that creates JSON for Product Rule and SV definitions.
     * 
     * @param ruleIds Set<Id> — IDs of SBQQ__ProductRule__c to generate JSON for.
     */
    public static void processRules(Set<Id> ruleIds) {
    List<SBQQ__ProductRule__c> rulesWithData = [
        SELECT Id, Name, SBQQ__Type__c, SBQQ__ConditionsMet__c, SBQQ__AdvancedCondition__c, ExceptionForBypass__c,
               (SELECT Id, SBQQ__Rule__r.Name, SBQQ__Index__c, SBQQ__TestedObject__c, SBQQ__TestedVariable__c, SBQQ__FilterType__c,
                       SBQQ__TestedField__c, SBQQ__Operator__c, SBQQ__FilterVariable__c, SBQQ__FilterValue__c
                FROM SBQQ__ErrorConditions__r)
        FROM SBQQ__ProductRule__c
        WHERE Id IN :ruleIds
    ];

    Map<String, list<String>> ruleVsSVsMap = new Map<String, list<String>>();
    Set<String> allSvIds = new Set<String>();
    Map<String, Map<String, Object>> ruleJsonMap = new Map<String, Map<String, Object>>();

    // Existing logic to build JSON for rules
    for (SBQQ__ProductRule__c rule : rulesWithData) {
        String ruleName = rule.Name;
        Map<String, Object> ruleMap = new Map<String, Object>();
        ruleMap.put('RBRKRuleName__c', ruleName);
        ruleMap.put('RBRKQuoteExceptions__c', rule.ExceptionForBypass__c);

        List<Map<String, Object>> condList = new List<Map<String, Object>>();
        if (rule.SBQQ__ErrorConditions__r != null) {
            for (SBQQ__ErrorCondition__c ec : rule.SBQQ__ErrorConditions__r) {
                if (ec.SBQQ__TestedVariable__c != null) {
                    if (!ruleVsSVsMap.containsKey(ruleName)) {
                        ruleVsSVsMap.put(ruleName, new List<String>());
                    }
                    ruleVsSVsMap.get(ruleName).add(ec.SBQQ__TestedVariable__c);
                }
                if (ec.SBQQ__FilterVariable__c != null) {
                    if (!ruleVsSVsMap.containsKey(ruleName)) {
                        ruleVsSVsMap.put(ruleName, new List<String>());
                    }
                    ruleVsSVsMap.get(ruleName).add(ec.SBQQ__FilterVariable__c);
                }

                Map<String, Object> condMap = new Map<String, Object>();
                condMap.put('RBRKIndex__c', ec.SBQQ__Index__c);
                condMap.put('RBRKTestedObject__c', ec.SBQQ__TestedObject__c);
                if (String.isNotBlank(ec.SBQQ__TestedField__c)) {
                    condMap.put('RBRKTestedField__c', ec.SBQQ__TestedField__c);
                    condMap.put('RBRKTestVariable__c', '');
                } else {
                    condMap.put('RBRKTestedField__c', '');
                    condMap.put('RBRKTestVariable__c', ec.SBQQ__TestedVariable__c);
                }
                if (ec.SBQQ__FilterType__c == 'Variable') {
                    condMap.put('VariableName__c', ec.SBQQ__FilterVariable__c);
                    condMap.put('RBRKFilterValue__c', '');
                } else {
                    condMap.put('VariableName__c', '');
                    condMap.put('RBRKFilterValue__c', ec.SBQQ__FilterValue__c);
                }
                condMap.put('RBRKFilterType__c', ec.SBQQ__FilterType__c);
                condMap.put('RBRKOperator__c', ec.SBQQ__Operator__c);
                condList.add(condMap);
            }
        }

        String finalLogic;
        if (rule.SBQQ__ConditionsMet__c == 'Custom' && String.isNotBlank(rule.SBQQ__AdvancedCondition__c)) {
            finalLogic = rule.SBQQ__AdvancedCondition__c;
        } else {
            List<String> logicIndexes = new List<String>();
            for (Integer i = 1; i <= condList.size(); i++) logicIndexes.add(String.valueOf(i));
            finalLogic = (rule.SBQQ__ConditionsMet__c == 'Any') ? String.join(logicIndexes, ' OR ') : String.join(logicIndexes, ' AND ');
        }

        ruleMap.put('RBRKLogic__c', finalLogic);
        ruleMap.put('Conditions', condList);
        ruleJsonMap.put(ruleName, ruleMap);
    }

    for (List<String> svList : ruleVsSVsMap.values()) allSvIds.addAll(svList);

    Map<Id, SBQQ__SummaryVariable__c> svLookupMap = new Map<Id, SBQQ__SummaryVariable__c>(
        [SELECT Id, Name, SBQQ__AggregateField__c, SBQQ__AggregateFunction__c, SBQQ__CombineWith__c, SBQQ__CompositeOperator__c,
                SBQQ__FilterField__c, SBQQ__FilterValue__c, SBQQ__Operator__c, SBQQ__Scope__c, SBQQ__TargetObject__c
         FROM SBQQ__SummaryVariable__c
         WHERE Id IN :allSvIds]
    );

    List<Map<String, Object>> svJsonList = new List<Map<String, Object>>();

    // Fetch existing RBRKRuleCondition__c by Rule Name
    Map<String, RBRKRuleCondition__c> existingRuleMap = new Map<String, RBRKRuleCondition__c>();
    for (RBRKRuleCondition__c existingRec : [
        SELECT Id, RBRKRuleName__c FROM RBRKRuleCondition__c WHERE RBRKRuleName__c IN :ruleJsonMap.keySet()
    ]) {
        existingRuleMap.put(existingRec.RBRKRuleName__c, existingRec);
    }

    List<RBRKRuleCondition__c> toUpsert = new List<RBRKRuleCondition__c>();

    for (String ruleName : ruleJsonMap.keySet()) {
        List<Id> svIdsForRule = ruleVsSVsMap.get(ruleName);
       if (svIdsForRule == null || svIdsForRule.isEmpty()) {
        return;
    }
        for (Id svId : svIdsForRule) {
            SBQQ__SummaryVariable__c sv = svLookupMap.get(svId);
            if (sv == null) continue;
            Map<String, Object> row = new Map<String, Object>();
            row.put('Name', sv.Name);
            row.put('RBRK_AggregateField__c', sv.SBQQ__AggregateField__c);
            row.put('RBRK_AggregateFunction__c', sv.SBQQ__AggregateFunction__c);
            row.put('RBRK_CombineWith__c', sv.SBQQ__CombineWith__c);
            row.put('RBRK_CompositeOperator__c', sv.SBQQ__CompositeOperator__c);
            row.put('RBRK_FilterField__c', sv.SBQQ__FilterField__c);
            row.put('RBRK_FilterValue__c', sv.SBQQ__FilterValue__c);
            row.put('RBRK_Operator__c', sv.SBQQ__Operator__c);
            row.put('RBRK_Scope__c', sv.SBQQ__Scope__c);
            row.put('RBRK_TargetObject__c', sv.SBQQ__TargetObject__c);
            row.put('RBRK_SVUniqueId__c', sv.Id);
            svJsonList.add(row);
        }

        String svJsonString = JSON.serialize(svJsonList);
        String conditionJson = JSON.serialize(ruleJsonMap.get(ruleName));

        RBRKRuleCondition__c rbrkRec;
        if (existingRuleMap.containsKey(ruleName)) {
            // Update existing
            rbrkRec = existingRuleMap.get(ruleName);
            rbrkRec.RuleJSON__c = conditionJson;
            rbrkRec.RuleSVJSON__c = svJsonString;
        } else {
            // Insert new
            rbrkRec = new RBRKRuleCondition__c(
                RBRKRuleName__c = ruleName,
                RuleJSON__c = conditionJson,
                RuleSVJSON__c = svJsonString,
                Name = ruleName
            );
        }
        toUpsert.add(rbrkRec);
    }

    // Upsert instead of insert
    upsert toUpsert Name;
}
}