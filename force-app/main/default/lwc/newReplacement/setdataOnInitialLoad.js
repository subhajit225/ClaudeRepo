//refactored
export function setDataOnLoad(dataModified, quoteType, disableValidations) {
    let displayedData = JSON.parse(JSON.stringify(dataModified));
    displayedData.forEach(function (currentItemWrapper, index) {
        if(currentItemWrapper.customIndex != undefined){
            // currentItemWrapper = setDataOnEachWrapper(currentItemWrapper,quoteType);

            // Added as part of FY25SR-1207 - Start
            if (currentItemWrapper.mapAssetEntitlements != undefined) {
                currentItemWrapper.showmapAssetEntitlements = true;
                currentItemWrapper.mapAssetEntitlements = setDataForRefreshFutureTransactions(currentItemWrapper.mapAssetEntitlements,quoteType,currentItemWrapper.customIndex,disableValidations);
                
            } else {
                currentItemWrapper.showmapAssetEntitlements = false;
            }

            if (currentItemWrapper.wrapHWSupportLines != undefined && currentItemWrapper.wrapHWSupportLines.length > 0) {
                currentItemWrapper.showwrapHWSupportLines = true;

                currentItemWrapper.wrapHWSupportLines = setData(currentItemWrapper.wrapHWSupportLines,quoteType,false,disableValidations);

                
                currentItemWrapper.wrapHWSupportLines.forEach(currentItem => {                    
                    //set available Quantity
                    currentItem.selectedMaxquantity = 1;
                    currentItem.selectedquantity = 1;
                });
            } else {
                currentItemWrapper.showwrapHWSupportLines = false;
            }

            if (currentItemWrapper.wrapInactiveEnt != undefined && currentItemWrapper.wrapInactiveEnt.length > 0) {
                currentItemWrapper.showwrapInactiveEnt = true;
                currentItemWrapper.wrapInactiveEnt = setData(currentItemWrapper.wrapInactiveEnt,quoteType,true,disableValidations);

                currentItemWrapper.wrapInactiveEnt.forEach(currentItem => {
                    if(currentItem.entitlementName.includes('-HW-')){
                        currentItem.selectedMaxquantity = 1;
                        currentItem.selectedquantity = 1;
                    }
                    currentItem.quantityAssetType = true;
                    currentItem.disableAssets = true;
                });
            } else {
                currentItemWrapper.showwrapInactiveEnt = false;
            }
            
            // Added as part of FY25SR-1207 - End
        } else {

            if (currentItemWrapper.wrapBaseLicense != undefined && currentItemWrapper.wrapBaseLicense.length > 0) {
                currentItemWrapper.showwrapBaseLicense = true;
                currentItemWrapper.wrapBaseLicense = setData(currentItemWrapper.wrapBaseLicense,quoteType,false,disableValidations);

                currentItemWrapper.wrapBaseLicense.forEach(currentItem => {
                    if(currentItem.entitlementName.includes('-HW-')|| currentItem.entitlementName.includes('-NRD-')){ //FY25SR-2112
                        currentItem.selectedMaxquantity = 1;
                        currentItem.selectedquantity = 1;
                    }
                });
            } else {
                currentItemWrapper.showwrapBaseLicense = false;
            }

            if (currentItemWrapper.wrapHWSupportLines != undefined && currentItemWrapper.wrapHWSupportLines.length > 0) {
                currentItemWrapper.showwrapHWSupportLines = true;

                currentItemWrapper.wrapHWSupportLines = setData(currentItemWrapper.wrapHWSupportLines,quoteType,false,disableValidations);

                
                currentItemWrapper.wrapHWSupportLines.forEach(currentItem => {                    
                    //set available Quantity
                    currentItem.selectedMaxquantity = 1;
                    currentItem.selectedquantity = 1;
                });
            } else {
                currentItemWrapper.showwrapHWSupportLines = false;
            }

            if (currentItemWrapper.wrapAddOnSupportLines != undefined && currentItemWrapper.wrapAddOnSupportLines.length > 0) {
                currentItemWrapper.showwrapAddOnSupportLines = true;

                currentItemWrapper.wrapAddOnSupportLines = setData(currentItemWrapper.wrapAddOnSupportLines,false,disableValidations);
            } else {
                currentItemWrapper.showwrapAddOnSupportLines = false;
            }

            if (currentItemWrapper.wrapInactiveEnt != undefined && currentItemWrapper.wrapInactiveEnt.length > 0) {
                currentItemWrapper.showwrapInactiveEnt = true;
                currentItemWrapper.wrapInactiveEnt = setData(currentItemWrapper.wrapInactiveEnt,quoteType,true,disableValidations);

                currentItemWrapper.wrapInactiveEnt.forEach(currentItem => {
                    if(currentItem.entitlementName.includes('-HW-')){
                        currentItem.selectedMaxquantity = 1;
                        currentItem.selectedquantity = 1;
                    }
                    currentItem.quantityAssetType = true;
                    currentItem.disableAssets = true;
                });
            } else {
                currentItemWrapper.showwrapInactiveEnt = false;
            }

            if (currentItemWrapper.wrapUpgradeEnt != undefined && currentItemWrapper.wrapUpgradeEnt.length > 0) {
                currentItemWrapper.showwrapUpgradeEnt = true;
                currentItemWrapper.wrapUpgradeEnt = setData(currentItemWrapper.wrapUpgradeEnt,quoteType,false,disableValidations);
                
            } else {
                currentItemWrapper.showwrapUpgradeEnt = false;
            }

            // Added as part of FY25SR-1207 - Start
            if (currentItemWrapper.mapAssetEntitlements != undefined) {
                currentItemWrapper.showmapAssetEntitlements = true;
                currentItemWrapper.mapAssetEntitlements = setDataForRefreshFutureTransactions(currentItemWrapper.mapAssetEntitlements,quoteType,currentItemWrapper.customIndex,disableValidations);
            } else {
                currentItemWrapper.showmapAssetEntitlements = false;
            }
            // Added as part of FY25SR-1207 - End
        }
    });
    return displayedData;

}

function setData(currentItemWrapper,quoteType,isInactiveLine,disableValidations){
    currentItemWrapper.forEach(currentItem => {
        currentItem = setDataOnEachWrapper(currentItem,quoteType,isInactiveLine,disableValidations);
    });
    return currentItemWrapper;
}

function addSpaceInName(name) {
    // Check and replace
    if (name.includes("/")) {
        name = name.replace(/\//g, "/ ");
    }
    
    if (name.includes("_")) {
        name = name.replace(/_/g, " ");
    }
    if (name.includes("+")) {
        name = name.replace(/\+/g, " +");
    }
    if(/[^a-zA-Z0-9 ]/.test(name)) {
        name = name.replace(/[^a-zA-Z0-9 ]/g, ' ') // replace special chars
        .replace(/\s+/g, ' ')           // collapse multiple spaces
        .trim();  // remove leading/trailing spaces
    }    
    return name;
}

function setDataOnEachWrapper(currentItem,quoteType,isInactiveLine,disableValidations){
    let maxQuan = 0;
    //Set Row Color for Arroyo ENT
    if (quoteType === 'Renewal+Expansion') {
        currentItem.setRowColor =  setRowBackgroungColor(currentItem.EndDate);
    }
    currentItem.serviceContractName = currentItem.serviceContractName != null ? addSpaceInName(currentItem.serviceContractName) : currentItem.serviceContractName;//FYSR25-1860
    //Set previous terms
    currentItem.previousReplacementTerm = currentItem.ReplacementTerm;
    currentItem.previousRemainingTerm = currentItem.RemainingTerm ;

    if(disableValidations == true){
        currentItem.manualDisposition = createManualDisposItion(currentItem,quoteType);
    }
    //Set Disposition Options
   // currentItem.autoDisposition = createAutoDisposItion(quoteType);
  //  currentItem.manualDisposition = createManualDisposItion(quoteType);
    currentItem.disableDisposition = false;

    //Set isModified to false on load
    currentItem.isModified = false;
    maxQuan = 0;
    if(currentItem.assetsAvailable != undefined && currentItem.assetsAvailable.length > 0){
        currentItem.assetsAvailable.forEach((currItem, indx) => {
            if (currItem.value === 'Full') {
                currItem.selected = true;
            }
        });

        //Added RBK check for FY25SR-1096
        if (currentItem.entitlementName.startsWith('RBK')) {
            maxQuan = maxQuan + currentItem.quantity;
        } else {
             maxQuan = maxQuan + currentItem.quantity;
            // currentItem.assetsAvailable.forEach((currItem, indx) => {
            //     maxQuan = maxQuan + currItem.quantity;
            // });
        }
        currentItem.quantityAssetType = false;
        //Disable Quantity - Added this method as part of FY25SR-1215
        currentItem.disableQuantity = true;
    } else {
        maxQuan = maxQuan + currentItem.quantity;
        currentItem.quantityAssetType = true;
        //Disable Quantity - Added this as part of FY25SR-1215
        currentItem.disableQuantity = false;
    }
    //set available Quantity
    currentItem.selectedMaxquantity = maxQuan;
    currentItem.selectedquantity = maxQuan;
    currentItem.consumedquantity = maxQuan;

    //set if product is replaceable
    currentItem.isReplaceableProduct = currentItem.SrprodRepCategory != undefined ? 
                                        checkIfReplaceableProduct(currentItem, quoteType) : false;

    //Disbale the renewal End date on load
    currentItem.disableRenewalEndDate = true;
    currentItem.disableAssets = false;
    //set full assets are selected for inner inactive ents 
    if(currentItem.wrapInactiveEnt != undefined && currentItem.wrapInactiveEnt.length > 0){
        currentItem.wrapInactiveEnt.forEach(currentItemInner => {

            //Set previous terms
            currentItemInner.previousReplacementTerm = currentItemInner.ReplacementTerm;
            currentItemInner.previousRemainingTerm = currentItemInner.RemainingTerm ;

            //Set Disposition Options
           // currentItemInner.autoDisposition = createAutoDisposItion(quoteType);
          //  currentItemInner.manualDisposition = createManualDisposItion(quoteType);
            currentItemInner.disableDisposition = false;

            //Set isModified to false on load
            currentItemInner.isModified = false;

            //Set Row Color for Arroyo ENT
            currentItemInner.setRowColor =  setRowBackgroungColor(currentItemInner.EndDate);
            //Start FY25SR-2298 override Row Color for Arroyo ENT if inactive ent is present (according to Inactive ent endDate)
            if (quoteType === 'Renewal+Expansion') {
                currentItem.setRowColor =  setRowBackgroungColor(currentItemInner.EndDate);
            } //end FY25SR-2298
            maxQuan = 0;
            if(currentItemInner.assetsAvailable != undefined && currentItemInner.assetsAvailable.length > 0){
                //Added RBK check for FY25SR-1096
                if (currentItem.entitlementName.startsWith('RBK')) {
                    maxQuan = maxQuan + currentItem.quantity;
                } else {
                currentItemInner.assetsAvailable.forEach((currItem, indx) => {
                    if (currItem.value === 'Full') {
                    currItem.selected = true;
                    }
                        // maxQuan = maxQuan + currItem.quantity;
                    });
                    maxQuan = maxQuan + currentItem.quantity;
                }
                
                currentItemInner.quantityAssetType = false;
            } else {
                maxQuan = maxQuan + currentItem.quantity;
                currentItemInner.quantityAssetType = true;
            }
            //Disable Quantity - Added this method as part of FY25SR-1215
            currentItemInner.disableQuantity = true;
            //set available Quantity
            currentItemInner.selectedMaxquantity = maxQuan;
            currentItemInner.selectedquantity = maxQuan;
            currentItemInner.consumedquantity = maxQuan;
            
            //set if product is replaceable
            currentItemInner.isReplaceableProduct = currentItemInner.SrprodRepCategory != undefined ? 
                                        checkIfReplaceableProduct(currentItemInner, quoteType) : false;

            currentItemInner.disableDisposition = true;
            currentItemInner.isReplaceableProduct = true;
            currentItemInner.disableTerm = true;
            currentItemInner.disableAssets = true;

            //Disbale the renewal End date on load
            currentItemInner.disableRenewalEndDate = true;
        });
    }

    //Set variables as false so that the inputs are not editable for inactive lines
    if(isInactiveLine){
        currentItem.disableDisposition = true;
        currentItem.isReplaceableProduct = true;
        //Disable Term - Added this method as part of FY25SR-1215
        currentItem.disableTerm = true;
        //Disable Quantity - Added this method as part of FY25SR-1215
        currentItem.disableQuantity = true;
    }

    //FY25SR-1557 Start
    if(currentItem.tphTypeEntitlement != undefined && currentItem.tphTypeEntitlement == true){
                currentItem.disableQuantity = true;
                currentItem.showAdd = false;
    }
    //FY25SR-1557 END
    
    //FY25SR-1705
    if(currentItem.targetProductType == undefined || currentItem.targetProductType == null){
        if(currentItem.quantityAssetType != undefined && currentItem.quantityAssetType == true){
            currentItem.targetProductType = 'Non-Hardware';
        }else if(currentItem.quantityAssetType != undefined && currentItem.quantityAssetType == false){
            currentItem.targetProductType = 'Hardware';
        }
    }
    //FY25SR-1705

    //FY25SR-2349
    if(currentItem.renewalEndDate != undefined && currentItem.renewalEndDate != null){
        currentItem.previousRenewalEndDate = currentItem.renewalEndDate;
        
    }
    //FY25SR-2349
    return currentItem;
}

// Added as part of FY25SR-1207 - Start
function setDataForRefreshFutureTransactions(mapData,quoteType,customIndex,disableValidations) {
    // let mapValues = new Map();
    // let keyk = '';
    // for(var key in mapData){
    //     let newList= [];
    //     newList = mapData[key];
    //     mapValues.key = key;
    //     mapValues.value = newList;
    //     keyk = key;
    // }
    let mapValues = JSON.parse(JSON.stringify(mapData));
    if(mapValues != undefined && mapValues.futureValues != undefined && mapValues.futureValues.length > 0){
        let newAssetList = [];
        mapValues.futureValues.forEach(function (currItem, index){
            currItem = setDataOnEachWrapper(currItem,quoteType,false,disableValidations);
            currItem.customIndex = customIndex + '.' + index;
            newAssetList = newAssetList.concat(currItem.assetsAvailable);
            if(index === 0){
                currItem.rowspan = mapValues.futureValues.length;
            }
        });

        let mapAssets = {};
        newAssetList.forEach(currentItem => {
            mapAssets[currentItem.value] = currentItem;
        });

        // Create new assets list for future transactions
        mapValues.futureValues.forEach(function (currItem, index){
            currItem.newAssetList = Object.values(mapAssets);
            currItem.disableQuantity = false;
        });
    }
    return mapValues; 
}
// Added as part of FY25SR-1207 - End

function createManualDisposItion(currItem,quoteType){
    if (quoteType === 'Renewal+Expansion') {
        currItem.autoDisposition.forEach(curr =>{
                currItem.manualDisposition.push(curr);
        });
    }
    return currItem.manualDisposition; 
}

// function createAutoDisposItion(quoteType){
//     if (quoteType === 'Renewal+Expansion') {
//         return [
//             { label: 'Conversion', value: 'Converted', selected : false },
//             { label: 'Refresh', value: 'Refreshed', selected : false },
//             { label: 'Upgrade', value: 'Upgraded', selected : false }
//         ];
//     }else if (quoteType === 'Renewal') {
//         return [
//             { label: 'Renew Now', value: 'Renewing', selected : false }        
//         ];
//     }
// }

function checkIfReplaceableProduct(currentItem, quoteType){
    if(currentItem.srcLicModel === 'Perpetual' || currentItem.srProdType === 'HW Support' || currentItem.disableSKU){//Fy25SR-2388
        return true;
    }
    // if((quoteType === 'Renewal+Expansion' && (currentItem.SrprodRepCategory === 'Not Replaceable' || currentItem.srcLicModel === 'Perpetual')) ||
    //         (quoteType === 'Renewal' && (currentItem.srcLicModel === 'Perpetual' || currentItem.srProdType === 'HW Support'))){
    //             return true;
    // }
    return false;
    //FY25SR-1592, 2232 End
}

function setRowBackgroungColor (enddate){
    if(checkdateForArroyo(enddate)){
        return 'background-color: #E8E8E8;';
    } else {
        return 'background-color: white;';
    }
}

function checkdateForArroyo(enddate){
    let isArroyoEnt = false;

    let today = new Date();
    if(formatDate(addMonthsToDate(today, -3)) <= enddate && formatDate(addMonthsToDate(today , 12)) >= enddate){
        isArroyoEnt = true;
    }
    return isArroyoEnt;
}

export function addMonthsToDate(date, months) {
  const newDate = new Date(date); // Create a new Date instance to avoid mutating the original date
  newDate.setMonth(newDate.getMonth() + months);
  return newDate;
}

export function formatDate(date) {
    var d = new Date(date),
        month = '' + (d.getMonth() + 1),
        day = '' + d.getDate(),
        year = d.getFullYear();

    if (month.length < 2) 
        month = '0' + month;
    if (day.length < 2) 
        day = '0' + day;

    return [year, month, day].join('-');
}