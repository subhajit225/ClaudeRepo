({
	doInit : function(component, event, helper) {
        var action = component.get("c.getUserInfluenceSummary");
        let currentUserId = component.get("v.userId")
        
        action.setParams({ userId : currentUserId});
		action.setStorable();
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                let influenceDetails = response.getReturnValue(); 
                component.set('v.influenceDetails', influenceDetails);
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });

        // $A.enqueueAction adds the server-side action to the queue.
        $A.enqueueAction(action);
	}
})