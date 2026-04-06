import { LightningElement,wire,api } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class DealDeskWarningOnOpp extends LightningElement {
    @api recordId;
    fields = ['Opportunity.StageName','Opportunity.Deal_Desk_Open_Cases__c']
    oldRecord

   /* connectedCallback() {
        this.fields = [this.FieldApi];
    } */
    @wire(getRecord, { recordId: '$recordId', fields: '$fields' })
    wiremethod({ data, error }) {
        if (data) {
            let oldStage = this.oldRecord == null ? null : getFieldValue(this.oldRecord, 'Opportunity.StageName');
            let newStage = data == null ? null : getFieldValue(data, 'Opportunity.StageName')
            let oldDDCases = this.oldRecord == null ? null : getFieldValue(this.oldRecord, 'Opportunity.Deal_Desk_Open_Cases__c');
            let newDDCases = data == null ? null : getFieldValue(data, 'Opportunity.Deal_Desk_Open_Cases__c');
            console.log('oldStage=> '+oldStage)
            console.log('newStage=> '+newStage)
            console.log('oldDDCases=> '+oldDDCases)
            console.log('newDDCases=> '+newDDCases)
            if (this.oldRecord != null && oldStage !== newStage && oldDDCases > 0 && 
            (newStage == '6 PO With Channel' || newStage == '7 Closed Won' || newStage == '7 Closed Lost' || newStage == '7 Closed Admin')) {
                const evt = new ShowToastEvent({
                    title: 'Warning',
                    message: 'You have open Deal Desk Cases on this Opportunity that are not Approved, Rejected or Closed. By moving this Opportunity to Stage 6 or Stage 7, you are going to close those Cases.',
                    variant: 'Warning',
                    mode: 'sticky'
                });
                this.dispatchEvent(evt);
            }
            this.oldRecord = data;
        }
        if(error){}
    };
}