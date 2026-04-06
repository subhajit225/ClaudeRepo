({
	save : function(component, event,helper) {
        helper.showSpinner(component, event,helper);
		var action = component.get("c.save");
        action.setCallback(this, function(response) {
            console.log(response.getReturnValue());
            helper.hideSpinner(component, event,helper);
            if(response.getState() === "SUCCESS") { 
                component.set("v.partnerType","");
                var resultsToast = $A.get("e.force:showToast");
                    resultsToast.setParams({
                        "title": "Signed",
                        "message": "Contract has been successfully Signed",
                        "type" : "success"
                    });
                    resultsToast.fire();
            }else if (response.getState() === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
                var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "title": "Error",
                    "message": "Error occurred while Signing Contract",
                    "type" : "error"
                });
                resultsToast.fire();
            }
            
        });
        $A.enqueueAction(action);
	},
    showSpinner: function (component, event, helper) {
        var spinner = component.find("mySpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },
    
    hideSpinner: function (component, event, helper) {
        var spinner = component.find("mySpinner");
        $A.util.addClass(spinner, "slds-hide");
    },
})