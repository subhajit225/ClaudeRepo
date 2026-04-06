({
    getTopics : function(component,event,helper) {
        var action = component.get("c.getTopicsList");
        action.setParams({
            'networkId' : component.get("v.networkId")
        });
        action.setCallback(this,function(res){
            var state = res.getState();
            if(state == 'SUCCESS'){
                component.set("v.topicsList",res.getReturnValue());
                /*Added by akashdeep Singh on 9 Feb*/
                var topicList = res.getReturnValue();
                var subscribedTopicList = 0;
                for(var i = 0; i < topicList.length; i++){
                    if(topicList[i].IsSubscribed == true){
                       subscribedTopicList++;
                   }
            }
                component.set("v.SubscribedTopicsLength", subscribedTopicList);
                if(subscribedTopicList == topicList.length){
                    component.set("v.allSubscribed", true);
                }
                else{
                    component.set("v.allSubscribed", false);
                }
            }
        });
        $A.enqueueAction(action);

        var action1 = component.get("c.getActivityData");
        action1.setCallback(this, function(response){
            helper.sortData(component,response.getReturnValue(), helper);
        });
        $A.enqueueAction(action1);

        var action2 = component.get("c.getCurrentUserRecord");
        action2.setCallback(this, function(response){
            component.set("v.currentUser", response.getReturnValue());
        });
        $A.enqueueAction(action2);
    },
    sortData: function (component ,data, helper) {
        //debugger;
        var fieldName = 'chA.LikeReceivedCount';
        var reverse = false;
        data = Object.assign([],data.sort(this.sortBy(fieldName, reverse ? -1 : 1)));
        component.set("v.userRecord", data);
    },
    sortBy: function (field, reverse, primer) {
        var key;
        if(field.includes('.')){
            var fields = field.split(".");
            var field1 = fields[0];
            var field2 = fields[1];
            key = function(x) {
                return x[field1][field2];
            };
        }else{
            key = primer ?
                function(x) {return primer(x[field])} :
            function(x) {return x[field]}
        }
        
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a)?key(a):'', b = key(b)?key(b):'', reverse * ((a > b) - (b > a));
        }
    },
    
    manageTopicSubscriptions : function(component,event,helper) {
       
        var topicId = event.target.id;
        var title   = event.target.title;
        if(title=='Subscribe'){
            var action = component.get("c.subscribeToTopics");
            action.setParams({
                    'networkId' : component.get("v.networkId"),
                    'topicId'   : topicId 
                });
            action.setCallback(this,function(res){
                var state = res.getState();
                if(state == 'SUCCESS'){
                    component.set("v.Modal1Open" ,true);
                    component.set("v.isSubscribed",true);
                   // component.set("v.topicsList",res.getReturnValue());

                //   $A.get('e.force:refreshView').fire();
                }
            });
          $A.enqueueAction(action);
    }
        
        else{
            var action = component.get("c.unSubscribeToTopics");
            action.setParams({
                    'networkId' : component.get("v.networkId"),
                    'topicId'   : topicId 
                });
            action.setCallback(this,function(res){
                var state = res.getState();
                if(state == 'SUCCESS'){
                    console.log(res.getReturnValue());
                 //   component.set("v.topicsList",res.getReturnValue());
                    component.set("v.Modal1Open" ,true);
                    component.set("v.isSubscribed",false);

                  
                }
            });
          $A.enqueueAction(action);  
        }
       
         
    } 
})