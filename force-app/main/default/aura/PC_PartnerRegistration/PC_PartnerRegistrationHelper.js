({
    validateForm: function(component) {
        var allValid = component.find('RegistrationFields').reduce(function (validFields, inputCmp) {
            inputCmp.showHelpMessageIfInvalid();
            return validFields && inputCmp.get('v.validity').valid;
        }, true);
        
        return (allValid);
    },
    /** For validating Zip Code **/
    validateFormInputFields: function(component, event, field){
        var countryValue=component.find("Country_Picklist__c").get("v.value");
        var allValid = true;
        if($A.util.isEmpty(component.get("v.RegistrationFields.Postal_Code__c")) && (component.get("v.RegistrationFields.Country__c") == 'US' || component.get("v.RegistrationFields.Country__c") == 'United States' || component.get("v.RegistrationFields.Country__c") == 'USA' )){
            $A.util.addClass(component.find(field), "slds-has-error");
            $A.util.removeClass(component.find(field+"_help"), "none");
            component.set('v.reqZipMsg','Complete this field.');
            allValid=false;
        }
        else if(!$A.util.isEmpty(component.get("v.RegistrationFields.Postal_Code__c")) && (component.get("v.RegistrationFields.Country__c") == 'US' || countryValue == 'United States' || component.get("v.RegistrationFields.Country__c") == 'USA' )){
            if(component.get("v.RegistrationFields.Postal_Code__c").length < 5 ){
                $A.util.addClass(component.find(field), "slds-has-error");
                $A.util.removeClass(component.find(field+"_help"), "none");
                component.set('v.reqZipMsg','Please enter a 5 digit Zip Code for a US Address.');
                allValid=false;
            }
            else
            {
                $A.util.removeClass(component.find(field), "slds-has-error");
                $A.util.addClass(component.find(field+"_help"), "none");
                component.set('v.reqZipMsg','');
            }
            // alert(allValid);
            return(allValid);
            
        }
    },
    loadNewRecord :function(component, event, helper){
        component.find("PartnerRecordCreator").getNewRecord(
            "Partner_Registration_Request__c", 
            null,        
            false,    
            $A.getCallback(function() {
                var rec = component.get("v.PartnerRequest");
                
                var error = component.get("v.newRegsitrationError");
                if(error || (rec === null)) {
                   // alert("Error initializing record template: " + error);
                }
            })
        );
    },
    
    /*
     * Show the error help text for lightning inputField.
     */
    showErrorField: function(component, event, field){
        $A.util.addClass(component.find(field), "slds-has-error");
        $A.util.removeClass(component.find(field+"_help"), "none");
    },
    
    /*
     * Hide the error help text for lightning inputField.
     */
    hideErrorField: function(component, event, field){
        $A.util.removeClass(component.find(field), "slds-has-error");
        $A.util.addClass(component.find(field+"_help"), "none");
    },
    saveRecord:function(component, event, helper){
        var partnerRegName=true;
        //alert('calling-->'+component.get("v.RegistrationFields"));
        helper.showSpinner(component);
        var action = component.get("c.savePartnerRecord"); 
        action.setParams({
            record:component.get("v.RegistrationFields"),
        });
        action.setCallback(this, function(response) { 
           // alert('state--->'+response.getState());
            if(response.getState() === "SUCCESS") {
                var result = response.getReturnValue();
                //alert('result-->'+result);
               if(result=='AccountNotexist'){
                  // alert('call1');
                    var resultsToast = $A.get("e.force:showToast");
                    resultsToast.setParams({
                        "title": "Saved",
                        "message": "Your are not a Partner with Rubrik.Please fill Partner onboarding form to be a Partner",
                        "type" : "success"
                    });
                    resultsToast.fire();
                    var onboaringUrl= "/"+'onboarding';  
                    var urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                        "url":onboaringUrl,
                        "redirect": false
                    });
                    urlEvent.fire(); 
                }
                else if(result=='Accountexist'){
                    //alert('call2');
                    var resultsToast = $A.get("e.force:showToast");
                    resultsToast.setParams({
                        "title": "Saved",
                        "message": "The record was saved.",
                        "type" : "success"
                    });
                    resultsToast.fire();
                    var url= "/"+'useraccesssubmit'  
                    var urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                        "url": url,
                        "redirect": false
                    });
                    urlEvent.fire(); 
                }
                    else if(response.getReturnValue()=="Duplicate"){
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            title : 'Error Message',
                            message:'You are already registered for the partner portal ',
                            messageTemplate: 'You are already registered for the partner portal with this Email ID. Note: Your username may be different than your email.Please visit {0} to reset your password.',
                            messageTemplateData: [{
                                url: 'https://rubrik.force.com/partners/',
                                label: 'here',
                                }
                            ],
                            duration:' 5000',
                            key: 'info_alt',
                            type: 'error',
                            mode: 'pester'
                        });
                        toastEvent.fire();
                        
                    }
                        else{
                            helper.showToast(component, event, helper, response.getReturnValue() , 'error');
                        }
                
            }
            else if (response.getState() === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && ( errors[0].message || errors[0].pageErrors)) {
                    	helper.showToast(component, event, helper, errors[0].message + errors[0].pageErrors , 'error');
                    }
                }
            }
            
           helper.hideSpinner(component); 
        });
        $A.enqueueAction(action);
        
    },
    showSpinner: function (component, event, helper) {
        var spinner = component.find("mySpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },
    
    hideSpinner: function (component, event, helper) {
        var spinner = component.find("mySpinner");
        $A.util.addClass(spinner, "slds-hide");
    }
})