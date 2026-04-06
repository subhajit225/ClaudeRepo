export function handleAssetSelection(parentOptionSelection, customIndex, dataModified){
    let receivedData = JSON.parse(JSON.stringify(parentOptionSelection));
    let displayedData = JSON.parse(JSON.stringify(dataModified));
    let quantitymax = 0;
    let maxAllquantityFull = 0;
    let showadds = false;
    let donotShowadds = false;
    let removedFullFromFirstRow = false;


    if (receivedData != null && receivedData.length > 0) {
        
        //Calculate the QUantity if full is slected
        if(checkIfFullSelected(receivedData)){
            maxAllquantityFull = setmaxAllquantityFull(receivedData);
        } 

        let assetMap = new Map();
        displayedData.forEach((currentItemWrapper, index) => {
            
            if(currentItemWrapper.assetsAvailable != undefined && currentItemWrapper.assetsAvailable.length > 0){

                currentItemWrapper.assetsAvailable.forEach((currWrap, index) => {
                    if (currWrap.value != 'Full' && currentItemWrapper.customIndex === customIndex) {
                        assetMap.set(currWrap.value, currWrap);
                    }
                });

                receivedData.forEach((element) => {
                    if (customIndex === currentItemWrapper.customIndex) {
                        currentItemWrapper.assetsAvailable.forEach((assetsAvailable) => {
                            if (assetsAvailable.value === element.value) {
                                if ( element.value === 'Full' && element.selected === false && customIndex.split('.')[1] == 0 && currentItemWrapper.customIndex === customIndex && assetsAvailable.value === 'Full' && element.selected != assetsAvailable.selected) {
                                    removedFullFromFirstRow = true;
                                }
                                    assetsAvailable.selected = element.selected;
                                if ( assetsAvailable.selected === true && element.value != 'Full' && currentItemWrapper.customIndex === customIndex) {
                                    //Added RBK condition for FY25SR-1096
                                    if (currentItemWrapper.entitlementName.startsWith('RBK')) {
                                        quantitymax = quantitymax + currentItemWrapper.quantity;
                                    } else {
                                        quantitymax = quantitymax + assetsAvailable.quantity;
                                    }
                                    currentItemWrapper.selectedquantity = quantitymax;
                                    donotShowadds = true;
                                } else if ( assetsAvailable.selected === false && element.value != 'Full' && currentItemWrapper.customIndex === customIndex ) {
                                    showadds = true;
                                }
                            }
                        });
                    }
                });

                receivedData.forEach((element) => {
                    if (element.value === 'Full' && element.selected === true && currentItemWrapper.customIndex === customIndex) {
                        currentItemWrapper.selectedquantity = maxAllquantityFull;
                        donotShowadds = true;
                        showadds = false;
                    }
                });

                if (currentItemWrapper.customIndex === customIndex) {
                    let assetIdToSelection = new Map();
                    receivedData.forEach((element) => {
                        if (!assetIdToSelection.has(element.value)) {
                        assetIdToSelection.set(element.value, element.selected);
                        }
                    });
                    if (assetIdToSelection != null) {
                        removedFullFromFirstRow = !Array.from(assetIdToSelection.values()).includes(true);
                    }
                }

                if (customIndex === currentItemWrapper.customIndex) {
                    if (showadds === true && assetMap != null) {
                        if (assetMap.size == 1) {
                            currentItemWrapper.showAdd = false;
                        } else if (assetMap.size > 1 && removedFullFromFirstRow === false) {
                            currentItemWrapper.showAdd = true;
                        } else if (removedFullFromFirstRow === true) {
                            currentItemWrapper.showAdd = false;
                        }
                    } else if (showadds === false && donotShowadds === true) {
                        currentItemWrapper.showAdd = false;
                    }

                    currentItemWrapper.isModified = true;
                }
            } else {
                
                if(currentItemWrapper.wrapBaseLicense != undefined){
                    const hasBaseProdFound = currentItemWrapper.wrapBaseLicense.find(ele => ele.customIndex === customIndex);
                    if(hasBaseProdFound) {
                        currentItemWrapper.wrapBaseLicense.forEach(function (currentItemWrapperBaseLicense, index){

                            //There should be no change to the assets if the HW Support lines commes as Base line
                            if(!currentItemWrapperBaseLicense.entitlementName.includes('-HW-')){
                                
                                currentItemWrapperBaseLicense.assetsAvailable.forEach((currWrap, index) => {                                
                                    if (currentItemWrapperBaseLicense.customIndex === customIndex){
                                        if(currWrap.value != 'Full'){
                                                assetMap.set(currWrap.value, currWrap);
                                            }
                                        }
                                });

                                receivedData.forEach((element) => {
                                    if (customIndex === currentItemWrapperBaseLicense.customIndex) {
                                        currentItemWrapperBaseLicense.assetsAvailable.forEach((assetsAvailable) => {
                                            if (assetsAvailable.value === element.value) {
                                                if (
                                                element.value === 'Full' &&
                                                element.selected === false &&
                                                customIndex.split('.')[1] == 0 &&
                                                currentItemWrapperBaseLicense.customIndex === customIndex &&
                                                assetsAvailable.value === 'Full' &&
                                                element.selected != assetsAvailable.selected
                                                ) {
                                                    removedFullFromFirstRow = true;
                                                }
                                                    assetsAvailable.selected = element.selected;
                                                if (
                                                assetsAvailable.selected === true &&
                                                element.value != 'Full' &&
                                                currentItemWrapperBaseLicense.customIndex === customIndex
                                                ) {
                                                    // Added RBK check for FY25SR-1096
                                                    if (currentItemWrapperBaseLicense.entitlementName.startsWith('RBK')) {
                                                        quantitymax = quantitymax + currentItemWrapperBaseLicense.quantity;
                                                    } else {
                                                        quantitymax = quantitymax + assetsAvailable.quantity;
                                                    }
                                                    currentItemWrapperBaseLicense.selectedquantity = quantitymax;
                                                    donotShowadds = true;
                                                } else if (
                                                assetsAvailable.selected === false &&
                                                element.value != 'Full' &&
                                                currentItemWrapperBaseLicense.customIndex === customIndex
                                                ) {
                                                    showadds = true;
                                                }
                                                // maxAllquantity = parseInt(maxAllquantity) + (assetsAvailable.isV1 ? 1 : parseInt(assetsAvailable.quantity));
                                            }
                                        });
                                    }
                                });

                                receivedData.forEach((element) => {
                                    if (element.value === 'Full' && element.selected === true && currentItemWrapperBaseLicense.customIndex === customIndex) {
                                        currentItemWrapperBaseLicense.selectedquantity = maxAllquantityFull;
                                        donotShowadds = true;
                                        showadds = false;
                                    }
                                });

                                if (currentItemWrapperBaseLicense.customIndex === customIndex) {
                                    let assetIdToSelection = new Map();
                                    receivedData.forEach((element) => {
                                        if (!assetIdToSelection.has(element.value)) {
                                        assetIdToSelection.set(element.value, element.selected);
                                        }
                                    });
                                    if (assetIdToSelection != null) {
                                        removedFullFromFirstRow = !Array.from(assetIdToSelection.values()).includes(true);
                                    }
                                }

                                if (customIndex === currentItemWrapperBaseLicense.customIndex) {
                                    if (showadds === true && assetMap != null) {
                                        if (assetMap.size == 1) {
                                            currentItemWrapperBaseLicense.showAdd = false;
                                        } else if (assetMap.size > 1 && removedFullFromFirstRow === false) {
                                            currentItemWrapperBaseLicense.showAdd = true;
                                        } else if (removedFullFromFirstRow === true) {
                                            currentItemWrapperBaseLicense.showAdd = false;
                                        }
                                    } else if (showadds === false && donotShowadds === true) {
                                        currentItemWrapperBaseLicense.showAdd = false;
                                    }

                                    currentItemWrapperBaseLicense.isModified = true;
                                }
                            }


                        });

                        

                    }

                }

                //Addons
                if(currentItemWrapper.wrapAddOnSupportLines != undefined){
                    const hasBaseProdFound = currentItemWrapper.wrapAddOnSupportLines.find(ele => ele.customIndex === customIndex);
                    if(hasBaseProdFound) {
                        currentItemWrapper.wrapAddOnSupportLines.forEach(function (currentItemWrapperAddOnSupport, index){
                            currentItemWrapperAddOnSupport.assetsAvailable.forEach((currWrap, index) => {
                                if (currWrap.value != 'Full' && currentItemWrapperAddOnSupport.customIndex === customIndex) {
                                    assetMap.set(currWrap.value, currWrap);
                                }
                            });

                            receivedData.forEach((element) => {
                                if (customIndex === currentItemWrapperAddOnSupport.customIndex) {
                                    currentItemWrapperAddOnSupport.assetsAvailable.forEach((assetsAvailable) => {
                                        if (assetsAvailable.value === element.value) {
                                            if (
                                            element.value === 'Full' &&
                                            element.selected === false &&
                                            customIndex.split('.')[1] == 0 &&
                                            currentItemWrapperAddOnSupport.customIndex === customIndex &&
                                            assetsAvailable.value === 'Full' &&
                                            element.selected != assetsAvailable.selected
                                            ) {
                                                removedFullFromFirstRow = true;
                                            }
                                                assetsAvailable.selected = element.selected;
                                            if (
                                            assetsAvailable.selected === true &&
                                            element.value != 'Full' &&
                                            currentItemWrapperAddOnSupport.customIndex === customIndex
                                            ) {
                                                // Added RBK check for FY25SR-1096
                                                if (currentItemWrapperBaseLicense.entitlementName.startsWith('RBK')) {
                                                    quantitymax = quantitymax + currentItemWrapperAddOnSupport.quantity;
                                                } else {
                                                    quantitymax = quantitymax + assetsAvailable.quantity;
                                                }
                                                currentItemWrapperAddOnSupport.selectedquantity = quantitymax;
                                                donotShowadds = true;
                                            } else if (
                                            assetsAvailable.selected === false &&
                                            element.value != 'Full' &&
                                            currentItemWrapperAddOnSupport.customIndex === customIndex
                                            ) {
                                                showadds = true;
                                            }
                                            // maxAllquantity = parseInt(maxAllquantity) + (assetsAvailable.isV1 ? 1 : parseInt(assetsAvailable.quantity));
                                        }
                                    });
                                }
                            });


                            receivedData.forEach((element) => {
                                if (element.value === 'Full' && element.selected === true && currentItemWrapperAddOnSupport.customIndex === customIndex) {
                                    currentItemWrapperAddOnSupport.selectedquantity = maxAllquantityFull;
                                    donotShowadds = true;
                                    showadds = false;
                                }
                            });

                            if (currentItemWrapperAddOnSupport.customIndex === customIndex) {
                                let assetIdToSelection = new Map();
                                receivedData.forEach((element) => {
                                    if (!assetIdToSelection.has(element.value)) {
                                    assetIdToSelection.set(element.value, element.selected);
                                    }
                                });
                                if (assetIdToSelection != null) {
                                    removedFullFromFirstRow = !Array.from(assetIdToSelection.values()).includes(true);
                                }
                            }

                            if (customIndex === currentItemWrapperAddOnSupport.customIndex) {
                                if (showadds === true && assetMap != null) {
                                    if (assetMap.size == 1) {
                                        currentItemWrapperAddOnSupport.showAdd = false;
                                    } else if (assetMap.size > 1 && removedFullFromFirstRow === false) {
                                        currentItemWrapperAddOnSupport.showAdd = true;
                                    } else if (removedFullFromFirstRow === true) {
                                        currentItemWrapperAddOnSupport.showAdd = false;
                                    }
                                } else if (showadds === false && donotShowadds === true) {
                                    currentItemWrapperAddOnSupport.showAdd = false;
                                }

                                currentItemWrapperAddOnSupport.isModified = true;
                            }
                        });
                    }
                }
                
                
                //upgrade
                if(currentItemWrapper.wrapUpgradeEnt != undefined){
                    const hasBaseProdFound = currentItemWrapper.wrapUpgradeEnt.find(ele => ele.customIndex === customIndex);
                    if(hasBaseProdFound) {
                        currentItemWrapper.wrapUpgradeEnt.forEach(function (currentItemWrapperUpgradeProd, index){
                            currentItemWrapperUpgradeProd.assetsAvailable.forEach((currWrap, index) => {
                                if (currWrap.value != 'Full' && currentItemWrapperUpgradeProd.customIndex === customIndex) {
                                    assetMap.set(currWrap.value, currWrap);
                                }
                            });

                            receivedData.forEach((element) => {
                                if (customIndex === currentItemWrapperUpgradeProd.customIndex) {
                                    currentItemWrapperUpgradeProd.assetsAvailable.forEach((assetsAvailable) => {
                                        if (assetsAvailable.value === element.value) {
                                            if (
                                            element.value === 'Full' &&
                                            element.selected === false &&
                                            customIndex.split('.')[1] == 0 &&
                                            currentItemWrapperUpgradeProd.customIndex === customIndex &&
                                            assetsAvailable.value === 'Full' &&
                                            element.selected != assetsAvailable.selected
                                            ) {
                                                removedFullFromFirstRow = true;
                                            }
                                                assetsAvailable.selected = element.selected;
                                            if (
                                            assetsAvailable.selected === true &&
                                            element.value != 'Full' &&
                                            currentItemWrapperUpgradeProd.customIndex === customIndex
                                            ) {
                                                // Added RBK check for FY25SR-1096
                                                if (currentItemWrapperBaseLicense.entitlementName.startsWith('RBK')) {
                                                    quantitymax = quantitymax + currentItemWrapperUpgradeProd.quantity;
                                                } else {
                                                    quantitymax = quantitymax + assetsAvailable.quantity;
                                                }
                                                currentItemWrapperUpgradeProd.selectedquantity = quantitymax;
                                                donotShowadds = true;
                                            } else if (
                                            assetsAvailable.selected === false &&
                                            element.value != 'Full' &&
                                            currentItemWrapperUpgradeProd.customIndex === customIndex
                                            ) {
                                                showadds = true;
                                            }
                                            // maxAllquantity = parseInt(maxAllquantity) + (assetsAvailable.isV1 ? 1 : parseInt(assetsAvailable.quantity));
                                        }
                                    });
                                }
                            });

                            receivedData.forEach((element) => {
                                if (element.value === 'Full' && element.selected === true && currentItemWrapperUpgradeProd.customIndex === customIndex) {
                                    currentItemWrapperUpgradeProd.selectedquantity = maxAllquantityFull;
                                    donotShowadds = true;
                                    showadds = false;
                                }
                            });

                            if (currentItemWrapperUpgradeProd.customIndex === customIndex) {
                                let assetIdToSelection = new Map();
                                receivedData.forEach((element) => {
                                    if (!assetIdToSelection.has(element.value)) {
                                    assetIdToSelection.set(element.value, element.selected);
                                    }
                                });
                                if (assetIdToSelection != null) {
                                    removedFullFromFirstRow = !Array.from(assetIdToSelection.values()).includes(true);
                                }
                            }

                            if (customIndex === currentItemWrapperUpgradeProd.customIndex) {
                                if (showadds === true && assetMap != null) {
                                    if (assetMap.size == 1) {
                                        currentItemWrapperUpgradeProd.showAdd = false;
                                    } else if (assetMap.size > 1 && removedFullFromFirstRow === false) {
                                        currentItemWrapperUpgradeProd.showAdd = true;
                                    } else if (removedFullFromFirstRow === true) {
                                        currentItemWrapperUpgradeProd.showAdd = false;
                                    }
                                } else if (showadds === false && donotShowadds === true) {
                                    currentItemWrapperUpgradeProd.showAdd = false;
                                }

                                currentItemWrapperUpgradeProd.isModified = true;
                            }
                        });
                    }
                }
            }
        });

    }

    return displayedData;
}

function setmaxAllquantityFull(receivedData){
    let maxAllquantityFull = 0;
    receivedData.forEach((element) => {
        if (element.value != 'Full') {
            maxAllquantityFull = maxAllquantityFull + element.quantity;
        }
    });
    return maxAllquantityFull;
}

function checkIfFullSelected(receivedData){
    let fullSelected = false;
     receivedData.forEach((element) => {
        if (element.value === 'Full' && element.selected === true) {
            fullSelected = true;
        }
    });
    return fullSelected;
}

// function assignDispoHW(currentItemHWLicence, selectedDispositionReason){
//     currentItemHWLicence.autoDisposition.forEach((currItem) => {
//         if(currItem.value === selectedDispositionReason){
//             currItem.selected = true;
//             currentItemHWLicence.disableDisposition = true;
//             currentItemHWLicence.selecteddisposition = currItem.value;
//         }
//     });
//     currentItemHWLicence.manualDisposition.forEach((currIt) => {
//         currIt.selected = false;
//     });
//     return currentItemHWLicence;
// }