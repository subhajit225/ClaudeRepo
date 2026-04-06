({ 
    HelpercreateCase: function(component, event, helper) {
        this.upsertCase(component, component.get("v.newCase"), function(a) {
            component.set("v.caseObj", a.getReturnValue());
           // window.location.replace("https://supfullsb-rubrik.cs14.force.com/CustomerSupport/s/uploadfile?id=");
            component.set("v.casesObject", a.getReturnValue());
            //console.log('a caseId 43 ====',a.getReturnValue());
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
        // console.log('a caseId 43 ====',component.get("c.getCaseDetails"));
        action.setCallback(this, function(response) {
            var state = response.getState();
            var hasImg = false;
            if (component.isValid() && state === "SUCCESS") {

                var statusPickList = response.getReturnValue();
                component.set("v.lstCaseStatus", statusPickList);
               // console.log('status picklist ::', component.get("v.lstCaseStatus"));
            }
        });
        $A.enqueueAction(action);

    },
    getRSCUrl: function(component) {
        let myCase = component.get("v.myCase");    
        let url = myCase && myCase.RSCInstance__r ? myCase.RSCInstance__r.RSCUrl__c : null;
                
        if (!url.startsWith('http://') && !url.startsWith('https://')) {
            var calculatedUrl = 'https://' + url;
            component.set("v.safeRSCUrl", calculatedUrl);
        }
        
        return url;
    }
})