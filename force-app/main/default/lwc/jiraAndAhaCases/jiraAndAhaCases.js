import { LightningElement, api, track } from 'lwc';
import getJiraRecords from '@salesforce/apex/CasesWithJiraAhaRefrencesController.getJiraRecords';
import getAhaRecords from '@salesforce/apex/CasesWithJiraAhaRefrencesController.getAhaRecords';
import getChecklistRecords from '@salesforce/apex/CasesWithJiraAhaRefrencesController.getChecklistRecords';
import { NavigationMixin } from "lightning/navigation";
import { deleteRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class JiraAndAhaCases extends NavigationMixin(LightningElement) {

    @api recordId;
    @api title;
    @api isClosed;
    @api tableSource;

    @track tableData = [];

    lastUpdatedInterval = 'a few seconds ago';
    isLoading = true;
    error;
    lastUpdatedIntervalJob;
    lastLoadTimestamp;
    isDeletionModalOpen = false;
    recordToDelete;


    JIRA_COLUMNS = [
        { label: "Summary", fieldName: "zsfjira__Summary__c", type: "text" },
        { label: "Priority", fieldName: "zsfjira__Prioriy__c", type: "text" },
        { label: "Fixed In Versions", fieldName: "Fixed_in_Version__c", type: "text" },
        { label: "Resolution", fieldName: "zsfjira__Resolution__c", type: "text" },
        { label: "Status", fieldName: "zsfjira__Status__c", type: "text" },
        { label: "Release Notes Candidate", fieldName: "Release_Notes_Candidate__c", type: "text" },
        { label: "Resolution Details", fieldName: "Resolution_Details__c", type: "richText", wrapText: true }
    ];

    AHA_COLUMNS = [
        { label: "Aha Idea Number", fieldName: "Aha_Idea_Number__c", type: "text" },
        { label: "Aha Unique ID", fieldName: "Aha_Unique_ID__c", type: "text" },
        { label: "External Unique Id", fieldName: "External_Unique_Id__c", type: "text" },
        { label: "Idea Category", fieldName: "Idea_Category__c", type: "text" },
        { label: "Idea Description", fieldName: "Idea_Description__c", type: "text" },
        { label: "Impacted Customers", fieldName: "Impacted_Customers__c", type: "text" },
        { label: "Problem Statement", fieldName: "Problem_Statement__c", type: "text" },
        { label: "Product Area", fieldName: "Product_Area__c", type: "text" },
        { label: "Product Component", fieldName: "Product_Component__c", type: "text" },
        { label: "Status", fieldName: "Status__c", type: "text" }
    ];

    CHECKLIST_COLUMNS = [
        {
            label: 'Subtask',
            fieldName: 'subTask__Url',
            type: 'url',
            typeAttributes: { label: { fieldName: 'subTask__Name' }, target: '_self' }
        },
        {
            label: "Due Date",
            fieldName: "Due_Date__c",
            type: "date",
            typeAttributes: { day: "numeric", month: "numeric", year: "numeric" }
        },
        { label: "Completed", fieldName: "Completed__c", type: "boolean" },
        { label: "Description", fieldName: "Description__c", type: "text" }
    ];

    getColumns(label, baseColumns) {
        baseColumns = baseColumns.map(item => ({ ...item, sortable: true }))
        return [
            {
                label: label,
                fieldName: 'Record__Url',
                type: 'url',
                typeAttributes: { label: { fieldName: 'Record__Name' }, target: '_self' },
                sortable: true
            },
            ...baseColumns,
            {
                type: 'action', typeAttributes: {
                    rowActions: [
                        { label: 'Edit', name: 'edit' },
                        { label: 'Delete', name: 'delete' }
                    ]
                },
                fixedWidth : 70
            }
        ]
    }

    get filterby() {
        if (this.tableSource == 'JIRA' || this.tableSource == 'RFE') {
            return 'Status'
        } else if (this.tableSource == 'Checklist') {
            return 'Completed';
        }
    }

    get columns() {
        if (this.tableSource == 'JIRA') {
            return this.getColumns('Jira Reference #', this.JIRA_COLUMNS)
        } else if (this.tableSource == 'RFE') {
            return this.getColumns('Aha Ideas Name', this.AHA_COLUMNS)
        } else if (this.tableSource == 'Checklist') {
            return this.getColumns('Title', this.CHECKLIST_COLUMNS)
        }
    }

    get style() {
        return this.totalItems ? 'slds-page-header__row slds-grid' : "slds-page-header__row slds-grid slds-p-vertical_xx-small";
    }

    getLastUpdatedInterval(value) {
        const difference = (value - this.lastLoadTimestamp) / 1000;
        let output = ``;
        if (difference < 60) {
            output = `a few seconds ago`;
        } else if (difference < 3600) {
            output = `${Math.floor(difference / 60)} minutes ago`;
        } else if (difference < 86400) {
            output = `${Math.floor(difference / 3600)} hours ago`;
        } else if (difference < 2620800) {
            output = `${Math.floor(difference / 86400)} days ago`;
        } else if (difference < 31449600) {
            output = `${Math.floor(difference / 2620800)} months ago`;
        } else {
            output = `${Math.floor(difference / 31449600)} years ago`;
        }
        return output;
    }

    handleWiredResult(result) {
        result = JSON.parse(JSON.stringify(result));
        result.forEach(res => {
            res.Record__Url = '/' + res.Id;
            res.Record__Name = res.Name;
            if (res.Sub_Task__c) {
                res.subTask__Url = '/' + res.Sub_Task__c;
                res.subTask__Name = res.Sub_Task__r.Name;
            }
        });
        this.tableData = result;
        this.error = undefined;
        this.isLoading = false;
        this.lastLoadTimestamp = new Date().getTime();
        if (!this.lastUpdatedIntervalJob) {
            this.lastUpdatedInterval = this.getLastUpdatedInterval(new Date().getTime());
            this.lastUpdatedIntervalJob = setInterval(() => {
                this.lastUpdatedInterval = this.getLastUpdatedInterval(new Date().getTime());
            }, 60000);
        }
    }
    handleWiredError(error) {
        console.error('error', error);
        this.isLoading = false;
        this.error = 'An error occured while retrieving data, please contact your Administrator';
    }

    getApexControllerMethod() {
        if (this.tableSource == 'JIRA') {
            return getJiraRecords;
        } else if (this.tableSource == 'RFE') {
            return getAhaRecords;
        } else if (this.tableSource == 'Checklist') {
            return getChecklistRecords;
        }
    }

    connectedCallback() {

        const fetchData = this.getApexControllerMethod();
        fetchData({ accountId: this.recordId, isClosed: this.isClosed })
            .then((result) => {
                this.handleWiredResult(result);
            })
            .catch((error) => {
                this.handleWiredError(error);
            });
    }

    get totalItems() {
        let totalItems = 0;
        if (this.tableData) {
            totalItems = this.tableData.length;
        }
        return totalItems;
    }

    handleAction(event) {
        const action = event.target.dataset.action;
        switch (action) {
            case 'refresh':
                this.isLoading = true;
                clearInterval(this.lastUpdatedIntervalJob);
                this.lastUpdatedIntervalJob = undefined;
                this.connectedCallback();
                break;
            case 'delete':
                this.delete(this.recordToDelete.Id);
                break;
            case 'closeDeletionModalOpen':
                this.isDeletionModalOpen = false;
                this.recordToDelete = undefined;
                break;
            default: break;
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'edit':
                this.navigate(row.Id, 'edit');
                break;
            case 'delete':
                //this.delete(row.Id);
                this.deleteConfirmation(row.Id);
                break;
        }
    }
    deleteConfirmation(recordId) {
        this.isDeletionModalOpen = true;
        this.recordToDelete = this.tableData.find(c => c.Id == recordId);
    }

    delete(recordId) {
        deleteRecord(recordId)
            .then(() => {
                this.isDeletionModalOpen = false;
                this.recordToDelete = undefined;
                this.isLoading = true;
                this.connectedCallback();
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Success",
                        message: "Record deleted",
                        variant: "success",
                    }),
                );
            })
            .catch((error) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Error deleting record",
                        message: error.body.message,
                        variant: "error",
                    }),
                );
            });
    }

    navigate(id, actionName) {
        const pageRef = {
            type: 'standard__recordPage',
            attributes: {
                recordId: id,
                actionName: actionName
            }
        };
        this[NavigationMixin.Navigate](pageRef);
    }
}