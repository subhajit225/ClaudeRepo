({
    doInit : function(component, event, helper) {
        var colString = $A.get("$Label.c.qlPromoRelatedListColumn");
        const columns = JSON.parse(colString);
        component.set('v.columns',columns);        
        var action = component.get("c.getQuoteLines");
        action.setParams({
            quoteId: component.get("v.recordId")
        });
        
        

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var data = response.getReturnValue();
                const jsonArray = JSON.parse(data).map(item => JSON.parse(item));
                component.set("v.data", jsonArray);
                var name = 'Prior Promo Details ('+component.get("v.data").length+')';
                component.set("v.name", name);
                console.log(component.get("v.name"));
            } else if (state === "ERROR") {
                console.error('Error fetching quote lines:', response.getError());
            }
        });

        $A.enqueueAction(action);
    }
})