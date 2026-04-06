({
     gotoURL : function (component, event, url) {        
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url":url,
            "redirect": false
        });
        urlEvent.fire();
    },
    
    gotoURL1 : function (component, event, url) {
        var incentiveid=event.target.id;
        if(incentiveid==null ||incentiveid==''){
           incentiveid=event.getSource().get("v.value");
        }
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url":url+'?incentiveId='+incentiveid,
            "redirect": false
        });
        urlEvent.fire();
    }
})