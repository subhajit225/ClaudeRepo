({
         execute : function(component, event, helper) {
         component.set('v.oppLoaded', true);
         helper.doInit(component, event, helper);
	},
    quoteChange: function(component, event, helper) {
      
        if(event.getParam("oldValue") && event.getParam("oldValue").length< event.getParam("value").length)
            helper.helperMethod(component, event, helper);
        else if(event.getParam("oldValue") && event.getParam("oldValue").length == event.getParam("value").length)
            $A.get("e.force:closeQuickAction").fire();
          
    }, 
	accept : function(component, event, helper) {
		$A.get("e.force:closeQuickAction").fire();
	}
})