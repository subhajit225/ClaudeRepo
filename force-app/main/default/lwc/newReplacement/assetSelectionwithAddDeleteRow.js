//Handle on asset change - start
export function handleSelectedAssetChange(parentOptionSelection, customIndex, displayedData,entitlementId,keyIdentifier) {
    let wrapperData = JSON.parse(JSON.stringify(displayedData));
    wrapperData.forEach(currentItem => {

        //Added for FY25SR-1207 - START
        if(currentItem.customIndex != undefined && currentItem.mapAssetEntitlements != undefined 
            && currentItem.customIndex === customIndex ){
                // code to clone the future transaction wrapper
                currentItem.mapAssetEntitlements = selectedAssetForLicense(parentOptionSelection, customIndex, currentItem.mapAssetEntitlements, true,entitlementId,keyIdentifier);

        }
        //Added for FY25SR-1207 - END

        //Base License
        //FY25SR-2112
        if(currentItem.wrapBaseLicense != undefined) {
            let nrd = false;
            currentItem.wrapBaseLicense.forEach(currItem => {
                    if(currItem.entitlementName.includes('-NRD-')){
                        nrd = true;
                        currentItem.disableAssets = true;
                    }
            });
            if(nrd == false){
                currentItem.wrapBaseLicense = selectedAssetForLicense(parentOptionSelection, customIndex, currentItem.wrapBaseLicense,false);
            }
        }
        //FY25SR-2112
        //Add ons
        if(currentItem.wrapAddOnSupportLines != undefined){
            currentItem.wrapAddOnSupportLines = selectedAssetForLicense(parentOptionSelection, customIndex, currentItem.wrapAddOnSupportLines,false);
        }
        //Upgrade
        if(currentItem.wrapUpgradeEnt != undefined){
            currentItem.wrapUpgradeEnt = selectedAssetForLicense(parentOptionSelection, customIndex, currentItem.wrapUpgradeEnt,false);
        }
    });  
    return wrapperData;
}
  
function selectedAssetForLicense(parentOptionSelection, customIndex,  licenseData, isFutureTransaction,entitlementId,keyIdentifier) {

     //Added for FY25SR-1207 - START
    if(isFutureTransaction){
        licenseData = selectedAssetForLicenseForFutureTransaction(parentOptionSelection, customIndex,  licenseData,entitlementId,keyIdentifier);
        return licenseData;
    }
     //Added for FY25SR-1207 - END

    let foundRowIndex = licenseData.findIndex(item => item.customIndex === customIndex);
    if(foundRowIndex != -1) {
        let row = licenseData[foundRowIndex];
        if(row.rowSelected) {
            row.isModified = true;
        } 
        if(row.tphTypeEntitlement != undefined && row.tphTypeEntitlement == false){   //FY25SR-1557
            if(parentOptionSelection.action === 'add') {
                let assetIndex = row.assetsAvailable.findIndex(asset => asset.value === parentOptionSelection.value);
                if(assetIndex != -1) {
                row.assetsAvailable[assetIndex].selected = true;
                row.selectedquantity = getUpdatedQTY(row.assetsAvailable, row); //FY25SR-1096, added parameter "row"
                row.showAdd = setShowAdd(row.assetsAvailable);
                row.errors = '';
                licenseData[foundRowIndex] = row; 
                licenseData = removeAssetFromList(parentOptionSelection, foundRowIndex, licenseData); 
                }
            } else {
                let assetIndex = row.assetsAvailable.findIndex(asset => asset.value === parentOptionSelection.value);
                if(assetIndex != -1) {
                row.assetsAvailable[assetIndex].selected = false;
                licenseData[foundRowIndex] = row; 
                row.selectedquantity = getUpdatedQTY(row.assetsAvailable, row); //FY25SR-1096, added parameter "row"
                row.showAdd = setShowAdd(row.assetsAvailable);
                for(let i in licenseData) {
                    let unselectedAssetList = row.assetsAvailable.filter(assetRow => assetRow.selected === false);
                    addAssetToList(licenseData[i] , unselectedAssetList); 
                    licenseData[i].showAdd = setShowAdd(licenseData[i].assetsAvailable);
                    licenseData[i].errors = '';
                }
                }
            }
        }
        
    }
    return licenseData;
}

 //Added for FY25SR-1207
function selectedAssetForLicenseForFutureTransaction(parentOptionSelection, customIndex,  row,entitlementId,keyIdentifier) {
    row.futureValues.forEach(currItem => {
        if(currItem.assetsAvailable != undefined && currItem.assetsAvailable.length > 0 
        ){
            if(currItem.keyIdentifier === keyIdentifier ){ 
                if(currItem.tphTypeEntitlement != undefined && !currItem.tphTypeEntitlement){   //FY25SR-1557
                    if(parentOptionSelection.action === 'add') {
                        let assetIndex = currItem.assetsAvailable.findIndex(asset => asset.value === parentOptionSelection.value);
                        
                        if(assetIndex != -1) {
                            currItem.assetsAvailable[assetIndex].selected = true;
                            currItem.selectedquantity = getUpdatedQTY(currItem.assetsAvailable, currItem);
                            currItem.showAdd = setShowAdd(currItem.assetsAvailable);
                            currItem.disableQuantity = false;
                            currItem.isModified = true;
                            currItem.errors = '';
                        }
                        let assetIndexDisplayList = currItem.newAssetList.findIndex(asset => asset.value === parentOptionSelection.value);
                        if(assetIndexDisplayList != -1){
                            currItem.newAssetList[assetIndexDisplayList].selected = true;
                            currItem.disableQuantity = false;
                        }
                    } else {
                        let assetIndex = currItem.assetsAvailable.findIndex(asset => asset.value === parentOptionSelection.value);
                        if(assetIndex != -1) {
                            currItem.assetsAvailable[assetIndex].selected = false;
                            currItem.selectedquantity = getUpdatedQTY(currItem.assetsAvailable, currItem);
                            currItem.showAdd = setShowAdd(currItem.assetsAvailable);
                            currItem.isModified = true;
                            currItem.errors = '';
                        }
                        let assetIndexDisplayList = currItem.newAssetList.findIndex(asset => asset.value === parentOptionSelection.value);
                        if(assetIndexDisplayList != -1){
                            currItem.newAssetList[assetIndexDisplayList].selected = false;
                        }
                    }
                }
            }
        }
    });
    return row;
}

function removeAssetFromListForFutureTransaction(parentOptionSelection,  currItem) {
            let newAssetList = currItem.assetsAvailable.filter(asset => asset.value !== parentOptionSelection.value);
            currItem.assetsAvailable = newAssetList;
            currItem.selectedquantity = getUpdatedQTY(newAssetList);
            currItem.showAdd = setShowAdd(newAssetList);
            currItem.errors = '';
    return currItem;
}

function removeAssetFromList(parentOptionSelection, skipRow,  licenseData) {
    for(let index in licenseData) {
        if(index != skipRow && licenseData[index].entitlementId === licenseData[skipRow].entitlementId) {
            let newAssetList = licenseData[index].assetsAvailable.filter(asset => asset.value !== parentOptionSelection.value);
            licenseData[index].assetsAvailable = newAssetList;
            licenseData[index].selectedquantity = getUpdatedQTY(newAssetList, licenseData[index]); //FY25SR-1096, added parameter "licenseData"
            licenseData[index].showAdd = setShowAdd(newAssetList);
            licenseData[index].errors = '';
            licenseData[index].keyIdentifier = createIdentifierKey(licenseData[index].assetsAvailable);
        }
    }
    return licenseData;
}
  
//FY25SR-1096, added parameter "wrapElement"
function getUpdatedQTY(assetList, wrapElement) {
    let totalQty = 0;
    for(let asset of assetList) {
        if(asset.value === 'Full' && asset.selected) {
            //FY25SR-1096, added parameter "wrapElement"
            totalQty = setmaxAllquantityFull(assetList, wrapElement);
            break;
        } else {
            if(asset.selected && asset.value !== 'Full' ) {
                //FY25SR-1096, added RBK check
                if (wrapElement.entitlementName.startsWith('RBK')) {
                    totalQty = totalQty + wrapElement.quantity;
                } else {
                    totalQty = totalQty + asset.quantity;
                }
            }
        }
    }
    return totalQty;
}

//FY25SR-1096, added parameter "wrapElement" 
function setmaxAllquantityFull(receivedData, wrapElement) {
    let maxAllquantityFull = 0;
    receivedData.forEach((element) => {
        if (element.value != 'Full') {
            //FY25SR-1096, added RBK check
            if (wrapElement.entitlementName.startsWith('RBK')) {
                maxAllquantityFull = maxAllquantityFull + wrapElement.quantity;
            }  else {
                maxAllquantityFull = maxAllquantityFull + element.quantity;
            }
        }
    });
    return maxAllquantityFull;
}
  
function setShowAdd(assetList) {
    let showAddDisabled = false;
    for(let asset of assetList) {
        if(asset.selected && asset.value === 'Full') {
            showAddDisabled = false;
            break;
        } 
        if(!asset.selected && asset.value !== 'Full') {
            showAddDisabled = true;
        }
    }
    return showAddDisabled;
}
//Handle on asset change - end
//Handle Delete row - start
export function hanleDeleteRow(customIndex,dataModified,keyIdentifier, exceptionMessage) {
    let displayedData = JSON.parse(JSON.stringify(dataModified));
    let newWrapperList = [];
    displayedData.forEach(function (currentItemWrapper, index){
        // Added as part of FY25SR-1207 - START
        //Future Transactions
        if(currentItemWrapper.mapAssetEntitlements != undefined && customIndex === currentItemWrapper.customIndex){
            currentItemWrapper.mapAssetEntitlements.futureValues = updateAssetOptionsForFutureTransactions(currentItemWrapper.mapAssetEntitlements.futureValues,keyIdentifier);
            
        }
        // Added as part of FY25SR-1207 - END

        //Base Product
        if(currentItemWrapper.wrapBaseLicense != undefined) {
            if(checkIfIndexPresent(currentItemWrapper.wrapBaseLicense,customIndex)) {
                currentItemWrapper.wrapBaseLicense = updateAssetOptions(
                    customIndex, currentItemWrapper.wrapBaseLicense, exceptionMessage);
            }
        }
        // //HW Support
       
        //Addons
        if(currentItemWrapper.wrapAddOnSupportLines != undefined){
            if(checkIfIndexPresent(currentItemWrapper.wrapAddOnSupportLines,customIndex)) {
                currentItemWrapper.wrapAddOnSupportLines = updateAssetOptions(
                    customIndex, currentItemWrapper.wrapAddOnSupportLines, exceptionMessage);
            }
        }
        
        //upgrade
        if(currentItemWrapper.wrapUpgradeEnt != undefined){
            if(checkIfIndexPresent(currentItemWrapper.wrapUpgradeEnt,customIndex)) {
                currentItemWrapper.wrapUpgradeEnt = updateAssetOptions(
                    customIndex, currentItemWrapper.wrapUpgradeEnt, exceptionMessage);
            }
        }
        newWrapperList.push(currentItemWrapper);
    });
    
    let newList = setShowAddFalseForHwSupport(newWrapperList);
    return newList;
}

function checkIfIndexPresent(currentItemWrapper, customIndex ) {
    return currentItemWrapper.find(ele => ele.customIndex === customIndex);
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

// Added as part of FY25SR-1207 - Start
function updateAssetOptionsForFutureTransactions(licenseList, keyIdentifier) {
    let newLicenseList = [];
    let displayedData = JSON.parse(JSON.stringify(licenseList));
    let findRow = displayedData.filter(row => row.keyIdentifier === keyIdentifier);
    if(findRow) {
      //For Asset Based
      for(let i in displayedData) {
        if(displayedData[i].keyIdentifier != keyIdentifier) {
            findRow.forEach(findRowElement => {
                    //Asset based
                    if(findRowElement.assetsAvailable && findRowElement.assetsAvailable.length > 0) {
                        displayedData[i].showAdd = true;
                        findRowElement.assetsAvailable.forEach(asset=> {
                            let hasAssets = displayedData[i].assetsAvailable.find(originalAsset => originalAsset.value === asset.value);
                            if(!hasAssets) {
                                asset.selected = false;
                                displayedData[i].assetsAvailable.push(asset);
                            }
                        });
                        findRowElement.newAssetList.forEach(asset=> {
                            let hasAssets = displayedData[i].newAssetList.find(originalAsset => originalAsset.value === asset.value);
                            if(!hasAssets) {
                                asset.selected = false;
                                displayedData[i].newAssetList.push(asset);
                            }
                        });
                    } else { //Non asset based
                    }
            });
            displayedData[i].errors = '';
            newLicenseList.push(displayedData[i]);
        }
      }
      let totalSelectedQTY = quantityTotal(newLicenseList);
      let newAssetList = []
      for(let i in newLicenseList) {
        newLicenseList[i].consumedquantity = parseInt(totalSelectedQTY);
        newLicenseList[i].errors = '';
        newLicenseList[i].isModified = true;
        newLicenseList[i].newAssetList.forEach(asset => {
            newAssetList.push(asset);
        });
      }

        let keyIdentifierNew = createIdentifierKey(newAssetList);

    }
    return newLicenseList;
}
// Added as part of FY25SR-1207 - END

function updateAssetOptions(customIndex, licenseList, exceptionMessage) {
    let newLicenseList = [];
    let displayedData = JSON.parse(JSON.stringify(licenseList));
    let findRow = displayedData.find(row => row.customIndex === customIndex);
    let exactCustomIndexToAddQTY = customIndex.split('.')[0] + '.' + customIndex.split('.')[1] + '.' + (customIndex.split('.')[2] - 1);
    let hasMismatchQTYAssets = false;
    if(findRow) {
      //For Asset Based
      for(let i in displayedData) {
        if(displayedData[i].entitlementId === findRow.entitlementId && displayedData[i].customIndex !== customIndex) {
            //Asset based
            if(findRow.assetsAvailable && findRow.assetsAvailable.length > 0) {
                displayedData[i].showAdd = true;
                addAssetToList(displayedData[i], findRow.assetsAvailable);
            } else { //Non asset based
                if(displayedData[i].customIndex === exactCustomIndexToAddQTY) {    //FY25SR-1084 START                
                    if(displayedData[i].skuAttributesToQuoteLine != undefined && displayedData[i].skuAttributesToQuoteLine != null && displayedData[i].skuAttributesToQuoteLine != 'null'){
                        if(!displayedData[i].skuAttributesToQuoteLine.hasOwnProperty('Salesforce_Quantity__c') &&
                                !displayedData[i].skuAttributesToQuoteLine.hasOwnProperty('Rubrik_Hosted_M365_Quantity__c') &&
                                !displayedData[i].skuAttributesToQuoteLine.hasOwnProperty('Atlassian_Quantity__c') &&
                                !displayedData[i].skuAttributesToQuoteLine.hasOwnProperty('Dynamics_Quantity__c') &&
                                !displayedData[i].skuAttributesToQuoteLine.hasOwnProperty('Google_Workspace_Quantity__c')){
                                        displayedData[i].selectedquantity = parseInt(displayedData[i].selectedquantity) + parseInt(findRow.selectedquantity);
                                }
						}
					}//FY25SR-1084 END
                }
            displayedData[i].errors = '';
            if(checkifNonAssetToNonAsset(displayedData[i], exceptionMessage)) {
                hasMismatchQTYAssets = true;
            }
            newLicenseList.push(displayedData[i]);
        }
      }
      let totalSelectedQTY = quantityTotal(newLicenseList);
      for(let i in newLicenseList) {
        if(!hasMismatchQTYAssets) {
            newLicenseList[i].showAdd = totalSelectedQTY < parseInt(findRow.selectedMaxquantity) ? true : false;
        }
        newLicenseList[i].consumedquantity = parseInt(totalSelectedQTY);
        newLicenseList[i].customIndex = createNewCustomIndex(customIndex , i);
        newLicenseList[i].errors = '';
        newLicenseList[i].isModified = true;
      }
    }
    return newLicenseList;
}

function quantityTotal(licenseList) {
  let totalSelectedQTY = 0;
  for(let i in licenseList) {
    totalSelectedQTY += parseInt(licenseList[i].selectedquantity);
  }
  return totalSelectedQTY;
}

function addAssetToList(dataRow , assetList) {
    assetList.forEach(asset=> {
      let hasAssets = dataRow.assetsAvailable.find(originalAsset => originalAsset.value === asset.value);
      if(!hasAssets) {
        asset.selected = false;
        dataRow.assetsAvailable.push(asset);
      }
    });
}
//Handle Delete row - end

function fetchRowId(customIndex, lastIndex) {
  let mainIndex = '';
  for(var i=0 ; i<lastIndex-1 ; i++) {
    mainIndex = mainIndex === '' 
      ? mainIndex + customIndex.split('.')[i] 
      : mainIndex + '.' + customIndex.split('.')[i];
  }
  return mainIndex;
}

//Handle Add Row - start
export function handleAddRow(customIndex,dataModified,quoteType,entitlementId,keyIdentifier, dnc, disableValidations, quotelineFieldApi) {
    let displayedData = JSON.parse(JSON.stringify(dataModified));
    let isFutureTransactionAdded = false;
    let newCustomIndex;
    let additionalWrapper;
    displayedData.forEach((currentItemWrapper, index) => {
        //Added for FY25SR-1207 - START
        if(currentItemWrapper.customIndex != undefined && currentItemWrapper.mapAssetEntitlements != undefined 
            && currentItemWrapper.customIndex === customIndex ){
                // code to clone the future transaction wrapper
                
                let customTemp = currentItemWrapper.mapAssetEntitlements.futureValues.find(element => element.keyIdentifier === keyIdentifier);
                let newAssetList = [];
                let mapN = new Map();
                let preLength = currentItemWrapper.mapAssetEntitlements.futureValues.length;
                let rowId = '';
                currentItemWrapper.mapAssetEntitlements.futureValues.forEach(function (currentItem, index){
                    if(currentItem.keyIdentifier === keyIdentifier){
                        rowId = fetchRowId(currentItem.customIndex,currentItem.customIndex.split('.').length);
                    }
                });
                
                currentItemWrapper.mapAssetEntitlements = addRowForFutureTransaction(customIndex, currentItemWrapper.mapAssetEntitlements, quoteType,keyIdentifier,entitlementId, dnc,disableValidations);
                currentItemWrapper.mapAssetEntitlements.futureValues.forEach(function (currentItem, index){
                    currentItem.showAdd = false;
                    currentItem.errors = '';
                    if(!currentItem.quantityAssetType){
                        currentItem.assetsAvailable = handleAddRowAssetAvailable(currentItem.assetsAvailable, false);
                        currentItem.newAssetList = handleAddRowAssetAvailable(currentItem.newAssetList, false);
                        currentItem.selectedquantity = getNewAssetQuantity(currentItem.assetsAvailable,currentItem);
                        if(currentItem.customIndex.startsWith(rowId)){
                            currentItem.newAssetList.forEach(asset => {
                                if(!mapN.has(asset.label)){
                                    mapN.set(asset.label,asset);
                                    newAssetList.push(asset);
                                }
                            });
                        }
                    }
                });
                let keyIdentifierNew = createIdentifierKey(newAssetList);

                currentItemWrapper.mapAssetEntitlements.futureValues.forEach(function (currentItem, index){
                    if(!currentItem.quantityAssetType){
                        if(currentItem.customIndex.startsWith(rowId)){
                            currentItem.keyIdentifier = keyIdentifierNew;
                        }
                    }
                });

        }
        //Added for FY25SR-1207 - END

        if(currentItemWrapper.wrapBaseLicense != undefined && currentItemWrapper.wrapBaseLicense.length > 0){
            currentItemWrapper.wrapBaseLicense = addRow(customIndex, currentItemWrapper.wrapBaseLicense, quoteType, dnc,disableValidations, quotelineFieldApi);
        }
        if(currentItemWrapper.wrapHWSupportLines != undefined && currentItemWrapper.wrapHWSupportLines.length > 0){
            currentItemWrapper.wrapHWSupportLines = addRow(customIndex, currentItemWrapper.wrapHWSupportLines, quoteType, dnc,disableValidations, quotelineFieldApi);
        }
        if(currentItemWrapper.wrapInactiveEnt != undefined && currentItemWrapper.wrapInactiveEnt.length > 0){
            currentItemWrapper.wrapInactiveEnt = addRow(customIndex, currentItemWrapper.wrapInactiveEnt, quoteType, dnc,disableValidations, quotelineFieldApi);
        }
        if(currentItemWrapper.wrapUpgradeEnt != undefined &&  currentItemWrapper.wrapUpgradeEnt.length > 0){
            currentItemWrapper.wrapUpgradeEnt = addRow(customIndex, currentItemWrapper.wrapUpgradeEnt, quoteType, dnc,disableValidations, quotelineFieldApi);
        }
        if(currentItemWrapper.wrapAddOnSupportLines != undefined &&   currentItemWrapper.wrapAddOnSupportLines.length > 0){
            currentItemWrapper.wrapAddOnSupportLines = addRow(customIndex, currentItemWrapper.wrapAddOnSupportLines, quoteType, dnc,disableValidations, quotelineFieldApi);
        }
    });
    //Added for FY25SR-1207 - START
    let newWrapperList = [];
    if(isFutureTransactionAdded){   
        displayedData.forEach(currentItemWrapper => {
            if(currentItemWrapper.customIndex != undefined &&
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
        });

    } else {
        newWrapperList = JSON.parse(JSON.stringify(displayedData));
    }
    //Added for FY25SR-1207 - END
    return newWrapperList;
}

//Added as part of FY25SR-1207 - Start
function addRowForFutureTransaction(customIndex, mapData, quoteType,keyIdentifier, dnc,disableValidations, quotelineFieldApi) {
        let newList = [];
        let newKey = '';
        let newMap = new Map(Object.entries(mapData));
        let i = 1;
        let j = 0;
        let assetsList = [];
        let customI;
        mapData.futureValues.forEach(function (currentItem, index){
            if(currentItem.keyIdentifier === keyIdentifier){
                customI = currentItem.customIndex.split('.')[2];
            }
        });
       mapData.futureValues.forEach(function (currentItem, index){
            if(currentItem.keyIdentifier === keyIdentifier){
                let newCustomIndex = createNewCustomIndex(customIndex, mapData.futureValues.length) ;
                let newRow = createNewRow(currentItem, newCustomIndex, quoteType, dnc,disableValidations, quotelineFieldApi);
                newRow.disableQuantity = currentItem.disableQuantity;
                newRow.showAdd = false;
                newRow.disableTerm = false;
                let splittedCustomIndex = currentItem.customIndex.split('.');
                newRow.customIndex = splittedCustomIndex[0] + '.' + splittedCustomIndex[1] + '.' + (parseInt(customI) + 1) + '.' + j;
                if(!newRow.quantityAssetType){
                    newRow.assetsAvailable = handleAddRowAssetAvailable(currentItem.assetsAvailable, true);
                    newRow.newAssetList = handleAddRowAssetAvailable(currentItem.newAssetList, true);
                    newRow.newAssetList.forEach(asset => {
                        assetsList.push(asset);
                    });
                    newRow.selectedquantity = getNewAssetQuantity(newRow.assetsAvailable,newRow);
                } else {
                    newRow = setnonAssetBasedQuantity(newRow,currentItem);
                }    
                newList.push(newRow);
                j++;
            }
        });
        newKey = createIdentifierKey(assetsList);
        newList[0].rowspan = newList.length;
        newList.forEach(currentItem => {
            currentItem.keyIdentifier = newKey;
        });

        let listValues = mapData.futureValues.concat(newList); 
        newMap.futureValues = listValues;   
        return newMap;
}
//Added as part of FY25SR-1207 - END

function addRow(customIndex, licensedData, quoteType, dnc,disableValidations, quotelineFieldApi) {
    let wrapperData = JSON.parse(JSON.stringify(licensedData));
    let hasRowIndex = wrapperData.findIndex(row => row.customIndex === customIndex);
    if(hasRowIndex !== -1) {
      let newCustomIndex = createNewCustomIndex(customIndex, wrapperData.length) ;
      let newRow = createNewRow(wrapperData[hasRowIndex], newCustomIndex, quoteType, dnc,disableValidations, quotelineFieldApi);
      newRow.showAdd = false;
      if(!newRow.quantityAssetType){
        newRow.assetsAvailable = handleAddRowAssetAvailable(wrapperData[hasRowIndex].assetsAvailable, true);
        newRow.selectedquantity = getNewAssetQuantity(newRow.assetsAvailable, newRow);  //FY25SR-1096, added parameter "newRow"
      } else {
        newRow.disableQuantity = false;
        newRow = setnonAssetBasedQuantity(newRow,wrapperData[hasRowIndex]);
      }
      
      for(let data of wrapperData) {
        data.showAdd = false;
        data.errors = '';
        if(!newRow.quantityAssetType){
            data.assetsAvailable = handleAddRowAssetAvailable(data.assetsAvailable, false);
            data.selectedquantity = getNewAssetQuantity(data.assetsAvailable, data); //FY25SR-1096, added parameter "data"
        }
      }
      wrapperData.push(newRow);
     
    }
    wrapperData = sortList(wrapperData);
    return wrapperData;
}

function sortList(wrapperData) {
    return wrapperData.sort((a, b) => parseInt(a.customIndex.split('.').join('')) - parseInt(b.customIndex.split('.').join('')));
}
function handleAddRowAssetAvailable(availableAssets, isRemoveAsset) {
    let availableAssetList = JSON.parse(JSON.stringify(availableAssets));
    let newAssetList = [];
    if(isRemoveAsset) {
        newAssetList = availableAssetList.filter(asset => asset.selected === false && asset.value !== 'Full');
        newAssetList.forEach(asset => {
            asset.selected = true;
        });
    } else {
        newAssetList = availableAssetList.filter(asset => asset.selected === true);
    }
    return newAssetList;
}

function setnonAssetBasedQuantity(additionalWrapper,currentItem){
    additionalWrapper.selectedquantity = parseInt(currentItem.selectedMaxquantity) - parseInt(currentItem.consumedquantity);
    additionalWrapper.consumedquantity = parseInt(currentItem.selectedMaxquantity) - parseInt(currentItem.consumedquantity);
    return additionalWrapper;
}

function createNewCustomIndex(customIndex,wrapperLength){
    return customIndex.split('.')[0] + '.'  + customIndex.split('.')[1] + '.'  + (parseInt(wrapperLength));
}

//FY25SR-1096, added parameter "wrapElement"
function getNewAssetQuantity(newAssetsAvailable, wrapElement){
    let newAssetQuantity = 0;
    newAssetsAvailable.forEach(currentItemAdd => {
        //FY25SR-1096 - Added logic for RBK
        if (wrapElement.entitlementName.startsWith('RBK')) {
            newAssetQuantity = newAssetQuantity + wrapElement.quantity;
        } else {
            newAssetQuantity = parseInt(newAssetQuantity) + parseInt(currentItemAdd.quantity);
        }
   });
    return newAssetQuantity
}

function createNewRow(itemToClone,customindex, quoteType, dnc, disableValidations, quotelineFieldApi){
    let additionalWrapper = Object.create(itemToClone);
    additionalWrapper.doNotConsolidateEnt = dnc; //FY25SR-1124
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
    //FY25SR-1557 START 
    additionalWrapper.tphTypeEntitlement = itemToClone.tphTypeEntitlement;
    additionalWrapper.tphQuantity = itemToClone.tphQuantity;
    additionalWrapper.tphOEM = itemToClone.tphOEM;
    additionalWrapper.tphModels = itemToClone.tphModels;
    //FY25SR-1557 END 
    additionalWrapper.skuProdRepCategory = '';
    additionalWrapper.skuProdType = '';
    additionalWrapper.skuProdLicenseType = '';
    additionalWrapper.skuProdLicenseCategory = '';
    additionalWrapper.skuProdLicenseSubCategory = '';
    additionalWrapper.skuProdPaymentOption = '';
    additionalWrapper.skuProdCodeType = itemToClone.skuProdCodeType;
    additionalWrapper.skuProdName = '';
    additionalWrapper.skuProductId = ''; 
    additionalWrapper.setRowColor = itemToClone.setRowColor;
    additionalWrapper.isReplaceableProduct = itemToClone.isReplaceableProduct;
    additionalWrapper.rowSelected = itemToClone.rowSelected;
    additionalWrapper.oldProductEdition = itemToClone.oldProductEdition;
    additionalWrapper.SrprodRepCategory = itemToClone.SrprodRepCategory;
    additionalWrapper.originalQuoteLineIdForEnt = itemToClone.originalQuoteLineIdForEnt;
    additionalWrapper.selecteddisposition = '';  
    additionalWrapper.disableDisposition = false;
    additionalWrapper.productId = itemToClone.productId;
    additionalWrapper.consumedquantity = itemToClone.consumedquantity;
    additionalWrapper.autoDisposition = createAutoDisposItion(itemToClone, disableValidations,quoteType);
    additionalWrapper.manualDisposition = createManualDisposItion(itemToClone, disableValidations,quoteType);
    additionalWrapper.renLine = itemToClone.renLine;
    // Added this method as part of FY25SR-1215
    additionalWrapper.disableTerm = itemToClone.disableTerm;
    additionalWrapper.renewalEndDate = itemToClone.renewalEndDate;
    additionalWrapper.disableRenewalEndDate = itemToClone.disableRenewalEndDate;
    additionalWrapper.previousRenewalEndDate = itemToClone.previousRenewalEndDate; //FY25SR-2349
    if(itemToClone.quantityAssetType != undefined && itemToClone.quantityAssetType == true){
        additionalWrapper.targetProductType = 'Non-Hardware';
    }else if(itemToClone.quantityAssetType != undefined && itemToClone.quantityAssetType == false){
        additionalWrapper.targetProductType = 'Hardware';
    }
   
    additionalWrapper.disableQuantity = itemToClone.disableQuantity;
    additionalWrapper.previousReplacementTerm = itemToClone.previousReplacementTerm;
    additionalWrapper.previousRemainingTerm = itemToClone.previousRemainingTerm;
    additionalWrapper.skuAttributesToQuoteLine = null;
    additionalWrapper.disableAssets = itemToClone.disableAssets;
    additionalWrapper.serviceContractId = itemToClone.serviceContractId;
    additionalWrapper.serviceContractName = itemToClone.serviceContractName;
    additionalWrapper.v1Product = itemToClone.v1Product; //FY25SR-2232
    additionalWrapper.srProdType = itemToClone.srProdType;//FY25SR-2232
    additionalWrapper.srPaymentType = itemToClone.srPaymentType;
    additionalWrapper.srRenewedProduct = itemToClone.srRenewedProduct;
    additionalWrapper.srCustomRenewedProduct = itemToClone.srCustomRenewedProduct;
     //FY25SR-2361 - start
    let mapQLAttributes = {};
    if(quotelineFieldApi != null && quotelineFieldApi!= undefined 
      && itemToClone.skuAttributesToQuoteLine != null && itemToClone.skuAttributesToQuoteLine != undefined) {
        quotelineFieldApi.forEach(element => {
            if(itemToClone.skuAttributesToQuoteLine.hasOwnProperty(element) && element !== 'snapshotId') {
                mapQLAttributes[element] = itemToClone.skuAttributesToQuoteLine[element];
            }
        });
        additionalWrapper.skuAttributesToQuoteLine = mapQLAttributes;
    }
    //FY25SR-2361 -End
    additionalWrapper.disableSKU = itemToClone.disableSKU;//FY25SR-2388
    return additionalWrapper;
}

function createManualDisposItion(itemToClone, disableValidations,quoteType){
    let manualClone = JSON.parse(JSON.stringify(itemToClone.manualDisposition));
    let autoClone = JSON.parse(JSON.stringify(itemToClone.autoDisposition));
    manualClone.forEach(currItem=> {
            currItem.selected = false;
    });
    return manualClone;
    
}

function createAutoDisposItion(itemToClone, disableValidations,quoteType){
    let autoClone = JSON.parse(JSON.stringify(itemToClone.autoDisposition));
    autoClone.forEach(currItem=> {
            currItem.selected = false;
    });
    return autoClone;
}

//Added as part of FY25SR-1207 - START - Ankita
function createIdentifierKey(assetList) {
    let identifierKey = '';
    let selectedAssets = [];
    assetList.forEach(asset => {
        if(asset.selected && asset.value !== 'Full' && !selectedAssets.includes(asset.label)) {
            selectedAssets.push(asset.label);
        }
    });
    if(selectedAssets.length > 0) {
        identifierKey = selectedAssets.join(',');
    }
    return identifierKey;
}
//Added as part of FY25SR-1207 - END - Ankita
//Handle add row- end


function checkifNonAssetToNonAsset(currentItemWrapper, exceptionMessage) {
    var hasMismatchException = checkHasMismatchExceptionSelected(exceptionMessage);
    if(currentItemWrapper.quantityAssetType && 
        currentItemWrapper.targetProductType != null && 
        currentItemWrapper.targetProductType != undefined && 
        currentItemWrapper.targetProductType === 'Non-Hardware' &&
        currentItemWrapper.skuProductId != null && 
        currentItemWrapper.skuProductId != undefined && 
        currentItemWrapper.skuProductId != '' &&
        hasMismatchException) {
        return true;
    } 
    return false;
}


function checkHasMismatchExceptionSelected(exceptionOptions) {
    let mismatchExceptionMessage = 'Mismatch Quantity';
    if(exceptionOptions) {
      let isMismatchSelected = exceptionOptions.find(ele => ele.selected 
        && isEqualStrings(ele.value, mismatchExceptionMessage));
      if(isMismatchSelected != null && isMismatchSelected != undefined){
        return true;
      }
    }
    return false;
  }
  
// FY25SR-2024 
function isEqualStrings(itemValue, tocompare) {
return itemValue.trim().toLowerCase() === tocompare.trim().toLowerCase();
}