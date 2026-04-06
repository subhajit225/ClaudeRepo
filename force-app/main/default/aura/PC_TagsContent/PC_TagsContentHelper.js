({
    loadData : function(component, event, helper) {
       // var property=component.get("v.btnlabel");
       // var selectedTag = event.getSource().get('v.name');
       // component.set("v.selectedTag",selectedTag);
       var Library=component.get("v.LibraryName");
        var action = component.get("c.fetchContentDetailsForCustomTags"); 
        action.setParams({
            TagsName:component.get("v.selectedTag"),
            LibraryName:Library,
            DefaultTag:component.get("v.defaultTag")
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