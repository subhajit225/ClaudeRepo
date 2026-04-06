import LightningAlert from 'lightning/alert';


/*************************************************************
 * Filter modified data only before quoteline creation
 ************************************************************/
export function filterRefreshData(refreshData){
    if (!refreshData) return null;

    let refreshCopy = JSON.parse(JSON.stringify(refreshData));
    for (let group of refreshCopy) {
        group.rows = group.rows.filter((row) => {return (row.isModified || (row.previousAssetIds && row.previousAssetIds.length>0))});
    }
    return refreshCopy;

}

/*************************************************************
 * Operation on refresh
 * US : FY25SR-1176
 ************************************************************/
export function handleOnRefresh(dataModified, refreshData, refreshUrl){

    //get refreshed assets
    let refreshedAssets = [];
    for (let group of refreshData) {
        for (let row of group.rows) {
            if (row.isSelected && !row.isHidden){
                refreshedAssets = refreshedAssets.concat(row.selectedAssetIds);
            }
        }
    }
    updateHWSupportDisposition(dataModified, refreshedAssets, refreshUrl);//FY25SR-2245
    return dataModified;
}

/*************************************************************
 * Update HW Support disposition to refreshed
 * US : FY25SR-1176
 ************************************************************/ 
function updateHWSupportDisposition(dataModified, refreshedAssets, refreshUrl){
    for (let bundleWrap of dataModified){
        let hasHWAsset = false;
        if(bundleWrap.wrapHWSupportLines) {
            for (let hwSupWrapper of bundleWrap.wrapHWSupportLines){
                if (hwSupWrapper.srProdType != 'HW Support') continue;
                //FY25SR-2245 -Start
                let assetLength = 0;
                if(hwSupWrapper.assetsAvailable) {
                    assetLength = hwSupWrapper.assetsAvailable.length > 1 ?  hwSupWrapper.assetsAvailable.length : 1;
                }
                //Update refreshed
                if (hwSupWrapper.assetsAvailable && hwSupWrapper.assetsAvailable[assetLength -1] && refreshedAssets.includes(hwSupWrapper.assetsAvailable[assetLength -1].value)){///FY25SR-2245
                    hwSupWrapper.refreshUrl = refreshUrl;//FY25SR-2245
                    hasHWAsset = true;//FY25SR-2245
                    if (hwSupWrapper.selecteddisposition == 'Refreshed') continue;
                    hwSupWrapper.disableDisposition = true;
                    hwSupWrapper.rowSelected = true;
                    hwSupWrapper.isModified = true;
                    hwSupWrapper.selecteddisposition = 'Refreshed';
                }
                //revert disposition
                else if (hwSupWrapper.selecteddisposition == 'Refreshed') {
                    hwSupWrapper.selecteddisposition = '';
                    hwSupWrapper.disableDisposition = false;
                    hwSupWrapper.rowSelected = false;
                    hwSupWrapper.isModified = true;
                    hwSupWrapper.ReplacementTerm = 12;
                    hwSupWrapper.refreshUrl = '';//FY25SR-2245
                }
            }
        }
        //FY25SR-2245 - Start
        if(bundleWrap.wrapBaseLicense) {
            for(let baseLicense of bundleWrap.wrapBaseLicense) {
                if(hasHWAsset) {
                    baseLicense.refreshUrl = refreshUrl;
                } else {
                    baseLicense.refreshUrl = '';
                }
            }
        }
        //FY25SR-2245 - Stop
    }
}

/*************************************************************
 * Clear Refresh data after replace on refreshed assets
 * US : FY25SR-1176
 ************************************************************/
export function handleReplaceAfterRefresh(dataModified, refreshData, action, rowIndex, errorMessagesValues, affectedAssets){
    let assetsForAlert = [];

    //check criteria
    let replaceRow = getRow(rowIndex, dataModified);
    if (replaceRow && (
        (action == 'checkboxchange' && replaceRow.skuProdName) || (action == 'skuchange' && replaceRow.rowSelected)
        || ((action == 'assetchange' || action == 'delete') && replaceRow.rowSelected && replaceRow.skuProdName)
    )){

        if (!affectedAssets || (affectedAssets && affectedAssets[0] == 'Full')){
            affectedAssets = [];
            let isFull = false;
            for (let assetData of replaceRow.assetsAvailable){
                if (assetData.value == 'Full') {
                    isFull = assetData.selected;
                    continue;
                }
                if (isFull || assetData.selected){
                    affectedAssets.push(assetData.value);
                }
            }
        }

        if (!affectedAssets || affectedAssets.length == 0) return;
        
        //clear refresh
        for (let group of refreshData) {
            let rowsUpdated = [];
            for (let row of group.rows) {
                if (!row.isSelected) continue;
                let removeRow = false;
                for (let assetId of row.selectedAssetIds) {
                    if (affectedAssets.includes(assetId)){
                        row.options.forEach(asset => assetsForAlert.push(asset.label.split(' ')[0]));
                        if (row.previousAssetIds && row.previousAssetIds.length){
                            row.isSelected = false
                            row.isModified = true;
                            row.isHidden = true;
                        }
                        else {
                            removeRow = true;
                        }
                        break;
                    }
                }
                if (!removeRow){
                    rowsUpdated.push(row);
                }
            }
            group.rows = rowsUpdated;
        }

        handleOnRefresh(dataModified, refreshData);
    }

    //alert message
    if (assetsForAlert.length > 0){
        let msg = errorMessagesValues.find(value =>  value.DeveloperName == 'Refresh_Cleared').Error_Message__c;
        msg += ' ' + assetsForAlert.join(', ');

        LightningAlert.open({
            message: msg,
            theme: 'warning',
            label: 'Alert',
        });
    }
}

function getRow(index, dataModified){
    for (let bundleWrapper of dataModified){
        if(bundleWrapper.wrapBaseLicense && bundleWrapper.wrapBaseLicense.length > 0){

            for (let row of bundleWrapper.wrapBaseLicense){
                if (row.customIndex == index){
                    return row;
                }
            }
        }
    }
}

/*************************************************************
 * get Refreshed Asset List
 * US : FY25SR-2245
 ************************************************************/
 export function refreshAssetsReconstruct(dataModified, refreshedAssets, refreshUrl) {
    updateHWSupportDisposition(dataModified, refreshedAssets, refreshUrl);
    return dataModified;
 }