({
    doInit : function(component, event, helper) {

        helper.getUItheme(component, helper);
        helper.fetchQueueIds(component)
        .then(function(result){
            component.set("v.queueMap", result)
        });

        var value = helper.getParameterByName(component , event, 'inContextOfRef');
        let recordtypeId = component.get('v.recordTypeId'); //added for CS21-780
        if ($A.util.isEmpty(recordtypeId)) {
            var action = component.get('c.getRecTypeId');
            action.setCallback(this,function(resp){
                if(resp.getState() === 'SUCCESS'){
                    component.set('v.recordTypeId',resp.getReturnValue());
                }else if (resp.getState() === "ERROR") {
                        var errors = resp.getError();
                        helper.handleErrorMessage(component, errors, 'An error occurred while trying to load the page.');
                }
                
            });
            $A.enqueueAction(action);
        }
        let recordId = component.get("v.recordId");
        let caseCreateURL = decodeURIComponent(window.location.href);
        var isCalled = false;
        // Processing FedRAMP for Clone Case from Classic
        if(recordId && recordId.startsWith('500') && component.get("v.isClassic")){
            helper.checkFedRampForCaseClone(component, recordId, helper);
        }

        // Processing FedRAMP based on URL recordId for "New Case" from Acc/Contact
        else if(value || component.get("v.isClassic")){
            let urlRecordId = null;
            if(value){
                var context = JSON.parse(window.atob(value));
                urlRecordId = context.attributes.recordId;
            }else{
                urlRecordId = recordId;
            }
            if(urlRecordId){
                helper.checkFedRampByRecordId(component, urlRecordId, helper);
            }
        }
        // processing fedRAMP from "Clone Case" button
        else if(recordId){
            helper.checkFedRampForCaseClone(component, recordId, helper);
        }// Start : Create Case button from Contact
        else if(caseCreateURL.includes('defaultFieldValues')){ 
            var acc_id = helper.getURLParameter(component,event,'AccountId');
            var con_id = helper.getURLParameter(component,event,'ContactId');
            component.find('ContactId').set('v.value', con_id);
            component.set('v.contactId', con_id);
            component.find('accIds').set('v.value', acc_id);
            var caseRec = component.get("v.caseRecord");
            caseRec.AccountId = acc_id;
            component.set("v.caseRecord",caseRec);
            helper.checkFedRampByRecordId(component, con_id, helper);
            var action = component.get('c.updateAccount');
             $A.enqueueAction(action);
             isCalled = true;
        }
        if(!isCalled){
            var action = component.get('c.updateAccount');
            $A.enqueueAction(action);
        }
         
        // End : Create Case button from Contact
    },
    updateCaseFields :  function(component, event, helper) {
        var caseRec = component.get("v.caseRecord");
        var user = component.get('v.userRecord');
        
        if(caseRec){
            if(caseRec.AccountId){
                component.find('accIds').set('v.value', caseRec.AccountId);
            }
            // Since Contact field is hidden when Account is FedRAMP
            // if(!component.get('v.isFedRamp')
            //     && caseRec.ContactId){
            //         component.find('ContactId').set('v.value', caseRec.ContactId);
            // }
            // Since All other fields are hidden when Account/Contact is FedRAMP
            if(!component.get('v.isFedRamp')
                && !component.get('v.isCommercialCustomer')
                && !component.get('v.hideSection')
                && !component.get('v.isGTCDenied')){
                component.find('ContactId').set('v.value', caseRec.ContactId);
                // Case Edit Section
                component.find('Status').set('v.value',caseRec.Status);
                component.set('v.Priority', caseRec.Priority);
                component.find('Origin').set('v.value', caseRec.Origin);
                component.find('Contact_method__c').set('v.value', caseRec.Contact_method__c);
                // Customer Success Section
                if(user && user.is_Customer_Success_User__c){
                    component.find('CSM_Owner__c').set('v.value',caseRec.CSM_Owner__c);
                    component.find('Product_Name__c').set('v.value', caseRec.Product_Name__c);
                    component.find('Phase__c').set('v.value', caseRec.Phase__c);
                    component.find('Sub_Phase__c').set('v.value', caseRec.Sub_Phase__c);
                    component.find('Churn_Reason__c').set('v.value', caseRec.Churn_Reason__c);
                    component.find('Customer_First_Contact__c').set('v.value',caseRec.Customer_First_Contact__c);
                    component.find('Customer_s_First_Response__c').set('v.value', caseRec.Customer_s_First_Response__c);
                    component.find('Customer_Onboarding_Adoption_Completion__c').set('v.value', caseRec.Customer_Onboarding_Adoption_Completion__c);
                }
                // Case Specifics Section
                component.find('Platform__c').set('v.value', caseRec.Platform__c);
                component.find('Software_Version__c').set('v.value', caseRec.Software_Version__c);
                component.find('Product_Area__c').set('v.value', caseRec.Product_Area__c);
                component.find('Problem_Type__c').set('v.value', caseRec.Problem_Type__c);
                component.find('Sub_Component__c').set('v.value', caseRec.Sub_Component__c);
                component.find('If_Other__c').set('v.value', caseRec.If_Other__c);
                // Case Description
                component.find('Subject').set('v.value',caseRec.Subject);
                component.find('Description').set('v.value', caseRec.Description);
            }
        }
    },
    updateOwner :  function(component, event, helper) {
        var user = component.get('v.userRecord'); 
        var contactId = component.get("v.caseRecord.contactId"); 
        if ((user.Profile.Name == 'Rubrik Customer Support User' || user.Profile.Name == 'Rubrik Renewal Specialist'  || user.Profile.Name == 'Rubrik Professional Services' ) && contactId == null) {
            component.set("v.rscInstanceFilter", "");                
        }

        helper.fetchQueueIds(component)
        .then(function(result){
            // CS21-1325, by Vijay: Fetch queueids by developer name
            let queueMap = result;
            
            var user = component.get('v.userRecord');
            let caseOwnerId = queueMap['Unassigned_Cases'];
            
            // Customer Success Manager
            if(user.is_Customer_Success_User__c){
                // Customer Onboarding fields are hidden for FedRAMP Acc/Cont
                if(!component.get('v.isFedRamp')
                    && !component.get('v.isCommercialCustomer')
                    && !component.get('v.hideSection')
                    && !component.get('v.isGTCDenied')){
                        component.find('Platform__c').set('v.value','Other');
                        component.find('If_Other__c').set('v.value','Other');
                }
                // Queue: Customer_Success 
                caseOwnerId = queueMap['Customer_Success'];
                component.set("v.isSupportUser",true);
                var sections = [];
                sections.push("A");
                sections.push("B");
                sections.push("C");
                sections.push("D");
                sections.push("E");
                sections.push("F");
                sections.push("Z");
                component.set("v.activeSections",sections);
            }
            // Rubrik Customer Support User
            else if(user.Profile.Name == 'Rubrik Customer Support User'){
                caseOwnerId = user.Id;
                component.set("v.isSupportUser",true);
            }
            // Normal User: Will take OPEN QUEUE as default value

            component.set("v.caseOwnerId", caseOwnerId);
        });
    },
    ownerChange : function(component, event, helper) {
        component.set("v.isOveride", true);
        component.set("v.caseOwnerId", event.getParam("value"));
    },
    //  Method call only on cancel of customer-success Manager / customer-success User Owner 
    removeUser: function(component, event, helper) {
        // CS21-1325, by Vijay: Fetch queueids by developer name
        let queueMap = component.get("v.queueMap");
        var caseRecord = component.get("v.caserec");
        caseRecord.OwnerId = '';
        component.set("v.caserec",caseRecord);
        component.set("v.isSupportUser",false);
        // Unassigned_Cases Queue: OPEN QUEUE
        component.find("OwnerId").set("v.value",queueMap['Unassigned_Cases']);
        component.set("v.caseOwnerId", queueMap['Unassigned_Cases']);
        component.set("v.isOveride", true);
    },
    updateAccount: function(component, event, helper) {
        var accId = Array.isArray(component.get('v.accountId')) ? component.get('v.accountId')[0]: component.get('v.accountId');
        // retaining form field values when closed and re-opened
        var caseRec = component.get("v.caseRecord");
        // Since, Case created from Classic have empty caseRec
        if(!caseRec){
            let caseObj = {'AccountId':''}
            caseRec = caseObj;
        }

        if(accId && accId != 0){
            let rscInstanceFilter = '(AccountId__c = \'' + accId + '\' OR SDPEndUser__c = \'' + accId + '\')';
            component.set("v.rscInstanceFilter", rscInstanceFilter);                             
            caseRec.AccountId = accId;
            component.set("v.caseRecord",caseRec);
            component.find('accIds').set('v.value', accId);
                var action = component.get('c.getAccountRecord');
                action.setParams({recId:accId});
                action.setCallback(this,function(resp){
                if(resp.getState() === 'SUCCESS'){
                    var res = resp.getReturnValue(); 
                    component.set('v.accountHeadsUpText',res.Heads_UpTo_Support_Team__c);

                    if(res.Tabs_Visibility__c != null && res.Tabs_Visibility__c.includes('Predibase')){
                        caseRec.Platform__c = 'Predibase';
                        caseRec.If_Other__c = 'Predibase';
                        caseRec.Product_Area__c = 'Other';
                        caseRec.Sub_Component__c = 'Other (specify)';
                        component.set("v.caseRecord",caseRec);
                        var predibaseText = res.Name +' is a Predibase customer. Predibase Engineering currently provides technical support services for Predibase products. Contact the #cs-predibase-engineering channel for questions.';
                        component.set('v.accountHeadsUpText',predibaseText);
                    }else{
                        caseRec.Platform__c = caseRec.Platform__c == 'Predibase'?'':caseRec.Platform__c;
                        caseRec.If_Other__c = caseRec.If_Other__c == 'Predibase'?'':caseRec.If_Other__c;
                        caseRec.Product_Area__c = '';
                        component.set("v.caseRecord",caseRec);
                    }

                    helper.checkForCustomerType(component, res.RSC_G_Support__c);
                    
                    component.set('v.accountName',res.Name);
                    component.set("v.fedRampCustomerName",res.Name);
                    let gtc = res.GTC__c == 'Denied' ? true : false;
                    component.set("v.isGTCDenied",gtc);
                    
                    // component.set('v.isFedRamp',res.FedRAMP__c);
                    // if(res.FedRAMP__c){
                    //     component.set('v.accountName',res.Name);
                    //     component.set("v.fedRampCustomerName",res.Name);
                    // }
                    
                    // if(!res.FedRAMP__c){
                    //     component.set('v.accountHeadsUpText',res.Heads_UpTo_Support_Team__c);
                    // }
                }
                else if (resp.getState() === "ERROR") {
                        var errors = resp.getError();
                        helper.handleErrorMessage(component, errors, 'An error occurred while trying to change the Account on Case.');
                }

            });
            $A.enqueueAction(action);
        }
        //Selected Account removed from form
        else{
            component.set("v.rscInstanceFilter", "");
            component.set("v.caseRecord.RSCInstance__c", null);
            var rscLookup = component.find("customRscLookup");
            if (rscLookup) {
                rscLookup.clear();
            }
            component.set("v.isFedRamp", false);
            component.set("v.isCommercialCustomer", false);
            component.set("v.hideSection", false);
            component.set("v.isGTCDenied", false);
            component.set('v.accountHeadsUpText','');
            // below logic When FedRamp Cont selected then FedRamp Acc Selected and removed: ALert will display FedRAMP Cont Acc Name
            // let contAccName = component.get('v.contAccName');
            component.set('v.accountName', '');
            component.set("v.fedRampCustomerName", '');
            // // re-assigning case field values
            caseRec.AccountId = '';
            // When Case created from Contact "Create Case" button and Account removed from Lookup
            if(component.get('v.contactId')){
                component.find('ContactId').set('v.value', component.get('v.contactId'));
            }
            component.set("v.caseRecord",caseRec);
            $A.enqueueAction(component.get('c.updateCaseFields'));
        }
    },
    // retaining form field values when FedRAMP Account selected and removed.
    handleOnChange: function(component, event) {
        let auraId = event.getSource().getLocalId();
        let value = event.getParam('value');
        var caseRec = JSON.parse(JSON.stringify(component.get("v.caseRecord")));
        if(!caseRec && value){
            let caseObj = {};
            caseRec = caseObj;
        }
        // Populating changed value to case Object respective field using auraId
        caseRec[auraId] = value;
        component.set("v.caseRecord",caseRec);
    },
    // CS21-1324: On Contact Checking fedRAMP Account
    handleContactChange: function(component, event, helper) {
        var contactId = event.getParam("value")[0];
        // retaining form field values when closed and re-opened
        var caseRec = component.get("v.caseRecord");
        // Since, Case created from Classic have empty caseRec
        if(!caseRec){
            let caseObj = {'ContactId':''}
            caseRec = caseObj;
        }
        
        if(contactId){
            caseRec.ContactId = contactId;
            component.set("v.caseRecord",caseRec);
            component.find('ContactId').set('v.value', contactId);
            var user = component.get('v.userRecord');
            if (user.Profile.Name == 'Rubrik Customer Support User' || user.Profile.Name == 'Rubrik Renewal Specialist'  || user.Profile.Name == 'Rubrik Professional Services') {
                var action = component.get('c.getAccountFromContact');
                action.setParams({ 
                    contactId: contactId 
                });

                action.setCallback(this, function(response) {
                    var state = response.getState();
                    if (state === 'SUCCESS') {
                        var accountId = response.getReturnValue();
                        
                        if (accountId) {                            
                            var accField = component.find('accIds');
                            if(accField){
                                accField.set('v.value', accountId);
                                console.log('Account Id from Contact set to Account lookup: ' + accountId);
                                var rscLookup = component.find("customRscLookup");

                                if (rscLookup) {
                                    component.set("v.rscInstanceFilter", "");
                                } 
                                
                                let rscInstanceFilter = '(AccountId__c = \'' + accountId + '\' OR SDPEndUser__c = \'' + accountId + '\')';
                                component.set("v.rscInstanceFilter", rscInstanceFilter);
                            }
                                                    
                        }
                    } else if (state === "ERROR") {
                        console.error('Error while getting Account from Contact: ' + JSON.stringify(response.getError()));
                    }
                });
                $A.enqueueAction(action);
            }
            // var action = component.get('c.getContactRecord');
            // action.setParams({recId:contactId});
            // action.setCallback(this,function(resp){
            //     if(resp.getState() === 'SUCCESS'){
                    
            //         let res = resp.getReturnValue();
            //         component.set('v.isContactFedRamp',res.isFedRAMP__c);
            //         if(res.isFedRAMP__c){
            //             component.set('v.contAccName',res.Account.Name); 
            //             component.set("v.fedRampCustomerName",res.Account.Name );
            //         }else{
            //             component.set('v.accountHeadsUpText',res.Heads_UpTo_Support_Team__c); 
            //         }
                    
            //     }
            //     else if (resp.getState() === "ERROR") {
            //             var errors = resp.getError();
            //             helper.handleErrorMessage(component, errors, 'An error occurred while trying to change the Contact on Case.');
            //     }
            // });
            // $A.enqueueAction(action);
        }
        //Selected Contact removed from form
        else{ 
            var user = component.get('v.userRecord');               

            if (user.Profile.Name == 'Rubrik Customer Support User' || user.Profile.Name == 'Rubrik Renewal Specialist'  || user.Profile.Name == 'Rubrik Professional Services') {
                var rscLookup = component.find("customRscLookup");
                if (rscLookup) {
                    rscLookup.clear();
                } 
                component.set("v.rscInstanceFilter", "");
                component.set("v.caseRecord.RSCInstance__c", null);        
                var accField = component.find('accIds');
                accField.set('v.value', null);
                var caseRec = component.get("v.caseRecord");
                if (caseRec) {
                    caseRec.AccountId = '';
                    component.set("v.caseRecord", caseRec);
                }
            }
            var caseRec = component.get("v.caseRecord");
            caseRec.ContactId = '';
            component.set("v.caseRecord",caseRec);
            component.find('ContactId').set('v.value', '');
            // Restruict case creation is defaultAccount is FedRAMP
            // component.set('v.isContactFedRamp',false);
            // Display defaultAccount Name in Alert Message 
            // let accName = component.get('v.accountName');
            // component.set('v.accountName',accName);
            // component.set("v.fedRampCustomerName", accName);
            // caseRec.ContactId = '';
            // component.set("v.caseRecord",caseRec);
            // re-assigning case field values
            $A.enqueueAction(component.get('c.updateCaseFields'));
        }
    },
    cancel : function(component, event, helper) {
        if (typeof sforce !== 'undefined' && sforce.one) {            
            var navEvt = $A.get("e.force:navigateToObjectHome");
            navEvt.setParams({
                "scope": "Case"
            });
            navEvt.fire();
            
        } else {
            if (window.parent && typeof window.parent.sforce !== 'undefined' && window.parent.sforce.cancel) {
                window.parent.sforce.cancel();                
            } else {
                window.location.href = '/500';
            }
        }
    },
    handleCustomerSuccess :  function(component, event, helper) {
        event.preventDefault();    
        var fields = event.getParam('fields');
        var acctId = component.find('accIds').get('v.value');
        fields.Account__c = acctId;
        fields.Entitlement__c = component.get("v.entitelementId");
        component.find('recordSuccessForm').submit(fields);
    },
    saveCase : function(component, event, helper) {
        // CS21-1325, by Vijay: Fetch queueids by developer name
        var rscValue = component.get("v.selectedRscId");
        let queueMap = component.get("v.queueMap");
        var spinner = component.find("caseSpinner");
        var caseOwnerId = component.get('v.caseOwnerId');
        var acctId = component.find('accIds').get('v.value');
        
        var isOveride = component.get("v.isOveride");
        if(!isOveride){
            var user = component.get('v.userRecord');
            if(user.Profile.Name == 'Rubrik Customer Support User'){
                caseOwnerId = user.Id;
            }else{
                caseOwnerId = queueMap['Unassigned_Cases'];
            }
            if(user.is_Customer_Success_User__c){
                caseOwnerId = queueMap['Customer_Success'];
            }
        }
        
        if(!caseOwnerId){
            event.preventDefault();
            component.set('v.hasCaseOwner',false);
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Warning!",
                "message": "Please select the Case Owner.",
                "type" : "warning"
            });
            toastEvent.fire();
            return;
        }

        let recordId = component.get("v.recordId");
        // NOTE: We are not creating CustomerSuccessOnboarding__c for Cloned Case.
        // NOTE: We are not creating CustomerSuccessOnboarding__c for Cloned Case.
        if((!recordId || !recordId.startsWith('500')) && component.get("v.userRecord").is_Customer_Success_User__c){
            event.preventDefault();
            var fields = event.getParam('fields');
            fields.RSCInstance__c = rscValue;
            fields.OwnerId = caseOwnerId;
            fields.RecordTypeId = component.get('v.recordTypeId');
            fields.End_User_Customer__c = acctId;
            fields.Entitlement__c = component.get("v.entitelementId");
            component.find('recordEditForm').submit(fields);
            $A.util.removeClass(spinner,"slds-hide");
        }else{
            // Rubrik Customer Support User
            if(!!component.get("v.recordId")){
                var caseRec = component.get("v.caseRecord");
                event.preventDefault();       // stop the form from submitting
                var fields = event.getParam('fields');
                fields.RSCInstance__c = rscValue;
                fields.Support_Tunnel__c = caseRec.Support_Tunnel__c;
                fields.Cluster__c = caseRec.Cluster__c;
                fields.Additional_Cluster__c = caseRec.Additional_Cluster__c;
                fields.RecordTypeId = component.get('v.recordTypeId');
                fields.OwnerId = caseOwnerId;
                fields.End_User_Customer__c = acctId;
                component.find('recordEditForm').submit(fields);
            }
            // Normal User
            else{
                event.preventDefault();       // stop the form from submitting
                var fields = event.getParam('fields');
                fields.RSCInstance__c = rscValue;
                fields.OwnerId = caseOwnerId;
                fields.RecordTypeId = component.get('v.recordTypeId');
                fields.End_User_Customer__c = acctId;
                component.find('recordEditForm').submit(fields);
            }
            $A.util.removeClass(spinner,"slds-hide");
        }
        
    },
    handleSuccess : function(component, event, helper) {
        var record = event.getParams().response;

        var recId = record.id;
        let UIThemeDisplayed = component.get("v.UITheme");
        let recordId = component.get("v.recordId");
        var baseUrl = helper.fetchBaseUrl(component , event);

        // Case Actions from Classic 
        var isClassicVFP = component.get("v.vfpUITheme");
        if(isClassicVFP == 'Theme3' || UIThemeDisplayed == 'Theme3'){
            var vfOrigin = baseUrl;
            // If New Case created from Parent record Detail
            if(recordId){
                recId = recId+'-subtab';
            }
            window.postMessage(recId, vfOrigin);
        }
        // New Case From Tab / Account / Contact
        else if(!recordId){
            var workspaceAPI = component.find("workspace");
            workspaceAPI.isConsoleNavigation().then(function(isConsole) {
                if (isConsole) {
                    workspaceAPI.openTab({
                        pageReference: {
                            "type": "standard__recordPage",
                            "attributes": {
                                "recordId": recId,
                                "actionName":"view"
                            },
                            "state": {}
                        },
                        focus: false
                    }).then(function(response) {
                        workspaceAPI.getTabInfo({
                            tabId: response
                        }).then(function(tabInfo) {
                            workspaceAPI.getFocusedTabInfo().then(function(response) {
                                var focusedTabId = response.tabId;
                                workspaceAPI.closeTab({tabId: focusedTabId});
                            })
                            .catch(function(error) {
                                console.log(error);
                            });

                        });
                    }).catch(function(error) {
                        console.log(error);
                    });
                } else {
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": recId,
                        "slideDevName": "detail"
                    });
                    navEvt.fire();
                }
            })
            .catch(function(error) {
                console.log(error);
            });
        }
        // Case Clone LEX
        else{
            var updatedRecord = JSON.parse(JSON.stringify(event.getParams()));
            //sforce.one.navigateToSObject(updatedRecord.response.id, "detail");
            var vfOrigin = baseUrl;
            window.postMessage(updatedRecord.response.id, vfOrigin);
        }
    },
    onException : function(component, event, helper) {
        var spinner = component.find("caseSpinner");
        $A.util.addClass(spinner,"slds-hide");
    },
    openAllSection: function(component, event, helper) {
        component.set("v.activeSections",['A','B','C','D','E']);
    },

    // CS21-2010: [FedRAMP 1.5] Enable case creation in Salesforce for hybrid RSC-G/RSC/CDM customers
    handleCaseSubmission: function(component) {
        component.set("v.isCommercialCustomer", false);
        component.set("v.isFedRamp", false);
        component.set("v.hideSection", false);
        component.set("v.isGTCDenied", false);
        $A.enqueueAction(component.get('c.updateCaseFields'));
    },
    
    handleAccRedirect: function(component, event, helper) {
        window.open('/'+component.get('v.accountId'));
    },
    handleRscSelect : function(component, event, helper) {
        var selectedRecord = event.getParam('selectedRecord');
        
        if (selectedRecord) {
            // This updates the hidden field so it saves
            component.set("v.selectedRscId", selectedRecord.Id);
            component.set("v.caseRecord.RSCInstance__c", selectedRecord.Id);
        } else {
            // This handles the "X" (remove) button click
            component.set("v.selectedRscId", null);
            component.set("v.caseRecord.RSCInstance__c", null);
        }
    }
})