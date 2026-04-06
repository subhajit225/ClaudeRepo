({
    getUserDetails : function(component, event) { 
        var action = component.get("c.getUserDetails"); 
        
        action.setCallback(this, function(response) { 
            if(response.getState() === "SUCCESS") { 
                var partner = response.getReturnValue();
                
                if(!$A.util.isEmpty(partner.Contact)) {
                    if(partner.Contact.Account.Type == "Reseller"){
                        partner.Contact.Account.Type = "Reseller";
                    }else if(partner.Contact.Account.Type == "MSP-Reseller"){
                        partner.Contact.Account.Type ="MSP-Reseller";
                    }
                }
                component.set("v.user", response.getReturnValue());                
            }            
        }); 
        
        $A.enqueueAction(action); 
    } ,
})