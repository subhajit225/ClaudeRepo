export function handleTermChange(termHandle,customIndex,displayedData,quoteDetails,errorMessages,entitlementId,keyIdentifier){
    let termError = '';

    errorMessages.forEach(currentItem => {
       if(currentItem.Message_Label__c === 'Term_Not_Zero'){
            termError = currentItem.Error_Message__c;
       }
    });

    displayedData.forEach((currentItemWrapper, index) => {
      if (currentItemWrapper.customIndex != undefined && customIndex == currentItemWrapper.customIndex) {
            // currentItemWrapper = SetvaluesEachWrapper(customIndex, termHandle, currentItemWrapper,termError );
            // Future Transaction
            // Added as part of FY25SR-1207 - Start
            if (currentItemWrapper.mapAssetEntitlements != undefined) {
                currentItemWrapper.mapAssetEntitlements = checkIfEntitlementIdPresentAndSetValues(currentItemWrapper.mapAssetEntitlements,customIndex, termHandle ,termError, entitlementId,keyIdentifier);
                
            }
            // Added as part of FY25SR-1207 - End
      } else {

            //Base Product
            if(currentItemWrapper.wrapBaseLicense != undefined){
                currentItemWrapper.wrapBaseLicense = checkIfIndexPresentAndSetValues(currentItemWrapper.wrapBaseLicense,customIndex, termHandle,termError);
            }

            //HW Support
            if(currentItemWrapper.wrapHWSupportLines != undefined){
                currentItemWrapper.wrapHWSupportLines = checkIfIndexPresentAndSetValues(currentItemWrapper.wrapHWSupportLines,customIndex, termHandle,termError);
			    currentItemWrapper.wrapHWSupportLines = checkIfHWSupportLineIsAutoDisposed(currentItemWrapper.wrapHWSupportLines,currentItemWrapper.wrapBaseLicense);

            }

            //Addons
            if(currentItemWrapper.wrapAddOnSupportLines != undefined){
                currentItemWrapper.wrapAddOnSupportLines = checkIfIndexPresentAndSetValues(currentItemWrapper.wrapAddOnSupportLines,customIndex, termHandle,termError);
            }
            //Inactive
            if(currentItemWrapper.wrapInactiveEnt != undefined){
                currentItemWrapper.wrapInactiveEnt = checkIfIndexPresentAndSetValues(currentItemWrapper.wrapInactiveEnt,customIndex, termHandle,termError);
            }
            //upgrade
            if(currentItemWrapper.wrapUpgradeEnt != undefined){
                currentItemWrapper.wrapUpgradeEnt = checkIfIndexPresentAndSetValues(currentItemWrapper.wrapUpgradeEnt,customIndex, termHandle,termError);
            }
        }
    });

    return displayedData;

}

// Added as part of FY25SR-1207 - Start
function checkIfEntitlementIdPresentAndSetValues(currentItemWrapper, customIndex, termHandle ,termError, selectedEntitlementId,keyIdentifier) {
    if(currentItemWrapper.futureValues) {
    currentItemWrapper.futureValues.forEach(element => {
        if(
            (
                element.skuProductId != undefined && element.skuProductId != '' && element.skuProductId != null && element.keyIdentifier === keyIdentifier
            ) || 
            (
                (element.skuProductId === undefined || element.skuProductId === '' || element.skuProductId === null) && element.entitlementId === selectedEntitlementId
            )
        ){
        //&& element.entitlementId === selectedEntitlementId){
            element.ReplacementTerm = parseInt(termHandle);
            element.isModified = true;
            if(parseInt(termHandle) != 0){
                element.errors = '';
            } else {
                element.errors = termError;
            }
        }
    });
    }
    
    return currentItemWrapper;
}
// Added as part of FY25SR-1207 - End

// Added this method as part of FY25SR-1215
function checkIfHWSupportLineIsAutoDisposed(hwSupportList,baseLicenseList){
  let isBaseLicenceModified = false;
  let assetSelected = '';
  let newTerm;
  if(baseLicenseList) {
  baseLicenseList.forEach(currentItem => {
      if(currentItem.isModified && currentItem.rowSelected){
          isBaseLicenceModified = true;
          newTerm = currentItem.ReplacementTerm;
          currentItem.assetsAvailable.forEach(asset => {
              if(asset.selected){
                  assetSelected = assetSelected + asset.value;
              }
          });
      }
  });
  }
  
  if(isBaseLicenceModified){
        if(hwSupportList) {
      hwSupportList.forEach(element => {
          let isAutoDispose = false;
          let isCorrectAsset = false;

          element.autoDisposition.forEach(currentItem => {
              if(currentItem.selected){
                  isAutoDispose = true;
              }
          });

            element.assetsAvailable.forEach(asset => {
                if(asset.selected && assetSelected.includes(asset.value)){
                  isCorrectAsset = true;
              }
          });

          if(element.rowSelected && isAutoDispose && isCorrectAsset){
              element.isModified = isAutoDispose;
              element.ReplacementTerm = newTerm;
          }
      });
  }
    }
  return hwSupportList;
}

function checkIfIndexPresentAndSetValues(currentItemWrapper, customIndex, termHandle,termError ) {
    if(currentItemWrapper.find(ele => ele.customIndex === customIndex)) {
        currentItemWrapper = Setvalues(customIndex, termHandle, currentItemWrapper,termError);
    }

    return currentItemWrapper;
}

function Setvalues(customIndex, termHandle, currentItemWrapperList ,termError){
    if(currentItemWrapperList) {
    currentItemWrapperList.forEach(element => {
        element = SetvaluesEachWrapper(customIndex, termHandle, element,termError);
    });
    }
    return currentItemWrapperList;
}

function SetvaluesEachWrapper(customIndex, termHandle, element, termError){
    if(element.customIndex === customIndex){
        element.ReplacementTerm = parseInt(termHandle);
        element.isModified = true;

        if(parseInt(termHandle) != 0){
            element.errors = '';
        } else {
            element.errors = termError;
        }
        // if(termHandle >= 12){
        //     element.errors = '';
        // } else {
        //     element.errors = 'The minimum term is 12 months for a Replacement. Please reach out to Deal Ops to Quote a shorter term.';
        // }
    }
    return element;
}