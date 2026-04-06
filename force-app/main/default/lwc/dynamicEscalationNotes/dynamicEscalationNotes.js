import { LightningElement, api, wire, track } from 'lwc';
// standard methods
import { getRecord, createRecord, updateRecord } from 'lightning/uiRecordApi';
// apex methods
import sendCaseComment from '@salesforce/apex/EscalationManagementTeamController.sendCaseComment';
import getDraftNote from '@salesforce/apex/EscalationManagementTeamController.getDraftNote';
import getNotesStatusPickListValues from '@salesforce/apex/EscalationManagementTeamController.getNotesStatusPickListValues';

export default class DynamicEscalationNotes extends LightningElement {
    
    objectApiName = 'Note__c'
    @api recordId
    noteVal 
    escalationName
    // parent params
    @api notesLabel
    @api notesTitle
    @api sectionType
    @api fields
    @api sObjectLabel
    @track showSpinner = false
    // autosave
    @track autoSaveVal 
    @track draftrecord = {}
    @track draftLastModifiedDate
    @track autoDraftNoteFields = {};
    @track isInValidDate = false;
    // 2011
    llStatus = {}

    // Addtional formats/properties for input rich text field
    allowedFormats = [
        'font',
        'size',
        'bold',
        'italic',
        'underline',
        'strike',
        'list',
        'indent',
        'align',
        'link',
        'image',
        'clean',
        'table',
        'header',
        'color',
        'background',
        'code',
        'code-block',
        'script',
        'blockquote',
        'direction',
    ];

    @wire(getRecord, { recordId: '$recordId', fields:  '$fields'})
    fetchEscalation({error, data}) {
        this.showSpinner = true;
        if (data) {
            // console.log('data: ', JSON.stringify(data));
            if(this.sObjectLabel == 'Escalation'){
                let recordTypeName = data.recordTypeInfo.name;
                if(recordTypeName.includes('Ransomware')){
                    this.escalationName = data.fields.Escalation_Ransomware_Number__c.value;
                }else{
                    this.escalationName = data.fields.Escalation_Support_Number__c.value;
                }
            }else if(this.sObjectLabel == 'Lesson Learned'){
                this.escalationName = data.fields.Lessons_Learned_Number__c.value;
            }
            this.fetchLessonsLearnedStatus();
            this.fetchDraftnote(data.id);
        } else if (error) {
            console.log('fetchEscalation ERROR: ',error);
        }
    }

    // CS21-2011
    fetchLessonsLearnedStatus(){
        getNotesStatusPickListValues()
        .then(data => {
            // Map the data to an array of options
            this.llStatus = data.map(option => {
                return {
                    label: option.label,
                    value: option.value
                };
            });
        })
        .catch(error => {
            console.log('getNotesStatusPickListValues: ', JSON.stringify(error));
            this.error = error;
        })
        .finally(() => {
            this.showSpinner = false;
        })
    }

    handleChange(event) {
        this.value = event.detail.value;
    }
    
    fetchDraftnote(recId){
        getDraftNote({ SectionType: this.sectionType, recordId: recId})
        .then(data => {
            // console.log('fetchDraftNote data: ',JSON.stringify(data));
            this.draftrecord = data;
            this.draftrecordId = data.Id;
            this.draftLastModifiedDate = data.LastModifiedDate;
            this.autoDraftNoteFields.Action_Items_Notes__c = data.Action_Items_Notes__c;
            this.autoDraftNoteFields.Area_Of_Improvement__c = data.Area_Of_Improvement__c;
            this.autoDraftNoteFields.Body__c = data.Body__c;
            this.autoDraftNoteFields.Due_Date__c = data.Due_Date__c;
            this.autoDraftNoteFields.Outcome__c = data.Outcome__c;
            this.autoDraftNoteFields.Status__c = data.Status__c;
            this.autoDraftNoteFields.Owner_s__c = data.Owner_s__c;
        })
        .catch(error => {
            console.log('getDraftNote: ', JSON.stringify(error));
            this.error = error;
        })
        .finally(() => {
            this.showSpinner = false;
        })
    }

    get renderAreaOfImpSection(){
        return this.sectionType == 'LL_Area_of_Improvement' ? true : false;
    }

    handleCancel(){
        // to reload nextStepsEscalationNotes LWC component data to show latest added Notes
        setTimeout(() => {
            eval("$A.get('e.force:refreshView').fire();");
        }, 1000); 
        // Close the action panel
        this.closeAction();
    }

    // Standard Quick Action Close icon
    disconnectedCallback() {
        this.handleCancel();
    }

    handleSubmit(event) {
        // console.log('handleSubmit sectionType: ',this.sectionType);
        
        let fields = this.autoDraftNoteFields;
        fields.isDraft__c = false;
        console.log('handleSubmit fields: ',JSON.stringify(fields));

        // Since OnBlur creates Note__c as draft, When User click save button draftrecordId is null, Added timer to fetch Id first and save as note record with draft false
        setTimeout(() => {
            console.log('draftrecordId fields: ', this.draftrecordId);
            if(this.draftrecordId){
                fields.Id = this.draftrecordId;
                // console.log('handleSubmit fields: ', JSON.stringify(fields));
                this.updateDraftNote(fields);
            }
        }, 1000); 

        // this.copyNotesOnCase();
        this.closeAction();
        // to reload nextStepsEscalationNotes LWC component data to show latest added Notes
        setTimeout(() => {
            eval("$A.get('e.force:refreshView').fire();");
        }, 1000); 
    }

    // Draft save method
    handleAutoSave(event){
        let tagName = event.target.name;
        let changeVal = event.target.value; 

        // match draft body length with current length, then only update else No
        let isChanged = false;
        if(changeVal){
            let fields = this.autoDraftNoteFields;
            
            if(tagName == 'nextStep'
                && changeVal.length != fields.Body__c){
                    if(this.draftrecordId){
                        fields.Body__c = changeVal; 
                    }else{
                        fields.Body__c = this.sObjectLabel+' Comments('+this.escalationName+'): '+ changeVal; 
                    }
                    isChanged = true;
            }else if(tagName == 'actionItems'
                && changeVal.length != fields.Action_Items_Notes__c){
                    fields.Action_Items_Notes__c = changeVal;
                    isChanged = true;
            }else if(tagName == 'aoi'
                && changeVal.length != fields.Area_Of_Improvement__c){
                    fields.Area_Of_Improvement__c = changeVal;
                    isChanged = true;
            }else if(tagName == 'owner'
                && changeVal.length != fields.Owner_s__c){
                    fields.Owner_s__c = changeVal;
                    isChanged = true;
            }else if(tagName == 'duedate'){
                    const today = new Date();
                    today.setDate(today.getDate() - 1);
                    if(new Date(changeVal) < today){
                        this.isInValidDate = true;
                    }else{
                        fields.Due_Date__c = changeVal;
                        isChanged = true;
                        this.isInValidDate = false;
                    }
            }else if(tagName == 'outcome'
                && changeVal.length != fields.Outcome__c){
                    fields.Outcome__c = changeVal;
                    isChanged = true;
            }
            // 2011
            else if(tagName == 'status'
                && changeVal.length != fields.Status__c){
                    fields.Status__c = changeVal;
                    isChanged = true;
            }

            if(isChanged){
                // draft  
                fields.isDraft__c = true;

                // console.log('draftrecordId: ',this.draftrecordId);
                if(this.draftrecordId){
                    // console.log('Id present: ');
                    fields.Id = this.draftrecordId;
                    this.updateDraftNote(fields);
                }else if(!fields.Section_Type__c){
                    this.storeOtherFields(fields);
                }

                this.autoDraftNoteFields = fields;
                // console.log('handleAutoSave: ',JSON.stringify(fields));
                // re-submit form
                // this.template.querySelector('lightning-record-edit-form').submit(fields);
            }
            
        }
        
    }

    storeOtherFields(fields){
        if(this.sObjectLabel == 'Escalation'){
            fields.Escalation__c = this.recordId;
        }else if(this.sObjectLabel == 'Lesson Learned'){
            fields.Lessons_Learned__c = this.recordId;
        }
        fields.Title__c = 'Recommendation/'+this.notesTitle;
        fields.Section_Type__c = this.sectionType;
        // console.log('storeOtherFields: ',JSON.stringify(fields));
        this.insertDraftNote(fields);
    }

    insertDraftNote(fields){
        // console.log('insertDraftNote fields: ', JSON.stringify(fields));
        const recordInput = {
            apiName: 'Note__c',
            fields: fields
        };
        
        createRecord(recordInput)
        .then((noteRec) => {
            this.draftrecordId = noteRec.id;
            console.log('createRecord:rec: ', JSON.stringify(noteRec));
        })
        .catch(error => {
            fields.Section_Type__c = '';
            this.showLoading = false;
            console.log('createRecord error: ',error);
        });
    }

    updateDraftNote(fields){
        // console.log('updateDraftNote fields: ', JSON.stringify(fields));
        const recordInput = {
            fields: fields
        };
        
        updateRecord(recordInput)
        .then((noteRec) => {
            console.log('updateRecord:rec: ', JSON.stringify(noteRec));
        })
        .catch(error => {
            console.log('updateRecord error: ',error);
        });
    }

    // handleSuccess(event) {

    //     console.log('handleSuccess: ',JSON.stringify(event.detail.fields));

    //     let fields = event.detail.fields;
    //     console.log('insert ed rec: ',fields.LastModifiedDate.value);
    //     console.log('Credate NoteId: ',fields.Name.value);
    //     this.draftrecordId = fields.Name.value;
    //     this.draftLastModifiedDate = fields.LastModifiedDate.value;
    //     console.log('draftLastModifiedDate: ',this.draftLastModifiedDate);
    //     // Copy Non Draft Note Comments on Case
    //     if(!fields.isDraft__c.value){
    //         this.copyNotesOnCase();
    //         this.closeAction();
    //         // to reload nextStepsEscalationNotes LWC component data to show latest added Notes
    //         setTimeout(() => {
    //             eval("$A.get('e.force:refreshView').fire();");
    //         }, 1000); 
    //     }
    // }

    // handleAutoSave(event){
    //     console.log('handleSubmit sectionType: ',this.sectionType);
    //     let changeVal = event.target.value; 
    //     if(changeVal){
    //         console.log('changeVal: ',changeVal);
    //         // setTimeout(() => {
    //             console.log('handleAutoSave: ',changeVal);
    //             const fields = {};

    //             fields.Body__c = this.sObjectLabel+' Comments('+this.escalationName+'): '+ changeVal; 
                

                

    //         // this.autoSaveVal = changeVal;
    //         // }, 5000); 
    //     }
    // }

    copyNotesOnCase(){
        sendCaseComment({ recordId: this.recordId, nextSteps: this.noteVal })
        .then(result => {
        })
        .catch(error => {
            console.log('sendCaseComment ERROR: ',error);
        })
    }
    
    closeAction() {
        this.dispatchEvent(new CustomEvent('closeaction'));
    }
}