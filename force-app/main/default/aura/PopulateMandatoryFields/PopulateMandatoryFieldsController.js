({  
    getLines : function(component, event, helper) {
        component.set("v.isLoading", true);
        helper.fetchQuoteLines(component, event, helper);
        helper.fetchHWQuoteLines(component, event, helper);
    }, 
    
    LeadSave : function(component, event, helper) {
        helper.saveLead(component,helper, event);
    },
    
    getValueFromApplicationEvent : function(component, event) {
        var ShowResultValue = event.getParam("selectedOption");
       	var bundleRecordId = event.getParam("currentRecId");
        if (bundleRecordId != undefined && bundleRecordId != undefined  != '' && bundleRecordId != undefined != null) {
            var newMap = component.get("v.mapOfBundleIdvsAssetIds");
            newMap[bundleRecordId] = ShowResultValue;
            component.set("v.mapOfBundleIdvsAssetIds", newMap);
        }   
    },
})