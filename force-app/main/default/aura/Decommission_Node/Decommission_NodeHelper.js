({
	getEntitlementDetails : function(component, event, helper) {
		var action = component.get("c.clearUsagecounter");
        var entUsageId = component.get("v.recordId");
        action.setParams({'entitlementusageId':entUsageId});
        $A.enqueueAction(action);
	}
})