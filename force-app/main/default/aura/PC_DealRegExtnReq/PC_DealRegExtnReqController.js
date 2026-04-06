({
    doInit : function(component, event, helper) {
		var action = component.get("c.getStatus");
        action.setParams({"dealRegId" : component.get("v.recordId")});
           
        action.setCallback(this, function(a) {
            console.log(a.getReturnValue());
            component.set("v.status",a.getReturnValue().Deal_Registration_Status__c);
            component.set("v.expDays",a.getReturnValue().Days_Before_Expiration__c);
            
        });
        $A.enqueueAction(action);
        
	},
	handleClick : function(component, event, helper) {
        component.set("v.btndisable",true);
        if(component.get("v.status") == 'Expired' && component.get("v.expDays") < -45){
            component.set("v.message","Deal Registration Extension is only applicable within 45 days of Expiration. Please submit a new registration");
             console.log(component.get("v.message"));    
            var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                        title : 'Error',
                        message: component.get("v.message"),
                        duration:' 5000',
                        type: 'error',
                        mode: 'pester'
                	});
                	toastEvent.fire();
            component.set("v.btndisable",false);
        }else if(component.get("v.status") != 'Approved' && component.get("v.status") != 'Expired' && component.get("v.status") != 'Pending Meeting'){
             component.set("v.message","Deal Registration Extension can only be requested for Approved, Expired and Pending meeting Deals");
             console.log(component.get("v.message"));    
            var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                        title : 'Error',
                        message: component.get("v.message"),
                        duration:' 5000',
                        type: 'error',
                        mode: 'pester'
                	});
                	toastEvent.fire();
            component.set("v.btndisable",false);
        }else{
            component.set("v.message","");
            var action = component.get("c.setExtension");
            action.setParams({"dealRegId" : component.get("v.recordId")});
               
            action.setCallback(this, function(a) {
                console.log('response '+a.getReturnValue());
                component.set("v.message",a.getReturnValue());
                if(component.get("v.message").search("already") > 0){
                    var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                        title : 'Warning',
                        message: component.get("v.message"),
                        duration:' 5000',
                        type: 'warning',
                        mode: 'pester'
                	});
                	toastEvent.fire();
                }else if(component.get("v.message").search("successfully") > 0){
                    var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                        title : 'success',
                        message: component.get("v.message"),
                        duration:' 5000',
                        type: 'success',
                        mode: 'pester'
                	});
                	toastEvent.fire();
                }else{
                    var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                        title : 'Error',
                        message: component.get("v.message"),
                        duration:' 5000',
                        type: 'error',
                        mode: 'pester'
                	});
                	toastEvent.fire();
                }
                component.set("v.btndisable",false);
            });
            $A.enqueueAction(action);
        }
	}
})