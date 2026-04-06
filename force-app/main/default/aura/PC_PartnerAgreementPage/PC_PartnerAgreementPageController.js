({
	doInit : function(component, event, helper) {
        var action = component.get("c.getEmail");
        action.setCallback(this, function(a) {
            console.log(a.getReturnValue());
            component.set("v.userEmail",a.getReturnValue());
            
        });
        $A.enqueueAction(action);
        
        var action1 = component.get("c.getpartnerType");
        action1.setCallback(this, function(a) {
            console.log(a.getReturnValue());
            component.set("v.partnerType",a.getReturnValue());
             if(component.get("v.partnerType") == ''){
            
            }else{
                var master = component.find("masterlink");
                $A.util.removeClass(master, 'disable');
            }
        });
        $A.enqueueAction(action1);
        
       
		var currenturl = window.location.href;
        if(currenturl.search('/s') >= 0){
            var temp = currenturl.split('/s');
            component.set("v.vfHost",temp[0]);
        }
	},
    openMasterModel : function(component, event, helper) {
        var height =  document.documentElement.scrollHeight + document.documentElement.clientHeight;
        component.set("v.isOpenMaster", true);
        var vfOrigin =  component.get("v.vfHost");
        window.addEventListener("message", function(event) {
            console.log(event.data.name);
            
            // Only handle messages we are interested in
            if (event.data.name === "Master-Reseller") {
                // Handle the message
                if(event.data.payload == 'agreed'){
                    component.set("v.masterCheckValue",true);
                }else{
                    component.set("v.masterCheckValue",false);
                }
                component.set("v.isOpenMaster", false);
            }
        }, false);
    },
    closeMasterModel: function(component, event, helper) {
        // for Hide/Close Model,set the "isOpenMaster" attribute to "Fasle"  
        component.set("v.isOpenMaster", false);
    },
    handleSaveForm : function(component, event, helper) {
        var termschecked = true;
        var mastc = component.find("masterCheckValue_help");
        if(component.get("v.masterCheckValue") == false ){
            $A.util.removeClass(mastc,"none"); 
            termschecked = false;
        }else{
            $A.util.addClass(mastc,"none"); 
        }
        if(termschecked){
         	helper.save(component, event,helper); 
        }
    }
})