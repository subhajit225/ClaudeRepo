export function handlecheckBoxSelection(displayedData,customIndex,checkBoxSelection, dnc){
    let rowSelected = checkBoxSelection;
    displayedData.forEach((currentItemWrapper, index) => {
        // if(currentItemWrapper.customIndex != undefined){
        //     currentItemWrapper = setRowSelectedVariableForSelectedCustomIndexEachWrapper(currentItemWrapper,rowSelected,customIndex);
        // }

        // Future Transaction
        // Added as part of FY25SR-1207 - Start
        if (currentItemWrapper.mapAssetEntitlements != undefined) {
            if(currentItemWrapper.customIndex === customIndex){
            currentItemWrapper.rowSelected = rowSelected;
            currentItemWrapper.isModified = true;
            currentItemWrapper.mapAssetEntitlements.futureValues.forEach(currentItem => {
                currentItem.rowSelected = rowSelected;
                currentItem.isModified = true;
            });
            }
            // currentItemWrapper = setRowSelectedVariableForSelectedCustomIndexEachWrapper(currentItemWrapper,rowSelected,customIndex);
            
        }
        // Added as part of FY25SR-1207 - End

        if (currentItemWrapper.wrapBaseLicense != undefined && currentItemWrapper.wrapBaseLicense.length > 0) {
            currentItemWrapper.wrapBaseLicense = setRowSelectedVariableForSelectedCustomIndex(currentItemWrapper.wrapBaseLicense,rowSelected,customIndex,dnc);
        }

        if (currentItemWrapper.wrapHWSupportLines != undefined && currentItemWrapper.wrapHWSupportLines.length > 0) {
            currentItemWrapper.wrapHWSupportLines = setRowSelectedVariableForSelectedCustomIndex(currentItemWrapper.wrapHWSupportLines,rowSelected,customIndex,dnc);
        }

        if (currentItemWrapper.wrapAddOnSupportLines != undefined && currentItemWrapper.wrapAddOnSupportLines.length > 0) {
            currentItemWrapper.wrapAddOnSupportLines = setRowSelectedVariableForSelectedCustomIndex(currentItemWrapper.wrapAddOnSupportLines,rowSelected,customIndex,dnc);
        }

        if (currentItemWrapper.wrapInactiveEnt != undefined && currentItemWrapper.wrapInactiveEnt.length > 0) {
            currentItemWrapper.wrapInactiveEnt = setRowSelectedVariableForSelectedCustomIndex(currentItemWrapper.wrapInactiveEnt,rowSelected,customIndex,dnc);
        }

        if (currentItemWrapper.wrapUpgradeEnt != undefined && currentItemWrapper.wrapUpgradeEnt.length > 0) {
            currentItemWrapper.wrapUpgradeEnt = setRowSelectedVariableForSelectedCustomIndex(currentItemWrapper.wrapUpgradeEnt,rowSelected,customIndex,dnc);
        }
    });
    return displayedData
}

function setRowSelectedVariableForSelectedCustomIndex(currentItemWrapper,rowSelected,customIndex,dnc){
    let customIndexSplitted = customIndex.split('.')[0]+ '.' + customIndex.split('.')[1];
    currentItemWrapper.forEach(currentItem => {
        currentItem = setRowSelectedVariableForSelectedCustomIndexEachWrapper(currentItem,rowSelected,customIndexSplitted,customIndex,dnc);
    });
    return currentItemWrapper;
}

function setRowSelectedVariableForSelectedCustomIndexEachWrapper(currentItem,rowSelected,customIndexSplitted,customIndex,dnc){
    if (customIndexSplitted === (currentItem.customIndex.split('.')[0] + '.' + currentItem.customIndex.split('.')[1])) {
        currentItem.rowSelected = rowSelected;
        currentItem.isModified = true;
    }
//FY25SR-1124
    if(currentItem.customIndex === customIndex){
        currentItem = exceptionCheck(currentItem, dnc);
    }
    
    return currentItem;
}

function exceptionCheck(currentItem,dnc){
    if(currentItem.skuProductId != undefined && currentItem.skuProductId != null && 
                    ((currentItem.quantityAssetType == false && currentItem.targetProductType != undefined && currentItem.targetProductType === 'Non-Hardware') || 
                    (currentItem.quantityAssetType == true && currentItem.targetProductType != undefined && currentItem.targetProductType === 'Hardware'))){
                        currentItem.doNotConsolidateEnt = true;
    }else{
        currentItem.doNotConsolidateEnt = dnc;
    }
    return currentItem;
}
//FY25SR-1124
export function handlecheckBoxSelectionAll(displayedData,rowSelected, massDisposition, selectedFromFull, dnc,massTermValue){//CPQ22-6193 this.massTermValue
    displayedData.forEach((currentItemWrapper, index) => {
      
      // Added as part of FY25SR-1207 - Start
      if (currentItemWrapper.mapAssetEntitlements != undefined && currentItemWrapper.showmapAssetEntitlements) {
        currentItemWrapper = setRowSelectedVariableEachWrapper(currentItemWrapper,rowSelected,massDisposition,selectedFromFull,true, dnc,massTermValue);//CPQ22-6193 this.massTermValue
        if(selectedFromFull == true){
            currentItemWrapper.rowSelected = rowSelected;
        }
        currentItemWrapper.mapAssetEntitlements.futureValues.forEach(currentItem => {
            currentItem = setRowSelectedVariableEachWrapper(currentItem,rowSelected,massDisposition,selectedFromFull,false, dnc,massTermValue);//CPQ22-6193 this.massTermValue
            if(selectedFromFull == true){
            currentItem.rowSelected = rowSelected;
            }
            currentItem.isModified = true;
            currentItem.errors = '';
        });
      }
      // Added as part of FY25SR-1207 - End

      if (currentItemWrapper.wrapBaseLicense != undefined && currentItemWrapper.wrapBaseLicense.length > 0 && currentItemWrapper.showwrapBaseLicense) {//CPQ22-6009
          currentItemWrapper.wrapBaseLicense = setRowSelectedVariable(currentItemWrapper.wrapBaseLicense,rowSelected,massDisposition,selectedFromFull, dnc,massTermValue);//CPQ22-6193 this.massTermValue
      }

      if (currentItemWrapper.wrapHWSupportLines != undefined && currentItemWrapper.wrapHWSupportLines.length > 0 && currentItemWrapper.showwrapHWSupportLines) {//CPQ22-6009
          currentItemWrapper.wrapHWSupportLines = setRowSelectedVariable(currentItemWrapper.wrapHWSupportLines,rowSelected,massDisposition,selectedFromFull, dnc,massTermValue);//CPQ22-6193 this.massTermValue
      }

      if (currentItemWrapper.wrapAddOnSupportLines != undefined && currentItemWrapper.wrapAddOnSupportLines.length > 0 && currentItemWrapper.showwrapAddOnSupportLines) {//CPQ22-6009
          currentItemWrapper.wrapAddOnSupportLines = setRowSelectedVariable(currentItemWrapper.wrapAddOnSupportLines,rowSelected,massDisposition,selectedFromFull, dnc,massTermValue);//CPQ22-6193 this.massTermValue
      }

      if (currentItemWrapper.wrapUpgradeEnt != undefined && currentItemWrapper.wrapUpgradeEnt.length > 0 && currentItemWrapper.showwrapUpgradeEnt) {//CPQ22-6009
          currentItemWrapper.wrapUpgradeEnt = setRowSelectedVariable(currentItemWrapper.wrapUpgradeEnt,rowSelected,massDisposition,selectedFromFull, dnc,massTermValue);//CPQ22-6193 this.massTermValue
      }

      
    });
    return displayedData;
}

function setRowSelectedVariable(currentItemWrapper,rowSelected,massDisposition,selectedFromFull, dnc,massTermValue){//CPQ22-6193 this.massTermValue
    currentItemWrapper.forEach(currentItem => {
        currentItem = setRowSelectedVariableEachWrapper(currentItem,rowSelected,massDisposition,selectedFromFull,false, dnc,massTermValue);//CPQ22-6193 this.massTermValue
        if (currentItem.wrapInactiveEnt != undefined && currentItem.wrapInactiveEnt.length > 0 && currentItem.showwrapInactiveEnt ) {
            currentItem.wrapInactiveEnt.forEach(currentItemInner => {
                        currentItemInner = setRowSelectedVariableEachWrapper(currentItemInner,rowSelected,massDisposition,selectedFromFull,false, dnc,massTermValue);//CPQ22-6193 this.massTermValue
            });
        }
    });
    return currentItemWrapper;
}

function setRowSelectedVariableEachWrapper(currentItem,rowSelected,massDisposition,selectedFromFull,isFutureTransaction, dnc,massTermValue){//CPQ22-6193 this.massTermValue
    if(selectedFromFull == true){
        if(rowSelected == true){
            currentItem.rowSelected = rowSelected;
            currentItem = exceptionCheck(currentItem, dnc);
                currentItem.isModified = true;
                currentItem.errors = '';                
        }else if(rowSelected == false && currentItem.renLine == false){
                currentItem = exceptionCheck(currentItem, dnc);
                currentItem.rowSelected = rowSelected;
                currentItem.isModified = true;
                currentItem.errors = '';
        }
    }else if(selectedFromFull == false){
        //CPQ22-6009--massDisposition != undefined &&
        if(currentItem.disableDisposition == false && currentItem.rowSelected == true){
              currentItem = setMassDisposition(currentItem,massDisposition,isFutureTransaction,massTermValue);//CPQ22-6193 this.massTermValue
              currentItem.isModified = true;
              currentItem.errors = ''; 
        }
    }    
    return currentItem;
}

function setMassDisposition(currentItem,massDisposition,isFutureTransaction,massTermValue){//CPQ22-6193 this.massTermValue
    currentItem = setExistingMassDispsitionToFalse(currentItem,isFutureTransaction);
     // Added as part of FY25SR-1207 - Start
    if(isFutureTransaction){
        currentItem.mapAssetEntitlements.futureValues.forEach(function (currItem){
            currItem = setManualDisposition(currItem,massDisposition,massTermValue);//CPQ22-6193 this.massTermValue
        });
    } else {
        currentItem.selecteddisposition = massDisposition;
        currentItem = setManualDisposition(currentItem,massDisposition,massTermValue);//CPQ22-6193 this.massTermValue
        
    }
     // Added as part of FY25SR-1207 - End
    return currentItem;
}

// Added as part of FY25SR-1207 - Start
function setManualDisposition(currentItem,massDisposition,massTermValue){//CPQ22-6193 this.massTermValue
    currentItem.manualDisposition.forEach(function (currItem){
            if(currItem.value === massDisposition){
                currItem.selected = true;
                currentItem.selecteddisposition = currItem.value;
                //Added as part of FY25SR-1492
                // Retain the values only if the remaining term is not set to 12
                if(currentItem.ReplacementTerm != 12 && currentItem.RemainingTerm != 12){
                    currentItem.previousReplacementTerm = currentItem.ReplacementTerm;
                    currentItem.previousRemainingTerm = currentItem.RemainingTerm;
                }
                if(currentItem.selecteddisposition === 'Renewing'){
                    // Set the values to 12 on changing or selection of manual disposition reason
                    /*if((massTermValue == null || massTermValue == undefined)){//CPQ22-6193 this.massTermValue
                    currentItem.ReplacementTerm = 12;//CPQ22-6414
                    currentItem.RemainingTerm = 12;//CPQ22-6414
                    }*/
                    //Added as part of FY25SR-1492
                    currentItem.disableRenewalEndDate = false;
                    //currentItem.disableTerm = true;//CPQ22-6193
                    
                } else {
                    //Added as part of FY25SR-1492
                    currentItem.disableRenewalEndDate = true;
                    currentItem.disableTerm = false;
                    currentItem.ReplacementTerm = currentItem.previousReplacementTerm;
                    currentItem.RemainingTerm = currentItem.previousRemainingTerm;
                }
            }                        
    });
    return currentItem;
}
// Added as part of FY25SR-1207 - END

function setExistingMassDispsitionToFalse(currentItem){
    currentItem.manualDisposition.forEach(function (currItem){
                    currItem.selected = false;
                });
    return currentItem;
}

export function appedCurrentPageDataOnSelectAll(currentPageData, datamodified){
    let currentDataMap = new Map();
    let finalWrapperList = [];
    currentPageData.forEach((currentItemWrapper, index) => {
        
      if(currentItemWrapper.customIndex != undefined){
            currentDataMap.set(currentItemWrapper.customIndex.split('.')[0], currentItemWrapper);
      }
      if (currentItemWrapper.wrapBaseLicense != undefined && currentItemWrapper.wrapBaseLicense.length > 0) {
            currentDataMap.set(currentItemWrapper.wrapBaseLicense[0].customIndex.split('.')[0], currentItemWrapper);      
            }
      if (currentItemWrapper.wrapHWSupportLines != undefined && currentItemWrapper.wrapHWSupportLines.length > 0) {
            currentDataMap.set(currentItemWrapper.wrapHWSupportLines[0].customIndex.split('.')[0], currentItemWrapper);      
            }
      if (currentItemWrapper.wrapAddOnSupportLines != undefined && currentItemWrapper.wrapAddOnSupportLines.length > 0) {
            currentDataMap.set(currentItemWrapper.wrapAddOnSupportLines[0].customIndex.split('.')[0], currentItemWrapper);      
            }
    //   if (currentItemWrapper.wrapInactiveEnt != undefined && currentItemWrapper.wrapInactiveEnt.length > 0) {
    //         currentDataMap.set(currentItemWrapper.wrapInactiveEnt[0].customIndex.split('.')[0], currentItemWrapper);      
    //         }
      if (currentItemWrapper.wrapUpgradeEnt != undefined && currentItemWrapper.wrapUpgradeEnt.length > 0) {
            currentDataMap.set(currentItemWrapper.wrapUpgradeEnt[0].customIndex.split('.')[0], currentItemWrapper);      }
    });

    let finalMap = new Map();
    datamodified.forEach((currentItemWrapper, index) => {
    let rowFound;

      if(currentItemWrapper.customIndex != undefined){
           rowFound = mapFinalWrapper(currentItemWrapper,currentDataMap);
           if(!finalMap.has(currentItemWrapper.customIndex.split('.')[0])){
                    if(rowFound == true){
                    finalMap.set(currentItemWrapper.customIndex.split('.')[0],currentDataMap.get(currentItemWrapper.customIndex.split('.')[0]));
                }else if(rowFound == false){
                    finalMap.set(currentItemWrapper.customIndex.split('.')[0],currentItemWrapper);
                }
            }   
      }
      if (currentItemWrapper.wrapBaseLicense != undefined && currentItemWrapper.wrapBaseLicense.length > 0) {
                rowFound = mapFinalWrapper(currentItemWrapper.wrapBaseLicense[0],currentDataMap);     
                if(!finalMap.has(currentItemWrapper.wrapBaseLicense[0].customIndex.split('.')[0])){
                        if(rowFound == true){
                        finalMap.set(currentItemWrapper.wrapBaseLicense[0].customIndex.split('.')[0],currentDataMap.get(currentItemWrapper.wrapBaseLicense[0].customIndex.split('.')[0]));
                    }else if(rowFound == false){
                        finalMap.set(currentItemWrapper.wrapBaseLicense[0].customIndex.split('.')[0],currentItemWrapper);
                    }
                }                 
            }
      if (currentItemWrapper.wrapHWSupportLines != undefined && currentItemWrapper.wrapHWSupportLines.length > 0) {
            rowFound = mapFinalWrapper(currentItemWrapper.wrapHWSupportLines[0],currentDataMap);     
                if(!finalMap.has(currentItemWrapper.wrapHWSupportLines[0].customIndex.split('.')[0])){
                    if(rowFound == true){
                        finalMap.set(currentItemWrapper.wrapHWSupportLines[0],currentDataMap.get(currentItemWrapper.wrapHWSupportLines[0].customIndex.split('.')[0]));
                    }else{
                        finalMap.set(currentItemWrapper.wrapHWSupportLines[0].customIndex.split('.')[0],currentItemWrapper);
                    }
                }                      
            }

      if (currentItemWrapper.wrapAddOnSupportLines != undefined && currentItemWrapper.wrapAddOnSupportLines.length > 0) {
            rowFound = mapFinalWrapper(currentItemWrapper.wrapAddOnSupportLines[0],currentDataMap);  
            if(!finalMap.has(currentItemWrapper.wrapAddOnSupportLines[0].customIndex.split('.')[0])){
                    if(rowFound == true){
                        finalMap.set(currentItemWrapper.wrapAddOnSupportLines[0],currentDataMap.get(currentItemWrapper.wrapAddOnSupportLines[0].customIndex.split('.')[0]));
                    }else{
                        finalMap.set(currentItemWrapper.wrapAddOnSupportLines[0].customIndex.split('.')[0],currentItemWrapper);
                    }
            }      
        }
    //   if (currentItemWrapper.wrapInactiveEnt != undefined && currentItemWrapper.wrapInactiveEnt.length > 0) {
    //         rowFound = mapFinalWrapper(currentItemWrapper.wrapInactiveEnt[0],currentDataMap);     
    //         if(!finalMap.has(currentItemWrapper.wrapInactiveEnt[0].customIndex.split('.')[0])){
    //                 if(rowFound == true){
    //                         finalMap.set(currentItemWrapper.wrapInactiveEnt[0],currentDataMap.get(currentItemWrapper.wrapInactiveEnt[0].customIndex.split('.')[0]));
    //                     }else{
    //                         finalMap.set(currentItemWrapper.wrapInactiveEnt[0].customIndex.split('.')[0],currentItemWrapper);
    //                     }
    //             }                 
    //         }
      if (currentItemWrapper.wrapUpgradeEnt != undefined && currentItemWrapper.wrapUpgradeEnt.length > 0) {
                rowFound = mapFinalWrapper(currentItemWrapper.wrapUpgradeEnt[0],currentDataMap);  
                if(!finalMap.has(currentItemWrapper.wrapUpgradeEnt[0].customIndex.split('.')[0])){
                        if(rowFound == true){
                            finalMap.set(currentItemWrapper.wrapUpgradeEnt[0],currentDataMap.get(currentItemWrapper.wrapUpgradeEnt[0].customIndex.split('.')[0]));
                        }else{
                            finalMap.set(currentItemWrapper.wrapUpgradeEnt[0].customIndex.split('.')[0],currentItemWrapper);
                    } 
                }   
            }
    });
    
    for (const value of finalMap.values()) {
        finalWrapperList.push(value);
    }
     return finalWrapperList;   
}

function mapFinalWrapper(currentItem,currentDataMap){   
    let rowFound = false;
        if(currentDataMap.has(currentItem.customIndex.split('.')[0])){
                rowFound = true;
        }
    return rowFound;
}