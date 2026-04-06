export function dataValidity(displayedData,quoteDetails,errorMessage,exceptionOptions, misMatchExcep){
    let displayedModified = JSON.parse(JSON.stringify(displayedData));
    let errorMessages = JSON.parse(JSON.stringify(errorMessage));
    let dispositionReasonError = '';
    let allAssetsQuantityToBeSelectedError  = '';
    let replacementTermMin12MonthsError   = '';
    let replacementTermDealOpsError  = '';
    let replacementTermSalesOpsError = '';
    let futureTransactionError = '';
    let futureTransactionPartialChurnError ='';
    let mismatchQuantityError = '';
    let nonAssetToNonAssetErrors = new Map();
    errorMessages.forEach(currentItem => {
       if(currentItem.Message_Label__c === 'All Assets / Quantity To Be Selected'){
            allAssetsQuantityToBeSelectedError = currentItem.Error_Message__c;
       } else if(currentItem.Message_Label__c === 'Disposition Reason'){
            dispositionReasonError = currentItem.Error_Message__c;
       } else if(currentItem.Message_Label__c === 'Replacement Term Deal Ops'){
            replacementTermDealOpsError = currentItem.Error_Message__c;
       } else if(currentItem.Message_Label__c === 'Replacement Term Min 12 Months'){
            replacementTermMin12MonthsError = currentItem.Error_Message__c;
       } else if(currentItem.Message_Label__c === 'Term Exception: Minimum Term'){
            replacementTermSalesOpsError = currentItem.Error_Message__c;
       }  else if(currentItem.Message_Label__c === 'Future Transaction Partial Split'){
            futureTransactionError = currentItem.Error_Message__c;
       }  else if(currentItem.Message_Label__c === 'Future Transaction Partial Churn'){
            futureTransactionPartialChurnError = currentItem.Error_Message__c;
       } else if(currentItem.Message_Label__c === 'Mismatch Quantity Error') {
            mismatchQuantityError = currentItem.Error_Message__c;
       } else if(currentItem.Message_Label__c === 'Partial Replacement Non Asset') {
            nonAssetToNonAssetErrors.set('Partial Replacement Non Asset',currentItem.Error_Message__c);
       } else if(currentItem.Message_Label__c === 'Mismatch Quantity Exception') {
           nonAssetToNonAssetErrors.set('Mismatch Quantity Exception', currentItem.Error_Message__c);
       } else if(currentItem.Message_Label__c === 'No Mismatch Exception found') {
            nonAssetToNonAssetErrors.set('No Mismatch Exception found', currentItem.Error_Message__c);
       }
    });

    /*if(!checkIfErrorAdded(displayedModified)){//CPQ22-6462
        //check data Validity For Aroyo (-3 + 12) entitlements
        displayedModified = checkDataValidityForDispositionReasonOfArroyoEnt(displayedModified,dispositionReasonError);
    }*/
    
    if(!checkIfErrorAdded(displayedModified)){
        // Check data validity for All the assets being selected
        displayedModified = checkDataValidityAllTheAssetsBeingSelected(displayedModified,allAssetsQuantityToBeSelectedError, mismatchQuantityError, misMatchExcep);
    }

    if(!checkIfErrorAdded(displayedModified)){
        // Check data validity for full quantity being selected for non asset based entitlement
        displayedModified = checkDataValidityFullQuantityForNonAssetsBeingSelected(displayedModified,allAssetsQuantityToBeSelectedError,exceptionOptions,nonAssetToNonAssetErrors, misMatchExcep);
    }

    if(!checkIfErrorAdded(displayedModified)){
        // Check data validity for replacement term for deal ops exception
        if(quoteDetails != undefined && (quoteDetails.RWD_Deal_Ops_Exception__c != undefined && quoteDetails.RWD_Deal_Ops_Exception__c.includes('Replacement Min term exception') 
        //|| quoteDetails.RWD_Sales_Rep_Exception__c != undefined && quoteDetails.RWD_Sales_Rep_Exception__c.includes('Term Exception: Minimum Term')
        )){
            displayedModified = checkDataValidityForReplacementTermDealOppsSalesOpps(displayedModified,replacementTermDealOpsError,replacementTermMin12MonthsError,replacementTermSalesOpsError,quoteDetails);
        } else {
            // Check data validity for replacement term to be greater than 12
            displayedModified = checkDataValidityForReplacementTerm(displayedModified,replacementTermMin12MonthsError);
        }
    }

    if(!checkIfErrorAdded(displayedModified)){
         // Check data validity for future Transactions for the Partial Churn
        displayedModified = checkDataValidityFuturePartialChurn(displayedModified,futureTransactionPartialChurnError);
    }
    if(!checkIfErrorAdded(displayedModified)){

         // Check data validity for future Transactions for the R6 and R7
        displayedModified = checkDataValidityFutureR6R7(displayedModified,futureTransactionError);
    }

    return displayedModified;
}

function anyErrorsMethod(currentItemWrapper){
    let errorsVal = false;
    currentItemWrapper.forEach(currentItem => {
        if(currentItem.errors != '') {
            errorsVal = true; 
        }
    });
    return errorsVal;
}
export function handleQuoteHeaderValidity(displayedData, exceptionOptions, comments, errorMessage) {
    let businessJustification = '';
    let noRowSelectedError;
    let errorMessages = JSON.parse(JSON.stringify(errorMessage));
     errorMessages.forEach(currentItem => {
        if(currentItem.Message_Label__c === 'Business Justification Error') {
            businessJustification = currentItem.Error_Message__c;
        }
        
        if(currentItem.Message_Label__c === 'No row selected') {
            noRowSelectedError = currentItem.Error_Message__c;
        }
     });
    // optimization: consider selected exceptions except "Do Not Consolidate Replacement Lines"
    const hasRelevantSelectedException = Array.isArray(exceptionOptions) && exceptionOptions.some(ex =>
        ex && ex.selected && typeof ex.value === 'string' && ex.value.trim().toLowerCase() !== 'do not consolidate replacement lines'
    );
    if(hasRelevantSelectedException && !comments && comments === '') {
        return businessJustification;
    }
    else if(exceptionOptions.find(ex => ex.selected == true)) {
        let noRowSelected = 0;
        displayedData.forEach(currentItemWrapper => {
            if (currentItemWrapper.wrapBaseLicense != undefined && currentItemWrapper.wrapBaseLicense.length > 0 ) {
                let filterResult = currentItemWrapper.wrapBaseLicense.filter(ele=>ele.selecteddisposition);
                if(filterResult && filterResult.length > 0) {
                    noRowSelected++;
                }
            }
            if (currentItemWrapper.wrapAddOnSupportLines != undefined && currentItemWrapper.wrapAddOnSupportLines.length > 0 ) {
                let filterResult = currentItemWrapper.wrapBaseLicense.filter(ele=>ele.selecteddisposition);
                if(filterResult && filterResult.length > 0) {
                    noRowSelected++;
                }
            }

            if (currentItemWrapper.wrapUpgradeEnt != undefined && currentItemWrapper.wrapUpgradeEnt.length > 0 ) {
                let filterResult = currentItemWrapper.wrapBaseLicense.filter(ele=>ele.selecteddisposition);
                if(filterResult && filterResult.length > 0) {
                    noRowSelected++;
                }
            }
            if(currentItemWrapper.mapAssetEntitlements != undefined && currentItemWrapper.mapAssetEntitlements.futureValues != undefined && currentItemWrapper.mapAssetEntitlements.futureValues.length > 0) {
                let filterResult = currentItemWrapper.mapAssetEntitlements.futureValues.filter(ele => ele.selecteddisposition);
                if(filterResult && filterResult.length > 0) {
                    noRowSelected++;
                }
            }
        });
        if(noRowSelected == 0) {
            return noRowSelectedError;
        }
    }
    
    return null;
}
export function removeAllErrors(displayedData, exceptionOptions) {
    displayedData.forEach(currentItemWrapper => {
        if (currentItemWrapper.wrapBaseLicense != undefined && currentItemWrapper.wrapBaseLicense.length > 0 ) {
          currentItemWrapper.wrapBaseLicense = removeErrorOnItem(currentItemWrapper.wrapBaseLicense, exceptionOptions);
        }

        if (currentItemWrapper.wrapHWSupportLines != undefined && currentItemWrapper.wrapHWSupportLines.length > 0) {
          currentItemWrapper.wrapHWSupportLines = removeErrorOnItem(currentItemWrapper.wrapHWSupportLines, exceptionOptions);
        }

        if (currentItemWrapper.wrapAddOnSupportLines != undefined && currentItemWrapper.wrapAddOnSupportLines.length > 0 ) {
          currentItemWrapper.wrapAddOnSupportLines = removeErrorOnItem(currentItemWrapper.wrapAddOnSupportLines, exceptionOptions);
        }

        if (currentItemWrapper.wrapInactiveEnt != undefined && currentItemWrapper.wrapInactiveEnt.length > 0 ) {
          currentItemWrapper.wrapInactiveEnt = removeErrorOnItem(currentItemWrapper.wrapInactiveEnt, exceptionOptions);
        }

        if (currentItemWrapper.wrapUpgradeEnt != undefined && currentItemWrapper.wrapUpgradeEnt.length > 0 ) {
          currentItemWrapper.wrapUpgradeEnt = removeErrorOnItem(currentItemWrapper.wrapUpgradeEnt, exceptionOptions);
        }
        if (currentItemWrapper.mapAssetEntitlements != undefined && currentItemWrapper.rowSelected != undefined && currentItemWrapper.rowSelected) {
          currentItemWrapper.mapAssetEntitlements.futureValues = removeErrorOnItem(currentItemWrapper.mapAssetEntitlements.futureValues, exceptionOptions);
        }
    });
    return displayedData;
}
function removeErrorOnItem(currentItem, exceptionOptions) {
    currentItem.forEach(element => {
        if(element.rowSelected) {
            if(checkifNonAssetToNonAsset(element)) {
                element.errors = '';
            }
      } else {
          element.errors = '';
          if(checkifNonAssetToNonAsset(element) && checkHasMismatchExceptionSelected(exceptionOptions)) {
                element.showAdd = false;
          }
        }
    });
   return currentItem;
}
export function checkIfErrorAdded(displayedData){
    let anyerrors = false;
    
    displayedData.forEach(currentItemWrapper => {
        // Added as part of FY25SR-1207 - Start
        if (currentItemWrapper.mapAssetEntitlements != undefined && currentItemWrapper.rowSelected != undefined && currentItemWrapper.rowSelected && !anyerrors) {
            anyerrors = anyErrorsMethod(currentItemWrapper.mapAssetEntitlements.futureValues);
        }
        // Added as part of FY25SR-1207 - End


        if (currentItemWrapper.wrapBaseLicense != undefined && currentItemWrapper.wrapBaseLicense.length > 0 && !anyerrors) {
            anyerrors = anyErrorsMethod(currentItemWrapper.wrapBaseLicense);
        }

        if (currentItemWrapper.wrapHWSupportLines != undefined && currentItemWrapper.wrapHWSupportLines.length > 0 && !anyerrors) {
            anyerrors = anyErrorsMethod(currentItemWrapper.wrapHWSupportLines);
        }

        if (currentItemWrapper.wrapAddOnSupportLines != undefined && currentItemWrapper.wrapAddOnSupportLines.length > 0 && !anyerrors) {
            anyerrors = anyErrorsMethod(currentItemWrapper.wrapAddOnSupportLines);
        }

        if (currentItemWrapper.wrapInactiveEnt != undefined && currentItemWrapper.wrapInactiveEnt.length > 0 && !anyerrors) {
            anyerrors = anyErrorsMethod(currentItemWrapper.wrapInactiveEnt);
        }

        if (currentItemWrapper.wrapUpgradeEnt != undefined && currentItemWrapper.wrapUpgradeEnt.length > 0 && !anyerrors) {
            anyerrors = anyErrorsMethod(currentItemWrapper.wrapUpgradeEnt);
        }
    });

    return (anyerrors);
}
/*CPQ22-6462
function checkDataValidityForDispositionReasonOfArroyoEnt(displayedData,dispositionReasonError){
    displayedData.forEach(currentItemWrapper => {
        // Future Transaction
        // Added as part of FY25SR-1207 - Start
        if (currentItemWrapper.mapAssetEntitlements != undefined && currentItemWrapper.rowSelected != undefined && currentItemWrapper.rowSelected) {
            currentItemWrapper.mapAssetEntitlements.futureValues = checkDispositionError(currentItemWrapper.mapAssetEntitlements.futureValues,dispositionReasonError,true);
            
        }
        // Added as part of FY25SR-1207 - End

        // if(currentItemWrapper.setRowColor != undefined && currentItemWrapper.rowSelected != undefined && currentItemWrapper.selecteddisposition != undefined && currentItemWrapper.setRowColor === 'background-color: #E8E8E8;' && currentItemWrapper.rowSelected && currentItemWrapper.selecteddisposition === '') {
        //     currentItemWrapper.errors = dispositionReasonError; 
        // }

        if (currentItemWrapper.wrapBaseLicense != undefined && currentItemWrapper.wrapBaseLicense.length > 0) {
            currentItemWrapper.wrapBaseLicense = checkDispositionError(currentItemWrapper.wrapBaseLicense,dispositionReasonError,false);
        }

        if (currentItemWrapper.wrapHWSupportLines != undefined && currentItemWrapper.wrapHWSupportLines.length > 0) {
            currentItemWrapper.wrapHWSupportLines = checkDispositionError(currentItemWrapper.wrapHWSupportLines,dispositionReasonError,false);
        }

        if (currentItemWrapper.wrapAddOnSupportLines != undefined && currentItemWrapper.wrapAddOnSupportLines.length > 0) {
            currentItemWrapper.wrapAddOnSupportLines = checkDispositionError(currentItemWrapper.wrapAddOnSupportLines,dispositionReasonError,false);
        }
        
        if (currentItemWrapper.wrapUpgradeEnt != undefined && currentItemWrapper.wrapUpgradeEnt.length > 0) {
            currentItemWrapper.wrapUpgradeEnt = checkDispositionError(currentItemWrapper.wrapUpgradeEnt,dispositionReasonError,false);
        }

    });

    return displayedData;
}*/
/*CPQ22-6462
function checkDispositionError(currentItemWrapper,dispositionReasonError,isFutureTransaction){
    currentItemWrapper.forEach(currentItem => {
        // Added as part of FY25SR-1207 - Start
        if(isFutureTransaction){
            currentItem.errors = setErrorForDisposition(currentItem.setRowColor,true,currentItem.selecteddisposition,dispositionReasonError);
        } else {
            currentItem.errors = setErrorForDisposition(currentItem.setRowColor,currentItem.rowSelected,currentItem.selecteddisposition,dispositionReasonError);
        }
        // Added as part of FY25SR-1207 - End
    });
    return currentItemWrapper;
}*/
/*CPQ22-6462
function setErrorForDisposition(setRowColor,rowSelected,selecteddisposition,dispositionReasonError){
    let error = '';
    //FY25SR-1073 - Start - Added condition to check the highlighted lines should also have disposition selected
    // if((setRowColor === 'background-color: #E8E8E8;' || rowSelected) && selecteddisposition === '') {
    if(rowSelected && selecteddisposition === '') {
        error = dispositionReasonError; 
    }
    return error;
}*/

function checkDataValidityForReplacementTermDealOppsSalesOpps(displayedData,replacementTermDealOpsError,replacementTermMin12MonthsError,replacementTermSalesOpsError,quoteDetails){
    displayedData.forEach((currentItemWrapper, index) => {
        if(currentItemWrapper.customIndex != undefined){
            // Future Transaction
            // Added as part of FY25SR-1207 - Start
            if (currentItemWrapper.mapAssetEntitlements != undefined && currentItemWrapper.rowSelected != undefined && currentItemWrapper.rowSelected) {
                currentItemWrapper.mapAssetEntitlements.futureValues = checkTermValidityDealOps(currentItemWrapper.mapAssetEntitlements.futureValues,replacementTermDealOpsError,replacementTermMin12MonthsError,replacementTermSalesOpsError,quoteDetails,true);
                
            }
            // Added as part of FY25SR-1207 - End
        } else {

            //Base Product
            if(currentItemWrapper.wrapBaseLicense != undefined){
                currentItemWrapper.wrapBaseLicense = checkTermValidityDealOps(currentItemWrapper.wrapBaseLicense,replacementTermDealOpsError,replacementTermMin12MonthsError,replacementTermSalesOpsError,quoteDetails,false);
            }

            //HW Support
            if(currentItemWrapper.wrapHWSupportLines != undefined){
                currentItemWrapper.wrapHWSupportLines = checkTermValidityDealOps(currentItemWrapper.wrapHWSupportLines,replacementTermDealOpsError,replacementTermMin12MonthsError,replacementTermSalesOpsError,quoteDetails,false);
            }

            //Addons
            if(currentItemWrapper.wrapAddOnSupportLines != undefined){
                currentItemWrapper.wrapAddOnSupportLines = checkTermValidityDealOps(currentItemWrapper.wrapAddOnSupportLines,replacementTermDealOpsError,replacementTermMin12MonthsError,replacementTermSalesOpsError,quoteDetails,false);
            }
            //Inactive
            if(currentItemWrapper.wrapInactiveEnt != undefined){
                currentItemWrapper.wrapInactiveEnt = checkTermValidityDealOps(currentItemWrapper.wrapInactiveEnt,replacementTermDealOpsError,replacementTermMin12MonthsError,replacementTermSalesOpsError,quoteDetails,false);
                
            }
            //upgrade
            if(currentItemWrapper.wrapUpgradeEnt != undefined){
                currentItemWrapper.wrapUpgradeEnt = checkTermValidityDealOps(currentItemWrapper.wrapUpgradeEnt,replacementTermDealOpsError,replacementTermMin12MonthsError,replacementTermSalesOpsError,quoteDetails,false);
            }
        }
    });
    return displayedData;
}

function checkTermValidityDealOpsEachWrapper(element,replacementTermDealOpsError,replacementTermMin12MonthsError,replacementTermSalesOpsError,quoteDetails,isFutureTransaction){
     // Added as part of FY25SR-1207 - Start
    if(isFutureTransaction){
        if(element.selecteddisposition != 'Renewing' && element.skuProductId) {
            if(element.ReplacementTerm != null 
                && parseInt(element.ReplacementTerm) >= parseInt(element.RemainingTerm)
                && element.skuProductId){
            if(element.errors.includes('Deal Ops permission') || element.errors.includes('Replacement term')){
                element.errors = '';
            }
        } else if(element.ReplacementTerm != null && parseInt(element.ReplacementTerm) < parseInt(element.RemainingTerm)){
                element.errors = replacementTermDealOpsError;
        } else {
                element.errors = replacementTermMin12MonthsError;
            }
        }
    } else {
        if(element.rowSelected != undefined && element.rowSelected 
            && element.selecteddisposition != 'Renewing' && element.skuProductId){
            if(element.ReplacementTerm != null && parseInt(element.ReplacementTerm) >= parseInt(element.RemainingTerm)){
                if(element.errors.includes('Deal Ops permission') || element.errors.includes('Replacement term')){
                    element.errors = '';
                }
            } else if(element.ReplacementTerm != null && parseInt(element.ReplacementTerm) < parseInt(element.RemainingTerm)){
                    element.errors = replacementTermDealOpsError;
            } else {
                    element.errors = replacementTermMin12MonthsError;
            }
        } else {
            element.errors = '';
        }
    }
    // Added as part of FY25SR-1207 - End

    return element;
}
function checkTermValidityDealOps(currentItemWrapper,replacementTermDealOpsError,replacementTermMin12MonthsError,replacementTermSalesOpsError,quoteDetails,isFutureTransaction){
    currentItemWrapper.forEach(function (element, index){
        element = checkTermValidityDealOpsEachWrapper(element,replacementTermDealOpsError,replacementTermMin12MonthsError,replacementTermSalesOpsError,quoteDetails,isFutureTransaction);
    });

    return currentItemWrapper;
}

function checkTermValidity(currentItemWrapper,replacementTermMin12MonthsError,isFutureTransaction){
    currentItemWrapper.forEach(function (element, index){
        element = checkTermValidityEachWrapper(element,replacementTermMin12MonthsError,isFutureTransaction);
    });

    return currentItemWrapper;
}

function checkTermValidityEachWrapper(element,replacementTermMin12MonthsError,isFutureTransaction){
    // Added as part of FY25SR-1207 - Start
    if(isFutureTransaction){
        if(element.selecteddisposition != 'Renewing' && element.skuProductId){
            if(parseInt(element.ReplacementTerm) >= parseInt(element.RemainingTerm)){
                element.errors = '';
            } else {
                element.errors = replacementTermMin12MonthsError;
            }
        }
    } else {
        if(element.rowSelected != undefined && element.rowSelected 
            && element.selecteddisposition != 'Renewing' && element.skuProductId){
            if(parseInt(element.ReplacementTerm) >= parseInt(element.RemainingTerm)){
                element.errors = '';
            } else {
                element.errors = replacementTermMin12MonthsError;
            }
        }    
    }
    // Added as part of FY25SR-1207 - End
    
    return element;
}


function checkDataValidityForReplacementTerm(displayedModified,replacementTermMin12MonthsError){
    displayedModified.forEach((currentItemWrapper, index) => {
        if (currentItemWrapper.customIndex != undefined) {
            // Future Transaction
            // Added as part of FY25SR-1207 - Start
            if (currentItemWrapper.mapAssetEntitlements != undefined && currentItemWrapper.rowSelected != undefined && currentItemWrapper.rowSelected) {
                currentItemWrapper.mapAssetEntitlements.futureValues = checkTermValidity(currentItemWrapper.mapAssetEntitlements.futureValues,replacementTermMin12MonthsError,true);
                
            }
            // Added as part of FY25SR-1207 - End
        } else {
            //Base Product
            if(currentItemWrapper.wrapBaseLicense != undefined){
                currentItemWrapper.wrapBaseLicense = checkTermValidity(currentItemWrapper.wrapBaseLicense,replacementTermMin12MonthsError,false);
            }

            //HW Support
            if(currentItemWrapper.wrapHWSupportLines != undefined){
                currentItemWrapper.wrapHWSupportLines = checkTermValidity(currentItemWrapper.wrapHWSupportLines,replacementTermMin12MonthsError,false);
            }

            //Addons
            if(currentItemWrapper.wrapAddOnSupportLines != undefined){
                currentItemWrapper.wrapAddOnSupportLines = checkTermValidity(currentItemWrapper.wrapAddOnSupportLines,replacementTermMin12MonthsError,false);
            }

            //Inactive
            if(currentItemWrapper.wrapInactiveEnt != undefined){
                currentItemWrapper.wrapInactiveEnt = checkTermValidity(currentItemWrapper.wrapInactiveEnt,replacementTermMin12MonthsError,false);
            }

            //upgrade
            if(currentItemWrapper.wrapUpgradeEnt != undefined){
                currentItemWrapper.wrapUpgradeEnt = checkTermValidity(currentItemWrapper.wrapUpgradeEnt,replacementTermMin12MonthsError,false);
            }
        } 
    });

    return displayedModified;
}

function checkAssetsValidity(currentItemWrapper,mapEntitlementIdToSelectedAssets,mapEntitlementIdToAllAssets,allAssetsQuantityToBeSelectedError,
    isFutureTransaction,customIndex, mapEntvsError, mismatchQuantityError, misMatchExcep){
    currentItemWrapper.forEach(function (element, index){
        
        if (element.assetsAvailable.length >= 0 && (element.rowSelected || isFutureTransaction)) {
            element = checkAssetsValidityEachWrapper(element,mapEntitlementIdToSelectedAssets,mapEntitlementIdToAllAssets,allAssetsQuantityToBeSelectedError,isFutureTransaction,customIndex, misMatchExcep);
        }
    });
    currentItemWrapper = addErroronAssetMismatch(currentItemWrapper, mapEntvsError, mismatchQuantityError, misMatchExcep);
    return currentItemWrapper;
}

function checkAssetsValidityEachWrapper(currentItemWrapper,mapEntitlementIdToSelectedAssets,mapEntitlementIdToAllAssets,allAssetsQuantityToBeSelectedError,isFutureTransaction,customIndex, misMatchExcep){
     // Added as part of FY25SR-1207 - Start
    let searchStringInMap = isFutureTransaction ? customIndex : currentItemWrapper.entitlementId;
     // Added as part of FY25SR-1207 - End

    if(misMatchExcep != undefined && misMatchExcep == true){
        if ( 
        mapEntitlementIdToSelectedAssets.has(searchStringInMap) &&
        mapEntitlementIdToAllAssets.has(searchStringInMap) &&
        (mapEntitlementIdToAllAssets.get(searchStringInMap) != mapEntitlementIdToSelectedAssets.get(searchStringInMap) || (currentItemWrapper.selectedquantity == null || currentItemWrapper.selectedquantity == undefined ||currentItemWrapper.selectedquantity < 1))
        && currentItemWrapper.assetsAvailable != undefined && currentItemWrapper.assetsAvailable.length > 0 && 
        currentItemWrapper.selecteddisposition != 'Renew Later' && currentItemWrapper.selecteddisposition != 'At Risk'
        ) {
                currentItemWrapper.errors = allAssetsQuantityToBeSelectedError;
        } else {
                currentItemWrapper.errors = '';
        }
    }else{
        if ( // Added as part of FY25SR-1207 - Start
        mapEntitlementIdToSelectedAssets.has(searchStringInMap) &&
        mapEntitlementIdToAllAssets.has(searchStringInMap) &&
        (mapEntitlementIdToAllAssets.get(searchStringInMap) != mapEntitlementIdToSelectedAssets.get(searchStringInMap) || (currentItemWrapper.selectedquantity == null || currentItemWrapper.selectedquantity == undefined ||currentItemWrapper.selectedquantity < 1))
        ) {//Ankita  // Added as part of FY25SR-1207 - end
                currentItemWrapper.errors = allAssetsQuantityToBeSelectedError;
        } else {
                currentItemWrapper.errors = '';
        }
    }
    return currentItemWrapper;
}

function addErroronAssetMismatch(currentItemWrapper, mapEntvsError, mismatchQuantityError, misMatchExcep){
    currentItemWrapper.forEach(function (element, index){
        if (element.assetsAvailable.length >= 0 && element.rowSelected){
            if(misMatchExcep == true){
                if(element.selecteddisposition != 'Renew Later' && element.selecteddisposition != 'At Risk'){
                    if(mapEntvsError.has(element.entitlementId)) {
                        element.errors = mismatchQuantityError;
                    } else {
                        element.errors = '';
                    }
                }
            }else{
                if(mapEntvsError.has(element.entitlementId)) {
                    element.errors = mismatchQuantityError;
                } else {
                    element.errors = '';
                }
            }
        } 
    });
    return currentItemWrapper;
}

function checkDataValidityAllTheAssetsBeingSelected(displayedModified,allAssetsQuantityToBeSelectedError, mismatchQuantityError, misMatchExcep){
    let mapEntitlementIdToListEntitlement = new Map();
    let mapEntitlementIdToSelectedAssets = new Map();
    let mapEntitlementIdToAllAssets = new Map();

    mapEntitlementIdToListEntitlement = createMapEntitlementIdToListEntitlement(displayedModified);
    let mapEntvsError = checkAssetQtyVsEntQty(mapEntitlementIdToListEntitlement);

    mapEntitlementIdToListEntitlement.forEach((val, entId) => {
        let listEnt = mapEntitlementIdToListEntitlement.get(entId);
        let assetsSelected = 0;
        listEnt.forEach((currentItem) => {
            if (currentItem.assetsAvailable.length > 0) {
        
                let hasFull = false;
                let hasOnlyOneAssetandNotFull = false;
                if (currentItem.assetsAvailable.length == 1) {
                    hasOnlyOneAssetandNotFull = true;
                } else {
                    currentItem.assetsAvailable.forEach((asset) => {
                    if (!asset.selected && asset.value === 'Full') {
                        hasFull = true;
                    }
                    });
                }

                let no = 0;
                currentItem.assetsAvailable.forEach((asset) => {
                    if (asset.selected && asset.value === 'Full') {
                    assetsSelected = parseInt(currentItem.assetsAvailable.length) - 1;
                    if (!mapEntitlementIdToAllAssets.has(entId)) {
                        no = parseInt(currentItem.assetsAvailable.length) - 1;
                    }
                    } else {
                        if (asset.selected && asset.value != 'Full') {
                            assetsSelected = parseInt(assetsSelected) + 1;
                            if (mapEntitlementIdToAllAssets.has(entId)) {
                                no = parseInt(mapEntitlementIdToAllAssets.get(entId)) + parseInt(currentItem.assetsAvailable.length);
                            } else {
                                if (hasFull) {
                                    no = parseInt(currentItem.assetsAvailable.length) - 1;
                                } else {
                                    no = parseInt(currentItem.assetsAvailable.length);
                                }
                            }
                        } else {
                            if (hasOnlyOneAssetandNotFull) {
                                no = parseInt(currentItem.assetsAvailable.length);
                            } else {
                                no = parseInt(currentItem.assetsAvailable.length) - 1;
                            }
                        }
                    }
                });
                mapEntitlementIdToAllAssets.set(entId, no);
            }
        });
        mapEntitlementIdToSelectedAssets.set(entId, assetsSelected);
    });


    displayedModified.forEach((currentItemWrapper) => {
        if(currentItemWrapper.customIndex != undefined){
            //Removed commented code
        } else {
            //Base Product
            if(currentItemWrapper.wrapBaseLicense != undefined){
                currentItemWrapper.wrapBaseLicense = checkAssetsValidity(currentItemWrapper.wrapBaseLicense,mapEntitlementIdToSelectedAssets,mapEntitlementIdToAllAssets,allAssetsQuantityToBeSelectedError,false, null, mapEntvsError, mismatchQuantityError, misMatchExcep);
            }

            //HW Support
            if(currentItemWrapper.wrapHWSupportLines != undefined){
                currentItemWrapper.wrapHWSupportLines = checkAssetsValidity(currentItemWrapper.wrapHWSupportLines,mapEntitlementIdToSelectedAssets,mapEntitlementIdToAllAssets,allAssetsQuantityToBeSelectedError,false, null, mapEntvsError, mismatchQuantityError, misMatchExcep);
            }

            //Addons
            if(currentItemWrapper.wrapAddOnSupportLines != undefined){
                currentItemWrapper.wrapAddOnSupportLines = checkAssetsValidity(currentItemWrapper.wrapAddOnSupportLines,mapEntitlementIdToSelectedAssets,mapEntitlementIdToAllAssets,allAssetsQuantityToBeSelectedError,false, null, mapEntvsError, mismatchQuantityError, misMatchExcep);
            }

            //Inactive
            if(currentItemWrapper.wrapInactiveEnt != undefined){
                currentItemWrapper.wrapInactiveEnt = checkAssetsValidity(currentItemWrapper.wrapInactiveEnt,mapEntitlementIdToSelectedAssets,mapEntitlementIdToAllAssets,allAssetsQuantityToBeSelectedError,false, null, mapEntvsError, mismatchQuantityError, misMatchExcep);
            }

            //upgrade
            if(currentItemWrapper.wrapUpgradeEnt != undefined){
                currentItemWrapper.wrapUpgradeEnt = checkAssetsValidity(currentItemWrapper.wrapUpgradeEnt,mapEntitlementIdToSelectedAssets,mapEntitlementIdToAllAssets,allAssetsQuantityToBeSelectedError,false, null, mapEntvsError, mismatchQuantityError,misMatchExcep);
            }

        }
    });

    return displayedModified;
}

function createMapEntitlementIdToListEntitlement(displayedModified){
    let mapEntitlementIdToListEntitlement = new Map();

    displayedModified.forEach((currentItemWrapper) => {
        if(currentItemWrapper.customIndex != undefined){
            // Future Transaction
            // Added as part of FY25SR-1207 - Start
            // if (currentItemWrapper.mapAssetEntitlements != undefined && currentItemWrapper.rowSelected != undefined && currentItemWrapper.rowSelected) {
            //     currentItemWrapper.mapAssetEntitlements.futureValues.forEach(function (element, index){
            //         console.log('currentItemWrapper.rowSelected ::' , currentItemWrapper.rowSelected);
            //         console.log('currentItemWrapper.rowSelected mapEntitlementIdToListEntitlement::' , mapEntitlementIdToListEntitlement);
            //         if (mapEntitlementIdToListEntitlement.has(currentItemWrapper.customIndex)) {
            //             let listEnt = mapEntitlementIdToListEntitlement.get(currentItemWrapper.customIndex);
            //             listEnt.push(element);
            //             mapEntitlementIdToListEntitlement.set(currentItemWrapper.customIndex, listEnt);
            //         } else {
            //             let listEnt = [];
            //             listEnt.push(element);
            //             mapEntitlementIdToListEntitlement.set(currentItemWrapper.customIndex, listEnt);
            //         }
            //     });
            // }
            // Added as part of FY25SR-1207 - End

        } else {
            //Base Product
            if(currentItemWrapper.wrapBaseLicense != undefined){
                currentItemWrapper.wrapBaseLicense.forEach(function (element, index){
                    if (mapEntitlementIdToListEntitlement.has(element.entitlementId)) {
                        let listEnt = mapEntitlementIdToListEntitlement.get(element.entitlementId);
                        listEnt.push(element);
                        mapEntitlementIdToListEntitlement.set(element.entitlementId, listEnt);
                    } else {
                        let listEnt = [];
                        listEnt.push(element);
                        mapEntitlementIdToListEntitlement.set(element.entitlementId, listEnt);
                    }
                });
            }

            //HW Support
            if(currentItemWrapper.wrapHWSupportLines != undefined){
                currentItemWrapper.wrapHWSupportLines.forEach(function (element, index){
                if (mapEntitlementIdToListEntitlement.has(element.entitlementId)) {
                    let listEnt = mapEntitlementIdToListEntitlement.get(element.entitlementId);
                    listEnt.push(element);
                    mapEntitlementIdToListEntitlement.set(element.entitlementId, listEnt);
                } else {
                    let listEnt = [];
                    listEnt.push(element);
                    mapEntitlementIdToListEntitlement.set(element.entitlementId, listEnt);
                }
                });
            }

            //Addons
            if(currentItemWrapper.wrapAddOnSupportLines != undefined){
                currentItemWrapper.wrapAddOnSupportLines.forEach(function (element, index){
                if (mapEntitlementIdToListEntitlement.has(element.entitlementId)) {
                    let listEnt = mapEntitlementIdToListEntitlement.get(element.entitlementId);
                    listEnt.push(element);
                    mapEntitlementIdToListEntitlement.set(element.entitlementId, listEnt);
                } else {
                    let listEnt = [];
                    listEnt.push(element);
                    mapEntitlementIdToListEntitlement.set(element.entitlementId, listEnt);
                }
                });
            }
            //Inactive
            if(currentItemWrapper.wrapInactiveEnt != undefined){
                currentItemWrapper.wrapInactiveEnt.forEach(function (element, index){
                if (mapEntitlementIdToListEntitlement.has(element.entitlementId)) {
                    let listEnt = mapEntitlementIdToListEntitlement.get(element.entitlementId);
                    listEnt.push(element);
                    mapEntitlementIdToListEntitlement.set(element.entitlementId, listEnt);
                } else {
                    let listEnt = [];
                    listEnt.push(element);
                    mapEntitlementIdToListEntitlement.set(element.entitlementId, listEnt);
                }
                });
                
            }
            //upgrade
            if(currentItemWrapper.wrapUpgradeEnt != undefined){
                currentItemWrapper.wrapUpgradeEnt.forEach(function (element, index){
                if (mapEntitlementIdToListEntitlement.has(element.entitlementId)) {
                    let listEnt = mapEntitlementIdToListEntitlement.get(element.entitlementId);
                    listEnt.push(element);
                    mapEntitlementIdToListEntitlement.set(element.entitlementId, listEnt);
                } else {
                    let listEnt = [];
                    listEnt.push(element);
                    mapEntitlementIdToListEntitlement.set(element.entitlementId, listEnt);
                }
                });
            }
        }
    });

    return mapEntitlementIdToListEntitlement;
}

function checkNonAssetsValidity(currentItemWrapper,mapEntitlementIdToConsumedQuantity,allAssetsQuantityToBeSelectedError,isFuturetransaction,customIndex,exceptionOptions, nonAssetToNonAssetErrors, misMatchExcep){
    currentItemWrapper = checkNonAssetPartialItem(currentItemWrapper, exceptionOptions, nonAssetToNonAssetErrors);
    currentItemWrapper.forEach(function (element, index){
        let filterResult = currentItemWrapper.filter(ele=>ele.entitlementId === element.entitlementId);
        let hasMismatchQTYNonAssetError = false;
        if(filterResult) {
            
            for(let i=0; i<filterResult.length ; i++) {
                if(checkifNonAssetToNonAsset(filterResult[i]) && checkHasMismatchExceptionSelected(exceptionOptions)) {
                    hasMismatchQTYNonAssetError = true;
                }
            }
        }
        element = checkNonAssetsValidityEachWrapper(element,mapEntitlementIdToConsumedQuantity,allAssetsQuantityToBeSelectedError,isFuturetransaction,customIndex,exceptionOptions, hasMismatchQTYNonAssetError, misMatchExcep);
    });

    return currentItemWrapper;
}


function checkNonAssetsValidityEachWrapper(currentItemWrapper,mapEntitlementIdToConsumedQuantity,allAssetsQuantityToBeSelectedError,isFutureTransaction,customIndex,exceptionOptions, hasMismatchQTYNonAssetError, misMatchExcep){
    // Added as part of FY25SR-1207 - Start
    let searchStringInMap = isFutureTransaction ? customIndex : currentItemWrapper.entitlementId;
     // Added as part of FY25SR-1207 - End
    // if (currentItemWrapper.quantityAssetType  && currentItemWrapper.rowSelected) {
    if (currentItemWrapper.rowSelected && !hasMismatchQTYNonAssetError && currentItemWrapper.quantityAssetType == true 
                && (currentItemWrapper.error == undefined || currentItemWrapper.error === '' || currentItemWrapper.error == null)) {
                if (// Added as part of FY25SR-1207 - Start
                    mapEntitlementIdToConsumedQuantity.has(searchStringInMap) &&
                    ( currentItemWrapper.selectedMaxquantity < mapEntitlementIdToConsumedQuantity.get(searchStringInMap) || currentItemWrapper.selectedMaxquantity != mapEntitlementIdToConsumedQuantity.get(searchStringInMap) || currentItemWrapper.selectedMaxquantity > mapEntitlementIdToConsumedQuantity.get(searchStringInMap) ||
                    (currentItemWrapper.selectedquantity == null || currentItemWrapper.selectedquantity == undefined || currentItemWrapper.selectedquantity < 1)
                    )
                    ) {//Ankita // Added as part of FY25SR-1207 - End
                        currentItemWrapper.errors = allAssetsQuantityToBeSelectedError;
                    } else if (currentItemWrapper.errors === '') {
                        currentItemWrapper.errors = '';
                }
            
    }
    return currentItemWrapper;
}
function checkNonAssetPartialItem(currentItemWrapper, exceptionOptions, nonAssetToNonAssetErrors) {
    currentItemWrapper.forEach(function (element, index){
        if(element.rowSelected == true && checkifNonAssetToNonAsset(element)) {
            let exception = exceptionOptions.find(ele => ele.value === 'Mismatch Quantity');
            let filterResult = currentItemWrapper.filter(ele=>ele.entitlementId === element.entitlementId);
          
            if(filterResult && filterResult.length > 1 ) {
          	if(checkHasMismatchExceptionSelected(exceptionOptions)) {
                    element.errors = nonAssetToNonAssetErrors.get('Partial Replacement Non Asset');
                    // 'Please remove partial replacement.';
          	}
            } else {
               element.errors = ''; 
                if(exception && !exception.selected && element.skuProductId 
                    && (element.selectedquantity != undefined
                        && element.selectedquantity != null 
                        && element.selectedquantity != element.quantity )
                    && filterResult.length == 1
                ) {
                    element.errors = nonAssetToNonAssetErrors.get('Mismatch Quantity Exception'); //Please select Mismatch Quantity exception detail for non asset selection';
                } else if(!exception && element.skuProductId 
                        && (element.selectedquantity != undefined
                        && element.selectedquantity != null 
                        && element.selectedquantity != element.quantity )
                ) {
                    element.errors = nonAssetToNonAssetErrors.get('No Mismatch Exception found');//No Mismatch Quantity exception found, contact deal ops team.';
                } else {
                    element.errors = '';
                }
            }
        }
    });
    return currentItemWrapper;
}
function checkDataValidityFullQuantityForNonAssetsBeingSelected(displayedModified,allAssetsQuantityToBeSelectedError,exceptionOptions,nonAssetToNonAssetErrors, misMatchExcep){
    let mapEntitlementIdToListEntitlement = new Map();
    let mapEntitlementIdToConsumedQuantity = new Map();

    mapEntitlementIdToListEntitlement = createMapEntitlementIdToListEntitlement(displayedModified);

    mapEntitlementIdToListEntitlement.forEach((val, entId) => {
        let listEnt = mapEntitlementIdToListEntitlement.get(entId);
        let maxQuantityConsumed = 0;
        listEnt.forEach((currentItem) => {
            // if (currentItem.quantityAssetType) {
                maxQuantityConsumed = parseInt(maxQuantityConsumed) + parseInt(currentItem.selectedquantity);
            // } 
        });
        mapEntitlementIdToConsumedQuantity.set(entId, maxQuantityConsumed);
    });


    displayedModified.forEach((currentItemWrapper) => {
        if(currentItemWrapper.customIndex != undefined){
            // Future Transaction
            // Added as part of FY25SR-1207 - Start
            // if (currentItemWrapper.mapAssetEntitlements != undefined && currentItemWrapper.rowSelected != undefined && currentItemWrapper.rowSelected) {
            //     currentItemWrapper.mapAssetEntitlements.futureValues = checkNonAssetsValidity(currentItemWrapper.mapAssetEntitlements.futureValues,mapEntitlementIdToConsumedQuantity,allAssetsQuantityToBeSelectedError,true,currentItemWrapper.customIndex);
            // }
            // Added as part of FY25SR-1207 - End;
        } else {
            //Base Product
            if(currentItemWrapper.wrapBaseLicense != undefined){
                currentItemWrapper.wrapBaseLicense = checkNonAssetsValidity(currentItemWrapper.wrapBaseLicense,mapEntitlementIdToConsumedQuantity,allAssetsQuantityToBeSelectedError,false,null,exceptionOptions,nonAssetToNonAssetErrors, misMatchExcep);
            }

            //HW Support
            if(currentItemWrapper.wrapHWSupportLines != undefined){
                currentItemWrapper.wrapHWSupportLines = checkNonAssetsValidity(currentItemWrapper.wrapHWSupportLines,mapEntitlementIdToConsumedQuantity,allAssetsQuantityToBeSelectedError,false,null,exceptionOptions,nonAssetToNonAssetErrors, misMatchExcep);
            }

            //Addons
            if(currentItemWrapper.wrapAddOnSupportLines != undefined){
                currentItemWrapper.wrapAddOnSupportLines = checkNonAssetsValidity(currentItemWrapper.wrapAddOnSupportLines,mapEntitlementIdToConsumedQuantity,allAssetsQuantityToBeSelectedError,false,null,exceptionOptions,nonAssetToNonAssetErrors, misMatchExcep);
            }
            //Inactive
            if(currentItemWrapper.wrapInactiveEnt != undefined){
                currentItemWrapper.wrapInactiveEnt = checkNonAssetsValidity(currentItemWrapper.wrapInactiveEnt,mapEntitlementIdToConsumedQuantity,allAssetsQuantityToBeSelectedError,false,null,exceptionOptions,nonAssetToNonAssetErrors, misMatchExcep);
                
            }
            //upgrade
            if(currentItemWrapper.wrapUpgradeEnt != undefined){
                currentItemWrapper.wrapUpgradeEnt = checkNonAssetsValidity(currentItemWrapper.wrapUpgradeEnt,mapEntitlementIdToConsumedQuantity,allAssetsQuantityToBeSelectedError,false,null,exceptionOptions,nonAssetToNonAssetErrors, misMatchExcep);
            }
        }
    });

    return displayedModified;
}

// Added as part of FY25SR-1207 - Start
function checkDataValidityFutureR6R7(displayedModified,futureTransactionError){
    //Scenario 1 - selected quantity == assets quantity ka total
    // 
    // displayedModified.forEach((currentItemWrapper) => {
    //     if(currentItemWrapper.customIndex != undefined){
    //         if (currentItemWrapper.mapAssetEntitlements != undefined && currentItemWrapper.rowSelected != undefined && currentItemWrapper.rowSelected) {
    //             currentItemWrapper.mapAssetEntitlements.futureValues.forEach(currentItem => {
    //                 let baseRowId = fetchRowId(currentItem.customIndex , currentItem.customIndex.split('.').length);
    //                 if(currentItem.assetsAvailable != undefined && currentItem.assetsAvailable.length > 0){
    //                     let assetsSelectedTotalQuantity = 0;
    //                     currentItem.assetsAvailable.forEach(element => {
    //                         assetsSelectedTotalQuantity = parseInt(assetsSelectedTotalQuantity) + parseInt(element.quantity);
    //                     });
    //                     console.log('baseRowId ::' , baseRowId);
    //                     console.log('assetsSelectedTotalQuantity ::' , assetsSelectedTotalQuantity);
    //                     console.log('mapRowIdToTotalGroupSelected.get(baseRowId) ::' , mapRowIdToTotalGroupSelected.get(baseRowId));
    //                     if(assetsSelectedTotalQuantity != mapRowIdToTotalGroupSelected.get(baseRowId)){
    //                         currentItem.errors = 'Please Add Quantity equal to the total selected assets Quanitity 1';
    //                     }
    //                 }
    //             });
    //         }
    //     }
    // });

    //Scenarios 2 - 1 asste - 1 ent (min quantity(asset quanity) > than selectedQuantity 
    let mapOfAssetIdToEntListAssociated = createMapAssetIdToEntList(displayedModified);
    if(!checkIfErrorAdded(displayedModified)){
        displayedModified.forEach((currentItemWrapper) => {
            if(currentItemWrapper.customIndex != undefined){
                if (currentItemWrapper.mapAssetEntitlements != undefined && currentItemWrapper.rowSelected != undefined && currentItemWrapper.rowSelected) {
                    currentItemWrapper.mapAssetEntitlements.futureValues.forEach(currentItem => {
                        if(currentItem.assetsAvailable != undefined && currentItem.assetsAvailable.length > 0){
                            currentItem.assetsAvailable.forEach(element => {
                                if(mapOfAssetIdToEntListAssociated.has(element.value) && mapOfAssetIdToEntListAssociated.get(element.value).length === 1){
                                    if(element.quantity > currentItem.selectedquantity){
                                        currentItem.errors = futureTransactionError;
                                    }
                                }
                            });
                        }
                    });
                }
            }
        });
    }

    //Scenarios 2 - split scenario
    if(!checkIfErrorAdded(displayedModified)){
        // let mapOfEntIdToCorrespondingEntList = createMapEntIdToCorrespondingEntList(displayedModified);
        let mapOfEntIdToTotalSelectedQuantity = createMapEntIdToTotalSelectedQuantity(displayedModified);
        let mapRowIdToTotalGroupSelected = createMapRowIdToCorrespondingTotalQuantitySelected(displayedModified);
        displayedModified.forEach((currentItemWrapper) => {
            if(currentItemWrapper.customIndex != undefined){
                if (currentItemWrapper.mapAssetEntitlements != undefined && currentItemWrapper.rowSelected != undefined && currentItemWrapper.rowSelected) {
                    currentItemWrapper.mapAssetEntitlements.futureValues.forEach(currentItem => {
                        let baseRowId = fetchRowId(currentItem.customIndex , currentItem.customIndex.split('.').length);
                        if(mapOfEntIdToTotalSelectedQuantity.has(currentItem.entitlementId) && mapOfEntIdToTotalSelectedQuantity.get(currentItem.entitlementId) != currentItem.selectedMaxquantity){
                                currentItem.errors = futureTransactionError;
                        }
                    });
                }
            }
        });
    }
    return displayedModified;
}
// Added as part of FY25SR-1207 - End;

// Added as part of FY25SR-1207 - Start
function checkDataValidityFuturePartialChurn(displayedModified,futureTransactionPartialChurnError){
    displayedModified.forEach((currentItemWrapper) => {
        if(currentItemWrapper.customIndex != undefined){
            if (currentItemWrapper.mapAssetEntitlements != undefined && currentItemWrapper.rowSelected != undefined && currentItemWrapper.rowSelected) {
                let isChurnSelected = false; 
                currentItemWrapper.mapAssetEntitlements.futureValues.forEach(currentItem => {
                    if(currentItem.selecteddisposition === 'Churn'){
                        isChurnSelected = true;
                    }

                    if(isChurnSelected){
                        currentItem.errors = futureTransactionPartialChurnError;
                    }
                });
            }
        }
    });
    return displayedModified;
}
// Added as part of FY25SR-1207 - End;

// Added as part of FY25SR-1207 - Start
function createMapEntIdToTotalSelectedQuantity(displayedModified){
    let mapOfEntIdToTotalSelectedQuantity = new Map();

    displayedModified.forEach((currentItemWrapper) => {
        if(currentItemWrapper.customIndex != undefined){
            // Future Transaction
            // Added as part of FY25SR-1207 - Start
            if (currentItemWrapper.mapAssetEntitlements != undefined && currentItemWrapper.rowSelected != undefined && currentItemWrapper.rowSelected) {
                currentItemWrapper.mapAssetEntitlements.futureValues.forEach(currentItem => {
                        if (mapOfEntIdToTotalSelectedQuantity.has(currentItem.entitlementId)) {
                            let totalQaun = mapOfEntIdToTotalSelectedQuantity.get(currentItem.entitlementId);
                            totalQaun = parseInt(totalQaun) + parseInt(currentItem.selectedquantity);
                            mapOfEntIdToTotalSelectedQuantity.set(currentItem.entitlementId, totalQaun);
                        } else {
                            mapOfEntIdToTotalSelectedQuantity.set(currentItem.entitlementId, currentItem.selectedquantity);
                        }
                });
            }
            // Added as part of FY25SR-1207 - End;
        }
    });
    return mapOfEntIdToTotalSelectedQuantity;
}
// Added as part of FY25SR-1207 - End;

// Added as part of FY25SR-1207 - Start
function fetchRowId(customIndex, lastIndex) {
  let mainIndex = '';
  for(var i=0 ; i<lastIndex-1 ; i++) {
    mainIndex = mainIndex === '' 
      ? mainIndex + customIndex.split('.')[i] 
      : mainIndex + '.' + customIndex.split('.')[i];
  }
  return mainIndex;
}

// Added as part of FY25SR-1207 - Start
function createMapRowIdToCorrespondingTotalQuantitySelected(displayedModified){
    let mapRowIdToTotalGroupSelected = new Map();

    displayedModified.forEach((currentItemWrapper) => {
        if(currentItemWrapper.customIndex != undefined){
            // Future Transaction
            // Added as part of FY25SR-1207 - Start
            if (currentItemWrapper.mapAssetEntitlements != undefined && currentItemWrapper.rowSelected != undefined && currentItemWrapper.rowSelected) {
                currentItemWrapper.mapAssetEntitlements.futureValues.forEach(currentItem => {
                    let baseRowId = fetchRowId(currentItem.customIndex , currentItem.customIndex.split('.').length);
                            if (mapRowIdToTotalGroupSelected.has(baseRowId)) {
                                let totQuan = mapRowIdToTotalGroupSelected.get(baseRowId);
                                totQuan = parseInt(totQuan) + parseInt(currentItem.selectedquantity);
                                mapRowIdToTotalGroupSelected.set(baseRowId, totQuan);
                            } else {
                                mapRowIdToTotalGroupSelected.set(baseRowId, currentItem.selectedquantity);
                            }
                });
            }
            // Added as part of FY25SR-1207 - End;
        }
    });
    return mapRowIdToTotalGroupSelected;
}
// Added as part of FY25SR-1207 - End;



// Added as part of FY25SR-1207 - Start
function createMapAssetIdToEntList(displayedModified){
    let mapOfAssetIdToEntListAssociated = new Map();

    displayedModified.forEach((currentItemWrapper) => {
        if(currentItemWrapper.customIndex != undefined){
            // Future Transaction
            // Added as part of FY25SR-1207 - Start
            if (currentItemWrapper.mapAssetEntitlements != undefined && currentItemWrapper.rowSelected != undefined && currentItemWrapper.rowSelected) {
                currentItemWrapper.mapAssetEntitlements.futureValues.forEach(currentItem => {
                    if( currentItem.assetsAvailable != undefined &&  currentItem.assetsAvailable.length > 0){
                        currentItem.assetsAvailable.forEach(asset => {
                            if (mapOfAssetIdToEntListAssociated.has(asset.value)) {
                                let listEnt = mapOfAssetIdToEntListAssociated.get(asset.value);
                                listEnt.push(currentItem.entitlementId);
                                mapOfAssetIdToEntListAssociated.set(asset.value, listEnt);
                            } else {
                                let listEnt = [];
                                listEnt.push(currentItem.entitlementId);
                                mapOfAssetIdToEntListAssociated.set(asset.value, listEnt);
                            }
                        });
                    }
                });
            }
            // Added as part of FY25SR-1207 - End;
        }
    });
    return mapOfAssetIdToEntListAssociated;
}
// Added as part of FY25SR-1207 - End;

// Added as part of FY25SR-1207 - Start
function createMapAssetIdToConsumedQuantityOnAllEnt(displayedModified){
    let mapOfAssetIdToConsumedQuantityOnAllEnt = new Map();

    displayedModified.forEach((currentItemWrapper) => {
        if(currentItemWrapper.customIndex != undefined){
            // Future Transaction
            // Added as part of FY25SR-1207 - Start
            if (currentItemWrapper.mapAssetEntitlements != undefined && currentItemWrapper.rowSelected != undefined && currentItemWrapper.rowSelected) {
                currentItemWrapper.mapAssetEntitlements.futureValues.forEach(currentItem => {
                    if( currentItem.assetsAvailable != undefined &&  currentItem.assetsAvailable.length > 0){
                        currentItem.assetsAvailable.forEach(asset => {
                            if(asset.selected == true){
                                if (mapOfAssetIdToConsumedQuantityOnAllEnt.has(asset.value)) {
                                    let selectedQaunt = mapOfAssetIdToConsumedQuantityOnAllEnt.get(asset.value);
                                    selectedQaunt = selectedQaunt + parseInt(currentItem.selectedquantity) ;
                                    mapOfAssetIdToConsumedQuantityOnAllEnt.set(asset.value, selectedQaunt);
                                } else {
                                    mapOfAssetIdToConsumedQuantityOnAllEnt.set(asset.value, currentItem.selectedquantity);
                                }
                            }
                        });
                    }
                });
            }
            // Added as part of FY25SR-1207 - End;
        }
    });
    return mapOfAssetIdToConsumedQuantityOnAllEnt;
}
// Added as part of FY25SR-1207 - End;
function checkAssetQtyVsEntQty(mapEntitlementIdToListEntitlement) {
    let mapEntvsError = new Map();
    mapEntitlementIdToListEntitlement.forEach(function (value, entId) {
        let listEnt = mapEntitlementIdToListEntitlement.get(entId);
        let maxQuantityConsumed = 0;
        let hasAsset = false;
        listEnt.forEach((currentItem) => {
            if(currentItem.assetsAvailable !== null && currentItem.assetsAvailable.length > 0) {
                hasAsset = true;
                maxQuantityConsumed = parseInt(maxQuantityConsumed) + parseInt(currentItem.selectedquantity);
            } 
        });
        if(hasAsset && listEnt[0].selectedMaxquantity!= null && maxQuantityConsumed != listEnt[0].selectedMaxquantity) {
            mapEntvsError.set(entId, true);
        }
    });
   return mapEntvsError;
}
function checkifNonAssetToNonAsset(currentItemWrapper) {
    if(currentItemWrapper.quantityAssetType && 
        currentItemWrapper.targetProductType != null && 
        currentItemWrapper.targetProductType != undefined && 
        currentItemWrapper.targetProductType === 'Non-Hardware' &&
        currentItemWrapper.skuProductId != null && 
        currentItemWrapper.skuProductId != undefined && 
      currentItemWrapper.skuProductId != '') {
        return true;
    } 
    return false;
}

function checkHasMismatchExceptionSelected(exceptionOptions) {
  let mismatchExceptionMessage = 'Mismatch Quantity';
  let isMismatchSelected = exceptionOptions.find(ele => ele.selected && isEqualStrings(ele.value, mismatchExceptionMessage));
  if(isMismatchSelected != null && isMismatchSelected != undefined){
      return true;
  }
  return false;
}

// FY25SR-2024 
function isEqualStrings(itemValue, tocompare) {
  return itemValue.trim().toLowerCase() === tocompare.trim().toLowerCase();
}

export function updateMismatchQuantityFlag(displayedData, isMismatchQTY) {
  if(isMismatchQTY) {
      displayedData.forEach(function (currentItemWrapper, index) {
          if (currentItemWrapper.customIndex != undefined && customIndex === currentItemWrapper.customIndex) {
            currentItemWrapper = updateMisMatchQTYFlag(currentItemWrapper);
          } else {
              //Base Product
              if(currentItemWrapper.wrapBaseLicense != undefined){
                  currentItemWrapper.wrapBaseLicense = updateMisMatchQTYFlag(currentItemWrapper.wrapBaseLicense);
              }

              //HW Support
              if(currentItemWrapper.wrapHWSupportLines != undefined){
                  currentItemWrapper.wrapHWSupportLines = updateMisMatchQTYFlag(currentItemWrapper.wrapHWSupportLines);
              }

              //Addons
              if(currentItemWrapper.wrapAddOnSupportLines != undefined){
                  currentItemWrapper.wrapAddOnSupportLines = updateMisMatchQTYFlag(currentItemWrapper.wrapAddOnSupportLines);
              }
              //Inactive
              if(currentItemWrapper.wrapInactiveEnt != undefined){
                  currentItemWrapper.wrapInactiveEnt = updateMisMatchQTYFlag(currentItemWrapper.wrapInactiveEnt);
              }
              //upgrade
              if(currentItemWrapper.wrapUpgradeEnt != undefined){
                  currentItemWrapper.wrapUpgradeEnt = updateMisMatchQTYFlag(currentItemWrapper.wrapUpgradeEnt);
              }
          }
      });
  }
  return displayedData;
}

function updateMisMatchQTYFlag(currentItemWrapper) {
  currentItemWrapper.forEach(function (element, index){
      if(element.rowSelected == true) {
          if(checkifNonAssetToNonAsset(element)) {
              element.misMatchQTY = true;
          } else {
              element.misMatchQTY = false;
          }
      }
  });
  return currentItemWrapper;
}