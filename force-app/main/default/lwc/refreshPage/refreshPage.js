import { api, track } from 'lwc';
import LightningModal from 'lightning/modal';
import getEligibleProducts from "@salesforce/apex/RefreshPage_Controller.getEligibleProducts";
import LightningAlert from 'lightning/alert';

export default class RefreshPage extends LightningModal {

    @api quoteId;
    @api accountId;
    @api entitlementData;
    @api refreshRecreateData;
    @api errorMessagesValues;
    @api quoteDetails;
    @api disableValidations; //FY25SR-1875
    @track entSearchString; // CPQ22-6309
    @track showDropdown = false; // CPQ22-6309
    licenceGroupMap = {};
    constructRowMap = {};
    @track refreshWrapper = [];
    @track assetMap = {};
    targetSKUs = [];
    skuMap = {};
    eligibleForRefresh = [];
    eligibleForLiketoLike = [];
    message;
    showMessage;
    multiAdd = true;
    colspan = 7;
    labelMap = {};
    assetToUpgradeSKUMap = {};
    networkTypeOptions = [{'label' : 'SFP+ NIC (-01)', 'value' : 'SFP+ NIC (Fiber)'}, {'label' : '10GBase-T NIC (-02)', 'value' : '10GBase-T NIC (Copper)'}];

    connectedCallback(){
        try{
            this.setLabelMap();
            
            getEligibleProducts().then(data => {
                this.sortEligibleProducts(data);
    
                //reconstruction
                if (this.refreshRecreateData) this.reconstructWrapper();

                //construct remanining assets
                this.constructWrapper();

                //seperate upgraded ents
                this.seperateUpgradedAssets();

                this.sortData();
                this.setProperties();
                this.filterData();

                if (!this.refreshWrapper || this.refreshWrapper.length == 0){
                    this.showMessage = true;
                    this.message = this.labelMap['Refresh_No_Assets'];
                }

            })
            .catch(error => {
                this.handleCatch(error);
            });
        }
        catch(error){
            this.handleCatch(error);
        }
    }

    /*************************************************************
     * sort source and target products
     ************************************************************/
    sortEligibleProducts(skuData){
        try{
            let type = (this.quoteDetails.SBQQ__Opportunity2__r.Aspen_Eligibility__c == 'Proposed Aspen' && !this.quoteDetails.SBQQ__Opportunity2__r.Override__c) ? 'Aspen' : 'Polaris';

            for (let sku of skuData){
                sku.label = sku.ProductCode + ' (' + sku.Usable_Capacity__c +' TB)';
                sku.value = sku.Id;
                this.skuMap[sku.Id] = sku;

                //eligible assets and licences
                if (sku.Refresh_Eligibility__c  == 'Eligible for R7 hardware refresh combos'){
                    this.eligibleForRefresh.push(sku.ProductCode);
                }
                else if (sku.Refresh_Eligibility__c == 'Eligible for Like to Like R7 HW refresh'){
                    this.eligibleForLiketoLike.push(sku.ProductCode);
                }
                else if (sku.Family == 'R6000' && (sku.Product_Type__c == 'Hardware' || sku.Product_Type__c == 'Appliance')){
                    this.eligibleForRefresh.push(sku.ProductCode);
                }
                //eligible target products
                else if (sku.Family == 'R7000' && sku.Product_Type__c == 'Hardware'){
                    let aspenProduct = (sku.RWD_Version__c == 'Aspen_HW' && sku.RWD_Hardware_Family__c != 'F10000' && sku.Product_Type__c!='Add-On Node');

                    if ((type=='Aspen' && aspenProduct) || (type!='Aspen' && !aspenProduct)){
                        this.targetSKUs.push(sku);
                    }
                }
            }
        }
        catch(error){
            this.handleCatch(error);
        }
    }

    /*************************************************************
     * Recreate wrapper state after back to refresh screen
     *
     ************************************************************/
    reconstructWrapper(){
        try{
            let reconstructData = JSON.parse(JSON.stringify(this.refreshRecreateData));
            console.log('reconstructData() reconstructData='+JSON.stringify(reconstructData));
            for (let licenceGroup of reconstructData){
                this.licenceGroupMap[licenceGroup.productCode] = licenceGroup;

                licenceGroup.availableAssets = [];
                licenceGroup.isLikeToLike = this.eligibleForLiketoLike.includes(licenceGroup.productCode);
                Object.defineProperty(licenceGroup, 'disableAdd', {
                    get: function() { return (!this.availableAssets || this.availableAssets.length == 0) }
                });

                let index = 1;
                for (let row of licenceGroup.rows){
                    if (row.isHidden) continue;
                    
                    //add processed assets
                    for (let assetOption of row.options){
                        this.assetMap[assetOption.value] = assetOption;
                    }

                    row.displayIndex = index++;
                    row.isExisting = row.previousAssetIds && row.previousAssetIds.length > 0;
                    row.key = row.displayIndex;
                    row.isLikeToLike = licenceGroup.isLikeToLike;
                }
                this.refreshWrapper.push(licenceGroup);
            }
        }
        catch(error){
            this.handleCatch(error);
        }
    }

    /*************************************************************
     * Populate refresh wrapper from entitlement data
     * 
     ************************************************************/
    constructWrapper(){

        try{
            
            console.log('constructWrapper() entitlementData= ', JSON.stringify(this.entitlementData));

            for (let bundleWrapper of this.entitlementData){
                if (!bundleWrapper.wrapBaseLicense) continue;

                for (let licenceWrapper of bundleWrapper.wrapBaseLicense){
                    if (licenceWrapper.assetsAvailable.length == 0) continue;
                    if (!this.checkEligibleLicence(licenceWrapper.entitlementName)) continue;
                    if (licenceWrapper.targetProductType == 'Non-Hardware') continue;

                    let licenceProd = licenceWrapper.entitlementName;

                    //create or get licence group
                    if (!this.licenceGroupMap[licenceProd]){
                        this.licenceGroupMap[licenceProd] = this.createLicenceGroup(licenceWrapper.productId, licenceWrapper.entitlementName, licenceWrapper.srSuppType);
                        this.refreshWrapper.push(this.licenceGroupMap[licenceProd]);
                    }   
                    let licenceGroup = this.licenceGroupMap[licenceProd];
                    let replacedLicenceProd = licenceWrapper.skuProdName;

                    //create or get construct row
                    if (!this.constructRowMap[licenceProd]){
                        let newRow = this.createRow(licenceGroup.rows.length+1);
                        newRow.displayIndex = licenceGroup.rows.length+1;
                        newRow.isLikeToLike = licenceGroup.isLikeToLike;
                        this.constructRowMap[licenceProd] = newRow;
                        licenceGroup.rows.push(newRow);
                    }
                    let row = this.constructRowMap[licenceProd];
                
                    //for replaced scenario
                    let replacedLicenceGroup;
                    let replacedRow;
                    if (replacedLicenceProd && licenceWrapper.rowSelected){
                        //create or get replaced group
                        if (!this.licenceGroupMap[replacedLicenceProd]){
                            this.licenceGroupMap[replacedLicenceProd] = this.createLicenceGroup(licenceWrapper.skuProductId, licenceWrapper.skuProdName, licenceWrapper.skuSuppType);
                            this.refreshWrapper.push(this.licenceGroupMap[replacedLicenceProd]);
                        }
                        replacedLicenceGroup = this.licenceGroupMap[replacedLicenceProd];

                        //create or get construct row
                        if (!this.constructRowMap[replacedLicenceProd]){
                            let newRow = this.createRow(replacedLicenceGroup.rows.length+1);
                            newRow.displayIndex = replacedLicenceGroup.rows.length+1;
                            newRow.isLikeToLike = replacedLicenceGroup.isLikeToLike;
                            this.constructRowMap[replacedLicenceProd] = newRow;
                            replacedLicenceGroup.rows.push(newRow);
                        }
                        replacedRow = this.constructRowMap[replacedLicenceProd];
                    }

                    this.addAssets(row, replacedRow, licenceWrapper, licenceGroup, replacedLicenceGroup);

                    //support type basic to premium
                    if (licenceGroup.supportType == 'Basic') licenceGroup.supportType = 'Premium';
                }

                //set hw support details
                if (bundleWrapper.wrapHWSupportLines){
                for (let supportWrapper of bundleWrapper.wrapHWSupportLines){
                    for (let assetData of supportWrapper.assetsAvailable){
                            if (assetData.value != 'Full' && this.assetMap[assetData.value] && supportWrapper.entitlementName != 'RBK-MSP-AIR' && !supportWrapper.entitlementName.includes('-SW')) {
                            this.assetMap[assetData.value].supportEntId = assetData.entitlementId;
                            this.assetMap[assetData.value].supportProdId = supportWrapper.productId;
                            this.assetMap[assetData.value].rowId = supportWrapper.customIndex;
                            this.assetMap[assetData.value].replacementTerm = supportWrapper.ReplacementTerm;
                                if (supportWrapper.EndDate){
                                    this.assetMap[assetData.value].label += ' (' + supportWrapper.EndDate + ')';
                                }
                                
                        }
                    }
                }
            }
                

                //for upgraded ents
                if (bundleWrapper.wrapUpgradeEnt){
                    for (let upgradeWrapper of bundleWrapper.wrapUpgradeEnt){
                        for (let assetData of upgradeWrapper.assetsAvailable){
                            if (assetData.value == 'Full') continue;
                            this.assetToUpgradeSKUMap[assetData.value] = upgradeWrapper;
                            console.log(assetData.label +' upgraded to '+upgradeWrapper.entitlementName);
                        }
                    }
                }
            }
        }
        catch(error){
            this.handleCatch(error);
        }
    }

    checkEligibleLicence(productCode){
        return (this.eligibleForRefresh.includes(productCode) || this.eligibleForLiketoLike.includes(productCode))
    }

    /*************************************************************
     * Check asset product eligible for refresh
     ************************************************************/
    checkEligibleAsset(asset){
        for (let eligibleSKU of this.eligibleForRefresh){
            if (asset.label.includes(eligibleSKU)){
                return true;
            }
        }
        console.log('checkEligibleAsset() ineligible sku='+asset.label);
        return false;
    }

    /*************************************************************
     * Create group for each licence
     * 
     ************************************************************/
    createLicenceGroup(productId, productCode, supportType){
        try{
            let licenceGroup = {
                productId : productId,
                productCode : productCode,
                supportType : supportType,
                isHidden : false,
                isLikeToLike : this.eligibleForLiketoLike.includes(productCode),
                isUpgraded : false,
                rows : [],
                availableAssets : [],
                get disableAdd(){
                    return (this.availableAssets.length == 0);
                }
            }
            return licenceGroup;
        }
        catch(error){
            this.handleCatch(error);
        }
    }

    /*************************************************************
     * Create row instance
     * 
     ************************************************************/
    createRow(key){
        try{
            let row = {
                isSelected : false,
                isModified : false,
                isHidden : false,
                isExisting : false,
                isLikeToLike : false,
                deltaQuantity : 0,
                availableQuantity : 0,
                targetQuantity : 0,
                previousAssetIds : [],
                selectedAssetIds : [],
                options : [],
                targetSKUs : [],
                selectedTargetIds : [],
                key : key,
                displayIndex : null,
                networkType : []
            };

            return row;
        }
        catch(error){
            this.handleCatch(error);
        }
    }

    /*************************************************************
     * Add assets to row
     ************************************************************/
    addAssets(row, replacedRow, licenceWrapper, licenceGroup, replacedLicenceGroup){
        let isFull = false;
        for (let assetData of licenceWrapper.assetsAvailable){
            if (assetData.value == 'Full') {
                isFull = assetData.selected;
            }
            //exclude processed assets
            else if (!this.assetMap[assetData.value] && this.checkEligibleAsset(assetData)){
                let assetWrapper = JSON.parse(JSON.stringify(assetData));
                assetWrapper.selected = false;
                this.assetMap[assetWrapper.value] = assetWrapper;

                //for replaced assets
                if (replacedRow && (isFull || assetData.selected)){
                    console.log('addAssets() Asset '+assetWrapper.label.split(' ')[0]+' replace to '+licenceWrapper.skuProdName);
                    replacedRow.options.push(assetWrapper);
                    replacedLicenceGroup.availableAssets.push(assetWrapper.value);
                }
                else {
                    row.options.push(assetWrapper);
                    licenceGroup.availableAssets.push(assetWrapper.value);
                }
            }
        }
    }

    /*************************************************************
     * Set target skus for each row
     ************************************************************/
    setTargetSKUS(row){
        if (row && row.isLikeToLike){
            row.targetSKUs = [];
            for (let sku of this.targetSKUs){
                if (row.options.length > 0 && row.options[0].quantity == sku.Usable_Capacity__c){
                    row.targetSKUs.push(sku);
                }
            }
        }
    }

    /*************************************************************
     * Seperate upgraded assets to upgraded group
     ************************************************************/
    seperateUpgradedAssets(){
        let groupsPrepend = [];
        let groupsAppend = [];
        let remainingGroups = [];
        let upgradeRowMap = {};
        for (let group of this.refreshWrapper){
            //skip if already done
            if (group.isUpgraded) {
                groupsPrepend.push(group);
                continue;
            }
            let remainingRows = [];

            for (let row of group.rows){
                let hasUpgrade = false;
		        let remainingAssets = [];
		        let remainingAssetIds = [];

                for (let asset of row.options){
                    if (this.assetToUpgradeSKUMap[asset.value]){
                        hasUpgrade = true;
                        console.log('seperateUpgradedAssets() upgraded asset '+asset.label);
                        let upgradeSKU = this.assetToUpgradeSKUMap[asset.value];
                        let key = group.productCode  + ' + ' + upgradeSKU.entitlementName;

                        //create upgrade group if not exists
                        if (!this.licenceGroupMap[key]){
                            let newGroup = this.licenceGroupMap[key] = this.createLicenceGroup(group.productId, group.productCode + ' + ' + upgradeSKU.entitlementName, group.supportType);
                            newGroup.isUpgraded = true;
                            newGroup.isLikeToLike = group.isLikeToLike;
                            if (row.isExisting) groupsPrepend.push(newGroup);
                            else groupsAppend.push(newGroup);
                        }
                        let upgradeGroup = this.licenceGroupMap[key];
                        //add existing rows as it is
                        if (row.isExisting && upgradeGroup && upgradeGroup.rows){
                            upgradeGroup.rows.push(row);
                            break;
                        }
                        //create upgrade row if not exists
                        if (!upgradeRowMap[key] && upgradeGroup && upgradeGroup.rows){
                            let newRow = upgradeRowMap[key] = this.createRow(upgradeGroup.rows.length+1);
                            newRow.isLikeToLike = upgradeGroup.isLikeToLike;
                            upgradeGroup.rows.push(newRow);
                        }
                        let upgradeRow = upgradeRowMap[key];
                        if (upgradeRow && upgradeRow.options && upgradeRow.selectedAssetIds){
                            upgradeRow.options.push(asset);
                            //upgradeRow.selectedAssetIds.push(asset.value);
                        }
                    }
                    else{
                        remainingAssets.push(asset);
                        remainingAssetIds.push(asset.value);
                }
            }
                if (hasUpgrade){
                    if (remainingAssets && remainingAssets.length > 0){
                        row.options = remainingAssets;
                        //row.selectedAssetIds = remainingAssetIds;
                        remainingRows.push(row);
                    }
                }
                else{
                    remainingRows.push(row);
        }
    }

            group.rows = remainingRows;
            if (group.rows.length > 0){
                remainingGroups.push(group);
            }
        }

        this.refreshWrapper = [...groupsPrepend, ...remainingGroups, ...groupsAppend];
    }

    /*************************************************************
     * sort licence groups
     ************************************************************/
    sortData(){
        this.refreshWrapper.sort(
            (g1, g2) => {
                return g1.isLikeToLike ? 1 : g2.isLikeToLike ? -1 : 0;
            }
        );
    }
    
    /*************************************************************
     * Refresh asset options on all rows
     ************************************************************/
    updateAvailableOptions(group, skipIndex){
        try{
            let index = 1;
            for (let i in group.rows){
                if (i == skipIndex) continue;
                group.rows[i].displayIndex = index ++;
                group.rows[i].options = [];
                for (let value of group.rows[i].selectedAssetIds){
                    this.assetMap[value].selected = true;
                    group.rows[i].options.push(this.assetMap[value]);
                }
                for (let value of group.availableAssets){
                    this.assetMap[value].selected = false;
                    group.rows[i].options.push(this.assetMap[value]);
                }
            }
        }
        catch(error){
            this.handleCatch(error);
        }
    }

    /*************************************************************
     * Refresh quantities on all rows
     ************************************************************/
    setQuantities(row){
        try {
            row.deltaQuantity = 0;
            row.availableQuantity = 0;
            row.targetQuantity = 0;
            for (let value of row.selectedAssetIds){
                row.availableQuantity += this.assetMap[value].quantity;
            }
            for (let selectedTargetId of row.selectedTargetIds){
                row.targetQuantity += this.skuMap[selectedTargetId].Usable_Capacity__c;
            }
            
            row.deltaQuantity = row.targetQuantity - row.availableQuantity;
        }
        catch(error){
            this.handleCatch(error);
        }
    }

    /*************************************************************
     * Set quantities all rows
     ************************************************************/
    setProperties(){
        try {
            for (let group of this.refreshWrapper){
                for (let row of group.rows){
                    this.setQuantities(row);
                    this.setTargetSKUS(row)
                }
                this.setDisableDelete(group);
                this.setIsHidden(group);
            }
        }
        catch(error){
            this.handleCatch(error);
        }
    }

    /*************************************************************
     * Disable delete for existing rows or if only 1 row in group
     ************************************************************/
    setDisableDelete(group){
        try {
            group.rows.forEach(row =>{
                row.disableDelete = (row.isExisting || group.rows.length == 1 || row.isLikeToLike);
            });
        }
        catch(error){
            this.handleCatch(error);
        }
    }

    /*************************************************************
     * hide group with 0 or all hidden rows
     ************************************************************/
    setIsHidden(group){
        group.isHidden = (group.rows.find((row) => !row.isHidden)) ? false : true;
    }

    /*************************************************************
     * Create label map
     ************************************************************/
    setLabelMap(){
        for (let value of this.errorMessagesValues){
            this.labelMap[value.DeveloperName] = value.Error_Message__c;
        }
    }

    /*************************************************************
     * filter refresh data
     ************************************************************/
    filterData(){
        try {
            for (let group of this.refreshWrapper){
                group.rows = group.rows.filter((row) => {return (row.options && row.options.length > 0)});
            }

            this.refreshWrapper = this.refreshWrapper.filter((group) => {return (group.rows && group.rows.length > 0)});
        }
        catch(error){
            this.handleCatch(error);
        }
    }

    /*************************************************************
     * handle asset select, unselect, pill cross actions
     ************************************************************/
    handleSelectAsset(event){
        try {
            let rowIndex = event.currentTarget.dataset.index;
            let groupIndex = event.currentTarget.dataset.group;
            let group = this.refreshWrapper[groupIndex];
            let actionRow = this.refreshWrapper[groupIndex].rows[rowIndex];
            let action = event.detail.action;
            console.log('handleSelectAsset() detail= '+JSON.stringify(event.detail));

            if (action === 'add'){
                let assetId = event.detail.value;
                actionRow.selectedAssetIds.push(assetId);
                this.assetMap[assetId].selected = true;
                group.availableAssets.splice(group.availableAssets.indexOf(assetId), 1);
                this.updateAvailableOptions(group, rowIndex);
            }
            else if (action == 'remove'){
                let assetId = event.detail.value;
                actionRow.selectedAssetIds.splice(actionRow.selectedAssetIds.indexOf(assetId), 1);
                this.assetMap[assetId].selected = false;
                group.availableAssets.push(assetId);
                this.updateAvailableOptions(group, rowIndex);
            }
            else if (action == 'select all'){
                actionRow.selectedAssetIds = [...event.detail.values];
                for (let assetId of actionRow.selectedAssetIds){
                    this.assetMap[assetId].selected = true;
                    group.availableAssets.splice(group.availableAssets.indexOf(assetId), 1);
                }
                this.updateAvailableOptions(group, rowIndex);
            }

            this.setQuantities(actionRow);
            this.setIsModified(actionRow);

            console.log('handleSelectAsset() selected='+JSON.stringify(actionRow.selectedAssetIds))
        }
        catch(error){
            this.handleCatch(error);
        }
    }


    /*************************************************************
     * handle asset select, pill cross actions
     ************************************************************/
    handleSelectTarget(event){
        try{
            let rowIndex = event.currentTarget.dataset.index;
            let groupIndex = event.currentTarget.dataset.group;
            let actionRow = this.refreshWrapper[groupIndex].rows[rowIndex];

            console.log('handleSelectTarget() detail='+JSON.stringify(event.detail));

            actionRow.selectedTargetIds = event.detail.values;
            actionRow.isSelected = actionRow.selectedTargetIds && actionRow.selectedTargetIds.length > 0; //CPQ22-6309
            this.setQuantities(actionRow);
            this.setIsModified(actionRow);
        }
        catch(error){
            this.handleCatch(error);
        }
        
    }

    /*************************************************************
     * handle row checkbox selection
     ************************************************************/
    handleSelectCheckBox(event){
        try {
            let rowIndex = event.currentTarget.dataset.index;
            let groupIndex = event.currentTarget.dataset.group;
            let actionRow = this.refreshWrapper[groupIndex].rows[rowIndex];
            actionRow.isSelected = !actionRow.isSelected;
            this.setIsModified(actionRow);
        }
        catch(error){
            this.handleCatch(error);
        }
    }

    /*************************************************************
     * Add new row and add all available assets to new row
     * 
     ************************************************************/
    handleAddRow(event){
        try {
            let rowIndex = Number(event.currentTarget.dataset.index);
            let groupIndex = Number(event.currentTarget.dataset.group);
            let group = this.refreshWrapper[groupIndex];
            let key = group.rows.reduce((max, row) => {return  row.key >= max ? row.key + 1 : max}, 0);
            
            //create and add new row
            let newRow = this.createRow(key);
            group.rows.splice(rowIndex+1, 0, newRow);
            this.updateAvailableOptions(group);
        }
        catch(error){
            this.handleCatch(error);
        }
    }

    /*************************************************************
     * handle row delete action, add assets to available list
     ************************************************************/
    handleDeleteRow(event){
        try {
            let rowIndex = Number(event.currentTarget.dataset.index);
            let groupIndex = Number(event.currentTarget.dataset.group);
            let actionRow = this.refreshWrapper[groupIndex].rows[rowIndex];
            let group = this.refreshWrapper[groupIndex];

            //remove row
            group.rows.splice(rowIndex, 1);

            //add available options
            group.availableAssets.push(...actionRow.selectedAssetIds);

            this.updateAvailableOptions(group);
            this.setDisableDelete(group);
        }
        catch(error){
            this.handleCatch(error);
        }
    }

    /*************************************************************
     * handle newtork type selection
     ************************************************************/
    handleNetworkTypeChange(event){
        try {
            let rowIndex = Number(event.currentTarget.dataset.index);
            let groupIndex = Number(event.currentTarget.dataset.group);
            let actionRow = this.refreshWrapper[groupIndex].rows[rowIndex];
            actionRow.networkType = event.detail.values;
            if (actionRow && actionRow.networkType && actionRow.networkType[0]){
                actionRow.networkTypeFilter = [{'key' : 'Product_NIC_Type__c', 'value' : actionRow.networkType[0]}];
            }
            else {
                actionRow.networkTypeFilter = null;
            }
        }
        catch(error){
            this.handleCatch(error);
        }
    }

    /*************************************************************
     * Get modified data
     ************************************************************/
    getWrapper(){
        try{
            let refreshDataCopy = JSON.parse(JSON.stringify(this.refreshWrapper));

            //filter modified/existing rows
            for (let group of refreshDataCopy){
                group.rows = group.rows.filter((row) => { return (row.isModified || row.isExisting)});
                for (let row of group.rows){
                    row.options = row.options.filter((option) => {return option.selected})
                    row.targetSKUs = [];
                }
                group.availableAssets = [];
            }
            //filter out empty groups
            refreshDataCopy = refreshDataCopy.filter((group) => { return group.rows.length > 0 });

            console.log('getWrapper() refreshData=',JSON.stringify(refreshDataCopy));
            return refreshDataCopy;
        }
        catch(error){
            this.handleCatch(error);
        }
    }

    closeModal(){
        this.close(this.refreshRecreateData);
    }

    /*************************************************************
     * pass refresh data to replacement page and close
     ************************************************************/
    handleDone(){
        try{
            if (this.validate()){
                this.showAlerts();
                const refreshData = this.getWrapper();
                this.template.querySelector('c-new-rep-event-wrapper').sendEventWrap(refreshData);
            }
        }
        catch(error){
            this.handleCatch(error);
        }
    }

    handleDoneEvent(event){
        console.log('handleDoneEvent event.detail '+JSON.stringify(event.detail));
        this.close(event.detail.value);
    }

    /********************************************** ***************
     * set is modified to capture modifed/new rows
     ************************************************************/
    setIsModified(row){
        row.isModified = !row.isExisting ? row.isSelected : true;
        console.log('setIsModified() isModified='+row.isModified);
    }

    /*************************************************************
     * handle catch errors
     ************************************************************/
    handleCatch(error) {
        console.error(error.message);
        this.message = error.message;
        this.showMessage = true;
    }
    /*************************************************************
     * Search global asset - CPQ22-6309
     ************************************************************/
    handleAssetNameSearch(event) { //CPQ22-6309 Starts
        try{
            this.entSearchString = event.target.value;
            const searchKey = this.entSearchString.toLowerCase();
            this.refreshWrapper = this.refreshWrapper.map(group => {
                let groupHasVisibleRows = false;

                const updatedRows = group.rows.map(row => {
                    const matches = row.options.some(opt => {
                        const isMatch = opt.label.toLowerCase().includes(searchKey);
                        return isMatch;
                     });
                     if (matches) groupHasVisibleRows = true;
                     return {
                        ...row, 
                        isHidden: this.entSearchString ? !matches : false 
                    };
                 });
                
                const isGroupHidden = this.entSearchString ? !groupHasVisibleRows : false;
                return { 
                    ...group, 
                    rows: updatedRows, 
                    isHidden: isGroupHidden 
                };
            });
        }
        catch(error){
            this.handleCatch(error);
        }
    }

    get suggestedAssets() {
        if (!this.entSearchString || this.entSearchString.length < 2) {
            return [];
        }
        const searchKey = this.entSearchString.toLowerCase();
        return Object.values(this.assetMap)
            .filter(asset => asset.label.toLowerCase().includes(searchKey))
            .map(asset => ({ label: asset.label, value: asset.value }))
            .slice(0, 10); 
    }

    get hasSuggestions() {
        return this.suggestedAssets.length > 0;
    }

    handleInputFocus() {
        this.showDropdown = true;
    }

    handleInputBlur() {
       setTimeout(() => {
            this.showDropdown = false;
        }, 200);
    }

    handleSelectSuggestion(event) {
        const selectedLabel = event.currentTarget.querySelector('.slds-truncate').innerText;
        this.entSearchString = selectedLabel;
        this.showDropdown = false; 
        this.handleAssetNameSearch({ target: { value: selectedLabel } });
    }
    //CPQ22-6309 Ends
    /*************************************************************
     * Validate user inputs
     ************************************************************/
    validate(){
        //FY25SR-1875 - Start
        if(this.disableValidations){
            return true;
        }
        //FY25SR-1875 - End
        
        let isValid = true;
        this.message = null;
        this.showMessage = false;

        for (let group of this.refreshWrapper){
            for (let row of group.rows){
                row.message = null;
                if (!row.isSelected) {
                    continue
                }
                else if (row.selectedAssetIds == null || row.selectedAssetIds.length == 0 || row.selectedTargetIds == null || row.selectedTargetIds.length == 0){
                    row.message = this.labelMap['Refresh_No_Selection'];
                    isValid = false;
                }
                else if (row.targetQuantity < row.availableQuantity){
                    row.message = this.labelMap['Refresh_Quantity_Validation'];
                    isValid = false;
                }
                else if (row.isLikeToLike && row.targetQuantity > row.availableQuantity){
                    row.message = this.labelMap['Refresh_Quantity_Like_to_Like'];
                    isValid = false;
                }
                else if (group.isUpgraded && row.targetQuantity > row.availableQuantity){
                    row.message = this.labelMap['Refresh_Validation_Upgrade'];
                    isValid = false;
                }
            }
        }
        if (!isValid){
            this.message = this.labelMap['Refresh_Error_Alert'];
            this.showMessage = true;
        }
        return isValid;
    }

    showAlerts(){
        let alertMessages = [];
        let nicAlert;
        for (let group of this.refreshWrapper){
            for (let row of group.rows){
                if (!row.isSelected) {
                    continue;
                }
                
                if (!nicAlert){
                    for (let option of row.options){
                        let skuCode = option.label.split(' ')[1].split('-');
                        let nicTypeAsset = skuCode[skuCode.length - 1].replace(')', '');
                        console.log('nicTypeAsset='+nicTypeAsset);
                        for (let skuId of row.selectedTargetIds){
                            let nicTypeTarget = this.skuMap[skuId].Product_NIC_Type__c;
                            console.log('nicTypeTarget='+nicTypeTarget);
                            if ((nicTypeAsset && nicTypeAsset == '01' && nicTypeTarget && nicTypeTarget != 'SFP+ NIC (Fiber)')
                            || (nicTypeAsset && nicTypeAsset == '02' && nicTypeTarget && nicTypeTarget != '10GBase-T NIC (Copper)')){
                                nicAlert = this.labelMap['Refresh_NIC_mismatch_alert'];
                                alertMessages.push(nicAlert);
                                break;
                            }
                        }
                        if (nicAlert) break;
                    }
                }
                
            }
        }

        if (alertMessages.length > 0){
            LightningAlert.open({
                message: alertMessages.join(', \n'),
                theme: 'warning',
                label: 'Alert',
            });
        }

        return alertMessages;
    }
}