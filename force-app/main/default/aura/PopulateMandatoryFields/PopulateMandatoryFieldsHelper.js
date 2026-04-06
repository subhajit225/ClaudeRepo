({    
    fetchQuoteLines : function(component, event, helper) {
        var action = component.get("c.getQuoteLines");
        action.setParams({
            quoteId: component.get("v.recordId")
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.qlList", response.getReturnValue());
                component.set("v.isLoading", false);
            }
        });
        $A.enqueueAction(action);
    },
    
    fetchHWQuoteLines : function(component, event, helper) {
        var action = component.get("c.getHWQuoteLines");
        action.setParams({
            quoteId: component.get("v.recordId")
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.hwQlList", response.getReturnValue());
                component.set("v.isLoading", false);
            }
        });
        $A.enqueueAction(action);
    },
    
    closeEditMode: function(component, event, helper) {
        var urlString = window.location.origin;
        var quoteId = component.get("v.recordId");
        urlString = urlString + '/lightning/r/SBQQ__Quote__c/' + quoteId + '/view';
        console.log('urlStringFirst>>', urlString);
        
        if ((typeof sforce != 'undefined') && sforce && (!!sforce.one)) {
            // Do something for Lightning Experience
            component.set("v.isLoading", false);
            sforce.one.navigateToURL(urlString);
        } else {
            // Use classic Visualforce
            component.set("v.isLoading", false);
            window.location.href = urlString;
        }
    },
    
    saveLead : function(component,helper, event) {
        var action = component.get("c.updateQuoteLinesforHW");
        action.setParams({
            qlvsSelected : component.get("v.mapOfBundleIdvsAssetIds"),
            changedQLList : component.get("v.qlList"),
            quoteId: component.get("v.recordId")
        });
        action.setCallback(this,function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                //alert('Record Created Successfully!!');
                helper.closeEditMode(component, event, helper);
            } else if(state === "ERROR"){
                var errors = action.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        alert(errors[0].message);
                    }
                }
            }
        });       
        $A.enqueueAction(action);
    }
})