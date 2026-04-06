({
	doInit : function(component, event, helper) {
		var action = component.get("c.getProfileName");
        action.setParams({
        });
        action.setCallback(this, function(response){
            if (response.getState() === "ERROR") {
                component.set("v.showSpinner", false);
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && ( errors[0].message || errors[0].pageErrors)) {
                    	helper.showToast(component, event, helper, errors[0].message + errors[0].pageErrors , 'error');
                    }
                    return;
                }
            }
            var profileName = response.getReturnValue();
            if(profileName == "Rubrik Field Sales User" )
                component.set("v.selectedTab", 'two');
            else
                component.set("v.selectedTab", 'one');
            
            
        });
        $A.enqueueAction(action);
	},
	
})