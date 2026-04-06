import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAccessibleOpportunityFields from '@salesforce/apex/LGTRenewalOpportunityController.getAccessibleOpportunityFields';

const FIELDS = [
    'Case.RecordType.Name',
    'Case.Opportunity_lookup__c'
];

export default class LGT_renewal_Opportunity_lwc extends LightningElement {
    @api recordId;
    @api oppRecordId;
    @track recordLoadError;
    @track oppFields = [];
    @track showEditCmp = false;
    @track isLoading = true;
    @track enableform = false;
    @track isErrorOccurred = false;
    errorMessage = '';
    commonErrorMessage = 'There was an issue while fetching the Opportunity fields. Please contact the administrator for further assistance.';
    hideDOM = true;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredCaseRecord({ error, data }) {
        if (data) {
            if (data.fields != null && data.fields != undefined && data.fields.Opportunity_lookup__c.value != null && data.fields.Opportunity_lookup__c.value != undefined) {
                this.oppRecordId = data.fields.Opportunity_lookup__c.value;
                this.showEditCmp = true;
                this.enableform = true;
            } else {
                this.errorMessage = 'There is no Opportunity linked to this Case. Please associate an Opportunity to modify the details.';
                this.isLoading = false;
            }

        } else if (error) {
            this.isLoading = false;
            this.recordLoadError = error;
            this.errorMessage = this.commonErrorMessage;
        }
    }
    @wire(getAccessibleOpportunityFields)
    wiredCaseFields({ error, data }) {
        if (data) {
            if (data != null && data.length > 0) {
                this.oppFields = data;
            } else if (this.errorMessage == null) {
                this.showEditCmp = false;
                this.errorMessage = this.commonErrorMessage;
                this.isLoading = false;
            }
        } else if (error) {
            this.isLoading = false;
            this.showEditCmp = false;
            this.oppFields = [];
            this.errorMessage = this.commonErrorMessage;
            console.error('Error fetching Case fields:', error);
        }
    }

    get isDataAvailable() {
        if (this.showEditCmp && this.oppFields.length > 0) {
            return true;

        }
        return false;
    }
    handleOnload(event) {
        this.isLoading = false;
        let fields = this.template.querySelectorAll('.inputTags');
        fields.forEach((field) => {
            if (field.value != null && field.value != '' && /^[0-9]+(\.[0-9]+)?$/.test(field.value) && field.value.toString().split('.')[1]?.length > 2) {
                if (typeof field.value == 'number') {
                    field.value = Number(parseFloat(field.value).toFixed(2));
                } else if (typeof field.value == 'string') {
                    field.value = parseFloat(field.value).toFixed(2)
                }
            }
        });
    }

    handleOnError(event) {
        this.isLoading = false;
        if (event != null && event != undefined && event.detail != null && event.detail != undefined) {
            let errorMessage = event.detail.detail != null ? event.detail.detail : event.detail.message;
            this.showToastMessage('error', errorMessage, event.detail.message);

        }

    }
    handleSubmit() {
        this.isLoading = true;
    }

    handleSuccess() {
        this.isLoading = false;
        this.showEditCmp = false;
        this.showToastMessage('success', 'Data inserted successfully', 'Success');
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    showToastMessage(variantType, message, title) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variantType,
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

}