({
    doInit : function(component, event, helper) {
        var action = component.get("c.getContributorDetails");
        let currentQuestionId = component.get("v.questionId");
        
        action.setParams({ questionId : currentQuestionId});
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                let contributorDetails = response.getReturnValue();
                component.set('v.contributorDetails', contributorDetails);
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