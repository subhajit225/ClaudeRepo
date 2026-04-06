({
    close : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    },
    sendForApproval: function(component, event, helper) {
        var recId = component.get("v.recordId");
        var action = component.get("c.opportunityApproval");
        action.setParams({"recId": recId});  
        action.setCallback(this, function(response)
                           {       
                               var result = response.getReturnValue();
                               if(result == 'Approved')
                               {
                                   var navEvt = $A.get("e.force:navigateToSObject");
                                   navEvt.setParams({
                                       "recordId": recId
                                   });
                                   navEvt.fire();
                               }
                               else{
                                   component.set("v.ShowApprovalModel",false);
                                   component.set("v.displayMessage",result);
                               }
                           }); 
        $A.enqueueAction(action);
    }
    
})