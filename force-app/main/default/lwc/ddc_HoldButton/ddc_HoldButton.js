import { LightningElement,api,wire,track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import validateData from '@salesforce/apex/DdcLwcController.validateData';
import updateCase from '@salesforce/apex/DdcLwcController.updateCase';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';

// import ID_FIELD from '@salesforce/schema/sbaa__Approval__c.Id';
// import STATUS_FIELD from '@salesforce/schema/sbaa__Approval__c.sbaa__Status__c';
// import REQ_STATUS_FIELD from '@salesforce/schema/Deal_Desk_Case__c.Request_Status__c';
// import USER_COMMENT_FIELD from '@salesforce/schema/sbaa__Approval__c.Additional_Comments__c';
// import { getRecord,updateRecord, getFieldValue } from "lightning/uiRecordApi";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class Ddc_HoldButton extends LightningElement {
    
    isLoaded=false;
    isRecordOpen=true;
    wrapper;
    @api recordId
    myId='';
    @track inputText='';
    statusTemp='';

    @wire(validateData, {recId: '$recordId'})
    validateRecord({error, data}) {
        if (error) {
            // TODO: Error handling
             console.log(error);
          this.isLoaded=true;
          this.closeModal();
        } else if (data) {
            // TODO: Data handling
            console.log(data);
          let obj= JSON.parse(data);
          this.wrapper=obj;
          if(obj.status=='Error'){
            this.showToast(obj.status,obj.message,obj.status);
           this.closeModal();
          }else{
            this.statusTemp=obj.status+' Comment';
            this.myId=obj.myId;
            this.isLoaded=true;
          }
        }
    }

    handleInputChange(event){
        console.log(event.target.value);  
        this.inputText = event.target.value;

    }

    handleSave(event){
      this.isLoaded=false;
      console.log('**><',this.myId);
      updateCase({myId:this.myId,comments:this.inputText})
          .then(result => {
              this.showToast("Success",result,"success");
              this.updateRecordView();
              this.closeModal();
          })
          .catch(error => {
              // TODO Error handling
              this.showToast("Error while submitting request!",error.body.message,"error");
              this.closeModal();
          });
    }

    closeModal(event){
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