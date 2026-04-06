export function getSelectedEnt(dataModified) {
    let returnEnt = []
    let entSelected = new Set();
    let indexSelected = new Set();
    let selectedBundle = [];
    let displayedData = JSON.parse(JSON.stringify(dataModified));
    displayedData.forEach(function (currentItemWrapper, index) {
        if(currentItemWrapper.customIndex != undefined && currentItemWrapper.rowSelected == true){
            currentItemWrapper.mapAssetEntitlements.futureValues.forEach(currentItem => {
                if(currentItem.entitlementId != undefined && !entSelected.has(currentItem.entitlementId)){
                    entSelected.add(currentItem.entitlementId);
                }
            });
        } else {
            if(currentItemWrapper.wrapBaseLicense != undefined && currentItemWrapper.wrapBaseLicense.length > 0){
                currentItemWrapper.wrapBaseLicense.forEach(currItem =>{
                    if(currItem.rowSelected != undefined && currItem.rowSelected == true && currItem.entitlementId != undefined && 
                                !indexSelected.has(currItem.customIndex.split('.')[0])){
                        indexSelected.add(currItem.customIndex.split('.')[0]);
                        selectedBundle.push(currentItemWrapper);
                    }
                });
            }
            if(currentItemWrapper.wrapHWSupportLines != undefined && currentItemWrapper.wrapHWSupportLines.length > 0){
                currentItemWrapper.wrapHWSupportLines.forEach(currItem =>{
                      if(currItem.rowSelected != undefined && currItem.rowSelected == true && currItem.entitlementId != undefined &&
                            !indexSelected.has(currItem.customIndex.split('.')[0])){
                        indexSelected.add(currItem.customIndex.split('.')[0]);
                        selectedBundle.push(currentItemWrapper);
                    }
                });
            }
            if(currentItemWrapper.wrapUpgradeEnt != undefined && currentItemWrapper.wrapUpgradeEnt.length > 0){
                currentItemWrapper.wrapUpgradeEnt.forEach(currItem =>{
                      if(currItem.rowSelected != undefined && currItem.rowSelected == true && currItem.entitlementId != undefined &&
                            !indexSelected.has(currItem.customIndex.split('.')[0])){
                        indexSelected.add(currItem.customIndex.split('.')[0]);
                        selectedBundle.push(currentItemWrapper);
                    }
                });
            }
            if(currentItemWrapper.wrapAddOnSupportLines != undefined && currentItemWrapper.wrapAddOnSupportLines.length > 0){
                currentItemWrapper.wrapAddOnSupportLines.forEach(currItem =>{
                      if(currItem.rowSelected != undefined && currItem.rowSelected == true && currItem.entitlementId != undefined &&
                            !indexSelected.has(currItem.customIndex.split('.')[0])){
                        indexSelected.add(currItem.customIndex.split('.')[0]);
                        selectedBundle.push(currentItemWrapper);
                    }
                });
            }
            if(currentItemWrapper.wrapInactiveEnt != undefined && currentItemWrapper.wrapInactiveEnt.length > 0){
                currentItemWrapper.wrapInactiveEnt.forEach(currItem =>{
                      if(currItem.rowSelected != undefined && currItem.rowSelected == true && currItem.entitlementId != undefined &&
                                !indexSelected.has(currItem.customIndex.split('.')[0])){
                        indexSelected.add(currItem.customIndex.split('.')[0]);
                        selectedBundle.push(currentItemWrapper);
                    }
                });
            }
        }
    });

    if(selectedBundle.length > 0){
            selectedBundle.forEach(currentItemWrapper =>{
                if(currentItemWrapper.wrapBaseLicense != undefined && currentItemWrapper.wrapBaseLicense.length > 0){
                currentItemWrapper.wrapBaseLicense.forEach(currItem =>{
                    if(currItem.entitlementId != undefined && !entSelected.has(currItem.entitlementId)){
                            entSelected.add(currItem.entitlementId);
                    }
                });
            }
            if(currentItemWrapper.wrapHWSupportLines != undefined && currentItemWrapper.wrapHWSupportLines.length > 0){
                currentItemWrapper.wrapHWSupportLines.forEach(currItem =>{
                    if(currItem.entitlementId != undefined && !entSelected.has(currItem.entitlementId)){
                            entSelected.add(currItem.entitlementId);
                    }
                });
            }
            if(currentItemWrapper.wrapUpgradeEnt != undefined && currentItemWrapper.wrapUpgradeEnt.length > 0){
                currentItemWrapper.wrapUpgradeEnt.forEach(currItem =>{
                    if(currItem.entitlementId != undefined && !entSelected.has(currItem.entitlementId)){
                            entSelected.add(currItem.entitlementId);
                    }
                });
            }
            if(currentItemWrapper.wrapAddOnSupportLines != undefined && currentItemWrapper.wrapAddOnSupportLines.length > 0){
                currentItemWrapper.wrapAddOnSupportLines.forEach(currItem =>{
                    if(currItem.entitlementId != undefined && !entSelected.has(currItem.entitlementId)){
                            entSelected.add(currItem.entitlementId);
                    }
                });
            }
            if(currentItemWrapper.wrapInactiveEnt != undefined && currentItemWrapper.wrapInactiveEnt.length > 0){
                currentItemWrapper.wrapInactiveEnt.forEach(currItem =>{
                    if(currItem.entitlementId != undefined && !entSelected.has(currItem.entitlementId)){
                            entSelected.add(currItem.entitlementId);
                    }
                });
            }
            });
    }
    if(entSelected.size > 0){
        returnEnt = [...entSelected];
    }
    return returnEnt;
}

export function getSelectedCustomIdex(dataModified) {
    let returnCustomIndex = [];
    let customIndexSelected = new Set();
    let displayedData = JSON.parse(JSON.stringify(dataModified));
    displayedData.forEach(function (currentItemWrapper, index) {
        if(currentItemWrapper.customIndex != undefined && currentItemWrapper.rowSelected == true){
            if(!customIndexSelected.has(currentItemWrapper.customIndex.split('.')[0])){
                customIndexSelected.add(currentItemWrapper.customIndex.split('.')[0]);
            }
        } else {
            if(currentItemWrapper.wrapBaseLicense != undefined && currentItemWrapper.wrapBaseLicense.length > 0){
                currentItemWrapper.wrapBaseLicense.forEach(currItem =>{
                      customIndexSelected = fetchSelectedCustomIndex(customIndexSelected, currItem);
                });
            }
            if(currentItemWrapper.wrapHWSupportLines != undefined && currentItemWrapper.wrapHWSupportLines.length > 0){
                currentItemWrapper.wrapHWSupportLines.forEach(currItem =>{
                      customIndexSelected = fetchSelectedCustomIndex(customIndexSelected, currItem);
                });
            }
            if(currentItemWrapper.wrapUpgradeEnt != undefined && currentItemWrapper.wrapUpgradeEnt.length > 0){
                currentItemWrapper.wrapUpgradeEnt.forEach(currItem =>{
                      customIndexSelected = fetchSelectedCustomIndex(customIndexSelected, currItem);
                });
            }
            if(currentItemWrapper.wrapAddOnSupportLines != undefined && currentItemWrapper.wrapAddOnSupportLines.length > 0){
                currentItemWrapper.wrapAddOnSupportLines.forEach(currItem =>{
                      customIndexSelected = fetchSelectedCustomIndex(customIndexSelected, currItem);
                });
            }
            if(currentItemWrapper.wrapInactiveEnt != undefined && currentItemWrapper.wrapInactiveEnt.length > 0){
                currentItemWrapper.wrapInactiveEnt.forEach(currItem =>{
                      customIndexSelected = fetchSelectedCustomIndex(customIndexSelected, currItem);
                });
            }
        }
    });

    if(customIndexSelected.size > 0){
        returnCustomIndex = [...customIndexSelected];
    }
    return returnCustomIndex;
}

function fetchSelectedCustomIndex(customIndexSelected, currItem){
    if(currItem.rowSelected != undefined && currItem.rowSelected == true && currItem.entitlementId != undefined){
                    if(!customIndexSelected.has(currItem.customIndex.split('.')[0])){
                        customIndexSelected.add(currItem.customIndex.split('.')[0]);
                    }
                }
    return customIndexSelected;
}