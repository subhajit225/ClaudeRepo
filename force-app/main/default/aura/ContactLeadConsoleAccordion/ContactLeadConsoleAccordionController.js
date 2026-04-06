({
	showContent : function(component, event, helper) {
		component.set('v.showContent', !component.get('v.showContent'));
	},
    
    openTab : function(component, event, helper) {
        var whichOne = event.currentTarget.id;
        if(!$A.get("e.force:navigateToSObject")){
            //window.location.href = '/'+ whichOne;
            window.open('/'+ whichOne, '_blank');
            return;
        }
        var workspaceAPI = component.find("workspace");
        workspaceAPI.openTab({
            recordId: whichOne,
            focus: true
        }).then(function(response) {
            workspaceAPI.getTabInfo({
                  tabId: response
            }).then(function(tabInfo) {
            console.log("The url for this tab is: " + tabInfo.url);
            });
        })
        .catch(function(error) {
            var navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
                "recordId": whichOne
            });
            navEvt.fire();
        });
    },
    
    expendAll: function(component, event, helper) {
		component.set('v.showContent', component.get('v.expendAll'));
	},
    
    selectContact: function(component, event, helper) {
        var contactList =  component.get("v.contactList");
        let con = contactList.find(element => element.Id == event.getSource().get("v.name"));
        con.selected = event.getSource().get("v.checked");
        component.set("v.contactList", contactList);
    },
    
     selectLead: function(component, event, helper) {
        var allLeadRecords =  component.get("v.allLeadRecords");
        let lead = allLeadRecords.find(element => element.Id == event.getSource().get("v.name"));
        lead.selected = event.getSource().get("v.checked");
        component.set("v.allLeadRecords", allLeadRecords);
    },
    
})