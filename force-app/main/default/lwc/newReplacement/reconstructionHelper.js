export function mergePrefilData(entilementList, prefillData, dnc, anytoany, quoteType) {
  let mergedList = [];
  let mapRowIdToIsPartail = new Map();
  let mapKeyIdentifierByRowId = new Map();
  let isFutureTransac = false;
  let hwAssetSKUMap = new Map();
  entilementList.forEach(dataRow => {
    mergedList.push(dataRow);
  });
  prefillData.forEach(ibmVal => {
    const { rowValues } = ibmVal;
    if(rowValues) {
    rowValues.forEach(row => {
        if(row.entId && row.disposition != null) {
        if (mapRowIdToIsPartail.has(row.entId)) {
            mapRowIdToIsPartail.set(row.entId, true);
        } else {
            mapRowIdToIsPartail.set(row.entId, false);
        }
          //Create Map for keyIdentifier
          let partialRowId = fetchRowId(row.rowId, row.rowId.split('.').length);
          let keyValue = '';
          
          if(mapKeyIdentifierByRowId.has(partialRowId)) {
            keyValue = mapKeyIdentifierByRowId.get(partialRowId);
            let ketIdentifierSet = fetchAssetList(row.selectedAsset, row.selectedAssetList, keyValue); 
            keyValue +=  ketIdentifierSet.join(',').length > 0 ? ','+ ketIdentifierSet.join(',') : '';
            mapKeyIdentifierByRowId.set(partialRowId, keyValue);
          } else {
            let ketIdentifierSet = fetchAssetList(row.selectedAsset, row.selectedAssetList, keyValue); 
            keyValue += ketIdentifierSet.join(',');
            mapKeyIdentifierByRowId.set(partialRowId, keyValue);
          }
      } 
    });
      //Iterate on ibm data again for HW asset collection
      if(ibmVal.skuSelected) {
        hwAssetSKUMap = fetchHWAssets(ibmVal, prefillData, hwAssetSKUMap);
      }
    }
  });
  
  prefillData.forEach(ibmVal => {
      const prefillRow = ibmVal;
      if(prefillRow) {
        mergedList.forEach(dataRow => {
          if(dataRow.wrapBaseLicense) {
            let wrapBaseLicense = _innerPrefillData(dataRow.wrapBaseLicense, prefillRow, mapKeyIdentifierByRowId, isFutureTransac, hwAssetSKUMap, dnc, anytoany, quoteType);
            dataRow.wrapBaseLicense = wrapBaseLicense;
          }
          if(dataRow.wrapHWSupportLines) {
            let wrapHWSupportLines = _innerPrefillData(dataRow.wrapHWSupportLines, prefillRow, mapKeyIdentifierByRowId, isFutureTransac, hwAssetSKUMap, dnc, anytoany, quoteType);
            dataRow.wrapHWSupportLines = wrapHWSupportLines;
          }
          if(dataRow.wrapUpgradeEnt) {
            let wrapUpgradeEnt = _innerPrefillData(dataRow.wrapUpgradeEnt, prefillRow, mapKeyIdentifierByRowId, isFutureTransac, hwAssetSKUMap, dnc, anytoany, quoteType);
            dataRow.wrapUpgradeEnt = wrapUpgradeEnt;
          }
          //FY25SR-1658 - Start
          if(dataRow.mapAssetEntitlements) {
            let mapAssetEntitlementsValues = _innerPrefillData(dataRow.mapAssetEntitlements.futureValues, prefillRow, mapKeyIdentifierByRowId, !isFutureTransac, hwAssetSKUMap, dnc, anytoany, quoteType);
            dataRow.mapAssetEntitlements.futureValues = mapAssetEntitlementsValues;
            dataRow.rowSelected = dataRow.mapAssetEntitlements.futureValues.findIndex(ent => ent.rowSelected == true) !== -1;
            if(dataRow.rowSelected) {
              dataRow.mapAssetEntitlements.futureValues = updateSelectionForFutureTransaction(dataRow.rowSelected, dataRow.mapAssetEntitlements.futureValues);
            }
          }//FY25SR-1658 - End
        });
      }
  });
  mergedList = sortBySelected(mergedList, mapRowIdToIsPartail);
  return mergedList;
}

function updateSelectionForFutureTransaction(rowSelected, modifiedData) {
  if(modifiedData) {
    for(let i=0 ; i<modifiedData.length ; i++) {
      modifiedData[i].rowSelected = rowSelected;
    }
  }
  return modifiedData;
}

function fetchAssetList(selectedAsset, selectedAssetList, keyValue) {
  let ketIdentifierSet = [];
  if(selectedAsset) {
    selectedAsset.split(',').forEach(asset => {
      if(!ketIdentifierSet.includes(selectedAssetList[asset]) && !keyValue.includes(selectedAssetList[asset])) {
        ketIdentifierSet.push(selectedAssetList[asset]);
      }
    });
  }
  return ketIdentifierSet;
}

function _innerPrefillData(innerTable, prefillRow, mapKeyIdentifierByRowId, isFutureTransac, hwAssetSKUMap, dnc, anytoany, quoteType) {
  let tempInnerTable = JSON.parse(JSON.stringify(innerTable));
  if(prefillRow.rowValues) {

  prefillRow.rowValues.forEach(rowValue => {
      const { entId, rowId, disposition} = rowValue;
    //FY25SR-1176 commented if(disposition === 'Refresh') return;
    //FY25SR-2298 
    var dataRow = innerTable.find(ent => 
                 (ent.entitlementId === entId || (quoteType === "Renewal" && ent.wrapInactiveEnt?.some(wrap => wrap.entitlementId === entId))) 
                 && (disposition !== undefined && disposition != null));
    if(dataRow) {
      if(rowId) {
        //FY25SR-1176 added log
        const lastIndex = rowId.split('.').length; 
        const isOriginalRow = lastIndex < 4 
                          ? (rowId.split('.')[lastIndex - 1] === '0' && lastIndex < 4) 
                          : (rowId.split('.')[lastIndex - 2] === dataRow.customIndex.split('.')[lastIndex - 2]);
        //FY25SR-2298
        const indexExists = innerTable.findIndex(ent =>
              ent.entitlementId === entId ||
             (quoteType === "Renewal" && ent.wrapInactiveEnt?.some(wrap => wrap.entitlementId === entId))
            );
        if(isOriginalRow) {
          dataRow = _prefillRowData(innerTable[indexExists], prefillRow, rowValue, isFutureTransac, hwAssetSKUMap, dnc, anytoany, quoteType);
            var mainIndex = fetchRowId(innerTable[indexExists].customIndex, lastIndex);
            dataRow.keyIdentifier = mapKeyIdentifierByRowId.get(mainIndex);
          tempInnerTable[indexExists] = dataRow;
        } else {
            var mainIndex = fetchRowId(innerTable[indexExists].customIndex, lastIndex-1);
            var newIndex = '';
            if(lastIndex < 4) {
              mainIndex = mainIndex + '.' + rowId.split('.')[lastIndex-2];
            } else {
              mainIndex = mainIndex + '.' + rowId.split('.')[lastIndex-2];
            }
            newIndex = mainIndex + '.' + rowId.split('.')[lastIndex-1];
          // Add new item
          let newRow = JSON.parse(JSON.stringify(dataRow));
          newRow.customIndex = newIndex;
          newRow.showSelectCheckBox = false;
          newRow.showDelete = true;
          newRow = _prefillRowData(newRow, prefillRow, rowValue, isFutureTransac, hwAssetSKUMap, dnc, anytoany, quoteType);
            newRow.keyIdentifier = mapKeyIdentifierByRowId.get(mainIndex);
          newRow.wrapInactiveEnt = [];
          if (!tempInnerTable.some(r => r.customIndex === newRow.customIndex)) {
          tempInnerTable.push(newRow);
        }
      }
    }
    }
  });
  }
  innerTable = JSON.parse(JSON.stringify(tempInnerTable));
  innerTable.sort((a, b) => parseInt(a.customIndex.split('.').join('')) - parseInt(b.customIndex.split('.').join('')));
  return innerTable;
}

function fetchRowId(customIndex, lastIndex) {
  let mainIndex = '';
  for(var i=0 ; i<lastIndex-1 ; i++) {
    mainIndex = mainIndex === '' 
      ? mainIndex + customIndex.split('.')[i] 
      : mainIndex + '.' + customIndex.split('.')[i];
  }
  return mainIndex;
}

function _prefillRowData(dataRow, prefilledData, rowValue, isFutureTransac, hwAssetSKUMap, dnc, anytoany, quoteType) {
  var row = JSON.parse(JSON.stringify(dataRow));
  row.rowSelected = true;
  row.skuProductId = prefilledData.skuSelected;
  row.skuProdName = prefilledData.skuSelectedName;
 // row.skuSuppType = prefilledData.skuSuppType; //Added for FY25SR-1553
  //row.skuProdCodeType = prefilledData.skuProdCodeType//Added for FY25SR-1084
  if(rowValue.disposition) {
    //FY25SR-1176 added Refreshed
    if(rowValue.disposition === 'Upgraded' || rowValue.disposition === 'Converted' || rowValue.disposition === 'Refreshed' || (rowValue.disposition === 'Renewing' && rowValue.isAutoDisposition)) {
      row.disableDisposition = true;
      const indexExists = row.autoDisposition.findIndex(element => element.value === rowValue.disposition);
      row.autoDisposition[indexExists].selected = true;
    } else {
      row.disableDisposition = false;
      const indexExists = row.manualDisposition.findIndex(element => element.value === rowValue.disposition);
      row.manualDisposition[indexExists].selected = true;
    }
  }
  row.anyToAnyFlag = anytoany;
  //FY25SR-2232
  if(quoteType === 'Renewal'){
    row.anyToAnyFlag = false;
  }
  //FY25SR-2298 start
  let inActiveEntId = rowValue.entId;
  let isRenewalWithInactiveEnt = (quoteType === "Renewal" && row.wrapInactiveEnt != undefined && row.wrapInactiveEnt.length > 0 && row.wrapInactiveEnt?.some(wrap => wrap.entitlementId === inActiveEntId));
  //FY25SR-2298 end
  //FY25SR-2232
  row.selecteddisposition = rowValue.disposition;
  if(!row.entitlementName.includes('-HW-') && !isRenewalWithInactiveEnt){//FY25SR-2298 
    row.selectedquantity = rowValue.selectedQty;
  }
  row.ReplacementTerm = rowValue.selectedTerm;
  row.previousReplacementTerm = row.ReplacementTerm ;
  row.previousRemainingTerm = row.RemainingTerm; 
  
  // Change for FY25SR-1492 - End
  if (!row.quantityAssetType) {
    row.disableQuantity = !isFutureTransac;
    row.assetsAvailable = row.assetsAvailable.map((asset) => {
      if(rowValue.selectedAsset) {
        asset.selected = rowValue.selectedAsset.split(',').indexOf(asset.value) !== -1;
      }
      return asset;
    });
  }
  row.newAssetList = row.assetsAvailable;
  if (prefilledData.renLine) {
    row.setRowColor = 'background-color: #E8E8E8;';
    row.renLine = true;
  } else {
    row.renLine = false;
  }
  //FY25SR-1705 Start
  if(row.selectedAssetsFromNonAsset != undefined && row.selectedAssetsFromNonAsset.length > 0){
      let quantitySum = 0;
      row.selectedAssetsFromNonAsset.forEach(currItem =>{
        if(currItem.quantity != undefined && currItem.quantity >0){
            quantitySum = parseInt(quantitySum)+parseInt(currItem.quantity);
        }
      });
      if(parseInt(quantitySum) > 0){
          row.disableQuantity = true;
      }
    }
  //FY25SR-1705 End
  //Added for FY25SR-1084 - start
  if(prefilledData.dynamicFieldValues) {
    row.skuAttributesToQuoteLine = JSON.parse(JSON.stringify(prefilledData.dynamicFieldValues));
    if(row.skuAttributesToQuoteLine != undefined && row.skuAttributesToQuoteLine != null && row.skuAttributesToQuoteLine != 'null'){
      if(row.skuAttributesToQuoteLine.hasOwnProperty('Support_Type__c')){
          row.skuSuppType = row.skuAttributesToQuoteLine['Support_Type__c'];
      }
      if(row.skuAttributesToQuoteLine.hasOwnProperty('Product_Code_Type__c')){
          row.skuProdCodeType = row.skuAttributesToQuoteLine['Product_Code_Type__c'];
      }
      if(row.skuAttributesToQuoteLine.hasOwnProperty('Salesforce_Quantity__c') ||
        row.skuAttributesToQuoteLine.hasOwnProperty('Rubrik_Hosted_M365_Quantity__c') ||
        row.skuAttributesToQuoteLine.hasOwnProperty('Atlassian_Quantity__c') ||
        row.skuAttributesToQuoteLine.hasOwnProperty('Dynamics_Quantity__c') ||
        row.skuAttributesToQuoteLine.hasOwnProperty('Google_Workspace_Quantity__c')){
        row.disableQuantity = true;
      }
      if(row.skuAttributesToQuoteLine.hasOwnProperty('SBQQ__Product__r.Replacement_Category__c')){
        row.skuProdRepCategory = row.skuAttributesToQuoteLine['SBQQ__Product__r.Replacement_Category__c'];
      }
		}
    //Cutover activity
    if(rowValue.disposition === 'Renewing') {
      // Change for FY25SR-1492 - Start
      if(row.skuAttributesToQuoteLine.hasOwnProperty('SBQQ__EndDate__c')){
        const str = row.skuAttributesToQuoteLine['SBQQ__EndDate__c'];
        row.renewalEndDate = new Date(str.substring(0, 10));
        //FY25SR-2298 start if it has inactiveEntWrapper then inactiveEnt.EndDate ,row.renewalEndDate
        const inactiveEntDate = (quoteType === "Renewal"  && row.wrapInactiveEnt != undefined && row.wrapInactiveEnt.length > 0) ? row.wrapInactiveEnt.find(wrap => wrap.EndDate)?.EndDate : null;
        if(inactiveEntDate !=null){
          row.ReplacementTerm = calculateSubscriptionTerm(inactiveEntDate, row.renewalEndDate );
        }
        else{
          row.ReplacementTerm = calculateSubscriptionTerm(row.EndDate, row.renewalEndDate );
        } //FY25SR-2298 end
      }
      row.disableRenewalEndDate = false;
      if(row.renewalEndDate != null){
       // row.disableTerm = true;
      }
		}
  } 
  //Added for FY25SR-1084 - end
  //FY25SR-1705- Start
  row.targetProductType = prefilledData.targetProductType;
  let hwAssetNonAssetList = [];
  if(row.skuProductId != undefined) {
    var rowlength = row.customIndex.split('.').length;
    var newKey = row.entitlementId + '-'+ row.customIndex.split('.')[rowlength - 1];
    if(hwAssetSKUMap.has(newKey) ) {
      let hwAsset = hwAssetSKUMap.get(newKey);
      hwAsset.forEach(asset => {
        let assetInfo = 
        {
          "label": asset.skuSelectedName + '(' + asset.rowValues[0].selectedQty + ')',
          "value": asset.skuSelected,
          "quantity": asset.rowValues[0].selectedQty,
          "selected": true,
          "entCustomIndex": row.customIndex,
          "entitlementId": asset.rowValues[0].entId
        }
        hwAssetNonAssetList.push(assetInfo);
      });
    }
  }
  row.selectedAssetsFromNonAsset = hwAssetNonAssetList;
  //FY25SR-1705 - End
  
  //FY25SR-1124 
  if(row.skuProductId != undefined && row.skuProductId != null && 
    ((row.quantityAssetType == false && row.targetProductType != undefined && 
      row.targetProductType === 'Non-Hardware') || 
     (row.quantityAssetType == true && row.targetProductType != undefined && 
      row.targetProductType === 'Hardware'))){
          row.doNotConsolidateEnt = true;
  }else{
          row.doNotConsolidateEnt = dnc;
  }
  //FY25SR-1124 
  return row;
};

function sortBySelected(mergedList, mapRowIdToIsPartail) {
  const tempStore = [];
  const selectedRowsMap = new Map();
  const unselectedMergedList = [];
  var index = 0;
  for(var index=0 ; index< mergedList.length ; index++) {
    if(mergedList[index].wrapBaseLicense) {
      mergedList[index].wrapBaseLicense.forEach(dataRow => {
        if(dataRow.rowSelected) {
          if(!selectedRowsMap.has(index)) {
            selectedRowsMap.set(index, mergedList[index]);
          }
          dataRow = _updateAvailableAssets(dataRow, mapRowIdToIsPartail);
        }
      });
    }
    if(mergedList[index].wrapHWSupportLines) {
      mergedList[index].wrapHWSupportLines.forEach(dataRow => {
        if(dataRow.rowSelected) {
          if(!selectedRowsMap.has(index)) {
            selectedRowsMap.set(index, mergedList[index]);
          }
          dataRow = _updateAvailableAssets(dataRow, mapRowIdToIsPartail);
        }
      });
    }
    if(mergedList[index].wrapUpgradeEnt) {
      mergedList[index].wrapUpgradeEnt.forEach(dataRow => {
        if(dataRow.rowSelected) {
          if(!selectedRowsMap.has(index)) {
            selectedRowsMap.set(index, mergedList[index]);
          }
          dataRow = _updateAvailableAssets(dataRow, mapRowIdToIsPartail);
        }
      });
    }
    if(mergedList[index].mapAssetEntitlements) {
      mergedList[index].mapAssetEntitlements.futureValues.forEach(dataRow => {
        if(dataRow.rowSelected) {
          if(!selectedRowsMap.has(index)) {
            selectedRowsMap.set(index, mergedList[index]);
          }
          dataRow = _updateAvailableAssets(dataRow, mapRowIdToIsPartail);
        }
      });
    }
    if(!selectedRowsMap.has(index)) {
      unselectedMergedList.push(mergedList[index]);
    }
  }
  selectedRowsMap.forEach((value, key) => {
    tempStore.push(value);
  });
  unselectedMergedList.forEach(row => {
    tempStore.push(row);
  });
  return tempStore;
}


function _updateAvailableAssets(row, mapRowIdToIsPartail) {
  let newAssetList = [];
  if(mapRowIdToIsPartail.has(row.entitlementId) && mapRowIdToIsPartail.get(row.entitlementId)) {
    row.assetsAvailable.forEach(currAsset => {
      if(currAsset.selected && currAsset.value !== 'Full') {
        newAssetList.push(currAsset);
      }
      if(newAssetList.length > 0) {
        row.assetsAvailable = newAssetList;
      }
    });
  }
  row.newAssetList = row.assetsAvailable;
  return row;
}
export function seggregateDataForPage(prefillData) {
  let replacementData = [];
  let refreshData = [];
  let result = new Map();
  if(prefillData) {
    prefillData.forEach(imbVal => {
      const {refreshCategoryId, rowValues} = imbVal;
      let isRefresh = false;
      if(rowValues) {
      rowValues.forEach(row => {
        const {disposition, rowId} = row;
        //FY25SR-1176 add rowId check and update value to Refreshed
        if(disposition === 'Refreshed' && !rowId) {
          isRefresh = true;
        } 
      });
      }
      if(isRefresh) {
        refreshData.push(imbVal);
      } else {
        replacementData.push(imbVal);
      }
    });
    result.set('Refresh',refreshData);
    result.set('Replacement',replacementData);
  }   
  return result;
}

export function refreshReconstructionPrep(prefillData, optionsMap, productList) {
  let reconstructionWrapperList = createGroupOnPrefillData(prefillData, optionsMap, productList);
  return reconstructionWrapperList;
}

//This method sorts the Target SKUs based on Assets 
function createGroupOnPrefillData(prefillData, optionsMap, productList) {
  let assetGroupMap = new Map();
  let productToAssetTargets = new Map();
  if(prefillData) {
    prefillData.forEach(ibmval => {
      const {rowValues} = ibmval;
      rowValues.forEach(row => {
        if(row.selectedAsset) {
          if(assetGroupMap.has(row.selectedAsset)) {
            var targetSKUs = assetGroupMap.get(row.selectedAsset);
            targetSKUs.push(ibmval.skuSelected);
            assetGroupMap.set(row.selectedAsset, targetSKUs);
          } else {
            var targetSKUs = [];
            targetSKUs.push(ibmval.skuSelected);
            assetGroupMap.set(row.selectedAsset, targetSKUs);
          }
        }
      });
    });
  }
  if(assetGroupMap) {
    prefillData.forEach(ibmVal=> {
      const {refreshCategoryId, rowValues } = ibmVal;
      if(refreshCategoryId) {
        var assetGroupList = [];
        if(productToAssetTargets.has(refreshCategoryId)) {
          assetGroupList = productToAssetTargets.get(refreshCategoryId);
          for(let rowValue of rowValues) {
            var foundElement = assetGroupList.find(element => element === rowValue.selectedAsset);
            if(!foundElement) {
              assetGroupList.push(rowValue.selectedAsset);
            }
          }
        } else {
          for(let rowValue of rowValues) {
            assetGroupList.push(rowValue.selectedAsset);
          }
        }
        productToAssetTargets.set(refreshCategoryId, assetGroupList);
      }
    });
  }
  return createRows(productToAssetTargets, assetGroupMap, optionsMap, productList );
}

function createRows(productToAssetTargets, assetGroupMap, optionsMap, productList ) {
  let wrapperList = [];
  productToAssetTargets.forEach((value, key) => {
    var productDetail = productList.find(prod => prod.productId === key);
    var rowDetail = {};
    if(productDetail) {
      rowDetail.productId = key;
      rowDetail.productCode = productDetail.productCode;
      rowDetail.supportType = productDetail.supportType;
      let innerRows = [];
      for(let assetGroup of productToAssetTargets.get(key)) {
        var newRow = {};
        var selectedAssets = assetGroup.split(",");
        newRow.isSelected = true;
        newRow.previousAssetIds = selectedAssets;
        newRow.selectedAssetIds = selectedAssets
        newRow.selectedTargetIds = assetGroupMap.get(assetGroup);
        var options = [];
        selectedAssets.forEach(element => {
          options.push(optionsMap.get(element));
        });
        newRow.options = options; 
        innerRows.push(newRow);
      }
      rowDetail.rows = innerRows;
      wrapperList.push(rowDetail);
    }
  });
  return wrapperList;
}

//Added as part of FY25SR-1492 to calculate the months between two dates(Entltlements End date and user selected Renewal End Date)
function calculateSubscriptionTerm(entEndDate, renewalEndDate) {
    var months;
    let entEndDateInstance = new Date(entEndDate);
    entEndDateInstance.setUTCDate(entEndDateInstance.getUTCDate()+1);//CPQ22-5929 - Added UTC
    let renewalEndDateInstance = new Date(renewalEndDate);
    months = (renewalEndDateInstance.getUTCFullYear() - entEndDateInstance.getUTCFullYear()) * 12;//CPQ22-5929 - Added UTC
    months += (renewalEndDateInstance.getUTCMonth() - entEndDateInstance.getUTCMonth());//CPQ22-5929 - Added UTC
    months += ( entEndDateInstance.getUTCDate() <= renewalEndDateInstance.getUTCDate() ? 1 : 0);//CPQ22-5929 - Added UTC
    // months -= entEndDateInstance.getMonth();
    // months += renewalEndDateInstance.getMonth();
    return months <= 0 ? 0 : months;
}

export function getSelectedEntitlements(prefillData) {
  let entitlementIds = [];
  if(prefillData) {
    prefillData.forEach(ibmVal => {
      const rowValues = ibmVal.rowValues;
      if(rowValues) {
      rowValues.forEach(row => {
        if(row.entId) {
           entitlementIds.push(row.entId);
         }
      });
      }
    });
  }
  return entitlementIds;
}
//FYSR25-1705 - start
function fetchHWAssets(ibmVal, prefillData, hwAssetSKUMap ) {
  // let nonAssetToAssetMap = new map();
  // prefillData.forEach(ibmData => {
    //Iterate on ibm data again for HW asset collection
    // if(ibmData.skuSelected) {
      const { rowValues } = ibmVal;
      //Filter rows based on refreshCategoryId
      let filteredHWAssets = prefillData.filter(ibm => ibm.refreshCategoryId === ibmVal.skuSelected);
      if(rowValues) {
        rowValues.forEach(eachRow => {
          //Filter HWs with refreshCategoryId based on selected Entitlement and add to map each entitlement
          let filterHWAssetPerEnt = filteredHWAssets.filter(asset => asset.rowValues[0].entId === eachRow.entId);
          if(filterHWAssetPerEnt) {
            filterHWAssetPerEnt.forEach(asset => {
              let rowLength = eachRow.rowId.split('.').length;
              if(eachRow.rowId.split('.')[rowLength - 1] === asset.rowValues[0].rowId.split('.')[rowLength -1]) {
                var newKey = eachRow.entId + '-' + eachRow.rowId.split('.')[rowLength - 1];
                if(hwAssetSKUMap.has(newKey)) {
                  let hwAssetList = [];
                  hwAssetList = hwAssetSKUMap.get(newKey);
                  hwAssetList.push(asset);
                  hwAssetSKUMap.set(newKey, hwAssetList);
                } else {
                  let hwAssetList = [];
                  hwAssetList.push(asset);
                  hwAssetSKUMap.set(newKey, hwAssetList);
                }
              }
            });
          }
        });
      }
    // }
  // });
  return hwAssetSKUMap;
}
//FRSR25-1708 - End//FY25SR-2245 - start
export function createRefreshAssetList(prefillData) {
  let assetList = [];
  prefillData.forEach(ibmVal => {
    const prefillRow = ibmVal;
    if(prefillRow) {
      if(prefillRow.rowValues) {
        prefillRow.rowValues.forEach(rowValue => {
          const {selectedAsset} = rowValue;
          if(selectedAsset) {
            let innerList = selectedAsset.split(",");
              assetList = assetList.concat(innerList);
          }
        });
      }
    }
  });
  return assetList;
}
//FY25SR-2245 - End