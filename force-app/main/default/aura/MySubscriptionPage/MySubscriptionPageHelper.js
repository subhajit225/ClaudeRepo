({
    subRecords : function(component, event, helper ) {
        var custNo = component.get("v.custNo");
        var action = component.get("c.getSubscribedList");   
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {       
                var custs = [];
                var conts = response.getReturnValue();
                component.set("v.catMAp",conts);
                component.set("v.dataCategList",Object.keys(conts));
                /*for ( var value in conts ) {
                    custs.push({value:conts[value], key:value});
                }
                component.set("v.dataCategList", custs[1].value);*/
            } 
        });           
        $A.enqueueAction(action); 
    }
})