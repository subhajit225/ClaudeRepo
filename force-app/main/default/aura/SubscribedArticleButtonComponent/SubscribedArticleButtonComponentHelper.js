({
    SubscribedArticle : function(component, event, helper){
        var action = component.get("c.getSubscription");
        var recId = component.get("v.recordId");
        console.log(recId);
        action.setParams({
            recId: recId
        });
        action.setCallback(this, function(response){
            var result=response.getReturnValue();
            console.log('res====' , result);
            component.set("v.isSubscribed",result.isSubscribed);
            component.set("v.linkedCategory",result.linkedCategory);
        });
        $A.enqueueAction(action);   
    },
    
    deleteSubscription : function(component, event, helper){
        var action = component.get("c.deleteSubscription");
        var recId = component.get("v.recordId");
        action.setParams({
            recId: recId ,
            isSubscribed : component.get("v.isSubscribed")
            
        });
        action.setCallback(this, function(response){
            var result=response.getReturnValue();
            console.log('resdel====' , result);
            component.set("v.isSubscribed",result);
            component.set("v.ModalOpen", true);
        });
        $A.enqueueAction(action);   
    },
    

})