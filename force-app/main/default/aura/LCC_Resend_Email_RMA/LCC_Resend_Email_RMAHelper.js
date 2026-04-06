({
	handlesaveRMA : function(component, event, helper) {
		component.set("v.sObjectInfo.Resend_Flash_Email__c ",true);
        helper.serversidesave(component, event, helper,component.get("v.sObjectInfo"));
	},
   
    serversidesave : function(component, event, helper, sobjectrec){
        var action = component.get("c.saveRecord");
        action.setParams({ rec : sobjectrec });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "ERROR") {
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
              helper.gotoRec(component,component.get("v.sObjectInfo.Id"));
            }
             
        });
        // Send action off to be executed
        $A.enqueueAction(action);
    },
    gotoRec : function(component, recId){
        var urlEvent = $A.get("e.force:navigateToSObject");
        urlEvent.setParams({"recordId": recId,"slideDevName": "detail"});        
        urlEvent.fire();
    }
})