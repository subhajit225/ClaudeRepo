import { LightningElement, track, wire } from 'lwc';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import CASE_OBJECT from '@salesforce/schema/Case';
import TYPE_FIELD from '@salesforce/schema/Case.Type__c';
import SUBTYPE_FIELD from '@salesforce/schema/Case.Subtype__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import { loadStyle } from 'lightning/platformResourceLoader';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';

// Custom labels for Case Types and Subtypes
import tapEmail from '@salesforce/label/c.TAPPartnerEmail';
import goForwardEmail from '@salesforce/label/c.GoForwardEmail';
import goForwardQueueId from '@salesforce/label/c.GoForwardQueueId';

//Apex to create case and Upload files attached to case
import getCurrentUserInfo from '@salesforce/apex/PC_PartnerCaseController.getCurrentUserInfo';
import createCase from '@salesforce/apex/PC_PartnerCaseController.createCase';
import uploadFilesToCase from '@salesforce/apex/PC_PartnerCaseController.uploadFilesToCase';
import deleteFile from '@salesforce/apex/PC_PartnerCaseController.deleteFile';

export default class Pc_PartnerCaseForm extends LightningElement {
    recordTypeId = '';
    selectedCategory = '';
    selectedGoType = '';
    selectedTapType = '';
    selectedSubType = '';
    goTypeOptions = [];
    subTypeOptions = [];
    isGoForward = false;
    isTAP = false;
    caseFiles = [];
    caseRecord = {};
    subjectValue = '';
    descriptionValue = '';
    formTitle = 'Case Submission Form';
    spinnerLoad = true;
    currentUserInfo;

    caseCategoryOptions = [
        { label: 'GoForward', value: 'GoForward' },
        { label: 'Third-Party Hardware (TAP)', value: 'Third-Party Hardware' }
    ];

    caseGoTypeOptions = [
        { label: 'LMS (Rubrik University)', value: 'LMS' },
        { label: 'Rewards (Rubrik Rewards)', value: 'Rewards' },
        { label: 'Sizing Tool (Sizing Tool Access)', value: 'Sizing Tool' },
        { label: 'Deal Registration', value: 'Deal Registration' },
        { label: 'Partner Portal Support', value: 'Partner Portal Support' },
        { label: 'Account Management', value: 'Account Management' },
        { label: 'General questions', value: 'General questions' }
    ];

    caseSubTypeOptions = [
        { label: 'Quote Submission', value: 'Quote Submission' },
        { label: 'Process Question', value: 'Process Question' },
        { label: 'Quote/Order Status', value: 'Quote/Order Status' },
        { label: 'Platform Qualification', value: 'Platform Qualification' },
        { label: 'Sales Support', value: 'Sales Support' }
    ];

    // Wire to get Case object metadata
    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    caseObjectInfo;

    //Wire to get the GoForward Queue Id and Current User details
    @wire(getCurrentUserInfo)
    wiredCurrentUserInfo({ data, error }) {
        if (data) {
            this.currentUserInfo = data.currentUser;
        } else if (error) {
            this.showToast('Error retrieving queue and user info:', error.body.message, 'error');
        }
    }

    // Wire to get the case recordtype value
    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    handleCaseObjectInfo({ data, error }) {
        if (data) {
            const { defaultRecordTypeId, recordTypeInfos } = data;
            this.recordTypeId = Object.keys(recordTypeInfos).find(rtId => recordTypeInfos[rtId].name === 'Partner Case') || defaultRecordTypeId;
        } else if (error) {
            this.showToast('Error retrieving Case object info:', error.body.message, 'error');
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: TYPE_FIELD })
    wiredTypePicklist({ data, error }) {
        if (data) {
            const fetchedValues = data.values.map(item => item.value);
            this.goTypeOptions = this.caseGoTypeOptions.filter(option => fetchedValues.includes(option.value));
        } else if (error) {
            this.showToast('Error fetching Case Type options', error.body.message, 'error');
        }
    }

    // Wire to get the picklist values for SubType__c
    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: SUBTYPE_FIELD })
    wiredSubTypePicklist({ data, error }) {
        if (data) {
            const fetchedValues = data.values.map(item => item.value);
            this.subTypeOptions = this.caseSubTypeOptions.filter(option => fetchedValues.includes(option.value));
        } else if (error) {
            this.showToast('Error fetching Case SubType options', error.body.message, 'error');
        }
    }

    connectedCallback() {
        Promise.all([
            loadStyle(this, PartnerCommunityResource + '/PartnerCommunityResource/Stylesheets/PartnerCommunityCSS.css')
        ]).then(() => {
            console.log("File path-->" + PartnerCommunityResource);
        })
            .catch(error => {
                console.log(error.body.message);
            });
        this.spinnerLoad = false;
    }

    // Handle Category Change
    handleCategoryChange(event) {
        this.selectedCategory = event.target.value;
        this.selectedSubType = '';
        this.selectedTapType = '';
        this.selectedGoType = '';
        this.isGoForward = (this.selectedCategory === 'GoForward');
        this.isTAP = (this.selectedCategory === 'Third-Party Hardware');
        this.selectedTapType = this.isTAP ? 'Third-Party Hardware' : '';
    }

    handleTypeChange(event) {
        const { value, name } = event.target;
        if (this.isGoForward) {
            this.selectedGoType = value;
        } else if (this.isTAP && name === 'CaseSubType') {
            this.selectedSubType = value;
        }
    }

    handleInputChange(event) {
        const { name, value } = event.target;
        if (name === 'Subject') this.subjectValue = value;
        else if (name === 'Description') this.descriptionValue = value;
    }

    handleFileUpload(event) {
        const uploadedFiles = event.detail.files;
        uploadedFiles.forEach(file => {
            this.caseFiles = [...this.caseFiles, { name: file.name, documentId: file.documentId }];
        });
    }

    async handleRemoveFile(event) {
        const fileIndex = event.target.dataset.index;
        const documentId = this.caseFiles[fileIndex]?.documentId;

        if (documentId) {
            this.spinnerLoad = true;
            try {
                await deleteFile({ documentId });
                this.caseFiles.splice(fileIndex, 1);
                this.showToast('Success', 'File deleted successfully', 'success');
            } catch (error) {
                this.showToast('Error', error, 'error');
            }
            this.spinnerLoad = false;
        }
    }

    checkFormValidity() {
        return Array.from(this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea')).every(input => {
            input.reportValidity();
            return input.checkValidity();
        });
    }

    async handleSubmit(event) {
        event.preventDefault();
        const errorMsg = 'Case failed submission. Please send you request email to goforward@rubrik.com or third-partner-hardware@rubrik.com';

        if (!this.checkFormValidity()) {
            this.showToast('Error', 'Please fill in all required fields.', 'error');
            return;
        }

        this.spinnerLoad = true;
        try {
            const caseRecord = {
                Origin: 'Portal',
                Status: 'New',
                Priority: 'None',
                RecordTypeId: this.recordTypeId,
                Subject: this.subjectValue,
                Description: this.descriptionValue,
                Type__c: this.isGoForward ? this.selectedGoType : this.selectedTapType,
                Subtype__c: this.isTAP ? this.selectedSubType : '',
                OwnerId: goForwardQueueId ? goForwardQueueId : this.currentUserInfo?.Id,
                ContactId: this.currentUserInfo?.ContactId,
                AccountId: this.currentUserInfo?.AccountId,
                SuppliedEmail: this.currentUserInfo?.Contact?.Email,
                Recipient_Email__c: this.isTAP ? tapEmail : goForwardEmail
            };

            const response = await createCase({ caseRecord });
            if (response?.caseId && this.caseFiles.length > 0) {
                this.uploadFilesToCase(response.caseId);
            }
            this.showToast('Success', 'Case created successfully', 'success');
            this.redirectToCasePage(response?.caseId);
        } catch (error) {
            this.showToast(errorMsg, error, 'error');
        }
        this.spinnerLoad = false;
    }

    async uploadFilesToCase(caseId) {
        const contentDocumentIds = this.caseFiles.map(file => file.documentId);
        try {
            await uploadFilesToCase({ contentDocumentIds, caseId });
            this.showToast('Success', 'Case created and files uploaded successfully', 'success');
            this.redirectToCasePage(caseId);
        } catch (error) {
            this.showToast('Error attaching files on case', error, 'error');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    redirectToCasePage(caseId) {
        window.location.href = `${window.location.origin}/s/viewcase?id=${caseId}`;
    }

}