import { LightningElement, api, track, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getAccessDetails from '@salesforce/apex/OpportunityAddDealRegLWCController.getAccessDetails';
import getLeads from '@salesforce/apex/OpportunityAddDealRegLWCController.getLeads';
import convertLead from '@salesforce/apex/OpportunityAddDealRegLWCController.convertLead';
const columns = [
    { label:'NAME', fieldName: 'leadLink', type: 'url', typeAttributes: {label: {fieldName: 'Name'}, tooltip:'Go to detail page', target: '_blank'}},
    { label: 'PRIMARY DEAL REGISTRATION', fieldName: 'Deal_Reg_Number__c', type: 'text' },
    { label: 'COMPANY', fieldName: 'Company', type: 'text' },
    { label: 'PARTNER', fieldName: 'Partner_Lookup__r.Name', type: 'text' },
    { label: 'PARTNER REP', fieldName: 'Partner_Rep__c', type: 'text'},
    { label: 'EMAIL', fieldName: 'Email', type: 'Email'},
];
export default class OpportunityAddDealRegLWC extends NavigationMixin(LightningElement){
    @api recordId;
    @track searchKey;
    @track error;
    @track accessDetails;
    @track columns = columns;
    @track leads; //All opportunities available for data table    
    @track showTable = false; //Used to render table after we get the data from apex controller    
    @track recordsToDisplay = []; //Records to be displayed on the page
    @track rowNumberOffset; //Row number
    @track LeadRecord = {};
    @track disableButtons = false;
    @track disableSubmitButton = true;
    @track showLoader = false;

    connectedCallback(){
        window.clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => {
            console.log(' recordId..!', this.recordId);
            getAccessDetails({
                'recId' : this.recordId
            }).then(result => {
                this.disableButtons = false;
                console.log(' accessDetails..!');         
                console.log(result);
                this.accessDetails = result[0];
               if(result[0].errMsg != ''){
                   this.showToast('', result[0].errMsg, result[0].variant, 'pester');
                   this.disableButtons = true;
               }
            }).catch(error => {
                console.log('error..!', error);
                this.showToast('', error.body.message, 'error', 'pester');
                this.disableButtons = true;
            });

        }, 100);
    }

    handleKeyChange(event){
        this.searchKey = event.target.value;
    }
     handleSearch(event){ 
         this.showTable = false;
         this.disableSubmitButton = true;
          getLeads({"searchText" : this.searchKey}).then(data => { 
                 if(data){
                    let recs = [];
                    console.log(' data..!');
                    console.log(data);
                    if(data != null && data.length > 0){
                        this.disableSubmitButton = false;
                        for(let i=0; i<data.length; i++){
                            let ld = {};
                            ld.rowNumber = ''+(i+1);
                            ld.leadLink = '/'+data[i].Id;
                            ld = Object.assign(ld, data[i]);
                            recs.push(ld);
                        }
                        this.leads = recs;
                        console.log(this.leads);
                        this.showTable = true;
                        this.rowNumberOffset = 0;
                    }
                }else{
                    this.error = error;
                }   
            }).catch(error => {
                console.log('error..!', error);
                
            });
     }
    //Capture the event fired from the paginator component
    handlePaginatorChange(event){
        this.recordsToDisplay = event.detail;
        this.rowNumberOffset = this.recordsToDisplay[0].rowNumber-1;
        console.log(this.recordsToDisplay);
        console.log(this.recordsToDisplay[0]);
    } 
    handleconvertLead(event){
        this.showLoader = true;
         console.log(this.LeadRecord);
         console.log(this.accessDetails.opp);
         convertLead({"leadRec" : this.LeadRecord, 'op' : this.accessDetails.opp, 'conId' : this.accessDetails.conId}).then(errmsg => { 
                this.showLoader = false;
                this.dispatchEvent(new CloseActionScreenEvent());
                if(errmsg != ''){
                     this.showToast('Error', errmsg, 'error', 'pester');
                }
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        'recordId': this.accessDetails.opp.Id,
                        'objectApiName': 'Opportunity',
                        'actionName': 'view'
                    }
                });
            }).catch(error => {
            console.log('error..!', error);
            this.showLoader = false;
            this.showToast('', error.body.message, 'error', 'pester');
        });
    }
    handleRowSelection(event){
        var selectedRow = event.detail.selectedRows;
        console.log('selectedRows');
        this.LeadRecord = selectedRow[0];
        console.log(selectedRow[0].Id);
        console.log(selectedRow[0].Name);
        console.log(this.LeadRecord.Id);
    }
    handleCancel(event){
        this.dispatchEvent(new CloseActionScreenEvent());
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