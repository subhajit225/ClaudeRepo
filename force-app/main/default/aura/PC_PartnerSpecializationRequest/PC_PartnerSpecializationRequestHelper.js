({
	doInit : function(component, event, helper) {
        
        component.set("v.showSpinner", true);
                
        var action = component.get("c.getAccountAndContacts");
        action.setParams({         
        });
        action.setCallback(this, function(response){
            component.set("v.showSpinner", false);
            if (response.getState() === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && ( errors[0].message || errors[0].pageErrors)) {
                    	helper.showToast(component, event, helper, errors[0].message + errors[0].pageErrors , 'error');
                    }
                    return;
                }
            }
            var data = response.getReturnValue();
            if(!data.isSuccess){
                helper.showToast(component, event, helper, data.errorMessage , 'error');
                return;
            }
            component.set("v.accountRecords", data.accList);
            component.set("v.userRecord", data.userRecds[0]);
            
        });
        $A.enqueueAction(action);
	},
    
    createPSRec : function(component, event, helper, fields) {
        component.set("v.showSpinner", true);  
        var action = component.get("c.createSpecilizationRequest");
        action.setParams({ 
            "spReq": fields
        });
        action.setCallback(this, function(response) {
            
            if (response.getState() === "ERROR") {
                component.set("v.showSpinner", false);
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && ( errors[0].message || errors[0].pageErrors)) {
                        helper.showToast(component, event, helper, errors[0].message + errors[0].pageErrors , 'error');
                    }
                    return;
                }
            }
            var data = response.getReturnValue();
            if(!data.isSuccess){
                component.set("v.showSpinner", false);
                helper.showToast(component, event, helper, data.errorMessage , 'error');
                return;
            }
            helper.showToast(component, event, helper, 'Request has been successfully submited' , 'success'); 
            var url = window.location.href;
            if(url.includes('partnersnew'))
            	helper.navigateToURL(component, event, "/partnersnew/s/program-partner-specializations"); 
            else
                helper.navigateToURL(component, event, "/s/program-partner-specializations"); 
        });
        $A.enqueueAction(action)
    },
    
    openAgreementModel : function(component, event, helper) {
         var height =  document.documentElement.scrollHeight + document.documentElement.clientHeight;
         component.set("v.iframeheight", height);
         component.set("v.isOpenAgreement", true);
         var vfOrigin = component.get("v.vfHost");
       	 window.addEventListener("message", function(event) {
            console.log(event.data.name);
            // Only handle messages we are interested in
            if (event.data.name === "RUBRIK_PROFESSIONAL_SERVICES_PARTNER") { 
                // Handle the message
                var sectc = component.find("agreementCheckValue_help");

                if(event.data.payload == 'agreed'){
                    component.set("v.agreementCheckValue",true);
                    $A.util.addClass(sectc,"none");
                }else{
                    component.set("v.agreementCheckValue",false);
                    $A.util.removeClass(sectc,"none");
                }
                component.set("v.isOpenAgreement", false);
            }
            
        }, false);
      
    },
    
     handleOnSubmit : function(component, event, helper) {
        if(component.get("v.showSpinner")) return;
        var sectc = component.find("agreementCheckValue_help");
        if(component.get("v.agreementCheckValue") == true ){ 
            $A.util.addClass(sectc,"none");
            var accRec = component.get("v.accountRecords")[0];
            var eventFields = event.getParam("fields"); //get the fields
            eventFields.Contact__c =component.get("v.userRecord").ContactId;
            if(!component.get("v.isAddressEditable")){
                eventFields.Street__c = accRec.BillingStreet;
                eventFields.City__c = accRec.BillingCity;
                eventFields.Country__c = accRec.BillingCountry;
                eventFields.State__c = accRec.BillingStateCode;
                eventFields.Postal_Code__c = accRec.BillingPostalCode;
            }
            eventFields.Partner_Company_Name__c = component.get("v.accountRecords[0].Id");
            helper.createPSRec(component, event, helper, eventFields );
            
        }else if(component.get("v.agreementCheckValue") == false ){
            $A.util.removeClass(sectc,"none");
        }
       
    },
    
})