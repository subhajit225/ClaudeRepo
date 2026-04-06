({
    handleClick : function(component, event, helper) {
        var url= "/" + component.get("v.url"); 
        var selectedTag = component.get('v.label');
        var parentPage;
        var pageName;
        var pathName = decodeURIComponent(window.location.pathname);
        var paths = pathName.split('/');
        if($A.util.isArray(paths)){
            pageName =  paths[paths.length-1];
        }
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url":url+'?name='+selectedTag,
            "redirect": false
        });
        urlEvent.fire();
    },
    handleClick2 : function(component, event, helper) {
        var url= "/" + component.get("v.url2"); 
        var selectedTag = component.get('v.label2');
        var parentPage;
        var pageName;
        var pathName = decodeURIComponent(window.location.pathname);
        var paths = pathName.split('/');
        if($A.util.isArray(paths)){
            pageName =  paths[paths.length-1];
        }
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url":url+'?name='+selectedTag,
            "redirect": false
        });
        urlEvent.fire();
    }
    
})