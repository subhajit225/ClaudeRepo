trigger ProductFeatureTrigger on Product_Feature__c (before insert) {
	TriggerManager.invokeHandler(new ProductFeatureTriggerHandler());
}