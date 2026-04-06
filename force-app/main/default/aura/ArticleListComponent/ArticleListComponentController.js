({
    doInit : function(component, event, helper) {
        /*var str = window.document.URL;
        var res = str.split("/s/kblistpage?categoryType_Article=");
        if(res[1].includes("&") == true){
            res = res[1].split("&")[0];
        }else{
            res = res[1];
        }*/
        var url_string = window.location.href;
        var url = new URL(url_string);
        var res = url.searchParams.get("categoryType_Article");
        var order = url.searchParams.get("sortBy");
        if(!!order){
            component.set("v.sortBy",order);

        }
        component.set("v.categoryType_Article",res);
        helper.getarticlevalue(component, event, helper);
        
    },
    
    pageChange : function(component,event,helper){
        var spinner = component.find("mySpinner");
        $A.util.removeClass(spinner,"slds-hide");
        var pageNumber = component.get("v.currentPageNumber");
        component.set("v.currentPageNumber", pageNumber-1);
        helper.buildData(component, helper,component.get("v.allData"));
        setTimeout(function(){ $A.util.addClass(spinner,"slds-hide");}, 1000);

        
    },
    nextPage : function(component,event,helper){
        var spinner = component.find("mySpinner");
        $A.util.removeClass(spinner,"slds-hide");
        var pageNumber = component.get("v.currentPageNumber");
        component.set("v.currentPageNumber", pageNumber+1);
        helper.buildData(component, helper,component.get("v.allData"));
        setTimeout(function(){ $A.util.addClass(spinner,"slds-hide");}, 1000);

    },
    getCategFilter : function(component, event, helper){
        var catg = event.getParam("CategFilter");
        var typeClicked = document.getElementById(catg);
        var fieldName = component.get("v.sortBy");
        component.set("v.selectedcateg", catg);
        var m  = window;
        var hrefNew = m.location.search;
        hrefNew = hrefNew.split('=');
        m.location.search = hrefNew[0]+"="+catg+'&sortBy='+fieldName;
        var catg = event.getParam("CategFilter");
        helper.getarticlevalue(component);
    },
    getSorted : function(component, event, helper){
        helper.sortData(component);
        helper.buildData(component, helper,component.get("v.allData"));
    },
    openCateg : function(component, event, helper) {
        
        var sideBarOpen = document.getElementById("myCategbar").style.width = "337px";
    },
    closeCateg : function(component, event, helper) {
        var sideBarOpen = document.getElementById("myCategbar").style.width = "0";
        
    },
    /* Not used
    deleteSubscription  : function(component, event, helper) {
        var str = window.document.URL;
        var res = str.split("/s/kblistpage?categoryType_Article=");
        var categ1 =   res[1];
        var action = component.get("c.DeleSubscription");
        action.setParams({
            label: categ1
        });
        action.setCallback(this, function(response){
            var result=response.getReturnValue();
            component.set("v.isSubscribed",result);
        });
        $A.enqueueAction(action);
        component.set("v.ModalOpen", true);
    },
    */
    manageSubscription  : function(component, event, helper) {
        var spinner = component.find("mySpinner");
        $A.util.removeClass(spinner,"slds-hide");
        var bool = component.get("v.isSubscribed");
        var categ =   component.get("v.categoryType_Article");
        var action = component.get("c.editSubscription");
        action.setParams({
            label: categ,
            isSubscribed: bool
        });
        action.setCallback(this, function(response){
            var result=response.getReturnValue();
            component.set("v.isSubscribed",result);
            $A.util.addClass(spinner,"slds-hide");
            component.set("v.ModalOpen", true);
        });
        $A.enqueueAction(action);   
       
    },
    closeBttn :function(component, event, helper) {
        component.set("v.ModalOpen", false);
    },
})