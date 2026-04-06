({
    executeQueryRec : function(component, event, helper, query, attributeName) {
        component.set("v.isReadOnly", true);
        component.set("v.showSpinner", true); 
        component.set("v."+attributeName, null);
        var action = component.get("c.executeQuery");
        action.setParams({
            "theQuery": query
        });
        
        action.setCallback(this, function(response) {
            
            var state = response.getState();
            
            if(state == "SUCCESS" && component.isValid()){
                var queryResult = response.getReturnValue();
                component.set("v.showSpinner", false); 
                component.set("v.orderRecOriginal", JSON.parse(JSON.stringify(queryResult[0]))); 
                component.set("v."+attributeName, queryResult[0]);
                
                
            }
            else{
                console.error("fail:" + response.getError()[0].message); 
               /* var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error",
                    "duration": 10000,
                    "type": "error",
                    "message": "Something went wrong in your org: " + response.getError()[0].message
                });
                toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire();*/
            }
        });
        $A.enqueueAction(action);
    },
    
    handleOnSubmit : function(component, event, helper) {
        if(component.get("v.showSpinner")) return;
        
        var entSupRec = component.get("v.orderRec");
        
        var eventFields = component.get("v.orderRecOriginal") ; //get the fields
        var isAnyFieldChanged = false;
        if(entSupRec){
            for (var key in entSupRec) {
                if (entSupRec[key] != eventFields[key] ) {
                    isAnyFieldChanged = true;
                }
            }
        }
        entSupRec.Id= component.get("v.recordId");
        if(!isAnyFieldChanged && entSupRec){
            component.set("v.isReadOnly", true);
            return;
        }
        helper.createRec(component, event, helper, entSupRec );
        
        
    },
    
    createRec : function(component, event, helper, fields) {
        component.set("v.showSpinner", true);  
        var action = component.get("c.saveRecord");
        action.setParams({ 
            "rec": fields
        });
        action.setCallback(this, function(response) {
            component.set("v.showSpinner", false);
            if (response.getState() === "ERROR" ||response.getReturnValue() !='') {
                
                var errors = response.getError();
                if (errors ||response.getReturnValue() !='') {
                    if (errors[0] && ( errors[0].message || errors[0].pageErrors)) {
                        helper.showToast(errors[0].message + errors[0].pageErrors , 'error');
                    }
                    if(response.getReturnValue() !=''){
                        helper.showToast(response.getReturnValue() , 'error');
                    }
                    return;
                }
                
            }
            component.set("v.isReadOnly", true);
            
        });
        $A.enqueueAction(action)
    },
    executeQuery : function(component, event, helper, query, attributeName) {
        component.set("v.isReadOnly", true);
        component.set("v.showSpinner", true); 
        component.set("v."+attributeName, null);
        var action = component.get("c.executeQuery");
        action.setParams({
            "theQuery": query
        });
        
        action.setCallback(this, function(response) {
            
            var state = response.getState();
            
            if(state == "SUCCESS" && component.isValid()){
                var queryResult = response.getReturnValue();
                component.set("v.showSpinner", false); 
                
                
                component.set("v."+attributeName, queryResult[0]);
                
                
            }
            else{
                console.error("fail:" + response.getError()[0].message); 
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error",
                    "duration": 10000,
                    "type": "error",
                    "message": "Something went wrong in your org: " + response.getError()[0].message
                });
                toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire();
            }
        });
        $A.enqueueAction(action);
    },
})