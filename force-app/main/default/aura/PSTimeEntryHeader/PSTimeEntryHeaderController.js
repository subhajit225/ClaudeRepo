({
	doInit : function(component, event, helper) {
        var today = new Date();
        component.set('v.today', today);
        helper.helperMethod(component, event, helper);
    },
})