({
    customerSusbscriptionRecords : function(component, event, helper) {
        var action = component.get("c.getPostSubscriptionInfo");   
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {       
                var custs = [];
                var conts = response.getReturnValue();
                console.log('sssssssssss'+ JSON.stringify(conts));
                component.set("v.catMAp",conts);
                component.set("v.dataCategList",Object.keys(conts));
            } 
        });           
        $A.enqueueAction(action); 
		
            
        
    }
})