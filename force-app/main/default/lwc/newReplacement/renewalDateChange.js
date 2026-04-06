// Added this method as part of FY25SR-1215
export function handleRenewalDateChange(selectedRenewalDate,customIndex,dataModified,errorMessages,selectedEntitlementId,keyIdentifier,fullSelected,massTerm){
    let renewalDateError = '';

    errorMessages.forEach(currentItem => {
       if(currentItem.Message_Label__c === 'Renewal_end_date_on_renewal_lines'){
            renewalDateError = currentItem.Error_Message__c;
       }
    });

    dataModified.forEach((currentItemWrapper, index) => {
        
      if (currentItemWrapper.customIndex != undefined) {
            // currentItemWrapper = SetvaluesEachWrapper(customIndex, selectedRenewalDate, currentItemWrapper,renewalDateError );
            //Future Transaction
            // Added as part of FY25SR-1207 - Start
            if(fullSelected == true){
                if (currentItemWrapper.mapAssetEntitlements != undefined && currentItemWrapper.rowSelected == true) {
                currentItemWrapper.showmapAssetEntitlements = true;
                currentItemWrapper.mapAssetEntitlements = checkIfEntitlementIdPresentAndSetValues(currentItemWrapper.mapAssetEntitlements,customIndex, selectedRenewalDate ,renewalDateError, selectedEntitlementId,keyIdentifier,currentItemWrapper.wrapInactiveEnt,fullSelected,massTerm);
                
            }
            }
            else if (customIndex == currentItemWrapper.customIndex){
            if (currentItemWrapper.mapAssetEntitlements != undefined) {
                currentItemWrapper.showmapAssetEntitlements = true;
                currentItemWrapper.mapAssetEntitlements = checkIfEntitlementIdPresentAndSetValues(currentItemWrapper.mapAssetEntitlements,customIndex, selectedRenewalDate ,renewalDateError, selectedEntitlementId,keyIdentifier,currentItemWrapper.wrapInactiveEnt,fullSelected,massTerm);
                
            }
            }
            // Added as part of FY25SR-1207 - End
      } else {
            //Base Product
            if(currentItemWrapper.wrapBaseLicense != undefined){
                currentItemWrapper.wrapBaseLicense = checkIfIndexPresentAndSetValues(currentItemWrapper.wrapBaseLicense,customIndex, selectedRenewalDate,renewalDateError,fullSelected,massTerm);
            }

            //HW Support
            if(currentItemWrapper.wrapHWSupportLines != undefined){
                currentItemWrapper.wrapHWSupportLines = checkIfIndexPresentAndSetValues(currentItemWrapper.wrapHWSupportLines,customIndex, selectedRenewalDate, renewalDateError,fullSelected,massTerm);
                currentItemWrapper.wrapHWSupportLines = checkIfHWSupportLineIsAutoDisposed(currentItemWrapper.wrapHWSupportLines,currentItemWrapper.wrapBaseLicense);
            }

            //Addons
            if(currentItemWrapper.wrapAddOnSupportLines != undefined){
                currentItemWrapper.wrapAddOnSupportLines = checkIfIndexPresentAndSetValues(currentItemWrapper.wrapAddOnSupportLines,customIndex, selectedRenewalDate, renewalDateError,fullSelected,massTerm);
            }
            //Inactive
            if(currentItemWrapper.wrapInactiveEnt != undefined){
                currentItemWrapper.wrapInactiveEnt = checkIfIndexPresentAndSetValues(currentItemWrapper.wrapInactiveEnt,customIndex, selectedRenewalDate,renewalDateError,fullSelected,massTerm);
            }
            //upgrade
            if(currentItemWrapper.wrapUpgradeEnt != undefined){
                currentItemWrapper.wrapUpgradeEnt = checkIfIndexPresentAndSetValues(currentItemWrapper.wrapUpgradeEnt,customIndex, selectedRenewalDate,renewalDateError,fullSelected,massTerm);
            }
        }
    });

    return dataModified;

}
// Added as part of FY25SR-1207 - Start
function checkIfEntitlementIdPresentAndSetValues(currentItemWrapper, customIndex, selectedRenewalDate ,renewalDateError, selectedEntitlementId,keyIdentifier,inactiveEntitlement,fullSelected,massTerm) {
    let mapBaseEntToInactiveEnt = new Map();
    if(inactiveEntitlement != undefined && inactiveEntitlement.length > 0){
        inactiveEntitlement.forEach(currentItem => {
            if (mapBaseEntToInactiveEnt.has(currentItem.baseProdIds)) {
                let listEnt = mapBaseEntToInactiveEnt.get(currentItem.entitlementId);
                listEnt.push(currentItem);
                mapBaseEntToInactiveEnt.set(currentItem.entitlementId, listEnt);
            } else {
                let listEnt = [];
                listEnt.push(currentItem);
                mapBaseEntToInactiveEnt.set(currentItem.entitlementId, listEnt);
            }
        });
    }
    currentItemWrapper.futureValues.forEach(element => {
        if(
            (element.keyIdentifier === keyIdentifier && 
            element.entitlementId === selectedEntitlementId) || (fullSelected == true && element.rowSelected  == true ) ){
            element = SetvaluesEachWrapper(customIndex, selectedRenewalDate, element ,renewalDateError);
            if(mapBaseEntToInactiveEnt.has(element.entitlementId)){
                element.ReplacementTerm = calculateSubscriptionTerm(mapBaseEntToInactiveEnt.get(element.entitlementId)[mapBaseEntToInactiveEnt.get(element.entitlementId).length - 1].EndDate , element.renewalEndDate,null);
            }
        }
    });
    return currentItemWrapper;
}
// Added as part of FY25SR-1207 - End

// Added this method as part of FY25SR-1215
function checkIfIndexPresentAndSetValues(currentItemWrapper, customIndex, selectedRenewalDate ,renewalDateError,fullSelected,massTerm) {
    if((currentItemWrapper.find(ele => ele.customIndex === customIndex) && fullSelected == false)||(fullSelected == true && currentItemWrapper.find(ele => ele.rowSelected == true))) {
        currentItemWrapper = Setvalues(customIndex, selectedRenewalDate, currentItemWrapper,renewalDateError,fullSelected,massTerm);
    }

    return currentItemWrapper;
}

// Added this method as part of FY25SR-1215
function checkIfHWSupportLineIsAutoDisposed(hwSupportList,baseLicenseList){
    let isBaseLicenceModified = false;
    let assetSelected = '';
    let newRenewalEnddate;
    if(baseLicenseList != undefined && baseLicenseList.length > 0){
    baseLicenseList.forEach(currentItem => {
        if(currentItem.isModified && currentItem.rowSelected){
            isBaseLicenceModified = true;
            newRenewalEnddate = currentItem.renewalEndDate;
                if(currentItem.assetsAvailable != undefined && currentItem.assetsAvailable.length > 0){

            currentItem.assetsAvailable.forEach(asset => {
                if(asset.selected){
                    assetSelected = assetSelected + asset.value;
                }
            });
        }
            }
        });
    }
    if(isBaseLicenceModified){
        hwSupportList.forEach(element => {
            let isAutoDispose = false;
            let isCorrectAsset = false;

            element.autoDisposition.forEach(currentItem => {
                if(currentItem.selected){
                    isAutoDispose = true;
                }
            });

            if(element.assetsAvailable != undefined && element.assetsAvailable.length > 0){
            element.assetsAvailable.forEach(asset => {
                if(asset.selected && assetSelected.includes(asset.value)){
                    isCorrectAsset = true;
                }
            });
            }

            if(element.rowSelected && isAutoDispose && isCorrectAsset){
                element.isModified = isAutoDispose;
                element.renewalEndDate = newRenewalEnddate;
            }
        });
    }
    return hwSupportList;
}

// Added this method as part of FY25SR-1215
function Setvalues(customIndex, selectedRenewalDate, currentItemWrapperList,renewalDateError,fullSelected,massTerm){
    currentItemWrapperList.forEach(element => {
        element = SetvaluesEachWrapperIfCustomIndexMatches(customIndex, selectedRenewalDate, element,renewalDateError,fullSelected,massTerm);
    });
    return currentItemWrapperList;
}

// Added as part of FY25SR-1207 - Start
function SetvaluesEachWrapperIfCustomIndexMatches(customIndex, selectedRenewalDate, element ,renewalDateError,fullSelected,massTerm){
    if((element.customIndex === customIndex && fullSelected == false) || (element.rowSelected == true && fullSelected == true )){
        element = SetvaluesEachWrapper(customIndex, selectedRenewalDate, element ,renewalDateError,massTerm);
    }
    return element;
}
// Added as part of FY25SR-1207 - End

// Added this method as part of FY25SR-1215
function SetvaluesEachWrapper(customIndex, selectedRenewalDate, element ,renewalDateError,massTerm){
    if (massTerm != undefined && massTerm != null && (!element.skuProdName && element.selecteddisposition !=='Refreshed')) {
      
        let newEndDate = new Date(element.EndDate);
        let massTermInt = parseInt(massTerm, 10); // ensures numeric
        if (isNaN(massTermInt)) {
            console.error('Invalid massTerm:'+ massTerm);
        } else {
            newEndDate.setMonth(newEndDate.getMonth() + massTermInt);
        }
        element.renewalEndDate = newEndDate;
         //console.log('element.renewalEndDate renewal end date',element.renewalEndDate);
        element.isModified = true;
        element.errors = '';
        
    }
    else if(!element.skuProdName && element.selecteddisposition !=='Refreshed'){
        element.renewalEndDate = selectedRenewalDate;
        element.isModified = true;
        let selectedEndDate = new Date(selectedRenewalDate);
        let endDate = new Date(element.EndDate);
        // todaySDate.setHours(0,0,0,0);
        if(selectedEndDate < endDate) {
            element.errors = renewalDateError;
        } else {
            element.errors = '';
        }
    }
        if(selectedRenewalDate === null && (!massTerm)){
            element.disableTerm = false;
            //Added as part of FY25SR-1492 to reassign the replacement term in case the user blanks out the Renewal end Date
            element.ReplacementTerm = 12;
            element.errors = '';
        } else {
            if(!element.skuProdName &&  element.selecteddisposition !== 'Refreshed' && element.selecteddisposition !== 'At Risk' && element.selecteddisposition !== 'Renew Later'){
           // element.disableTerm = true;
            }
            //Added as part of FY25SR-1492 to retain the replacement term
            element.previousReplacementTerm = element.ReplacementTerm;
            element.previousRemainingTerm = element.RemainingTerm;

            //Calculate term based on end date of inactive line if inactive line present
            if(element.wrapInactiveEnt != undefined && element.wrapInactiveEnt.length > 0){
                //Added as part of FY25SR-1492 to recalculate the replacement term using inactive lines end date and the user entered Renewal End date
                if(!massTerm){
            element.ReplacementTerm = calculateSubscriptionTerm(element.wrapInactiveEnt[element.wrapInactiveEnt.length - 1].EndDate , element.renewalEndDate,null);
                }
                else{
            element.ReplacementTerm = massTerm;
            let newEndDate = new Date(element.wrapInactiveEnt[element.wrapInactiveEnt.length - 1].EndDate);
            let massTermInt = parseInt(massTerm, 10); // ensures numeric
            if (isNaN(massTermInt)) {
                console.error('Invalid massTerm:'+ massTerm);
            } else {
                newEndDate.setMonth(newEndDate.getMonth() + massTermInt);
            }
            element.renewalEndDate = newEndDate;
                }

            } else {
                //Added as part of FY25SR-1492 to recalculate the replacement term using base lines end date and the user entered Renewal End date
                element.ReplacementTerm = calculateSubscriptionTerm(element.EndDate , element.renewalEndDate,null);
            }
            if(element.skuProdName || element.selecteddisposition === 'Refreshed'){
                if(!massTerm){
                    element.renewalEndDate = null;
                    element.ReplacementTerm = element.previousReplacementTerm;
                }
                else
                {element.ReplacementTerm = massTerm;
                 element.renewalEndDate = null;
                }
            
            }

        }

        //FY25SR-2349
        if(element.renewalEndDate != undefined && element.renewalEndDate != null && element.selecteddisposition != undefined && element.selecteddisposition === 'Renewing'){
            element.previousRenewalEndDate = element.renewalEndDate;
            element.previousReplacementTerm = element.ReplacementTerm;
            element.previousRemainingTerm = element.RemainingTerm;
        }
        //FY25SR-2349
    return element;
}

//Added as part of FY25SR-1492 to calculate the months between two dates(Entltlements End date and user selected Renewal End Date)
function calculateSubscriptionTerm(entEndDate, renewalEndDate,massTerm) {
    if(massTerm){
        months = this.massTerm;
    }
    else{
    var months;
    let entEndDateInstance = new Date(entEndDate);
    entEndDateInstance.setDate(entEndDateInstance.getDate()+1);
    let renewalEndDateInstance = new Date(renewalEndDate);
    months = (renewalEndDateInstance.getFullYear() - entEndDateInstance.getFullYear()) * 12;
    months += (renewalEndDateInstance.getMonth() - entEndDateInstance.getMonth());
    months += ( entEndDateInstance.getDate() <= renewalEndDateInstance.getDate() ? 1 : 0);
    // months -= entEndDateInstance.getMonth();
    // months += renewalEndDateInstance.getMonth();
    return months <= 0 ? 0 : months;
    }
}