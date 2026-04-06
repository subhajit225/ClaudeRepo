({
    doinit : function(component,event){
        var action = component.get("c.hideShowCalendly");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.showCalendly", response.getReturnValue());
            } else {
                console.log("Error: " + response.getError());
            }
        });
        $A.enqueueAction(action);
    },
    TabsVisible : function(cmp,event){
        var userRecord = cmp.get("v.UserRecord");
        var calendlyURl = $A.get("$Label.c.Calendly_Link")+'&email='+userRecord.Email+'&name='+userRecord.Name+'&a4='+userRecord.Account.Name;
        cmp.set("v.calendlyURl",calendlyURl);
        var visibiltyTabs = cmp.get("v.UserRecord.Account.Tabs_Visibility__c");  
        if(visibiltyTabs != null){
            console.log(visibiltyTabs);
            if(visibiltyTabs.includes('Training')){
                cmp.set("v.showTraining",true); 
            }
            if(visibiltyTabs.includes('Forums')){
                cmp.set("v.showForums",true); 
            }
        }
        cmp.set("v.showMenu",true);
    }
})