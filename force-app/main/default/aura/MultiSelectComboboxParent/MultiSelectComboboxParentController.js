({
	doInit : function( component, event, helper ) {
        var fromVF = component.get("v.recordList");
        var reason = [];
            Object.entries(JSON.parse(fromVF)).forEach(([key, value]) => reason.push({
                label: value,
                value: value 
            }));  
        component.set("v.options",JSON.stringify(reason));
        
    }
       
})