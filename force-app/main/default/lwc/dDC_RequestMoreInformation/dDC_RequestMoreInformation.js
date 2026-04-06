import { LightningElement , api, wire} from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import Request_More_Information_Notes__c from '@salesforce/schema/Request_More_Information_Notes__c';
import DDC_FIELD from '@salesforce/schema/sbaa__Approval__c.Deal_Desk_Case__c';
import STATUS_FIELD from '@salesforce/schema/sbaa__Approval__c.sbaa__Status__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import currentUserId from '@salesforce/user/Id';

export default class DDC_RequestMoreInformation extends LightningElement {
    @api recordId;
    approvalRecord;
    @api default=false;
    isLoaded=false;
    objectName = Request_More_Information_Notes__c;
    requestorId=currentUserId;
    rmiId=0;

    validationMessage='The record needs to be in Requested status to Request more information on the approval!';

    @wire(getRecord,{ recordId: "$recordId", fields: [DDC_FIELD,STATUS_FIELD] })
    getApprovalRecord ({error, data}) {
        if (error) {
          console.log(error);
          this.isLoaded=true;
          if(this.default){
            this.dispatchEvent(new CustomEvent('loadevent', {detail: {message: this.isLoaded}}));
          }
        } 
        else if (data) {
          if(this.rmiId==0){
            this.approvalRecord=data;
            let approval_status =  getFieldValue(this.approvalRecord,STATUS_FIELD);
              if(approval_status !='Requested'){
                if(approval_status =='Waiting On Others'){
                  this.validationMessage='There is already a question open with the business user, kindly wait for it to be answered before requesting another question.'
                }       
                this.showToast("Error",this.validationMessage,"error");
                this.closeAction();
              }
              else{
                console.log(this.requestorId);
                this.isLoaded=true;
                if(this.default){
                  this.dispatchEvent(new CustomEvent('loadevent', {detail: {message: this.isLoaded}}));
                }
              }
          }
        }
      }
    

        
    get DealDeskCaseId(){
        return getFieldValue(this.approvalRecord,DDC_FIELD)
    }

    handleSuccess(event){
      this.isLoaded=true;
       console.log(event.detail.id);
        this.rmiId = event.detail.id;
        if(this.rmiId!=0){
          this.showToast("Success","We have sent the request to the business user for more details on this approval request!","success");
        }
        this.closeAction();
          
    }

    handleObjectCreated(event){
      this.isLoaded=false;
      if(this.default){
          this.dispatchEvent(new CustomEvent('loadevent', {detail: {message: this.isLoaded}}));
        }
      event.preventDefault();       
      const fields = event.detail.fields;
      fields.Requestor__c = this.requestorId;
      this.template.querySelectorAll('lightning-edit-field').forEach(element => element.reportValidity());
      this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    closeAction(){
      if(!this.default){
        this.updateRecordView();
        this.dispatchEvent(new CloseActionScreenEvent());
      }else{
         this.dispatchEvent(new CustomEvent('rmicomplete', {
            detail: {
                message: this.rmiId
            }
        }));
      }
    }

    updateRecordView() {
      setTimeout(() => {
        eval("$A.get('e.force:refreshView').fire();");
      }, 2000);
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
}