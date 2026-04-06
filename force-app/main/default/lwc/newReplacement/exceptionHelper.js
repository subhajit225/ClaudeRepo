//FY25SR-1124 START
export function exceptionMapping(dataModified, dnc, replaceUI, errorMessagesValues, isMisMatchSelected) {
    let replaceUiError = '';
    errorMessagesValues.forEach(currentItem => {
       if(currentItem.Message_Label__c === 'Replace_AnyToAny_Exception_Message'){
            replaceUiError = currentItem.Error_Message__c;
       }
    });
    let displayedData = JSON.parse(JSON.stringify(dataModified));
    displayedData.forEach(function (currentItemWrapper, index) {
        if(currentItemWrapper.entitlementId != null){
            if(currentItemWrapper.selecteddisposition){//CPQ22-6009
                currentItemWrapper = mapExceptionToEachLine(currentItemWrapper, dnc,replaceUI, replaceUiError);
                currentItemWrapper = qtyVerificationShowAdd(currentItemWrapper,isMisMatchSelected );
            }
        } else {
            if(currentItemWrapper.wrapBaseLicense != undefined && currentItemWrapper.wrapBaseLicense.length > 0){
                currentItemWrapper.wrapBaseLicense = mapExceptionToLines(
                    currentItemWrapper.wrapBaseLicense, dnc,replaceUI, replaceUiError, isMisMatchSelected); 
            }
            if(currentItemWrapper.wrapHWSupportLines != undefined && currentItemWrapper.wrapHWSupportLines.length > 0){
                currentItemWrapper.wrapHWSupportLines = mapExceptionToLines(
                    currentItemWrapper.wrapHWSupportLines, dnc,replaceUI, replaceUiError, isMisMatchSelected);
            }
            if(currentItemWrapper.wrapUpgradeEnt != undefined && currentItemWrapper.wrapUpgradeEnt.length > 0){
                currentItemWrapper.wrapUpgradeEnt = mapExceptionToLines(
                    currentItemWrapper.wrapUpgradeEnt, dnc,replaceUI, replaceUiError, isMisMatchSelected);
            }
            if(currentItemWrapper.wrapAddOnSupportLines != undefined && currentItemWrapper.wrapAddOnSupportLines.length > 0){
                currentItemWrapper.wrapAddOnSupportLines = mapExceptionToLines(
                    currentItemWrapper.wrapAddOnSupportLines, dnc,replaceUI, replaceUiError, isMisMatchSelected);
            }
            if(currentItemWrapper.wrapInactiveEnt != undefined && currentItemWrapper.wrapInactiveEnt.length > 0){
                currentItemWrapper.wrapInactiveEnt = mapExceptionToLines(
                    currentItemWrapper.wrapInactiveEnt, dnc,replaceUI, replaceUiError, isMisMatchSelected);
            }
        }
    });
    return displayedData;
}

function mapExceptionToLines(currentItemWrapper, dnc,replaceUI, replaceUiError, isMisMatchSelected){
    currentItemWrapper.forEach(currItem =>{
            if(currItem.selecteddisposition){//CPQ22-6009
                currItem = mapExceptionToEachLine(currItem, dnc,replaceUI, replaceUiError);
            }
            currItem = mapReplaceAnyToAny(currItem, dnc,replaceUI, replaceUiError);
    });
    currentItemWrapper = qtyVerificationShowAdd(currentItemWrapper, isMisMatchSelected);
    return currentItemWrapper;
}

function mapReplaceAnyToAny(currItem, dnc,replaceUI, replaceUiError){
    if(replaceUI == false && currItem.anyToAnyFlag == true){
        currItem.errors = replaceUiError;
    }
    if(replaceUI == true && currItem.errors === replaceUiError){
        currItem.errors = '';
    }
    return currItem;
}

function mapExceptionToEachLine(currItem, dnc,replaceUI, replaceUiError){
    if(currItem.skuProductId != undefined && currItem.skuProductId != null && 
                    ((currItem.quantityAssetType == false && currItem.targetProductType != undefined && currItem.targetProductType === 'Non-Hardware') || 
                    (currItem.quantityAssetType == true && currItem.targetProductType != undefined && currItem.targetProductType === 'Hardware'))){
                        currItem.doNotConsolidateEnt = true;
    }else{
            currItem.doNotConsolidateEnt = dnc;
    } 
    if(currItem.doNotConsolidateEnt == true && currItem.selecteddisposition != undefined && 
            (currItem.selecteddisposition != 'Renewing' && currItem.selecteddisposition != 'At Risk' &&
                currItem.selecteddisposition != 'Renew Later' && currItem.selecteddisposition != 'Churn')){
        currItem.isModified = true;
    }
    return currItem;
}
//FY25SR 1124 END
function qtyVerificationShowAdd(currentItemWrapper, isMisMatchSelected) {
    //check if partial
    currentItemWrapper.forEach(function (element, index){
        if(checkifNonAssetToNonAsset(element)) {
            let filterResult = currentItemWrapper.filter(ele=>ele.entitlementId === element.entitlementId);
            if(filterResult) {
                if(filterResult.length == 1) {
                    //Non-split
                    if(isMisMatchSelected) {
                        element.showAdd = false;
                    } else {
                        if(parseInt(element.selectedquantity) < parseInt(element.quantity)) {
                            element.showAdd = true;
                        }
                    }
                } else if(filterResult.length > 1) {
                    let sumQty = 0;
                    for(let i=0 ; i<filterResult.length ; i++) {
                        sumQty = sumQty + parseInt(filterResult[i].selectedquantity);
                    }
                    if(sumQty < parseInt(filterResult[filterResult.length - 1].quantity)) {
                        for(let i=0 ; i<filterResult.length ; i++) {
                           let lastIndex = currentItemWrapper.findIndex(
                                            ele => ele.entitlementId === element.entitlementId
                                                && filterResult[i].customIndex === ele.customIndex);
                            if(lastIndex != null && lastIndex != undefined && isMisMatchSelected) {
                                currentItemWrapper[lastIndex].showAdd = false;
                            } else {
                                currentItemWrapper[lastIndex].showAdd = true;
                            }
                        }
                    }
                }
            } 
        }
        
    });
    return currentItemWrapper;
}

function checkifNonAssetToNonAsset(currentItemWrapper) {
    if(currentItemWrapper.quantityAssetType && 
        currentItemWrapper.targetProductType != null && 
        currentItemWrapper.targetProductType != undefined && 
        currentItemWrapper.targetProductType === 'Non-Hardware' &&
        currentItemWrapper.skuProductId != null && 
        currentItemWrapper.skuProductId != undefined && 
        currentItemWrapper.skuProductId != '' ) {
        return true;
    }
    return false;
}