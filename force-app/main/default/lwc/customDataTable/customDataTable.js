import { LightningElement, wire, track, api } from 'lwc';
import getFieldsInfo from '@salesforce/apex/customDataTableController.getFieldsInfo';
import saveNotes from '@salesforce/apex/customDataTableController.saveNotes';
import getNotesStatusPickListValues from '@salesforce/apex/EscalationManagementTeamController.getNotesStatusPickListValues';
// delete record
import { deleteRecord } from 'lightning/uiRecordApi';
// toast message
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// refreshApex
import { refreshApex } from '@salesforce/apex';

export default class CustomDataTable extends LightningElement {

    fieldheaders = ['Sl No', 'Title', 'Body', 'Created By', 'Crated Date'];
    editMode = false
    @track records
    // record to revert on cancel
    @track revertRecords = []
    // error params
    errorHeader
    error
    //
    @api recordId
    recordsToUpdate = [];
    //to provide Width space for table columns
    isAreaOfImpSec = false

    // UI Params
    isLoading = false;

    // Parant CMP params
    @api tableName;
    @api objectName;
    @api fieldSetName;
    @api filterStr;

    // fields
    fldDetail

    // 2011
    @track llStatus
    
    // records to Update
    @track rowsToUpdate = []
    
    @wire(getFieldsInfo, {objectName: '$objectName', fieldSetName: '$fieldSetName', parentRecordId: '$recordId', filterStr: '$filterStr'})
    datatableInfo({error, data}) {
        if(this.fieldSetName == 'LL_Areas_of_Improvement'){
            this.isAreaOfImpSec = true;
        }
        this.isLoading = true;
        if(data){
            this.fldDetail = data.FieldDetail;
            this.records = data.sObjectRecords;
            let dataRows = [];
            let index = 0;
            let uiIndex = this.records.length;
            
            this.records.forEach(element => {
                element = Object.assign({}, element);
                element.editable = false;
                element.index = index;
                element.uiIndex = uiIndex;
                dataRows.push(element);
                index++;
                uiIndex--;
            });
            
            this.records = dataRows;
            this.revertRecords = JSON.parse(JSON.stringify(dataRows));
            console.log('fldDetail:: ', JSON.stringify(this.fldDetail));
            console.log('rec:: ', JSON.stringify(this.records));
            this.fetchLessonsLearnedStatus();
            this.isLoading = false;
        } else if(error){
            console.log('error:: ', JSON.stringify(error));
            this.errorHeader = 'An error occurred while trying to fetch the Note records';
            this.error = error;
            this.isEditable = false;
            this.isLoading = false;
        }
    }

    // CS21-2011
    fetchLessonsLearnedStatus(){
        console.log('fetchLessonsLearnedStatus: ', JSON.stringify(this.llStatus));
        getNotesStatusPickListValues()
        .then(data => {
            // Map the data to an array of options
            this.llStatus = data.map(option => {
                return {
                    label: option.label,
                    value: option.value
                };
            });
            console.log('llStatus: ', JSON.stringify(this.llStatus));
        })
        .catch(error => {
            console.log('getNotesStatusPickListValues: ', JSON.stringify(error));
            this.error = error;
        })
        .finally(() => {
            this.isLoading = false;
        })
    }

    handleEditRow(event){
        var rowindex = event.target.dataset.name;
        this.records.forEach(element => {
            // Inline edit current row
            if(element.index == rowindex){
                this.records[rowindex].editable = true;
            }
            // apply view for other rows
            else{
                this.records[element.index].editable = false;
            }
        });
        this.editMode = true;
    }

    handleEditView(){
        this.editMode = true;
    }

    handleChangeRow(event){
        this.isLoading = true;
        let val = event.detail.val;
        let row = event.detail.row;
        let fldApi = event.detail.fldApi;

        let rowList = this.rowsToUpdate;
        let editedRow = {};

        // Second time Edited row
        if(rowList[row.index]){
            editedRow = rowList[row.index];
        }
        // First time edited row
        else{
            editedRow = row;
        }

        editedRow.editable = true;
        editedRow[fldApi] = val;

        rowList[row.index] = editedRow;
        // updated actual record var with latest updated values
        this.records[row.index] = editedRow;
        
        this.records = JSON.parse(JSON.stringify(this.records));
        
        console.log('rowsToUpdate: ', JSON.stringify(rowList));
        this.rowsToUpdate = rowList;
        this.isLoading = false;
    }

    handleSave(){
        this.isLoading = true;
        // remove null elements from rowsToUpdate
        let rowsToUpdateCopy = JSON.parse(JSON.stringify(this.rowsToUpdate));
        this.rowsToUpdate = this.rowsToUpdate.filter(elements => {return elements !== null;});
        
        this.rowsToUpdate.forEach(ele1 => {
            if(ele1.isDraft__c){
                ele1.isDraft__c = false;
            }
            // removing temp ele assigned in JS
            // delete ele1.editable;
            // delete ele1.index;
            // delete ele1.Owner;
        });

        if(this.rowsToUpdate){
            this.saveNotesRecords();
        }else{
            this.handleCancel();
        }
    }

    saveNotesRecords(){
        saveNotes({ notesStrData: JSON.stringify(this.rowsToUpdate) })
		.then(result => {
            this.editMode = false;
            this.refreshInnerRecord(this.records, false);
            this.error = '';
		})
		.catch(error => {
            this.errorHeader = 'An error occurred while trying to Save the Note records';
            let errorBody = error.body.message;
            
            if(errorBody.includes('VALIDATION')){
                let validationMsg = errorBody.split('FIELD_CUSTOM_VALIDATION_EXCEPTION,')[1];
                errorBody = validationMsg.split(':')[0];
            }
            this.error = errorBody;
		})
        .finally(() => {
            this.isLoading = false;
        })
    }

    handleCancel(){
        this.isLoading = true;
        this.editMode = false;
        this.error = false;
        this.refreshInnerRecord(this.revertRecords, true);
    }

    handleDeleteNote(event){
        this.isLoading = true;
        let noteId = event.currentTarget.dataset.id;
        console.log('handleDeleteNote:rec: ', noteId);
        
        // remove deleted row from result
        this.removeByAttr(this.records, 'Id', noteId);

        deleteRecord(noteId).then(result => {
        }).catch(error => {
            // this.showToast('Error updating or refreshing records', error.body.message, 'Error', 'dismissable');
        }).finally(()=>{
            this.isLoading = false;
            return refreshApex(this.records);
        });
    }

    // remove deleted row from result
    removeByAttr(arr, attr, value){
        var i = arr.length;
        while(i--){
           if( arr[i] 
               && arr[i].hasOwnProperty(attr) 
               && (arguments.length > 2 && arr[i][attr] === value ) ){ 
    
               arr.splice(i,1);
    
           }
        }
        return arr;
    }
 
    // keepDraftRec: When inline edit of Draft Note and Canceled we need to keep DRAFT text 
    // keepDraftRec/isDraft__c will be false when total save
    refreshInnerRecord(records, keepDraftRec){
        let allRec = JSON.parse(JSON.stringify(records));
        this.records = [];

        let index = 0;
        allRec.forEach(element => {
            element.editable = false;
            element.index = index;
            // Keep draft value as if on click of cancel, and draft to false on save list on UI
            if(!keepDraftRec){
                element.isDraft__c = false;
            }
            index++;
        });
        // to re-render child component
        setTimeout(() => {
            this.records = JSON.parse(JSON.stringify(allRec));
            this.isLoading = false;
        }, 200);
    }

    showToast(title, msg, vari){
        console.log('showToast: ');
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: msg,
                variant: vari
            })
        );
    }
}