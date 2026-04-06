({
	   
    GetFieldsWrapper : function(component,event) 
    {
        var action = component.get("c.getFields");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS")
            {
                var fieldsWrapper = response.getReturnValue();
                 component.set('v.FieldWrapper',fieldsWrapper);
                this.fillPicklist(component);
            }
        });
         $A.enqueueAction(action);
    },
    saveFormHelper : function(component,event,wrapper) {
        var action = component.get("c.SaveForm");
        action.setParams({ wrappers : JSON.stringify(wrapper)});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS")
            {
               component.set('v.IsSubmitted',false);
            } else
            {
                 component.set('v.IsSubmitted',true);
            }
        });
         $A.enqueueAction(action);
    },
    Validata : function(component,event) {
        var IsValid = true;
        var cmpTarget = component.find('Subject');
        if(cmpTarget!=null && cmpTarget!=undefined){
            var cmpTargetValue = cmpTarget.get("v.value"); 
            if(cmpTargetValue !=null && cmpTargetValue!=undefined && cmpTargetValue!=''){                
                               
            }else{
                IsValid = false;
                cmpTarget.showHelpMessageIfInvalid();
            }
        } 
        var cmpTarget = component.find('Type');
        if(cmpTarget!=null && cmpTarget!=undefined){
            var cmpTargetValue = cmpTarget.get("v.value"); 
            if(cmpTargetValue !=null && cmpTargetValue!=undefined && cmpTargetValue!=''){                
                               
            }else{
                IsValid = false;
                cmpTarget.showHelpMessageIfInvalid();
            }
        } 
         var cmpTarget = component.find('Description');
        if(cmpTarget!=null && cmpTarget!=undefined){
            var cmpTargetValue = cmpTarget.get("v.value"); 
            if(cmpTargetValue !=null && cmpTargetValue!=undefined && cmpTargetValue!=''){                
                               
            }else{
                IsValid = false;
                cmpTarget.showHelpMessageIfInvalid();
            }
        }
        return IsValid;
    },
    
    fillPicklist: function (component) {
        var opts = [
             {  label: "--None--", value:''},
            {  label: "Case", value: "Case"},
            {  label: "Knowledge Base", value: "Knowledge Base" },
            {  label: "Ideas", value: "Ideas" },
            {  label: "My Product", value: "My Product" },
            { label: "Docs & Downloads", value: "Docs & Downloads" }            
        ];
        component.set('v.options', opts);
    }
})