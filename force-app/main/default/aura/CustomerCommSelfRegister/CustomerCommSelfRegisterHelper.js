({
    fetchAccountGtc: function (component, event, helper) {
        component.set("v.spinner", true); 
        var email = component.get("v.Email");
        var action = component.get("c.getAccountGTC");

        let currentTime = new Date();
        currentTime = currentTime.toLocaleTimeString();
        action.setParams({
            domainname : email.split('@')[1],
            timestamp : currentTime
        });
        action.setCallback(this, function(resp){
            console.log('resp:: ', resp.getState());
            if(resp.getState() === 'SUCCESS'){
                var res = resp.getReturnValue();
                console.log('res:: ', res);
                if(res == 'Denied'){
                    component.set("v.isDeniedAccount",true);
                    component.set("v.spinner", false); 
                    return;
                }else{
                    // Check Validation 
                    this.checkValidation(component, event, helper);
                }
            }else if (resp.getState() === "ERROR") {
                var errors = resp.getError();
                if (errors
                    && errors[0] 
                    && errors[0].message) {
                        component.set("v.spinner", false); 
                        console.log("Error message for Account GTC: " +errors[0].message);
                }
            }
        
        });
        $A.enqueueAction(action);
    },
    checkValidation : function(component, event, helper){
        component.set("v.stopRegister",true);
        var lastName = component.get("v.lastName");
        var firstName = component.get("v.firstName");
        var email = component.get("v.Email");
        var title = component.get("v.title");
        var phone = component.get("v.phone");
        var info = component.get("v.information");
        var action = component.get('c.validateLoginInfo');
        var hasError = false;
        if(component.get("v.hasMultipleAcc")){
            if(info == '' || info == null){
                hasError = true;
            }else{
                component.set("v.hasMultipleAcc",false);
            }
        }
        if(firstName == '' || firstName == null){
            hasError = true;
        }
        if(lastName == '' || lastName == null){
            hasError = true;
        }

        var pattern = /^([\w-\.]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([\w-]+\.)+))([a-zA-Z]{2,80}|[0-9]{1,3})(\]?)$/;
        if((email == '' || email == null)){
            hasError = true;
        }
      if(!pattern.test(email)){
            component.set("v.invalidEmail",true);
            hasError = true;
       }
        if(title == '' || title == null){
            hasError = true;
        }
        var intRegex = /^[+]?([0-9]*[\.\s\-\(\)]|[0-9]+){3,24}$/;
        if(phone == '' || phone == null || !intRegex.test(phone)){
            hasError = true;
        }
        if(!intRegex.test(phone)){
            component.set("v.invalidPhone",true);
        }
        if(hasError){
            component.set("v.hasError",hasError);
            component.set("v.stopRegister",false);
        }else{
            action.setParams({
                'Email' : component.get('v.Email'),
                'firstName' : component.get('v.firstName'),
                'lastName' : component.get('v.lastName'),
                'title' : component.get('v.title'),
                'phone' : component.get('v.phone'),
                'externalKey' : component.get('v.information')
            });
            action.setCallback(this, function(result){
                var caseResult = result.getReturnValue();
                if(caseResult == 'hasDuplicateRecord'){
                    component.set("v.stopRegister",false);
                    component.set("v.hasMultipleAcc",true);
                }else{
                    component.set("v.errorMessage",result.getReturnValue());
                    component.set("v.showError",true);
                    component.set("v.stopRegister",false);
                }
            });
            $A.enqueueAction(action);
            $A.util.addClass(component.find('editmodalwindow1'), 'slds-fade-in-open');
        	$A.util.addClass(component.find('backdrop'), 'slds-backdrop_open');
        }
        component.set("v.spinner", false); 
    },
})