//close Case js controller

({
    doinit: function(component,event,helper){
        var action = component.get("c.getCaseEmails");
        action.setParams({'recordId':component.get('v.recordId')});
        action.setCallback(this,function(response){
            if(response.getState() === "SUCCESS"){
                component.set("v.emailsList",response.getReturnValue());
            }
        });
        $A.enqueueAction(action);

        helper.setDuplicateCaseId(component);
    },
    closeModal: function(component,event,helper){
        var baseUrl = helper.fetchBaseUrl(component , event);
        var isTrue = confirm("Any changes made will be lost. Are you sure to cancel?");
        if(isTrue){
            if(!component.get("v.recordId")){
                var workspaceAPI = component.find("workspace");
                workspaceAPI.getFocusedTabInfo().then(function(response) {
                    var focusedTabId = response.tabId;
                    workspaceAPI.closeTab({tabId: focusedTabId});
                })
                .catch(function(error) {
                    console.log(error);
                });
            }else{
                var vfOrigin = baseUrl;
                window.postMessage('close', vfOrigin);    
            }
        }
        //sforce.one.back(true);
    },
    handleOnload: function(cmp, event, helper) {
        setTimeout(function(){
            if(!!cmp.find('workaroundProvided')){
                var workaroundProvided = cmp.find('workaroundProvided').get("v.value");//,new Date().toISOString());
                
                if(workaroundProvided == null) {
                    cmp.find('workaroundProvided').set("v.value",new Date().toISOString());
                }
            }
            if(!!cmp.find('workaroundVerified')){
                var workaroundVerified = cmp.find('workaroundVerified').get("v.value");
                
                if(workaroundVerified == null) {
                    cmp.find('workaroundVerified').set("v.value",new Date().toISOString());
                }
            }
            if(!!cmp.find('resolutionField')){
                var resField = cmp.find("resolutionField").get("v.value");
                cmp.set("v.hasErrorForDuplicateResol", (resField != 'Duplicate'));
            }
            if(!!cmp.find('platformType')){
               helper.originChangeHelper(cmp, event, helper);
            }
            if(!!cmp.find('reTriggerField')){
                var reTrigger = cmp.find("reTriggerField").get("v.value");
                var noRetriggerReason = cmp.find("noTriggerReasonField");
                cmp.set("v.isReTriggerChecked", reTrigger);
                if(reTrigger){
                    $A.util.addClass(noRetriggerReason, 'hideField');
                }
                else{
                    $A.util.removeClass(noRetriggerReason, 'hideField');
                }
            }
            var resField = cmp.find("resolutionField").get("v.value");
            //CS21-2571
            if(resField != null && (resField == 'H/W - Replaced' || resField == 'H/W - 3rd Party')){
                cmp.find('Product_Area__c').set("v.value", "Hardware\\RMA");
            }
            //CS21-2571 ends
        },100);
    },
    handleSuccess: function(component, event, helper) {
        //For modal Save
        var baseUrl = helper.fetchBaseUrl(component , event);
        if(!component.get("v.recordId")){
            var updatedRecord = JSON.parse(JSON.stringify(event.getParams()));
            var workspaceAPI = component.find("workspace");
            workspaceAPI.isConsoleNavigation().then(function(isConsole) {
                if (isConsole) {
                    workspaceAPI.openTab({
                        pageReference: {
                            "type": "standard__recordPage",
                            "attributes": {
                                "recordId": updatedRecord.response.id,
                                "actionName":"view"
                            },
                            "state": {}
                        },
                        focus: false
                    }).then(function(response) {
                        workspaceAPI.getTabInfo({
                            tabId: response
                        }).then(function(tabInfo) {
                            workspaceAPI.getFocusedTabInfo().then(function(response) {
                                var focusedTabId = response.tabId;
                                workspaceAPI.closeTab({tabId: focusedTabId});
                            })
                            .catch(function(error) {
                                console.log(error);
                            });
                        });
                    }).catch(function(error) {
                        console.log(error);
                    });
                } else {
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": updatedRecord.response.id,
                        "slideDevName": "detail"
                    });
                    navEvt.fire();
                }
            })
            .catch(function(error) {
                console.log(error);
            });
        }else{
            var updatedRecord = JSON.parse(JSON.stringify(event.getParams()));
            sforce.one.navigateToSObject(updatedRecord.response.id, "detail");
            var vfOrigin = baseUrl;
            window.postMessage('refresh', vfOrigin);
        }
        /*var workspaceAPI = cmp.find("workspace");
        var message = 'refresh';
        var vfOrigin = sforce.one.navigateToSObject(cmp.get("v.recordId"), 'related');
        window.postMessage(message, vfOrigin);
        sforce.one.navigateToSObject(cmp.get("v.recordId"), 'related');*/

    },
    openEmail: function(cmp, event, helper) {
        sforce.one.navigateToSObject(event.target.id, 'detail');
    },
    resDetailChange: function(cmp, event, helper) {
        var hasError = false;
        var resDetails = cmp.find("details").get("v.value");
        if(resDetails!=null && resDetails!='' && resDetails!=undefined){

        }else{
            hasError = true;
        }
        cmp.set("v.hasError",hasError);
    },
    
    originChange: function(cmp, event, helper) {
        helper.originChangeHelper(cmp, event, helper);
    },
    resFieldChange: function(cmp, event, helper) {
        var hasErrorForDuplicateResol = false;
        var resField = cmp.find("resolutionField").get("v.value");
        //CS21-2571
        if(resField != null && (resField == 'H/W - Replaced' || resField == 'H/W - 3rd Party')){
            cmp.find('Product_Area__c').set("v.value", "Hardware\\RMA");
        }
        //CS21-2571 ends
        if(resField != null && resField == 'Noise - Duplicate/Alert'){

        }
        if(resField != null && resField == 'Duplicate'){
            cmp.find('workaroundProvided').set("v.value",new Date().toISOString());
            cmp.find('workaroundVerified').set("v.value",new Date().toISOString());
        }
        else{
            var hasErrorForDuplicateResol = true;
        }
        cmp.set("v.hasErrorForDuplicateResol",hasErrorForDuplicateResol);
    },
    handleSubmit : function(cmp, event, helper){
        var hasError = false;
        if(!!cmp.find("details")){
            var resDetails = cmp.find("details").get("v.value");
            if(resDetails!=null && resDetails!='' && resDetails!=undefined){
                
            }
            else{
                var resField = cmp.find("resolutionField").get("v.value");
                if(resField != null && resField == 'Duplicate'){
                    
                }
                else{
                    hasError = true; 
                }
            }

        }
        event.preventDefault();     
        var exception;
        var otherException;
        if(cmp.get("v.recordType") == 'Customer Success'){
            exception = cmp.find("exception").get("v.value");
            otherException = cmp.find("otherException").get("v.value");
            if(!cmp.find("Entitlement__c").get("v.value")){
                if(exception == 'Other' && otherException == ''){
                    cmp.find("otherException").reportValidity();
                    hasError = true; 
                }else if(exception == 'Other' && otherException != ''){
                    exception = exception+' - ';
                } 
            }
        }
        cmp.set("v.hasError",hasError);
        if(hasError){
            document.getElementById('scrollUp').scrollIntoView(true);
            event.preventDefault();       // stop the form from submitting
            return;
        }else{
            var duplicateCaseId = cmp.get("v.duplicateCase.Id");
            var fields = event.getParam('fields');
            if(cmp.get("v.recordType") == 'Customer Success'){
                fields["Entitlement_Exception__c"] = exception+otherException;
            }
            fields["Status"] = 'Closed';
            fields["Duplicate_Case_Id__c"] = duplicateCaseId != null ? duplicateCaseId : null;
            cmp.find('recordForm').submit(fields);
        }
    },
    handleError : function(cmp, event, helper){
        document.getElementById('scrollUp').scrollIntoView(true);
    },
    openOpp: function(cmp, event, helper){
        alert('123');
        var editRecordEvent = $A.get("e.force:editRecord");
        editRecordEvent.setParams({
            "recordId": "006U8000003H3cVIAS"
        });
        editRecordEvent.fire();
    },
    handleReTrigger: function(cmp, event, helper){
        var reTrigger = cmp.find("reTriggerField").get("v.value");
        var noRetriggerReason = cmp.find("noTriggerReasonField");
    	cmp.set("v.isReTriggerChecked", reTrigger);
        if(reTrigger){
            $A.util.addClass(noRetriggerReason, 'hideField');
        }
        else{
            $A.util.removeClass(noRetriggerReason, 'hideField');
        }
    }

})