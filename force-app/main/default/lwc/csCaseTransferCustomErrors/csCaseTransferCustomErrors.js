import { LightningElement, api } from 'lwc';

export default class CsCaseTransferCustomErrors extends LightningElement {
    @api customErrors;
    @api showErrors = false;

    //fires event when close button is clicked
    handleClose() {
        const closeEvent = new CustomEvent("closeerrors");
        this.dispatchEvent(closeEvent);
    }
}