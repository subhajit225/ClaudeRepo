({
	doinit : function(component, event, helper) {
        var action = component.get("c.getKCSId"); // Get the Apex method
        action.setParams({
            "processId" : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                // Set the data in the component attribute
                var kbId = response.getReturnValue();
                component.set("v.kcsId", kbId);
                if(kbId.startsWith("ka0")){
                    component.set("v.show",true);
                }
            } else {
                console.log("Error: " + response.getError());
            }
        });
        $A.enqueueAction(action); // Enqueue the Apex action
	},
    editArticle : function(component, event, helper) {
        var editRecordEvent = $A.get("e.force:editRecord");
        editRecordEvent.setParams({
            "recordId": component.get("v.kcsId")
        });
        editRecordEvent.fire();
    },
    handleSaveSuccess: function(component, event, helper) {
        // Refresh the record view after saving
        var refreshEvent = $A.get("e.force:refreshView");
        refreshEvent.fire(); // Refresh the view to reflect changes
        alert('refressh');
    }
    
})