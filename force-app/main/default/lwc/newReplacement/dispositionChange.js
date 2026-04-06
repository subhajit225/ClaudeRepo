export function handleDisposition(selectedDisposition,customIndex,dataModified,entitlementId,keyIdentifier){
    let selectedDesposition = selectedDisposition;
    let displayedData = JSON.parse(JSON.stringify(dataModified));
    let customIndexModified = customIndex;
    displayedData.forEach((currentItemWrapper, index) => {
        if (currentItemWrapper.customIndex != undefined && customIndexModified === currentItemWrapper.customIndex) {
            // Added as part of FY25SR-1207 - Start
            if (currentItemWrapper.mapAssetEntitlements != undefined) {
                // currentItemWrapper.showmapAssetEntitlements = true;
                currentItemWrapper.mapAssetEntitlements = checkIfEntitlementIdPresentAndSetValues(currentItemWrapper.mapAssetEntitlements,customIndex, selectedDesposition,entitlementId,keyIdentifier);
                
            }
            // Added as part of FY25SR-1207 - End

            // currentItemWrapper.manualDisposition = setDisposition(currentItemWrapper.manualDisposition,selectedDesposition);
            // currentItemWrapper.selecteddisposition = selectedDesposition;
            // currentItemWrapper.isModified = true;
        }
      
        if (currentItemWrapper.wrapBaseLicense != undefined && currentItemWrapper.wrapBaseLicense.length > 0) {
            currentItemWrapper.wrapBaseLicense = Setvalues(customIndexModified, selectedDesposition, currentItemWrapper.wrapBaseLicense);
        }

        if (currentItemWrapper.wrapHWSupportLines != undefined && currentItemWrapper.wrapHWSupportLines.length > 0){
            currentItemWrapper.wrapHWSupportLines = Setvalues(customIndexModified, selectedDesposition, currentItemWrapper.wrapHWSupportLines);
            currentItemWrapper.wrapHWSupportLines.forEach(currentItem => {
                //FY25SR-2349
                if(customIndexModified === currentItem.customIndex){
                    if(selectedDesposition === 'Renewing'){

                        /*if(currentItem.renewalEndDate != undefined && currentItem.renewalEndDate != null){//CPQ22-6414
                            //currentItem.ReplacementTerm = currentItem.previousReplacementTerm;
                            currentItem.RemainingTerm = currentItem.previousRemainingTerm;
                          if(currentItem.previousRenewalEndDate != undefined){//CPQ22-6414
                                currentItem.renewalEndDate = currentItem.previousRenewalEndDate;//CPQ22-6414
                            }
                        }else{
                                currentItem.ReplacementTerm = 12;
                        }*/
                       if(currentItem.renewalEndDate == undefined || currentItem.renewalEndDate == null){//CPQ22-6414
                                currentItem.ReplacementTerm = 12;
                        }
                        currentItem.disableRenewalEndDate = false;
                       // currentItem.disableTerm = true;
                    }
                }
                //FY25SR-2349
            });
        }
        
        if (currentItemWrapper.wrapAddOnSupportLines != undefined && currentItemWrapper.wrapAddOnSupportLines.length > 0) {
            currentItemWrapper.wrapAddOnSupportLines = Setvalues(customIndexModified, selectedDesposition, currentItemWrapper.wrapAddOnSupportLines);
        }

        if (currentItemWrapper.wrapUpgradeEnt != undefined && currentItemWrapper.wrapUpgradeEnt.length > 0) {
            currentItemWrapper.wrapUpgradeEnt = Setvalues(customIndexModified, selectedDesposition, currentItemWrapper.wrapUpgradeEnt);
        }
    });

    return displayedData;
}

// Added as part of FY25SR-1207 - Start
function checkIfEntitlementIdPresentAndSetValues(currentItemWrapper, customIndex, selectedDesposition , selectedEntitlementId,keyIdentifier) {
    currentItemWrapper.futureValues.forEach(currentItem => { // 
        if(currentItem.keyIdentifier === keyIdentifier && currentItem.entitlementId === selectedEntitlementId){
            currentItem.manualDisposition = setDisposition(currentItem.manualDisposition,selectedDesposition);
            currentItem.selecteddisposition = selectedDesposition;
            currentItem.isModified = true;
            //Added as part of FY25SR-1492
            // Retain the values only if the remaining term is not set to 12
            if(currentItem.ReplacementTerm != 12 && currentItem.RemainingTerm != 12){
                currentItem.previousReplacementTerm = currentItem.ReplacementTerm;
                currentItem.previousRemainingTerm = currentItem.RemainingTerm;
            }
            //FY25SSR-2349
            if(currentItem.selecteddisposition === 'Renewing'){
                // Set the values to 12 on changing or selection of manual disposition reason
               /* if(currentItem.renewalEndDate != undefined && currentItem.renewalEndDate != null){//CPQ22-6414
                    currentItem.ReplacementTerm = currentItem.previousReplacementTerm;//CPQ22-6414
                    currentItem.RemainingTerm = currentItem.previousRemainingTerm;
                    if(currentItem.previousRenewalEndDate != undefined){//CPQ22-6414
                       currentItem.renewalEndDate = currentItem.previousRenewalEndDate; //CPQ22-6414
                    }
                }else{
                        currentItem.ReplacementTerm = 12;
                }*/
               if(currentItem.renewalEndDate == undefined && currentItem.renewalEndDate == null){//CPQ22-6414
                        currentItem.ReplacementTerm = 12;
                }
                //Added as part of FY25SR-1492
                currentItem.disableRenewalEndDate = false;
                //currentItem.disableTerm = true;
               // currentItem.renewalEndDate = '';
                // currentItem.disableTerm = true;
            } else {
                //Added as part of FY25SR-1492
                currentItem.disableRenewalEndDate = true;
                currentItem.disableTerm = false;
                //currentItem.ReplacementTerm = 12;//CPQ22-6414
                //currentItem.RemainingTerm = 12;//CPQ22-6414
            }
            //FY25SSR-2349
            if(currentItem.selecteddisposition != ''){
                currentItem.errors = '';
            }
        }
    });
    return currentItemWrapper;
}
// Added as part of FY25SR-1207 - End

function Setvalues(customIndexModified, selectedDesposition, currentItemWrapperList ){
    currentItemWrapperList.forEach(currentItem => {
        if(customIndexModified === currentItem.customIndex){
            currentItem.manualDisposition = setDisposition(currentItem.manualDisposition,selectedDesposition);
            currentItem.selecteddisposition = selectedDesposition;
            currentItem.isModified = true;
            //Added as part of FY25SR-1492
            // Retain the values only if the remaining term is not set to 12
            if(currentItem.ReplacementTerm != 12 && currentItem.RemainingTerm != 12){
                currentItem.previousReplacementTerm = currentItem.ReplacementTerm;
                currentItem.previousRemainingTerm = currentItem.RemainingTerm;
            }
            //FY25SSR-2349
            if(currentItem.selecteddisposition === 'Renewing'){
                // Set the values to 12 on changing or selection of manual disposition reason
               /* if(currentItem.renewalEndDate != undefined && currentItem.renewalEndDate != null){//CPQ22-6414
                            currentItem.ReplacementTerm = currentItem.previousReplacementTerm;//CPQ22-6414
                            currentItem.RemainingTerm = currentItem.previousRemainingTerm;
                            if(currentItem.previousRenewalEndDate != undefined){//CPQ22-6414
                                currentItem.renewalEndDate = currentItem.previousRenewalEndDate;
                            }
                }else{
                        currentItem.ReplacementTerm = 12;
                }*/
                if(currentItem.renewalEndDate == undefined || currentItem.renewalEndDate == null){//CPQ22-6414
                        currentItem.ReplacementTerm = 12;
                }
                //Added as part of FY25SR-1492
                
                currentItem.disableRenewalEndDate = false;
                //currentItem.disableTerm = true;
               // currentItem.renewalEndDate = '';
                
            } else {
                //Added as part of FY25SR-1492
                currentItem.disableRenewalEndDate = true;
                currentItem.disableTerm = false;
                //currentItem.ReplacementTerm = 12;//CPQ22-6414
                //currentItem.RemainingTerm = 12;//CPQ22-6414
            }
            //FY25SSR-2349

            if(currentItem.selecteddisposition != ''){
                currentItem.errors = '';
            }
        }

    });

    return currentItemWrapperList;
}

function setDisposition(dispositionList, selectedDesposition){
    dispositionList.forEach((currItem) => {
        if (selectedDesposition === currItem.value) {
            currItem.selected = true;
        } else {
            currItem.selected = false;
        }

    });
    return dispositionList;
}