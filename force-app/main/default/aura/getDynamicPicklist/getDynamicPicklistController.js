({
    getLines : function(component, event, helper) {
        component.set("v.isLoading", true);
    	helper.getPicklistValues(component, event);
    },
     
    handleOnChange : function(component, event, helper) {
        helper.saveLead(component, event);
    }
})