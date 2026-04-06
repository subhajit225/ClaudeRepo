import { LightningElement, wire } from 'lwc';
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import BILLINGCOUNTRYCODE_FIELD from "@salesforce/schema/Account.BillingCountryCode";
import getRecordDetails from '@salesforce/apex/customLookupLWCController.fetchDetailedRecords';
import recTypeId from '@salesforce/label/c.Account_RecordType_Partner_Distributor';
const FIELDS = 'Id, Name, Owner.Name, Owner.Email, BillingCountry, Parent_Tier__c';

export default class pc_accountManagerLookup_lwc extends LightningElement {
    recordtype = 'Customer/Prospect';
    recordsList = [];
    countryPicklist = [];
    isDisabled = true;
    showSpinner = false;
    searchClicked = false;

    @wire(getPicklistValues,{ recordTypeId: recTypeId, fieldApiName: BILLINGCOUNTRYCODE_FIELD })
    wiredCountryPicklist(result){
        this.countryPicklist = result;
    }

    handleSelected(event){
        let recId = event.detail.Id;
        this.recsNotAvailable = false;
        this.showSpinner = true;
        if(recId){
            getRecordDetails({recordId : recId, searchTxt : null, country : null, objectName : 'Account', recordTypeName : this.recordtype, fields : FIELDS})
            .then(result => {
                this.recordsList = result;
                this.isDisabled = true;
                this.showSpinner = false;
            })
            .catch(error => {
                this.error = error;
                this.showSpinner = false;
            })
        }else if (!this.searchClicked){
            this.showSpinner = false;
        }
        this.searchClicked = false;
    }

    handleSearchText(event){
        if(event.detail.searchText && event.detail.searchText.length >= 3){
            this.searchText = event.detail.searchText;
            this.isDisabled = false;
        }else{
            this.searchText = null;
            this.isDisabled = true;
            this.recordsList = [];
        }
    }

    handleSearch(){
        this.recsNotAvailable = false;
        this.searchClicked = true;
        if(this.searchText && this.searchText.length >= 3 ){
            this.showSpinner = true;
            getRecordDetails({recordId : null, searchTxt : this.searchText, country : this.selectedCountry, objectName : 'Account', recordTypeName : this.recordtype, fields : FIELDS})
            .then(result => {
                this.recordsList = result;
                if(this.recordsList.length === 0){
                    this.recordsList = [];
                    this.recsNotAvailable = true;
                }
                this.showSpinner = false;
            })
            .catch(error => {
                this.error = error;
                this.showSpinner = false;
            })
        }
    }

    handleCountry(event){
        this.selectedCountry = event.target.options.find(opt => opt.value === event.detail.value).label;
    }

    handleClear(){
        this.recordsList = [];
        this.isDisabled = true;
    }
}