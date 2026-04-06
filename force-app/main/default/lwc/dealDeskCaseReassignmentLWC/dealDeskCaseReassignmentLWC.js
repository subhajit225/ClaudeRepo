import { LightningElement, wire, api, track } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import DDC_OBJECT from '@salesforce/schema/Deal_Desk_Case__c'
import TEAM_FIELD from "@salesforce/schema/Deal_Desk_Case__c.Deal_Desk_Team__c";
import STATUS_FIELD from "@salesforce/schema/Deal_Desk_Case__c.Request_Status__c";
import fetchFilteredRecords from '@salesforce/apex/DealDeskCaseReassignmentController.fetchFilteredRecords';
import fetchReassignUser from '@salesforce/apex/DealDeskCaseReassignmentController.fetchReassignUser';
import reassignCase from '@salesforce/apex/DealDeskCaseReassignmentController.reAssignCase';
import dualListBoxHeight from '@salesforce/resourceUrl/dualListBoxHeight';
import { loadStyle } from "lightning/platformResourceLoader";
const columns = [
    {
        label: 'Request Number',
        fieldName: 'reqId',
        type: 'url',
        typeAttributes: { label: { fieldName: 'Name' }}
    }, {
        label: 'Opportunity',
        fieldName: 'oppId',
        type: 'url',
        typeAttributes: { label: { fieldName: 'Opportunity' }}
    }, {
        label: 'Case Owner',
        fieldName: 'ownrId',
        type: 'url',
        typeAttributes: { label: { fieldName: 'Owner' }}
    }, {
        label: 'Deal Desk Team',
        fieldName: 'Deal_Desk_Team__c',
        type: 'text'
    }, {
        label: 'ETM (Theatre)',
        fieldName: 'ETM_Theatre__c',
        type: 'text'
    }, {
        label: 'ETM (Area)',
        fieldName: 'ETM_Area__c',
        type: 'text'
    }, {
        label: 'Request Status',
        fieldName: 'Request_Status__c',
        type: 'text'
    }, {
        label: 'Submitted Date',
        fieldName: 'SubmittedDate__c',
        type: 'text'
    }
];

export default class DealDeskCaseReassignmentLWC extends NavigationMixin(LightningElement) {
    statusPickListValues;
    teamPickListValues;
    recordTypeId;
    @track selectedRecords = [];
    @track selectedRecordsLength;
    assigneeIds= [];
    status = null;
    team = null;
    filteredCases = [];
    filteredCaseIds = [];
    columns = columns;
    rows = [];
    selectedCaseIds = [];
    statusSelected = [];
    //reassign
    @track isSearchLoading = false;
    @track messageFlag = false;
    @track reassignUserName;
    @track reassignUserId;
    @track reassignUserSearchList;
    @track isValueSelected = false;
    @track blurTimeout;
    @track searchTerm;
    @track showSearchTable = false;
    @track isLoading = false;
    @track dataFound = false
    @track dataNotFound = false;
    @track isInitialMsg = true;
    @track isReassignDisable = true;

    renderedCallback() {
        Promise.all([
            loadStyle(this, dualListBoxHeight )
        ]).then(() => {
            console.log( 'Files loaded' );
        })
        .catch(error => {
            console.log( error.body.message );
        });
    }

    @wire(getObjectInfo, { objectApiName: DDC_OBJECT })
    getObjectData({error,data}){
       if(data){
         this.recordTypeId = data.defaultRecordTypeId;
       }else if(error){
           console.log('error '+error);
        }
     };
    
    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId',
        fieldApiName: STATUS_FIELD
    })
    statusPickLists({ error, data }) {
        if (error) {
            console.log("error", error);
        } else if (data) {
            this.statusPickListValues = [
               // { label: "--None--", value: null },
                ...data.values
            ];
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId',
        fieldApiName: TEAM_FIELD
    })
    teamPickLists({ error, data }) {
        if (error) {
            console.log("error", error);
        } else if (data) {
            this.teamPickListValues = [
                { label: "--None--", value: null },
                ...data.values
            ];
        }
    }

    handleselectedUserRecords(event) {
        this.assigneeIds = [];
        this.selectedRecords = [...event.detail.selRecords]
        this.selectedRecordsLength = this.selectedRecords.length;
        for (let i = 0; i < this.selectedRecords.length; i++) {
            this.assigneeIds.push(this.selectedRecords[i].Id);
        }
    }
    handleTeamChange(event){
        this.team = event.target.value;
    }
    handleStatusChange(event){
        //this.status = event.target.value;
        this.statusSelected = event.detail.value;
    }

    handleSearchButton(){
        this.isLoading = true;
        this.isInitialMsg = false;
        this.filteredCases = [];
        console.log('search assignee id: '+this.assigneeIds);
        console.log('search team: '+this.team);
        console.log('search status: '+this.statusSelected);
        fetchFilteredRecords({'assigneeIds': this.assigneeIds, 'team': this.team, 'statusList': this.statusSelected})
        .then(data=>{
            console.log('data length: '+data.length)
            if(data.length>0){
                    data = JSON.parse(JSON.stringify(data));
                let filteredIds = [];
                data.forEach(res => {
                    filteredIds.push(res.Id);
                    res.reqId = window.location.origin + "/" + res.Id,
                    res.oppId = window.location.origin + "/" + res.Opportunity__c,
                    res.ownrId = window.location.origin + "/" + res.OwnerId
                    res.Opportunity = res.Opportunity__r.Name
                    res.Owner = res.Owner.Name
                }); 
                this.filteredCases = data;
                this.filteredCaseIds = filteredIds;
                this.isLoading = false;
                this.dataFound = true;
                this.dataNotFound = false;
                console.log('filtered: '+this.filteredCaseIds)
                //console.log('after search '+JSON.stringify(this.filteredCases));
                
            }
            else{
                this.dataFound = false;
                this.dataNotFound = true;
                this.isLoading = false;
            }
        }).catch(error=>{
            this.isLoading = false;
            console.error('error while retreiving data: '+error);
        })
    }

    handleSelectedRows(event){
        this.rows = event.detail.selectedRows;
    }

    handleReassign(){
        this.isLoading = true;
        this.selectedCaseIds = [];
        if(this.dataFound == true){
            var selectedDDCRecords =  this.template.querySelector("lightning-datatable").getSelectedRows();
            if(selectedDDCRecords.length > 0){
          console.log('selectedDDCRecords are ', selectedDDCRecords);
            let ids = [];
            selectedDDCRecords.forEach(currentItem => {
              ids.push(currentItem.Id);
          });
          this.selectedCaseIds = ids;
         var isSelectedClosedCase = false;
         selectedDDCRecords.forEach(currentItem => {
            if(currentItem.Request_Status__c == 'Closed - Completed' || currentItem.Request_Status__c == 'Closed - Incomplete'){
                isSelectedClosedCase = true;
            }
        });
        console.log('isSelectedClosedCase '+isSelectedClosedCase);
       // this.userIds = this.userComment.Recipient_Ids__c.split(',');
          console.log('selected Id list: '+this.selectedCaseIds);
          if(this.reassignUserId == '' || this.reassignUserId ==null){
            this.isLoading = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error!',
                    message: 'Please select a user for reassignment',
                    variant: 'error'
                })
            );
          }
          else if(isSelectedClosedCase){
            this.isLoading = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error!',
                    message: 'You can\'t reassign a Closed Case',
                    variant: 'error'
                })
            );
          }
          else{
            console.log('sent data: ' +this.selectedCaseIds+ ' '+this.reassignUserId)
            reassignCase({caseIds : this.selectedCaseIds, assignToId: this.reassignUserId, filteredIds: this.filteredCaseIds})
            .then(data=>{
              if(data.length>0){
                  data = JSON.parse(JSON.stringify(data));
                  data.forEach(res => {
                      res.reqId = window.location.origin + "/" + res.Id,
                      res.oppId = window.location.origin + "/" + res.Opportunity__c,
                      res.ownrId = window.location.origin + "/" + res.OwnerId,
                      res.Opportunity = res.Opportunity__r.Name,
                      res.Owner = res.Owner.Name
                  });
                  this.isLoading = false;
                  this.filteredCases = data;
                  this.isValueSelected = false;
                  this.isReassignDisable = true;
                  this.searchTerm = '';
                  this.template.querySelector('lightning-datatable').selectedRows=[]; 
                  this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success!',
                        message: 'Case Reassigned successfully !!',
                        variant: 'Success'
                    })
                );
                refreshApex(this.filteredCases);
              }
            }).catch(error=>{
                this.isLoading = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error!',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
              console.log('error while retreiving data: '+error);
          })
          }
      }
      else{
        this.isLoading = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error!',
                    message: 'Please select Cases to be reassigned',
                    variant: 'error'
                })
            );
      }  
    }
else{
    this.isLoading = false;
    this.dispatchEvent(
        new ShowToastEvent({
            title: 'Error!',
            message: 'Please search the Cases to be reassigned',
            variant: 'error'
        })
    );
}
    }

    searchReassignUser(){
        fetchReassignUser({searchTerm : this.searchTerm})
        .then(result => {
            this.isSearchLoading = false;
            this.reassignUserSearchList = result;
            if (this.searchTerm.length > 0 && result.length == 0) {
                this.messageFlag = true;
            } else {
                this.messageFlag = false;
            }
         })
         .catch(error => {
            console.log(error);
        });
    
    }
    
    handleSearchClick() {
        //this.searchTerm = '';
        this.showSearchTable = true;
    }

    onSelectReassignUser(event) {
        let selectedId = event.currentTarget.dataset.id;
        let selectedName = event.currentTarget.dataset.name;
        /*const valueSelectedEvent = new CustomEvent('lookupselected', {detail:  selectedId });
        this.dispatchEvent(valueSelectedEvent);*/
        this.isValueSelected = true;
        this.isReassignDisable = false;
        this.reassignUserName = selectedName;
        this.reassignUserId = selectedId;
        this.showSearchTable = false;
        this.searchTerm = '';
        console.log('selectedId '+selectedId);
        console.log('selectedName '+selectedName);
       }

    handleRemovePill() {
        this.isValueSelected = false;
        this.isReassignDisable = true;
        this.searchReassignUser();
        this.reassignUserName = '';
        this.reassignUserId = '';
        this.searchTerm='';
    }

    onChangeSearchKey(event) {
        this.isSearchLoading = true;
        window.clearTimeout(this.delayTimeout);
        const searchKey = event.target.value;
        this.delayTimeout = setTimeout(() => {
            this.searchTerm = searchKey;
            this.searchReassignUser();
        }, 300);
        this.showSearchTable = true;
    }

    handleMouseLeave(){
        this.showSearchTable = false;
    }
}