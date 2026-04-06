import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import startedLabel from '@salesforce/label/c.ETM_BatchJob_Started_Message';
import runningLabel from '@salesforce/label/c.ETM_BatchJob_Already_Running_Message';
import notEligibleLabel from '@salesforce/label/c.ETM_Batch_Job_Not_Eligible_Message';

import runETMBatch from '@salesforce/apex/ETMBatchJobsLWCController.runETMBatch';

export default class ETMBatchJobsRunLWC extends NavigationMixin(LightningElement) {
 label = {
        startedLabel,
        runningLabel,
        notEligibleLabel
    };   

@api recordId;    
@track started = false;
@track running = false;
@track notEligible = false;
@track showLoader = false;

    connectedCallback(){
        this.showLoader = true;
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            console.log(' recordId..!', this.recordId);
            runETMBatch({
                'recId' : this.recordId
            }).then(result => {
                this.showLoader = false;  
                console.log(' runETMBatch..!');         
                console.log(result);
               if(result == 'Started'){
                   this.started = true;
               }
               if(result == 'Already Running'){
                   this.running = true;
               }
               if(result == 'Not Eligible'){
                   this.notEligible = true;
               }
            }).catch(error => {
                this.showLoader = false;  
                console.log('error..!', error);
                this.showToast('', error.body.message, 'error', 'pester');
            });

        }, 100);
    }

    handleCancel(event){
        this.dispatchEvent(new CloseActionScreenEvent());
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