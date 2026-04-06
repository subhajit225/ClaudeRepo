({
    accept : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
    doInit : function(component, event, helper) {
        component.set("v.showGenericSpinner", true);
        component.find("createRecord").getNewRecord(
            "Opportunity", // sObject type (objectApiName)
            null,      // recordTypeId
            false,     // skip cache?
            $A.getCallback(function() {
                component.set("v.showGenericSpinner", false);
                var rec = component.get("v.newOpportunity");
                var error = component.get("v.newOrecordError");
                if(error || (rec === null)) {
                    return;
                }
            })
        );
        
    },        
    
    close : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
    
    recordUpdated: function(component, event, helper) {
        if(component.get("v.showGenericSpinner")) return;
        component.set("v.newOpportunityRecord.Name", component.get("v.OpportunityRecord.Name")+' - '+'DEBOOKING');
        component.set("v.newOpportunityRecord.AccountId", component.get("v.OpportunityRecord.AccountId"));
        component.set("v.newOpportunityRecord.CloseDate", component.get("v.OpportunityRecord.CloseDate"));
        component.set("v.newOpportunityRecord.OwnerId", component.get("v.OpportunityRecord.OwnerId"));
        component.set("v.newOpportunityRecord.Opportunity_Type__c", 'Debooking');
        component.set("v.newOpportunityRecord.StageName", '7 Closed Won');
        component.set("v.newOpportunityRecord.Win_Alert_Sent__c", component.get("v.OpportunityRecord.Win_Alert_Sent__c"));
        component.set("v.newOpportunityRecord.Opportunity_Sub_Type__c", component.get("v.OpportunityRecord.Opportunity_Sub_Type__c"));
        component.set("v.showGenericSpinner", true);
        component.find("createRecord").saveRecord(function(saveResult) {
            component.set("v.showGenericSpinner", false);
            if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": saveResult.recordId,
                });
                navEvt.fire();
            } else if (saveResult.state === "INCOMPLETE") {
                 component.set("v.recordError","User is offline, device doesn't support drafts.");
                //alert("User is offline, device doesn't support drafts.");
            } else if (saveResult.state === "ERROR") {
                component.set("v.recordError",JSON.stringify(saveResult.error));
                //alert('Problem saving contact, error: ' + JSON.stringify(saveResult.error));
            } else {
                component.set("v.recordError",JSON.stringify(saveResult.error));
                //alert('Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
            }
        });
    }
})