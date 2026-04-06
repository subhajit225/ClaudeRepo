import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class InternalNotesLwc extends LightningElement {
    @api recordId; // Automatically injected on Case record page
    @api fieldApiName = 'Internal_Notes__c';
    @track isCollapsed = false;

    isEditing = false;
    isLoading = false;

    handleEdit() {
        this.isEditing = true;
    }

    handleCancel() {
        this.isEditing = false;
    }

    handleSubmit() {
        this.isLoading = true;
    }

    handleSuccess() {
        this.isLoading = false;
        this.isEditing = false;
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Saved',
                message: 'Internal notes updated successfully.',
                variant: 'success'
            })
        );
    }

    toggleSectionHeader() {
        this.isCollapsed = !this.isCollapsed;
    }

    handleError(event) {
        this.isLoading = false;
        const message = event?.detail?.message || 'An unexpected error occurred while saving.';
        this.dispatchEvent(
            new ShowToastEvent({ title: 'Error', message, variant: 'error' })
        );
    }
}