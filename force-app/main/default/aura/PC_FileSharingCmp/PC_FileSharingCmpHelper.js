({
	 saveRecord : function(component, event,helper) { 
        helper.showSpinner(component);
        var action = component.get("c.saveRecord");
        var rec = component.get("v.simplefileSharing");
        
        console.log(rec);
        action.setParams({
            "rec": rec,
            accRecords : component.get("v.selectedAccountRecords"),
            cpRecords : component.get("v.selectedChannelProgramRecords"),
            cplRecords : component.get("v.selectedChannelProgramLevelRecords")
        });
        
        action.setCallback(this, function(response) { 
            var saveResult = response.getState();
            helper.hideSpinner(component); 
            if(response.getState() === "SUCCESS") { 
                var result = response.getReturnValue();
                var resultsToast = $A.get("e.force:showToast");
                if(result.includes('Exception occurred')){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Cannot update the record",
                        "duration": 10000,
                        "type": "error",
                        "message": response.getReturnValue()
                    });
                    toastEvent.fire();
                }else{
                    helper.gotoRec(component,result);
                }
            }else if (response.getState() === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
                var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "title": "Cannot update the record",
                    "duration": 10000,
                    "type": "error",
                    "message": response.getReturnValue()
                });
                resultsToast.fire();
            }           
        }); 
        
        $A.enqueueAction(action); 
    } ,

    showSpinner: function (component, event, helper) {
        var spinner = component.find("mySpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },
    
    hideSpinner: function (component, event, helper) {
        var spinner = component.find("mySpinner");
        $A.util.addClass(spinner, "slds-hide");
    },
    gotoRec : function(component, recId){
       window.parent.location ='/one/one.app#/sObject/' + recId+ '/view';

            },
})