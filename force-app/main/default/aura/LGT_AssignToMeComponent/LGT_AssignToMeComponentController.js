({
	doInit: function(component, event, helper) {
        var caseList = component.get("v.caseList");
        var action = component.get("c.updateOwner");
        var baseUrl = helper.fetchBaseUrl(component , event);
        action.setParams({
            "caseIds" : caseList
        });
        action.setCallback(this, function(response) {
            var state = response.getState();  
            var vfOrigin = baseUrl;
            if(state === "SUCCESS"){
                let res = 'close';
                if(response.getReturnValue() != null){
                    res = response.getReturnValue();
                }
                window.history.back();
            }
            // Added by Vijay: 1326: handling VR rules on Owner change
            else if(state === "ERROR"){
                var errors = response.getError();
                if (errors
                    && errors[0] 
                    && errors[0].message) {
                        window.postMessage('dbErr: '+errors[0].message, vfOrigin); 
                }
            }
        });
        $A.enqueueAction(action);
    }
})