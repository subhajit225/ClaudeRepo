import { LightningElement, api, wire } from 'lwc';
import sendEmailController from "@salesforce/apex/su_vf_console.SUVFConsoleController.sendEmailController";
import getCaseRecord from "@salesforce/apex/su_vf_console.SUVFConsoleController.getCaseRecord";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { fireEvent } from 'c/supubsub';

export default class SU_SendAsEmail extends LightningElement {
    toEmail = [];
    ccEmail = [];
    @api fromEmail;
    subject = "";
    singleFileToUpload = [];
    body;
    files = [];
    @api eventCode;
    wantToUploadFile = false;
    noEmailError = false;
    invalidEmails = false;
    isShowModal = false;
    @api recordId;
    @api title;
    @api idd;
    @api objectname;
    @api sourcename;
    emailBody;
    @api 
    set emailHref(value){
        this.emailBody = "Hi,\n Please find below the link "+value;
    }
    get emailHref(){ return this.emailBody;}

    @wire(getCaseRecord, {recordId: '$recordId'})
    wiredRecord({ error, data }) {
        if (data) {
            this.toEmail = data.ContactEmail ? [data.ContactEmail] : [];
        } else if (error) {
            console.log('Something went wrong:', error);
        }
    }

    closeModal() {
        this.isShowModal = false;
        fireEvent(null, "closeSendEmailBlock"+this.eventCode, '');
    }

    toggleFileUpload() {
        this.wantToUploadFile = !this.wantToUploadFile;
    }

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        this.files = [...this.files, ...uploadedFiles];
        for(let i=0; i<this.files.length; i++){
            this.singleFileToUpload.push(this.files[i].documentId);
        }   
        this.wantToUploadFile = false;
    }

    handleRemove(event) {
        const index = event.target.dataset.index;
        this.files.splice(index, 1);
    }

    handleToEmailChange(event) {
        if (event)
            this.toEmail = event.detail.selectedValues;
    }

    handleCcEmailChange(event) {
        this.ccEmail = event.detail.selectedValues;
    }

    handleSubjectChange(event) {
        this.subject = event.target.value;
    }

    validateEmails(emailAddressList) {
        let areEmailsValid;
        if (emailAddressList.length > 1) {
            areEmailsValid = emailAddressList.reduce((accumulator, next) => {
                const isValid = this.validateEmail(next);
                return accumulator && isValid;
            });
        }
        else if (emailAddressList.length > 0) {
            areEmailsValid = this.validateEmail(emailAddressList[0]);
        }
        return areEmailsValid;
    }

    validateEmail(email) {
        console.log("In VE");
        const res = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        console.log("res", res);
        return res.test(String(email).toLowerCase());
    }

    handleReset() {
        this.toEmail = [];
        this.ccEmail = [];
        this.subject = "";
        this.emailBody = "";
        this.files = [];
        this.template.querySelectorAll("c-email-input").forEach((input) => input.reset());
    }

    handleBodyChange(event) {
        this.emailBody = event.target.value;
    }

    handleSendEmail() {
        var sendData = { "id": this.idd, "objName": this.objectname, "ptitle": this.title,"sourceName":this.sourcename };
        fireEvent(null, "caseCommentEmailEvent" + this.eventCode, sendData);
        this.noEmailError = false;
        this.invalidEmails = false;
       
        if (![...this.toEmail, ...this.ccEmail].length > 0) {
            this.noEmailError = true;
            return;
        }

        if (!this.validateEmails([...this.toEmail, ...this.ccEmail])) {
            this.invalidEmails = true;
            return;
        }

        let emailDetails = {
            toEmail: this.toEmail,
            ccEmail: this.ccEmail,
            subject: this.subject,
            body: this.emailBody
        };

        sendEmailController({ emailDetailStr: JSON.stringify(emailDetails), filestoupload: this.singleFileToUpload })
            .then(() => {
                const event = new ShowToastEvent({
                    title: 'Email Sent',
                    message: 'Email Sent',
                    variant: 'success',
                    mode: 'dismissable'
                });
                this.dispatchEvent(event);
            })
            .catch((error) => {
                console.error("Error in sendEmailController:", error);
            }).finally(()=>{
                fireEvent(null, "closeSendEmailBlock"+this.eventCode, '');
            })
        this.isShowModal = false;      
    }
}