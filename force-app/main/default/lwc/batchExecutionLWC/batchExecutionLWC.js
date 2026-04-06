import { LightningElement,track,wire } from 'lwc';
import getConfigurationData from '@salesforce/apex/BatchExecutionController.getConfigurationData'
import executeBatchApex from '@salesforce/apex/BatchExecutionController.executeBatchApex'
import isBatchScheduled from '@salesforce/apex/BatchExecutionController.isBatchScheduled'
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class BatchExecutionLWC extends LightningElement {
    @track batchConfigurationMetadata = [];
    @track selectedObj = {};
    @track result;
    @track showSpinner = false;
    @track bShowModal = false;
    @track modalMessage = '';
    @wire(getConfigurationData)
    wiredCustomMetadata({data,error}){
        if(data){
            this.batchConfigurationMetadata = data;
            console.log('::::>'+JSON.stringify(data));
            console.log('metadata :::>'+JSON.stringify(this.batchConfigurationMetadata));
        }else{
            console.log('Error Occured'+JSON.stringify(error));
        }
    }

    handleClick(event){
        console.log(event.target.dataset.id);
         this.selectedObj = this.batchConfigurationMetadata.find(item => item.Id === event.target.dataset.id);
         console.log('Selected Object');
         console.log(JSON.stringify(this.selectedObj,null,4));
         this.isBatchScheduled();
         //this.findObjectById(event.target.dataset.id);
        
        
    }

    /*findObjectById(objId) {
        return this.batchConfigurationMetadata.find(item => item.Id === objId);
    }*/

    handleBatchExecution() {
        this.showSpinner = true;
        console.log('Inside Batch Execution');
        executeBatchApex({strJson: JSON.stringify(this.selectedObj) })
            .then(result => {
                if(this.bShowModal){
                    this.bShowModal = false;
                }
                this.result = result;
                console.log('result :::>?'+this.result);
                //this.showToast('Success', result, 'success');
                
        const event = new ShowToastEvent({
            title: 'Success !!',
            variant: 'success',
            message: `Batch execution completed ! please check apex jobs for more info`,

        });
        this.dispatchEvent(event);
    
            })
            .catch(error => {
                console.error(error);
               const event = new ShowToastEvent({
            title: 'Error !!',
            variant: 'error',
            message: `Something went wrong please contact system administrator`,

        });
        this.dispatchEvent(event);
            }).finally(()=>{
                this.showSpinner = false;
            });
    }

    isBatchScheduled(){
         this.showSpinner = true;
         let batchClassName = this.selectedObj?.BatchClassName__c;
        isBatchScheduled({batchClassName: batchClassName})
            .then(result => {
                  let oResponse= JSON.parse(result);
                if(oResponse?.bScheduled == 1){
                    this.modalMessage = oResponse?.message;
                    this.handleShowConfirmationModal();
                }
                else{
                   this.handleBatchExecution();
                }
                
       
            })
            .catch(error => {
                console.error(error);
               const event = new ShowToastEvent({
            title: 'Error !!',
            variant: 'error',
            message: `Something went wrong please contact system administrator`,
           

        });
         this.dispatchEvent(event);
            }).finally(()=>{
                this.showSpinner = false;
            });
    }

    handleShowConfirmationModal(){
        this.bShowModal = !this.bShowModal;
    }
    handleConfirmClick(){
        console.log('handle Confirm Clicked');
        this.handleBatchExecution();
    }
    
}