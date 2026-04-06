({
	getPicklistValues: function(component, event) {
        var action = component.get("c.getIndustryFieldValue");
        action.setParams({
            objectAPIName: "SBQQ__QuoteLine__c",
            fieldAPIName: "Licensing_Model__c",
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                var fieldMap = [];
                for(var key in result){
                    if (component.get("v.prevSelection") != result[key]) {
                        fieldMap.push({key: key, value: result[key]});
                    }                    
                }
                component.set("v.fieldMap", fieldMap);
            }
        });
        $A.enqueueAction(action);
    }, 
    saveLead : function(component, event) {
        var selected = component.find("industryPicklist").get("v.value");
        var myEvent = $A.get("e.c:getDynamicPicklistValue");
            myEvent.setParams({
                selectedOption: selected,
                currentRecId: component.get("v.qlInScope")
            });
            myEvent.fire();
    }
})