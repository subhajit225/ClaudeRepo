({
	handleClick : function(component, event, helper){
            helper.serversidesave(component, event, helper, component.get("v.sObjectInfoClone"));
                  
    },
    
    handleCancel : function(component, event, helper) {
        if(component.get("v.isInsideVF")){
            window.location.href = '/'+component.get("v.recordId");
            return;
        }
        $A.get("e.force:closeQuickAction").fire();     
    }
})