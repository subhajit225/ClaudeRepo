({
    doUpdate : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        var action = component.get("c.getAhaIdeaRecordValue");
        component.set('v.showSpinner',true);
        action.setParams({
            "rcId": recordId
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS"){
                var idearec = JSON.stringify(response.getReturnValue());
                var ahauniqueid = String(JSON.stringify(response.getReturnValue().Aha_Unique_ID__c));
                var escalationval = String(JSON.stringify(response.getReturnValue().Escalation__c));
                var escalationval = escalationval.slice(1);
                var escalationval = escalationval.slice(0, -1);
                var ahauniqueid = ahauniqueid.slice(1);
                var ahauniqueid = ahauniqueid.slice(0, -1);
                component.set("v.ahaUniqueId",ahauniqueid);
                component.set('v.showSpinner',true);
                if(escalationval == 'Yes'){
                    component.set("v.hideEscalteModal", true);
                }
                else{
                     component.set("v.showEscalteModal", true);
                }
            }
        });

        $A.enqueueAction(action);
    },

    closeModal: function(component, event, helper) {

        $A.get("e.force:closeQuickAction").fire();
    },
    escalateIdea: function(component, event, helper) {
        component.set("v.showSpinner",true);
        var parmetermap = component.get("v.mapforParamters");
        var ideaUniqueId = component.get("v.ahaUniqueId");
        var ideaid = component.get("v.recordId");
        parmetermap[ideaUniqueId] = ideaid;
        var action = component.get("c.performActionOnAhaIdeaRecord");
        action.setParams({
            "selectedAhaIdeaRecord": parmetermap,
            "action" : 'Escalate'
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS"){
                component.set("v.showSpinner",false);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Success',
                    message: 'Idea Escalated Successfully.',
                    duration:' 5000',
                    key: 'info_alt',
                    type: 'success',
                    mode: 'dismissible'
                });
                toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire();
                $A.get('e.force:refreshView').fire();
            }
            else{
                component.set("v.showSpinner",false);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Error',
                    message:'An Error is occured while Escalating this Idea.',
                    duration:' 5000',
                    key: 'info_alt',
                    type: 'error',
                    mode: 'pester'
                });
                toastEvent.fire();
            }
        });

        $A.enqueueAction(action);
    }
})