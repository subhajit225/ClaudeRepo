({
    saveTimeEntry : function(component, isSaveAndNew) {
        let timeEntry = component.get("v.timeEntry");
        let timeEntryList = [];
        timeEntryList.push(timeEntry);
        let action = component.get("c.saveDirectPSEntries");
        action.setParams({
            timeEntryList: timeEntryList
        });

        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                if (isSaveAndNew) {
                    this.handleReset(component);
                    component.set("v.showModal", false);
                    setTimeout(() => {
                        component.set("v.showModal", true);
                    }, 100);
                        window.location.reload();
                } else {
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": response.getReturnValue().Id,
                        "slideDevName": "detail"
                    });
                    navEvt.fire();
                }
                let toast = $A.get("e.force:showToast");
                toast.setParams({
                    "title": "Success",
                    "message": "Time Entry saved successfully.",
                    "type": "success"
                });
                toast.fire();
                if(!isSaveAndNew){
                    let workspaceAPI = component.find("workspace");
                    workspaceAPI.getEnclosingTabId().then(function(tabId) {
                        workspaceAPI.closeTab({ tabId: tabId });
                    })
                }
            } else {
                console.error('Error:', response.getError());
                let toast = $A.get("e.force:showToast");
                toast.setParams({
                    "title": "Error",
                    "message": "Error saving Time Entry.",
                    "type": "error"
                });
                toast.fire();
            }
        });

        $A.enqueueAction(action);
    },

    handleReset : function(component, event, helper) {
        let fields = component.find("formFields"); 
        if (Array.isArray(fields)) {
            fields.forEach(field => field.set("v.value", ""));
        } else {
            fields.set("v.value", "");
        }
        component.set('v.timeEntry.PS_Task__c','');
        component.set('v.timeEntry.Name','');
    },
    
})