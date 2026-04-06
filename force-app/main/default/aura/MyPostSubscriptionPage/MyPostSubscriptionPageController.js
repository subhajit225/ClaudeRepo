({
    doInit : function(component, event, helper) {
        
        helper.customerSusbscriptionRecords(component, event, helper);
        
        /* CS21-1172*/
        var action = component.get("c.getUserSubsriptionType");
        
        action.setCallback(this, function(response) {
            //store state of response
            var state = response.getState();
            if (state === "SUCCESS") {
                if(response.getReturnValue() != null && response.getReturnValue() != undefined && response.getReturnValue() != ''){
                    component.set("v.value", response.getReturnValue());
                }
                else{
                    component.set("v.value", "false");
                }
                
            }
        });
        $A.enqueueAction(action);

    },
    handleUnsubscribeAll: function(component, event, helper) {
        window.alert("This may take a while.  Please refresh the page to confirm Unsubscribe All has completed successfully.");
        var action = component.get("c.unsubscribeAll");
        action.setCallback(this, function(response) {
            if (response.getState() == 'SUCCESS') {
                location.reload();
            }
        });
        $A.enqueueAction(action);
    },
    //CS21-1172
    radioHandler: function(component,event,helper){
        component.set("v.isChanged", true);
    },
    
    yesButton: function(component, event, helper){
        var action = component.get("c.saveRadioSubscription");
        action.setParams({
            "subscriptionAlert": component.get("v.value")
        });
        $A.enqueueAction(action);
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : 'Success',
            message: 'Your email frequency has been updated!',
            duration:' 4000',
            key: 'info_alt',
            type: 'success',
            mode: 'pester'
        });
        toastEvent.fire();
        component.set("v.isChanged", false);
    },
    closeButton: function(component, event, helper){
        var action = component.get("c.getUserSubsriptionType");
        action.setCallback(this, function(response) {
            //store state of response
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.value", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
        component.set("v.isChanged", false);
    }
})