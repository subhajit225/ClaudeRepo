import { LightningElement,track,wire } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { NavigationMixin } from "lightning/navigation";
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';
import getDealRegEngagementRecords from '@salesforce/apex/PC_DealRegTableController.getDealRegEngagementRecords';

export default class MyManagedServiceEngagements extends NavigationMixin(LightningElement){
    @track columns;
    @track error;
    @track dealRegList = [];
    @track serachValue = '';
    disableExport = false   ;
    loadSpinner = false;

    connectedCallback(){
        this.loadSpinner = true;
        this.fetchData();
        Promise.all([loadStyle( this, PartnerCommunityResource + '/PartnerCommunityResource/Stylesheets/PartnerCommunityCSS.css')])
        .then(() => {
            console.log("File path-->"+ PartnerCommunityResource);
        })
        .catch(error => {
            console.log( error.body.message );
        });
    }

    fetchData(){
        this.loadSpinner = true;
        getDealRegEngagementRecords({ searchText : this.serachValue})
        .then(result=>{
            this.columns = [
                {label: 'Customer Account', fieldName: 'companyName', type: 'text', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column'}},
                {label: 'Deal Registration Number', fieldName: 'Name', type: 'text', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column'}, initialWidth : 150},
                {label: 'Status', fieldName: 'Deal_Registration_Status__c', type: 'text', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column'}},
                {label: 'Submitted Date', fieldName: 'Deal_Reg_Submitted_Date__c', type: 'date', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column'}},
                {label: 'Approval Date', fieldName: 'Approval_Timestamp__c', type: 'date', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column'}},
                {label: 'Expiration Date', fieldName: 'Deal_Registration_Expiration__c', type: 'date', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column'}},
                {label: 'Engaged with Rubrik', fieldName: 'Engaged_with_Rubrik__c', type: 'text', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column'}},
                {label: 'Amount of Data', fieldName: 'Number_of_protected_machines__c', type: 'text', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column'}},
                {label: 'Scope of Opportunity', fieldName: 'Scope_of_Opportunity__c', type: 'text', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column'}},
                {label: 'Utility Shared Licensing', fieldName: 'Utility_Shared_Licensing__c', type: 'text', sortable: false, hideDefaultActions: true, cellAttributes: { class: 'custom-column'}}
            ];
            
            if(result.length > 0){
                this.dealRegList = result.map(dealRecord => {
                    return {
                        ...dealRecord,
                        companyName: dealRecord.Company_Name__r?.Name || '',
                        accountName: dealRecord.Account__r?.Name || '',
                        partnerName: dealRecord.Partner_Lookup__r?.Name || ''
                    };
                });
            }else{
                this.dealRegList = [];
            }
            this.loadSpinner = false;
        })
        .catch(error=>{
            console.log('Error->',error);
            this.loadSpinner = false;
        });
    }

    handleSearchChange(event){
        this.serachValue = event.detail.value;
        this.fetchData();
    }

    handleResetClick(){
        this.serachValue = '';
        this.dealRegList = [];
        this.fetchData();
    }

    handleExportClick() {
        const rowEnd = '\n';

        // Define CSV headers and field mappings in one structure
        const columns = [
            { label: 'Registration Number', field: 'Name' },
            { label: 'Customer Account Name', field: 'companyName' },
            { label: 'Customer Contact First Name', field: 'FirstName__c' },
            { label: 'Customer Contact Last Name', field: 'LastName__c' },
            { label: 'Customer Contact Email', field: 'Email__c' },
            { label: 'Engaged with Rubrik', field: 'Engaged_with_Rubrik__c' },
            { label: 'Reseller Account Name', field: 'accountName' },
            { label: 'Partner Account Name', field: 'partnerName' },
            { label: 'Status', field: 'Deal_Registration_Status__c' },
            { label: 'Submitted Date', field: 'Deal_Reg_Submitted_Date__c' },
            { label: 'Approved Date', field: 'Approval_Timestamp__c' },
            { label: 'Expire Date', field: 'Deal_Registration_Expiration__c' },
            { label: 'Rejection Reason', field: 'Rejection_Reason__c' },
            { label: 'Rejection Other Reason', field: 'Rejection_Other_Reason__c' },
            { label: 'Source of the opportunity', field: 'Source_of_the_Opportunity__c' },
            { label: 'Amount of Data', field: 'Number_of_protected_machines__c' },
            { label: 'Customer Budget', field: 'Budget__c' },
            { label: 'Timeframe', field: 'Purchase_Timeframe__c' },
            { label: 'Customer Need', field: 'Customer_Needs__c' },
            { label: 'Scope of Opportunity', field: 'Scope_of_Opportunity__c' },
            { label: 'Scope of Opportunity (Additional Details)', field: 'Scope_of_Opportunity_Additional_Details__c' },
            { label: 'Utility Shared Licensing', field: 'Utility_Shared_Licensing__c' },
            { label: 'Utility Shared Licensing Why', field: 'Utility_Shared_Licensing_Why__c' },
            { label: 'PO Number', field: 'PO_Number__c' }
        ];

        // Build CSV header
        let csvString = columns.map(col => col.label).join(',') + rowEnd;

        // Build CSV rows
        this.dealRegList.forEach(record => {
            const row = columns.map(col => {
                let value = record[col.field];
                if (value === null || value === undefined) value = '';
                value = String(value).replace(/"/g, '""'); // Escape quotes
                return `"${value}"`;
            }).join(',');
            csvString += row + rowEnd;
        });

        const downloadElement = document.createElement('a');
        downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csvString);
        downloadElement.target = '_self';
        downloadElement.download = 'Managed_Service_Engagements_Report.csv';
        document.body.appendChild(downloadElement);
        downloadElement.click();
        document.body.removeChild(downloadElement);
    }

}