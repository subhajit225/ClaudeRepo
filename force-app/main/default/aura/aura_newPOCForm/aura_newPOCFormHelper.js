({
	getOpportunityValidation : function(component, event, helper) {
		return new Promise( function(resolve, reject){
			var action = component.get('c.validateCheck');
			action.setParams({
				'oppId': component.get("v.recordId")
			});
			action.setCallback(this, function(response){
				let responseApex = response.getReturnValue();
				console.log('responseApex', responseApex);
                if(responseApex == null){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        type: 'error',
                        message: 'You do not have access to create POCs. Please contact pochelp@rubrik.com.'
                    });
                    toastEvent.fire();
                }
				else if( Object.keys(responseApex).length === 0 || responseApex['Status'] === "Success" ) {
					resolve();
                } else {
					reject( responseApex['Message'] );
				}
			});
			$A.enqueueAction( action );
		});		
	},
    
   
})