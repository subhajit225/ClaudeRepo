import { LightningElement,track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';
import getPartnerSPIFFList from '@salesforce/apex/PC_PartnerSPIFFClaimApexController.getPartnerSPIFFClaims';
import getFiscalYear from '@salesforce/apex/PC_PortalNavigationApexController.getFiscalYear';
import currentUserId from '@salesforce/user/Id';

export default class Pc_spiffClaimReport_lwc extends LightningElement {
    @track columns = [
        { label: 'Customer Name', fieldName: 'Customer_Name', type: 'text', sortable: false, hideDefaultActions: true, wrapText: true, cellAttributes: { class: 'custom-column'} },
        { label: 'Status', fieldName: 'Status', type: 'text', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column deal-type-col'} },
        { label: 'Incentive', fieldName: 'Incentive_Name', type: 'text', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column'} },
        { label: 'Deal Reg #', fieldName: 'Deal_Registration_Number', type: 'text', cellAttributes: { alignment: 'right' }, sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column'} },
        { label: 'Approval Date', fieldName: 'Approval_Date', type: 'Date', cellAttributes: { alignment: 'right' }, sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column'} },
        { label: 'Payee Name', fieldName: 'Partner_Rep', type: 'text', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column stage-col'} },
        { label: 'Payee Amount', fieldName: 'Partner_Rep_Amount', type: 'currency', typeAttributes: { currencyCode : 'USD'}, cellAttributes: { alignment: 'right' }, sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column'}},
        { label: 'SE Name', fieldName: 'Partner_SE_Name', type: 'text', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column stage-col'} },
        { label: 'SE Amount', fieldName: 'Partner_SE_Amount', type: 'currency', typeAttributes: { currencyCode : 'USD'}, cellAttributes: { alignment: 'right' }, sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column'}}
    ];

    @track error;
    @track SPIFFList = [];
    @track currUserID = currentUserId;
    @track startDate = '';
    @track endDate = '';
    @track accountSearch = '';
    disableFilter = true;
    disableExport = true;
    disableReset = true;
    loadSpinner = false;
    @track fiscalList;
    @track fiscalYearOptions = [];
    @track fiscalYear = null;
    @track accountIds = [];
    status = '';
    incentiveType = '';
    currentStartDate = null;
    currentEndDate = null;

    connectedCallback(){
        this.loadSpinner = true;
        Promise.all([loadStyle( this, PartnerCommunityResource + '/PartnerCommunityResource/Stylesheets/PartnerCommunityCSS.css')])
        .then(() => {
            //console.log("File path-->"+ PartnerCommunityResource);
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

        getFiscalYear()
        .then(result=>{
            this.fiscalList = result;
            let options = [];
            this.fiscalYear = result[0].Name;
            for(let i = 0; i < result.length; i++){
                options.push({label : result[i].Name, value : result[i].Name});
                if(currentfiscalyear == result[i].Name){
                    this.startDate = result[i].StartDate;
                    this.currentStartDate = result[i].StartDate;
                    this.endDate = result[i].EndDate;
                    this.currentEndDate = result[i].EndDate;
                }
            }
            this.fiscalYearOptions = options;
            this.fetchData();
        })
        .catch(error=>{
            console.log('error->'+JSON.stringify(error));
        });
    }

    fetchData(){
        this.loadSpinner = true;
        getPartnerSPIFFList({ partnerAccountId: this.currUserID, startDate : this.startDate, endDate : this.endDate, searchText : this.accountSearch, accIds : this.accountIds, status : this.status, incentiveType : this.incentiveType})
        .then(result=>{
            if(result.length > 0){
                let spiffRecAll = [];
                result.forEach(spiffEle => {
                    let spiffRec = {};
                    spiffRec.Id = spiffEle.Id;
                    spiffRec.Customer_Name = spiffEle.Customer_Company__c;
                    spiffRec.Status = spiffEle.User__c;
                    spiffRec.Incentive_Name = spiffEle.Incentive__r.Name;
                    spiffRec.Deal_Registration_Number = spiffEle.Deal_Registration_Number__c;
                    spiffRec.Approval_Date = spiffEle.Approval_Date__c;
                    spiffRec.Partner_Rep = spiffEle.Partner_Rep_Name__c;
                    spiffRec.Partner_Rep_Amount = spiffEle.Partner_REP_Amount__c;
                    spiffRec.Partner_SE_Name = spiffEle.Partner_SE_Name__c;
                    spiffRec.Partner_SE_Amount = spiffEle.Partner_SE_Amount__c;
                    spiffRecAll.push(spiffRec);
                })
                this.SPIFFList = spiffRecAll;
                if(this.SPIFFList.length > 0 && this.SPIFFList){
                    this.disableExport = false;
                }
                this.loadSpinner = false;
            }else{
                this.SPIFFList = [];
                this.loadSpinner = false;
            }
        })
        .catch(error=>{
            console.log('Error->'+JSON.stringify(error));
            this.loadSpinner = false;
        });
    }

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
        this.loadSpinner = true;
        this.startDate = null;
        this.endDate = null;
        this.accountSearch = null;
        this.disableReset = true;
        this.status = null;
        this.incentiveType = null;
        this.template.querySelector('c-pc_account-Hierarchy').reset();
        this.template.querySelectorAll('lightning-combobox').forEach(each => {
            each.value = null;
        });
        this.startDate = this.currentStartDate;
        this.endDate = this.currentEndDate;
        this.accountIds = [];
        this.fetchData();
    }

    handleAccountFilter(event){
        this.accountIds = event.detail;
        this.fetchData();
    }

    handleExportClick(){
        let rowEnd = '\n';
        let csvString = '';
        let rowData = new Set();
        let spiffToExport = this.SPIFFList;

        spiffToExport.forEach(function (ele) {
            Object.keys(ele).forEach(function(key) {
                rowData.add(key);
            });
        });

        rowData = Array.from(rowData);

        csvString += rowData.join(',');
        csvString += rowEnd;

        for(let i=0; i < spiffToExport.length; i++){
            let colValue = 0;
            for(let key in rowData) {
                if(rowData.hasOwnProperty(key)) {
                    let rowKey = rowData[key];
                    if(colValue > 0){
                        csvString += ',';
                    }
                    let value = spiffToExport[i][rowKey] === undefined ? '' : spiffToExport[i][rowKey];
                    csvString += '"'+ value +'"';
                    colValue++;
                }
            }
            csvString += rowEnd;
        }

        let downloadElement = document.createElement('a');

        downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csvString);
        downloadElement.target = '_self';
        downloadElement.download = 'SPIFF Claim Report.csv';
        document.body.appendChild(downloadElement);
        downloadElement.click();
    }

    get statusOptions() {
        return [
            { label: 'Submitted', value: 'Submitted' },
            { label: 'Pending', value: 'Pending' },
            { label: 'Approved', value: 'Approved' },
            { label: 'Rejected', value: 'Rejected' },
        ];
    }

    handleStatusOptChange(event) {
        this.value = event.detail.value;
        this.status = this.value;
        this.fetchData();
    }

    get incentiveOptions() {
        return [
            { label: 'Deal Reg Incentive', value: 'Deal Reg Incentive' },
            { label: 'Closed Deal Incentive', value: 'Closed Deal Incentive' },
        ];
    }

    handleIncentiveOptChange(event) {
        this.value = event.detail.value;
        this.incentiveType = this.value;
        if(this.incentiveType){
            this.fetchData();
        }
    }
}