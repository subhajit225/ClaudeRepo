import { LightningElement,track,wire } from 'lwc';
import getCustomMetadataRecords from '@salesforce/apex/MeetingConsoleController.getCustomMetadataRecords';
import getFilterCustomMetadataRecords from '@salesforce/apex/MeetingConsoleController.getFilterCustomMetadataRecords';
import getEventRecords from '@salesforce/apex/MeetingConsoleController.getEventRecords';
import getSelectedRecords from '@salesforce/apex/MeetingConsoleController.getSelectedRecords';
import {loadStyle} from 'lightning/platformResourceLoader';
import COLORS from '@salesforce/resourceUrl/lwcstyledatatable';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class MeetingConsole extends LightningElement {
    _name;
    _label;
    _outcome = 'Opportunity Sourced';
    isCssLoaded = false;
    noOppSourced = false;
    noOppSourcedwithOther = false;
    
    upcomingMeetings = false;
    isLoading = false;
    _req = false;
    selectedRowRecords;
    dispositionedRecords = [];
    _error;

    pageSize = 25;
    @track isPreviousDisable = true;
    @track isNextDisable = false;
    @track page = 1;
    @track totalPage = 1;
    @track resultItems = [];
    totalRecountCount = 0;
    startingRecord = 0;
    endingRecord = 0;
    selection = [];
    dashboard = 'Disposition';

    @track mainFilterList = [];
    @track updatedEvents = [];
    @track _reason = null;
    @track _otherReason = null;
    @track data ;
    @track columns = [];
    @track meetingTimings = 'All Meetings';
    @track sortBy='createdDate';
    @track sortDirection = 'asc';
    @track reasonOptions = [];
    @track isShowModal = false;
    @track eventIds = [];

    @track dataItems = [];
    @track filterMap = new Map();
    headerTitles=[
        {
            id:'total',
            label:'Total Meetings',
            count:0
        },
        {
            id:'opportunitySourced',
            label:'Opportunity Sourced Meeting',
            count:0
        },
        {
            id:'noOpportunitySourced',
            label:'No Opportunity Sourced',
            count:0
        },
        {
            id:'cancelled',
            label:'Meeting Cancelled',
            count:0
        },
        {
            id:'upcoming',
            label:'Upcoming Meetings',
            count:0
        },
        {
            id:'pastDue',
            label:'Past Due Meetings',
            count:0
        }
    ];


    @wire(getFilterCustomMetadataRecords)
    filterDate({error,data})
    {
        if(data){

            this.dataItems = data.map(item =>{
                let optionsValues = [];
                let defaultValues = '';
                if(item.MasterLabel == 'Disposition Status'){
                    optionsValues.push({label: '--None--' , value: null});
                }
                item.Options__c.split(';').forEach(val =>{
                    optionsValues.push({label: val , value: val});
                   
                });
                if(item.MasterLabel == 'Meeting Timing'){
                    defaultValues = 'All Meetings';
                }
                if(item.MasterLabel == 'Meeting FQ'){
                    defaultValues = 'Current Quarter';
                }
                return {...item, 
                   "optionsValues": optionsValues,
                   "defaultValue": defaultValues
                  }
            })
            let totalRows = Math.ceil(this.dataItems.length / 5);
            let starting = 0;
            let ending = this.dataItems.length <= 5 ? this.dataItems.length : 5;

            for(let i =0;i<totalRows ;i++){
                let filters = this.dataItems.slice(starting, ending);
                let isFirstRow = i === 0;
                let rowClass = isFirstRow ? 'slds-p-bottom_medium' : '';
                let row = {'data': filters, "isFirstRow": isFirstRow, "rowClass" : rowClass};
                this.mainFilterList.push(row);
                starting = starting +5;
                ending = ending +5;
            }
            
        }else if(error){
            console.log('err---',error);
        }
    }

     @wire(getCustomMetadataRecords)
    columnData({ error, data }) 
    {
        if(data) {
            let items = [];
            data.forEach(item => {
                if(item.Type__c != 'url'){
                    items = [...items , {
                                      label: item.MasterLabel, 
                                      fieldName: item.FieldName__c,
                                      type: item.Type__c, 
                                      wrapText: true,
                                      sortable: item.Sortable__c,
                                      cellAttributes:{
                                        class:{fieldName:'cellColor'}
                                            }
                                      }
                                      ];
                }
                else{
                    items = [...items , {
                                      label: item.MasterLabel, 
                                      fieldName: item.Hyperlink__c,
                                      type: item.Type__c,
                                      wrapText: true,
                                      typeAttributes: {
                                            label: { 
                                                    fieldName: item.FieldName__c
                                                    },
                                            target : '_blank'
                                      },
                                      sortable: item.Sortable__c,
                                      cellAttributes:{
                                        class:{fieldName:'cellColor'}
                                        }
                                      }
                                      ];
                }
                
            });
            this.columns = items;
        }else if(error){
            console.log('err---',error);
        }
    }
    
    rowSelection(evt){
       // List of selected items from the data table event.
            let updatedItemsSet = new Set();
            // List of selected items we maintain.
            let selectedItemsSet = new Set(this.selection);
            // List of items currently loaded for the current view.
            let loadedItemsSet = new Set();


            this.data.map((event) => {
                loadedItemsSet.add(event.meetingLink);
            });


            if (evt.detail.selectedRows) {
                evt.detail.selectedRows.map((event) => {
                    updatedItemsSet.add(event.meetingLink);
                });


                // Add any new items to the selection list
                updatedItemsSet.forEach((id) => {
                    if (!selectedItemsSet.has(id)) {
                        selectedItemsSet.add(id);
                    }
                });        
            }


            loadedItemsSet.forEach((id) => {
                if (selectedItemsSet.has(id) && !updatedItemsSet.has(id)) {
                    // Remove any items that were unselected.
                    selectedItemsSet.delete(id);
                }
            });


            this.selection = [...selectedItemsSet];
            console.log('---selection---'+JSON.stringify(this.selection));
    }
    connectedCallback(){
        this.setDefaultFilter();
    }

    setDefaultFilter(){
        this.filterMap.set('Meeting_Timing','All Meetings');
        this.filterMap.set('Meeting_FQ','Current Quarter');
        this.filterMap.set('Parent_Account_Tier','');
        this.filterMap.set('Week_of_Fiscal_Quarter','');
        this.filterMap.set('Disposition_Status','');
    }
    renderedCallback(){
        console.log('rendered');
        if(this.isCssLoaded) return
        this.isCssLoaded = true
        loadStyle(this, COLORS).then(()=>{
            console.log("Loaded Successfully")
        }).catch(error=>{ 
            console.error("Error in loading the colors")
        })
        
        this.datarecords();
    }
    get options() {
        return [
            { label: 'Past Meeting', value: 'Past Meeting' },
            { label: 'Upcoming Meeting', value: 'Upcoming Meeting' },
            { label: 'All Meetings', value: 'All Meetings' },
        ];
    }

    get selectedRowsOption(){
         return [
            { label: 'Opportunity Sourced', value: 'Opportunity Sourced' },
            { label: 'No Opportunity Sourced', value: 'No Opportunity Sourced' },
            { label: 'Meeting Cancelled', value: 'Meeting Cancelled' },
        ];
    }
    
    handleChange(event){
        if(event.target.name == 'Meeting_Timing'){
            this.meetingTimings = event.target.value;
        }
       this.filterMap.set(event.target.name, event.target.value);   
    }
   
    filterSubmit(){
        this.isLoading = true;
        this.page= 1;
        this.isPreviousDisable = true;
        this.startingRecord =0;
        this.parseData = undefined;
        this.selection = [];
        this.datarecords();
        if(this.data != undefined){
            this.template.querySelector('lightning-datatable').selectedRows=[];
        }
    }
    resetSubmit(){
        this.dataItems.forEach(element =>{
            if(element.DeveloperName == 'Meeting_FQ'){
                this.template.querySelector(`[data-id=${element.DeveloperName}]`).value = 'Current Quarter';
            }else if(element.DeveloperName == 'Meeting_Timing'){
                this.template.querySelector(`[data-id=${element.DeveloperName}]`).value = 'All Meetings';
            }else{
                this.template.querySelector(`[data-id=${element.DeveloperName}]`).value = '';
            }
        });
        this.isLoading=true;
        this.page= 1;
        this.isPreviousDisable = true;
        this.startingRecord =0;
        this.parseData = undefined;
        this.selection = [];
        this.setDefaultFilter();
        this.datarecords();
        if(this.data != undefined){
            this.template.querySelector('lightning-datatable').selectedRows=[];
        }
        
    }
           
    @track arrayrrr;
    @track persistData = [];
    datarecords(){
        this.persistData = [];
        this.arrayrrr = Array.from(this.filterMap, ([key, value]) => ({ key, value }));
        getEventRecords({filterMapValues : JSON.stringify(this.arrayrrr), eventData :JSON.stringify(this.updatedEvents)})
        .then(result => {
            this.totalRecountCount = result.length;
            this.totalPage = this.totalRecountCount <= this.pageSize ? 1 : Math.ceil(this.totalRecountCount / this.pageSize);
            this.isNextDisable = this.totalPage == 1 ? true : false;
            
            this.endingRecord = this.totalRecountCount <= this.pageSize ? this.totalRecountCount :this.pageSize;

             this.resultItems = result.map(item =>{
                let date1=new Date(item.activityDateClr);
                let cellColor;
              
                
                let set_date;
                if(item.createdDateString != undefined){
                    set_date = item.createdDateString.split(' ')[0];
                }
                item.actualCreatedDate = item.createdDate;
                item.actualCreatedDateString = set_date;

                let dispositin_date = '';
                if(item.completedDateString != undefined){
                    dispositin_date = item.completedDateString;
                }
                item.actualcompletedDateString = dispositin_date;
                item.actualcompletedDate = item.completedDate;

                
                item.actualActivityDate = item.activityDate;
                item.actualActivityDateString =item.activityDateString;

                
                if((this.meetingTimings == 'Past Meeting' || this.meetingTimings == 'All Meetings') && date1.toJSON().slice(0, 10) <  new Date().toJSON().slice(0, 10) && item.outcome == null){
                    cellColor = "datatable-red";
                }
                else if(item.outcome != 'Opportunity Sourced' && item.outcome != 'No Opportunity Sourced' && item.outcome != 'Meeting Cancelled' && item.outcome != undefined){
                    cellColor = "slds-truncate slds-text-color_error";
                    this.persistData.push(item);
                }
                return {...item, 
                   "cellColor": cellColor}
            });
            //here we slice the data according page size
            this.data = this.resultItems.slice(0, this.totalRecountCount <= this.pageSize ? this.totalRecountCount :this.pageSize);
            this.isLoading=false;
        })
        .catch(error =>{
            this._error = error;
             this.data = undefined;
        })
    }
   
    doSorting(event){
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }
    @track parseData;
    sortData(fieldname, direction) {
        this.parseData = JSON.parse(JSON.stringify(this.resultItems));
        if(fieldname == 'actualcompletedDateString'){
            fieldname = 'actualcompletedDate';
        }
        else if(fieldname == 'actualActivityDateString'){
            fieldname = 'actualActivityDate';
        }
        else if(fieldname == 'actualCreatedDateString'){
            fieldname = 'actualCreatedDate';
        }
        let keyValue = (a) => {
            if(fieldname == 'accountLink'){
                return a['accountName'];
            }
            else{
                return a[fieldname];
            }
            
        };
        let isReverse = direction === 'asc' ? 1: -1;
        this.parseData.sort((x, y) => {
            
            x = keyValue(x) ? keyValue(x) : '';
            y = keyValue(y) ? keyValue(y) : '';
            if(fieldname == 'activityDate'){
                let a = x.slice(0, 10);
                let b = y.slice(0, 10);
                 return isReverse * ((a > b) - (b > a));
            }
            else{
                return isReverse * ((x > y) - (y > x));
            }
        });
        this.data = this.parseData.slice(this.startingRecord, this.endingRecord);
    }


    getSelectedRows(){
        if(this.data != undefined){
            let selectedRecords = [];
            let event_Ids = [];
            selectedRecords =  this.selection;
            this.selectedRowRecords =selectedRecords;
            
            if(selectedRecords == ''){
                this.showToast('Please select atleast 1 record', 'error','','dismissable');
            }else{
                this.isShowModal = true;
                
                selectedRecords.forEach(element =>{
                        event_Ids.push(element.replace('/','').trim());
                });
                this.eventIds = event_Ids;
            } 
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
     hideModalBox(){
         this.isShowModal = false;
         this.noOppSourcedwithOther = false;
         this.noOppSourced = false;
     }
    submitDispositioned() { 
        let validreason = true;
        if(this._outcome == 'No Opportunity Sourced' && this._reason == 'Other'){
            var inp=this.template.querySelector('lightning-input');
            if(!inp.reportValidity()){
                inp.reportValidity();
                validreason = inp.checkValidity()
            }
            
        }
        
        const allvalid = [...this.template.querySelectorAll('lightning-combobox')]
        .reduce((validSofar, inpCom) =>{
             inpCom.reportValidity();
             
            return validSofar && inpCom.checkValidity();
        });
        if(allvalid && validreason){
            if(this.meetingTimings == 'Upcoming Meeting'){
              this.upcomingMeetings = true;
              this.isShowModal = false;
              this.showToast('You are dispositioning Upcoming meetings', 'warning','', 'dismissable');
            }else{
                
                this.updateDispositionedRecords();
            }
        }
        else{
            this.showToast('Please fill Missing Required Fields', 'error','', 'dismissable');
        }
          
    }

    updateDispositionedRecords(){
            this.isLoading = true;
            this.noOppSourced = false;
            this.noOppSourcedwithOther = false;
            this.isShowModal = false;
            
            if(this.eventIds != ''){
             
             getSelectedRecords({selectedEventIds : this.eventIds, outcome : this._outcome, reason : this._reason, othrReason : this._otherReason})
             .then(result =>{
                this.selection = [];
                this.page= 1;
                this._reason=null;
                this._otherReason=null;
                this.isPreviousDisable = true;
                 this.updatedEvents = result;
                                  
                 if(this.updatedEvents == ''){
                     this.showToast('Selected meetings have been dispositioned successfully', 'success','', 'dismissable');
                     this.isLoading = false;
                 }else{
                     this.showToast(this.updatedEvents.length+' of '+Number(this.eventIds.length) +' Meeting were not successfully dispositioned, please correct and reattempt ', 'error','', 'sticky');
                     this._outcome = 'Opportunity Sourced';
                 }
                 this.updatedEvents.push.apply(this.updatedEvents,this.persistData);
                 this.datarecords();
             })
             .catch(error =>{
                 console.log('error is  ',error);
             })
                  
            }
    }
    
    
    handleSelectedRows(event){
        this._reason=null;
        this._otherReason = null;
       
        this._outcome = event.target.value;
        if(event.target.name == 'Outcome' && this._outcome == 'No Opportunity Sourced'){
            this.noOppSourced = true;
            this._name = 'Reason for no opportunity';
            this._label ='Reason for no opportunity?';
            this.reasonOptions = [
                                    { label: 'No calendered next step', value: 'No calendered next step' },
                                    { label: 'No found mutually identified pain', value: 'No found mutually identified pain' },
                                    { label: 'No found potential champion', value: 'No found potential champion' },
                                    { label: 'No found problem worth solving', value: 'No found problem worth solving' },
                                    { label: 'Other', value: 'Other' },
                                ]; 
        }else if(event.target.name == 'Outcome' && this._outcome == 'Meeting Cancelled'){
             this.noOppSourced = true;
             this.noOppSourcedwithOther = false;
             this._name = 'Cancellation reason';
             this._label ='Cancellation reason';
             this.reasonOptions = [
                                    { label: 'Customer - No Show', value: 'Customer - No Show' },
                                    { label: 'Customer - Reschedule', value: 'Customer - Reschedule' },
                                    { label: 'Customer - Cancellation', value: 'Customer - Cancellation' },
                                    { label: 'Sales - Reschedule', value: 'Sales - Reschedule' },
                                    { label: 'Sales - Cancellation', value: 'Sales - Cancellation' },
                                    { label: 'Created in Error', value: 'Created in Error' },
                                    { label: 'System Closed No Action', value: 'System Closed No Action' },
                                ];     
        }else{
            this.noOppSourcedwithOther = false;
            this.noOppSourced = false;
        }
    }
    
    handleReasons(event){
        this._reason =  event.target.value;   
        if(this._name == 'Reason for no opportunity' && this._reason == 'Other'){
            this.noOppSourcedwithOther = true;
            this._req = true;            
        }else{
            this.noOppSourcedwithOther = false;
        }                                               
    }
    
    handlerOtherReason(event){
        this._otherReason = event.target.value;
    }

    handleCancel(){
        this.upcomingMeetings = false;
    }
    handleSubmit(){
        this.isLoading = true;
        this.upcomingMeetings = false;
        this.updateDispositionedRecords();
    }

    //press on previous button this method will be called
    previousHandler() {
        if (this.page > 1) {
            this.page = this.page - 1;
            this.displayRecordPerPage(this.page);
        }
        if(this.page == 1){
            this.isPreviousDisable = true;
        }
        if(this.page < this.totalPage){
            this.isNextDisable = false;
        }
    }

    //press on next button this method will be called
    nextHandler() {
        if ((this.page < this.totalPage) && this.page !== this.totalPage) {
            this.page = this.page + 1;
            this.displayRecordPerPage(this.page);
        }
        if(this.page > 1){
            this.isPreviousDisable = false;
        }
        if(this.page == this.totalPage){
            this.isNextDisable = true;
        }
    }

    //this method displays records page by page
    displayRecordPerPage(page){
        
        this.startingRecord = ((page - 1) * this.pageSize);
        this.endingRecord = (this.pageSize * page);

        this.endingRecord = (this.endingRecord > this.totalRecountCount)
            ? this.totalRecountCount : this.endingRecord;
            this.data = this.parseData!=undefined ? this.parseData.slice(this.startingRecord, this.endingRecord) : this.resultItems.slice(this.startingRecord, this.endingRecord);
            this.startingRecord = this.startingRecord + 1;
            this.template.querySelector(
                '[data-id="datarow"]'
              ).selectedRows = this.selection;
    }

}