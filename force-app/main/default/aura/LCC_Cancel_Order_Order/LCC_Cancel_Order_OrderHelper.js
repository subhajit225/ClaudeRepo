({
	handlesaveOrder : function(component, event, helper) {
		var action = component.get("c.saveRecord");
        action.setParams({ rec : component.get("v.sObjectInfo") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "ERROR" ) {
                var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Cannot update the record",
                                "duration": 10000,
                                "type": "error",
                        "message": response.getReturnValue()
                    });
                    toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire();  
            }else if (state === "SUCCESS"){
                var str = response.getReturnValue();
                if(str.includes('Exception occurred')){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Cannot update the record",
                                "duration": 10000,
                                "type": "error",
                        "message": response.getReturnValue()
                    });
                    toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire();  
                }else{
                	helper.gotoRecord(component,component.get("v.recordId"));
                }
            }
            $A.get("e.force:closeQuickAction").fire();
        });
        // Send action off to be executed
        $A.enqueueAction(action);
	},
    gotoRecord : function (component, recId) {
        var urlEvent = $A.get("e.force:navigateToSObject");
        urlEvent.setParams({"recordId": recId,"slideDevName": "detail"});        
        urlEvent.fire();
    },
})