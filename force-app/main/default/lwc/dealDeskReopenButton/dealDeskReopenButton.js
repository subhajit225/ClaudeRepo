import { LightningElement,api,track,wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getddCaseDetails from '@salesforce/apex/dDCaseDetails.getddCaseDetails';
import updateCase from '@salesforce/apex/dDCaseDetails.updateCase';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class DealDeskReopenButton extends NavigationMixin(LightningElement) {
recordId;
error;
@track isLoading = false;

@wire(CurrentPageReference)
getStateParameters(CurrentPageReference){
    if(CurrentPageReference){
        this.recordId = CurrentPageReference.state.recordId;
    }
}

connectedCallback(){
    getddCaseDetails({ddCaseId:this.recordId})
    .then(result=>{
        if(result){
            console.log('case count '+result.caseCount)
            this.isLoading= true;
            if(result.ddRecord.Opportunity_Stage__c == '6 PO With Channel' || result.ddRecord.Opportunity_Stage__c == '7 Closed Won' || result.ddRecord.Opportunity_Stage__c == '7 Closed Lost' || result.ddRecord.Opportunity_Stage__c == '7 Closed Admin'){
                this.dispatchEvent(new CloseActionScreenEvent());
                this.showToast('Error','You can only ReOpen a case when related Opportunity is having Stage 0 to Stage 5','Error','dismissable');
                this.isLoading = false;
            }
            else if(result.ddRecord.Request_Status__c== 'Requested'){
                this.dispatchEvent(new CloseActionScreenEvent());
                this.showToast('Error','Case is already in Requested Status','Error','dismissable');
                this.isLoading = false;
            }
            else if(result.ddRecord.Request_Status__c== 'Draft'){
                this.dispatchEvent(new CloseActionScreenEvent());
                this.showToast('Error','Case is already Open','Error','dismissable');
                this.isLoading = false;
            }

            else{
                this.update();
                this.isLoading = false;
            }
            this.isLoading = false;
        }
    })
    .catch(error=>{
        this.dispatchEvent(new CloseActionScreenEvent());
                this.showToast('Error',error.body.message,'Error','dismissable');
                this.isLoading = false;
        console.log(error.body.message);
    })

}

update(){
        updateCase({
            ddCaseId:this.recordId
        }).then(result => {
            this.dispatchEvent(new CloseActionScreenEvent());
            this.showToast('Success','Case ReOpened Successfully!! Now Click on Submit for Approval to start the Approval Process','Success','dismissable');
            this.updateRecordView();
            
        }).catch(error => {
            this.dispatchEvent(new CloseActionScreenEvent());
            this.showToast('Error',error.body.message,'Error','dismissable');
            this.isLoading = false;
    console.log(error.body.message); 
        });
    }

    updateRecordView() {
       setTimeout(() => {
            eval("$A.get('e.force:refreshView').fire();");
       }, 500); 
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