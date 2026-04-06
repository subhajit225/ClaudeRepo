({
    getPicklist : function(component, event,fieldAPIName) {
        var action = component.get("c.getPicklistValues");
        action.setParams({
            'fieldName': fieldAPIName
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var arr = [];
                if(fieldAPIName == 'Segment__c' || fieldAPIName == 'Partner_Selling_Countries__c' || fieldAPIName == 'Country__c' || fieldAPIName == 'PartnerType__c' || fieldAPIName == 'Referral_Source__c' || fieldAPIName == 'Territory__c'){
                    arr = [
                        { value: "", label: "--None--" }
                    ];
                }
                //console.log(response.getReturnValue());
                response.getReturnValue().forEach(function(labelval){
                    console.log("labelval------->"+labelval);
                    var temp = labelval.split(';');
                    var temparr = [];
                    temparr['label'] = temp[0];
                    temparr['value'] = temp[1];
                    if((fieldAPIName == 'PartnerType__c' && temp[1] != 'Distributor' && temp[1] != 'MSP' && temp[1] != 'MSP-Reseller' && temp[1] != 'Alliance Partner') || fieldAPIName != 'PartnerType__c'){
                    	arr.push(temparr);
                	}
                });
                if(fieldAPIName == 'Vendors_your_Org_works_with_today__c'){
                    component.set("v.options",arr);
                }else if(fieldAPIName == 'Country__c'){
                    component.set("v.countryoptions",arr);
                }else if(fieldAPIName == 'PartnerType__c'){
                    component.set("v.PartnerTypeoptions",arr);
                }else if(fieldAPIName == 'Referral_Source__c'){
                    component.set("v.referralsourceoptions",arr);
                }else if(fieldAPIName == 'Territory__c'){
                    component.set("v.optionsTerritory__c",arr);
                }else if(fieldAPIName == 'Partner_Selling_Countries__c'){
                    component.set("v.PSellingCountriesOptions",arr);
                }else if(fieldAPIName == 'Segment__c'){
                    component.set("v.optionsSegment__c",arr);
                }
                console.log(component.get("v.PSellingCountriesOptions"));
                console.log(component.get("v.options"));
                console.log(component.get("v.countryoptions"));
            }else if (state === "ERROR") {
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
    
    /*
     * Save the Partner on-boarding.
     */
    savePOB : function(component, event,helper) { 
        helper.showSpinner(component);
        var action = component.get("c.savePartnerOnboard");
        var rec = component.get("v.simplePartnerOnboard");
        
        console.log(rec);
        action.setParams({
            "PO_Request": rec,
            "Segment" :component.get("v.selectedSegment")
        });
        
        action.setCallback(this, function(response) { 
            var saveResult = response.getState();
            //alert(response.getState());
            helper.hideSpinner(component);
            if(response.getState() === "SUCCESS") { 
                var result = response.getReturnValue();
                
                // alert(result);
                // record is saved successfully
                if(result == "success"){
                    var resultsToast = $A.get("e.force:showToast");
                    resultsToast.setParams({
                        "title": "Saved",
                        "message": "The record was saved.",
                        "type" : "success"
                    });
                    resultsToast.fire();
                    component.set("v.showsaveMessage",true);
                    component.set("v.saveMessage","Thank you for your request. We will reach out within 48 hours once your request is reviewed. For any questions please reach out to <a href='mailto:goforward@rubrik.com'>goforward@rubrik.com</a>");

                }else if(result == "Error while saving"){
                    var resultsToast = $A.get("e.force:showToast");
                    resultsToast.setParams({
                        "title": "Error",
                        "message": "Error occurred while submitting record",
                        "type" : "error"
                    });
                    resultsToast.fire();
                    component.set("v.showsaveMessage",true);
                    component.set("v.saveMessage","Error occurred while submitting record. Please contact <a href='mailto:goforward@rubrik.com'>goforward@rubrik.com</a> if you have questions.");
                    
                }else if(result == "Account record already Exists"){
                    var resultsToast = $A.get("e.force:showToast");
                    resultsToast.setParams({
                        "title": "Already a Partner",
                        "message": "You are already registered as a Partner",
                        "type" : "info"
                    });
                    resultsToast.fire();
                    component.set("v.showsaveMessage",true);
                    var currenturl = window.location.href;
                    var tempurl = currenturl.split('/s/');
                    var navurl =tempurl[0]+'/s/useraccess'; 
                    component.set("v.saveMessage","<h3>You are already registered as a partner.To get Partner access, please click <a href="+navurl+">here</a> </h3>");
                    //helper.gotoURL(component,event,'onboardingconfirmation?showMessage='+component.get("v.saveMessage"));
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
                var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "title": "Error",
                    "message": "Error occurred while submitting record",
                    "type" : "error"
                });
                resultsToast.fire();
                component.set("v.showsaveMessage",true);
                component.set("v.saveMessage","Error occurred while submitting record. Please contact <a href='mailto:channels@rubrik.com'>channels@rubrik.com</a> if you have questions.");
            }           
        }); 
        
        $A.enqueueAction(action); 
    } ,
    
    concatenateSelectedCountries : function(component, event){
        var controllerValueKey = component.get("v.PSellingCountriesSelected");
        var options = '';
        if(!$A.util.isEmpty(controllerValueKey)){
            for(var i=0;i<controllerValueKey.length;i++){
               if( $A.util.isEmpty(options)){
                    options = controllerValueKey[i]+';';
                }else{
                    options = options+controllerValueKey[i]+';';
                }                
            }
            component.set("v.simplePartnerOnboard.Partner_Selling_Countries__c",options);
        }
        component.set("v.simplePartnerOnboard.Partner_Selling_Countries__c",options);
    },
    
    /*
     * Check Form required inpuytField validations 
     * */
    validateFormInputFields : function(component, event) {
        var allValid = true;
        var zipValid = true;
        var emailValid = true;
        var requiredFields = component.get("v.requiredFields");
        var businessSectionRequiredFields = component.get("v.businessSectionRequiredFields");
        var separateValidationRequiredFields = component.get("v.separateValidationRequiredFields");
        var helper = this;
        
        requiredFields.forEach(function(field) {
            var disablefield = 'v.disable'+field;
            console.log(component.get(disablefield));
            if($A.util.isEmpty(component.get("v.simplePartnerOnboard."+field)) && !separateValidationRequiredFields.includes(field)){
                 if(((!$A.util.isUndefined(component.get(disablefield)) && !component.get(disablefield)) || $A.util.isUndefined(component.get(disablefield)))
 						&&((businessSectionRequiredFields.includes(field) && component.get("v.showBusinessSection")) || !businessSectionRequiredFields.includes(field))){
                    	helper.showErrorField(component, event, field);
                    	allValid = false;
                 }
        	}else if(!$A.util.isEmpty(component.get("v.simplePartnerOnboard."+field)) &&  !separateValidationRequiredFields.includes(field)){
            	 	helper.hideErrorField(component, event, field);
            }else{
                if(field == 'Postal_Code__c')
                    zipValid = helper.ShowHideErrorZipField(component, event, field);
            }
       });
        if($A.util.isEmpty(component.get("v.selectedSegment")) && component.get("v.simplePartnerOnboard.Country__c") == 'United States'){
              allValid = false;
              helper.showErrorField(component, event, "Segment__c");
        }else{
            helper.hideErrorField(component, event, "Segment__c");
        }
      
        // alert(allValid);
        if(!zipValid || !emailValid){
            allValid = false;
        }
        return(allValid);
    },
    
    /*
     * Check Form required input validations.
     */
    validateForm: function(component) {
        // var validNewRecord = true;        
        // return(validNewRecord);
        console.log('@@ {!v.simplePartnerOnboard.FCPAPP__c} '+component.get("v.simplePartnerOnboard.FCPAPP__c"));
        // Show error messages if required fields are blank
        var allValid = component.find('pobField').reduce(function (validFields, inputCmp) {
            inputCmp.showHelpMessageIfInvalid();
            return validFields && inputCmp.get('v.validity').valid;
        }, true);
        //alert(allValid);
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
    ShowHideErrorZipField : function(component, event, field){
        var zipvalid = true;
        if($A.util.isEmpty(component.get("v.simplePartnerOnboard.Postal_Code__c"))){
            $A.util.addClass(component.find(field), "slds-has-error");
            $A.util.removeClass(component.find(field+"_help"), "none");
            component.set('v.reqZipMsg','Complete this field.');
            zipvalid = false;
        }else if(!$A.util.isEmpty(component.get("v.simplePartnerOnboard.Postal_Code__c")) && (component.get("v.simplePartnerOnboard.Country__c") == 'US' || component.get("v.simplePartnerOnboard.Country__c") == 'United States' || component.get("v.simplePartnerOnboard.Country__c") == 'USA' )){
            if(component.get("v.simplePartnerOnboard.Postal_Code__c").length < 5 ){
                $A.util.addClass(component.find(field), "slds-has-error");
                $A.util.removeClass(component.find(field+"_help"), "none");
                component.set('v.reqZipMsg','Please enter a 5 digit Zip Code for a US Address.');
                zipvalid = false;
            }else{
                var postalCodeRegex = /^([0-9]{5})(?:[-\s]*([0-9]{4}))?$/;
                var isValidZip = postalCodeRegex.test(component.get("v.simplePartnerOnboard.Postal_Code__c"));
                if(isValidZip){    
                    $A.util.removeClass(component.find(field), "slds-has-error");
                    $A.util.addClass(component.find(field+"_help"), "none");
                    component.set('v.reqZipMsg','');
                    zipvalid = true;
                }else{
                    $A.util.addClass(component.find(field), "slds-has-error");
                    $A.util.removeClass(component.find(field+"_help"), "none");
                    component.set('v.reqZipMsg','Please enter a valid Zip Code');
                    zipvalid = false;
                }
            }
        }else{
            if(!$A.util.isEmpty(component.get("v.simplePartnerOnboard.Postal_Code__c")) && component.get("v.simplePartnerOnboard.Postal_Code__c").length >= 20){
                $A.util.addClass(component.find(field), "slds-has-error");
                $A.util.removeClass(component.find(field+"_help"), "none");
                component.set('v.reqZipMsg','Zip Code length cannot be more than 20 characters');
                zipvalid = false;
            }else{
                $A.util.removeClass(component.find(field), "slds-has-error");
                $A.util.addClass(component.find(field+"_help"), "none");
                component.set('v.reqZipMsg','');
                zipvalid = true;
            }
        }
        return zipvalid;
    },
  /*  ShowHideErrorEmailField : function(component, event, field){   
        var emailvalid = true;
        if($A.util.isEmpty(component.get("v.simplePartnerOnboard.Email__c"))){
            $A.util.addClass(component.find(field), "slds-has-error");
            $A.util.removeClass(component.find(field+"_help"), "none");
            component.set('v.reqEmailMsg','Complete this field.');
            emailvalid = false;
        }else{
            var emailRegex = /^[^@]+@[^\.]+\..+/;
            var isValidEmail = emailRegex.test(component.get("v.simplePartnerOnboard.Email__c"));
            if(isValidEmail){    
                $A.util.removeClass(component.find(field), "slds-has-error");
                $A.util.addClass(component.find(field+"_help"), "none");
                component.set('v.reqEmailMsg','');
                emailvalid = true;
            }else{
                $A.util.addClass(component.find(field), "slds-has-error");
                $A.util.removeClass(component.find(field+"_help"), "none");
                component.set('v.reqEmailMsg','Please enter a valid Email Id example@companyname.com');
                emailvalid = false;
            }
        }
        return emailvalid;
    },*/
    fetchPicklistValues: function(component,controllerField, dependentField) {
        // call the server side function  
        var action = component.get("c.getDependentMap");
        // pass paramerters [object definition , contrller field name ,dependent field name] -
        // to server side function 
        action.setParams({
            'contrfieldApiName': controllerField,
            'depfieldApiName': dependentField 
        });
        //set callback   
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                //store the return response from server (List<string>>)  
                var StoreResponse = response.getReturnValue();
                console.log(StoreResponse); 
                component.set("v.DependentFieldMap"+dependentField,StoreResponse);
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
        });
        $A.enqueueAction(action);
    },
    fetchDepValues: function(component, dependentField,ListOfDependentFields) {
        // create a  array var for store dependent picklist values for controller field  
        var arr = [
            { value: "", label: "--None--" }
        ];
        if(!$A.util.isEmpty(ListOfDependentFields)){
            for(var i=0;i<ListOfDependentFields.length;i++){
                var temp = ListOfDependentFields[i].split(';');
                arr.push({ value: temp[0], label: temp[1] });
            } 
        }
        
        // set the dependentFields variable values to store(dependent picklist field) on lightning:select
        var disablefield = 'v.disable'+dependentField;
        var optionsfield = 'v.options'+dependentField;
        if(!$A.util.isEmpty(ListOfDependentFields)){
            component.set(disablefield,false);
        }else{
            component.set(disablefield,true);
        }
        component.set(optionsfield,arr);  
        
    },
    fetchDistributorValues : function (component, event, controllerValueKey,helper) {
        var action = component.get("c.getDistributorValues");
        action.setParams({
            'territorySelectedValue': controllerValueKey
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var arr = [];
                    arr = [
                        { value: "", label: "--None--" }
                    ];
                console.log('@@ Dist values '+response.getReturnValue());
                if(response.getReturnValue() != null && response.getReturnValue().length > 0){
                	component.set("v.disableDistributor__c" , false);
                }else{
                    helper.resetPicklistValues(component,event,'Distributor__c');
                }
                response.getReturnValue().forEach(function(labelval){
                    var temp = labelval.split(';');
                    var temparr = [];
                    temparr['label'] = temp[0];
                    temparr['value'] = temp[1];
                    arr.push(temparr);
                });
                component.set("v.optionsDistributor__c",arr);
            }else if (state === "ERROR") {
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
    resetPicklistValues : function(component,event,field){
        var arr = [
            { value: "", label: "--None--" }
        ];
        var disablefield = "v.disable"+field;
        var optionsfield = "v.options"+field;
        var showfield = "v.show"+field;
        var fielAPI = "v.simplePartnerOnboard."+field;
        component.set(optionsfield, arr);
        component.set(showfield,false);
        component.set(showfield,true);
        component.set(fielAPI,"");
        component.set(disablefield, true); 
        
    },
    
    showSpinner: function (component, event, helper) {
        var spinner = component.find("mySpinner");
        $A.util.removeClass(spinner, "slds-hide");
    },
    
    hideSpinner: function (component, event, helper) {
        var spinner = component.find("mySpinner");
        $A.util.addClass(spinner, "slds-hide");
    },
    isQueValid: function (c, id) {
        var validateFields = c.find('question_1');
        var isValid;
        if (validateFields) {
            isValid = [].concat(validateFields).reduce(function (validSoFar, input) {
                input.showHelpMessageIfInvalid();
                return validSoFar && input.get('v.validity').valid;
            }, true);
        }
        return isValid;
    },
     partnerSellingChange : function (component, event, helper) {
        console.log(component.get("v.simplePartnerOnboard.Country__c"));
        var distArr = [];
        component.set("v.optionsDistributor__c",distArr);
        component.set("v.simplePartnerOnboard.Distributor__c","");
        component.set("v.selectedSegment","");
        component.set("v.selectedLookUpRecords",[]);
        var sellingCountryVal = component.get("v.simplePartnerOnboard.Country__c");
        if(sellingCountryVal == 'United States'){
            component.set("v.showSegment__c",true);
        }else{
            component.set("v.showSegment__c",false);
        }
        distArr = [{ value: "", label: "--None--" }];
        var action = component.get("c.getDistributorNames");
        action.setParams({
            'sellingCountry': sellingCountryVal
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                if(!$A.util.isEmpty(response.getReturnValue())){
                    response.getReturnValue().forEach(function(accIdName){
                        var temp = accIdName.split(';');
                        var temparr = [];
                        temparr['label'] = temp[0];
                        temparr['value'] = temp[1];
                        distArr.push(temparr);
                    });
                	component.set("v.optionsDistributor__c",distArr);
                    component.set("v.optionsPSDistributor__c",distArr);
                    component.set("v.disableDistributor__c" , false);
                }else{
                    component.set("v.disableDistributor__c" , true);
                }
            }else if (state === "ERROR") {
                component.set("v.disableDistributor__c" , true);
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
    }
})