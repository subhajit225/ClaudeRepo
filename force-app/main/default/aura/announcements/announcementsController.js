({ 
    doInit: function(cmp){
        var action = cmp.get("c.getPortalNews");
        action.setParams({'recordId':'','Name':cmp.get("v.type")});
        action.setCallback(this, function(response){
            var state = response.getState();
            var result = response.getReturnValue();
            
            cmp.set("v.newsList", result);
        });
        $A.enqueueAction(action);
    }
})