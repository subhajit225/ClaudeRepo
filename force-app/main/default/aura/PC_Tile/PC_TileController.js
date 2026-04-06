({
	handleClick : function(component, event, helper) {
        var url= "/" + component.get("v.url");        
		helper.gotoURL(component, event, url);
	}
})