({
    doInit : function(component, event, helper) {
        var action = component.get("c.getRelatedAttachment");
        action.setParams({
            recordId:component.get("v.recordId")
        });
        action.setCallback(component, function(response) {
            component.set("v.AttachedContentDocuments",response.getReturnValue());
        });
        $A.enqueueAction(action);
    },
	addFeedback : function(component, event, helper) {
		var title = component.get("v.title");
        var body = component.get("v.body");
        
        var formats = {
            font: 'Gotham-light',
            size: '14px'
        };
        var editor = component.find("editor");
        editor.setFormat(formats);
        if(body != null && body.length > 4000){
            component.set("v.maxLength",true);
            return;
        }
        if(title == null || (body == null || body == '')){
            component.set("v.isRequired",true);
        }else{
            component.set("v.isRequired",false);
            component.set("v.maxLength",false);
            var action = component.get("c.saveFeedback");
            action.setParams({
                'kbId' : component.get("v.recordId"),
                'title' : title,
                'body' :body
            });
            action.setCallback(this,function(response){
                console.log(response.getState());
                var state = response.getState();
                if (state === "SUCCESS") {
                    component.set("v.title",'');
                    component.set("v.body",'');
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "message": "Thanks for taking the time to submit your feedback. We'll use your feedback to improve our knowledge content."
                    });
                    toastEvent.fire();
                }
            });
           $A.enqueueAction(action);

        }
	},
    openFiles : function (component, event, helper) {
        // console.log(event.target.id);
        $A.get('e.lightning:openFiles').fire({
            recordIds: [event.target.id]
        });
    }
})