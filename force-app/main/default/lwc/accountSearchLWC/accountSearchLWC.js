import { LightningElement, api,wire, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
// importing to get the object info 
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
// importing Account shcema
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import ShowPage from '@salesforce/apex/accountsearchLWCController.ShowPage';
import createSearchAccount from '@salesforce/apex/accountsearchLWCController.createSearchAccount';
import RequestAccCreation from '@salesforce/apex/accountsearchLWCController.RequestAccCreation';
import PostAccounttoCM from '@salesforce/apex/accountsearchLWCController.PostAccounttoCM';

const columns = [
    { label:'NAME', fieldName: 'accountName', type: 'text'},
    { label: 'Status', fieldName: 'accountStatus', type: 'text' },
    { label: 'Record Type', fieldName: 'recTypeName', type: 'text' },
    { label: 'Owner', fieldName: 'AccountOwner', type: 'text' },
    { label: 'Id', fieldName: 'sourceID', type: 'text'},
    { label: 'Billing Street', fieldName: 'fullAddress', type: 'text'},
    { label: 'Billing City', fieldName: 'city', type: 'text'},
    { label: 'Billing State', fieldName: 'state', type: 'text'},
    { label: 'Billing Postal Code', fieldName: 'postalCode', type: 'text'},
    { label: 'Billing Country', fieldName: 'country', type: 'text'},
    {type: "button", typeAttributes: {
                label: 'Create',
                name: 'Create',
                title: 'Create',
                disabled: { fieldName: 'hideCreateBtn'},
                value: 'Create'
    }},
     {type: "button", typeAttributes: {
                label: 'View',
                name: 'View',
                title: 'View',
                disabled: { fieldName: 'hideViewBtn'},
                value: 'View'
        }},   
    ];

const subcolumns = [
    { label:'NAME', fieldName: 'accountName', type: 'text'},
    { label: 'Billing Street', fieldName: 'fullAddress', type: 'text'},
    { label: 'Billing City', fieldName: 'city', type: 'text'},
    { label: 'Billing State', fieldName: 'state', type: 'text'},
    { label: 'Billing Postal Code', fieldName: 'postalCode', type: 'text'},
    { label: 'Billing Country', fieldName: 'country', type: 'text'},
    {type: "button", typeAttributes: {
                label: 'Create',
                name: 'Create',
                title: 'Create',
                disabled: { fieldName: 'hideCreateBtn'},
                value: 'Create'
    }},
     {type: "button", typeAttributes: {
                label: 'View',
                name: 'View',
                title: 'View',
                disabled: { fieldName: 'hideViewBtn'},
                value: 'View'
        }},   
    ];

export default class accountSearch extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName = 'Account';
    @track isFederalUpdateable = false;

    @track columns = columns;
    @track exactcolumns = subcolumns;
    @track showLoader = true;

    @track ShowAccount = true;
    @track showPotentialMatch = false;
    @track showExactMatch = false;
    @track displayPage = true;
    @track returnWrapClassList = {};
    @track potentialMatchList = [];
    @track exactMatchList = [];
    @track potentialrowNumberOffset; //Row number
    @track exactrowNumberOffset; //Row number
    @track potentialrecordsToDisplay = []; //Records to be displayed on the page
    @track exactrecordsToDisplay = []; //Records to be displayed on the page
    @track exactTitle = '';
    @track newAccRecord = {};
    @track accRecord = {};
    @track searchType;
    @track isFederalVisible = false;

    @track selectedrecordTypeId;
    @track options = [];

    // object info using wire service
    @wire(getObjectInfo, { objectApiName: ACCOUNT_OBJECT })
       accObjectInfo({data, error}) {
        if(data) {
            if(data.fields != null && data.fields.isFederalIntel__c != undefined){
                this.isFederalVisible = true;
                this.isFederalUpdateable = data.fields.isFederalIntel__c.updateable;
            }else{
                this.isFederalUpdateable = false;
            }
            
            let optionsValues = [];
            // map of record type Info
            const rtInfos = data.recordTypeInfos;

            // getting map values
            let rtValues = Object.values(rtInfos);

            for(let i = 0; i < rtValues.length; i++) {
                if(rtValues[i].name !== 'Master') {
                    optionsValues.push({
                        label: rtValues[i].name,
                        value: rtValues[i].recordTypeId
                    })
                }
            }

            this.options = optionsValues;
        }
        else if(error) {
            window.console.log('Error ===> '+JSON.stringify(error));
        }
    }
     
    // Handling on change value
    handleChange(event) {
        this.selectedrecordTypeId = event.detail.value;
    }

    connectedCallback(){
        this.showLoader = false;
        this.ShowAccount = true;
        ShowPage().then(result => {
            this.displayPage =  result;         
            console.log('displayPage..!', result);
            if(this.displayPage == false){
                this.ShowAccount = false;
            }else{
                const inputFields = this.template.querySelectorAll(
                    'lightning-input-field'
                );
                if (inputFields) {
                    inputFields.forEach(field => {
                        if(field.fieldName == 'BillingCountryCode'){
                            field.value = 'US';
                        }
                    });
                }
            }
        }).catch(error => {
            console.log('error..!', error);
            this.showToast('', error.body.message, 'error', 'pester');
        });
    } 
    handleRowAction(event){
        var action = event.detail.action;
        var row = event.detail.row;
        console.log(row);
        switch (action.name) {
            case 'View':
                this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            'recordId': row.sourceID,
                            'actionName': 'view'
                        }
                });
                break;
            case 'Create':
                this.newAccRecord = row;
                this.ShowAccount = false;
                break;
        }
    }
    handleCancel(event){
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    recordtypeSelected(event){
        this.showLoader = true;
        console.log(this.selectedrecordTypeId);
        if(this.displayPage == false){
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: 'Account',
                    actionName: 'new'
                },
                state: {
                    nooverride: "1",
                    recordTypeId: this.selectedrecordTypeId
                }
            });
        }else{
            console.log(JSON.stringify(this.newAccRecord));
            this.searchType = this.newAccRecord.searchType;
            delete this.newAccRecord.fullAddress;
            delete this.newAccRecord.hideCreateBtn;
            delete this.newAccRecord.hideViewBtn;
            delete this.newAccRecord.index;
            delete this.newAccRecord.searchType;
            
            var newAccRecordJSON = '['+JSON.stringify(this.newAccRecord)+']';
            console.log(newAccRecordJSON);
            var isFederalIntel = false;
            if(this.isFederalVisible ==  false){
                isFederalIntel = false;
            }else{
                isFederalIntel = this.accRecord.isFederalIntel__c;
            }
            RequestAccCreation({
                'newAccRecordJSON' : newAccRecordJSON,
                'recTypeId' : this.selectedrecordTypeId,
                'IsfederalIntel' : isFederalIntel,
                'searchType' : this.searchType
            }).then(result => {    
                console.log('RequestAccCreation..!', result);
                if(result != null){
                    var accToinsert = result;
                    PostAccounttoCM({
                        'accToinsert' : accToinsert,
                        'searchType': this.searchType,
                        'IsfederalIntel' : isFederalIntel
                    }).then(result1 => {    
                        this.showLoader = false;      
                        console.log('PostAccounttoCM..!', result1);
                        this[NavigationMixin.Navigate]({
                            type: 'standard__recordPage',
                            attributes: {
                                'recordId': accToinsert.Id,
                                'actionName': 'view'
                            }
                        });
                        
                    }).catch(error1 => {
                        this.showLoader = false;
                        console.log('error1..!', error1);
                        this.showToast('', error1.body.message, 'error', 'pester');
                    });
                }
            }).catch(error => {
                this.showLoader = false;
                console.log('error..!', error);
                this.showToast('', error.body.message, 'error', 'pester');
            });
        }
    }
    createSearchAccount(event){
        this.showPotentialMatch = false;
        this.showExactMatch = false;
        var isValid = true;
        var isValidtemp = true; 
        var record = {};
        var BillingState = '';
        var temp = '';
        const inputFields = this.template.querySelectorAll(
            'lightning-input-field'
        );
        if (inputFields) {
            inputFields.forEach(field => {
                isValidtemp = field.reportValidity();
                if(!isValidtemp)
                    isValid = false;
                record[field.fieldName] = field.value;  
                if(field.fieldName == 'BillingStateCode')
                    temp = field.outerText.split('\n');
            });
        }
        if(temp != null && temp.length > 0)
            BillingState = temp[1];
        record['BillingState'] = BillingState;
        console.log(record);
        var j = 0;
        var k = 0;
        this.potentialMatchList = [];
        this.exactMatchList = [];
        this.showLoader = true;
        this.accRecord = record;
        createSearchAccount({
            'searchAccount' : record
        }).then(result => {          
            console.log('createSearchAccount..!', JSON.stringify(result));
            this.returnWrapClassList = result;
            for(var i =0;i<this.returnWrapClassList.length;i++){
                if(this.returnWrapClassList[i].listtype == "potentialMatch"){
                    this.potentialMatchList[j] = this.returnWrapClassList[i].potentialAccounts;
                    this.potentialMatchList[j].index = j+1;
                    this.potentialMatchList[j].searchType = this.returnWrapClassList[i].searchType;
                    this.potentialMatchList[j].fullAddress = this.potentialMatchList[j].addressLine1+' '+this.potentialMatchList[j].addressLine2;
                    if(this.potentialMatchList[j].sourceID != '')
                        this.potentialMatchList[j].hideCreateBtn = true;
                    if(this.potentialMatchList[j].sourceID == '')
                        this.potentialMatchList[j].hideViewBtn = true;    
                    j++;
                    this.potentialrowNumberOffset = 0;
                }
                if(this.returnWrapClassList[i].listtype == "exactMatch"){
                    this.exactMatchList[k] = this.returnWrapClassList[i].potentialAccounts;
                    this.exactMatchList[k].index = k+1;
                    this.exactMatchList[k].searchType = this.returnWrapClassList[i].searchType;
                    this.exactMatchList[j].fullAddress = this.exactMatchList[j].addressLine1+' '+this.exactMatchList[j].addressLine2;
                    if(this.exactMatchList[j].sourceID != '')
                        this.exactMatchList[j].hideCreateBtn = true;
                    if(this.exactMatchList[j].sourceID == '')
                        this.exactMatchList[j].hideViewBtn = true; 
                    k++;
                    this.exactrowNumberOffset = 0;
                }
            }
            if(this.potentialMatchList.length > 0){
                this.showPotentialMatch = true;
            }
            if(this.exactMatchList.length > 0){
                this.showExactMatch = true;
                if(this.exactMatchList.length == 1 && (this.exactMatchList[0].newAccount=='Y' || this.exactMatchList[0].newAccount=='y')){
                    this.exactTitle = 'Create New Account';
                    this.exactcolumns = subcolumns;
                }else{
                    this.exactTitle = 'Account already exists';
                    this.exactcolumns = columns;
                }
            }
            this.showLoader = false;
        }).catch(error => {
            this.showLoader = false;
            console.log('error..!', error);
            this.showToast('', error.body.message, 'error', 'pester');
        });

    }
    //Capture the event fired from the paginator component
    potentialHandlePaginatorChange(event){
        this.potentialrecordsToDisplay = event.detail;
        this.potentialrowNumberOffset = this.potentialrecordsToDisplay[0].index-1;
    } 
    exactHandlePaginatorChange(event){
        this.exactrecordsToDisplay = event.detail;
        this.exactrowNumberOffset = this.exactrecordsToDisplay[0].index-1;
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