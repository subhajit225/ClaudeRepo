({
    doInit : function(component, event, helper) {
       
        console.log('hasRecordid'+component.get("v.recordId"));
        //console.log(component.get("v.recordId"));
        var action = component.get("c.getSusbcriptionInfo");
        action.setParams({
            networkId: component.get("v.networkId"),
            topicId  : component.get("v.recordId")
        });
        action.setCallback(this, function(response){
            var result=response.getReturnValue();
            if(result==true){
                component.set("v.SubUnsub",'Unsubscribe to category');                
            }
            else{
                component.set("v.SubUnsub",'Subscribe to category');
            }
            component.set("v.isSubscribed",result);
        });
        $A.enqueueAction(action);
        
    },
    close1Bttn :function(component, event, helper) {
        
        component.set("v.Modal1Open", false);
        if(component.get("v.SubUnsub") == 'Subscribe to category'){
            component.set("v.SubUnsub",'Unsubscribe to category');
        }else{
            component.set("v.SubUnsub",'Subscribe to category');
        }
    },
    
    manageSubscription:  function(component, event, helper) {            
        var state= component.get("v.isSubscribed");
        var type = component.get("v.SubUnsub");
        var subType;
        if(type.toLowerCase().includes('category')){
            subType = 'Forum Category';
        }else{
            subType = 'FeedItem';
        }
        if(state==true){
            //unsubscribe 
            var action = component.get("c.unSubscribe");
            action.setParams({
                networkId: component.get("v.networkId"),
                topicId1 : component.get("v.recordId"),
                subscriptionType: subType
            });
            action.setCallback(this, function(response){
                var result=response.getReturnValue();
                if(result==true){
                    component.set("v.SubUnsub",'Unsubscribe to category');
                    component.set("v.isSubscribed",false);
                    component.set("v.Modal1Open", true);
                }
                
            });
            $A.enqueueAction(action);
        }else{            
            var action = component.get("c.subscribe");
            action.setParams({
                networkId: component.get("v.networkId"),
                topicId  : component.get("v.recordId")
            });
            action.setCallback(this, function(response){
                var result=response.getReturnValue();
                if(result==true){                     
                    component.set("v.isSubscribed",true);
                    component.set("v.SubUnsub",'Subscribe to category');
                    component.set("v.Modal1Open", true);
                }
                
            });
            $A.enqueueAction(action);            
        }
        
    },
    //added for Forums Gamification - Veera - CS21-712
    navigateToUserProfile : function(component, event, helper) {
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        let pageURL = $A.get("$Label.c.ForumGamificationProfilePage");
        
        $A.get("e.force:navigateToURL").setParams({ 
            "url": "/"+pageURL+"?recordId=" + userId
        }).fire();
    }
    //End - Veera - CS21-712
    
})