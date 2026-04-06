({
    Cancel: function(component, event, helper){
        var url_string = window.location.href;
        var url = new URL(url_string);
        var id = url.searchParams.get("id");
        if(id){
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
                "url": "/viewcase?id="+id
            });
            urlEvent.fire();
        }
        //component.set("v.showPopup",false);
    },
    addComment : function(component, event, helper) {
        var spinner = component.find("spinner");
        $A.util.removeClass(spinner,"slds-hide");
        var action = component.get("c.addMyComment");
        var commentbody = component.get("v.commentText");
        if(!component.get("v.commentText")){
            $A.util.addClass(spinner,"slds-hide");
            console.log( component.get("v.validatedB"));
            component.set("v.hasError",true);
        }else{
            action.setParams({
                parentId : component.get("v.caseId"),
                body : commentbody
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                $A.get("e.force:refreshView").fire();
                console.log('response.getState();'+state);
                if (state === "SUCCESS") {
                    var urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                        "url": "/viewcase?id="+component.get("v.caseId")
                    });
                    urlEvent.fire();
                    //component.set("v.showPopup",false);
                }
            });
            $A.enqueueAction(action);
        }
        
        
        
    },
    addReopen : function(component, event, helper) {
        var spinner = component.find("spinner");
        $A.util.removeClass(spinner,"slds-hide");
        var action = component.get("c.reopen");
        var commentbody = component.get("v.commentText");
        if(!component.get("v.commentText")){
            $A.util.addClass(spinner,"slds-hide");
            component.set("v.hasError",true);
        }else{
            action.setParams({
                parentId : component.get("v.caseId"),
                body : commentbody
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                $A.get("e.force:refreshView").fire();
                console.log('response.getState();'+state);
                if (state === "SUCCESS") {
                    var urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                        "url": "/viewcase?id="+component.get("v.caseId")
                    });
                    urlEvent.fire();
                    //component.set("v.showPopup",false);
                }
            });
            
            $A.enqueueAction(action);
        }
    },
    addescalate : function(component, event, helper) {
        var action2 = component.get("c.escalate");
        var spinner = component.find("spinner");
        $A.util.removeClass(spinner,"slds-hide");
        var commentbody = component.get("v.commentText");
        if(!component.get("v.commentText")){
            $A.util.addClass(spinner,"slds-hide");
            component.set("v.hasError",true);
        }else{
            action2.setParams({
                parentId : component.get("v.caseId"),
                body : commentbody
            });
            action2.setCallback(this, function(response) {
                var state = response.getState();
                $A.util.addClass(spinner,"slds-hide");
                $A.get('e.force:refreshView').fire();
                if (state === "SUCCESS") {
                    var urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                        "url": "/viewcase?id="+component.get("v.caseId")
                    });
                    urlEvent.fire();
                    //                    component.set("v.showPopup",false);
                }
            });
            
            $A.enqueueAction(action2);
        }
    },
    init : function(component, event, helper) {
        var currentId2 = location.search.substring(1);
        var splited = currentId2.split("=");
        
        var action = component.get("c.getAttachmentDetails");
        action.setParams({recordId:splited[1]});
        action.setCallback(component, function(response) {
            console.log('All cases result',response.getReturnValue())
            component.set("v.myCase1",response.getReturnValue());
            
        });
        $A.enqueueAction(action);
    },
    closeCase  : function(component, event, helper) {
        component.set("v.isError", false)
        component.set("v.showEditView", false);
        component.set("v.errorMsg", "");
        
        var action = component.get("c.getCaseDetails");
        action.setParams({
            caseId1  : component.get("v.recordId")
        });
        
        action.setCallback(this, function(a) {
            $A.get("e.force:refreshView").fire();
            if (a.getState() === "SUCCESS") {
                
                component.set("v.record", a.getReturnValue());
                helper.getStatusPickListValue(component);
            }
        });
        
        $A.enqueueAction(action);
    },
    
    closeCase1 : function (component, event, helper) {
        console.log("caseid: ", component.get("v.caseId"));
        var action = component.get("c.statusclosed");
        //var Status = component.get("v.record.Status") //get value of field
        action.setParams({recId :  component.get("v.caseId")});
        action.setCallback(this, function(a) {
            if (a.getState() === "SUCCESS") {
                console.log('closed sucessfully'+a.getReturnValue());
            }
        });
        
        $A.enqueueAction(action);
    }
    
})