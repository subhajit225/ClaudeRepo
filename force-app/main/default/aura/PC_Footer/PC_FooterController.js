({
	myAction : function(component, event, helper) {
		
	},
    gotoURL : function (component, event, url) {
        //alert(url);
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": url,
            "isredirect": false
        });
        urlEvent.fire();
    },
})