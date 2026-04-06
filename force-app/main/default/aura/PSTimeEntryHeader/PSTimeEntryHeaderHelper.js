({
	 helperMethod : function(component, event, helper) {
        var action = component.get("c.getUserName");
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set("v.currentUserName", result);
            }
        });
        $A.enqueueAction(action);   
    },
})