({
    doInit : function(component, event, helper) {
        
        var action = component.get('c.getRecord');    
        action.setParams({
            'recordId':component.get('v.recordId')
        });
        action.setCallback(this,function(response){
            var state = response.getState();
            var result = response.getReturnValue();
            console.log(result);
            if (state === "SUCCESS") {
                var assist = result.assitRecord;
                assist.Summary_of_the_Issue_Problem_Statement__c = '';
                assist.Assist_Request_Fullfilled__c = '';
                component.set("v.AssistRequest",result.assitRecord);
                component.set("v.fulfilled",result.fulfilledOptions);
                component.set("v.isLoad",true);
            }
        });
        $A.enqueueAction(action);
    },
    OverideClose : function(component, event, helper) {
        component.set("v.isOveride","Yes");
    },
    updateRequest : function(component, event, helper) {
        var error = false;
        var Fullfilled = component.find('Fullfilled');
        var OwnerComment = component.find('OwnerComment');
        var Reopen = component.find('Reopen');
        var Reason = component.find('Reason');
        if(!Fullfilled.checkValidity()){error = true;}
        if(!OwnerComment.checkValidity()){OwnerComment.reportValidity();error = true;}
        if(Fullfilled.get('v.value') == 'Unresolved/Request Reopen'){
            if(!Reopen.checkValidity()){Reopen.reportValidity();error = true;}
            if(!Reason.checkValidity()){Reason.reportValidity();error = true;}
        }
        if(!error){
            var overridereason ='';
            if(component.get('v.overideReason')!='' || component.get('v.overideReason')!= 'undefined'){
                var overridereason = component.get('v.overideReason');
            }
            
            var action = component.get('c.updateClose');    
            action.setParams({
                'assistRequest':component.get('v.AssistRequest'),
                'isReopen':component.get('v.isReopen'),
                'reopenText':component.get('v.ReopenText'),
                'overideReason':overridereason
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
    }
})