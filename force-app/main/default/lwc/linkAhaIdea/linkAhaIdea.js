import { LightningElement, track, wire, api } from 'lwc';
import searchRecords from '@salesforce/apex/LinkAhaController.searchRecords';
import linkAhaIdeaRecord from '@salesforce/apex/LinkAhaController.linkAhaIdeaRecord';
import getOpptyandCaseRecords from '@salesforce/apex/LinkAhaController.getOpptyandCaseRecords';
import unlinkIdeaWithCaseOrOppty from '@salesforce/apex/LinkAhaController.unlinkIdeaWithCaseOrOppty';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SearchComponent extends LightningElement {
    @api recordId;
    @track searchResults;
    @track noResultFound = false;
    @track doinitCheck = false;
    @track showOppOrCaseRecordsForUnlink = false;
    @track loadspinner = false;
    columns = [
        { label: 'Name', fieldName: 'RecordName', type: 'url',typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' } },
        { label: 'Type', fieldName: 'Type', type: 'text' },
        { label: 'Status', fieldName: 'Status', type: 'text' },
        { label: 'Subject', fieldName: 'Subject', type: 'text' }
    ];

    connectedCallback() {
        // initialize component
        this.doinitCheck = false;
    }

    handleSearch(event) {
        const searchTerm = event.target.value;
        searchRecords({ searchTerm, rcId: this.recordId })
            .then((result) => {
                if (result != '') {
                    let tempRecs = [];
                     result.forEach( ( record ) => {
                        let tempRec = Object.assign( {}, record );
                        tempRec.RecordName = '/' + tempRec.Id;
                        //tempRec.RecordName = '/lightning/r/opportunity/' + tempRec + '/view';
                        tempRec.type = tempRec.type;
                        tempRec.status = tempRec.status;
                        tempRec.Subject = tempRec.Subject;
                        tempRecs.push( tempRec );
                    });
                    this.noResultFound = true;
                    this.searchResults = tempRecs;
                }
                else {
                    this.doinitCheck = true;
                    this.noResultFound = false;
                }
            })
            .catch((error) => {
                console.error('Error retrieving search results', error);
            });
    }

    handleRowSelection(event) {
    }

    getSelectedRec(event){
        this.loadspinner = true;
        var selectedRecords = this.template.querySelector("lightning-datatable").getSelectedRows();
        const mapData = new Map();
        if (selectedRecords.length > 0){
            selectedRecords.forEach(currentItem => {
                mapData.set(currentItem.Id, currentItem.AccountId);
            });
            linkAhaIdeaRecord({rcId:this.recordId,objectRecordIdAndAccountId:Object.fromEntries(mapData.entries())})
                .then((result) => {
                    const event = new ShowToastEvent({
                        title: 'SUCCESS',
                        message: 'Ideas Linked Successfully.',
                        variant: 'success',
                        mode: 'dismissable'
                    });
                    this.loadspinner = false;
                    this.dispatchEvent(event);
                    this.dispatchEvent(new CloseActionScreenEvent());
                    window.location = '/lightning/r/Aha_Ideas__c/' + this.recordId + '/view';
                })
                .catch((error) => {
                    console.error('Error retrieving search results', error);
                    this.loadspinner = false;
                    var errorMessage;
                    if (error.body.message != '' && error.body.message != undefined) {
                        errorMessage = error.body.message;
                    }
                    else {
                        errorMessage = error.body.pageErrors[0].statusCode + '_____' + error.body.pageErrors[0].message;
                    }
                    const event = new ShowToastEvent({
                        title: 'error',
                        message: errorMessage,
                        variant: 'error',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(event);
                });
        }
    }

    openLinkedOpportunityandCaseForm(){
      getOpptyandCaseRecords({rcId: this.recordId})
      .then((result) => {
        this.tableData = [];
        if(result.length>0){
            let tempRecs = [];
                result.forEach( ( record ) => {
                let tempRec = Object.assign( {}, record );
                tempRec.RecordName = '/' + tempRec.Id;
                tempRec.type = tempRec.type;
                tempRec.status = tempRec.status;
                tempRec.Subject = tempRec.Subject;
                tempRecs.push( tempRec );
            });
            this.searchResults = tempRecs;
            this.showOppOrCaseRecordsForUnlink = true;
            this.loadspinner = false;
        }
        else{
          this.showOppOrCaseRecordsForUnlink = false;
          this.loadspinner = false;
        }
      })
      .catch(error => {
            // Handle error
            this.showOppOrCaseRecordsForUnlink = false;
            this.loadspinner = false;
      });

    }// End of method openLinkedOpportunityandCaseForm

    //Unlink the idea Record with the Case or Opportunity
    unlinkedAhaIdeaRecord(){
      this.loadspinner = true;
        const mapData = new Map();
        var selectedRecords =  this.template.querySelector("lightning-datatable").getSelectedRows();
        if(selectedRecords.length > 0){
            var objAccountId = '';
            selectedRecords.forEach(currentItem => {
              if(currentItem.AccountId != null){
                  objAccountId = currentItem.AccountId;
              }
                mapData.set(currentItem.Id, objAccountId);
            });
            unlinkIdeaWithCaseOrOppty({rcId:this.recordId,recordlist:selectedRecords,objectRecordIdandAccountId: Object.fromEntries(mapData.entries())})
            .then(result => {
            const event = new ShowToastEvent({
                title: 'SUCCESS',
                message: 'Ideas Unliked successfully.',
                variant: 'success',
                mode: 'dismissable'
            });
             this.dispatchEvent(event);
              this.loadspinner = false;
              this.dispatchEvent(new CloseActionScreenEvent());
              window.location = '/lightning/r/Aha_Ideas__c/' + this.recordId + '/view';
            })
            .catch(error => {
                // Handle error
                this.showToast('Error', error.body.message, 'error');
                this.loadspinner = false;
            });
        }
    }
    handleActive(event){
        this.activeTab = event.target.value;
        if(this.activeTab == 1){
        }
        if(this.activeTab == 2){
         this.loadspinner = true;
         this.openLinkedOpportunityandCaseForm();
        }
    }
}