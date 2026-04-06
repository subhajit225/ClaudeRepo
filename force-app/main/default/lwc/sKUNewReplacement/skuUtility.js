export function dataFilter(sProdName, sProdDes, sPrdtypeval, sPrdlictypeval, SPrdlicCatval, rawdata) {
   
    let searchProdName = sProdName || '';
    let searchProdDes = sProdDes || '';
    let prdtypevalInput = sPrdtypeval || '';
    let prdlictypevalInput = sPrdlictypeval || '';
    let prdlicCatvalInput = SPrdlicCatval || '';

    let newProdList = rawdata.filter((raw) => {
      let issearchProdNameTrue = false;
      if (raw.productName === undefined) {
        raw.productName = '';
      }
      issearchProdNameTrue = raw.productName.toLowerCase().indexOf(searchProdName.toLowerCase()) !== -1;
      let issearchProdDesTrue = false;
      if (raw.productDescription === undefined) {
        raw.productDescription = '';
      }
      issearchProdDesTrue = raw.productDescription.toLowerCase().indexOf(searchProdDes.toLowerCase()) !== -1;
      if (raw.productLicenseCategory === undefined) {
        raw.productLicenseCategory = '';
      }
      if (raw.productLicenseType === undefined) {
        raw.productLicenseType = '';
      }
      if (raw.productProductType === undefined) {
        raw.productProductType = '';
      }
      let isProdTypeFilterTrue = false;
      let isProdLicTypeFilterTrue = false;
      let isProdLicCatFilterTrue = false;
      isProdTypeFilterTrue = prdtypevalInput != 'None' ? raw.productProductType.indexOf(prdtypevalInput) !== -1 : true;
      isProdLicTypeFilterTrue =
        prdlictypevalInput != 'None' ? raw.productLicenseType.indexOf(prdlictypevalInput) !== -1 : true;
      isProdLicCatFilterTrue =
        prdlicCatvalInput != 'None' ? raw.productLicenseCategory.indexOf(prdlicCatvalInput) !== -1 : true;
      return (
        issearchProdNameTrue &&
        issearchProdDesTrue &&
        isProdTypeFilterTrue &&
        isProdLicTypeFilterTrue &&
        isProdLicCatFilterTrue
      );
    });
    return newProdList;
}

export function selectedValueSKU(prodList, cIndex) {
  let displayedData = JSON.parse(JSON.stringify(prodList));
  displayedData.forEach(function (currentItemWrapper, indexWrapper) {
      
      if(currentItemWrapper.customIndex === cIndex){
           // selRowVal = currentItemWrapper;
            currentItemWrapper.isRowSelected = true;
          }else{
              if(currentItemWrapper.errors != null){
                currentItemWrapper.errors = '';
              }
              if(currentItemWrapper.isRowSelected == true){
                currentItemWrapper.isRowSelected = false;
              }            

              if(currentItemWrapper.showAttributeSection == true){
                currentItemWrapper.showAttributeSection = false;
              }            

              if(currentItemWrapper.showAssets == true){
                currentItemWrapper.showAssets = false;
              }      

              if(currentItemWrapper.multiAddAssets == true){
                currentItemWrapper.multiAddAssets = false;
              }      
          }
    });
    return displayedData;
}

export function selectedSkuAfterFilter(prodList, rowsVal){
    let displayedData = JSON.parse(JSON.stringify(prodList));
    displayedData.forEach(function (currentItemWrapper, indexWrapper) {
        if(rowsVal != undefined){
            currentItemWrapper.isRowSelected = false;
            if(rowsVal.productId != undefined && currentItemWrapper.productId === rowsVal.productId){
             // currentItemWrapper = rowsVal;
              currentItemWrapper.isRowSelected = true;              
            }
        }        
      });
      return displayedData;
}

export function checkRowSelectionInPrdFilter(prodList, rowsVal){
    let recordFound = false;
    let displayedData = JSON.parse(JSON.stringify(prodList));
    displayedData.forEach(function (currentItemWrapper, indexWrapper) {
      if(rowsVal != undefined){
        if(currentItemWrapper.productId === rowsVal.productId){
            recordFound = true;
        }
      }
    });
    return recordFound;
}
//FY25SR-1705 START

export function assetNonAssetTypeCheck(ents, rowsVal){
  if(ents.quantityAssetType != undefined){
        if(ents.quantityAssetType == false){
                rowsVal = mapPathforSKUForAsset(rowsVal, ents);
        }else if(ents.quantityAssetType == true){
                rowsVal = mapPathforSKUForNonAsset(rowsVal, ents);
        }
  }         
  return rowsVal;
}

export function mapPathforSKUForAsset(rowSel, ents){
      if(rowSel.productReplacementCategory != undefined && rowSel.productReplacementCategory === 'Enterprise Data Protection - Scale'){
          rowSel.pathFromSKU = 'Hardware'; 
          rowSel.showAssets = true;
      }else{
          if(rowSel.hardwareNotRequiredForHybrid == false){
                rowSel.pathFromSKU = 'Hardware';
          }else if(rowSel.hardwareNotRequiredForHybrid == true){
                rowSel.pathFromSKU = 'Non-Hardware';
          }
      }
        return rowSel;
  }

  export function mapPathforSKUForNonAsset(rowSel, ents){
          if(rowSel.productReplacementCategory === 'Enterprise Data Protection - Scale'){
              if(rowSel.hardwareNotRequiredForHybrid == false && ents.tphTypeEntitlement == false){
                  rowSel.pathFromSKU = 'Non-Hardware'; 
                  rowSel.showAssets = true;
                  rowSel.multiAddAssets = true; 
              }else{
                  rowSel.pathFromSKU = 'Non-Hardware';
              }
          }else if(rowSel.hardwareNotRequiredForHybrid == false){
            rowSel.pathFromSKU = 'Hardware';
            rowSel.multiAddAssets = true;
            rowSel.showAssets = true;
          }else if(rowSel.hardwareNotRequiredForHybrid == true){
            rowSel.pathFromSKU = 'Non-Hardware';
          }
        return rowSel;
  }
  
  export function attributeSectionCheck(prodList, checkBoxChange, assetSelectedProductId, multiAddSelectedProductId,selectedRowval){
    if(checkBoxChange == true){
        let selRowVal;    
        selRowVal = prodList.filter(prd => prd.isRowSelected == true);     
        selRowVal[0] = handleSelectedRowAttributes(selRowVal[0], assetSelectedProductId, multiAddSelectedProductId);         
        return selRowVal[0];
    }else if(checkBoxChange == false){
        let selRowVal = prodList.filter(prd => prd.productId === selectedRowval.productId);
        selRowVal[0] = handleSelectedRowAttributes(selRowVal[0], assetSelectedProductId, multiAddSelectedProductId);       
        return selRowVal[0];
    }    
  }
  //FY25SR-1084
  function handleSelectedRowAttributes(selRowVal, assetSelectedProductId, multiAddSelectedProductId){
      if(selRowVal.attributeEligibleCheck != undefined && selRowVal.attributeEligibleCheck == true){
                    selRowVal.showAttributeSection = true;
      }
      if(selRowVal.showAssets != undefined && (selRowVal.showAssets == true || (assetSelectedProductId != undefined && assetSelectedProductId === selRowVal.productId))){
                    selRowVal.showAssets = true;
      }
      if(selRowVal.multiAddAssets != undefined && (selRowVal.multiAddAssets == true || (multiAddSelectedProductId != undefined && multiAddSelectedProductId === selRowVal.productId))){
                    selRowVal.multiAddAssets = true;
      }
      return selRowVal;
  }
   //FY25SR-1084
 export function calculateConsolidation(rowsel, sourceEnt){
    if(sourceEnt.quantityAssetType == false && rowsel.pathFromSKU === 'Non-Hardware'){
      rowsel.doNotConsolidateSKU = true;
    }
    if(sourceEnt.quantityAssetType == true && rowsel.pathFromSKU === 'Hardware'){
      rowsel.doNotConsolidateSKU = true;
    }    
    return rowsel;
  }

  //FY25SR-1705 END