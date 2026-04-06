({
    /*
     * Get the Record Type ID.
     */
    doInit : function(component, event,helper) {
        
        helper.getRecordTypeId(component, event,helper);
    },
   
    /*
     * Get the Record Type ID.
     */
    getRecordTypeId : function(component, event,helper) {
        var params = {
            "sObjectType": component.get("v.sObjectType"),
            "recTypeName": component.get("v.recTypeName")
        };
        helper.callServer(component, "c.getRecordType",params,function(response){
            if(!$A.util.isEmpty(response)){
                component.set("v.recTypeId",response);
                helper.loadNewRecord(component, event,helper);
            }
        },false);
    } ,
    
    /*PRIT-340-start
     * Load values for Deal Reg Form
     */
    getRecordDetails : function(component, event, helper, objId, objName){
        //call apex
        //console.log('apex calling 37->');
        var action = component.get('c.getRecordDetails');
        action.setParams({ 
            'objectId' : objId,
            'objectName' : objName
        });
        action.setCallback(this, function(response) {
            var responseValue = response.getReturnValue(); 
            //console.log('responseValue-->'+JSON.stringify(responseValue));
            
            component.set('v.dealRegFields.FirstName__c',responseValue.FirstName);
            component.set('v.dealRegFields.LastName__c',responseValue.LastName);
            component.set('v.dealRegFields.Title__c',responseValue.Title);
            component.set('v.dealRegFields.Email__c',responseValue.Email);
            component.set('v.dealRegFields.Phone__c',responseValue.Phone);
            component.set('v.dealRegFields.Lead_Share_Campaign__c', true);
            component.set('v.dealRegFields.Date_of_Event__c', responseValue.Last_MQL_Date__c);
            component.set('v.dealRegFields.Save_the_Data_Event__c',"No");
            component.set('v.dealRegFields.End_User_attend_a_Marketing_Event__c',"Yes");
            component.set('v.dealRegFields.Lead_Source__c', responseValue.LeadSource);
            if(objName == 'Lead'){
                component.set("v.dealRegFields.Company__c", responseValue.Company);
                component.set('v.selectedCompanyValue', responseValue.Company);
                if(responseValue.Company != undefined){
                    component.set('v.companyDisabled', true);
                }
                component.set('v.dealRegFields.Country__c',responseValue.Country);
                component.set('v.dealRegFields.Street__c', responseValue.Address);
                component.set('v.dealRegFields.City__c',responseValue.City);
                component.set('v.dealRegFields.StateCode__c',responseValue.StateCode);
                component.set('v.dealRegFields.Street__c', responseValue.Street);
                component.set('v.dealRegFields.PostalCode__c',responseValue.PostalCode);
                component.set('v.dealRegFields.Customer_Category__c',responseValue.Customer_Category__c);
                component.set('v.dealRegFields.Lead__c', objId);
            }else{
                component.set("v.dealRegFields.Company__c", responseValue.Account.Name);
                component.set('v.selectedCompanyValue', responseValue.Account.Name);
                if(responseValue.mkto71_Inferred_Company__c != undefined){
                    component.set('v.companyDisabled', true);
                }
                component.set('v.dealRegFields.Country__c',responseValue.MailingCountry);
                component.set('v.dealRegFields.Street__c', responseValue.MailingStreet);
                component.set('v.dealRegFields.City__c',responseValue.MailingCity);
                component.set('v.dealRegFields.PostalCode__c',responseValue.MailingPostalCode);
                component.set('v.dealRegFields.StateCode__c',responseValue.MailingStateCode);
                component.set('v.dealRegFields.Primary_Contact__c', objId);
            }
            component.set("v.leadDashboardDisabled", true);
            //console.log('dealRegFields--->',JSON.stringify(component.get('v.dealRegFields')));
        });
        // Enqueue Action
        $A.enqueueAction(action);
    },
    //PRIT-340-end
    
    /*
     * Load a new record from template using LDS
     */
    loadNewRecord: function(component, event, helper) {
        // Prepare a new record from template
        component.find("dealRegRecordCreator").getNewRecord(
            "Deal_Registration__c", // sObject type (objectApiName)
            component.get("v.recTypeId"),      // recordTypeId 0121W0000009pMd
            false,     // skip cache?
            $A.getCallback(function() {
                var rec = component.get("v.newDealReg");

                var error = component.get("v.newRecordError");
                if(error || (rec === null)) {
                    console.log("Error initializing record template: " + error);
                }else{  
                    //PRIT-340-start
                    var objId = component.get('v.objectId');
                    var objName = component.get('v.objectName');
                    if(objId != null && objName != null){
                        helper.getRecordDetails(component, event, helper, objId, objName);
                    }
                    //PRIT-340-end
                    helper.getUserDetails(component, event,helper);                    
                    helper.showRequiredFields(component, event);
                }
            })
        );

        //  helper.fetchPicklistFields(component, event);
    },

    /*
     * Get the Logged in user deatils.
     */
    getUserDetails : function(component, event,helper) {
        var params={};        
        helper.callServer(component, "c.getUserDetails",null,function(response){
            if(!$A.util.isEmpty(response)){
                var partner = response.userRec;
                var distiList = response.distributorList;
                var oemRecordTypeId = response.oemRecId;
                var distiName = '';
                component.set("v.partnerAccountDetails", partner); //PRIT26-548
				component.set("v.distiList", distiList);//PRIT26-548
                
                //PRIT24-776-start
                if(partner.Contact.Account.Type == "MSP" || partner.Contact.Account.Type == "MSP-Reseller"){
                    component.set("v.showManagedServicePopup","true");
                }
				//PRIT24-776-end
				
                if(partner.Contact.Account.Type == 'Distributor' || partner.Contact.Account.Type == 'OEM'){
                    component.set("v.isDistributor",true);
                    component.set("v.dealRegFields.Distributor__c", partner.Contact.AccountId);
                    component.set("v.dealRegFields.Distributor_Company_Name__c", partner.Contact.Account.Name);
                    component.set("v.distributorId", partner.Contact.AccountId);
                    if(partner.Contact.Account.Type == 'OEM'){
                        component.set('v.dealRegFields.RecordType.Id',oemRecordTypeId);
                        component.set('v.dealRegFields.RecordType.Name','OEM');
                        component.set('v.dealRegFields.RecordTypeId',oemRecordTypeId);
                        component.set('v.isNotOEM', false);
                    }
                }else{
                    component.set("v.dealRegFields.Partner_Rep_Email_Address__c", $A.get('$SObjectType.CurrentUser.Email'));
                    component.set("v.dealRegFields.Partner__c", partner.Contact.Account.Name);
                    component.set("v.dealRegFields.Partner_Lookup__c", partner.Contact.AccountId);
                    if(partner.Contact.Account.Distributor__c != null){
                        component.set("v.dealRegFields.Distributor__c", partner.Contact.Account.Distributor__c);
                        component.set("v.dealRegFields.Distributor_Company_Name__c", partner.Contact.Account.Distributor__r.Name);
                        component.set("v.distributorId", partner.Contact.Account.Distributor__c);
                    }
                    if(partner.Contact.Account.Type !== 'OEM')
                    {
                        $A.util.addClass(component.find('Rep_Name'), "customRequired");
                        $A.util.addClass(component.find('SE_Name'), "customRequired");
                        
                        let fields=component.get('v.requiredFields');
                        fields.push('Partner_Rep__c');
                        fields.push('Partner_SE_Name__c');
                        component.set('v.requiredFields',fields);
                        }
                }
                //PRIT24-445-start
                component.set('v.selectedPartnerRepNameValue',partner.Contact.Name);
                component.set('v.dealRegFields.Partner_Rep__c', partner.Contact.Name);
                component.set('v.dealRegFields.Partner_Rep_Email_Address__c', partner.Contact.Email);
                component.set('v.dealRegFields.Partner_Rep_Title__c',partner.Contact.Title);
                component.set('v.dealRegFields.Partner_Rep_Phone_Number__c',partner.Contact.Phone);
                //PRIT24-445-end
                //PRIT26-548 -start
                helper.evaluateDistributorLogic(component);
                /*if((partner.Contact.Account.BillingCountry != "" 
                   && partner.Contact.Account.BillingCountry != "United States" 
                   && partner.Contact.Account.Type != 'OEM') || (partner.Contact.Account.BillingCountry == "United States" 
                                                                && (component.get("v.dealRegFields.Customer_Category__c") == "State & Local Govt/Education" 
                                                                    || component.get("v.dealRegFields.Customer_Category__c") == "Federal Govt"))){
                    component.set("v.showDistributor",true);
                    let arr = [];
                    distiList.forEach(function(labelval){
                        let temp = labelval.split(';');
                        let temparr = [];
                        temparr['label'] = temp[0];
                        temparr['value'] = temp[1];
                        arr.push(temparr);
                    });
                    component.set("v.optionsDistributor__c",arr);
                }*/
                //PRIT26-548 - end
            }
        },false);
    } ,

    /*
     * Get the Partner Account Details based on email.
     */
    /* : function(component, event,helper) {
        var partnerRepEmail = component.get("v.dealRegFields.Partner_Rep_Email_Address__c");

        if(!$A.util.isEmpty(partnerRepEmail)){
            var params = {
                "partnerRepEmail": partnerRepEmail
            };

            helper.callServer(component, "c.getPartnerRepAccount",params,function(response){
                if(!$A.util.isEmpty(response)){
                    for(field in objName){
                        var optionValues = objName[field];
                        this.buildPicklist(component, field, optionValues);
                    }
                    component.set("v.dealRegFields.Partner__c", response["partnerAccountName"]);
                    component.set("v.dealRegFields.Partner_Lookup__c", response["partnerAccountId"]);
                }
            },false);
        }else{
        }
    } ,*/

    /*
     * Save the Deal Registration.
     */
    saveDealReg : function(component, event,helper) {
        helper.showSpinner(component);
        var action = component.get("c.saveDealReg");
        var vDealReg = component.get("v.dealRegFields");
        if(vDealReg.Partner_Lookup__c == ''){
            vDealReg.Partner__c = '';
        }
        
        action.setParams({
            "vDealReg": vDealReg
        });

        action.setCallback(this, function(response) {
            helper.hideSpinner(component);
            var toastTitle = "Error"
            var toastMessage = "Unable to Submit a Deal.";

            var saveResult = response.getState();

            if(response.getState() === "SUCCESS") {
                var result = response.getReturnValue();
                if(result){
                    // record is saved successfully
                    toastTitle = "Submitted";
                    toastMessage = "Deal Registration was successfully submitted!";
                }
            }else if (response.getState() === "ERROR") {
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

            var resultsToast = $A.get("e.force:showToast");
            resultsToast.setParams({
                "title": toastTitle,
                "message": toastMessage
            });
            resultsToast.fire();

            if(toastTitle === "Submitted"){
                helper.navigateToURL(component, event, "/dealreglist");
            }
        });

        $A.enqueueAction(action);
    } ,

    /*
     * Check Form required inpuytField validations
     * */
    validateFormInputFields : function(component, event) {
        var allValid = true;
        var requiredFields = component.get("v.requiredFields");
        var helper = this;
        console.log(requiredFields);
        requiredFields.forEach(function(field) {
            if($A.util.isEmpty(component.get("v.dealRegFields."+field))){
                if(field == 'StateCode__c') {
                    //   || (component.get("v.dealRegFields.Country__c") == 'United States' || component.get("v.dealRegFields.Country__c") == 'Canada')) {
                    // helper.showErrorField(component, event, field);
                    // allValid = false;
                    var requiredStateCountry = component.get("v.requiredStateCountry");
                    var isStateRequired = false;
                    if($A.util.isArray(requiredStateCountry)){
                        isStateRequired = requiredStateCountry.includes(component.get("v.dealRegFields.Country__c"));
                    }
                    if(isStateRequired){
                        helper.showErrorField(component, event, field);
                        allValid = false;
                    }else{
                        helper.hideErrorField(component, event, field);
                    }
                }else{ 
                    if(((field==='Partner_SE_Name__c' || field==='Partner_Rep__c') && component.get('v.isNotOEM')) || (field==='Partner_SE_Name__c' && field==='Partner_Rep__c'))
                    helper.showErrorField(component, event, field);
                    allValid = false;
                }
            }else{
                helper.hideErrorField(component, event, field);
            }
        });
        return(allValid);
    },

    /*
     * Check Form required input validations.
     */
    validateForm: function(component) {
        // Show error messages if required fields are blank
        var allValid = component.find('dealRegField').reduce(function (validFields, inputCmp) {
            inputCmp.showHelpMessageIfInvalid();
            return validFields && inputCmp.get('v.validity').valid;
        }, true);

        return(allValid);
        //return(validNewRecord);
    },

    /*
     * Show the * for required lightning inputFields.
     */
    showRequiredFields: function(component, event){
        var requiredFields = component.get("v.requiredFields");
        requiredFields.forEach(function(field) {
            $A.util.removeClass(component.find(field), "none");
        });
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

    showSpinner: function (component, event, helper) {
        var spinner = component.find("mySpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },

    hideSpinner: function (component, event, helper) {
        var spinner = component.find("mySpinner");
        $A.util.addClass(spinner, "slds-hide");
    },
    /* Backup -  START */
    /*
     * Save the Deal Registration Form using standard LDS method.
     */
    validateEmail : function(component, event, helper) {
        var allValid = component.find('dealRegFieldEmail').reduce(function (validFields, emailField) {
            var isValidEmail = true;
            var emailFieldValue = emailField.get("v.value");
            var regExpEmailformat = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;

            if(!$A.util.isEmpty(emailFieldValue)){
                if(!emailFieldValue.match(regExpEmailformat)){
                    emailField.set('v.validity', {valid:false, badInput :true});
                    $A.util.addClass(emailField, 'slds-has-error');
                }
            }else{
                emailField.set('v.validity', {valid:false, badInput :true});
            }
            emailField.showHelpMessageIfInvalid();
            return validFields && emailField.get('v.validity').valid;
        }, true);
        return(allValid);
    },

    saveFormBackup: function(component, event, helper) {
        component.find("dealRegRecordCreator").saveRecord(function(saveResult) {
            if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                // record is saved successfully
                var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "title": "Saved",
                    "message": "The record was saved."
                });
                resultsToast.fire();
                helper.navigateToURL(component, event, "/dealreglist");
                //this.gotoURL(component, event, "/dealreglist")
            } else if (saveResult.state === "INCOMPLETE") {
                // handle the incomplete state
                console.log("User is offline, device doesn't support drafts.");
            } else if (saveResult.state === "ERROR") {
                // handle the error state
                console.log('Problem saving Record, error: ' + JSON.stringify(saveResult.error));
            } else {
                console.log('Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
            }
        });
    },

    /*
     * Get the Record Type ID.
     */
    getRecordTypeIdBackup : function(component, event) {
        var action = component.get("c.getRecordType");
        action.setParams({
            "sObjectType": component.get("v.sObjectType"),
            "recTypeName": component.get("v.recTypeName")
        });

        action.setCallback(this, function(response) {
            if(response.getState() === "SUCCESS") {
                var recTypeId = response.getReturnValue();
                component.set("v.recTypeId", recTypeId);
            }
        });

        $A.enqueueAction(action);
    } ,

    /*
     * Get the logged in user details.
     */
    getUserDetailsBackup : function(component, event) {
        var action = component.get("c.getUserDetails");

        action.setCallback(this, function(response) {
            if(response.getState() === "SUCCESS") {
                var partner = response.getReturnValue();
                component.set("v.user", response.getReturnValue());
                component.set("v.dealRegFields.Partner__c", partner.Contact.Account.Name);
                component.set("v.dealRegFields.Partner_Lookup__c", partner.Contact.AccountId);

                if(partner.Contact.Account.Type == 'Distributor' ){
                    component.set("v.dealRegFields.Distributor__c", partner.Contact.AccountId);
                    component.set("v.dealRegFields.Distributor_Company_Name__c", partner.Contact.Account.Name);
                }else{
                    // component.set("v.dealRegFields.Distributor__c", partner.Contact.Account.Distributor__c);
                    component.set("v.dealRegFields.Distributor_Company_Name__c", partner.Contact.Account.Distributor__r.Name);
                }
            }
        });
        $A.enqueueAction(action);
    } ,

    gotoURL : function (component, event, url) {
        //alert(url);
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": url,
            "isredirect": false
        });
        urlEvent.fire();
    },

    getOptions : function(component, event, actionName, attributeName) {
        var myAction = component.get(actionName);
        var opts = [];
        myAction.setCallback(this, function(response) {
            if(response.getState() === "SUCCESS") {
                var options = response.getReturnValue();
                for (var i = 0; i < options.length; i++) {
                    opts.push({
                        class: "optionClass",
                        label: options[i],
                        value: options[i]
                    });
                }
                console.log('***'+JSON.stringify(opts));
                component.set(attributeName, opts);
            }
        });
        $A.enqueueAction(myAction);
    },

    /*
 	* Set Picklist Fields names to get data from Apex
 	*/
    fetchPicklistFields: function(component, event) {
        var picklistFields = component.get("v.picklistFields");
        var formPicklistFields = ["Country__c","StateCode__c","Customer_Category__c", "Purchase_Timeframe__c","Number_of_protected_machines__c","Current_Backup_Vendor__c","Current_Storage_Vendor__c","Budget__c","Need__c","Alliance_Partner_Name__c"];
        picklistFields['Deal_Registration__c'] = formPicklistFields;
        //   var remoteAccessPicklistFields = ["RS_Remote_Access_Type__c"];
        //   picklistFields['RS_Remote_Access_Type__c'] = remoteAccessPicklistFields;

        this.getPicklistValues(component,picklistFields);

    },

    /*
 	* get Picklist Fields data from Apex
 	*/
    getPicklistValues : function(component, sobjFieldsmap) {
        var action = component.get("c.getPicklistValues");
        action.setParams({
            "objpicklistFieldsMap": JSON.stringify(sobjFieldsmap)
        });
        action.setCallback(this, function(resp) {
            var state=resp.getState();

            if(state === "SUCCESS"){
                var res = resp.getReturnValue();

                var obj;
                for(obj in res){
                    var objName = res[obj];
                    console.log('object name --> ' + obj);
                    var field;
                    for(field in objName){
                        var optionValues = objName[field];
                        this.buildPicklist(component, field, optionValues);
                    }
                }
            }
        });
        $A.enqueueAction(action);
    },

    /*
 	* Fill Picklist Fields
 	*/
    buildPicklist: function(component, elementId, optionValues) {
        var opts = [];

        var optionValue;
        for(optionValue in optionValues){
            var optionValuesList = optionValues[optionValue];
            opts.push({
                class: "optionClass",
                value: optionValue,
                label: optionValues[optionValue],
                selected:false
            });
        }
        console.log(JSON.stringify(opts));
        component.set("v."+elementId, opts);
    },
    // Start PRIT26-548
    evaluateDistributorLogic : function(component) {
        var partner = component.get("v.partnerAccountDetails");
        console.log('partner>>' + JSON.stringify(partner));
        var distiList = component.get("v.distiList");
        var category = component.get("v.dealRegFields.Customer_Category__c");
        
        if ((partner.Contact.Account.BillingCountry != "" && partner.Contact.Account.BillingCountry != "United States" && partner.Contact.Account.Type != 'OEM') ||
            (partner.Contact.Account.BillingCountry == "United States" &&
                (category == "State & Local Govt/Education" || category == "Federal Govt"))) {
            component.set("v.showDistributor", true);
            let arr = [];
            distiList.forEach(function(item) {
                let temp = item.split(";");
                arr.push({
                    label: temp[0],
                    value: temp[1]
                });
            });
            component.set("v.optionsDistributor__c", arr);
        } else {
            component.set("v.showDistributor", false);
        }
	},
    // End PRIT26-548
    /* Backup -  END */
    //PRIT26-680-Start
    handleOppSpecificsChange : function(component, event) {
        // Get the value from the event
        var newValue = event.getSource().get("v.value");
        if(newValue && newValue.length > 255){
            let dealRegFields = component.get("v.dealRegFields");
            dealRegFields.Opportunity_Details__c = newValue.substring(0, 255);
            component.set("v.dealRegFields",dealRegFields);
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "message": "Only 255 characters are allowed to explain characteristics/specifics of the Opportunity.",
            });
            toastEvent.fire();
        }

    }
    //PRIT26-680-End
})