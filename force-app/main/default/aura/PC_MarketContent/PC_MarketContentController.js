({
    doinit: function(component, event, helper) {
        //var replaced=component.get("v.name");
       // var buttonname=decodeURI(replaced); 
        //component.set("v.selectedTag",buttonname);
        helper.contentDetails(component, event, helper);
      },
     PreviewContent:function(component, event, helper) {
        var url= "/" + component.get("v.url"); 
        helper.gotoURL(component,event,url);//call helperCmp gotoURL method
    }
	
})