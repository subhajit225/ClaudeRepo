({
	handlesaveOpp : function(component, event, helper) {
		var action = component.get("c.saveRecord");
        action.setParams({ rec : component.get("v.sObjectInfo") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS" && !$A.util.isEmpty(response.getReturnValue())) {
                var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Cannot update the record",
                                "duration": 20000,
                                "type": "error",
                        "message": response.getReturnValue()
                    });
                    toastEvent.fire();
                 helper.closeQuickAction(component, event);    
            }else if (state === "SUCCESS" && $A.util.isEmpty(response.getReturnValue())){
                helper.gotoRecord(component,component.get("v.recordId"));
            }
            helper.closeQuickAction(component, event, helper);    
        });
        // Send action off to be executed
        $A.enqueueAction(action);
	},
    
    closeQuickAction : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
})