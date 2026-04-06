import { LightningElement, api, wire } from 'lwc';
// stanatard methods
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
// toast message
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// close Screen Quick Action
import { CloseActionScreenEvent } from 'lightning/actions';

export default class CloseEscalationQuickAction extends LightningElement {
    @api recordId
    isShowModal = false;
    confirmClose = false;

    @wire(getRecord, { recordId: '$recordId', fields: ['Escalation__c.Status__c'] })
    fetchCurrentStatus({error, data}) {
        if (data 
            && !this.confirmClose) {
                let currentStatus = data.fields.Status__c.value;
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
        fields['Status__c'] = statusVal;
        fields['Closed_Date__c'] = currentDate;

        console.log('fields: ',JSON.stringify(fields));

        const recordInput = { fields };
        updateRecord(recordInput)
        .then(() => {
            this.closeAction('Success', 'Escalation \"'+statusVal+'\" successfully!', 'success');
        })
        .catch(error => {
            console.log('ESc updateStatusClose: ', error);
            let errorObj = error.body.output.errors[0];
            this.closeAction('Error while updating record', errorObj.message, 'error');
        });
    }

    hideModalBox() {  
        this.isShowModal = false;
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