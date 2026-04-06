({
	gotoURL : function(component, event, url) {
        var urlEvent = $A.get("e.force:navigateToURL");
        
       urlEvent.setParams({
            "url":url+'?incentiveId='+component.get("v.recordId"),
            "redirect": false
        });
        urlEvent.fire();
    },
    handlePreview:function(component, event, helper) {
        var actionImage = component.get("c.getdocs");
        actionImage.setParams({
            incentiveId:component.get("v.recordId")
        });
        actionImage.setCallback(this, function(rep){
            var attachment = rep.getReturnValue();
            component.set("v.docObj", rep.getReturnValue());
            component.set("v.NoAttachment",true);
        });
        $A.enqueueAction(actionImage);
        
    }
		
	
})