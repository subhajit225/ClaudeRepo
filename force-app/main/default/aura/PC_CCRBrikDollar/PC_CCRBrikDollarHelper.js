({
	
    fetchCcrAmount:function(component, event, helper) {
         
        var action = component.get("c.claimDetails"); 
           action.setCallback(this, function(response) { 
            response.getState(response.getState());
               //alert(response.getState());
            if(response.getState() === "SUCCESS") {
                //alert(response.getReturnValue());
             component.set("v.ccrAmount",response.getReturnValue());
          }
        });
        $A.enqueueAction(action); 
        
    }, 
    gotoURL : function (component, event, url) {        
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url":url,
            "redirect": false
        });
        urlEvent.fire();
    }
})