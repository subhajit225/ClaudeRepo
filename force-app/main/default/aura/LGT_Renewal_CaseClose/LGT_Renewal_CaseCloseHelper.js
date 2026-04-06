({
	fetchBaseUrl : function(component, event) {
        var url = window.location.href;
        var pathname = window.location.pathname;
        var index1 = url.indexOf(pathname);
        var index2 = url.indexOf("/", index1 );
        var baseUrl = url.substr(0, index2);
        if(baseUrl!= null && baseUrl!=''){
            return baseUrl;
        }else{
            return null;
        }
    },
    setDuplicateCaseId : function(component) {
        var action = component.get("c.getDuplicateCaseRecord");
        action.setParams({'recordId':component.get('v.recordId')});
        action.setCallback(this, function(response){
            var duplicateCase = response.getReturnValue();
            if(response.getState() === "SUCCESS" && duplicateCase != null){
                component.set("v.duplicateCase", duplicateCase);
                this.populateDuplicateCaseId(component, duplicateCase);
            }
        });
        $A.enqueueAction(action);
    },
    populateDuplicateCaseId : function(component, duplicateCaseRecord) {
        var duplicateCaseIdLookupComp = component.find("duplicateCaseIdLookup");
        if(!!duplicateCaseIdLookupComp)
            duplicateCaseIdLookupComp.prepopulateLookupMethod(duplicateCaseRecord);
    }
})