export function endDateFilterChangeEnts(previousDataModified, currentDataModified) {
    let selectedData = JSON.parse(JSON.stringify(previousDataModified));
    let selectedWrapper = [];
    let falseSelected = new Set();
    selectedData.forEach(function (currentItemWrapper, index) {
        let valueSelected = false;
        if(currentItemWrapper.customIndex != null && currentItemWrapper.customIndex != undefined){
            if(currentItemWrapper.rowSelected != undefined && currentItemWrapper.rowSelected == true){
                valueSelected = true;
                selectedWrapper.push(currentItemWrapper);
            }
            if(currentItemWrapper.customIndex != undefined && currentItemWrapper.rowSelected == false){
                  falseSelected.add(currentItemWrapper.customIndex);  
            }
        } else {            
            if(currentItemWrapper.wrapBaseLicense != undefined && currentItemWrapper.wrapBaseLicense.length > 0){
               if(valueSelected == false){
                    valueSelected = returnRowSelected(currentItemWrapper.wrapBaseLicense) == true ? true : false;
                    if(valueSelected == true){selectedWrapper.push(currentItemWrapper);}
               }  
               if(returnFalseSelected(currentItemWrapper.wrapBaseLicense) != undefined && returnFalseSelected(currentItemWrapper.wrapBaseLicense).size > 0){
                    returnFalseSelected(currentItemWrapper.wrapBaseLicense).forEach(item => falseSelected.add(item));
               }                                                
            }
            if(currentItemWrapper.wrapHWSupportLines != undefined && currentItemWrapper.wrapHWSupportLines.length > 0){
                if(valueSelected == false){
                    valueSelected = returnRowSelected(currentItemWrapper.wrapHWSupportLines) == true ? true : false;
                    if(valueSelected == true){selectedWrapper.push(currentItemWrapper);}
               } 
               if(returnFalseSelected(currentItemWrapper.wrapHWSupportLines) != undefined && returnFalseSelected(currentItemWrapper.wrapHWSupportLines).size > 0){
                    returnFalseSelected(currentItemWrapper.wrapHWSupportLines).forEach(item => falseSelected.add(item));
               }                      
            }
            if(currentItemWrapper.wrapUpgradeEnt != undefined && currentItemWrapper.wrapUpgradeEnt.length > 0){
                if(valueSelected == false){
                    valueSelected = returnRowSelected(currentItemWrapper.wrapUpgradeEnt) == true ? true : false;
                    if(valueSelected == true){selectedWrapper.push(currentItemWrapper);}
                } 
                if(returnFalseSelected(currentItemWrapper.wrapUpgradeEnt) != undefined && returnFalseSelected(currentItemWrapper.wrapUpgradeEnt).size > 0){
                    returnFalseSelected(currentItemWrapper.wrapUpgradeEnt).forEach(item => falseSelected.add(item));
               }                      
            }
            if(currentItemWrapper.wrapInactiveEnt != undefined && currentItemWrapper.wrapInactiveEnt.length > 0){
                if(valueSelected == false){
                    valueSelected = returnRowSelected(currentItemWrapper.wrapInactiveEnt) == true ? true : false;
                    if(valueSelected == true){selectedWrapper.push(currentItemWrapper);}
                }   
                if(returnFalseSelected(currentItemWrapper.wrapInactiveEnt) != undefined && returnFalseSelected(currentItemWrapper.wrapInactiveEnt).size > 0){
                    returnFalseSelected(currentItemWrapper.wrapInactiveEnt).forEach(item => falseSelected.add(item));
               }                    
            }
        }
    });
    
    let displayedData = JSON.parse(JSON.stringify(currentDataModified));
    displayedData.forEach(function (currentItemWrapper, index) {
        let valueSelected = false; 
        if(currentItemWrapper.customIndex != null && currentItemWrapper.customIndex != undefined){
            valueSelected =  appendSelected(currentItemWrapper.customIndex.split('.')[0],selectedWrapper);
                    if(valueSelected == false){selectedWrapper.push(currentItemWrapper);}
        } else {                
            if(currentItemWrapper.wrapBaseLicense != undefined && currentItemWrapper.wrapBaseLicense.length > 0 && valueSelected == false){
                    valueSelected =  appendSelected(currentItemWrapper.wrapBaseLicense[0].customIndex.split('.')[0],selectedWrapper);
                    if(valueSelected == false){selectedWrapper.push(currentItemWrapper);}                    
            }
            if(currentItemWrapper.wrapHWSupportLines != undefined && currentItemWrapper.wrapHWSupportLines.length > 0 && valueSelected == false){
                    valueSelected =  appendSelected(currentItemWrapper.wrapHWSupportLines[0].customIndex.split('.')[0],selectedWrapper);
                    if(valueSelected == false){selectedWrapper.push(currentItemWrapper);}  
            }
            if(currentItemWrapper.wrapUpgradeEnt != undefined && currentItemWrapper.wrapUpgradeEnt.length > 0 && valueSelected == false){
                    valueSelected =  appendSelected(currentItemWrapper.wrapUpgradeEnt[0].customIndex.split('.')[0],selectedWrapper);
                    if(valueSelected == false){selectedWrapper.push(currentItemWrapper);}  
                } 
            if(currentItemWrapper.wrapInactiveEnt != undefined && currentItemWrapper.wrapInactiveEnt.length > 0 && valueSelected == false){
                    valueSelected =  appendSelected(currentItemWrapper.wrapInactiveEnt[0].customIndex.split('.')[0],selectedWrapper);
                    if(valueSelected == false){selectedWrapper.push(currentItemWrapper);}  
                }
        }
    });

    let finalData = JSON.parse(JSON.stringify(selectedWrapper));
    finalData.forEach(function (currentItemWrapper, index) {
        if(currentItemWrapper.customIndex != null && currentItemWrapper.customIndex != undefined){
            if(currentItemWrapper.rowSelected == true && falseSelected != undefined && falseSelected.has(currentItemWrapper.customIndex)){
                currentItemWrapper.rowSelected = false;
            }
        } else {                
            if(currentItemWrapper.wrapBaseLicense != undefined && currentItemWrapper.wrapBaseLicense.length > 0){
                    currentItemWrapper.wrapBaseLicense =  checkRowSelected(currentItemWrapper.wrapBaseLicense, falseSelected)         
            }
            if(currentItemWrapper.wrapHWSupportLines != undefined && currentItemWrapper.wrapHWSupportLines.length > 0){
                    currentItemWrapper.wrapHWSupportLines =  checkRowSelected(currentItemWrapper.wrapHWSupportLines, falseSelected)
            }
            if(currentItemWrapper.wrapUpgradeEnt != undefined && currentItemWrapper.wrapUpgradeEnt.length > 0){
                    currentItemWrapper.wrapUpgradeEnt =  checkRowSelected(currentItemWrapper.wrapUpgradeEnt, falseSelected)
                } 
            if(currentItemWrapper.wrapInactiveEnt != undefined && currentItemWrapper.wrapInactiveEnt.length > 0){
                    currentItemWrapper.wrapInactiveEnt =  checkRowSelected(currentItemWrapper.wrapInactiveEnt, falseSelected)
                }
        }
    });
    return finalData;
}

function returnRowSelected(currentItemWrapper){
    let valueSelected = false;
    currentItemWrapper.forEach(function (currItem){
            if(currItem.rowSelected == true){
                valueSelected = true;
            }
    });
    return valueSelected;
}

function checkRowSelected(currentItemWrapper,falseSelected){
    currentItemWrapper.forEach(function (currItem){
        if(currItem.rowSelected == true && falseSelected != undefined && falseSelected.has(currItem.customIndex)){
                currItem.rowSelected = false;
        }            
    });
    return currentItemWrapper;
}

function returnFalseSelected(currentItemWrapper){
    let falseSet = new Set();
    currentItemWrapper.forEach(function (currItem){
            if(currItem.customIndex != undefined && currItem.rowSelected == false){
                  falseSet.add(currItem.customIndex);  
            }
    });
    return falseSet;
}

function appendSelected(customSplit, selectedWrapper){
    let rowFound = false;
    let selectedData = JSON.parse(JSON.stringify(selectedWrapper));
    selectedData.forEach(function (currentItemWrapper, index){
        if(currentItemWrapper.customIndex != null && currentItemWrapper.customIndex != undefined){
                if(customSplit === currentItemWrapper.customIndex.split('.')[0]){rowFound = true;}
        }else{
            if(currentItemWrapper.wrapBaseLicense != undefined && currentItemWrapper.wrapBaseLicense.length > 0){
                    if(customSplit === currentItemWrapper.wrapBaseLicense[0].customIndex.split('.')[0]){rowFound = true;}              
            }
            if(currentItemWrapper.wrapHWSupportLines != undefined && currentItemWrapper.wrapHWSupportLines.length > 0){
                    if(customSplit === currentItemWrapper.wrapHWSupportLines[0].customIndex.split('.')[0]){rowFound = true;}    
            }
            if(currentItemWrapper.wrapUpgradeEnt != undefined && currentItemWrapper.wrapUpgradeEnt.length > 0){
                    if(customSplit === currentItemWrapper.wrapUpgradeEnt[0].customIndex.split('.')[0]){rowFound = true;}     
            } 
            if(currentItemWrapper.wrapInactiveEnt != undefined && currentItemWrapper.wrapInactiveEnt.length > 0){
                    if(customSplit === currentItemWrapper.wrapInactiveEnt[0].customIndex.split('.')[0]){rowFound = true;}     
            } 
        }
    });
    return rowFound;
}