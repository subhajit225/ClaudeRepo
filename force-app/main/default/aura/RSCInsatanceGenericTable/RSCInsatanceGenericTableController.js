({
    doInit : function(component, event, helper) {       
        // If data is passed from the parent
        if (component.get("v.isPortal") === true) {
            return;
        }
        var action = component.get("c.getInitialData");        
        action.setParams({ 
            recordId : component.get("v.recordId") 
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                var records = result.dataList;
                var columns = result.columns;
                // Update the visibility flag first
                component.set("v.isPortal", result.isPortalView);
                component.set("v.isVisible", result.isVisible);
                component.set("v.isPartenerDistributorAcc", result.isPartenerDistributorAccRecType);
                component.set("v.sObjectOfID", result.sObjectOfID);

                // Data is already flattened by Apex (SDPEndUser_Name, PrimaryAccount_SDP)
                // Only handle URL formatting for lookup fields
                records.forEach(function(row) {
                    if (row.AccountId__c) {
                        row.AccountId__c = '/' + row.AccountId__c;
                    }
                    if (row.SDPEndUser__c) {
                        row.SDPEndUser__c = '/' + row.SDPEndUser__c;
                    }                    
                    if (row.RSCAccountTypeLabel__c) {
                        row.RSCAccountType__c = row.RSCAccountTypeLabel__c;
                    }
                    if (row.Id) {
                        row.Id = '/' + row.Id;
                    }
                });
                component.set("v.columns", result.columns);
                component.set("v.data", records);

                if(records.length < 6 && records.length > 0){
                    var currentState = component.get("v.isExpanded");
                    component.set("v.isExpanded", !currentState);
                }

                columns.forEach(function(row) {
                    if (row.label && row.label == "MSP") {
                        component.set("v.isMSPCustomer", true);
                    }
                });

            } 
        });

        $A.enqueueAction(action);
    },
    toggleTable : function(component, event, helper) {
        var currentState = component.get("v.isExpanded");
        component.set("v.isExpanded", !currentState);
    }
})