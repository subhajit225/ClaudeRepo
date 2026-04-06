import { LightningElement, api } from 'lwc';

//Commented as a part of PRIT25-380 and 404
/*
import { refreshApex } from '@salesforce/apex';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
*/

export default class PsEscalationButton extends LightningElement {
    @api dealRegRec;
    @api recordId;
    isDisabled = false;
    showPSEsclationForm = false;
    //psEscCount;
    //Commented as a part of PRIT25-380 and 404
    /*@wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'DR_PS_Escalations__r',
        where: '{ Status__c: { in: ["Submitted", "More Info Required", "Under Review"] }}',
    })
    listRecordInfo(wiredResult) {
        this.result = wiredResult;
        console.log(JSON.stringify(wiredResult));
        if (this.result.data) {
            this.psEscCount = this.result.data.count;
            let drStatus = this.dealRegRec.fields.Deal_Registration_Status__c.value;
            let approvalDate = this.dealRegRec.fields.DR_Approved_Date__c ? this.dealRegRec.fields.DR_Approved_Date__c.value : "";
            console.log(this.psEscCount,drStatus,approvalDate);
            if(this.psEscCount > 0 || drStatus !== 'Approved' || (approvalDate && this.getNumberOfDays(approvalDate) > 90)){
                this.isDisabled = true;
            }
        } else if (this.result.error) {
            console.log(JSON.stringify(error));
        }
    }

    getNumberOfDays(start) {
        if(start){
            const date1 = new Date(start);
            const date2 = new Date();
            // One day in milliseconds
            const oneDay = 1000 * 60 * 60 * 24;
            // Calculating the time difference between two dates
            const diffInTime = date2.getTime() - date1.getTime();
            // Calculating the no. of days between two dates
            const diffInDays = Math.round(diffInTime / oneDay);
            return diffInDays;
        }
    }*/

    //PRIT25-446 : Disable the button if DE sttaus is not Approved
    //PRIT26-10 : Disable the button if DR Rec Type is Engagement
    connectedCallback(){
        if(this.dealRegRec && this.dealRegRec.fields.Deal_Registration_Status__c.value != 'Approved' || this.dealRegRec.recordTypeInfo.name == 'Engagement'){
            this.isDisabled = true;
        }
    }

    openModal(){
        this.showPSEsclationForm = true;
    }

    closeModal(){
        this.showPSEsclationForm = false;
        //refreshApex(this.result);
    }

    handleKeyDown(event){
        if(event.code == 'Escape') {
            this.closeModal();
            event.preventDefault();
            event.stopImmediatePropagation();
        }
    }

    handleStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            this.closeModal();
        }
    }

    get inputVariables() {
        return [
            {
                name: 'DealRegRec',
                type: 'String',
                value: this.recordId
            }
        ];
    }
}