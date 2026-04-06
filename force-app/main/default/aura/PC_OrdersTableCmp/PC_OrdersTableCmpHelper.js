({
    getColumnDefinitions: function () {
        var columns = [
            {label: 'Order Number', fieldName: 'orderNumber', type: 'string', sortable : true, cellAttributes: { class: 'custom-column'}},
            {label: 'Distributor PO Number', fieldName: 'distributorPONumber', type: 'text', sortable : true, typeAttributes: {label: { fieldName: 'Name' }, target: '_self'},cellAttributes: { class: 'custom-column'}},
            {label: 'End User PO Number', fieldName: 'endUserPoNumber', type: 'text', sortable : true, cellAttributes: { class: 'custom-column'}},
            {label: 'Order Status', fieldName: 'status', type: 'text', sortable : true, cellAttributes: { class: 'custom-column'}},
            {label: 'Estimated Ship Date', fieldName: 'estShipDate', type: 'date-local', sortable : true, cellAttributes: { class: 'custom-column'}},
            {label: 'Actual Order Ship Date', fieldName: 'actualOrderShipDate', type: 'date-local', sortable : true, cellAttributes: { class: 'custom-column'}},
            {label: 'Shipping Carrier', fieldName: 'shippingCarrier', type: 'text', sortable : true, cellAttributes: { class: 'custom-column'}},
            {label: 'Tracking No.', fieldName: 'trackingNo', type: 'text', sortable : true, cellAttributes: { class: 'custom-column'}},
            {label: 'Tracking Link', fieldName: 'trackingLink', type: 'url', typeAttributes: { label: { fieldName: 'shippingCarrier' }, target: '_blank' }, cellAttributes: { class: 'custom-column'}}
        ];
        return columns;
    },
    /* Get Orders list to show the distributors */
    getOrdersList : function(component, event,helper) {
        
        var params = {
            "poNumber" : component.get("v.distributorPO"),
            "endUserPO" : component.get("v.endUserPO"),
            "orderNumber" : component.get("v.rubrikSO"),
            "pageSize": component.get("v.initialRows"),
            "pageNumber": component.get("v.rowNumberOffset")
        };
        /*
        var params = {
            "poNumber" : component.get("v.distributorPO"),
            "endUserPO" : component.get("v.endUserPO"),
            "orderNumber" : component.get("v.rubrikSO"),
            "pageSize" : component.get("v.pageSize"),
            "pageNumber" : component.get("v.pageNumber")
        };*/
        
        //alert(component.get("v.rubrikSO"));
        helper.callServer(component, "c.getOrdersList",params,function(response){ 
           
            if(!$A.util.isEmpty(response)){
                component.set("v.ordersWrap",response);
                //Console.log('response.totalRecords');
                component.set("v.data",response.lstOrders);
                component.set("v.totalRecords",response.totalRecords);
                component.set("v.totalNumberOfRows",response.totalRecords);
                component.set("v.totalPages",response.totalPages);                            
            }else{
                component.set("v.ordersList",[]);
                component.set("v.totalRecords",0);
                component.set("v.totalPages",0);
            }
            component.set("v.currentCount", component.get("v.initialRows"));
        },false);
    } ,
    sortData: function (cmp, fieldName, sortDirection) {
        var data = cmp.get("v.data");
        var reverse = sortDirection !== 'asc';
        //sorts the rows based on the column header that's clicked
        data.sort(this.sortBy(fieldName, reverse))
        cmp.set("v.data", data);
    },
    sortBy: function (field, reverse, primer) {
        var key = primer ?
            function(x) {return primer(x[field])} :
        function(x) {return x[field]};
        //checks if the two rows should switch places
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    },
    fetchData: function(component , rows){
        return new Promise($A.getCallback(function(resolve, reject) {
           /* 
            var params = {
                "poNumber" : component.get("v.distributorPO"),
                "endUserPO" : component.get("v.endUserPO"),
                "orderNumber" : component.get("v.rubrikSO"),
                "pageSize" : component.get("v.pageSize"),
                "pageNumber" : component.get("v.pageNumber")
            };
            
            helper.callServer(component, "c.getOrdersList",params,function(response){
                resolve(response);
                if(!$A.util.isEmpty(response)){
                    component.set("v.ordersWrap",response);
                    component.set("v.data",response.lstOrders);
                    component.set("v.totalRecords",response.totalRecords);
                    component.set("v.totalPages",response.totalPages);                            
                }else{
                    component.set("v.ordersList",[]);
                    component.set("v.totalRecords",0);
                    component.set("v.totalPages",0);
                }
                var countstemps = component.get("v.currentCount");
                countstemps = countstemps+component.get("v.initialRows");
                component.set("v.currentCount",countstemps);
            },false);
            */
                                  
            var currentDatatemp = component.get('c.getOrdersList');
            var counts = component.get("v.currentCount");
            currentDatatemp.setParams({
                "poNumber" : component.get("v.distributorPO"),
                "endUserPO" : component.get("v.endUserPO"),
                "orderNumber" : component.get("v.rubrikSO"),
                "pageSize": component.get("v.initialRows"),
            	"pageNumber": component.get("v.rowNumberOffset")
            });
            
            currentDatatemp.setCallback(this, function(a) {
                var response = a.getReturnValue();
                resolve(response.lstOrders);
                var countstemps = component.get("v.currentCount");
                countstemps = countstemps+component.get("v.initialRows");
                component.set("v.currentCount",countstemps);
            });
            $A.enqueueAction(currentDatatemp);
        }));        
    }     
})