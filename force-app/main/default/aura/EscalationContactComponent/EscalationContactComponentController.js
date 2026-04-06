({
	selectContact : function(component, event, helper) {
        var oldList = component.get("v.primaryContacts");
        oldList.push(component.get("v.contact"));
        component.set("v.primaryContacts",oldList);
         component.set("v.buttonstate",true);
	}
})