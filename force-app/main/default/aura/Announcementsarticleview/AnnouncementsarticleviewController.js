({ 
    doInit : function(component, event, helper) {
        var url_string = window.location.href
        var url = new URL(url_string);
        var Id = url.searchParams.get("Id");
        component.set("v.portId",Id);
        var action = component.get("c.getPortalDetailNews");
        action.setParams({
            "recordId":Id
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            component.set("v.newsList", response.getReturnValue());
            let recordTypeName = response.getReturnValue().RecordType.Name;
			
            if (recordTypeName && recordTypeName == 'Forums') {
                component.set("v.isForums", true);
            } else {
                component.set("v.isForums", false);
            }
        });
        $A.enqueueAction(action);
    },
    redirect: function(component, event, helper){
        window.history.back();
        return false;
    }
})