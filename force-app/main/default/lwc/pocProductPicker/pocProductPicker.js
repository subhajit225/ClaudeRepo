import { LightningElement, track, api } from 'lwc';
import getProductMetadata from '@salesforce/apex/PocFormControllerCls.getProductCustomMetadata1';
import getProductSKUs from '@salesforce/apex/PocFormControllerCls.getProductSKUs';
import { ProductClass, addProduct, addAccessory, setProductVisibility, setAccessoryVisibility, computeAddAccessoryBtn } from './productStructureClass';
import RoadrunnerURL from "@salesforce/label/c.POC_RubrikAppliance_RoadRunnerURL"; //Added for MKT26-101
import RubrikAgentCloudURL from "@salesforce/label/c.POC_Rubrik_Agent_Cloud_URL"; //Added for MKT-38
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import AnnapurnaURL from "@salesforce/label/c.POC_Annapurna_URL"; //Added for MKT26-405


const products = ['Polaris_GPS_and_Radar', 'Polaris_Sonar', 'Polaris_Cloud_Native_Protection', 'Polaris_M365', 'NAS_CloudDirect'];
var dem, cupr = [];
export default class PocProductPicker extends LightningElement {
    prodTypes;
    skus = [];
    error;
    activeSectionsMessage;
    productCategories;
    selectedProductCategories = [];
    @track isProductM365 = false;
    @track isM365Selected = false;
    @track isSaaS = false; // to show Banner for SaaS
    @track mainProductList = []; //Enables deep tracking of complex structures.
    count = 1;
    @track identityRecovery = false;  // to show Banner for identity Recovery
    @track isCloudUnstructured = false; // to show Banner for Cloud Unstructured (S3, Azure Blob, and Cloud Files)
    
    @track showDataRedundancyArchive = false;
    @track showDataRedundancyBackup = false;
    dataRedundacyArchValue = '';
    dataredundancyBackup = '';
    
    //private
    _productPrototypes = {};
    _pocProductAttributes = {};
    _noFieldProducts = [];
    _willYouBeProtecting = false;
    _cloudClusterWithUcl = false;
    _showPolaris = false;
    _currentPOCType = '';
    uclEdition = '';//Basic UCL (No RCV)
    _ncdEdition = '';//'Basic NCD (No RCV)';
    _numberOfUCL = 1;
    _numberOfNCD = 1;
    RCVType='';

    showUCLBanner  = false;
   
    isAzureSelected = false;
    isAWSSelected = false;
    showStorageRegionBundleArchive = false;
    showStorageRegionBundleBackup = false;
    
    storageRegionGovArc='';
    storageRegionGovBack='';
    @track hostingEnvironmentWebtry = 'Rubrik Hosted Enterprise Edition';
    @track hostingEnvironmentOtherThenWebtry = 'Rubrik Hosted EE, DSPM, Identity Recovery & Resilience';

    //Added for MKT26-101
    //Added for MKT26-101
    labels = {
        RoadrunnerURL,
		AnnapurnaURL,
        RubrikAgentCloudURL
    };

    @api pocRscgContact;
    @api pocRscgContactName; //Added for MKT26-99

    @track rscGReadOnly = true;

    connectedCallback() {
        this.getMetadata();
    }


    renderedCallback() {        
        if (this.showProductTable) {
            let prodAccordion = this.template.querySelector('.mainTable [data-position]');
            var openProducts = [];
            let numberUCL = this.template.querySelector(`lightning-input-field[data-apiname="Number_Of_UCL_FETB__c"]`);
            let numberNCD = this.template.querySelector(`lightning-input-field[data-apiname="Number_Of_NCD_FETB__c"]`);
            let rscGEnterprise = this.template.querySelector(`lightning-input-field[data-apiname="RSC_G_Enterprise_Edition_bundle__c"]`);
            let uclEdition = this.template.querySelector(`lightning-input-field[data-apiname="UCL_Edition__c"]`);
            let uclFETB = this.template.querySelector(`lightning-input-field[data-apiname="Number_Of_UCL_FETB__c"]`);
            if (uclFETB && this.selectedProductCat && this.selectedProductCat.includes('UCL (Cloud Cluster, Cloud Native & Entra ID)')) {
                uclFETB.classList.add('slds-hide');
            }
            
            let dataRedundancyArchv = this.template.querySelector(`lightning-input-field[data-apiname="Data_Redundancy_Archive__c"]`);
            let storageRegionRCVArchive = this.template.querySelector(`lightning-input-field[data-apiname="Storage_Region_Bundle_RCV_Archive__c"]`);
            let storageRegionRCVBackup = this.template.querySelector(`lightning-input-field[data-apiname="Storage_Region_Bundle_RCV_Backup__c"]`);
            let dataRedundancyBackup = this.template.querySelector(`lightning-input-field[data-apiname="Data_Redundancy_Backup__c"]`);
            let storageRegionBundleUCL = this.template.querySelector(`lightning-input-field[data-apiname="Storage_Region_Bundle_UCL__c"]`);
            let identityResilienceVal = this.template.querySelector(`lightning-input-field[data-apiname="Add_Identity_Resilience__c"]`);
            let identityRecoveryVal = this.template.querySelector(`lightning-input-field[data-apiname="Add_Identity_Recovery__c"]`);
            let identityRecoveryForOktaVal = this.template.querySelector(`lightning-input-field[data-apiname="Identity_Cyber_Recovery_for_Okta__c"]`); //added for MKT26-1427
            
            this.mainProductList.forEach((prod) => {
                openProducts.push(prod.productName);

                // Making those changes to Set default Values OR Read-Only
                prod.productFields.forEach((prodField) => {
                    let prodFieldObj = prodField;

                    if(this.selectedProductCat && this.selectedProductCat.includes('Identity Recovery and Resilience - AD, Entra ID, Okta')){
                        prodFieldObj.isIdentityResilience = prodFieldObj.Field_Api_Name__c == 'Add_Identity_Resilience__c' && identityResilienceVal.value == 'Yes' ? true : false;
                        prodFieldObj.isIdentityRecovery = prodFieldObj.Field_Api_Name__c == 'Add_Identity_Recovery__c' && identityRecoveryVal.value == 'Yes' ? true : false;
                        prodFieldObj.isIdentityRecoveryForOkta = prodFieldObj.Field_Api_Name__c == 'Identity_Cyber_Recovery_for_Okta__c' && identityRecoveryForOktaVal.value == 'Yes' ? true : false; //added for MKT26-1427
                    }
                    if (this.isWebTryAndBuy && prodFieldObj.Field_Api_Name__c == 'M365_Hosting_environment__c') {
                        prodFieldObj.value = this.hostingEnvironmentWebtry;
                    }
                    if (!this.isWebTryAndBuy && prodFieldObj.Field_Api_Name__c == 'M365_Hosting_environment__c') {
                        prodFieldObj.value = this.hostingEnvironmentOtherThenWebtry;
                    }
                    if (this.selectedProductCat != undefined) {
                        if (this.selectedProductCat.includes('UCL (Cloud Cluster, Cloud Native & Entra ID)') && prodFieldObj.Field_Api_Name__c == 'UCL_Edition__c' && this.cloudLocation == '') {
                            prodFieldObj.value = '';
                            prodFieldObj.disable = true;
                        }
                        if (this.selectedProductCat.includes('UCL (Cloud Cluster, Cloud Native & Entra ID)') && prodFieldObj.Field_Api_Name__c == 'UCL_Edition__c' && this.uclEdition == 'Basic UCL (No RCV)') {
                            prodFieldObj.value = 'Basic UCL (No RCV)';
                            prodFieldObj.Required__c = true;
                        }
                        if (this.selectedProductCat.includes('NAS Cloud Direct') && prodFieldObj.Field_Api_Name__c == 'NCD_Editions__c' && this._ncdEdition == 'Basic NCD (No RCV)') {
                            prodFieldObj.value = 'Basic NCD (No RCV)';
                            prodFieldObj.Required__c = true;
                        }
                        if (this.selectedProductCat.includes('UCL (Cloud Cluster, Cloud Native & Entra ID)') && prodFieldObj.Field_Api_Name__c == 'Number_Of_UCL_FETB__c' && this.uclEdition == 'Basic UCL (No RCV)') {
                            prodFieldObj.disable = true;
                            numberUCL.value = 1;
                        }
                        if (this.selectedProductCat.includes('NAS Cloud Direct') && prodFieldObj.Field_Api_Name__c == 'Number_Of_NCD_FETB__c' && this._ncdEdition != 'Bundled with Cloud Unstructured') {
                            prodFieldObj.Required__c = true;
                        }
                        if (this.selectedProductCat.includes('RSC-G Enterprise Edition') && prodFieldObj.Field_Api_Name__c == 'RSC_G_Enterprise_Edition_bundle__c') {
                            rscGEnterprise.value = true;
                            prodFieldObj.disable = true;
                        }
                        if (this.selectedProductCat.includes('UCL(Cloud Cluster & Cloud Native)') && prodFieldObj.Field_Api_Name__c == 'UCL_Edition__c') {
                            uclEdition.value = 'Rubrik Security Cloud - Government, Universal Cloud License (No RCV)';
                            prodFieldObj.disable = true;
                        }
                        /*if (this.selectedProductCat.includes('UCL(Cloud Cluster & Cloud Native)') && prodFieldObj.Field_Api_Name__c == 'Number_Of_UCL_FETB__c') {
                            uclFETB.value = 1;
                            prodFieldObj.disable = true;
                        }
                        
                        if (this.selectedProductCat.includes('UCL(Cloud Cluster & Cloud Native)') && prodFieldObj.Field_Api_Name__c == 'Storage_Region_Bundle_UCL__c') {
                            storageRegionBundleUCL.value = 'Gov Cloud';
                            prodFieldObj.disable = true;
                        }*/
                       if(dataRedundancyArchv && this.selectedProductCat && this.selectedProductCat.includes('Rubrik Cloud Vault - Government') && prodFieldObj.Field_Api_Name__c == 'Data_Redundancy_Archive__c'  && !this.showDataRedundancyArchive){
                            
                            dataRedundancyArchv.classList.add('slds-hide');
                            prodFieldObj.Required__c = false;
                        }
                        
                        if(dataRedundancyArchv && this.selectedProductCat && this.selectedProductCat.includes('Rubrik Cloud Vault - Government') && prodFieldObj.Field_Api_Name__c == 'Data_Redundancy_Archive__c'  && !this.showDataRedundancyArchive){
                            
                            dataRedundancyArchv.classList.add('slds-hide');
                            prodFieldObj.Required__c = false;
                        }
                       
                        if(dataRedundancyArchv && this.selectedProductCat && this.selectedProductCat.includes('Rubrik Cloud Vault') && prodFieldObj.Field_Api_Name__c == 'Data_Redundancy_Archive__c'  && !this.showDataRedundancyArchive){
                            dataRedundancyArchv.classList.add('slds-hide');
                            prodFieldObj.Required__c = false;
                        }
                        if(dataRedundancyArchv && this.selectedProductCat && this.selectedProductCat.includes('Rubrik Cloud Vault') && prodFieldObj.Field_Api_Name__c == 'Data_Redundancy_Archive__c' && this.showDataRedundancyArchive){
                            dataRedundancyArchv.classList.remove('slds-hide');
                        }
                        
                        if(dataRedundancyBackup && this.selectedProductCat && this.selectedProductCat.includes('Rubrik Cloud Vault - Government') && prodFieldObj.Field_Api_Name__c == 'Data_Redundancy_Backup__c'  && !this.showDataRedundancyBackup){
                            dataRedundancyBackup.classList.add('slds-hide');
                            prodFieldObj.Required__c = false;
                        }
                        
                        if(dataRedundancyBackup && this.selectedProductCat && this.selectedProductCat.includes('Rubrik Cloud Vault') && prodFieldObj.Field_Api_Name__c == 'Data_Redundancy_Archive__c'  && !this.showDataRedundancyBackup){
                            dataRedundancyBackup.classList.add('slds-hide');
                            prodFieldObj.Required__c = false;

                        }
                        if(dataRedundancyBackup && this.selectedProductCat && this.selectedProductCat.includes('Rubrik Cloud Vault') && prodFieldObj.Field_Api_Name__c == 'Data_Redundancy_Archive__c' && this.showDataRedundancyBackup){
                            dataRedundancyBackup.classList.remove('slds-hide');
                        }

                        if(dataRedundancyBackup && this.selectedProductCat && this.selectedProductCat.includes('Rubrik Cloud Vault - Government') && prodFieldObj.Field_Api_Name__c == 'Data_Redundancy_Backup__c'  && !this.showDataRedundancyBackup){
                            dataRedundancyBackup.classList.add('slds-hide');
                            prodFieldObj.Required__c = false;
                        }
                        
                        if(storageRegionRCVArchive && this.selectedProductCat && this.selectedProductCat.includes('Rubrik Cloud Vault') && prodFieldObj.Field_Api_Name__c == 'Storage_Region_Bundle_RCV_Archive__c'  && this.dataRedundacyArchValue !== 'Single Zone (LRS)'){
                            storageRegionRCVArchive.classList.add('slds-hide');
                            prodFieldObj.Required__c = false;
                        }
                        
                        if(storageRegionRCVArchive && this.selectedProductCat && this.selectedProductCat.includes('Rubrik Cloud Vault') && prodFieldObj.Field_Api_Name__c == 'Storage_Region_Bundle_RCV_Archive__c' && this.dataRedundacyArchValue === 'Single Zone (LRS)'){
                            storageRegionRCVArchive.classList.remove('slds-hide');
                        }
	 if(storageRegionRCVBackup && this.selectedProductCat && this.selectedProductCat.includes('Rubrik Cloud Vault - Government') && prodFieldObj.Field_Api_Name__c == 'Storage_Region_Bundle_RCV_Backup__c'  && !this.dataredundancyBackup !== 'Single Zone (LRS)'){
                            storageRegionRCVBackup.classList.add('slds-hide');
                            prodFieldObj.Required__c = false;
                        }
                        if(storageRegionRCVArchive && this.selectedProductCat && this.selectedProductCat.includes('Rubrik Cloud Vault - Government') && prodFieldObj.Field_Api_Name__c == 'Storage_Region_Bundle_RCV_Archive__c'  && !this.dataRedundacyArchValue !== 'Single Zone (LRS)'){
                            storageRegionRCVArchive.classList.add('slds-hide');
                            prodFieldObj.Required__c = false;
                        }

                        if(storageRegionRCVBackup && this.selectedProductCat && this.selectedProductCat.includes('Rubrik Cloud Vault - Government') && prodFieldObj.Field_Api_Name__c == 'Storage_Region_Bundle_RCV_Backup__c'  && !this.dataredundancyBackup !== 'Single Zone (LRS)'){
                            storageRegionRCVBackup.classList.add('slds-hide');
                            prodFieldObj.Required__c = false;
                        }
                        
                        
                        if(storageRegionRCVArchive && this.selectedProductCat && this.selectedProductCat.includes('Rubrik Cloud Vault - Government') && prodFieldObj.Field_Api_Name__c == 'Storage_Region_Bundle_RCV_Archive__c'  && !this.dataRedundacyArchValue !== 'Single Zone (LRS)'){
                            storageRegionRCVArchive.classList.add('slds-hide');
                            prodFieldObj.Required__c = false;
                        }

                        if(storageRegionRCVBackup && this.selectedProductCat && this.selectedProductCat.includes('Rubrik Cloud Vault') && prodFieldObj.Field_Api_Name__c == 'Storage_Region_Bundle_RCV_Backup__c'  && !this.dataredundancyBackup !== 'Single Zone (LRS)'){
                            storageRegionRCVBackup.classList.add('slds-hide');
                            prodFieldObj.Required__c = false;
                        }
                        if(storageRegionRCVBackup && this.selectedProductCat && this.selectedProductCat.includes('Rubrik Cloud Vault') && prodFieldObj.Field_Api_Name__c == 'Storage_Region_Bundle_RCV_Backup__c' && this.dataredundancyBackup === 'Single Zone (LRS)'){
                            storageRegionRCVBackup.classList.remove('slds-hide');
                        }
                        
                        if (this.selectedProductCat?.includes('Rubrik Cloud Vault')) {
                            
                            this.handleBannerDisplay(
                                dataRedundancyArchv, 
                                'data-redundancy-banner', 
                                'For RCV on AWS, select Multi-Zone (ZRS). For RCV on Azure, you can use any data redundancy but only select ZRS if your opportunity requires it. Otherwise, use LRS.', 
                                this.showDataRedundancyArchive
                            );
                            
                            
                            this.handleBannerDisplay(
                                dataRedundancyBackup, 
                                'data-redundancy-backup-banner', 
                                'For RCV on AWS, select Multi-Zone (ZRS). For RCV on Azure, you can use any data redundancy but only select ZRS or GRS if your opportunity requires it. Otherwise, use LRS.', 
                                this.showDataRedundancyBackup
                            );
                        }
                        
                    }
                    
                });
            });
            openProducts.push('SAP_Hana_Kubernetes');
            openProducts.push('OtherProductComments');
            openProducts.push('Rubrik_Cloud_Security');
            openProducts.push('SAP_Hana_Kubernetes_1');
            openProducts.push('Rubrik_Third_Party');
            openProducts.push('Rubrik_Private_Ack');
            openProducts.push('Rubrik_Ransome_Ack');
            openProducts.push('Rubrik_Proactive_Ack');
            prodAccordion.activeSectionName = openProducts;
        }
    }

    @api isWebTryAndBuy = false;
    @api showToastMethod;
    @api currentHostingEnv = 'Rubrik Hosted Enterprise Edition';
    @api selectedProductCat;

    @api
    get pocType() {
        return this._currentPOCType;
    }
    set pocType(value) {
        this._currentPOCType = value;
        this.selectedProductCategories = [];
        this.mainProductList = [];
        this.processProductPickerOptions();
    }

    @api getAllData() {
        if (this.template.querySelectorAll('[data-product]')) {
            let productPicker = [];
            this.template.querySelectorAll('[data-product]').forEach((product) => {
                let entry = {};
                entry['productName'] = product.dataset.product;
                if (product.dataset.product === 'Rubrik Cloud Security') {
                    if ([...this.template.querySelectorAll('[data-product="Rubrik Cloud Security"] lightning-input[data-ismainbundle="true"]')][0].checked === true) {
                        entry['productName'] = 'RSC Enterprise Edition';
                        entry['fields'] = {};
                        productPicker.push(entry);
                    } else {
                        [...this.template.querySelectorAll('[data-product="Rubrik Cloud Security"] lightning-input[data-ismainbundle="false"]')].forEach((element) => {
                            if (element.checked === true) {
                                let branchEntry = {};
                                branchEntry['productName'] = element.name
                                branchEntry['fields'] = {};
                                productPicker.push(branchEntry);
                            }
                        });
                    }
                } else if (product.dataset.product === 'RSC 3rd Party S/W With Enterprise Ed.') {
                    if (product.dataset.hasfields === 'false') {
                        return;
                    }
                    entry['fields'] = {};
                    [...this.template.querySelectorAll('[data-product="RSC 3rd Party S/W With Enterprise Ed."] lightning-combobox')].forEach(fieldValue => {
                        entry['fields']['RSC_3rd_Party_Acknowledgment__c'] = (fieldValue.value === 'Yes');
                    });
                    productPicker.push(entry);
                } else if (product.dataset.product === 'RSC-G Third Party Software with Enterprise Edition') {
                    if (product.dataset.hasfields === 'false') {
                        return;
                    }
                    entry['fields'] = {};
                    [...this.template.querySelectorAll('[data-product="RSC-G Third Party Software with Enterprise Edition"] lightning-combobox')].forEach(fieldValue => {
                        entry['fields']['RSC_G_3rd_Party_Acknowledgment__c'] = (fieldValue.value === 'Yes');
                    });
                    productPicker.push(entry);
                } else if (product.dataset.product === 'RSC-Private') { //updated for MKT26-93
                    if (product.dataset.hasfields === 'false') {
                        return;
                    }
                    entry['fields'] = {};
                    [...this.template.querySelectorAll('[data-product="RSC-Private"] lightning-combobox')].forEach(fieldValue => { //updated for MKT26-93
                        entry['fields']['RSC_Private_Acknowledgement__c'] = (fieldValue.value === 'Yes');
                    });
                    product.querySelectorAll('lightning-input-field').forEach(field => {
                        entry['fields'][field.fieldName] = field.value;
                    });
                    productPicker.push(entry);
                }
                else if (product.dataset.product === 'RSC Enterprise Edition') {
                    entry['fields'] = {};
                    [...this.template.querySelectorAll('[data-product="RSC Enterprise Edition"] lightning-combobox')].forEach(fieldValue => {
                        entry['fields']['Ransomware_Recovery_Software_Acknowledge__c'] = (fieldValue.value === 'Yes');
                    });
                    productPicker.push(entry);
                }
                else if (product.dataset.product === 'RSC Proactive Edition') {
                    entry['fields'] = {};
                    [...this.template.querySelectorAll('[data-product="RSC Proactive Edition"] lightning-combobox')].forEach(fieldValue => {
                        entry['fields']['RSC_Proactive_Edition_Acknowledgement__c'] = (fieldValue.value === 'Yes');
                    });
                    productPicker.push(entry);
                }
                else if (product.dataset.product !== 'RSC Enterprise Edition') {
                    if (product.dataset.ismultiple === 'true') {
                        product.querySelectorAll('lightning-accordion').forEach(section => {
                            entry[section.dataset.sectionName] = [];
                            section.querySelectorAll('lightning-accordion-section').forEach(productEntry => {
                                let productEr = {};
                                productEntry.querySelectorAll('lightning-input-field').forEach(field => {
                                    productEr[field.dataset.fieldname] = field.value;
                                });
                                productEntry.querySelectorAll('lightning-input').forEach(field => {
                                    productEr[field.label] = field.value;
                                });
                                entry[section.dataset.sectionName].push(productEr);
                            });
                        });
                    } else {
                        entry['fields'] = {};
                        product.querySelectorAll('lightning-input-field').forEach(field => {
                            entry['fields'][field.fieldName] = field.value;
                        });
                        if(entry.productName === 'polarisDetails' && this._currentPOCType == 'Standard POC : RSC-G' ) { //Added for MKT26-99
                            entry['fields']['RSC_G_Contact__c'] = this.pocRscgContact;
                        }
                    }
                    productPicker.push(entry);
                }
            });
            return productPicker;
        }
        return [];
    }

    @api validate() {
        if (this.mainProductList.length === 0) {
            this.showToastMethod('No Product Selected', 'error', 'Error');
            return false;
        } if (this.mainProductList.length > 0) {
            let allValid = [...this.template.querySelectorAll('lightning-input-field')]
                .reduce((validSoFar, inputCmp) => {
                    if (inputCmp.required === false) {
                        return validSoFar;
                    }
                    if ((typeof (inputCmp.value) !== 'boolean') && !inputCmp.value) {
                        return validSoFar && false;
                    }
                    return validSoFar && true;
                },true); //Added for MKT26-93

            let quantityDOM = [...this.template.querySelectorAll('lightning-input')];
            let quantityValid = true;
            if (quantityDOM.length > 0) {
                quantityValid = quantityDOM.reduce((validSoFar, inputCmp) => {
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
                });
            }

            if (allValid === false || quantityValid === false) {
                this.template.querySelector('.dummyButton lightning-button:first-child').click();
            }
            return allValid && quantityValid;
        }
        return true;
    }
    @api atlassianValidation() {
        let numberAtlUsers = this.template.querySelector(`lightning-input-field[data-apiname="Number_of_Users_Atlassian__c"]`);
        if (this.selectedProductCat != undefined && this.selectedProductCat.includes('Atlassian Jira Cloud') && numberAtlUsers.value < 200) {
            return false;
        }
        return true;
    }

    @api validateHostEnv() {

        if ((this.currentHostingEnv == 'Rubrik Hosted' || this.currentHostingEnv == 'Customer Hosted') && (this.isWebTryAndBuy || (this._currentPOCType == 'Standard POC' && this.selectedProductCat.includes('M365 and Entra ID')))) {
            return false;
        }
        return true;
    }

    @api validateNumberOfUCL() {
        if (this.selectedProductCat != undefined && this.selectedProductCat.includes('UCL (Cloud Cluster, Cloud Native & Entra ID)') && (this._numberOfUCL > 5 || this._numberOfUCL < 1)) {
            return false;
        }
        return true;
    }
    

    @api validateCloudType(){
        let cloudType = this.template.querySelector(`lightning-input-field[data-apiname="Cloud_Type__c"]`);
        if (this.selectedProductCat != undefined && this.selectedProductCat.includes('Cloud Unstructured (S3, Azure Blob, and Cloud Files)') && (cloudType.value == null || cloudType.value == '' || cloudType.value == undefined)) {
            return false;
        }
        return true;


    }

    get rscgContactURL() {  //Added for MKT26-99
        return '/' + this.pocRscgContact;
    }
    
    get hideRscgUrl() { // Added for MKT26-99
        return this.pocRscgContact === undefined;
    }

    get isPocTypeWebTryAndBuy() {
        return this.isWebTryAndBuy === 'true';
    }

    get isRansomwareRecovery() {
        return this._currentPOCType === 'Ransomware Recovery Software';
    }

    get showProductTable() {

        return this.mainProductList.length > 0;
    }

    get getSectionOnLoad() {
        let allProd = [];
        this.mainProductList.forEach(prod => {
            allProd.push(prod.productName);
        });
        return allProd;
    }

    get showRSCSection() {
        var selectedProducts = this.getSelectedProducts();
        return selectedProducts.includes('RSC Enterprise Edition');
    }

    get saphanaKubernetesProtection() {
        var selectedProducts = this.getSelectedProducts();
        return selectedProducts.includes('Rubrik Appliance') || selectedProducts.includes('UCL (Cloud Cluster, Cloud Native & Entra ID)') || selectedProducts.includes('Edge');
    }

    get showPolarisDetails() {
        return this.getSelectedProducts().length > 0;
    }

    get rscGProduct() {
        if (this._currentPOCType == 'Standard POC : RSC-G') {
            return true;
        } else {
            return false;
        }
    }

    get thirdPartyAcknowledge() {
        return [
            { label: 'Yes', value: 'Yes' },
            { label: 'No', value: 'No' },
        ];
    }

    get rscPvtAck() {
        return [
            { label: 'Yes, my POC meets the requirements for RSC-Private', value: 'Yes' },
            { label: 'No, my POC does not meet the requirements for RSC-Private', value: 'No' },
        ];
    }
    get ransomeAck() {
        return [
            { label: 'Yes, my POC meets the requirements for Ransomware Recovery Software', value: 'Yes' },
            { label: 'No, my POC does not meet the requirements for Ransomware Recovery Software', value: 'No' },
        ];
    }
    get rscRegion() {
        return [
            { label: 'US', value: 'US' }

        ];
    }
    get proactiveAck() {
        return [
            { label: 'Yes, my POC meets the requirements for RSC Proactive Edition', value: 'Yes' },
            { label: 'No, my POC does not meet the requirements for RSC Proactive Edition', value: 'No' },
        ];
    }
    get showRSC3rdParty() {
        var selectedProducts = this.getSelectedProducts();
        return selectedProducts.includes('RSC 3rd Party S/W With Enterprise Ed.');
    }
    get showRSCG3rdParty() {
        var selectedProducts = this.getSelectedProducts();
        return selectedProducts.includes('RSC-G Third Party Software with Enterprise Edition');
    }

    get showRSCPrivateEd() {
        var selectedProducts = this.getSelectedProducts();
        return false;
        //return selectedProducts.includes('RSC-Private with Enterprise Edition') && this._currentPOCType !== 'Ransomware Recovery Software'; //updated for MKT26-93
    }

    get showRansomeAck() {
        var selectedProducts = this.getSelectedProducts();
        return selectedProducts.includes('RSC Enterprise Edition') && this._currentPOCType === 'Ransomware Recovery Software';
    }
    /*get showRSCProactiveEd() {
        var selectedProducts = this.getSelectedProducts();
        return selectedProducts.includes('RSC Proactive Edition') && (this._currentPOCType === 'Standard POC' ||this._currentPOCType === 'Conditional PO' ||this._currentPOCType === 'CSAT Loaner' ||this._currentPOCType === 'Partner Software Access');    
    }*/
    get showPartnerSoftwareAccessType() {
        return this._currentPOCType === 'Partner Software Access';
    }

    //dummy method but is needed!
    //weird hack but works!! 
    handleSubmit(event) {
        //return false;
        this.showToastMethod('Please update the invalid form entries and try again.', 'error', 'Error');
        event.preventDefault();
    }

    removeSelectedProduct(event) {
        var productName = event.target.dataset.productname;
        var productIndex = event.target.dataset.productIndex;
        let prodInstance = this.mainProductList.filter(arr => arr.productName === productName);
        prodInstance[0].instances.splice(productIndex, 1);
        setProductVisibility(prodInstance[0]);
    }

    removeSelectedAccessories(event) {
        var productName = event.target.dataset.productname;
        var accessoryIndex = event.target.dataset.productIndex;
        let prodInstance = this.mainProductList.filter(arr => arr.productName === productName);
        prodInstance[0].accessories.splice(accessoryIndex, 1);
        setAccessoryVisibility(prodInstance[0]);
    }

    getSelectedProducts() {
        if (this.isPocTypeWebTryAndBuy) {
            return ['M365 and Entra ID'];
        }
        return this.template.querySelector('lightning-checkbox-group').value || [];
    }

    getWillYouBeProtecting() {
        return ([...this.template.querySelectorAll('[data-product="sapHanaProtection"] lightning-input-field')].filter(node => node.value === true)).length > 0;

    }

    getShowPicklistVal() {
        return ([...this.template.querySelectorAll('[data-product="sapHanaProtection"] lightning-input-field')].filter(node => node.value === true)).length > 0;
    }

    getCloudClusterWithUcl() {
        var selectedProducts = this.getSelectedProducts();
        var ccLocationvalue = '';
        if (selectedProducts.includes('UCL (Cloud Cluster, Cloud Native & Entra ID)')) {
            [...this.template.querySelectorAll('[data-product="UCL (Cloud Cluster, Cloud Native & Entra ID)"] lightning-input-field')].forEach(field => {
                ccLocationvalue = field.value;
                
            });
        }
        return (ccLocationvalue === 'AWS' || ccLocationvalue === 'Azure');
    }
    @track cloudLocation;

    _isIdentityResilience = false;
    _isIdentityRecovery = false;
    _isIdentityRecoveryForOkta = false; //added for MKT26-1427
    _isGoogleWorkspace = false;
    handleCloudClusterLocationChange(event) {
        
        if(event.target.name == 'Add_Identity_Resilience__c'){
            if(event.target.value == 'Yes'){
                this._isIdentityResilience = true;
            }else{
                this._isIdentityResilience = false;
            }
            
        }
        if(event.target.name == 'Add_Identity_Recovery__c'){
            if(event.target.value == 'Yes'){
                this._isIdentityRecovery = true;
            }else{
                this._isIdentityRecovery = false;
            }
            
        }
        //below if block is added for MKT26-1427
        if(event.target.name == 'Identity_Cyber_Recovery_for_Okta__c'){
            if(event.target.value == 'Yes'){
                this._isIdentityRecoveryForOkta = true;
            }else{
                this._isIdentityRecoveryForOkta = false;
            }
            
        }
        if(event.target.name == 'M365_Hosting_environment__c'){
           this.hostingEnvironmentWebtry = event.target.value;
           this.hostingEnvironmentOtherThenWebtry = event.target.value;
        }

        //added for MKT26-1556
        if(event.target.name == 'Google_Workspace__c'){
            if(event.target.value == 'Yes'){
                this._isGoogleWorkspace = true;
            }else{
                this._isGoogleWorkspace = false;
            }
        }
        
        this.mainProductList.forEach((prod) => {
            prod.productFields.forEach((prodField) => {
                let prodFieldObj = prodField;
                
                if(prod.productName == 'Identity Recovery and Resilience - AD, Entra ID, Okta' && prodFieldObj.Field_Api_Name__c == 'Add_Identity_Resilience__c'){
                    prodFieldObj.isIdentityResilience = this._isIdentityResilience;
                }
                if(prod.productName == 'Identity Recovery and Resilience - AD, Entra ID, Okta' && prodFieldObj.Field_Api_Name__c == 'Add_Identity_Recovery__c'){
                    prodFieldObj.isIdentityRecovery = this._isIdentityRecovery;
                }
          //below if block is added for MKT26-1427
                if(prod.productName == 'Identity Recovery and Resilience - AD, Entra ID, Okta' && prodFieldObj.Field_Api_Name__c == 'Identity_Cyber_Recovery_for_Okta__c'){
                    prodFieldObj.isIdentityRecoveryForOkta = this._isIdentityRecoveryForOkta;
                }
          
                //added for MKT26-1556
                if(prod.productName == 'M365 and Google Workspace' && prodFieldObj.Field_Api_Name__c == 'Google_Workspace__c'){
                    prodFieldObj.isGoogleWorkspace = this._isGoogleWorkspace;
                }
            })
        })
        
        if (event.target.name === 'Cloud_Cluster_Location__c' ) {
            this.mainProductList.forEach((prod) => {
                prod.productFields.forEach((prodField) => {
                    let prodFieldObj = prodField;

                    prodFieldObj.isCombobox = false;
                    if (this.selectedProductCat.includes('UCL (Cloud Cluster, Cloud Native & Entra ID)') && prodFieldObj.Field_Api_Name__c === 'UCL_Edition__c' && event.target.value && event.target.value === 'Azure') {
                        this.isAzureSelected = true;
                        this.isAWSSelected = false;
                        
                        prodFieldObj.label = 'UCL Edition';
                        let options = [];
                        prodFieldObj.isCombobox = true;
                        options.push({ label: '--None--', value: null });
                        options.push({ label: 'UCL with Customer-hosted Enterprise Edition (No RCV)', value: 'UCL with Customer-hosted Enterprise Edition (No RCV)' });
                        
                        prodFieldObj.options = options;

                        prodFieldObj.value = "";
                        this.uclEdition = "";

                    } else if (this.selectedProductCat.includes('UCL (Cloud Cluster, Cloud Native & Entra ID)') && prodFieldObj.Field_Api_Name__c === 'UCL_Edition__c' && event.target.value && (event.target.value === 'AWS' || event.target.value === 'GCP')) {
                        prodFieldObj.label = 'UCL Edition';
                        let options = [];
                        prodFieldObj.isCombobox = true;
                        this.isAzureSelected = false;
                        
                        
                        options.push({ label: '--None--', value: null });
                        if(event.target.value === 'AWS'){
                            options.push({ label: 'UCL with Customer-hosted Enterprise Edition (No RCV)', value: 'UCL with Customer-hosted Enterprise Edition (No RCV)' });
                        } else{
                            options.push({label: 'UCL with Customer-hosted Foundation Edition (No RCV)', value : 'UCL with Customer-hosted Foundation Edition (No RCV)'});
                        }
                        prodFieldObj.options = options;
                        prodFieldObj.value = "";
                        this.uclEdition = "";
                        if(event.target.value === 'AWS' ){
                            this.isAWSSelected = true;
                        } else{
                            this.isAWSSelected = false;
                        }

                    } else if (this.selectedProductCat.includes('UCL (Cloud Cluster, Cloud Native & Entra ID)') && (prodFieldObj.Field_Api_Name__c === 'UCL_Edition__c' || prodFieldObj.Field_Api_Name__c === 'Number_Of_UCL_FETB__c')) {
                        console.log('Val621 :: ',prodFieldObj );
                        if (prodFieldObj.Field_Api_Name__c === 'UCL_Edition__c') {
                            prodFieldObj.label = 'UCL Edition';

                            let options = [];
                            prodFieldObj.isCombobox = false;
                            prodFieldObj.disable = true;
                            options.push({ label: '--None--', value: null });

                            prodFieldObj.options = options;
                            prodFieldObj.value = '';
                        } else if (prodFieldObj.Field_Api_Name__c === 'Number_Of_UCL_FETB__c') {
                            prodFieldObj.isCombobox = false;
                            prodFieldObj.value = 1;
                            prodFieldObj.disable = true;
                        }



                    }else{
                        this.isAWSSelected = false;
                        this.isAzureSelected = false;
                    }
                });
            });
        }

        if (event.target.dataset.apiname == 'M365_Hosting_environment__c') {
            this.currentHostingEnv = event.target.value;
        }

        // if(event.target.fieldName == 'Cloud_Cluster_Location__c'){
        //     this.cloudLocation = event.target.value;
        // }
        if (event.target.dataset.apiname == 'Cloud_Cluster_Location__c') {
            this.cloudLocation = event.target.value;
        }

        if (event.target.dataset.apiname == 'Number_Of_UCL_FETB__c') {
            this._numberOfUCL = event.target.value;
        }
        if (event.target.dataset.apiname == 'Number_Of_NCD_FETB__c') {
            this._numberOfNCD = event.target.value;
        }
		if(event.target.dataset.apiname == 'NCD_Editions__c' ){
            this._ncdEdition = event.target.value;
        }
        


        //let ncdValue = 1;
        let uclValue = 1;
        let numberUCL = this.template.querySelector(`lightning-input-field[data-apiname="Number_Of_UCL_FETB__c"]`);
        let numberNCD = this.template.querySelector(`lightning-input-field[data-apiname="Number_Of_NCD_FETB__c"]`);
        if (event.target.name === 'Data_Redundancy_Archive__c') {
            
            this.dataRedundacyArchValue = event.target.value;
            let dataRedundancyArchiveField = this.template.querySelector(`lightning-input-field[data-apiname="Data_Redundancy_Archive__c"]`);
            this.showStorageRegionBundleArchive = (event.target.value && event.target.value !== 'Single Zone (LRS)');
            let storageRegionRCVArchive = this.template.querySelector(`lightning-input-field[data-apiname="Storage_Region_Bundle_RCV_Archive__c"]`);
            let storageRegionGovArchive = this.template.querySelector(`lightning-combobox[data-id="Storage_Region_Bundle_RCV_Archive__c"]`);
            storageRegionGovArchive?.classList.add('slds-hide');
            if(event.target.value === 'Single Zone (LRS)'){
                if(storageRegionGovArchive){
                    storageRegionGovArchive?.classList.remove('slds-hide');
                    storageRegionGovArchive.value='';
                }
                if(storageRegionRCVArchive){
                    storageRegionRCVArchive?.classList.remove('slds-hide');
                    storageRegionRCVArchive.value='';
                }
            } else {
               this.storageRegionGovArc ='';
            }
            if (dataRedundancyArchiveField) {
                let parentContainer = dataRedundancyArchiveField.closest('.slds-form-element');

                if (parentContainer) {
                    let existingBanner = this.template.querySelector('.storage-region-archive');
                    
                    if (existingBanner) {
                        existingBanner.remove();
                    }

                    if (this.showStorageRegionBundleArchive && !this.selectedProductCat.includes('Rubrik Cloud Vault')) { // MKT26-688
                        let banner = document.createElement('span');
                        banner.className = 'slds-m-top_x-small slds-notify_alert storage-region-archive';
                        banner.textContent = 'You do not need to configure the storage region bundle for multi-zone (ZRS). Multi-zone (ZRS) can be configured in any customer region of choice.';

                        parentContainer.appendChild(banner);
                    }
                    
                }
            }

            this.mainProductList.forEach((prod) => {
                prod.productFields.forEach((prodField) => {
                    let prodFieldObj = prodField;
                    if((storageRegionRCVArchive || storageRegionGovArchive) && this.selectedProductCat && (this.selectedProductCat.includes('Rubrik Cloud Vault') || this.selectedProductCat.includes('Rubrik Cloud Vault - Government')) && prodFieldObj.Field_Api_Name__c == 'Storage_Region_Bundle_RCV_Archive__c' && this.dataRedundacyArchValue !== 'Single Zone (LRS)'){
                        storageRegionRCVArchive?.classList.add('slds-hide');
                        storageRegionGovArchive?.classList.add('slds-hide');
                        prodFieldObj.Required__c = false;                    
                        prodFieldObj.value =''
                    }
                })
            })
            this.dispatchRCVGOVEvent();
        }else if(event.target.name === 'Data_Redundancy_Backup__c') { 
            this.dataredundancyBackup = event.target.value;
            let dataRedundancyBackupField = this.template.querySelector(`lightning-input-field[data-apiname="Data_Redundancy_Backup__c"]`);
            this.showStorageRegionBundleBackup = (event.target.value && event.target.value !== 'Single Zone (LRS)');
            let storageRegionRCVBackup = this.template.querySelector(`lightning-input-field[data-apiname="Storage_Region_Bundle_RCV_Backup__c"]`);
            let storageRegionGovBackup = this.template.querySelector(`lightning-combobox[data-id="Storage_Region_Bundle_RCV_Backup__c"]`);
            storageRegionGovBackup?.classList.add('slds-hide');
            if(event.target.value === 'Single Zone (LRS)'){
                if(storageRegionGovBackup){
                    storageRegionGovBackup?.classList.remove('slds-hide');
                    storageRegionGovBackup.value='';
                }
                if(storageRegionRCVBackup){
                    storageRegionRCVBackup?.classList.remove('slds-hide');
                    storageRegionRCVBackup.value='';
                }
            }else {
                this.storageRegionGovBack ='';
            }
            if (dataRedundancyBackupField ) {
                let parentContainer = dataRedundancyBackupField.closest('.slds-form-element');
        
                if (parentContainer) {
                    let existingBanner = this.template.querySelector('.storage-region-backup');
                    if (existingBanner) {
                        existingBanner.remove();
                    }
                    
                    }
                }
            
            this.dispatchRCVGOVEvent();
        }
        if(event.target.name ===  'Storage_Region_Bundle_RCV_Archive__c' && (this.selectedProductCat.includes('Rubrik Cloud Vault - Government') || this.selectedProductCat.includes('Rubrik Cloud Vault'))){
            this.storageRegionGovArc = event.target.value;
            this.dispatchRCVGOVEvent();
        } else if(event.target.name ===  'Storage_Region_Bundle_RCV_Backup__c' && (this.selectedProductCat.includes('Rubrik Cloud Vault - Government') || this.selectedProductCat.includes('Rubrik Cloud Vault'))){
            this.storageRegionGovBack = event.target.value;
            this.dispatchRCVGOVEvent();
        }
        if (event.target.name == 'RCV_Backup_Tier__c' || event.target.name == 'RCV_Archive_Tier__c' || event.target.name == 'Data_Redundancy_Backup__c' || event.target.name == 'Data_Redundancy_Archive__c') {
            let dataRedundancyArchvGov = this.template.querySelector(`lightning-input-field[data-apiname="Data_Redundancy_Archive__c"]`);
            let dataRedundancyBackupRCV_Gov = this.template.querySelector(`lightning-input-field[data-apiname="Data_Redundancy_Backup__c"]`);
            this.mainProductList.forEach((prod) => {
                prod.productFields.forEach((prodField) => {
                    let prodFieldObj = prodField;
                    
                    if (this.selectedProductCat.includes('Rubrik Cloud Vault') && ((event.target.name == 'RCV_Backup_Tier__c' ) || (event.target.name == 'RCV_Archive_Tier__c' ) )) {
                        
                        if (event.target.value == 'No' || event.target.value =='') {  
                            prodFieldObj.Required__c = false;
                        } else {
                            prodFieldObj.disable = false;
                            prodFieldObj.Required__c = true;
                        }

                    }
                    if(this.selectedProductCat.includes('Rubrik Cloud Vault - Government') && (event.target.name ===  'RCV_Archive_Tier__c' || event.target.name ===  'Data_Redundancy_Archive__c' ) && prodFieldObj.Field_Api_Name__c === 'Data_Redundancy_Archive__c' && (event.target.value === 'Yes' || event.target.value === 'Single Zone (LRS)')){
                        this.showDataRedundancyArchive = true;
                        dataRedundancyArchvGov?.classList.remove('slds-hide');
                        let dataRedundancyGovArchive = this.template.querySelector(`lightning-combobox[data-id="Data_Redundancy_Archive__c"]`);
                        if(dataRedundancyGovArchive){
                            dataRedundancyGovArchive.classList.remove('slds-hide');
                        }
                        let options = [];
                        prodFieldObj.label = 'Data Redundancy ( Archive )';
                        prodFieldObj.apiname = 'Data_Redundancy_Archive__c';
                        prodFieldObj.isCombobox = true;
                        options.push({label: '--None--', value:''});
                        options.push({label: 'Single Zone (LRS)', value:'Single Zone (LRS)'});
                        prodFieldObj.options = options;
                        prodFieldObj.value='';
                    }
                    if(event.target.name ===  'RCV_Archive_Tier__c' && prodFieldObj.Field_Api_Name__c === 'RCV_Archive_Tier__c' && event.target.value === 'Yes'){
                       this.showDataRedundancyArchive = true;
                        if(dataRedundancyArchvGov && this.selectedProductCat && this.selectedProductCat.includes('Rubrik Cloud Vault - Government') && prodFieldObj.Field_Api_Name__c == 'RCV_Archive_Tier__c' && this.showDataRedundancyArchive){
                            dataRedundancyArchvGov.classList.remove('slds-hide');
                        }
                    } else if(event.target.name ===  'RCV_Archive_Tier__c' && prodFieldObj.Field_Api_Name__c === 'RCV_Archive_Tier__c' && (event.target.value === 'No' || event.target.value ==='')){
                        this.showDataRedundancyArchive = false;
                        let storageRegionRCVArchive  = this.template.querySelector(`lightning-input-field[data-apiname="Storage_Region_Bundle_RCV_Archive__c"]`);
                        storageRegionRCVArchive?.classList.add('slds-hide');
                        let storageRegionGovArch = this.template.querySelector(`lightning-combobox[data-id="Storage_Region_Bundle_RCV_Archive__c"]`);
                        storageRegionGovArch?.classList.add('slds-hide');
                        let dataRedundancyArchv = this.template.querySelector(`lightning-input-field[data-apiname="Data_Redundancy_Archive__c"]`);
                        let dataRedundancyGovArchive = this.template.querySelector(`lightning-combobox[data-id="Data_Redundancy_Archive__c"]`);
                        if(dataRedundancyGovArchive){
                            dataRedundancyGovArchive.value =''
                            dataRedundancyGovArchive.classList.add('slds-hide');
                        }
                        if(dataRedundancyArchv){
                            dataRedundancyArchv.value = '';
                        }
                        if(storageRegionGovArch ){
                            storageRegionGovArch.value='';
                        }
                        if(storageRegionRCVArchive){
                            storageRegionRCVArchive.value=''
                        }
                        let dataRedundancyArchive = this.template.querySelector(`lightning-input-field[data-apiname="Data_Redundancy_Archive__c"]`);
                        if(dataRedundancyArchive){
                            dataRedundancyArchive.value = '';
                        }
                        if(dataRedundancyArchvGov && this.selectedProductCat && this.selectedProductCat.includes('Rubrik Cloud Vault - Government') && prodFieldObj.Field_Api_Name__c == 'RCV_Archive_Tier__c'  && !this.showDataRedundancyArchive){
                            dataRedundancyArchvGov.classList.add('slds-hide');
                            prodFieldObj.Required__c = false;
                        }
                    } 
                    
                    if(event.target.name ===  'RCV_Backup_Tier__c' && prodFieldObj.Field_Api_Name__c === 'RCV_Backup_Tier__c' && event.target.value === 'Yes' ){
                        this.showDataRedundancyBackup = true;
                        if(dataRedundancyBackupRCV_Gov && this.selectedProductCat && this.selectedProductCat.includes('Rubrik Cloud Vault - Government') && prodFieldObj.Field_Api_Name__c == 'RCV_Backup_Tier__c' && this.showDataRedundancyBackup){
                            dataRedundancyBackupRCV_Gov.classList.remove('slds-hide');
                            this.handleBannerDisplay(
                                dataRedundancyBackupRCV_Gov, 
                                'data-redundancy-backup-banner', 
                                'Only select ZRS or GRS if your opportunity requires it. Otherwise, use LRS.', 
                                this.showDataRedundancyBackup
                            );
                        }
                    } else if(event.target.name ===  'RCV_Backup_Tier__c' && prodFieldObj.Field_Api_Name__c === 'RCV_Backup_Tier__c' && (event.target.value === 'No' || event.target.value ==='')){
                        this.showDataRedundancyBackup = false;
                        let storageRegionRCVBackup = this.template.querySelector(`lightning-input-field[data-apiname="Storage_Region_Bundle_RCV_Backup__c"]`);
                        let storageRegionGovBackup = this.template.querySelector(`lightning-combobox[data-id="Storage_Region_Bundle_RCV_Backup__c"]`);
                        storageRegionGovBackup?.classList.add('slds-hide');
                        let dataRedundancyBackup = this.template.querySelector(`lightning-input-field[data-apiname="Data_Redundancy_Backup__c"]`);
                        if(dataRedundancyBackup){
                            dataRedundancyBackup.value = '';
                        }
                        let dataRedundancyBackupGOV = this.template.querySelector(`lightning-combobox[data-id="Data_Redundancy_Backup__c"]`);
                        if(dataRedundancyBackupGOV){
                            dataRedundancyBackupGOV.value = '';
                        }
                        storageRegionRCVBackup?.classList.add('slds-hide');
                        if(storageRegionRCVBackup){
                            storageRegionRCVBackup.value = '';
                        }
                        if(storageRegionGovBackup){
                            storageRegionGovBackup.value = '';
                        }
                        if(dataRedundancyBackupRCV_Gov && this.selectedProductCat && this.selectedProductCat.includes('Rubrik Cloud Vault - Government') && prodFieldObj.Field_Api_Name__c == 'RCV_Backup_Tier__c'  && !this.showDataRedundancyBackup){
                            dataRedundancyBackupRCV_Gov.classList.add('slds-hide');
                            prodFieldObj.Required__c = false;
                            this.handleBannerDisplay(
                                dataRedundancyBackupRCV_Gov, 
                                'data-redundancy-backup-banner', 
                                'Only select ZRS or GRS if your opportunity requires it. Otherwise, use LRS.', 
                                this.showDataRedundancyBackup
                            );
                        }
                        
                    }
                })
            })
        }

        if (event.target.name == 'UCL_Edition__c' || event.target.name == 'NCD_Editions__c') {

            //this.uclEdition = event.target.value;

            if (event.target.name == 'UCL_Edition__c') {
                this.uclEdition = event.target.value;
                if (event.target.value === 'Foundation Edition (CNP for Azure w/RCV Backup Tier)' || event.target.value === 'Enterprise Edition (CNP for Azure w/RCV Backup Tier + Ransomware Investigation + Data Classification)') {
                    this.uclValue = null;
                    this.uclEdition = event.target.value;
                } else if (event.target.value === 'Basic UCL (No RCV)') {
                    this.uclEdition = event.target.value;
                } else if (event.target.value === "" || event.target.value === null) {
                    this.uclEdition = ""
                }

                
            }


            
                
            this.mainProductList.forEach((prod) => {
                prod.productFields.forEach((prodField) => {
                    let prodFieldObj = prodField;
                    
                    if(this.selectedProductCat.includes('UCL (Cloud Cluster, Cloud Native & Entra ID)') && prodFieldObj.Field_Api_Name__c == 'UCL_Edition__c'){
                        prodFieldObj.value = this.uclEdition;
                        numberUCL.value = 1;
                    }
                    if (this.selectedProductCat.includes('UCL (Cloud Cluster, Cloud Native & Entra ID)') && prodFieldObj.Field_Api_Name__c == 'Number_Of_UCL_FETB__c' && this.uclEdition == 'Basic UCL (No RCV)') {
                        prodFieldObj.disable = true;
                        numberUCL.value = 1;
                    }
                    if (this.selectedProductCat.includes('UCL (Cloud Cluster, Cloud Native & Entra ID)') && prodFieldObj.Field_Api_Name__c == 'Number_Of_UCL_FETB__c' && (this.uclEdition == 'Foundation Edition (CNP for Azure w/RCV Backup Tier)' || this.uclEdition == 'Enterprise Edition (CNP for Azure w/RCV Backup Tier + Ransomware Investigation + Data Classification)')) {
                        numberUCL.value = this.uclValue;
                    }

                    if (this.selectedProductCat.includes('UCL (Cloud Cluster, Cloud Native & Entra ID)') && prodFieldObj.Field_Api_Name__c == 'Number_Of_UCL_FETB__c' && this.uclEdition != 'Basic UCL (No RCV)') {
                        if (this.uclEdition == '') {
                            prodFieldObj.disable = true;
                            numberUCL.value = 0;
                        } else {
                            prodFieldObj.disable = false;
                        }
                    }

                    if(this.selectedProductCat.includes('NAS Cloud Direct') && prodFieldObj.Field_Api_Name__c == 'Number_Of_NCD_FETB__c'){
                        if(this._ncdEdition == 'Bundled with Cloud Unstructured'){
                            prodFieldObj.disable = true;
                            prodFieldObj.Required__c = false;
                            prodFieldObj.value = null;
                        }else{
                            prodFieldObj.disable = false;
                            prodFieldObj.Required__c = true;
                            prodFieldObj.value = 0;
                        }
                    }

                })
            })
        }

        const uclEditionEvent = new CustomEvent('ucledition', {
            detail: this.uclEdition
        });
        //Dispatch Event
        this.dispatchEvent(uclEditionEvent);
        
        this._cloudClusterWithUcl = this.getCloudClusterWithUcl();
    }
    handleProtectionChange(event) {
        this._willYouBeProtecting = this.getWillYouBeProtecting();
    }

    handleRSCContentSelection(event) {
        var isSelected = false;
        [...this.template.querySelectorAll('[data-ismainbundle="false"][data-rscsection="true"]')].forEach(element => (isSelected = element.checked || isSelected));
        this.template.querySelector('[data-ismainbundle="true"][data-rscsection="true"]').disabled = isSelected;
        this._showPolaris = isSelected;
    }

    handleRSCSelection(event) {
        [...this.template.querySelectorAll('[data-ismainbundle="false"][data-rscsection="true"]')].forEach((element) => {
            element.disabled = event.target.checked;
            element.checked = false
        });
        this._showPolaris = event.target.checked;
    }

    handleProductCategoryChange(event) {
        dem = event.detail.value;
        cupr = [event.detail.value];
        let selectedProductValues = Object.values(event.detail.value);
        this.selectedProductCat = selectedProductValues;
        let protoArray = this._productPrototypes;
        let metaList = this.mainProductList.map(curr => curr.productName);
        if (metaList.length < selectedProductValues.length) {
            selectedProductValues.forEach(product => {
                if (!metaList.includes(product)) {
                    let protoArrayObj = protoArray[product];
                    computeAddAccessoryBtn(protoArrayObj);
                    this.mainProductList.push(Object.assign({}, protoArrayObj));
                }
            });

            if(selectedProductValues.includes('Identity Recovery and Resilience - AD, Entra ID, Okta')) {
                this.mainProductList.forEach( (product) => {
                    if( product.productName === 'Identity Recovery and Resilience - AD, Entra ID, Okta') {
                        product.productFields.forEach( field => {
                            if(field.Field_Api_Name__c === 'Add_Identity_Recovery__c' ) {
                                field['identityRecoveryBanner'] = true;
                            }
                        });
                    }
                });
            }
            
            //Start - Added for MKT26-410, 405, 490
            if(selectedProductValues.includes('RSC Enterprise and Proactive Editions') || selectedProductValues.includes('RSC-G Enterprise and Proactive Editions') || selectedProductValues.includes('RSC-Private') || selectedProductValues.includes('Annapurna') ) {
                this.mainProductList.forEach( (product) => {
                    if( product.productName === 'RSC Enterprise and Proactive Editions' || product.productName === 'RSC-G Enterprise and Proactive Editions' || product.productName === 'Annapurna') {
                        product.productFields.forEach( field => {
                            if( field.Field_Api_Name__c === 'RSC_Enterprise_Edition__c' || field.Field_Api_Name__c === 'RSC_G_Enterprise_Edition__c' ) {
                                field['rscEEBanner'] = true;
                            }
                            if( field.Field_Api_Name__c === 'RSC_Proactive_Edition__c' || field.Field_Api_Name__c === 'RSC_G_Proactive_Edition__c') {
                                field['rscPEBanner'] = true;
                            }
                            if(  product.productName === 'Annapurna'  ) {
                                field['annapurnaBanner'] = true;
                            }
                        });
                    }
                    if( product.productName === 'RSC-Private' ) {
                        product['rscpAckBanner'] = true;
                    }
                });
            }
            //End - Added for MKT26-410, 405, 490
        } else {
            metaList.forEach((product, index) => {
                if (!selectedProductValues.includes(product)) {
                    this.mainProductList.splice(index, 1);
                }
            })
            if (!selectedProductValues.includes('UCL (Cloud Cluster, Cloud Native & Entra ID)')){
                this._cloudClusterWithUcl = false;
                this.isAzureSelected = false;
                this.isAWSSelected = false;
                this.cloudLocation = '';
            }
        }
    }

    handleSectionToggle(event) {
        const openSections = event.detail.openSections;

        this.mainProductList.forEach(product => {
            product.isProductM365 = (product.productName == 'M365 and Entra ID') ? true : false;
            product.isProductM365AndGSpace = (product.productName == 'M365 and Google Workspace') ? true : false;
            product.isM365Selected = (product.productName == "M365") ? true : false;
            product.isSaaS = (product.productName == "SaaS (Jira Cloud, Salesforce)") ? true : false;
            product.identityResilience = (product.productName == "Identity Recovery and Resilience - AD, Entra ID, Okta") ? true : false;
            product.identityRecovery = (product.productName == "Identity Recovery") ? true : false;
            product.isCloudUnstructured = (product.productName == "Cloud Unstructured (S3, Azure Blob, and Cloud Files)") ? true : false;
            product.isRubrikAgentCloud = (product.productName == 'Rubrik Agent Cloud') ? true : false;

            product.showUCLBanner  =  product.productName === "UCL (Cloud Cluster, Cloud Native & Entra ID)"; 
            product.isRubrikAppliance = product.productName === "Rubrik Appliance";  //Added for MKT26-101
        });
        
        if (event.target.dataset['position']) {
            this.mainProductList.forEach(product => {
                product.isAccordionOpen = openSections.includes(product.productName);
            });
        }
        if (event.target.dataset['sectionName']) {
            let parentProduct = event.target.parentElement.dataset['productName'];
            let sectionName = event.target.dataset['sectionName'];
            let product = this.mainProductList.filter(arr => arr.productName === parentProduct);
            if (sectionName === 'accessory') {
                product[0].accessories.forEach(acc => {
                    product[0].accessoryAccMap[acc] = openSections.includes(acc);
                });
            } else if (sectionName === 'product') {
                product[0].instances.forEach(acc => {
                    product[0].productAccMap[acc] = openSections.includes(acc);
                });
            }
        }
        
    }

    handlePolarisRegionChange(event) {
        this.template.querySelector('[data-product="polarisDetails"] lightning-input-field:nth-child(2)').disabled = event.detail.value === 'N/A - RSC Private';
        this.template.querySelector('[data-product="polarisDetails"] lightning-input-field:nth-child(2)').required = event.detail.value !== 'N/A - RSC Private';
    }

    addMoreProductInstances(event) {
        var productName = event.target.dataset.productname;
        let prodInstance = this.mainProductList.filter(arr => arr.productName === productName);
        addProduct(prodInstance[0]);
    }

    addMoreAccessories(event) {
        let productName = event.target.dataset.productname;
        let prodindex = event.target.dataset.prodindex;
        let prodInstance = this.mainProductList.filter(arr => arr.productName === productName);
        addAccessory(prodInstance[0]);
    }

    getMetadata() {
        Promise.all([getProductMetadata(), getProductSKUs()])
            .then(result => {
                this.prodTypes = [];
                this.productCategories = [];
                this._pocProductAttributes = {};
                let fields = result[0];
                this.skus = result[1];
                for (let productType in fields) {
                    this.productCategories.push({
                        "label": fields[productType].prodCategory,
                        "value": fields[productType].prodCategory

                    });

                    this._productPrototypes[fields[productType].prodCategory] = new ProductClass(
                        fields[productType].prodCategory,
                        fields[productType].fields,
                        fields[productType].multiProduct,
                        fields[productType].prodCategory === 'Rubrik Appliance',
                        fields[productType].pocTypes
                    );

                }
                if (this.isPocTypeWebTryAndBuy) {
                    this.selectedProductCategories.push('M365 and Entra ID');
                    this.mainProductList.push(Object.assign({}, this._productPrototypes['M365 and Entra ID']));
                }
                if (this._currentPOCType !== "") {
                    this.processProductPickerOptions();
                }
            }, error => this.error).catch(error => this.error)
    }

    processProductPickerOptions() {
        this.productCategories = [];
        Object.keys(this._productPrototypes).forEach((fieldName) => {
            if (fieldName && this._productPrototypes[fieldName] && this._productPrototypes[fieldName].validPOCTypes.includes(this._currentPOCType)) {
                this.productCategories.push({
                    "label": fieldName,
                    "value": fieldName
                });
            }
        });
    }
    @api
    checkValidationForCombobox() {
        let isValid = true;
        let checkBoxFieldCloudLocation = this.template.querySelector(`lightning-input-field[data-apiname="Cloud_Cluster_Location__c"]`); 
        let checkFieldUclEdition = this.selectedProductCat?.includes('UCL (Cloud Cluster, Cloud Native & Entra ID)') && !this.uclEdition;
        if ((checkBoxFieldCloudLocation && (checkBoxFieldCloudLocation?.value == null || checkBoxFieldCloudLocation?.value == "")) || checkFieldUclEdition) {
            isValid = false;
        }
        return isValid;
    }

    dispatchRCVGOVEvent(){
        const dataReduncyArchive = this.dataRedundacyArchValue ?? '';
        const storageRegionRCVArchGov = this.storageRegionGovArc ?? '';
        const storageRegionRCVBackupGov = this.storageRegionGovBack ?? '';
        const eventDetailString = `${dataReduncyArchive};${storageRegionRCVArchGov};${storageRegionRCVBackupGov}`;
        const GovDataAndStorage = new CustomEvent('govdataandstorage', {
            detail: eventDetailString
        });
        this.dispatchEvent(GovDataAndStorage);
    }
    
        

    get dataRedundancyArchiveOptions(){
        return [
            { label: 'Single Zone (LRS)', value: 'Single Zone (LRS)' },
            { label: 'Multi Zone (ZRS)', value: 'Multi Zone (ZRS)' }
        ]
    }



    handleBannerDisplay(fieldElement, bannerClass, bannerText, showCondition) {
        
        if (fieldElement) {
            let parentContainer = fieldElement.closest('.slds-form-element');
            if (parentContainer) {
                let existingBanner = this.template.querySelector(`.${bannerClass}`);
                
                if (showCondition) {
                    fieldElement.classList.remove('slds-hide');
    
                    if (!existingBanner) {
                        let banner = document.createElement('span');
                        banner.className = `slds-notify_alert ${bannerClass}`;
                        banner.textContent = bannerText;
                        if(bannerClass === 'data-redundancy-banner'){
                            let archiveBanner  = this.template.querySelector(`lightning-input-field[data-apiname="Archive_TB__c"]`).closest('.slds-form-element');
                            archiveBanner.appendChild(banner);
                        } else if(bannerClass === 'data-redundancy-backup-banner'){
                            let backupBanner  = this.template.querySelector(`lightning-input-field[data-apiname="Backup_TB__c"]`).closest('.slds-form-element');
                            backupBanner.appendChild(banner);
                        }
                    }
                } else {
                    fieldElement.classList.add('slds-hide');
                    if (existingBanner) {
                        existingBanner.remove();
                    }
                }
            }
        }
    }
    
}