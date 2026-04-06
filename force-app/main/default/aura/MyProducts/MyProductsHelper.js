({
	unCheckClustersFromList: function(component, event, helper) {
		var checkboxes = component.find("clusterId");
        if (Array.isArray(checkboxes)) {
            checkboxes.forEach(function(cb) {
                cb.set("v.checked", false);
            });
        } else if (checkboxes) {
            checkboxes.set("v.checked", false);
        }
        component.set("v.selectedClusterIdList", []);
        component.set("v.unCheckedClusterIdList", []);
		component.set("v.selectedProactiveContact",'');
	},
	unCheckBulkClustersCheckbox: function(component, event, helper) {
		var checkbox = component.find("clusterIdall");
		component.set("v.selectedProactiveContact",'');
        if (checkbox && checkbox.get("v.checked")) {
            checkbox.set("v.checked", false);
            component.set("v.selectedClusterIdList", []);
            component.set("v.unCheckedClusterIdList", []);
        }
	},
    checkAllClusters: function(component, event, helper) {
		var checkboxes = component.find("clusterId");
        if (Array.isArray(checkboxes)) {
            checkboxes.forEach(function(cb) {
                cb.set("v.checked", true);
            });
        }
	},
    getRSCInstances : function(component, event, helper) {
        var action = component.get("c.getRSCInstances");
        action.setCallback(this, function (response) {
            const state = response.getState();
            if (state === "SUCCESS") {
                let data = response.getReturnValue();
                component.set("v.rscInstances", data);
            }
        });
        $A.enqueueAction(action);
    }
})