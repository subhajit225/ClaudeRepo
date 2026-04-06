({
	doInit : function(component, event, helper) {
        var parentString = component.get("v.ParentString");
        var Strlength = component.get("v.Strlength");
        if(parentString.length > Strlength ){
            component.set("v.SubbedString",parentString.substr(0,Strlength)+ '...' );
        }else{
            component.set("v.SubbedString",parentString);
        }
        console.log(component.get("v.SubbedString"));
	}
})