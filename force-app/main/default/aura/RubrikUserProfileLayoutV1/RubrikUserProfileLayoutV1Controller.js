({
    redirect : function(component, event, helper) {
        $A.get("e.force:navigateToURL").setParams({ 
            "url": "https://www.rubrik.com/"
        }).fire();
    }
})