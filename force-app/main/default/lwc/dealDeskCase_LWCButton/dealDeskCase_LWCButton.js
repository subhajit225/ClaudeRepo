import { LightningElement,api,track,wire} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import dualListBoxHeight from '@salesforce/resourceUrl/dualListBoxHeight';
import { loadStyle } from "lightning/platformResourceLoader";
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import getOppDetails from '@salesforce/apex/dDCaseOppDetails.getOppDetails';
import getQuesMetadata from '@salesforce/apex/dDCaseOppDetails.getQuesMetadata';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class dealDeskCase_LWCButton extends NavigationMixin(LightningElement) {

    @api recordId;
    @track renderForm = false;
    @track isLoading = false;
    error;
    metadataRecords;
    ddReqId;
    oppVal;
    oppOwner;
    accName;
    closeDateVal;
    amtTcvVal;
    ETMThtrVal;
    amtAcvVal;
    ETMArVal;
    ETMRegVal;
    dsnVal;
    inForGVPVal;
    prQuoteVal;
    prQuoteStVal;
    bizJustQuestVal = '';
    reqTypeVal;
    reqTypeValList = [];
    selectedDDTeam;
    isVisible = false; //DD25-7
    oppRecType;//DD25-7
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

    @wire(CurrentPageReference)
    getStateParameters(CurrentPageReference){
    if(CurrentPageReference){
        this.recordId = CurrentPageReference.state.recordId;
    }
    }
    @wire( getQuesMetadata )  
    wiredRecs( value ) {
        const { data, error } = value;
        if ( data ) {             
            this.metadataRecords = data;
            console.log('this.metadataRecords '+JSON.stringify(this.metadataRecords));
            this.error = undefined;
        } else if ( error ) {
            this.error = error;
            console.log('errorsss '+this.error);
            this.metadataRecords = undefined;
        }
    } 

    handleDDTeamChange(event){
        this.selectedDDTeam = event.detail.value;
    }

    handlereqTypeChange(event) {
        this.bizJustQuestVal = '';
        this.reqTypeValList = [];
        console.log('Selected Picklist Value: '+event.detail.value);
        this.reqTypeVal = event.detail.value;
        if(this.reqTypeVal!=null && this.reqTypeVal!=''){
            this.reqTypeValList = this.reqTypeVal.split(';');
        }
        else {
            this.bizJustQuestVal = '';
            return;
        }
        console.log('this.reqTypeValList '+this.reqTypeValList);
        console.log('this.reqTypeValList length'+this.reqTypeValList.length);
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
    
connectedCallback(){
    getOppDetails({oppId:this.recordId})
    .then(result=>{
        if(result){
            console.log('case count '+result.caseCount)
            console.log('opp record type: '+result.oppRecordType);//DD25-7
            /* Commeting this part as a change for DD25-88
            if(result.oppRecord.StageName == '6 PO With Channel' || result.oppRecord.StageName == '7 Closed Won' || result.oppRecord.StageName == '7 Closed Lost' || result.oppRecord.StageName == '7 Closed Admin'){
              this.renderForm = false;
                this.dispatchEvent(new CloseActionScreenEvent());
                const event = new ShowToastEvent({
                    title : 'Error',
                    message : 'You can create a Deal Desk Case on Stages 0 to 5 only',
                    variant : 'Error',
                    mode : 'dismissable'
                });
                this.dispatchEvent(event);
            }
            else{
            if(result.ddcAlreadyExist == false){
              this.renderForm = false;
                this.dispatchEvent(new CloseActionScreenEvent());
                const event = new ShowToastEvent({
                    title : 'Error',
                    message : 'A Deal desk '+ result.ddcName +' case Already Exist',
                    variant : 'Error',
                    mode : 'dismissable'
                });
                this.dispatchEvent(event);
            }
            else{ */
                this.renderForm = true;
                this.ddReqId = result.ddReqId;
                this.oppVal = this.recordId;
                this.oppOwner = result.oppRecord.OwnerId;
                this.closeDateVal = result.oppRecord.CloseDate;
                this.accName = result.oppRecord.AccountId;
                this.amtTcvVal = result.oppRecord.Amount;
                this.ETMThtrVal = result.oppRecord.ETM_Theatre__c;
                this.amtAcvVal = result.oppRecord.ACV_Amount__c;
                this.ETMArVal = result.oppRecord.ETM_Area__c;
                this.ETMRegVal = result.oppRecord.ETM_Region__c;
                this.dsnVal = result.oppRecord.Deal_Structuring_Oppty_Notes__c;
                this.inForGVPVal = result.oppRecord.In_Forecast_Theatre__c;
                this.prQuoteVal = result.oppRecord.SBQQ__PrimaryQuote__c;
                this.prQuoteStVal = result.oppRecord.Primary_Quote_Approval_Status__c;
                this.oppRecType = result.oppRecordType; //DD25-7
          //  }
            //} DD25-88
        }
    })
    .catch(error=>{
        this.error = error;
    })
}
    handleSuccess(event){
        this.isLoading = false;
        const evt = new ShowToastEvent({
            title: 'Success',
            message: 'Deal Desk Case Created Successfully',
            variant: 'success',
            mode: 'sticky'
        });
        this.dispatchEvent(evt);
       this.dispatchEvent(new CloseActionScreenEvent());
        const ddcId = event.detail.id;
        console.log('new dd id: '+ddcId)
        this[NavigationMixin.GenerateUrl]({
        type: 'standard__recordPage',
        attributes: {
            recordId: ddcId,
            objectApiName: 'Deal_Desk_Case__c',
            actionName: 'view'
        }
        }).then(generatedUrl => {
            window.open(generatedUrl);
        });
    }
    handleCancel(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    handleSubmit(){
        this.isLoading = true;
    }
    handleError(){
        this.isLoading = false;
        //this.template.querySelector('[data-id="formerror"]').setError('Please check all the errors on the page');
        const evt = new ShowToastEvent({
            title: 'Error',
            message: 'Please check all the errors on the page1',
            variant: 'Error',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }
   
}