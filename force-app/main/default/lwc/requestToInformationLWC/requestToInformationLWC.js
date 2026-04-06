import { LightningElement, api, track, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { refreshApex } from '@salesforce/apex';
import {getRecord, getFieldValue, updateRecord} from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';



//export default class RequestToInformationLWC extends NavigationMixin(LightningElement) {
export default class RequestToInformationLWC extends LightningElement {    
    @api recordId;
    @track isLoadingComplete = false;
    @track showMessage = false;
    @track selectedValue = '';
    @track selectedCategory = '';
    @track selectedComment = '';
    @track selectedEmail = '';
    EmailProvided = false;
    valueRequired = false;
    @track companyEmail = '';
    @track isEmailInvalid = false;
    @track selectedFeedComment = '';
    

    handleInputChange(event) {
        this.selectedValue = event.detail.value;
        if(this.selectedValue== 'Other')
        {
            this.EmailProvided = true;
            this.valueRequired = true;
        }
        else {
            this.EmailProvided = false;
            this.valueRequired = false;
            this.isEmailInvalid=false;
            this.selectedEmail = '';
             }
        //this.sendToController();
    }
    handleEmailChange(event) {
        this.selectedEmail = event.detail.value;
         
        
        //this.sendToController();
    }

    handleFeedCommentChange(event) {
        this.selectedFeedComment = event.detail.value;
        //this.sendToController();
    }
    validateEmail(event) {
        const emailRegex="^[A-Za-z0-9._%+-]+@rubrik\.com$";
        let emailValue=this.template.querySelector(".validEmail");
        let checkEmailVal=emailValue.value;
        if(checkEmailVal.match(emailRegex)){
                     
           this.isEmailInvalid=false;

        }else{
            this.isEmailInvalid=true;
                      
            }
       
    
    }
    handleCategoryChange(event) {
        this.selectedCategory = event.detail.value;
        //this.sendToController();
    }
    handleCommentChange(event) {
        this.selectedComment = event.detail.value;
        //this.sendToController();
    }

    handleSubmit(event) {
        this.isLoadingComplete = false;
        console.log('> this.selectedValue: ',this.selectedValue);
        let fields = {
                    Id: this.recordId,
                    Feedback_Groups__c : this.selectedValue,
                    Categories__c : this.selectedCategory,
                    Request_To_Information_Comment__c : this.selectedComment,
                    Request_To_Information_Status__c: 'Waiting for Information',
                    Feedback_User_Email__c: this.selectedEmail,
                    Feedback_Group_Comments__c: this.selectedFeedComment
                }
        const recordInput = { fields };
        updateRecord(recordInput);
        console.log('Submitted');
        this.handleCancel();
    }

    handleCancel(event){
        /*this[NavigationMixin.Navigate]({
            "type" : "standard__recordPage",
            "attributes": {
                "recordId": this.recordId,
                "objectApiName": "sbaa__Approval__c",
                "actionName": "view"
            }
        });*/
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    handleLoad(){
        this.isLoadingComplete = true;
    }

     handleSuccess(event) {
        this.isLoadingComplete = true;
        this.showMessage = true;
        //this.caseAuditRecordId = event.detail.id;

        setTimeout(() => {
            this.showMessage = false;
        }, 3000);
    }
}