({
    accessSupportPortal : function(component) {
        component.set("v.spinner", true); 
        let selectedUserName = component.get("v.selectedUserName");
        var action = component.get("c.updateUserinOktaToAccessPortal");
        action.setParams({
            userName: selectedUserName
        });
        action.setCallback(component, function(response) {
            var state = response.getState();

            let SupportMultipltUsers = JSON.parse(localStorage.getItem('SupportMultipltUsers'));
            var arrayUsers = new Map();
            if (state === "SUCCESS") {
                var resp = response.getReturnValue();
                if(resp.isGTC == 'Denied'){
                    component.set("v.isGtcAccount", true);
                }else{
                    // Iterating Existing Localstorage User values
                    SupportMultipltUsers.forEach(element => {
                        // reset other userser are Multiple_UN
                        arrayUsers.set(element[0], 'Multiple_UN');
                        if(element[0] == selectedUserName){
                            // making current UN as Selected_UN
                            arrayUsers.set(element[0], 'Selected_UN');
                        }
                    });

                    localStorage.setItem('SupportMultipltUsers', JSON.stringify(Array.from(arrayUsers.entries())));
                    var result = decodeURIComponent(resp.SAML_URL);
                    localStorage.setItem('is_mu_select', 'true');
                    window.open(result,"_self")
                }
                component.set("v.spinner", false); 
            }else if(state === "ERROR"){
                console.log('There was a problem in accessSupportPortal : '+JSON.stringify(response.getError()));
                component.set("v.spinner", false); 
            }
        });
        $A.enqueueAction(action);
    },
})