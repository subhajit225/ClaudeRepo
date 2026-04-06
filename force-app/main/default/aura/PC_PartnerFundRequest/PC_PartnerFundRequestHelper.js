({
    doInit: function (component, event, helper) {
        helper.getPicklist(component, event, 'Activity');
        //helper.getPicklist(component, event,'Campaign_Focus__c');
        helper.getPicklist(component, event, 'Alliances__c');
        helper.getPicklist(component, event, 'PO_Currency__c');
        helper.getPicklist(component, event, 'Activity_Objective__c');

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
                if (fieldAPIName == 'Activity' || fieldAPIName == 'Activity_Objective__c' || fieldAPIName == 'PO_Currency__c' || fieldAPIName == 'Campaign_Focus__c') {
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
                if (fieldAPIName == 'Activity') {
                    component.set("v.activitytypeoptions", arr);
                } else if (fieldAPIName == 'Alliances__c') {
                    component.set("v.allianceoptions", arr);
                } else if (fieldAPIName == 'PO_Currency__c') {
                    component.set("v.PoCurrencyOptions", arr);
                } else if (fieldAPIName == 'Activity_Objective__c') {
                    component.set("v.activityobjectiveoptions", arr);
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
    savePF: function (component, event, helper, isValidForm) {
        var controllerValueKey = component.get("v.PAllianceSelected");
        var options = '';
        if (!$A.util.isEmpty(controllerValueKey)) {
            for (var i = 0; i < controllerValueKey.length; i++) {
                if ($A.util.isEmpty(options)) {
                    options = controllerValueKey[i] + ';';
                } else {
                    options = options + controllerValueKey[i] + ';';
                }
            }
            component.set("v.Alliances__c", options);
        }
        component.set("v.Alliances__c", options);
        var isValid = true;
        isValid = isValidForm;
        var requiredFields = component.get("v.requiredFields");
        requiredFields.forEach(function (field) {
            if ($A.util.isEmpty(component.get("v." + field)) || $A.util.isUndefined(component.get("v." + field))) {
                isValid = false;
                helper.showErrorField(component, event, field);
            } else {
                helper.hideErrorField(component, event, field);
            }
        });

        if (isValid) {
            helper.showSpinner(component);
            var action = component.get("c.savePartnerFundReq");
            var rec = component.get("v.wrap");
            console.log(component.get("v.Activity_End_Date__c"));
            //prit26-11
            if(component.get('v.showDedicatedResourceSection') == false){
                component.set("v.Dedicated_Resource_Name__c",null);
                component.set("v.Job_Title__c",null);
                component.set("v.Measurements_of_Success_Q1__c",null);
                component.set("v.Measurements_of_Success_Q2__c",null);
                component.set("v.Measurements_of_Success_Q3__c",null);
                component.set("v.Measurements_of_Success_Q4__c",null);
            }
            //prit26-11
            console.log(rec);
            action.setParams({
                "title": component.get("v.Title"),
                "Activity": component.get("v.Activity"),
                "Activity_Objective": component.get("v.Activity_Objective__c"),
                "Alliances": component.get("v.Alliances__c"),
                "PO_Currency": component.get("v.PO_Currency__c"),
                "Activity_Start_Date": component.get("v.Activity_Start_Date__c"),
                "Activity_End_Date": component.get("v.Activity_End_Date__c"),
                "RequestedAmount": component.get("v.RequestedAmount"),
                "Description": component.get("v.Description"),
                "docIds": component.get("v.docIds"),
                "dedicatedResourceName" : component.get("v.Dedicated_Resource_Name__c"),
                "jobTitle" : component.get("v.Job_Title__c"),
                "mos1" : component.get("v.Measurements_of_Success_Q1__c"),
                "mos2" : component.get("v.Measurements_of_Success_Q2__c"),
                "mos3" : component.get("v.Measurements_of_Success_Q3__c"),
                "mos4" : component.get("v.Measurements_of_Success_Q4__c")
            });

            action.setCallback(this, function (response) {
                var saveResult = response.getState();
                helper.hideSpinner(component);
                if (response.getState() === "SUCCESS") {
                    var result = response.getReturnValue();
                    // record is saved successfully
                    if (result == "success") {
                        var resultsToast = $A.get("e.force:showToast");
                        resultsToast.setParams({
                            "title": "Submitted",
                            "message": "Thanks for submitting the request.",
                            "type": "success"
                        });
                        resultsToast.fire();
                        helper.navigateToURL(component, event, "/marketingfunds");
                    } else {
                        var resultsToast = $A.get("e.force:showToast");
                        resultsToast.setParams({
                            "title": "Error",
                            "message": result,
                            "type": "error"
                        });
                        resultsToast.fire();
                    }
                } else if (response.getState() === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " +errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                    var resultsToast = $A.get("e.force:showToast");
                    resultsToast.setParams({
                        "title": "Error",
                        "message": "Error occurred while submitting record",
                        "type": "error"
                    });
                    resultsToast.fire();
                }
            });
            $A.enqueueAction(action);
        }
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
    showErrorField: function (component, event, field) {
        $A.util.addClass(component.find(field), "slds-has-error");
        $A.util.removeClass(component.find(field + "_help"), "none");
    },
    /*
    * Hide the error help text for lightning inputField.
    */
    hideErrorField: function (component, event, field) {
        $A.util.removeClass(component.find(field), "slds-has-error");
        $A.util.addClass(component.find(field + "_help"), "none");
    },
})