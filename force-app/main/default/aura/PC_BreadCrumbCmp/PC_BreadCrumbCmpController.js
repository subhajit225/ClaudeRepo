({
    doInit : function(component, event, helper) {
        
        var label = component.get("v.label");
        var labels = label.split(',');
        
        var page = component.get("v.page");
        var pages = page.split(',');
        
        // component.set("v.labels",labels);
        //  component.set("v.pages",pages);
        
        var crumbs = [];
        for(var i =0; i < labels.length;  i++){
            var url = pages[i];
            var crumb = { 'label': labels[i],'url': url};
            crumbs.push(crumb);
        }
        helper.getUrlParameter(component, event);   
        var pageName = '';
        
        var parentPageName = component.get("v.parentPageName");
        if(!$A.util.isEmpty(parentPageName)){
            var crumb = { 'label': parentPageName,'url': parentPageName};
            crumbs.push(crumb);
            /*var url="";
            var crumb1 = { 'label': "Content Details",'url': url1};
            crumbs.push(crumb1);*/
        }
        var pageName = component.get("v.pageName");
        if (pageName === "contentdetails"){
            var url1;
            var crumb1 = { 'label': "Content Details",'url': url1};
            crumbs.push(crumb1);
        }
        
        component.set("v.crumbs",crumbs);
    },
    
    gotoURL : function (component, event, url) {
        var name = event.getSource().get('v.name');
        if(!$A.util.isEmpty(name)){
            var url = '/'; ///partnersnew/s/
            if(name != 'home'){
                url = url + name; 
            }            
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
                "url": url,
                "redirect": false
            });
            urlEvent.fire(); 
        }        
    }
})