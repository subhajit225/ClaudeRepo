({
	handleForgotPassword : function (component, event, helper) {
        //var username = component.get("v.username");
        var username = document.getElementById("userEmailId").value;
        
        console.log('usr@@'+username);
        var hasError = false;
        var pattern = /^([\w-\.]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([\w-]+\.)+))([a-zA-Z]{2,6}|[0-9]{1,3})(\]?)$/;
        if((username == '' || username == null)){
            hasError = true;
        }
        if(!pattern.test(username)){
            hasError = true;
        }
        if(hasError){
             component.set("v.showValidationError",true);
             component.set("v.errorMessage",'Please enter a valid Email : '+username);
        } else {
            
            var action = component.get("c.handleforgotPassword");
            action.setParams({emailId : username});
            action.setCallback(this, function(a) {
                var rtnValue = a.getReturnValue();
                if (rtnValue != null) {
                    component.set("v.errorMessage",rtnValue);
                    component.set("v.showError",true);
                }
            });
            $A.enqueueAction(action);
        }
    },

})