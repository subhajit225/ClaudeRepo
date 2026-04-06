({
	navigateToLatest : function(component, event, helper) {
        console.log('init');
        var action = component.get("c.knowledgeId");
        action.setParams({
            'kbId' : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                if(response.getReturnValue() != component.get("v.recordId")){
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": response.getReturnValue(),
                        "slideDevName": "detail"
                    });
                    navEvt.fire();
                }
            }
        });
        $A.enqueueAction(action);
	}
})