({
	doInIt : function(component, event, helper) {
		 var saveAction = component.get("c.getStatus");
        console.log('getStatus');
        saveAction.setParams({
            mdfId: component.get("v.recordId")  
             
        });
        saveAction.setCallback(this, function(response) {
            var state = response.getState();
           
            if(state === "SUCCESS") {
                if(response.getReturnValue() == false || response.getReturnValue() === 'false'){
                    var resultsToast = $A.get("e.force:showToast");
                    resultsToast.setParams({
                        "title": "Error",
                        "message": "Cannot submit a claim for a completed MDF request",
                        "type" : "error"
                    });
                    resultsToast.fire();
                   
                }else{
                    helper.navigateToURL(component, event, "/fundclaimnew?recordId="+component.get("v.recordId")); 
                }
            }
            else if (state === "ERROR") {
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
        
        $A.enqueueAction(saveAction);
	}
})