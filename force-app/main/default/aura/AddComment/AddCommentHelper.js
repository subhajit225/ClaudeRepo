({
    HelpercreateCase: function(component, event, helper) {
        this.upsertCase(component, component.get("v.newCase"), function(a) {
            component.set("v.caseObj", a.getReturnValue());
           // window.location.replace("https://support.rubrik.com/s/uploadfile?id=");
            component.set("v.casesObject", a.getReturnValue());
            console.log('a caseId 43 ====',component.get("v.casesObject").Id);
            window.location.replace("https://support.rubrik.com/s/uploadfile?id="+component.get("v.casesObject").Id);
        });
    },
    
    upsertCase : function(component, Case, callback) {
        var action = component.get("c.saveCase");
        action.setParams({ 
            "ca": Case
        });
        if (callback) {
            action.setCallback(this, callback);
        }
        $A.enqueueAction(action);
    },
    getStatusPickListValue : function(component) {

        var action = component.get("c.getCaseDetails");
         console.log('a caseId 43 ====',component.get("c.getCaseDetails"));
        action.setCallback(this, function(response) {
            var state = response.getState();
            var hasImg = false;
            if (component.isValid() && state === "SUCCESS") {

                var statusPickList = response.getReturnValue();
                component.set("v.lstCaseStatus", statusPickList);
                console.log('status picklist ::', component.get("v.lstCaseStatus"));
            }
        });
        $A.enqueueAction(action);

    }
})