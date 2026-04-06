({
     doInit : function(component, event, helper) {
        var action = component.get("c.getSetupCompanyMaster");
        action.setCallback(this,function(response){
              var state = response.getState();
              if(state === "SUCCESS"){
              	  component.set("v.wcList",response.getReturnValue()); 
                  if(!$A.util.isEmpty(component.get("v.wcList"))){
                      component.set("v.profileName",component.get("v.wcList")[0].profName);
                  }	
              }else if (state === "ERROR") {
                        var errors = response.getError();
                        if (errors) {
                            if (errors[0] && errors[0].message) {
                                console.log("v.content","Error message: " + 
                                            errors[0].message);
                            }
                        } else {
                            console.log("Unknown error");
                        }
                   } 
            helper.handlesavePOC(component, event, helper);
        }); 
        $A.enqueueAction(action);
    },
	handlesavePOC : function(component, event, helper) {
        if(component.get("v.profileName") === 'Order Manager' || component.get("v.profileName") === 'Sales Operations' || component.get("v.profileName") === 'System Administrator') {
            component.set("v.sObjectInfo.POC_Returned__c ",true);
            helper.serversidesave(component, event, helper,component.get("v.sObjectInfo"));
        }else{
            helper.gotoRec(component,component.get("v.sObjectInfo.Id"));
        }
	},
   
    serversidesave : function(component, event, helper, sobjectrec){
        var action = component.get("c.saveRecord");
        action.setParams({ rec : sobjectrec });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "ERROR") {
                var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Cannot update the record",
                        "duration": 10000,
                        "type": "error",
                        "message": response.getReturnValue()
                    });
                    toastEvent.fire(); 
                	$A.get("e.force:closeQuickAction").fire(); 
            }else if (state === "SUCCESS"){
                 var str = response.getReturnValue();
                if(str.includes('Exception occurred')){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Cannot update the record",
                                "duration": 10000,
                                "type": "error",
                        "message": response.getReturnValue()
                    });
                    toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire(); 
                }else{
              		helper.gotoRec(component,component.get("v.sObjectInfo.Id"));
                }
            }
             
        });
        // Send action off to be executed
        $A.enqueueAction(action);
    },
    gotoRec : function(component, recId){
        var urlEvent = $A.get("e.force:navigateToSObject");
        urlEvent.setParams({"recordId": recId,"slideDevName": "detail"});        
        urlEvent.fire();
    }

})