({
	showToast : function(component, event, helper, message, type) {
        var toastEvent = $A.get("e.force:showToast");
        if(!toastEvent){
            component.set('v.errorType',type);
            component.set('v.errorMessage',message);
            window.setTimeout(
            $A.getCallback(function() {
                component.set('v.errorType','');
                component.set('v.errorMessage','');
            }), 6000
        );
            
            return;
        }
        toastEvent.setParams({
            "message": message,
            "type": type
        });
        toastEvent.fire();
    },
})