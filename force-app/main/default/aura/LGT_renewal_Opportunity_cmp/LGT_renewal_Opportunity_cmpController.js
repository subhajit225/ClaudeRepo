({
    doinit : function(component, event, helper) {
        if(component.get("v.CaseRecord").Opportunity_lookup__c != null){
            component.set("v.oppRecordId",component.get("v.CaseRecord").Opportunity_lookup__c);
            component.set("v.enableForm",true);

          
        }else{
            alert("There is no Opportunity linked to case.");
            var dismissActionPanel = $A.get("e.force:closeQuickAction");
            component.set("v.disableCSS",true);
            component.set("v.enableForm",false);
            dismissActionPanel.fire();
        }
    },
    handleError: function(component, event, helper) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            mode: 'dismissible',
            title: 'Error!',
            type: 'error',
            duration: 9000,
            message: event.getParam("detail")
        });
        toastEvent.fire();
    },

    handleSuccess : function(component, event, helper) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            mode: 'dismissible',
            title: 'Success!',
            type: 'success',
            duration: 3000,
            message: 'The record has been saved.'
        });
        toastEvent.fire();
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        component.set("v.disableCSS",true);
        component.set("v.enableForm",false);
        dismissActionPanel.fire();
    }
    
    
})