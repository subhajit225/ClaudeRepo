({
    doInit : function(component, event, helper) {
        var action = component.get("c.fetchUser");
        /*action.setParams({
            caseId: component.get("v.recordId")
        });*/
        action.setCallback(this,function(response) {
            var result = response.getReturnValue();
            if(result != null && result != ''){
                component.set("v.userInfo",result); 	
            }
        });
        $A.enqueueAction(action);
    },
    hideSection : function(component, event, helper) {
        component.set("v.hideDropdown",true);
    },
    showSection: function(component, event, helper) {
        component.set("v.hideDropdown",false);
    },
    openEditModal: function(component,event,helper){
        component.set('v.isOpen',true);
        var blurBackground = component.find("CSNS_BackgroundBlur");
        $A.util.addClass(blurBackground, 'blurBackgroundForModalForCSNS');
        document.body.style.overflowX = 'hidden';
        document.body.style.overflowY = 'hidden';
    },
    closeModal: function(component,event,helper){
        component.set('v.isOpen',false);
        var blurBackground = component.find("CSNS_BackgroundBlur");
        $A.util.removeClass(blurBackground, 'blurBackgroundForModalForCSNS');
        document.body.style.overflowX = 'scroll';
        document.body.style.overflowY = 'scroll';
    },
    handleSuccess: function(cmp, event, helper) {
        //For modal Save
        cmp.set('v.isOpen',false);
        $A.get('e.force:refreshView').fire();
        document.body.style.overflowX = 'scroll';
        document.body.style.overflowY = 'scroll';
        //location.reload();
    },
    showSpinner: function(component, event, helper) {        
        component.set("v.Spinner", true); 
    },
    
    hideSpinner : function(component,event,helper){        
        component.set("v.Spinner", false);
    },
})