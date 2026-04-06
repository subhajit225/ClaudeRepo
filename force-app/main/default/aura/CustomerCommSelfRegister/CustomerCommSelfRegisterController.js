({
	myAction : function(component, event, helper) {

	},
    handleRegister : function(component, event, helper) {
        helper.fetchAccountGtc(component,event,helper);
	},
    closeModal : function(component, event, helper){
    	component.set("v.showError",false);
        component.set("v.isDeniedAccount",false);
        component.set("v.phone","");
        component.set("v.lastName","");
        component.set("v.firstName","");
        component.set("v.Email","");
        component.set("v.title","");
        component.set("v.hasError",false);
        component.set("v.invalidEmail",false);
        component.set("v.invalidPhone",false);
    },
    onEmailChange:function(component, event, helper){

         var email = component.get("v.Email");

         var pattern = /^([\w-\.]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([\w-]+\.)+))([a-zA-Z]{2,80}|[0-9]{1,3})(\]?)$/;
       if(!pattern.test(email)){
            component.set("v.invalidEmail",true);

       }else{
           component.set("v.invalidEmail",false);
       }
    },
})