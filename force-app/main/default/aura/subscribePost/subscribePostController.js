({
    doInit : function(component, event, helper) {
        

         var userId = $A.get("$SObjectType.CurrentUser.Id");     
         component.set("v.currentUserId",userId);
        
        console.log('@@@recordId%%'+component.get("v.recordId"));
        var action = component.get("c.getBookmarkInfo");
        action.setParams({
            networkId: component.get("v.networkId"),
            questionId:  component.get("v.recordId")
        });
        action.setCallback(this, function(response){
            var result=response.getReturnValue();
            console.log('result DD result');
            console.log(result);
            if(result==true){
                component.set("v.SubUnsub",'Unsubscribe to post');                
             }
             else{
                 component.set("v.SubUnsub",'Subscribe to post');
              }
            component.set("v.isSubscribed",result);
            component.set("v.isBookmarked",result);
        });
        $A.enqueueAction(action);
        
    },
    
    close1Bttn :function(component, event, helper) {
        
        component.set("v.Modal1Open", false);
        //  helper.doInit(component, event, helper);
        var isBookmarked=  component.get("v.isBookmarked");
        component.set("v.isSubscribed",isBookmarked);
      //  $A.get('e.force:refreshView').fire();
       // location.reload();
    },
    
    manageSubscription: function(component, event, helper) {
        
        var networkId =component.get("v.networkId");
        
        if( component.get("v.isBookmarked")==true){
            //removebookmark
            var action = component.get("c.removeBookMark");
            action.setParams({
                networkId: component.get("v.networkId"),
                questionId:  component.get("v.recordId"),
                isBookmarked: !component.get("v.isBookmarked"),
                currentuserId: component.get("v.currentUserId")
            });
            action.setCallback(this, function(response){
                var result=response.getReturnValue();
                component.set("v.isSubscribed",result);
                component.set("v.isBookmarked",result);
                component.set("v.SubUnsub",'Subscribe to post');
                //component.set("v.Modal1Open",true);
                $A.get('e.force:refreshView').fire();
            });
            $A.enqueueAction(action);
        }
        
        if( component.get("v.isBookmarked")==false){
            var action = component.get("c.addBookMark");
            action.setParams({
                networkId: component.get("v.networkId"),
                questionId:  component.get("v.recordId"),
                isBookmarked: !component.get("v.isBookmarked")
            });
            action.setCallback(this, function(response){
                var result=response.getReturnValue();
                console.log('result@@@#');
                console.log(result);
                component.set("v.isSubscribed",result);
                component.set("v.isBookmarked",result);
            
                component.set("v.SubUnsub",'Unsubscribe to post');
                  $A.get('e.force:refreshView').fire();
            });
            $A.enqueueAction(action);
            //   $A.get('e.force:refreshView').fire();
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