import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOppDetails from '@salesforce/apex/RequestSEMisalignmentControllerLWC.getOppDetails';
import save from '@salesforce/apex/RequestSEMisalignmentControllerLWC.save';
import { NavigationMixin } from 'lightning/navigation';

export default class UpdateGrainAttributes extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName = 'Opportunity';
    @track showLoader = true;
    @track showTable = false;
    @track oppRecord = {};

    connectedCallback(){
        
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            console.log(' recordId..!', this.recordId);
            getOppDetails({
                'recId' : this.recordId
            }).then(result => { 
                this.showLoader = false; 
                this.showTable = true; 
                console.log(' getOppDetails..!');         
                console.log(result);
                this.oppRecord = result;
            }).catch(error => {
                this.showLoader = false; 
                this.showTable = true; 
                console.log('error..!', error);
                this.showToast('', error.body.message, 'error', 'pester');
            });
        }, 100);
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
        record = this.oppRecord;
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
            this.showLoader = true;
            save({
                'oppRecord' : record
            }).then(result => {
                this.showLoader = false;         
                console.log('result..!', result);
                if(result.search('Success') >=0){
                    this.dispatchEvent(new CloseActionScreenEvent());    
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            'recordId': this.recordId,
                            'objectApiName': 'Opportunity',
                            'actionName': 'view'
                        }
                    });
                }else{
                    this.showToast('', result, 'error', 'pester');
                }
            }).catch(error => {
                this.showLoader = false;     
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