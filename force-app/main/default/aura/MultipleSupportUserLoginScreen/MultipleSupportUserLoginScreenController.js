({
    handleUsernameChange : function(component, event, helper) {
        var userName = component.find('username').get('v.value')
        component.set("v.selectedUserName", userName);
        component.set("v.spinner", true); 
        var action = component.get("c.checkForExpiredEntitlement");
        action.setParams({
            userName: userName
        });
        action.setCallback(component, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var resp = response.getReturnValue();
                console.log('resp:: '+resp); 
                
                // error for Expired Entitlement / Opportunity status Stage 7
                if(resp){
                    component.set("v.isExpiredEntitlement", resp)
                    component.set("v.disableBtn", true)
                }else{
                    if(userName){
                        component.set("v.disableBtn", false)
                    }else{
                        component.set("v.disableBtn", true)
                    }
                }
                component.set("v.spinner", false); 
            }else if(state === "ERROR"){
                console.log('There was a problem in handleUsernameChange : '+JSON.stringify(response.getError()));
                component.set("v.spinner", false); 
            }
        });
        $A.enqueueAction(action);
    },
    
    closeModal : function(component, event, helper){
    	component.set("v.isExpiredEntitlement",'');
    },

    handleLogin : function(component, event, helper) {
        helper.accessSupportPortal(component);
    },

    handleLogout : function(component) {
        let communityBaseUrl = $A.get("$Label.c.Community_Base_URL").split('/s/');
        let encodedBaseUrl = encodeURI(communityBaseUrl);
        window.location.replace(communityBaseUrl[0]+"/secur/logout.jsp?retUrl="+encodedBaseUrl+"login");
    },
})