({
    onTabFocused : function(component, event, helper) {
        var focusedTabId = event.getParam('currentTabId'); 
        var workspaceAPI = component.find("workspace"); 
        workspaceAPI.getFocusedTabInfo().then(function(tab) {
            workspaceAPI.getEnclosingTabId().then(function(tabId) {
                if(tab.recordId.startsWith("500")){
                    if (focusedTabId == tabId) {
                       // alert('Case Refreshed!');
                        workspaceAPI.refreshTab({
                            tabId: focusedTabId,
                            includeAllSubtabs: true
                        });
                    }
                }
            }).catch(function(error) {
                console.log(error);
            });
        }).catch(function(error) {
            console.log(error);
        });
    },
    init: function (cmp, event, helper) {
        var action = cmp.get('c.getCaseInfo');
        console.log('recId=>'+cmp.get("v.recordId"))
        action.setParams({'recId':cmp.get("v.recordId")});
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log('Case info=>>'+response.getReturnValue());
                console.log(response.getReturnValue());
                var result = response.getReturnValue();
                cmp.set("v.recordTypeName",result.recordTypeName);
                var cmpEvent = cmp.getEvent("RecTypeEvent"); 
                cmpEvent.setParams({"recordType" : result.recordTypeName});
                //cmpEvent.setParams({"recordType" : result.recordTypeName , "showMilestone" : result.showMilestone}); 
                cmpEvent.fire();
            }
            
        });
        $A.enqueueAction(action);
    }
})