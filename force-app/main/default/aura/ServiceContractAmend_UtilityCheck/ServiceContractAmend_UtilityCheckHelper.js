({
	checkOrderType: function(component) {
        var action = component.get("c.checkOrderTypeMethod");
        action.setParams({
            recordId: component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('====ReturnValue()======', response.getReturnValue());
            if (state === "SUCCESS") {
                if (response.getReturnValue()) {
                    var urlEvent = $A.get("e.force:navigateToURL");
                    var urlToRedirect = '/apex/SBQQSC__AmendServiceContract?scontrolCaching=1&id=' + component.get('v.recordId');
                    urlEvent.setParams({ "url": urlToRedirect });
                    urlEvent.fire();
                } else {
                    alert("Utility Amendment Quote must be created from Opportunity using 'Amend Contract’ button.");
                }
            } else {
                console.error("Error in response: ", response.getError());
            }
        });
        $A.enqueueAction(action);
    }
})