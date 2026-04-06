({
    contentDetails:function(component, event, helper) {
        var action = component.get("c.fetchContentDetails"); 
        console.log('tags--->',component.get("v.selectedTag"));
        action.setParams({
            TagsName:component.get("v.selectedTag"),
        });
        action.setCallback(this, function(response) { 
            if(response.getState() === "SUCCESS") {
                component.set("v.Contents",response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },
    /*gotoURL:function(component, event, url) {
        var parentPage;
        var contentId = event.target.id;
        if($A.util.isEmpty(contentId)){
            contentId = event.getSource().get("v.value");            
        }
        var pageName;
        var pathName = decodeURIComponent(window.location.pathname);
        var paths = pathName.split('/');
        if($A.util.isArray(paths)){
            pageName =  paths[paths.length-1];
        }
        
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url":url+'?id='+contentId+'&parentPage='+pageName,
            "redirect": false
        });
        urlEvent.fire();
    }*/
})