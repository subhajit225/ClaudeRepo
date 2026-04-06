({
    doInit : function(component, event, helper) {
        component.set("v.showModal", true);
        component.set('v.timeEntry.Billable__c',true);
        component.set('v.timeEntry.Status__c','Pending');
        component.set('v.timeEntry.Filled_TimeEntry_Manually__c',true);
        let pageRef = component.get("v.pageReference");
        if (pageRef && pageRef.state && pageRef.state.PS_Task__c) {
            let psTaskId = pageRef.state.PS_Task__c;
            if (psTaskId) {
                component.set("v.recordId", psTaskId);
                component.set("v.timeEntry.PS_Task__c", psTaskId);
            }
        }
    },

    handleSave : function(component, event, helper) {
        event.preventDefault(); 
        const fields = component.find("formFieldsToValidate");
        let allValid = true;

        if (Array.isArray(fields)) {
            allValid = fields.reduce((validSoFar, field) => {
                return validSoFar && field.reportValidity();
            }, true);
        } else {
            allValid = fields.reportValidity();
        }
        if (allValid) {
            helper.saveTimeEntry(component, false); 
        } else {
            let toast = $A.get("e.force:showToast");
            toast.setParams({
                "title": "Error",
                "message": "Please fill required field.",
                "type": "error"
            });
            toast.fire();
        }

    },

    handleSaveAndNew : function(component, event, helper) {
        event.preventDefault(); 
        const fields = component.find("formFieldsToValidate");
        let allValid = true;

        if (Array.isArray(fields)) {
            allValid = fields.reduce((validSoFar, field) => {
                return validSoFar && field.reportValidity();
            }, true);
        } else {
            allValid = fields.reportValidity();
        }
        if (allValid) {
            component.set("v.saveAndNew",true);
            helper.saveTimeEntry(component, true);
        } else {
            let toast = $A.get("e.force:showToast");
            toast.setParams({
                "title": "Error",
                "message": "Please fill required field.",
                "type": "error"
            });
            toast.fire();
        }
         
    },

    closeModal : function(component, event, helper) {
        component.set("v.showModal", false);
        var navService = component.find("navService");
        let pageReference = {
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'PS_Time_Entry__c',
                actionName: 'home'
            }
        };
        navService.navigate(pageReference);
		let workspaceAPI = component.find("workspace");
        workspaceAPI.getEnclosingTabId().then(function(tabId) {
            workspaceAPI.closeTab({ tabId: tabId });
        })
    },
      
})