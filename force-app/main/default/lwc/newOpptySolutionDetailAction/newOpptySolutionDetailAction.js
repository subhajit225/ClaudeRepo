import { LightningElement, track,wire } from 'lwc';
import { NavigationMixin,CurrentPageReference} from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { getRecord } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const FIELDS = ['Opportunity.Opportunity_Sub_Type__c', 'Opportunity.IsClosed'];

export default class NewOpptySolutionDetailAction extends NavigationMixin(LightningElement) {
    @track wireRecordId;
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.wireRecordId = currentPageReference.state.recordId;
        }
    }

    @wire(getRecord, { recordId: '$wireRecordId', fields: FIELDS })
    wiredOpportunity({ error, data }) {
        if (data) {
            const subType = data.fields.Opportunity_Sub_Type__c?.value || '';
            if ((!subType.includes('MSP') && subType != 'GC Offer') || data.fields.IsClosed.value) {
                this.showError('Opportunity Solution Details cannot be created when the Opportunity Sub Type is not MSP / GC Offer or the Opportunity is closed.');
                return;
            }
            this.navigateToNewRecord();
        } else if (error) {
            this.showError('Unable to fetch Opportunity details.');
        }
    }

    navigateToNewRecord() {
        const defaultValues = encodeDefaultFieldValues({
            Opportunity__c: this.wireRecordId
        });
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Opportunity_Solution_Detail__c',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: defaultValues
            }
        }, true);
    }

    showError(message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Cannot Create Record',
                message: message,
                variant: 'error'
            })
        );
        this.dispatchEvent(new CloseActionScreenEvent());
    }

}