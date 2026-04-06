import { LightningElement, wire, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadStyle } from 'lightning/platformResourceLoader';
import { CloseActionScreenEvent } from 'lightning/actions';
import CVEEngagementCSS from '@salesforce/resourceUrl/CVEEngagementCSS';
import maxOppCount from '@salesforce/label/c.CXO_Max_Contact_Opportunity_Count'; 
import maxOppCountExceeded from '@salesforce/label/c.CXO_Maximum_Opportunity_Exceeded';
import cxoFormTitle from '@salesforce/label/c.CXO_Header_Title';
import cxoFormText from '@salesforce/label/c.CXO_Header_Text';
import getData from '@salesforce/apex/CXORequestForm.getFormData';
import createCveEngagement from '@salesforce/apex/CXORequestForm.createCveEngagementRecord';
import { NavigationMixin } from 'lightning/navigation';

export default class CxoRequestForm extends NavigationMixin(LightningElement) {
    @api recordId;
    toastMessage;
    isLoading = false;
    cveEngagementType;
    valueEconomicsScope;
    whysPresented;
    archWorkshopExecuted;
    willTheEbSponsorThis;
    orgChartOrAccPlanningDoc;
    @track cveEngagementObj = {};
    @track cveMultiSelectValueObj = {};
    selectedCveEngagementTypeVal;
    selectedValueEconomicsScopeVal;

    @track selectedRecords = [];
    @track selectedRecordsLength;    

    formTitle = cxoFormTitle;
    formText = cxoFormText;

    connectedCallback(){
        this.getFormData();
        loadStyle(this, CVEEngagementCSS);
    }

    getFormData(){
        this.isLoading = false;
        getData({})
        .then(response => {
            if (response.Success) {
                let data = response.Data;
                this.cveEngagementType = data.fieldToOptionWrapperLstMap['CVE_Engagement_Type__c'];
                this.valueEconomicsScope = data.fieldToOptionWrapperLstMap['Value_Economics_Scope__c'];
                this.whysPresented = data.fieldToOptionWrapperLstMap['X3_Why_s_Presented__c'];
                this.archWorkshopExecuted = data.fieldToOptionWrapperLstMap['Architectural_Workshop_Executed__c'];
                this.willTheEbSponsorThis = data.fieldToOptionWrapperLstMap['Will_the_EB_sponsor_this__c'];
                this.orgChartOrAccPlanningDoc = data.fieldToOptionWrapperLstMap['Org_Chart_or_Account_Planning_Document__c'];
                this.isLoading = true;
            }else{
                this.toastMessage = response.Message;
                this.showError();
                this.isLoading = true;
            }
        })
        .catch(error => {
            if (Array.isArray(error.body)) {
                this.toastMessage = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                this.toastMessage = error.body.message;
            }
            this.showError();
        });
    }

    handleInputChange(event) {
        if(event.target.tagName == 'LIGHTNING-DUAL-LISTBOX'){
            if(event.target.name == 'CVE_Engagement_Type__c'){
                this.selectedCveEngagementTypeVal = event.target.value;
            } else if(event.target.name == 'Value_Economics_Scope__c'){
                this.selectedValueEconomicsScopeVal = event.target.value;
            }
        } else {
            this.cveEngagementObj[event.target.name] = event.target.value;
        }        
    }

    handleSubmit(){        
        this.cveEngagementObj['Account__c'] = this.recordId;
        this.isLoading = false;
        this.template.querySelectorAll('lightning-input').forEach(element => {
            element.reportValidity();
        });

        this.template.querySelectorAll('lightning-combobox').forEach(element => {
            element.reportValidity();
        });

        let isError = this.template.querySelector(".slds-has-error");
        if(isError == undefined || isError == null || isError.length == 0) {    
            if(this.selectedRecordsLength == null || this.selectedRecordsLength == 0){
                this.toastMessage = 'Please select at least 1 Opportunity.';
                this.showError();
                this.isLoading = true;
            } else if(this.selectedRecordsLength > maxOppCount){
                this.toastMessage = maxOppCountExceeded;
                this.showError();
                this.isLoading = true;
            } else {
                this.submitFormDetails();
            }            
        } else {
            this.toastMessage = 'Please fill in required fields.';
            this.showError();
            this.isLoading = true;
        }
    }

    submitFormDetails() {
        createCveEngagement({
            cveEngagementJsonStr : JSON.stringify(this.cveEngagementObj),
            selectedOppsStr : JSON.stringify(this.selectedRecords),
            cveEngagementTypeVal : this.selectedCveEngagementTypeVal,
            valueEconomicsScopeVal : this.selectedValueEconomicsScopeVal
        })
        .then(response => {
            if (response.Success) {
                this.toastMessage = response.Message;                
                this.showSuccess();
                this.navigateToRecord(response.Data.Id);
            }else{
                this.toastMessage = response.Message;
                this.showError();
            }
            this.isLoading = true;
        })
        .catch(error => {
            if (Array.isArray(error.body)) {
                this.toastMessage = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                this.toastMessage = error.body.message;
            }
            this.showError();
            this.isLoading = true; 
        });
    }

    handleCancel(){
         this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleselectedOppRecords(event) {
        this.selectedRecords = [...event.detail.selRecords]
        this.selectedRecordsLength = this.selectedRecords.length;

        if(this.selectedRecordsLength > maxOppCount){
            this.toastMessage = maxOppCountExceeded;
            this.showError();
            this.isLoading = true;
        } 
    }

    // show success toast message
    showSuccess(){
        const evt = new ShowToastEvent({
            title: 'Success',
            message: this.toastMessage,
            variant: 'success'
        });
        this.dispatchEvent(evt);
    }

    showError(){
        const evt = new ShowToastEvent({
            title: 'Error',
            message: this.toastMessage,
            variant: 'error'
        });
        this.dispatchEvent(evt);
    }

    navigateToRecord(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    } 
}