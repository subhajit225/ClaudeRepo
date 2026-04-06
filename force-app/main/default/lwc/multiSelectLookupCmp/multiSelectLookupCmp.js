import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import retriveSearchData from '@salesforce/apex/CXORequestForm.retriveSearchData';

export default class MultiSelectLookupCmp extends LightningElement {
    @api objectname = 'Account';
    @api fieldnames = ' Id, Name ';
    @api currentrecordid;
    @api label;
    @track searchRecords = [];
    @track selectedrecords = [];
    @api iconName = 'standard:account'
    @track messageFlag = false;
    @track isSearchLoading = false;
    @api placeholder = 'Search..';
    @track searchKey = '';
    delayTimeout;
    toastMessage;

    searchField() {
        var selectedRecordIds = [];
        this.selectedrecords.forEach(ele=>{
            selectedRecordIds.push(ele.Id);
        })
        retriveSearchData({ObjectName: this.objectname, fieldName: this.fieldnames, value: this.searchKey, selectedRecId: selectedRecordIds, currentRecordId: this.currentrecordid })
            .then(response => {
                if(response.Success) {
                    this.searchRecords = response.Data;
                    this.isSearchLoading = false;
                    const lookupInputContainer = this.template.querySelector('.lookupInputContainer');
                    lookupInputContainer.classList.add('slds-is-open');
                    if (this.searchKey.length > 0 && response.Data.length == 0) {
                        this.messageFlag = true;
                    } else {
                        this.messageFlag = false;
                    }   
                }else{
                    this.toastMessage = response.Message;
                    this.showError();
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

    // update searchKey property on input field change  
    handleKeyChange(event) {
        // Do not update the reactive property as long as this function is
        this.isSearchLoading = true;
        window.clearTimeout(this.delayTimeout);
        const searchKey = event.target.value;
        this.delayTimeout = setTimeout(() => {
            this.searchKey = searchKey;
            this.searchField();
        }, 300);
    }

    // method to toggle lookup result section on UI 
    toggleResult(event) {
        const lookupInputContainer = this.template.querySelector('.lookupInputContainer');
        const clsList = lookupInputContainer.classList;
        const whichEvent = event.target.getAttribute('data-source');

        switch (whichEvent) {
            case 'searchInputField':
                clsList.add('slds-is-open');
                this.searchField();
                break;
            case 'lookupContainer':
                clsList.remove('slds-is-open');
                break;
        }
    }

    setSelectedRecord(event) {       
        var recId = event.target.dataset.id;
        var selectName = event.currentTarget.dataset.name;
        let newsObject = this.searchRecords.find(data => data.Id === recId);
        this.selectedrecords.push(newsObject);
        this.template.querySelector('.lookupInputContainer').classList.remove('slds-is-open');
        let selRecords = this.selectedrecords;
        this.template.querySelectorAll('lightning-input').forEach(each => {
            each.value = '';
        });

        const selectedEvent = new CustomEvent('selected', { detail: { selRecords }, });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
    }

    removeRecord(event) {
        let selectRecId = [];
        for (let i = 0; i < this.selectedrecords.length; i++) {
            if (event.detail.name !== this.selectedrecords[i].Id)
                selectRecId.push(this.selectedrecords[i]);
        }

        this.selectedrecords = [...selectRecId];
        let selRecords = this.selectedrecords;

        const selectedEvent = new CustomEvent('selected', { detail: { selRecords }, });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
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
}