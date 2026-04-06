//refactored
export function handleQuanChange(quantity, customIndex,dataModified,entitlementId,keyIdentifier, exceptionMessage) {
    let quantSelected = quantity;
    let displayedData = JSON.parse(JSON.stringify(dataModified));
    let dataToReturn = [];
    let errorMessage = 'The replacement quantity cannot be 0 or Blank.';

    if (quantSelected != undefined && quantSelected != '') {
        if (quantSelected.includes('-') || quantSelected.includes('.')) {
          dataToReturn = addErrorIfInvalidQuantity(displayedData,customIndex);
        } else {
          dataToReturn = quantityChange(displayedData,customIndex,quantSelected,entitlementId,keyIdentifier, exceptionMessage);
        }
    } else {
        displayedData.forEach(function (currentItemWrapper, index) {
          if (currentItemWrapper.customIndex != undefined && customIndex === currentItemWrapper.customIndex) {
            currentItemWrapper.showAdd = false;
            currentItemWrapper.errors = errorMessage;
          } else {
              //Base Product
              if(currentItemWrapper.wrapBaseLicense != undefined){
                  currentItemWrapper.wrapBaseLicense = addError(currentItemWrapper.wrapBaseLicense,errorMessage,customIndex);
              }

              //HW Support
              if(currentItemWrapper.wrapHWSupportLines != undefined){
                  currentItemWrapper.wrapHWSupportLines = addError(currentItemWrapper.wrapHWSupportLines,errorMessage,customIndex);
              }

              //Addons
              if(currentItemWrapper.wrapAddOnSupportLines != undefined){
                  currentItemWrapper.wrapAddOnSupportLines = addError(currentItemWrapper.wrapAddOnSupportLines,errorMessage,customIndex);
              }
              //Inactive
              if(currentItemWrapper.wrapInactiveEnt != undefined){
                  currentItemWrapper.wrapInactiveEnt = addError(currentItemWrapper.wrapInactiveEnt,errorMessage,customIndex);
                    
              }
              //upgrade
              if(currentItemWrapper.wrapUpgradeEnt != undefined){
                  currentItemWrapper.wrapUpgradeEnt = addError(currentItemWrapper.wrapUpgradeEnt,errorMessage,customIndex);
              }
          }
          dataToReturn.push(currentItemWrapper);
        });
    }
    return dataToReturn;
}

function addErrorIfInvalidQuantity(displayedData,customIndex){
    let errorMessage = 'You cannot enter negative/decimal quantity.';
    displayedData.forEach(function (curr, index) {
        if (curr.customIndex != undefined && customIndex === curr.customIndex) {
          curr.showAdd = false;
          curr.errors = errorMessage;
        } else {
          //Base Product
          if(currentItemWrapper.wrapBaseLicense != undefined){
              currentItemWrapper = checkIndexPresentAndAddError(currentItemWrapper.wrapBaseLicense,customIndex,);
          }


            //HW Support
            if(currentItemWrapper.wrapHWSupportLines != undefined){
                currentItemWrapper = checkIndexPresentAndAddError(currentItemWrapper.wrapHWSupportLines,customIndex,errorMessage);
            }

            //Addons
            if(currentItemWrapper.wrapAddOnSupportLines != undefined){
                currentItemWrapper = checkIndexPresentAndAddError(currentItemWrapper.wrapAddOnSupportLines,customIndex,errorMessage);
            }
            //Inactive
            if(currentItemWrapper.wrapInactiveEnt != undefined){
                currentItemWrapper = checkIndexPresentAndAddError(currentItemWrapper.wrapInactiveEnt,customIndex,errorMessage);
            }
            //upgrade
            if(currentItemWrapper.wrapUpgradeEnt != undefined){
              currentItemWrapper = checkIndexPresentAndAddError(currentItemWrapper.wrapUpgradeEnt,customIndex,errorMessage);
            }
        }
    });

}

function checkIndexPresentAndAddError(currentItemWrapper,customIndex,errorMessage){
  if(checkIfIndexPresent(currentItemWrapper,customIndex)) {
    currentItemWrapper = addError(currentItemWrapper,errorMessage,customIndex);
  }
  return currentItemWrapper;
}
function addError(currentItemWrapper,errorMessage,customIndex){
  currentItemWrapper.forEach(function (element, index){
      if(element.customIndex === customIndex) {
        element.showAdd = false;
        element.errors = errorMessage;
      }
  });
  return currentItemWrapper;
}

function quantityChange(displayedData,customIndex,quantSelected,entitlementId,keyIdentifier, exceptionMessage){
    let newWrapperList = [];
    let maxCurrQuan = 0;
    displayedData.forEach(function (currentItemWrapper, indexWrapper) {
      if(currentItemWrapper.customIndex != undefined ){
          // Future Transaction
            // Added as part of FY25SR-1207 - Start
            if (currentItemWrapper.mapAssetEntitlements != undefined) {
                currentItemWrapper.mapAssetEntitlements = checkIfEntitlementIdPresentAndSetValues(currentItemWrapper.mapAssetEntitlements,customIndex, quantSelected , entitlementId,keyIdentifier);
                
            }
          // Added as part of FY25SR-1207 - End
      } else {
        //Base Product
        if(currentItemWrapper.wrapBaseLicense != undefined){
          if(checkIfIndexPresent(currentItemWrapper.wrapBaseLicense,customIndex)) {
            currentItemWrapper.wrapBaseLicense = setQuantities(customIndex,currentItemWrapper.wrapBaseLicense,quantSelected,displayedData);
            maxCurrQuan = setmaxCurrQuan(customIndex,currentItemWrapper.wrapBaseLicense);
            newWrapperList = createNewList(customIndex,currentItemWrapper.wrapBaseLicense);
          }
        }


        //HW Support
        if(currentItemWrapper.wrapHWSupportLines != undefined){
            if(checkIfIndexPresent(currentItemWrapper.wrapHWSupportLines,customIndex)){
              currentItemWrapper.wrapHWSupportLines = setQuantities(customIndex,currentItemWrapper.wrapHWSupportLines,quantSelected,displayedData);
              maxCurrQuan = setmaxCurrQuan(customIndex,currentItemWrapper.wrapHWSupportLines);
              newWrapperList = createNewList(customIndex,currentItemWrapper.wrapHWSupportLines);
            }
        }

        //Addons
        if(currentItemWrapper.wrapAddOnSupportLines != undefined){
            if(checkIfIndexPresent(currentItemWrapper.wrapAddOnSupportLines,customIndex)) {
              currentItemWrapper.wrapAddOnSupportLines = setQuantities(customIndex,currentItemWrapper.wrapAddOnSupportLines,quantSelected,displayedData);
              maxCurrQuan = setmaxCurrQuan(customIndex,currentItemWrapper.wrapAddOnSupportLines);
              newWrapperList = createNewList(customIndex,currentItemWrapper.wrapAddOnSupportLines);
              
            }
        }
        //Inactive
        if(currentItemWrapper.wrapInactiveEnt != undefined){
            if(checkIfIndexPresent(currentItemWrapper.wrapInactiveEnt,customIndex)) {
              currentItemWrapper.wrapInactiveEnt = setQuantities(customIndex,currentItemWrapper.wrapInactiveEnt,quantSelected,displayedData);
              maxCurrQuan = setmaxCurrQuan(customIndex,currentItemWrapper.wrapInactiveEnt);
              newWrapperList = createNewList(customIndex,currentItemWrapper.wrapInactiveEnt);
              
            }
        }
        //upgrade
        if(currentItemWrapper.wrapUpgradeEnt != undefined){
            if(checkIfIndexPresent(currentItemWrapper.wrapUpgradeEnt,customIndex)) {
              currentItemWrapper.wrapUpgradeEnt = setQuantities(customIndex,currentItemWrapper.wrapUpgradeEnt,quantSelected,displayedData);
              maxCurrQuan = setmaxCurrQuan(customIndex,currentItemWrapper.wrapUpgradeEnt);
              newWrapperList = createNewList(customIndex,currentItemWrapper.wrapUpgradeEnt);
            }
        }
      }
        
    });

    let currMaxWithoutEvent = 0;
    newWrapperList.forEach((currItem, index) => {
        if(currItem.selectedquantity != undefined){
            currMaxWithoutEvent = parseInt(currMaxWithoutEvent) + parseInt(currItem.selectedquantity);
        }
    });

    currMaxWithoutEvent = parseInt(currMaxWithoutEvent) + parseInt(quantSelected);
    let errorOccured = false;
    let equalQuantity = false;
    if (currMaxWithoutEvent > maxCurrQuan) {
      errorOccured = true;
    } else if (currMaxWithoutEvent == maxCurrQuan) {
      equalQuantity = true;
    }


    displayedData.forEach((currentItemWrapper, index) => {
      if (currentItemWrapper.customIndex != undefined && 
            customIndex.split('.')[0]+'.'+customIndex.split('.')[1]  === currentItemWrapper.customIndex.split('.')[0]+'.'+currentItemWrapper.customIndex.split('.')[1] 
            && errorOccured == true) {
          currentItemWrapper.errors = 'The replacement quantity cannot be greater than the original quantity';
          currentItemWrapper.showAdd = false;
      } else if(currentItemWrapper.customIndex != undefined){
        
        currentItemWrapper =  setIconVisibilityEachWrapper(
          customIndex, currentItemWrapper, errorOccured, equalQuantity, exceptionMessage, currentItemWrapper);
      } else {
        //Base Product
        if(currentItemWrapper.wrapBaseLicense != undefined){
          if(checkIfIndexPresent(currentItemWrapper.wrapBaseLicense,customIndex)) {
            currentItemWrapper.wrapBaseLicense = setIconVisibility(customIndex, currentItemWrapper.wrapBaseLicense, errorOccured, equalQuantity, exceptionMessage);
        }
        }


        //HW Support
        if(currentItemWrapper.wrapHWSupportLines != undefined){

            if(checkIfIndexPresent(currentItemWrapper.wrapHWSupportLines,customIndex)){
              currentItemWrapper.wrapHWSupportLines = setIconVisibility(customIndex, currentItemWrapper.wrapHWSupportLines, errorOccured, equalQuantity, exceptionMessage);
        }
        }

        //Addons
        if(currentItemWrapper.wrapAddOnSupportLines != undefined){
            if(checkIfIndexPresent(currentItemWrapper.wrapAddOnSupportLines,customIndex)) {
              currentItemWrapper.wrapAddOnSupportLines = setIconVisibility(customIndex, currentItemWrapper.wrapAddOnSupportLines, errorOccured, equalQuantity, exceptionMessage);
            }
        }
        //Inactive
        if(currentItemWrapper.wrapInactiveEnt != undefined){
            if(checkIfIndexPresent(currentItemWrapper.wrapInactiveEnt,customIndex)) {
              currentItemWrapper.wrapInactiveEnt = setIconVisibility(customIndex, currentItemWrapper.wrapInactiveEnt, errorOccured, equalQuantity, exceptionMessage);
            }
        }
        //upgrade
        if(currentItemWrapper.wrapUpgradeEnt != undefined){
            if(checkIfIndexPresent(currentItemWrapper.wrapUpgradeEnt,customIndex)) {
              currentItemWrapper.wrapUpgradeEnt = setIconVisibility(customIndex, currentItemWrapper.wrapUpgradeEnt, errorOccured, equalQuantity, exceptionMessage);
        }
        }

      }
    });

    return displayedData;
}

// Added as part of FY25SR-1207 - Start
function checkIfEntitlementIdPresentAndSetValues(currentItemWrapper, customIndex, quantSelected, selectedEntitlementId,keyIdentifier) {
  currentItemWrapper.futureValues.forEach(element => {
      if(element.keyIdentifier === keyIdentifier && element.entitlementId === selectedEntitlementId){
          element.selectedquantity = quantSelected;
          element.errors = '';
          element.isModified = true;
      }
  });
  return currentItemWrapper;
}
// Added as part of FY25SR-1207 - End

function createNewList(customIndex,currentItemWrapper){
  let newWrapperList = [];
  let splittedCustomIndex = customIndex.split('.')[0] + '.' + customIndex.split('.')[1];
  currentItemWrapper.forEach(function (element, index){
      if (element.quantityAssetType && splittedCustomIndex === element.customIndex.split('.')[0] + '.' + element.customIndex.split('.')[1]) {
          if (customIndex != element.customIndex) {
              newWrapperList.push(element);
          }
      }
  });

  return newWrapperList;
}

function setmaxCurrQuan(customIndex,currentItemWrapper){
  let maxCurrQuan = 0;
  let splittedCustomIndex = customIndex.split('.')[0] + '.' + customIndex.split('.')[1];
    currentItemWrapper.forEach(function (element, index){
        if (element.quantityAssetType 
            && splittedCustomIndex === element.customIndex.split('.')[0] + '.' + element.customIndex.split('.')[1]
        ) {
            maxCurrQuan = parseInt(element.selectedMaxquantity);
        }
    });
    return maxCurrQuan;
}
function setQuantities(customIndex,currentItemWrapper,quantSelected,displayedData){
  currentItemWrapper.forEach(function (element, index){
    element = setQuantitiesEachWrapper(customIndex,element,quantSelected,displayedData);
  });

  return currentItemWrapper;
}

function setQuantitiesEachWrapper(customIndex,element,quantSelected,displayedData){
  let splittedCustomIndex = customIndex.split('.')[0] + '.' + customIndex.split('.')[1];
  let splittedCustomIndexElement = element.customIndex.split('.')[0] + '.' + element.customIndex.split('.')[1];
  if (element.quantityAssetType  &&  splittedCustomIndex === splittedCustomIndexElement ) {
      if (customIndex == element.customIndex) {
          element.selectedquantity = quantSelected;
          element.errors = '';
          element.consumedquantity = setConsumedQuantity(customIndex,quantSelected,displayedData);
      }
  }
  return element;
}

function setConsumedQuantity(customIndex,quantSelected,displayedData){
  let consumedquantity = 0;
  if(customIndex.split('.')[2] == 0 ){
    consumedquantity = parseInt(quantSelected);
  } else {
    consumedquantity = calculateQuantityConsumed(customIndex,displayedData);
  }   

  return consumedquantity;
}

function setIconVisibility(customIndex, currentItemWrapper, errorOccured, equalQuantity, exceptionMessage){
    currentItemWrapper.forEach(function (element, index){
        let filterResult = currentItemWrapper.filter(ele=>ele.entitlementId === element.entitlementId);
        element = setIconVisibilityEachWrapper(customIndex, element, errorOccured, equalQuantity, exceptionMessage, filterResult);
    });
    return currentItemWrapper;
}

function setIconVisibilityEachWrapper(customIndex,element, errorOccured, equalQuantity, exceptionMessage, filterResult){

    if (customIndex === element.customIndex) {
      if(errorOccured == false && equalQuantity == false) { //When qty is less 
         element.showAdd = true;
      } else {
         element.showAdd = false; 
      }
      let hasMismatchQTYAssets = false;
      for(let i=0 ; i<filterResult.length ; i++) {
        if(checkIfNonAssetToNonAssetitem(filterResult[i], exceptionMessage)) {
          hasMismatchQTYAssets = true;
        }
      }
      if(hasMismatchQTYAssets == true) {
        element.showAdd = false;
      }
      element.isModified = true;
    }
    element.errors = '';
    return element;
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
        if(currentItemWrapper.wrapBaseLicense != undefined ){
          if(checkIfIndexPresent(currentItemWrapper.wrapBaseLicense,customIndex)) {
            consumedQuantity = calculateConsumedQuantityFromEachList(currentItemWrapper.wrapBaseLicense,customIndex);
          }
        }

        //HW Support
        if(currentItemWrapper.wrapHWSupportLines != undefined){
          if(checkIfIndexPresent(currentItemWrapper.wrapHWSupportLines,customIndex)) {
            consumedQuantity = calculateConsumedQuantityFromEachList(currentItemWrapper.wrapHWSupportLines,customIndex);
          }
        }

        //Addons
        if(currentItemWrapper.wrapAddOnSupportLines != undefined){
          if(checkIfIndexPresent(currentItemWrapper.wrapAddOnSupportLines,customIndex)) {
            consumedQuantity = calculateConsumedQuantityFromEachList(currentItemWrapper.wrapAddOnSupportLines,customIndex);
          }
        }
        //Inactive
        if(currentItemWrapper.wrapInactiveEnt != undefined){
          if(checkIfIndexPresent(currentItemWrapper.wrapInactiveEnt,customIndex)) {
            consumedQuantity = calculateConsumedQuantityFromEachList(currentItemWrapper.wrapInactiveEnt,customIndex);
          }
              
        }
        //upgrade
        if(currentItemWrapper.wrapUpgradeEnt != undefined){
          if(checkIfIndexPresent(currentItemWrapper.wrapUpgradeEnt,customIndex)) {
            consumedQuantity = calculateConsumedQuantityFromEachList(currentItemWrapper.wrapUpgradeEnt,customIndex);
          }
        }
    }
  });
  return consumedQuantity;
}

function calculateConsumedQuantityFromEachList(currentItemWrapper,customIndex){
  let consumedQuantity = 0;
  let customIndexSplit = customIndex.split('.')[0] + '.' + customIndex.split('.')[1];
  currentItemWrapper.forEach(function (element, index){
      if(customIndexSplit == element.customIndex.split('.')[0] + '.' + element.customIndex.split('.')[1]){
        consumedQuantity = parseInt(consumedQuantity) + parseInt(element.selectedquantity);
      }
  });

  return consumedQuantity;
}

function checkIfIndexPresent(currentItemWrapper, customIndex ) {
    return currentItemWrapper.find(ele => ele.customIndex === customIndex);
}
function checkIfNonAssetToNonAssetChange(currentItemWrapper, exceptionMessage) {
  let hasNonAsset = false;
  currentItemWrapper.forEach(function (element){
      if(!hasNonAsset) {
        hasNonAsset = checkIfNonAssetToNonAssetitem(element, exceptionMessage);
      }
    });
    return hasNonAsset;
}

function checkIfNonAssetToNonAssetitem(currentItemWrapper, exceptionMessage) {

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