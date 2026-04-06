import { LightningElement, wire, api } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

const FIELDS = [
    'Case.CaseTransferStatus__c',
    'Case.CaseNumber',
    'Case.CustomerCommunicationFrequency__c',
    'Case.CaseTransferType__c'
];

export default class CsCaseTransferRequest extends LightningElement {
    @api recordId;
    decision = 'TransferForm';
    transferStatus = '';
    showSubmittedScreens = false;
    showTransferScreens = false;
    caseNumber;
    customerCommunicationFrequencyValue;
    error;

    //to fetch case details
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    case({ error, data }) {
        if (data) {
            this.transferStatus = data.fields.CaseTransferStatus__c.value;
            this.caseNumber = data.fields.CaseNumber.value;
            this.showSubmittedScreens = this.transferStatus == 'Submitted' ? true : false;
            this.showTransferScreens = this.transferStatus == 'Submitted' ? false : true;
            this.customerCommunicationFrequencyValue = data.fields.CustomerCommunicationFrequency__c.value;
            this.decision = data.fields.CaseTransferType__c.value;
            this.error = undefined;
        } else if (error) {
            this.error = error;
        }
    }

}