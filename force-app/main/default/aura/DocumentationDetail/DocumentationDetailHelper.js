({
	 showdocument : function(component, releaseId) {
       console.log('............?');
        var action = component.get("c.getReleaseVDocs");
        action.setParams({
            "releaseId":releaseId,
            "IsPolaris":true 
        });
        
        action.setCallback(this, function(response){
            if(response.getState()==="SUCCESS" && component.isValid()){
                var result = response.getReturnValue();
                console.log(' AttachmentDocslist Result=>',result);
               component.set("v.AttachmentDocslist",result.relDocList);
            }
        });
        $A.enqueueAction(action);
    }
})