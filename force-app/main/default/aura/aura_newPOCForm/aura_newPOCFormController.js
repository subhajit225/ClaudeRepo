({
	onLoad : function(component, event, helper) {
        if( component.get('v.showPOCForm') === false ) {
            helper.getOpportunityValidation(component, event, helper).then( 
                $A.getCallback(function() {
                    $A.get("e.force:closeQuickAction").fire();
                    var evt = $A.get("e.force:navigateToComponent");
                    evt.setParams({
                        "componentDef": "c:aura_newPOCForm",
                        componentAttributes: {
                            recordId : component.get("v.recordId"),
                            showPOCForm: true
                        }
                    });
                    evt.fire();
                }), $A.getCallback(function(error) {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type": "Error",
                        "message": error
                    });
                    toastEvent.fire();
                    //$A.get("e.force:closeQuickAction").fire();
                    //$A.get('e.force:refreshView').fire();
                })
            );
            $A.get("e.force:closeQuickAction").fire();
        } else {
            component.set('v.showPOCForm', true); 
           // component.set('v.showPOCForm', true); 
        }

        //helper.getURL();
	},
    goBack: function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.closeTab({tabId: focusedTabId});
        })
        .catch(function(error) {
            console.log('error');
        })
        .finally(() => {
            var recordId = event.getParam('targetRecordId');
            console.log('new Target record', recordId);
            var navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
                "recordId": recordId,
                "slideDevName": "detail"
            });
            navEvt.fire();
        })
    }
})