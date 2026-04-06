({
	doInit : function(component, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:PSProjectOrderAssignmentCmp",
            componentAttributes: {
                projectId : component.get("v.recordId")
            }
        });
        evt.fire();
        
        /*
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            console.log('tab info..!', JSON.parse(JSON.stringify(response)));
            workspaceAPI.isSubtab({
                tabId: response.tabId
            }).then(function(isSubTab) {
                console.log('isSubTab..!', JSON.parse(JSON.stringify(isSubTab)));
                if(isSubTab){
                    var focusedTabId = response.parentTabId;       
                    workspaceAPI.closeTab({tabId: response.tabId});
                } else {
                    var focusedTabId = response.tabId;                    
                }
                workspaceAPI.openSubtab({
                    parentTabId: focusedTabId,
                    url: ' /cmp/c__PSProjectOrderAssignmentCmp?c__projectId='+component.get("v.recordId"),
                    focus: true
                }).then(function(sTabSuccessResponse){
                    console.log('sTabSuccessResponse..!', JSON.parse(JSON.stringify(sTabSuccessResponse)));
                }).catch(function(sTabErrorResponse){
                    console.log('sTabErrorResponse..!', JSON.parse(JSON.stringify(sTabErrorResponse)));
                });
            });
        })
        .catch(function(error) {
            console.log(error);
        });
        */
	}
})