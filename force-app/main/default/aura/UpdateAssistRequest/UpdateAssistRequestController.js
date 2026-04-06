({
	updateRequest : function(component, event, helper) {
        var error = false;
        var Reason = component.find('nextSteps');
        if(!Reason.checkValidity()){Reason.reportValidity();error = true;}
        if(!error){
            var action = component.get('c.addResponse');    
            action.setParams({
                'recordId': component.get('v.recordId'),
                'response':component.get('v.nextSteps')
            });
            action.setCallback(this,function(response){
                var state = response.getState();
                var result = response.getReturnValue();
                console.log(result);
                if (state === "SUCCESS") {
                    $A.get('e.force:refreshView').fire();
                    var dismissActionPanel = $A.get("e.force:closeQuickAction");
                    dismissActionPanel.fire();
                }
            });
            $A.enqueueAction(action);
        }
    },
    close: function(component, event, helper) {
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    },
    charLimitValidation: function(component, event, helper) {
        let response = component.get('v.nextSteps');
        let validation = document.getElementById('message');
        
        if (response && response.length > 3960) {
            component.set('v.disable', true);
            component.set('v.validation','Warning Character Limit Exceeded by '+(response.length - 3960) +' Characters.');
            validation.style = "color:#c00";
        } else if (response && response.length > 3560) {
            component.set('v.disable', false);
            component.set('v.validation', (3960 - response.length) + ' Characters Remaining.');
            validation.style = "color:#c90";
        } else {
            component.set('v.disable', false);
            component.set('v.validation', '');
        }
    }
})