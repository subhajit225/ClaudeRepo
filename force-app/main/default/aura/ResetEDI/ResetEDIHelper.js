({
	serversidesave : function(component, event, helper, sobjectrec){
    component.set("v.spinner", true); 
    var action = component.get("c.resynEdi");
    action.setParams({ poId : component.get("v.recordId") });
    action.setCallback(this, function(response) {
        var state = response.getState();
         var errors = response.getError();
        if (state === "ERROR") {
            if (errors && errors[0] && ( errors[0].message || errors[0].pageErrors)) {
            if(component.get("v.isInsideVF")){
                alert(errors[0].message+': '+ errors[0].pageErrors);
                return;
            }
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Cannot update the record",
                "duration": 10000,
                "type": "error",
                "message": errors[0].message+': '+ errors[0].pageErrors
            });
            toastEvent.fire(); 
            $A.get("e.force:closeQuickAction").fire(); 
            }
        }else if (state === "SUCCESS"){
            component.set("v.spinner", false); 
            var str = response.getReturnValue();
                if(str != ''){
                    if(component.get("v.isInsideVF")){
                        alert(response.getReturnValue());
                        return;
                    }
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Cannot update the record",
                                "duration": 10000,
                                "type": "error",
                        "message": response.getReturnValue()
                    });
                    toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire();  
                }else{
            		helper.gotoRec(component,component.get("v.sObjectInfoClone.Id"));
                }
        }
        
    });
    // Send action off to be executed
    $A.enqueueAction(action);
    },
    
    gotoRec : function(component, recId){
        if(component.get("v.isInsideVF")){
             window.location.href = '/'+component.get("v.recordId");
            return;
        }
        $A.get("e.force:closeQuickAction").fire();
        var workspaceAPI = component.find("workspace");
        workspaceAPI.isConsoleNavigation().then(function(isConsole) {
            if (isConsole) {
                var workspaceAPI = component.find("workspace");
                workspaceAPI.getFocusedTabInfo().then(function(response) {
                    var focusedTabId = response.tabId;
                    workspaceAPI.refreshTab({
                        tabId: focusedTabId
                    });
                })
                .catch(function(error) {
                    $A.get('e.force:refreshView').fire();
                });
                
            } else {
                $A.get('e.force:refreshView').fire();
            }
        })
        .catch(function(error) {
            $A.get('e.force:refreshView').fire();
        });
        
    }
})