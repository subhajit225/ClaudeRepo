import { LightningElement, api, wire } from 'lwc';
// standard methods
import { getRecord } from 'lightning/uiRecordApi';
// close Screen Quick Action
import { CloseActionScreenEvent } from 'lightning/actions';
// toast message
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// apex methods
import createCaseTeamMember from '@salesforce/apex/EscalationManagementTeamController.createCaseTeamMember';

export default class CopyMeOnCaseUpdates extends LightningElement {
    @api recordId

    @wire(getRecord, { recordId: '$recordId', fields: ['Escalation__c.Case__c'] })
    fetchCurrentStatus({error, data}) {
        console.log('fetchCurrentStatus: ', JSON.stringify(data));
        if (data) {
            this.copyCurrentUserForCaseUpdates(data.fields.Case__c.value);
            this.closeAction();
        } else if (error) {
            console.log('fetchCurrentStatus ERROR: ',error);
        }
    }

    copyCurrentUserForCaseUpdates(caseId){
        createCaseTeamMember({ caseId: caseId})
        .then((result) => {
            setTimeout(()=>this.showToastMsg('Success', 'Successfully copied you!', 'success'), 1000)
        })
        .catch((error) => {
            setTimeout(()=>this.showToastMsg('Error', error, 'error'), 1000)
        });  
    }

    showToastMsg(title, msg, type){
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: msg,
                variant: type
            })
        );
    }

    closeAction(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}