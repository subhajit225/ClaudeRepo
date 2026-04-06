({
    doInit : function(component, event, helper) {
        
        var action = component.get('c.assignToMe');    
        action.setParams({
            'recordId':component.get('v.recordId')
        });
        action.setCallback(this,function(response){
            var state = response.getState();
            var result = response.getReturnValue();
            console.log(result);
            if (state === "SUCCESS") {
                $A.get('e.force:refreshView').fire();
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
            }
        });
        $A.enqueueAction(action);
    },
})