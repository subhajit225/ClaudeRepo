import { LightningElement, wire, api } from 'lwc';
// Close Quick Action Modal
import { CloseActionScreenEvent } from 'lightning/actions';
// standard methods
import { getRecord, createRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';

export default class LessonsLearnedTimelineQuickAction extends NavigationMixin(LightningElement) {
    @api recordId

    @wire(getRecord, { recordId: '$recordId', fields: ['Lessons_Learned__c.Case__c'] })
    fetchLessonsLearned({error, data}) {
        if (data) {
            this.closeAction();
            this.handleNavigate(data.fields.Case__c.value);
        } else if (error) {
            console.log('fetchLessonsLearned ERROR: ',error);
        }
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleNavigate(caseId) {
        const sfdcBaseURL = window.location.origin;
        const finalURL = sfdcBaseURL+'/lightning/n/E2CAdv__Comments_List?c__id='+caseId;
        // timiline in new window
        window.open(finalURL, '_blank');
    }
}