import { LightningElement, wire, api } from 'lwc';
import getRequests from '@salesforce/apex/CaseTransferApprovalRequest.getAssistRequests';

const TABLECOLUMNS = [
    { label: 'Assist Request', fieldName: 'Name', hideDefaultActions:'true' },
    { label: 'Type', fieldName: 'Type__c', hideDefaultActions:'true' },
    { label: 'Priority', fieldName: 'Priority__c', hideDefaultActions:'true' },
    { label: 'Status', fieldName: 'Status__c', hideDefaultActions:'true' },
    { label: 'Owner', fieldName: 'OwnerName', hideDefaultActions:'true' }
];

export default class CsCaseTransferARList extends LightningElement {
    @api recordId;
    columns = TABLECOLUMNS;
    assistRequests;
    error;

    get showAssistRequest() {
        if (this.assistRequests && this.assistRequests.length > 0) {
            return true;
        }

        return false;
    }

    @wire(getRequests, { caseId: '$recordId' })
    wiredAssistRequests({ error, data }) {
        if (data) {
            this.assistRequests = data.map(
                record => Object.assign(
                    { "OwnerName": record.Owner.Name },
                    record
                )
            );
        } else if (error) {
            this.error = error;
            this.assistRequests = undefined;
        }
    }
}