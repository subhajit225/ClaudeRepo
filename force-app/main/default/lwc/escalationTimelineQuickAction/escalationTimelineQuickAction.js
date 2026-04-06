import { LightningElement, wire, api } from 'lwc';
// Close Quick Action Modal
import { CloseActionScreenEvent } from 'lightning/actions';
// standard methods
import { getRecord, createRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';

export default class EscalationTimelineQuickAction extends NavigationMixin(LightningElement) {
    @api recordId

    @wire(getRecord, { recordId: '$recordId', fields: ['Escalation__c.Case__c'] })
    fetchEscalation({error, data}) {
        if (data) {
            this.closeAction();
            this.handleNavigate(data.fields.Case__c.value);
        } else if (error) {
            console.log('fetchEscalation ERROR: ',error);
        }
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleNavigate(caseId) {
        const sfdcBaseURL = window.location.origin;
        const finalURL = sfdcBaseURL+'/lightning/n/E2CAdv__Comments_List?c__id='+caseId;
        window.open(finalURL, '_blank');
    }
}