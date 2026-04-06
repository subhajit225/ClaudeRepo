({
     gotoURL : function (component, event, url) {        
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url":url,
            "redirect": false
        });
        urlEvent.fire();
    }
})