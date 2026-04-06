({
    doInit : function(component, event, helper) {        
        component.set('v.columns', helper.getColumnDefinitions());
        helper.getOrdersList(component, event,helper); 
    },
    
    handleSearch : function(component, event, helper) {
        component.set("v.initialRows",20);
        component.set("v.rowNumberOffset",0);
        helper.getOrdersList(component, event,helper);
    },   
    loadMoreData: function (component, event, helper) {
        //Display a spinner to signal that data is being loaded
        event.getSource().set("v.isLoading", true);
        //Display "Loading" when more data is being loaded
        component.set('v.loadMoreStatus', 'Loading');
        helper.fetchData(component, component.get('v.rowsToLoad')).then($A.getCallback(function (data) {
            if (component.get('v.data').length >= component.get('v.totalNumberOfRows')) {
                component.set('v.enableInfiniteLoading', false);
                component.set('v.loadMoreStatus', 'No more data to load');
            } else {
                var currentData = component.get('v.data');
                //Appends new data to the end of the table
                var newData = currentData.concat(data);
                component.set('v.data', newData);
                component.set('v.loadMoreStatus', 'Please wait ');
            }
            event.getSource().set("v.isLoading", false);
        }));
    },
    
    // Client-side controller called by the onsort event handler
    updateColumnSorting: function (cmp, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        // assign the latest attribute with the sorted column fieldName and sorted direction
        cmp.set("v.sortedBy", fieldName);
        cmp.set("v.sortedDirection", sortDirection);
        helper.sortData(cmp, fieldName, sortDirection);
    },
})