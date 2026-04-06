({
    executeBackend: function(component, actionName, parameters, callback, errorCallback, background) {
        var helper = this;
        var errorHandler = function(message, technicalData) {
            if (!background) component.set("v.loading", false);
            if (errorCallback) {
                errorCallback(message);
            } else {
                helper.displaySystemError(component, "Server Error", message, 
                                          actionName + "\r\n" + JSON.stringify(parameters) + "\r\n\r\n" + technicalData);
            }
        };
        
        var action = component.get("c." + actionName);
        if (action) {
            if (parameters) action.setParams(parameters);
            
            action.setCallback(component, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var responseValue = response.getReturnValue();
                    if (!((callback && callback(responseValue)) || background)) {
                        component.set("v.loading", false);
                    }
                } else if (state === "ERROR") {
                    var error = response.getError();
                    errorHandler((error ? (error[0].message || error.message) : undefined) || "Unknown Error");
                } else {
                    errorHandler("Unknown Error");
                }
            });
            
            if (!background) component.set("v.loading", true);
            $A.enqueueAction(action);
        } else {
            errorHandler("There is no \"" + actionName + "\" action");
        }
    },
    displaySystemError: function(component, title, message, technicalData) {
        var userInfo = $A.get("$SObjectType.CurrentUser");
        var toastEvent = $A.get("e.force:showToast");
        if (toastEvent) {
            toastEvent.setParams({
                type: "error",
                mode: "sticky",
                title: title,
                message: message ? message.split("\n")[0] : "Unknown Error",
                messageTemplate: "{0}. {1}",
                messageTemplateData: [
                    message ? message.split("\n")[0] : "Unknown Error", {
                        url: 'mailto:'+userInfo.Email+'?subject=Customer%20Support&body=' + encodeURIComponent(technicalData),
                        label: 'Send technical data.'
                    }
                ]
            });
            toastEvent.fire();
        }
    },
     buildData : function(component, helper) {
        var data = [];
        var pageNumber = component.get("v.currentPageNumber");
        var pageSize = component.get("v.pageSize");
        var allData = component.get("v.allData");
        var x = (pageNumber-1)*pageSize;
        
        //creating data-table data
        for(; x<(pageNumber)*pageSize; x++){
            if(allData[x]){
            	data.push(allData[x]);
            }
        }
        component.set("v.questionList", data);
        
    },
});