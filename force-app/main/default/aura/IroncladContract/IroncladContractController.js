({
    handleInit: function (component, event, helper) {
        var checkInterval = setInterval($A.getCallback(function() {
            var checkboxElement = document.querySelectorAll('input[type="checkbox"]')[0];
            var softwareDetails = sessionStorage.getItem('softwareDetails');
            softwareDetails = JSON.parse(softwareDetails);
            if (softwareDetails) {
                component.set("v.releaseType",softwareDetails.releaseType);
                component.set("v.releaseId",softwareDetails.releaseId);
                component.set("v.softwareName",softwareDetails.softwareName);
                component.set("v.isProduction",softwareDetails.isProduction);
            }
            if (checkboxElement) {
                let expandCollapseBtn = document.querySelector(".ps-expand-button");
                let contractBody = document.querySelector('.ps-contract-body');
                /* CS21-2046: Added by Ashish, Open contract in new page to fix pop-ups issue*//*
                checkboxElement.addEventListener('change', function(event) {
                    let divElement = document.querySelector('.ps-contract-body');
                    if (event.target.checked) {
                        divElement.style.display='None';
                        expandCollapseBtn.style.display = '';
                    } else {
                        divElement.style.display='';
                        expandCollapseBtn.style.display = 'None';
                    }
                });

                expandCollapseBtn.addEventListener('click', function(event) {
                    let divElement = document.querySelector('.ps-contract-body');
                    divElement.style.display='';
                    expandCollapseBtn.style.display = 'None';
                });
                */
               /* CS21-2046: Added by Ashish, Open contract in new page to fix pop-ups issue*/

                contractBody.addEventListener("scroll", function() {
                    if (contractBody.scrollTop + contractBody.clientHeight + 10>= contractBody.scrollHeight) {
                        let labelElements = document.querySelectorAll('.ps-checkbox-container');
                        if (labelElements.length >= 2) {
                            var acceptAgreementElement = labelElements[1];
                            acceptAgreementElement.style.display = "";
                            var srollBottomElement = labelElements[0];
                            srollBottomElement.style.display = "None";
                        }
                    }
                  });
                
                // Clear the interval once the checkbox is found
                clearInterval(checkInterval);
            }
        }), 100); 
    },
    scriptsLoaded: function (component, event, helper) {
        let vaultURL = $A.get("$Label.c.EULA_vaultURL");
        var softwareDetails = sessionStorage.getItem('softwareDetails');
        softwareDetails = JSON.parse(softwareDetails);
        if (softwareDetails) {
            component.set("v.releaseType",softwareDetails.releaseType);
            component.set("v.releaseId",softwareDetails.releaseId);
            component.set("v.softwareName",softwareDetails.softwareName);
            component.set("v.isProduction",softwareDetails.isProduction);
        }
        
        // This method will be called when the component is loaded
        let subdomains = [];
        let isProduction = component.get("v.isProduction");
        // PactSafe settings.
        let siteAccessId = $A.get("$Label.c.IroncladSiteId");
        let groupKey = isProduction ? $A.get("$Label.c.IroncladGroupKey") : $A.get("$Label.c.IroncladGroupKeySandbox");
        if (vaultURL != 'https://vault.pactsafe.io/') {

            _ps("create", siteAccessId, {
                disable_sending: true
            });

            _ps("load", groupKey, {
                container_selector: "eula-contract",
                test_mode: true
            });

            _ps.on('valid', function (params, context) {
                component.set("v.isAgreedReceivedFromIronClad", true);
                component.set("v.showError", false);
                component.set("v.showSpinner", false);
            });

            var action = component.get("c.getUserDetails");
            action.setCallback(this, function (response) {
                let state = response.getState();

                if (state === "SUCCESS") {
                    let userDetails = response.getReturnValue();
                    component.set("v.userDetails", userDetails);
                    component.set("v.showSpinner", false);
                    _ps("set", "signer_id", userDetails.Email);
                    _ps("send", "updated", {
                        disable_sending: false,
                        custom_data: {
                            first_name: userDetails.FirstName,
                            last_name: userDetails.LastName,
                            company_name: userDetails.Account.Name
                        }
                    });
                } else if (state === "INCOMPLETE") {
                    component.set("v.hasApexError", true);
                    component.set("v.showSpinner", false);
                    console.log("Error :: please contact your system admin");
                } else if (state === "ERROR") {
                    let errors = response.getError();
                    component.set("v.hasApexError", true);
                    component.set("v.showSpinner", false);
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
        else {
            try {
                var action = component.get("c.getUserDetails");
                action.setCallback(this, function (response) {
                    let state = response.getState();

                    if (state === "SUCCESS") {
                        let userDetails = response.getReturnValue();
                        component.set("v.userDetails", userDetails);
                        var contract = component.get("c.getContractDetails");
                        contract.setParams({ siteAccessId: siteAccessId, groupKey: groupKey });
                        contract.setCallback(this, function (response) {
                            let state = response.getState();
                            if (state == "SUCCESS") {
                                // --- check status code --- 
                                let contractResponse = response.getReturnValue();
                                contractResponse = JSON.parse(contractResponse);
                                if (contractResponse.statusCode == 200) {
                                    let contractBody = contractResponse.resBody;
                                    let contractHtml = '';                                   
                                    contractHtml = helper.getSubString('contract_html: "', '",\n', contractBody);                                    
                                    if (contractHtml != '') {
                                        contractHtml = contractHtml.replaceAll('\\n', "");
                                        contractHtml = contractHtml.replaceAll('\\"', "");
                                        var container = component.find("eula-contract-div");
                                        container.getElement().innerHTML = contractHtml;
                                        component.set("v.isAgreedReceivedFromIronClad", true);
                                        component.set("v.showError", false);
                                        component.set("v.showSpinner", false);

                                        let group = helper.getSubString('group: ', ',\n', contractBody);
                                        component.set("v.groupId", group);
                                        let contracts = helper.getSubString('contracts: ', ',\n', contractBody);
                                        component.set("v.contracts", contracts);
                                        let versions = helper.getSubString("versions: ['", "'],\n", contractBody);
                                        component.set("v.versions", versions);
                                        helper.applyCustomCSS();
                                    }
                                    else {
                                        component.set("v.hasApexError", true);
                                        component.set("v.showSpinner", false);
                                        console.log("Error :: please contact your system admin, contractHtml is Empty!!");
                                    }
                                }
                                else {
                                    component.set("v.hasApexError", true);
                                    component.set("v.showSpinner", false);
                                    console.log('Body_', contractResponse.resBody);
                                    console.log('StatusCode_', contractResponse.statusCode);
                                }
                            }
                            else if (state === "INCOMPLETE") {
                                component.set("v.hasApexError", true);
                                component.set("v.showSpinner", false);
                                console.log("Error :: please contact your system admin");
                            }
                            else if (state === "ERROR") {
                                let errors = response.getError();
                                component.set("v.hasApexError", true);
                                component.set("v.showSpinner", false);
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
                        $A.enqueueAction(contract);
                    } else if (state === "INCOMPLETE") {
                        component.set("v.hasApexError", true);
                        component.set("v.showSpinner", false);
                        console.log("Error :: please contact your system admin");
                    } else if (state === "ERROR") {
                        let errors = response.getError();
                        component.set("v.hasApexError", true);
                        component.set("v.showSpinner", false);
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
            catch (err) {
                component.set("v.showError", true);
                message = 'Uh oh, something went wrong. Please refresh and try again.';
                component.set("v.errorMessage", message);
                component.set("v.showSpinner", false);
                console.log("Catch error while getting contract --", err);
            }
        }
       
    },
    handleFormSubmit: function (component, event, helper) {
        event.preventDefault();
        let formSubmitted = component.get("v.contractSent");
        let isProduction = component.get("v.isProduction");
        try{
            if (!formSubmitted) {
                //set contractSent Flag to true - to avoid double clicks
                component.set("v.contractSent", true);
                
                let groupKey = isProduction ? $A.get("$Label.c.IroncladGroupKey") : $A.get("$Label.c.IroncladGroupKeySandbox");
                let contractChecked = document.querySelectorAll('input[type="checkbox"]')[0].checked; // to validate if the agreed checkbox is clicked
                let isValidFromIronClad = component.get("v.isAgreedReceivedFromIronClad"); //return value from Ironclad when agreed
                let hasApexError = component.get("v.hasApexError");
                let sendAgreedtoIronclad = contractChecked && contractChecked === true && isValidFromIronClad && isValidFromIronClad === true;
                let userDetails = component.get("v.userDetails");
                let software = component.get("v.softwareName");
                let siteAccessId = $A.get("$Label.c.IroncladSiteId");
    
                if (sendAgreedtoIronclad) {
                    let vaultURL = $A.get("$Label.c.EULA_vaultURL");
                    // Set custom data that gets sent on acceptance.
                    if (vaultURL != 'https://vault.pactsafe.io/') {
                        // Set custom data that gets sent on acceptance.
                        _ps('set', 'custom_data', {
                            Source: 'Rubrik Support Portal',
                            AccountName: userDetails.Account.Name,
                            FullName: userDetails.Name,
                            SoftwareName: software
                        });

                        // We don't need to block the form submission at this point.
                        // Manually send acceptance with the PactSafe Group.
                        _ps(groupKey + ':send', "agreed", {
                            disable_sending: false,
                            // The event_callback function will be invoked once the "send" is complete.
                            event_callback: function (err, eventType, embeddedContract, payload) {
                                if (err) {
                                    if (err == 'Send encountered a network error') {
                                        component.set("v.showSpinner", true);
                                        console.log('..' + JSON.stringify(embeddedContract));
                                        var action = component.get("c.calloutToIronClad");
                                        action.setParams({ requestBody: JSON.stringify(embeddedContract) });
                                        helper.downloadSoftware(component, event, helper, embeddedContract);
                                    } else {
                                        component.set("v.contractSent", false);
                                        component.set("v.showError", true);
                                        component.set("v.errorMessage", 'Uh oh, something went wrong. Please contact your system admin.');
                                        return false; // Prevent form submission due to error.                                
                                    }
                                } else {
                                    component.set("v.showSpinner", true);
                                    console.log('..' + JSON.stringify(embeddedContract));
                                    helper.downloadSoftware(component, event, helper, embeddedContract);
                                }
                                // The send is complete and acceptance was captured successfully.
                            }
                        });
                    }
                    else {
                        let title = '';
                        let page_url = '';
                        let page_domain = '';
                        let page_path = '';
                        let referrer = '';
                        let browser_timezone = '';
                        let browser_locale = '';
                        let operating_system = '';
                        let environment = '';
                        let screen_color_depth = '';
                        let screen_resolution = '';
                        let user_agent = '';
                        let origin = '';
                        try {
                            
                            var softwareDetails = sessionStorage.getItem('softwareDetails');
                            softwareDetails = JSON.parse(softwareDetails);
                            const dt = new Date();
                            let diffTZ = dt.getTimezoneOffset();
                            let operatingSystem = helper.getOperatingSystemDetail();
                            title = softwareDetails.pageTitle;
                            page_url = softwareDetails.pageURL;
                            page_domain = window.location.hostname;
                            page_path = softwareDetails.pagePath;
                            referrer = softwareDetails.pageURL;
                            browser_timezone = diffTZ;
                            browser_locale = navigator.language;
                            operating_system = operatingSystem;
                            environment = helper.detectDeviceType();
                            screen_color_depth = screen.colorDepth+'-bit';
                            screen_resolution = screen.width+'x'+screen.height;
                            user_agent = navigator.userAgent;
                            origin = window.location.origin;
                        }
                        catch(err) {
                            console.log("Error message while getting details -",err);
                        }
                        
                        let embeddedContractBody = {
                            'site_id': siteAccessId,
                            'signer_id': userDetails.Email,
                            'version': component.get("v.versions"),
                            'event_type': 'agreed',
                            'contracts': component.get("v.contracts"),
                            'group': component.get("v.groupId"),
                            'page_title': title,
                            'page_url': page_url,
                            'page_domain': page_domain,
                            'page_path': page_path,
                            'referrer': referrer,
                            'browser_timezone': browser_timezone,
                            'browser_locale': browser_locale,
                            'operating_system': operating_system,
                            'environment': environment,
                            'screen_color_depth': screen_color_depth,
                            'screen_resolution': screen_resolution,
                            'user_agent': user_agent,
                            'origin': origin,
                            'custom_data': {
                                Source: 'Rubrik Support Portal',
                                AccountName: userDetails.Account.Name,
                                FullName: userDetails.Name,
                                SoftwareName: software,
                                FirstName: userDetails.FirstName,
                                LastName: userDetails.LastName,
                                Company: userDetails.Account.Name
                            }
                        }
                        let message = '';
                        component.set("v.showSpinner", true);
                        var action = component.get("c.calloutToIronClad");
                        action.setParams({ requestBody: JSON.stringify(embeddedContractBody) });
                        action.setCallback(this, function (response) {
                            let state = response.getState();
                            if (state == "SUCCESS") {
                                let statusCode = response.getReturnValue();
                                if (statusCode == 200) {
                                    helper.downloadSoftware(component, event, helper, embeddedContractBody);
                                }
                                else {
                                    component.set("v.showSpinner", false);
                                    component.set("v.contractSent", false);
                                    component.set("v.showError", true);
                                    message = 'Uh oh, something went wrong. Please refresh and try again.';
                                    component.set("v.errorMessage", message);
                                }
                            }
                            else if (state === "INCOMPLETE") {
                                component.set("v.showSpinner", false);
                                component.set("v.contractSent", false);
                                component.set("v.showError", true);
                                message = 'Uh oh, something went wrong. Please refresh and try again.';
                                component.set("v.errorMessage", message);
                            }
                            else if (state === "ERROR") {
                                let errors = response.getError();
                                component.set("v.showSpinner", false);
                                component.set("v.contractSent", false);
                                component.set("v.showError", true);
                                message = 'Uh oh, Salesforce error. Please contact your system admin.';
                                component.set("v.errorMessage", message);
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

                } else {
                    component.set("v.contractSent", false);
                    //component.set("v.isAgreedReceivedFromIronClad", false);
                    component.set("v.showError", true);
                    
                    let message = 'You must accept the EULA before continuing.';
                    if (hasApexError && hasApexError === true) {
                        message = 'Uh oh, Salesforce error. Please contact your system admin.'
                    } else if (contractChecked && contractChecked === true) {
                        message = 'Uh oh, something went wrong. Please refresh and try again.' 
                    }
                    
                    component.set("v.errorMessage", message);
                }
            }
        }
        catch(err) {
            component.set("v.showSpinner", false);
            component.set("v.contractSent", false);
            component.set("v.showError", true);
            let message = 'Uh oh, something went wrong. Please refresh and try again.' ;
            component.set("v.errorMessage", message);
            console.log("Catch error while sending contract --", err);
        }
    },/* CS21-2046: Added by Ashish, Open contract in new page to fix pop-ups issue*/
    handleSoftwareDownload: function(component, event, helper) {
        //added for CS21-706  
        component.set("v.showSpinner", true);
        var releaseSoft = event.getParam("releaseId");
        var embeddedContract = event.getParam("embeddedContract");
        
        var action = component.get("c.gets3Link");
        
        action.setParams({
            "Id": releaseSoft,
            "isName": false,
            "ironcladResponse": embeddedContract
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                // ---- CS21-2046: Download software when pop-ups are blocked ---
                var urlEvent = $A.get("e.force:navigateToURL");
                urlEvent.setParams({
                    "url": response.getReturnValue()
                });
                //urlEvent.fire();
                window.location.href = response.getReturnValue();
                component.set("v.isSoftwareDownloaded",true);
                component.set("v.showSpinner", false);
                setTimeout(function() {
                    var softwareDetails = sessionStorage.getItem('softwareDetails');
                    softwareDetails = JSON.parse(softwareDetails);
                    component.set("v.showSpinner", true);
                    window.location.href = softwareDetails.pageURL;
                    // Clear the session storage
                    sessionStorage.removeItem('softwareDetails');
                }, 3000);
                
            } else if (state === "INCOMPLETE") {
                component.set("v.showSpinner", false);
                console.log("Error :: please contact your system admin");
            } else if (state === "ERROR") {
                component.set("v.showSpinner", false);
                let errors = response.getError();
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
    /* CS21-2046: Added by Ashish, Open contract in new page to fix pop-ups issue*/
})