({
    navigateToUserProfile : function(component, event, helper) {
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        let pageURL = $A.get("$Label.c.ForumGamificationProfilePage");
        
        $A.get("e.force:navigateToURL").setParams({ 
            "url": "/"+pageURL+"?recordId=" + userId
        }).fire();
    }
})