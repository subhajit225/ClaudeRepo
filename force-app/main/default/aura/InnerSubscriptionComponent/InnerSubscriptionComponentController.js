({
	doInit : function(component, event, helper) {
		var map = component.get("v.catMAp");
        var dataCAt = component.get("v.dataString");
        console.log('datacat===' , map);
        component.set("v.dataCategList",map[dataCAt]);
	},
    UnsubscribeArticle  :function(component, event, helper) {
        helper.DelRecord(component, event, helper);
       
    }
})