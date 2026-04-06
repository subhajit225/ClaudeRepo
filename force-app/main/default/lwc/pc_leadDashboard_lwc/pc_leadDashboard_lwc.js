import { LightningElement, track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';
import getData from '@salesforce/apex/PC_PortalNavigationApexController.getLeadDashboardData';
import basepath from '@salesforce/community/basePath';
export default class Pc_leadDashboard_lwc extends LightningElement {

    @track listData = [];
    sortDirection = 'asc';
    sortField;
    showSpinner = false;
    showMeetingWidget = false;
    leadId;
    expDate;

    //PRIT24-422
    selectedObject;
    selectedRecordId;

    //ICONS utility:arrowdown, utility:arrowup
    nameIcon="";
    companyIcon="";
    emailIcon="";
    statusIcon="";

    //PAGINATION
    pageSize = 10;
    pageNumber;
    totalRecords = 0;
    totalPages = 0;
    startIndex = 0;
    endIndex = 0;
    @track pageRecords = [];
    isPrev = true;
    isNext = true;
    basepath = basepath;

    //EXPORT
    disableExport = false;

    //PRIT24-532
    searchText = '';

    connectedCallback() {
        Promise.all([
        loadStyle( this, PartnerCommunityResource + '/PartnerCommunityResource/Stylesheets/PartnerCommunityCSS.css')
        ]).then(() => {
            //console.log("File path-->"+ PartnerCommunityResource);
        })
        .catch(error => {
            console.log( error.body.message );
        });
        this.fetchData(); 
    }

    fetchData(){
        getData({searchText : this.searchText})
        .then(result=>{
            this.showSpinner = true;
            console.log('result->'+JSON.stringify(result));
            this.totalRecords = result.leadList.length + result.contactList.length;
            this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
            if(this.totalRecords == 0){
                this.disableExport = true;
            }
            this.listData = [];
            if(!this.pageNumber){
                this.pageNumber = 1;
            }
            this.endIndex = this.pageNumber * this.pageSize;
            if(result.leadList.length > 0){
                result.leadList.forEach(lead => {
                    let actionsList = [];
                    let showActions = true;
                    let dealRegId = null;
                    let dashStatus = null;
                    let highlightRow; /* PRIT24-781 */
                    if(lead.Status == 'Open'){
                        if(lead.Deal_Registrations__r != undefined && lead.Deal_Registrations__r.length > 0){
                            dashStatus = 'Deal Registration Submitted';
                            actionsList.push({name : 'View Deal Registration', value : 'View Deal Registration'});
                            dealRegId = lead.Deal_Registrations__r[0].Id;
                        }
                        else{
                            actionsList.push({name : 'Working', value : 'Working'});
                            actionsList.push({name : 'Contacted / No Interest', value : 'Contacted/No Interest'});
                            actionsList.push({name : 'No Contact Information', value : 'No Contact Information'});
                            actionsList.push({name : 'Book a Meeting', value : 'Book a Meeting'});
                            actionsList.push({name: 'Register a Deal', value : 'Register a Deal'});
                        }
                        
                    }else if(lead.Status == 'Working'){
                        actionsList.push({name : 'Contacted / No Interest', value : 'Contacted/No Interest'});
                        actionsList.push({name : 'No Contact Information', value : 'No Contact Information'});
                        actionsList.push({name : 'Book a Meeting', value : 'Book a Meeting'});
                        actionsList.push({name: 'Register a Deal', value : 'Register a Deal'});
                    }else if(lead.Status == 'Meeting Set'){
                        if(lead.Events != undefined && lead.Events.length != 0){
                            if(lead.Events[0].Post_Meeting_Status__c == null){
                                actionsList.push({name : 'Log Meeting Outcome', value : 'Log Meeting Outcome'});
                                actionsList.push({name : 'Reschedule Meeting', value : 'Reschedule Meeting'});
                            }else if(lead.Events[0].Post_Meeting_Status__c = 'Opportunity Sourced' && lead.Deal_Registrations__r != undefined && lead.Deal_Registrations__r.length > 0){
                                dashStatus = 'Deal Registration Submitted';
                                actionsList.push({name : 'View Deal Registration', value : 'View Deal Registration'});
                                dealRegId = lead.Deal_Registrations__r[0].Id;
                            }else if(lead.Events[0].Post_Meeting_Status__c != null && lead.Deal_Registrations__r == undefined){
                                actionsList.push({name : 'Register a Deal', value : 'Register a Deal'});
                            }
                        }else{
                            if(lead.Deal_Registrations__r != undefined && lead.Deal_Registrations__r.length > 0){
                                actionsList.push({name : 'View Deal Registration', value : 'View Deal Registration'});
                                dealRegId = lead.Deal_Registrations__r[0].Id;
                            }
                        }
                    }
                    if(actionsList.length == 0){
                        showActions = false;
                    }
                    if(dashStatus == null){
                        dashStatus = lead.Status;
                    }
                    /* PRIT24-781 : START */
                    if(lead.Lead_Source_Most_Recent_Details__c != null && lead.Lead_Source_Most_Recent_Details__c.toLowerCase().startsWith('priority')){
                        highlightRow= 'highlight-row';
                    }
                    /* PRIT24-781 : END */
                    this.listData.push({id : lead.Id,
                                        objName : 'Lead',
                                        name: lead.Name, 
                                        company: lead.Company, 
                                        email : lead.Email, 
                                        phone : lead.Phone, 
                                        title : lead.Title, 
                                        city : lead.City,
                                        state : lead.StateCode,
                                        country : lead.CountryCode,
                                        status : dashStatus,
                                        createdDate : lead.CreatedDate,
                                        lastActivityDate:  lead.LastActivityDate,
                                        leadSourceMostRecentDetails: lead.Lead_Source_Most_Recent_Details__c,
                                        leadSourceMostRecent: lead.Lead_Source_Most_Recent__c,
                                        expDate : lead.Lead_Share_Program_Expiration_Date__c,
                                        dealRegId : dealRegId,
                                        actionsList : actionsList,
                                        showActions : showActions,
                                        highlightRow: highlightRow != null ? highlightRow : null
                                    });
                });
            }
            if(result.contactList.length > 0){
                result.contactList.forEach(contact=>{
                    let actionsList = [];
                    let showActions = true;
                    let dealRegId = null;
                    let dashStatus = null;
                    let highlightRow; /* PRIT24-781 */
                    if(contact.Contact_Status__c == 'Open'){
                        if(contact.Deal_Registrations__r != undefined && contact.Deal_Registrations__r.length > 0){
                            dashStatus = 'Deal Registration Submitted';
                            actionsList.push({name : 'View Deal Registration', value : 'View Deal Registration'});
                            dealRegId = contact.Deal_Registrations1__r[0].Id;
                        }
                        else{
                            actionsList.push({name : 'Working', value : 'Working'});
                            actionsList.push({name : 'Contacted/No Interest', value : 'Contacted/No Interest'});
                            actionsList.push({name : 'No Contact Information', value : 'No Contact Information'});
                            actionsList.push({name : 'Book a Meeting', value : 'Book a Meeting'});
                            actionsList.push({name: 'Register a Deal', value : 'Register a Deal'});
                        }
                    }else if(contact.Contact_Status__c == 'Working'){
                        actionsList.push({name : 'Contacted/No Interest', value : 'Contacted/No Interest'});
                        actionsList.push({name : 'No Contact Information', value : 'No Contact Information'});
                        actionsList.push({name : 'Book a Meeting', value : 'Book a Meeting'});
                        actionsList.push({name: 'Register a Deal', value : 'Register a Deal'});
                    }else if(contact.Contact_Status__c == 'Meeting Set'){
                        if(contact.Events != undefined && contact.Events.length > 0){
                            if(contact.Events[0].Post_Meeting_Status__c == null){
                                actionsList.push({name : 'Log Meeting Outcome', value : 'Log Meeting Outcome'});
                                actionsList.push({name : 'Reschedule Meeting', value : 'Reschedule Meeting'});
                            }else if(contact.Events[0].Post_Meeting_Status__c = 'Opportunity Sourced' && contact.Deal_Registrations1__r != undefined && contact.Deal_Registrations1__r.length > 0){
                                dashStatus = 'Deal Registration Submitted';
                                actionsList.push({name : 'View Deal Registration', value : 'View Deal Registration'});
                                dealRegId = contact.Deal_Registrations1__r[0].Id;
                            }else if(contact.Events[0].Post_Meeting_Status__c != null && contact.Deal_Registrations1__r == undefined){
                                actionsList.push({name : 'Register a Deal', value : 'Register a Deal'});
                            }
                        }else{
                            if(contact.Deal_Registrations1__r != undefined && contact.Deal_Registrations1__r.length > 0){
                                actionsList.push({name : 'View Deal Registration', value : 'View Deal Registration'});
                                dealRegId = contact.Deal_Registrations1__r[0].Id;
                            }
                        }
                    }
                    if(actionsList.length == 0){
                        showActions = false;
                    }
                    if(dashStatus == null){
                        dashStatus = contact.Contact_Status__c;
                    }
                    /* PRIT24-781 : START */
                    if(contact.Lead_Source_Most_Recent_Details__c != null && contact.Lead_Source_Most_Recent_Details__c.toLowerCase().startsWith('priority')){
                        highlightRow= 'highlight-row';
                    }
                    /* PRIT24-781 : END */
                    this.listData.push({id : contact.Id,
                                        objName : 'Contact',
                                        name: contact.Name, 
                                        company: contact.Account.Name, 
                                        email : contact.Email, 
                                        phone : contact.Phone, 
                                        title : contact.Title, 
                                        city : contact.MailingCity,
                                        state : contact.MailingStateCode,
                                        country : contact.MailingCountryCode,
                                        status : dashStatus,
                                        createdDate : contact.CreatedDate,
                                        lastActivityDate : contact.LastActivityDate,
                                        leadSourceMostRecent : contact.Lead_Source_Most_Recent__c,
                                        leadSourceMostRecentDetails : contact.Lead_Source_Most_Recent_Details__c,
                                        expDate : contact.Lead_Share_Program_Expiration_Date__c,
                                        dealRegId : dealRegId,
                                        actionsList : actionsList,
                                        showActions : showActions,
                                        highlightRow: highlightRow != null ? highlightRow : null
                                    });
                });
            }
            this.highlightPriorityOnTop();
            this.handlePagination();
            this.showSpinner = false;
        })
        .catch(error=>{
            console.log('error24-> '+error);
            this.showSpinner = false;
        })
    }

    highlightPriorityOnTop(){
        this.listData.sort((a, b) => {
            const first = a.leadSourceMostRecentDetails != null?a.leadSourceMostRecentDetails.toLowerCase():'';
            const second = b.leadSourceMostRecentDetails != null?b.leadSourceMostRecentDetails.toLowerCase():'';
            if (first < second) { return 1;}
            if (first > second) { return -1;}
            return 0;
        });
    }

    handleSearchText(event){
        this.findRequiredData(event.target.value);
    }

    handleReset(){
        this.findRequiredData('');
    }

    findRequiredData(str){
        this.searchText = str;
        this.showSpinner = true;
        this.listData = [];
        this.pageNumber = 1;
        this.startIndex = 0;
        this.fetchData();
    }

    handleSort(event){
        this.showSpinner = true;
        let sortByField = event.target.name;

        if(this.sortField == sortByField && this.sortDirection == 'asc'){
        
            this.listData.sort((a, b) => {
                const first = a[sortByField].toUpperCase();
                const second = b[sortByField].toUpperCase();
                if (first < second) {
                    return -1;
                }
                if (first > second) {
                    return 1;
                }
                return 0;
            });

            this.sortDirection = 'desc';

        }else if(this.sortDirection = 'desc' && this.sortField == sortByField){
            this.sortDirection = 'asc';
            this.listData.sort((a, b) => {
                const first = a[sortByField].toUpperCase();
                const second = b[sortByField].toUpperCase();
                if (second < first) {
                    return -1;
                }
                if (second > first) {
                    return 1;
                }
                return 0;
            });
        }else{
            this.listData.sort((a, b) => {
                const first = a[sortByField].toUpperCase();
                const second = b[sortByField].toUpperCase();
                if (first < second) {
                    return -1;
                }
                if (first > second) {
                    return 1;
                }
                return 0;
            });
            this.sortDirection = 'desc';
        }
        
        this.sortField = sortByField;
        this.showSpinner = false;
        this.setIcons(sortByField);
        this.handlePagination();
        
    }

    setIcons(sortByField){
        if(sortByField == 'name'){
            if(this.sortDirection == 'desc'){
                this.nameIcon = 'utility:arrowup';
            }else{
                this.nameIcon = 'utility:arrowdown';
            }
            this.companyIcon = '';
            this.emailIcon ='';
            this.statusIcon='';
        }
        else if(sortByField == 'company'){
            if(this.sortDirection == 'desc'){
                this.companyIcon = 'utility:arrowup';
            }else{
                this.companyIcon = 'utility:arrowdown';
            }
            this.nameIcon = '';
            this.emailIcon ='';
            this.statusIcon='';
        }else if(sortByField == 'email'){
            if(this.sortDirection == 'desc'){
                this.emailIcon = 'utility:arrowup';
            }else{
                this.emailIcon = 'utility:arrowdown';
            }
            this.nameIcon = '';
            this.companyIcon ='';
            this.statusIcon='';
        }else if(sortByField == 'status'){
            if(this.sortDirection == 'desc'){
                this.statusIcon = 'utility:arrowup';
            }else{
                this.statusIcon = 'utility:arrowdown';
            }
            this.nameIcon = '';
            this.companyIcon ='';
            this.emailIcon='';
        }
    }


    handleAction(event){
        var selectedAction = event.detail.value;
        const recordId = event.currentTarget.dataset.id;
        const objName = event.currentTarget.dataset.objname;
        const dealRegId = event.currentTarget.dataset.dealregid;
        const expDate = event.currentTarget.dataset.expdate;
        this.selectedObject = event.currentTarget.dataset.objname;
        this.selectedRecordId = event.currentTarget.dataset.id;

        if(selectedAction == 'Register a Deal'){
            let url = this.basepath + '/dealregterms' + '?objectId='+recordId+'&objectName='+objName;
            window.open(url,'_self');
        }else if(selectedAction == 'Working' || selectedAction == 'Contacted/No Interest' || selectedAction =='No Contact Information'){
            this.updateRecordStatus(recordId, selectedAction);
        }else if(selectedAction == 'Book a Meeting'||selectedAction == 'Reschedule Meeting'||selectedAction == 'Log Meeting Outcome'){
            this.showMeetingWidget = true;
            this.leadId = recordId;
            this.expDate = expDate;
            this.meetingAction = selectedAction;
        }else if(selectedAction == 'View Deal Registration'){
            let url = this.basepath + '/dealregdetail?recordId=' + dealRegId;
            window.open(url,'_self');
        }

    }

    updateRecordStatus(recId, selAction){
        this.showSpinner = true;
        let strRejectReason;
        let strStatus;
        const fields = {};
        fields['Id'] = recId;

        if(selAction == 'Working'){
            strStatus = selAction;
        }else if(selAction == 'Contacted/No Interest'){
            strRejectReason = selAction;
            strStatus = 'Nurture';
        }else if(selAction == 'No Contact Information'){
            strRejectReason = selAction;
            strStatus = 'Non-Qualified';
        }

        if(recId.slice(0, 3) == '003'){
            fields['Contact_Status__c'] = strStatus;
            if(strRejectReason){
                fields['ContactRejectReason__c'] = strRejectReason;
            }
        }else if(recId.slice(0, 3) == '00Q'){
            fields['Status'] = strStatus;
            if(strRejectReason){
                fields['Lead_Rejection_Reason__c'] = strRejectReason;
            }
        }
        
        const recordInput = {fields};
        updateRecord(recordInput)
            
            .then(() => {
                this.showToast('Success!!', 'Record status changed!!', 'success', 'dismissable');
                this.refreshData();
            })
            .catch(error => {
                this.showSpinner = false;
                this.showToast('Error!!', error.body.message, 'error', 'dismissable');
                console.log('error-> '+error);
                console.log('error-> '+JSON.stringify(error));
            });
    }


    resetMeetingWidget(){
        this.showMeetingWidget = false;
    }

    handleNext(){
        this.pageNumber = this.pageNumber+1;
        this.startIndex = this.endIndex;
        this.endIndex = this.pageNumber * this.pageSize;
        this.handlePagination();
    }

    handlePrev(){
        this.pageNumber = this.pageNumber-1;
        this.startIndex = this.startIndex - this.pageSize;
        this.endIndex = this.pageNumber * this.pageSize; 
        this.handlePagination();
    }

    handlePagination(){
        let allRecords = this.listData;
        this.pageRecords = allRecords.slice(this.startIndex, this.endIndex);
        this.handlepaginationButtons();
    }

    handlepaginationButtons(){
        if(this.startIndex == 0){
            this.isPrev = true;
        }else{
            this.isPrev = false;
        }

        if(this.endIndex >= this.listData.length){
            this.isNext = true;
        }else{
            this.isNext = false;
        }
    }

    handleExportClick(){
        let rowEnd = '\n';
        let csvString = '';
        
        let rowData = new Set();

        let recordToExport = this.listData;
        recordToExport.forEach(function (rec) {
            Object.keys(rec).forEach(function(key) {
                rowData.add(key);
            });
        });

        rowData = Array.from(rowData);

        csvString += rowData.join(',');
        csvString += rowEnd;

        for(let i=0; i < recordToExport.length; i++){
            let colValue = 0;
            for(let key in rowData) {
                if(rowData.hasOwnProperty(key)) {
                    let rowKey = rowData[key];
                    if(colValue > 0){
                        csvString += ',';
                    }
                    let value = recordToExport[i][rowKey] === undefined ? '' : recordToExport[i][rowKey];
                    csvString += '"'+ value +'"';
                    colValue++;
                }
            }
            csvString += rowEnd;
        }
        let downloadElement = document.createElement('a');

        downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csvString);
        downloadElement.target = '_self';
        downloadElement.download = 'Lead Dashboard.csv';
        document.body.appendChild(downloadElement);
        downloadElement.click();
    }

    showToast(title, message, variant, mode) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(event);
    }

    refreshData(){
        console.log('refresh event');
        this.listData = this.pageRecords = [];
        this.fetchData();
    }

    navigateToDealRegTerms(){
        let url = this.basepath + '/dealregterms' + '?objectId='+this.selectedRecordId+'&objectName='+this.selectedObject;
        window.open(url,'_self');
    }

}