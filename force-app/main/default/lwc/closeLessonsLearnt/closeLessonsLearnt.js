import { LightningElement, api, wire } from 'lwc';
// stanatard methods
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
// toast message
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// close Screen Quick Action
import { CloseActionScreenEvent } from 'lightning/actions';

export default class CloseLessonsLearnt extends LightningElement {
    @api recordId
    isShowModal = false;
    confirmClose = false;

    @wire(getRecord, { recordId: '$recordId', fields: ['Lessons_Learned__c.Lessons_Learnt_Status__c'] })
    fetchCurrentStatus({error, data}) {
        if (data
            && !this.confirmClose) {
                let currentStatus = data.fields.Lessons_Learnt_Status__c.value;
                if(currentStatus != 'Closed'){
                    this.isShowModal = true;
                }else{
                    this.updateStatusClose('Re-Open', '');
                }
        } else if (error) {
            console.log('fetchCurrentStatus ERROR: ',error);
        }
    }

    hideConfirm(){
        this.confirmClose = true;
        var today = new Date();
        this.updateStatusClose('Closed', today.toISOString());
    }

    updateStatusClose(statusVal, currentDate){
        const fields = {};
        fields['Id'] = this.recordId;
        fields['Lessons_Learnt_Status__c'] = statusVal;
        fields['Closed_Date__c'] = currentDate;

        const recordInput = { fields };
        updateRecord(recordInput)
        .then(() => {
            this.closeAction('Success', 'Lessons Learned \"'+statusVal+'\" successfully!', 'success');
        })
        .catch(error => {
            this.closeAction('Error creating record', error.body.message, 'error');
        });
    }

    closeAction(title, msg, vari){
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: msg,
                variant: vari
            })
        );
        this.dispatchEvent(new CloseActionScreenEvent());
    }

}