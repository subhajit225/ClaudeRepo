({
    doInit : function(component, event, helper) {
        helper.getTiles(component, event, helper);
    },
    manageSubscription :function(component, event, helper) {
        
        component.set("v.ModalOpen", true);
    },
    
    closeBttn : function(component, event, helper) {
        component.set("v.ModalOpen", false);
    },
    
    updateCheckbox  : function(component, event, helper) {
        var whichOne = event.getSource().get("v.value");  
        var isChecked = event.getSource().get("v.checked");
        console.log('whichOne--' , whichOne);
        var subsList = component.get("v.subscribedInfoList");
        if(whichOne ==='All'){
            for(var i=0;i<subsList.length;i++){
                if(isChecked){
                    subsList[i].isSubscribed = true;
                }else{
                    subsList[i].isSubscribed = false;
                }
                
            }
            component.set("v.subscribedInfoList", subsList);
        }  else{
            var j = 1;
            for(var i=0;i<subsList.length;i++){
                if(subsList[i].api != 'All' && subsList[i].isSubscribed){
                    j++;
                }
            }
            console.log(j);
            console.log(subsList.length);
            if(subsList.length == j){
                subsList[0].isSubscribed = true;
            }else{
                subsList[0].isSubscribed = false;
            }
            component.set("v.subscribedInfoList", subsList);
        }  
        
    },
    saveBtn :  function(component, event, helper) {
        var isSubscribed = component.get("v.subscribedInfoList");
        console.log('dd-' , isSubscribed);
        var action = component.get("c.saveSubscription");
        action.setParams({
            "subsCategList"	 : isSubscribed
        });
        action.setCallback(this, function(response) {  
            //store state of response
            var state = response.getState();
            if (state === "SUCCESS") {
                //set response value in wrapperList attribute on component.
                 $A.get('e.force:refreshView').fire();
                component.set('v.subscribedInfoList', response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },
    
    
})