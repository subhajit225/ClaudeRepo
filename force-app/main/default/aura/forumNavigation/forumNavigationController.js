({
    doInit: function(cmp){
        try{ 
            
            var action = cmp.get("c.gettopicDetail");
            action.setParams({'recordId':cmp.get("v.recordId")});
            action.setCallback(this, function(response){
                 
                var bodyCom = cmp.find('spinner');
            	$A.util.addClass(bodyCom, 'slds-hide');
                console.log('@@@@@result  ',response.getReturnValue());
                cmp.set("v.feed",response.getReturnValue().feed);
                cmp.set("v.currentTopicId",response.getReturnValue().topicId);
                cmp.set("v.currentCategory",response.getReturnValue().topicName);
                cmp.set("v.userFeedData",response.getReturnValue().userData);
                cmp.set("v.bestCommentCount",response.getReturnValue().bestComment);
                cmp.set("v.isDeleted",response.getReturnValue().isDeleted);
                if(response.getReturnValue().topicList!=null && response.getReturnValue().topicList!='' && response.getReturnValue().topicList!=undefined){
                    var options = [];
                    for(var record in response.getReturnValue().topicList){
                      var option = new Object();
                        option.value=response.getReturnValue().topicList[record].Id;
                        option.label = response.getReturnValue().topicList[record].Name;
                        if(response.getReturnValue().topicList[record].Id == response.getReturnValue().topicId){
                            option.selected = true;
                            cmp.set("v.newTopicId",response.getReturnValue().topicList[record].Id)
                        }
                        options.push(option);
                    }
                    
                    cmp.set("v.topicsList",options);
                    console.log('@@@@@@@',cmp.get("v.topicsList"));
                }  
            });
            $A.enqueueAction(action);
            
        }
        catch(err) {
          console.log("Error:  " , err.message );  
        }
    },
    closeModal:function(component,event,helper){    
        var cmpTarget = component.find('Modalbox');
        var cmpBack = component.find('Modalbackdrop');
        $A.util.removeClass(cmpBack,'slds-backdrop--open');
        $A.util.removeClass(cmpTarget, 'slds-fade-in-open');
        $A.get('e.force:refreshView').fire();
    },
    openmodal: function(component,event,helper) {
        var cmpTarget = component.find('Modalbox');
        var cmpBack = component.find('Modalbackdrop');
        $A.util.addClass(cmpTarget, 'slds-fade-in-open');
        $A.util.removeClass(cmpBack, 'slds-backdrop');
        $A.util.removeClass(cmpTarget, 'slds-fade-in-close');
        $A.util.addClass(cmpBack, 'slds-backdrop--open');
        
    },
    SaveFormData : function(component,event,helper){
        var hasError = false; 
        var spinner = component.find("mySpinner");
        $A.util.removeClass(spinner, "slds-hide");
        $A.util.addClass(spinner, "slds-show");
        var newTopicId = component.get("v.newTopicId");
        var questionRec = component.get("v.feed");
        var cat = component.find("productCat");
        var title = component.find("disTitle");
        var body = component.find("disBody");
        if(cat.get("v.value") == null  ||  cat.get("v.value") == '' ){
            $A.util.addClass(cat, 'slds-has-error');
            hasError = true; 
        }else{
            $A.util.removeClass(cat, 'slds-has-error');
        }
        if(title.get("v.value") == null  ||  title.get("v.value") == '' ){
            $A.util.addClass(title, 'slds-has-error');
            hasError = true; 
        }
        if(body.get("v.value") == null  ||  body.get("v.value") == ''){
            $A.util.addClass(body, 'errorForRich');
            hasError = true; 
        }else{
            $A.util.removeClass(body, 'errorForRich');
        }
        component.set("v.errorBlock",hasError);
        if(hasError == false){
          var action = component.get("c.saveData");
            action.setParams({'topicId':newTopicId,'feed':questionRec});
            action.setCallback(this, function(response){
                if(response.getState() == 'SUCCESS'){
                    $A.util.addClass(spinner, "slds-hide");
                    $A.get('e.force:refreshView').fire();
                }  
            });
            $A.enqueueAction(action);      
        }else{
           $A.util.addClass(spinner, "slds-hide"); 
        }
        
    }
})