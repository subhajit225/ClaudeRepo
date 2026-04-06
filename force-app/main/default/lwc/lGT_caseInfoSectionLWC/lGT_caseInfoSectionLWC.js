import { LightningElement, api, track } from 'lwc';
import { refreshTab, getFocusedTabInfo, getEnclosingTabId, IsConsoleNavigation } from 'lightning/platformWorkspaceApi';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getRecordType from '@salesforce/apex/CaseDetailsControllerLWC.getRecType';
import getRecordFields from '@salesforce/apex/CaseDetailsControllerLWC.getFields';
import { RefreshEvent } from 'lightning/refresh';

export default class LGT_caseInfoSectionLWC extends LightningElement {
    showSpinner = false;
    recordTypeName = '';
    activeSections = ['A'];
    @track wrapperData;
    @track fieldsList;
    @api recordId;
    caseRecord;
    currentIndex = 0;
    errors = [];
    isOpen = false;
    saved = false;
    exception = false;
    exceptionMsg = '';
    createCustomerSuccess = false;
    isCustomerSuccessUsr = false;
    sectionLabel = '';
    isSupportManager = false;
    isSaved = false; isSnooze = false; isHotSectionOpen = false; isHotSectionSaved = false; escalationManagerFlag = false;
    escalationOwnerManagerName = ''; disableEscalationManagerFlag = false; isEditMode = false;
    compId;
    caseNumberText;
    caseUrl;

    connectedCallback() {
        this.showSpinner = true;
        try {
            getRecordFields({ recordId: this.recordId })
                .then((result) => {
                    this.wrapperData = result;
                    this.fieldsList = this.wrapperData.wrapperList;
                    this.caseRecord = this.wrapperData.recordDetail;
                    this.isCustomerSuccessUsr = this.wrapperData.isCustomerSuccessUser;
                    this.sectionLabel = this.wrapperData.sectionLabel;
                    this.isSupportManager = this.wrapperData.isSupportManager;
                    this.showSpinner = false;
                    this.escalationOwnerManagerName = (this.caseRecord && this.caseRecord.EscalationManagerOwner__r) ? this.caseRecord.EscalationManagerOwner__r.Name : '';
                    this.escalationManagerFlag = this.caseRecord.HotCriticalIssue__c;
                    this.disableEscalationManagerFlag = this.escalationManagerFlag ? false : true;

                    this.fieldsList.forEach(field => {
                        if (field.Name.includes('Opportunity_lookup__r') || field.Name === 'Account.Customer_URL__c' || field.Name === 'Account.Id' ||
                            field.Name === 'Account.Sum_of_Opportunities__c' || field.Name === 'Account.Account_Preference__c') {
                            let splittedField = field.Name.split('.');
                            field.isLookupField = true;
                            field.isUrlField = field.Name.includes('URL__c') ? true : false;
                            if (this.caseRecord[splittedField[0]] != null && this.caseRecord[splittedField[0]] != undefined && this.caseRecord[splittedField[0]][splittedField[1]] != null) {
                                field.lookupFieldValue = this.caseRecord[splittedField[0]][splittedField[1]].toString();
                            }
                        }
                        if (field.Name === 'Account.OwnerId') {
                            let splittedField = field.Name.split('.');
                            field.isLookupField = true;
                            if (this.caseRecord[splittedField[0]] != null && this.caseRecord[splittedField[0]] != undefined && this.caseRecord[splittedField[0]][splittedField[1]] != null) {
                                field.lookupFieldValue = this.caseRecord[splittedField[0]]['Owner']['Name'].toString();
                            }
                        }
                        if (field.Name === 'Account.Rubrik_Sales_Engineer__c') {
                            let splittedField = field.Name.split('.');
                            field.isLookupField = true;
                            if (this.caseRecord[splittedField[0]] != null && this.caseRecord[splittedField[0]] != undefined && this.caseRecord[splittedField[0]]['Rubrik_Sales_Engineer__r'] != null) {
                                field.lookupFieldValue = this.caseRecord[splittedField[0]]['Rubrik_Sales_Engineer__r']['Name'].toString();
                            }
                        }
                        if (field.Name === 'Entitlement__r.EndDate' || field.Name === 'Entitlement__r.AnnualContractValue__c') {
                            let splittedField = field.Name.split('.');
                            field.isLookupField = true;
                            if (this.caseRecord[splittedField[0]] != null && this.caseRecord[splittedField[0]] != undefined && this.caseRecord[splittedField[0]][splittedField[1]] != null) {
                                field.lookupFieldValue = this.caseRecord[splittedField[0]][splittedField[1]].toString();
                            }
                        }
                        if (field.Name === 'Cluster__c' || field.Name === 'Additional_Cluster__c') {
                            field.isLookupField = true;
                            // Dynamically pick related object name (relationship name always ends with __r)
                            const relationshipName = field.Name.replace('__c', '__r');

                            if (this.caseRecord[relationshipName]) {
                                field.showCopyIcon = true;
                                field.lookupFieldValue = this.caseRecord[relationshipName]['Name'].toString();
                                field.customUrlLink = '/' + this.caseRecord[relationshipName]['Id'].toString();
                            }
                        }
                        if (field.Name === 'Feature__c') {
                            field.isLookupField = true;
                            // Dynamically pick related object name (relationship name always ends with __r)
                            const relationshipName = field.Name.replace('__c', '__r');

                            if (this.caseRecord[relationshipName]) {
                                field.showCopyIcon = true;
                                field.lookupFieldValue = this.caseRecord[relationshipName]['Feature__c'].toString();
                                field.customUrlLink = '/' + this.caseRecord[relationshipName]['Id'].toString();
                            }
                        }
                        if (field.Name === 'CaseNumber') {
                            field.showCopyIcon = true;
                            field.showCaseUrl = true;
                            field.caseNumberText = this.caseRecord?.CaseNumber;
                            field.caseUrl = '/' + this.recordId;
                            this.caseNumberText = this.caseRecord?.CaseNumber;
                        }
                    });
                }).catch((err) => {
                    this.exception = true;
                    console.log('errors..!', err);
                    console.log('exception type=>', err.exceptionType);
                    this.exceptionMsg = err.message;
                    this.showSpinner = false;
                });
        } catch (error) {
            this.exception = true;
            console.log('errors..!', error);
            console.log('exception type=>', error.exceptionType);
            if (this.errors[0].includes('There is No Customer Success')) {
                this.createCustomerSuccess = true;
            }
            this.exceptionMsg = error.message;
            this.showSpinner = false;
        }
    }

    /************************Inline Edit Functions***************/
    inlineEdit(event) {
        event.preventDefault();
        let fName = event.target.dataset.id;
        if (fName == 'Platform__c' || fName == 'Product_Area__c' ||
            fName == 'Problem_Type__c' || fName == 'Sub_Component__c' ||
            fName == 'Software_Version__c' || fName == 'If_Other__c' || fName == 'Sub_Phase__c' || fName == 'Churn_Reason__c') {
            this.isOpen = true;
            this.saved = false;
            this.compId = fName;
        } else if (fName == 'HotCriticalIssue__c') {
            this.isHotSectionOpen = true;
            this.isHotSectionSaved = false;
        } else {
            this.toggleEditMode(fName, true);
        }
    }
    toggleEditMode(fieldApiName, isEdit) {/***Toggle Edit Mode***/
        this.fieldsList.forEach(field => {
            if (field.Name === fieldApiName) {
                field.isEditMode = isEdit;
            }
        });
    }
    closeInlineEdit(event) {
        let fieldApiName = event.target.dataset.id;
        this.toggleEditMode(fieldApiName, false);
    }
    handleFieldChange(event) {
        let fieldVal = event.target.value;
        let fieldAPiName = event.target.dataset.id;
        this.caseRecord[fieldAPiName] = fieldVal;
    }
    /****************Save Record*****************/
    saveCaseRecord(event) {
        event.preventDefault();
        this.showSpinner = true;
        const fields = event.detail.fields;
        event.target.submit(fields);
    }
    handleAfterSave(event) {
        event.preventDefault();
        this.saved = true;
        let fName = event.target.dataset.id;
        this.toggleEditMode(fName, false);
        this.showSpinner = false;
        this.showToastMessage('Success', 'Record Updated!!', 'success');
        this.dispatchEvent(new RefreshEvent());
    }
    handleError(event) {
        let fName = event.target.dataset.id;
        let message = 'Error while Saving ' + fName + ' field data. Please contact your System Adminstrator.';
        this.showSpinner = false;
        this.showToastMessage('Error!', message, 'error');
    }
    /**********Toast Message************/
    showToastMessage(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,//variant values -> 'success','error','warning','info'
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    /************************** Modal Functions Starts ********************************/
    closeModal(event) {
        this.isOpen = false;
        this.saved = true;
        this.fieldsList.forEach(field => {
            field.isEditMode = false;
        });
    }

    handleHotSectionEdit(event) {
        console.log('value from child=>', event.detail);
        this.isHotSectionOpen = event.detail.isHotSectionOpen;
        this.isHotSectionSaved = event.detail.isHotSectionSaved;
    }

    handleHotSectionSubmit(event) {
        event.preventDefault();
        this.showSpinner = true;
        this.isHotSectionOpen = false;
        //this.isEditMode = false;
        const fields = event.detail.fields;
        event.target.submit(fields);
    }

    handleHotSectionSuccess(event) {
        this.showSpinner = false;
        this.showToastMessage('Success', 'Record Updated!!', 'success');//params -> title,message,variant
        this.isHotSectionOpen = false;
        this.isHotSectionSaved = true;
        getRecordFields({ recordId: this.recordId })
            .then((result) => {
                this.caseRecord = result.recordDetail;
                this.escalationOwnerManagerName = (this.caseRecord && this.caseRecord.EscalationManagerOwner__r) ? this.caseRecord.EscalationManagerOwner__r.Name : '';
                this.escalationManagerFlag = this.caseRecord.HotCriticalIssue__c;
                this.disableEscalationManagerFlag = this.escalationManagerFlag ? false : true;
                this.fieldsList = result.wrapperList;
            }).catch((err) => {
                this.exception = true;
                console.log('errors..!', err);
                console.log('exception type=>', err.exceptionType);
                if (this.err[0].includes('There is No Customer Success')) {
                    this.createCustomerSuccess = true;
                }
                this.exceptionMsg = err.message;
                this.showSpinner = false;
            });

    }

    closeHotSectionModal(event) {
        this.isHotSectionOpen = false;
        this.isHotSectionSaved = true;
        if (this.caseRecord != null) {
            this.escalationManagerFlag = this.caseRecord.HotCriticalIssue__c;
            this.disableEscalationManagerFlag = this.escalationManagerFlag ? false : true;
        }
    }

    handleSubmit(event) {
        event.preventDefault();
        this.isOpen = false;
        this.showSpinner = true;
        //this.isEditMode = false;
        const fields = event.detail.fields;
        event.target.submit(fields);
    }

    handleSuccess(event) {
        event.preventDefault();
        this.showToastMessage('Success', 'Record Updated Successfully!!', 'success');//params -> title,message,variant
        this.isOpen = false;
        this.saved = true;
        this.showSpinner = false;
    }
    /************************** Modal Functions Ends********************************/

    checkSubPhase(event) {
        let subphase = event.target.value;
        this.isSnooze = subphase == 'Snooze' ? true : false;
    }

    handleLoad(event) {
        let ele = this.template.querySelector('[data-id="subPhase"]');
        this.isSnooze = ele.value == 'Snooze' ? true : false;
    }

    handleEscalationManagerField(event) {
        this.escalationManagerFlag = event.target.value;

        if (!event.target.value) {
            const inputField = this.template.querySelector('[data-id="HotCriticalOwner"]');
            inputField.value = null;
            //set HotCriticalOwner value to null
        }
        this.disableEscalationManagerFlag = event.target.value ? false : true;
    }
    handleCopyClick(event) {
        let copyFieldValue = this.caseNumberText;//window.location.href;
        const fieldName = event.target.dataset.id;
        if (fieldName != '' && fieldName != undefined && (fieldName === 'Cluster__c' || fieldName === 'Additional_Cluster__c')) {
            copyFieldValue = event.target.dataset.label;
        }
        try {
            if (navigator.clipboard && navigator.clipboard.writeText) {
                navigator.clipboard.writeText(copyFieldValue)
                    .then(() => {
                        console.log('Text copied!');
                        this.showToastMessage('Copied To Clipboard!', '', 'info');
                        event.target.blur(); // Remove focus to prevent aria-hidden error
                    })
                    .catch(err => {
                        console.error('Failed to copy:', err);
                    });
            } else {
                console.warn('Clipboard API not available');
                this.fallbackCopy(copyFieldValue);
            }
        }
        catch (error) {
            console.log('Error :' + error);
            this.fallbackCopy(copyFieldValue);
        }
    }
    fallbackCopy(text) {
        try {
            const tempInput = document.createElement('textarea');
            tempInput.value = text;
            document.body.appendChild(tempInput);
            tempInput.select();
            document.execCommand('copy'); // Fallback method
            document.body.removeChild(tempInput);
            this.showToastMessage('Copied To Clipboard!', '', 'info');
            console.log('Copied using fallback method!');
        }
        catch (error) {
            console.log('Error :' + error);
            console.log('Error while copying using fallback method!');
        }
    }
}