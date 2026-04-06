({
    navigateURL : function(component, event) {
        var url;
        
        if(component.get("v.linkType") == "File" ){
            var pageurl = window.location.href;
            pageurl = pageurl.split('/s');
            // url = pageurl[0]+"/sfc/servlet.shepherd/version/download/"+component.get("v.Link1Id");
            url = pageurl[0]+"/sfc/servlet.shepherd/document/download/"+component.get("v.Link1Id")
        }else if(component.get("v.linkType") == "Community Page" ){
            url = "/"+component.get("v.Link1Id");
        }else if(component.get("v.linkType") == "External Url" ){
            url = component.get("v.Link1Id");
        }
        
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url" : url            
        });
        urlEvent.fire();        
    },
})