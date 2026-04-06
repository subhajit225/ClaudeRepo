({
	doinit : function(component, event, helper) {
        var contentId=component.get("v.id");
        var action = component.get("c.PreviewContentDetails"); 
        action.setParams({
            ContentIds:contentId,
        });
        action.setCallback(this, function(response) { 
          if(response.getState() === "SUCCESS") {
                //alert('value---->'+response.getReturnValue());
             component.set("v.ContentdocIds",response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
		
	}
})