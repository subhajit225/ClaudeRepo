({
	save : function(component, event, helper) {
		var recIdVar = '';
        var amountVar = '';
        var DescriptionVar = '';
        var fiscalQuarterVar = '';
        var mos1Var = '';
        var mos2Var = '';
        var mos3Var = '';
        var mos4Var = '';
        if(!$A.util.isUndefined(component.get("v.recordId"))){
            recIdVar = component.get("v.recordId");
        }
        if(!$A.util.isUndefined(component.get("v.Amount"))){
            amountVar = component.get("v.Amount");
        }
        if(!$A.util.isUndefined(component.get("v.Description"))){
            DescriptionVar = component.get("v.Description");
        }
        //prit26-12
        if(component.get('v.showDedicatedResourceSection') == true){
            if(!$A.util.isUndefined(component.get("v.Fiscal_Quarter__c"))){
                fiscalQuarterVar = component.get("v.Fiscal_Quarter__c");
            }
            mos1Var = component.get("v.Measurements_of_Success_Q1__c");
            mos2Var = component.get("v.Measurements_of_Success_Q2__c");
            mos3Var = component.get("v.Measurements_of_Success_Q3__c");
            mos4Var = component.get("v.Measurements_of_Success_Q4__c");
        }
        //prit26-12
        
        var action;
        helper.showSpinner(component);
        console.log('@@ Page '+component.get("v.vfHost")+"/apex/FileUploadVF");
        var vfOrigin = component.get("v.vfHost")+"/apex/FileUploadVF";
        var vfWindow = component.find("vfFrame1").getElement().contentWindow;
        
        
        vfWindow.postMessage(component.get("v.AttList"), vfOrigin);
        // send parameters to VF page to save the template
        vfWindow.postMessage({"amount":amountVar,"recId":recIdVar,"Description":DescriptionVar,"fiscalQuarter":fiscalQuarterVar,"measurementOfSuccess1":mos1Var,"measurementOfSuccess2":mos2Var,"measurementOfSuccess3":mos3Var,"measurementOfSuccess4":mos4Var}, vfOrigin);//prit26-12
        
        console.log('inside postMessage');
        window.addEventListener("message", function(event) {
            var json = JSON.stringify(event.data);
            var temp = JSON.parse(json);
            var MsgStatus = temp.status;
            var contentVersionVar = '';
            contentVersionVar = temp.contentVersionIds;
            
            if(MsgStatus == 'SUCCESS'){
                // on save success 
                console.log('Success in save'); 
                helper.hideSpinner(component);
                var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "title": "Submitted",
                    "message": "Thank you for submitting your claim.",
                    "type" : "success"
                });
                resultsToast.fire();
                helper.navigateToURL(component, event, "/marketingfundsdetail?recordId="+recIdVar); 
            }else{
                // If failed in save action
                helper.hideSpinner(component);
                var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "title": "Error",
                    "message": "Error occurred while submitting record. Please refresh the page and try again",
                    "type" : "error"
                });
                resultsToast.fire();
                
            }
            console.log('Success action');
        }, false); 
            
	},
    getPicklist: function (component, event, fieldAPIName) {
        var action = component.get("c.getPicklistValues");
        action.setParams({
            'fieldName': fieldAPIName
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var arr = [];
                if (fieldAPIName == 'Fiscal_Quarter__c') {
                    arr = [
                        { value: "", label: "--None--" }
                    ];
                }
                //console.log(response.getReturnValue());
                response.getReturnValue().forEach(function (labelval) {
                    var temp = labelval.split(';');
                    var temparr = [];
                    temparr['label'] = temp[0];
                    temparr['value'] = temp[1];
                    arr.push(temparr);
                });
                if (fieldAPIName == 'Fiscal_Quarter__c') {
                    component.set("v.fiscalQuarterOptions", arr);
                } 

            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +
                            errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
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
})