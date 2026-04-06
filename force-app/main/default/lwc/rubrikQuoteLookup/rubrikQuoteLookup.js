import { LightningElement, track } from 'lwc';
import lookupQuote from '@salesforce/apex/RubrikQuoteLookupController.lookupQuote';

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export default class RubrikQuoteLookup extends LightningElement {
    @track quoteNumber = '';
    @track emailAddress = '';
    @track quoteError = '';
    @track emailError = '';
    @track serverError = '';
    @track isLoading = false;
    @track showSuccess = false;

    get showForm() {
        return !this.showSuccess;
    }

    get quoteFieldClass() {
        return `field-input${this.quoteError ? ' has-error' : ''}`;
    }

    get emailFieldClass() {
        return `field-input${this.emailError ? ' has-error' : ''}`;
    }

    handleQuoteChange(event) {
        this.quoteNumber = event.target.value.trim();
        if (this.quoteNumber) {
            this.quoteError = '';
        }
    }

    handleEmailChange(event) {
        this.emailAddress = event.target.value.trim();
        if (this.emailAddress) {
            this.emailError = '';
        }
    }

    validate() {
        let valid = true;
        this.quoteError = '';
        this.emailError = '';
        this.serverError = '';

        if (!this.quoteNumber) {
            this.quoteError = 'Please enter your quote number.';
            valid = false;
        }

        if (!this.emailAddress) {
            this.emailError = 'Please enter your email address.';
            valid = false;
        } else if (!EMAIL_REGEX.test(this.emailAddress)) {
            this.emailError = 'Please enter a valid email address.';
            valid = false;
        }

        return valid;
    }

    handleSubmit() {
        if (!this.validate()) return;

        this.isLoading = true;
        this.serverError = '';

        lookupQuote({ quoteNumber: this.quoteNumber, email: this.emailAddress })
            .then(result => {
                if (result && result.errorMessage) {
                    this.serverError = result.errorMessage;
                } else if (result && result.quoteUrl) {
                    this.showSuccess = true;
                    // Navigate after brief success display
                    setTimeout(() => {
                        window.location.href = result.quoteUrl;
                    }, 1500);
                } else {
                    this.serverError = 'No quote found matching the details provided. Please check and try again.';
                }
            })
            .catch(() => {
                this.serverError = 'Something went wrong. Please try again or contact support.';
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
}
