/*****************Below logic handles support switch for Renewals and R+E- FY25SR-1080, FY25SR-1393 ***/
export function handleSKUPaymentSwitch(dataModified, cIndex){
  let customIndex = cIndex.split('.')[0];
  let displayedData = JSON.parse(JSON.stringify(dataModified));
  let assetBaseMap = new Map();
  displayedData.forEach((currentItemWrapper, index) => {          
                if(currentItemWrapper.wrapBaseLicense != undefined && currentItemWrapper.wrapBaseLicense.length > 0){
                    assetBaseMap = mapBaseAssetsToDisposition(currentItemWrapper.wrapBaseLicense, customIndex);
                }
                if(currentItemWrapper.wrapHWSupportLines != undefined && currentItemWrapper.wrapHWSupportLines.length > 0){
                    currentItemWrapper.wrapHWSupportLines.forEach(function (currItem){
                        if(!currItem.quantityAssetType && currItem.customIndex.split('.')[0] === customIndex && currItem.customIndex != cIndex){
                            currItem = assignBaseAssetDispositionToHWSupport(currItem, assetBaseMap);
                        }
                    });
                }
    });
    return displayedData;
  }

  function mapBaseAssetsToDisposition(currentItemWrapper, customIndex){
    let assetMap = new Map();
    currentItemWrapper.forEach(function (currBase){
        if(currBase.customIndex.split('.')[0] === customIndex && !currBase.quantityAssetType){
            if(currBase.rowSelected == true && currBase.skuProductId != undefined && currBase.skuProductId.length >0 && currBase.srSuppType != undefined && currBase.skuSuppType != undefined && currBase.skuSuppType.length >0 && currBase.srSuppType != currBase.skuSuppType){
                    currBase.assetsAvailable.forEach(function (asst){
                        if(asst.selected == true){
                            assetMap.set(asst.value, fetchDispositionForCurrentBaseLine(currBase));
                        }
                    });
                }
            }
    });    
    return assetMap;
  }

  function fetchDispositionForCurrentBaseLine(currBase){
    let autoDispositionReason;
    currBase.autoDisposition.forEach(function (element){
        if(element.selected == true){
            autoDispositionReason = element.value;
        }
    })
    return autoDispositionReason;
  }

  function assignBaseAssetDispositionToHWSupport(currItem, assetBaseMap){
    currItem.assetsAvailable.forEach(function (element){
        if(element.value != 'Full'){
            if(assetBaseMap != undefined && (assetBaseMap.has('Full') || (assetBaseMap.has(element.value) && assetBaseMap.get(element.value) != undefined))){
                currItem = assetBaseMap.has('Full') ? mapAutoDisposition(currItem, assetBaseMap.get('Full')) : mapAutoDisposition(currItem, assetBaseMap.get(element.value));
                }
                //R+R do not clear refreshed
                else if (currItem.selecteddisposition != 'Refreshed'){
                currItem = mapAutoDispsitionToFalse(currItem);
            }
        }
    });
    return currItem;
  }

    export function mapAutoDisposition(currentItemWrapper, dispositionReason){
        currentItemWrapper = mapManualDispositionToFalse(currentItemWrapper);
        currentItemWrapper.autoDisposition.forEach((currItem) => {

          currItem.selected = false;
            currItem.errors = '';
          if(currItem.value === dispositionReason){
                currItem.selected = true;
                currentItemWrapper.selecteddisposition = currItem.value;
                currentItemWrapper.disableDisposition = true;
                currentItemWrapper.rowSelected = true;
                currentItemWrapper.isModified = true;
                //Added as part of FY25SR-1492
                // Retain the values only if the remaining term is not set to 12
                if(currentItemWrapper.ReplacementTerm != 12 && currentItemWrapper.RemainingTerm != 12){
                    currentItemWrapper.previousReplacementTerm = currentItemWrapper.ReplacementTerm;
                    currentItemWrapper.previousRemainingTerm = currentItemWrapper.RemainingTerm;
                }
                if(currentItemWrapper.selecteddisposition === 'Renewing'){
                    // Set the values to 12 on changing or selection of manual disposition reason
                    currentItemWrapper.ReplacementTerm = 12;
                    currentItemWrapper.RemainingTerm = 12;
                    //Added as part of FY25SR-1492
                    currentItemWrapper.disableRenewalEndDate = false;
                    // currentItem.disableTerm = true;
                } else {
                    //Added as part of FY25SR-1492
                    currentItemWrapper.disableRenewalEndDate = true;
                    currentItemWrapper.disableTerm = false;
                    currentItemWrapper.ReplacementTerm = currentItemWrapper.previousReplacementTerm;
                    currentItemWrapper.RemainingTerm = currentItemWrapper.previousRemainingTerm;
                }
          }
      });
    return currentItemWrapper;
  }

    export function mapAutoDispsitionToFalse(currentItemWrapper){
    currentItemWrapper.autoDisposition.forEach((currItem) => {
                if(currItem.selected == true){
                    currItem.selected = false;
                    currentItemWrapper.selecteddisposition = '';
                    currentItemWrapper.disableDisposition = false;  
                    if(currentItemWrapper.renLine == false){
                        currentItemWrapper.rowSelected = false;
                    }                        
                    currentItemWrapper.isModified = true;              
                }                
      });
    return currentItemWrapper;
    }
    
    function mapManualDispositionToFalse(currentItemWrapper){
    currentItemWrapper.manualDisposition.forEach((currItem) => {
                if(currItem.selected == true){
                    currItem.selected = false;     
                    currentItemWrapper.selecteddisposition = '';                         
                }                
      });
    return currentItemWrapper;

    }