({   
    doInit: function(component, event, helper) {
      var pageName = component.get("v.pageName");
      /*  var pageName =  helper.getPageName();
        if($A.util.isEmpty(pageName)){
            pageName = component.get("v.pageName");
        }*/
        var action = component.get("c.getTiles");
        action.setParams({
            "pageName": pageName,
            "imageType": component.get("v.imageType")
        });
        action.setCallback(this, function(response) {
            
            if(response.getState() === "SUCCESS") {                
                component.set("v.imageList",response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },
    onSelect : function(component, event, helper) {
        var index = event.target.id;
        if(index >= 0){
            component.set("v.selectedIndex",index);
        }
        
    }    
   /* handleClick : function(component, event, helper) {
        
        var tile = component.get("v.imageList").find(record => record.Id === event.target.id);
        var url ;
        
        //Navigation url is present it will redirect to that page
        if(!$A.util.isEmpty(tile.Navigate_Url__c)){
            
            if(tile.Link_Type__c == 'Community Page'){
                url= "/" + tile.Navigate_Url__c;                
            } else if(tile.Link_Type__c == 'External URL'){
                url= tile.Navigate_Url__c;                
            }
            if(!$A.util.isEmpty(url)){
                helper.navigateToURL(component, event, url);
            }
        }
        
    } */
    
})