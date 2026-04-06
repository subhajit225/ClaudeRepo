({
    createCSVObject : function(cmp, csv) {
        var action = cmp.get('c.getCSVObject');
        action.setParams({
            csv_str : csv 
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state == "SUCCESS") {
		        
                var errorMsg = '';

                if(response.getReturnValue().lstOrders == undefined){
                    errorMsg = 'Please upload the CSV with correct headers. Following are the correct headers: "Order ID", Order Number", "Fulfilled in QTR", "Current Est Ship Date", "Est Delivery Date".';
                }else if(response.getReturnValue().lstOrders.length == 0){
                    errorMsg = 'This CSV file does not contain the proper data. Please upload the correct file.';
                }else if(response.getReturnValue().setDupOrds.length > 0){
                    errorMsg = 'This CSV file contains the following duplicate Orders: '+ response.getReturnValue().setDupOrds.toString()+'. Please upload the CSV file with the proper data.';
                }else{
                    cmp.set("v.csvObject", response.getReturnValue());
                    cmp.set("v.disableButton", false);
                    cmp.set("v.disableSave", false);
                    var lines = [];
                
                    for ( var key in response.getReturnValue().mapIdValues) {
                        lines.push({value:response.getReturnValue().mapIdValues[key], key:key});
                    }
                    cmp.set("v.mapLines", lines);
                }
                cmp.set("v.errorMessage", errorMsg);
                cmp.set("v.loadSpinner", false);
            }else{
                var errors = response.getError();
                var errorMsg = '';
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        errorMsg = errors[0].message+'.';
                    }
                } else {
                    errorMsg = 'Unknown error';
                }
                cmp.set("v.errorMessage", errorMsg);
                cmp.set("v.loadSpinner", false);
            }
        });
        $A.enqueueAction(action);
    },

    saveOrdersHelper : function(cmp, lstOrders) {

        var csvObject = cmp.get("v.csvObject");
        var action = cmp.get('c.saveOrderDetails');
        action.setParams({
            lstOrders : lstOrders,
            mapOrders : csvObject.mapIdValues
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state == "SUCCESS") {
                
                var lines = [];
                
                for ( var key in response.getReturnValue()) {
                    lines.push({value:response.getReturnValue()[key], key:key});
                }   
                cmp.set("v.mapLines",lines);
                cmp.set("v.displayStatus",true);
            }else{
                var errors = response.getError();
                var errorMsg = '';
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        errorMsg = errors[0].message+'.';
                    }
                } else {
                    errorMsg = 'Unknown error';
                }
                cmp.set("v.errorMessage", errorMsg);
                cmp.set("v.loadSpinner", false);
            }
            cmp.set("v.loadSpinner", false);
        });
        $A.enqueueAction(action);
    },
})