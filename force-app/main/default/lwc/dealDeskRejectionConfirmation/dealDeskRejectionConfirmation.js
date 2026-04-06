import { LightningElement, track, api ,wire} from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import currentUserId from '@salesforce/user/Id';
import STATUS_FIELD from '@salesforce/schema/sbaa__Approval__c.sbaa__Status__c';
export default class DealDeskRejectionConfirmation extends NavigationMixin(LightningElement) {
    @api recordId;
    @track loaded = true;
    @track modal = true;
    requestorId=currentUserId;
    header='Warning';

    @wire(getRecord,{ recordId: "$recordId", fields: [STATUS_FIELD] })
    getApprovalRecord ({error, data}) {
        if (error) {
          console.log(error);
          this.loaded=true;
        } 
        else if (data) {
            let approvalRecord=data;
            let approval_status =  getFieldValue(approvalRecord,STATUS_FIELD);
              if(approval_status =='Rejected' || approval_status =='Approved'|| approval_status =='Recalled'|| approval_status =='Revoked'){
                this.validationMessage='Only an active approval request can be rejected!'       
                this.showToast("Error",this.validationMessage,"error");
                this.dispatchEvent(new CloseActionScreenEvent());
              }
              else{
                console.log(this.requestorId);
                this.loaded=true;
              }
          }
      }

    onCancelClick() {
        window.location.assign("https://rubrikinc--sbaa.vf.force.com/apex/Reject?scontrolCaching=1&id="+this.recordId);
    }
    handleRmiResponse(event){
        console.log(event.detail.message);
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    onContinueClick() {
        this.modal = false;  
        this.loaded=false;    
    }
    handleLoad(event){
        console.log(event.detail.message);
        this.loaded=event.detail.message;
    }

    showToast(title,message,variant){
      this.dispatchEvent(
        new ShowToastEvent({
          title: title,
          message: message,
          variant: variant,
          mode: 'sticky'
        }),);
    }
    onCancel(){
        this.dispatchEvent(new CloseActionScreenEvent());

    }
    onReject(){
            window.location.assign('https://rubrikinc--sbaa.vf.force.com/apex/Reject?scontrolCaching=1&id='+this.recordId);
    }
}