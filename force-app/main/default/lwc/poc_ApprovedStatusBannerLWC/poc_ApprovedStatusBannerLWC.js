import { LightningElement, track, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import POC_TYPE from '@salesforce/schema/POC__c.POC_Type__c';
import APPROVAL_STATUS from '@salesforce/schema/POC__c.Approval_Status__c';

export default class Poc_ApprovedStatusBannerLWC extends LightningElement {
    @api recordId;
    @track pocType = '';
    @track approvalStatus = '';
    @track showLabApprovalBanner = false;
    @wire(getRecord, { recordId: '$recordId', fields: [APPROVAL_STATUS, POC_TYPE]})
    pocRecordFetched({data, error}) {
        if(data) {
            this.pocType = data.fields.POC_Type__c.value;
            this.approvalStatus = data.fields.Approval_Status__c.value;
            if(this.pocType === 'Virtual Lab'){
                this.showLabApprovalBanner = (this.approvalStatus === 'Approved' || this.approvalStatus === 'Extension Approved') ? true: false;
            }
        }else{
            console.log('Error: ',error);
        }
    }
}