import { LightningElement, track } from 'lwc';
import getFilteredCases from '@salesforce/apex/PC_PartnerCaseController.getFilteredCases';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadStyle } from 'lightning/platformResourceLoader';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';

export default class PartnerCasesList extends LightningElement {
    @track cases = [];
    @track allCases = [];
    @track currentPage = 1;
    @track totalCases = 0;
    @track selectedFilter = 'My Open Cases';
    @track isLoading = false;
    @track filterOptions = [];

    pageSize = 25;
    formTitle = 'Partner Cases List';
    pageSizeOptions = [
        { label: '5', value: 5 },
        { label: '15', value: 15 },
        { label: '20', value: 20 },
        { label: '25', value: 25 }
    ];

    columns = [
        { label: 'Case Number', fieldName: 'CaseNumber', type: 'url' },
        { label: 'Case Owner', fieldName: 'Owner.Name', type: 'text' },
        { label: 'Status', fieldName: 'Status', type: 'text' },
        { label: 'Type', fieldName: 'Type__c', type: 'text' },
        { label: 'Sub Type', fieldName: 'Subtype__c', type: 'text' },
        { label: 'Contact Name', fieldName: 'Contact.Name', type: 'text' },
        { label: 'Created Date', fieldName: 'CreatedDate', type: 'date' },
        { label: 'Last Modified', fieldName: 'LastModifiedDate', type: 'date' },
    ];
    

    connectedCallback() {
        this.loadCustomCSS();
        this.loadCases();
    }

    loadCustomCSS() {
        loadStyle(this, `${PartnerCommunityResource}/PartnerCommunityResource/Stylesheets/PartnerCommunityCSS.css`)
            .catch(error => console.error('CSS Load Error:', error));
    }

    get offsetSize() {
        return (this.currentPage - 1) * this.pageSize;
    }

    get isFirstPage() {
        return this.currentPage === 1;
    }

    get isLastPage() {
        return this.currentPage >= this.totalPages;
    }

    get hasCases() {
        return this.cases.length > 0;
    }

    get columnCount() {
        return this.columns.length;
    }

    get totalPages() {
        return Math.ceil(this.totalCases / this.pageSize);
    }

    async loadCases() {
        this.isLoading = true;
        try {
            const response = await getFilteredCases({
                filter: this.selectedFilter
            });

            this.allCases = this.formatCases(response.caseList);
            this.totalCases = this.allCases.length;
            this.updateCurrentPage();
            this.filterOptions = this.getViewOptions(response.isAccess);
        } catch (error) {
            this.showToast('Error', 'Failed to load cases', 'error');
            console.error(error);
        } finally {
            this.isLoading = false;
        }
    }

    formatCases(caseList) {
        return caseList.map(caseRecord => ({
            key: caseRecord.Id,
            fields: this.columns.map(column => ({
                key: column.fieldName,
                isLink: column.type === 'url',
                caseLink: column.type === 'url' ? `${window.location.origin}/s/viewcase?id=${caseRecord.Id}` : '',
                value: this.setFieldValueBasedOnType(column.type, caseRecord, column.fieldName)
            }))
        }));
    }

    setFieldValueBasedOnType(type, caseRecord, fieldName) {
        const value = this.parseCaseFieldValue(caseRecord, fieldName);
        return type === 'date' ? this.formatDate(value) : value;
    }

    parseCaseFieldValue(record, fieldPath) {
        return fieldPath.split('.').reduce((value, key) => value?.[key], record);
    }

    formatDate(dateString) {
        if (!dateString) return '';
        return new Intl.DateTimeFormat('en-US', {
            day: 'numeric',
            month: 'short',
            year: 'numeric',
            hour: 'numeric',
            minute: 'numeric',
            second: 'numeric',
            hour12: true
        }).format(new Date(dateString));
    }

    getViewOptions(isAccess) {
        const options = [
            { label: 'My Open Cases', value: 'My Open Cases' },
            { label: 'My Closed Cases', value: 'My Closed Cases' },
            { label: 'Recently Viewed Cases', value: 'Recently Viewed Cases' }
        ];
        if (isAccess) {
            options.unshift(
                { label: 'Open Cases', value: 'Open Cases' },
                { label: 'Closed Cases', value: 'Closed Cases' }
            );
        }
        return options;
    }

    updateCurrentPage() {
        const startIndex = (this.currentPage - 1) * this.pageSize;
        const endIndex = startIndex + this.pageSize;
        this.cases = this.allCases.slice(startIndex, endIndex);
    }
    
    handleFilterChange(event) {
        this.selectedFilter = event.detail.value;
        this.currentPage = 1;
        this.loadCases();
    }
    
    handlePageSizeChange(event) {
        this.pageSize = parseInt(event.detail.value, 10);
        this.currentPage = 1;
        this.updateCurrentPage();
    }
    
    handlePrevious() {
        if (!this.isFirstPage) {
            this.currentPage -= 1;
            this.updateCurrentPage();
        }
    }
    
    handleNext() {
        if (!this.isLastPage) {
            this.currentPage += 1;
            this.updateCurrentPage();
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}