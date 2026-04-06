trigger ProductRuleTrigger on SBQQ__ProductRule__c (after insert, after update) {
 TriggerManager.invokeHandler(new ProductRuleJsonGenerator());
}