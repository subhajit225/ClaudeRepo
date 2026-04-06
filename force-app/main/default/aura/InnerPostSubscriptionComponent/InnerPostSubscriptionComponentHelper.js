({
    DelRecord : function(component, event, helper ) {
        var recId =event.currentTarget.dataset.index;
        console.log('recId===' , recId);
        var action = component.get("c.removeBookMark");
        action.setParams({
            networkId:component.get("v.networkId"),
            questionId: recId,
            isBookmarked:false,
            currentuserId: $A.get("$SObjectType.CurrentUser.Id")
        });
        action.setCallback(this, function(response){
           var state = response.getState();
            // $A.get('e.force:refreshView').fire();
            //var compEvent = component.getEvent("refreshEvent");
             //compEvent.fire();
           // var result= response.getReturnValue();
        });
        
		
		
        $A.enqueueAction(action);      
    }
})