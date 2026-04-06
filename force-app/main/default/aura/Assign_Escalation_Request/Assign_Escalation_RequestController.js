({
	doinit : function(component, event, helper) {
		var action = component.get("c.assignMe");
        action.setParams({
            'escalationId':component.get("v.recordId") 
        });
        action.setCallback(this,function(res){
            $A.get('e.force:refreshView').fire();
            $A.get("e.force:closeQuickAction").fire();
        });
        $A.enqueueAction(action);
	}
})