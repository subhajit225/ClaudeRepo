({
	doInit : function(component, event, helper) {
		var action = component.get("c.unlockCCR");
        action.setParams({ 
            recordId : component.get("v.recordId") 
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                console.log('result..!', result);
                
                if(result.isError)
                    helper.showToast('Error!', result.errMsg, 'sticky', 'error');
                else
                    helper.showToast('Success!', 'Record unlocked successfully.', 'pester', 'success');
            }
            else{
                var errors = response.getError();
                console.log('errors..!', errors);
            }
            $A.get("e.force:closeQuickAction").fire();
            $A.get('e.force:refreshView').fire();
        });
        $A.enqueueAction(action);
    }
})