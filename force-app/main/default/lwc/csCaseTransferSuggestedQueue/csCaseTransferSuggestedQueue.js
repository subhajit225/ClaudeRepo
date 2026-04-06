import { LightningElement, api } from "lwc";

export default class CsCaseTransferSuggestedQueue extends LightningElement {
    @api recordId;
    showSpinner = false;

    //handles save operation when suggested queue is updated
    handleSubmit(event) {
        this.showSpinner = true;
    }

    //fires when record is saved successfully
    handleSuccess(event) {
        const decisionEvent = new CustomEvent("submitted", { detail: "Success" });
        this.dispatchEvent(decisionEvent);
        this.showSpinner = false;
    }
}