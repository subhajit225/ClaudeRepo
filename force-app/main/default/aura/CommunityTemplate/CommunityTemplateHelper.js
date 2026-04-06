({
    getMultipleUsers : function(component) {
        var action = component.get("c.fetchMultipleUsers");
        action.setCallback(component, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                
                component.set("v.userNameList", result);
                if(result[0]
                    && result[0].Contact.Account.GTC__c == 'Denied'){
                        component.set("v.isGtcAccount", true);
                }
                else if(result.length > 1){
                    component.set("v.isMultipleUsersExists", true);

                    var arrayUsers = new Map();

                    // When Portal Loading after UN Selection, and Selected UN found, below var will be true to lead Selected User into Portal 
                    let isDisplayMultipleUserDropDown = true;
                    result.forEach(element => {
                        arrayUsers.set(element.Username, 'Multiple_UN');
                        // fetch stored local storage
                        let SupportMultipltUsers = JSON.parse(localStorage.getItem('SupportMultipltUsers'));
                        if(SupportMultipltUsers
                            && SupportMultipltUsers.length == result.length){
                                SupportMultipltUsers.forEach(localEle => {
                                    if(localEle[0] == element.Username
                                        && localEle[1] == 'Selected_UN'){
                                        // For Multiple User: When Selected User already created session login into portal
                                        isDisplayMultipleUserDropDown = false;
                                        // When new tab is opened from Portal, keeping selected_UN in current session 
                                        arrayUsers.set(element.Username, 'Selected_UN');
                                    }
                                });
                        }
                    });
                    component.set("v.displayMultipleUserDropDown", isDisplayMultipleUserDropDown);
                    
                    // Local storage
                    localStorage.setItem('SupportMultipltUsers', JSON.stringify(Array.from(arrayUsers.entries())));
                    let SupportMultipltUsers = JSON.parse(localStorage.getItem('SupportMultipltUsers'));
                    console.log('SupportMultipltUsers final: ', SupportMultipltUsers);
                }else if(result.length == 1
                        && result[0]
                        && result[0].Contact.Account.GTC__c == 'Denied'){
                            component.set("v.isGtcAccount", true);
                }

            }else if(state === "ERROR"){
                console.log('There was a problem in getMultipleUsers : '+JSON.stringify(response.getError()));
            }
        });
        $A.enqueueAction(action);
    },
})