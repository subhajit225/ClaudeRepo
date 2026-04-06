({
    doInit : function(component, event, helper) {
        var action = component.get("c.getSetupCompanyMaster");
        action.setCallback(this,function(response){
              var state = response.getState();
              if(state === "SUCCESS"){
              	  component.set("v.wcList",response.getReturnValue()); 
                  if(!$A.util.isEmpty(component.get("v.wcList"))){
                      component.set("v.EnableCM",component.get("v.wcList")[0].Enable_CM);
                      component.set("v.userDivision",component.get("v.wcList")[0].userDivision);              
                  }	
              }else if (state === "ERROR") {
                        var errors = response.getError();
                        if (errors) {
                            if (errors[0] && errors[0].message) {
                                console.log("v.content","Error message: " + 
                                            errors[0].message);
                            }
                        } else {
                            console.log("Unknown error");
                        }
                   } 
            helper.handlesaveLead(component, event, helper);
        }); 
        $A.enqueueAction(action);
    },
	handlesaveLead : function(component, event, helper) {
        if(!$A.util.isEmpty(component.get("v.sObjectInfo.CountryCode")) && component.get("v.sObjectInfo.isFederalIntel__c") == false && component.get("v.Enable_CM__c") == true){
            component.set("v.content","Please enter country"); 
            component.set("v.showcancel",true);
        }else{
            if (component.get("v.userDivision") == 'Inside Sales' && component.get("v.sObjectInfo.SDR_Led__c") == false) {
            	component.set("v.content",'Please check SDR Led checkbox');
                component.set("v.showcancel",true);
            }else{
                if (component.get("v.sObjectInfo.Converting__c") == true) {
                    if(component.get("v.EnableCM") == true){
                        component.find('navService').navigate({    
                            "type": "standard__component",
                            "attributes": {
                                "componentName": "c__leadConversionContainer"    
                            },    
                            "state": {
                                "c__leadId": component.get("v.sObjectInfo.Id")
                            }
                        });
                    }
                    //helper.gotoURL(component,'/apex/CustomLeadConversion?id='+component.get("v.sObjectInfo.Id"));
                    else
                    	helper.gotoURL(component,'/lightning/cmp/runtime_sales_lead__convertDesktopConsole?leadConvert__leadId='+component.get("v.sObjectInfo.Id"));
                } else {
                    component.set("v.sObjectInfo.Converting__c",true);
                    helper.serversidesave(component, event, helper, component.get("v.sObjectInfo"));
        		}
        	}
        }
       
	},
      serversidesave : function(component, event, helper, sobjectrec){
        var action = component.get("c.saveRecord");
        action.setParams({ rec : sobjectrec });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "ERROR") {
                var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Cannot update the record",
                        "duration": 10000,
                        "type": "error",
                        "message": response.getReturnValue()
                    });
                    toastEvent.fire(); 
                	$A.get("e.force:closeQuickAction").fire(); 
            }else if (state === "SUCCESS"){
                if(component.get("v.EnableCM") == true){
                    component.find('navService').navigate({    
                        "type": "standard__component",
                        "attributes": {
                            "componentName": "c__leadConversionContainer"    
                        },    
                        "state": {
                            "c__leadId": component.get("v.sObjectInfo.Id")
                        }
                    });    
                }
                //helper.gotoURL(component,'/apex/CustomLeadConversion?id='+component.get("v.sObjectInfo.Id"));
                 else
                   	helper.gotoURL(component,'/lightning/cmp/runtime_sales_lead__convertDesktopConsole?leadConvert__leadId='+component.get("v.sObjectInfo.Id"));
              
            }
             
        });
        // Send action off to be executed
        $A.enqueueAction(action);
    },    
     gotoURL : function (component, urlToNavigate) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({"url": urlToNavigate});
        urlEvent.fire();
    },
})