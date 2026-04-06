import {LightningElement,api,track,wire} from 'lwc';
import { getRecord } from "lightning/uiRecordApi";
import getRecordTypeId from '@salesforce/apex/CloseCaseControllerPartner.getPartnerRecordTypeId';
import {getPicklistValuesByRecordType} from 'lightning/uiObjectInfoApi';
const FIELDS = ["Case.CaseNumber", "Case.Status"];

export default class CloseCaseLWC extends LightningElement {
    @api caseId;
    @track caseNumber;
    @track objectApiName = 'Case';
    @track caseToClose;
    @track recordTypeId;
    @track error;
    @track options = [];
    @track completeOptions = [];
    @track value = 'Closed';
    @track alreadyClosed = false;
    @track isLoading = true;

    connectedCallback() {
        getRecordTypeId({})
            .then((result) => {
                this.recordTypeId = result;
            })
            .catch((error) => {
                this.error = error;
                console.log('error', error);
            });
    }

    @wire(getRecord, { recordId: "$caseId", fields: FIELDS})
    caseDetails({
        data,
        error
    }) {
        if (data) {
            this.caseToClose = data;
            this.caseNumber = this.caseToClose.fields.CaseNumber.value;
            if (this.caseToClose.fields.Status.value.includes('Closed')) {
                this.alreadyClosed = true;
                this.isLoading = false;
            } else {
                this.alreadyClosed = false;
            }

        } else if (error) {
            console.log('err-->', error);
        }
    }
    @wire(getPicklistValuesByRecordType, {
        objectApiName: 'Case',
        recordTypeId: '$recordTypeId'
    })
    StatusPicklistValues({
        error,
        data
    }) {
        if (data) {
            this.options = data.picklistFieldValues.Status.values;
            this.completeOptions = this.options.filter(o => o.label.includes('Closed')).map(o => ({
                label: o.label,
                value: o.value
            }));
        } else if (error) {
            window.console.log('error =====> ' + JSON.stringify(error));
            this.showToast('error', 'Error retriving closed values...');
        }
    }
    handleSubmit(event) {
        event.preventDefault();
        this.isLoading = true;
        const now = new Date();
        const fields = event.detail.fields;
        fields.Status = this.template.querySelector('lightning-combobox').value;
        if (this.template.querySelector('lightning-combobox').value.includes('Closed')) {
            fields.Date_Time_Closed__c = now.toISOString();
        }
        this.template.querySelector('lightning-record-edit-form').submit(fields);

    }
    handleLoad(event) {
        this.isLoading = false; // Stop the spinner
    }
    handleSuccess(event) {
        this.isLoading = false;
        this.showToast('success', 'The case has been closed Sucessfully...');
    }
    //https://rubrik.atlassian.net/browse/CS21-2110
    handleError(event){
        this.isLoading = false;
        event.preventDefault();
        //this.showToast('error', 'Failed to close case');
    }
    handleCancel() {
        try {
            var base_url = document.referrer;
            if (base_url.includes('lightning')) {
               window.open('/lightning/r/Case/'+this.caseId+'/view','_top')
            } else {
               window.open('/'+this.caseId, '_top');

            }
        } catch (e) {
            console.log('Error-->', e);
        }
    }

    @track toast;
    showToast(toastType, msg) {
        this.toast = {
            _class: toastType === 'success' ? 'slds-notify slds-notify_toast slds-theme_success' : 'slds-notify slds-notify_toast slds-theme_error',
            containerClass: toastType === 'success' ? 'slds-notify_container slds-is-relative slds-is-absolute' : 'slds-notify_container',
            iconName: toastType === 'success' ? 'utility:success' : 'utility:error',
            altText: toastType === 'success' ? 'Success' : 'Error',
            title: toastType === 'success' ? 'Success!' : 'Error!',
            message: msg
        }
        setTimeout(() => {
            this.handleCancel();
        }, 1000);
    }

    handleToastCross() {
        this.toast = undefined;
    }

    get formattedCaseId() {
        return `{${this.caseNumber}}`;
    }

}