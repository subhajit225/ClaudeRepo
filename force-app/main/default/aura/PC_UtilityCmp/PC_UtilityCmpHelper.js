({
    /*
     * Call Apex method.
     */
    callServer : function(component, actionName,params,callback,cacheable) { 
        
        var action = component.get(actionName);
        if(params){
            action.setParams(params); 
        }
        if (cacheable) {
            action.setStorable();
        }
        action.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") { 
                // pass returned value to callback function
                callback.call(this,response.getReturnValue());
            } else if (state === "ERROR") {
                // generic error handler
                var errors = response.getError();
                if (errors) {
                    console.log("Errors", errors);
                    if (errors[0] && errors[0].message) {
                        throw new Error("Error" + errors[0].message);
                    }
                } else {
                    throw new Error("Unknown Error");
                } 
            }
        });
        $A.enqueueAction(action);
        
    } ,
    navigateToURL : function (component, event, url, isredirect) {
        if(!isredirect){
            isredirect = false;
        }
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": url,
            "isredirect": isredirect
        });
        urlEvent.fire();
    },
    getPageName : function(){
        var pageName = '';
        var pathName = decodeURIComponent(window.location.pathname);
        if(!$A.util.isEmpty(pathName)){
            var paths = pathName.split('/');            
            if($A.util.isArray(paths)){
                pageName =  paths[paths.length-1];
            }
        } 
        return pageName;
    },
    gotoURL:function(component, event, url) {
        var parentPage;
        var contentId = event.target.id;
        if($A.util.isEmpty(contentId)){
            contentId = event.getSource().get("v.value");            
        }
        var pageName;
        var pathName = decodeURIComponent(window.location.pathname);
        var paths = pathName.split('/');
        if($A.util.isArray(paths)){
            pageName =  paths[paths.length-1];
        }
        
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url":url+'?id='+contentId+'&parentPage='+pageName,
            "redirect": false
        });
        urlEvent.fire();
    },
    
    showToast : function(component, event, helper, message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "message": message,
            "type": type
        });
        toastEvent.fire();
    },
})