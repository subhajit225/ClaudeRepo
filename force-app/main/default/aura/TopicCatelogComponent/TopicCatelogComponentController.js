({
    doInit : function(component, event, helper) {
        helper.getTopics(component,event,helper);
    },
    
    manageSubscription :function(component, event, helper) {
        component.set("v.ModalOpen", true);
    },
    
    manageTopicSubscription :function(component, event, helper) {
        helper.manageTopicSubscriptions(component,event,helper);
    },
    closeBttn :function(component, event, helper) {
        component.set("v.ModalOpen", false);
        
        $A.get('e.force:refreshView').fire();
        
    },
    
    close1Bttn :function(component, event, helper) {
        
        component.set("v.Modal1Open", false);
        //  helper.doInit(component, event, helper);
        $A.get('e.force:refreshView').fire();
    },
    
    updateCheckbox  : function(component, event, helper) {
        var whichOne = event.getSource().get("v.value");
        var isChecked = event.getSource().get("v.checked");
        var subsList = component.get("v.topicsList");
        var newList=[];
        if(whichOne ==='All'){
            if(isChecked==true){
                for(var i=0;i<subsList.length;i++){
                    subsList[i].IsSubscribed = true;
                    newList.push(subsList[i]);
                }
            }else{
                for(var i=0;i<subsList.length;i++){
                    subsList[i].IsSubscribed = false;
                }
                
            }
            component.set("v.topicsList", subsList);
        }  else{
            
            if(isChecked==true){
                
                var topicID = event.getSource().get("v.name");
                console.log('topicID'+topicID);
                for(var i=0;i<subsList.length;i++){
                    if(subsList[i].topic.Id ==topicID){
                        subsList[i].IsSubscribed=true;
                    }
                }
                component.set("v.topicsList", subsList);
            }
            else{
                
                var topicID = event.getSource().get("v.name");
                console.log('topicID'+topicID);
                for(var i=0;i<subsList.length;i++){
                    if(subsList[i].topic.Id ==topicID){
                        subsList[i].IsSubscribed=false;
                    }
                }
                
                component.set("v.topicsList", subsList);
            }
        }
        component.set("v.changeSubscription", true);
    },
    
    saveBtn :  function(component, event, helper) {
        
        var isSubscribed = component.get("v.topicsList");
        console.log('dd-' , isSubscribed);
        var action = component.get("c.saveSubscription");
        action.setParams({
            "topicsList"	 : isSubscribed,
            "networkId": component.get("v.networkId")
        });
        action.setCallback(this, function(response) {
            //store state of response
            var state = response.getState();
            if (state === "SUCCESS") {
                //set response value in wrapperList attribute on component.
                $A.get('e.force:refreshView').fire();
                component.set("v.truthy",false);
                component.set('v.topicsList', response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },//added for Forums Gamification - Veera - CS21-712
    navigateToUserProfile : function(component, event, helper) {
        let userId = event.currentTarget.dataset.id;
        let pageURL = $A.get("$Label.c.ForumGamificationProfilePage");
        
        $A.get("e.force:navigateToURL").setParams({
            "url": "/"+pageURL+"?recordId=" + userId
        }).fire();
    },
    navigateToForumsProfile : function(component, event, helper) {
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        let pageURL = $A.get("$Label.c.ForumGamificationProfilePage");
        
        $A.get("e.force:navigateToURL").setParams({
            "url": "/"+pageURL+"?recordId=" + userId
        }).fire();
    },
    navigateToForumsGuidelines: function(component, event, helper) {
        let pageURL = 'forum-guidelines?type=All';
        
        $A.get("e.force:navigateToURL").setParams({
            "url": "/"+pageURL
        }).fire();
    },
    //CS21-1100 : Forums 2.0 Rewards Redemption/Swag Store
    navigateToRedemptionPage: function(component, event, helper) {
        let pageURL = $A.get("$Label.c.Redemption_Page");
        
        $A.get("e.force:navigateToURL").setParams({
            "url": "/" + pageURL
        }).fire();
    },

    modalHandler: function(component, event, helper){
       
        var change = component.get("v.changeSubscription");
        if(change){
        	component.set("v.modalToggle", true);
            component.set("v.changeSubscription", false);
        }
        else{
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
              "url": "/mypostsubscriptionpage"
            });
            urlEvent.fire();
        }
    },

    closeButton: function(component, event, helper){
        component.set("v.modalToggle", false);
    },
})