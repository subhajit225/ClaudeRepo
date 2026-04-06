import { LightningElement, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import CURRENTUSER_ID from '@salesforce/user/Id';
import TERMSANDCONDITIONS from '@salesforce/resourceUrl/SupportCommunityTermsAndConditions';
import ISTERMSANDCONDITIONSACCEPTED_FIELD from '@salesforce/schema/User.IsCustomerSupportTCAccepted__c';
import updateTermsAndConditons from '@salesforce/apex/CSCommunityTermsAndConditionsController.updateTermsAndConditions';

const FIELDS = [ISTERMSANDCONDITIONSACCEPTED_FIELD];

export default class RubrikSupportTermsAndConditions extends LightningElement {

    supportCommunityTermsAndContidions = TERMSANDCONDITIONS + '#view=FitH';
    showTermsAndConditionsAgreement = false;
    _termsandconditionsagreed = false;
    user;
    errorMessage;
    showError = false;
    checkBoxError = false;
    checkBoxErrorMsg = 'You must accept our terms & conditions to continue using this community!';


    @wire(getRecord, { recordId: CURRENTUSER_ID, fields: FIELDS })
    wiredRecord({ error, data }) {
        if (error) {
            let message = 'Unknown error';
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }

            this.showError = true;
            this.errorMessage = message;
        } else if (data) {
            this.user = data;
            this.showError = false;

            if (this.user.fields.IsCustomerSupportTCAccepted__c.value === false) {
                this.showTermsAndConditionsAgreement = true;
            }
        }
    }

    handleCheckBoxChange(event) {
        this.checkBoxError =! event.target.checked; 
        this._termsandconditionsagreed = event.target.checked;
    }

    handleFormSubmit() {
        if (this._termsandconditionsagreed) {
            updateTermsAndConditons({ currentUserId: CURRENTUSER_ID })
                .then((result) => {
                    this.showTermsAndConditionsAgreement = false;
                    this.showError = false;
                })
                .catch((error) => {
                    let message = 'Unknown error';
                    if (Array.isArray(error.body)) {
                        message = error.body.map(e => e.message).join(', ');
                    } else if (typeof error.body.message === 'string') {
                        message = error.body.message;
                    }

                    this.showError = true;
                    this.errorMessage = message;
                });
        } else {
            const allValidInputComponents = [
                ...this.template.querySelectorAll('lightning-input'),
            ].reduce((validSoFar, inputComponent) => {
                inputComponent.reportValidity();
                return validSoFar && inputComponent.checkValidity();
            }, true);
            this.checkBoxError = true;
        }
    }

}