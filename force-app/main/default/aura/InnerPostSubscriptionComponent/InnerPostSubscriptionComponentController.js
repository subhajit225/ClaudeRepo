({
    doInit : function(component, event, helper) {
		var map = component.get("v.catMAp");
        var dataCAt = component.get("v.dataString");
        console.log('datacat===' , map);
        component.set("v.dataCategList",map[dataCAt]);
        console.log( component.get("v.dataCategList"));
    },
    
    Unsubscribepost  :function(component, event, helper) {
        helper.DelRecord(component,event, helper);
        window.location.reload();
      
    }
	
	
})