({
	init : function(component, event, helper) {
        var spinner = component.find("spinner");
        
		var url_string = window.location.href;
        var url = new URL(url_string);
        var currentId = url.searchParams.get("id");
        
        var action = component.get("c.getIdeaDetails");
        action.setParams({
            recordId : currentId
        });
        action.setCallback(component, function(response) {
            var result = response.getReturnValue();
            component.set("v.ideaRec",result);
            console.log(result);
            var isliked = false;
            var isUserLiked = false;
            if(result.Votes != null && result.Votes[0] != null){
				isUserLiked = true;                
                if(result.Votes[0].Type == 'Up'){
                    isliked = true;
                }
            }
            component.set("v.UserLiked",isUserLiked);
            component.set("v.isLiked",isliked);
            $A.util.addClass(spinner,'slds-hide');
        });
        $A.enqueueAction(action);
	},
    showComment : function(component, event, helper) {
        component.set("v.showcommentBox",true);
    },
    Cancel : function(component, event, helper) {
        component.set("v.commentText","");
        component.set("v.showcommentBox",false);
        component.set("v.hasError",false);
    },
    addComment : function(component, event, helper) {
        var spinner = component.find("spinner");
        $A.util.removeClass(spinner,'slds-hide');
        var url_string = window.location.href;
        var url = new URL(url_string);
        var currentId = url.searchParams.get("id");
        
        
        var commentbody = component.get("v.commentText");
        var hasError = false;
        if(commentbody == undefined || commentbody == '' || commentbody == null){
            hasError = true;
        }
        if(!hasError){
            var action = component.get("c.savecomment");
            action.setParams({
                parentId : currentId,
                body:commentbody
            });
            
            action.setCallback(component, function(response) {
                var result = response.getReturnValue();
                console.log("dff" , result);
                component.set("v.ideaRec",result);
                component.set("v.hasError",hasError);
                component.set("v.commentText",'');
                component.set("v.showcommentBox",false);
                $A.util.addClass(spinner,'slds-hide');
            });
            $A.enqueueAction(action);
        }else{
            component.set("v.hasError",hasError);
            $A.util.addClass(spinner,'slds-hide');
        }
       
        

    },
    handleLike : function(component, event, helper){
        console.log('123');
        var spinner = component.find("spinner");
        $A.util.removeClass(spinner,'slds-hide');
        var url_string = window.location.href;
        var url = new URL(url_string);
        var currentId = url.searchParams.get("id");
        console.log(currentId);
        var action = component.get("c.addVote");
        action.setParams({
            parentId : currentId,
            type : event.getSource().getLocalId()
        });
        action.setCallback(component, function(response) {
            var result = response.getReturnValue();
            console.log(result);
            if(event.getSource().getLocalId() == 'Up'){
                component.set("v.isLiked",true);
            }else{
                component.set("v.isLiked",false);
            }
            component.set("v.UserLiked",true);
            
            component.set("v.ideaRec",result);
            $A.util.addClass(spinner,'slds-hide');
        });
        $A.enqueueAction(action);
    }
})