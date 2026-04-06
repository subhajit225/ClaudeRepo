({
    getParameterByName: function(component, event, name) {
        name = name.replace(/[\[\]]/g, "\\$&");
        var url = window.location.href;
        var regex = new RegExp("[?&]" + name + "(=1\.([^&#]*)|&|#|$)");
        var results = regex.exec(url);
        if (!results) return null;
        if (!results[2]) return '';
        return decodeURIComponent(results[2].replace(/\+/g, " "));
    },
    fetchBaseUrl : function(component, event) {
        var url = window.location.href;
        var pathname = window.location.pathname;
        var index1 = url.indexOf(pathname);
        var index2 = url.indexOf("/", index1 );
        var baseUrl = url.substr(0, index2);
        if(baseUrl!= null && baseUrl!=''){
            return baseUrl;
        }else{
            return null;
        }
    },
    // Processing FedRAMP based on URL recordId for "New Case
    checkFedRampByRecordId : function(component, urlRecordId, helper) {
        var caseRec = component.get("v.caseRecord");
        // If Current URL has AccounttId
        if(urlRecordId && urlRecordId.startsWith('001')){
            component.find('accIds').set('v.value', urlRecordId);
            component.set("v.accountId",urlRecordId);
            var action = component.get('c.getAccountRecord');
            action.setParams({recId:urlRecordId});
            action.setCallback(this,function(resp){
                if(resp.getState() === 'SUCCESS'){
                    var res = resp.getReturnValue();
                    caseRec.AccountId = res.Id;

                    helper.checkForCustomerType(component, res.RSC_G_Support__c);

                    component.set('v.accountHeadsUpText',res.Heads_UpTo_Support_Team__c);
                    component.set('v.accountName',res.Name);
                    component.set("v.fedRampCustomerName",res.Name);
                    component.set("v.isGTCDenied",res.GTC__c);
                    let gtc = !res.GTC__c ? false : res.GTC__c == 'Denied' ? true : false;
                    component.set("v.isGTCDenied",gtc);
                }
                else if (resp.getState() === "ERROR") {
                        var errors = resp.getError();
                        helper.handleErrorMessage(component, errors, 'An error occurred while trying to load the page.');
                }
            });
            $A.enqueueAction(action);
        }
        // by Vijay CS21-1325: FedRAMP Check: Populating Accoount and Contact on Case Form
        // If Current URL has ContactId
        else if(urlRecordId && urlRecordId.startsWith('003')){
            var action = component.get('c.getContactRecord');
            action.setParams({recId:urlRecordId});
            action.setCallback(this,function(resp){
                if(resp.getState() === 'SUCCESS'){
                    let res = resp.getReturnValue();
                    console.log('getContactRecord:: ', JSON.stringify(res));

                    let accountId = res.AccountId;
                    component.set("v.accountId", accountId);
                    let rscInstanceFilter = '(AccountId__c = \'' + accountId + '\' OR SDPEndUser__c = \'' + accountId + '\')';
                    component.set("v.rscInstanceFilter", rscInstanceFilter);
                    this.checkForCustomerType(component, res.Account.RSC_G_Support__c);

                    caseRec.AccountId = res.AccountId;
                    caseRec.ContactId = res.Id;
                    component.find('accIds').set('v.value', res.AccountId);
                    if(!component.get('v.isFedRamp')
                        && !component.get('v.isCommercialCustomer')){
                                component.find('ContactId').set('v.value', res.Id);
                    }
                    
                    // component.set('v.accountHeadsUpText',res.Account.Heads_UpTo_Support_Team__c); 
                    component.set('v.fedRampCustomerName',res.Account.Name);
                    let gtc = res.Account.GTC__c == 'Denied' ? true : false;
                    component.set("v.isGTCDenied",gtc);
                    // if(res.isFedRAMP__c){
                    //     component.set('v.isFedRamp',res.Account.FedRAMP__c);
                    //     component.set('v.isContactFedRamp',res.isFedRAMP__c);
                    //     component.set('v.contAccName',res.Account.Name); 
                    //     component.set("v.fedRampCustomerName",res.Account.Name );
                    // }else{
                    //     component.set('v.accountHeadsUpText',res.Heads_UpTo_Support_Team__c); 
                    // }
                }
                else if (resp.getState() === "ERROR") {
                        var errors = resp.getError();
                        helper.handleErrorMessage(component, errors, 'An error occurred while trying to load the page.');
                }
            });
            $A.enqueueAction(action);
        }
        // If Current URL has CaseId
        else if(urlRecordId && urlRecordId.startsWith('500')){
            component.find('parentIds').set('v.value', urlRecordId);
            component.set("v.caseId",urlRecordId);
        }
    },
    // processing fedRAMP from "Clone Case" button
    checkFedRampForCaseClone : function(component, caseId, helper) {
        var action = component.get('c.checkFedRAMPForCloneCase');
            action.setParams({recId:caseId});
            action.setCallback(this,function(resp){
                if(resp.getState() === 'SUCCESS'){
                    let res = resp.getReturnValue();

                    this.checkForCustomerType(component, res.Account.RSC_G_Support__c);
                    
                    component.set('v.accountName',res.Account.Name); 
                    component.set("v.fedRampCustomerName",res.Account.Name );
                    component.find('accIds').set('v.value', res.Account.Id);
                    let gtc = res.Account.GTC__c == 'Denied' ? true : false;
                    component.set("v.isGTCDenied",gtc);

                    if(!component.get('v.isFedRamp')
                        && !component.get('v.isCommercialCustomer')){
                                component.find('ContactId').set('v.value', res.Contact.Id);
                    }

                    // if(res.Account){
                    //     component.set('v.isFedRamp',res.Account.FedRAMP__c);
                    //     if(res.Account.FedRAMP__c){
                    //         component.set('v.accountName',res.Account.Name); 
                    //         component.set("v.fedRampCustomerName",res.Account.Name );
                    //     }
                    //     component.find('accIds').set('v.value', res.Account.Id);
                    // }
                    // if(res.Contact){
                    //     component.set('v.isContactFedRamp',res.Contact.Account.FedRAMP__c);
                    //     component.find('ContactId').set('v.value', res.ContactId);
                    //     if(res.Contact.Account.FedRAMP__c){
                    //         component.set('v.contAccName',res.Contact.Account.Name); 
                    //         component.set("v.fedRampCustomerName",res.Contact.Account.Name );
                    //     }
                    // }
                }else if (resp.getState() === "ERROR") {
                        var errors = resp.getError();
                        helper.handleErrorMessage(component, errors, 'An error occurred while trying to clone the case.');
                }
            });
        $A.enqueueAction(action);
    },

    checkForCustomerType : function(component, rscgproduct) {
        // CS21-2010
        var RSC_G_Allowed_Values = $A.get("$Label.c.FedRAMP_RSC_G_For_Case_Creation");

        console.log('checkForCustomerType:: ', rscgproduct);
        // 1: When Account RSC-G Support is blank
        if(!rscgproduct){
            // User navigates to case submission form
            component.set("v.isFedRamp", false);
            component.set("v.isCommercialCustomer", false);
            component.set("v.hideSection",false);
        }
        // 2: When Account RSC-G Support contains CDM in multipicklist values
        else if(rscgproduct.includes(RSC_G_Allowed_Values)){
            // Display case creation prompt and proceed to case submission form
            component.set("v.isCommercialCustomer", true);
            component.set("v.isFedRamp", false);
            component.set("v.hideSection",true);
        }
        // 3: When Account RSC-G Support = RSC-G
        else if(!rscgproduct.includes(RSC_G_Allowed_Values)){
            // Display disable case creation prompt
            component.set("v.isFedRamp", true);
            component.set("v.isCommercialCustomer", false);
            component.set("v.hideSection",true);
        }
    },

    getUItheme : function (component, helper) {
    	var action = component.get("c.getUIThemeDescription");
        action.setCallback(this, function(res) {
            if(res.getState() === 'SUCCESS'){
                component.set("v.UITheme", res.getReturnValue());
            }else if (res.getState() === "ERROR") {
                    var errors = res.getError();
                    helper.handleErrorMessage(component, errors, 'An error occurred while trying to load the page.');
            }
        });
        $A.enqueueAction(action);
    },

    fetchQueueIds : function (component, helper) {
        var queueMap = new Promise( $A.getCallback( function( resolve , reject ) { 
            var action = component.get("c.getQueueIds");
            action.setCallback( this , function(resp) {
                if(resp.getState()=='SUCCESS') {
                    resolve( resp.getReturnValue() );
                }
                if(resp.getState()=='ERROR') {
                    var errors = resp.getError();
                    helper.handleErrorMessage(component, errors, 'An error occurred while trying to load the page.');
                    reject( resp.getError() );
                }
            });
            $A.enqueueAction( action );
        }));            
        return queueMap;
    },

    handleErrorMessage : function (component, dbError, uiMsg) {
        var errors = dbError;
        if (errors
            && errors[0] 
            && errors[0].message) {
                console.log('error:: ', errors[0].message);
                component.set("v.errorHeader", uiMsg);
                component.set("v.error", errors[0].message);
        }
    },
    
    /*Return the Url parameter values from Name*/
    getURLParameter : function(component,event,name){
        var urlParams = new URLSearchParams(window.location.search);
        var defaultFieldValues = urlParams.get('defaultFieldValues');
        var urlParamList = defaultFieldValues.split(',');
        var val = '';
        for(var a = 0;a<urlParamList.length;a++){
            if(urlParamList[a].includes(name)){
                val = urlParamList[a].split(name+'=')[1];
            }
        }
        return val;
    }
})