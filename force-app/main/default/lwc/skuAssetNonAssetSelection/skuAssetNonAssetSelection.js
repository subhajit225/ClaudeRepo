/************This component is build for story FY25SR-1705************************************************/
import { LightningElement, track, api, wire } from 'lwc';
import getNetorkTypePickValues from '@salesforce/apex/SKUNewReplacementController.fetchNetworkTypeForAssetNonAsset';
import getR7kProducts from '@salesforce/apex/ReplacementQueryController.getR7kProducts';
import nonAssetBasedPath from '@salesforce/label/c.NonAssetBasedPath';
import assetBasedPath from '@salesforce/label/c.assetBasedPath';

export default class SkuAssetNonAssetSelection extends LightningElement {
@api customerrors;
@api rowsel;
@api sourceent;
@api sourcequantitysum;
@api sourcePath;
@api sourcecustomindex;
@api targetPathSKU = [];
@api selectedPath = [];
@api selectedOptions = [];
@track showmsg;
@track showSpinner;
@api quoteDetails;
@track message;
@track networkSelValue;
@track networkTypeOptions = [];
@track networkTypeFilter;
@track componentVisible = false;
nonAssetVerbiage = nonAssetBasedPath;
assetVerbiage = assetBasedPath;

async connectedCallback(){
try{
    if(this.rowsel.pathFromSKU != undefined){
        this.sourcePath = this.rowsel.pathFromSKU;
    }    

    let networkValues = await getNetorkTypePickValues();
    if(networkValues != undefined && Array.isArray(networkValues) && networkValues.length > 0){
            this.networkTypeOptions = networkValues.map(item => ({
                    label: item.label,
                    value: item.value,
                    selected: item.selected
            })); 
    }
    let elgibleProducts = await getR7kProducts();
    if(this.rowsel.pathFromSKU === 'Hardware' && this.rowsel.productReplacementCategory === 'Enterprise Data Protection - Scale'){
        let targetItem = [];
            targetItem.push({
                label: 'Non Asset',
                        value: 'Non Asset',
                        selected: false
            });
            this.targetPathSKU = targetItem;
    }else if (Array.isArray(elgibleProducts) && elgibleProducts.length > 0) {
        let targetItem = [];
        let assignData = JSON.parse(JSON.stringify(elgibleProducts));
        const type = (this.quoteDetails.SBQQ__Opportunity2__r.Aspen_Eligibility__c === 'Proposed Aspen' &&
                  !this.quoteDetails.SBQQ__Opportunity2__r.Override__c) ? 'Aspen' : 'Polaris';
            assignData.forEach(prd => {
                if (prd.Family == 'R7000' && prd.Product_Type__c == 'Hardware'){
                    let aspenProduct = (prd.RWD_Version__c == 'Aspen_HW' && prd.RWD_Hardware_Family__c != 'F10000' && prd.Product_Type__c!='Add-On Node');
                                if ((type =='Aspen' && aspenProduct) || (type!='Aspen' && !aspenProduct)){
                                    targetItem.push({
                                            label: `${prd.ProductCode} (${prd.Usable_Capacity__c} TB)`,
                                            value: prd.Id,
                                            selected: false,
                                            quantity: prd.Usable_Capacity__c,
                                            Product_NIC_Type__c : prd.Product_NIC_Type__c,
                                            entCustomIndex: this.sourceent?.customIndex || '',
                                            entitlementId: this.sourceent?.entitlementId || ''
                                        });
                                }
                }
                
            });
           this.targetPathSKU = targetItem; 
    }
    
    let nonAssetPath;
            if(this.sourceent.skuProductId != undefined && this.rowsel.productId != undefined && this.sourceent.skuProductId === this.rowsel.productId){
                    if(this.rowsel.pathAssetSelected != undefined && this.rowsel.pathAssetSelected.length > 0){
                        this.selectedPath = this.rowsel.pathAssetSelected.map(item => item);
                        this.selectedPath.forEach(curr =>{
                                this.selectedOptions.push(curr.value);
                        });                        
                    }
                    if(this.sourceent.targetProductType != undefined && this.sourcePath != undefined && this.sourceent.targetProductType === 'Non-Hardware' && this.sourcePath === 'Hardware'){
                                this.selectedPath.forEach(currItem =>{
                                    if(currItem.value === 'Non Asset'){
                                        currItem.selected = true;
                                    }
                                });
                                this.selectedOptions.push('Non Asset');
                    }
                    if(this.sourceent.targetProductType != undefined){
                        nonAssetPath = this.sourceent.targetProductType;
                    }
            }
            
            let rowSelValue = JSON.parse(JSON.stringify(this.rowsel));
            
            if((nonAssetPath == undefined || nonAssetPath == null) && this.sourcePath != undefined){
                nonAssetPath = this.sourcePath;
            }
            const myEvent = new CustomEvent('skupathevent', {
                    detail: { rowselpath : rowSelValue , sourcepath : this.sourcePath, pathFromChild : nonAssetPath}                    
                });
            this.dispatchEvent(myEvent);
            console.log('targetPathSKU options ', JSON.stringify(this.targetPathSKU));
            console.log('selectedOptions are  33333', JSON.stringify(this.selectedOptions));
    }catch (error) {
        this.handleCatch(false, error);
    } 
} 

handleSelectPath(event){
    try{
        let nonAssetPath;
        this.assignValuesToSelected(event.detail);    
        let quantityUsed = this.calculateQuantity(this.selectedPath);
        let rowsVal = JSON.parse(JSON.stringify(this.rowsel));
        if(quantityUsed > this.sourcequantitysum){
                this.showmsg = true;
                this.customerrors.forEach(currentItem => {
                if(currentItem.Message_Label__c === 'Asset_Selection_According_to_src_quantit'){
                        this.message = currentItem.Error_Message__c;
                    }
                });
                rowsVal.errors = 'Error Occured';
        }else{
                this.showmsg = false;
                this.message = '';
                rowsVal.errors = '';
        }
        rowsVal.pathAssetSelected = this.selectedPath.map(item => item);
        if(this.selectedOptions.length > 0){
            nonAssetPath = 'Hardware';
        }else{
            nonAssetPath = this.sourcePath;
        }
        const myEvent = new CustomEvent('skupathevent', {
                        detail: { rowselpath : rowsVal , sourcepath : this.sourcePath, pathFromChild : nonAssetPath}                    
                    });
        this.dispatchEvent(myEvent);
    }catch (error) {
        this.handleCatch(false, error);
    } 
}

handleselectoptionparent(event){
    try{ 
        let nonAssetPath; 
        if(event.detail.action === 'add'){
                this.targetPathSKU.forEach(targetItem =>{
                        if(event.detail.value === targetItem.value){
                            let currItem = targetItem;
                            currItem.selected = true;
                            this.selectedPath.push(currItem);                            
                        }
                });
                nonAssetPath = 'Non-Hardware';
                this.selectedOptions.push(event.detail.value);
        }else if(event.detail.action === 'remove'){
                this.selectedPath = [];
                this.selectedOptions = [];
                nonAssetPath = this.sourcePath;
        }    
        let rowsVal = JSON.parse(JSON.stringify(this.rowsel));
        console.log('sele optioons12222 ', JSON.stringify(this.selectedOptions));
        const myEvent = new CustomEvent('skupathevent', {
                        detail: { rowselpath : rowsVal , sourcepath : this.sourcePath, pathFromChild : nonAssetPath}                    
                    });
        this.dispatchEvent(myEvent); 
    }catch (error) {
        this.handleCatch(false, error);
    }    
}

calculateQuantity(selectedPath){
    let quantSum = 0;
    selectedPath.forEach(targetItem =>{
                if(targetItem.selected == true && targetItem.quantity != undefined){
                    quantSum = parseInt(quantSum) + parseInt(targetItem.quantity);
                }
            });
    return quantSum;
}

assignValuesToSelected(selectedValues){
    try{
        if(selectedValues.action === 'add'){
                this.targetPathSKU.forEach(targetItem =>{
                        if(selectedValues.value === targetItem.value){
                            let currItem = targetItem;
                            currItem.selected = true;
                            this.selectedPath.push(currItem);                            
                        }
                });
                this.selectedOptions = selectedValues.values.map(item => item);            
        }else if(selectedValues.action === 'remove'){
            this.selectedPath = [];
            if(selectedValues.values.length > 0){
                selectedValues.values.forEach(item =>{
                this.targetPathSKU.forEach(targetItem =>{
                        if(item === targetItem.value){
                            let currItem = targetItem;
                            currItem.selected = true;
                            this.selectedPath.push(currItem);
                        }
                });
                });
            } 
            this.selectedOptions = selectedValues.values.map(item => item);           
        }  
    }catch (error) {
        this.handleCatch(false, error);
    }  
}


handleNetworkTypeChange(event){
    if(event.detail.action === 'add'){
                this.networkTypeOptions.forEach(targetItem =>{
                    targetItem.selected = false;
                        if(event.detail.value === targetItem.value){
                            targetItem.selected = true;
                            this.networkSelValue = targetItem.value;
                            this.networkTypeFilter = [{'key' : 'Product_NIC_Type__c', 'value' : event.detail.value}];
                        }
                });
        }else if(event.detail.action === 'remove'){
                this.networkTypeOptions.forEach(targetItem =>{
                    targetItem.selected = false;
                        if(event.detail.value === targetItem.value){
                            this.networkSelValue = null;
                            this.networkTypeFilter = null;
                        }
                });
        }
}


handleCatch(spinnerValue, error) {
    console.error(error);
    this.showSpinner = spinnerValue;
    this.message = error;
    this.showmsg = true;
    this.showErrorToast(error);
  }

showErrorToast(messgae) {
    const evt = new ShowToastEvent({
        title: 'Error',
        message: String(messgae),
        variant: 'error',
        mode: 'dismissable'
    });
    this.dispatchEvent(evt);
}

}