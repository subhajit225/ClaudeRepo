({
    doInit : function(component, event, helper) {
        helper.getRecordTypeId(component, event, helper);
        helper.getIncentiveForm(component, event, helper);
    },
    
    handleSaveCcrRecord:function(component, event, helper) {
        component.set("v.ccrFieldsClone", JSON.parse(JSON.stringify(component.get("v.ccrFields"))));
        if (helper.validateForm(component)) {
            helper.saveRecord(component, event, helper);
        }
    },
    
    handleCancelCcrRecord:function(component, event, helper) {
        helper.gotoURL(component, event, "/incentives");
    }  
})