import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getQuoteDetails from '@salesforce/apex/SendOvfEmailController.getQuoteDetails';
import sendOvfEmail from '@salesforce/apex/SendOvfEmailController.sendOvfEmail';

/**
 * @description Quick action component for sending Order Verification Form (OVF)
 *              emails from the SBQQ__Quote__c record page. Shows a preview of the
 *              recipient details and quote line items before sending.
 */
export default class SendOvfQuickAction extends LightningElement {
    _recordId;

    /**
     * @description Public property for the record ID. Uses a getter/setter pattern
     *              because lightning__RecordAction quick actions inject @api properties
     *              AFTER connectedCallback fires. The setter triggers data loading
     *              as soon as the platform provides the recordId.
     */
    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        if (value) {
            this.loadQuoteDetails();
        }
    }

    /** Quote preview data */
    quoteNumber = '';
    contactName = '';
    contactEmail = '';
    lineItems = [];

    /** Additional recipients input */
    additionalEmails = '';
    additionalEmailsError = '';

    /** UI state flags */
    isLoading = true;
    isSending = false;
    hasError = false;
    errorMessage = '';

    /**
     * @description Computed property indicating whether the preview screen should be shown.
     * @returns {boolean} True when not loading and no error has occurred
     */
    get showPreview() {
        return !this.isLoading && !this.hasError;
    }

    /**
     * @description Computed property indicating whether there are line items to display.
     * @returns {boolean} True when line items array is non-empty
     */
    get hasLineItems() {
        return this.lineItems && this.lineItems.length > 0;
    }

    /**
     * @description Computed property returning the count of line items.
     * @returns {number} Number of line items
     */
    get lineItemCount() {
        return this.lineItems ? this.lineItems.length : 0;
    }

    /**
     * @description Fetches quote details from the Apex controller and populates
     *              the preview data. Handles errors by setting the error state.
     */
    async loadQuoteDetails() {
        this.isLoading = true;
        this.hasError = false;

        try {
            const result = await getQuoteDetails({ quoteId: this.recordId });

            this.quoteNumber = result.quoteNumber;
            this.contactName = result.contactName;
            this.contactEmail = result.contactEmail;

            this.lineItems = (result.lineItems || []).map((item) => ({
                id: item.id,
                productName: item.productName || '',
                quantity: item.quantity != null ? item.quantity : 0,
                listPrice: item.listPrice,
                netTotal: item.netTotal,
                formattedListPrice: this.formatCurrency(item.listPrice),
                formattedNetTotal: this.formatCurrency(item.netTotal)
            }));
        } catch (error) {
            this.hasError = true;
            this.errorMessage = this.extractErrorMessage(error);
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * @description Handles changes to the Additional Recipients input field.
     */
    handleAdditionalEmailsChange(event) {
        this.additionalEmails = event.detail.value;
        this.additionalEmailsError = '';
    }

    /**
     * @description Validates the additional emails input. Each comma-separated
     *              token must match a basic email format. Empty input is valid.
     * @returns {boolean} True if all tokens are valid emails or the input is empty
     */
    validateAdditionalEmails() {
        const raw = (this.additionalEmails || '').trim();
        if (!raw) {
            this.additionalEmailsError = '';
            return true;
        }

        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        const tokens = raw.split(',');
        const invalid = [];

        for (const token of tokens) {
            const trimmed = token.trim();
            if (trimmed && !emailRegex.test(trimmed)) {
                invalid.push(trimmed);
            }
        }

        if (invalid.length > 0) {
            this.additionalEmailsError =
                'Invalid email address' +
                (invalid.length > 1 ? 'es' : '') +
                ': ' +
                invalid.join(', ');
            return false;
        }

        this.additionalEmailsError = '';
        return true;
    }

    /**
     * @description Handles the Send Email button click. Validates additional
     *              recipients, then calls the Apex method to send the OVF email,
     *              displays a toast, and closes the action.
     */
    async handleSend() {
        if (!this.validateAdditionalEmails()) {
            return;
        }

        // Build clean array of additional email addresses
        const additionalEmailsList = (this.additionalEmails || '')
            .split(',')
            .map((e) => e.trim())
            .filter((e) => e.length > 0);

        this.isSending = true;

        try {
            await sendOvfEmail({
                quoteId: this.recordId,
                additionalEmails: additionalEmailsList
            });

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: `OVF email sent successfully to ${this.contactEmail}`,
                    variant: 'success'
                })
            );

            this.closeAction();
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error Sending Email',
                    message: this.extractErrorMessage(error),
                    variant: 'error',
                    mode: 'sticky'
                })
            );
        } finally {
            this.isSending = false;
        }
    }

    /**
     * @description Handles the Cancel button click. Closes the quick action panel.
     */
    handleCancel() {
        this.closeAction();
    }

    /**
     * @description Dispatches the CloseActionScreenEvent to close the quick action modal.
     */
    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    /**
     * @description Formats a numeric value as a USD currency string for display.
     * @param {number} value - The numeric value to format
     * @returns {string} Formatted currency string or dash if null/undefined
     */
    formatCurrency(value) {
        if (value == null) {
            return '-';
        }
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        }).format(value);
    }

    /**
     * @description Extracts a user-friendly error message from various error shapes
     *              returned by Apex imperative calls.
     * @param {Object} error - The error object from a failed Apex call
     * @returns {string} Extracted error message
     */
    extractErrorMessage(error) {
        if (!error) {
            return 'An unknown error occurred.';
        }
        if (error.body && error.body.message) {
            return error.body.message;
        }
        if (error.message) {
            return error.message;
        }
        if (typeof error === 'string') {
            return error;
        }
        return 'An unexpected error occurred. Please try again.';
    }
}
