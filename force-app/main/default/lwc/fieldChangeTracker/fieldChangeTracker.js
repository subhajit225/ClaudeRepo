import { api, LightningElement, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class FieldChangeTracker extends LightningElement {
    @api recordId
    @api variant
    @api title
    @api message
    @api FieldApi
    @api anyMsg = ''
    @api url = ''
    @api urlMsg = ''
    fields = []
    oldRecord
    connectedCallback() {
        this.fields = [this.FieldApi];
    }
    @wire(getRecord, { recordId: '$recordId', fields: '$fields' })
    wiremethod({ data, error }) {
        if (data) {
            let oldValue = this.oldRecord == null ? null : getFieldValue(this.oldRecord, this.FieldApi);
            if (this.oldRecord != null && oldValue !== getFieldValue(data, this.FieldApi)) {
                const evt = new ShowToastEvent({
                    title: this.title,
                    message: this.message,
                    variant: this.variant,
                    messageData: [
                        this.anyMsg,
                        {
                            url: this.url,
                            label: this.urlMsg,
                        },
                    ],
                });
                this.dispatchEvent(evt);
            }
            this.oldRecord = data;
        }
    };
}