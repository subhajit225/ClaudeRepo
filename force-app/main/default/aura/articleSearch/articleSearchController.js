({
	doInit : function(component, event, helper) {
		
        var testId = component.get("v.recordId");
        if(!!testId){
            var action = component.get("c.getArticlesApex");
            action.setParams({ 'caseId':component.get("v.recordId")});
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS")
                    {
                        var fieldsWrapper = response.getReturnValue();
                        component.set('v.existingArticles',fieldsWrapper);
                        if(response.getReturnValue().length == 0){
                        }else{
                        }
                    }    
            });
            
            $A.enqueueAction(action);
        }
        
	},
    getArticlesEnter : function(component, event, helper){
        if (event.keyCode === 13) {
			helper.getArticles(component,event,helper);
		}
    },
    getArticlesCLick : function(component, event, helper){
        helper.getArticles(component,event,helper);
    },
    removeArticle: function(component, event, helper){
    	var articleId = event.target.id;
        var action = component.get("c.removeFromCase1");
        action.setParams({
            articleId : articleId,
            caseId:component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var baseUrl = helper.fetchBaseUrl(component , event);
            var state = response.getState();
            if (state === "SUCCESS"){
            	if(component.get("v.type")!=null && component.get("v.type") !=undefined && component.get("v.type") !=''){
                	var message = 'close';
                    var vfOrigin = baseUrl;
                    
                    window.postMessage(message, vfOrigin);    
                }else if (window.location.href.includes('closeCase')){
                    alert('Article Removed Successfully');
                    component.set('v.articleList',null);
                    component.set("v.articleNumber",'');
                    $A.enqueueAction(component.get("c.doInit"));
                }else{
                    console.log('refresh else');
                    var message = 'refresh';
                    var vfOrigin = baseUrl;
                    window.postMessage(message, vfOrigin);
                    alert('Article Removed Successfully');
                    component.set('v.articleList',null);
                    component.set("v.articleNumber",'');
                    $A.enqueueAction(component.get("c.doInit"));
                }    
            }
        });
         $A.enqueueAction(action);
    },
    
    attachToCase : function(component, event, helper){
        var kbIds = component.get("v.kbIds");
        var action = component.get("c.attachToCase1");
        action.setParams({
            articleIds : kbIds,
            caseId:component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS")
            {
               component.find("accordion").set('v.activeSectionName', 'A');
                if(component.get("v.type")!=null && component.get("v.type") !=undefined && component.get("v.type") !=''){
                	var message = 'close';
                    var vfOrigin = baseUrl;
                    window.postMessage(message, vfOrigin);    
                }else if (window.location.href.includes('closeCase')){
                    //alert('Article Attached Successfully');
                    //component.set('v.articleList',null);
                    component.set('v.kbIds',null);
                    //component.set("v.articleNumber",'');
                    //$A.enqueueAction(component.get("c.doInit"));
                }else{
                    if(component.get("v.theme") == 'Theme4u'){
                        helper.refreshFocusedTab(component);
                    }
                    else {
                        let urlString = window.location.href;
                        var vfOrigin = urlString.substring(0, urlString.indexOf("/s"));
                        window.postMessage('refresh', vfOrigin);
                    }
                }
                var attachedArticles = component.get("v.existingArticles");
                var articleList = component.get("v.articleList");
                var remArticleList = [];
                for(var i=0;i<articleList.length;i++){
                    if(kbIds.includes(articleList[i].KnowledgeArticleId)){
                        attachedArticles.push(articleList[i]);
                    }else{
                        remArticleList.push(articleList[i]);
                    }
                }
                component.set('v.articleList',remArticleList);
                component.set('v.existingArticles',attachedArticles);
                component.set('v.kbIds',[]);
            }
        });
         $A.enqueueAction(action);
    },
    updateKbIds : function(component, event, helper){
        var kbIds = component.get("v.kbIds");
        var kbId = event.getSource().get("v.accesskey");
        if(event.getSource().get("v.checked")){
            kbIds.push(kbId);
        }else{
            var index = kbIds.indexOf(kbId);
            if (index > -1) {
                kbIds.splice(index, 1);
            }
        }
        component.set("v.kbIds",kbIds);
    },
    onNext : function(component, event, helper) {        
        var pageNumber = component.get("v.currentPageNumber");
        component.set("v.currentPageNumber", pageNumber+1);
        helper.pagination(component, helper);
    },
    
    onPrev : function(component, event, helper) {        
        var pageNumber = component.get("v.currentPageNumber");
        component.set("v.currentPageNumber", pageNumber-1);
        helper.pagination(component, helper);
    },
    
    processMe : function(component, event, helper) {
        component.set("v.currentPageNumber", parseInt(event.target.name));
        console.log(component.get("v.currentPageNumber"));
        helper.pagination(component, helper);
    },
    
    onFirst : function(component, event, helper) {        
        component.set("v.currentPageNumber", 1);
        helper.pagination(component, helper);
    },
    
    onLast : function(component, event, helper) {        
        component.set("v.currentPageNumber", component.get("v.totalPages"));
        helper.pagination(component, helper);
    }
})