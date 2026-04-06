import { LightningElement,api,wire,track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import validateData from '@salesforce/apex/DdcLwcController.validateDataForApproval';
import approveCase from '@salesforce/apex/DdcLwcController.approveCase';
import Approval from '@salesforce/schema/sbaa__Approval__c';
import userId from "@salesforce/user/Id";
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

// import ID_FIELD from '@salesforce/schema/sbaa__Approval__c.Id';
// import STATUS_FIELD from '@salesforce/schema/sbaa__Approval__c.sbaa__Status__c';
// import REQ_STATUS_FIELD from '@salesforce/schema/Deal_Desk_Case__c.Request_Status__c';
// import USER_COMMENT_FIELD from '@salesforce/schema/sbaa__Approval__c.Additional_Comments__c';
// import { getRecord,updateRecord, getFieldValue } from "lightning/uiRecordApi";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class Ddc_CondtitionalApproval extends LightningElement{
    
    isLoaded=false;
    @api recordId
    myId='';
    statusTemp='Conditionally Approve';
    objectName=Approval;
    userId=userId;

    @wire(validateData, {recId: '$recordId',userId:'$userId'})
    validateRecord({error, data}) {
        if (error) {
            // TODO: Error handling
            console.log(error);
            this.isLoaded=true;
            this.closeAction();
        } else if (data) {
            // TODO: Data handling
            console.log(data);
            let obj= JSON.parse(data);
            this.wrapper=obj;
            if(obj.status=='Error'){
                this.showToast(obj.status,obj.message,obj.status);
            this.closeAction();
            }else{
                this.myId=obj.myId;
                    setTimeout(() => {this.isLoaded=true;}, 1000);
            }
        }
    }


    handleObjectCreated(event){
    console.log('---');
      event.preventDefault();       
      const fields = event.detail.fields;
      console.log(JSON.stringify(fields));
      let obj={};
      obj.amount=100;
      obj.closeDate=null;
      obj.primaryQuote=null;
      obj.approvalComments=fields.sbaa__CommentsLong__c;
      console.log(obj);
    console.log(JSON.stringify(obj));  
    // if((obj.amount==null || obj.amount==undefined) && (obj.closeDate==null || obj.closeDate==undefined)  && ( obj.primaryQuote==null || obj.primaryQuote==undefined )){
    //     this.showToast('Error','To conditionally approve a request you must provide either Amount, Close Date or Primary Quote!','error');
    // }
    // else 
    if(obj.approvalComments==null || obj.approvalComments==undefined ){
        this.showToast('Error','Comments are mandatory to approve a request.','error');
    }
    else{
      this.isLoaded=false;
        approveCase({user:this.userId,approvalId:this.recordId,ddcId:this.myId,inputData:JSON.stringify(obj)})
            .then(result => {
                this.handleSuccess();
            })
            .catch(error => {
                // TODO Error handling
                this.handleSuccess();
            });
        }
    }

   handleSuccess(event){
        this.isLoaded=true;
        this.closeAction();
          
    }

    closeAction(event){
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    get checkValidity(){
      console.log(this.inputText)
      return (this.inputText==null || this.inputText==undefined || this.inputText=='')
    }
    updateRecordView() {
        getRecordNotifyChange([{ recordId: this.recordId }]);

    // setTimeout(() => {eval("$A.get('e.force:refreshView').fire();");}, 1000);
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