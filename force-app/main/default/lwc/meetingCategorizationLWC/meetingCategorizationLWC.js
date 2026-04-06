import { LightningElement, track, wire,api } from 'lwc';
import getCustomMetadataRecords from '@salesforce/apex/MeetingCategorizationController.getCustomMetadataRecords';
import getFilterCustomMetadataRecords from '@salesforce/apex/MeetingCategorizationController.getFilterCustomMetadataRecords';
import getMeetingCategoryPicklistValues from '@salesforce/apex/MeetingCategorizationController.getMeetingCategoryPicklistValues';
import getEventRecords from '@salesforce/apex/MeetingCategorizationController.getEventRecords';
import getWhoIdDetails from '@salesforce/apex/MeetingCategorizationController.getWhoIdDetails';
import getEditAccessForRemainingChunks from '@salesforce/apex/MeetingCategorizationController.getEditAccessForRemainingChunks';
import updateSelectedRecords from '@salesforce/apex/MeetingCategorizationController.updateSelectedRecords';
import updateLeaderAttended from '@salesforce/apex/MeetingCategorizationController.updateLeaderAttended';
import updateRelatedToRecords from '@salesforce/apex/MeetingCategorizationController.updateRelatedToRecords';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import MeetingCategorizationLwc from "@salesforce/resourceUrl/MeetingCategorizationLwc";
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';

export default class MeetingCategorizationLWC extends LightningElement {
    _name;
    _label;
    meeting_Category = 'None';
    isCssLoaded = false;
    noOppSourced = false;
    noOppSourcedwithOther = false;
    
    upcomingMeetings = false;
    isLoading = false;
    _req = false;
    //selectedRowRecords;
    dispositionedRecords = [];
    _error;

    pageSize = 20;
    @track isPreviousDisable = true;
    @track isNextDisable = false;
    @track page = 1;
    @track totalPage = 1;
    @track resultItems = [];
    @track wasPreviousSortCategory = false;
    isLeaveBlank = true;
    selectedLeaveBlank = false;
    totalRecountCount = 0;
    startingRecord = 0;
    endingRecord = 0;
    selection = [];
    dashboard = 'Categorization'; 
    relatedToLabelForFilter = 'Related To - Opportunity';
    relatedToIconName = 'standard:opportunity';
    sObjectApiName = 'Opportunity';
    accountListForRelatedTo = [];
    showOpportunitySearchFilter = false;

    @track mainFilterList = [];
    @track meetingCatgeoryData;
    @track meetingCategoryOptions;
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
    @track isShowRelatedToModal = false;
    @track isShowLeaderAttendedModal = false;
    @track eventIds = [];
    @track isTaggingDisabled = false;
    @track dataItems = [];
    @track filterMap = new Map();
    @track setOfEventIdWithLead = new Set();
    @track countOfUntaggedEventsWithLead = 0;
    @track defaultMonthFilter = '';
    headerTitles=[
        {
            id:'total',
            label:'Total Meetings',
            count:0
        },
        {
            id:'tagged',
            label:'Total Tagged Meetings',
            count:0
        },
        {
            id:'untagged',
            label:'Total Untagged Meetings',
            count:0
        }
    ];
    
    @track taggedOutCome = [];
    getMeetingConsoleMetadataRecords(){
        getFilterCustomMetadataRecords()
        .then(result =>{
            this.dataItems = result.map(item =>{
                let optionsValues = [];
                let defaultValues = '';
                let isMultiselect = false;
                item.Options__c.split(';').forEach(val =>{
                    /*if(item.MasterLabel === 'Week of Fiscal Quarter' && val === 'All Weeks'){
                        optionsValues.push({label: '--None--' , value: val});
                    }else{
                        optionsValues.push({label: val , value: val});
                    }*/
                   if(item.MasterLabel === 'Meeting Category' && val === 'None'){
                        optionsValues.push({label: '--None--' , value: val});
                    }else{
                        optionsValues.push({label: val , value: val});
                    }
                });
                if(item.MasterLabel == 'Meeting Timing'){
                    defaultValues = 'All Meetings';
                }
                if(item.MasterLabel == 'Meeting FQ'){
                    defaultValues = 'Current Quarter';
                }
                if(item.MasterLabel == 'Month of the Fiscal Quarter'){
                    defaultValues = this.getMonthOfFiscalQuarter();
                }
                if(item.MasterLabel === 'Week of Fiscal Quarter'){
                    defaultValues = 'All Weeks';
                }
                if(item.MasterLabel == 'Meeting Category'){
                    item.Options__c.split(';').forEach(item1 =>{
                        this.taggedOutCome.push(item1);
                    })
                    isMultiselect = true;
                    this.meetingCategoryOptions = [optionsValues];
                }
                return {...item, 
                    "optionsValues": optionsValues,
                    "defaultValue": defaultValues,
                    "isMultiselect": isMultiselect
                }
            });
            let totalRows = Math.ceil(this.dataItems.length / 5);
            let starting = 0;
            let ending = this.dataItems.length <= 5 ? this.dataItems.length : 5;

            for(let i =0;i<totalRows ;i++){
                let filters = this.dataItems.slice(starting, ending);
                let row = {'data': filters, "isFirstRow": i === 0};
                this.mainFilterList.push(row);
                starting = starting +5;
                ending = ending +5;
            }
        })
        .catch(error =>{
            console.log('err---',error);
        })
    }

    getMeetingConsoleColumnsMetadataRecords(){
        getCustomMetadataRecords()
        .then(result =>{
            let items = [];
            result.forEach(item => {
                if(item.Type__c == 'boolean'){
                    items = [...items , {
                        label: item.MasterLabel, 
                        fieldName: item.FieldName__c,
                        type: item.Type__c, 
                        sortable: item.Sortable__c,
                        cellAttributes:{
                          alignment: 'center',
                          class:{fieldName:'cellColor'}
                              }
                        }
                        ];

                }else if(item.Type__c != 'url'){
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
                }else if(item.FieldName__c == 'Lead_Icon'){
                    items = [...items , {
                                        label: '', 
                                        fieldName: item.Hyperlink__c,
                                        type: item.Type__c,
                                        sortable: item.Sortable__c,
                                        fixedWidth: 32,
                                        hideDefaultActions: true,
                                        cellAttributes:{
                                          iconName: {fieldName:'leadIcon'},
                                          class : 'alignLeadIcon'
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
            console.log('items---',items);
            this.columns = items;

        })
        .catch(error =>{
            console.log('err---',error);
        })
    }

     /*@wire(getMeetingCategoryPicklistValues)
    meetingCategoryValues({error,data}){
        if(data){
            data.forEach(item =>{
                this.taggedOutCome.push(item);
            })
        }else if(error){

        }
    }*/

    /*@wire(getFilterCustomMetadataRecords)
    filterData({error,data})
    {
        if(data){
            this.dataItems = data.map(item =>{
                let optionsValues = [];
                let defaultValues = '';
                item.Options__c.split(';').forEach(val =>{
                    optionsValues.push({label: val , value: val});  
                });
                if(item.MasterLabel == 'Meeting Timing'){
                    defaultValues = 'All Meetings';
                }
                if(item.MasterLabel == 'Meeting FQ'){
                    defaultValues = 'Current Quarter';
                }
                if(item.MasterLabel == 'Month of the Fiscal Quarter'){
                    defaultValues = this.getMonthOfFiscalQuarter();
                }
                return {...item, 
                    "optionsValues": optionsValues,
                    "defaultValue": defaultValues
                }
            });
            let totalRows = Math.ceil(this.dataItems.length / 5);
            let starting = 0;
            let ending = this.dataItems.length <= 5 ? this.dataItems.length : 5;

            for(let i =0;i<totalRows ;i++){
                let index = this.dataItems.findIndex((data)=> data.MasterLabel === 'Meeting Category');
                if(index != -1){
                    this.meetingCatgeoryData = this.dataItems.splice(index,1);
                }                
                this.meetingCategoryOptions = this.meetingCatgeoryData.map(item => item.optionsValues);
                let noneValue = {"label":"--None--","value":"None"};
                this.meetingCategoryOptions[0].unshift(noneValue);
                this.mainFilterList.push(this.dataItems.slice(starting, ending));
                starting = starting +5;
                ending = ending +5;
            }
        }else if(error){
            console.log('err---',error);
        }
    }*/
   /* @wire(getCustomMetadataRecords)
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
    }*/
    connectedCallback(){
        Promise.all([
            loadStyle(this, MeetingCategorizationLwc )
        ]).catch(error => {
            console.log('Error loading styles: ' + JSON.stringify(error));
        });
        this.isLoading=true;
        this.setDefaultFilter();
        this.getMeetingConsoleColumnsMetadataRecords();
        this.getMeetingConsoleMetadataRecords();
        this.datarecords();
    }
    setDefaultFilter(){
        this.filterMap.set('Meeting_Timing','All Meetings');
        this.filterMap.set('Meeting_FQ','Current Quarter');
        this.filterMap.set('Week_of_Fiscal_Quarter','All Weeks');
        this.getMonthOfFiscalQuarter();
    }
    getMonthOfFiscalQuarter(){
        const d = new Date();
        let month = d.getMonth();
        if( month % 3 === 1){
            this.defaultMonthFilter = 'Month 1';
        }else if(month % 3 === 2){
            this.defaultMonthFilter = 'Month 2';
        }else if(month % 3 === 0){
            this.defaultMonthFilter = 'Month 3';
        }
        this.filterMap.set('Month_of_the_Fiscal_Quarter',this.defaultMonthFilter);
        return this.defaultMonthFilter;
    }
    get options() {
        return [
            { label: 'Past Meeting', value: 'Past Meeting' },
            { label: 'Upcoming Meeting', value: 'Upcoming Meeting' },
            { label: 'All Meetings', value: 'All Meetings' },
        ];
    }
    handleChange(event){
        if(event.target.name == 'Meeting_Timing'){
            this.meetingTimings = event.target.value;
        }
       if(event.target.name !== 'Meeting_Category'){
            this.filterMap.set(event.target.name, event.target.value);
       } 
       this.arrayrrr = Array.from(this.filterMap, ([key, value]) => ({ key, value }));
    }
    filterSubmit(){
        this.isLoading = true;
        this.page= 1;
        this.isPreviousDisable = true;
        this.startingRecord =0;
        this.parseData = undefined;
        this.selection = [];
        this.accountLinkList = [];
        this.datarecords(true);
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
            }else if(element.DeveloperName == 'Week_of_Fiscal_Quarter'){
                this.template.querySelector(`[data-id=${element.DeveloperName}]`).value = 'All Weeks';
            }else if(element.DeveloperName == 'Month_of_the_Fiscal_Quarter'){
                this.template.querySelector(`[data-id=${element.DeveloperName}]`).value = this.defaultMonthFilter;
            }else{
                this.template.querySelector(`[data-id=${element.DeveloperName}]`).value = '';
            }
        });
        this.template.querySelector('c-meeting-category-multi-select').resetCategory();
        this.isLoading=true;
        this.page= 1;
        this.isPreviousDisable = true;
        this.startingRecord =0;
        this.parseData = undefined;
        this.selection = [];
        this.setDefaultFilter();
        this.accountLinkList = [];
        this.datarecords(true);
        if(this.data != undefined){
            this.template.querySelector('lightning-datatable').selectedRows=[];
        }
        
    }
    @track arrayrrr;
    @track persistData = [];
    @api accountLinkList = [];
    @track selectedAccountId;
    @track selectedOpportunityId;
    clonedResultItem = [];

    datarecords(isParent = false){
        this.persistData = [];
        this.arrayrrr = Array.from(this.filterMap, ([key, value]) => ({ key, value }));
        getEventRecords({filterMapValues : JSON.stringify(this.arrayrrr), eventData :JSON.stringify(this.updatedEvents)})
        .then(result => {
            this.totalRecountCount = result.length;
            this.totalPage = this.totalRecountCount <= this.pageSize ? 1 : Math.ceil(this.totalRecountCount / this.pageSize);
            this.isNextDisable = this.totalPage == 1 ? true : false;
            
            this.endingRecord = this.totalRecountCount <= this.pageSize ? this.totalRecountCount :this.pageSize;
            this.setOfEventIdWithLead.clear();
            this.countOfUntaggedEventsWithLead = 0;
             this.resultItems = result.map(item =>{
                this.accountLinkList.push(item.accountLink.replace('/',''));

                let cellColor;
                let set_date;
                if(item.createdDateString != undefined){
                    set_date = item.createdDateString.split(' ')[0];
                }
                item.actualCreatedDate = item.createdDate;
                item.actualCreatedDateString = set_date;
                
                item.actualActivityDate = item.activityDate;
                item.actualActivityDateString =item.activityDateString;

                cellColor = "slds-truncate";
                let taggedOutCome = ["None","Marketing / SDR Intro Meeting","Discovery Meeting","New Business Meeting","Deal Progression Meeting","EB Go / No Go","Champ Go / No Go","Partner Meeting","Other Meetings", "Cancelled"];                
                if(!taggedOutCome.includes(item.meetingCategory) && item.meetingCategory != undefined){
                    this.persistData.push(item);
                }
                if(!item.hasAccessToEditTheMeeting){
                    cellColor = "insufficientAccessRow";
                }
                if(item.leadContactLink.startsWith('/00Q')){
                    this.setOfEventIdWithLead.add(item.meetingLink);
                }
                
                return {...item, 
                   "cellColor": cellColor}

            });
            /*if(isParent){
                this.template.querySelector("c-meeting-category-account-search").handlerMethod(this.accountLinkList);
            }*/
            if(this.resultItems.length > 200){
                this.getTheEditAccessForRemainingRecords();
            }
            this.clonedResultItem = JSON.parse(JSON.stringify(this.resultItems));
            this.data = this.resultItems.slice(0, this.totalRecountCount <= this.pageSize ? this.totalRecountCount :this.pageSize);
            this.parseData = JSON.parse(JSON.stringify(this.resultItems));
            this.meeting_Category = 'None';
            this.isLoading=false;
        })
        .catch(error =>{
            this._error = error;
            console.log('error::: '+JSON.stringify(error));
             this.data = undefined;
        })
    }
    getTheEditAccessForRemainingRecords(){
        if(this.resultItems.length > 200){
            let chunkResultItems = (dataItem, chunkSize) =>{
                const chunks = [];
                for (let i = 0; i < dataItem.length; i += chunkSize) {
                  chunks.push(dataItem.slice(i, i + chunkSize));
                }
                return chunks;
            }
            let getReturnedChunks = chunkResultItems(this.resultItems, 200);
            getReturnedChunks = getReturnedChunks.slice(1);
            let chunkNumber = 0;
            if(getReturnedChunks.length > 2){
                this.isLoading=true;
            }
            getReturnedChunks.forEach(chunk =>{
                let meetingLinks = [];
                chunk.map((item1) => {
                    meetingLinks.push(item1.meetingLink.replace('/','').trim());
                });
                getEditAccessForRemainingChunks({meetingIds: meetingLinks, eventWrapperStringified: JSON.stringify(chunk)})
                .then(result => {
                    chunkNumber += 1;
                    let mergeUpdatedChunkToMainData = (actualResultItem, chunkOfResultItems) => {
                        chunkOfResultItems.forEach(subItem => {
                            let mainItemIndex = actualResultItem.findIndex(mainItem => mainItem.meetingLink === subItem.meetingLink);
                            if (mainItemIndex !== -1) {
                                actualResultItem[mainItemIndex] = subItem;
                            }
                        });
                    }
                    mergeUpdatedChunkToMainData(this.resultItems, result);
                    this.resultItems = this.resultItems.map(item =>{
                        let cellColor;
                        let set_date;
                        if(item.createdDateString != undefined){
                            set_date = item.createdDateString.split(' ')[0];
                        }
                        item.actualActivityDate = item.activityDate;
                        item.actualActivityDateString =item.activityDateString;
                        item.actualCreatedDate = item.createdDate;
                        item.actualCreatedDateString = set_date;
                        cellColor = "slds-truncate";
                        if(!item.hasAccessToEditTheMeeting){
                            cellColor = "insufficientAccessRow";
                        }
                        return {...item, 
                            "cellColor": cellColor}
                        
                    });
                    this.clonedResultItem = JSON.parse(JSON.stringify(this.resultItems));
                    this.parseData = JSON.parse(JSON.stringify(this.resultItems));
                    if(chunkNumber == getReturnedChunks.length){
                        this.isLoading= false;
                    }
                });
            })
        }
    }
    doSorting(event){
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }
    @track parseData;
    /*sortData(fieldname, direction) {
        this.parseData = JSON.parse(JSON.stringify(this.resultItems));
        if(fieldname == 'actualActivityDateString'){
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
    }*/

    sortData(fieldname, direction) {
        let fieldNamesForSorting = [];
        this.parseData = JSON.parse(JSON.stringify(this.resultItems));
        if(fieldname == 'actualActivityDateString'){
            fieldname = 'actualActivityDate';
        }
        else if(fieldname == 'actualCreatedDateString'){
            fieldname = 'actualCreatedDate';
        }

        if(fieldname !== 'actualCreatedDate'){
            fieldNamesForSorting.push(fieldname);
            this.parseData = this.performSort(this.parseData, fieldNamesForSorting, direction);
            if(fieldname == 'meetingCategory'){
                this.wasPreviousSortCategory = true;
            }else{
                this.wasPreviousSortCategory = false;
            }
        }else{
            if(this.wasPreviousSortCategory){
                fieldNamesForSorting.push(fieldname, 'meetingCategory');
                this.parseData = this.performSort(this.parseData, fieldNamesForSorting, direction);

            }else{
                fieldNamesForSorting.push(fieldname);
                this.parseData = this.performSort(this.parseData, fieldNamesForSorting, direction);
            }
        }
        this.data = this.parseData.slice(this.startingRecord, this.endingRecord);
    }

    performSort(data, fieldNamesForSorting, direction) {
        let keyValue = (a) => {
            if (fieldNamesForSorting[0] == 'accountLink') {
                return a['accountName'];
            } else {
                return a[fieldNamesForSorting[0]];
            }
        };
        
        let isReverse = direction === 'asc' ? 1 : -1;

        if(fieldNamesForSorting.length === 1){
            return data.slice().sort((x, y) => {
                x = keyValue(x) ? keyValue(x) : '';
                y = keyValue(y) ? keyValue(y) : '';
    
                if (fieldNamesForSorting[0] == 'activityDate') {
                    let a = x.slice(0, 10);
                    let b = y.slice(0, 10);
                    return isReverse * ((a > b) - (b > a));
                } else {
                    return isReverse * ((x > y) - (y > x));
                }
            });
        }else{
            let keyValue1 = (a) => {
                return a['meetingCategory'];     
            };

            return data.slice().sort((x, y) => {
                let a = keyValue1(x) ? keyValue1(x) : '';
                let b = keyValue1(y) ? keyValue1(y) : '';

                let c = keyValue(x) ? keyValue(x) : '';
                let d = keyValue(y) ? keyValue(y) : '';
    
                return 1 * ((a > b) - (b > a)) || isReverse * ((c > d) - (d > c));
            });
        }
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
            // this.startingRecord = this.startingRecord + 1;
            this.template.querySelector(
                '[data-id="datarow"]'
              ).selectedRows = this.selection;
    }

    //getting selected  values from child componenet
    handleSelectedMeetingCategory(event){
        const selectedItems=event.detail;
        this.filterMap.set('Meeting_Category', selectedItems);
        this.arrayrrr = Array.from(this.filterMap, ([key, value]) => ({ key, value }));
    } 
    // getting selected records
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
                evt.detail.selectedRows = evt.detail.selectedRows.filter(row => row.cellColor !== 'insufficientAccessRow');
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

     get leaderAttendedOption(){
        let selectedOptions = [];
        selectedOptions.push({ label: '--None--', value: 'none' });
        selectedOptions.push({ label: 'RD', value: 'RD' });
        selectedOptions.push({ label: 'VP', value: 'VP' });
        selectedOptions.push({ label: 'Senior Leader', value: 'Senior Leader' });
        selectedOptions.push({ label: 'CEO', value: 'CEO' });
        return selectedOptions;
     }

    get selectedRowsOption(){
        let selectedOptions = [];
        this.taggedOutCome.forEach(item =>{
            if(item === 'None'){
                selectedOptions.push({ label: '--None--', value: item });
            }else{
                selectedOptions.push({ label: item, value: item });
            }
        });

        return selectedOptions;
        /*[
            { label: 'Marketing / SDR Intro Meeting', value: 'Marketing / SDR Intro Meeting' },
            { label: 'Discovery Meeting', value: 'Discovery Meeting' },
            { label: 'New Business Meeting', value: 'New Business Meeting' },
            { label: 'Champ Go / No Go', value: 'Champ Go / No Go' },
            { label: 'Deal Progression Meeting', value: 'Deal Progression Meeting' },
            { label: 'EB Go / No Go', value: 'EB Go / No Go' },
            { label: 'Partner Meeting', value: 'Partner Meeting' },
            { label: 'Other Meetings', value: 'Other Meetings' },
            { label: 'Cancelled', value: 'Cancelled' },
       ];*/
   }

    quickTaggingHandler(){
        if(this.data != undefined){
            let selectedRecords = [];
            let event_Ids = [];
            selectedRecords =  this.selection;

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
    /*relatedToHandler(){
        if(this.data != undefined){
            let selectedMeetings = [];
            let meetingIds = [];
            selectedMeetings =  this.selection;

            if(selectedMeetings == ''){
                this.showToast('Please select atleast 1 record', 'error','','dismissable');
            }else{
                selectedMeetings.forEach(element =>{
                    meetingIds.push(element.replace('/','').trim());
                });
                this.eventIds = meetingIds;
                getWhoIdDetails({selectedEventIds : this.eventIds})
                .then(result => {
                    if(result === ''){
                        this.isShowRelatedToModal = true;
                        this.showOpportunitySearchFilter = true;
                    }else{
                        this.showToast('Please convert the Lead(' + result + ') to Contact before associating the Opportunity', 'error','', 'sticky');
                    }
                })
                .catch(error =>{
                    console.log('after getWhoIdDetails error--',JSON.stringify(error));
                }) 
            }
        }
    }*/

    relatedToHandler(){
        if(this.data != undefined){
            let selectedMeetings = [];
            this.countOfUntaggedEventsWithLead = 0;
            let meetingIds = [];
            selectedMeetings =  this.selection;
            if(selectedMeetings == ''){
                this.showToast('Please select atleast 1 record', 'error','','dismissable');
            }else{
                selectedMeetings.forEach(element =>{
                    if(!this.setOfEventIdWithLead.has(element)){
                        meetingIds.push(element.replace('/','').trim());
                    }else{
                        this.countOfUntaggedEventsWithLead += 1;
                    }
                });
                this.eventIds = meetingIds;
                this.isShowRelatedToModal = true;
                this.showOpportunitySearchFilter = true;
            }
        }
    }

    meetingCategoryHandler(event){
        this.meeting_Category = event.target.value;
    }
    hideModalBox(){
        this.isShowModal = false;
    }
    cancelRelatedTo(){
        this.isShowRelatedToModal = false;
        this.showOpportunitySearchFilter = false;
    }
    
    submitQuickTagging(){
        this.isLoading = true;
        this.isShowModal = false;
        
        if(this.eventIds != ''){
            updateSelectedRecords({ selectedEventIds : this.eventIds , varMeetingCategory : this.meeting_Category})
            .then(result => {
                this.page = 1;
                this.selection = [];
                 this.isPreviousDisable = true;
                this.updatedEvents = result;
                if(this.updatedEvents == ''){
                    this.showToast('Selected meetings have been tagged successfully', 'success','', 'dismissable');
                    
                }else{
                    this.showToast(this.updatedEvents.length+' of '+Number(this.eventIds.length) +' Meeting were not successfully tagged, please correct and reattempt ', 'error','', 'sticky');
                    this.meeting_Category = 'None';
                }
                this.updatedEvents.push.apply(this.updatedEvents,this.persistData);
                this.datarecords();
                
            })
            .catch(error =>{
                console.log('after tagged error--',JSON.stringify(error));
            })
        }
        
    }
    submitRelatedTo(){
        this.isLoading = true;
        this.isShowRelatedToModal = false;
        if(this.eventIds != '' || this.countOfUntaggedEventsWithLead > 0){
            if(this.selectedOpportunityId != undefined || (this.selectedOpportunityId == undefined && this.selectedLeaveBlank)){
                updateRelatedToRecords({ selectedEventIds : this.eventIds , relatedToOpportunity : this.selectedOpportunityId, selectedLeaveBlank: this.selectedLeaveBlank})
                .then(result => {
                    this.page = 1;
                    let selectedLength = this.selection.length;
                    this.selection = [];
                    this.isPreviousDisable = true;
                    this.updatedEvents = result;
                    if(this.updatedEvents == ''){
                        let sucessFullyUpdatedMeetings = selectedLength - this.countOfUntaggedEventsWithLead;
                        if(this.countOfUntaggedEventsWithLead == 0 && this.eventIds.length > 0){
                            this.showToast(sucessFullyUpdatedMeetings + ' out of ' +  selectedLength + ' meetings were successfully updated.','success','', 'dismissable');
                        }else if(sucessFullyUpdatedMeetings > 0 && this.countOfUntaggedEventsWithLead > 0){
                             this.showToast(sucessFullyUpdatedMeetings + ' out of ' +  selectedLength + ' meetings were successfully updated. Please convert the remaining '+ this.countOfUntaggedEventsWithLead + ' Leads to Contacts before attempting', 'success','', 'dismissable');
                        }else if(sucessFullyUpdatedMeetings == 0){
                            this.showToast('Please convert the ' +  selectedLength + ' Leads to Contacts before attempting', 'success','', 'dismissable');
                        }
                    }else{
                        this.showToast(this.updatedEvents.length+' of '+Number(this.eventIds.length) +' Meeting were not successfully updated, please correct and reattempt ', 'error','', 'sticky');
                    }
                    this.updatedEvents.push.apply(this.updatedEvents,this.persistData);
                    this.showOpportunitySearchFilter = false;
                    this.datarecords();
                    this.selectedLeaveBlank = false;
                    this.selectedOpportunityId = null;
                })
                .catch(error =>{
                    console.log('after relatedTo error--',JSON.stringify(error));
                })
            }else{
                this.showToast('No Opportunity was selected to update the RelatedTo on the selected meetings, please correct and reattempt ', 'error','', 'sticky');
                this.isLoading = false;
                this.isShowRelatedToModal = true;
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

    handleUpload(event){
        if(!this.showOpportunitySearchFilter){
            this.selectedAccountId = event.detail.selectedId;
            this.accountLinkList = [];
            this.searchAccountHandler(this.selectedAccountId);
            this.page = 1;
            this.selection = [];
            this.isPreviousDisable = true;
        }
    }
    searchAccountHandler(value){
        this.isLoading=true;
        let resultData = [];
        this.data = [];
        
        if(value != undefined){
            this.resultItems.map(item => {
                try{
                    if(item.accountName.toLowerCase().search(value.toLowerCase()) != -1){
                        resultData.push(item);
                    } 
                }catch(err){
                    console.log('err- ',err);
                }
            }); 
            this.resultItems = [];
            this.resultItems = resultData;
            this.sliceMethod();   
        }else{
             this.resultItems = [];
             this.resultItems = this.clonedResultItem;
             this.sliceMethod(); 

        }
    }

    sliceMethod(){
        let totalRecountCount = this.resultItems.length;
        let totalPages = totalRecountCount <= this.pageSize ? 1 : Math.ceil(totalRecountCount / this.pageSize);
        this.totalPage = totalPages;
        this.isNextDisable = this.totalPage == 1 ? true : false;
        
        this.endingRecord = totalRecountCount <= this.pageSize ? totalRecountCount :this.pageSize;
        this.data = this.resultItems.slice(0, totalRecountCount <= this.pageSize ? totalRecountCount :this.pageSize);
        this.isLoading=false;
    }

    handleRelatedToUpload(event){
        if(this.sObjectApiName === 'Opportunity' && this.showOpportunitySearchFilter){
            this.selectedOpportunityId = event.detail.selectedId;
        }
    }

    handleIsLeaveBlank(event){
        if(this.sObjectApiName === 'Opportunity' && this.showOpportunitySearchFilter){
            if(event.detail.isLeaveBlank != undefined){
                this.selectedLeaveBlank = event.detail.isLeaveBlank;
            }
        }
    }

    LeaderAttendedHandler(){
        if(this.data != undefined){
            let selectedMeetings = [];
            let meetingIds = [];
            selectedMeetings =  this.selection;
            if(selectedMeetings == ''){
                this.showToast('Please select atleast 1 record', 'error','','dismissable');
            }else{
                selectedMeetings.forEach(element =>{
                        meetingIds.push(element.replace('/','').trim());
                });
                this.eventIds = meetingIds;
                this.isShowLeaderAttendedModal = true;
            }
        }

    }
    cancelLeaderAttended(){
        this.isShowLeaderAttendedModal = false;
    }
    @track leaderValue = 'none';
    leaderAttendedHandler(event){
        this.leaderValue = event.target.value;
    }

    submitLeaderAttended(){
        this.isShowLeaderAttendedModal = false;
        this.isLoading = true;
        if(this.eventIds != ''){
            updateLeaderAttended({ selectedEventIds : this.eventIds , varLeaderAttended : this.leaderValue})
            .then(result => {
                this.page = 1;
                this.selection = [];
                this.isPreviousDisable = true;
                this.updatedEvents = result;
                if(this.updatedEvents == ''){
                    this.showToast('Selected meetings have been updated successfully', 'success','', 'dismissable');
                    
                }else{
                    this.showToast(this.updatedEvents.length+' of '+Number(this.eventIds.length) +' Meeting were not successfully updated, please correct and reattempt ', 'error','', 'sticky');
                }
                this.leaderValue ='none';
                this.updatedEvents.push.apply(this.updatedEvents,this.persistData);
                this.datarecords();
                
            })
            .catch(error =>{
                console.log('after tagged error--',JSON.stringify(error));
            })
        }
    }
}