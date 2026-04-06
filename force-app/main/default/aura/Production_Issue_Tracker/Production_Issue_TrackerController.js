({
    doInit: function(component, event, helper) {
        var filterCondition = "CreatedDate";
        helper.queryOrders(component, filterCondition, function(responseValue, orderIds, quoteIds, opptyIds, toggleValue) {
            console.log('orderIds: ', '(' + orderIds + ')');
            console.log('quoteIds: ' + quoteIds);
            component.set("v.quoteId", quoteIds);
            component.set("v.opptyId", opptyIds);
            helper.collection(component, helper, responseValue, toggleValue);
        });
    },
    shippedOrders: function(component, event, helper) {
        var spanElement = component.find("mySpan").getElement();
        spanElement.innerHTML = event.target.checked ? "Shipped" : "Created";
        var filterCondition = event.target.checked ? "Actual_Order_Ship_Date__c" : "CreatedDate";
        helper.queryOrders(component, filterCondition, function(responseValue, orderIds, quoteIds, opptyIds, toggleValue) {
            component.set("v.quoteId", quoteIds);
            component.set("v.orderId", orderIds);
            component.set("v.opptyId", opptyIds);
            helper.collection(component, helper, responseValue, toggleValue);
        });
    }
})