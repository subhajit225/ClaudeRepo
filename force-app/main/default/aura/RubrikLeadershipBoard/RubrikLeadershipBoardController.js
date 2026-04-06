({
    doInit : function(component, event, helper) {
        var action = component.get("c.getLeaders");
        action.setStorable();
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                let leaderDetails = response.getReturnValue();
                component.set('v.leaders', leaderDetails);
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
    },
    navigateToUserProfile : function(component, event, helper) {
        let userId = event.currentTarget.dataset.id;
        let pageURL = $A.get("$Label.c.ForumGamificationProfilePage");
        
        $A.get("e.force:navigateToURL").setParams({ 
            "url": "/"+pageURL+"?recordId=" + userId
        }).fire();
    }
})