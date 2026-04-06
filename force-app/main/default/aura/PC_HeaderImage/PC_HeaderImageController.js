({
    doInit : function(component, event, helper) {
        var deviceType = $A.get("$Browser.formFactor");
        if( deviceType == 'DESKTOP'){
            
        }else if( deviceType == 'PHONE'){
            if(!$A.util.isEmpty(component.get("v.header"))){
                component.set("v.imgurl",component.get("v.header"));                
            }
            if(!$A.util.isEmpty(component.get("v.label"))){
                component.set("v.imgHeight",component.get("v.label"));
            }
        }else if(deviceType == 'TABLET' ){
            
        }
    }
})