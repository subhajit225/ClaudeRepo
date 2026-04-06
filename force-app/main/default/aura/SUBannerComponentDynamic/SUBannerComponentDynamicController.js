({
    doInit : function(component,event,helper) {
        helper.doInitFunc(component,event,helper);
    },
    searchButtonPress : function(component,event,helper) {
        helper.searchButtonPressFunc(component,event,helper);
    },
    fillSearchBoxOnSuggest : function(component,event,helper){
        var fillBoxData = event.getParam("searchString");
        component.set("v.searchString",fillBoxData);
    },
    enterKeySearch : function(component,event,helper) {
        helper.enterKeySearchFunc(component,event,helper);
    },
    mouseleft: function(component,event,helper){
        helper.mouseleftFunc(component,event,helper);
    },
    fillSearchbox: function(component,event,helper){
        if(component.get("v.isEnableTitleRedirect")){
            var url = event.currentTarget.dataset.url;
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
                "isredirect": true,
                "url": url
            });
            urlEvent.fire();
        }
        else{
                helper.fillSearchboxFunc(component,event,helper);
        }
    }
})