({
	onLoad : function(component, event, helper) {
        component.set('v.showPOCReturnForm', true); 
	},
    goBack: function(component, event, helper) {
        var recordId = event.getParam('targetRecordId');
        console.log('new Target record', recordId);
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": recordId,
            "slideDevName": "detail"
        });
        navEvt.fire();
    }
})