({
	init: function(cmp) {
        var myPageRef = cmp.get("v.pageReference");
        var caseId = myPageRef.state.c__caseId;
        var caseComm = myPageRef.state.c__caseComment;
        var tabId = myPageRef.state.c__tabId;
        
        cmp.set("v.caseId", caseId);
        cmp.set("v.caseCommentVal", caseComm);
        cmp.set("v.tabId", tabId);

   		var action = cmp.get('c.setFocusedTabLabel');
        $A.enqueueAction(action);
    },
    setFocusedTabLabel : function(component) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getEnclosingTabId().then(function(response) {// getEnclosingTabId getFocusedTabInfo
            var focusedTabId = response.tabId;
            workspaceAPI.setTabLabel({
                tabId: focusedTabId,
                label: "Case Comment"
            });
            workspaceAPI.setTabIcon({
                tabId: focusedTabId,
                icon: "standard:case_comment",
                iconAlt: "Case Comment"
            });
        })
        .catch(function(error) {
            console.log(error);
        });
    }

})