export function assignDataToColumns(event,datamodified, pickListChange) {
    let displayedData = JSON.parse(JSON.stringify(datamodified));
        let customIndex = event.target.dataset.customIndex;
        displayedData.forEach(currentItemWrapper => {
                currentItemWrapper.columns.forEach(currItem =>{
                    if(customIndex === currItem.skuRowCustomIndex){
                        currItem.fieldValue = event.detail.value;
                        if(pickListChange == true){
                            currItem.pickValues.forEach(currPick =>{
                                currPick.selected = false;
                                if(currPick.value === event.detail.value){
                                    currPick.selected = true;                                
                                }
                             })
                        }
                        
                    }
                });
        });
    return displayedData;
}

export function initialLoadValidation(datamodified, ent, rowVal, rowSelParentMap, customIndex, quantitySumSource, customErrorMessages) {    
    let displayedData = JSON.parse(JSON.stringify(datamodified));
        displayedData.forEach(currentItemWrapper => {
                currentItemWrapper.columns.forEach(currItem =>{                    
                    if(currItem.fieldApiName === 'Storage_Tier__c' || currItem.fieldApiName === 'Storage_Region_Bundle_FrontEnd__c'){                                   
                                currItem.errorOccured = true;
                                customErrorMessages.forEach(currentItem => {
                                if(currentItem.Message_Label__c === 'Mandatory_Selection'){
                                        currItem.errorMessage = currentItem.Error_Message__c;
                                    }                                
                                });
                     }
                    if(currItem.fieldApiName === 'Salesforce_Quantity__c'){
                        if(rowSelParentMap.has(currItem.fieldApiName) && rowSelParentMap.get(currItem.fieldApiName) != 'null' && rowSelParentMap.get(currItem.fieldApiName) != undefined && 
                                                rowSelParentMap.get(currItem.fieldApiName) !=null){
                            currItem.fieldValue = rowSelParentMap.get(currItem.fieldApiName);                      
                        }  
                        if(currItem.fieldValue == null || currItem.fieldValue == undefined || currItem.fieldValue =='null'){
                                currItem.fieldValue = 0;                              
                        }                      
                    }
                    if(currItem.fieldApiName === 'Rubrik_Hosted_M365_Quantity__c'){
                        if(rowSelParentMap.has(currItem.fieldApiName) && rowSelParentMap.get(currItem.fieldApiName) != 'null' && rowSelParentMap.get(currItem.fieldApiName) != undefined && 
                                                rowSelParentMap.get(currItem.fieldApiName) !=null){
                            currItem.fieldValue = rowSelParentMap.get(currItem.fieldApiName);                      
                        }
                        if(currItem.fieldValue == null || currItem.fieldValue == undefined || currItem.fieldValue =='null'){
                                currItem.fieldValue = 0;
                        } 
                    }
                    if(currItem.fieldApiName === 'Atlassian_Quantity__c'){
                        if(rowSelParentMap.has(currItem.fieldApiName) && rowSelParentMap.get(currItem.fieldApiName) != 'null' && rowSelParentMap.get(currItem.fieldApiName) != undefined && 
                                                rowSelParentMap.get(currItem.fieldApiName) !=null){
                            currItem.fieldValue = rowSelParentMap.get(currItem.fieldApiName);                      
                        }
                        if(currItem.fieldValue == null || currItem.fieldValue == undefined || currItem.fieldValue =='null'){
                                currItem.fieldValue = 0;
                        } 
                    }
                    if(currItem.fieldApiName === 'Dynamics_Quantity__c'){
                        if(rowSelParentMap.has(currItem.fieldApiName) && rowSelParentMap.get(currItem.fieldApiName) != 'null' && rowSelParentMap.get(currItem.fieldApiName) != undefined && 
                                                rowSelParentMap.get(currItem.fieldApiName) !=null){
                            currItem.fieldValue = rowSelParentMap.get(currItem.fieldApiName);                      
                        }
                        if(currItem.fieldValue == null || currItem.fieldValue == undefined || currItem.fieldValue =='null'){
                                currItem.fieldValue = 0;
                        } 
                    }   
                    if(currItem.fieldApiName === 'Google_Workspace_Quantity__c'){
                        if(rowSelParentMap.has(currItem.fieldApiName) && rowSelParentMap.get(currItem.fieldApiName) != 'null' && rowSelParentMap.get(currItem.fieldApiName) != undefined && 
                                                rowSelParentMap.get(currItem.fieldApiName) !=null){
                            currItem.fieldValue = rowSelParentMap.get(currItem.fieldApiName);                      
                        }
                        if(currItem.fieldValue == null || currItem.fieldValue == undefined || currItem.fieldValue =='null'){
                                currItem.fieldValue = 0;
                        } 
                    }   

                    if(ent.skuProductId != undefined &&  ent.skuProductId === rowVal.productId){
                        if(rowVal.childMappingSKUattributes != undefined &&
                                    rowVal.childMappingSKUattributes.hasOwnProperty(currItem.fieldApiName)){
                            currItem.fieldValue = rowVal.childMappingSKUattributes[currItem.fieldApiName];
                            currItem.errorOccured = false;
                            currItem.errorMessage = '';
                            if(currItem.pickValues != undefined && currItem.pickValues.length >0){
                                currItem.pickValues.forEach(currPick =>{
                                    currPick.selected = false;
                                    if(currPick.value === rowVal.childMappingSKUattributes[currItem.fieldApiName]){
                                        currPick.selected = true;                                
                                    }
                                });
                            }                            
                        }
                    }   

                });
        });
    console.log('return from validation load ' , JSON.stringify(displayedData));
    return displayedData;
}


export function checkValidations(datamodified, rowsel, ent,rowSelParentMap,customErrorMessages) {     
    let displayedData = JSON.parse(JSON.stringify(datamodified));     
        displayedData.forEach(currentItemWrapper => {
                currentItemWrapper.columns.forEach(currItem =>{
                    if(currItem.fieldApiName === 'Storage_Tier__c' && (currItem.fieldValue == null || currItem.fieldValue == undefined || currItem.fieldValue =='null')){
                        currItem.errorOccured = true;
                        customErrorMessages.forEach(currentItem => {
                        if(currentItem.Message_Label__c === 'Storage_Tier_Mandatory'){
                                currItem.errorMessage = currentItem.Error_Message__c;
                            }                                
                        });
                    }else if(currItem.fieldApiName === 'Storage_Region_Bundle_FrontEnd__c' && (currItem.fieldValue == null || currItem.fieldValue == undefined || currItem.fieldValue =='null')){
                        currItem.errorOccured = true;
                        customErrorMessages.forEach(currentItem => {
                        if(currentItem.Message_Label__c === 'Storage_Region_Bundle_Mandatory'){
                                currItem.errorMessage = currentItem.Error_Message__c;
                            }                                
                        });
                    }else if((currItem.fieldApiName === 'Storage_Region_Bundle_FrontEnd__c' || currItem.fieldApiName === 'Storage_Tier__c') && rowsel.productId === ent.productId && currItem.fieldValue != null && currItem.fieldValue != undefined && currItem.fieldValue !='null'){
                            if(rowSelParentMap.has(currItem.fieldApiName) && rowSelParentMap.get(currItem.fieldApiName) != 'null' && rowSelParentMap.get(currItem.fieldApiName) != undefined && 
                                                rowSelParentMap.get(currItem.fieldApiName) !=null && rowSelParentMap.get(currItem.fieldApiName) === currItem.fieldValue){
                                    currItem.errorOccured = true;
                                    customErrorMessages.forEach(currentItem => {
                                    if(currentItem.Message_Label__c === 'Source_and_Destination_Cannot_be_Same'){
                                            currItem.errorMessage = currentItem.Error_Message__c;
                                        }                                
                                    });
                            }else{
                                currItem.errorOccured = false;
                                currItem.errorMessage = '';
                            }
                    }else if(currItem.fieldApiName === 'Storage_Tier__c' || currItem.fieldApiName === 'Storage_Region_Bundle_FrontEnd__c'){
                        currItem.errorOccured = false;
                        currItem.errorMessage = '';
                    }
                });
        });
        console.log('return from check validation load ' , JSON.stringify(displayedData));
    return displayedData;
}

export function assignQuantityParent(currItem, rowsel,quantitySumSource,rowSelParentMap){    
    if(rowSelParentMap.has(currItem.fieldApiName) && rowSelParentMap.get(currItem.fieldApiName) != 'null' && rowSelParentMap.get(currItem.fieldApiName) != undefined && 
                                rowSelParentMap.get(currItem.fieldApiName) !=null){
                                    quantitySumSource = parseInt(quantitySumSource)+parseInt(rowSelParentMap.get(currItem.fieldApiName)); 
                                }
    return quantitySumSource;
}