({
	closeQA : function(component, event, helper) {
		$A.get("e.force:closeQuickAction").fire();
        if(event.getParam("onlyCloseQA") == 'true') return;
        
        var workspaceAPI = component.find("workspace");
        workspaceAPI.isConsoleNavigation().then(function(isConsole) {
            if (isConsole) {
                var workspaceAPI = component.find("workspace");
                workspaceAPI.getFocusedTabInfo().then(function(response) {
                    var focusedTabId = response.tabId;
                    workspaceAPI.refreshTab({
                      tabId: focusedTabId
                });
                })
                .catch(function(error) {
                     $A.get('e.force:refreshView').fire();
                });
                
            } else {
                 $A.get('e.force:refreshView').fire();
            }
        })
        .catch(function(error) {
             $A.get('e.force:refreshView').fire();
        });
        
        
	}
})