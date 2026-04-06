import { LightningElement, api } from 'lwc';

export default class Modal extends LightningElement {
    @api showModal = false;
    rejectMessage = '';

    handleClose() {
        const rejectMessage = new CustomEvent("rejected", { detail: {message: this.rejectMessage, iscancelled: true} });
        this.dispatchEvent(rejectMessage);
    }

    handleRejectMessageChange(event) {
        this.rejectMessage = event.target.value;
    }

    handleNotApprovedToHandover() {
        const rejectMessage = new CustomEvent("rejected", { detail: {message: this.rejectMessage, iscancelled: false} });
        this.dispatchEvent(rejectMessage);
    }
}