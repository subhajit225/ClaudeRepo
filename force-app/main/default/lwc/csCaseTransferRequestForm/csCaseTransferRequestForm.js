import { LightningElement, api, wire, track } from "lwc";
import apexSubmitCaseForTransferApproval from "@salesforce/apex/CaseTransferApprovalRequest.submitCaseForTransferRequestApproval";
import apexApproveCaseTransferRequest from "@salesforce/apex/CaseTransferApprovalRequest.approveCaseTransferRequest";
import { getRecord } from "lightning/uiRecordApi";
import CURRENTSTATUS_FIELD from "@salesforce/schema/Case.Current_Status__c";
import NEXTSTEP_FIELD from "@salesforce/schema/Case.Next_Step__c";
import PRIORITY from "@salesforce/schema/Case.Priority";
import NEXTACTION_FIELD from "@salesforce/schema/Case.SuccessResolutionCriteria__c";
import caseTransferQueuId from "@salesforce/label/c.CaseTransferQueueId";
import warmSlackChannel from "@salesforce/label/c.CaseTransferWarmSlackChannel";
import coldSlackChannel from "@salesforce/label/c.CaseTransferColdSlackChannel";
import TRANSFER_FIELD from "@salesforce/schema/Case.CaseTransferType__c";
import apexGetCaseDetails from '@salesforce/apex/CaseTransferApprovalRequest.getCaseDetails';

const fields = [CURRENTSTATUS_FIELD, NEXTSTEP_FIELD, PRIORITY, TRANSFER_FIELD, NEXTACTION_FIELD];

export default class CsCaseTransferRequestForm extends LightningElement {
    @api recordId;
    @api warmflag = false;
    @api decision;
    error;
    showCustomFrequency = false;
    caseCommentNumber;
    customErrors = [];
    showErrors = false;
    @track productLine;
    @track functionalArea;
    @track component;
    @track isShowOther = false;
    @api isSupportManager = false;
    showSpinner = false;
    @api customerCommunicationFrequencyValue;
    @api isSubmitted;
    showRejectView = false;
    rejectMessage = '';

    @wire(getRecord, {
        recordId: "$recordId",
        fields
    })
    caseRecord;

    //logic to decide if comment field should be displayed	
    get isOther() {
        alert(this.caseRecord.Platform__c);
        return false;
    }

    //logic to decide if comment field should be displayed	
    get caseReason() {

        return this.caseRecord.CaseTransferType__c;
    }

    //logic to decide if comment field should be displayed
    get isTransferForm() {
        if (this.decision && this.decision != "") {
            return true;
        }

        return false;
    }

    get isCaseComment() {
        if (this.decision && this.decision == "CaseComment") {
            return true;
        }

        return false;
    }

    get isShowCustomFrequency() {
        if (this.decision
            && this.decision != ""
            && this.customerCommunicationFrequencyValue
            && this.customerCommunicationFrequencyValue == 'Custom Schedule') {
            return true;
        }

        return false;
    }

    get disableWarmTransfer() {
        return !this.isSupportManager;
    }

    handleError(event) {
        console.log(event.detail.output.fieldErrors);
        console.log('error', event.detail);
        this.showSpinner = false;
    }

    //get save button name
    get saveButtonName() {
        if (this.isSupportManager) {
            return "Save and Approve";
        }

        return "Submit";
    }

    //handles save operation on case transfer form
    async handleSubmit(event) {
        event.preventDefault();
        const fields = event.detail.fields;
        //show Spinner
        this.showSpinner = true;
        this.showErrors = false;
        this.customErrors = [];
        try {
            const caseInfo = await apexGetCaseDetails({ caseId: this.recordId });
            if (caseInfo && caseInfo.isOldCase) {
                this.showSpinner = false;
                this.customErrors.unshift(caseInfo.errorMessage);
                this.showErrors = true;
            } else {
                if (!this.isSubmitted) {
                    if (this.caseRecord.data.fields.Priority.value != 'P1' && this.decision == 'Critical Escalation') {
                        this.customErrors.unshift("Critical Escalation is only for p1 cases.");
                        this.showErrors = true;
                    }
                } else {
                    this.decision = this.caseRecord.data.fields.CaseTransferType__c.value;
                }

                if (!this.isSupportManager && this.decision && !this.showErrors) {
                    this.handleCustomValidations(
                        fields.Current_Status__c,
                        fields.Next_Step__c,
                        fields.SuccessResolutionCriteria__c
                    );
                }

                if (!this.showErrors) {
                    fields.CaseTransferPreviousOwnerId__c = fields.OwnerId;
                    fields.OwnerId = caseTransferQueuId;
                    fields.CaseTransferType__c = this.decision;
                    fields.WarmTransferRequired__c = this.warmflag;

                    if (!this.isSupportManager) {
                        fields.CaseTransferStatus__c = "submitted";
                        fields.CaseTransferNotificationSlackEmail__c = this.warmflag
                            ? warmSlackChannel
                            : coldSlackChannel;
                    }
                    if (this.isSupportManager && this.isSubmitted) {
                        fields.CaseTransferStatus__c = "Approved";
                    }
                    if (this.showCustomFrequency == false) {
                        fields.CustomCommunicationFrequency__c = "";
                    }

                    if (this.decision && this.decision == 'TransferForm') {
                        fields.CaseTransferComment__c = null;
                    } else {
                        this.caseCommentNumber = fields.CaseTransferComment__c;
                        //fields.CustomerCommunicationFrequency__c = "";
                        //fields.CustomCommunicationFrequency__c = "";
                    }

                    this.template.querySelector("lightning-record-edit-form").submit(fields);
                } else {
                    this.showSpinner = false;
                }
            }
        } catch (error) {
            console.error(error);
            // this.showError('Unable to load case details');
            this.showSpinner = false;
        }
    }


    handleLoad(event) {
        console.log(this.caseRecord);
    }


    handleOtherChange(event) {
        if (event.target.name == 'Component') {
            this.component = event.target.value;
        } else if (event.target.name == 'Functional Area') {
            this.functionalArea = event.target.value;
        } else if (event.target.name == 'Product-line') {
            this.productLine = event.target.value;
        }
        if (event.target.value == 'Other' || event.target.value == 'Other (specify)') {
            this.isShowOther = true;
        } else if (this.productLine != 'Other' && this.functionalArea != 'Other' && this.component != 'Other') {
            this.isShowOther = false;
        }
    }

    //if the CustomerCommunicationFrequency__c is set to custom schedule
    //show custom frequency textfield
    handleFrequencyChange(event) {
        let communicationFrequency = event.target.value;
        this.customerCommunicationFrequencyValue = communicationFrequency;

        if (communicationFrequency == "Custom Schedule") {
            this.showCustomFrequency = true;
        } else {
            this.showCustomFrequency = false;
        }
    }

    //custom field validations are handled in this method
    handleCustomValidations(currentStatus, nextSteps, techAction) {
        this.showErrors = false;
        this.customErrors = [];

        // if (nextSteps == this.caseRecord.data.fields.Next_Step__c.value) {
        //     this.customErrors.unshift("Next Step should be updated.");
        //     this.showErrors = true;
        // }

        // if (currentStatus == this.caseRecord.data.fields.Current_Status__c.value) {
        //     this.customErrors.unshift("Current Status should be updated.");
        //     this.showErrors = true;
        // }

        if (techAction == this.caseRecord.data.fields.SuccessResolutionCriteria__c.value) {
            this.customErrors.unshift("Next Technical Actions should be updated.");
            this.showErrors = true;
        }
    }

    //fires when record is saved successfully
    handleSuccess(event) {
        let message;

        if (this.isSupportManager) {
            this.approveOrRejectTransferRequest('Approve');
            message = 'Thanks for approving the transfer request. For more details, please reachout to #support-case-transfer.';
        } else {
            this.submitApproval();
            message = 'Thank you for submitting the transfer request. For more details, please reachout to #support-case-transfer.';
        }

        if (message && !this.showErrors) {
            const decisionEvent = new CustomEvent("submitted", { detail: message });
            this.dispatchEvent(decisionEvent);
        }
        //close spinner
        //this.showSpinner = false;
    }

    handleReject() {
        this.showRejectView = true;
    }

    //fires event when record is rejected
    handleRejectmessage(event) {
        let rejectDetails = event.detail;

        if (rejectDetails.iscancelled) {
            this.showRejectView = false;
            this.showSpinner = false;
        } else {
            let message;

            if (this.isSupportManager) {
                this.approveOrRejectTransferRequest('Reject', rejectDetails.message);
                message = 'Thank you. You have rejected this case transfer. For more details, please reachout to #support-case-transfer.';
            }

            if (message && !this.showErrors) {
                const decisionEvent = new CustomEvent("submitted", { detail: message });
                this.dispatchEvent(decisionEvent);
            }

            //close spinner
            this.showSpinner = false;
        }
    }

    //event fired from custom error component to close the cases.
    handleCloseCustomErrors() {
        this.showErrors = false;
    }

    //event to submit the case for transfer approval
    submitApproval() {
        apexSubmitCaseForTransferApproval({
            caseId: this.recordId,
            caseComment: this.caseCommentNumber
        })
            .then((result) => {
                this.error = undefined;
            })
            .catch((error) => {
                //error handling
                this.handleApexErrors(error);
            });
    }

    //handles manger's approval
    approveOrRejectTransferRequest(action, message) {
        apexApproveCaseTransferRequest({
            caseId: this.recordId,
            action: action,
            message: message
        })
            .then((result) => {
                this.error = undefined;
            })
            .catch((error) => {
                //error handling
                this.handleApexErrors(error);
            });
    }

    //error handling
    handleApexErrors(error) {
        if (Array.isArray(error.body)) {
            this.error = error.body.map(e => e.message).join(', ');
        } else if (typeof error.body.message === 'string') {
            this.error = error.body.message;
        } else if (error.body.pageErrors && error.body.pageErrors[0].message) {
            this.error = JSON.stringify(error.body.pageErrors[0].message);
        } else {
            this.error = 'Unexpected error occurred. Please contact your adminstrator.';
        }

        console.log('error : ' + this.error);
        this.customErrors.unshift(this.error);
        this.showErrors = true;
    }
}