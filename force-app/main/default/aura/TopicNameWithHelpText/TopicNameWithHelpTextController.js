({
    doInit : function(component, event, helper) {
        
         console.log('@@hasRecordID');
         console.log(component.get("v.recordId"));
        
         var action = component.get("c.getTopicInfo");
         action.setParams({
            networkId: component.get("v.networkId"),
            topicId  : component.get("v.recordId")
        });
        action.setCallback(this, function(response){
            var result=response.getReturnValue();
            console.log('result result');
            console.log(result);
             component.set("v.Description",result.Description);
             component.set("v.Name",result.Name);
            
            
        });
        $A.enqueueAction(action);
		
        
    }
    
    
    
    
})