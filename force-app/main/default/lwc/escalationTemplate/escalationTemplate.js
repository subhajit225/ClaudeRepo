import { LightningElement, api, wire, track} from 'lwc';
// navigation
import { NavigationMixin } from 'lightning/navigation';
// toast message
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// stanatard methods
import { getRecord, createRecord, updateRecord } from 'lightning/uiRecordApi';
// apex methods
import getCaseDetails from '@salesforce/apex/EscalationManagementTeamController.getCaseDetails';
import attachCaseNotes from '@salesforce/apex/EscalationManagementTeamController.attachCaseNotes';
// Draft
import getDraftEscalation from '@salesforce/apex/EscalationManagementTeamController.getDraftEscalation';
// current userid
import Id from '@salesforce/user/Id';
import LightningConfirm from "lightning/confirm";

export default class EscalationTemplate extends NavigationMixin(LightningElement) {
    sobjectName = 'Escalation__c';
    @api templateDetail = {};
    @track escalationObj = {'recordId':'', 'isEdit':true}
    isEdit = true
    currentUserName
    showSpinner = false
    userId = Id
    caseRecord = {}
    // escalation Id
    @track recordId
    // draft
    @track fields = {}
    @track draftEscalationId
    @track draftLastModifiedDate
    @track isDraft = true;
    @track isInsightVal = false
    @track error
    
    @track savedRecord = {'er_recordId':'',
                            'er_isEdit':true,
                            'es_recordId':'',
                            'es_isEdit':true,
                            'er_draft':{'Id':'', 'CaseId':''},
                            'es_draft':{'Id':'', 'CaseId':''}};


    @wire(getRecord, { recordId: Id, fields: ['User.Name']}) 
    userDetails({error, data}) {
        if (data) {
            this.currentUserName = data.fields.Name.value;
            this.error = '';
        } else if (error) {
            console.log('userDetails error: ', error);
            this.error = error.body.message;
        }
    }

    @api
    handleSectionChange(templateInfo){
        console.log('handleSectionChange: ', JSON.parse(JSON.stringify(templateInfo)));
        // this.templateInfo = Object.assign({}, templateInfo);
        // this.templateDetail.mode = this.templateDetail.recordId ? 'view' : 'edit';

        // Existing Error occured and On Option change when record deleted: removing displayed error from screen
        this.error = '';
        if(templateInfo.type == 'Ransomware'){
            // draft details
            this.escalationObj.isEdit = true;
            this.escalationObj.recordId = templateInfo.er_draft.Id ? templateInfo.er_draft.Id : '';
            this.draftEscalationId = templateInfo.er_draft.Id ? templateInfo.er_draft.Id : '';
            this.fields.Case__c = templateInfo.er_draft.CaseId ? templateInfo.er_draft.CaseId : '';
            this.draftLastModifiedDate = templateInfo.er_draft.lastmodifieddate ? templateInfo.er_draft.lastmodifieddate : '';
                
            if(templateInfo.er_recordId){
                this.escalationObj.isEdit = false;
                this.escalationObj.recordId = templateInfo.er_recordId;
            }
        }
        else if(templateInfo.type == 'Escalation'){
                // draft details
                this.escalationObj.isEdit = true;
                this.escalationObj.recordId = templateInfo.es_draft.Id ? templateInfo.es_draft.Id : '';
                this.draftEscalationId = templateInfo.es_draft.Id ? templateInfo.es_draft.Id : '';
                this.fields.Case__c = templateInfo.es_draft.CaseId ? templateInfo.es_draft.CaseId : '';
                this.draftLastModifiedDate = templateInfo.es_draft.lastmodifieddate ? templateInfo.es_draft.lastmodifieddate : '';

                if(templateInfo.es_recordId){
                    this.escalationObj.isEdit = false;
                    this.escalationObj.recordId = templateInfo.es_recordId;
                }
        }
        
        // Field to nulls and Draft Escalation record is deleted: When tab selection is are changed
        if(!this.escalationObj.recordId){
            this.escalationObj.isEdit = true;
            this.escalationObj.recordId = '';
            this.handleReset();
        }
        console.log('UI Var update: ', JSON.parse(JSON.stringify(this.escalationObj)));
        
    }

    get getMode(){
        return this.escalationObj.isEdit;
    }

    handleChange(event){
        this.showSpinner = true;
        let fldVal = event.target.value;
        let fldApi = event.target.name;

        let fields = this.fields;
        fields.isDraft__c = true;
        fields.RecordTypeId = this.templateDetail.recordtypeId;

        console.log('fldVal: ', fldVal);
        console.log('fldApi: ', fldApi);
        
        if(fldApi == 'is_there_a_relevant_insight_in_SentryAI__c'){
            this.isInsightVal = fldVal;
        }
        
        if(fldVal){
            if(fldApi == 'Case__c'
            && fldVal){
                this.error = '';
                fields.Case__c = fldVal;
                this.fetchCaseRecord(fldVal, fields);

                // Deplay for record insert/update
                setTimeout(() => {
                    fields[fldApi] = fldVal;
                    
                    // Record Update
                    if(!this.draftEscalationId){
                        console.log('INSERT: ', JSON.stringify(fields));
                        this.insertDraftNote(fields);
                    }
                    // Record Insert
                    else{
                        fields.Id = this.draftEscalationId;
                        console.log('UPDATE: ', JSON.stringify(fields));
                        this.updateDraftNote(fields);
                    }
                }, 1000); 
            }else{
                // Store changes values 
                fields[fldApi] = fldVal;
                // Check if Case field is selected
                if(fields.Case__c != null && fields.Case__c != ""){
                    this.error = '';
                    console.log('fldApi: ', fldApi, ' :fldVal: ', fldVal);
                    console.log('draftEscalationId: ', this.draftEscalationId);
                    
                    // Deplay for record insert/update
                    setTimeout(() => {
                        // Record Update
                        if(!this.draftEscalationId){
                            console.log('INSERT: ', JSON.stringify(fields));
                            this.insertDraftNote(fields);
                        }
                        // Record Insert
                        else{
                            let fields = {};
                            fields[fldApi] = fldVal;
                            fields.Id = this.draftEscalationId;
                            console.log('UPDATE: ', JSON.stringify(fields));
                            this.updateDraftNote(fields, false);
                        }
                    }, 1000); 
                }
                // Display error if Case field is Not selected
                else{
                    fields.Case__c = null;
                    alert('WARNING: Please select Case field before filling other details.');
                    // this.error = 'Please select Case field before filling other details on this page!'
                }
            }
        }
        // When value removed on field
        else{
            fields[fldApi] = fldVal;
        }
        this.fields = fields;
        this.showSpinner = false;
    }

    insertDraftNote(fields){
        console.log('insertDraftNote fields: ', JSON.stringify(fields));
        const recordInput = {
            apiName: 'Escalation__c',
            fields: fields
        };
        
        createRecord(recordInput)
        .then((noteRec) => {
            this.draftEscalationId = noteRec.id;
            if(this.templateDetail.type == 'Ransomware'){
                this.savedRecord.er_draft.Id = noteRec.id;
            }else{
                this.savedRecord.es_draft.Id = noteRec.id;
            }
            console.log('createRecord:rec: ', JSON.stringify(noteRec));
            // Pass draft recordId to parent Cmp
            const selectedEvent = new CustomEvent("escalationchange", {
                detail: this.savedRecord
            });
            // Dispatches the event.
            this.dispatchEvent(selectedEvent);
        })
        .catch(error => {
            // fields.Section_Type__c = '';
            console.log('createRecord error: ',error);
            this.error = error.body.output.errors[0].message;
            this.showSpinner = false;
        })
    }

    // isSaved will be true only when Escalation saved w/o draft.
    // isSaved will be true for Re-Editing saved field: to keep template on edit view 
    updateDraftNote(fields, isSaved){
        console.log('updateDraftNote fields: ', JSON.stringify(fields));
        const recordInput = {
            fields: fields
        };
        
        updateRecord(recordInput)
        .then((noteRec) => {
            console.log('updateRecord:rec: ', JSON.stringify(noteRec));
            if(!this.isDraft && isSaved){
                this.handleSuccess();
            }
        })
        .catch(error => {
            console.log('updateRecord error: ',error);
            let errorObj = error.body.output;
            if(errorObj.errors 
                && errorObj.errors[0]){
                    this.error = error.body.output.errors[0].message;
            }
            this.showSpinner = false;
        })
    }

    fetchCaseRecord(caseId, fields){
        getCaseDetails({ caseId: caseId})
        .then((result) => {
            this.error = '';
            console.log('result: ', JSON.stringify(result));
            this.caseRecord = result.caseRecord;
            // field save in bakend
            fields.Idea_Reference__c = this.caseRecord.Idea_Reference__c;
            this.displayFieldValues(result.caseRecord, result, fields);
        })
        .catch((error) => {
            console.log('fetchCaseRecord error: ', error);
            this.error = error.body.message;
            this.showSpinner = false;
        });   
    }

    displayFieldValues(objCase, wrapperResult, fields){
        const inputFields = this.template.querySelectorAll('lightning-input-field');
        if (inputFields) {
            inputFields.forEach(field => {
                if(field.fieldName == 'Account__c'){
                    field.value = objCase.AccountId ? objCase.Account.Name : null;
                }
                if(field.fieldName == 'Customer_preferred_time_zone_of_contact__c'){
                    field.value = objCase.Case_Time_Zone__c ? objCase.Case_Time_Zone__c : null;
                }
                if(field.fieldName == 'Case_Priority__c'){
                    field.value = objCase.Priority ? objCase.Priority : null;
                }
                if(field.fieldName == 'Cluster_UUID__c'){
                    field.value = objCase.Cluster__c ? objCase.Cluster__r.uuid__c : null;
                }
                if(field.fieldName == 'Cluster_Stats_SentryAI_URL__c'){
                    field.value = objCase.SentryAI_URL__c ? objCase.SentryAI_URL__c : null;
                }
                if(field.fieldName == 'Current_Rubrik_CDM_version__c'){
                    field.value = objCase.Software_Version__c ? objCase.Software_Version__c : null;
                }
                if(field.fieldName == 'JIRA_Reference__c'){
                    field.value = objCase.Jira_Reference_urls__c ? objCase.Jira_Reference_urls__c : null;
                    fields.JIRA_Reference__c = field.value;
                }
                if(field.fieldName == 'Support_Tunnel__c'){
                    field.value = objCase.Support_Tunnel__c ? objCase.Support_Tunnel__c : null;
                }
                if(field.fieldName == 'Slack_channel__c'){
                    field.value = objCase.Slack_channel__c ? objCase.Slack_channel__c : null;
                }
                if(field.fieldName == 'Heads_up_to_support_team__c'){
                    field.value = objCase.AccountId ? wrapperResult.headsUpString : null;
                    fields.Heads_up_to_support_team__c = field.value;
                }
                if(field.fieldName == 'Tagged_KB_article__c'){
                    field.value = wrapperResult.existingArticles ? wrapperResult.existingArticles : null;
                    fields.Tagged_KB_article__c = field.value;
                }
                if(field.fieldName == 'Grafana_Link__c'){
                    field.value = objCase.Grafana_Link__c ? objCase.Grafana_Link__c : null;
                }
                if(field.fieldName == 'AHA_reference__c'){
                    field.value = objCase.AHA_reference__c ? objCase.AHA_reference__c : null;
                    fields.AHA_reference__c = field.value;
                }
                if(field.fieldName == 'Escalation_Manager_Owner__c'){
                    field.value = objCase.EscalationManagerOwner__c ? objCase.EscalationManagerOwner__r.Id : null;
                    fields.Escalation_Manager_Owner__c = field.value;
                }
                if(field.fieldName == 'Idea_Reference__c'){
                    field.value = objCase.Idea_Reference__c ? objCase.Idea_Reference__c : null;
                    fields.Idea_Reference__c = field.value;
                }
            });
        }
        this.showSpinner = false;
    }

    handleReset() {
        const inputFields = this.template.querySelectorAll('lightning-input-field');
        if (inputFields) {
            inputFields.forEach(field => {
                field.reset();
            });
        }
    }

    handleEdit(){
        this.escalationObj.isEdit = true;
    }

    handleContinue(){
        let recordId = '';
        if(this.templateDetail.type == 'Ransomware'){
            recordId = this.templateDetail.er_recordId;
        }else{
            recordId = this.templateDetail.es_recordId;
        }
        this.navigateToViewPage(recordId);
    }

    handleCancel(){
        this.escalationObj.isEdit = false;
        if(!this.escalationObj.recordId){
            const selectedEvent = new CustomEvent('loadmainpage');
            this.dispatchEvent(selectedEvent);
        }
    }

    handleSuccess() {

        // Continue button will be hidden when Escalation record saved as Draft
        this.isEdit = false;
        let recordId = this.draftEscalationId;
        this.transferNotes(recordId);

        this.escalationObj.recordId = recordId;
        this.escalationObj.isEdit = false;
        this.templateDetail = Object.assign({}, this.templateDetail);
        if(this.templateDetail.type == 'Ransomware'){
            this.templateDetail.er_recordId = recordId;
            this.templateDetail.er_isEdit = false;
            this.savedRecord.er_draft.Id = '';
            this.savedRecord.er_recordId = recordId;
            this.savedRecord.er_isEdit = false;
        }else{
            this.templateDetail.es_recordId = recordId;
            this.templateDetail.es_isEdit = false;
            this.savedRecord.es_draft.Id = '';
            this.savedRecord.es_recordId = recordId;
            this.savedRecord.es_isEdit = false;
        }

        const selectedEvent = new CustomEvent("escalationchange", {
            detail : this.savedRecord
        });
        // Dispatches the event.
        this.dispatchEvent(selectedEvent);
        this.showSpinner = false;
    }

    handleSubmit(){
        this.showSpinner = true;
        console.log('this.userId: ', this.draftEscalationId);
        console.log('this.fields: ', JSON.stringify(this.fields));

        // Draft Id wil be assigned when any field changes on UI
        if(this.draftEscalationId){

            this.isDraft = false;
            const fields = this.fields
            fields.Id = this.draftEscalationId;
            fields.isDraft__c = false;
            fields.RecordTypeId = this.templateDetail.recordtypeId;
            fields.Reported_By__c = this.userId;
            fields.Owner__c = this.userId;

            if(!fields.Case__c){
                this.showSpinner = false;
                const result = LightningConfirm.open({
                    message: "Please select Case",
                    variant: "default", // headerless
                    label: "Required Field missing!"
                });
            }
            // Insight_Id_is_required if is_there_a_relevant_insight_in_SentryAI__c set to true
            else if(this.isInsightVal
                && !fields.Insight_Id__c){
                    this.showSpinner = false;
                    const result = LightningConfirm.open({
                        message: "Please fill Insight Id when \"is there a relevant insight in SentryAI\" is set to true",
                        variant: "default", // headerless
                        label: "Required Field missing!"
                    });
            }else{
                if(fields.Insight_Id__c){
                    fields.is_there_a_relevant_insight_in_SentryAI__c = true;
                }
                console.log('handleSubmit UPDATE: ', JSON.stringify(fields));
                this.updateDraftNote(fields, true);
            }
        }
    }
    
    transferNotes(recordId){
        attachCaseNotes({ caseId: this.caseRecord.Id, escId : recordId})
            .then((result) => {
                console.log('result: ', result);
            })
            .catch((error) => {
                console.log('fetchCaseRecord error: ', error);
                this.showSpinner = false;
            });   
    }

    // Navigate to View Page
    navigateToViewPage(recordId) {
        window.location.href='/'+recordId;
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
}