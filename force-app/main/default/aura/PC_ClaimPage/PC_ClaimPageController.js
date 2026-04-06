({
    doinit:function(component, event, helper) {
        helper.handlePreview(component, event, helper);
        
    },
    handleClick : function(component, event, helper) {
        var url= "/" + component.get("v.url");  
        helper.gotoURL(component, event, url);
    },
    homedetails:function(component, event, helper) {
        var url= "/" + component.get("v.ReturnHome");  
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url":url,
            "redirect": false
        });
        urlEvent.fire();
    },
    incentivesdetails:function(component, event, helper) {
        var url= "/" + component.get("v.ReturnIncentives");  
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url":url,
            "redirect": false
        });
        urlEvent.fire();
    }
    
    
})