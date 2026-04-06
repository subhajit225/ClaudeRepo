import { LightningElement, track } from 'lwc';
import executeQuery from '@salesforce/apex/LCC_JSMQueryResultService.executeQuery';

const COLUMNS = [
    {
        label: 'Asset',
        fieldName: 'assetLink',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'assetName' },
            target: '_blank'
        },
        sortable: true,
        cellAttributes: { class: 'slds-text-link' }
    },
    { 
        label: 'Serial Number', 
        fieldName: 'serial', 
        sortable: true 
    },
    {
        label: 'Account',
        fieldName: 'accountLink',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'accountName' },
            target: '_blank'
        },
        sortable: true,
        cellAttributes: { class: 'slds-text-link' }
    },
    {
        label: 'Product',
        fieldName: 'productLink',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'productName' },
            target: '_blank'
        },
        sortable: true,
        cellAttributes: { class: 'slds-text-link' }
    },
    { 
        label: 'Status', 
        fieldName: 'status', 
        sortable: true
    },
    { 
        label: 'Start Date', 
        fieldName: 'startDate', 
        type: 'date', 
        sortable: true,
        typeAttributes: {
            year: 'numeric',
            month: 'short',
            day: '2-digit'
        }
    },
    { 
        label: 'End Date', 
        fieldName: 'endDate', 
        type: 'date', 
        sortable: true,
        typeAttributes: {
            year: 'numeric',
            month: 'short',
            day: '2-digit'
        }
    },
    { 
        label: 'Notes', 
        fieldName: 'notes', 
        wrapText: true,
        cellAttributes: { class: 'slds-cell-wrap' }
    }
];

export default class ReportLWCAssetsWithoutActiveSWEntitlements extends LightningElement {
    columns = COLUMNS;
    @track data = [];
    @track totalRecords = '0 Records';
    @track error;
    @track disableButton = false;
    @track isLoading = false;
    @track defaultSortDirection = 'asc';
    @track sortDirection = 'asc';
    @track sortedBy;

    @track startDateVar = '';
    @track accountNameVar = '';

    connectedCallback() {
        this.fetchData();
    }

    handleAccountNameChange(event) {
        this.accountNameVar = event.target.value;
    }

    handleStartDateChange(event) {
        this.startDateVar = event.target.value;
    }

    handleSearch() {
        this.disableButton = true;
        this.fetchData();
        this.disableButton = false;
    }

    handleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.data];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.data = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    sortBy(field, reverse) {
        const key = (x) => {
            const value = x[field];
            return typeof value === 'string' ? value.toLowerCase() : value;
        };

        return (a, b) => {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }

    fetchData() {
        this.isLoading = true;
        let baseQuery = `
                SELECT Id, Name, SerialNumber, Product2Id, Product2.Name, Status, 
                    AccountId, Account.Name, Support_Start_Date__c, Premium_Support_End_Date__c, 
                    Description, 
                    (SELECT Id, Entitlement__r.Status FROM Scale_Assets__r 
                        ORDER BY Entitlement__r.EndDate DESC LIMIT 1)
                FROM Asset
                WHERE Status = 'Purchased' AND Id IN (
                    SELECT AssetId FROM Entitlement 
                    WHERE Status IN ('Active', 'Inactive') AND (NOT Notes__c LIKE '%reviewed by installed base%') AND Entitlement_Status__c != 'Terminated'
                ) AND Product2.Product_Level__c != null AND Id NOT IN (SELECT Asset__c FROM Scale_Entitlement__c WHERE Entitlement__r.Status IN ('Active', 'Inactive'))`;

        let filters = [];

        if (this.accountNameVar) {
            filters.push(`Account.Name LIKE '%${this.accountNameVar}%'`);
        }

        if (this.startDateVar) {
            filters.push(`Support_Start_Date__c >= ${this.startDateVar}`);
        }
        if (filters.length > 0) {
            baseQuery += ' AND ' + filters.join(' AND ');
        }

        baseQuery += ' LIMIT 10000';

        executeQuery({ theQuery: baseQuery })
            .then(result => {
                const filtered = result.filter(row => 
                    (!row.Description || !row.Description.toLowerCase().startsWith('exception'))
                );
                this.data = filtered.map(row => ({
                    assetLink: '/' + row.Id,
                    assetName: row.Name,
                    serial: row.SerialNumber,
                    productLink: row.Product2Id ? '/' + row.Product2Id : '',
                    productName: row.Product2?.Name || '',
                    accountLink: row.AccountId ? '/' + row.AccountId : '',
                    accountName: row.Account?.Name || '',
                    status: row.Status,
                    startDate: row.Support_Start_Date__c,
                    endDate: row.Premium_Support_End_Date__c,
                    notes: row.Description
                }));
                this.totalRecords = this.data.length + ' Records';
                this.error = undefined;
                this.isLoading = false;
            })
            .catch(error => {
                this.error = error;
                this.data = [];
                this.isLoading = false;
                console.error('Error while loading data : ',error);
            });
    }
}