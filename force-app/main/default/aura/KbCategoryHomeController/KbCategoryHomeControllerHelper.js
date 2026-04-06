({
    getTiles : function(component, event, helper ) {
        console.log('enter--') ;
        var custNo = component.get("v.custNo");
        var action = component.get("c.getAllCategoryGroups");   
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {       
                var custs = [];
                var conts = response.getReturnValue();
                for ( var key in conts ) {
                    custs.push({value:conts[key], key:key});
                }
                component.set("v.dataCategList", custs);
                var action1 = component.get("c.getSubscription");   
                action1.setCallback(this, function(resp) {
                    var state1 = resp.getState();
                    console.log('sub===',state1);
                    if (state1 === "SUCCESS") {                
                        console.log('sub====',resp.getReturnValue());
                        component.set("v.subscribedInfoList",resp.getReturnValue());
                    } 
                });           
                $A.enqueueAction(action1); 
                
            } 
        });           
        $A.enqueueAction(action); 
    }
})