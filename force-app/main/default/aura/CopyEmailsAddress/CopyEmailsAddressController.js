({
	doinit : function(component, event, helper) {
		var action = component.get("c.copyEmails");
        action.setParams({
            'escalationId':component.get("v.recordId"),
            'emailType': 'customerContact'
        });
        action.setCallback(this,function(res){
            if(res.getState() == 'SUCCESS'){
                var copyText = res.getReturnValue();
                if(copyText != null){
                    var el = document.createElement('textarea');
                    // Set value (string to be copied)
                    el.value = copyText;
                    // Set non-editable to avoid focus and move outside of view
                    el.setAttribute('readonly', '');
                    el.style = {position: 'absolute', left: '-9999px'};
                    document.body.appendChild(el);
                    // Select text inside element
                    el.select();
                    // Copy text to clipboard
                    document.execCommand('copy');
                }
                
                $A.get('e.force:refreshView').fire();
                $A.get("e.force:closeQuickAction").fire();
            }
        });
        $A.enqueueAction(action);
	}
})