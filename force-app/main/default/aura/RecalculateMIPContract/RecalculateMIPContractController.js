({
	doInit : function(component, event, helper) {
        var message = 'Recalculating MIP Contract';
        var recordId = component.get('v.recordId');
        
        var action = component.get('c.initiateMIPSyncBatch');
        action.setParams({
            recordId : recordId
        });
        action.setCallback(component, function(response){
            var result = response.getReturnValue();
            console.log('12->?',result);
        });
        
        var resultsToast = $A.get("e.force:showToast"); 
        resultsToast.setParams({ 
            "title": "Success" , 
            "message": message + "." 
        }); 
        $A.enqueueAction(action);
        resultsToast.fire();
        var dismissActionPanel = $A.get("e.force:closeQuickAction"); 
        dismissActionPanel.fire();
        
	}
})