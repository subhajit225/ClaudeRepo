import { LightningElement, track, api } from 'lwc';
import getRecordsByName from '@salesforce/apex/customLookupLWCController.getRecordsByName';
import fetchDefaultRecord from '@salesforce/apex/customLookupLWCController.fetchDefaultRecord';
const DELAY = 300;

export default class CustomLookUpLWC extends LightningElement {
    @api
    objectname;
    @api
    defaultRecordId = '';
    @track
    recordsList;
    //PRIT24-340 - start
    @api selectedValue ='';
    @api isDisabled = false;
    //PRIT24-340 - end
    error; 
    recordselected = false;
    @api
    iconname;
    @api tableindex;

    @api placeholder = 'Enter Company Name...';
    @api recordtype = '';

    //PRIT24-435-START
    _emaildomain;
    @api 
    set emaildomain(val){
        this._emaildomain = val;
    }
    get emaildomain(){
        return this._emaildomain;
    }
    //PRIT24-435-END

    //PRIT24-445-START
    _accid = '';
    @api set accid(val){
        this._accid = val;
    }
    get accid(){
        return this._accid;
    }
    @track contactList = [];
    @api isRequired = false;
    //PRIT24-445-END

    //PRIT26-5-START
    @api mspRestrictedFlag;
    @api accIdNotIn;
    @api accTypes;
    //PRIT26-5-END

    // initial function to populate default selected lookup record if defaultRecordId provided  
    connectedCallback(){
         if(this.defaultRecordId != ''){
            fetchDefaultRecord({ recordId: this.defaultRecordId , 'objectName' : this.objectname })
            .then((result) => {
                if(result != null){
                    this.recordselected = true;
                    this.selectedValue = result.Name;
                    const selectedEvent = new CustomEvent('selected', {
                        detail: {
                            Name : result.Name,
                            Id : result.Id
                        } 
                    });
                    this.dispatchEvent(selectedEvent);
                }
            })
            .catch((error) => {
                this.error = error;
                this.recordsList = {};
            });
         }
         console.log('isReuired->'+this.isRequired);
    }

    //Method to query data after typing search term
    onKeyChange(event) {
        window.clearTimeout(this.delayTimeout);
        this.selectedValue = event.target.value;
        const searchEvent = new CustomEvent('search', {
            detail: {
                searchText : this.selectedValue,
            } 
        });
        this.dispatchEvent(searchEvent);
        this.delayTimeout = setTimeout(() => {
            if(this.selectedValue.length >= 3){
                getRecordsByName({objectName : this.objectname, searchFor : this.selectedValue,  recordTypeName : this.recordtype, emailDomain : this._emaildomain, accId : this._accid, mspRestrictedFlag : this.mspRestrictedFlag, accIdNotIn : this.accIdNotIn, accTypes : this.accTypes })//prit24-435-added email, prit24-445-added accId
                .then(result => {
                    this.recordsList = result;
                    console.log('result'+result);
                    //prit24-445-start
                    if(this.objectname == 'Contact'){
                        this.contactList = result;
                    }
                    //prit24-445-end
                })
                .catch(error => {
                    //exception handling
                    this.error = error;
                })
            }
        },DELAY);
        window.setTimeout(() => window.addEventListener('click', this.handleClose), 0);
    }

    handleClose = () => {
        console.log('close called');
        this.recordsList = false;
        if(!this.recordselected){
            const selectedEvent = new CustomEvent('selected', {
                detail: {
                    Name : this.selectedValue,
                    Id : ''
                } 
            });
            this.dispatchEvent(selectedEvent);
        }
        window.removeEventListener('click', this.handleClose);
    }

    //Method to clear search list and show selected value.
    clearSelection() {
        this.recordselected = false;
        this.selectedValue = "";
        this.recordsList = undefined;
        const clearEvent = new CustomEvent('clear', {
            detail: {
                Name : this.selectedValue,
                Id : ''
            }
        });
        this.dispatchEvent(clearEvent);
    }
    //Method to pass selected record to parent component.
    setSelectedValue(event) {
        console.log('selected called');
        this.selectedValue = event.target.dataset.itemname;
        this.recordselected = true;
        this.recordsList = undefined;
        event.preventDefault();
        const selectedEvent = new CustomEvent('selected', {
            detail: {
                Name : this.selectedValue,
                Id : event.target.dataset.itemid,
                conList : this.contactList //prit24-445-added conList
            } 
        });
        this.dispatchEvent(selectedEvent);
        event.stopPropagation();
    }
    @api
    populateValue(value){
        this.selectedValue = value;
        this.recordselected = true;
        this.recordsList = undefined;
    }
}