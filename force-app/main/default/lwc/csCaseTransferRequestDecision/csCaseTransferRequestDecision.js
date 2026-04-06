import { LightningElement, wire, api } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import Transfer_Reason from '@salesforce/schema/Case.CaseTransferType__c';
import apexIsSupportManager from '@salesforce/apex/CaseTransferApprovalRequest.isSupportManager';

export default class CsCaseTransferRequestDecision extends LightningElement {
    @api recordId;
    @api decision;
    value = 'Critical Escalation';
    disabled = true;
    warmTransferFlag = false;
    error;
    isSupportManager = false;
    successMessage;
    isSuccess = false;
    @api transferStatus;
    @api showSubmittedScreens;
    @api showTransferScreens;
    @api customerCommunicationFrequencyValue;

    
    @wire(getPicklistValues,
        {
            recordTypeId: '0126f0000014VBQ', 
            fieldApiName: Transfer_Reason
        }
    )
    picklistValues;
    
    //options to select case transfer reason
    get options() {
        return [
            { label: 'Case requires continued work (Further troubleshooting / Scheduled Upgrades / Customer to be contacted during their tz etc)', value: 'TransferForm' },
            { label: 'Monitor Inbounds (Data Recovery / Restores etc)', value: 'CaseComment' },
        ];
    }

    //to get case updated screen
    get isCaseUpdateScreen() {
        if (!this.isSupportManager && !this.isSuccess) {
            return true;
        }
        return false;
    }

    get showManagerForm() {
        if (this.isSupportManager && !this.isSuccess) {
            return true;
        }
        return false;
    }

    //handles show/hide warm transfer toggle
    get showWarmTransfer() {
        if (this.value && this.value == 'TransferForm') {
            return true;
        }

        return false;
    }

    //when the case transfer reason is selected
    handleOnChange(event) {
        if (!event.target.value) {
            this.disabled = true;
        } else if (this.transferStatus != 'Submitted') {
            this.value = event.target.value;
            this.disabled = false;
        }
    }

     handleReqChange(event) {
        this.value = event.detail.value;
        //this.decision = event.detail.value;
    }
    
    //warm case toggle is changed
    handleToggleChange(event) {
        this.warmTransferFlag = event.target.checked;
    }

    //get if logged in user is manager
    @wire(apexIsSupportManager, { isSubmitted: '$showSubmittedScreens' })
    getIsSupportManager({ error, data }) {
        if (data) {
            this.isSupportManager = data;
            //this.value = this.decision && this.isSupportManager ? this.decision : 'TransferForm';
            this.error = undefined;
        } else if (error) {
            this.error = error;
        }
    }

    //handles event and shows success screen
    returnSuccessScreen(event) {
        this.isSuccess = true;
        this.isSupportManager = false;
        this.successMessage = event.detail;
    }

    //handles event and shows success screen for update
    returnUpdateSuccessScreen() {
        this.isSuccess = true;
        this.successMessage = 'Case is successfully updated. For more details, please reachout to #support-case-transfer.';
    }
}