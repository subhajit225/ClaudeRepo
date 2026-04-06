({
	myAction : function(component, event, helper) {
        helper.getEntitlementDetails(component);
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
	}
})