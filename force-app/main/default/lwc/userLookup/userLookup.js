import { LightningElement, api } from 'lwc';
export default class UserLookup extends LightningElement {
    @api value;
    @api lookupObjectName;
    @api objectFieldApiName;
    @api recId;

    handleChange(event) {
        const userId = event.detail.value;
        this.doNotIncrement = true;
        this.dispatchEvent(new CustomEvent('userselect', {
            detail: { userId }
        }));
    }
}