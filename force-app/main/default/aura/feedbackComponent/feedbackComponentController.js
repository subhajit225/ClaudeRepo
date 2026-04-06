({
	myAction : function(component, event, helper) {
		
	},
    doInit : function(component, event, helper) {         
		helper.GetFieldsWrapper(component,event);
	},
    SaveFormData : function(component, event, helper) {
       var IsValid = helper.Validata(component,event);  
        if(IsValid)
        {
            var wrapper = component.get("v.FieldWrapper");
			helper.saveFormHelper(component,event,wrapper);
            component.set("v.IsValid",true);
        }else
        {
            component.set("v.IsValid",false);
        }        
	},    
    validatedata : function(component, event, helper) {
        var IsValid = helper.Validata(component,event);  
        if(IsValid)
            component.set("v.IsValid",true);
        else{
            component.set("v.IsValid",false);
        }
    },
    changeForm :  function(component, event, helper) { 
       
         component.set('v.IsSubmitted',true);   
        component.set('v.FieldWrapper.Type','');  
        component.set('v.FieldWrapper.Subject','');
        component.set('v.FieldWrapper.Description','');
    },
    validateDesc : function(component, event, helper) { 
    var cmpTarget = component.find('Description');
        if(cmpTarget!=null && cmpTarget!=undefined){
            var cmpTargetValue = cmpTarget.get("v.value"); 
            if(cmpTargetValue !=null && cmpTargetValue!=undefined && cmpTargetValue!=''){                
                  component.set("v.IsDescriptionValid",false);             
            }else{
                       component.set("v.IsDescriptionValid",true);     
            }
        }
    }
 })