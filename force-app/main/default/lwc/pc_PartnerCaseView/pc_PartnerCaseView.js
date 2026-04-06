import { LightningElement, api, wire, track } from 'lwc';
import getCaseDetails from '@salesforce/apex/PC_PartnerCaseController.getCaseDetails';
import addCommentApex from '@salesforce/apex/PC_PartnerCaseController.addMyComment';
import reopenCase from '@salesforce/apex/PC_PartnerCaseController.reopen';
import createCaseWithComment from '@salesforce/apex/PC_PartnerCaseController.createCaseWithComment';

// Custom labels for Case Types and Subtypes
import tapEmail from '@salesforce/label/c.TAPPartnerEmail';
import goForwardEmail from '@salesforce/label/c.GoForwardEmail';

import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadStyle } from 'lightning/platformResourceLoader';
import { updateRecord } from "lightning/uiRecordApi";
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';

export default class pc_PartnerCaseView extends NavigationMixin(LightningElement) {
    @track recordId;
    @track isEditAccess = false;
    @track isLoaded = false;
    @track toggleSpinner = true;
    @track caseDetail = [];
    @track caseDetailData = [];
    @track caseContactData = [];
    @track caseAdditionalData = [];
    @track attachedContentDocuments = [];
    @track caseComments = [];
    @track emails = [];
    @track isCloseCaseStatus = false;
    @track commentText = '';
    @track showPopup = false;
    @track caseNumber;
    @track hasError = false;
    @track errorMessage = "You haven't composed anything yet.";
    @track textLimit = 32000;
    @track caseClosedateTime = '';
    @track popupSpinner = false;

    get commentLength() {
        return this.commentText.length;
    }
    
    caseDetailColumns = [
        { label: 'Case Number', fieldName: 'CaseNumber', type: 'url', columnCSS: 'field-container slds-size_1-of-2' },
        { label: 'Case Owner', fieldName: 'Owner.Name', type: 'text', columnCSS: 'field-container slds-size_1-of-2' },
        { label: 'Case Origin', fieldName: 'Origin', type: 'text', columnCSS: 'field-container slds-size_1-of-2' },
        { label: 'Priority', fieldName: 'Priority', type: 'text', columnCSS: 'field-container slds-size_1-of-2' },
        { label: 'Status', fieldName: 'Status', type: 'text', columnCSS: 'field-container slds-size_1-of-2' },
        { label: 'Type', fieldName: 'Type__c', type: 'text', columnCSS: 'field-container slds-size_1-of-2' },
        { label: 'Subject', fieldName: 'Subject', type: 'text', columnCSS: 'field-container slds-size_1-of-2' },
        { label: 'Subtype', fieldName: 'Subtype__c', type: 'text', columnCSS: 'field-container slds-size_1-of-2' },
        { label: 'Description', fieldName: 'Description', type: 'text', columnCSS: 'field-container-description slds-size_1-of-2' },
    ];

    contactInforamtionColumns = [
        { label: 'Contact Name', fieldName: 'Contact_Name__c', type: 'url' },
        { label: 'Contact Phone', fieldName: 'Contact_Phone__c', type: 'text' },
        { label: 'Contact Email', fieldName: 'Contact_Email__c', type: 'text' }
    ];

    additionalInforamtionColumns = [
        { label: 'Date/Time Opened', fieldName: 'CreatedDate', type: 'date' },
        { label: 'Date/Time Closed', fieldName: 'Date_Time_Closed__c', type: 'date' }
    ];

    connectedCallback() {
        this.recordId = new URLSearchParams(window.location.search).get('id');
        this.loadCustomCSS();
        this.loadCaseDetails();
    }

    loadCustomCSS() {
        loadStyle(this, `${PartnerCommunityResource}/PartnerCommunityResource/Stylesheets/PartnerCommunityCSS.css`)
            .catch(error => console.error('CSS Load Error:', error));
    }

    async loadCaseDetails() {
        try {
            const response = await getCaseDetails({ recordId: this.recordId });
            this.caseDetail = response?.caseList[0];
            this.isCloseCaseStatus = this.caseDetail?.Status.includes('Closed') ? true : false;
            this.caseNumber = this.caseDetail?.CaseNumber;
            this.caseClosedateTime = this.caseDetail?.Date_Time_Closed__c;
            this.isEditAccess = response.isAccess;
            this.toggleSpinner = false;
            this.isLoaded = true;
            this.setColumnData(response?.caseList);
            this.setCommentData(this.caseDetail);
        } catch (error) {
            this.toggleSpinner = false;
            this.showToast('Error', error, 'error');
            console.error(error);
        }
    }

    setColumnData(caseList){
        this.caseDetailData = this.formatCases(caseList, 'caseDetail')[0].fields;
        this.caseContactData = this.formatCases(caseList, 'contactInfo')[0].fields;
        this.caseAdditionalData = this.formatCases(caseList, 'AdditionalInfo')[0].fields;
    }

    setCommentData(caseList){
        this.attachedContentDocuments = caseList?.AttachedContentDocuments || [];
        this.caseComments = caseList?.CaseComments ? this.emailCommentdataWithIndex(caseList?.CaseComments) : [];
        this.emails = caseList?.EmailMessages ? this.emailCommentdataWithIndex(caseList?.EmailMessages) : [];
    }

    formatCases(caseList, type) {
        const column =  type === 'caseDetail' ? 
                        this.caseDetailColumns : 
                        type === 'contactInfo' ? 
                        this.contactInforamtionColumns :  
                        this.additionalInforamtionColumns;
        return caseList.map(caseRecord => ({
            key: caseRecord.Id,
            fields: column.map(column => ({
                key: column.label,
                value: this.setFieldValueBasedOnType(column.type, caseRecord, column.fieldName),
                columnCSS: column.columnCSS
            }))
        }));
    }

    setFieldValueBasedOnType(type, caseRecord, fieldName) {
        const value = this.parseCaseFieldValue(caseRecord, fieldName);
        return type === 'date' ? this.formatDate(value) : value;
    }

    parseCaseFieldValue(record, fieldPath) {
        return fieldPath.split('.').reduce((value, key) => value?.[key], record);
    }

    formatDate(dateString) {
        if (!dateString) return '';
        return new Intl.DateTimeFormat('en-US', {
            day: 'numeric',
            month: 'short',
            year: 'numeric',
            hour: 'numeric',
            minute: 'numeric',
            second: 'numeric',
            hour12: true
        }).format(new Date(dateString));
    }

    emailCommentdataWithIndex(emails) {
        return emails.map((email, index) => ({
            ...email,
            number: index + 1
        }));
    }

    handleUploadFile(){
        this.showToast('Success', 'File has been uploaded successfully', 'success');
        this.handleRefresh();
    }

    handleCloseCase() {
        this.toggleSpinner = true;
        const fields = {
            'Status': 'Closed',
            'Id': this.recordId
        };
        const recordInput = { fields };
    
        updateRecord(recordInput)
        .then(() => {
            this.showToast('Success', 'Case closed successfully.', 'success');
            this.toggleSpinner = false;
            this.handleRefresh();
        })
        .catch((error) => {
            this.toggleSpinner = false;
            this.showToast('Error', 'System issue please contact with System Admin.', 'error');
        });
    }

    handleOpenFile(event) {
        const fileId = event.target.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: fileId,
                actionName: 'view',
            },
        });
    }

    handleCommentBox() {
        this.commentText = '';
        this.showPopup = true;
    }

    handleCancel() {
        this.showPopup = false;
    }

    handleCommentChange(event) {
        this.commentText = event.target.value;
        this.hasError = !this.commentText;
    }

    handleAddComment() {
        if (!this.commentText) {
            this.hasError = true;
            return;
        }
        this.invokeApex(addCommentApex);
    }

    handleAddReopen() {
        if (!this.commentText) {
            this.hasError = true;
            return;
        }

        const currentDateTime = new Date();
        const caseCloseDate = new Date(this.caseClosedateTime);
        const timeDifference = currentDateTime - caseCloseDate;
        const daysDifference = timeDifference / (1000 * 60 * 60 * 24);

        if (daysDifference <= 7) {
            this.invokeApex(reopenCase);
        } else {
            this.createCaseWithComment(createCaseWithComment);
        }
    }

    invokeApex(apexMethod) {
        this.popupSpinner = true;
        apexMethod({ parentId: this.recordId, body: this.commentText })
        .then(() => {
            this.showToast('Success', 'Operation completed successfully!', 'success');
            this.showPopup = false;
            this.popupSpinner = false;
            this.handleRefresh();
        })
        .catch((error) => {
            this.showToast('Error', error.body.message, 'error');
        })
        .finally(() => {
            this.popupSpinner = false;
        });
    }

    async createCaseWithComment(apexMethod) {
        this.popupSpinner = true;
        try {
            const caseRecord = {
                Duplicate_Case_Id__c: this.recordId,
                Status: 'New',
                Origin: 'Portal',
                OwnerId: this.caseDetail?.OwnerId,
                ContactId: this.caseDetail?.ContactId,
                AccountId: this.caseDetail?.AccountId,
                RecordTypeId: this.caseDetail?.RecordTypeId,
                Type__c: this.caseDetail?.Type__c,
                SubType__c: this.caseDetail?.SubType__c,
                SuppliedEmail: this.caseDetail?.SuppliedEmail,
                Subject: this.caseDetail?.Subject,
                Description: this.caseDetail?.Description,
                Recipient_Email__c: this.caseDetail?.Origin == 'Email - TAP' || tapEmail.includes(this.caseDetail?.Recipient_Email__c) ? tapEmail : goForwardEmail
            };

            const response = await apexMethod({ caseRecord, body: this.commentText });
            this.showToast('Success', 'Case created successfully', 'success');
            window.location.href = `${window.location.origin}/s/viewcase?id=${response?.caseId}`;
        } catch (error) {
            this.showToast(errorMsg, error, 'error');
        }
        this.popupSpinner = false;
    }

    handleRefresh() {
        this.toggleSpinner = true;
        this.loadCaseDetails();
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}