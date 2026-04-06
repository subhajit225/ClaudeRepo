import { LightningElement, api, wire } from 'lwc';
import labels from './labels';
import opportunityApproval from '@salesforce/apex/LCC_Credit_SDRISR_Opportunity_Controller.opportunityApproval';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';

export default class LCC_Credit_SDR_ISR_Opportunity_LWC extends NavigationMixin(LightningElement) {
    @api recordId;
    userId = USER_ID;
    meetingEvidenceLink = '';
    notes = '';
    _isCriteriaSatisfy = true;
    isCorrectProfile = true;
    displayMessage = '';
    isSpinner = false;
    labels = labels
    get isCriteriaSatisfy() {
        return (this._isCriteriaSatisfy && this.isCorrectProfile);
    }

    @wire(getRecord, { recordId: '$userId', fields: ['User.Profile.Name'] })
    userdetails({ data, error }) {
        if (data) {
            var profile = data?.fields?.Profile?.displayValue;
            const profilesArray = this.labels.Credit_SDR_Approval_Eligible_Profiles_comma_separated.replace(/(\r\n|\n|\r)/gm,"").split(",");
            if (profilesArray.includes(profile)) {
                this.isCorrectProfile = true;
            } else {
                this.isCorrectProfile = false;
                this.displayMessage = this.labels.Credit_SDR_Approval_Not_Eligible_Profile_Msg;
            }
        } else if (error) {
            console.log('error : ', error);
        } else {
            console.log('error : Unknown error');
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: ['Opportunity.Credit_SDR_ISR_Approval_Status__c'] })
    getdetaisl({ data, error }) {
        if (data) {
            var status = data.fields?.Credit_SDR_ISR_Approval_Status__c?.value;
            this._isCriteriaSatisfy = true;
            if (this.isCorrectProfile) {
                if (status == 'Pending') {
                    this._isCriteriaSatisfy = false;
                    this.displayMessage = this.labels.Credit_SDR_Pending_Approval_msg;
                } else if (status == 'Approved') {
                    this._isCriteriaSatisfy = false;
                    this.displayMessage = this.labels.Credit_SDR_Approved_Approval_msg;
                }
            }
        } else {
            console.log(':error : ', error);
            if (this.recordId) {                
                this._isCriteriaSatisfy = false;
                this.displayMessage ="Error while loading screen:" + JSON.stringify(error);
            }
        }
    }

    handleMeetingEvidenceLinkChange(event) {
        this.meetingEvidenceLink = event.target.value;
    }

    handleNotesChange(event) {
        this.notes = event.target.value;
    }
    validateForm() {

        var isvalid = true;
        var meetingEvidenceLinkInput = this.template.querySelector("lightning-input[data-recid=Meetingevidencelink]")
        this.meetingEvidenceLink = meetingEvidenceLinkInput?.value;
        if (!meetingEvidenceLinkInput.checkValidity()) {
            meetingEvidenceLinkInput.reportValidity();
            isvalid = false;
        }

        var notesInput = this.template.querySelector("lightning-input[data-recid=Notes]")
        this.notes = notesInput.value;
        if (!notesInput.checkValidity()) {
            notesInput.reportValidity();
            isvalid = false;
        }

        return isvalid;

    }
    sendForApproval() {
        this.isSpinner = true;
        const isvalid = this.validateForm();

        if (!isvalid) {
            this.isSpinner = false;
            return;
        }

        opportunityApproval({
            recId: this.recordId,
            meetEvdLink: this.meetingEvidenceLink,
            notes: this.notes
        })
            .then(result => {
                if (result === 'Approved') {
                    this.isSpinner = false;
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: this.recordId,
                            actionName: 'view',
                        },
                    });
                    this.close();
                } else {
                    this.isSpinner = false;
                    this._isCriteriaSatisfy = false;
                    this.displayMessage = result;
                }
            })
            .catch(error => {
                this.isSpinner = false;
                console.error('Error sending for approval: ', error);
            });
    }


    close() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

}