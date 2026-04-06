({ 
    
   
    handleOnSubmit : function(component, event, helper) {
        event.preventDefault();
        helper.handleFormSubmit(component, event, helper); 
    },
    
       /* handleSuccess : function(component, event, helper) {
         console.log('callSuccess-----');
         var params = event.getParams();
        console.log('created Id: '+params.response.id);
         var action = component.get("c.doCallout");
        action.setParams({
           // "recordId": params.response.id  
           "recordId":component.get("v.rscRecordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
              if(state == "SUCCESS"){
                  console.log('callout triggered--');
              }
        });
         var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title : 'Success',
                message: 'RSC Process is a successfully created',
                duration:' 5000',
                key: 'info_alt',
                type: 'success',
                mode: 'pester'
            });
            toastEvent.fire();
            $A.get("e.force:closeQuickAction").fire();
            component.set("v.reloadForm", false);
            
    },
   
     handleCancel : function(component, event, helper) {
        component.set("v.reloadForm", false);
        component.set("v.reloadForm", true);
        component.set("v.isReadOnly", true);
    },
    
    checkUploadField : function(component, event, helper) {
        component.set("v.renderCluster", false);
        component.set("v.openmodel",true);
        
        
    },
   
    
    closeModal : function(component,event,helper){
       component.set('v.openmodel',false);
        
    },
    upload: function(component, event, helper) {
       component.set('v.openmodel',false);
       component.set('v.showButton',false);
      component.set('v.setUploadAttribute',true);  
       
    },   */ 
    
    handleCreateLoad: function(component, event, helper) {
        component.set("v.showSpinner", false);
    },
     handleFreeTrial: function(component, event, helper) {
        component.set("v.isFreeTrial", true);
        component.set("v.showFirstScreen", false);
         helper.Init(component, event, helper);
        
    },
    handlePaid: function(component, event, helper) {
        component.set("v.isFreeTrial", false);
        component.set("v.showFirstScreen", false);
        helper.Init(component, event, helper);

    },
})