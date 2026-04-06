//refactored
export function addRow(customIndex,dataModified,quoteType) {
    let displayedData = JSON.parse(JSON.stringify(dataModified));
    let iswrapBaseLicenseProduct = false;
    let iswrapHWSupportLinesProduct = false;
    let isstandAloneProduct = false;
    let iswrapInactiveEntProduct = false;
    let iswrapUpgradeEntProduct = false;
    let iswrapAddOnSupportLinesProduct = false;
    let newWrapperList = [];
    let additionalWrapper;
    let newCustomIndex;

    displayedData.forEach((currentItemWrapper, index) => {
            if(currentItemWrapper.customIndex != undefined && currentItemWrapper.customIndex === customIndex){
                isstandAloneProduct = true;
                newCustomIndex = currentItemWrapper.customIndex.split('.')[0] + '.' 
                                + currentItemWrapper.customIndex.split('.')[1] + '.' 
                                + (parseInt(currentItemWrapper.customIndex.split('.')[2]) + 1);
                additionalWrapper = createNewRow(currentItemWrapper,newCustomIndex,quoteType);

                //sets assets for new record 
                if(!currentItemWrapper.quantityAssetType){

                    //Set the selectedquantity and assetsAvailable on the additionalWrapper
                    additionalWrapper = setSelectedquantityAndassetsAvailableOnAdditionalWrapperForAssetBasedEnt(additionalWrapper,currentItemWrapper);
                    additionalWrapper.showAdd = newAssetsAvailable.length > 1 ? true : false;

                    let assetsToRemove = getAssetsList(currentItemWrapper.assetsAvailable , true);
                    //reassign the assets after removal
                    currentItemWrapper.assetsAvailable = assetsToRemove;

                } else {
                    //Set the selectedquantity and consumedquantity on the additionalWrapper
                    additionalWrapper = setSelectedAndConsumedQuantityOnAdditionalWrapperForNonAssetBasedEnt(additionalWrapper,currentItemWrapper);
                }
            }
            if(currentItemWrapper.wrapBaseLicense != undefined && currentItemWrapper.wrapBaseLicense.length > 0){
                currentItemWrapper.wrapBaseLicense.forEach(function (currentItemBaseLicence, index){
                    if(currentItemBaseLicence.customIndex === customIndex){
                        iswrapBaseLicenseProduct = true;
                        
                        newCustomIndex = createNewCustomIndex(currentItemBaseLicence.customIndex,currentItemWrapper.wrapBaseLicense.length);
                        additionalWrapper = createNewRow(currentItemBaseLicence,newCustomIndex,quoteType);

                        //sets assets for new record 
                        if(!currentItemBaseLicence.quantityAssetType){
                            //Set the selectedquantity and assetsAvailable on the additionalWrapper
                            additionalWrapper = setSelectedquantityAndassetsAvailableOnAdditionalWrapperForAssetBasedEnt(additionalWrapper,currentItemBaseLicence);

                            let assetsToRemove = getAssetsList(currentItemBaseLicence.assetsAvailable , true);
                            //reassign the assets after removal
                            currentItemBaseLicence.assetsAvailable = assetsToRemove;

                        } else {
                           //Set the selectedquantity and consumedquantity on the additionalWrapper
                           additionalWrapper = setSelectedAndConsumedQuantityOnAdditionalWrapperForNonAssetBasedEnt(additionalWrapper,currentItemBaseLicence);
                        }
                    }
                });
            }
            if(currentItemWrapper.wrapHWSupportLines != undefined && currentItemWrapper.wrapHWSupportLines.length > 0){
                currentItemWrapper.wrapHWSupportLines.forEach(function (currentItemHWLicence, index){
                    if(currentItemHWLicence.customIndex === customIndex){
                        iswrapHWSupportLinesProduct = true;

                        newCustomIndex = createNewCustomIndex(currentItemHWLicence.customIndex,currentItemWrapper.wrapHWSupportLines.length);
                        additionalWrapper = createNewRow(currentItemHWLicence,newCustomIndex,quoteType);

                        //sets assets for new record 
                        if(!currentItemHWLicence.quantityAssetType){


                            //Set the selectedquantity and assetsAvailable on the additionalWrapper
                            additionalWrapper = setSelectedquantityAndassetsAvailableOnAdditionalWrapperForAssetBasedEnt(additionalWrapper,currentItemHWLicence);

                            let assetsToRemove = getAssetsList(currentItemHWLicence.assetsAvailable , true);
                            //reassign the assets after removal
                            currentItemHWLicence.assetsAvailable = assetsToRemove;
                        } else {
                            //Set the selectedquantity and consumedquantity on the additionalWrapper
                            additionalWrapper = setSelectedAndConsumedQuantityOnAdditionalWrapperForNonAssetBasedEnt(additionalWrapper,currentItemHWLicence);
                        }
                    }
                });
            }

            if(currentItemWrapper.wrapInactiveEnt != undefined && currentItemWrapper.wrapInactiveEnt.length > 0){
                currentItemWrapper.wrapInactiveEnt.forEach(function (currentItemInactiveEnt, index){
                    if(currentItemInactiveEnt.customIndex === customIndex){
                        iswrapInactiveEntProduct = true;

                        newCustomIndex = createNewCustomIndex(currentItemInactiveEnt.customIndex,currentItemWrapper.wrapInactiveEnt.length);
                        additionalWrapper = createNewRow(currentItemInactiveEnt,newCustomIndex,quoteType);
                        //sets assets for new record 
                        if(!currentItemInactiveEnt.quantityAssetType){
                            //Set the selectedquantity and assetsAvailable on the additionalWrapper
                            additionalWrapper = setSelectedquantityAndassetsAvailableOnAdditionalWrapperForAssetBasedEnt(additionalWrapper,currentItemInactiveEnt);

                            let assetsToRemove = getAssetsList(currentItemInactiveEnt.assetsAvailable , true);
                            //reassign the assets after removal
                            currentItemInactiveEnt.assetsAvailable = assetsToRemove;
                            

                        } else {
                            //Set the selectedquantity and consumedquantity on the additionalWrapper
                            additionalWrapper = setSelectedAndConsumedQuantityOnAdditionalWrapperForNonAssetBasedEnt(additionalWrapper,currentItemInactiveEnt);
                        }
                    }
                });
            }
            if(currentItemWrapper.wrapUpgradeEnt != undefined &&  currentItemWrapper.wrapUpgradeEnt.length > 0){
                currentItemWrapper.wrapUpgradeEnt.forEach(function (currentItemwrapUpgradeEnt, index){
                    if(currentItemwrapUpgradeEnt.customIndex === customIndex){
                        iswrapUpgradeEntProduct = true;

                        newCustomIndex = createNewCustomIndex(currentItemwrapUpgradeEnt.customIndex,currentItemWrapper.wrapUpgradeEnt.length);
                        additionalWrapper = createNewRow(currentItemwrapUpgradeEnt,newCustomIndex,quoteType);

                        //sets assets for new record 
                        if(!currentItemwrapUpgradeEnt.quantityAssetType){
                            //Set the selectedquantity and assetsAvailable on the additionalWrapper
                            additionalWrapper = setSelectedquantityAndassetsAvailableOnAdditionalWrapperForAssetBasedEnt(additionalWrapper,currentItemwrapUpgradeEnt);

                            let assetsToRemove = getAssetsList(currentItemwrapUpgradeEnt.assetsAvailable , true);
                            //reassign the assets after removal
                            currentItemwrapUpgradeEnt.assetsAvailable = assetsToRemove;
                            
                        } else {
                            //Set the selectedquantity and consumedquantity on the additionalWrapper
                            additionalWrapper = setSelectedAndConsumedQuantityOnAdditionalWrapperForNonAssetBasedEnt(additionalWrapper,currentItemwrapUpgradeEnt);
                        }
                    }
                });
            }
            if(currentItemWrapper.wrapAddOnSupportLines != undefined &&   currentItemWrapper.wrapAddOnSupportLines.length > 0){
                currentItemWrapper.wrapAddOnSupportLines.forEach(function (currentItemAddOnSupportLines, index){
                    if(currentItemAddOnSupportLines.customIndex === customIndex){
                        iswrapAddOnSupportLinesProduct = true;

                        newCustomIndex = createNewCustomIndex(currentItemAddOnSupportLines.customIndex,wrapAddOnSupportLines.wrapBaseLicense.length);
                        additionalWrapper = createNewRow(currentItemAddOnSupportLines,newCustomIndex,quoteType);
                        //sets assets for new record 
                        if(!currentItemAddOnSupportLines.quantityAssetType){
                            //Set the selectedquantity and assetsAvailable on the additionalWrapper
                            additionalWrapper = setSelectedquantityAndassetsAvailableOnAdditionalWrapperForAssetBasedEnt(additionalWrapper,currentItemAddOnSupportLines);

                            let assetsToRemove = getAssetsList(currentItemAddOnSupportLines.assetsAvailable , true);
                            //reassign the assets after removal
                            currentItemAddOnSupportLines.assetsAvailable = assetsToRemove;

                            
                        } else {
                            //Set the selectedquantity and consumedquantity on the additionalWrapper
                            additionalWrapper = setSelectedAndConsumedQuantityOnAdditionalWrapperForNonAssetBasedEnt(additionalWrapper,currentItemAddOnSupportLines);
                        }

                    }
                });
            }
            
    });

    displayedData.forEach((currentItemWrapper, index) => {
        if(isstandAloneProduct) {
            if(currentItemWrapper.customIndex != undefined 
                        (newCustomIndex === (currentItemWrapper.customIndex.split('.')[0] + '.' 
                                    + currentItemWrapper.customIndex.split('.')[1] + '.' 
                                    + (parseInt(currentItemWrapper.customIndex.split('.')[2]) + 1)))
            ){
                currentItemWrapper.showAdd = false;
                newWrapperList.push(currentItemWrapper);
                newWrapperList.push(additionalWrapper);
                }  else {
                    newWrapperList.push(currentItemWrapper);
                }          
                
                
        } else   
        if(iswrapBaseLicenseProduct) {
            if(currentItemWrapper.wrapBaseLicense != undefined) {
                currentItemWrapper.wrapBaseLicense = addLinesToExistingList(customIndex,additionalWrapper,currentItemWrapper.wrapBaseLicense);
            }
            newWrapperList.push(currentItemWrapper);
        } else
        if(iswrapHWSupportLinesProduct) {
            if(currentItemWrapper.wrapHWSupportLines != undefined){
                currentItemWrapper.wrapHWSupportLines = addLinesToExistingList(customIndex,additionalWrapper,currentItemWrapper.wrapHWSupportLines);
            }
            newWrapperList.push(currentItemWrapper);
        } else
        if(iswrapInactiveEntProduct) {
            if(currentItemWrapper.wrapInactiveEnt != undefined){
                currentItemWrapper.wrapInactiveEnt = addLinesToExistingList(customIndex,additionalWrapper,currentItemWrapper.wrapInactiveEnt);
            }

            newWrapperList.push(currentItemWrapper);
        } else
        if(iswrapUpgradeEntProduct) {
             if(currentItemWrapper.wrapUpgradeEnt != undefined){
                currentItemWrapper.wrapUpgradeEnt = addLinesToExistingList(customIndex,additionalWrapper,currentItemWrapper.wrapUpgradeEnt);
             }
            newWrapperList.push(currentItemWrapper);
        } else
        if(iswrapAddOnSupportLinesProduct) {
            if(currentItemWrapper.wrapAddOnSupportLines != undefined){
                currentItemWrapper.wrapAddOnSupportLines = addLinesToExistingList(customIndex,additionalWrapper,currentItemWrapper.wrapAddOnSupportLines);
            }
            newWrapperList.push(currentItemWrapper);
        } else {
            newWrapperList.push(currentItemWrapper);
        }
    });

    return newWrapperList;
}

function setSelectedquantityAndassetsAvailableOnAdditionalWrapperForAssetBasedEnt(additionalWrapper,currentItem){
    let newAssetsAvailable = getAssetsList(currentItem.assetsAvailable , false);
    additionalWrapper.selectedquantity = getNewAssetQuantity(newAssetsAvailable);
    additionalWrapper.assetsAvailable = newAssetsAvailable;
    return additionalWrapper;
}

function setSelectedAndConsumedQuantityOnAdditionalWrapperForNonAssetBasedEnt(additionalWrapper,currentItem){
    additionalWrapper.selectedquantity = parseInt(currentItem.selectedMaxquantity) - parseInt(currentItem.consumedquantity);
    additionalWrapper.consumedquantity = parseInt(currentItem.selectedMaxquantity) - parseInt(currentItem.consumedquantity);
    // additionalWrapper.consumedquantity = parseInt(additionalWrapper.selectedquantity) + parseInt(currentItem.consumedquantity);

    return additionalWrapper;
}

function createNewCustomIndex(customIndex,wrapperLength){
    return customIndex.split('.')[0] + '.'  + customIndex.split('.')[1] + '.'  + (parseInt(wrapperLength - 1) + 1);
}

function getNewAssetQuantity(newAssetsAvailable){
    let newAssetQuantity = 0;
    newAssetsAvailable.forEach(currentItemAdd => {
        newAssetQuantity = parseInt(newAssetQuantity) + parseInt(currentItemAdd.quantity);
    });
    return newAssetQuantity
}

function addLinesToExistingList(customIndex, additionalWrapper, currentItemWrapperList ){
    let childList = [];
    currentItemWrapperList.forEach(function (currentItem, index){
        if(currentItem.customIndex === customIndex){
            currentItem.showAdd = false;
            childList.push(currentItem);
            childList.push(additionalWrapper);
        } else {
            childList.push(currentItem);
        }
    });
    return childList.sort((a, b) => parseInt(a.customIndex.split('.').join('')) - parseInt(b.customIndex.split('.').join('')));
}

function getAssetsList(assetsList, removeList){
    let newList = [];
    assetsList.forEach((currentItemAdd) => {
        if (!currentItemAdd.selected && !removeList && currentItemAdd.value != 'Full') {
            let newWrapper = Object.create(currentItemAdd);
            newWrapper.selected = true;
            newWrapper.value = currentItemAdd.value;
            newWrapper.label = currentItemAdd.label;
            newWrapper.entitlementId = currentItemAdd.entitlementId;
            newWrapper.entitlementName = currentItemAdd.entitlementName;
            newWrapper.quantity = currentItemAdd.quantity;
            newList.push(newWrapper);
        } else if (currentItemAdd.selected && removeList) {
            let newWrapper = Object.create(currentItemAdd);
            newWrapper.selected = true;
            newWrapper.value = currentItemAdd.value;
            newWrapper.label = currentItemAdd.label;
            newWrapper.entitlementId = currentItemAdd.entitlementId;
            newWrapper.entitlementName = currentItemAdd.entitlementName;
            newWrapper.quantity = currentItemAdd.quantity;
            newList.push(newWrapper);
        }
    });

    return newList;
}

function createNewRow(itemToClone,customindex, quoteType){
    let additionalWrapper = Object.create(itemToClone);
    additionalWrapper.errors = '';
    additionalWrapper.customIndex = customindex;
    additionalWrapper.isModified = true;
    additionalWrapper.entitlementOrderNumber = itemToClone.entitlementOrderNumber;
    additionalWrapper.assetsAvailable = itemToClone.assetsAvailable;
    additionalWrapper.entitlementName = itemToClone.entitlementName;
    additionalWrapper.entitlementId = itemToClone.entitlementId;
    additionalWrapper.quantity = itemToClone.quantity;
    additionalWrapper.StartDate = itemToClone.StartDate;
    additionalWrapper.EndDate = itemToClone.EndDate;
    // additionalWrapper.showAdd = true;
    additionalWrapper.showDelete = true;   
    additionalWrapper.SrprodLicSubCategoryVal = itemToClone.SrprodLicSubCategoryVal;
    additionalWrapper.srSuppType = itemToClone.srSuppType;
    additionalWrapper.showSelectCheckBox = false;
    additionalWrapper.selectedMaxquantity = itemToClone.selectedMaxquantity;
    additionalWrapper.selectedquantity = itemToClone.selectedquantity;
    additionalWrapper.quantityAssetType = itemToClone.quantityAssetType;
    additionalWrapper.ReplacementTerm = itemToClone.ReplacementTerm;
    additionalWrapper.TargetProductDefaultTerm = itemToClone.TargetProductDefaultTerm;
    additionalWrapper.RemainingTerm = itemToClone.RemainingTerm;
    additionalWrapper.ReplacementCategory = itemToClone.ReplacementCategory;
    additionalWrapper.skuProdRepCategory = '';
    additionalWrapper.skuProdType = '';
    additionalWrapper.skuProdLicenseType = '';
    additionalWrapper.skuProdLicenseCategory = '';
    additionalWrapper.skuProdLicenseSubCategory = '';
    additionalWrapper.skuProdPaymentOption = '';
    additionalWrapper.skuProdCodeType = '';
    additionalWrapper.skuProdName = '';
    additionalWrapper.skuProductId = ''; 
    additionalWrapper.setRowColor = itemToClone.setRowColor;
    additionalWrapper.isReplaceableProduct = itemToClone.isReplaceableProduct;
    additionalWrapper.rowSelected = itemToClone.rowSelected;
    additionalWrapper.oldProductEdition = itemToClone.oldProductEdition;
    additionalWrapper.SrprodRepCategory = itemToClone.SrprodRepCategory;
    additionalWrapper.selecteddisposition = '';  
    additionalWrapper.originalQuoteLineIdForEnt = itemToClone.originalQuoteLineIdForEnt;
    additionalWrapper.disableDisposition = false;
    additionalWrapper.productId = itemToClone.productId;
    additionalWrapper.consumedquantity = itemToClone.consumedquantity;
    additionalWrapper.autoDisposition = createAutoDisposItion(quoteType);
    additionalWrapper.manualDisposition = createManualDisposItion(quoteType);
    additionalWrapper.renLine = itemToClone.renLine;
    // Added this method as part of FY25SR-1215
    additionalWrapper.disableTerm = false;
    // additionalWrapper.renewalEndDate = itemToClone.renewalEndDate;
    additionalWrapper.disableRenewalEndDate = true;
    additionalWrapper.disableQuantity = false;
    additionalWrapper.previousReplacementTerm = itemToClone.previousReplacementTerm;
    additionalWrapper.previousRemainingTerm = itemToClone.previousRemainingTerm;
    return additionalWrapper;
}

function createManualDisposItion(quoteType){
    if (quoteType === 'Renewal+Expansion') {
      return [
        { label: 'Renew Now', value: 'Renewing', selected : false },
        { label: 'Renew Later', value: 'Renew Later', selected : false },
        { label: 'At Risk', value: 'At Risk' , selected : false}
      ];
    } else if (quoteType === 'Renewal') {
      return [
        { label: 'Renew Now', value: 'Renewing', selected : false },
        { label: 'Churn', value: 'Churn', selected : false },
        { label: 'At Risk', value: 'At Risk' , selected : false}
      ];
    }
    
}

function createAutoDisposItion(quoteType){
    if (quoteType === 'Renewal+Expansion') {
    return [
        { label: 'Conversion', value: 'Converted', selected : false },
        { label: 'Refresh', value: 'Refreshed', selected : false },
        { label: 'Upgrade', value: 'Upgraded', selected : false }
      ];
    }else if (quoteType === 'Renewal') {
      return [
        { label: 'Renew Now', value: 'Renewing', selected : false }        
      ];
    }
}

//refactored
export function deleteRow(customIndex,dataModified) {
    let displayedData = JSON.parse(JSON.stringify(dataModified));
    let newWrapperList = [];
    let standAloneList = [];
    
    // Get the list of assets from the deleted row
    let deletedAssetList = getDeletedAssetList(displayedData,customIndex);
    // Get the Quantity from the deleted row
    let deletedEntQuantity = getdeletedEntQuantity(displayedData,customIndex);

    let exactCustomIndexToAddTheAssets = customIndex.split('.')[0] + '.' + customIndex.split('.')[1] + '.' + (customIndex.split('.')[2] - 1);
    displayedData.forEach(function (currentItemWrapper, index){
        if(currentItemWrapper.customIndex != undefined && currentItemWrapper.customIndex != customIndex){
            standAloneList.push(currentItemWrapper);
        } else if(currentItemWrapper.customIndex === undefined) { //if(!currentItemWrapper.standAlone)
            //Base Product
            if(currentItemWrapper.wrapBaseLicense != undefined){
                if(checkIfIndexPresent(currentItemWrapper.wrapBaseLicense,customIndex)) {
                    currentItemWrapper.wrapBaseLicense = setAssetsAndQuantityForDeleteAndUpdateIconVisibility(customIndex, currentItemWrapper.wrapBaseLicense, deletedAssetList,deletedEntQuantity,exactCustomIndexToAddTheAssets);
                }
            }
            
            //HW Support
            if(currentItemWrapper.wrapHWSupportLines != undefined){
                if(checkIfIndexPresent(currentItemWrapper.wrapHWSupportLines,customIndex)) {
                    currentItemWrapper.wrapHWSupportLines = setAssetsAndQuantityForDeleteAndUpdateIconVisibility(customIndex, currentItemWrapper.wrapHWSupportLines, deletedAssetList,deletedEntQuantity,exactCustomIndexToAddTheAssets);
                }
            }
            
            //Addons
            if(currentItemWrapper.wrapAddOnSupportLines != undefined){
                if(checkIfIndexPresent(currentItemWrapper.wrapAddOnSupportLines,customIndex)) {
                    currentItemWrapper.wrapAddOnSupportLines = setAssetsAndQuantityForDeleteAndUpdateIconVisibility(customIndex, currentItemWrapper.wrapAddOnSupportLines, deletedAssetList,deletedEntQuantity,exactCustomIndexToAddTheAssets);
                }
            }
            
            //Inactive
            if(currentItemWrapper.wrapInactiveEnt != undefined){
                if(checkIfIndexPresent(currentItemWrapper.wrapInactiveEnt,customIndex)) {
                    currentItemWrapper.wrapInactiveEnt = setAssetsAndQuantityForDeleteAndUpdateIconVisibility(customIndex, currentItemWrapper.wrapInactiveEnt, deletedAssetList,deletedEntQuantity,exactCustomIndexToAddTheAssets);
                }
            }
            
            //upgrade
            if(currentItemWrapper.wrapUpgradeEnt != undefined){
                if(checkIfIndexPresent(currentItemWrapper.wrapUpgradeEnt,customIndex)) {
                    currentItemWrapper.wrapUpgradeEnt = setAssetsAndQuantityForDeleteAndUpdateIconVisibility(customIndex, currentItemWrapper.wrapUpgradeEnt, deletedAssetList,deletedEntQuantity,exactCustomIndexToAddTheAssets);
                }
            }
            newWrapperList.push(currentItemWrapper);
        }
    });
    if(standAloneList) {
        standAloneList = updateAddIconVisiblity(standAloneList, customIndex);
        standAloneList.forEach(function(element) {
            element.selectedquantity = parseInt(element.selectedquantity) + parseInt(deletedEntQuantity);
            if(parseInt(element.consumedquantity) >= parseInt(deletedEntQuantity)){
                element.consumedquantity = parseInt(element.consumedquantity) - parseInt(deletedEntQuantity);
            } else {
                element.consumedquantity = parseInt(element.selectedMaxquantity) - parseInt(element.selectedquantity);
            }
            if(parseInt(element.selectedquantity) === parseInt(element.selectedMaxquantity)){
                element.showAdd = false;
            }    
            newWrapperList.push(element);
        });
    }

    let newList = setShowAddFalseForHwSupport(newWrapperList);
    return newList;
}

function setAssetsAndQuantityForDeleteAndUpdateIconVisibility(customIndex, currentItemWrapper, deletedAssetList,deletedEntQuantity,exactCustomIndexToAddTheAssets){
    let childList = [];
    childList = setAssetsAndQuantityForDelete(currentItemWrapper, customIndex, deletedAssetList, deletedEntQuantity, exactCustomIndexToAddTheAssets);
    childList = updateAddIconVisiblity(childList , customIndex);
    return childList;
}

function setAssetsAndQuantityForDelete(currentItemWrapper, customIndex, deletedAssetList, deletedEntQuantity, exactCustomIndexToAddTheAssets){
    let newList = [];
    currentItemWrapper.forEach(function (element, index){
        if(element.customIndex != customIndex) {
            if( exactCustomIndexToAddTheAssets === element.customIndex){
                element.showAdd = true;
                element.isModified = true;
                if(element.assetsAvailable != undefined && deletedAssetList != undefined && element.assetsAvailable.length > 0 && deletedAssetList.length > 0){
                    element.assetsAvailable = addDeletedAssets(deletedAssetList,element.assetsAvailable);
                } else { //FY25SR-1084 Start
                    if(element.skuAttributesToQuoteLine != undefined && element.skuAttributesToQuoteLine != null && element.skuAttributesToQuoteLine != 'null'){
                        if(!element.skuAttributesToQuoteLine.hasOwnProperty('Salesforce_Quantity__c') &&
                                !element.skuAttributesToQuoteLine.hasOwnProperty('Rubrik_Hosted_M365_Quantity__c') &&
                                !element.skuAttributesToQuoteLine.hasOwnProperty('Atlassian_Quantity__c') &&
                                !element.skuAttributesToQuoteLine.hasOwnProperty('Dynamics_Quantity__c') &&
                                !element.skuAttributesToQuoteLine.hasOwnProperty('Google_Workspace_Quantity__c')){
                                        element.selectedquantity = parseInt(element.selectedquantity) + parseInt(deletedEntQuantity);
                                }
                    }//FY25SR-1084 end
                }
            }
            newList.push(element);
        }
    });

    newList.forEach(element => {
        if(element.assetsAvailable === undefined || element.quantityAssetType){
            element.consumedquantity = calculateConsumedQuantity(newList,customIndex);
        }
    });
    return newList;
}

function calculateConsumedQuantity(currentItemWrapper,customIndex){
    let consumedQuantity = 0;
    currentItemWrapper.forEach(function (element, index){
        // if(element.customIndex != customIndex) {
            // if( element.customIndex != customIndex){
                consumedQuantity = parseInt(consumedQuantity) + parseInt(element.selectedquantity)
            // }
        // }
    });
    return consumedQuantity;
}

function updateAddIconVisiblity(listToUpdate, customIndex) {
    let resultList = [];
    const mapData = new Map();
    // Iterate over the list to populate the Map
    listToUpdate.forEach(element => {
        var key = element.customIndex.split('.')[0] + '.' + element.customIndex.split('.')[1] ;
        if (mapData.has(key)) {
            mapData.get(key).push(element);
        } else {
            var tempList = [];
            tempList.push(element);
            mapData.set(key, tempList);
        }
    });

    // Iterating over the Map to rewrite the customIndex
    mapData.forEach((value, key) => {
        for(var i=0 ; i<value.length ; i++) {
            value[i].customIndex = value[i].customIndex.split('.')[0] + '.'
                + value[i].customIndex.split('.')[1] + '.'
                + i;
            value[i].showAdd = false;
            if(value[i].quantityAssetType 
                && (
                        (value[i].consumedquantity === 0 || value[i].consumedquantity < value[i].selectedMaxquantity) 
                        // && value[i].selectedquantity != value[i].selectedMaxquantity 
                    )       
            ){
                value[i].showAdd = true;
            } else {
                value[i].assetsAvailable.forEach(asset => {
                    if(!asset.selected){
                        value[i].showAdd = true;
                    }
                });

                value[i].assetsAvailable.forEach(asset => {
                    // if(asset.selected == true && asset.label === 'Full'){
                    if(asset.label === 'Full'){
                        value[i].showAdd = false;
                    }
                    
                });
            }
            resultList.push(value[i]);
        }
        
    });
    return resultList;
}

function setShowAddFalseForHwSupport(newWrapperList){

    newWrapperList.forEach(currentItemWrapper => {
        //HW Support
        if(currentItemWrapper.wrapHWSupportLines != undefined){
            currentItemWrapper.wrapHWSupportLines.forEach(function (element, index){
                element.showAdd = false;
            });
        }
    });
    return newWrapperList;
}

function checkIfIndexPresent(currentItemWrapper, customIndex ) {
    return currentItemWrapper.find(ele => ele.customIndex === customIndex);
}

function getDeletedAssetList(displayedData,customIndex){
    let deletedAssets = [];
    displayedData.forEach(function (currentItemWrapper, index) {
        if (currentItemWrapper.quantityAssetType != undefined && !currentItemWrapper.quantityAssetType && currentItemWrapper.customIndex != undefined && currentItemWrapper.customIndex === customIndex) {
            if(element.assetsAvailable != undefined && element.assetsAvailable.length > 0){
                currentItemWrapper.assetsAvailable.forEach(function (currItem, index) {
                    deletedAssets.push(currItem);
                });
            }
        } else {
            //Base Product
            if(currentItemWrapper.wrapBaseLicense != undefined){
                if(checkIfIndexPresent(currentItemWrapper.wrapBaseLicense,customIndex)) {
                    deletedAssets = getListAssetsDeleted(customIndex, currentItemWrapper.wrapBaseLicense);
                }
            }

            //HW Support
            if(currentItemWrapper.wrapHWSupportLines != undefined){
                if(checkIfIndexPresent(currentItemWrapper.wrapHWSupportLines,customIndex)) {
                    deletedAssets = getListAssetsDeleted(customIndex, currentItemWrapper.wrapHWSupportLines);
                }
            }

            //Addons
            if(currentItemWrapper.wrapAddOnSupportLines != undefined){
                if(checkIfIndexPresent(currentItemWrapper.wrapAddOnSupportLines,customIndex)) {
                    deletedAssets = getListAssetsDeleted(customIndex, currentItemWrapper.wrapAddOnSupportLines);
                }
            }

            //Inactive
            if(currentItemWrapper.wrapInactiveEnt != undefined){
                if(checkIfIndexPresent(currentItemWrapper.wrapInactiveEnt,customIndex)) {
                    deletedAssets = getListAssetsDeleted(customIndex, currentItemWrapper.wrapInactiveEnt);
                }
            }

            //upgrade
            if(currentItemWrapper.wrapUpgradeEnt != undefined){
                if(checkIfIndexPresent(currentItemWrapper.wrapUpgradeEnt,customIndex)) {
                    deletedAssets = getListAssetsDeleted(customIndex, currentItemWrapper.wrapUpgradeEnt);
                }
            }
        }
    });

    return deletedAssets;
}

function getListAssetsDeleted(customIndex, currentItemWrapper){
    let deletedAssets = [];
    currentItemWrapper.forEach(function (element, index){
        if(!element.quantityAssetType) {
            if(customIndex === element.customIndex){  
                if(element.assetsAvailable != undefined && element.assetsAvailable.length > 0){
                    element.assetsAvailable.forEach(currItem => {
                        deletedAssets.push(currItem);
                    });
                }
            }
        }
    });
    return deletedAssets;
}

function getdeletedEntQuantity(displayedData,customIndex){
    let quantityDeleted = 0;
    displayedData.forEach(function (currentItemWrapper, index) {
        if (currentItemWrapper.quantityAssetType != undefined && currentItemWrapper.quantityAssetType && currentItemWrapper.customIndex != undefined && currentItemWrapper.customIndex === customIndex) {
            quantityDeleted = parseInt(quantityDeleted) + parseInt(currentItemWrapper.selectedquantity);  
        } else {
            //Base Product
            if(currentItemWrapper.wrapBaseLicense != undefined){
                if(checkIfIndexPresent(currentItemWrapper.wrapBaseLicense,customIndex)) {
                    quantityDeleted = getDeletedQuantity(customIndex,currentItemWrapper.wrapBaseLicense);
                }
            }

            //HW Support
            if(currentItemWrapper.wrapHWSupportLines != undefined){
                if(checkIfIndexPresent(currentItemWrapper.wrapHWSupportLines,customIndex)) {
                    quantityDeleted = getDeletedQuantity(customIndex,currentItemWrapper.wrapHWSupportLines);
                }
            }

            //Addons
            if(currentItemWrapper.wrapAddOnSupportLines != undefined){
                if(checkIfIndexPresent(currentItemWrapper.wrapAddOnSupportLines,customIndex)) {
                    quantityDeleted = getDeletedQuantity(customIndex,currentItemWrapper.wrapAddOnSupportLines);
                }
            }

            //Inactive
            if(currentItemWrapper.wrapInactiveEnt != undefined){
                if(checkIfIndexPresent(currentItemWrapper.wrapInactiveEnt,customIndex)) {
                    quantityDeleted = getDeletedQuantity(customIndex,currentItemWrapper.wrapInactiveEnt);
                }
            }

            //upgrade
            if(currentItemWrapper.wrapUpgradeEnt != undefined){
                if(checkIfIndexPresent(currentItemWrapper.wrapUpgradeEnt,customIndex)) {
                    quantityDeleted = getDeletedQuantity(customIndex,currentItemWrapper.wrapUpgradeEnt);
                }
            }
        }
    });

    return quantityDeleted;
}

function getDeletedQuantity(customIndex, currentItemWrapper){
    let quantityDeleted = 0;
    currentItemWrapper.forEach(function (element, index){
        if(element.quantityAssetType) {
            if(customIndex === element.customIndex){  
                quantityDeleted = parseInt(quantityDeleted) + parseInt(element.selectedquantity);  
            }
        }
    });
    return quantityDeleted;
}

function addDeletedAssets(deletedAssets,assetsAvailable){

    let tempSelectedAssets = assetsAvailable;
    deletedAssets.forEach(function (currItem, index) {
        currItem.selected = false;
        tempSelectedAssets.push(currItem);
    });

    return tempSelectedAssets.filter((value, index, self) => index === self.findIndex((t) => t.value === value.value));
}

function calculateQuantityConsumed(customIndex, dataModified){
  let consumedQuantity = 0;
  dataModified.forEach(currentItemWrapper => {
    if(currentItemWrapper.customIndex != undefined){
      if(customIndex.split('.')[0] + '.' + customIndex.split('.')[1] === currentItemWrapper.customIndex.split('.')[0] + '.' + currentItemWrapper.customIndex.split('.')[1]){
          consumedQuantity = parseInt(consumedQuantity) + parseInt(currentItemWrapper.selectedquantity);
      }
    } else {
        //Base Product
        if(currentItemWrapper.wrapBaseLicense != undefined){
            if(checkIfIndexPresent(currentItemWrapper.wrapBaseLicense,customIndex)){
                consumedQuantity = getConsumedQuantity(customIndex, currentItemWrapper.wrapBaseLicense);
            }
        }

        //HW Support
        if(currentItemWrapper.wrapHWSupportLines != undefined){
            if(checkIfIndexPresent(currentItemWrapper.wrapHWSupportLines,customIndex)){
                consumedQuantity = getConsumedQuantity(customIndex, currentItemWrapper.wrapHWSupportLines);
            }
        }

        //Addons
        if(currentItemWrapper.wrapAddOnSupportLines != undefined){
            if(checkIfIndexPresent(currentItemWrapper.wrapAddOnSupportLines,customIndex)){
                consumedQuantity = getConsumedQuantity(customIndex, currentItemWrapper.wrapAddOnSupportLines);
            }
        }
        //Inactive
        if(currentItemWrapper.wrapInactiveEnt != undefined){
            if(checkIfIndexPresent(currentItemWrapper.wrapInactiveEnt,customIndex)){
                consumedQuantity = getConsumedQuantity(customIndex, currentItemWrapper.wrapInactiveEnt);
            }
        }
        //upgrade
        if(currentItemWrapper.wrapUpgradeEnt != undefined){
            if(checkIfIndexPresent(currentItemWrapper.wrapUpgradeEnt,customIndex)){
                consumedQuantity = getConsumedQuantity(customIndex, currentItemWrapper.wrapUpgradeEnt);
            }
        }
    }
  });
  return consumedQuantity;
}

function getConsumedQuantity(customIndex, currentItemWrapper){
    let consumedQuantity = 0;
    let customIndexSplitted = customIndex.split('.')[0] + '.' + customIndex.split('.')[1];
    currentItemWrapper.forEach(function (element, index){
        if(customIndexSplitted === element.customIndex.split('.')[0] + '.' + element.customIndex.split('.')[1]){
            consumedQuantity = parseInt(consumedQuantity) + parseInt(element.selectedquantity);
        }
    });
    return consumedQuantity;
}