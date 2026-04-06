({
	init : function(component, event, helper) {
        var spinner = component.find("mySpinner");
        $A.util.removeClass(spinner, "slds-hide");
        var path = decodeURIComponent(window.location.search.substring(1));
        var topicId = component.get("v.recordId");
        if(topicId == null){
            $A.util.addClass(spinner, "slds-hide");
            return;
        }
        
        helper.executeBackend(component, "getQuestionList", {topicId : topicId}, function(results) {
            var result = results.feed;
            component.set("v.pinnedArticles",results.pinnedfeeds);
            console.log(result);
            component.set("v.totalPages", Math.ceil(result.length/component.get("v.pageSize")));
            var i = 1;
            var arrayList = [];
            while(i <= component.get("v.totalPages")){
                arrayList.push(i);
                i++;
            }
            component.set("v.totalPagesList",arrayList);
            component.set("v.allData", result);
            component.set("v.currentPageNumber",1);
            helper.buildData(component, helper);
            $A.util.addClass(spinner, "slds-hide");
        });
    },
    navigateto : function(component, event, helper) {
        var selectedQuestion = event.target.id;
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "/question/"+selectedQuestion
        });
        urlEvent.fire();
    },
    createNewPost : function(component, event, helper) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "/createpost"
        });
        urlEvent.fire();
    },
    toggleLike : function(component, event, helper) {
        var selectedQuestion = event.target.id;
        var selectedCat = component.get("v.selectedCategory");
        helper.executeBackend(component, "createVote", {questionId : selectedQuestion,articleType:selectedCat}, function(result) {
            component.set("v.questionList",result);
        });
    },
    onNext : function(component, event, helper) {        
        var pageNumber = component.get("v.currentPageNumber");
        component.set("v.currentPageNumber", pageNumber+1);
        helper.buildData(component, helper);
    },
    
    onPrev : function(component, event, helper) {        
        var pageNumber = component.get("v.currentPageNumber");
        component.set("v.currentPageNumber", pageNumber-1);
        helper.buildData(component, helper);
    },
    
    processMe : function(component, event, helper) {
        component.set("v.currentPageNumber", parseInt(event.target.name));
        console.log(component.get("v.currentPageNumber"));
        helper.buildData(component, helper);
    },
    
    onFirst : function(component, event, helper) {        
        component.set("v.currentPageNumber", 1);
        helper.buildData(component, helper);
    },
    
    onLast : function(component, event, helper) {        
        component.set("v.currentPageNumber", component.get("v.totalPages"));
        helper.buildData(component, helper);
    },
    toogleSub: function(component, event, helper) {      
        helper.executeBackend(component, "toogleSubscription", { isSubscribed : component.get("v.buttonstate"),articleType :   component.get("v.selectedCategory")}, function(result) {
            console.log( result);
            component.set("v.buttonstate",result);
        });
    },
     handleSelect: function (component, event, helper) {
         var spinner = component.find("mySpinner");
         $A.util.removeClass(spinner, "slds-hide");
         var feedVal = event.getParam("value").split(',');
         var feedId = feedVal[0];
         var topicId = component.get("v.recordId");
         var methodName = feedVal[1] == 'pin' ? 'PinPost' : 'DeletePost';
         helper.executeBackend(component,methodName, {feedId : feedId,topicId:topicId}, function(results) {
             var result = results.feed;
             component.set("v.pinnedArticles",results.pinnedfeeds);
             component.set("v.totalPages", Math.ceil(result.length/component.get("v.pageSize")));
             var i = 1;
             var arrayList = [];
             while(i <= component.get("v.totalPages")){
                 arrayList.push(i);
                 i++;
             }
             component.set("v.totalPagesList",arrayList);
             component.set("v.allData", result);
             component.set("v.currentPageNumber",1);
             helper.buildData(component, helper);
             $A.util.addClass(spinner, "slds-hide");
         });
    },
    navigateToUserProfile : function(component, event, helper) {
        let userId = event.currentTarget.dataset.id;
        let pageURL = $A.get("$Label.c.ForumGamificationProfilePage");

        $A.get("e.force:navigateToURL").setParams({ 
            "url": "/"+pageURL+"?recordId=" + userId
        }).fire();
    }
})