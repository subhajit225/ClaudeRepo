import { LightningElement, api } from 'lwc';
export default class NewRepEventWrapper extends LightningElement {
@api
    sendEventWrap(value) {
        const customEvt = new CustomEvent('wrapevent', {
            detail: { value },
            bubbles: true,
            composed: true
        });

        this.dispatchEvent(customEvt);
    }
}