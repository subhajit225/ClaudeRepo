({
    handleSubmit : function(component, event, helper) {
       	helper.handleOnSubmit(component, event, helper);         
    },
     
    handleClose : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire() 
    },
    
    // function automatic called by aura:waiting event
    showSpinner: function(component, event, helper) {
        // make Spinner attribute true for displaying loading spinner 
        component.set("v.spinner", true); 
    },
     
    // function automatic called by aura:doneWaiting event 
    hideSpinner : function(component,event,helper){
        // make Spinner attribute to false for hiding loading spinner    
        component.set("v.spinner", false);
    }
})