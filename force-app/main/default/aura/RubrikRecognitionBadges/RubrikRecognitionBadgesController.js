({
    doInit : function(component, event, helper) {
        var action = component.get("c.getRecognitionBadges");
        let currentUserId = component.get("v.userId")
        
        action.setParams({userId : currentUserId});
        action.setStorable();

        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                let badges = response.getReturnValue();
                component.set('v.badges', badges);
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