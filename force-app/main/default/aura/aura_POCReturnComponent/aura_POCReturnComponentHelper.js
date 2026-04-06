({
	getOpportunityValidation : function(component, event, helper) {
		return new Promise( function(resolve, reject){
			var action = component.get('c.getOrders');
			action.setParams({
				'oppId': component.get("v.recordId")
			});
			action.setCallback(this, function(response){
				let responseApex = response.getReturnValue();
				console.log('responseApex', responseApex);
				if(responseApex.isSuccess){
                   
                   // resolve();
                } else {
                    
                    // responseApex.errorMessage;
                }
			});
			$A.enqueueAction( action );
		});		
	},
    
   
})