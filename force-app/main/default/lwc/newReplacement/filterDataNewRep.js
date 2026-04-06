export function dataFilter(dataModified, entSearchString, entStartDate, entEndDate, entOrderNumber, entAssetsearchStr, defStartDate, defEndData,entitlementFilter) {
      
        let displayedData = JSON.parse(JSON.stringify(dataModified));
        let entitlementSearchString = entSearchString || '';
        let startDate = entStartDate;
        let endDate = entEndDate;
        let entitlementOrderNumberSearchString = entOrderNumber || '';
        let entitlementAssetSearchString = entAssetsearchStr || '';
        let entitlementUpgradeSet = new Set();
        let localdata = [];
        let mapArrayList = [];
        let entSetUg = new Set();
        displayedData.forEach((currentItemWrapper, index) => {
          if(currentItemWrapper.entitlementId != null){
              currentItemWrapper  = convertEntitlementnameToLowerCaseEachWrapper(currentItemWrapper);
          } else {
              //Added as part of FY25SR-1207 - Start
              if(currentItemWrapper.mapAssetEntitlements != undefined && currentItemWrapper.mapAssetEntitlements.futureValues.length > 0){
                  currentItemWrapper.mapAssetEntitlements.futureValues = convertEntitlementnameToLowerCaseList(currentItemWrapper.mapAssetEntitlements.futureValues);
              } 
              //Added as part of FY25SR-1207 - END

              if(currentItemWrapper.wrapBaseLicense != undefined && currentItemWrapper.wrapBaseLicense.length > 0){
                  currentItemWrapper.wrapBaseLicense = convertEntitlementnameToLowerCaseList(currentItemWrapper.wrapBaseLicense);
              }
              
              if(currentItemWrapper.wrapHWSupportLines != undefined && currentItemWrapper.wrapHWSupportLines.length > 0){
                  currentItemWrapper.wrapHWSupportLines = convertEntitlementnameToLowerCaseList(currentItemWrapper.wrapHWSupportLines);
              }
  
              if(currentItemWrapper.wrapUpgradeEnt != undefined &&  currentItemWrapper.wrapUpgradeEnt.length > 0){
                  currentItemWrapper.wrapUpgradeEnt = convertEntitlementnameToLowerCaseList(currentItemWrapper.wrapUpgradeEnt);
                  currentItemWrapper.wrapUpgradeEnt.forEach(function (currentItemUpgLicence, index){
                        if(entitlementAssetSearchString != undefined && entitlementAssetSearchString.length >0){
                              currentItemUpgLicence.assetsAvailable.filter((asset) => {
                              let isAssetNameTrue = false;
                              let isAssetUpgEnt = asset.label.toLowerCase().indexOf(entitlementAssetSearchString.toLowerCase()) !== -1;
                              if (isAssetNameTrue === false && (isAssetUpgEnt != isAssetNameTrue || (!entitlementAssetSearchString && currentItemUpgLicence.rowSelected == true))) {//CPQ22-6389
                                  isAssetNameTrue = true;
                                  if (currentItemWrapper.baseProdIds !== undefined) {
                                      const baseProdIdsArray = currentItemWrapper.baseProdIds.split(',').map(id => id.trim());
                                      baseProdIdsArray.forEach(id => entSetUg.add(id));
                                  }
                              }
                          });
                        }
                  });

              }

              if(currentItemWrapper.wrapInactiveEnt != undefined &&  currentItemWrapper.wrapInactiveEnt.length > 0){
                  currentItemWrapper.wrapInactiveEnt = convertEntitlementnameToLowerCaseList(currentItemWrapper.wrapInactiveEnt);
              }
          } 
        });
        
        if (
          entitlementAssetSearchString != null &&
          entitlementAssetSearchString !== undefined &&
          entitlementAssetSearchString != ''
        ) {
          let definedSet = new Set();
          let upgradeEntSet = new Set();
          displayedData.forEach((currentItemWrapper, index) => {
            if(currentItemWrapper.entitlementId != null){
                if(!entitlementAssetSearchString && currentItemWrapper.rowSelected == true && !definedSet.has(currentItemWrapper.customIndex.split('.')[0])){//CPQ22-6389
                        definedSet.add(currentItemWrapper.customIndex.split('.')[0]);
                        mapArrayList.push(currentItemWrapper);
                }else{
                    currentItemWrapper.assetsAvailable.filter((asset) => {
                      let isAssetNameTrue = false;
                      isAssetNameTrue = asset.label.toLowerCase().indexOf(entitlementAssetSearchString.toLowerCase()) !== -1;
                      if (isAssetNameTrue === true) {
                        mapArrayList.push(currentItemWrapper);
                      }                
                  })
                }
                ;
          } else {
            let isAssetNameTrue = false;  
              if(currentItemWrapper.wrapBaseLicense != undefined && currentItemWrapper.wrapBaseLicense.length > 0){                  
                  currentItemWrapper.wrapBaseLicense.forEach(function (currentItemBaseLicence, index){
                    if(isAssetNameTrue == false && !entitlementAssetSearchString && currentItemBaseLicence.rowSelected == true && !definedSet.has(currentItemBaseLicence.customIndex.split('.')[0])){//CPQ22-6389
                        definedSet.add(currentItemBaseLicence.customIndex.split('.')[0]);
                        mapArrayList.push(currentItemWrapper);
                        isAssetNameTrue = true;
                        if(currentItemBaseLicence.entitlementId != undefined){ entitlementUpgradeSet.add(currentItemBaseLicence.entitlementId) };
                    }else if(!entitlementAssetSearchString && entSetUg != undefined && !definedSet.has(currentItemBaseLicence.customIndex.split('.')[0]) &&  //CPQ22-6389
                                 currentItemBaseLicence.entitlementId != undefined && entSetUg.has(currentItemBaseLicence.entitlementId)){
                        definedSet.add(currentItemBaseLicence.customIndex.split('.')[0]);
                        mapArrayList.push(currentItemWrapper);
                    }else{
                      currentItemBaseLicence.assetsAvailable.filter((asset) => {                      
                        let assetBase = asset.label.toLowerCase().indexOf(entitlementAssetSearchString.toLowerCase()) !== -1;
                        if (isAssetNameTrue === false && assetBase != isAssetNameTrue && !definedSet.has(currentItemBaseLicence.customIndex.split('.')[0])) {
                          mapArrayList.push(currentItemWrapper);
                          definedSet.add(currentItemBaseLicence.customIndex.split('.')[0]);
                          isAssetNameTrue = true;
                          if(currentItemBaseLicence.entitlementId != undefined){ entitlementUpgradeSet.add(currentItemBaseLicence.entitlementId) };
                        }
                      });
                    }                     
                  });
              }

              if(currentItemWrapper.mapAssetEntitlements != undefined && currentItemWrapper.mapAssetEntitlements.futureValues.length > 0){
                    currentItemWrapper.mapAssetEntitlements.futureValues.forEach(function (currentItemBaseLicence, index){
                          currentItemBaseLicence.assetsAvailable.filter((asset) => {                      
                                let assetBase = asset.label.toLowerCase().indexOf(entitlementAssetSearchString.toLowerCase()) !== -1;
                                if (isAssetNameTrue === false && assetBase != isAssetNameTrue && !definedSet.has(currentItemBaseLicence.customIndex.split('.')[0])) {
                                  mapArrayList.push(currentItemWrapper);
                                  definedSet.add(currentItemBaseLicence.customIndex.split('.')[0]);
                                  isAssetNameTrue = true;
                                }
                          });
                    });
              }
                    
              if(currentItemWrapper.wrapHWSupportLines != undefined && currentItemWrapper.wrapHWSupportLines.length > 0){
                  currentItemWrapper.wrapHWSupportLines.forEach(function (currentItemHWLicence, index){
                    if(isAssetNameTrue == false && !entitlementAssetSearchString && currentItemHWLicence.rowSelected == true && !definedSet.has(currentItemHWLicence.customIndex.split('.')[0])){//CPQ22-6389
                        definedSet.add(currentItemHWLicence.customIndex.split('.')[0]);
                        mapArrayList.push(currentItemWrapper);
                        isAssetNameTrue == true;
                    }else{
                        currentItemHWLicence.assetsAvailable.filter((asset) => {
                          let isAssetHW = asset.label.toLowerCase().indexOf(entitlementAssetSearchString.toLowerCase()) !== -1;
                          if (isAssetNameTrue === false && isAssetHW != isAssetNameTrue  && !definedSet.has(currentItemHWLicence.customIndex.split('.')[0])) {
                            mapArrayList.push(currentItemWrapper);
                            definedSet.add(currentItemHWLicence.customIndex.split('.')[0]);
                            isAssetNameTrue = true;
                            if(currentItemWrapper.wrapBaseLicense != undefined && currentItemWrapper.wrapBaseLicense.length > 0){
                                currentItemWrapper.wrapBaseLicense.forEach(function (currentItemBaseLicence, index){
                                      if(currentItemBaseLicence.entitlementId != undefined){ entitlementUpgradeSet.add(currentItemBaseLicence.entitlementId) };
                                });
                            }
                          }
                      });
                    }                      
                  });
              }
  
              if(currentItemWrapper.wrapUpgradeEnt != undefined && currentItemWrapper.wrapUpgradeEnt.length > 0){ 
                  let isUpgradeRow = false;
                  if(currentItemWrapper.baseProdIds != undefined){
                        const baseProdIdsArray = currentItemWrapper.baseProdIds.split(',').map(id => id.trim());
                        upgradeEntSet = new Set(baseProdIdsArray);
                        isUpgradeRow = upgradeRowCheck(upgradeEntSet, entitlementUpgradeSet);
                  }
                  currentItemWrapper.wrapUpgradeEnt.forEach(function (currentItemUpgLicence, index){
                    if(isAssetNameTrue == false && !entitlementAssetSearchString && currentItemUpgLicence.rowSelected == true && !definedSet.has(currentItemUpgLicence.customIndex.split('.')[0])){//CPQ22-6389
                        definedSet.add(currentItemUpgLicence.customIndex.split('.')[0]);
                        mapArrayList.push(currentItemWrapper);
                        isAssetNameTrue == true;
                    }else if(isUpgradeRow == true && !definedSet.has(currentItemUpgLicence.customIndex.split('.')[0])){
                        mapArrayList.push(currentItemWrapper);
                        definedSet.add(currentItemUpgLicence.customIndex.split('.')[0]);
                      }
                    else{
                        currentItemUpgLicence.assetsAvailable.filter((asset) => {
                            let isAssetUpgEnt = asset.label.toLowerCase().indexOf(entitlementAssetSearchString.toLowerCase()) !== -1;
                            if (isAssetNameTrue === false && isAssetUpgEnt != isAssetNameTrue && !definedSet.has(currentItemUpgLicence.customIndex.split('.')[0])) {
                              mapArrayList.push(currentItemWrapper);
                              definedSet.add(currentItemUpgLicence.customIndex.split('.')[0]);
                              isAssetNameTrue = true;
                            }
                        });
                    } 
                  });
              } 
              
              if(currentItemWrapper.wrapInactiveEnt != undefined && currentItemWrapper.wrapInactiveEnt.length > 0){
                  currentItemWrapper.wrapInactiveEnt.forEach(function (currentItemUpgLicence, index){

                    if(isAssetNameTrue == false && !entitlementAssetSearchString && currentItemUpgLicence.rowSelected == true && !definedSet.has(currentItemUpgLicence.customIndex.split('.')[0])){
                        definedSet.add(currentItemUpgLicence.customIndex.split('.')[0]);
                        mapArrayList.push(currentItemWrapper);
                        isAssetNameTrue == true;
                    }else{
                      currentItemUpgLicence.assetsAvailable.filter((asset) => {
                          let isAssetUpgEnt = asset.label.toLowerCase().indexOf(entitlementAssetSearchString.toLowerCase()) !== -1;
                          if (isAssetNameTrue === false && isAssetUpgEnt != isAssetNameTrue && !definedSet.has(currentItemUpgLicence.customIndex.split('.')[0])) {
                            mapArrayList.push(currentItemWrapper);
                            definedSet.add(currentItemUpgLicence.customIndex.split('.')[0]);
                            isAssetNameTrue = true;
                          }
                      });
                    }                      
                  });
              } 
            }
    
            });
            if (mapArrayList != null) {
              localdata = filterSearchData(mapArrayList,entitlementSearchString,startDate,endDate,entitlementOrderNumberSearchString);            
            }
          } else {
                localdata = filterSearchData(displayedData,entitlementSearchString,startDate,endDate,entitlementOrderNumberSearchString);
            }
  
        if (
          entitlementAssetSearchString.length === 0 &&
          entitlementOrderNumberSearchString.length === 0 &&
         (startDate === undefined || startDate == null) &&
         (endDate === undefined || endDate == null) &&
          entitlementSearchString.length === 0 
            ) {
          localdata = displayedData;
        }
      // Apply entitlementFilter modes as a final step so it composes with other search filters
      if(entitlementFilter){
        localdata = applyEntitlementFilterSettings(entitlementFilter,localdata);
      }
      return localdata;
      // }         
}

/** CPQ22-6380
   * Optimized: update per-wrapper show* flags according to mode and return
   * an array of wrappers that have at least one visible row under those flags.
   *
   * - Single pass over this.dataModified.
   * - Returns filtered wrappers for callers that need them (caller may ignore).
   */
  function applyEntitlementFilterSettings(entitlementFilter,localdata) {
    if (!Array.isArray(localdata)) return [];

    const hasArr = (w, prop) => Array.isArray(w[prop]) && w[prop].length > 0;
    const hasMapAssets = w => w && w.mapAssetEntitlements && Array.isArray(w.mapAssetEntitlements.futureValues) && w.mapAssetEntitlements.futureValues.length > 0;

    // HW_ONLY: show only wrappers that contain HW support; set flags so UI renders only HW rows.
    if (entitlementFilter === 'HW_ONLY') {
      const hwOnly = localdata.reduce((acc, w) => {
        const hasHW = hasArr(w, 'wrapHWSupportLines');
        // Set flags explicitly: show only hw
        w.showwrapHWSupportLines = hasHW;
        w.showwrapBaseLicense = false;
        w.showwrapAddOnSupportLines = false;
        w.showwrapInactiveEnt = false;
        w.showwrapUpgradeEnt = false;
        w.showmapAssetEntitlements = false;
        if (hasHW) acc.push(w);
        return acc;
      }, []);
      return hwOnly;
    }

    // HIDE_HW or ALL: do not remove wrappers — just toggle visibility of HW rows (and ensure other flags reflect presence)
    const result = localdata.map(w => {
      const hasHW = hasArr(w, 'wrapHWSupportLines');
      if (entitlementFilter === 'HIDE_HW' && hasHW) {
        w.showwrapHWSupportLines = false;
      } else {
        w.showwrapHWSupportLines = hasHW;
      }

      w.showwrapBaseLicense = hasArr(w, 'wrapBaseLicense');
      w.showwrapAddOnSupportLines = hasArr(w, 'wrapAddOnSupportLines');
      w.showwrapInactiveEnt = hasArr(w, 'wrapInactiveEnt');
      w.showwrapUpgradeEnt = hasArr(w, 'wrapUpgradeEnt');
      w.showmapAssetEntitlements = hasMapAssets(w);
      return w;
    });

    return result;
  }
function convertEntitlementnameToLowerCaseList(currentItemWrapper){
    currentItemWrapper.forEach(function (element, index){
        element = convertEntitlementnameToLowerCaseEachWrapper(element);
    });
    return currentItemWrapper;
}

function convertEntitlementnameToLowerCaseEachWrapper(element){
  if(element.entitlementName != undefined && element.entitlementName.toLowerCase()){
            element.currEntNameLower = element.entitlementName.toLowerCase();
      }
  if (element.entitlementOrderNumber === undefined) {
              element.entitlementOrderNumber = '';
  }
    return element;
}

function filterSearchData(displayedData,entitlementSearchString,startDate,endDate,entitlementOrderNumberSearchString){

let entUpgset = new Set();
let upgradeEnt = new Set();
const bothSearchBlank = !entitlementSearchString && !entitlementOrderNumberSearchString;

let entBeforeUpgrade = new Set();
let upgradeData= JSON.parse(JSON.stringify(displayedData));
let upgradeDataFilter = upgradeData.filter((currentItemWrapper) => {
            let isNameFilterAssetTrue; 
            let isStartDateFilterTrue;
            let isEndDateFilterTrue;        
            let isOrderNumberTrue;
            let isRowSelected;
            let isProdOrOrderMatch; 

            if(currentItemWrapper.wrapUpgradeEnt != undefined && currentItemWrapper.wrapUpgradeEnt.length > 0){
                  currentItemWrapper.wrapUpgradeEnt.forEach(function (currentItemUpgLicence, index){
                        isNameFilterAssetTrue = isNameFilterAssetTrue != undefined && isNameFilterAssetTrue == true ? true : currentItemUpgLicence.currEntNameLower.indexOf(entitlementSearchString.toLowerCase()) !== -1;
                        isStartDateFilterTrue = true;
                        isEndDateFilterTrue = true;
                        isOrderNumberTrue = isOrderNumberTrue != undefined && isOrderNumberTrue == true ? true : currentItemUpgLicence.entitlementOrderNumber.indexOf(entitlementOrderNumberSearchString) !== -1;
                        isRowSelected = isRowSelected != undefined && isRowSelected == true ? true : currentItemUpgLicence.rowSelected;
                        isProdOrOrderMatch = isProdOrOrderMatch == true ? true :(entitlementSearchString && currentItemUpgLicence.currEntNameLower.indexOf(entitlementSearchString.toLowerCase()) !== -1) || (entitlementOrderNumberSearchString && currentItemUpgLicence.entitlementOrderNumber.indexOf(entitlementOrderNumberSearchString) !== -1);

                        if((isNameFilterAssetTrue &&
                            isOrderNumberTrue &&
                            isStartDateFilterTrue &&
                            isEndDateFilterTrue)|| (isRowSelected && (bothSearchBlank||isProdOrOrderMatch))){
                            //||isRowSelected - CPQ22-6009
                                if (currentItemWrapper.baseProdIds !== undefined) {
                                    const baseProdIdsArray = currentItemWrapper.baseProdIds.split(',').map(id => id.trim());
                                    baseProdIdsArray.forEach(id => entBeforeUpgrade.add(id));
                                }
                        }
                  });
          }
});


let localdata = displayedData.filter((currentItemWrapper) => {
            let isNameFilterAssetTrue; 
            let isStartDateFilterTrue;
            let isEndDateFilterTrue;        
            let isOrderNumberTrue;
            let isRowSelected;
            let isUpgradeRow = false;
            let isProdOrOrderMatch;             

            if(currentItemWrapper.entitlementId != null){
                isNameFilterAssetTrue = currentItemWrapper.currEntNameLower.indexOf(entitlementSearchString.toLowerCase()) !== -1;
                isStartDateFilterTrue = startDate ? currentItemWrapper.EndDate >= startDate : true;
                isEndDateFilterTrue = endDate ? currentItemWrapper.EndDate <= endDate : true;         
                isOrderNumberTrue = currentItemWrapper.entitlementOrderNumber.indexOf(entitlementOrderNumberSearchString) !== -1;
                isRowSelected = isRowSelected != undefined && isRowSelected == true ? true : currentItemWrapper.rowSelected;
                isProdOrOrderMatch = isProdOrOrderMatch == true ? true :(entitlementSearchString && currentItemWrapper.currEntNameLower.indexOf(entitlementSearchString.toLowerCase()) !== -1) || (entitlementOrderNumberSearchString && currentItemWrapper.entitlementOrderNumber.indexOf(entitlementOrderNumberSearchString) !== -1);
            } else {
             
              //Added as part of FY25SR-1207 - Start
                if(currentItemWrapper.mapAssetEntitlements != undefined && currentItemWrapper.mapAssetEntitlements.futureValues.length > 0){
                      currentItemWrapper.mapAssetEntitlements.futureValues.forEach(function (currentItemBaseLicence, index){
                        isNameFilterAssetTrue = isNameFilterAssetTrue != undefined && isNameFilterAssetTrue == true ? true : currentItemBaseLicence.currEntNameLower.indexOf(entitlementSearchString.toLowerCase()) !== -1;
                        isStartDateFilterTrue = isStartDateFilterTrue != undefined && isStartDateFilterTrue == true ? true : (startDate ? currentItemBaseLicence.EndDate >= startDate : true);
                        isEndDateFilterTrue = isEndDateFilterTrue != undefined && isEndDateFilterTrue == true ? true : (endDate ? currentItemBaseLicence.EndDate <= endDate : true);         
                        isOrderNumberTrue = isOrderNumberTrue != undefined && isOrderNumberTrue == true ? true :  currentItemBaseLicence.entitlementOrderNumber.indexOf(entitlementOrderNumberSearchString) !== -1;
                        isRowSelected = isRowSelected != undefined && isRowSelected == true ? true : currentItemBaseLicence.rowSelected;
                        isProdOrOrderMatch = isProdOrOrderMatch == true ? true : (entitlementSearchString && currentItemBaseLicence.currEntNameLower.indexOf(entitlementSearchString.toLowerCase()) !== -1) || (entitlementOrderNumberSearchString && currentItemBaseLicence.entitlementOrderNumber.indexOf(entitlementOrderNumberSearchString) !== -1);

                        if((isNameFilterAssetTrue &&
                            isOrderNumberTrue &&
                            isStartDateFilterTrue &&
                            isEndDateFilterTrue)|| (isRowSelected && (bothSearchBlank||isProdOrOrderMatch))){
                            //||isRowSelected - CPQ22-6009
                                if(currentItemBaseLicence.entitlementId != undefined){entUpgset.add(currentItemBaseLicence.entitlementId);}
                            }

                        });
              } 
              //Added as part of FY25SR-1207 - END

              if(currentItemWrapper.wrapBaseLicense != undefined && currentItemWrapper.wrapBaseLicense.length > 0){
                    currentItemWrapper.wrapBaseLicense.forEach(function (currentItemBaseLicence, index){
                        isNameFilterAssetTrue = isNameFilterAssetTrue != undefined && isNameFilterAssetTrue == true ? true : currentItemBaseLicence.currEntNameLower.indexOf(entitlementSearchString.toLowerCase()) !== -1;
                        isStartDateFilterTrue = isStartDateFilterTrue != undefined && isStartDateFilterTrue == true ? true : (startDate ? currentItemBaseLicence.EndDate >= startDate : true);
                        isEndDateFilterTrue = isEndDateFilterTrue != undefined && isEndDateFilterTrue == true ? true : (endDate ? currentItemBaseLicence.EndDate <= endDate : true);         
                        isOrderNumberTrue = isOrderNumberTrue != undefined && isOrderNumberTrue == true ? true :  currentItemBaseLicence.entitlementOrderNumber.indexOf(entitlementOrderNumberSearchString) !== -1;
                        isRowSelected = isRowSelected != undefined && isRowSelected == true ? true : currentItemBaseLicence.rowSelected;
                        isProdOrOrderMatch = isProdOrOrderMatch == true ? true :(entitlementSearchString && currentItemBaseLicence.currEntNameLower.indexOf(entitlementSearchString.toLowerCase()) !== -1) ||( entitlementOrderNumberSearchString && currentItemBaseLicence.entitlementOrderNumber.indexOf(entitlementOrderNumberSearchString) !== -1);

                        if((isNameFilterAssetTrue &&
                            isOrderNumberTrue &&
                            isStartDateFilterTrue &&
                            isEndDateFilterTrue)|| (isRowSelected && (bothSearchBlank||isProdOrOrderMatch))){
                            //||isRowSelected - CPQ22-6009
                                if(currentItemBaseLicence.entitlementId != undefined){entUpgset.add(currentItemBaseLicence.entitlementId);}
                            }
                        if(entBeforeUpgrade != undefined && currentItemBaseLicence.entitlementId != undefined && entBeforeUpgrade.has(currentItemBaseLicence.entitlementId)){
                            isUpgradeRow = true;
                        }
                    })
              }             
                
                if(currentItemWrapper.wrapHWSupportLines != undefined && currentItemWrapper.wrapHWSupportLines.length > 0){
                    currentItemWrapper.wrapHWSupportLines.forEach(function (currentItemHWLicence, index){
                        isNameFilterAssetTrue = isNameFilterAssetTrue != undefined && isNameFilterAssetTrue == true ? true : currentItemHWLicence.currEntNameLower.indexOf(entitlementSearchString.toLowerCase()) !== -1;
                        isStartDateFilterTrue = isStartDateFilterTrue != undefined && isStartDateFilterTrue == true ? true : (startDate ? currentItemHWLicence.EndDate >= startDate : true);
                        isEndDateFilterTrue = isEndDateFilterTrue != undefined && isEndDateFilterTrue == true ? true : (endDate ? currentItemHWLicence.EndDate <= endDate : true);         
                        isOrderNumberTrue = isOrderNumberTrue != undefined && isOrderNumberTrue == true ? true : currentItemHWLicence.entitlementOrderNumber.indexOf(entitlementOrderNumberSearchString) !== -1;
                        isRowSelected = isRowSelected != undefined && isRowSelected == true ? true : currentItemHWLicence.rowSelected;
                        isProdOrOrderMatch = isProdOrOrderMatch == true ? true :(entitlementSearchString &&  currentItemHWLicence.currEntNameLower.indexOf(entitlementSearchString.toLowerCase()) !== -1 )|| ( entitlementOrderNumberSearchString && currentItemHWLicence.entitlementOrderNumber.indexOf(entitlementOrderNumberSearchString) !== -1);

                        if((isNameFilterAssetTrue &&
                            isOrderNumberTrue &&
                            isStartDateFilterTrue &&
                            isEndDateFilterTrue)|| (isRowSelected && (bothSearchBlank||isProdOrOrderMatch))){ 
                            //||isRowSelected - CPQ22-6009
                                if(currentItemHWLicence.entitlementId != undefined){entUpgset.add(currentItemHWLicence.entitlementId);}
                                if(currentItemWrapper.wrapBaseLicense != undefined && currentItemWrapper.wrapBaseLicense.length > 0){
                                  currentItemWrapper.wrapBaseLicense.forEach(function (currentItemBaseLicence, index){
                                      if(currentItemBaseLicence.entitlementId != undefined){entUpgset.add(currentItemBaseLicence.entitlementId);}
                                  });
                                }
                            }
                    });
                }
  
                if(currentItemWrapper.wrapUpgradeEnt != undefined && currentItemWrapper.wrapUpgradeEnt.length > 0){
                  if(currentItemWrapper.baseProdIds != undefined){
                        const baseProdIdsArray = currentItemWrapper.baseProdIds.split(',').map(id => id.trim());
                        upgradeEnt = new Set(baseProdIdsArray);
                        isUpgradeRow = upgradeRowCheck(upgradeEnt, entUpgset);
                  }
                  
                  currentItemWrapper.wrapUpgradeEnt.forEach(function (currentItemUpgLicence, index){
                        isNameFilterAssetTrue = isNameFilterAssetTrue != undefined && isNameFilterAssetTrue == true ? true : currentItemUpgLicence.currEntNameLower.indexOf(entitlementSearchString.toLowerCase()) !== -1;
                        isStartDateFilterTrue = true;
                        isEndDateFilterTrue = true;
                        isOrderNumberTrue = isOrderNumberTrue != undefined && isOrderNumberTrue == true ? true : currentItemUpgLicence.entitlementOrderNumber.indexOf(entitlementOrderNumberSearchString) !== -1;
                        isRowSelected = isRowSelected != undefined && isRowSelected == true ? true : currentItemUpgLicence.rowSelected;
                        isProdOrOrderMatch = isProdOrOrderMatch == true ? true :(entitlementSearchString && currentItemUpgLicence.currEntNameLower.indexOf(entitlementSearchString.toLowerCase()) !== -1) || ( entitlementOrderNumberSearchString && currentItemUpgLicence.entitlementOrderNumber.indexOf(entitlementOrderNumberSearchString) !== -1);
                    });
                }

                if(currentItemWrapper.wrapInactiveEnt != undefined && currentItemWrapper.wrapInactiveEnt.length > 0){
                  currentItemWrapper.wrapInactiveEnt.forEach(function (currItemInactive, index){
                        isNameFilterAssetTrue = isNameFilterAssetTrue != undefined && isNameFilterAssetTrue == true ? true : currItemInactive.currEntNameLower.indexOf(entitlementSearchString.toLowerCase()) !== -1;
                        isStartDateFilterTrue = isStartDateFilterTrue != undefined && isStartDateFilterTrue == true ? true : (startDate ? currItemInactive.EndDate >= startDate : true);
                        isEndDateFilterTrue = isEndDateFilterTrue != undefined && isEndDateFilterTrue == true ? true : (endDate ? currItemInactive.EndDate <= endDate : true);         
                        isOrderNumberTrue = isOrderNumberTrue != undefined && isOrderNumberTrue == true ? true : currItemInactive.entitlementOrderNumber.indexOf(entitlementOrderNumberSearchString) !== -1;
                        isRowSelected = isRowSelected != undefined && isRowSelected == true ? true : currItemInactive.rowSelected;
                        isProdOrOrderMatch = isProdOrOrderMatch == true ? true :(entitlementSearchString && currItemInactive.currEntNameLower.indexOf(entitlementSearchString.toLowerCase()) !== -1) || (entitlementOrderNumberSearchString && currItemInactive.entitlementOrderNumber.indexOf(entitlementOrderNumberSearchString) !== -1);
                  });
                }
            }            
              return (
                (isNameFilterAssetTrue &&
                isOrderNumberTrue &&
                isStartDateFilterTrue &&
                isEndDateFilterTrue)||(isRowSelected && (bothSearchBlank||isProdOrOrderMatch)) ||isUpgradeRow
                //||isRowSelected -CPQ22-6009
              );
          });
    console.log('filter data after is ', JSON.stringify(localdata));
    return localdata;
}

function upgradeRowCheck(upgradeEnt, entUpgset){
    let isUpgradeRow = false;
    if(upgradeEnt != undefined && entUpgset != undefined){
        for(const id of entUpgset){
              if(upgradeEnt.has(id)){
                    isUpgradeRow = true;
              }
        }
    } 
  return isUpgradeRow;
}