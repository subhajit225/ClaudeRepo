({
    searchHelper : function(component,event,getInputkeyWord) {
        // call the apex class method 
        var action = component.get("c.fetchLookUpValues");
        // set param to method  
        action.setParams({
            'searchKeyWord': getInputkeyWord,
            'ObjectName' : component.get("v.objectAPIName"),
            'ExcludeitemsList' : component.get("v.lstSelectedRecords")
        });
        // set a callBack    
        action.setCallback(this, function(response) {
            $A.util.removeClass(component.find("mySpinner"), "slds-show");
            var state = response.getState();
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();
                // if storeResponse size is equal 0 ,display No Records Found... message on screen.                }
                if (storeResponse.length == 0) {
                    component.set("v.Message", 'No Records Found...');
                } else {
                    component.set("v.Message", '');
                    // set searchResult list with return value from server.
                }
                component.set("v.listOfSearchRecords", storeResponse); 
            }
        });
        // enqueue the Action  
        $A.enqueueAction(action);
    },
    
    setLabelValPair : function(component, event, helper) {
        var lstSelectedRecords = component.get("v.lstSelectedRecords") || [];
        var listOfSearchRecords = component.get("v.listOfSearchRecords");
        var labelValuePairOfSelectedRecords = [];
        for(var i =0; i< lstSelectedRecords.length ; i++){
            let obj = listOfSearchRecords.find(o => o.value === lstSelectedRecords[i]);
            labelValuePairOfSelectedRecords.push(obj);
        }
        component.set("v.labelValuePairOfSelectedRecords", labelValuePairOfSelectedRecords);
    },
})