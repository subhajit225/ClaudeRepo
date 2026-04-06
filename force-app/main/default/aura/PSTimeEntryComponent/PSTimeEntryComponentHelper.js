({
    allProjects : function(component, event, helper) {
        component.set("v.Spinner", true); 
        var action = component.get("c.getProject");
        action.setParams({ 
            "cmpStartDate" : component.get("v.weekStartDate"),
            "weekType" : component.get("v.weekTypeString")
        });
        action.setCallback(this, function(res) {
            var state = res.getState();
            if (state === "SUCCESS") {
                var resp = res.getReturnValue();
                var resp1 = resp.disablePreviousWeek;
                var resp2 = resp.disableNextWeek;
                var selected = [];
                var dropdownSelected = [];
                var dropdownSelectedIds = [];
                var allProjectsRecieved = resp.allProjects;
                var clickedValue;
                component.set("v.ReadOnlyForHour",resp.readOnly);
                for(var i =0; i < allProjectsRecieved.length; i++){
                    if(allProjectsRecieved[i].selected){
                        selected.push(allProjectsRecieved[i]); 
                        clickedValue = {
                            "Id":allProjectsRecieved[i].project.Id,
                            "Name":allProjectsRecieved[i].project.Name
                        };
                        dropdownSelectedIds.push(allProjectsRecieved[i].project.Id);
                        dropdownSelected.push(clickedValue);
                    }
                }
                component.set("v.ProjectList",resp.allProjects);
                component.set("v.weekStartDate",resp.weekStartDate);
                component.set("v.weekEndDate",resp.weekEndDate);
                component.set("v.SelectedProjects",selected);
                component.set("v.SelectedProjectsList",dropdownSelected);
                component.set("v.SelProjIds",dropdownSelectedIds);
                component.set("v.disablePreviousWeek", resp.disablePreviousWeek);
                component.set("v.disableNextWeek",resp.disableNextWeek);
            } else {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error :",
                    "mode": "sticky",
                    "message": res.getError()[0].message 
                });
                toastEvent.fire();
            }
            component.set("v.Spinner", false); 
        });
        $A.enqueueAction(action);
    },
    
    helpersave : function(component,event,helper, buttonclicked) {
        component.set("v.Spinner", true); 
        var temp = component.get("v.SelectedProjects");
        var action = component.get("c.savePSEntries");
        action.setParams({
            "saveList" : JSON.stringify(temp),
            "buttonClicked": buttonclicked  
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
          
            if (state === "SUCCESS") {
                var retResponse = response.getReturnValue();
                //console.log('retResponse ________________________________ ',retResponse);
                if(retResponse == null){
                    component.set("v.notificationmessage", 'Timesheet saved successfully.');
                    component.set("v.weekTypeString", null);
                    helper.allProjects(component, event, helper);
                    $A.util.removeClass(component.find('warningDiv'), 'slds-hide');
                    window.setTimeout($A.getCallback(function() {
                        $A.util.addClass(component.find('warningDiv'), 'slds-hide');
                    }), 2000); 
                }else{
                    console.log('Id _________ ',retResponse.Id);
                    console.log('Error _________ ',retResponse.Error);
                    component.set("v.errorTaskId", retResponse.Id);
                    component.set("v.errorMessage", retResponse.Error);
                    $A.util.removeClass(component.find('errorDiv'), 'slds-hide');
                    window.setTimeout($A.getCallback(function() {
                        $A.util.addClass(component.find('errorDiv'), 'slds-hide');
                    }), 300000000);   
                }
            }else if (state === "ERROR") {
                var retResponse = response.getReturnValue();
                var err;
                if(response.getError() != null && response.getError() != 'undefined' &&
                   response.getError()[0] != null && response.getError()[0] != 'undefined' &&
                   response.getError()[0].pageErrors[0] != null && 
                   response.getError()[0] != 'undefined' && 
                   response.getError()[0].pageErrors[0].message != null && 
                   response.getError()[0].pageErrors[0].message != 'undefined'
                  ){
                    //console.log('Error ______________________________________________',response.getError()[0]);
                   	 var err = response.getError()[0].pageErrors[0].message;
                } else {
                    var err = 'Some error occured. Please contact your admin.'
                }
                component.set("v.errorMessage", err);
                $A.util.removeClass(component.find('errorDiv'), 'slds-hide');
                window.setTimeout($A.getCallback(function() {
                    $A.util.addClass(component.find('errorDiv'), 'slds-hide');
                }), 300000000);
            }
            component.set("v.Spinner", false); 
        });
        $A.enqueueAction(action);
    },
    
})