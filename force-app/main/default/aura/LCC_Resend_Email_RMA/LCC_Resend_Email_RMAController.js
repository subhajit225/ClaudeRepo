({
    handleRecordUpdated : function(component, event, helper) {
        var eventParams = event.getParams();
        if(eventParams.changeType === "LOADED") {
           // record is loaded (render other component which needs record data value)
            console.log("Record is loaded successfully.");
            console.log(component.get("v.sObjectInfo"));
            helper.handlesaveRMA(component, event, helper);

        }else if(eventParams.changeType === "ERROR") {
            //there’s an error while loading, saving, or deleting the record
            console.error("Can't load the record.");
            var toastEvent = $A.get("e.force:showToast");
    		toastEvent.setParams({
        		"title": "Can't load the record.",
                        "duration": 10000,
                        "type": "error",
        		"message": "Can't load the record."
    		});
    		toastEvent.fire();
           $A.get("e.force:closeQuickAction").fire();
        }
       
    },
    
})