import { LightningElement, api, wire, track } from 'lwc';
import { getRecord} from 'lightning/uiRecordApi';
import UserNameFIELD from '@salesforce/schema/User.Name';
import USER_EMAIL_FIELD from '@salesforce/schema/User.Email';
import Id from "@salesforce/user/Id";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import hasAuditFormEditAccess from '@salesforce/customPermission/Case_Audit_form_Edit_Access';
 


const FIELDS = ['Case.Customer_360_Review__c','Case.PRD_Entitlement__c','Case.Account_Customer_Name__c','Case.Record_Type__c','Case.Customer_Success_Fields__c','Case.Communication_Call_Audit__c',
'Case.Private_Public_Comments__c','Case.Mode_of_Communication__c','Case.Customer_Follow_up__c','Case.Technical_Skills__c','Case.Case_Closure__c','Case.Onboarding_Completed__c','Case.Call_Audit_Score__c','Case.Case_Audit_Timestamp__c',
'Case.Discovery__c','Case.Call_Flow__c','Case.Walkthrough_and_product_awareness__c','Case.Query_handling_Issue_Analysis__c','Case.Customer_Sentiment__c','Case.Call_Documentation__c','Case.Audit_Score__c','Case.Call_Audit_Timestamp__c'];

export default class CSMAuditForm extends LightningElement {
    @api recordId;
    @api objectApiName='Case';
    @track caseRecord1 = '';
    @track caseRecordUpdate  = new Object();

    totalAnswered = 0;
    answered = 0;
    percentage;
    caseTotalAnswered = 0;
    caseAnswered = 0;
    casePercentage;
    callTotalAnswered = 0;
    callAnswered = 0;
    callPercentage;
    Customer_360_Review;
    PRD_Entitlement;
    Account_Customer_Name;
    Record_Type;
    Customer_Success_Fields;
    Private_Public_Comments;
    Mode_of_Communication;
    Customer_Follow_up;
    Technical_Skills;
    Case_Closure;
    Onboarding_Completed;
    currentUserName;
    currentUserEmail;
    Discovery;
    Call_Flow;
    Walkthrough_and_product_awareness;
    Query_handling_Issue_Analysis;
    Customer_Sentiment;
    Call_Documentation;
    Communication_Call_Audit;
    userId = Id;
    Selected_Form;
    showCallForm = false;
    showCaseForm = false;
    showSelectForm = true;
    alreadySubmitted = false;
    formType = '';

    get radioOptions() {
        return [
            { label: 'Case Audit', value: 'case' },
            { label: 'Call Audit', value: 'call' },
        ];
    }

    handleRadioChange(event){
          const selectedOption = event.detail.value;
          if(selectedOption == 'case'){
            this.showCaseForm = true;
            this.percentage = this.casePercentage;
            this.totalAnswered = this.caseTotalAnswered;
            this.answered = this.caseAnswered;
            this.formType = 'Case';
          }
          if(selectedOption == 'call'){
            this.showCallForm = true;
            this.percentage = this.callPercentage;
            this.totalAnswered = this.callTotalAnswered;
            this.answered = this.callAnswered;
            this.formType = 'Call';
          }
          this.showSelectForm = false;
    }
    

    renderedCallback(){    
        const radioGroup = this.template.querySelectorAll('lightning-radio-group');
        const AuditInputField=this.template.querySelectorAll('lightning-input-field');
        const SaveButton=this.template.querySelector('.saveButton');
        if (!hasAuditFormEditAccess && SaveButton && AuditInputField && radioGroup) {
         SaveButton.style.display="None";
         radioGroup.forEach(function(element){
              element.disabled=true;
            
        })
        AuditInputField.forEach(function(element){           
              element.disabled=true;
        })

        }     
       
    }
  
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
            this.Customer_360_Review = this.caseRecord1.fields.Customer_360_Review__c.value;
            this.PRD_Entitlement = this.caseRecord1.fields.PRD_Entitlement__c.value;
            this.Record_Type = this.caseRecord1.fields.Record_Type__c.value;
            this.Account_Customer_Name = this.caseRecord1.fields.Account_Customer_Name__c.value;
            this.Customer_Success_Fields = this.caseRecord1.fields.Customer_Success_Fields__c.value;
            this.Private_Public_Comments = this.caseRecord1.fields.Private_Public_Comments__c.value;
            this.Mode_of_Communication = this.caseRecord1.fields.Mode_of_Communication__c.value;
            this.Customer_Follow_up = this.caseRecord1.fields.Customer_Follow_up__c.value;
            this.Technical_Skills = this.caseRecord1.fields.Technical_Skills__c.value;
            this.Case_Closure = this.caseRecord1.fields.Case_Closure__c.value;
            this.Onboarding_Completed = this.caseRecord1.fields.Onboarding_Completed__c.value;
            this.Discovery =this.caseRecord1.fields.Discovery__c.value;
            this.Call_Flow =this.caseRecord1.fields.Call_Flow__c.value;
            this.Walkthrough_Product =this.caseRecord1.fields.Walkthrough_and_product_awareness__c.value;
            this.Query_Handling =this.caseRecord1.fields.Query_handling_Issue_Analysis__c.value;
            this.Customer_Sentiment =this.caseRecord1.fields.Customer_Sentiment__c.value;
            this.Call_Documentation =this.caseRecord1.fields.Call_Documentation__c.value;
            this.Communication_Call_Audit =this.caseRecord1.fields.Communication_Call_Audit__c.value;
            let answeredQuestion = 0;
            let totalQuestion = 0;
            if(this.caseRecord1.fields.Audit_Score__c.value != null){
                answeredQuestion += this.Customer_360_Review == 'Yes' ? 1 : 0;
                answeredQuestion += this.PRD_Entitlement == 'Yes' ? 1 : 0;
                answeredQuestion += this.Account_Customer_Name == 'Yes' ? 1 : 0;
                answeredQuestion += this.Record_Type == 'Yes' ? 1 : 0;
                answeredQuestion += this.Customer_Success_Fields == 'Yes' ? 1 : 0;
                answeredQuestion += this.Private_Public_Comments == 'Yes' ? 1 : 0;
                answeredQuestion += this.Mode_of_Communication == 'Yes' ? 1 : 0; 
                answeredQuestion += this.Customer_Follow_up == 'Yes' ? 1 : 0;
                answeredQuestion += this.Onboarding_Completed == 'Yes' ? 1 : 0;
                totalQuestion += this.Customer_360_Review == 'NA' || this.Customer_360_Review == null  ? 0 : 1;
                totalQuestion += this.PRD_Entitlement == 'NA' || this.PRD_Entitlement == null? 0 : 1;
                totalQuestion += this.Account_Customer_Name == 'NA' || this.Account_Customer_Name == null? 0 : 1;
                totalQuestion += this.Record_Type == 'NA'|| this.Record_Type == null ? 0 : 1;
                totalQuestion += this.Customer_Success_Fields == 'NA' || this.Customer_Success_Fields == null? 0 : 1;
                totalQuestion += this.Private_Public_Comments == 'NA' || this.Private_Public_Comments == null? 0 : 1;
                totalQuestion += this.Mode_of_Communication == 'NA' || this.Mode_of_Communication == null? 0 : 1;
                totalQuestion += this.Customer_Follow_up == 'NA'|| this.Customer_Follow_up == null ? 0 : 1;
                totalQuestion += this.Onboarding_Completed == 'NA'|| this.Onboarding_Completed == null ? 0 : 1;
                this.caseRecordUpdate["Customer_360_Review__c"] = this.Customer_360_Review;
                this.caseRecordUpdate['PRD_Entitlement__c'] =this.PRD_Entitlement;
                this.caseRecordUpdate['Account_Customer_Name__c'] =this.Account_Customer_Name;
                this.caseRecordUpdate['Record_Type__c'] =this.Record_Type;
                this.caseRecordUpdate['Customer_Success_Fields__c'] =this.Customer_Success_Fields;
                this.caseRecordUpdate['Private_Public_Comments__c'] =this.Private_Public_Comments;
                this.caseRecordUpdate['Mode_of_Communication__c'] =this.Mode_of_Communication;
                this.caseRecordUpdate['Customer_Follow_up__c'] =this.Customer_Follow_up;
                this.caseRecordUpdate['Onboarding_Completed__c'] =this.Onboarding_Completed;
                this.casePercentage = ((answeredQuestion / totalQuestion)*100).toFixed(0);
                this.casePercentage =  isNaN(this.casePercentage) ? 0 : this.casePercentage;
                this.caseAnswered= answeredQuestion;
                this.caseTotalAnswered = totalQuestion;

            }
            if(this.caseRecord1.fields.Call_Audit_Score__c.value != null){
                answeredQuestion = 0;
                totalQuestion = 0;
                answeredQuestion += this.Technical_Skills == 'Yes' ? 1 : 0;
                answeredQuestion += this.Case_Closure == 'Yes' ? 1 : 0;
                answeredQuestion += this.Discovery == 'Yes' ? 1 : 0;
                answeredQuestion += this.Call_Flow == 'Yes' ? 1 : 0;
                answeredQuestion += this.Communication_Call_Audit == 'Yes' ? 1 : 0;
                answeredQuestion += this.Walkthrough_Product == 'Yes' ? 1 : 0;
                answeredQuestion += this.Query_Handling == 'Yes' ? 1 : 0; 
                answeredQuestion += this.Customer_Sentiment == 'Yes' ? 1 : 0;
                answeredQuestion += this.Call_Documentation == 'Yes' ? 1 : 0;
                totalQuestion += this.Technical_Skills == 'NA' || this.Technical_Skills == null? 0 : 1;
                totalQuestion += this.Case_Closure == 'NA' || this.Case_Closure == null? 0 : 1;
                totalQuestion += this.Discovery == 'NA' || this.Discovery == null? 0 : 1;
                totalQuestion += this.Call_Flow == 'NA' || this.Call_Flow == null? 0 : 1;
                totalQuestion += this.Communication_Call_Audit == 'NA' || this.Communication_Call_Audit == null? 0 : 1;
                totalQuestion += this.Query_Handling == 'NA' || this.Query_Handling == null? 0 : 1;
                totalQuestion += this.Walkthrough_Product == 'NA' || this.Walkthrough_Product == null? 0 : 1;
                totalQuestion += this.Customer_Sentiment == 'NA' || this.Customer_Sentiment == null? 0 : 1;
                totalQuestion += this.Call_Documentation == 'NA' || this.Call_Documentation == null? 0 : 1;
                this.caseRecordUpdate["Technical_Skills__c"] =this.Technical_Skills;
                this.caseRecordUpdate["Case_Closure__c"] =this.Case_Closure;
                this.caseRecordUpdate["Discovery__c"] =this.Discovery;
                this.caseRecordUpdate["Call_Flow__c"] =this.Call_Flow;
                this.caseRecordUpdate["Communication_Call_Audit__c"] =this.Communication_Call_Audit;
                this.caseRecordUpdate["Walkthrough_and_product_awareness__c"] =this.Walkthrough_Product;
                this.caseRecordUpdate["Query_handling_Issue_Analysis__c"] =this.Query_Handling;
                this.caseRecordUpdate["Customer_Sentiment__c"] =this.Customer_Sentiment;
                this.caseRecordUpdate["Call_Documentation__c"] =this.Call_Documentation;
                this.callPercentage = ((answeredQuestion / totalQuestion)*100).toFixed(0);
                this.callPercentage =  isNaN(this.callPercentage) ? 0 : this.callPercentage;
                this.callAnswered = answeredQuestion;
                this.callTotalAnswered = totalQuestion;
            }
            //this.alreadySubmitted = this.caseRecord1.fields.Audit_Score__c.value !=null ? true : false;
        } else if(error){
          
            console.log(error);
            console.log(error.body.message);
            
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

        if(this.formType == 'Case'){
            fields.Customer_360_Review__c = this.caseRecordUpdate.Customer_360_Review__c;
            fields.PRD_Entitlement__c = this.caseRecordUpdate.PRD_Entitlement__c;
            fields.Record_Type__c = this.caseRecordUpdate.Record_Type__c;
            fields.Account_Customer_Name__c = this.caseRecordUpdate.Account_Customer_Name__c;
            fields.Customer_Success_Fields__c = this.caseRecordUpdate.Customer_Success_Fields__c;
            fields.Private_Public_Comments__c = this.caseRecordUpdate.Private_Public_Comments__c;
            fields.Customer_Follow_up__c = this.caseRecordUpdate.Customer_Follow_up__c;
            fields.Mode_of_Communication__c = this.caseRecordUpdate.Mode_of_Communication__c;
            fields.Onboarding_Completed__c = this.caseRecordUpdate.Onboarding_Completed__c;
            fields.Audit_Score__c = this.percentage;
            
            fields.Case_Audit_Timestamp__c = someDate.toISOString();  
        }else{
            fields.Technical_Skills__c = this.caseRecordUpdate.Technical_Skills__c;
            fields.Case_Closure__c = this.caseRecordUpdate.Case_Closure__c;
            fields.Discovery__c =this.caseRecordUpdate.Discovery__c;
            fields.Call_Flow__c =this.caseRecordUpdate.Call_Flow__c;
            fields.Walkthrough_and_product_awareness__c =this.caseRecordUpdate.Walkthrough_and_product_awareness__c;
            fields.Query_handling_Issue_Analysis__c =this.caseRecordUpdate.Query_handling_Issue_Analysis__c;
            fields.Customer_Sentiment__c =this.caseRecordUpdate.Customer_Sentiment__c;
            fields.Call_Documentation__c =this.caseRecordUpdate.Call_Documentation__c;
            fields.Communication_Call_Audit__c =this.caseRecordUpdate.Communication_Call_Audit__c;
            fields.Call_Audit_Score__c = this.percentage;
            fields.Call_Audit_Timestamp__c = someDate.toISOString();  
        }
       
      
        fields.Auditor_Name__c=this.currentUserName;
        fields.Auditor_Email_Id__c=this.currentUserEmail;
        //fields.Other_Feedback_Observations__c=fields.Other_Feedback_Observations__c+'<{@}>';
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

    handleBack(event) {
        this.showCaseForm = false;
        this.showCallForm = false;
        this.showSelectForm = true;
    }
    
}