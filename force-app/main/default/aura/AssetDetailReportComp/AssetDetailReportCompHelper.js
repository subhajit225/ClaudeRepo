({
    fetchAccHelper : function(component, event, helper) {       
        component.set('v.mycolumns', [
            {label: 'Account Name', fieldName: 'AccountName', type: 'text'},
                {label: 'Asset Name', fieldName: 'AssetName', type: 'text'},
                {label: 'Product Name', fieldName: 'ProductName', type: 'text'},
            	{label: 'Sales Order', fieldName: 'OrderNumber', type: 'text'},
                {label: 'Purchase Date', fieldName: 'PurchaseDate', type: 'url '},
                {label: 'Quote Number', fieldName: 'QuoteNumber', type: 'url '},
                {label: 'orderItemNumber', fieldName: 'orderItem', type: 'url',typeAttributes: {label: { fieldName: 'OInumber' }, target: '_blank'}}
            ]);
        var action = component.get("c.fetchAssetsWithOrderLines");
        action.setParams({
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var records =response.getReturnValue();
                records.forEach(function(record){
                    console.log('record is ' + JSON.stringify(record));
                    record.orderItem = '/'+record.orderItemId;
                });

                component.set("v.records", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    }
})