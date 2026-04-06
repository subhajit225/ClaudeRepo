import { LightningElement, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import { RefreshEvent } from 'lightning/refresh';
import getAccessibleFields from '@salesforce/apex/LCC_JSMQueryResultService.getAccessibleFields';
import saveRecord from '@salesforce/apex/LCC_JSMQueryResultService.saveRecordwithBypass';

export default class GenericRecordEditForm extends LightningElement {
    @api recordId;
    parentRecordId;
    recordData ={};
    objData = {};
    isLoading = true;

    connectedCallback() {
        console.log('recordId >>' + this.recordId);
        if (this.recordId) {
            this.parentRecordId = this.recordId;
            
            this.fetchAccessibleFields();
        }else{
            this.isLoading = false;
        }
    }

    @wire(CurrentPageReference)
    getPageRef({ state }) {
        console.log(JSON.stringify(state));
        if (state && state.recordId && this.parentRecordId === undefined) {
            this.parentRecordId = state.recordId;
        }
        if(this.parentRecordId){
            console.log('recordId >>'+this.parentRecordId);
            this.fetchAccessibleFields();
        }
    }

    async fetchAccessibleFields(){
        try{
            const results = await getAccessibleFields({ parentRecId: this.parentRecordId });
            console.log('results::', results);
            this.objData = JSON.parse(results);
            this.isLoading = false;
        }
        catch(error){
            this.isLoading = false;
            this.handleError(error, 'Error Loading Record Details');
        }
    }
    
    handleError(error, defaultMessage) {
        let errorMessage = defaultMessage || 'An unknown error occurred.';
        if (error?.body?.message) {
            errorMessage = error.body.message;
        } else if (error?.message) {
            errorMessage = error.message;
        }
        this.showToastMessage('Error!', errorMessage, 'error');
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSubmit(event){
        console.log('handleSubmit::');
        event.preventDefault();
        console.log(JSON.stringify(event.detail.fields));
        this.recordData = event.detail.fields;
        console.log(this.recordData);
        this.handleCustomSave();
    }

    handleCustomSave(){
        try{
            this.isLoading = true;
            this.recordData.Id = this.parentRecordId;
            console.log('record data:::', JSON.stringify(this.recordData));
            saveRecord({rec : this.recordData,objectAPIName : this.objData.objAPIName})
            .then(result => {
                this.isLoading = false;
                console.log('Result >> ',result)
                if(!result || result.trim() === ''){
                    this.showToastMessage('Success', 'Record saved successfully!', 'success');
                    this.handleCancel();
                    this.dispatchEvent(new RefreshEvent());
                }else{
                    this.handleError(null, result);
                }
            })
            .catch(error =>{
                this.recordData = {};
                this.isLoading = false;
                this.handleError(error, 'Error updating record');
            });

        }
        catch(error){
            console.log('error save::', error);
            this.isLoading = false;

        }
        
    }
    
    showToastMessage(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }

}