({
    navigateToUserProfile : function(component, event, helper) {
        let enableNavigation = component.get("v.enableNavigation");
        
        if (enableNavigation) {
            console.log('error');
            let userId = event.currentTarget.dataset.id;
            let pageURL = $A.get("$Label.c.ForumGamificationProfilePage");
            
            $A.get("e.force:navigateToURL").setParams({ 
                "url": "/"+pageURL+"?recordId=" + userId
            }).fire();
        }
    }
})