({
	handlesaveOrder : function(component, event, helper) {
        var action = component.get("c.sendemailToFlash");
        action.setParams({
            'orderId': component.get("v.sObjectInfo.Id")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                if(response.getReturnValue() == true){
                    component.set("v.content","Email sent successfully");
                    component.set("v.showok",true);
                }else{
                    component.set("v.content","Sending failed");
                    component.set("v.showok",true);
                }
            }else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        component.set("v.content","Error message: " + 
                                      errors[0].message);
                        component.set("v.showok",true);
                    }
                } else {
                    component.set("v.content","Unknown error");
                    component.set("v.showok",true);
                }
            }
        });
        $A.enqueueAction(action);

       
	},
})