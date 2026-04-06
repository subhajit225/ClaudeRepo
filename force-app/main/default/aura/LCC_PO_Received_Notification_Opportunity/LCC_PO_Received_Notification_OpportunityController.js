({
    execute : function(component, event, helper) {
        if(component.get("v.Profile.Name") == 'Sales Operations' || component.get("v.Profile.Name") == 'Order Manager' || component.get("v.Profile.Name") == 'System Administrator'){ 
        helper.loadQuotes(component, event, helper);  
        }else
        {
            component.set("v.content","You are not allowed to send this notification");
        }
    },
    handleQuoteSelect : function(component, event, helper) {
        let quoteId = component.get("v.selectedQuoteId");
        helper.updatePrimary(component, quoteId);
    },
    
    handleCancel : function(component, event, helper) {
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    }
})