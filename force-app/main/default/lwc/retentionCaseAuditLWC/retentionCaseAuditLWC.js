import { LightningElement, api, wire, track } from 'lwc';
import { getRecord} from 'lightning/uiRecordApi';
import UserNameFIELD from '@salesforce/schema/User.Name';
import USER_EMAIL_FIELD from '@salesforce/schema/User.Email';
import Id from "@salesforce/user/Id";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import hasAuditFormEditAccess from '@salesforce/customPermission/Retention_Case_Audit_Form_Permission';
 


const FIELDS = ['Case.Account_360_degree_review__c','Case.RP_Ownership__c','Case.RP_Validation__c','Case.RP_Validation_Accuracy__c','Case.RP_Fields__c','Case.Communication_Call_Audit__c',
'Case.RP_Followup__c','Case.RP_Action__c','Case.RP_Communication__c','Case.RP_Closure__c','Case.Case_Closure__c','Case.RP_Risk_status__c','Case.Call_Audit_Score__c','Case.Case_Audit_Timestamp__c',
'Case.Discovery__c','Case.Call_Flow__c','Case.Walkthrough_and_product_awareness__c','Case.Query_handling_Issue_Analysis__c','Case.Customer_Sentiment__c','Case.Call_Documentation__c','Case.Audit_Score__c','Case.Call_Audit_Timestamp__c'];

export default class RetentionCaseAuditLWC extends LightningElement {
    @api recordId;
    @api objectApiName='Case';
    @track caseRecord1 = '';
    @track caseRecordUpdate  = new Object();
    @track customPermission = hasAuditFormEditAccess;

    totalAnswered = 0;
    answered = 0;
    percentage;
    caseTotalAnswered = 0;
    caseAnswered = 0;
    casePercentage;
    Account_360_Degree_Review;
    RP_Ownership;
    RP_Validation;
    RP_Validation_Accuracy;
    RP_Fields;
    RP_Followup;
    RP_Communication;
    RP_Closure;
    RP_Risk_status;
    currentUserName;
    currentUserEmail;
    userId = Id;

    get options() {
        return [
            { label: 'No', value: 'No' },
            { label: 'Yes', value: 'Yes' },
            { label: 'NA', value: 'NA' },
        ];
    }

     
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({error, data}) {
        if(data){
             
            this.caseRecord1 = data;
            this.Account_360_Degree_Review = this.caseRecord1.fields.Account_360_degree_review__c.value;
            this.RP_Ownership = this.caseRecord1.fields.RP_Ownership__c.value;
            this.RP_Validation_Accuracy = this.caseRecord1.fields.RP_Validation_Accuracy__c.value;
            this.RP_Validation = this.caseRecord1.fields.RP_Validation__c.value;
            this.RP_Fields = this.caseRecord1.fields.RP_Fields__c.value;
            this.RP_Followup = this.caseRecord1.fields.RP_Followup__c.value;
            this.RP_Action = this.caseRecord1.fields.RP_Action__c.value;
            this.RP_Communication= this.caseRecord1.fields.RP_Communication__c.value;
            this.RP_Closure = this.caseRecord1.fields.RP_Closure__c.value;
            this.RP_Risk_status = this.caseRecord1.fields.RP_Risk_status__c.value;
            let answeredQuestion = 0;
            let totalQuestion = 0;
            if(this.caseRecord1.fields.Audit_Score__c.value != null){
                answeredQuestion += this.Account_360_Degree_Review == 'Yes' ? 1 : 0;
                answeredQuestion += this.RP_Ownership == 'Yes' ? 1 : 0;
                answeredQuestion += this.RP_Validation == 'Yes' ? 1 : 0;
                answeredQuestion += this.RP_Validation_Accuracy == 'Yes' ? 1 : 0;
                answeredQuestion += this.RP_Fields == 'Yes' ? 1 : 0;
                answeredQuestion += this.RP_Followup == 'Yes' ? 1 : 0;
                answeredQuestion += this.RP_Communication == 'Yes' ? 1 : 0; 
                answeredQuestion += this.RP_Closure == 'Yes' ? 1 : 0;
                answeredQuestion += this.RP_Action == 'Yes' ? 1 : 0;
                answeredQuestion += this.RP_Risk_status == 'Yes' ? 1 : 0;
                totalQuestion += this.Account_360_Degree_Review == 'NA' || this.Account_360_Degree_Review == null  ? 0 : 1;
                totalQuestion += this.RP_Ownership == 'NA' || this.RP_Ownership == null? 0 : 1;
                totalQuestion += this.RP_Validation == 'NA' || this.RP_Validation == null? 0 : 1;
                totalQuestion += this.RP_Validation_Accuracy == 'NA'|| this.RP_Validation_Accuracy == null ? 0 : 1;
                totalQuestion += this.RP_Fields == 'NA' || this.RP_Fields == null? 0 : 1;
                totalQuestion += this.RP_Followup == 'NA' || this.RP_Followup == null? 0 : 1;
                totalQuestion += this.RP_Communication == 'NA' || this.RP_Communication == null? 0 : 1;
                totalQuestion += this.Customer_Follow_up == 'NA'|| this.Customer_Follow_up == null ? 0 : 1;
                totalQuestion += this.RP_Risk_status == 'NA'|| this.RP_Risk_status == null ? 0 : 1;
                totalQuestion += this.RP_Action == 'NA'|| this.RP_Action == null ? 0 : 1;
                this.caseRecordUpdate["Account_360_degree_review__c"] = this.Account_360_Degree_Review;
                this.caseRecordUpdate['RP_Ownership__c'] =this.RP_Ownership;
                this.caseRecordUpdate['RP_Validation__c'] =this.RP_Validation;
                this.caseRecordUpdate['RP_Validation_Accuracy__c'] =this.RP_Validation_Accuracy;
                this.caseRecordUpdate['RP_Fields__c'] =this.RP_Fields;
                this.caseRecordUpdate['RP_Followup__c'] =this.RP_Followup;
                this.caseRecordUpdate['RP_Communication__c'] =this.RP_Communication;
                this.caseRecordUpdate['RP_Action__c'] =this.RP_Action;
                this.caseRecordUpdate['RP_Risk_status__c'] =this.RP_Risk_status;
                this.caseRecordUpdate['RP_Risk_Closure__c'] =this.RP_Closure;
                this.casePercentage = ((answeredQuestion / totalQuestion)*100).toFixed(0);
                this.casePercentage =  isNaN(this.casePercentage) ? 0 : this.casePercentage;
                this.caseAnswered= answeredQuestion;
                this.caseTotalAnswered = totalQuestion;

            }
        } else if(error){
            console.error(error);
        }
    }
 
    @wire(getRecord, { recordId: '$userId', fields: [UserNameFIELD,USER_EMAIL_FIELD]}) 
    currentUserInfo({error, data}) {
        if (data) {
            this.currentUserName = data.fields.Name.value;
            this.currentUserEmail = data.fields.Email.value;

         
        } else if (error) {
            this.error = error ;
        }
    }


    handleChange(event) {
        const selectedOption = event.detail.value;
        let fieldName = event.target.dataset.name;
        const oldVal = this.caseRecordUpdate[fieldName];
        this.caseRecordUpdate[fieldName] = selectedOption;
        if(oldVal == 'Yes'){
            if(selectedOption == 'No'){
                this.answered = this.answered - 1;
            }
            if(selectedOption == 'NA'){
                this.answered = this.answered - 1;
                this.totalAnswered = this.totalAnswered - 1;
            }
        }
        else if(oldVal == 'No'){
            if(selectedOption == 'Yes'){
                this.answered = this.answered + 1;
            }
            if(selectedOption == 'NA'){
                this.totalAnswered = this.totalAnswered - 1;
            }
        }
        else if(oldVal == 'NA'){
            if(selectedOption =='Yes'){
                this.answered = this.answered + 1;
                this.totalAnswered = this.totalAnswered + 1;
            }
            if(selectedOption == 'No'){
                this.totalAnswered = this.totalAnswered + 1;
            }
        }else{
            if(selectedOption == 'Yes'){
                this.answered = this.answered + 1;
                this.totalAnswered = this.totalAnswered + 1;
            }
            if(selectedOption == 'No'){
                this.totalAnswered = this.totalAnswered + 1;
            }
        }
        this.percentage = ((this.answered / this.totalAnswered)*100).toFixed(0);
        this.percentage =  isNaN(this.percentage) ? 0 : this.percentage;
    }

    handleSubmit(event) {
        event.preventDefault();     // stop the form from submitting
        const fields = event.detail.fields;
        var someDate = new Date(new Date().getTime()); //added 90 days to todays date
            fields.Account_360_degree_review__c = this.caseRecordUpdate.Account_360_degree_review__c;
            fields.RP_Ownership__c = this.caseRecordUpdate.RP_Ownership__c;
            fields.RP_Validation_Accuracy__c = this.caseRecordUpdate.RP_Validation_Accuracy__c;
            fields.RP_Validation__c = this.caseRecordUpdate.RP_Validation__c;
            fields.RP_Fields__c = this.caseRecordUpdate.RP_Fields__c;
            fields.RP_Followup__c = this.caseRecordUpdate.RP_Followup__c;
            fields.RP_Communication__c = this.caseRecordUpdate.RP_Communication__c;
            fields.RP_Action__c = this.caseRecordUpdate.RP_Action__c;
            fields.RP_Risk_status__c = this.caseRecordUpdate.RP_Risk_status__c;
            fields.RP_Closure__c = this.caseRecordUpdate.RP_Closure__c
            fields.Audit_Score__c = this.percentage;
            fields.Case_Audit_Timestamp__c = someDate.toISOString();  
            fields.Retention_Case_Auditor_Name__c=this.currentUserName;
            fields.Auditor_Email_Id__c=this.currentUserEmail;
            this.template.querySelector('lightning-record-edit-form').submit(fields);
    }
    handleSuccess(event) {
         const evt = new ShowToastEvent({
            title: 'Success',
            message: 'Audit form is successfully Submitted! Audit Score : '+this.percentage+'%',
            variant: 'success',
        });
        this.dispatchEvent(evt);
            this.dispatchEvent(new CloseActionScreenEvent());

    }

     handleError(event) {
        this.dispatchEvent(new CloseActionScreenEvent());
    }



    handleClose(event) {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    
}