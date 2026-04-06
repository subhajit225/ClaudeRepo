({
    doInit : function(component, event, helper) {
        var str = window.document.URL;
        var res = str.split("/s/article/");
        console.log('ss===' , res[1]);
        component.set("v.UrlName" , res);
        var e = component.get("v.recordId");
         console.log('e===' ,e);
        helper.SubscribedArticle(component, event, helper);
        
    },
    manageSubscription  : function(component, event, helper) {
        
        var bool = component.get("v.isSubscribed");
        if(bool == null )
            return;
        helper.deleteSubscription(component, event, helper);
        
    },
    closeBttn :function(component, event, helper) {
        component.set("v.ModalOpen", false);
    },
    
    redirect: function(component, event, helper){
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": "/kblistpage?categoryType_Article=All"
        });
        urlEvent.fire();
    }
    
})