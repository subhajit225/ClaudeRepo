({ 
init : function(component, event, helper) {
    window.location = '/'+component.get("v.recId");
/*$A.get("e.force:navigateToSObject").setParams({
"recordId": component.get("v.recId"),
"slideDevName": "related"
}).fire();*/
}
})