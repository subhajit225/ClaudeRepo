({
    //fetch 10 timecard baseed on farthest end end. 
    fetchTimeCard : function(component, event, helper) {
        
        var action = component.get('c.GetTimeCard');
        component.set("v.Spinner", true); 
        action.setCallback(this,function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var responseValue = response.getReturnValue();
                component.set("v.TimecardList",responseValue);
            }
            component.set("v.Spinner", false); 
        });
        $A.enqueueAction(action);
    },
    
    fetchTimeCardWrp : function(component, event, helper) {
      
        var action = component.get('c.GetTimeCards');
        component.set("v.Spinner", true); 
        action.setCallback(this,function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var responseValue = response.getReturnValue();
                component.set("v.TimecardList",responseValue);
            }
            component.set("v.Spinner", false); 
        });
        $A.enqueueAction(action);
    }
    
})