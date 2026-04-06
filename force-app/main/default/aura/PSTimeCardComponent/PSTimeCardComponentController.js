({
    doInit : function(component, event, helper) {
        helper.fetchTimeCardWrp(component, event, helper);
        document.title = "PSTimeEntry Home";
      	  
        var workspaceAPI = component.find("workspace");
        workspaceAPI.isConsoleNavigation().then(function(response) {
            component.set('v.isConsoleApplication', response);
            workspaceAPI.getFocusedTabInfo().then(function(response) {
                var focusedTabId = response.tabId;
                workspaceAPI.setTabLabel({
                    tabId: focusedTabId,
                    label: "PSTimeEntry Home"
                });
                workspaceAPI.setTabIcon({
                    tabId : focusedTabId, 
                    icon : 'standard:contact_list',
                    iconAlt : 'Timecard'
                });
            })
            .catch(function(error) {
                console.log(error);
            });
        })
        .catch(function(error) {
            console.log(error);
        });
    },
    openPrimaryTab : function(component, event, helper) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.openTab({
            url: '/'+event.target.dataset.recid,
            focus: true
        });
    },
    openTimeEntriesTab : function(component, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:PSTimeEntryComponent",
            componentAttributes: {
                weekStartDate : event.target.dataset.dt
            }
        });
        evt.fire();
    },
    Timecards : function(component, event, helper) {
        var compEvent = component.getEvent("PSTimeCardShowProject");
        compEvent.setParams({
            "comp" : component
        });
        compEvent.fire();
        
        var isConsoleApplication = component.get('v.isConsoleApplication');
        if(isConsoleApplication){
            var evt = $A.get("e.force:navigateToComponent");
            evt.setParams({
                componentDef : "c:PSTimeEntryComponent",
                componentAttributes: {}
            });
            evt.fire();
        } else {
        	window.open('/c/PSTimeEntries.app','_self');    
        }
    },
    hideSpinner : function(component,event,helper){    
        component.set("v.Spinner", false);
    },
    showSpinner: function(component, event, helper) {
        //component.set("v.Spinner", true); 
    },
    UnlockRecord:function(component, event, helper) {
        var action = component.get('c.UnlockRecordMethod');   
        action.setParams({
            TimeCardIdList:component.get('v.GetTimeCardID'),            
        });
        action.setCallback(this, function(response) {
             var state = response.getState();
            
            if (state === "SUCCESS") {
         component.set("v.TimecardList",response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
         component.set("v.IsModelOpen", false);
    },
    openModel: function(component, event, helper) {
      component.set("v.GetTimeCardID", event.target.id);
      component.set("v.IsModelOpen", true);
   },
    closeModel: function(component, event, helper) {
      component.set("v.IsModelOpen", false);
   },
    handleRefreshTab: function(component, event, helper) {
        helper.fetchTimeCardWrp(component, event, helper);
    }
})