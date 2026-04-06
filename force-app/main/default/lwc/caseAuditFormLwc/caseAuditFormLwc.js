import { LightningElement, wire , api, track } from 'lwc';
import getCaseInfo from '@salesforce/apex/CaseAuditFormController.getCaseAndCaseAuditRecord';
import userId from '@salesforce/user/Id';

export default class CaseAuditFormLwc extends LightningElement {

    @api recordId;
    @track caseRecord = '';
    @track currentUser = userId;
    @track caseAuditRecordId;
    @track auditScore = 0;
    @track isAuditRecordExisting = false;
    @track isLoadingComplete = false;
    @track showMessage = false;
    @track isReady = false;
    @track nowTime = new Date().toISOString();
    _total = [];
    _points = [];

    @wire(getCaseInfo, {caseId: '$recordId'})
    wiredCaseInfo({error, data}) {
        if(data){
            this.caseRecord = data;
            if(data.Case_Audits__r != null) {
                this.isAuditRecordExisting = true;
                this.prepopulateValues(data);
            }
        } else if(error){
            this.error = error;
            this.isEditable = false;
        }
        this.isReady = true;
    }

    prepopulateValues(data) {
        let caseAuditRecord = data.Case_Audits__r[0];
        this.caseAuditRecordId = caseAuditRecord.Id;
        this.auditScore = caseAuditRecord.Final_Audit_Score__c;

        if(caseAuditRecord.Case_Documentation__c == 'Great' || caseAuditRecord.Case_Documentation__c == 'Acceptable') {
            this._total.push('Case_Documentation__c');
            this._points.push('Case_Documentation__c');
        }
        else if(caseAuditRecord.Case_Documentation__c == 'Improvement Required') {
            this._total.push('Case_Documentation__c');
        }

        if(caseAuditRecord.Case_Field_Classification__c == 'Great' || caseAuditRecord.Case_Field_Classification__c == 'Acceptable') {
            this._total.push('Case_Field_Classification__c');
            this._points.push('Case_Field_Classification__c');
        }
        else if(caseAuditRecord.Case_Field_Classification__c == 'Improvement Required') {
            this._total.push('Case_Field_Classification__c');
        }

        if(caseAuditRecord.Overall_Case_management__c == 'Great' || caseAuditRecord.Overall_Case_management__c == 'Acceptable') {
            this._total.push('Overall_Case_management__c');
            this._points.push('Overall_Case_management__c');
        }
        else if(caseAuditRecord.Overall_Case_management__c == 'Improvement Required') {
            this._total.push('Overall_Case_management__c');
        }

        if(caseAuditRecord.Resolution__c == 'Great' || caseAuditRecord.Resolution__c == 'Acceptable') {
            this._total.push('Resolution__c');
            this._points.push('Resolution__c');
        }
        else if(caseAuditRecord.Resolution__c == 'Improvement Required') {
            this._total.push('Resolution__c');
        }
    }

    handleLoad(){
        this.isLoadingComplete = true;
    }

    handleChange(event) {
        let value = event.detail.value;
        let fieldName = event.target.dataset.name;

        if(!this._total.includes(fieldName)) {
            if(value == 'Great' || value == 'Acceptable') {
                this._total.push(fieldName);
                this._points.push(fieldName);
            }
            else if(value == 'Improvement Required') {
                this._total.push(fieldName);
            }
        }
        else {
            if(!this._points.includes(fieldName) && (value == 'Great' || value == 'Acceptable')) {
                this._points.push(fieldName);
            }
            else if(this._points.includes(fieldName) && value == 'Improvement Required') {
                this._points.splice((this._points).indexOf(fieldName), 1);
            }
            else if(value == 'N/A') {
                this._total.splice((this._total).indexOf(fieldName), 1);

                if(this._points.includes(fieldName)) {
                    this._points.splice(this._points.indexOf(fieldName), 1);
                }
            }
        }

        this.auditScore = this._total.length != 0 ? (this._points.length/this._total.length)*100 : 0;
    }

    handleSubmit(event) {
        this.isLoadingComplete = false;
        event.preventDefault();     // stop the form from submitting
        const fields = event.detail.fields;
        fields.Case_Owner_s_Manager_s_Manager__c = this.caseRecord.Owner_s_Manager_s_Manager__c;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    handleSuccess(event) {
        this.isLoadingComplete = true;
        this.showMessage = true;
        this.caseAuditRecordId = event.detail.id;

        setTimeout(() => {
            this.showMessage = false;
            this.isAuditRecordExisting = true;
        }, 3000);
    }
}