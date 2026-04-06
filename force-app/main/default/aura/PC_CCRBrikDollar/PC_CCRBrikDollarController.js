({
    doInit: function(component, event, helper) {
        helper.fetchCcrAmount(component, event, helper);
    },
    handleClick : function(component, event, helper) {
        var navigationUrl=component.get("v.Navurl");
        if(!$A.util.isEmpty(navigationUrl)){
             var url= "/"+navigationUrl;
             helper.gotoURL(component, event, url);
        }
       // var url= "/" + component.get("v.url");        
       // helper.gotoURL(component, event, url);
    }
})