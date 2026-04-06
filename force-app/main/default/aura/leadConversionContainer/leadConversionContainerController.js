({
    onPageReferenceChange: function(component, evt, helper) {
        var myPageRef = component.get("v.pageReference");
        var leadId = myPageRef.state.c__leadId;
        component.set("v.leadId", leadId);
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.setTabLabel({
                tabId: focusedTabId,
                label: "Convert Lead"
            });
            workspaceAPI.setTabIcon({
                tabId: focusedTabId,
                icon: "standard:asset_relationship",
                iconAlt: "Convert Lead"
            });
        }).catch(function(error) {
            console.log(error);
        });
    }
})