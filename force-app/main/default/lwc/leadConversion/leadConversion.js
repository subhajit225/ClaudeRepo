import { LightningElement, track, api, wire } from 'lwc';
import startRequest from '@salesforce/apexContinuation/LeadConversionController.startRequest';
import createORsetAccount from '@salesforce/apex/LeadConversionController.createORsetAccount';
import postAccountConvertLead from '@salesforce/apex/LeadConversionController.postAccountConvertLead';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import Id from '@salesforce/user/Id';
import ProfileName from '@salesforce/schema/User.Profile.Name';
import {getRecord} from 'lightning/uiRecordApi';

export default class LeadConversion extends NavigationMixin(LightningElement) {
    @api leadId;
    @track showLoader = false;
    @track disableConvertButton = false;
    @track disableCancelButton = false;
    @track accountsModal = false;
    @track accountsModalSpinner = false;
    @track potentialAccMatch = [];
    @track exactAccMatch = [];
    @track ldSource = {};

    @track currentUserProfileName;

    //params from UI
    @track sendEmailToOwner;
    @track dontCreateOpp;
    @track oppName;
    @track oppAmount;
    @track accountName;
    @track selectedLeadStatus;
    @track selectedrowIndex;
    @track accountOwnerId;
    @track searchType;
    @track result = {
        isError : false,
        potentialAccMatch : [],
        exactAccMatch : []
    };

    @wire(getRecord, { recordId: Id, fields: [ProfileName]}) 
    currentUserInfo({error, data}) {
        if (data) {
            this.currentUserProfileName = data.fields.Profile.value.fields.Name.value;
        } else if (error) {
            console.log('ERrror::', JSON.stringify(error));
            this.error = error ;
        }
    }

    get checkCurrentUserProfile(){
        let profileList = ['Rubrik Light Administrator','System Administrator','Sales Operations'];
        if(this.title_2 == 'Create New Account' && !profileList.includes(this.currentUserProfileName)){
            return false;
        }else{
            return true;
        }
    }

    get checkTitleCheck(){
        let profileList = ['Rubrik Light Administrator','System Administrator','Sales Operations'];
        if(this.title_2 != 'Create New Account' && !profileList.includes(this.currentUserProfileName)){
            return true;
        }
    }

    get accountMessage(){
        return 'Please contact Sales Data Ops ( salesdataops@rubrik.com ) for Account creation';
    }

    get convertedStatusOptions(){
        return [
            { label: '- None -', value: '' },
            { label: 'Open', value: 'Open' },
            { label: 'Meeting Set', value: 'Meeting Set' },
            { label: 'Working', value: 'Working' },
            { label: 'Nurture', value: 'Nurture' }
        ];
    }
    get showTable_1(){
        return this.result.potentialAccMatch.length > 0 ? true : false;
    }
    get showTable_2(){
        return this.result.exactAccMatch.length > 0 ? true : false;
    }
    get title_2(){
        if(this.result.exactAccMatch.length == 1)
            if(this.result.exactAccMatch[0].newAccount == 'Y' || this.result.exactAccMatch[0].newAccount == 'y')
                return 'Create New Account';
            else
                return 'Existing Account';        
        return 'Existing Account';
    }
    get showAdditionalColumnsInTable_2(){
        if(this.result.exactAccMatch.length == 1)
            if(this.result.exactAccMatch[0].newAccount == 'Y' || this.result.exactAccMatch[0].newAccount == 'y')
                return false;
            else
                return true;        
        return true;
    }
    connectedCallback() {                
        this.showLoader = true;
        startRequest({
            'leadId' : this.leadId
        }).then(result => {            
            console.log('result..!', result);
            this.showLoader = false;
            this.potentialAccMatch = result.potentialAccMatch;
            this.exactAccMatch = result.exactAccMatch;
            this.searchType = result.searchType;
            for(var i = 0; i < this.potentialAccMatch.length; i++){
                this.potentialAccMatch[i].idxVal = i+'-pm';
            }
            for(var i = 0; i < this.exactAccMatch.length; i++){
                this.exactAccMatch[i].idxVal = i+'-em';
            }
            this.oppName = result.ldSource.Company+'-';
            this.ldSource = result.ldSource;
            var stCallback = function(){
                this.template.querySelector('c-custom-look-up-l-w-c').populateValue(this.ldSource.Owner.Name);
            };
            setTimeout(stCallback.bind(this), 2000);
            this.accountOwnerId = this.ldSource.OwnerId;
            this.result = result;
            if(result.isError){
                this.showToast('', result.errMsg, 'error', 'sticky');
            }
        }).catch(error => {
            console.log('error..!', error);
            this.showLoader = false;
            this.showToast('', error.body.message, 'error', 'pester');
        });
    }
    handleChange(event){        
        if(event.target.name == 'Account Owner'){
            this.accountOwnerId = event.detail.Id;            
        } else if(event.target.name == 'Send Email to the Owner'){
            this.sendEmailToOwner = event.target.checked;
        } else if(event.target.name == 'Account Name'){
            
        } else if(event.target.name == 'Opportunity Name'){
            this.oppName = event.target.value;
        } else if(event.target.name == 'Opportunity Amount'){
            this.oppAmount = event.target.value;
        } else if(event.target.name == 'Do Not Create Opportunity'){
            this.dontCreateOpp = event.target.checked;
        } else if(event.target.name == 'Converted Status'){
            this.selectedLeadStatus = event.target.value;
        } else if(event.target.name == 'account'){
            this.selectedrowIndex = event.target.value;
            var idx_splits = this.selectedrowIndex.split('-');
            if(idx_splits[1] == 'em')
                this.accountName = this.exactAccMatch[parseInt(idx_splits[0])].accountName;
            else if(idx_splits[1] == 'pm')
                this.accountName = this.potentialAccMatch[parseInt(idx_splits[0])].accountName;
        }
    }
    searchAccountNames(event){
        this.accountsModal = true;
    }
    closeAccountsModal(event){
        this.accountsModal = false;
    }
    selectAccount(event){
        this.accountsModal = false;
    }
    isInputValid() {
        let isValid = true;
        let inputFields = this.template.querySelectorAll('.required-field');
        inputFields.forEach(inputField => {
            if(!inputField.checkValidity()) {
                inputField.reportValidity();
                isValid = false;
            }
        });
        return isValid;
    }
    validate(){
        this.oppAmount = this.oppAmount ? this.oppAmount.trim() : this.oppAmount;

        if(this.oppAmount)
        {
            var rx = new RegExp(/^\d*\.?\d*$/);
            if(!rx.test(this.oppAmount)){
                return 'Opportunity Amount: Invalid Currency.'
            }

            if(this.oppAmount.length > 16){
                return 'Opportunity Amount: Too long.'
            }
        }
        
        return null;
    }
    handleConvert(event){
        var isValid = this.isInputValid();
        if(!isValid){
            this.showToast('', 'Required fields missing.', 'error', 'pester');
            return;
        }

        var msg = this.validate();
        if(msg != null){
            this.showToast('', msg, 'error', 'pester');
            return;
        }

        this.disableConvertButton = true;
        this.disableCancelButton = true;
        createORsetAccount({
            'exactAccMatchPayload' : JSON.stringify(this.exactAccMatch),
            'potentialAccMatchPayload' : JSON.stringify(this.potentialAccMatch),
            'selectedrowIndex' : this.selectedrowIndex,
            'searchType' : this.searchType,
            'leadId' : this.leadId,
            'sendEmailToOwner' : this.sendEmailToOwner,
            'dontCreateOpp' : this.dontCreateOpp,
            'oppName' : this.oppName,
            'oppAmount' : this.oppAmount,
            'selectedLeadStatus' : this.selectedLeadStatus,
            'accountOwnerId' : this.accountOwnerId
        }).then(conversionResult => {
            console.log('conversionResult..!', conversionResult);
            this.disableConvertButton = false;
            this.disableCancelButton = false;
            
            this.disableConvertButton = true;
            this.disableCancelButton = true;
            postAccountConvertLead({
                'exactAccMatchPayload' : JSON.stringify(this.exactAccMatch),
                'selectedrowIndex' : this.selectedrowIndex,
                'searchType' : this.searchType,
                'leadConvertErrMsg' : '',
                'convertedAccountId' : conversionResult.convertedAccountId,
                'selectedAccountId' : conversionResult.selectedAccountId
            }).then(postConversionResult => {         
                console.log('postConversionResult..!', postConversionResult);       
                this.disableConvertButton = false;
                this.disableCancelButton = false;
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: conversionResult.convertedAccountId,
                        objectApiName: 'Account',
                        actionName: 'view'
                    }
                });
            }).catch(error => {
                console.log('error..!', error);
                this.disableConvertButton = false;
                this.disableCancelButton = false;
                this.showToast('', error.body.message, 'error', 'pester');
            });            
        }).catch(error => {            
            console.log('error..!', error);
            this.disableConvertButton = false;
            this.disableCancelButton = false;
            this.showToast('', error.body.message, 'error', 'pester');

        });
    }
    handleCancel(event){
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.leadId,
                objectApiName: 'Lead',
                actionName: 'view'
            }
        });
    }
    showToast(title, message, variant, mode) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(event);
    }
}