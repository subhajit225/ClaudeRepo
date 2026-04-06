({
    autoSave : function(component, event, helper) {
        helper.callApexMethod(component,helper);
    },
    callApexMethod : function (component,helper){    
        console.log('callApexMethod');
        var action = component.get("c.autoSaveNote");  
        action.setParams({
            'parentId': component.get('v.recordId'),
            'oldNextSteps' : component.get('v.oldNextSteps'),
            'note':component.get('v.nextSteps')
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var retVal = response.getReturnValue() ;
                component.set("v.oldNextSteps",retVal);
                if($A.util.isEmpty(component.get('v.nextSteps'))){
                   component.set("v.nextSteps",retVal);
                }
            }
        });
        $A.enqueueAction(action); 
    }                       
})