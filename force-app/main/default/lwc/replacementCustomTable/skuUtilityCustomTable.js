export function assignEntDataToSku(event,dataModified) {

    let customIndex = event.currentTarget.dataset.customIndex;
    let displayedData = JSON.parse(JSON.stringify(dataModified));
    let entdata;
    displayedData.forEach(function (currentItemWrapper, index) {
        if(currentItemWrapper.entitlementId != null){
            if(currentItemWrapper.customIndex && currentItemWrapper.customIndex === customIndex){
                entdata = currentItemWrapper;
            }
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
        }
    });
    console.log('entdata is ', JSON.stringify(entdata));
    return entdata;
}

export function quantityCalculation(customIndex,dataModified) { //FY25SR-1084 START
    debugger;
    let quantityTobeReturned = 0;
    let quantitySum = 0;
    let maxQuantity = 0;
    let cIndex = customIndex.split('.')[0];
    let displayedData = JSON.parse(JSON.stringify(dataModified));
    displayedData.forEach(function (currentItemWrapper, index) {
        if(currentItemWrapper.entitlementId != null){
            if(currentItemWrapper.customIndex && currentItemWrapper.customIndex === customIndex){
            }
        } else {
            if(currentItemWrapper.wrapBaseLicense != undefined && currentItemWrapper.wrapBaseLicense.length > 0){
                currentItemWrapper.wrapBaseLicense.forEach(function (element, index){
                        if(element.customIndex === customIndex){
                            maxQuantity = parseInt(element.selectedMaxquantity);
                        }                        
                        if(element.customIndex.split('.')[0] === cIndex && element.quantityAssetType == true && element.customIndex != customIndex){                            
                            quantitySum = parseInt(quantitySum) + parseInt(element.selectedquantity);
                        }
                });
            }
            if(currentItemWrapper.wrapHWSupportLines != undefined && currentItemWrapper.wrapHWSupportLines.length > 0){
                currentItemWrapper.wrapHWSupportLines.forEach(function (element, index){
                        if(element.customIndex === customIndex){
                            maxQuantity = parseInt(element.selectedMaxquantity);
                        }                        
                        if(element.customIndex.split('.')[0] === cIndex && element.quantityAssetType == true && element.customIndex != customIndex){                            
                            quantitySum = parseInt(quantitySum) + parseInt(element.selectedquantity);
                        }
                });
            }
            if(currentItemWrapper.wrapUpgradeEnt != undefined && currentItemWrapper.wrapUpgradeEnt.length > 0){
                currentItemWrapper.wrapUpgradeEnt.forEach(function (element, index){
                        if(element.customIndex === customIndex){
                            maxQuantity = parseInt(element.selectedMaxquantity);
                        }
                        if(element.customIndex.split('.')[0] === cIndex && element.quantityAssetType == true && element.customIndex != customIndex){                            
                            quantitySum = parseInt(quantitySum) + parseInt(element.selectedquantity);
                        }
                });
            }
            if(currentItemWrapper.wrapInactiveEnt != undefined && currentItemWrapper.wrapInactiveEnt.length > 0){
                currentItemWrapper.wrapInactiveEnt.forEach(function (element, index){
                        if(element.customIndex === customIndex){
                            maxQuantity = parseInt(element.selectedMaxquantity);
                        }
                        if(element.customIndex.split('.')[0] === cIndex && element.quantityAssetType == true && element.customIndex != customIndex){
                            quantitySum = parseInt(quantitySum) + parseInt(element.selectedquantity);
                        }
                });
            }
            if(currentItemWrapper.wrapAddOnSupportLines != undefined && currentItemWrapper.wrapAddOnSupportLines.length > 0){
                currentItemWrapper.wrapAddOnSupportLines.forEach(function (element, index){
                        if(element.customIndex === customIndex){
                            maxQuantity = parseInt(element.selectedMaxquantity);
                        }
                        if(element.customIndex.split('.')[0] === cIndex && element.quantityAssetType == true && element.customIndex != customIndex){
                            quantitySum = parseInt(quantitySum) + parseInt(element.selectedquantity);
                        }
                });
            }
        }
    });
    if(parseInt(maxQuantity) > 0){
            quantityTobeReturned = parseInt(maxQuantity)-parseInt(quantitySum);
    }
    console.log('quantityTobeReturned is ',quantityTobeReturned);
    return quantityTobeReturned;
}
//FY25SR-END 


function assignEntitlement(currentItemWrapper,customIndex){
    let entdata;
    currentItemWrapper.forEach(function (element, index){
        if(element.customIndex === customIndex){
            entdata = element;
        }
    });
    return entdata;
}

export function handleSkuAssignment(AssignSKUValue,dataModified,customIndex, rowsval) {
    let rowsel;
	if(AssignSKUValue == true){		
        rowsel = rowsval;
	}else{
		rowsval = undefined;
	}   
    let displayedData = JSON.parse(JSON.stringify(dataModified));
	
    displayedData.forEach(function (currentItemWrapper, index) {
        if(currentItemWrapper.entitlementId != null){
            currentItemWrapper = assignSkuVariablesToEachWrapper(currentItemWrapper,customIndex, rowsel);
        } else {
            
            if(currentItemWrapper.wrapBaseLicense != undefined && currentItemWrapper.wrapBaseLicense.length > 0){
                currentItemWrapper.wrapBaseLicense = assignSkuVariablesToList(currentItemWrapper.wrapBaseLicense,customIndex, rowsel);
            }
            if(currentItemWrapper.wrapHWSupportLines != undefined && currentItemWrapper.wrapHWSupportLines.length > 0){
                currentItemWrapper.wrapHWSupportLines = assignSkuVariablesToList(currentItemWrapper.wrapHWSupportLines,customIndex, rowsel);
            }  
            if(currentItemWrapper.wrapUpgradeEnt != undefined && currentItemWrapper.wrapUpgradeEnt.length > 0){
                currentItemWrapper.wrapUpgradeEnt = assignSkuVariablesToList(currentItemWrapper.wrapUpgradeEnt,customIndex, rowsel);
            }           
        }

    });
    console.log(' return data from handleSkuAssignment ', JSON.stringify(displayedData));
    return displayedData;
}

function assignSkuVariablesToList(currentItemWrapper,customIndex, rowsel){
    currentItemWrapper.forEach(function (element, index){
        element = assignSkuVariablesToEachWrapper(element,customIndex, rowsel);
    });
    return currentItemWrapper;
}

function assignSkuVariablesToEachWrapper(element,customIndex, rowsel){
    if(element.customIndex === customIndex){
        element = assignSkuVariables(element, rowsel);
    }
    return element;
}

function assignSkuVariables(entDataWrapper, rowsel){    
    entDataWrapper.skuProdName = rowsel != undefined ?  (rowsel.productName != undefined ? rowsel.productName : ''):'';
    entDataWrapper.skuProductId = rowsel != undefined ?  (rowsel.productId != undefined ? rowsel.productId : ''):'';
    entDataWrapper.skuSuppType = rowsel != undefined ?  (rowsel.productSupportType != undefined ? rowsel.productSupportType : ''):'';
    entDataWrapper.isModified = rowsel != undefined ?  (rowsel.productId != undefined ? true : false) : false;
    if(rowsel != undefined && rowsel.dispositionReason != undefined){
        entDataWrapper.autoDisposition.forEach((currItem) => {
          currItem.selected = false;  
          if(rowsel.dispositionReason === currItem.label){
                currItem.selected = true;  
                entDataWrapper.selecteddisposition = currItem.value;  
                entDataWrapper.disableDisposition = true;
          }
      })
    }else{
			entDataWrapper.autoDisposition.forEach((currItem) => {
			  if(currItem.selected = true){
					currItem.selected = false;  
					entDataWrapper.selecteddisposition = '';  
					entDataWrapper.disableDisposition = false;
			  }
			})
    }    
    return entDataWrapper;
  }