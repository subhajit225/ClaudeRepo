import { LightningElement,api,wire,track } from 'lwc';
import getColumnsAccountDetails from '@salesforce/apex/HeatMapController.getColumnsAccountDetails';
import getEditAccessOnAccounts from '@salesforce/apex/HeatMapController.setEditAccessOnAccounts';
import heatMapStyles from '@salesforce/resourceUrl/HeatMapStyles';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class HeatMapDatatable extends LightningElement {
    selectedColumnFilter = null;
    loadingData = false;
    @track columnMapNew = new Map();
    @track showWorkloadModal = false;
    showHoverModal = false;
    //entryAndWorkload = [];
    @track workloadToPass = {};
    modalStyle = '';
    modalStyleHover = '';
    selectedFilter = '';
    screenWidth;
    hasEditAccountAccess = false;
    clickedType = '';
    showMiniModal = false;
    showMultiModal = false;
    //@api allFilters = {};
    @track dataAccounts = [];
    @track filteredDataAccounts = [];
    @track currentPageData = []; //stores the current account data as per pagination
    @track accountAndWorkloads = [];
    @track columns =[];
    @track fixedColumns = [
        {label:"Account",title:"Account" ,columnClass:"slds-is-resizable slds-is-sortable slds-cell_action-mode fixed-column first-column columnHeaders" , isSortable:true ,iconName:"utility:sort"},
        // {label:"",title:"Salesforce" ,columnClass:"slds-is-resizable slds-is-sortable slds-cell_action-mode fixed-column sec-column columnHeaders" , isSortable:false ,iconName:"utility:sort"},
        {label:"",title:"SentryAI" ,columnClass:"slds-is-resizable slds-is-sortable slds-cell_action-mode fixed-column sec-column columnHeaders" , isSortable:false ,iconName:"utility:sort"}
        // {label:"",title:"SentryAI" ,columnClass:"slds-is-resizable slds-is-sortable slds-cell_action-mode fixed-column thrd-column columnHeaders" , isSortable:false ,iconName:"utility:sort"}
    ];
    @api preferredFilters;
    @api showDatatable = false;
    @track selectedFiltersToApex;
    @track unselectedAccountIds = new Set();

    //Pagination Variables start
    @track pageNumber = 1;
    @track totalPages = 0;
    @track startingRecord;
    @track endingRecord;
    @track totalRecords = 0;
    @track pageSize = 200;
    // Pagination Variables End

    //Sorting Variable Start here
    @track sortedDirection = 'asc';
    @track sortedBy = 'accountName';
    @track sortingDefinationType = 'String';
    @track maintainSortState = false;
    @track prevState = '';
    @track workloadMap = {
        'Protected': 1,
        'Protected*': 1,
        'Target': 2,
        'Target*': 2,
        'Not Protected': 3,
        'Not Protected*': 3,
        'NA': 4,
        'NA*': 4,
        '': 5,
        '*': 5
    };
    @track filteredAccountDetails = [];
    //Sorting Variable End Here

    backgroundColors = {
        'Protected': 'background-color: #00B46E',
        'Protected*': 'background-color: #00B46E',
        'Not Protected': 'background-color: #BAC9D1',
        'Not Protected*': 'background-color: #BAC9D1',
        'Target': 'background-color: #0668DD;',
        'Target*': 'background-color: #0668DD;',
        'BE': 'background-color: #FFBE2E',
        'EE': 'background-color: #008451',
        'EPE': 'background-color: #005535',
        'FE': 'background-color: #980000',
        'BE; FE': 'background-color: #FFBE2E',
        'EE; BE': 'background-color: #9AB200',
        'EE; FE': 'background-color: #9AB200',
        'EPE; EE': 'background-color: #008451',
        'EPE; FE': 'background-color: #9AB200',
        'EPE; BE': 'background-color: #9AB200',
        'EE; BE; FE': 'background-color: #9AB200',
        'EPE; BE; FE': 'background-color: #9AB200',
        'EE; EPE; FE': 'background-color: #9AB200',
        'EE; EPE; BE': 'background-color: #9AB200',
        'EE; EPE; BE; FE': 'background-color: #9AB200'
    };

    @track alignmentMap = {
        'Left': 'cellLeftAlign',
        'Right': 'cellRightAlign',
        'Center': 'cellCenterAlign'
    };

    lowColor = [78, 202, 139];  // #4ECA8B (lowest value)
    highColor = [0, 85, 53];    // #005535 (highest value)

    _preferredAccounts = [];
    set preferredAccounts(values) {
        this._preferredAccounts = values?.filter(value => value.isChecked).map(value => value.id)
    }
    @api get preferredAccounts() {
        return this._preferredAccounts;
    }

    @api getUpdatedColumnData(selectedFilters){
        this.selectedFiltersToApex = JSON.parse(JSON.stringify(selectedFilters));
        this.getColumnsAndAccountDetails();
    }

    @api getUpdatedRowData(selectedFilters) {
        this.selectedFiltersToApex = JSON.parse(JSON.stringify(selectedFilters));
        this.sortedDirection = 'asc';
        this.sortedBy = 'accountName';
        this.pageNumber = 1;
        this.manageSortingIcon();
        this.getColumnsAndAccountDetails();
    }

    connectedCallback() {
        document.addEventListener('click', this.handleDocumentClick);
        Promise.all([
            loadStyle(this, heatMapStyles )
        ]).catch(error => {
            console.log('Error loading styles: ' + JSON.stringify(error));
        });
        this.selectedFiltersToApex = JSON.parse(JSON.stringify(this.preferredFilters));
        this.showDatatable = true;
        this.getColumnsAndAccountDetails();
    }
    
    get dataAccounts(){
        return this.dataAccounts;
    }

    get showPagination(){
        return this.filteredDataAccounts.length > this.pageSize && !this.loadingData;
    }

    get isNextDisabled() {
        return this.pageNumber == this.totalPages ? true : false;
    }

    get isPreviousDisabled() {
        return this.pageNumber == 1 ? true : false;
    }

    get sortingIcon(){
        return this.sortedDirection == 'asc'?'utility:arrowup':'utility:arrowdown';
    }
     @track columnToListOfOptions = new Map();
    getColumnsAndAccountDetails(){
		this.loadingData = true;
        const customEvent = new CustomEvent("isheatmapreadonly", {
            detail : true
        });
        this.dispatchEvent(customEvent);
        getColumnsAccountDetails({selectedFiltersToApex:JSON.stringify(this.selectedFiltersToApex)})
        .then(result =>{
            let accountWorkloadsWrapper = this.setWorkloadProperties(result.accountDetailsWrapper);
            if(accountWorkloadsWrapper && accountWorkloadsWrapper.length > 0){
                accountWorkloadsWrapper = this.setPropertiesOfSumOfWon(accountWorkloadsWrapper,result.columnDetailsWrapper);
            }
            const columnExists = result.columnDetailsWrapper?.some(column => column.columnName === this.sortedBy);
            if (!columnExists) {
                this.sortedBy = 'accountName';
                this.sortedDirection = 'asc';
                this.sortingDefinationType = 'String';
            }
            this.dataAccounts = this.doSorting(this.sortedBy,this.sortedDirection, accountWorkloadsWrapper,this.sortingDefinationType);            
            if(this.dataAccounts){
                this.showDatatable = this.dataAccounts.length > 0;
            }
            if (this.preferredAccounts?.length) {
                this.filteredDataAccounts = this.dataAccounts.filter(account => this.preferredAccounts.includes(account.accountId));
            } else {
                this.filteredDataAccounts = [...this.dataAccounts];
            }
            this.filteredAccountDetails = JSON.parse(JSON.stringify(this.filteredDataAccounts));

            this.setAccountAndWorkloads();
            this.columnMapNew = new Map();
            if(result.columnDetailsWrapper != null){
                result.columnDetailsWrapper.forEach(element => {
                    if(!this.columnMapNew.has(element.columnCategory)){
                        this.columnMapNew.set(element.columnCategory,[]);
                    }
                    this.columnMapNew.get(element.columnCategory).push(element.columnName);
                });
                const values = Array.from(this.columnMapNew.values());
                this.columns = values.flat();
                this.columns = this.columns.map(item => ({
                    label: item,
                    iconName: 'utility:sort',
                    sortingTypeDefinition: result.columnDetailsWrapper.find(column => column.columnName === item)?.sortingTypeDefinition,
                    isHeaderFilter: result.columnDetailsWrapper.find(column => column.columnName === item)?.isHeaderFilter,
                    columnCategory: result.columnDetailsWrapper.find(column => column.columnName === item)?.columnCategory,
                    columnName: result.columnDetailsWrapper.find(column => column.columnName === item)?.columnName,
                    showHeaderFilter: false,
                    reportUrl: result.columnDetailsWrapper.find(column => column.columnName === item)?.reportUrl,
                    isTelemetryAvailable: result.columnDetailsWrapper.find(column => column.columnName === item)?.isTelemetryAvailable,
                    headerFilterOptions: this.getFilterOptionsdata(result.columnDetailsWrapper.find(column => column.columnName === item)?.columnCategory, result.columnDetailsWrapper.find(column => column.columnName === item)?.columnName)
                }));
                this.columns.forEach(item =>{
                    this.columnToListOfOptions.set(item.columnName, item.headerFilterOptions);
                })
            }
            const customEvent = new CustomEvent("getaccountdetails", {
                detail : this.dataAccounts
            });
            this.dispatchEvent(customEvent);
            /* Dispatch account data to row filter*/
            const accountDetails = this.dataAccounts.map(item => (
                {
                    accountId: item.accountId,
                    accountName: item.accountName,
                    state: this.preferredAccounts?.length ? this.preferredAccounts.includes(item.accountId) : true
                }
            ));
            const customEvt = new CustomEvent("getaccountrowfilters", {
                detail : accountDetails
            });
            this.dispatchEvent(customEvt);
            /* Dispatch account data to row filter*/
            const divElement = this.template.querySelector('[data-id="divBlock"]');
            this.screenWidth = window.screen.width;
            this.updateDivElementClass(divElement);
            this.manageSortingIcon();
            this.paginationHelper();
            this.loadingData = false;
            const customReadOnlyEvent = new CustomEvent("isheatmapreadonly", {
                detail : false
            });
            this.dispatchEvent(customReadOnlyEvent);
        })
        .catch(error =>{
            console.log('error',JSON.stringify(error));
            this.loadingData = false;
            const customReadOnlyEvent = new CustomEvent("isheatmapreadonly", {
                detail : false
            });
            this.dispatchEvent(customReadOnlyEvent);
            this.showToastNotificationMessage(JSON.stringify(error));
        })
    }

    async handleCellRightClick(event){
        event.preventDefault();
        this.showWorkloadModal = false;
        await  this.clickHelper(event);
        const targetCell = event.target;
        let ele = this.template.querySelector(".heatmap-datatable .cell-selected");
        if(ele){
            ele.classList.remove('cell-selected');
        }
        targetCell.classList.add('cell-selected');
        const rect = targetCell.getBoundingClientRect();
        const y = rect.top + targetCell.offsetHeight - 10;
        const x = rect.left + targetCell.offsetWidth - 10;
        const top =  y + 135 > window.innerHeight ? y - 133 : y;
        const left = x + 200 > window.innerWidth ? x - 200 : x;
        this.modalStyle = `position: fixed; top: ${top}px; left: ${left}px; z-index:25`;
        this.clickedType = 'rightClick';
        
        this.showMultiModal = false;
        
        if(this.hasEditAccountAccess == 'true' && this.workloadToPass.columnFilter != 'Account Information'){
            this.showMiniModal = true;
        }else{
            this.showMiniModal = false;
        }
        window.setTimeout(() => window.addEventListener('click', this.handleClose), 0);   
        this.showWorkloadModal = true;  
    }
    maxScroll = '';
    handleCellDoubleClick(event){
        event.preventDefault();

        const targetCell = event.target;
        let ele = this.template.querySelector(".heatmap-datatable .cell-selected");
        if(ele){
            ele.classList.remove('cell-selected');
        }
        targetCell.classList.add('cell-selected');
        const rect = targetCell.getBoundingClientRect();
        const y = rect.top + targetCell.offsetHeight - 20;
        const x = rect.left + targetCell.offsetWidth - 20;
        const top =  y+ 300 > window.innerHeight ? y - 300 : y;
        const left = x + 420 > window.innerWidth ? x - 430 : x;
        this.modalStyle = `position: fixed; top: ${top}px; left: ${left}px; z-index:25`;
        this.maxScroll = (window.innerHeight - y >= 8) && (y != top) ? `max-height: ${230 + window.innerHeight - y}px;` : `max-height: ${window.innerHeight-rect.top - 310 +230}px;`;
        this.clickedType = 'doubleClick';
        this.showWorkloadModal = true;
        this.showHoverModal = false;
        this.showMiniModal = false;
        this.showMultiModal = true;
        this.clickHelper(event);
        window.setTimeout(() => window.addEventListener('click', this.handleClose), 0);
    }

    handleClose = () => {
        this.showWorkloadModal = false;
        this.clickedType = '';
        this.showMiniModal = false;
        this.showMultiModal = false;
        let ele = this.template.querySelector(".heatmap-datatable .cell-selected");
        if(ele){
            ele.classList.remove('cell-selected');
        }
        
        window.removeEventListener('click', this.handleClose);
    }

    handleModalAction(event){
        this.showWorkloadModal = false;
        this.showMiniModal = false;
        this.showMultiModal = false;
        const updateFlag = event.detail.updateWorkloadFlag;
        if(updateFlag){
            const updatedWorkloadObj = event.detail.heatMapEntryObj;
            const updatedAccountObj = event.detail.updatedAccountObj;
            this.filteredDataAccounts.forEach(element => {
                const workload = element.workloadCells.find(ele => (ele.columnId === updatedWorkloadObj.HeatMap_Column__c && ele.accountId === updatedWorkloadObj.Account__c));
                if (workload) {
                    const updateWorkloadField = (field, fieldName) => {
                        if (updatedWorkloadObj.hasOwnProperty(fieldName) && updatedWorkloadObj[fieldName] !== workload[field]) {
                            workload[field] = updatedWorkloadObj[fieldName];
                        }
                    };
                    updateWorkloadField('value', 'Manual_Workload_Value__c');
                    updateWorkloadField('manualWorkloadVal', 'Manual_Workload_Value__c');
                    updateWorkloadField('manualIncumbent', 'Manual_Incumbent__c');
                    updateWorkloadField('manualObjCount', 'Manual_Object_Count__c');
                    updateWorkloadField('manualObjCapacity', 'Manual_Object_Capacity__c');
                    workload.backgroundColour = this.backgroundColors[workload.value] || '';

                    if(workload?.value?.includes('*')){                        
                        workload.value = workload.value.replace('*', '');
                    }                    

                    if((workload?.manualObjCapacity && workload?.manualObjCapacity != 0) 
                        || (workload?.manualObjCount && workload?.manualObjCount != 0 )
                        || (workload?.manualIncumbent && workload?.manualIncumbent != null)){
                            workload.value = workload.value ? (workload.value.includes("*") ? workload.value : workload.value + '*') : '*';
                    }
                }

                const workloadAccount = element.workloadCells.find(ele => (ele.columnId === updatedAccountObj.columnId && ele.accountId === updatedAccountObj.accountId));
                if(workloadAccount){
                    if(updatedAccountObj.columnName == 'PG Notes' && updatedAccountObj.pgValue != workloadAccount.value){
                        workload.value = updatedAccountObj.pgValue;
                    }else if(updatedAccountObj.columnName == 'PG Next Step' && updatedAccountObj.pgValue != workloadAccount.value){
                        workload.value = updatedAccountObj.pgValue;
                    }
                }
            });
        }
        this.setAccountAndWorkloads();
    }

    clickHelper(event){
        this.workloadToPass = {};
        let accId = event.target.getAttribute('data-acc-id');
        let cellIndex = event.target.getAttribute('data-cell-index');
        const workloads = this.accountAndWorkloads.find(cell=> cell.key == accId).value;
        this.workloadToPass = workloads[cellIndex];
        this.hasEditAccountAccess = event.target.getAttribute('data-haseditaccess');
    }

    updateDivElementClass(divElement){
        if(divElement && this.columns.length==0 && this.screenWidth >=1250 && this.screenWidth< 1500){
            divElement.classList.add('table-container-noDataSmallerScreen')
            divElement.classList.remove('table-container-largeScreen')
            divElement.classList.remove('table-container-noDataLargeScreen')
            divElement.classList.remove('table-container-smallerScreen')
            divElement.classList.remove('table-container-smallerScreenWithColumnLenght')
            divElement.classList.remove('table-container-largeScreenWithColumnLenght')

        }else if(divElement && this.columns.length==0 && this.screenWidth >1500 ){
            divElement.classList.add('table-container-noDataLargeScreen')
            divElement.classList.remove('table-container-largeScreen')
            divElement.classList.remove('table-container-noDataSmallerScreen')
            divElement.classList.remove('table-container-smallerScreen')
            divElement.classList.remove('table-container-smallerScreenWithColumnLenght')
            divElement.classList.remove('table-container-largeScreenWithColumnLenght')

        }else if(divElement && this.columns.length!=0 && this.columns.length>0 && this.columns.length<=4 && this.screenWidth >=1250 && this.screenWidth< 1500 ){
            divElement.classList.add('table-container-smallerScreenWithColumnLenght')
            divElement.classList.remove('table-container-smallerScreen')
            divElement.classList.remove('table-container-noDataSmallerScreen')
            divElement.classList.remove('table-container-noDataLargeScreen')
            divElement.classList.remove('table-container-largeScreen')
            divElement.classList.remove('table-container-largeScreenWithColumnLenght')

        }else if(divElement && this.columns.length!=0 && this.screenWidth >=1250 && this.screenWidth< 1500 ){
            divElement.classList.add('table-container-smallerScreen')
            divElement.classList.remove('table-container-noDataSmallerScreen')
            divElement.classList.remove('table-container-noDataLargeScreen')
            divElement.classList.remove('table-container-largeScreen')
            divElement.classList.remove('table-container-smallerScreenWithColumnLenght')
            divElement.classList.remove('table-container-largeScreenWithColumnLenght')

        }else if(divElement && this.columns.length!=0 && this.columns.length>0 && this.columns.length<=4 && this.screenWidth >1500){
            divElement.classList.add('table-container-largeScreenWithColumnLenght')
            divElement.classList.remove('table-container-largeScreen')
            divElement.classList.remove('table-container-smallerScreen')
            divElement.classList.remove('table-container-noDataSmallerScreen')
            divElement.classList.remove('table-container-noDataLargeScreen')
            divElement.classList.remove('table-container-smallerScreenWithColumnLenght')
        }else if(divElement && this.columns.length!=0 && this.screenWidth >1500){
            divElement.classList.add('table-container-largeScreen')
            divElement.classList.remove('table-container-smallerScreen')
            divElement.classList.remove('table-container-noDataSmallerScreen')
            divElement.classList.remove('table-container-noDataLargeScreen')
            divElement.classList.remove('table-container-smallerScreenWithColumnLenght')
            divElement.classList.remove('table-container-largeScreenWithColumnLenght')
        }
    }

    handleSalesforceRedirect(event) {
        event.preventDefault();
        // const id = event.currentTarget.querySelector('img').dataset.id;
        const id = event.currentTarget.querySelector('.accountRedirect').dataset.id;
        const url = window.location.origin + `/${id}`;
        window.open(url, '_blank');
    }

    handleSentryAIRedirect(event){
        event.preventDefault();
        const id = event.currentTarget.querySelector('img').dataset.id;
        const url = `https://sentryai.rubrik.com/account/${id}`;
        window.open(url, '_blank');
    }

    redirectToTheRelatedClusters(event){
        event.preventDefault();
        this.clickedType = 'singleClick';
        let cellValue = event.target.dataset.value;
        let columnName = event.target.dataset.columnname;
        if(columnName == 'CDM Capacity Risk'){
            this.redirectUrl(event);
        }
        if(columnName == 'Critical Support Cases' && cellValue > 0){
            this.redirectToReport(event);
        }
        if(columnName == 'Next Renewal' && cellValue){
            this.redirectToReport(event);
        }
    }
    redirectToRBRCreation(event){
        event.preventDefault();
        this.clickedType = 'dblClick';
        let columnName = event.target.dataset.columnname;
        if(columnName == 'Next RBR'){
            this.redirectUrl(event);
        }
    }

    redirectUrl(event){
        let accId = event.target.dataset.accountid;
        let url = '';
        if(this.clickedType == 'dblClick'){
            url = window.location.origin + `/lightning/o/Health_Check__c/new?count=1&nooverride=1&useRecordTypeCheck=1&defaultFieldValues=Account__c=`+accId;
        }else if(this.clickedType == 'singleClick'){
            url = window.location.origin + `/lightning/r/Account/${accId}/related/Clusters__r/view`;
        }
        window.open(url, '_blank');
    }

    redirectToReport(event){
        let accountId = event.target.dataset.accountid;
        let columnname = event.target.dataset.columnname;
        const columnDetails = this.columns.find((column) => column.columnName === columnname);
        const reportUrlBase = columnDetails?.reportUrl;

        if (reportUrlBase) {
            let reportUrl = '/lightning/r/Report' + reportUrlBase + accountId;
            window.open(reportUrl, '_blank');
        }
    }

    @api handleFilteration(updatedValues){
        if(updatedValues.isChecked){
            const elementToAdd = this.dataAccounts.find(item => item.accountId === updatedValues.id);
            if (elementToAdd && !this.filteredDataAccounts.some(item => item.accountId === updatedValues.id)) {
                this.filteredDataAccounts.push(elementToAdd);
                if(this.unselectedAccountIds.has(updatedValues.id)){
                    this.unselectedAccountIds.delete(updatedValues.id);
                }
            }
        }else{
            this.filteredDataAccounts = this.filteredDataAccounts.filter(item => item.accountId !== updatedValues.id);
            this.unselectedAccountIds.add(updatedValues.id);
        }
		this.filteredDataAccounts = this.doSorting(this.sortedBy,this.sortedDirection, this.filteredDataAccounts,this.sortingDefinationType);
        this.paginationHelper();
        this.setAccountAndWorkloads();
  }

    @api resetAccountFilters(){
        this.filteredDataAccounts = [...this.dataAccounts];
        this.paginationHelper();
    }

    @api handleSelectAndClearAll(buttonClicked){
        if(buttonClicked === 'Select All'){
            this.filteredDataAccounts = [...this.dataAccounts];
        }else if(buttonClicked === 'Clear All'){
            this.filteredDataAccounts = [];
        }
        this.filteredDataAccounts = this.doSorting('accountName',this.sortedDirection, this.filteredDataAccounts,this.sortingDefinationType);
        this.paginationHelper();
        this.setAccountAndWorkloads();
    }

    @track workloadval ='';
    showModal(event) {
        const targetCell = event.target;
        const rect = targetCell.getBoundingClientRect();
        const y = rect.top + targetCell.offsetHeight - 10;
        const x = rect.left + targetCell.offsetWidth - 10;
        const top =  y + 135 > window.innerHeight ? y - 133 : y;
        const left = x + 200 > window.innerWidth ? x - 200 : x;
        this.modalStyleHover = `position: fixed; top: ${y+10}px; left: ${x+10}px; z-index:25`;

        let accId = event.target.getAttribute('data-acc-id');
        let cellIndex = event.target.getAttribute('data-cell-index');
        if(this.accountAndWorkloads.find(cell=> cell.key == accId) != undefined){
            const workloads = this.accountAndWorkloads.find(cell=> cell.key == accId).value;
            this.workloadval = event.target.getAttribute('data-val');
            if(!this.showWorkloadModal && this.workloadval != null && workloads[cellIndex].columnName != '' && (workloads[cellIndex].columnName == 'PG Notes' || workloads[cellIndex].columnName == 'PG Next Step')){
                this.showHoverModal = true;
            }
        }
    }

    hideModal(event) {
        this.showHoverModal = false;
    }

    setWorkloadProperties(accWorkloadsWrapper){
        accWorkloadsWrapper.forEach(element => {
            element.workloadCells.forEach(workloadElement => {
                if (workloadElement?.value != null) {
                    workloadElement.backgroundColour = this.backgroundColors[workloadElement.value] || '';
                }
                if (workloadElement?.columnAlignment) {
                    const alignmentClass = this.alignmentMap[workloadElement.columnAlignment] || this.alignmentMap['Center'];
                    workloadElement.cellAlignmentClass = `textColor workload-cell textalign truncated-cell ${alignmentClass}`;
                }
                if(workloadElement.columnName === 'CDM Capacity Risk'){
                    workloadElement.backgroundColour = workloadElement?.value ? 'background-color:#980000' : '';
                }
                if(workloadElement.columnName === 'Last RBR'){
                    if((workloadElement?.value == null || workloadElement?.value == "") && workloadElement?.accountType == 'Prospect'){
                        workloadElement.backgroundColour = '';
                    }else if((workloadElement?.value == null || workloadElement?.value == "") && workloadElement?.accountType == 'Customer'){
                        workloadElement.backgroundColour = 'background-color:#980000';
                    }else if(workloadElement?.value != null && workloadElement?.value != ""){
                        let lastRbrDate = this.convertStringToDate(workloadElement);
                        let referenceDate = new Date();
                        let monthsPrior12 = new Date(referenceDate);
                        monthsPrior12.setMonth(monthsPrior12.getMonth() - 12);
                        let monthsPrior6 = new Date(referenceDate);
                        monthsPrior6.setMonth(monthsPrior6.getMonth() - 6);
                        
                        if(lastRbrDate < monthsPrior12){
                            workloadElement.backgroundColour = 'background-color:#980000';
                        }else if(lastRbrDate > monthsPrior12 && lastRbrDate < monthsPrior6){
                            workloadElement.backgroundColour = 'background-color:#FFBE2E';
                        }else if(lastRbrDate > monthsPrior6){
                            workloadElement.backgroundColour = 'background-color:#005535';
                        }else{
                            workloadElement.backgroundColour = '';
                        }
                    }
                }
                if(workloadElement.columnName === 'Critical Support Cases' && workloadElement?.value > 0){
                    workloadElement.backgroundColour = 'background-color:#980000';
                }
                if((workloadElement?.manualObjCapacity && workloadElement?.manualObjCapacity != 0) 
                    || (workloadElement?.manualObjCount && workloadElement?.manualObjCount != 0 )
                    || (workloadElement?.manualIncumbent && workloadElement?.manualIncumbent != null) ){
                        workloadElement.value = workloadElement.value ? workloadElement.value + '*' : '*';
                }
                //MKT26-1106 : override backgroundColour if applicable
                if(workloadElement?.licenseOverride){
                        workloadElement.backgroundColour = 'background-color:' + workloadElement?.licenseOverride;
                }
            });
        });
        return accWorkloadsWrapper;
    }
    setPropertiesOfSumOfWon(accWorkloadsWrapper, columnDetailsWrapper){
        let isAccountInformationSelected = false;
        columnDetailsWrapper.forEach(column => {
            if(column.columnCategory === 'Account Information'){
                isAccountInformationSelected = true;
            }
        })
        if(isAccountInformationSelected){
            let dataAccounts = this.doSorting('Sum of Won ACV','asc', accWorkloadsWrapper,'Number');
            dataAccounts = this.applyGradientToCell(dataAccounts);
            return dataAccounts;
        }
        return accWorkloadsWrapper;
    }

    // Function to apply the gradient to the table cells
    applyGradientToCell(cells) {
        let workloadCellMin = cells[0].workloadCells
        let workloadCellMax = cells[cells.length-1].workloadCells
        const indexOfMin = workloadCellMin.findIndex(cell => cell.columnName === "Sum of Won ACV");
        const indexOfMax = workloadCellMax.findIndex(cell => cell.columnName === "Sum of Won ACV");
        const minValue = parseInt(workloadCellMin[indexOfMin].value?.toString().replace(/[$,]/g, ""));
        const maxValue = parseInt(workloadCellMax[indexOfMax].value?.toString().replace(/[$,]/g, ""));
        cells.forEach(element => {
            element.workloadCells.forEach(workloadElement => {
                if (workloadElement?.columnName === 'Sum of Won ACV') {
                    const value = parseInt(workloadElement.value?.toString().replace(/[$,]/g, ""));
                    const color = this.interpolateColor(value, minValue, maxValue);
                    workloadElement.backgroundColour = workloadElement?.value && workloadElement?.value != '$0' ? color:'';
                }
            });
        });
        return cells;
    }
    // Function to interpolate between two colors based on the value
    interpolateColor(value, minValue, maxValue) {
        const ratio = (value - minValue) / (maxValue - minValue);
        const interpolatedColor = this.lowColor.map((low, i) =>
            Math.round(low + ratio * (this.highColor[i] - low))
        );
        return `background-color:rgb(${interpolatedColor.join(',')});color: white;`;
    }

    setAccountAndWorkloads(){
        this.accountAndWorkloads = [];
        if(this.filteredDataAccounts != null){
            this.filteredDataAccounts.forEach(element => {
                let eleAcc = {};
                let workloads = [];
                element.workloadCells.forEach(workloadElement => {
                    workloads.push(workloadElement);
                });
                eleAcc.key = element.accountId;
                eleAcc.value = workloads;
                this.accountAndWorkloads.push(eleAcc);
            });
        }
    }

    //pagination methods
    previousHandler() {
        this.pageNumber = this.pageNumber - 1;
        this.paginationHelper();
        this.template.querySelector('.table-scrollable').scrollTop=0;
    }
    nextHandler() {
        this.pageNumber = this.pageNumber + 1;
        this.paginationHelper();
        this.template.querySelector('.table-scrollable').scrollTop=0;
    }

    paginationHelper() {
        this.totalRecords = this.filteredDataAccounts ? this.filteredDataAccounts.length : 0;
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
        this.pageNumber = Math.max(1, Math.min(this.pageNumber, this.totalPages));
        this.startingRecord = (this.pageNumber - 1) * this.pageSize;
        this.endingRecord = Math.min(this.pageNumber * this.pageSize, this.totalRecords);
       let accountIds = [];
        let dataRecords = this.filteredDataAccounts.slice(this.startingRecord, this.endingRecord);
        dataRecords.forEach(item =>{
            accountIds.push(item.accountId);
        })
        getEditAccessOnAccounts({accountIdList : accountIds})
        .then(result =>{
            const accountIdAccessMap = new Map();
            result.forEach(item =>{
                accountIdAccessMap.set(item, true);
            })
            dataRecords.forEach( element=>{
                if(accountIdAccessMap.has(element.accountId)){
                    element.hasEditAccess = true;
                }
            })
        })
        .catch(error =>{
            console.log('error-',error);
        })
        this.currentPageData = dataRecords;
    }

    handleSortClick(event) {
        const clickedColumn = event.target.name;
        if (this.prevState === clickedColumn) {
            this.maintainSortState = !this.maintainSortState;
        } else {
            this.maintainSortState = true;
            this.prevState = clickedColumn;
        }
        this.sortedDirection = this.maintainSortState ? 'asc' : 'desc';
        this.sortedBy = clickedColumn;
        let sortingDefinition = this.columns.find(column => column.label == clickedColumn)?.sortingTypeDefinition;
        this.sortingDefinationType = sortingDefinition;
        this.manageSortingIcon(sortingDefinition);
        this.paginationHelper();
        this.template.querySelector('.table-scrollable').scrollTop=0;
    }

    manageSortingIcon(sortingDefinition){
        if (this.sortedBy === 'Account' || this.sortedBy === 'accountName') {
            this.fixedColumns.forEach(element => {
                this.sortedBy = 'Account'
                element.iconName = (element.title === this.sortedBy)
                    ? (this.sortedDirection === 'asc' ? 'utility:arrowup' : 'utility:arrowdown')
                    : 'utility:sort';
            });
            this.columns.forEach(element => {
                element.iconName = 'utility:sort';
            });
            this.sortedBy = 'accountName';
            this.filteredDataAccounts = this.doSorting('accountName',this.sortedDirection, this.filteredDataAccounts, sortingDefinition);
        } else {
            this.fixedColumns.forEach(element => {
                element.iconName = 'utility:sort';
            });
            this.columns.forEach(element => {
                element.iconName = (element.label === this.sortedBy)
                    ? (this.sortedDirection === 'asc' ? 'utility:arrowup' : 'utility:arrowdown')
                    : 'utility:sort';
            });
            this.filteredDataAccounts = this.doSorting(this.sortedBy,this.sortedDirection, this.filteredDataAccounts, sortingDefinition);
        }
    }

    //Sorting methods
    doSorting(sortBy, sortDirection, dataToSort, sortingDefinition) {
        let parseData = JSON.parse(JSON.stringify(dataToSort));
        let isReverse = sortDirection === 'asc' ? 1 : -1;

        let keyValue = (a) => {
            if(sortBy === 'accountName'){
                return a[sortBy];
            }else{
                let workloadCell = a.workloadCells.find(cell => cell.columnName === sortBy);
                if(sortingDefinition == 'Date'){
                    return this.convertStringToDate(workloadCell);
                }else if(sortingDefinition == 'Number'){
                    return this.convertStringToInteger(workloadCell);
                }else if(sortingDefinition == 'Workload'){
                    return this.convertWorkloadValue(workloadCell);
                }else{
                    return workloadCell?.value;
                }
            }
        };

        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : '';
            y = keyValue(y) ? keyValue(y) : '';
            return isReverse * ((x > y) - (y > x));
        });
        return JSON.parse(JSON.stringify(parseData));
    }

    convertStringToInteger(workloadCell){
        let newWorkloadCell;
        if (workloadCell?.value?.includes('$')) {
            newWorkloadCell = workloadCell.value.replace('$', '');  // Remove $ and update value
        }else{
            newWorkloadCell = workloadCell?.value;
        }
        return newWorkloadCell ? parseFloat(parseFloat(newWorkloadCell?.replace(/,/g, ''))?.toFixed(2)) : 0;
    }

    convertStringToDate(workloadCell) {
        if (!workloadCell || !workloadCell.value) return new Date(0);
        let date = new Date(workloadCell.value);
        return isNaN(date.getTime()) ? new Date(0) : date;
    }

    convertWorkloadValue(workloadCell){
        return workloadCell?.value ? this.workloadMap[workloadCell.value] || 5 : 6;
    }

    showToastNotificationMessage(erroMessage){
        if(erroMessage.includes('Too many query rows') ||
             erroMessage.includes('Apex heap size too large')||
             erroMessage.includes('Apex CPU time limit exceeded')
        ){
            const event = new ShowToastEvent({
                title: 'Error in Filtering',
                message: 'Too many accounts match the filter criteria. Please refine your filters or reduce the column family for more accurate results.',
                variant: 'error',
                mode: 'sticky'
            });
            this.dispatchEvent(event);
        }
    }
    
    @track updatedFilterOPtions = [];
    toggleFilter(event){
        let columnName = event.target.name;
        
        this.columns.forEach(item =>{
            
            if(columnName == item.label){
                item.showHeaderFilter =  true ;
            }else{
                item.showHeaderFilter = false;
            }
        });
        event.stopPropagation();
    }

    getFilterOptionsdata(columnCatg, columnName){
        if(columnCatg == 'Product Editions'){
            return [{value : 'EPE', label : 'EPE', isChecked : false, columnName : columnName, columnCategory : columnCatg}, 
                    {value : 'EE', label : 'EE', isChecked : false, columnName : columnName, columnCategory : columnCatg}, 
                    {value : 'BE', label : 'BE', isChecked : false, columnName : columnName, columnCategory : columnCatg}, 
                    {value : 'FE', label : 'FE', isChecked : false, columnName : columnName, columnCategory : columnCatg},
                    {value : '', label : 'Blank', isChecked : false, columnName : columnName, columnCategory : columnCatg}];
        }else{
            return [{value : 'Target', label : 'Target', isChecked : false, columnName : columnName, columnCategory : columnCatg},
                    {value : 'Protected', label : 'Protected', isChecked : false, columnName : columnName, columnCategory : columnCatg}, 
                    {value : 'Not Protected', label : 'Not Protected', isChecked : false, columnName : columnName, columnCategory : columnCatg}, 
                    {value : 'NA', label : 'NA', isChecked : false, columnName : columnName, columnCategory : columnCatg}, 
                    {value : '', label : 'Blank', isChecked : false, columnName : columnName, columnCategory : columnCatg}];
        }
    }

    handleDocumentClick = () => {
        this.columns.forEach(option => {
            option.showHeaderFilter = false;
        });
    }
    handleChildClick(event) {
        event.stopPropagation();
    }

    @track filteredData = [];
    handleFilterSelection(event){
        let mapofoptions = event.detail.columnNameToOptions;
       
        this.filteredData = [];
         this.filteredAccountDetails.forEach(acc =>{
            let count1 =0
            let count2 =0;
            let count3 =0;
            let count4 =0;
            acc.workloadCells.forEach(col =>{
                const columnHeaderFilter = mapofoptions.get(col.columnName);
                for(const option of columnHeaderFilter){
                    if(option.isChecked && col.columnFilter == 'Product Editions'){
                        count1++;
                        break;
                    }
                    if(option.isChecked && col.columnFilter != 'Product Editions'){
                        count2++;
                        break;
                    }
                }
                
                for(const option of columnHeaderFilter){
                    if(option.isChecked){
                        if(col.columnFilter == 'Product Editions' && col.columnName == option.columnName  && col.value != undefined && ((option.label != 'Blank' && col.value.includes(option.value)) || col.value == option.value)){
                            count3++;
                            break;
                        }
                        if(col.columnFilter != 'Product Editions' && col.columnName == option.columnName  && col.value != undefined && (col.value == option.value || col.value == option.value+'*')){
                            count4++;
                            break;
                        }
                    }
                }
                
            });
            if(count1 + count2 == count3 + count4){
                this.filteredData.push(acc);
            }
        });
        this.columns.forEach(item =>{
            if(item.columnName == event.detail.columnName){
                item.headerFilterOptions = mapofoptions.get(event.detail.columnName); 
            }
        });

        let filterData = event.detail.filterOptions;
        let columnName = filterData.length ? filterData[0].columnName : null;

        if (columnName) {
            let isAnyChecked = filterData.some(option => option.isChecked);
            const sortingButton = this.template.querySelector(`.columnHeaders[data-label="${columnName}"]`);
            
            if (sortingButton) {
                sortingButton.style.backgroundColor = isAnyChecked ? '#7725BE' : 'transparent';
            }
        }
        this.filteredDataAccounts = this.filteredData;
        this.setAccountAndWorkloads();
        this.paginationHelper();
       
    }
}