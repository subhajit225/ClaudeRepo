import { LightningElement, api, wire, track } from 'lwc';
// stanatard methods
import { getRecord, createRecord, updateRecord, deleteRecord } from 'lightning/uiRecordApi';
import TIME_ZONE  from '@salesforce/i18n/timeZone';
// apex methods
import getEscalationDetails from '@salesforce/apex/EscalationManagementTeamController.getEscalationDetails';
import recentCaseListAction from '@salesforce/apex/EscalationManagementTeamController.recentCaseListAction';
import getDraftLessonsLearned from '@salesforce/apex/EscalationManagementTeamController.getDraftLessonsLearned';
// current userid
import Id from '@salesforce/user/Id';
// toast message
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// Close Quick Action Modal
import { CloseActionScreenEvent } from 'lightning/actions';
// Alert modal
import LightningConfirm from "lightning/confirm";

export default class LessonsLearnt extends LightningElement {

    @api recordId
    currentUserName
    showSpinner = false
    sobjectName = 'Lessons_Learned__c'
    lessonLearnedTemplateFields = ['Case__c', 
                                    'Account__c',
                                    'Business_impact_media_attention__c', 
                                    'Case_Priority__c',
                                    'Customer_GEO__c',
                                    'Escalation__c',
                                    'Escalation_Manager_Owner__c',
                                    'Issue_Summary__c',
                                    'JIRA_Reference__c',
                                    'AHA_reference__c',
                                    'Lessons_Learned_Attendees__c',
                                    'Lessons_Learnt_Status__c',
                                    'Product_Area_s__c',
                                    'Slack_channel__c', 
                                    'Stakeholders__c'];

    // Recent Cases
    caseList = []
    columns = [
        { label: 'Case Number', fieldName: 'CaseURL', type: 'url',
            typeAttributes: {
                label: {
                    fieldName: 'CaseNumber'
                }, 
                target: '_new'
            } 
        },
        { label: 'Name', fieldName: 'OwnerName' },
        { label: 'Status', fieldName: 'Status'},
        { label: 'Priority', fieldName: 'Priority' },
        { label: 'Subject', fieldName: 'Subject' },
        { label: 'JIRA Reference', fieldName: 'Jira_Reference_urls__c' },
        { label: 'Date/Time Opened', fieldName: 'CreatedDate',type: 'date', 
            typeAttributes:{
                month: "2-digit",
                day: "2-digit",
                year: "numeric",
                hour: "2-digit",
                minute: "2-digit",
                hour12: true ,
                timeZone: TIME_ZONE 
            } 
        },
        { label: 'Date/Time Closed', fieldName: 'ClosedDate',type: 'date', 
            typeAttributes:{
                month: "2-digit",
                day: "2-digit",
                year: "numeric",
                hour: "2-digit",
                minute: "2-digit",
                hour12: true ,
                timeZone: TIME_ZONE 
            } 
         },
    ];

    // save as drafg
    @track fields = {}
    @track draftLlId
    @track isDraft = false
    @track error
    @track draftLastModifiedDate
    
    @wire(getEscalationDetails, {esclId: '$recordId'}) 
    async fetchDeatils({error, data}){
        this.showSpinner = true;
        if(data){
            // fetch draft Lessons Learned record
            this.fetchDraftLl(data.Id);
            this.displayFieldValues(data);
        }else{
            console.log('getEscalationDetails ERROR: ', error);
        }
        this.showSpinner = false;
    }

    async fetchDraftLl(esclId){
        this.showSpinner = true;
        await getDraftLessonsLearned({'escId':esclId})
        .then((result) => {
            console.log('getDraftLessonsLearned resw '+ JSON.stringify(result[0]));
            if(result.length == 0){
                // create draft LL, soon as open modal popup
                console.log('fieldsdraftLlId '+ JSON.stringify(this.draftLlId));
                if(!this.draftLlId){
                    let fields = this.fields;
                    fields.isDraft__c = true;
                    this.insertDraftLl(fields);
                }
            }else{
                this.draftLlId = result[0].Id;
                this.draftLastModifiedDate = result[0].LastModifiedDate;
                this.isDraft = true;
            }
        })
        .catch((error) => {
            console.log('getDraftLessonsLearned '+ JSON.stringify(error));
        })
        .finally(() =>{
            this.showSpinner = false;
        })
    }

    @wire(getRecord, { recordId: Id, fields: ['User.Name']}) 
    userDetails({error, data}) {
        if (data) {
            this.currentUserName = data.fields.Name.value;
        } else if (error) {
            console.log('userDetails ERROR: ', error);
        }
    }

    async displayFieldValues(objEscl){
        let fields = this.fields;
        fields.Idea_Reference__c = objEscl.Case__r.Idea_Reference__c;
        const inputFields = this.template.querySelectorAll('lightning-input-field');
        if (inputFields) {
            inputFields.forEach(field => {
                if(field.fieldName == 'Lessons_Learnt_Status__c'){
                    field.value = 'Open';
                    fields.Lessons_Learnt_Status__c = field.value;
                }
                if(field.fieldName == 'Case__c'){
                    field.value = objEscl.Case__c ? objEscl.Case__c : null;
                    // for draft LL record
                    this.fields.Case__c = objEscl.Case__c ? objEscl.Case__c : null;
                    field.isReadOnly = 'true';
                }
                if(field.fieldName == 'Account__c'){
                    field.value = objEscl.Account__c ? objEscl.Account__c : null;
                }
                if(field.fieldName == 'Business_impact_media_attention__c'){
                    field.value = objEscl.Business_impact_media_attention__c ? objEscl.Business_impact_media_attention__c : null;
                    fields.Business_impact_media_attention__c = field.value;
                }
                if(field.fieldName == 'Case_Priority__c'){
                    field.value = objEscl.Case_Priority__c ? objEscl.Case_Priority__c : null;
                }
                if(field.fieldName == 'Closed_Date__c'){
                    field.value = objEscl.Closed_Date__c ? objEscl.Closed_Date__c : null;
                    fields.Closed_Date__c = field.value;
                }
                if(field.fieldName == 'Customer_Geo__c'){
                    field.value = objEscl.Customer_Geo__c ? objEscl.Customer_Geo__c : null;
                    fields.Customer_Geo__c = field.value;
                }
                if(field.fieldName == 'Escalation__c'){
                    field.value = objEscl.Id ? objEscl.Id : null;
                    // for draft LL record
                    this.fields.Escalation__c = objEscl.Id ? objEscl.Id : null;
                }
                if(field.fieldName == 'JIRA_Reference__c'){
                    field.value = objEscl.JIRA_Reference__c ? objEscl.JIRA_Reference__c : null;
                    fields.JIRA_Reference__c = field.value;
                }
                if(field.fieldName == 'Slack_channel__c'){
                    field.value = objEscl.Slack_channel__c ? objEscl.Slack_channel__c : null;
                }
                if(field.fieldName == 'AHA_reference__c'){
                    field.value = objEscl.AHA_reference__c ? objEscl.AHA_reference__c : null;
                    fields.AHA_reference__c = field.value;
                }
                this.fields = fields;
            });
        }
        this.showSpinner = false;

        this.fetchCaseRecords('RecentCases');
    }

    handleOpenCases(){
        this.fetchCaseRecords('OpenCases');
    }

    handleClosedCases(){
        this.fetchCaseRecords('ClosedCases');
    }

    handleRelatedCases(){
        this.fetchCaseRecords('RelatedCases');
    }

    async fetchCaseRecords(listViewFilter){
        this.showSpinner = true;
        await recentCaseListAction({ esclId: this.recordId , filterCondition : listViewFilter})
        .then((result) => {
            if(result){
                this.caseList = result.map(row=>{
                    return{...row, CaseURL : '/' + row.Id, OwnerName : row.Owner.Name}
                })
            }
            this.error = undefined;
            this.showSpinner = false;
        })
        .catch((error) => {
            console.log('recentCaseListAction ERROR: ', error);
            this.caseList = undefined;
            this.showSpinner = false;
        });
    }

    handleSuccess(event) {
        let recordId = event.detail.id;
        this.showToast('Success', 'Record '+event.detail.fields.Lessons_Learned_Number__c.value+' Crearted Successfully!', 'success');
        // Close the action panel
        this.closeAction();
    }

    handleSubmit(event){
        event.preventDefault();
        const fields = event.detail.fields;
        fields.Owner__c = Id;
        fields.Reported_By__c = Id;
        fields.isDraft__c = false;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    //save as draft
    handleChange(event){
        this.showSpinner = true;
        let fldVal = event.target.value;
        let fldApi = event.target.name;

        let fields = this.fields;
        fields.isDraft__c = true;

        if(fldVal){
            // Store changes values 
            fields[fldApi] = fldVal;

            if(fldApi == 'Case__c'
                && fldVal){
                    this.error = '';
                    fields.Case__c = fldVal;
                    this.fetchCaseRecord(fldVal, fields);

                    // Deplay for record insert/update
                    setTimeout(() => {
                        // Record Update
                        if(!this.draftLlId){
                            this.insertDraftLl(fields);
                        }
                        // Record Insert
                        else{
                            fields.Id = this.draftLlId;
                            this.updateDraftLl(fields);
                        }
                    }, 1000); 
            }else{
                // Check if Case field is selected
                if(fields.Case__c != null 
                    && fields.Case__c != ""){
                        this.error = '';
                        
                        // Deplay for record insert/update
                        setTimeout(() => {
                            // Record Update
                            if(!this.draftLlId){
                                this.insertDraftLl(fields);
                            }
                            // Record Insert
                            else{
                                let fields = {};
                                fields[fldApi] = fldVal;
                                fields.Id = this.draftLlId;
                                this.updateDraftLl(fields);
                            }
                        }, 1000); 
                }
                // Display error if Case field is Not selected
                else{
                    fields.Case__c = null;
                    alert('WARNING: Please select Case field before filling other details.');
                    // this.error = 'Please select Case field before filling other details on this page!'
                }
                this.showSpinner = false;
            }
        }
        // When value removed on field
        else{
            fields[fldApi] = fldVal;
            this.showSpinner = false;
        }
        this.fields = fields;
    }

    insertDraftLl(fields){
        console.log('insertDraftLl fields: ', JSON.stringify(fields));
        const recordInput = {
            apiName: 'Lessons_Learned__c',
            fields: fields
        };
        
        createRecord(recordInput)
        .then((noteRec) => {
            this.draftLlId = noteRec.id;
            console.log('createRecord:rec: ', JSON.stringify(noteRec));
        })
        .catch(error => {
            // fields.Section_Type__c = '';
            console.log('createRecord error: ',error);
            this.error = error.body.output.errors[0].message;
        });
    }

    // DRAFT
    updateDraftLl(fields){
        console.log('updateDraftLl fields: ', JSON.stringify(fields));
        const recordInput = {
            fields: fields
        };
        
        updateRecord(recordInput)
        .then((noteRec) => {
            console.log('updateRecord:rec: ', JSON.stringify(noteRec));
        })
        .catch(error => {
            console.log('updateRecord error: ',error);
            this.error = error.body.output.errors[0].message;
        });
    }

    // draft options change
    async handleDraftOptions(event) {
        let optionVal = event.detail.value;
        console.log('optionVal:: ', optionVal);

        // populate draft record values on fields
        if(optionVal == 'edit'){
            this.isDraft = false;
        }
        // delete draft escalation record 
        else{
            const result = await LightningConfirm.open({
                message: "are you sure, you want to delete this draft Lessons Learned?",
                variant: "default", // headerless
                label: "Delete a record"
            });
            if (result) {
                await deleteRecord(this.draftLlId)
                this.draftLlId = '';
                // remove DRAFT button after record delete
                this.isDraft = false;
                this.handleCancel();
            }
        }
    }

    showToast(title, msg, type) {
        const event = new ShowToastEvent({
            title: title,
            message: msg,
            variant: type,
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    handleCancel(){
        // Close the action panel
        this.closeAction();
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}