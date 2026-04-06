import { LightningElement, api, wire } from 'lwc';
import sendEmailController from '@salesforce/apex/SU_Knowbler.KCSPublishController.sendEmailController';
import feedRecord from '@salesforce/apex/SU_Knowbler.KCSPublishController.feedRecord';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class KnowblerSendLinkViaEmail extends LightningElement {
  toAddress = [];

  ccAddress = [];

  subject = '';

  singleFileToUpload = [];

  @api body;

  files = [];

  EmailValue;

  wantToUploadFile = false;

  noEmailError = false;

  invalidEmails = false;

  @api ishowmodal;

  @api caseid;

  @api articleid;

  @api flexipageregionwidth;

  closeModal() {
    this.dispatchEvent(new CustomEvent('closeemailmodal'));
  }

  toggleFileUpload() {
    this.wantToUploadFile = !this.wantToUploadFile;
  }

  handleUploadFinished(event) {
    const uploadedFiles = event.detail.files;
    this.files = [...this.files, ...uploadedFiles];

    for (let i = 0; i < this.files.length; i++) {
      this.singleFileToUpload.push(this.files[i].documentId);
    }

    this.wantToUploadFile = false;
  }

  handleRemove(event) {
    const { index } = event.target.dataset;
    this.files.splice(index, 1);
  }

  handleToAddressChange(event) {
    this.toAddress = event.detail.selectedValues;
  }

  handleCcAddressChange(event) {
    this.ccAddress = event.detail.selectedValues;
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
    } else if (emailAddressList.length > 0) {
      areEmailsValid = this.validateEmail(emailAddressList[0]);
    }

    return areEmailsValid;
  }

  validateEmail(email) {
    const res =
      /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()s[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;

    return res.test(String(email).toLowerCase());
  }

  handleReset() {
    this.toAddress = [];
    this.ccAddress = [];
    this.subject = '';
    this.body = '';
    this.files = [];
    this.template
      .querySelectorAll('c-knowbler-email-Input')
      .forEach((input) => input.reset());
  }

  handleBodyChange(event) {
    this.body = event.target.value;
  }

  handleSendEmail() {
    this.noEmailError = false;
    this.invalidEmails = false;

    if (![...this.toAddress, ...this.ccAddress].length > 0) {
      this.noEmailError = true;

      return;
    }

    const emailDetails = {
      toAddress: this.toAddress,
      ccAddress: this.ccAddress,
      subject: this.subject,
      body: this.body
    };

    sendEmailController({
      emailDetailStr: JSON.stringify(emailDetails),
      filestoupload: this.singleFileToUpload
    })
      .then(() => {
        this.createFeedRecord();
        const event = new ShowToastEvent({
          title: 'Email Sent',
          message: 'Email Sent',
          variant: 'success',
          mode: 'dismissable'
        });
        this.dispatchEvent(event);
      })
      .catch((error) => {
        console.error('Error in sendEmailController:', error);
      });

    this.ishowmodal = false;
  }

  createFeedRecord() {
    feedRecord({ caseId: this.caseid, body: this.body })
      .then((result) => {
        this.message = result;
        this.error = undefined;
        this.result = this.message;
      })
      .catch((error) => {
        this.error = error;
      });
  }
}