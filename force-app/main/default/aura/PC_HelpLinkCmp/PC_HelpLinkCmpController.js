({
    doInit: function(component, event, helper) {
        
        var pageName =  helper.getPageName();
        var action = component.get("c.getHelpLinks");
        action.setParams({
            "pageName": pageName,
            "imageType": component.get("v.imageType")
        });
        action.setCallback(this, function(response) { 
            if(response.getState() === "SUCCESS") {
                component.set("v.helpLinks",response.getReturnValue());
            }
        });
        $A.enqueueAction(action); 
    },
    handleClick:function(component, event, helper) {
        var hLink = component.get("v.helpLinks").find(record => record.Id === event.target.id);
        var url;
        
        if(hLink.Link_Type__c == "Community Page"){
            url = hLink.Navigate_Url__c;
        }
        else if(hLink.Link_Type__c == "File" ){
            var pageurl = window.location.href;
            pageurl = pageurl.split('/s');
            url = pageurl[0]+hLink.Navigate_Url__c;            
        }
        else if(hLink.Link_Type__c == "External URL" ){
            url = hLink.Navigate_Url__c;
        }
        if(!$A.util.isEmpty(url)){
            helper.navigateToURL(component, event, url,true);
        }
    },
    
})