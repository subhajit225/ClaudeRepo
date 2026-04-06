({
   
    handleRecordUpdated : function(component, event, helper) {
        var eventParams = event.getParams();
        if(eventParams.changeType === "LOADED") {
           // record is loaded (render other component which needs record data value)
            console.log("Record is loaded successfully.");
            var  mObj=JSON.parse(JSON.stringify(component.get("v.sObjectInfoFromLds")))
            component.set("v.sObjectInfoClone", mObj);
            if (mObj.RecordType == null || (mObj.RecordType && mObj.RecordType.Name !== 'Phantom Order')) {

                helper.getThresholdAmount(component, event, helper); 

            }else {  

                component.set("v.content","Do you really want to Submit this Order?");

                component.set("v.sObjectInfoClone.Sync_to_NetSuite__c", true); 

                component.set("v.showcancel",true);

                component.set("v.showok",true); 

            }
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
       
     handleClick : function(component, event, helper){
            helper.serversidesave(component, event, helper, component.get("v.sObjectInfoClone"));
                  
    },
    handleCancel : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();     
    }
})