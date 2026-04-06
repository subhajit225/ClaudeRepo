({
	doinit : function(component, event, helper) {
        var action = component.get("c.caseEntitlementDetails");
        action.setParams({'caseId': component.get("v.recordId")});
        action.setCallback(this,function(res){
            if(res.getState() === 'SUCCESS'){
                var resp = res.getReturnValue();
                if(!resp.isAuthorized){
                    alert('You are not authorized to access this case.');
                    if(resp.isRenewalCase){
                        var workspaceAPI = component.find("workspace");
                        workspaceAPI.isConsoleNavigation().then(function(isConsole) {
                            if (isConsole) {
                                workspaceAPI.getFocusedTabInfo().then(function(response) {
                                    var focusedTabId = response.tabId;
                                    workspaceAPI.closeTab({tabId: focusedTabId});
                                })
                                .catch(function(error) {
                                    console.log(error);
                                });
                            }else{
                                history.back();
                            }
                        });
                        history.back();
                    }
                }
                component.set("v.hasActive",resp.isSubscribed);
                component.set("v.hasDiffDistr",resp.hasDiffDistr);
                component.set("v.isRenewalCase",resp.isRenewalCase);
                component.set("v.isCustomerSuccessCase",resp.isCustomerSuccessCase);
                component.set("v.distrString",resp.distributorLookup);
                console.log('hasActive---->',component.get("v.hasActive"));
                component.set("v.activeEntitlements",resp.entitlementNames);
            	component.set("v.USFederal",resp.isUSFederalAccount);
                component.set("v.isUSFederalAccountPurchasedOrApproval",resp.isUSFederalAccountPurchasedOrApproval);
                component.set("v.isFedRAMP",resp.isFedRAMPAccount);
                component.set("v.isJiraWarned",resp.isJiraWarned);
                component.set("v.assistUrl",resp.assistUrl);
                component.set("v.autoShow",true);
                component.set('v.accountName',resp.accName);
                component.set('v.ActualaccountName',resp.ActualaccountName);
                component.set('v.completeEditionPdtName',resp.completeEdnPdt);
                component.set('v.completeEdition',resp.isActivated);
                component.set('v.igneous',resp.isIgneous);
                component.set("v.isRSCCDM",resp.isRSCCDMAccount);
                
                if(resp.objCase
                    && resp.objCase.Account){
                        component.set('v.accId',resp.objCase.AccountId);
                }
                
                // 2450
                if(resp.objCase
                   && resp.objCase.Account.Approved_software_program__c
                   && resp.objCase.Account.Approved_software_program__c.includes('Approved CDM 8.1 extension')){
                    let softVer = resp.objCase.Account.Approved_software_program__c;
                    softVer = softVer.includes(';') ? softVer.replace(/;/g, ', ') : softVer;
                    component.set("v.approvedSoftwareVersion",softVer);
                }

                // 2428
                if(resp.objCase
                   && resp.objCase.Account.GTC__c
                   && resp.objCase.Account.GTC__c.includes('Denied')){
                    	component.set("v.isGTCDenied",true);
                }
                
                // method call
                var action2 = component.get("c.getRansomware");
                var cacheBuster = new Date().getTime();
                action2.setParams({'caseId': component.get("v.recordId"), 'cacheBuster':cacheBuster});
                action2.setCallback(this, function(response2) {
                    var state2 = response2.getState();
                    if (state2 === "SUCCESS") {
                        if(response2.getReturnValue()){
                            component.set("v.rrtBanner",true);   
                        }else{
                            component.set("v.rrtBanner",false);   
                        }
                    } else {
                        console.error("caseEntitlement Error in getRansomware Method: ", response2.getError());
                        component.set("v.rrtBanner",false);   
                    }
                });
                $A.enqueueAction(action2);
            }
            else {
                console.error("caseEntitlement Error in caseEntitlementDetails Method: ", res.getError());
            }
        });
        $A.enqueueAction(action);
	},
    
    handleAccRedirect: function(component, event, helper) {
        window.open('/'+component.get('v.accId'));
    }
})