({
    doInit: function(component, event, helper) {
        component.set("v.imageUrl",'');
        var deviceType = $A.get("$Browser.formFactor");
        var pageName =  helper.getPageName();
        
        if($A.util.isEmpty(pageName)){
            pageName = component.get("v.pageName")
        }
        
        var action = component.get("c.getBanner");
        action.setParams({
            "pageName": pageName,
            "imageType": component.get("v.imageType")
        });
        action.setCallback(this, function(response) {
           
            if(response.getState() === "SUCCESS") {
                var response = response.getReturnValue();
               
                if(!$A.util.isEmpty(response)){
                    debugger;
                    component.set("v.banner",response);
                     
                    if(!$A.util.isEmpty(response.Image_Height__c)){
                        component.set("v.imgHeight",response.Image_Height__c);
                    }                    
                    
                    var imageUrl ;                   
                    
                    if( deviceType == 'PHONE' && (!$A.util.isEmpty(response.Mobile_Image_Url__c))){
                        
                        if(!$A.util.isEmpty(response.Static_Resource_Name__c)){
                            imageUrl = $A.get('$Resource.'+ response.Static_Resource_Name__c) + response.Mobile_Image_Url__c;
                        }else{
                            imageUrl = response.Mobile_Image_Url__c;
                        }
                    }else{
                        if(!$A.util.isEmpty(response.Static_Resource_Name__c)){
                            imageUrl = $A.get('$Resource.'+ response.Static_Resource_Name__c) + response.Image_Url__c;
                        }else{
                            imageUrl = response.Image_Url__c;
                        }                        
                        
                    }
                    component.set("v.imageUrl",imageUrl);
                    
                    
                    /*
                    if( deviceType == 'DESKTOP' || deviceType == 'TABLET'){
                        
                        if(!$A.util.isEmpty(response.Static_Resource_Name__c)){
                            imageUrl = $A.get('$Resource.'+ response.Static_Resource_Name__c) + response.Image_Url__c;
                        }else{
                            imageUrl = response.Image_Url__c;
                        }                        
                        component.set("v.imageUrl",imageUrl);
                    }else if( deviceType == 'PHONE'){
                        if(!$A.util.isEmpty(response.Mobile_Image_Url__c)){
                            
                            if(!$A.util.isEmpty(response.Static_Resource_Name__c)){
                                imageUrl = $A.get('$Resource.'+ response.Static_Resource_Name__c) + response.Mobile_Image_Url__c;
                            }else{
                                imageUrl = response.Mobile_Image_Url__c;
                            }
                            
                            component.set("v.imageUrl",response.Mobile_Image_Url__c);                
                        }else{
                            component.set("v.imageUrl",response.Image_Url__c);
                        }
                    }
                    */
                } 
            }
        });
        $A.enqueueAction(action); 
    },
})