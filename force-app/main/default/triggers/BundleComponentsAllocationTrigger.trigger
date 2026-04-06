trigger BundleComponentsAllocationTrigger on Bundle_Components_Allocation__c (before insert) {
	TriggerManager.invokeHandler(new BundleComponentsAllocationTriggerHandler());
}