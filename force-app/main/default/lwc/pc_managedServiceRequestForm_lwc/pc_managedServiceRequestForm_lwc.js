import { LightningElement, track, wire } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';
import saveEngagementDealRegistration from '@salesforce/apex/PC_PortalNavigationApexController.saveEngagementDealRegistration';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {NavigationMixin} from "lightning/navigation";
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValuesByRecordType } from "lightning/uiObjectInfoApi";
import DEALREGISTRATION_OBJECT from "@salesforce/schema/Deal_Registration__c";
//FIELDS
import Company_Name_Field from '@salesforce/schema/Deal_Registration__c.Company_Name__c';
import First_Name_Field from '@salesforce/schema/Deal_Registration__c.FirstName__c';
import Last_Name_Field from '@salesforce/schema/Deal_Registration__c.LastName__c';
import Email_Field from '@salesforce/schema/Deal_Registration__c.Email__c';
import Engaged_With_Rubrik_Field from '@salesforce/schema/Deal_Registration__c.Engaged_with_Rubrik__c';
import Source_Opportunity_Field from '@salesforce/schema/Deal_Registration__c.Source_of_the_Opportunity__c';
import Account_Field from '@salesforce/schema/Deal_Registration__c.Account__c';
import Amount_Of_Data_Field from '@salesforce/schema/Deal_Registration__c.Number_of_protected_machines__c';
import Customer_Budget_Field from '@salesforce/schema/Deal_Registration__c.Budget__c';
import Timeframe_Field from '@salesforce/schema/Deal_Registration__c.Purchase_Timeframe__c';
import Customer_Needs_Field from '@salesforce/schema/Deal_Registration__c.Customer_Needs__c';
import Scope_Of_Opportunity_Field from '@salesforce/schema/Deal_Registration__c.Scope_of_Opportunity__c';
import Scope_Of_Opportunity_Additional_Details_Field from '@salesforce/schema/Deal_Registration__c.Scope_of_Opportunity_Additional_Details__c';
import Utility_Shared_Licensing_Field from '@salesforce/schema/Deal_Registration__c.Utility_Shared_Licensing__c';
import Utility_Shared_Licensing_Why_Field from '@salesforce/schema/Deal_Registration__c.Utility_Shared_Licensing_Why__c';
import PO_Number_Field from '@salesforce/schema/Deal_Registration__c.PO_Number__c';
export default class Pc_managedServiceRequestForm_lwc extends NavigationMixin(LightningElement){

    fieldNames = { 
        firstName : First_Name_Field.fieldApiName,
        lastName : Last_Name_Field.fieldApiName,
        email : Email_Field.fieldApiName,
        engagedWithRubrik : Engaged_With_Rubrik_Field.fieldApiName,
        sourceOfOpportunity : Source_Opportunity_Field.fieldApiName,
        amountOfData : Amount_Of_Data_Field.fieldApiName,
        customerBudget : Customer_Budget_Field.fieldApiName,
        timeframe : Timeframe_Field.fieldApiName,
        customerNeeds : Customer_Needs_Field.fieldApiName,
        scopeOfOpportunity : Scope_Of_Opportunity_Field.fieldApiName,
        scopeOfOpportunityAdditionalDetails : Scope_Of_Opportunity_Additional_Details_Field.fieldApiName,
        utilitySharedLicensing : Utility_Shared_Licensing_Field.fieldApiName,
        utilitySharedLicensingWhy : Utility_Shared_Licensing_Why_Field.fieldApiName,
        poNumber : PO_Number_Field.fieldApiName
    };

    @track dealRegRecord =
    {
        [Company_Name_Field.fieldApiName] : "",
        [First_Name_Field.fieldApiName] : "",
        [Last_Name_Field.fieldApiName] : "",
        [Email_Field.fieldApiName] : "",
        [Engaged_With_Rubrik_Field.fieldApiName] : "",
        [Source_Opportunity_Field.fieldApiName] : "",
        [Account_Field.fieldApiName] : "",
        [Amount_Of_Data_Field.fieldApiName] : "",
        [Customer_Budget_Field.fieldApiName] : "",
        [Timeframe_Field.fieldApiName] : "",
        [Customer_Needs_Field.fieldApiName] : "",
        [Scope_Of_Opportunity_Field.fieldApiName] : "",
        [Scope_Of_Opportunity_Additional_Details_Field.fieldApiName] : "",
        [Utility_Shared_Licensing_Field.fieldApiName] : "",
        [Utility_Shared_Licensing_Why_Field.fieldApiName] : "",
        [PO_Number_Field.fieldApiName] : ""
    };

    recordTypeId;
    spinnerLoad = true;
    picklistFieldNames = ['Engaged_with_Rubrik__c','Source_of_the_Opportunity__c','Number_of_protected_machines__c','Budget__c','Purchase_Timeframe__c','Scope_of_Opportunity__c','Utility_Shared_Licensing__c'];
    picklistArrays;
    uslValue = false;
    
    mspRestrictedFlag = true;
    selectedAccountId;
    selectedAccountId2;
    showSecondLookup = false;
    reqFieldMsg = 'Complete this field.';
    accTypes = ['MSP-Reseller','Reseller'];

    @wire(getObjectInfo, { objectApiName: DEALREGISTRATION_OBJECT })
    objectInfo({ data, error }) {
        if (data) {
            const rtInfos = data.recordTypeInfos;
            for (let rtId in rtInfos) {
                if (rtInfos[rtId].name === 'Engagement' && rtInfos[rtId].available) {
                    this.recordTypeId = rtId;
                    break;
                }
            }
        } else if (error) {
            console.error('Error loading object info', error);
        }
    }

    @wire(getPicklistValuesByRecordType, {
        objectApiName: DEALREGISTRATION_OBJECT,
        recordTypeId: '$recordTypeId',
    })
    picklistValuesByRecordType({ data, error }) {
        if (data) {
            this.picklistArrays = data.picklistFieldValues;
            console.log('-->'+JSON.stringify(data.picklistFieldValues));
        } else if (error) {
            console.error('Error in getPicklistValuesByRecordType', error);
        }
    }

    connectedCallback()
    {
        Promise.all([
            loadStyle( this, PartnerCommunityResource + '/PartnerCommunityResource/Stylesheets/PartnerCommunityCSS.css')
            ]).then(() => {
                console.log("File path-->"+ PartnerCommunityResource);
                this.spinnerLoad = false;
            })
            .catch(error => {
                console.log( error.body.message );
                this.spinnerLoad = false;
        });

    }

    handleChangeEvent(event){
        this.dealRegRecord[event.target.name] = event.target.value;
        if(event.target.name == this.fieldNames.utilitySharedLicensing && event.target.value == 'Yes'){
            this.uslValue = true;
        }else if(event.target.name == this.fieldNames.utilitySharedLicensing && event.target.value == 'No'){
            this.uslValue = false;
            this.dealRegRecord[Utility_Shared_Licensing_Why_Field.fieldApiName] = '';
        }
    }

    handleSelected(event){
        this.selectedAccountId = event.detail.Id;
        this.dealRegRecord[Company_Name_Field.fieldApiName] = event.detail.Id;
    }

    handleClear(event){
        this.selectedAccountId = null;
        this.dealRegRecord[Company_Name_Field.fieldApiName] = null;
    }

    handleSelected2(event){
        this.selectedAccountId2 = event.detail.Id;
        this.dealRegRecord[Account_Field.fieldApiName] = event.detail.Id;
    }

    handleClear2(event){
        this.selectedAccountId2 = null;
        this.dealRegRecord[Account_Field.fieldApiName] = null;
    }

    handleSearchText(event){
        console.log('-search->'+JSON.stringify(event.detail));
    }

    handleSubmit(event){
        this.spinnerLoad = true;
        let pageApiName = event.target.value;
        let isValid = this.validateForm();
        let showError = this.template.querySelector('.custom-lookup-error');
        let field = this.template.querySelector('.custom-lookup');
        let customLookupValidate;
        console.log('-->'+this.dealRegRecord[Company_Name_Field.fieldApiName]);
        if(this.dealRegRecord[Company_Name_Field.fieldApiName] == null || this.dealRegRecord[Company_Name_Field.fieldApiName] == "")
        {   customLookupValidate = false;
            if(showError){
                showError.classList.remove('none');
            }
            
            if(field){
                field.classList.add('slds-has-error');
            }
        }else{
            customLookupValidate = true;
            if(showError){
                showError.classList.add('none');
            }
            
            if(field){
                field.classList.remove('slds-has-error');
            }
        }

        if(isValid && customLookupValidate){
            //save record
            console.log('--recordDetails->'+JSON.stringify(this.dealRegRecord));
            saveEngagementDealRegistration({ record : this.dealRegRecord})
            .then(result=>{
                this.showToast('Success','Record has been submitted','success');
                this.spinnerLoad = false;
                
                setTimeout(() => {
                    this.handleRedirect(pageApiName);
                }, 1500);
            })
            .catch(error=>{
                console.log('error->'+JSON.stringify(error));
                this.spinnerLoad = false;
            });
        }else{
            this.showToast('Error','Error occurred while submitting record. Please review','error');
            this.spinnerLoad = false;
        }
        
    }

    handleCancel(event){
        let pageApiName = event.target.value;
        this.handleRedirect(pageApiName);
    }

    handleRedirect(pageAPIName){
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: pageAPIName
            }
        });
    }

    validateForm(){
        let isValid = true;
        let inputFields = this.template.querySelectorAll('.input');
        inputFields.forEach(inputField => {
            if(!inputField.checkValidity()) {
                inputField.reportValidity();
                isValid = false;
            }else{
                inputField.reportValidity();
            }
        });
        return isValid;
    }

    //picklist options
    get engagedWithRubrikOptions(){
        let engagedWithRubrikOptions = [];
        
        if(this.picklistArrays?.Engaged_with_Rubrik__c){
            engagedWithRubrikOptions = this.picklistArrays.Engaged_with_Rubrik__c.values.map(val=>({
                    label: val.label,
                    value: val.value
            }));
        }
        return engagedWithRubrikOptions;
    }

    get sourceOfOpportunityOptions(){
        let sourceOfOpportunityOptions = [];
        if(this.picklistArrays?.Source_of_the_Opportunity__c){
            sourceOfOpportunityOptions = this.picklistArrays.Source_of_the_Opportunity__c.values.map(val=>({
                    label: val.label,
                    value: val.value
            }));
        }
        return sourceOfOpportunityOptions;
    }

    get amountOfDataOptions(){
        let amountOfDataOptions = [];
        if(this.picklistArrays?.Number_of_protected_machines__c){
            amountOfDataOptions = this.picklistArrays.Number_of_protected_machines__c.values.map(val=>({
                    label: val.label,
                    value: val.value
            }));
        }
        return amountOfDataOptions;
    }

    get customerBudgetOptions(){
        let customerBudgetOptions = [];
        if(this.picklistArrays?.Budget__c){
            customerBudgetOptions = this.picklistArrays.Budget__c.values.map(val=>({
                    label: val.label,
                    value: val.value
            }));
        }
        return customerBudgetOptions;
    }

    get timeframeOptions(){
        let timeframeOptions = [];
        if(this.picklistArrays?.Purchase_Timeframe__c){
            timeframeOptions = this.picklistArrays.Purchase_Timeframe__c.values.map(val=>({
                    label: val.label,
                    value: val.value
            }));
        }
        return timeframeOptions;
    }

    get scopeOfOpportunityOptions(){
        let scopeOfOpportunityOptions = [];
        if(this.picklistArrays?.Scope_of_Opportunity__c){
            scopeOfOpportunityOptions = this.picklistArrays.Scope_of_Opportunity__c.values.map(val=>({
                    label: val.label,
                    value: val.value
            }));
        }
        return scopeOfOpportunityOptions;
    }

    get utilitySharedLicensingOptions(){
        let utilitySharedLicensingOptions = [];
        if(this.picklistArrays?.Utility_Shared_Licensing__c){
            utilitySharedLicensingOptions = this.picklistArrays.Utility_Shared_Licensing__c.values.map(val=>({
                    label: val.label,
                    value: val.value
            }));
        }
        return utilitySharedLicensingOptions;
    }

    showToast(title, message, variant){
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
    
}