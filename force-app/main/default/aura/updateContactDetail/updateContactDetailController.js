({
	handleSuccess : function(component, event, helper) {
		component.find("reloadRecord").reloadRecord(false);
        $A.get('e.force:refreshView').fire();
        component.find("reloadRecord").reloadRecord(true);
	},
    
})