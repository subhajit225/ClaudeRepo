({
	doInit : function(component, event, helper) {
        var url_string = window.location.href;
        var url = new URL(url_string);
        var nn = url.searchParams.get("nn");
        console.log(nn);
        if(nn != null){
            component.set("v.nodename",nn);
            component.find("nname").set("v.value",nn);
        }
        var uuid = url.searchParams.get("uuid");
        if(uuid != null){ 
            component.set("v.uuid",uuid);
            component.find("uid").set("v.value",uuid);
        }
	},
    register : function(component, event, helper) {
        var uuid = component.get("v.uuid");
        if(!uuid){
            component.set("v.nodeRes",{"error":true});
        }else{
            var action = component.get("c.registerMosacProduct");
            action.setParams({
                uuid:component.get("v.uuid")
            });
            action.setCallback(component, function(response) {
                console.log(response.getReturnValue());
                var result = response.getReturnValue();
                component.set("v.nodeRes",result);
                if(result != null && result != ''){
                    component.set("v.regString",result.regString);
                    component.set("v.regdownload",result.regdownload);
                }
                
            });
            $A.enqueueAction(action);
        }
		
	}
})