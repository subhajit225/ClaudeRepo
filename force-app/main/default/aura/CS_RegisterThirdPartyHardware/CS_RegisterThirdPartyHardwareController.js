({
	doInit : function(component, event, helper) {
        helper.getData(component);
        component.set("v.showSpinner", false);
	},

    onBlur : function(component, event, helper) {
        let key = event.getSource().get('v.name');
        let value = event.getSource().get('v.value');
        helper.setDataInSessionStorage(key, value);
    },

    register : function(component, event, helper) {
        component.set("v.showSpinner", true);
        component.set("v.hasError", false);
        component.set("v.displayTimeoutMessage", false);
        component.set("v.nodeRes", null);
        let isValid = helper.validateData(component);

        if(isValid){
            helper.registerProduct(component);
        }
        else{
            component.set("v.showSpinner", false);
        }
	},

    updateNode : function(component, event, helper) {
        var nodeVal = component.find("nname").get("v.value");
        if(!!nodeVal)
            component.find("nname").set("v.value",nodeVal.toUpperCase());
    }
})