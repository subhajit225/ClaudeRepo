({
    doInit : function(component, event, helper) {
        helper.loadNewRecord(component, event, helper);
    },
    /** Saving Partner Record  **/
    SavePartnerRequestRecord:function(component, event, helper) {
        var isFormValid = helper.validateForm(component);
        var requiredValidation;
        var requiredValidate;
        var countryValue=component.find("Country_Picklist__c").get("v.value");
        var stateValue=component.get("v.RegistrationFields.State_Picklist__c");
        var postalcodeval;
        var countryval;
        var stateVal;
        //Postal  Code Logic
        var postalcode=component.find("Postal_Code__c").get("v.value");
        if(postalcode==null||postalcode==''){
            $A.util.addClass(component.find('Postal_Code__c'), "slds-has-error");
            $A.util.removeClass(component.find('Postal_Code__c'+"_help"), "none");
            component.set('v.reqZipMsg','Complete this field.');
            postalcodeval=false; 
        }else{
            
            $A.util.removeClass(component.find('Postal_Code__c'), "slds-has-error");
            $A.util.addClass(component.find('Postal_Code__c'+"_help"), "none");
            component.set('v.reqZipMsg','');
            postalcodeval=true;
        }
        
        //Country value Logic
        if(countryValue==null || countryValue==''){
            $A.util.addClass(component.find('Country_Picklist__c'), "slds-has-error");
            $A.util.removeClass(component.find('Country_Picklist__c'+"_help"), "none");
            component.set('v.reqCountryFieldMsg','Complete this field.');
            countryval=false;
        } else{
            $A.util.removeClass(component.find('Country_Picklist__c'), "slds-has-error");
            $A.util.addClass(component.find('Country_Picklist__c'+"_help"), "none");
            component.set('v.reqCountryFieldMsg','');
            countryval=true;
        }
        
        //Sate Logic  
        if( (countryValue== 'USA' || countryValue == 'United States' ||countryValue =='Canada')&& (stateValue==null ||stateValue==''))
        {
            $A.util.addClass(component.find('State_Picklist__c'), "slds-has-error");
            $A.util.removeClass(component.find('State_Picklist__c'+"_help"), "none");
            component.set('v.reqStateFieldMsg','Complete this field.');
            stateVal=false;  
            
        }else{
            
            $A.util.removeClass(component.find('State_Picklist__c'), "slds-has-error");
            $A.util.addClass(component.find('State_Picklist__c'+"_help"), "none");
            component.set('v.reqStateFieldMsg','');
            stateVal=true;
        }
        
        //After  filling postal code,country,state value
        if(postalcodeval==true && countryval==true && stateVal==true &&(countryValue=='US'||countryValue=='USA' || countryValue=='United States' || countryValue =='Canada')){
            requiredValidate=helper.validateFormInputFields(component,event,'Postal_Code__c');
        }
        if( (stateValue==null ||stateValue=='') &&(postalcodeval==true)&&countryval==true ) {
            
            if(countryValue=='United States' || countryValue=='USA' ||countryValue=='US' ||countryValue =='Canada' ){
                
                requiredValidation=false;
            }else{
                
                requiredValidation=true; 
            }
            
        }

        //PRIT24-435-start
        var email = component.get('v.RegistrationFields.Email__c');
        var validateEmail = true;
        var emailRegex = /^[\w.-]+@(?!hotmail\.com$|googlemail\.com$|gmail\.com$|yahoo\.com$|gmx\.com$|ymail\.com$|outlook\.com$)([A-Za-z\d-]+\.)+[A-Za-z]{2,}$/;

        if (!emailRegex.test(email)) {
            validateEmail = false;
            $A.util.addClass(component.find('Email'), "slds-has-error");
            $A.util.removeClass(component.find('Email_help'), "none");
            component.set('v.emailError', 'Free email domain is not allowed');
        }else{
            validateEmail = true;
            $A.util.removeClass(component.find('Email'), "slds-has-error");
            $A.util.addClass(component.find('Email'+"_help"), "none");
            component.set('v.emailError','');
        }
        var companyName = component.get('v.selectedCompanyValue');
        var validateCompany = false;
        if(companyName == null || companyName == ''){
            component.set('v.reqCompanyFieldMsg','Complete this field.');
        }else{
            validateCompany = true;
            component.set('v.reqCompanyFieldMsg','');
        }
        
        
        
        if(isFormValid==true && typeof requiredValidation=='undefined'&& typeof requiredValidate=='undefined' && countryValue=='Canada' && validateCompany && validateEmail)
        {
            helper.saveRecord(component, event, helper);
        }else if(isFormValid && (requiredValidation || requiredValidate==="undefined" || requiredValidate) && validateCompany && validateEmail)
        {
            helper.saveRecord(component, event, helper);
        }//PRIT24-435-end
        
    },
    /** Making state is Mandatory or not mandatoy based on country**/
    HandlingCountryChange:function(component, event, helper) {
        var countryValue=component.find("Country_Picklist__c").get("v.value");
        if(countryValue==null || countryValue==''||countryValue== 'USA' || countryValue == 'United States' ||countryValue =='Canada'){
            component.set("v.showStates",true);
            component.set("v.HideStates",false); 
        }
        else{
            component.set("v.showStates",false);
            component.set("v.HideStates",true); 
        }        
    },
    //PRIT24-435-start
    handleEmailChange : function(component, event, helper){
        var emailDomain = component.get('v.RegistrationFields.Email__c');
        var domain = emailDomain.split('@')[1];
        if(domain != undefined && domain != null){
            component.set('v.emailDomain',domain);
        }
        console.log('validate->'+helper.validateForm(component));
    },
    handleSelectedAccount : function(component, event, helper){
        let accountRec = event.getParams();
        if(accountRec){
            console.log('accId->'+accountRec.Id);
            console.log('accName->'+accountRec.Name);
            component.set('v.selectedCompanyValue',accountRec.Name);
            component.set('v.RegistrationFields.Company_Name__c',accountRec.Name); 
            component.set('v.RegistrationFields.Partner_Account_Lookup__c',accountRec.Id);
        }
    },
    handleSearchValue : function(component, event, helper){
        let accountRec = event.getParams();
        if(accountRec){
            console.log('typed company name ->'+accountRec.searchText);
            component.set('v.selectedCompanyValue',accountRec.searchText);
            component.set('v.RegistrationFields.Company_Name__c',accountRec.searchText);
            component.set('v.RegistrationFields.Partner_Account_Lookup__c','');
        }
    },
    handleClearValue : function(component, event, helper){
        let accountRec = event.getParams();
        if(accountRec){
            console.log('accId->'+accountRec.Id);
            console.log('accName->'+accountRec.Name);
            component.set('v.selectedCompanyValue',accountRec.Name);
            component.set('v.RegistrationFields.Company_Name__c',accountRec.Name);
            component.set('v.RegistrationFields.Partner_Account_Lookup__c',accountRec.Id);
        }
    }
    //PRIT24-435-end
    
})