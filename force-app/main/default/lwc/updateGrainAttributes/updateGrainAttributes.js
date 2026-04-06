import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveAccount from '@salesforce/apex/UpdategrainAttributesControllerLWC.saveAccountLWC';
import getAccessDetails from '@salesforce/apex/UpdategrainAttributesControllerLWC.getAccessDetails';
import { NavigationMixin } from 'lightning/navigation';

export default class UpdateGrainAttributes extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName = 'Account';
    @track showLoader = true;
    @track accessDetails = {
        'accRecord' : {
            'isFederalIntel__c' : false
        }
    };
    @track disableButtons = false;

    get showBackButton(){
        return this.accessDetails.accRecord.isFederalIntel__c || !this.accessDetails.hasRecAccess? true : false;
    }
     get showTable(){

        return (!this.accessDetails.isFederal && this.accessDetails.hasRecAccess && !this.accessDetails.disableCM )? true : false;
    }
    connectedCallback(){
        //this.showTable = true;
        this.showLoader = true;
        this.disableButtons = true;
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            console.log(' recordId..!', this.recordId);
            getAccessDetails({
                'recId' : this.recordId
            }).then(result => {  
                this.showLoader = false; 
                this.disableButtons = false;
                console.log(' accessDetails..!');         
                console.log(result);
                this.accessDetails = result[0];
                
               // console.log(this.accessDetails);
               if(result[0].errMsg != null || result[0].errMsg != ''){
                   this.showToast('', result[0].errMsg, result[0].variant, 'pester');
                   if(result[0].variant == 'warning')
                        this.disableButtons = true;
               }
            }).catch(error => {
                this.showLoader = false; 
                this.disableButtons = false;
                console.log('error..!', error);
                this.showToast('', error.body.message, 'error', 'pester');
            });

        }, 200);
    } 

    handleCancel(event){
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    handleSave(event){ 
        var isValid = true;
        var isValidtemp = true;
        const inputFields = this.template.querySelectorAll(
            'lightning-input-field'
        );
        var record = {};
        record = this.accessDetails.accRecord;
        console.log('record');
        console.log(record);
        if (inputFields) {
            inputFields.forEach(field => {
                isValidtemp = field.reportValidity();
                if(!isValidtemp)
                    isValid = false;
                console.log('Field is==> ' + field.fieldName);
                console.log('Field is==> ' + field.value);
                record[field.fieldName] = field.value;  
            });
        }

        record.Id = this.recordId;
        console.log('record..!',record);
        
        if(isValid){
            this.disableButtons = true;
            saveAccount({
                'accrecord' : record
            }).then(result => { 
                this.disableButtons = false;           
                console.log('result..!', result);
                this.dispatchEvent(new CloseActionScreenEvent());    
                this.showToast('Success', 'Record updated!', 'success', '');
                console.log('redirection...');
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        'recordId': this.recordId,
                        'objectApiName': 'Account',
                        'actionName': 'view'
                    }
                });
                
                window.open('/'+this.recordId,"_self");
                //getRecordNotifyChange(record);
                //updateRecord({fields: this.recordId})
            }).catch(error => {
                this.disableButtons = false;
                console.log('error..!', error);
                this.showToast('', error.body.message, 'error', 'pester');
            });
        }
    }

    showToast(title, message, variant, mode) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(event);
    }
}