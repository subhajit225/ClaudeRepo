({
	doinit : function(component, event, helper) {
		var action = component.get("c.getDomains");
        action.setCallback(this,function(res){
            component.set("v.domainList",res.getReturnValue());
        });
        $A.enqueueAction(action);
    },
    addDomain : function(component, event, helper){
        var inputDomain = component.find("domainEnter");
        if(inputDomain.checkValidity() && !!inputDomain.get("v.value")){
           var domain = inputDomain.get("v.value");
            var updateddomainList = component.get("v.updateddomainList");
            var domains=  component.get("v.domainList");
            var api = domain.trim();
            api = api.replace('.','_');
            var data = {
                'domainName':domain,
                'domainMethod':'ADD',
                'domainAPI':api
            };
            var domainString =  JSON.stringify(domains);
            domainString +=  JSON.stringify(updateddomainList);
            if(domainString.includes(api)){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "This domain already exist."
                });
                toastEvent.fire();
            }else{
                updateddomainList.push(data);
                component.set("v.updateddomainList",updateddomainList);
            } 
        }
        
        
    },
    removeDomain : function(component, event, helper){
        var index = event.getSource().get("v.name");
        var domains=  component.get("v.domainList");
        var domain = domains[index];
        domain.domainMethod = 'REMOVE';
        domains.splice(index, 1);
        var updateddomainList = component.get("v.updateddomainList");
        updateddomainList.push(domain);
        component.set("v.updateddomainList",updateddomainList);
        component.set("v.domainList",domains);
    },
    removeDomainNew : function(component, event, helper){
        var index = event.getSource().get("v.name");
        var updateddomainList = component.get("v.updateddomainList");
        updateddomainList.splice(index, 1);
        component.set("v.updateddomainList",updateddomainList);
    },
    updateDomains : function(component, event, helper){
        component.find("updateBtn").set("v.disabled",true);
        var action = component.get("c.addDomains");
        action.setParams({
            'updatedDomains' : component.get("v.updateddomainList")
        });
        action.setCallback(this,function(res){
            $A.get('e.force:refreshView').fire();
        });
        $A.enqueueAction(action);
        
    }
})