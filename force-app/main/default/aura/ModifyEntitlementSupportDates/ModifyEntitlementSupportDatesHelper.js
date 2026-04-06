({
    handleOnSubmit : function(component, event, helper) { 
        //Comment here
        if(component.get("v.showSpinner")) return;
        var entSupRec = component.get("v.entitlementSupportRec");
        var entSupRecClone = component.get("v.entitlementSupportRecClone");
        var eventFields = event.getParam("fields"); //get the fields
        eventFields.Cluster__c = component.get("v.clusterid");//entSupRecClone.Cluster__c;
        var isAnyFieldChanged = false;
        if(entSupRec){
            for (var key in eventFields) {
                if (entSupRec[key] != eventFields[key] ) {
                    isAnyFieldChanged = true;
                }
            }
        }
        eventFields.Entitlement__c= component.get("v.recordId");
        if(!isAnyFieldChanged && entSupRec){
            component.set("v.isReadOnly", true);
            return;
        }
        helper.createRec(component, event, helper, eventFields );
    },
    createRec : function(component, event, helper, fields) {
        component.set("v.callcluster", false);
        
        component.set("v.showSpinner", true);
        var action = component.get("c.createEntitlementSupportRec");
        action.setParams({
            "req": fields
        });
        action.setCallback(this, function(response) {
            if (response.getState() === "ERROR") {
                component.set("v.showSpinner", false);
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && ( errors[0].message || errors[0].pageErrors)) {
                        helper.showToast(errors[0].message + errors[0].pageErrors , 'error');
                    }
                    return;
                }
            }
            var data = response.getReturnValue();
            if(!data.isSuccess){
                component.set("v.showSpinner", false);
                helper.showToast(data.errorMessage , 'error');
                return;
            }
            $A.get('e.force:refreshView').fire();  
            var quoteQuery = 'select Id,StartDate,EndDate,AccountId,(select  Id,Start_Date__c,End_Date__c,createdDate,Warranty_Status__c,Warranty_Compliant__c,CEM_Notes__c,CEM_Health_Check_Date__c,Entitlement__c,Entitlement__r.AccountId,Entitlement__r.StartDate,Entitlement__r.EndDate, Cluster__c,Cluster__r.Name from Entitlement_Warrenty_Details__r order by createddate Desc limit 1) from entitlement where  Id = \''+ component.get("v.recordId") + '\'';
            helper.executeQuery(component, event, helper, quoteQuery, 'entitlementSupportRec');
        });
        $A.enqueueAction(action)
    },
    executeQuery : function(component, event, helper, query, attributeName) {
        component.set("v.isReadOnly", true);
        component.set("v.showSpinner", true);
        component.set("v."+attributeName, null);
        var action = component.get("c.executeQuery");
        action.setParams({
            "theQuery": query
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state == "SUCCESS" && component.isValid()){
                var queryResult = response.getReturnValue();
                component.set("v.entitlementRec", JSON.parse(JSON.stringify(queryResult[0])));
                if(queryResult[0].hasOwnProperty('Entitlement_Warrenty_Details__r')){
                component.set("v."+attributeName, queryResult[0].Entitlement_Warrenty_Details__r[0]);
                }
                if(!queryResult[0]){
                    queryResult[0] = {};
                }
                if(queryResult[0].hasOwnProperty('Entitlement_Warrenty_Details__r')){
                component.set("v.entitlementSupportRecClone", JSON.parse(JSON.stringify(queryResult[0].Entitlement_Warrenty_Details__r[0])));
                }else{
                component.set("v.entitlementSupportRecClone", JSON.parse(JSON.stringify(queryResult[0])));
                }
				if(component.get("v."+attributeName)!= null && component.get("v."+attributeName).Cluster__c != null){
                	component.set("v.clusterid",component.get("v."+attributeName).Cluster__c);
                    component.set("v.searcht",component.get("v."+attributeName).Cluster__r.Name );
                    component.set("v.selectedLabel",component.get("v."+attributeName).Cluster__r.Name);
                }
                var clustercall = component.get("v.callcluster");
                if(clustercall){
                        component.set("v.accountId",queryResult[0].AccountId);
                        if(component.get("v.accountId")!=null ){
                            var queryforClusters = 'Select id,name from Cluster__c where  account__c = \''+ component.get("v.accountId") + '\''+ ' order by createddate Desc ';
                            helper.executeQueryGenericMethod(component, event, helper, queryforClusters);     
                        }
                }
                
                
            }
            else{
                console.error("fail:" + response.getError()[0].message);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error",
                    "duration": 10000,
                    "type": "error",
                    "message": "Something went wrong in your org: " + response.getError()[0].message
                });
                toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire();
            }
        });
        $A.enqueueAction(action);
    },
    executeQueryGenericMethod : function(component, event, helper,query) {
        component.set("v.showSpinner", false);

        var searchedString = component.get("v.searchString");
        var action = component.get("c.executeQuery");
        action.setParams({
            "theQuery": query
        });  
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var queryResult = response.getReturnValue();
                console.log('queryResult is ##### ' + JSON.stringify(queryResult));
                component.set("v.showSpinner", true);

                component.set("v.options", JSON.parse(JSON.stringify(queryResult)));
            }                
            
        });
        $A.enqueueAction(action);
    },
    gotoRec : function(component, recId){
        $A.get("e.force:closeQuickAction").fire();
        var workspaceAPI = component.find("workspace");
        workspaceAPI.isConsoleNavigation().then(function(isConsole) {
            if (isConsole) {
                workspaceAPI.openTab({
                    pageReference: {
                        "type": "standard__recordPage",
                        "attributes": {
                            "recordId": recId,
                            "actionName":"view"
                        },
                        "state": {}
                    },
                    focus: false
                }).then(function(response) {
                    /*workspaceAPI.getTabInfo({
tabId: response
}).then(function(tabInfo) {
workspaceAPI.getFocusedTabInfo().then(function(response) {
var focusedTabId = response.tabId;
workspaceAPI.closeTab({tabId: focusedTabId});
})
.catch(function(error) {
console.log(error);
});
});*/
}).catch(function(error) {
    console.log(error);
});
} else {
    var navEvt = $A.get("e.force:navigateToSObject");
    navEvt.setParams({
        "recordId": recId,
        "slideDevName": "detail"
    });
    navEvt.fire();
}
})
.catch(function(error) {
    $A.get('e.force:refreshView').fire();
});
}
})