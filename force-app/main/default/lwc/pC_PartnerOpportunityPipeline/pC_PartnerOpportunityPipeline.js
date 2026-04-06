import { LightningElement,track,wire } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { NavigationMixin } from "lightning/navigation";
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';
import getPartnerOpportunityList from '@salesforce/apex/PC_PartnerOppPipelineApexController.getPartnerOppPipeline';
import getFiscalYear from '@salesforce/apex/PC_PortalNavigationApexController.getFiscalYear';
import getAccountHierarchy from '@salesforce/apex/PC_PortalNavigationApexController.getAccountHierarchy';
import currentUserId from '@salesforce/user/Id';

export default class PC_PartnerOpportunityPipeline extends NavigationMixin(LightningElement){
    @track columns;
    @track error;
    @track oppList = [];
    @track currUserID = currentUserId;
    @track startDate = '';
    @track endDate = '';
    @track startDateMaster = '';
    @track endDateMaster = '';
    @track accountSearch = '';
    disableFilter = true;
    disableExport = true;
    disableReset = true;
    loadSpinner = false;
    @track fiscalList;
    @track fiscalYearOptions = [];
    @track currentFiscalYear = '';
    @track fiscalYear = '';
    @track accountIds = [];
    @track accountIdsMaster = [];
    buttonNavigateURL = 'incentives';
    @track toggleValue = false;
    showSPIFFButton = true;
    //PRIT26-83
    //SPIFF_Column = { label: 'SPIFF Eligible', fieldName: 'SPIFF_Eligible', type: 'boolean', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column'} };
    @track dealInitiatedType = '';

    connectedCallback(){
        this.loadSpinner = true;
        Promise.all([loadStyle( this, PartnerCommunityResource + '/PartnerCommunityResource/Stylesheets/PartnerCommunityCSS.css')])
        .then(() => {
            console.log("File path-->"+ PartnerCommunityResource);
        })
        .catch(error => {
            console.log( error.body.message );
        });

        let today = new Date();
        let currentfiscalyear = '';
        if(today.getMonth() >= 1){
            currentfiscalyear = today.getFullYear() + 1;
        }else{
            currentfiscalyear = today.getFullYear();
        }
        this.fiscalYear = currentfiscalyear;
        this.currentFiscalYear = currentfiscalyear;
        getFiscalYear()
        .then(result=>{
            this.fiscalList = result;
            let options = [];
            for(let i = 0; i < result.length; i++){
                options.push({label : result[i].Name, value : result[i].Name});
                if(currentfiscalyear == result[i].Name)
                {
                    this.startDate = result[i].StartDate;
                    this.endDate = result[i].EndDate;
                    this.startDateMaster = result[i].StartDate;
                    this.endDateMaster = result[i].EndDate;
                }
            }
            this.fiscalYearOptions = options;
            console.log('options->'+JSON.stringify(this.fiscalYearOptions));

            this.getAccountHierarchy();
        })
        .catch(error=>{
            console.log('error->'+JSON.stringify(error));
        });
    }

    getAccountHierarchy(){
        getAccountHierarchy()
        .then(result=>{
            console.log('result->'+JSON.stringify(result));
            if(result.accList != undefined && result.accList.length > 0){
                let accIds = [];
                for(let i = 0; i < result.accList.length; i++){
                    accIds.push(result.accList[i].Id);
                }
                this.accountIds = accIds;
                this.accountIdsMaster = accIds;
            }else{
                this.accountIds.push(result.userRec.Contact.AccountId);
                this.accountIdsMaster.push(result.userRec.Contact.AccountId);
            }
            this.fetchData();
        })
        .catch(error=>{
            console.log('error Acc hierarchy method->'+JSON.stringify(error));
        });
    }

    fetchData(){
        this.loadSpinner = true;
        let dealInitiatedType = [];
        if(this.dealInitiatedType != '' && this.dealInitiatedType != null){
            dealInitiatedType.push(this.dealInitiatedType);
            if(this.dealInitiatedType == 'Partner Sourced New Logo (PSNL)'){
                dealInitiatedType.push('Partner Initiated Deal');
            }
            else if(this.dealInitiatedType == 'Partner Sourced Expand'){
                dealInitiatedType.push('Joint Initiated Deal');
            }else{
                dealInitiatedType.push('Rubrik Initiated Deal');
            }
        }else{
            dealInitiatedType = [];
        }
        getPartnerOpportunityList({ partnerAccountId: this.currUserID, startDate : this.startDate, endDate : this.endDate, searchText : this.accountSearch, accIds : this.accountIds, dealInitiatedType : dealInitiatedType})
        .then(result=>{
            this.columns = [
                { label: 'Account Name', fieldName: 'Account_Name', type: 'text', sortable: false, hideDefaultActions: true, wrapText: true, cellAttributes: { class: 'custom-column'} },
                { label: 'Account Owner', fieldName: 'Account_Owner_Name', type: 'text', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column'} },
                { label: 'Stage', fieldName: 'Stage', type: 'text', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column'} },
                { label: 'Tier', fieldName: 'Account_Parent_Tier', type: 'text', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column'} },//prit25-11
                { label: 'Deal Initiated Type', fieldName: 'Deal_Registration_Type__c', type: 'text', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column'} },
                { label: 'Close Date', fieldName: 'Close_Date', type: 'Date', cellAttributes: { alignment: 'right' }, sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column'} },
                { label: 'Deal Reg', fieldName: 'Deal_Registration', type: 'text', cellAttributes: { alignment: 'right' }, sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column'} },
                //PRIT26-83 { label: 'SPIFF Eligible', fieldName: 'SPIFF_Eligible', type: 'boolean', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column'} },
                //{ label: 'Amount', fieldName: 'SPIFF_Eligible_Amount', type: 'currency', typeAttributes: { currencyCode : 'USD'}, cellAttributes: { alignment: 'right' }, sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column'}},
                { label: 'Sourcing Partner', fieldName: 'Sourcing_Partner_Name', type: 'text', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column'} },
                { label: 'Opp ID', fieldName: 'Id', type: 'text', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column'} }
            ];
            if((result.partnerAccTheatre.includes('EMEA') || result.partnerAccTheatre.includes('NAM')) && result.partnerAccLevel === 'Authorized'){
                this.showSPIFFButton = false;
                //PRIT26-83
                //this.columns.splice(this.columns.findIndex(ele => ele.label === this.SPIFF_Column.label), 1);
            }
            if(result.oppAllList.length > 0){
                let oppRecAll = [];
                result.oppAllList.forEach(oppEle => {
                    let oppRec = {};
                    oppRec.Id = oppEle.Id;
                    oppRec.Account_Name = oppEle.Account.Name;
                    oppRec.Account_Owner_Name = oppEle.Account.Owner.Name;
                    oppRec.Deal_Registration_Type__c = oppEle.Deal_Registration_Type__c;
                    oppRec.Close_Date = oppEle.CloseDate;
                    oppRec.Stage = oppEle.StageName;
                    oppRec.Deal_Registration = oppEle.Deal_Registration_Number__c;
                    oppRec.Account_Parent_Tier = oppEle.Account.Parent_Tier__c;//prit25-11
                    //PRIT26-83
                    /*if(oppEle.Deal_Registration_Type__c != 'Rubrik Sourced' 
                       && oppEle.Deal_Registration_Number__c != null && oppEle.Deal_Registration_Number__c != undefined 
                       && oppEle.Account.Parent_Tier__c != null && oppEle.Account.Parent_Tier__c != undefined
                       && !((result.partnerAccTheatre.includes('EMEA') || result.partnerAccTheatre.includes('NAM')) && result.partnerAccLevel === 'Authorized')
                       && oppEle.Account.Parent_Tier__c != 'Tier 4' && oppEle.Account.Parent_Tier__c != 'Tier 5'
                      )
                    { 
                            oppRec.SPIFF_Eligible = true;
                    
                    }else
                    {
                                oppRec.SPIFF_Eligible = false;
                    }*/
                    if(oppEle.Sourcing_Partner__c != null){
                        oppRec.Sourcing_Partner_Name = oppEle.Sourcing_Partner__r.Name;
                    }
                    /*if(this.toggleValue){
                        oppRec.SPIFF_Eligible_Amount = oppEle.ACV_Amount__c;
                    }else{
                        oppRec.SPIFF_Eligible_Amount = oppEle.Amount;
                    }*/
                    oppRecAll.push(oppRec);
                })
                this.oppList = oppRecAll;
                if(this.oppList.length > 0 && this.oppList){
                    this.disableExport = false;
                }
            }else{
                this.oppList = [];
            }
            this.loadSpinner = false;
        })
        .catch(error=>{
            console.log('Error->'+error);
            this.loadSpinner = false;
        });
    }

    /*handleToggleChange(event){
        this.loadSpinner = true;
        if(event.target.checked){
            this.toggleValue = true;
        }else{
            this.toggleValue = false;
        }
        this.fetchData();
    }*/

    handlefiscalYearChange(event){
        let fiscalY = event.detail.value;
        let fiscalListOptions = this.fiscalList;
        for(let i = 0; i < fiscalListOptions.length; i++){
            if(fiscalListOptions[i].Name == fiscalY){
                this.startDate = fiscalListOptions[i].StartDate;
                this.endDate = fiscalListOptions[i].EndDate;
            }
        }
        this.fetchData();
    }

    /*handleStartDateChange(event){
        this.loadSpinner = true;
        this.startDate = event.detail.value;
        if(this.startDate){
            this.disableReset = false;
        }
    }

    handleEndDateChange(event){
        this.loadSpinner = true;
        this.endDate = event.detail.value;
        if(this.endDate){
            this.disableReset = false;
        }
    }*/

    handleSearchChange(event){
        let searchKey = event.detail.value;
        if(searchKey.length > 3){
            this.accountSearch = searchKey;
            this.fetchData();
        }
        if(this.accountSearch){
            this.disableReset = false;
        }
    }

    handleResetClick(){
        this.fiscalYear = '';
        this.template.querySelectorAll('lightning-combobox').forEach(each => {
            each.value = null;
        });
        this.template.querySelectorAll('lightning-input').forEach(each => {
            each.value = '';
        });
        
        this.startDate = this.startDateMaster;
        this.endDate = this.endDateMaster;
        this.toggleValue = false;
        this.accountSearch = '';
        this.dealInitiatedType = '';
        this.disableReset = true;
        this.template.querySelector('c-pc_account-Hierarchy').reset();
    }

    handleDealInitiatedTypeChange(event){
        this.dealInitiatedType = event.detail.value;
        this.fetchData();
    }

    handleAccountFilter(event){
        console.log('event->'+event.detail.length);
        if(event.detail.length > 0){
            this.accountIds = event.detail;
        }else{
            this.accountIds = this.accountIdsMaster;
        }
        console.log('this.accountIds->'+this.accountIds);
        this.fetchData();
    }

    handleExportClick(){
        let rowEnd = '\n';
        let csvString = '';

        let rowData = new Set();

        let oppToExport = this.oppList;

        oppToExport.forEach(function (opp) {
            Object.keys(opp).forEach(function(key) {
                rowData.add(key);
            });
        });

        rowData = Array.from(rowData);

        csvString += rowData.join(',');
        csvString += rowEnd;

        for(let i=0; i < oppToExport.length; i++){
            let colValue = 0;
            for(let key in rowData) {
                if(rowData.hasOwnProperty(key)) {
                    let rowKey = rowData[key];
                    if(colValue > 0){
                        csvString += ',';
                    }
                    let value = oppToExport[i][rowKey] === undefined ? '' : oppToExport[i][rowKey];
                    csvString += '"'+ value +'"';
                    colValue++;
                }
            }
            csvString += rowEnd;
        }

        let downloadElement = document.createElement('a');

        downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csvString);
        downloadElement.target = '_self';
        downloadElement.download = 'Opportunity Pipeline.csv';
        document.body.appendChild(downloadElement);
        downloadElement.click();
    }

    handleSPIFFClaimClick(){
        this[NavigationMixin.Navigate]({
            "type": "standard__namedPage",
            "attributes": {
                "pageName": this.buttonNavigateURL
            }
        },true);
    }

    get dealInitiatedTypeOptions(){
        return [{label : 'None', value : null},
                {label : 'Partner Sourced New Logo (PSNL)', value : 'Partner Sourced New Logo (PSNL)'},
                {label : 'Partner Sourced Expand', value : 'Partner Sourced Expand'},
                {label : 'Rubrik Sourced', value : 'Rubrik Sourced'}];
    }
}