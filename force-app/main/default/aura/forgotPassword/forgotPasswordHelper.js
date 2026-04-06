({
    qsToEventMap: {
        'expid'  : 'e.c:setExpId'
    },
    
    handleForgotPassword: function (component, event, helpler) {
        var username = component.find("username").get("v.value");
        var hasError = false;
        var pattern = /^([\w-\.]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([\w-]+\.)+))([a-zA-Z]{2,6}|[0-9]{1,3})(\]?)$/;
        var isResetClicked = component.get("v.isResetButtonClicked");
        
        if((username == '' || username == null)){
            hasError = true;
        }
        if(!pattern.test(username)){
            hasError = true;
        }
        if(hasError){
             component.set("v.showError",true);
             component.set("v.errorMessage",'Please enter a valid Email.');
        } else {
            if (!isResetClicked) {
                component.set("v.isResetButtonClicked", true);
                var checkEmailUrl = component.get("v.checkEmailUrl");
                var action = component.get("c.forgotCustomerPassword");
                action.setParams({username:username});
                action.setCallback(this, function(a) {
                    var rtnValue = a.getReturnValue();
                    
                    if (rtnValue != null) {
                        if (rtnValue == 'Reset Password link is send please check.') {
                            rtnValue = $A.get("$Label.c.Forgot_Password_Label");
                        }
                        
                        component.set("v.errorMessage",rtnValue);
                        component.set("v.showError",true);
                    }
                });
                $A.enqueueAction(action);
            }
        }
       
    },

    setBrandingCookie: function (component, event, helpler) {
        var expId = component.get("v.expid");
        if (expId) {
            var action = component.get("c.setExperienceId");
            action.setParams({expId:expId});
            action.setCallback(this, function(a){ });
            $A.enqueueAction(action);
        }
    }
})