({
	getAttachment : function(component, event, helper) {
       
        var action2 = component.get('c.getAttch');
        action2.setParams({
            "opprId": component.get('v.oppId')
        });
        
        action2.setCallback(this, function(resp) {
            var state = resp.getState();
            if (state == "SUCCESS") {
                if(!!resp.getReturnValue() && resp.getReturnValue().length > 0){
                    component.set('v.data',resp.getReturnValue());
                    component.set('v.showSpinner',false);
                    component.set("v.showData",true);
                }else{
                    window.setTimeout(function(){ 
                    	component.set('v.retryCount',component.get('v.retryCount')+1);
                    },2000);
                }
                
               
            }
        });
        $A.enqueueAction(action2);
	},
    
})