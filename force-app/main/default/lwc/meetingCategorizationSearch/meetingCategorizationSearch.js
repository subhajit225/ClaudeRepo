import { LightningElement, api, wire } from 'lwc';
import fetchLookupData from '@salesforce/apex/MeetingCategorizationController.fetchLookupData';

const DELAY = 300;

export default class MeetingCategorizationSearch extends LightningElement {

    @api accountLinkList;
    @api label = 'Account Search';
    @api iconName = 'standard:account';
    @api placeholder = 'Search...';
    @api sObjectApiName = 'Account';
    @api isLeaveBlank = false;
    isLeaveBlankSelected = false;

    lstResult = [];
    hasRecords = true; 
    searchKey='';
    isSearchLoading = false;
    delayTimeout;
    selectedRecord = {};
    fontWieght;
    disableSearch = false;
    lstResultLenght = 0;
    clickOnSearch = false;
    buttonStyle = "position: absolute;margin-top: 2%;";
    newMapBlankPosition = new Map([[0,160],[1,200],[2,260],[3,330],[4,400],[5,460]]);

    @api handlerMethod(value){
      this.accountLinkList = value;
    }

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
            this.lstResultLenght = this.lstResult.length;
            if(this.clickOnSearch){
              const lookupInputContainerClass = this.template.querySelector('.lookupInputContainer');  
              const classList = lookupInputContainerClass.classList;
              classList.add('slds-is-open');            
              this.buttonStyle = `position: absolute;top:${this.newMapBlankPosition.get(this.lstResultLenght)}%`;                
            }  
        }
        else if (error) {
            console.log('(error---> ' + JSON.stringify(error));
        }
    };

    // update searchKey property on input field change  
    handleKeyChange(event) {

        this.isSearchLoading = true;
        window.clearTimeout(this.delayTimeout);
        const searchKey = event.target.value;
        this.delayTimeout = setTimeout(() => {
        this.searchKey = searchKey;
        this.clickOnSearch = true;
        }, DELAY);
    }

    handleOnBlur(event) {
        // setTimeout(()=>{
          this.template.querySelector('.slds-combobox.slds-dropdown-trigger.slds-dropdown-trigger_click')?.classList.remove('slds-is-open');
          this.buttonStyle = "position: absolute;margin-top: 2%;";  
          this.clickOnSearch = false;
        // }, 100);
    } 

    // method to toggle lookup result section on UI 
    toggleResult(event){
        const lookupInputContainer = this.template.querySelector('.lookupInputContainer');  
        const clsList = lookupInputContainer.classList;
        const whichEvent = event.target.getAttribute('data-source');
        switch(whichEvent) {
            case 'searchInputField':
                clsList.add('slds-is-open');                 
                this.buttonStyle = `position: absolute;top:${this.newMapBlankPosition.get(5)}`;
                this.clickOnSearch = true; 
                this.buttonStyle = `position: absolute;top:${this.newMapBlankPosition.get(this.lstResultLenght)}%`;           
              break;
            case 'lookupContainer':
                clsList.remove('slds-is-open');     
                this.buttonStyle = "position: absolute;margin-top: 2%;";  
                this.clickOnSearch = false;
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

    //new changes --start MKT25-289
    handleLeaveBlank(event){
      this.isLeaveBlankSelected = event.target.checked;
      if(this.selectedRecord.Name!=null && this.isLeaveBlankSelected){
        this.handleRemove();
      }
      this.disableSearch = !this.disableSearch;
      if(this.disableSearch){
        this.searchKey = "";
      }
      var selectedEvent = new CustomEvent('uploadisblank', { detail:        
                                          {isLeaveBlank : this.isLeaveBlankSelected}});
                                          this.dispatchEvent(selectedEvent);
    }
}