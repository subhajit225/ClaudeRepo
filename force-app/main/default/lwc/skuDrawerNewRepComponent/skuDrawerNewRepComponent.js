/**************This full component is build as a part of FY25SR-1084 Story****************/
import { LightningElement, api,track } from 'lwc';
import getSchemaFields from '@salesforce/apex/SKUNewReplacementController.getSchemaFieldsForQuoteLine';
import { assignDataToColumns, checkValidations, assignQuantityParent, initialLoadValidation, loadPreviousTransaction } from './skuDrawerNewRepUtility.js'; 
export default class SkuDrawerNewRepComponent extends LightningElement {
@api rowsel;
@api sourceent;
@api sourcequantitysum;
@api customerrors = new Map();
@api sourcecustomindex;
@track datamodified = [];
@track rawData = [];
@track columnsPerRow = 3;
@track showSpinner;
@track message;
@track targetPathSKU = [];
@track selcectedPath = [];
@track showmsg;
@track rowSelParentMap = new Map();
@api ismismatchqty; /*CPQ22-6157*/
fixedWidth = "width:15rem;";

async connectedCallback() {
        try{
            this.showSpinner = true;
            debugger;
            console.log(' source quantity sum is ', this.sourcequantitysum, ' source ent is ', JSON.stringify(this.sourceent));
            console.log('errors inside newrp SKu ', JSON.stringify(this.customerrors));
            if(this.rowsel.parentMetadataMapping != undefined){
                                    for(var key in this.rowsel.parentMetadataMapping){
                                         this.rowSelParentMap.set(key, this.rowsel.parentMetadataMapping[key]);
                                    } 
            }         
            let rows = this.rowsel;            
             let schemaDetails = await getSchemaFields({skuWrap : rows});
             this.rawData = schemaDetails;
             for (let i = 0; i < schemaDetails.length; i += this.columnsPerRow) {
                    this.datamodified.push({
                    id: `row-${i}`,
                    columns: schemaDetails.slice(i, i + this.columnsPerRow)                    
                });
             }
            this.showSpinner = false;
            this.datamodified = initialLoadValidation(this.datamodified,this.sourceent, this.rowsel,this.rowSelParentMap, this.sourcecustomindex, this.sourcequantitysum, this.customerrors);
            this.datamodified = this.handleQuantityCheck(this.datamodified, this.sourcequantitysum);
            const myEvent = new CustomEvent('skuattributesevent', {
                    detail: { dataFromInnerChild: this.datamodified }                    
                });
                this.dispatchEvent(myEvent);
        }catch (error){
            this.handleCatch(false, error);
        }        
    }

handlePickListChange(event){
    try{
        debugger;
        this.datamodified = assignDataToColumns(event,this.datamodified, true);
        this.datamodified = checkValidations(this.datamodified, this.rowsel, this.sourceent, this.rowSelParentMap,this.customerrors);
        console.log('pick change disp data is ',JSON.stringify(this.datamodified));
        const myEvent = new CustomEvent('skuattributesevent', {
            detail: { dataFromInnerChild: this.datamodified }
        });
        this.dispatchEvent(myEvent);
    }catch (error) {
        this.handleCatch(false, error);
    }
}

handleDecimalClick(event){
    try{

    }catch(error){
        this.handleCatch(false, error);
    } 
}

handleDoubleClick(event) {
        event.preventDefault();
        event.stopPropagation();
    }

handleDecimalChange(event){
    debugger;
    try{
        this.datamodified = assignDataToColumns(event,this.datamodified, false);
        this.datamodified = this.handleQuantityCheck(this.datamodified, this.sourcequantitysum);
        console.log('Decimal change disp data is ',JSON.stringify(this.datamodified));
        const myEvent = new CustomEvent('skuattributesevent', {
            detail: { dataFromInnerChild: this.datamodified }
        });
        this.dispatchEvent(myEvent);
    }catch(error){
        this.handleCatch(false, error);
    }
}

handleCurrencyChange(event){
    try{
        this.datamodified = assignDataToColumns(event,this.datamodified, false);
        console.log('Currency change disp data is ',JSON.stringify(this.datamodified));
        const myEvent = new CustomEvent('skuattributesevent', {
            detail: { dataFromInnerChild: this.datamodified }
        });
        this.dispatchEvent(myEvent);
    }catch(error){
        this.handleCatch(false, error);
    }
}

handleTextChange(event){
    try{
        this.datamodified = assignDataToColumns(event,this.datamodified, false);
        console.log('Text change disp data is ',JSON.stringify(this.datamodified));
        const myEvent = new CustomEvent('skuattributesevent', {
            detail: { dataFromInnerChild: this.datamodified }
        });
        this.dispatchEvent(myEvent);
    }catch(error){
        this.handleCatch(false, error);
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

handleQuantityCheck(datamodified, sourcequantitysum){
    let displayedData = JSON.parse(JSON.stringify(datamodified));
    let quantitySumTarget = 0;
    let quantitySumSource = 0;
    
        displayedData.forEach(currentItemWrapper => {
                currentItemWrapper.columns.forEach(currItem =>{
                    if(currItem.fieldApiName === 'Salesforce_Quantity__c'){
                        quantitySumTarget  = (currItem.fieldValue != undefined && currItem.fieldValue != null && currItem.fieldValue.length >0) ? parseInt(quantitySumTarget)+parseInt(currItem.fieldValue) : quantitySumTarget;                       
                        quantitySumSource = assignQuantityParent(currItem, this.rowsel,quantitySumSource, this.rowSelParentMap);                        
                    }
                    if(currItem.fieldApiName === 'Atlassian_Quantity__c'){
                        quantitySumTarget  = (currItem.fieldValue != undefined && currItem.fieldValue != null && currItem.fieldValue.length >0) ? parseInt(quantitySumTarget)+parseInt(currItem.fieldValue) : quantitySumTarget;
                        quantitySumSource = assignQuantityParent(currItem, this.rowsel,quantitySumSource, this.rowSelParentMap);                        
                    }   
                    if(currItem.fieldApiName === 'Dynamics_Quantity__c'){
                        quantitySumTarget  = (currItem.fieldValue != undefined && currItem.fieldValue != null && currItem.fieldValue.length >0) ? parseInt(quantitySumTarget)+parseInt(currItem.fieldValue) : quantitySumTarget;                       
                        quantitySumSource = assignQuantityParent(currItem, this.rowsel,quantitySumSource,this.rowSelParentMap);
                    }
                    if(currItem.fieldApiName === 'Rubrik_Hosted_M365_Quantity__c'){
                        quantitySumTarget  = (currItem.fieldValue != undefined && currItem.fieldValue != null && currItem.fieldValue.length >0) ? parseInt(quantitySumTarget)+parseInt(currItem.fieldValue) : quantitySumTarget;
                        quantitySumSource = assignQuantityParent(currItem, this.rowsel,quantitySumSource, this.rowSelParentMap);                        
                    }
                    if(currItem.fieldApiName === 'Google_Workspace_Quantity__c'){
                        quantitySumTarget  = (currItem.fieldValue != undefined && currItem.fieldValue != null && currItem.fieldValue.length >0) ? parseInt(quantitySumTarget)+parseInt(currItem.fieldValue) : quantitySumTarget;
                        quantitySumSource = assignQuantityParent(currItem, this.rowsel,quantitySumSource, this.rowSelParentMap);                        
                    }
                });
        });

        console.log('quantitySumTarget is ',quantitySumTarget, ' quantitySumSource is ',quantitySumSource, 'sourcequantitysum is  ',sourcequantitysum);
        displayedData.forEach(currentItemWrapper => {                
                currentItemWrapper.columns.forEach(currItem =>{                    
                    if(currItem.fieldApiName === 'Salesforce_Quantity__c'){
                            currItem = this.quantityErrorCheck(currItem, quantitySumTarget,sourcequantitysum);                                                                     
                    }
                    if(currItem.fieldApiName === 'Atlassian_Quantity__c'){
                            currItem = this.quantityErrorCheck(currItem, quantitySumTarget,sourcequantitysum);                                              
                    }
                    if(currItem.fieldApiName === 'Dynamics_Quantity__c'){
                            currItem = this.quantityErrorCheck(currItem, quantitySumTarget,sourcequantitysum);                         
                    }
                    if(currItem.fieldApiName === 'Rubrik_Hosted_M365_Quantity__c'){
                            currItem = this.quantityErrorCheck(currItem, quantitySumTarget,sourcequantitysum);                                               
                    }
                    if(currItem.fieldApiName === 'Google_Workspace_Quantity__c'){
                            currItem = this.quantityErrorCheck(currItem, quantitySumTarget,sourcequantitysum);                                               
                    }
                });
            });
        return displayedData;
    }

quantityErrorCheck(currItem, quantitySumTarget,sourcequantitysum){
        if(parseInt(quantitySumTarget) == 0){
            this.customerrors.forEach(currentItem => {
            if(currentItem.Message_Label__c === 'Replacement_Sum_Cannot_Be_Zero'){
                    this.message = currentItem.Error_Message__c;
                }
            });
            this.showmsg = true;
            currItem.errorOccured = true;
        }else if((parseInt(quantitySumTarget) > parseInt(sourcequantitysum)) && this.ismismatchqty == false){
            let errorMessageOne;
            let errorMessageTwo;
            this.customerrors.forEach(currentItem => {
            if(currentItem.Message_Label__c === 'Replacement_Quantity_Error_One'){
                    errorMessageOne = currentItem.Error_Message__c;
                }
            if(currentItem.Message_Label__c === 'Replacement_Quantity_Error_Two'){
                    errorMessageTwo = currentItem.Error_Message__c;
                }
            });
            this.message = errorMessageOne +'('+sourcequantitysum+')'+errorMessageTwo;
            this.showmsg = true;
            currItem.errorOccured = true;
        }else{
            this.showmsg = false;
            this.message = ''
            currItem.errorOccured = false;
            currItem.errorMessage = ''
        }
    return currItem;
}

}