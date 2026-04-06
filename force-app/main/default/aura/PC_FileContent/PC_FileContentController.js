({	
     doInit : function(component, event, helper) {
        var action = component.get("c.fetchAttachedContentDocDetails"); 
        action.setCallback(this, function(response) { 
            if(response.getState() === "SUCCESS") {
                component.set("v.ContentDocIds",response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    }
})