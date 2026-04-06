import { LightningElement, api, wire } from 'lwc';
// stanatard methods
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
// current userid
import Id from '@salesforce/user/Id';
// toast message
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// close Screen Quick Action
import { CloseActionScreenEvent } from 'lightning/actions';

export default class AssignToMeLessonsLearnt extends LightningElement {
    @api recordId

    @wire(getRecord, { recordId: '$recordId', fields: ['Lessons_Learned__c.Name'] })
    fetchCurrentStatus({error, data}) {
        if (data) {
            this.updateAssignToMe();
            this.closeAction();
        } else if (error) {
            console.log('fetchCurrentStatus ERROR: ',error);
        }
    }

    updateAssignToMe(){
        const fields = {};
        fields['Id'] = this.recordId;
        fields['Owner__c'] = Id;

        const recordInput = { fields };
        updateRecord(recordInput)
        .then(() => {
            this.closeAction('Success', 'Owner updated successfully!', 'success');
        })
        .catch(error => {
            this.closeAction('Error', error.body.message, 'error');
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