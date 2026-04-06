import { LightningElement,api,track,wire} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import dualListBoxHeight from '@salesforce/resourceUrl/dualListBoxHeight';
import { loadStyle } from "lightning/platformResourceLoader";
import { NavigationMixin } from 'lightning/navigation';
import getQuesMetadata from '@salesforce/apex/dDCaseOppDetails.getQuesMetadata';
import getDDCPermission from '@salesforce/apex/dDCaseOppDetails.getDDCPermission';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
const FIELDS = ['Deal_Desk_Case__c.Time_To_First_Response__c'];

export default class DealDeskCustomFormLWC extends NavigationMixin(LightningElement) {

    @api recordId;
    @track renderForm = false;
    @track isLoading = false;
    @track isEditable = false;
    @track isDDCUser = false;
    @track isDraft = false;
    @track isDealDeskOther = false;
    error;
    showTimer = false;
    wiredRecord;
    metadataRecords;
    bizJustQuestVal;
    reqTypeVal;
    reqTypeValList = [];
    dealdeskTaggingValues =[];
    selectedDDTeam;
    isVisible = false; //SAL26-481
    renderedCallback() {

        Promise.all([
            loadStyle(this, dualListBoxHeight )
        ]).then(() => {
            console.log( 'Files loaded' );
        })
        .catch(error => {
            console.log( error.body.message );
        });
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    recordHandler(value) {
        this.wiredRecord = value;
        const { data, error } = value;
        if (data) {
            const hasElapsed = data.fields.Time_To_First_Response__c?.value;
            this.showTimer = !hasElapsed || hasElapsed === '';
        } else if (error) {
            this.showTimer = true;
        }
    }
    //handleSuccess() {
    //    refreshApex(this.wiredRecord);
    //}
    @wire( getQuesMetadata )  
    wiredRecs( value ) {
        const { data, error } = value;
        if ( data ) {             
            this.metadataRecords = data;
            this.error = undefined;
        } else if ( error ) {
            this.error = error;
            this.metadataRecords = undefined;
        }
    } 

    connectedCallback(){
        console.log( 'Files loaded' );
        getDDCPermission({ddcId:this.recordId})
        .then(result=>{
            if(result){
                if(result.isDDCUser){
                    this.isDDCUser = true;
                }else{
                    this.isDDCUser = false;
                }
                if(result.ddCaseRecord.Request_Status__c == 'Draft'){
                    this.isDraft = true;
                }else{
                    this.isDraft = false;
                }
                }
             })
        .catch(error=>{
            this.error = error;
        })
    }

    handleDDTeamChange(event){
        this.selectedDDTeam = event.detail.value;
    }
    handlereqTypeChange1(event) {
        this.dealdeskTaggingValues =event.detail.value;
        if(this.dealdeskTaggingValues.includes('Other')) {
            this.isDealDeskOther = true;
        }
        else {
            this.isDealDeskOther = false;
        }

    }
    handlereqTypeChange(event) {
        this.bizJustQuestVal = '';
        this.reqTypeValList = [];
        this.reqTypeVal = event.detail.value;
        if(this.reqTypeVal!=null && this.reqTypeVal!=''){
            this.reqTypeValList = this.reqTypeVal.split(';');
        }
        else {
            this.bizJustQuestVal = '';
            return;
        }
        if(this.reqTypeValList.length >= 1){
            var bizJustStr = '-> Provide Quote Number!';
            for(let i = 0 ; i < this.reqTypeValList.length ; i++){
                if(this.metadataRecords[this.reqTypeValList[i]]!='' && this.metadataRecords[this.reqTypeValList[i]]!=null 
                && this.metadataRecords[this.reqTypeValList[i]] !='undefined' ){
                    if(this.reqTypeValList[i]!='General Inquiry'){
                bizJustStr = bizJustStr + '\n' + '-> ' +this.metadataRecords[this.reqTypeValList[i]];
                    }
                    else if (this.reqTypeValList[i]=='General Inquiry'){
                        if(this.selectedDDTeam == 'Deal Operations'){
                            bizJustStr = bizJustStr + '\n' + '->What are you trying to quote?'+
                                        '\n' + 'Attach a screenshot of the error in Attachments.'+
                                        '\n' + 'Please refer to our cannon page for much of our Quoting Processes and Guidance.';
                        }
                        else if(this.selectedDDTeam == 'Deal Structuring'){
                            bizJustStr = bizJustStr + '\n' + '->How can we help you?'+
                                        '\n' + 'Please explain your issue in detail.'+
                                        '\n' + 'Please refer to our cannon page for much of our Deal Structuring Guidance.';
                        }
                    }
                }
            }
            this.bizJustQuestVal = bizJustStr;
        }
    }
    
    handleSuccess(event){
        refreshApex(this.wiredRecord);
        this.isLoading = false;
        this.isEditable = false;
        const evt = new ShowToastEvent({
            title: 'Success',
            message: '',
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }
    handleCancel(){
        this.isEditable = false;
    }
    handleSubmit(){
        this.isLoading = true;
    }
    handleError(event){
        this.isLoading = false;
        //this.template.querySelector('[data-id="formerror"]').setError('Please check all the errors on the page');
        const evt = new ShowToastEvent({
            title: 'Error',
            message: 'Please check all errors on the page',
            variant: 'Error',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }
    handleEdit(){
        this.isEditable = true;
    }
}