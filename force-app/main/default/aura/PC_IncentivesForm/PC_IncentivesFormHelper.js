({
    validateForm: function(component) {
        var allValid = component.find('ccrFields').reduce(function (validFields, inputCmp) {
            inputCmp.showHelpMessageIfInvalid();
            return validFields && inputCmp.get('v.validity').valid;
        }, true);
        return (allValid);
    },
    
    getRecordTypeId : function(component, event,helper) {
        const params = {
            "sObjectType": component.get("v.sObjectType"),
            "recTypeName": component.get("v.recTypeName")
        };        
        helper.callServer(component, "c.getRecordType",params,function(response){
            if(!$A.util.isEmpty(response)){
                component.set("v.recTypeId",response);
                helper.loadNewRecord(component, event,helper);
            }
        },false);
    },
    
    getIncentiveForm: function(component, event, helper){
        const params = {
            "incentiveId" : component.get("v.id")
        };
        helper.callServer(component, "c.getIncentiveForm",params,function(response){
            //PRIT26-310
            if(!$A.util.isEmpty(response) && response.Name == $A.get("$Label.c.PC_IncentiveTechSPIFF")){
                component.set("v.isTechSPIFFForm",true);
            }
        },false);
    },
    
    loadNewRecord:function(component, event, helper) { 
        component.find("CCRRecordCreator").getNewRecord(
            "CCR__c", // sObject type (objectApiName)
            component.get("v.recTypeId"),        // recordTypeId 0121W0000009pMd
            false,     // skip cache?
            $A.getCallback(function() {
                var rec = component.get("v.CCR");
                var error = component.get("v.newIncentiveError");
                if(error || (rec === null)) {
                    console.log("Error initializing record template: " + error);
                }else{ 
                    helper.getUserDetails(component, event,helper);                    
                }
            })
        );
    },
    
    gotoURL:function(component, elementId, url) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({ url, isredirect: false });
        urlEvent.fire();
        
    },
    
    getUserDetails : function(component, event,helper) {
        var params={};        
        helper.callServer(component, "c.getUserDetails",null,function(response){
            if(!$A.util.isEmpty(response)){
                var partnerUser = response;
                component.set("v.ccrFields.Incentive__c",component.get("v.id"));
                component.set("v.ccrFields.Partner_Company_Name__c", partnerUser.AccountId);
                component.set("v.ccrFields.Partner_Rep_Phone_Number__c",partnerUser.contact.Phone);
                component.set("v.ccrFields.Partner_Rep_Email__c",partnerUser.contact.Email);  
            }
            false
        });
    },
    
    saveRecord:function(component, event,helper){
        helper.showSpinner(component);
        var action = component.get("c.saveCcrRecord"); 
        action.setParams({
            record:component.get("v.ccrFieldsClone"),
            ccrtype:component.get("v.Ctype"),
            
        });
        action.setCallback(this, function(response) { 
            if(response.getState() === "SUCCESS") {
                helper.hideSpinner(component);
                console.log('response.getReturnValue()--->'+response.getReturnValue());
                var resultsToast = $A.get("e.force:showToast");
                //PRIT26-20 : Changed logic to show errors
                if(response.getReturnValue().length == 15 || response.getReturnValue().length == 18){
                    resultsToast.setParams({
                        "title": "Saved",
                        "message": "The record was saved.",
                        "type": 'success',
                        "mode": 'pester',
                        duration:' 5000',
                    });
                    resultsToast.fire();
                    var url= "/" + component.get("v.url");  
                    helper.gotoURL(component, event,url);
                }else{
                    resultsToast.setParams({
                        "title": "Error",
                        "message": response.getReturnValue(),
                        "type": "error",
                        "mode": 'pester',
                        duration:' 500',
                    });
                    resultsToast.fire();
                }
            }  
            else if (response.getState() === "ERROR") {
                helper.hideSpinner(component);
                var toast = $A.get("e.force:showToast");
                if(toast){
                    toast.setParams({
                        "title": "Error",
                        "message": response.getError()[0].message,
                        "type": "error",
                        "mode": 'pester',
                        duration:' 500',
                    });
                }
                toast.fire();
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
    
})