import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class RiskProfileCustomApprovalProcesssLWC extends LightningElement {
    @api recordId;
    @track showRejectedComment = false;

    handleValidationChange(event) {
        const selectedValue = event.detail.value;
        this.showRejectedComment = selectedValue === 'Rejected';
    }

    handleSuccess() {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Risk Profile updated successfully',
                variant: 'success'
            })
        );
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}