import { LightningElement, api, wire } from 'lwc';
import fetchLookupData from '@salesforce/apex/MeetingCategorizationController.fetchLookupData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const DELAY = 300;
export default class MeetingCategoryAccountSearch extends LightningElement {
  
    @api accountLinkList;
    @api label = 'Account Search';
    @api iconName = 'standard:account';
    @api placeholder = 'Search...';
    @api sObjectApiName = 'Account';

    lstResult = [];
    hasRecords = true; 
    searchKey='';
    isSearchLoading = false;
    delayTimeout;
    selectedRecord = {};
    fontWieght;
    /*
    @api handlerMethod(value){
      this.accountLinkList = value;
    }*/

    connectedCallback(){
      if(this.label == 'Account Search'){
        this.fontWieght = 'font-wieght';
      }
    }

    // wire function property to fetch search record based on user input
    @wire(fetchLookupData, { searchKey: '$searchKey' , sObjectApiName : '$sObjectApiName', accountIdsList : '$accountLinkList'})
        searchResult(value) {
        const { data, error } = value; // destructure the provisioned value
        this.isSearchLoading = false;
        if (data) {
            this.hasRecords = data.length == 0 ? false : true; 
            this.lstResult = JSON.parse(JSON.stringify(data));  
        }
        else if (error) {
            console.log('(error---> ' + JSON.stringify(error));
        }
    };

    // update searchKey property on input field change  
    handleKeyChange(event) {

        //this.isSearchLoading = true;
        window.clearTimeout(this.delayTimeout);
        const searchKey = event.target.value;
        this.delayTimeout = setTimeout(() => {
        this.searchKey = searchKey;
        }, DELAY);
    }

    // method to toggle lookup result section on UI 
    toggleResult(event){
        const lookupInputContainer = this.template.querySelector('.lookupInputContainer');
        const clsList = lookupInputContainer.classList;
        const whichEvent = event.target.getAttribute('data-source');
        switch(whichEvent) {
            case 'searchInputField':
                clsList.add('slds-is-open');
              break;
            case 'lookupContainer':
                clsList.remove('slds-is-open');   
            break;                    
          }
    }

    // method to clear selected lookup record  
    handleRemove(){
        this.searchKey = '';    
        this.selectedRecord = {};
        this.lookupUpdatehandler(undefined); // update value on parent component as well from helper function 

        // remove selected pill and display input field again 
        const searchBoxWrapper = this.template.querySelector('.searchBoxWrapper');
        searchBoxWrapper.classList.remove('slds-hide');
        searchBoxWrapper.classList.add('slds-show');
        const pillDiv = this.template.querySelector('.pillDiv');
        pillDiv.classList.remove('slds-show');
        pillDiv.classList.add('slds-hide');

        
    }

    // method to update selected record from search result 
    handelSelectedRecord(event){   
        var objId = event.target.getAttribute('data-recid'); // get selected record Id 
        this.selectedRecord = this.lstResult.find(data => data.Id === objId); // find selected record from list 
        this.lookupUpdatehandler(objId); // update value on parent component as well from helper function 
        this.handelSelectRecordHelper(); // helper function to show/hide lookup result container on UI
 
      }

    // COMMON HELPER METHOD STARTED
    handelSelectRecordHelper(){
        this.template.querySelector('.lookupInputContainer').classList.remove('slds-is-open');
        const searchBoxWrapper = this.template.querySelector('.searchBoxWrapper');
        searchBoxWrapper.classList.remove('slds-show');
        searchBoxWrapper.classList.add('slds-hide');
        const pillDiv = this.template.querySelector('.pillDiv');
        pillDiv.classList.remove('slds-hide');
        pillDiv.classList.add('slds-show');     
    }
    
    // send selected lookup record to parent component using custom event
    lookupUpdatehandler(value){
      let customEventLabel;
      if(this.sObjectApiName === 'Account'){
        customEventLabel = 'uploadevent';
      }else if(this.sObjectApiName === 'Opportunity'){
        customEventLabel = 'uploadrelatedtoevent';
      } 
      var selectedEvent = new CustomEvent(customEventLabel, { detail:        
                          {selectedId : value}});
                  // Dispatches the event.
                  this.dispatchEvent(selectedEvent);
    }

    key_Code_Checker(component, event, helper){
      if (component.which == 13){
        this.searchAccountHandler();
      }
    }
    
    searchAccountHandler(){
      if(this.searchKey.length >= 3){
        this.lookupUpdatehandler(this.searchKey);
        this.handelSelectRecordHelper();
      }else{
        this.showToast('Search term should be minimum of 3 characters', 'error','','dismissable');
      }
    }

    showToast(message, type, title, mode){
      this.dispatchEvent(
              new ShowToastEvent({
                  title: title,
                  message: message,
                  variant: type,
                  mode: mode
              }),
      );
    }
}