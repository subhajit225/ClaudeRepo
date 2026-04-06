export function assignEntDataToSku(event,dataModified) {

    let customIndex = event.currentTarget.dataset.customIndex;
    let displayedData = JSON.parse(JSON.stringify(dataModified));
    let entdata;
    displayedData.forEach(function (currentItemWrapper, index) {
        if(currentItemWrapper.customIndex && currentItemWrapper.customIndex === customIndex){
                entdata = currentItemWrapper;
        } else {
            if(currentItemWrapper.wrapBaseLicense != undefined && currentItemWrapper.wrapBaseLicense.length > 0){
                entdata = entdata == undefined ? assignEntitlement(currentItemWrapper.wrapBaseLicense,customIndex) : entdata;
            }
            if(currentItemWrapper.wrapHWSupportLines != undefined && currentItemWrapper.wrapHWSupportLines.length > 0){
                entdata = entdata == undefined ? assignEntitlement(currentItemWrapper.wrapHWSupportLines,customIndex) : entdata;
            }
            if(currentItemWrapper.wrapUpgradeEnt != undefined && currentItemWrapper.wrapUpgradeEnt.length > 0){
                entdata = entdata == undefined ? assignEntitlement(currentItemWrapper.wrapUpgradeEnt,customIndex) : entdata;
            }
            if(currentItemWrapper.wrapAddOnSupportLines != undefined && currentItemWrapper.wrapAddOnSupportLines.length > 0){
                entdata = entdata == undefined ? assignEntitlement(currentItemWrapper.wrapAddOnSupportLines,customIndex) : entdata;
            }
            if(currentItemWrapper.wrapInactiveEnt != undefined && currentItemWrapper.wrapInactiveEnt.length > 0){
                entdata = entdata == undefined ? assignEntitlement(currentItemWrapper.wrapInactiveEnt,customIndex) : entdata;
            }
        }
    });
    return entdata;
}

function assignEntitlement(currentItemWrapper,customIndex){
    let entdata;
    currentItemWrapper.forEach(function (element, index){
        if(element.customIndex === customIndex){
            entdata = element;
        }
    });
    return entdata;
}

export function handleSkuAssignment(
    dnc, AssignSKUValue,dataModified,customIndex, fullSelected, 
    massDispositionValue, entitlementId , keyIdentifier, rowsval, isMisMatchQty, quotelineFieldApi ) {
    let rowsel;
	if(AssignSKUValue == true){		
        rowsel = rowsval;
	}else{
		//rowsval = undefined;
        rowsel = undefined;
	}   
    let displayedData = JSON.parse(JSON.stringify(dataModified));
	debugger;
    displayedData.forEach(function (currentItemWrapper, index) {
        // if(currentItemWrapper.entitlementId != null){
        //     currentItemWrapper = assignSkuVariablesToEachWrapper(currentItemWrapper,customIndex, rowsel, fullSelected, massDispositionValue,displayedData);
        // } else {
            //Future Transaction
            // Added as part of FY25SR-1207 - Start
            if (currentItemWrapper.mapAssetEntitlements != undefined) {
                currentItemWrapper.mapAssetEntitlements = checkIfEntitlementIdPresentAndSetValues(currentItemWrapper.mapAssetEntitlements,customIndex,
                   rowsel, fullSelected, massDispositionValue,keyIdentifier,displayedData, dnc, quotelineFieldApi);
                
            }
            // Added as part of FY25SR-1207 - End
            
            if(currentItemWrapper.wrapBaseLicense != undefined && currentItemWrapper.wrapBaseLicense.length > 0){
                currentItemWrapper.wrapBaseLicense = assignSkuVariablesToList(
                    currentItemWrapper.wrapBaseLicense,customIndex, rowsel, fullSelected, massDispositionValue,displayedData, dnc, isMisMatchQty, quotelineFieldApi);
            }
            if(currentItemWrapper.wrapHWSupportLines != undefined && currentItemWrapper.wrapHWSupportLines.length > 0){
                currentItemWrapper.wrapHWSupportLines = assignSkuVariablesToList(
                    currentItemWrapper.wrapHWSupportLines,customIndex, rowsel, fullSelected, massDispositionValue,displayedData, dnc, isMisMatchQty, quotelineFieldApi);
            } 
            if(currentItemWrapper.wrapAddOnSupportLines != undefined && currentItemWrapper.wrapAddOnSupportLines.length > 0){
                currentItemWrapper.wrapAddOnSupportLines = assignSkuVariablesToList(
                    currentItemWrapper.wrapAddOnSupportLines,customIndex, rowsel, fullSelected, massDispositionValue,displayedData, dnc, isMisMatchQty, quotelineFieldApi);
            }
            if(currentItemWrapper.wrapInactiveEnt != undefined && currentItemWrapper.wrapInactiveEnt.length > 0){
                currentItemWrapper.wrapInactiveEnt = assignSkuVariablesToList(
                    currentItemWrapper.wrapInactiveEnt,customIndex, rowsel, fullSelected, massDispositionValue,displayedData, dnc, isMisMatchQty, quotelineFieldApi);
            } 
            if(currentItemWrapper.wrapUpgradeEnt != undefined && currentItemWrapper.wrapUpgradeEnt.length > 0){
                currentItemWrapper.wrapUpgradeEnt = assignSkuVariablesToList(
                    currentItemWrapper.wrapUpgradeEnt,customIndex, rowsel, fullSelected, massDispositionValue,displayedData, dnc, isMisMatchQty, quotelineFieldApi);
            }           
        // }

    });
    return displayedData;
}

// Added as part of FY25SR-1207 - Start
function checkIfEntitlementIdPresentAndSetValues(
    currentItemWrapper, customIndex, rowsel, fullSelected, massDispositionValue,keyIdentifier,displayedData, dnc, isMisMatchQty, quotelineFieldApi) {
    currentItemWrapper.futureValues.forEach(element => {
        if(element.keyIdentifier === keyIdentifier ){ //&& element.entitlementId === selectedEntitlementId
            element = assignSkuVariables(element, rowsel, fullSelected, massDispositionValue,displayedData, dnc, isMisMatchQty, quotelineFieldApi);
        }
    });
    return currentItemWrapper;
}
// Added as part of FY25SR-1207 - End

function assignSkuVariablesToList(currentItemWrapper,customIndex, rowsel, fullSelected, massDispositionValue,
            displayedData, dnc, isMisMatchQty, quotelineFieldApi){
    currentItemWrapper.forEach(function (element, index){
        element = assignSkuVariablesToEachWrapper(
            element,customIndex, rowsel, fullSelected, massDispositionValue,displayedData, dnc, isMisMatchQty, quotelineFieldApi );
    });
    return currentItemWrapper;
}

function assignSkuVariablesToEachWrapper(
    element,customIndex, rowsel, fullSelected, massDispositionValue,displayedData, dnc, isMisMatchQty, quotelineFieldApi){
    if(element.customIndex === customIndex){
        element = assignSkuVariables(element, rowsel, fullSelected, massDispositionValue,displayedData, dnc, isMisMatchQty, quotelineFieldApi);
    }
    return element;
}

function assignSkuVariables(entDataWrapper, rowsel, fullSelected, massDispositionValue,displayedData, dnc, isMisMatchQty, quotelineFieldApi){   
    entDataWrapper.skuProdName = rowsel != undefined ?  (rowsel.productName != undefined ? rowsel.productName : ''):'';
    entDataWrapper.skuProductId = rowsel != undefined ?  (rowsel.productId != undefined ? rowsel.productId : ''):'';
    
    entDataWrapper.skuSuppType = rowsel != undefined ?  (rowsel.productSupportType != undefined ? rowsel.productSupportType : ''):'';
  //  entDataWrapper.skuProdCodeType = rowsel != undefined ? (rowsel.productCodeType != undefined ? rowsel.productCodeType : '') : ''; 
    entDataWrapper.skuProdCodeType = rowsel != undefined ? (rowsel.productCodeType != undefined ? rowsel.productCodeType : entDataWrapper.skuProdCodeType) : entDataWrapper.skuProdCodeType; //FY25SR-1705
    entDataWrapper.isModified = rowsel != undefined ?  (rowsel.productId != undefined ? true : false) : false;
    entDataWrapper.anyToAnyFlag = rowsel != undefined ? (rowsel.anyToAnyFlag != undefined ? rowsel.anyToAnyFlag : false) : false;
    entDataWrapper.skuProdRepCategory = rowsel != undefined ? (rowsel.productReplacementCategory != undefined ? rowsel.productReplacementCategory : '') : '';
    entDataWrapper.errors = ''; //FY25SR-1084 START
    entDataWrapper.doNotConsolidateEnt = rowsel != undefined ? (rowsel.doNotConsolidateSKU != undefined && rowsel.doNotConsolidateSKU == true ? rowsel.doNotConsolidateSKU : dnc) : dnc; //FY25SR-1705
    if(entDataWrapper.tphTypeEntitlement != undefined && entDataWrapper.tphTypeEntitlement == true){
        entDataWrapper.disableQuantity = true;
        entDataWrapper.showAdd = false;
    }
    //For Non asset to non asset
    if((entDataWrapper.skuProductId === null || entDataWrapper.skuProductId === undefined || entDataWrapper.skuProductId === '') 
    && entDataWrapper.quantityAssetType) {
        let totalQuantity = calculateTotalSelectedNonAssetQuantity(displayedData,entDataWrapper);
        if(totalQuantity < entDataWrapper.quantity ) {
          entDataWrapper.showAdd = true;
        }
    }
    if(rowsel != undefined){   
        entDataWrapper.targetProductType = rowsel.pathFromSKU != undefined ? rowsel.pathFromSKU : '';
        if(checkifNonAssetToNonAsset(entDataWrapper) && isMisMatchQty) {
            entDataWrapper.showAdd = false;
      } else {
          let totalQuantity = calculateTotalSelectedNonAssetQuantity(displayedData,entDataWrapper);
            if(totalQuantity < entDataWrapper.quantity) {
              entDataWrapper.showAdd = true;
          }
        }
            if(rowsel.pathAssetSelected != undefined && rowsel.pathAssetSelected.length > 0){
                //FY25SR-1705
                entDataWrapper.selectedAssetsFromNonAsset = rowsel.pathAssetSelected.map(item => item);
                let quantSum = 0;
                entDataWrapper.selectedAssetsFromNonAsset.forEach(currItem =>{
                    if(currItem.selected == true && currItem.value != 'Non Asset' && currItem.quantity != undefined){
                        quantSum = parseInt(quantSum) + parseInt(currItem.quantity);
                    }
                });
                if(parseInt(quantSum) > 0 && entDataWrapper.quantityAssetType == true){
                    entDataWrapper.selectedquantity = parseInt(quantSum);
                    let totalQuantity = calculateConsumedQuantity(displayedData,entDataWrapper);
                    entDataWrapper = mapConsumedForEnt(totalQuantity, entDataWrapper,parseInt(quantSum)); 
                    entDataWrapper.disableQuantity = true;
                }
            }   //FY25SR-1705      
            let mapSkuAttributes = {};
            if(rowsel.childMappingSKUattributes != undefined){
                //FY25SR-2361- Start
                if(entDataWrapper.skuAttributesToQuoteLine != undefined && quotelineFieldApi != undefined) {
                    quotelineFieldApi.forEach(field => {
                        if (entDataWrapper.skuAttributesToQuoteLine.hasOwnProperty(field)) {
                            mapSkuAttributes[field] = entDataWrapper.skuAttributesToQuoteLine[field];
                        }
                    });
                }//FY25SR-2361 - End
                for(var key in rowsel.childMappingSKUattributes){
                    mapSkuAttributes[key] = rowsel.childMappingSKUattributes[key];
                }
                entDataWrapper.skuAttributesToQuoteLine = mapSkuAttributes;
                let quantitySum = 0;
                quantitySum = mapSkuAttributes.hasOwnProperty('Salesforce_Quantity__c') && mapSkuAttributes['Salesforce_Quantity__c'] != undefined && mapSkuAttributes['Salesforce_Quantity__c'] != null && mapSkuAttributes['Salesforce_Quantity__c'] != '' ? parseInt(quantitySum)+parseInt(mapSkuAttributes['Salesforce_Quantity__c']) : parseInt(quantitySum);
                quantitySum = mapSkuAttributes.hasOwnProperty('Rubrik_Hosted_M365_Quantity__c') && mapSkuAttributes['Rubrik_Hosted_M365_Quantity__c'] != undefined && mapSkuAttributes['Rubrik_Hosted_M365_Quantity__c'] != null && mapSkuAttributes['Rubrik_Hosted_M365_Quantity__c'] != '' ? parseInt(quantitySum)+parseInt(mapSkuAttributes['Rubrik_Hosted_M365_Quantity__c']) : parseInt(quantitySum);
                quantitySum = mapSkuAttributes.hasOwnProperty('Atlassian_Quantity__c') && mapSkuAttributes['Atlassian_Quantity__c'] != undefined && mapSkuAttributes['Atlassian_Quantity__c'] != null && mapSkuAttributes['Atlassian_Quantity__c'] != '' ? parseInt(quantitySum)+parseInt(mapSkuAttributes['Atlassian_Quantity__c']) : parseInt(quantitySum);
                quantitySum = mapSkuAttributes.hasOwnProperty('Dynamics_Quantity__c') && mapSkuAttributes['Dynamics_Quantity__c'] != undefined && mapSkuAttributes['Dynamics_Quantity__c'] != null && mapSkuAttributes['Dynamics_Quantity__c'] != '' ? parseInt(quantitySum)+parseInt(mapSkuAttributes['Dynamics_Quantity__c']) : parseInt(quantitySum);                
quantitySum = mapSkuAttributes.hasOwnProperty('Google_Workspace_Quantity__c') && mapSkuAttributes['Google_Workspace_Quantity__c'] != undefined && mapSkuAttributes['Google_Workspace_Quantity__c'] != null && mapSkuAttributes['Google_Workspace_Quantity__c'] != '' ? parseInt(quantitySum)+parseInt(mapSkuAttributes['Google_Workspace_Quantity__c']) : parseInt(quantitySum);                

                if(parseInt(quantitySum) > 0 && entDataWrapper.quantityAssetType == true){
                            entDataWrapper.selectedquantity = parseInt(quantitySum);
                            let totalQuantity = calculateConsumedQuantity(displayedData,entDataWrapper);
                            entDataWrapper = mapConsumedForEnt(totalQuantity, entDataWrapper,parseInt(quantitySum));  
                            entDataWrapper.disableQuantity = true;
                }
            }
    }else{
                if(entDataWrapper.quantityAssetType != undefined && entDataWrapper.quantityAssetType == true){
                    entDataWrapper.targetProductType = 'Non-Hardware';
                }else if(entDataWrapper.quantityAssetType != undefined && entDataWrapper.quantityAssetType == false){
                    entDataWrapper.targetProductType = 'Hardware';
                }

                if(entDataWrapper.tphTypeEntitlement != undefined && entDataWrapper.tphTypeEntitlement == true){
                            entDataWrapper.disableQuantity = true;
                            entDataWrapper.showAdd = false;
                }else if(entDataWrapper.quantityAssetType != undefined && entDataWrapper.quantityAssetType == false){
                    entDataWrapper.disableQuantity = true;
                }else{
                    entDataWrapper.disableQuantity = false;
                }
                entDataWrapper.skuAttributesToQuoteLine = null;
                entDataWrapper.selectedAssetsFromNonAsset = [];
    }    
//FY25SR-1084 END
    if(rowsel != undefined && rowsel.dispositionReason != undefined){
        entDataWrapper.autoDisposition.forEach((currItem) => {
          currItem.selected = false;  
          if(rowsel.dispositionReason === currItem.label){
                currItem.selected = true;  
                entDataWrapper.selecteddisposition = currItem.value;  
                entDataWrapper.disableDisposition = true;
          }
      });
      entDataWrapper.manualDisposition.forEach((currItem) => {
          currItem.selected = false;            
      });

    }else{

			entDataWrapper.autoDisposition.forEach((currItem) => {
			  if(currItem.selected == true){
					currItem.selected = false;  
					entDataWrapper.selecteddisposition = '';  
					entDataWrapper.disableDisposition = false;
			  }
			});
            entDataWrapper.manualDisposition.forEach((currItem) => {
			  if(currItem.selected == true){
					currItem.selected = false;  
					entDataWrapper.selecteddisposition = '';  
			  }
			});
            if(fullSelected == true && entDataWrapper.rowSelected == true){
                entDataWrapper.manualDisposition.forEach((currItem) => {
                    if(currItem.value === massDispositionValue){
                            currItem.selected = true;  
                            entDataWrapper.selecteddisposition = massDispositionValue;  
                    }
                });
            }
    }    

    //Added as part of FY25SR-1492
    // Retain the values only if the remaining term is not set to 12
    if(entDataWrapper.ReplacementTerm != 12 && entDataWrapper.RemainingTerm != 12){
        entDataWrapper.previousReplacementTerm = entDataWrapper.ReplacementTerm;
        entDataWrapper.previousRemainingTerm = entDataWrapper.RemainingTerm;
    }
    
    if(entDataWrapper.selecteddisposition === 'Renewing' && (entDataWrapper.renewalEndDate === undefined || entDataWrapper.renewalEndDate === null)){
        // Set the values to 12 on changing or selection of manual disposition reason
        entDataWrapper.ReplacementTerm = 12;
        entDataWrapper.RemainingTerm = 12;
        //Added as part of FY25SR-1492
        //FY25SSR-2349
        entDataWrapper.disableRenewalEndDate = false;
        entDataWrapper.disableTerm = true;
        //FY25SSR-2349
    } else {
        //Added as part of FY25SR-1492
        entDataWrapper.disableRenewalEndDate = true;
        entDataWrapper.disableTerm = false;
        // if(entDataWrapper.selecteddisposition === ''){
            entDataWrapper.ReplacementTerm = entDataWrapper.previousReplacementTerm != undefined ? entDataWrapper.previousReplacementTerm : 12 ;
            entDataWrapper.RemainingTerm = entDataWrapper.previousRemainingTerm != undefined ? entDataWrapper.previousRemainingTerm : 12;
        // }
    }

    //FY25SSR-2349
    if(rowsel != undefined && entDataWrapper.selecteddisposition === 'Renewing'){
        entDataWrapper.disableRenewalEndDate = false;
        entDataWrapper.disableTerm = true;
    }
    //FY25SSR-2349
    return entDataWrapper;
  }
  //FY25SR-1084, FY25SR-1705
  function mapConsumedForEnt(totalQuantity, entDataWrapper, quantitySum){
    if(parseInt(totalQuantity) === 0){
            entDataWrapper.consumedquantity = 0;
            entDataWrapper.consumedquantity = parseInt(entDataWrapper.consumedquantity)+parseInt(quantitySum);
            if(parseInt(entDataWrapper.selectedMaxquantity) === parseInt(entDataWrapper.consumedquantity)){
                    entDataWrapper.showAdd = false;
            }else if(parseInt(entDataWrapper.selectedMaxquantity) > parseInt(entDataWrapper.consumedquantity)){
                    entDataWrapper.showAdd = true;
            }
    }else {  
            entDataWrapper.consumedquantity = parseInt(totalQuantity)+parseInt(quantitySum);                                        
                if(parseInt(entDataWrapper.selectedMaxquantity) > parseInt(entDataWrapper.consumedquantity)){
                        entDataWrapper.showAdd = true;
                }
    }
    return entDataWrapper;
  }
   //FY25SR-1084, FY25SR-1705
  //FY25SR-1084 START
  function calculateConsumedQuantity(displayedData, entWrapper){
    let totalQuantity=0;
        displayedData.forEach(function (currentItemWrapper, index) {
        if(currentItemWrapper.entitlementId != null){
            if(currentItemWrapper.customIndex.split('.')[0] === entWrapper.customIndex.split('.')[0] && entWrapper.customIndex != currentItemWrapper.customIndex){
                totalQuantity = parseInt(totalQuantity)+parseInt(currentItemWrapper.selectedquantity);
            }
        } else {
            if(currentItemWrapper.wrapBaseLicense != undefined && currentItemWrapper.wrapBaseLicense.length > 0){
                currentItemWrapper.wrapBaseLicense.forEach(function (element, index){
                        if(element.customIndex.split('.')[0] === entWrapper.customIndex.split('.')[0] && entWrapper.customIndex != element.customIndex){
                            totalQuantity = parseInt(totalQuantity)+parseInt(element.selectedquantity);
                        }
                });
            }
            if(currentItemWrapper.wrapHWSupportLines != undefined && currentItemWrapper.wrapHWSupportLines.length > 0){
                currentItemWrapper.wrapHWSupportLines.forEach(function (element, index){
                        if(element.customIndex.split('.')[0] === entWrapper.customIndex.split('.')[0] && entWrapper.customIndex != element.customIndex){
                            totalQuantity = parseInt(totalQuantity)+parseInt(element.selectedquantity);
                        }
                });
            } 
            if(currentItemWrapper.wrapAddOnSupportLines != undefined && currentItemWrapper.wrapAddOnSupportLines.length > 0){
                currentItemWrapper.wrapAddOnSupportLines.forEach(function (element, index){
                        if(element.customIndex.split('.')[0] === entWrapper.customIndex.split('.')[0] && entWrapper.customIndex != element.customIndex){
                            totalQuantity = parseInt(totalQuantity)+parseInt(element.selectedquantity);
                        }
                });
            }
            if(currentItemWrapper.wrapInactiveEnt != undefined && currentItemWrapper.wrapInactiveEnt.length > 0){
                currentItemWrapper.wrapInactiveEnt.forEach(function (element, index){
                        if(element.customIndex.split('.')[0] === entWrapper.customIndex.split('.')[0] && entWrapper.customIndex != element.customIndex){
                            totalQuantity = parseInt(totalQuantity)+parseInt(element.selectedquantity);
                        }
                });
            } 
            if(currentItemWrapper.wrapUpgradeEnt != undefined && currentItemWrapper.wrapUpgradeEnt.length > 0){
                currentItemWrapper.wrapUpgradeEnt.forEach(function (element, index){
                        if(element.customIndex.split('.')[0] === entWrapper.customIndex.split('.')[0] && entWrapper.customIndex != element.customIndex){
                            totalQuantity = parseInt(totalQuantity)+parseInt(element.selectedquantity);
                        }
                });
            }           
        }

    });
      return totalQuantity;
  }
   //FY25SR-1084 END
   function calculateTotalSelectedNonAssetQuantity(displayedData, entWrapper) {
    let totalQuantity = 0;
    displayedData.forEach(function (currentItemWrapper, index) {
        if(currentItemWrapper.entitlementId != null){
            if(currentItemWrapper.customIndex.split('.')[0] === entWrapper.customIndex.split('.')[0] && entWrapper.entitlementId === currentItemWrapper.entitlementId){
                totalQuantity = parseInt(totalQuantity)+parseInt(currentItemWrapper.selectedquantity);
            }
        } else {
            if(currentItemWrapper.wrapBaseLicense != undefined && currentItemWrapper.wrapBaseLicense.length > 0){
                let filteredEnts = currentItemWrapper.wrapBaseLicense.filter(item => item.entitlementId === entWrapper.entitlementId);
                filteredEnts.forEach(currentItemWrapper => {
                    totalQuantity = parseInt(totalQuantity)+parseInt(currentItemWrapper.selectedquantity);
                });
            }
            if(currentItemWrapper.wrapHWSupportLines != undefined && currentItemWrapper.wrapHWSupportLines.length > 0){
                let filteredEnts = currentItemWrapper.wrapHWSupportLines.filter(item => item.entitlementId === entWrapper.entitlementId);
                filteredEnts.forEach(currentItemWrapper => {
                    totalQuantity = parseInt(totalQuantity)+parseInt(currentItemWrapper.selectedquantity);
                });
            } 
            if(currentItemWrapper.wrapAddOnSupportLines != undefined && currentItemWrapper.wrapAddOnSupportLines.length > 0){
                let filteredEnts = currentItemWrapper.wrapAddOnSupportLines.filter(item => item.entitlementId === entWrapper.entitlementId);
                filteredEnts.forEach(currentItemWrapper => {
                    totalQuantity = parseInt(totalQuantity)+parseInt(currentItemWrapper.selectedquantity);
                });
            }
            if(currentItemWrapper.wrapInactiveEnt != undefined && currentItemWrapper.wrapInactiveEnt.length > 0){
                let filteredEnts = currentItemWrapper.wrapInactiveEnt.filter(item => item.entitlementId === entWrapper.entitlementId);
                filteredEnts.forEach(currentItemWrapper => {
                    totalQuantity = parseInt(totalQuantity)+parseInt(currentItemWrapper.selectedquantity);
                });
            } 
            if(currentItemWrapper.wrapUpgradeEnt != undefined && currentItemWrapper.wrapUpgradeEnt.length > 0){
                let filteredEnts = currentItemWrapper.wrapUpgradeEnt.filter(item => item.entitlementId === entWrapper.entitlementId);
                filteredEnts.forEach(currentItemWrapper => {
                    totalQuantity = parseInt(totalQuantity)+parseInt(currentItemWrapper.selectedquantity);
                });
            }           
        }
    });
    return totalQuantity;
   }
function checkifNonAssetToNonAsset(currentItemWrapper) {
    if(currentItemWrapper.quantityAssetType && 
      currentItemWrapper.targetProductType != null && 
      currentItemWrapper.targetProductType != undefined && 
      isEqualStrings(currentItemWrapper.targetProductType, 'Non-Hardware') &&
      
      currentItemWrapper.skuProductId != null && 
      currentItemWrapper.skuProductId != undefined && 
      currentItemWrapper.skuProductId != '' ) {
      return true;    
    }
    return false;
  }

// FY25SR-1124 - end
function isEqualStrings(itemValue, tocompare) {
  return itemValue.trim().toLowerCase() === tocompare.trim().toLowerCase();
}