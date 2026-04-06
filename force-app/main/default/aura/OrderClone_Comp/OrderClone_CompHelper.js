({
    handleOnSubmit : function(component, event, helper) {        
        component.set("v.showConfirmDialogBox", true);
        var action = component.get("c.createClonedRecord");
        var recordId = component.get("v.recordId");        
        action.setParams({
            "parentId": recordId
        });
        component.set("v.spinner", true); 
        action.setCallback(this, function(response) {
            component.set("v.spinner", false); 
            if (response.getState() === "ERROR") {
                component.set("v.showSpinner", false);
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && ( errors[0].message || errors[0].pageErrors)) {
                        helper.showToast(errors[0].message + errors[0].pageErrors , 'error');
                    }
                    return;
                }
            }
            var data = response.getReturnValue();
            if(!data.isSuccess){
                component.set("v.showSpinner", false);
                helper.showToast(data.errorMessage , 'error');
                return;
            }
            /*var state = response.getState();
             var navEvt; 
            if(state == "SUCCESS"){*/
                var custs = [];
                var conts = response.getReturnValue();
                /*alert('===='+JSON.stringify(response.getReturnValue()));
                console.log('log====='+JSON.stringify(response.getReturnValue()));
               
                for ( var key in conts ) {                    
                    if(key=="newOrderId"){
                        component.set("v.newOrderRecordId", conts[key]);
                    }
                    custs.push({value:conts[key], key:key});
                }   */
                component.set("v.newOrderRecordId", conts.newOrderId);
             var navEvt;
                navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": component.get("v.newOrderRecordId"),
                        "slideDevName": "detail"
                    });
                    navEvt.fire();
                  
            
        });        
        $A.enqueueAction(action);
    }
    
})